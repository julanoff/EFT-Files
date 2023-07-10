%MODULE MOVETRN <MAIN>;
**********************************************************
* Copyright (c) 2016 Standard Chartered Bank	           *
* Mar 2017           Standard Chartered Bank    				 *
* Author: J.Novak					                               *
**********************************************************
* This program removes a message from specified queue and enqueues it to another queue.
* ALL_20170428231706 
* ******************************************************
* Revisions.
* 3/10/17  JN	V1.0

%def		<ENTFTR>	%`SBJ_DD_PATH:ENTFTR_FSECT.DDL`		%End
%def		<ENTREPT>	%`SBJ_DD_PATH:ENTREPT_FSECT.DDL`	%End
%def		<ENT>		%`SBJ_DD_PATH:ENT_FSECT.DDL`		%End
%def		<ACE>	  	%`SBJ_DD_PATH:ACE_FSECT.DDL`		%End
%def		<ROUTE>		%`SBJ_DD_PATH:ROUTE_FSECT.DDL`		%End

%def		<MOVETRN_WS>
Trn_no:					Vstr(17);
Bnk_name1:				Vstr(3);
Memo_ws:				Vstr(80);
Err_msg:				Vstr(80);
Err_str:				Vstr(160);
Err_compose:			Compose;
Compose_ws:				Compose;
Ret_status: 			Boolean;
Ref:					Rec(%`SBJ_DD_PATH:TRN_ID_REC.DDF` );   
Gen_q:					Que(%`SBJ_DD_PATH:GEN_WORK_QUE.DDF`);
Pnd_q:					Que(%`SBJ_DD_PATH:SAF_PND_QUE.DDF`);
Fut_q:					Que(%`SBJ_DD_PATH:FUTURE_QUE.DDF`);
Sum_q:					Que(%`SBJ_DD_PATH:SUMMARY_QUE.DDF`);
Ant_q:					Que(%`SBJ_DD_PATH:ANT_QUE.DDF`);
Trg_ant_q:				Que(%`SBJ_DD_PATH:ANT_QUE.DDF`);
Trg_sum_q:				Que(%`SBJ_DD_PATH:SUMMARY_QUE.DDF`);
Trg_fut_q:				Que(%`SBJ_DD_PATH:FUTURE_QUE.DDF`);
Trg_pnd_q:				Que(%`SBJ_DD_PATH:SAF_PND_QUE.DDF`);
Trg_gen_q:				Que(%`SBJ_DD_PATH:GEN_WORK_QUE.DDF`);
Trg_ant_q_qid:      	Rec (%`SBJ_DD_PATH:PRIV_ITEM_REC.DDF`);
Trg_sum_q_qid:      	Rec (%`SBJ_DD_PATH:PRIV_ITEM_REC.DDF`);
Trg_fut_q_qid:      	Rec (%`SBJ_DD_PATH:PRIV_ITEM_REC.DDF`);
Trg_pnd_q_qid:      	Rec (%`SBJ_DD_PATH:PRIV_ITEM_REC.DDF`);
Trg_gen_q_qid:      	Rec (%`SBJ_DD_PATH:PRIV_ITEM_REC.DDF`);
F_qname:				Vstr(12);
T_qname:				Vstr(12);
Ace_vstr_ws:    		Vstr(%`%ACE$_MSG_STR_SIZE`);
Bnk_key_ws: 			Str(3);	%^ current bank if any
Long_zero_ws:			Long = <0> ;
No_ws:					Long;
Frc_ws:					Str(1);
Dbg_sw:					Str(1);
Qtyp_ws:				Vstr(3);
State_del:				Boolean;
Conn_ws:				Boolean;

%End

%Work
01  Q_found				Pic X		Value "N".
01  Qtp_ws          	Pic X(3).

%PROCEDURE.

A100_MAIN_PROGRAM.
*
*
	Call "ACE_ARG_FIND" using
		by content   "-hel*p:",
		by content   "U",
        by value     %SIZ(frc_ws),
        by reference frc_ws,
        by reference frc_ws_length,
        by reference OMITTED,
        by reference OMITTED,
	  returning ret_status.

	If Success_is in Ret_status
		Display "    Message Move Facility for SCB MTS"
		Display "    -----------------------------------"
		Display "  Invocation:  movetrn -b jpt -type PND -from FROM_QUEUE -trn 20170303-234 -to TO_QUEUE -memo TEXT"
		Display "  Arguments to execute this utility:"
		Display "  Mandatory  -b    bank name (Example: SCB, JPT) "
		Display "  Mandatory  -trn  trn number in the format YYYYMMDD-NNNN "
		Display "  Mandatory  -from name of the source queue"
		Display "  Mandatory  -to   name of the target queue"
		Display "  Mandatory  -memo memo that appears in the msg history"
		Display "  Optional   -type type of the target que (ANT,SUM,FUT,PND,GEN). Default is GEN. "
		Display "    -------------------------------------"
		%Exit Program
	End-if.
    Call "ACE_ARG_FIND" using
                   by content   "-b*ank",
                   by content   "U",
                   by value     %SIZ(Bnk_name1),
                   by reference Bnk_name1,
                   by reference Bnk_name1_length,
                   by reference Ace_vstr_ws,
                   by reference Ace_vstr_ws_length,
           Returning Ret_status.

  	If ( Failure_is IN Ret_status)
	    %Beg Err_compose ^Out(Err_msg) "MOVETRN: Bank was not specified. Exiting. ", /; %End
		Display Err_msg(1:Err_msg_length)
	    Call "NEX_CREATE_AND_BROADCAST_MSG" USING
				by reference Err_msg,
				by value Err_msg_length,
				%ace_msg_arg_list("MOVETRN");
		%Exit Program
    End-if.
	Call "ACE_ARG_FIND" using
        by content   "-typ*e",
        by content   "U",
		by value     %SIZ(Qtyp_ws),
		by reference Qtyp_ws,
		by reference Qtyp_ws_length,
		by reference Ace_vstr_ws,
		by reference Ace_vstr_ws_length,
		Returning Ret_status.

  	If ( Failure_is IN Ret_status)
		Move "GEN" to Qtyp_ws
	End-if.
	
	If Qtyp_ws Not = "ANT" and "SUM" and "FUT" and "PND" and "GEN"
	    %Beg Err_compose ^Out(Err_msg) "MOVETRN: Incorrect Q type. Exiting. ", /; %End
		Display Err_msg(1:Err_msg_length)
	    Call "NEX_CREATE_AND_BROADCAST_MSG" USING
				by reference Err_msg,
				by value Err_msg_length,
				%ace_msg_arg_list("MOVETRN");
		%Exit Program
	End-if.

	Move Bnk_name1(1:3) to Bnk_key_ws.

	Call "ACE_ARG_FIND" using
        by content   "-from*_queue",
        by content   "U",
		by value     %SIZ(F_qname),
		by reference F_qname,
		by reference F_qname_length,
		by reference Ace_vstr_ws,
		by reference Ace_vstr_ws_length,
		Returning Ret_status.

    If ( Failure_is IN Ret_status)
		%Beg Err_compose ^Out(Err_msg) "MOVETRN: Incorrect Source Queue was specified. Exiting. ", /; %End
		Display Err_msg(1:Err_msg_length)
	    Call "NEX_CREATE_AND_BROADCAST_MSG" USING
				by reference Err_msg,
				by value Err_msg_length,
				%ace_msg_arg_list("MOVETRN");
		%Exit Program
    End-if.

    Call "ACE_ARG_FIND" using
               by content   "-to*_queue",
               by content   "U",
               by value     %SIZ(T_qname),
               by reference T_qname,
               by reference T_qname_length,
               by reference Ace_vstr_ws,
               by reference Ace_vstr_ws_length,
            Returning Ret_status.

    If ( Failure_is IN Ret_status)
 		%Beg Err_compose ^Out(Err_msg) "MOVETRN: Incorrect Target Queue was specified. Exiting. ", /; %End
		Display Err_msg(1:Err_msg_length)
		Call "NEX_CREATE_AND_BROADCAST_MSG" USING
					by reference Err_msg,
					by value Err_msg_length,
					%ace_msg_arg_list("MOVETRN");
		%Exit Program
	End-if.

      Call "ACE_ARG_FIND" using
               by content   "-me*mo",
               by content   "U",
               by value     %SIZ(Memo_ws),
               by reference Memo_ws,
               by reference Memo_ws_length,
               by reference Ace_vstr_ws,
               by reference Ace_vstr_ws_length,
            Returning Ret_status.

    If ( Failure_is IN Ret_status)
		 		%Beg Err_compose ^Out(Err_msg) "MOVETRN: Memo must be specified. Exiting. ", /; %End
						Display Err_msg(1:Err_msg_length)
				    Call "NEX_CREATE_AND_BROADCAST_MSG" USING
							by reference Err_msg,
							by value Err_msg_length,
							%ace_msg_arg_list("MOVETRN");
						%Exit Program
	End-if.
    CALL "DAT_CONN_ROOT_AND_MSG".

	Evaluate Qtyp_ws
		when "ANT"
			%ace_conn_q /<Bnk_key_ws>///<t_qname> To Trg_ant_q With Optimization Giving Ret_status;
		when "SUM"
			%ace_conn_q /<Bnk_key_ws>///<t_qname> To Trg_sum_q With Optimization Giving Ret_status;
		when "FUT"
			%ace_conn_q /<Bnk_key_ws>///<t_qname> To Trg_fut_q With Optimization Giving Ret_status;
		when "PND"
			%ace_conn_q /<Bnk_key_ws>///<t_qname> To Trg_pnd_q With Optimization Giving Ret_status;
		when "GEN"
			%ace_conn_q /<Bnk_key_ws>///<t_qname> To Trg_gen_q With Optimization Giving Ret_status;
	End-evaluate.
	If Failure_is in Ret_status
 		%Beg Err_compose ^Out(Err_msg) "MOVETRN: Target Queue does not exist. Exiting. ", /; %End
		Display Err_msg(1:Err_msg_length)
		Call "NEX_CREATE_AND_BROADCAST_MSG" USING
					by reference Err_msg,
					by value Err_msg_length,
					%ace_msg_arg_list("MOVETRN");
		%Exit Program
	End-if.

	Call "ACE_ARG_FIND" using
		by content   "-t*rn",
		by content   "U",
		by value     %SIZ(Trn_no),
		by reference Trn_no
		by reference Trn_no_length,
		by reference Ace_vstr_ws,
		by reference Ace_vstr_ws_length,
			Returning Ret_status.

    If ( Failure_is IN Ret_status)
	    %Beg Err_compose ^Out(Err_msg) "MOVETRN: TRN was not specified. Exiting. ", /; %End
		Display Err_msg(1:Err_msg_length)
	    Call "NEX_CREATE_AND_BROADCAST_MSG" USING
				by reference Err_msg,
				by value Err_msg_length,
				%ace_msg_arg_list("MOVETRN");
		%Exit Program
	End-if.

	Move 17 to Trn_no_length.
	Perform until Trn_no(Trn_no_length:1) not = Space or Trn_no_length = 0
			Subtract 1 from Trn_no_length
	End-perform.				

	%Beg Parse (^notrap) ^IN (Trn_no), Ref.Trn_date, "-", Ref.Trn_Num,/; %End
	If Failure_is in Parse_status
		%Beg Err_compose ^Out(Err_msg) "MOVETRN: TRN number is incorrect (20160301-234). Exiting. ", /; %End
		Display Err_msg(1:Err_msg_length)
		Call "NEX_CREATE_AND_BROADCAST_MSG" USING
			by reference Err_msg,
			by value Err_msg_length,
			%ace_msg_arg_list("MOVETRN");
  		%Exit Program
	End-if.
	%Beg
		Parse ^IN(Ref.Trn_num) No_ws(^NUMBER);
		Compose_ws ^OUT(Ref.Trn_num) No_ws(^LEADING_ZEROS, ^NUM<8>);
	    BREAK: Ent_msg_history;
	    Ref_index ^SEARCH (forward, eql, Key = Ref);
    %End.

    If Success_is in Ref_index_status
        %Beg
       		Ref_index CONN: Ent_msg_history(NOMOD);
            Ent_msg_history ^First;
        %End
    Else
		%Beg Err_compose ^Out(Err_msg) "MOVETRN: TRN number was not found. Exiting. ", /; %End
		Display Err_msg(1:Err_msg_length)
		Call "NEX_CREATE_AND_BROADCAST_MSG" USING
			by reference Err_msg,
			by value Err_msg_length,
			%ace_msg_arg_list("MOVETRN");
  		%Exit Program	      
  	End-if.

* make sure that this msg is on the source q.
	%Beg Ent_msg_history ^Last; %End.
	Move "N" to Q_found.
	Move Spaces to Qtp_ws.

	Perform until Seq_beg_is in Ent_msg_history_cursor or Q_found = "Y"
		If Idname of Qname of Ent_msg_history = F_qname
			Evaluate Qtype of Ent_msg_history
				when "QTYP$_ANT_QUE"
					Move "ANT" to Qtp_ws
					%Beg
							BREAK: Ant_q;
							Ent_msg_history (notrap, CONN: Ant_q);
							State_del = Ant_q State.Deleted;
					%End
					%ACE_IS Ant_q CONNECTED Giving Conn_ws
					If Failure_is in State_del and Success_is in Conn_ws
						Move "Y" to Q_found
					End-if
				when "QTYP$_SUMMARY_QUE"
					Move "SUM" to Qtp_ws
					%Beg
							BREAK: Sum_q;
							Ent_msg_history (notrap, CONN: Sum_q);
							State_del = Sum_q State.Deleted;
					%End
					%ACE_IS Sum_q CONNECTED Giving Conn_ws
					If Failure_is in State_del and Success_is in Conn_ws
						Move "Y" to Q_found
					End-if
				when "QTYP$_FUTURE_QUE"
					Move "FUT" to Qtp_ws
					%Beg
							BREAK: Fut_q;
							Ent_msg_history (notrap, CONN: Fut_q);
							State_del = Fut_q State.Deleted;
					%End
					%ACE_IS Fut_q CONNECTED Giving Conn_ws
	
					If Failure_is in State_del and Success_is in Conn_ws
						Move "Y" to Q_found
					End-if
					
				when "QTYP$_SAF_PND_QUE"
					Move "PND" to Qtp_ws
					%Beg
							BREAK: Pnd_q;
							Ent_msg_history (notrap, CONN: Pnd_q);
							State_del = Pnd_q State.Deleted;
					%End
					%ACE_IS Pnd_q CONNECTED Giving Conn_ws
	
					If Failure_is in State_del and Success_is in Conn_ws
						Move "Y" to Q_found
					End-if
	
				when "QTYP$_GEN_WORK_QUE"
					Move "GEN" to Qtp_ws
					%Beg
							BREAK: Gen_q;
							Ent_msg_history (notrap, CONN: Gen_q);
							State_del = Gen_q State.Deleted;
					%End
					%ACE_IS Gen_q CONNECTED Giving Conn_ws
	
					If Failure_is in State_del and Success_is in Conn_ws
						Move "Y" to Q_found
					End-if
	
				when other
					%Beg Err_compose ^Out(Err_msg) "MOVETRN: Source Qtype ", Ent_msg_history.Qtype,  " is not supported. Exiting. ", /; %End
					Display Err_msg(1:Err_msg_length)
					Call "NEX_CREATE_AND_BROADCAST_MSG" USING
						by reference Err_msg,
						by value Err_msg_length,
						%ace_msg_arg_list("MOVETRN");
					%Exit Program
			End-evaluate
		End-if
		If Idname of Qname of Ent_msg_history = "*SUB_HISTORY"
			%Beg
				BREAK: Ent_msg_subhist;
				Ent_msg_history CONN: Ent_msg_subhist(nomod);
				Ent_msg_subhist ^Last;
			%End
			Perform until Seq_beg_is in Ent_msg_subhist_cursor or Q_found = "Y"
				If Idname of Qname of Ent_msg_subhist = F_qname
					Evaluate Qtype of Ent_msg_subhist
						when "QTYP$_ANT_QUE"
							Move "ANT" to Qtp_ws
							%Beg
								BREAK: Ant_q;
								Ent_msg_subhist (notrap, CONN: Ant_q);
								State_del = Ant_q State.Deleted;
							%End
							%ACE_IS Ant_q CONNECTED Giving Conn_ws
	
							If Failure_is in State_del and Success_is in Conn_ws
								Move "Y" to Q_found
							End-if
	
						when "QTYP$_SUMMARY_QUE"
							Move "SUM" to Qtp_ws
							%Beg
								BREAK: Sum_q;
								Ent_msg_subhist (notrap, CONN: Sum_q);
								State_del = Sum_q State.Deleted;
							%End
							%ACE_IS Sum_q CONNECTED Giving Conn_ws
	
							If Failure_is in State_del and Success_is in Conn_ws
								Move "Y" to Q_found
							End-if
	
						when "QTYP$_FUTURE_QUE"
							Move "FUT" to Qtp_ws
							%Beg
								BREAK: FUT_q;
								Ent_msg_subhist (notrap, CONN: Fut_q);
								State_del = Fut_q State.Deleted;
							%End
							%ACE_IS Fut_q CONNECTED Giving Conn_ws
	
							If Failure_is in State_del and Success_is in Conn_ws
								Move "Y" to Q_found
							End-if
	
						when "QTYP$_SAF_PND_QUE"
							Move "PND" to Qtp_ws
							%Beg
								BREAK: Pnd_q;
								Ent_msg_subhist (notrap, CONN: Pnd_q);
								State_del = Pnd_q State.Deleted;
							%End
							If Failure_is in State_del
								Move "Y" to Q_found
							End-if
	
						when "QTYP$_GEN_WORK_QUE"
							Move "GEN" to Qtp_ws
							%Beg
								BREAK: Gen_q;
								Ent_msg_subhist (notrap, CONN: Gen_q);
								State_del = Gen_q State.Deleted;
							%End
							%ACE_IS Gen_q CONNECTED Giving Conn_ws
	
							If Failure_is in State_del and Success_is in Conn_ws
								Move "Y" to Q_found
							End-if
	
						when other
							%Beg Err_compose ^Out(Err_msg) "MOVETRN: Source Qtype ", Ent_msg_subhist.Qtype,  " is not supported. Exiting. ", /; %End
							Display Err_msg(1:Err_msg_length)
							Call "NEX_CREATE_AND_BROADCAST_MSG" USING
									by reference Err_msg,
									by value Err_msg_length,
									%ace_msg_arg_list("MOVETRN");
							%Exit Program	
					End-evaluate
				End-if
				%Beg Ent_msg_subhist ^Prev; %End
			End-perform
			%Beg Ent_msg_history ^Prev; %End
		Else
			%Beg Ent_msg_history ^Prev; %End
		End-if
	End-perform.
	If Q_found = "N"
		%Beg Err_compose ^Out(Err_msg) "MOVETRN: TRN is not on the specified queue. Exiting. ", /; %End
		Display Err_msg(1:Err_msg_length)
		Call "NEX_CREATE_AND_BROADCAST_MSG" USING
			by reference Err_msg,
			by value Err_msg_length,
			%ace_msg_arg_list("MOVETRN");
		%Exit Program	      
  	End-if.

	Evaluate Qtp_ws
		When "GEN"
			%Beg DELETE: Gen_q(insert); %End
		When "SUM"
			%Beg DELETE: Sum_q(insert); %End
		When "PND"
			%Beg DELETE: Pnd_q(insert); %End
		When "FUT"
			%Beg DELETE: Fut_q(insert); %End
		When "ANT"
			%Beg DELETE: Ant_q(insert); %End
	End-evaluate.
	Evaluate Qtyp_ws
		When "GEN"
			%Beg
				ALLOC_END: Ent_msg_history(mod,
				.Qname(
				.Idprod = null,
				.Idbank = Bnk_key_ws,
				.Idloc = null,
				.Idcust = null,
				.Idname = T_qname),
				.Qtype = "QTYP$_GEN_WORK_QUE",
				.Memo = Memo_ws,
					ALLOC_JOIN: Trg_gen_q(
					insert,
					.Trn = Ref,
					.Txt = Ref,
					.Systime Now,
					.Bnk_id = Bnk_key_ws,
					.Memo = Memo_ws));
			%End
		When "SUM"
			%Beg
				ALLOC_END: Ent_msg_history(mod,
				.Qname(
				.Idprod = null,
				.Idbank = Bnk_key_ws,
				.Idloc = null,
				.Idcust = null,
				.Idname = T_qname),
				.Qtype = "QTYP$_SUMMARY_QUE",
				.Memo = Memo_ws,
					ALLOC_JOIN: Trg_sum_q(
					insert,
					.Trn = Ref,
					.Txt = Ref,
					.Enq_time Now));
			%End
		When "PND"
			%Beg
				ALLOC_END: Ent_msg_history(mod,
				.Qname(
				.Idprod = null,
				.Idbank = Bnk_key_ws,
				.Idloc = null,
				.Idcust = null,
				.Idname = T_qname),
				.Qtype = "QTYP$_SAF_PND_QUE",
				.Memo = Memo_ws,
					ALLOC_JOIN: Trg_pnd_q(
					insert,
					.Ref_num = Ref,
					.Systime Now));
			%End
		When "FUT"
			%Beg
				ALLOC_END: Ent_msg_history(mod,
				.Qname(
				.Idprod = null,
				.Idbank = Bnk_key_ws,
				.Idloc = null,
				.Idcust = null,
				.Idname = T_qname),
				.Qtype = "QTYP$_FUTURE_QUE",
				.Memo = Memo_ws,
					ALLOC_JOIN: Trg_fut_q(
					insert));
			%End
		When "ANT"
			%Beg
				ALLOC_END: Ent_msg_history(mod,
				.Qname(
				.Idprod = null,
				.Idbank = Bnk_key_ws,
				.Idloc = null,
				.Idcust = null,
				.Idname = T_qname),
				.Qtype = "QTYP$_ANT_QUE",
				.Memo = Memo_ws,
					ALLOC_JOIN: Trg_ant_q(
					insert));
			%End
	End-evaluate.
	%Beg
		ALLOC_END: Ent_msg_history (mod,
			.Qname(
			.Idprod = null,
			.Idbank = Bnk_key_ws,
			.Idloc  = null,
			.Idcust = null,
			.Idname = "*SYS_MEMO"),
			.Qtype = "OBJTYP$_NULL",
			.Memo = Memo_ws );
	%End.
	Call "DAT_BREAK_MSG".
	%Beg Commit: Tran; %End.
	Call "LOCK_DEQ" using
		By reference omitted
		By value Long_zero_ws.
	Display "The TRN ", Trn_no, " was moved from ", F_qname, " to " T_qname.
	
	%Exit Program.
