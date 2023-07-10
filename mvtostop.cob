%Module MVTOSTOP <main,no_ace_init>;
*
**********************************************************
* Copyright (c) 2016 Standard Chartered Bank             *
* Apr 2016           Standard Chartered Bank             *
* Author: J.Novak                                        *
**********************************************************
* This is an utility to move transaction from/to Firco / OFAC queues. 
* It performs routing using standard ACI routing table.
* 
* ******************************************************
* Revisions.
* 4/10/16  JN   V1.0
* 7/16/17  JN   SCB_20170715030537 Add ability to move msgs with case opened to specified queues.

%^ Subject definitions.
%def  		<ACE>			%`SBJ_DD_PATH:ACE_FSECT.DDL`		%end
%def  		<ENTFTR>		%`SBJ_DD_PATH:ENTFTR_FSECT.DDL`	%end
%def		<FTRSCRV>		%`SBJ_INCLUDE_PATH:FTRSCR.DEF`	%end
%def		<ENT>			%`SBJ_DD_PATH:ENT_FSECT.DDL`		%end
%def		<SWF_SUBS>		%`SBJ_DD_PATH:SWF_SUBS_FSECT.DDL`	%end
%def 		<ROUTE>			%`SBJ_DD_PATH:ROUTE_FSECT.DDL`	%end
%def		<MAPSHR>		%`SBJ_DD_PATH:MAPSHR_FSECT.DDL`	%end


%def		<MVTOSTOP_WS>	%^ local fsect
Pmtq:	 	       			QUE (%`SBJ_DD_PATH:GEN_WORK_QUE.DDF`);
Pmtq_qid:      				REC (%`SBJ_DD_PATH:PRIV_ITEM_REC.DDF`);
Admq:	 	       			QUE (%`SBJ_DD_PATH:GEN_WORK_QUE.DDF`);
Admq_qid:      				REC (%`SBJ_DD_PATH:PRIV_ITEM_REC.DDF`);
Genq:	 	       			QUE (%`SBJ_DD_PATH:GEN_WORK_QUE.DDF`);
Genq_qid:      				REC (%`SBJ_DD_PATH:PRIV_ITEM_REC.DDF`);
Genq1:	 	       			QUE (%`SBJ_DD_PATH:GEN_WORK_QUE.DDF`);
Genq1_qid:      			REC (%`SBJ_DD_PATH:PRIV_ITEM_REC.DDF`);
Pndq:	 	       			QUE (%`SBJ_DD_PATH:SAF_PND_QUE.DDF`);
Pndq_qid:      				REC (%`SBJ_DD_PATH:PRIV_ITEM_REC.DDF`);
Mv_que:			   			REC (%`SBJ_DD_PATH:PRIV_ITEM_REC.DDF`);
Scan_msg_history:			Seq(%`SBJ_DD_PATH:MSG_HISTORY_SEQ.DDF`);
Ace_vstr_ws:   				Vstr(%`%ACE$_MSG_STR_SIZE`);
Bnk_key_ws: 				Str(3);	%^ current bank if any
Ftr_mode_ws:				Str(3) = "MAP";
Null_ws:					Str(1) = "";
Q_name:						Vstr(12);
PmtQue:						Vstr(12);
AdmQue:						Vstr(12);
Bnk_name1:					Vstr(3);
Ret_status: 				Boolean;
Long_zero_ws:				Long = <0> ;
Mv_cnt:						Vstr(5);
Mv_cnt_l:					Long = <0> ;
Command_str_ws:				Str(3);
Function_str_ws:			Str(3);
Parsed_flag:				Str(1);
Case_sw:					Str(1);
Log_memo_ws:				Vstr(80);
Hist_memo_ws:		        Vstr(80);
Err_msg:					Vstr(80);
Err_compose:				Compose;

Mv_msg_currency:       	   	Str(3);
Mv_temp_bic:           	    Str(12);
Mv_swf_route_src:      	    Str(3);
Mv_compose:					Compose;
Mv_parse:					Parse;
Mv_union_key:          	    Rec (%`SBJ_DD_PATH:CFG_ID_REC.DDF`);
Mv_item_key:           	    Vstr(25);
Mv_seq_ordinal:        	    Word;
Mv_item_type:         		Vstr(16);
Mv_fake_bic:           	    Vstr(8);
Mv_match_key:         		Vstr(132);
Mv_message_type:       	    Str(3);
Mv_sender_bic:         	    Str(12);
Mv_receiver_branch:    	    Str(3);
Mv_message_currency:   	    Str(3);
Mv_receiver_type:      	    Str(1);
Mv_message_source:     	    Str(3);
Mv_message_bank:       	    Str(3);
Mv_message_codeword:   	    Str(10);
Mv_receiver_address:   	    Vstr(64);
Mv_first_key:         		Vstr(8);
Mv_matched_entry:      	    Boolean;
Mv_item_data:          	    Vstr(256);
Mv_entry_key:          	    Vstr(145) ;
Mv_entry_action:       	    Vstr(145) ;
Mv_routing_mode:       	    Vstr(3);
Mv_routing_command:    	    Vstr(3);
Mv_queue_id:           	    Vstr(72);
Mv_routing_idtype:     	    Vstr(1);
Mv_routing_id:         	    Vstr(64);
Mv_return_valve:       	    Vstr(1);
Mv_q_name:					Vstr(60);
Mv_cust_status:        	    Boolean;
Mv_dst_seq_conn:			Long;
Deb_sw:						Str(1);
Msg_command_ws:				Vstr(10);
Skip_susp:               	Str(1);
Skip_info:					Str(1);

%End

%Work
01  Match-count             PIC 9.
01  Move_cnt				Pic 9(5) 		Value 99999.
01  Trn_count				Pic 9(5)		Value Zeros.
01  Dv						Pic 9(4).
01  Rm 						Pic 9(2).
01  Fnd_sw					Pic X.
01 	Receiver_address  	    Pic X(64).
01 	Receiver_address_length	 %Length;
01 	Receiver_branch		    Pic X(3).
01 	Message_currency		Pic X(3).
01 	Receiver_type		    Pic X(1).
01 	Message_source		    Pic X(3).
01 	Message_bank		    Pic X(3).
01 	Message_codeword		Pic X(10).
01 	Routing_mode		    Pic X(3).
01 	Routing_command		    Pic X(3).
01 	Queue_id			    Pic X(72).
01 	Queue_id_length		    %Length;
01 	Routing_idtype		    Pic X(1).
01 	Routing_id		        Pic X(64).
01 	Routing_id_length		%Length;
01 	Return_valve_flg		Pic x(1).
01 	Error_memo		        Pic X(80).
01 	Error_memo_length		%Length;
01	Routing_table_status	%Boolean;

%Procedure.

A100_MAIN.
        Call "ACE_ARG_FIND" using
                 by content   "-he*lp",
                 by content   "U",
                 by value     %SIZ(Deb_sw),
                 by reference Deb_sw,
                 by reference Deb_sw_length,
                 by reference Ace_vstr_ws,
                 by reference Ace_vstr_ws_length,
              Returning Ret_status.

        If ( Success_is IN Ret_status)
			Display "    Move to Stop Matcher Utility.  "
			Display " This program is used to force unscanned messages thru the Stop Matcher "
			Display "   in case of the emergency failover from Firco back to ACI Stop Matcher."
			Display " -suspskip Y <---   will skip messages that are suspended (CHP/FED) till the next day"
			Display " -infoskip Y <---   will skip messages that received info from Firco"
			Display " -que   <--- is a queue name to be processed like FCS1_PNDQ" 
			Display " -bank  <--- is the bank's name like SCB "
			Display " -casemove  <--- will move msgs with case opened to specified queues "
			Display " -pmtq <--- queue to move payment msgs if casemove is Y"
			Display " -admq <--- queue to move admin msgs if casemove is Y"
			%Exit Program
		End-if.

		Display "Starting move to Stop matcher". 
		Move "N" to Deb_sw Skip_susp Skip_info Case_sw.
		Move Spaces to AdmQue, PmtQue.
        Call "ACE_ARG_FIND" using
                 by content   "-deb*ug",
                 by content   "U",
                 by value     %SIZ(Deb_sw),
                 by reference Deb_sw,
                 by reference Deb_sw_length,
                 by reference Ace_vstr_ws,
                 by reference Ace_vstr_ws_length,
              Returning Ret_status.

        If ( Success_is IN Ret_status)
        	Move "Y" to Deb_sw
		End-if.
		If Deb_sw = "Y"
				Display " DEBUG is ON for mvstop move"
		End-if.

        Call "ACE_ARG_FIND" using
                 by content   "-susp*skip",
                 by content   "U",
                 by value     %SIZ(Skip_susp),
                 by reference Skip_susp,
                 by reference Skip_susp_length,
                 by reference Ace_vstr_ws,
                 by reference Ace_vstr_ws_length,
              Returning Ret_status.

        If ( Success_is IN Ret_status)
        	Move "Y" to Skip_susp
				End-if.
				If Skip_susp = "Y"
					Display " Skipping suspended message is ON for mvstop move"
				End-if.
        Call "ACE_ARG_FIND" using
                 by content   "-info*skip",
                 by content   "U",
                 by value     %SIZ(Skip_info),
                 by reference Skip_info,
                 by reference Skip_info_length,
                 by reference Ace_vstr_ws,
                 by reference Ace_vstr_ws_length,
              Returning Ret_status.

        If ( Success_is IN Ret_status)
        	Move "Y" to Skip_info
		End-if.
		If Skip_info = "Y"
			Display " Skipping message with INFO only is ON for mvstop move"
		End-if.

        Call "ACE_ARG_FIND" using
                   by content   "-q*ueue_name",
                   by content   "U",
                   by value     %SIZ(Q_name),
                   by reference Q_name,
                   by reference Q_name_length,
                   by reference Ace_vstr_ws,
                   by reference Ace_vstr_ws_length,
                Returning Ret_status.

        If ( Failure_is IN Ret_status)
	 		%beg Err_compose ^Out(Err_msg) "MVTOSTOP: Incorrect Queue was specified. Exiting. ", /; %end
	 		Call "NEX_CREATE_AND_BROADCAST_MSG" USING
					by reference Err_msg,
					by value Err_msg_length,
					%ace_msg_arg_list("MVTOSTOP");
   			%exit program
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
	 		%beg Err_compose ^Out(Err_msg) "MVTOSTOP: Incorrect Bank was specified. Exiting. ", /; %end
	 		Call "NEX_CREATE_AND_BROADCAST_MSG" USING
					by reference Err_msg,
					by value Err_msg_length,
					%ace_msg_arg_list("MVTOSTOP");
   			%Exit program
        End-if.

		CALL "DAT_CONN_ROOT_AND_MSG".
        %beg
        	Bnk_key_ws = Bnk_name1;
			Break: Menu_bnk_union;
			Bnk_Index ^First;
			Bnk_index KEY=Bnk_name1,
		    ^SEARCH CONN: Menu_bnk_union (NOMOD);
		%end.

        Call "ACE_ARG_FIND" using
                 by content   "-case*move",
                 by content   "U",
                 by value     %SIZ(Case_sw),
                 by reference Case_sw,
                 by reference Case_sw_length,
                 by reference Ace_vstr_ws,
                 by reference Ace_vstr_ws_length,
              Returning Ret_status.

        If ( Success_is IN Ret_status)
        	Move "Y" to Case_sw
			Call "ACE_ARG_FIND" using
                 by content   "-pmt*q",
                 by content   "U",
                 by value     %SIZ(PmtQue),
                 by reference PmtQue,
                 by reference PmtQue_length,
                 by reference Ace_vstr_ws,
                 by reference Ace_vstr_ws_length,
              Returning Ret_status
			If ( Success_is IN Ret_status)
				%ace_conn_q /<Bnk_key_ws>///<PmtQue> To Pmtq With Optimization Giving Ret_status;
				If Failure_is in Ret_status
					%beg Err_compose ^Out(Err_msg) "MVTOSTOP: Incorrect Payment Queue was specified. Exiting. ", /; %end
					Call "NEX_CREATE_AND_BROADCAST_MSG" Using
						by reference Err_msg,
						by value Err_msg_length,
					%ace_msg_arg_list("MVTOSTOP");
					%Exit program
				End-if
			Else
				%beg Err_compose ^Out(Err_msg) "MVTOSTOP: Payment Queue was not specified. Exiting. ", /; %end
				Call "NEX_CREATE_AND_BROADCAST_MSG" Using
					by reference Err_msg,
					by value Err_msg_length,
				%ace_msg_arg_list("MVTOSTOP");
				%Exit program
			End-if
			Call "ACE_ARG_FIND" using
                 by content   "-adm*q",
                 by content   "U",
                 by value     %SIZ(AdmQue),
                 by reference AdmQue,
                 by reference AdmQue_length,
                 by reference Ace_vstr_ws,
                 by reference Ace_vstr_ws_length,
              Returning Ret_status

			If ( Success_is IN Ret_status)
				%ace_conn_q /<Bnk_key_ws>///<AdmQue> To Admq With Optimization Giving Ret_status;
				If Failure_is in Ret_status
					%beg Err_compose ^Out(Err_msg) "MVTOSTOP: Incorrect Admin Queue was specified. Exiting. ", /; %end
					Call "NEX_CREATE_AND_BROADCAST_MSG" Using
						by reference Err_msg,
						by value Err_msg_length,
					%ace_msg_arg_list("MVTOSTOP");
					%Exit program
				End-if
			Else
				%beg Err_compose ^Out(Err_msg) "MVTOSTOP: Admin Queue was not specified. Exiting. ", /; %end
				Call "NEX_CREATE_AND_BROADCAST_MSG" Using
					by reference Err_msg,
					by value Err_msg_length,
				%ace_msg_arg_list("MVTOSTOP");
				%Exit program
			End-if
		End-if.
		If Case_sw = "Y"
			Display " Moving msgs with case opened to " AdmQue, " ", PmtQue, " queues"
		End-if.

        Call "ACE_ARG_FIND" using
                 by content   "-coun*t",
                 by content   "U",
                 by value     %SIZ(Mv_cnt),
                 by reference Mv_cnt,
                 by reference Mv_cnt_length,
                 by reference Ace_vstr_ws,
                 by reference Ace_vstr_ws_length,
              Returning Ret_status.

        If ( Success_is IN Ret_status)
        	%Beg Mv_parse ^IN(Mv_cnt) Mv_cnt_l(^NUMBER); %End
			Move Mv_cnt_l to Move_cnt
		End-if.
		If Deb_sw = "Y"
			Display " Moving ", Move_cnt , " messages"
		End-if.

   		Move Zero to Match-count.
       	Inspect Q_name Tallying Match-count for all "PND".
        If Match-count = 0
       		Inspect Q_name Tallying Match-count for all "PEND"
        End-if.
        If Deb_sw = "Y"
        	DISPLAY "FOUND ", MATCH-COUNT, " OCCURRENCE(S) OF PNDQ IN"
        End-if.
        If Match-count > 0
	        %ace_conn_q /<Bnk_key_ws>///<q_name> To Pndq With Optimization Giving Ret_status;
        else
	        %ace_conn_q /<Bnk_key_ws>///<q_name> To Genq With Optimization Giving Ret_status;
		End-if.
		If Failure_is in Ret_status
	 		%beg Err_compose ^Out(Err_msg) "MVTOSTOP: Incorrect Queue was specified. Exiting. ", /; %end
	 		Call "NEX_CREATE_AND_BROADCAST_MSG" Using
					by reference Err_msg,
					by value Err_msg_length,
					%ace_msg_arg_list("MVTOSTOP");
   			%Exit program
		End-if.

        %Beg
			ALLOC_TEMP: Mapsh_wrp_que_seq(MOD) ;
			COMMIT_TEMP: Mapsh_wrp_que_seq ;
			Mv_union_key.Idname = "REPAIR_VERIFY_TABLES";
			Mv_seq_ordinal = <1>;

			Mv_item_key = "WRP_RPR_Q:";
			Mv_item_type = "VSTR(60)";
		%End

		Set Success_Is in Routing_table_status to TRUE
		Perform UNTIL (Failure_is in Routing_table_status )
			%^ Get the WRP repair queues.
				    Call "CFG_GET_ITEM" USING
				        BY Reference Idname of Mv_union_key
				        BY Reference Idprod of Mv_union_key
				        BY Reference Idbank of Mv_union_key
				        BY Reference Idloc of Mv_union_key
				        BY Reference Idcust of Mv_union_key
				        BY Reference Mv_item_key
				        By Reference Mv_seq_ordinal
				        By Reference Mv_item_type
				        By Reference Mv_item_data
				        By Reference Mv_item_data_length
				        By Reference Error_memo
				        By Reference Error_memo_length
			              RETURNING Routing_table_status
				    If (Success_Is in Routing_table_status)
							Add 1 to Mv_seq_ordinal
							%Beg
								Mv_parse ^IN(Mv_item_data)
					        "/", ^OPTION(^STRING),  "/", ^OPTION(^STRING),  "/",
									^OPTION(^STRING),  "/", Mv_q_name,
									"/", ^OPTION ("(", ^STRING, ")" ), /;
							%End
							If Success_is in Mv_parse_status then
							   %Beg ALLOC_END: Mapsh_wrp_que_seq(.wrpq_name = Mv_q_name ) ; %End
							End-if
				    END-IF
		End-perform.
		%Beg
			Mv_seq_ordinal = <1>;
			Mv_item_key = "WRP_EXC_Q:";
		%End.

		Set Success_Is in Routing_table_status to TRUE.
		Perform UNTIL (Failure_is in Routing_table_status )
		    Call "CFG_GET_ITEM" USING
			        BY Reference Idname of Mv_union_key
			        BY Reference Idprod of Mv_union_key
			        BY Reference Idbank of Mv_union_key
			        BY Reference Idloc of Mv_union_key
			        BY Reference Idcust of Mv_union_key
			        BY Reference Mv_item_key
			        By Reference Mv_seq_ordinal
			        By Reference Mv_item_type
			        By Reference Mv_item_data
			        By Reference Mv_item_data_length
			        By Reference Error_memo
			        By Reference Error_memo_length
		              RETURNING Routing_table_status
		    If (Success_Is in Routing_table_status)
				Add 1 to Mv_seq_ordinal
				%Beg
					Mv_parse ^IN(Mv_item_data)
	                	"/", ^OPTION(^STRING),  "/", ^OPTION(^STRING),  "/",
						^OPTION(^STRING),  "/", Mv_q_name,
						"/", ^OPTION ("(", ^STRING, ")" ), /;
				%End
				If Success_is in Mv_parse_status then
				   %Beg ALLOC_END: Mapsh_wrp_que_seq(.wrpq_name = Mv_q_name ) ; %End
				End-if
		    End-if
		End-perform.
		%Beg  BEG: Mapsh_wrp_que_seq(NOMOD );  %End.

		Perform B100_proc_msg thru B100_end.
		%Exit Program.

B100_PROC_MSG.
		If Match-count > 0
			%beg Pndq ^First; %end
			Perform until Seq_end_is in Pndq_cursor
				Add 1 to Trn_count
			   	%beg Pndq CONN: Ent_msg_history (mod); %end
				Perform B200_DO_MSG thru B200_DO_MSG_END
				If Trn_count > Move_cnt
					%Beg Pndq ^Last; %End
				End-if
				%beg Pndq ^next; %end
				DIVIDE Trn_count BY 100 GIVING Dv REMAINDER Rm
				If Rm = 0
					Display "Processed ", Trn_count, " trns from ", Q_name
				End-if
		   	End-perform
			%Beg BREAK: Pndq; %End
		Else
			%beg Genq ^First; %end
			Perform until Seq_end_is in Genq_cursor
				Add 1 to Trn_count
			   	%beg Genq CONN: Ent_msg_history (mod); %end
				Perform B200_DO_MSG thru B200_DO_MSG_END
				If Trn_count > Move_cnt
					%Beg Genq ^Last; %End
				End-if
				%beg Genq ^next; %end
				DIVIDE Trn_count BY 100 GIVING Dv REMAINDER Rm
				If Rm = 0
					Display "Processed ", Trn_count, " trns from ", Q_name
				End-if
		   	End-perform
		    %Beg BREAK: Genq; %End
		End-if.
B100_END.
		Exit.

B200_DO_MSG.
	   	Call "DAT_CONN_MSG".
		If Skip_susp = "Y"
			%Beg
				BREAK: Scan_msg_history;
				Ent_msg_history EQUATE: Scan_msg_history(nomod);
				Scan_msg_history ^LAST;
				SCAN: Scan_msg_history(backward, eql, scan_key="FCS_SUSPD_LOG");
			%End
			If Idname of Scan_msg_history = "FCS_SUSPD_LOG"		%^ the msg was suspended
			   	If Deb_sw = "Y"
					Display "Trn - ", trn_date of trn_ref of ent_ftr_set, "-", trn_num of trn_ref of ent_ftr_set, " - suspended/skipped"
				End-if
				Perform C360_cancel thru C360_cancel_end
				Go to B200_do_msg_end
			End-if
		End-if.
		If Skip_info = "Y"
			%Beg
				BREAK: Scan_msg_history;
				Ent_msg_history EQUATE: Scan_msg_history(nomod);
				Scan_msg_history ^LAST;
			%End
			If Idname of Scan_msg_history = "*SYS_MEMO" and 
				Memo of Scan_msg_history(1:3) is = "HIT"  %^ last memo from Firco ( only info )
				If Deb_sw = "Y"
					Display "Trn - ", trn_date of trn_ref of ent_ftr_set, "-", trn_num of trn_ref of ent_ftr_set, " - info_only/skipped"
				End-if
				Perform C360_cancel thru C360_cancel_end
				Go to B200_do_msg_end
			End-if
		End-if.

		If Case_sw = "Y"	%^ SCB_20170715030537 
%^ We are looking for  *SYS_MEMO         DECI-I-FMF USER DECISION: CASE
			%Beg
				BREAK: Scan_msg_history;
				Ent_msg_history EQUATE: Scan_msg_history(nomod);
				Scan_msg_history ^FIRST;
				SCAN: Scan_msg_history(forward, eql, scan_key="*SYS_MEMO");
			%End
			Perform until Seq_end_is in Scan_msg_history_cursor
				If Idname of Scan_msg_history = "*SYS_MEMO" and 
					Memo of Scan_msg_history = "DECI-I-FMF USER DECISION: CASE"
					If Deb_sw = "Y"
						Display "Trn - ", trn_date of trn_ref of ent_ftr_set, "-", trn_num of trn_ref of ent_ftr_set, " - case opened"
					End-if
					If Match-count > 0
						%beg
							Pndq(insert); 
							DELETE: Pndq; 
						%end
					Else
						%beg 
							Genq(insert);
							DELETE: Genq; 
						%end
					End-if
					If Tran_type of Ent_ftr_set = "FTR" or = "PRE" or = "IRS" or = "FFS" or = "FFR" or = "DEP" or = "DFT" 
							or = "DRW" or = "DFA" or = "CKS" or = "CKR"
						%Beg
							ALLOC_END: Ent_msg_history(mod,
								.Qname(
									.Idbank = "SCB",
									.Idname = PmtQue,
									.Idloc  = NULL),
								.Qtype  = "QTYP$_GEN_WORK_QUE", ALLOC_JOIN:
							Pmtq(insert,(
									.Trn = Ent_ftr_set.Trn_ref,
									.Memo = "Moved by MVSTOP",
									.Bnk_id = "SCB")));

							ALLOC_ELEM: Ent_msg_history (
								.Qname(.Idbank = "SCB",
								.Idloc = NULL,
								.Idname= "*SYS_MEMO"),
								.Memo = "Moved by MVSTOP",
								.Qtype = "OBJTYP$_NULL");
						%End
						Perform C350_commit thru C350_commit_end
					Else
						%Beg
							ALLOC_END: Ent_msg_history(mod,
								.Qname(
									.Idbank = "SCB",
									.Idname = AdmQue,
									.Idloc  = NULL),
								.Qtype  = "QTYP$_GEN_WORK_QUE", ALLOC_JOIN:
							Admq(insert,(
									.Trn = Ent_ftr_set.Trn_ref,
									.Memo = "Moved by MVSTOP",
									.Bnk_id = "SCB")));

							ALLOC_ELEM: Ent_msg_history (
								.Qname(.Idbank = "SCB",
								.Idloc = NULL,
								.Idname= "*SYS_MEMO"),
								.Memo = "Moved by MVSTOP",
								.Qtype = "OBJTYP$_NULL");
						%End
						Perform C350_commit thru C350_commit_end
					End-if
					Go to B200_do_msg_end
				End-if
				%Beg Scan_msg_history ^Next; %End
			End-perform
		End-if.
		
	   	Move "MAP" to Function_str_ws. 
	   	If Src_code of Ent_ftr_set = "LTR" or = "TRD" or = "FAX" or = "WIR"
		   	Move "ENT" to Function_str_ws
		End-if.
		If Src_code of Ent_ftr_set = "STO"
		   	Move "STO" to Function_str_ws
		End-if.
		If Src_code of Ent_ftr_set = "ADM"
		   	Move "ADE" to Function_str_ws
		End-if.
		If Src_code of Ent_ftr_set = "RTN"
		   	Move "VF1" to Function_str_ws
		End-if.
		Move spaces to Command_str_ws.
		If Deb_sw = "Y"
			Display "before Trn - ", trn_date of trn_ref of ent_ftr_set, "-", trn_num of trn_ref of ent_ftr_set, " - ", Stop_intercept_flg of ent_ftr_set, " STP - ", STRAIGHT_THRU_FLG of flgs2 of ent_ftr_set
		End-if.
		If Src_code of Ent_ftr_set = "DTP" or = "OTP" or = "ACB" or = "IVY"
		   	Move Src_code of Ent_ftr_set to Command_str_ws
			If Command_str_ws = "OTP"
				Move "DTP" to Command_str_ws
			End-if
		End-if.
		%beg 
			Ent_ftr_set (mod);
			Ent_ftr_set.Flgs.Stop_intercept_flg = " ";
			Ent_credit_set (mod);
			Ent_debit_set (mod);
			Ent_dst_seq (mod);
		%end.
		If Match-count > 0
			%beg
				Pndq(insert); 
				DELETE: Pndq; 
			%end
		Else
			%beg 
				Genq(insert);
				DELETE: Genq; 
			%end
		End-if.
		If Src_code OF Ent_ftr_set = "SWF" or = "CAL" or = "GMS"
			Perform D400_route_swf thru D400_End
			Move Routing_command to Command_str_ws
			If Incoming_msgtype of Ent_ftr_set = "210" and Command_str_ws = Spaces   %^ SCB_20161122200421
				Move "NUL" to Command_str_ws
				If Deb_sw = "Y"
					Display " 210 type Set to NUL", Incoming_msgtype of Ent_ftr_set
				End-if
			End-if
		End-if.
		If Queue_id not = SPACES and Queue_id_length > 0  %^ Que id found enq directly
			%Beg
			    Mv_parse ^IN(Mv_queue_id)
						^OPTION(Mv_que.Idbank
				       (^STRING(<CHAR$M_ALPHA!CHAR$M_NUMBER>))),
						"/", ^OPTION(Mv_que.Idloc
				       (^STRING(<CHAR$M_ALPHA!CHAR$M_NUMBER>))), ^SPACE,
						"/", ^OPTION(Mv_que.Idcust
				       (^STRING(<CHAR$M_ALPHA!CHAR$M_NUMBER>))), ^SPACE,
						"/", ^OPTION(Mv_que.Idprod
				       (^STRING(<CHAR$M_ALPHA!CHAR$M_NUMBER>))), ^SPACE,
						"/", Mv_que.Idname, ^SPACE, / ;
			%end
			IF Idbank of Mv_que = SPACES
			    %Beg  Mv_que.Idbank = Bnk_key_ws;  %End
			End-if
			%Beg
				BREAK: Mr_rout_cond_seq;
				ALLOC_TEMP: Mr_Rout_cond_seq (Mod, Init);
	            ALLOC_END: Mr_rout_cond_seq (
	            		.Rcs_route(.Rcs_Category 	= "SWFRTE/Q",
						.Rcs_Command  	= ""),
						.Rcs_addl_route (
						  .Rcs_type	= "ENQ",
						  .Rcs_queue (
								.Idbank =  Mv_que.Idbank,
							    .Idloc  =  Mv_que.Idloc,
							    .Idcust =  Mv_que.Idcust,
							    .Idprod =  Mv_que.Idprod,
							    .Idname =  Mv_que.Idname) ),
					      .Rcs_Routing_Str   		= "",
					      .Rcs_Rtg_Memo1	   		= "",
					      .Rcs_Rtg_Memo2	   		= "");
				Msg_command_ws = "$$$SWF";
				Mr_rout_cond_seq ^First;
		        Mr_rout_cond_seq.Rcs_routing_selected = "X";
	            UPDATE: Mr_rout_cond_seq;
	            Log_memo_ws = "Moved back STOP MATCHER for BCP";
				Mv_dst_seq_conn = Ent_dst_seq State.conn;
	        %End

			If (Mv_dst_seq_conn = 0 )
	    				%Beg  Ent_msg_union.dst_seq CONN: Ent_dst_seq;  %End
			End-if
						
	        Call "ROUTE_REQUEST" USING
	              by content	"MAP"
	     	      by reference 	Msg_command_ws 
	     	      by content	"ENQ"
	     	      by reference 	Log_memo_ws
	              by reference 	Log_memo_ws_length
	           Returning Ret_status
			Perform C350_commit thru C350_commit_end
			Display "Trn - ", trn_date of trn_ref of ent_ftr_set, "-", trn_num of trn_ref of ent_ftr_set, " was processed."
			Go to B200_DO_MSG_END
		End-if.
		If Tran_type of Typ of Ent_ftr_set = "FTR"
			Call "FTRSCR_EDITS" using by reference Ftr_mode_ws
			%Beg Break: Ftrscr; %End
			If Edits_Passed_Flg_Ws not = "T"
			    %beg
					Ent_ftr_set(mod, .Flgs2.Repair_chng_flg = "Y");
			    %end
			    If Deb_sw = "Y"
				    Display "Edit failed for TRN: ", trn_date of trn_ref of ent_ftr_set, "-", trn_num of trn_ref of ent_ftr_set
				End-if
			End-if
			Move STRAIGHT-THRU-FLG of flgs2 of ent_ftr_Set to Parsed_flag
		End-if.
		If Deb_sw = "Y"
			Display " Command_srt before msg routing call ", Command_str_ws, " src - ", Src_code OF Ent_ftr_set
		End-if.
		Call "MESSAGE_ROUTING" Using
			 by value     8		%^ number of parameters here
			 by reference Function_str_ws
			 by reference Command_str_ws
			 by content   "TRAP"			%^ Trap if no entry
			 by content   "$$$CMM"			%^ operator id
			 by reference Hist_memo_ws_length
			 by reference Hist_memo_ws
			 by reference Parsed_flag.
		Display "Trn - ", trn_date of trn_ref of ent_ftr_set, "-", trn_num of trn_ref of ent_ftr_set, " was processed.".
		Perform C350_commit thru C350_commit_end.
B200_DO_MSG_END.
 	Exit.
 	
C350_COMMIT.
		Call "DAT_BREAK_MSG".
%^		%beg Cancel: Tran; %end.
		%beg Commit: Tran; %end.
		Call "LOCK_DEQ" using
		    By reference omitted
		    By value Long_zero_ws.
C350_COMMIT_END.
    EXIT.

C360_CANCEL.
		Call "DAT_BREAK_MSG".
		%beg Cancel: Tran; %end.
		Call "LOCK_DEQ" using
		    By reference omitted
		    By value Long_zero_ws.
C360_CANCEL_END.
    EXIT.

D400_ROUTE_SWF.
		%Beg Ent_text_seq ^First; %end.
		Move "N" to Fnd_sw.
		Perform until Fnd_sw = "Y"
			If Txt of Ent_text_seq(1:3) = "{1:"
				Move Txt of Ent_text_seq to Swfs_Hdr_Line1
			End-if
			If Txt of Ent_text_seq(1:3) = "{2:"
				Move Txt of Ent_text_seq to Swfs_Hdr_Line2
				Move "Y" to Fnd_sw
			End-if
			%Beg Ent_text_seq ^Next; %end
			If Seq_end_is in Ent_text_seq_cursor
				Move "Y" to Fnd_sw
			End-if
		End-perform.
		Move 8 to Mv_fake_bic_length.
		%Beg Mv_msg_currency = Ent_ftr_set.currency_code; %End.
					
		If  Swfshl2m_in_branch of Swfshl2_Mir of Swfs_hdr_line2 Not = "XXX"
		    %Beg
									Mv_compose ^OUT(Mv_temp_bic)
							     Swfs_hdr_line2.Swfshl2_Mir.Swfshl2m_in_adr,
							     Swfs_hdr_line2.Swfshl2_Mir.Swfshl2m_in_tid,
							     Swfs_hdr_line2.Swfshl2_Mir.Swfshl2m_in_branch,/;
						    %End
					
		Else
						   %Beg
									Mv_compose ^OUT(Mv_temp_bic) ^TRAILING_BLANKS,
							     Swfs_hdr_line2.Swfshl2_Mir.Swfshl2m_in_adr,/;
						   %end
		End-if.
		If (Incoming_msgtype of Ent_Ftr_set = "300" or "304" or "392" or "398")
				        %Beg
							    Ent_msg_union.msgtype trade;
							    Ent_ftr_set.typ.tran_type = "TRA";
							    Mv_swf_route_src = "TRD";
						   %End
						Else
						   %Beg Mv_swf_route_src = Ent_ftr_set.src_code; %end
		End-if.
		%Beg
					    Mv_union_key.Idcust = "";
							Mv_union_key(.Idprod = "MTS",
								.Idname = "SWIFT_TELEX_TABLES" );
							Mv_item_key = "SWF_ROUTING_TABLE:";
							Mv_seq_ordinal = <1> ;
							Mv_item_type = "VSTR(145)";
		%End.
		Move Swfshl2_msg_type of Swfs_hdr_line2 to Mv_message_type.
		Move Mv_temp_bic To Mv_sender_bic.
		Move Swfshl1_out_adr of Swfshl1_address of Swfs_hdr_line1 to Mv_receiver_address.
		Move Mv_fake_bic_length to Mv_receiver_address_length.
		Move Swfshl1_out_branch of Swfshl1_address to Mv_receiver_branch.
		Move Mv_msg_currency to Mv_message_currency.
		Move Swfshl1_out_tid of Swfshl1_address of Swfs_hdr_line1 to Mv_receiver_type.
		Move Mv_swf_route_src to Mv_message_source.
		Move Bnk_key_ws to Mv_message_bank.
		Move Spaces to Mv_message_codeword.
		Move SPACES to Routing_command.
		Move SPACES to Queue_id.
		Move Zero to Queue_id_length.
		Move SPACE to Routing_idtype.
		Move SPACES to Routing_id.
		Move ZERO to Routing_id_length.
		Move SPACES to Return_valve_flg.
		Move SPACES to Error_memo.
		Move ZERO to Error_memo_length.
		%Beg
										Mv_compose ^OUT(Mv_match_key)
											"|", Mv_message_type, "|", Mv_sender_bic, "|",
											Mv_receiver_address, "|", Mv_receiver_branch, "|",
											Mv_message_currency, "|", Mv_receiver_type, "|",
											Mv_message_source, "|", Mv_message_bank, "|", Mv_message_codeword, / ;
										Mv_compose ^OUT(Mv_first_key)
											"|", Mv_message_type, "|", / ;
		%End.
		If Deb_sw = "Y"
			Display "Mv_match_key", Mv_match_key
		End-if.
		Set Failure_Is in Mv_matched_entry to TRUE.
		Perform UNTIL (Success_Is in Mv_matched_entry)
					    Call "CFG_MATCH_ITEM_CONT" USING
					        By Reference Idname of Mv_union_key
				          By Reference Idprod of Mv_union_key
					        By Reference Idbank of Mv_union_key
				          By Reference Idloc  of Mv_union_key
				          By Reference Idcust of Mv_union_key
					        By reference Mv_item_key
				   	      By Reference Mv_first_key
				          By Reference Mv_first_key_length
				      	  By Reference Mv_seq_ordinal
				          By Reference Error_memo
				          By Reference Error_memo_length
				              Returning Routing_table_status
					    If (Failure_Is in Routing_table_status)
					        %Exit program
					    END-IF
					    Call "CFG_GET_ITEM" Using
					        BY Reference Idname of Mv_union_key
					        BY Reference Idprod of Mv_union_key
					        BY Reference Idbank of Mv_union_key
					        BY Reference Idloc of Mv_union_key
					        BY Reference Idcust of Mv_union_key
					        BY Reference Mv_item_key
					        By Reference Mv_seq_ordinal
					        By Reference Mv_item_type
					        By Reference Mv_item_data
					        By Reference Mv_item_data_length
					        By Reference Error_memo
					        By Reference Error_memo_length
				              RETURNING  Routing_table_status
					    If (Failure_Is in Routing_table_status)
					        %EXIT PROGRAM
					    END-IF
					    %Beg
						    Mv_parse ^IN(Mv_item_data)
									Mv_entry_key, "||", Mv_entry_action, / ;
					    %End
					    If (Failure_Is in Mv_parse_status )
								Set Failure_Is in Routing_table_status to TRUE
								%Exit Program
					    End-if
					    CALL "NEX_MATCH_STRINGS" USING
								By Reference Mv_entry_key
								By Reference Mv_entry_key_length
								By Reference Mv_match_key
								By Reference Mv_match_key_length
						      RETURNING Mv_matched_entry
					    If (Failure_Is in Mv_matched_entry)
				%^ Try again with next table entry
								Add 1 to Mv_seq_ordinal
					    Else
								%Beg
									Mv_parse ^IN(Mv_entry_action)
										^SPACE, Mv_routing_mode, ^SPACE, "|",
										^SPACE, Mv_routing_command, ^SPACE, "|",
										^SPACE, Mv_queue_id, "|",
										^SPACE, Mv_routing_idtype, ^SPACE, "|",
										^SPACE, Mv_routing_id, ^SPACE, "|",
										^SPACE, Mv_return_valve, ^SPACE, "|", / ;
								%End
								Move Mv_parse_status to Routing_table_status
								If (Failure_Is in Routing_table_status)
							    	    %EXIT PROGRAM
								End-if
								Move Mv_parse_status to Mv_matched_entry
					    End-if
		End-perform.
				
		Perform UNTIL (Success_Is in Mv_matched_entry)
			
				    Call "CFG_MATCH_ITEM_CONT" USING
				        By Reference Idname of Mv_union_key
			                By Reference Idprod of Mv_union_key
				        By Reference Idbank of Mv_union_key
			                By Reference Idloc  of Mv_union_key
			                By Reference Idcust of Mv_union_key
				        By reference Mv_item_key
			   	        By Reference Mv_first_key
			                By Reference Mv_first_key_length
			      	        By Reference Mv_seq_ordinal
			                By Reference Error_memo
			                By Reference Error_memo_length
			              Returning Routing_table_status
				    If (Failure_Is in Routing_table_status)
			%^ We fell off the end of the table.
				        %Exit program
				    End-if
				    Call "CFG_GET_ITEM" Using
				        BY Reference Idname of Mv_union_key
				        BY Reference Idprod of Mv_union_key
				        BY Reference Idbank of Mv_union_key
				        BY Reference Idloc of Mv_union_key
				        BY Reference Idcust of Mv_union_key
				        BY Reference Mv_item_key
				        By Reference Mv_seq_ordinal
				        By Reference Mv_item_type
				        By Reference Mv_item_data
				        By Reference Mv_item_data_length
				        By Reference Error_memo
				        By Reference Error_memo_length
			              RETURNING  Routing_table_status
				    If (Failure_Is in Routing_table_status)
			%^ Should never happen
				        %Exit program
				    End-if
				    %Beg
				    	Mv_parse ^IN(Mv_item_data)
								Mv_entry_key, "||", Mv_entry_action, / ;
				    %End
				    If (Failure_Is in Mv_parse_status )
								Set Failure_Is in Routing_table_status to TRUE
								%Exit Program
				    END-IF
				    CALL "NEX_MATCH_STRINGS" Using
							By Reference Mv_entry_key
							By Reference Mv_entry_key_length
							By Reference Mv_match_key
							By Reference Mv_match_key_length
				      RETURNING Mv_matched_entry
				    If (Failure_Is in Mv_matched_entry)
			%^ Try again with next table entry
							Add 1 to Mv_seq_ordinal
				    Else
							%beg
								Mv_parse ^IN(Mv_entry_action)
									^SPACE, Mv_routing_mode, ^SPACE, "|",
									^SPACE, Mv_routing_command, ^SPACE, "|",
									^SPACE, Mv_queue_id, "|",
									^SPACE, Mv_routing_idtype, ^SPACE, "|",
									^SPACE, Mv_routing_id, ^SPACE, "|",
									^SPACE, Mv_return_valve, ^SPACE, "|", / ;
							%End
							Move Mv_parse_status to Routing_table_status
							If (Failure_Is in Routing_table_status)
				  	  	    %EXIT PROGRAM
							END-IF
							Move Mv_parse_status to Mv_matched_entry
				    END-IF
		End-perform.
			
		Call "CUST_SWF_RTE_MATCH" using
				   by reference Mv_routing_mode
				   by reference Mv_routing_command
				   by reference Mv_queue_id
				   by reference Mv_queue_id_length
				   by reference Mv_routing_idtype
				   by reference Mv_routing_idtype_length
				   by reference Mv_routing_id
				   by reference Mv_routing_id_length
				   returning Mv_cust_status.
			
		If (Mv_routing_mode_length NOT = 0 )
				    Move Mv_routing_mode to Routing_mode
				    If Deb_sw = "Y"
					    Display "Mv_routing_mode", Routing_mode
					  End-if
				End-if.
				If (Mv_routing_command_length NOT = 0 )
				    Move Mv_routing_command to Routing_command
				    If Deb_sw = "Y"
					    Display "Mv_routing_command",  Routing_command
					  End-if
		End-if.
		If (Mv_queue_id_length NOT = 0 )
				    Move Mv_queue_id to Queue_id
				    Move Mv_queue_id_length to Queue_id_length
						If Mv_queue_id = "////"  %^ for some reason slashes are there. That means no queue name
							Move Spaces to Queue_id
							Move Zeros to Queue_id_length
						End-if
				    If Deb_sw = "Y"
					    Display "queue_id", Queue_id
					  End-if
		End-if.
		If (Mv_routing_idtype_length NOT = 0 )
				    Move Mv_routing_idtype to Routing_idtype
		End-if.
		If (Mv_routing_id_length NOT = 0 )
				    Move Mv_routing_id to Routing_id
				    Move Mv_routing_id_length to Routing_id_length
		End-if.
D400_END.
		EXIT.
