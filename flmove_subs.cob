%MODULE FLMOVE_SUBS;
**********************************************************
* Copyright (c) 2016 Standard Chartered Bank	           *
* Mar 2016           Standard Chartered Bank    				 *
* Author: J.Novak					                               *
**********************************************************
* This program receives a trn #. Finds a msg on falcon pending q.
* Sends it back to ACI flow as if we received NO authentication needed.
* ******************************************************
* Revisions.
* 3/6/19  JN	V1.0

%def		<ENTFTR>	%`SBJ_DD_PATH:ENTFTR_FSECT.DDL`		%end
%def		<ENTREPT>	%`SBJ_DD_PATH:ENTREPT_FSECT.DDL`	%end
%def		<ENT>		%`SBJ_DD_PATH:ENT_FSECT.DDL`		%end
%def		<ACE>	  	%`SBJ_DD_PATH:ACE_FSECT.DDL`		%end
%def		<ROUTE>		%`SBJ_DD_PATH:ROUTE_FSECT.DDL`		%end
%def 		<LINE_FS>	%`SBJ_DD_PATH:LINE_FS_FSECT.DDL`	%end
%def 		<RMT>     	%`SBJ_DD_PATH:RMT_FSECT.DDL`      	%end

%def		<FLMOVE_SUBS_WS>
Genq:					Que(%`SBJ_DD_PATH:GEN_WORK_QUE.DDF`);
Pndq:                	Que(%`SBJ_DD_PATH:SAF_PND_QUE.DDF`) scan_key = Ref_num;
Refno:					Rec(%`SBJ_DD_PATH:TRN_ID_REC.DDF` ); 
Act_log:				Que(%`SBJ_DD_PATH:OPR_ACTION_LOG.DDF`);  
Fal_q_name:				Vstr(12) = "FAL1_PNDQ";
S2b_q_name:				Vstr(12) = "S2B1_PNDQ";
Fal_vfyq_name:			Vstr(12) = "FAL_VFYPNDQ";
S2b_vfyq_name:			Vstr(12) = "S2B_VFYPNDQ";
Q_name:					Vstr(12);
Fal_log_name:			Vstr(12) = "FALRLSE_LOG";
S2B_log_name:			Vstr(12) = "S2BRLSE_LOG";
Log_name:				Vstr(12);
Line_ws:				Str(3);
Bnk_name1:				Vstr(3);
Trn_no:					Vstr(17);
Err_str:				Vstr(160);
Err_msg:				Vstr(80);
Err_compose:			Compose;
Compose_ws:				Compose;
Memo_ws:				Vstr(80);
Opr_ws:					Vstr(10);
Q_connected_ws:   		Boolean;
Ret_status: 			Boolean;
No_ws:					Long;
Parse_ws:				Parse;
Tmp1:					Vstr(80);
Long_zero_ws:			Long = <0>;

%end

%Work
01  First_time	    	Pic X   Value "Y".
01  PndExist			Pic X   Value "N".

%Linkage
01  Bnk_name_ls			Pic X(3).
01  Line_ls				Pic X(3).
01  Trn_no_ls			Pic X(17).
01  Force_ls			Pic X.
01  Dbg_sw_ls			Pic X.
01  Vfy_ls				Pic X.
01	Opr_ls				Pic X(10).
01	Memo_ls				Pic X(80). 
01  Err_str_ls			Pic X(160).
01  Ret_stat 			Pic S9(9) COMP-5.
	   88 FAILURE-IS VALUE 0.
	   88 SUCCESS-IS VALUE 1.

%Procedure Using Bnk_name_ls, Line_ls, Trn_no_ls Force_ls Dbg_sw_ls Vfy_ls Opr_ls Memo_ls Err_str_ls Returning Ret_stat.

A000_MAIN.
	Set Success_is in Ret_stat to true.
	Move Spaces to Err_str_ls.
	%Beg Err_str = ""; %End.
	Move Bnk_name_ls to Bnk_name1.
	Move 3 to Bnk_name1_length.
	Move Trn_no_ls to RefNo.
	Move Opr_ls to Opr_ws.
	Move 10 to Opr_ws_length.
	Perform until Opr_ws(Opr_ws_length:1) not = Space or Opr_ws_length = 0
			Subtract 1 from Opr_ws_length
	End-perform.
	Move Memo_ls to Memo_ws.
	Move 80 to Memo_ws_length.
	Perform until Memo_ws(Memo_ws_length:1) not = Space or Memo_ws_length = 0
			Subtract 1 from Memo_ws_length
	End-perform.
	Move Line_ls to Line_ws.

	Perform B100_sbj_init thru B100_sbj_init_end.
*
* Loop to dequeue messages and process them
*
	Perform B200_process_msg thru B200_process_msg_end.

%EXIT PROGRAM.


B100_SBJ_INIT.
* Initialization:
*
    CALL "DAT_CONN_ROOT_AND_MSG".
%^ Make connections to the common domains
	If Line_ls not = Q_name(1:3)
		%Beg BREAK: Pndq; %End
	End-if.
    %ace_is Pndq CONNECTED returning Q_connected_ws;
	If Failure_is in Q_connected_ws		%^ Means the Act log is NOT connected
		If Line_ls = "FAL"
			If Vfy_ls = "V"
				%Beg Q_name = Fal_vfyq_name; %End
			Else
				%Beg Q_name = Fal_q_name; %End
			End-if
		Else
			If Vfy_ls = "V"
				%Beg Q_name = S2b_vfyq_name; %End
			Else
				%Beg Q_name = S2b_q_name; %End
			End-if
		End-if
	End-if.
	%ace_conn_q /<Bnk_name1>///<Q_name> to Pndq;.
    If Failure_is IN Pndq_status
		%beg Err_compose ^Out(Err_msg) "FL_RELEASE: Cannot connect to ", Q_name, " Exiting. ", /; %end
		Call "NEX_CREATE_AND_BROADCAST_MSG" USING
			by reference Err_msg,
			by value Err_msg_length,
			%ace_msg_arg_list("FL_RELEASE");
			Perform X100_make_err thru X100_end
			Set Failure_is in Ret_stat to true
			%exit program
    End-if.
	If Q_name(1:3) not = Log_name(1:3)
		%Beg BREAK: Act_log; %End
	End-if.
    %ace_is Act_log CONNECTED returning Q_connected_ws;
	If Failure_is in Q_connected_ws		%^ Means the Act log is NOT connected
		If Line_ls = "FAL"
			%Beg Log_name = Fal_log_name; %End
		Else
			%Beg Log_name = S2b_log_name; %End
		End-if
		%ace_conn_q /<Bnk_name1>///<Log_name> to Act_log for insert;
	End-if.
    If Failure_is IN Act_log_status
		%beg Err_compose ^Out(Err_msg) "FL_RELEASE: Cannot connect to ", Log_name, " Exiting. ", /; %end
		Call "NEX_CREATE_AND_BROADCAST_MSG" USING
			by reference Err_msg,
			by value Err_msg_length,
			%ace_msg_arg_list("FL_RELEASE");
			Perform X100_make_err thru X100_end
			Set Failure_is in Ret_stat to true
			%exit program
    End-if.
	If Dbg_sw_ls = "Y"
		Display "Falcon Init routine"
		Display " Bank - ", Bnk_name1, " trn: ", RefNo, " oper - ", Opr_ws, "  memo - ", Memo_ws
	End-if.
B100_SBJ_INIT_END.
	EXIT.

B200_PROCESS_MSG.
	If Dbg_sw_ls = "Y"
		Display "B200 proc"
	End-if.
	If RefNo = Spaces	%^ We must have a TRN #
		%beg Err_compose ^Out(Err_msg) "FL_RELEASE: TRN # is missing. Exiting. ", /; %end
		Call "NEX_CREATE_AND_BROADCAST_MSG" USING
			by reference Err_msg,
			by value Err_msg_length,
			%ace_msg_arg_list("FL_RELEASE");
			Perform X100_make_err thru X100_end
			Set Failure_is in Ret_stat to true
			%exit program
	End-if.
	%Beg
		Parse_ws ^IN(RefNo.Trn_num) No_ws(^NUMBER);
		Compose_ws ^OUT(RefNo.Trn_num) No_ws(^LEADING_ZEROS, ^NUM<8>);
		SCAN: Pndq (EQL, FORWARD, scan_key = RefNo );
	%End.
	If Failure_is in Pndq_status
		%beg Err_compose ^Out(Err_msg) "FL_RELEASE: TRN ", RefNo, " not found in ", Q_name, ". Exiting. ", /; %end
		Call "NEX_CREATE_AND_BROADCAST_MSG" USING
			by reference Err_msg,
			by value Err_msg_length,
			%ace_msg_arg_list("FL_RELEASE");
		Perform X100_make_err thru X100_end
		Set Failure_is in Ret_stat to true
  		%exit program
	End-if.
	%Beg
		BREAK: Ent_msg_history;
        Ent_msg_history (NOMOD_WAIT, NOTRAP);
	   	Pndq  CONN: Ent_msg_history (MOD);
        Ret_status = Ent_msg_history status;
        Ent_msg_history(MOD_WAIT,ETRAP);
	%End.
	If ( Failure_is IN Ret_status)
		%Beg Tmp1 = Pndq.Ref_num; %End
		Display "!!!!!! Message: ", Tmp1(1:tmp1_length), " is locked by another process."
		Call "DAT_BREAK_MSG"
		%beg Cancel: Tran; %end
		Go to B200_process_msg_end
	End-if.
	Call "DAT_CONN_MSG".
    If Dbg_sw_ls = "Y"
        Display "Msg props: " , Trn_ref of Ent_ftr_set, " tran type - ", Tran_type of typ of Ent_ftr_set, " src - ", Src_code of Ent_ftr_Set
    End-if.
	%Beg
		DELETE: Pndq(insert);
        ALLOC_END: Ent_msg_history  (mod,
           .Qname (.idprod = null,
                   .idbank = Ent_ftr_set.loc_info.bank,
                   .idloc  = Ent_ftr_set.loc_info.loc,
                   .idcust = null,
                   .idname = Log_name),
           .Qtype  = "QTYP$_OPR_ACTION_LOG"
           .Memo   = Memo_ws,
        ALLOC_JOIN: Act_log (
                      .Person = Opr_ws,
					  .Systime NOW,
                      .Txt = Ent_ftr_set.Trn_ref ));
	%End.
	Perform C300_ROUTE_AND_COMMIT thru C300_END.
B200_PROCESS_MSG_END.
	EXIT.

C300_ROUTE_AND_COMMIT.
	If Dbg_sw_ls = "Y"
		Display "C300 Commit"
	End-if.
	Call "MESSAGE_ROUTING" using
		by value 9
		by content Line_ws
		by content "PAY"
		by content "TRAP"
		by content Opr_ws                  %^ operator id
		by reference Memo_ws_length
		by reference Memo_ws
		by content "Y"
		by content "Y".
	If Dbg_sw_ls = "Y"
		Display "C300 after msg routing"
	End-if.

	Call "DAT_BREAK_MSG".
	%beg Commit: Tran; %end.
%^	%beg Cancel: Tran; %end.
	Call "LOCK_DEQ" using
	    By reference omitted
	    By value Long_zero_ws.
C300_END.
    EXIT.
	
X100_MAKE_ERR.
	Add 1 to Err_str_length.
	Move Err_msg(1:Err_msg_length) to Err_str(Err_str_length:).
	Add Err_msg_length to Err_str_length.
	If Err_str_length > 160
		Move 160 to Err_str_length
	End-if.
	Move Err_str to Err_str_ls.
X100_END.
	EXIT.
