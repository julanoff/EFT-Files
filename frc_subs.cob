%MODULE FRC_SUBS;
**********************************************************
* Copyright (c) 2016 Standard Chartered Bank             *
* Aug 2016           Standard Chartered Bank             *
* Author: J.Novak                                        *
**********************************************************
* Revisions.
* 8/10/16  JN   V1.0
* 02-Dec-2016	JN	SCB_20161203000636. Skip non acct FED from this process.
* 19-Mar-2017   JN  SCB_20161122010257. FED/CHP suspend process changes.
* 19-Sep-2017   JN  SCB_20170919170604. Determine if the TRN was thru PAYADV after the suspension. If it is then move the funds again.

%def            <ENTFTR>        %`SBJ_DD_PATH:ENTFTR_FSECT.DDL`         %end
%def            <ENTREPT>       %`SBJ_DD_PATH:ENTREPT_FSECT.DDL`        %end
%def            <ENT>           %`SBJ_DD_PATH:ENT_FSECT.DDL`            %end
%def            <ACE>           %`SBJ_DD_PATH:ACE_FSECT.DDL`            %end
%def			<ISI2>			%`SBJ_DD_PATH:ISI2_FSECT.DDL`			%end
%def 			<FTRSCRV>		%`SBJ_INCLUDE_PATH:FTRSCR.DEF`			%end


%def            <FRC_SUBS_WS>
Genq:							Que(	%`SBJ_DD_PATH:GEN_WORK_QUE.DDF`);
Pndq:                			Que(	%`SBJ_DD_PATH:SAF_PND_QUE.DDF`) scan_key = Ref_num;
Ref:					        Rec( 	%`SBJ_DD_PATH:TRN_ID_REC.DDF` );   
Opr_log:						Que(	%`SBJ_DD_PATH:OPR_ACTION_LOG.DDF`);
Line_log: 	 	                Que(	%`SBJ_DD_PATH:LINE_LOG.DDF`);
Save_ftr_set:					Set(%`SBJ_DD_PATH:FTR_SET.DDF`);
Save_debit_set:					Set(%`SBJ_DD_PATH:DEBIT_SET.DDF`);
Save_msg_union:					Set(%`SBJ_DD_PATH:MSG_UNION.DDF`);
Save_msg_history:				Seq(%`SBJ_DD_PATH:MSG_HISTORY_SEQ.DDF`);
Scan_msg_history:				Seq(%`SBJ_DD_PATH:MSG_HISTORY_SEQ.DDF`);
ComLine:						Vstr(12);
Q_name:							Vstr(12);
Err_str:						Vstr(160);
Err_msg:						Vstr(80);
Err_compose:					Compose;
Ret_status: 					Boolean;
Line_stat:						Boolean;
Ace_vstr_ws:    				Vstr(%`%ACE$_MSG_STR_SIZE`);
Bnk_key_ws: 					Str(3) = "SCB";
One_ws:							Word = <1>;
Chp_cnt:						Word = <0>;
Fed_cnt:						Word = <0>;
Chp_amt:						Amount;
Fed_amt:						Amount;
Status_memo:					Vstr(80);
BitVal:							Word;
Hist_memo_ws:					Vstr(80);	%^ memo for msg history
Tmp1:							Vstr(80);
Current_period_ws:				Time;
Func_mode_ws:					Str="OFP";

Is_rptv_lookup_wf:				Boolean;
Nochange_bank_wf:				Boolean;
Rtn_loc_bnk_change_wf:			Boolean;
Dbt_adr_status_wf:				Boolean;
Cdt_adr_status_wf:				Boolean;
Vdate_changed_wf:				Boolean;

%^ For creditdside lookup
C_ambig_flg_ws:					Boolean;
D_ambig_flg_ws:					Boolean;
Long_ambig_flg_ws:				Long = <1>;
Long_multibnk_ws:				Boolean;
Long_zero_ws:					Long = <0> ;
Cdt_2nd_idtype:					Str(1);
Cdt_2nd_id:						Vstr(132);
Cdt_Account_type_ws: 			Str(1) = "D";
Chips_qualified_ws:     		Boolean;
Dbt_Account_type_ws: 			Str(1);
Currency_code_ws:				Str(3);
Amount_ws:						Amount;
Dbt_Account_id_ws:				Rec(	%`SBJ_DD_PATH:ACC_ID_REC.DDF` ) ;
Cdt_Account_id_ws:				Rec(	%`SBJ_DD_PATH:ACC_ID_REC.DDF` ) ;
Lookup_Payment_ws:				Long = <1>;
Lock_dbt_party_ws:				Long = <1>;
Zero_long_ws:					Long = <0>;
One_long_ws:					Long = <1>;
Nochange_bank:					Long = <1>;
Qualify_chips_ws:       		Long = <0>;
Advice_parties_ws:      		Long;
Original_cdt_depth_ws:  		Long;
Second_credit_matched:  		Long; 
Dbt_full_parse_ws:				Boolean;
Long_full_parse_ws:				Boolean;
No_beneficiary_ws:				Boolean;
Errors_found_ws:				Long = <0>;
Debitside_status:				Boolean;
Msg_bank_changed:				Boolean;
Dbt_errors_found_ws:			Long = <0>;
Debit_completed:				Long = <0>;
Debit_internal_state:			Long = <0>;
Second_debit_matched:   		Long = <0>;
Nothing_suspicious:				Long = <0>;
Last_memo_ws:					Vstr(80);
Init_Debit_currency_ws:			Str(3);
Dbt_Amount_currency_ws: 		Str(3);
Cdt_Amount_currency_ws: 		Str(3);
Credit_fee_key_ws:				Str(1);
Debit_fee_key_ws:				Str(1);
Dbt_state_ws:					Long;
Dbt_account_curr_ws:			Str(3);
Cdt_account_curr_ws:			Str(3);
Party_rerun_ind_ws:				Str(6);
Save_Type_Code:					Str(4);
Xbank_account_ok:				Boolean;
Return_status:					Boolean;
Save_acc_idtype:				Str(1);
Save_acc_id:					Vstr(14);
Susp_log:						Vstr(14);
Pnd_qname:						Vstr(14);
Appl_name:						Vstr(10);
Memo_vstr:						Vstr(80);
Line_ind:						Str(3);

%End
	
%Macro Display_debug = 
If not match quotedstring($Msg_txt);
  then error 'Msg String required';
endif
Insert (
'	       If Dbg_sw_ls = "Y"'/
' 	      	Display ""'$Msg_txt'""'/
'   	   End-if'/ );
Endm

%Work
01  First_time	    			Pic X   Value "Y".
01  Pay_found				    Pic X   Value "N".
01  Sub							Pic 99.
01  CntD						Pic zzzzz9.
01  AmtD						Pic $$$,$$$,$$$.$$.

01  Tot_line1.	
		03 Filler				Pic X(25)		Value "Totals:   Chips Count - ".
		03 Cnt1					Pic X(6).
		03 Filler      			Pic X(13)		Value "   Amount - ".
		03 Amt1					Pic X(15).
01  Tot_line2.	
		03 Filler				Pic X(25)		Value "            Fed Count - ".
		03 Cnt2					Pic X(6).
		03 Filler       		Pic X(13)		Value "   Amount - ".
		03 Amt2					Pic X(15).
01	Str80						Pic X(80).

%Linkage
01  Mode_ls						Pic X.
01  Dbg_sw_ls					Pic X.
01  Err_str_ls					Pic X(160).
01  Ret_stat 					Pic S9(9) COMP-5.
	   88 FAILURE-IS VALUE 0.
	   88 SUCCESS-IS VALUE 1.

%Procedure Using Mode_ls Dbg_sw_ls Err_str_ls Returning Ret_stat.

A000_MAIN.

	Set Success_is in Ret_stat to true.
	Move Spaces to Err_str_ls.
	%Beg Err_str = ""; %End.
    CALL "DAT_CONN_ROOT_AND_MSG".

* Check if CHP/FED lines are up!
	%beg ComLine = "FEDIN1"; %end.
	Perform B150_check_line thru B150_end.
	%beg ComLine = "FEDOUT2"; %end.
	Perform B150_check_line thru B150_end.
	%beg ComLine = "CHIPSOUT1"; %end.
	Perform B150_check_line thru B150_end.
	%beg ComLine = "CHIPSOUT2"; %end.
	Perform B150_check_line thru B150_end.
	%beg ComLine = "CHIPSOUT3"; %end.
	Perform B150_check_line thru B150_end.
	%beg ComLine = "CHIPSIN1"; %end.
	Perform B150_check_line thru B150_end.
	%beg ComLine = "CHIPSIN2"; %end.
	Perform B150_check_line thru B150_end.
	%beg ComLine = "CHIPSIN3"; %end.
	Perform B150_check_line thru B150_end.

	Move Zeros to Chp_cnt, Fed_cnt, Chp_amt, Fed_amt.
    %Beg
		Break: Menu_bnk_union;
		Break: Menu_bnk_spec_seq;
		Bnk_Index ^First;
		Bnk_index KEY=Bnk_key_ws,
	    	^SEARCH CONN: Menu_bnk_union (NOMOD);
	%End.

	%ace_conn_q ////"AMT_INDEX" to Amt_index for Insert;.
	%ace_conn_root_q cur_frx_index;.

	%Beg 
		Susp_log = "FCS_SUSPD_LOG";
		Q_name = "FCS1_PNDQ";
		Appl_name = "TsaaS";
		BREAK: Menu_bnk_spec_seq;
		Menu_bnk_union(
						.Special_seq CONN: Menu_bnk_spec_seq(NOMOD) );
		Menu_bnk_spec_seq ^SEARCH (
			.Special_id(
			.Idbank = Menu_bnk_union.bnk_id,
			.Idkey = "FED CHP HOLDOVER" ) );
	%End.
	If Success_is in Menu_bnk_spec_seq_status
		%Beg
			Save_acc_idtype = Menu_bnk_spec_seq .Special_acc.Idtype;
			Save_acc_id = Menu_bnk_spec_seq .Special_acc.Idkey;
		%End
	Else  %^ Use OFAC Suspense acct
		%Beg
			Menu_bnk_spec_seq ^SEARCH (
					.Special_id(
		   			.Idbank = Menu_bnk_union.bnk_id,
		   			.Idkey = "OFAC SEIZED FUNDS" ) );
			Save_acc_idtype = Menu_bnk_spec_seq .Special_acc.Idtype;
			Save_acc_id = Menu_bnk_spec_seq .Special_acc.Idkey;
		%End
	End-if.
	%Display_debug "Doing FCS line"
	Move "FCS" to Line_ind.
	Perform B100_LOOP_THRU_APPS thru B100_END.

	%Beg 
		Susp_log = "PAI_SUSPD_LOG"; 
		Q_name = "PAI2_PNDDLVQ";
		Appl_name = "PAIMI";
		BREAK: Menu_bnk_spec_seq;
		Menu_bnk_union(
						.Special_seq CONN: Menu_bnk_spec_seq(NOMOD) );
		Menu_bnk_spec_seq ^SEARCH (
			.Special_id(
			.Idbank = Menu_bnk_union.bnk_id,
			.Idkey = "PA-IMI HOLDOVER AC" ) );
	%End.
	If Success_is in Menu_bnk_spec_seq_status
		%Beg
			Save_acc_idtype = Menu_bnk_spec_seq .Special_acc.Idtype;
			Save_acc_id = Menu_bnk_spec_seq .Special_acc.Idkey;
		%End
	Else
		%beg Err_compose ^Out(Err_msg) "FRC_SCAN: PA-IMI Holdover account does not exist. Exiting. ", /; %end
		Call "NEX_CREATE_AND_BROADCAST_MSG" USING
			by reference Err_msg,
			by value Err_msg_length,
			%ace_msg_arg_list("FRC_SCAN");
			Perform X100_make_err thru X100_end
			Set Failure_is in Ret_stat to true
			%exit program
	End-if.
	%Display_debug "Doing PAI line"
	Move "PAI" to Line_ind.
	Perform B100_LOOP_THRU_APPS thru B100_END.

	%Beg Q_name = "PAI3_PNDDLVQ"; %End.
	Perform B100_LOOP_THRU_APPS thru B100_END.

	Set Success_is in Ret_stat to true.
	Move Chp_cnt to CntD.
	Move Chp_amt to AmtD.
	Move CntD to Cnt1.
	Move AmtD to Amt1.
	Move Fed_cnt to CntD.
	Move Fed_amt to AmtD.
	Move CntD to Cnt2.
	Move AmtD to Amt2.
	Move Tot_line1 to Str80.
	Move Str80 to Err_str_ls.
	Move Tot_line2 to Str80.
	Move Str80 to Err_str_ls(81:).
%EXIT PROGRAM.

B100_LOOP_THRU_APPS.
	Set Success_is in Ret_stat to true.
	Move Spaces to Err_str_ls.
	%Beg Err_str = ""; %End.
	%Beg 
		Prm_pend_dlvack_qname = Q_name; 
		BREAK: Pndq;
		BREAK: Opr_log;
	%End.
	%ace_conn_q /<Bnk_key_ws>///<Q_name> to Pndq for Read_only;.
	%ace_conn_q /<Bnk_key_ws>///<Susp_log> to Opr_log for Insert;.
    If Failure_is IN Pndq_status
		%beg Err_compose ^Out(Err_msg) "FRC_SCAN: Cannot connect to ", Q_name, " Exiting. ", /; %end
		Call "NEX_CREATE_AND_BROADCAST_MSG" USING
			by reference Err_msg,
			by value Err_msg_length,
			%ace_msg_arg_list("FRC_SCAN");
			Perform X100_make_err thru X100_end
			Set Failure_is in Ret_stat to true
			%exit program
    End-if.
		
    %Beg Pndq ^First; %End.

	Perform B200_process_msg thru B200_process_msg_end until
		Seq_end_is in Pndq_cursor.

B100_END.
	Exit.

B150_CHECK_LINE.
	%ace_conn_q /<Bnk_key_ws>///<ComLine> to Line_log for Read_only;.
	If Failure_is IN Line_log_status
		%beg Err_compose ^Out(Err_msg) "FRC_SCAN: Cannot connect to ",ComLine, " line log. Exiting. ", /; %end
		Call "NEX_CREATE_AND_BROADCAST_MSG" USING
				by reference Err_msg,
				by value Err_msg_length,
				%ace_msg_arg_list("FRC_SCAN");
		Perform X100_make_err thru X100_end
		Set Failure_is in Ret_stat to true
  	  	%exit program
    End-if
    %beg Line_log ^Last; %end.
	%Beg BitVal = Line_log.Line_State.up; %End.
	If BitVal = 1
		%beg Err_compose ^Out(Err_msg) "FRC_SCAN: ", ComLine, " line is up. Must be DOWN. Exiting. ", /; %end
		Call "NEX_CREATE_AND_BROADCAST_MSG" USING
			by reference Err_msg,
			by value Err_msg_length,
			%ace_msg_arg_list("FRC_SCAN");
		Perform X100_make_err thru X100_end
		Set Failure_is in Ret_stat to true
  	  	%exit program
	End-if.
B150_END.
	Exit.

B200_PROCESS_MSG.
	%Display_debug "In B200"
	%Beg
		BREAK: Ent_msg_history;
        Ent_msg_history (NOMOD_WAIT, NOTRAP);
	   	Pndq  CONN: Ent_msg_history (MOD);
        Ret_status = Ent_msg_history status;
        Ent_msg_history(MOD_WAIT,ETRAP);
	%End.
	If ( Failure_is IN Ret_status)
		%Beg Tmp1 = Pndq.Ref_num; %End
		Display "!!!!!! Message: ", Tmp1(1:tmp1_length), " is locked by another process. Skipping."
		Call "DAT_BREAK_MSG"
		%beg Cancel: Tran; %end
		Go to B200_cont
	End-if.
	Call "DAT_CONN_MSG".
	If Dbg_sw_ls = "Y"
		Display "Msg props: " , Trn_ref of Ent_ftr_set, " tran type - ", Tran_type of typ of Ent_ftr_set, " src - ", Src_code of Ent_ftr_Set
	End-if.
	If 	( Tran_type of typ of Ent_ftr_set not = "FTR" and not = "DRW" and not = "CKS" ) or
		( Src_code of Ent_ftr_Set not = "CHP" and not = "FED" )
			Call "DAT_BREAK_MSG"
			%beg Cancel: Tran; %end
			Go to B200_cont
	End-if.
%^ Issue SCB_20161203000636. Omit non accounting FEDs from this process.
	If Src_code of Ent_ftr_Set = "FED" and 
	   (Incoming_msgtype of Ent_ftr_Set(3:2) = "31" or = "01" or = "07" )
		Call "DAT_BREAK_MSG"
		%beg Cancel: Tran; %end
		Go to B200_cont
	End-if.
	%Beg	%^ See if it is NOT suspended!! 
		BREAK: Scan_msg_history;
		Ent_msg_history EQUATE: Scan_msg_history(nomod);
		Scan_msg_history ^LAST;
		SCAN: Scan_msg_history(backward, eql, scan_key=Susp_log);
	%End.
	If Success_is in Scan_msg_history_status  %^ Already suspended?
%^ SCB_20170919170604. See if the TRN was thru payadv after that. If it was ( rejected by SWF or similar cancellation) we need to move $ to SFU hold acct again. 
        Move "N" to Pay_found
        Perform until Seq_end_is in Scan_msg_history_cursor or Pay_found = "Y"
                If Idname of Qname of Scan_msg_history = "PAYADV_LOG"
                    Move "Y" to Pay_found
				End-if
				%Beg Scan_msg_history ^Next; %End
		End-perform
		If Seq_end_is in Scan_msg_history_cursor  %^ TRN was not processed thru payadv. Don't touch!
			Call "DAT_BREAK_MSG"
			%beg Cancel: Tran; %end
			Go to B200_cont
		End-if
		%Display_debug "Suspended, Processed thru payadv. Move $s again."
	End-if.

%^ See if it is a posting message that we created here to move funds from CHP/FED to holdover acct
	If Cdt_id of Ent_credit_set(1:Save_acc_id_length) = Save_acc_id
			Call "DAT_BREAK_MSG"
			%beg Cancel: Tran; %end
			Go to B200_cont
	End-if.

	%Display_debug "Continue 1, After cust call"
	If Success_is in Ret_stat
		%Display_debug "Continue 2, call succeded"
		%Beg
		  Opr_log.systime now;
		  Err_compose ^Out(Memo_vstr) "Trn was suspended due to no timely response from ", Appl_name, /;
		  Alloc_end: Ent_msg_history  (mod,
		   .Qname (.idprod = null,
			    .idbank = Ent_ftr_set.loc_info.bank,
			    .idloc  = Ent_ftr_set.loc_info.loc,
			    .idcust = null,
			    .idname = Susp_log),
		   .Qtype  = "QTYP$_OPR_ACTION_LOG"
		   .Memo   =  Memo_vstr,
		    ALLOC_JOIN: Opr_log
			    ( .person = "$$$SUSP",
			      .Txt = Ent_ftr_set.Trn_ref ));
		%End

		If Src_code of Ent_ftr_Set = "FED"
			Add 1 to Fed_cnt
			Add Base_amount of Ent_ftr_set to Fed_amt
		End-if
		If Src_code of Ent_ftr_Set = "CHP"
			Add 1 to Chp_cnt
			Add Base_amount of Ent_ftr_set to Chp_amt
		End-if
	End-if.

	%Beg  %^ save dbt set
		BREAK: Save_debit_set;
		BREAK: Save_ftr_set;
		BREAK: Save_msg_union;
		BREAK: Save_msg_history;
		Ent_msg_union EQUATE: Save_msg_union (nomod);
		Ent_msg_history EQUATE: Save_msg_history (nomod);
		Ent_ftr_set EQUATE: Save_ftr_set (nomod);
		Ent_debit_set EQUATE: Save_debit_set (nomod);
	%End.
	Perform C400_move_fnds thru C400_end.
	Perform C300_commit thru C300_end.

B200_cont.
    %Beg Pndq ^Next; %End.

B200_PROCESS_MSG_END.
	EXIT.

C300_COMMIT.
	Call "DAT_BREAK_MSG".
	%beg
		BREAK: Save_msg_union;
		BREAK: Save_msg_history;
		BREAK: Save_ftr_set;
		BREAK: Save_debit_set;
	%end.
	%beg Commit: Tran; %end.
%^	%beg Cancel: Tran; %end.
	Call "LOCK_DEQ" using
	    By reference omitted
	    By value Long_zero_ws.
C300_END.
    EXIT.

C400_MOVE_FNDS.
	Call "DAT_BREAK_MSG".
	If Src_code of Save_ftr_set = "CHP"
		Call "DAT_ALLOC_MSG" using
			by value 0
			by content "CHP"
			by reference Bnk_key_ws
			by content "F"
	End-if.
	If Src_code of Save_ftr_set = "FED"
		Call "DAT_ALLOC_MSG" using
			by value 0
			by content "FED"
			by reference Bnk_key_ws
			by content "F"
	End-if.
	%Beg
	 	Current_period_ws Current_period;
		Ent_msg_union( mod,
		 .Msgtype FTR_MSG );
	
		Ent_ftr_set( mod,
		 .Src_code = Save_ftr_set.Src_code,
		 .Loc_info = Save_ftr_set.Loc_info,
		 .Incoming_msgtype = Save_ftr_set.Incoming_msgtype,
		 .Amount = Save_ftr_Set.Amount,
		 .Currency_code = Save_ftr_set.Currency_code,
		 .Typ.Tran_type = Save_ftr_set.Typ.Tran_type,
		 .Loc_info.Bank = Save_ftr_set.Loc_info.Bank,
		 .Base_amount = Save_ftr_set.Base_amount,
		 .Flgs.Stop_intercept_flg = "N",  %^ comment , the msg WILL go to tsaas.
		 .Prime_Send_date.Date_time = Current_period_ws );
	
		Ent_debit_set( mod,
			.Dbt_typ(       
			  .Dbt_ovr = Save_debit_set.Dbt_typ.Dbt_ovr,
			 	.Dbt_idtype = Save_debit_set.Dbt_typ.Dbt_idtype,
	 			.Dbt_id = Save_debit_set.Dbt_typ.Dbt_id),
		 .Dbt_book_date.Date_time = Current_period_ws,
%^		 .Dbt_account = Save_debit_set.Dbt_account,
		 .Dbt_rel_id = <0>,
		 .Dbt_value_date.Date_time = Current_period_ws );

		Ent_credit_set(mod, 
		 .Cdt_rel_id = <0>,
		 .Cdt_book_date.Date_time = Current_period_ws,
		 .Cdt_value_date.Date_time = Current_period_ws,
		 .Cdt_typ(
		 	.Cdt_idtype = Save_acc_idtype,
		 	.Cdt_id = Save_acc_id) );
%^				.Idkey = "3582427000840" ),  %^ CHP acct
%^				.Idkey = "3582059750600"			%^ FED acct
	%End.
	Set Success_is in C_ambig_flg_ws to true.
	Set Failure_is in Xbank_account_ok to true.
	Set Failure_is in Long_multibnk_ws to true. %^ = 0

	%Display_debug "before dbt call "
	If Dbt_ovr of Save_debit_set = "*"
		%Display_debug "NOF debit account "
		%Beg
			Ent_debit_set(
			 .Dbt_rel_id = Save_debit_set.Dbt_rel_id,
			 .Dbt_adr_bnk_id = Save_debit_set.Dbt_adr_bnk_id,
			 .Dbt_name1 = Save_debit_set.Dbt_name1,
			 .Dbt_name2 = Save_debit_set.Dbt_name2,
			 .Dbt_name3 = Save_debit_set.Dbt_name3,
			 .Dbt_name4 = Save_debit_set.Dbt_name4,
			 .Dbt_account = Save_debit_set.Dbt_account,
			 .Dbt_department = Save_debit_set.Dbt_department,
			 .Dbt_book_date.Date_time = Current_period_ws,
			 .Dbt_value_date.Date_time = Current_period_ws,
			 .Dbt_adr_type = Save_debit_set.Dbt_adr_type );
		%End
	Else
		Call "DEBITSIDE_LOOKUP" Using
			By Reference One_long_ws  %^C_ambig_flg_ws
			By Reference Long_multibnk_ws
			By Reference Currency_code_ws
			By Reference Cdt_2nd_id
			By Reference Cdt_2nd_id_length
			By Reference One_long_ws
			By Reference Xbank_account_ok
			By Reference Zero_long_ws  %^Notell_no_debit
			By Reference Zero_long_ws  %^Nochange_bank
			By Reference Zero_long_ws  %^Resume_SIs
			By Reference Amount_ws
			By Reference Currency_code_ws
			By Reference Dbt_account_id_ws
			By Reference One_long_ws %^Is_payment
			By Reference Cdt_Account_type_ws  %^Account_type is D
			By Reference Zero_long_ws  %^Is_repetitive_lookup
			By Reference Zero_long_ws  %^Lock_dbt_party
			By Reference Credit_fee_key_ws %^Special_fee_key
			By Reference Party_rerun_ind_ws
			By Reference Debit_completed
			By Reference Debit_internal_state
			By Reference Init_Debit_currency_ws %^Currency_found 
			By Reference Second_debit_matched
			By Reference Nothing_suspicious
			By Reference Msg_bank_changed
			By Reference Errors_found_ws %^Error_Memo_count
			By reference Last_memo_ws
			By reference Last_memo_ws_length
			Returning Return_status_ws

		If Failure_is in Return_status_ws
			Display "Debit acct not found"
		End-if
	End-if.

	Call "CREDITSIDE_LOOKUP" Using
			 By reference C_ambig_flg_ws
		     By reference Long_multibnk_ws 
		     By reference Currency_code_ws   
		     By reference Amount_ws
		     By reference Cdt_Amount_currency_ws
		     By reference Cdt_2nd_id
		     By reference Cdt_2nd_id_length	
	 	     By reference Cdt_Account_id_ws
		     By reference Lookup_Payment_ws	       
		     By reference One_long_ws	       
		     By reference Zero_long_ws	       
		     By reference Cdt_Account_type_ws
		     By reference Zero_long_ws	       
		     By reference Qualify_chips_ws          
		     By reference Zero_long_ws
		     By reference One_long_ws	       
		     By reference Credit_fee_key_ws
		     by Reference Party_rerun_ind_ws
%^--------End of common input arguments/Beginning of Debit_look_account args.
		     By reference Init_Debit_currency_ws
		     By reference Currency_code_ws   
		     By reference Dbt_account_id_ws
		     By reference Dbt_account_type_ws
		     By reference Nochange_bank
		     By reference Zero_long_ws
		     By reference Debit_fee_key_ws
		     By reference Dbt_state_ws
%^--------Return Values from Debit_look_account
			 By reference Dbt_full_parse_ws
		     By reference Debitside_status
		     By reference Msg_bank_changed
		     By reference Dbt_errors_found_ws
		     By reference Dbt_account_curr_ws
%^--------Return Values from Creditside Lookup
		     By reference Cdt_account_curr_ws
		     By reference Original_cdt_depth_ws  
			 By reference Advice_parties_ws     
		     By reference Chips_qualified_ws    
		     By reference Second_credit_matched 
		     By reference Long_full_parse_ws    
		     By reference No_beneficiary_ws
		     By reference Errors_found_ws
		     By reference Last_memo_ws
		     By reference Last_memo_ws_length
		  Returning Return_status.
	If Failure_is in Return_status 
		%Display_debug "Credit acct not found"
	End-if.
		
	Set Failure_is in Is_rptv_lookup_wf to true.
	Set Failure_is in Nochange_bank_wf to true.
	Set Failure_is in Rtn_loc_bnk_change_wf to true.
	Set Failure_is in Dbt_adr_status_wf to true.
	Set Failure_is in Cdt_adr_status_wf to true.

	Call "SET_CREDIT_ADDRESS" using
	 by reference Is_rptv_lookup_wf
	 returning Cdt_adr_status_wf.

	If Dbt_ovr of Save_debit_set not = "*"
		Call "SET_DEBIT_ADDRESS" using
		 by reference Is_rptv_lookup_wf
		 by reference Nochange_bank_wf
		 by reference Rtn_loc_bnk_change_wf
		 returning Dbt_adr_status_wf
	End-if.

	%Beg 
		BREAK: Ftrscr;
		ALLOC_TEMP: Ftrscr; 
	%End.
	Call "FTRSCR_EDITS" using Func_mode_ws	%^ Don't do "ENT" caller edits

	If Edits_passed_flg_ws = "F"
		Display "It has failed screen edits; Routing to Exc."
	End-if.
	If Mode_ls not = "S"
			Move "$$$IS2" to Opr_login_id of Menu_opr_union
	End-if.
	%Beg 
%^ Insert the TRN into AMT_INDEX for INQ purposes...
		Ent_ftr_set.amt_ndx_join ALLOC_JOIN : Amt_index (
			.Amount = Ent_ftr_set.Base_amount,
			.Txt = Ent_ftr_set.Trn_ref,
			.Value_date = Ent_ftr_set.Inst_date);
			
  		Err_compose ^Out(Hist_memo_ws) "TRN: ", Save_ftr_set.Trn_ref.Trn_date, "-", 
  			Save_ftr_set.Trn_ref.Trn_num, " suspended due to no same day ", Appl_name, " response." /; 
	%End.
	Call "MESSAGE_ROUTING" using
		 by value 9
		 by content "FCS"
		 by content "PAY"
		 by content "TRAP"
		 by content   "$$$FCS"			%^ operator id
		 by reference Hist_memo_ws_length
		 by reference Hist_memo_ws
		 by content "Y"
		 by content "Y".

	%Beg
       ALLOC_ELEM: Ent_msg_history (
                .Qname(.Idbank = Bnk_key_ws,
                       .Idloc = NULL,
                       .Idname= "*SYS_MEMO"),
                .Memo = Hist_memo_ws,
                .Qtype = "OBJTYP$_NULL");

		Err_compose ^Out(Hist_memo_ws) Line_ind,"-TRN: ", Ent_ftr_set.Trn_ref.Trn_date, "-", Ent_ftr_set.Trn_ref.Trn_num, " moved funds to holdover acct Day 1." /;

		ALLOC_END: Save_msg_history(mod,
		 .Qname(
			.Idbank = Bnk_key_ws, 
	  	.Idloc  = null,
	  	.Idname ="*SYS_MEMO"),
	 	.Qtype = "OBJTYP$_NULL",
	 	.Memo = Hist_memo_ws );
	%end.
C400_END.
	EXIT.

X100_MAKE_ERR.
	If Err_str_length > 160
			Go to X100_end
	End-if.
	If Err_str_length > 0
		Add 1 to Err_str_length
	End-if.
	Move Err_msg(1:Err_msg_length) to Err_str(Err_str_length:).
	Add Err_msg_length to Err_str_length.
	If Err_str_length > 160
		Move 160 to Err_str_length
	End-if.
	Move Err_str to Err_str_ls.
X100_END.
	EXIT.
