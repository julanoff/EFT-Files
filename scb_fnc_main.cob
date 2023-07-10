%MODULE SCB_FNC_MAIN;
**********************************************************
* Copyright (c) 2016 Standard Chartered Bank        		 *
* Author: J.Novak					 *
**********************************************************
* Modification History.
* V1.0 3/27/16 J. Novak	Initial Version.
* V1.1 5/25/17 J. Novak  SCB_20170525015451  Validate entered TRN number.
* V1.2 6/12/17 J. Novak  SCB_20170613005725  Traps on FED returns.
* V1.3 7/7/19  J. Novak  Add Falcon/S2B release & verify capabilities.
* V1.4 6/16/20 J. Novak  Add realising operator ID to the memo field.
* V2.0 12/2/22 J. Novak  CASHVENDOR-13293 and CASHVENDOR-13383. Show MX incoming text.

%def 	<ACE>		 				%`SBJ_DD_PATH:ACE_FSECT.DDL`			%End
%def	<ENTFTR>	 				%`SBJ_DD_PATH:ENTFTR_FSECT.DDL`			%End
%def	<LINE_FS>	 				%`SBJ_DD_PATH:LINE_FS_FSECT.DDL`		%End
%def	<SCB_FNC>	 				%`SBJ_DD_PATH:SCB_FNC_FSECT.DDL`		%End
%def 	<FORMAT_SUB>				%`SBJ_DD_PATH:FORMAT_SUB_FSECT.DDL`  	%End
%def 	<PRINT_SUB>					%`SBJ_DD_PATH:PRINT_SUB_FSECT.DDL`   	%End
%def 	<MSGHIST>					%`SBJ_DD_PATH:MSGHIST_FSECT.DDL`     	%End

%def		<SCB_FNC_MAIN_WS>

%`SBJ_INCLUDE_PATH:SCB_FNC_SEL.DEF`	
%`SBJ_INCLUDE_PATH:SCB_FNC_RSND.DEF`	
%`SBJ_INCLUDE_PATH:SCB_FNC_FRCS.DEF`
%`SBJ_INCLUDE_PATH:SCB_FNC_CAN.DEF`	
%`SBJ_INCLUDE_PATH:SCB_FNC_PNDQ.DEF`	
%`SBJ_INCLUDE_PATH:SCBLIST_SCR.DEF`	
%`SBJ_INCLUDE_PATH:SCB_MSGPRINT.DEF`	
Cfgtyp_c_start_wc:		Str  = "CFGTYP$C_START";
Cfgtyp_c_length_wc:		Str  = "CFGTYP$C_LENGTH";
Opr_log:				QUE( %`SBJ_DD_PATH:OPR_ACTION_LOG.DDF`);
PndCmdq:                QUE( %`SBJ_DD_PATH:GEN_VSTR_INDEX.DDF`);
Scb_rsnd_set:			SEQ( %`SBJ_DD_PATH:SCB_FNC_RSND_SET.DDF`);
Scb_sel_seq:			SEQ( %`SBJ_DD_PATH:MENU_SUBFUNCTION_SEQ.DDF`);
Scb_pndq_sel:			SEQ( %`SBJ_DD_PATH:MENU_SUBFUNCTION_SEQ.DDF`);
Prt_vstr80_Text_Seq:	SEQ( %`SBJ_DD_PATH:DAT_TEXT_SEQ.DDF`);
Pndq_sum_seq:			SEQ( %`SBJ_DD_PATH:DAT_TEXT_SEQ.DDF`);
Tr_str:					REC( %`SBJ_DD_PATH:TRN_ID_REC.DDF` );
Ref1:					REC( %`SBJ_DD_PATH:TRN_ID_REC.DDF` ); 
Pndq:                	QUE( %`SBJ_DD_PATH:SAF_PND_QUE.DDF`) scan_key = Ref_num;
PndVfyq:               	QUE( %`SBJ_DD_PATH:SAF_PND_QUE.DDF`) scan_key = Ref_num;
L_log:                	QUE( %`SBJ_DD_PATH:LINE_LOG.DDF`);
Bnk_rpt_seq:			SEQ( %`SBJ_DD_PATH:SCBBFN_SEQ.DDF`);
Logical_pndq:			QUE( %`SBJ_DD_PATH:SAF_PND_QUE.DDF`) logical;

Parm_cli_present_sw:	Str(1);		%^ (I) "Y" or "N"
Parm_testkey_sw:		Str(20);	%^ (I) Module name
Msg_hist_arg:			Boolean;
Q_name:					Vstr(12);
Vfy_name:				Vstr(12);

Next_screen:			Oneof(Main_scr, Rsnd_scr, Frcs_scr, Can_scr, Uncan_scr, Canlst_scr, 
							Pndq_scr, Mondsp_scr, RlsFlc_scr, RlsS2B_scr, VfyFlc_scr, VfyS2B_scr);
Mark_mode:				Oneof ( mark, unmark);
Set_filter:				Oneof ( all_trns, dda, f20, trn);
Filter_arg:				Vstr(20);
Save_cursor:			Str(132);
Menu_xfr_vstr_ws:		Vstr(80);
Has_Priv_Ws:			Boolean;
Ret_status:				Boolean;
Trn_no:					Vstr(17);
Compose_ws:				Compose;
My_cmp: 				Compose;
Parse:					Parse;
Err_str:				Vstr(160);
Err_str1:				Vstr(80);
Err_str2:				Vstr(80);
No_ws:					Long;
Time_ws:				Time;
Del_bit:				Boolean;
Subject_status_ws:		Boolean;
Long_zero_ws:			Long = <0> ;
Mode_sw:				Str(1) = "S";
Rls_memo:				Vstr(60);
VfyCmd_key:				Vstr(80);
Tmp_ws:					Vstr(80);
Tmp_mem1:				Vstr(80);
Rls_opr:				Vstr(10);
%^ Fourth screen vars
Amt1:					Amount;
Cnt1:					Long;
Seq1:					SEQ( %`SBJ_DD_PATH:DAT_TEXT_SEQ.DDF`);
Amt2:					Amount;
Cnt2:					Long;
Seq2:					SEQ( %`SBJ_DD_PATH:DAT_TEXT_SEQ.DDF`);
Str80:					Vstr(80);
Str60:					Vstr(60);
Time_str_ws:        	Str(23);
Desc_ws:				Vstr(78);
Period_ws:      		Date;
Sel_date:				Str(8);
Dd_fil: 				Str(2);
Mm_fil: 				Str(3);
Cc_fil: 				Str(2);
Yy_fil: 				Str(2);
Tt_fil: 				Str(8);
Time_st: 				Str(18);
Timezone_bank_ws:       Str(3);
Timezone_time_ws:       time;
Time_delta_ws:          time;
Time_zone_ws:           Rec(
 Time_zone_code:        str(3);
 Time_zone_comma:       str(1);
 Time_zone_sign:        str(1);
 Time_zone_hours:       str(2);
 Time_zone_colon:       vstr(1);
 Time_zone_minutes:     vstr(2);
 Time_zone_filler:      vstr(30););
Title_pnd:				str(11);
Q_dspl:					vstr(11);
Xml_buf_ws:				vstr(100000);
%End

%Work
01  W_s					Pic 9	Value  1.
01  Send_scr			Pic X	Value "Y".
01  Want_out			Pic X	Value "N".
01  Frc_sw				Pic X	Value "N".
01  Dbg_sw				Pic X	Value "Y".
01 	Line_Upcase  		Pic X(12).
01	Q_Found				Pic X.
01	Info_sw				Pic X.
01  Seq_cnt				Pic 9(5).
01	Sub					Pic 9.
01  Stat_sw				Pic X.
01  Vfy_sw				Pic X	Value "V".
                    	
%Procedure.

A000_MAIN.
	Perform A100_initialize Thru A100_end.
	Set Main_scr in Next_screen to True.
	Move "Y" to Send_scr.
	Move 1 to W_s.
	Set ALL_TRNS in Set_filter to True.
	Perform until W_s = 0
	    Evaluate True
			When Main_scr in Next_screen
			    Perform B050_main_scr thru B050_end
			When Rsnd_scr in Next_screen
			   	Perform C050_Rsnd_scr thru C050_end
			When Frcs_scr in Next_screen
		    	Perform D050_Frcs_scr thru D050_end
			When Can_scr in Next_screen
				Set Mark in Mark_mode to True
		    	Perform E050_Frcs_scr thru E050_end
			When Uncan_scr in Next_screen
				Set Unmark in Mark_mode to True
		    	Perform E050_Frcs_scr thru E050_end
			When Canlst_scr in Next_screen
		    	Perform E060_Frcs_scr thru E060_end
			When Pndq_scr in Next_screen
		    	Perform F050_Frcs_scr thru F050_end
			When Mondsp_scr in Next_screen
		    	Perform G050_Frcs_scr thru G050_end
			When RlsFlc_scr in Next_screen
			When RlsS2B_scr in Next_screen
		    	Perform H050_Frcs_scr thru H050_end
			When VfyFlc_scr in Next_screen
			When VfyS2B_scr in Next_screen
		    	Perform I050_Frcs_scr thru I050_end
	    End-evaluate
	End-perform.
	Perform Z900_break_all thru Z900_end.
  	
	%Exit Program.
  		
A100_INITIALIZE.
%^ Make connections to the common domains
    CALL "DAT_CONN_ROOT_AND_MSG".

%^ Obtain passed menu subject connections and parameters
    CALL "MENU_RECEIVE".

	%Beg
%^ Clear subfunction sequence register.
	   	Save_cursor = null;
%^ Initialize passed menu arguments
	   	Menu_msg1 = null;
	  	Menu_msg2 = null;
	%End.   
			
A100_END.
    Exit.

A150_SET_MAIN_MENU.
	%Beg
	    Break: Scb_sel_seq;
	    ALLOC_TEMP: Scb_sel_Seq (mod);
%^ Set operator privilege flags.
    	Menu_Priv_Seq ^SEARCH (KEY = "ACELINU");
    	Has_Priv_Ws = Menu_Priv_Seq Status;
	%End.
		  
	If Success_is in Has_priv_ws
		%Beg
		    ALLOC_ELEM: Scb_sel_seq (
		       (   .Option = "SF1",
				   .Desc = "Resend Messages." ));
		%End
	End-if.

	%Beg
	  	Menu_Priv_Seq ^SEARCH (KEY = "MTSMOVSP");
	  	Has_Priv_Ws = Menu_Priv_Seq Status;
	%End.
	If Success_is in Has_priv_ws and Bnk_id of Menu_Bnk_Union = "SCB" %^ ONLY for US!
	  	%Beg
		    ALLOC_ELEM: Scb_sel_seq (
		       (   .Option = "SF2",
				   .Desc = "Move CHP/FED without TSaaS/PAIMI response to suspense acct." ));
		%End
	End-if.
	%Beg
	   	Menu_Priv_Seq ^SEARCH (KEY = "MTSCANCL");
	   	Has_Priv_Ws = Menu_Priv_Seq Status;
	%End.
	If Failure_is in Has_priv_ws and Bnk_id of Menu_Bnk_Union = "SCB" %^ Try CANEX,  Only for US
		%Beg
	    	Menu_Priv_Seq ^SEARCH (KEY = "MTSCANEX");
	  	  	Has_Priv_Ws = Menu_Priv_Seq Status;
		%End
	End-if.
	If Success_is in Has_priv_ws and Bnk_id of Menu_Bnk_Union = "SCB" %^ ONLY for US!
		%Beg
		    ALLOC_ELEM: Scb_sel_seq (
	  		     (  .Option = "SF3",
					.Desc = "Mark TRN waiting for TSaas/PAIMI response for interception." ));
		    ALLOC_ELEM: Scb_sel_seq (
	  		     (  .Option = "SF4",
					.Desc = "Unmark TRN waiting TSaas/PAIMI response from interception." ));
		    ALLOC_ELEM: Scb_sel_seq (
	  		     (  .Option = "SF5",
					.Desc = "List of TRNs marked for interception." ));
		%End
	End-if.

	%Beg
	    	Menu_Priv_Seq ^SEARCH (KEY = "MTSQUS");
	    	Has_Priv_Ws = Menu_Priv_Seq Status;
	%End.
	If Success_is in Has_priv_ws and Bnk_id of Menu_Bnk_Union = "SCB" %^ ONLY for US!
		%Beg
		    ALLOC_ELEM: Scb_sel_seq (
			       (   .Option = "SF6",
					   .Desc = "Display TSaaS Pending Queue Totals." ));
		%End
	End-if.
	If Success_is in Has_priv_ws and Bnk_id of Menu_Bnk_Union = "SCB" %^ ONLY for US!
		%Beg
		    ALLOC_ELEM: Scb_sel_seq (
			       (   .Option = "SF61",
					   .Desc = "Display PAIMI Pending Queue Totals." ));
		%End
	End-if.
	If Success_is in Has_priv_ws and Bnk_id of Menu_Bnk_Union = "SCB" %^ ONLY for US!
		%Beg
		    ALLOC_ELEM: Scb_sel_seq (
		       (   .Option = "SF7",
				   .Desc = "Monitor Auto Release Report." ));
		%End
	End-if.
%^ New stuff Falcon & S2B
	%Beg
	  	Menu_Priv_Seq ^SEARCH (KEY = "MTSFALSB");
	  	Has_Priv_Ws = Menu_Priv_Seq Status;
	%End.
	If Success_is in Has_priv_ws
		%Beg
		    ALLOC_ELEM: Scb_sel_seq (
			       (   .Option = "SF8",
					   .Desc = "Release messages from Falcon Pending Queue." ));
		%End
		%Beg
		    ALLOC_ELEM: Scb_sel_seq (
		       (   .Option = "SF9",
				   .Desc = "Release messages from S2B Pending Queue." ));
		%End
		%Beg
		    ALLOC_ELEM: Scb_sel_seq (
			       (   .Option = "SF10",
					   .Desc = "Verify release of msgs from Falcon Pending Queue." ));
		%End
		%Beg
		    ALLOC_ELEM: Scb_sel_seq (
		       (   .Option = "SF11",
				   .Desc = "Verify release of msgs from S2B Pending Queue." ));
		%End
	End-if.
	
	%Beg  Scb_sel_seq ^First (NOMOD);  %End.
A150_END.
	Exit.

B050_MAIN_SCR.
	If Send_scr = "Y"
		Perform B100_send_scr Thru B100_end
	Else
		Perform B200_reply_scr thru B200_end
	End-if.
	Evaluate True
		When ( Scr_status of Scb_fnc_sel = "ENTR")
			Evaluate Option of Scb_sel_seq
				When "SF1"		%^ Resend messages
					Perform B300_reject_scr thru B300_end
					Perform B400_break thru B400_end
					Set Rsnd_scr in Next_screen to True
					Move "Y" to Send_scr
				When "SF2"		%^ Move CHP/FED items without TSaaS response to suspense acct.
					Perform B300_reject_scr thru B300_end
					Perform B400_break thru B400_end
					Set Frcs_scr in Next_screen to True
					Move "Y" to Send_scr
				When "SF3"		%^ Mark TRN waiting for TSaas response for interception.
					Perform B300_reject_scr thru B300_end
					Perform B400_break thru B400_end
					Set Can_scr in Next_screen to True
					Move "Y" to Send_scr
				When "SF4"		%^ Unmark TRN waiting for TSaas response from interception.
					Perform B300_reject_scr thru B300_end
					Perform B400_break thru B400_end
					Set Uncan_scr in Next_screen to True
					Move "Y" to Send_scr
				When "SF5"		%^ List of TRNs marked for interception
					Perform B300_reject_scr thru B300_end
					Perform B400_break thru B400_end
					Set Canlst_scr in Next_screen to True
					Move "Y" to Send_scr
				When "SF6"		%^Display TSaaS Pending Queue Totals.
					Perform B300_reject_scr thru B300_end
					Perform B400_break thru B400_end
					Set Pndq_scr in Next_screen to True
					%Beg Title_pnd = "TSAAS_TITLE"; %End
					Move "Y" to Send_scr
				When "SF61"		%^Display PAIMI Pending Queue Totals.
					Perform B300_reject_scr thru B300_end
					Perform B400_break thru B400_end
					%Beg Title_pnd = "PAIMI_TITLE"; %End
					Set Pndq_scr in Next_screen to True
					Move "Y" to Send_scr
				When "SF7"		%^Monitor Auto Release Report.
					Perform B300_reject_scr thru B300_end
					Perform B400_break thru B400_end
					Set Mondsp_scr in Next_screen to True
					Move "Y" to Send_scr
				When "SF8"		%^ Release messages from Falcon Pending Queue.
					Perform B300_reject_scr thru B300_end
					Perform B400_break thru B400_end
					Set RlsFlc_scr in Next_screen to True
					Move "Y" to Send_scr
				When "SF9"		%^ Release messages from S2B Pending Queue.
					Perform B300_reject_scr thru B300_end
					Perform B400_break thru B400_end
					Set RlsS2b_scr in Next_screen to True
					Move "Y" to Send_scr
				When "SF10"  	%^ Verify release of msgs from Falcon Pending Queue.
					Perform B300_reject_scr thru B300_end
					Perform B400_break thru B400_end
					Set VfyFlc_scr in Next_screen to True
					Move "Y" to Send_scr
				When "SF11"  	%^Verify release of msgs from S2B Pending Queue.
					Perform B300_reject_scr thru B300_end
					Perform B400_break thru B400_end
					Set VfyS2b_scr in Next_screen to True
					Move "Y" to Send_scr
		    	When Other
					Move "N" to Send_scr
					Perform B200_reply_scr thru b200_end
			End-evaluate
		When (Scr_status of Scb_fnc_sel = "GOLDCANCEL" or
		      Scr_status of Scb_fnc_sel = "CMD_MENU")
			    CALL "MENU_PARSE" Using
					BY REFERENCE Cmdarg OF Scb_fnc_sel
					RETURNING Ret_status
				IF (Success_is in Ret_Status  )
					Perform B300_reject_scr thru B300_end
					Perform B400_break thru B400_end
					%Beg Menu_xfr_vstr_ws = Null;  %End
					Call "MENU_TRANSFER" using by reference Menu_xfr_vstr_ws
					Move Zeros to W_s
					Move "Y" to Send_scr
				Else
					%Beg Menu_msg1 = Menu_Errmsg; %End
					Move "N" to Send_scr
					Perform B200_reply_scr thru b200_end
		    	End-if
		When (Scr_status of Scb_fnc_sel = "TIMOUT")
		    	Perform B300_reject_scr thru B300_end
		    	Perform B400_break thru B400_end
		    	%Beg Menu_xfr_vstr_ws = "*TO*";  %End
		    	Call "MENU_TRANSFER" using by reference Menu_xfr_vstr_ws
		    	Move Zeros to W_s
		    	Move "Y" to Send_scr
	End-evaluate.
B050_END.
		Exit.

B100_SEND_SCR.	

%^ Allocate main menu selection sequence.
%^ If you want to add an extra special inquiry you need to add a new desc and
%^ option here. 
	Perform A150_set_main_menu thru A150_end.

%^ Break common menu screen subjects 
    %Beg
		BREAK: Scb_fnc_sel; 
		Err_str1 = Null;
		Err_str2 = Null;

%^ Allocate common menu screen subjects 
		ALLOC_TEMP: Scb_fnc_sel;

%^ Place cursor back on last selected menu option
		Scb_fnc_sel.Attributes.cursor_position = Save_cursor;	

%^ Initialize screen control set 
	  	Scb_fnc_sel(
			.Attributes.Clrta = T,
			.Fkeys (
		       .Entr.Enable = T,
		       .Goldcancel.Enable = T,
		       .Goldcancel.Noedit = T,
		       .Rlse.Enable = F,
		       .Timout.Enable = T,
		       .Timout.Noedit = T ),
			.Cmds (
		       .Cmd_menu.Enable = T,
		       .Cmd_menu.Noedit = T),
		 		.msg1 = Menu_Msg1,
		 		.msg2 = Menu_Msg2 
	    );

	    SEND: Scb_fnc_sel (
			.Menu_Bnk_Union send == Menu_Bnk_Union,
	  		.Spc_seq send == Scb_sel_seq );

    	Menu_msg1 = null;
    	Menu_msg2 = null;
   	%End.

B100_END.
    Exit.

B200_REPLY_SCR.	
    If (Menu_msg1 NOT = Spaces)
	   	%Beg
	       Scb_fnc_sel.Msg1 = Menu_msg1;
	       Menu_msg1 = null;
	   	%End
    End-if.

    If (Menu_msg2 NOT = Spaces)
	   	%Beg
	       Scb_fnc_sel.Msg2 = Menu_msg2;
	       Menu_msg2 = null;
	   	%End
    End-if.

    %Beg
	   	 REPLY: Scb_fnc_sel &;
	   	 REPLY: Menu_Bnk_Union &;
	   	 REPLY: Scb_sel_Seq;
	
	   	 Menu_msg1 = null;
	  	 Menu_msg2 = null;
    %End.
B200_END.
    Exit.

B300_REJECT_SCR.
    %Beg
	    Scb_fnc_sel(
			.Msg1 = null,
			.Msg2 = null );
	    Save_cursor = Scb_fnc_sel.Attributes.Cursor_position;
		Menu_msg1 = null;
		Menu_msg2 = null;
    %End.
B300_END.
    Exit.

B400_BREAK.
	%Beg
		   BREAK: Bnk_spec_set(init);
		   BREAK: Bnk_spec_seq;
		   BREAK: Scb_Sel_Seq;
		   BREAK: Scb_fnc_sel; 
	%End.
B400_END.
    Exit.

* Resend message
C050_RSND_SCR.
	If Send_scr = "Y"
		Perform C100_send_scr Thru C100_end
	Else
		Perform C200_reply_scr thru C200_end
	End-if.
	Evaluate True
		When (Scr_status of Scb_fnc_rsnd = "CMD_FRC")
			Move "Y" to Frc_sw
		When ( Scr_status of Scb_fnc_rsnd = "ENTR")
* check for validity and call to resend
			If Trn_mode of Scb_rsnd_set = "T"
				%Beg Compose_ws ^OUT(Trn_no) Scb_rsnd_set.Trn_date, "-", Scb_rsnd_set.Trn_num, /; %End
			Else
				Move Spaces to Trn_no
			End-if
			Move FUNCTION UPPER-CASE(Line_name of Scb_rsnd_set) to Line_Upcase
			Call "RSNDMSGS_SUBS"  Using Bnk_id of Menu_Bnk_Union Period1 of Scb_rsnd_set Line_Upcase Trn_no Beg_seq of Scb_rsnd_set End_seq  of Scb_rsnd_set Frc_sw Dbg_sw Err_str RETURNING Ret_status
			Move 160 to Err_str_length
			Perform until Err_str(Err_str_length:1) not = Space or Err_str_length = 0
				Subtract 1 from Err_str_length
			End-perform
			If Err_str_length < 80
				%Beg Menu_msg1 = Err_str; %End
			Else
				Move Err_str(1:80) to Err_str1
				Move 80 to Err_str1_length
				Move Err_str(81:) to Err_str2
				Subtract 80 from Err_str_length giving Err_str2_length
				%Beg 
					Menu_msg1 = Err_str1; 
					Menu_msg2 = Err_str2; 
				%End
			End-if

		When (Scr_status of Scb_fnc_rsnd = "GOLDCANCEL")
			Set Main_scr in Next_screen to True
			Perform C300_reject_scr thru C300_end
			Perform C400_break thru C400_end
			Move "Y" to Send_scr

		When (Scr_status of Scb_fnc_rsnd = "CMD_MENU")
			CALL "MENU_PARSE" Using BY REFERENCE Cmdarg OF Scb_fnc_rsnd RETURNING Ret_status
			IF (Success_is in Ret_Status  )
				Perform C300_reject_scr thru C300_end
				Perform C400_break thru C400_end
				%Beg Menu_xfr_vstr_ws = Null;  %End
				Move "Y" to Send_scr
				Move Zeros to W_s
				Call "MENU_TRANSFER" using by reference Menu_xfr_vstr_ws
			Else
				%Beg  Menu_msg1 = Menu_Errmsg;  %End
				Move "N" to Send_scr
				Perform C200_reply_scr thru C200_end
		    End-if

		When (Scr_status of Scb_fnc_rsnd = "TIMOUT")
			Perform C300_reject_scr thru C300_end
			Perform C400_break thru C400_end
			%Beg Menu_xfr_vstr_ws = "*TO*";  %End
			Call "MENU_TRANSFER" using by reference Menu_xfr_vstr_ws
		  	Move Zeros to W_s
			Move "Y" to Send_scr
	End-evaluate.

C050_END.
	Exit.
		
* Second screen performs
C100_SEND_SCR.	
%^ Break common menu screen subjects 
    %Beg
		BREAK: Scb_fnc_rsnd;
		BREAK: Scb_rsnd_set;
		Err_str1 = Null;
		Err_str2 = Null;

%^ Allocate common menu screen subjects 
		ALLOC_TEMP: Scb_fnc_rsnd;
		ALLOC_TEMP: Scb_rsnd_set(mod);
		Scb_rsnd_set (
			.Line_name = "",
			.Beg_seq = "",
			.End_seq = "",
			.Period1 = "",
		  	.Trn_mode = "",
		  	.Trn_date = "",
		   	.Trn_num = "" 
		);

%^ Place cursor back on last selected menu option
		Scb_fnc_rsnd.Attributes.cursor_position = Save_cursor;	
		Scb_fnc_rsnd.Attributes.Disp_only = F;

 %^ Initialize screen control set 
	  	Scb_fnc_rsnd(
			.Attributes.Clrta = T,
			.Fkeys (
		       .Entr.Enable = T,
		       .Goldcancel.Enable = T,
		       .Goldcancel.Noedit = T,
		       .Rlse.Enable = F,
		       .Timout.Enable = T,
		       .Timout.Noedit = T ),
			.Cmds (
		       .Cmd_frc.Enable = T,
		       .Cmd_frc.Noedit = T,
		       .Cmd_menu.Enable = T,
		       .Cmd_menu.Noedit = T),
		    .sel_rec.line_name.cursor = T,
		    .sel_rec.line_name.bold = T,
		 	.msg1 = Menu_Msg1,
		 	.msg2 = Menu_Msg2 
		);

		SEND: Scb_fnc_rsnd (
			.Menu_Bnk_Union send == Menu_Bnk_Union,
			.Sel_rec send == Scb_rsnd_set );

	    Menu_msg1 = null;
	    Menu_msg2 = null;
    %End.

C100_END.
    Exit.

C200_REPLY_SCR.	
    If (Menu_msg1 NOT = Spaces)
	   	%Beg
	       Scb_fnc_rsnd.Msg1 = Menu_msg1;
	       Menu_msg1 = null;
	  	%End
    End-if.

    If (Menu_msg2 NOT = Spaces)
	   	%Beg
	       Scb_fnc_rsnd.Msg2 = Menu_msg2;
	       Menu_msg2 = null;
	   	%End
    End-if.

    %Beg
	   	REPLY: Scb_fnc_rsnd &;
	   	REPLY: Menu_Bnk_Union &;
	   	REPLY: Scb_rsnd_set;
	
	   	Menu_msg1 = null;
	  	Menu_msg2 = null;
    %End.
C200_END.
    Exit.

C300_REJECT_SCR.
    %Beg
	    Scb_fnc_rsnd(
			.Msg1 = null,
			.Msg2 = null );
	    Save_cursor = Scb_fnc_rsnd.Attributes.Cursor_position;
		Menu_msg1 = null;
		Menu_msg2 = null;
    %End.
C300_END.
    Exit.

C400_BREAK.
	%Beg
	   BREAK: Scb_rsnd_Set;
	   BREAK: Scb_fnc_rsnd; 
	%End.
C400_END.
    Exit.

* Move CHP/FED items without TSaaS response to suspense acct.
D050_FRCS_SCR.
	If Send_scr = "Y"
		Perform D100_send_scr Thru D100_end
	Else
		Perform D200_reply_scr thru D200_end
	End-if.
	Evaluate True
		When ( Scr_status of Scb_fnc_frcs = "RLSE")
			Call "FRC_SUBS"  Using Mode_sw Dbg_sw Err_str RETURNING Ret_status
			If ( Failure_is IN Ret_status)
				Move Err_str(1:80) to Err_str1
				Move 80 to Err_str1_length
			Else
				Move Err_str(1:80) to Err_str1
				Move 80 to Err_str1_length
				Move Err_str(81:) to Err_str2
				Subtract 80 from Err_str_length giving Err_str2_length
			End-if
			%Beg 
				Menu_msg1 = Err_str1; 
				Menu_msg2 = Err_str2; 
			%End
		When (Scr_status of Scb_fnc_frcs = "GOLDCANCEL")
			Set Main_scr in Next_screen to True
			Perform D300_reject_scr thru D300_end
			Perform D400_break thru D400_end
			Move "Y" to Send_scr

		When (Scr_status of Scb_fnc_frcs = "CMD_MENU")
			CALL "MENU_PARSE" Using BY REFERENCE Cmdarg OF Scb_fnc_frcs RETURNING Ret_status
			IF (Success_is in Ret_Status  )
				Perform D300_reject_scr thru D300_end
				Perform D400_break thru D400_end
				%Beg Menu_xfr_vstr_ws = Null;  %End
				Move "Y" to Send_scr
				Move Zeros to W_s
				Call "MENU_TRANSFER" using by reference Menu_xfr_vstr_ws
			Else
				%Beg  Menu_msg1 = Menu_Errmsg;  %End
				Move "N" to Send_scr
				Perform D200_reply_scr thru D200_end
		    End-if
		When (Scr_status of Scb_fnc_frcs = "TIMOUT")
	    	Perform D300_reject_scr thru D300_end
	    	Perform D400_break thru D400_end
	    	%Beg Menu_xfr_vstr_ws = "*TO*";  %End
	    	Call "MENU_TRANSFER" using by reference Menu_xfr_vstr_ws
	    	Move Zeros to W_s
			Move "Y" to Send_scr
	End-evaluate.

D050_END.
	Exit.

* Third  screen performs
D100_SEND_SCR.	
%^ Break common menu screen subjects 
    %Beg
		BREAK: Scb_fnc_frcs;
		Err_str1 = Null;
		Err_str2 = Null;

%^ Allocate common menu screen subjects 
		ALLOC_TEMP: Scb_fnc_frcs;

 %^ Initialize screen control set 
	  	Scb_fnc_frcs(
			.Attributes.Clrta = T,
			.Fkeys (
		       .Rlse.Enable = T,
		       .Goldcancel.Enable = T,
		       .Goldcancel.Noedit = T,
		       .Timout.Enable = T,
		       .Timout.Noedit = T ),
			.Cmds (
		       .Cmd_menu.Enable = T,
		       .Cmd_menu.Noedit = T),
			.msg1 = Menu_Msg1,
			.msg2 = Menu_Msg2 
		);

		SEND: Scb_fnc_frcs (
			.Menu_Bnk_Union send == Menu_Bnk_Union );

	    Menu_msg1 = null;
	    Menu_msg2 = null;
    %End.

D100_END.
    Exit.

D200_REPLY_SCR.	
    If (Menu_msg1 NOT = Spaces)
		%Beg
	       Scb_fnc_frcs.Msg1 = Menu_msg1;
	       Menu_msg1 = null;
	   	%End
    End-if.

    If (Menu_msg2 NOT = Spaces)
		%Beg
			Scb_fnc_frcs.Msg2 = Menu_msg2;
			Menu_msg2 = null;
	   	%End
    End-if.

    %Beg
	  	REPLY: Scb_fnc_frcs &;
	   	REPLY: Menu_Bnk_Union ;
	
	   	Menu_msg1 = null;
	  	Menu_msg2 = null;
    %End.
D200_END.
    Exit.

D300_REJECT_SCR.
    %Beg
	    Scb_fnc_frcs(
			.Msg1 = null,
			.Msg2 = null );
	    Save_cursor = Scb_fnc_frcs.Attributes.Cursor_position;
		Menu_msg1 = null;
		Menu_msg2 = null;
    %End.
D300_END.
    Exit.

D400_BREAK.
	%Beg BREAK: Scb_fnc_frcs; %End.
D400_END.
    Exit.

* Mark/Unmark TRN waiting for TSaas response for interception.
E050_FRCS_SCR.
	If Send_scr = "Y"
		Perform E100_send_scr Thru E100_end
	Else
		Perform E200_reply_scr thru E200_end
	End-if.
	Evaluate True
		When ( Scr_status of Scb_fnc_can = "ENTR")
* check for validity and call to resend
			%Beg Compose_ws ^OUT(Trn_no) Scb_rsnd_set.Trn_date, "-", Scb_rsnd_set.Trn_num, /; %End
			Move Err_str(1:80) to Err_str1
			Move 80 to Err_str1_length
			%Beg
				No_ws = <0>;
				Parse (^notrap) ^IN(Scb_rsnd_set.Trn_num) No_ws(^NUMBER);
				Compose_ws ^OUT(Ref1.Trn_num) No_ws(^LEADING_ZEROS, ^NUM<8>);
				Ref1.Trn_date = Scb_rsnd_set.Trn_date;
				BREAK: Ent_msg_history;
				Ref_index ^SEARCH (forward, eql, Key = Ref1);
			%End
			Move 1 to sub		%^ SCB_20170525015451
			Perform until Sub > 8
				If Trn_num of Scb_rsnd_set(sub:1) not numeric and 
				   Trn_num of Scb_rsnd_set(sub:1) not = Space
					Set Failure_is in Ref_index_status to true
					Move 8 to sub
				End-if
				Add 1 to Sub
			End-perform
			If Success_is in Ref_index_status
				%Beg
					Ref_index CONN: Ent_msg_history(NOMOD);
					Ent_msg_history ^First;
				%End
				Perform E150_call_format thru E150_end
			Else
				%Beg Compose_ws ^Out(Err_str1) "TRN ", Trn_no, " not found. ", /; %End
			End-if
			%Beg 
				Menu_msg1 = Err_str1; 
				Menu_msg2 = Err_str2; 
			%End

		When (Scr_status of Scb_fnc_can = "CMD_CANCEL")
		When (Scr_status of Scb_fnc_can = "CMD_UNMARK")
			%Beg 
				Ent_msg_history (NOMOD_WAIT, NOTRAP);
				Ent_msg_history(MOD);
				Ret_status = Ent_msg_history status;
				Ent_msg_history(MOD_WAIT,ETRAP);
			%End
			If ( Failure_is IN Ret_status)
				Move "Message is in use. Cannot get MOD access, try again later." to Err_str1
				Move 80 to Err_str1_length
			Else
				%Beg
					BREAK: Ent_msg_union;
					BREAK: Ent_ftr_set;
					Ent_msg_history (mod,notrap,
							TOP: Ent_msg_union(notrap,nomod,
								.Ftr CONN: Ent_ftr_set(notrap,mod) ) );
					Compose_ws ^Out(Err_str1) Scb_fnc_can.Cmdarg, " by ",  Menu_opr_union.Opr_login_id, ".", /;
					ALLOC_END: Ent_msg_history(
						.Qname(
						  .Idbank = null, 
						  .Idloc  = null,
						  .Idname ="*SYS_MEMO"),
						 .Qtype = "OBJTYP$_NULL",
						 .Memo = Err_str1 );
				%End
				Evaluate True
					When ( Mark in Mark_mode)
						%Beg 
							Ent_ftr_set.Flgs4.Cancelled_flag="Y";
							Compose_ws ^Out(Err_str1) "TRN - ", Trn_no, " is marked for interception", /;
						%End
					When ( Unmark in Mark_mode)
						%Beg 
							Ent_ftr_set.Flgs4.Cancelled_flag=""; 
							Compose_ws ^Out(Err_str1) "TRN - ", Trn_no, " is unmarked for interception", /; 
						%End
				End-evaluate
				Call "DAT_BREAK_MSG"
				%Beg Commit: Tran; %End
				%^	%Beg Cancel: Tran; %End
				Call "LOCK_DEQ" using
					By reference omitted
					By value Long_zero_ws
			End-if
			%Beg 
				Menu_msg1 = Err_str1; 
				Menu_msg2 = Err_str2; 
			%End
			Move "Y" to Send_scr

		When (Scr_status of Scb_fnc_can = "GOLDCANCEL")
			Set Main_scr in Next_screen to True
			Perform E300_reject_scr thru E300_end
			Perform E400_break thru E400_end
			Move "Y" to Send_scr

		When (Scr_status of Scb_fnc_can = "CMD_MENU")
			CALL "MENU_PARSE" Using BY REFERENCE Cmdarg OF Scb_fnc_can RETURNING Ret_status
			If (Success_is in Ret_Status  )
				Perform E300_reject_scr thru E300_end
				Perform E400_break thru E400_end
				%Beg Menu_xfr_vstr_ws = Null;  %End
				Move "Y" to Send_scr
				Move Zeros to W_s
				Call "MENU_TRANSFER" using by reference Menu_xfr_vstr_ws
			Else
				%Beg  Menu_msg1 = Menu_Errmsg;  %End
				Move "N" to Send_scr
				Perform E200_reply_scr thru E200_end
		    End-if
		    		
		When (Scr_status of Scb_fnc_can = "TIMOUT")
			Perform E300_reject_scr thru E300_end
			Perform E400_break thru E400_end
			%Beg Menu_xfr_vstr_ws = "*TO*";  %End
			Call "MENU_TRANSFER" using by reference Menu_xfr_vstr_ws
			Move Zeros to W_s
			Move "Y" to Send_scr
	End-evaluate.

E050_END.
	Exit.

* List of TRNs marked for interception.
E060_FRCS_SCR. 
    If Send_scr = "Y"
		Perform E065_set_values thru E065_end
		Perform G100_send_scr Thru G100_end
	Else
		Perform G200_reply_scr thru G200_end
    End-if.

    Evaluate True
		When (Scr_status of Scblist_scr = "GOLDCANCEL")
			Set Main_scr in Next_screen to True
			Perform G300_reject_scr thru G300_end
			Perform G400_break thru G400_end
			Move "Y" to Send_scr

		When (Scr_status of Scblist_scr = "CMD_MENU")
			  CALL "MENU_PARSE" Using BY REFERENCE Cmdarg OF Scblist_scr RETURNING Ret_status
		    IF (Success_is in Ret_Status  )
				Perform G300_reject_scr thru G300_end
				Perform G400_break thru G400_end
				%Beg Menu_xfr_vstr_ws = Null;  %End
				Move "Y" to Send_scr
				Move Zeros to W_s
				Call "MENU_TRANSFER" using by reference Menu_xfr_vstr_ws
		    Else
				%Beg  Menu_msg1 = Menu_Errmsg;  %End
				Move "N" to Send_scr
				Perform G200_reply_scr thru G200_end
    		End-if

		When ( Scr_status of Scblist_scr = "ENTR")
			%Beg
				BREAK: Ent_msg_history;
				Ref_index ^SEARCH (forward, eql, Key = Bnk_rpt_seq.Trn);
			%End
			If Success_is in Ref_index_status
				%Beg
					Ref_index CONN: Ent_msg_history(NOMOD);
					Ent_msg_history ^First;
				%End
				Perform Y100_make_msgp thru Y100_end  %^ Output is Prt_vstr80_text_seq, positioned on the 1st line
				Perform G300_reject_scr thru G300_end
				%Beg BREAK: Scblist_scr; %End
				Perform Y150_show_msgp thru Y150_end
				If Scr_status of Scb_msgprint = "TIMOUT"
			    	%Beg Menu_xfr_vstr_ws = "*TO*";  %End
			    	Call "MENU_TRANSFER" using by reference Menu_xfr_vstr_ws
			    	Move Zeros to W_s
					Move "Y" to Send_scr
				Else
					Move "Y" to Send_scr
				End-if
			Else
			 	%Beg Compose_ws ^Out(Err_str1) "TRN ", Bnk_rpt_seq.Trn, " not found. ", /; %End
				Move "N" to Send_scr
			End-if
			%Beg 
				Menu_msg1 = Err_str1; 
				Menu_msg2 = Err_str2; 
			%End

		When (Scr_status of Scblist_scr = "TIMOUT")
	    	Perform G300_reject_scr thru G300_end
	    	Perform G400_break thru G400_end
	    	%Beg Menu_xfr_vstr_ws = "*TO*";  %End
	    	Call "MENU_TRANSFER" using by reference Menu_xfr_vstr_ws
	    	Move Zeros to W_s
			Move "Y" to Send_scr
	End-evaluate.
E060_END.
	Exit.

E065_SET_VALUES.
	%Beg
	    Break: Bnk_rpt_seq;
	    Alloc_temp: Bnk_rpt_seq(mod);
		Q_name = "FCS1_PNDQ";
		BREAK: Logical_pndq;
		ALLOC_TEMP: Logical_Pndq;
		BREAK: Pndq;
	%End.
	%ace_conn_q /<Menu_Bnk_Union.Bnk_id>///<Q_name> to Pndq for Read_only;
	If Failure_is IN Pndq_status
			%Beg 
				Compose_ws ^Out(Err_str1) "Severe Error. Queue ", Q_name, " not found. ", /;
				Menu_msg1 = Err_str1; 
				Menu_msg2 = ""; 
			%End
			Move "Y" to Send_scr
			Go to E065_end
	End-if.
	%Beg 
		Logical_Pndq LINK: Pndq;
		Q_name = "PAI2_PNDDLVQ";
		BREAK: Pndq;
	%End.
	%ACE_CONN_Q /<Menu_Bnk_Union.Bnk_id>///<Q_name> to Pndq for Read_only;
	If Failure_is IN Pndq_status
			%Beg 
				Compose_ws ^Out(Err_str1) "Severe Error. Queue ", Q_name, " not found. ", /;
				Menu_msg1 = Err_str1; 
				Menu_msg2 = ""; 
			%End
			Move "Y" to Send_scr
			Go to E065_end
	End-if.
	%Beg 
		Logical_Pndq LINK: Pndq;
		Q_name = "PAI3_PNDDLVQ";
		BREAK: Pndq;
	%End.
	%ACE_CONN_Q /<Menu_Bnk_Union.Bnk_id>///<Q_name> to Pndq for Read_only;
	If Failure_is IN Pndq_status
			%Beg 
				Compose_ws ^Out(Err_str1) "Severe Error. Queue ", Q_name, " not found. ", /;
				Menu_msg1 = Err_str1; 
				Menu_msg2 = ""; 
			%End
			Move "Y" to Send_scr
			Go to E065_end
	End-if.
	%Beg 
		Logical_Pndq LINK: Pndq;
		Logical_Pndq ^First; 
	%End.
	Move Zeros to Seq_cnt.
	Perform until Seq_end_is in Logical_Pndq_cursor
		%Beg
			Break: Ent_msg_history;
            Break: Ent_msg_union;
            Break: Ent_ftr_set;
			Logical_Pndq CONN: Ent_msg_history (nomod,
                TOP: Ent_msg_union(nomod,
						.Ftr CONN: Ent_ftr_set(nomod) ) );
		%End
		If Cancelled_flag of Ent_ftr_set = "Y"
			%Beg
				Compose_ws ^OUT(Desc_ws), Ent_ftr_set.trn_ref.trn_date, "-", Ent_ftr_set.trn_ref.trn_num,
										" message is marked for interception.  ",  /;
				ALLOC_ELEM: Bnk_rpt_seq( (
					.Amount = <0>,
					.Trn = Ent_ftr_set.Trn_ref,
					.Desc = Desc_ws));
			%End
			Add 1 to Seq_cnt
		End-if
 
		If Seq_cnt > 300
			%Beg COMMIT_TEMP: Bnk_rpt_seq; %End
			Move Zeros to Seq_cnt
		End-if
		%Beg Logical_Pndq ^Next; %End
	End-perform.
	%Beg Bnk_rpt_seq ^First; %End.
E065_END.
	Exit.
	
* Third screen performs
E100_SEND_SCR.	
%^ Break common menu screen subjects 
    %Beg
		BREAK: Scb_fnc_can;
		BREAK: Scb_rsnd_set;
		BREAK: Prt_vstr80_text_seq;
		Err_str1 = Null;
		Err_str2 = Null;

%^ Allocate common menu screen subjects 
		ALLOC_TEMP: Scb_fnc_can;
		ALLOC_TEMP: Scb_rsnd_set(mod);
		ALLOC_TEMP: Prt_vstr80_text_seq(mod);
		Scb_rsnd_set (
			.Line_name = "",
		   	.Beg_seq = "",
		   	.End_seq = "",
		   	.Period1 = "",
		    .Trn_mode = "",
		    .Trn_date = "",
		    .Trn_num = "" 
		);

%^ Place cursor back on last selected menu option
		Scb_fnc_can.Attributes.cursor_position = Save_cursor;	
		Scb_fnc_can.Attributes.Disp_only = F;

 %^ Initialize screen control set 

	  	Scb_fnc_can(
			.Attributes.Clrta = T,
			.Fkeys (
		       .Entr.Enable = T,
		       .Goldcancel.Enable = T,
		       .Goldcancel.Noedit = T,
		       .Rlse.Enable = F,
		       .Timout.Enable = T,
		       .Timout.Noedit = T ),
			.Cmds (
		       .Cmd_menu.Enable = T,
		       .Cmd_menu.Noedit = T,
		       .Cmd_cancel.Enable = F,
		       .Cmd_cancel.Noedit = F,
		       .Cmd_unmark.Enable = F,
		       .Cmd_unmark.Noedit = F),
		    .sel_rec.interface.cursor = T,
		    .sel_rec.interface.bold = T,
		 	.msg1 = Menu_Msg1,
		 	.msg2 = Menu_Msg2 
		);
	%End.
	
	Evaluate True
		When ( Mark in Mark_mode)
			%Beg Scb_fnc_can.Title_name = "DISPLAY_NM1"; %End
		When ( Unmark in Mark_mode)
			%Beg Scb_fnc_can.Title_name = "DISPLAY_NM2"; %End
	End-evaluate.

	%Beg
		SEND: Scb_fnc_can (
			.Menu_Bnk_Union send == Menu_Bnk_Union,
		  	.Sel_rec send == Scb_rsnd_set,
			.R_seq send == Prt_vstr80_text_seq );

	    Menu_msg1 = null;
	    Menu_msg2 = null;
    %End.

E100_END.
    Exit.

E150_CALL_FORMAT.
* See if the msg on the pending q.
	If Interface of Scb_rsnd_set = "T"
		%Beg 
			Q_name = "FCS1_PNDQ";
			Q_dspl = "TSaaS";
		%End
		Move "N" to Q_found
		Perform X100_Find_pndq thru X100_end
		If Q_found = "N"
			%Beg Q_name = "FCI_PNDDLVQ"; %End
			Move "N" to Q_found
			Perform X100_Find_pndq thru X100_end
		End-if
	Else
		%Beg 
			Q_name = "PAI2_PNDDLVQ";
			Q_dspl = "PAIMI";
		%End
		Move "N" to Q_found
		Perform X100_Find_pndq thru X100_end
		If Q_found = "N"
			%Beg Q_name = "PAI3_PNDDLVQ"; %End
			Move "N" to Q_found
			Perform X100_Find_pndq thru X100_end
		End-if
	End-if.
    	
	If Q_found = "N"
		%Beg Compose_ws ^Out(Err_str1) "TRN ", Trn_no, " is not on ", Q_dspl, " pending queue. ", /; %End
		Go to E150_end
	End-if.
	Perform Y100_make_msgp thru Y100_end.
	Evaluate True
		When ( Mark in Mark_mode) and Cancelled_flag of Ent_ftr_set = "Y"
			Move "Message is already marked for interception." to Err_str1
			Move 80 to Err_str1_length
			Go to E150_end
		When ( Unmark in Mark_mode) and Cancelled_flag of Ent_ftr_set NOT = "Y"
			Move "Message is NOT marked for interception." to Err_str1
			Move 80 to Err_str1_length
			Go to E150_end
	End-evaluate
	%Beg
		Prt_vstr80_text_seq ^First;
	 	Scb_fnc_can.Fkeys.Entr.Enable = F;
	%End.
	Evaluate True
		When ( Mark in Mark_mode)
			%Beg
				My_cmp ^Out (Err_str1) "Use command to mark - ", Ent_ftr_set.Trn_ref, " for interception.", /; 
				Scb_fnc_can.Cmds (
					.Cmd_cancel.Enable = T,
					.Cmd_cancel.Noedit = T);
			%End
		When ( Unmark in Mark_mode)
			%Beg
				My_cmp ^Out (Err_str1) "Use command to unmark - ", Ent_ftr_set.Trn_ref, " from interception.", /; 
				Scb_fnc_can.Cmds (
					.Cmd_unmark.Enable = T,
					.Cmd_unmark.Noedit = T);
			%End
	End-evaluate.
	Move "N" to Send_scr.
E150_END.
	Exit.

E200_REPLY_SCR.	
    If (Menu_msg1 NOT = Spaces)
	   	%Beg
	       Scb_fnc_can.Msg1 = Menu_msg1;
	       Menu_msg1 = null;
	   	%End
    End-if.

    If (Menu_msg2 NOT = Spaces)
	   	%Beg
	       Scb_fnc_can.Msg2 = Menu_msg2;
	       Menu_msg2 = null;
	   	%End
    End-if.

    %Beg
		REPLY: Scb_fnc_can &;
	   	REPLY: Menu_Bnk_Union &;
	   	REPLY: Scb_rsnd_set &;
		REPLY: Prt_vstr80_text_seq with: "VMSG$_RESTORE";
	
	   	Menu_msg1 = null;
	  	Menu_msg2 = null;
    %End.
E200_END.
    Exit.

E300_REJECT_SCR.
    %Beg
	    Scb_fnc_can(
			.Msg1 = null,
			.Msg2 = null );
	    Save_cursor = Scb_fnc_can.Attributes.Cursor_position;
		Menu_msg1 = null;
		Menu_msg2 = null;
    %End.
E300_END.
    Exit.

E400_BREAK.
	%Beg
		BREAK: Scb_rsnd_Set;
		BREAK: Scb_fnc_can; 
		BREAK: Prt_vstr80_text_seq;
	%End.
E400_END.
    Exit.

* Display TSaaS/PAIMI Pending Queue Totals.
F050_FRCS_SCR.
    If Send_scr = "Y"
		Perform F100_send_scr Thru F100_end
	Else
		Perform F200_reply_scr thru F200_end
	End-if.
	
	Evaluate True
		When ( Scr_status of Scb_fnc_pndq = "ENTR")
			Evaluate Option of Scb_pndq_sel
			    When "S1"
			    	%Beg
						BREAK: Pndq_sum_seq;
						Seq1 EQUATE: Pndq_sum_seq ^First;
					%End
			    When "S2"
			    	%Beg
						BREAK: Pndq_sum_seq;
						Seq2 EQUATE: Pndq_sum_seq ^First;
					%End
			End-Evaluate
			Move "N" to Send_scr
		When ( Scr_status of Scb_fnc_pndq = "CMD_REFRESH")
			Move "Y" to Send_scr
		When (Scr_status of Scb_fnc_pndq = "GOLDCANCEL")
			Set Main_scr in Next_screen to True
			Perform F300_reject_scr thru F300_end
			Perform F400_break thru F400_end
			Move "Y" to Send_scr
		When (Scr_status of Scb_fnc_pndq = "CMD_MENU")
			CALL "MENU_PARSE" Using BY REFERENCE Cmdarg OF Scb_fnc_pndq RETURNING Ret_status
			IF (Success_is in Ret_Status  )
				Perform F300_reject_scr thru F300_end
				Perform F400_break thru F400_end
				%Beg Menu_xfr_vstr_ws = Null;  %End
				Move "Y" to Send_scr
				Move Zeros to W_s
				Call "MENU_TRANSFER" using by reference Menu_xfr_vstr_ws
			Else
				%Beg  Menu_msg1 = Menu_Errmsg;  %End
				Move "N" to Send_scr
				Perform F200_reply_scr thru F200_end
	   		End-if
		When (Scr_status of Scb_fnc_pndq = "TIMOUT")
	    	Perform F300_reject_scr thru F300_end
	    	Perform F400_break thru F400_end
	    	%Beg Menu_xfr_vstr_ws = "*TO*";  %End
	    	Call "MENU_TRANSFER" using by reference Menu_xfr_vstr_ws
	    	Move Zeros to W_s
			Move "Y" to Send_scr
	End-evaluate.

F050_END.
	Exit.

F060_PROCESS_MSG.
	%Beg
		BREAK: Ent_msg_history;
		BREAK: Ent_msg_union;
		BREAK: Ent_ftr_set;
		BREAK: Ent_credit_seq;
		BREAK: Ent_credit_set;
		Logical_Pndq  CONN: Ent_msg_history (NOMOD);
		Ent_msg_history (nomod,notrap,
		  	TOP: Ent_msg_union(notrap,nomod,
                .Cdt_seq CONN: Ent_credit_seq ( ^First CONN: Ent_credit_set (nomod, notrap) ),
				.Ftr CONN: Ent_ftr_set(notrap,nomod) ) );
		Ent_msg_history ^Next;
	%End.
	Move "N" to Info_sw.
* Amt1,cnt1 - is to msgs with Info,  Amt2..  - for no response from Firco
	Perform until Seq_end_is in Ent_msg_history_cursor or Info_sw = "Y"
		If Idname of Qname of Ent_msg_history(1:3) is = "FCS" and
		   Idname of Qname of Ent_msg_history(5:4) is = "_SND"
			%Beg
				BREAK: L_log;
				Ent_msg_history CONN: L_log (notrap, read_only);
				Time_str_ws = "";
				Tt_fil = "";
			%End
			If Success_is in Ent_msg_history_status and Success_is in L_log_status
				%Beg 
					Time_str_ws = L_log.Systime;
					Parse ^IN(Time_str_ws) Dd_fil, "-", mm_fil, "-", cc_fil, yy_fil, " ", tt_fil, ".", ^str<2>, /;
					Compose_ws ^OUT(Time_st) Dd_fil, "-", Mm_fil, "-", Yy_fil, " ", Tt_fil, /;
				%End
			End-if
		End-if
		If Idname of Qname of Ent_msg_history is = "*SYS_MEMO" and 
			(Memo of Ent_msg_history(1:6) = "HitRef" or 
			 Memo of Ent_msg_history(1:8) = "CheckSum" or 
			 Memo of Ent_msg_history(1:8) = "SystemId" )
				Move "Y" to Info_sw
				Add 1 to Cnt1
				Add Base_amount of Ent_ftr_set to Amt1
				%Beg 
					Compose_ws ^OUT(Str80) Ent_ftr_set.Trn_ref.Trn_date, "-", Ent_ftr_set.Trn_ref.Trn_num,
						" Src: ", Ent_ftr_set.Src_code, " Mop: ", Ent_credit_set.Cdt_adv_typ, " ", 
						Ent_ftr_set.Base_amount(^Num(^American_format,^commas, ^noleading_zeros, ^dollar_sign)), " ", ^Column<63>,  Time_st, /;
				   	ALLOC_ELEM: Seq1( (
						.Txt = Str80));
				%End
		End-if
		%Beg Ent_msg_history ^Next; %End
	End-perform.
	If Info_sw = "N"
		Add 1 to Cnt2
		Add Base_amount of Ent_ftr_set to Amt2
		%Beg 
			Compose_ws ^OUT(Str80) Ent_ftr_set.Trn_ref.Trn_date, "-", Ent_ftr_set.Trn_ref.Trn_num, 
				" Src: ", Ent_ftr_set.Src_code, " Mop: ", Ent_credit_set.Cdt_adv_typ, " ",
		  		Ent_ftr_set.Base_amount(^Num(^noleading_zeros,^American_format,^commas, ^dollar_sign)), " ", ^Column<63>,  Time_st, /;
		   	ALLOC_ELEM: Seq2( (
				.Txt = Str80));
		%End
	End-if.
	%Beg Logical_Pndq ^Next; %End.
F060_END.
	Exit.

F061_PROCESS_MSG.
	%Beg
		BREAK: Ent_msg_history;
		BREAK: Ent_msg_union;
		BREAK: Ent_ftr_set;
		BREAK: Ent_credit_seq;
		BREAK: Ent_credit_set;
		Logical_Pndq  CONN: Ent_msg_history (NOMOD);
		Ent_msg_history (nomod,notrap,
		  	TOP: Ent_msg_union(notrap,nomod,
                .Cdt_seq CONN: Ent_credit_seq ( ^First CONN: Ent_credit_set (nomod, notrap) ),
				.Ftr CONN: Ent_ftr_set(notrap,nomod) ) );
		Ent_msg_history ^Next;
	%End.
	Move "N" to Info_sw.
* Amt1,cnt1 - is to msgs with Info,  Amt2..  - for no response from Firco
	Perform until Seq_end_is in Ent_msg_history_cursor or Info_sw = "Y"
		If Idname of Qname of Ent_msg_history(1:3) is = "PAI" and
		   Idname of Qname of Ent_msg_history(5:6) is = "_I_SND"
			%Beg
				BREAK: L_log;
				Ent_msg_history CONN: L_log (notrap, read_only);
				Time_str_ws = "";
				Tt_fil = "";
			%End
			If Success_is in Ent_msg_history_status and Success_is in L_log_status
				%Beg 
					Time_str_ws = L_log.Systime;
					Parse ^IN(Time_str_ws) Dd_fil, "-", mm_fil, "-", cc_fil, yy_fil, " ", tt_fil, ".", ^str<2>, /;
					Compose_ws ^OUT(Time_st) Dd_fil, "-", Mm_fil, "-", Yy_fil, " ", Tt_fil, /;
				%End
			End-if
		End-if
		If Idname of Qname of Ent_msg_history is = "*SYS_MEMO" and 
			(Memo of Ent_msg_history(1:6) = "HitRef" or 
			 Memo of Ent_msg_history(1:8) = "CheckSum" or 
			 Memo of Ent_msg_history(1:8) = "SystemId" )
				Move "Y" to Info_sw
				Add 1 to Cnt1
				Add Base_amount of Ent_ftr_set to Amt1
				%Beg 
					Compose_ws ^OUT(Str80) Ent_ftr_set.Trn_ref.Trn_date, "-", Ent_ftr_set.Trn_ref.Trn_num,
						" Src: ", Ent_ftr_set.Src_code, " Mop: ", Ent_credit_set.Cdt_adv_typ, " ", 
						Ent_ftr_set.Base_amount(^Num(^American_format,^commas, ^noleading_zeros, ^dollar_sign)), " ", ^Column<63>,  Time_st, /;
				   	ALLOC_ELEM: Seq1( (
						.Txt = Str80));
				%End
		End-if
		%Beg Ent_msg_history ^Next; %End
	End-perform.
	If Info_sw = "N"
		Add 1 to Cnt2
		Add Base_amount of Ent_ftr_set to Amt2
		%Beg 
			Compose_ws ^OUT(Str80) Ent_ftr_set.Trn_ref.Trn_date, "-", Ent_ftr_set.Trn_ref.Trn_num, 
				" Src: ", Ent_ftr_set.Src_code, " Mop: ", Ent_credit_set.Cdt_adv_typ, " ",
		  		Ent_ftr_set.Base_amount(^Num(^noleading_zeros,^American_format,^commas, ^dollar_sign)), " ", ^Column<63>,  Time_st, /;
		   	ALLOC_ELEM: Seq2( (
				.Txt = Str80));
		%End
	End-if.
	%Beg Logical_Pndq ^Next; %End.
F061_END.
	Exit.

* Fourth screen performs
F100_SEND_SCR.
	Perform F150_SET_VALUES thru F150_end.
		 
%^ Break common menu screen subjects 
    %Beg
		BREAK: Scb_fnc_pndq;
		Err_str1 = Null;
		Err_str2 = Null;

%^ Allocate common menu screen subjects 
		ALLOC_TEMP: Scb_fnc_pndq;
	%End.

	%Beg
%^ Place cursor back on last selected menu option
		Scb_fnc_pndq.Attributes.cursor_position = Save_cursor;	
		Scb_fnc_pndq.Attributes.Disp_only = F;

%^ Initialize screen control set 

	  	Scb_fnc_pndq(
			.Title = Title_pnd,
			.Attributes.Clrta = T,
			.Fkeys (
		       .Entr.Enable = T,
		       .Goldcancel.Enable = T,
		       .Goldcancel.Noedit = T,
		       .Rlse.Enable = F,
		       .Timout.Enable = T,
		       .Timout.Noedit = T ),
			.Cmds (
		       .Cmd_refresh.Enable = T,
		       .Cmd_refresh.Noedit = T,
		       .Cmd_menu.Enable = T,
		       .Cmd_menu.Noedit = T),
		 		.msg1 = Menu_Msg1,
		 		.msg2 = Menu_Msg2 
		    );

		Scb_pndq_sel ^First;
		Pndq_sum_seq ^First;
				
		SEND: Scb_fnc_pndq (
			.Menu_Bnk_Union send == Menu_Bnk_Union,
		 	.P_seq send == Scb_pndq_sel,
			.R_seq send == Pndq_sum_seq );

	    Menu_msg1 = null;
	    Menu_msg2 = null;
    %End.

F100_END.
    Exit.

F150_SET_VALUES.
	%Beg
		BREAK: Pndq;
		BREAK: Seq1;
		BREAK: Seq2;
		ALLOC_TEMP: Seq1(MOD);
		ALLOC_TEMP: Seq2(MOD);
		Amt1 = <0.00>;
		Cnt1 = <0>;
		Amt2 = <0.00>;
		Cnt2 = <0>;
	%End.		

	If Title_pnd(1:5) = "TSAAS"
		%Beg 
			Q_name = "FCS1_PNDQ";
			BREAK: Logical_pndq;
			ALLOC_TEMP: Logical_Pndq;
			BREAK: Pndq;
		%End
		%ace_conn_q /<Menu_Bnk_Union.Bnk_id>///<Q_name> to Pndq for Read_only;
		If Failure_is IN Pndq_status
			%Beg 
				Compose_ws ^Out(Err_str1) "Severe Error. Queue ", Q_name, " not found. ", /;
				Menu_msg1 = Err_str1; 
				Menu_msg2 = ""; 
			%End
			Move "Y" to Send_scr
			Go to F150_end
		End-if
		%Beg 
			Logical_Pndq LINK: Pndq;
			Logical_Pndq ^First; 
		%End
		Perform F060_process_msg thru F060_end until
			Seq_end_is in Logical_Pndq_cursor
	Else
		%Beg 
			BREAK: Logical_pndq;
			ALLOC_TEMP: Logical_Pndq;
			Q_name = "PAI2_PNDDLVQ";
			BREAK: Pndq;
		%End
		%ace_conn_q /<Menu_Bnk_Union.Bnk_id>///<Q_name> to Pndq for Read_only;
		If Failure_is IN Pndq_status
			%Beg 
				Compose_ws ^Out(Err_str1) "Severe Error. Queue ", Q_name, " not found. ", /;
				Menu_msg1 = Err_str1; 
				Menu_msg2 = ""; 
			%End
			Move "Y" to Send_scr
			Go to F150_end
		End-if
		%Beg 
			Logical_Pndq LINK: Pndq;
			Q_name = "PAI3_PNDDLVQ";
			BREAK: Pndq;
		%End
		%ace_conn_q /<Menu_Bnk_Union.Bnk_id>///<Q_name> to Pndq for Read_only;
		If Failure_is IN Pndq_status
			%Beg 
				Compose_ws ^Out(Err_str1) "Severe Error. Queue ", Q_name, " not found. ", /;
				Menu_msg1 = Err_str1; 
				Menu_msg2 = ""; 
			%End
			Move "Y" to Send_scr
			Go to F150_end
		End-if
		%Beg 
			Logical_Pndq LINK: Pndq;
			Logical_Pndq ^First; 
		%End
		Perform F061_process_msg thru F061_end until
			Seq_end_is in Logical_Pndq_cursor
	End-if.

	%Beg
	    BREAK: Scb_pndq_sel;
	    ALLOC_TEMP: Scb_pndq_sel (mod);
	    Compose_ws ^OUT(Str60) "Info Responses. ", ^Column<17>, Cnt1, ^Column<29>, Amt1(^Num(^noleading_zeros,^American_format,^commas, ^dollar_sign)),/;
	    ALLOC_ELEM: Scb_pndq_sel (
			(   .Option = "S1",
				.Desc = Str60 ));
		Compose_ws ^OUT(Str60) "  No Responses. ", ^Column<17>, Cnt2, ^Column<29>, Amt2(^Num(^noleading_zeros,^American_format,^commas, ^dollar_sign)),/;
		ALLOC_ELEM: Scb_pndq_sel (
	       (   .Option = "S2",
					   .Desc = Str60 ));
		BREAK: Pndq_sum_seq;
		Seq1 EQUATE: Pndq_sum_seq;
	%End.

F150_END.
		Exit.
		
F200_REPLY_SCR.	
    If (Menu_msg1 NOT = Spaces)
	   	%Beg
	       Scb_fnc_pndq.Msg1 = Menu_msg1;
	       Menu_msg1 = null;
	   	%End
    End-if.

    If (Menu_msg2 NOT = Spaces)
	   	%Beg
	       Scb_fnc_pndq.Msg2 = Menu_msg2;
	       Menu_msg2 = null;
	   	%End
    End-if.

    %Beg
		Scb_pndq_sel ^First;
		Pndq_sum_seq ^First;
	   	REPLY: Scb_fnc_pndq &;
	   	REPLY: Menu_Bnk_Union &;
	   	REPLY: Scb_pndq_sel &;
		REPLY: Pndq_sum_seq with: "VMSG$_RESTORE";
	
	   	Menu_msg1 = null;
		Menu_msg2 = null;
    %End.
F200_END.
    Exit.

F300_REJECT_SCR.
    %Beg
		Scb_fnc_pndq(
			.Msg1 = null,
			.Msg2 = null );
			Save_cursor = Scb_fnc_pndq.Attributes.Cursor_position;
		   	Menu_msg1 = null;
		  	Menu_msg2 = null;
    %End.
F300_END.
    Exit.

F400_BREAK.
	%Beg
		BREAK: Scb_pndq_sel;
		BREAK: Scb_fnc_pndq; 
		BREAK: Pndq_sum_seq;
	%End.
F400_END.
    Exit.

* Monitor Auto Release Report.
G050_FRCS_SCR.
    If Send_scr = "Y"
		Perform G150_set_values thru G150_end
		Perform G100_send_scr Thru G100_end
	Else
		Perform G200_reply_scr thru G200_end
    End-if.

    Evaluate True
		When (Scr_status of Scblist_scr = "GOLDCANCEL")
			Set Main_scr in Next_screen to True
			Perform G300_reject_scr thru G300_end
			Perform G400_break thru G400_end
			Move "Y" to Send_scr

		When (Scr_status of Scblist_scr = "CMD_PERIOD")
			If Cmdarg OF Scblist_scr not = Spaces
				Move Cmdarg OF Scblist_scr to Sel_date
				%Beg Parse (^notrap) ^IN(Sel_date) Period_ws.yyyymmdd, /; %End
				If Period_ws not = zeros and Success_is in Parse_Status
					%Beg Break: Opr_log;	%End
					%ACE_CONN_Q /<Menu_Bnk_Union.Bnk_id>///"AUTOMNRLS_LOG" to Opr_log for Read_only;
					%Beg
						Opr_log ^First_period;
						Opr_log ^Search_Period Forward, Period = Period_ws;
					%End
					If Opr_log_period not = Period_ws
						%Beg  Menu_msg1 = "Period not found. Try again.";  %End
						Move "N" to Send_scr
						Perform G200_reply_scr thru G200_end
					Else
						Move "Y" to Send_scr
					End-if
				Else
					%Beg  Menu_msg1 = "Period not found. Try again.";  %End
					Move "N" to Send_scr
					Perform G200_reply_scr thru G200_end
				End-if
			Else
				%Beg Break: Opr_log;	%End
			End-if
				
		When (Scr_status of Scblist_scr = "CMD_MENU")
			  CALL "MENU_PARSE" Using BY REFERENCE Cmdarg OF Scblist_scr RETURNING Ret_status
		    IF (Success_is in Ret_Status  )
				Perform G300_reject_scr thru G300_end
				Perform G400_break thru G400_end
				%Beg Menu_xfr_vstr_ws = Null;  %End
				Move "Y" to Send_scr
				Move Zeros to W_s
				Call "MENU_TRANSFER" using by reference Menu_xfr_vstr_ws
		    Else
				%Beg  Menu_msg1 = Menu_Errmsg;  %End
				Move "N" to Send_scr
				Perform G200_reply_scr thru G200_end
    		End-if

		When ( Scr_status of Scblist_scr = "ENTR")
			%Beg
				BREAK: Ent_msg_history;
				Ref_index ^SEARCH (forward, eql, Key = Bnk_rpt_seq.Trn);
			%End
			If Success_is in Ref_index_status
				%Beg
					Ref_index CONN: Ent_msg_history(NOMOD);
					Ent_msg_history ^First;
				%End
				Perform Y100_make_msgp thru Y100_end  %^ Output is Prt_vstr80_text_seq, positioned on the 1st line
				Perform G300_reject_scr thru G300_end
				%Beg BREAK: Scblist_scr; %End
				Perform Y150_show_msgp thru Y150_end
				If Scr_status of Scb_msgprint = "TIMOUT"
			    	%Beg Menu_xfr_vstr_ws = "*TO*";  %End
			    	Call "MENU_TRANSFER" using by reference Menu_xfr_vstr_ws
			    	Move Zeros to W_s
					Move "Y" to Send_scr
				Else
					Move "Y" to Send_scr
				End-if
			Else
				%Beg Compose_ws ^Out(Err_str1) "TRN ", Bnk_rpt_seq.Trn, " not found. ", /; %End
				Move "N" to Send_scr
			End-if
			%Beg 
				Menu_msg1 = Err_str1; 
				Menu_msg2 = Err_str2; 
			%End

		When (Scr_status of Scblist_scr = "TIMOUT")
	    	Perform G300_reject_scr thru G300_end
	    	Perform G400_break thru G400_end
	    	%Beg Menu_xfr_vstr_ws = "*TO*";  %End
	    	Call "MENU_TRANSFER" using by reference Menu_xfr_vstr_ws
	    	Move Zeros to W_s
			Move "Y" to Send_scr
	End-evaluate.

G050_END.
	Exit.

* Fifth screen performs
G100_SEND_SCR.	
		 
%^ Break common menu screen subjects 
    %Beg
		BREAK: Scblist_scr;
		Err_str1 = Null;
		Err_str2 = Null;

%^ Allocate common menu screen subjects 
		ALLOC_TEMP: Scblist_scr;
	%End.

	%Beg
%^ Place cursor back on last selected menu option
		Scblist_scr.Attributes.cursor_position = Save_cursor;	
		Scblist_scr.Attributes.Disp_only = F;

%^ Initialize screen control set 

		Scblist_scr(
			.Attributes.Clrta = T,
			.Fkeys (
		       .Entr.Enable = T,
		       .Goldcancel.Enable = T,
		       .Goldcancel.Noedit = T,
		       .Rlse.Enable = F,
		       .Timout.Enable = T,
		       .Timout.Noedit = T ),
			.Cmds (
		       .Cmd_rlsall.Enable = F,
		       .Cmd_rlsall.Noedit = F,
		       .Cmd_fltall.Enable = F,
		       .Cmd_fltall.Noedit = F,
		       .Cmd_flttrn.Enable = F,
		       .Cmd_flttrn.Noedit = F,
		       .Cmd_fltdda.Enable = F,
		       .Cmd_fltdda.Noedit = F,
		       .Cmd_fltf20.Enable = F,
		       .Cmd_fltf20.Noedit = F,
		       .Cmd_vfy.Enable = F,
		       .Cmd_vfy.Noedit = F,
		       .Cmd_period.Enable = T,
		       .Cmd_period.Noedit = T,
		       .Cmd_menu.Enable = T,
		       .Cmd_menu.Noedit = T),
		 	.msg1 = Menu_Msg1,
		 	.msg2 = Menu_Msg2 
		);
	%End.

	Evaluate True
		When ( Mondsp_scr in Next_screen)
			%Beg Scblist_scr.Inq_name = "DISPLAY_INQ1"; %End
		When ( Canlst_scr in Next_screen)
			%Beg 
				Scblist_scr.Inq_name = "DISPLAY_INQ2"; 
				Scblist_scr.Cmds(
					.Cmd_period.Enable = F,
					.Cmd_period.Noedit = F
				);
			%End
	End-evaluate.

	%Beg
		SEND: Scblist_scr (
			.Menu_Bnk_Union send == Menu_Bnk_Union,
			.B_seq send == Bnk_rpt_seq );

	    Menu_msg1 = null;
	    Menu_msg2 = null;
    %End.

G100_END.
    Exit.

G150_SET_VALUES.
	%Beg
	    Break: Bnk_rpt_seq;
	    Alloc_temp: Bnk_rpt_seq(mod);
	%End.
    %ACE_IS Opr_log connected;
    If Failure_is in ace_status_wf
		%Beg  Break: Opr_log; %End
		%ACE_CONN_Q /<Menu_Bnk_Union.Bnk_id>///"AUTOMNRLS_LOG" to Opr_log for Read_only;
	End-if.
	%Beg Opr_log ^First; %End.
	Move Zeros to Seq_cnt.
	Perform until Seq_end_is in Opr_log_cursor
		%Beg
			Break: Ent_msg_history;
			Opr_log CONN: Ent_msg_history;
		%End
		If Memo_length of Ent_msg_history_lengths > 61
			Move 61 to Memo_length of Ent_msg_history_lengths
		End-if
		%Beg
			Compose_ws ^OUT(Desc_ws),Opr_log.Txt, " ", Ent_msg_history.Memo, /;
	
			ALLOC_ELEM: Bnk_rpt_seq( (
				.Amount = <0>,
				.Trn = Opr_log.Txt,
				.Desc = Desc_ws));
		%End
		Add 1 to Seq_cnt
		If Seq_cnt > 300
			%Beg COMMIT_TEMP: Bnk_rpt_seq; %End
			Move Zeros to Seq_cnt
		End-if
		%Beg Opr_log ^Next; %End
	End-perform.
	%Beg Bnk_rpt_seq ^First; %End.
G150_END.
	Exit.

G200_REPLY_SCR.	
    If (Menu_msg1 NOT = Spaces)
	   	%Beg
	       Scblist_scr.Msg1 = Menu_msg1;
	       Menu_msg1 = null;
		%End
    End-if.

    If (Menu_msg2 NOT = Spaces)
	   	%Beg
	       Scblist_scr.Msg2 = Menu_msg2;
	       Menu_msg2 = null;
	   	%End
    End-if.

    %Beg
		Bnk_rpt_seq ^First;
	   	REPLY: Scblist_scr &;
	   	REPLY: Menu_Bnk_Union &;
		REPLY: Bnk_rpt_seq with: "VMSG$_RESTORE";
	
	   	Menu_msg1 = null;
	  	Menu_msg2 = null;
    %End.
G200_END.
    Exit.

G300_REJECT_SCR.
    %Beg
	    Scblist_scr(
			.Msg1 = null,
			.Msg2 = null );
	    Save_cursor = Scblist_scr.Attributes.Cursor_position;
		Menu_msg1 = null;
		Menu_msg2 = null;
    %End.
G300_END.
    Exit.

G400_BREAK.
	%Beg
		BREAK: Bnk_rpt_seq;
		BREAK: Scblist_scr; 
		BREAK: Opr_log;
	%End.
G400_END.
    Exit.

* Release messages from Falcon/S2B Pending Queues.
H050_FRCS_SCR.
    If Send_scr = "Y"
		Perform H150_set_values thru H150_end
		Perform H100_send_scr Thru H100_end
	Else
		Perform H200_reply_scr thru H200_end
    End-if.
	If Dbg_sw = "Y"
		display "1. h050. doing this command - ", Scr_status of Scblist_scr
	End-if.

    Evaluate True
		When (Scr_status of Scblist_scr = "GOLDCANCEL")
			Set Main_scr in Next_screen to True
			Perform H300_reject_scr thru H300_end
			Perform H400_break thru H400_end
			Move "Y" to Send_scr

		When (Scr_status of Scblist_scr = "CMD_FLTALL")
			Set ALL_TRNS in Set_filter to True
			%Beg Filter_arg = ""; %End
			Perform H150_set_values thru H150_end
			Move "N" to Send_scr
			
		When (Scr_status of Scblist_scr = "CMD_FLTTRN")
			Set TRN in Set_filter to True
			%Beg
				Filter_arg = Scblist_scr.Cmdarg;
				Parse (^Notrap) ^IN(Filter_arg) Ref1.Trn_date, "-", Ref1.Trn_Num,/; 
			%End
			If (Failure_is IN Parse_status)
				If Filter_arg_length < 8  %^ Assume that date is omitted. Use current period
					%Beg 
						Time_ws Current_period;
						Ref1.Trn_date = Time_ws.Yyyymmdd;
						Parse (^Notrap) ^IN(Filter_arg) No_ws(^NUMBER);
						Compose_ws ^OUT(Ref1.Trn_num) No_ws(^LEADING_ZEROS, ^NUM<8>);
						Filter_arg = Ref1;
					%End
				End-if
			Else
				%Beg
					Parse (^Notrap) ^IN(Ref1.Trn_num) No_ws(^NUMBER);
					Compose_ws ^OUT(Ref1.Trn_num) No_ws(^LEADING_ZEROS, ^NUM<8>);
					Filter_arg = Ref1;
				%End
			End-if
			Perform H150_set_values thru H150_end
			Move "N" to Send_scr
			
		When (Scr_status of Scblist_scr = "CMD_RLSALL")
			%Beg Rls_memo = Scblist_scr.Cmdarg; %End
			Perform H500_do_release thru H500_end
			Set ALL_TRNS in Set_filter to True
			%Beg Filter_arg = ""; %End
			Perform H150_set_values thru H150_end
			Move "N" to Send_scr
			
		When (Scr_status of Scblist_scr = "CMD_FLTDDA")
			Set Dda in Set_filter to true
			%Beg Filter_arg = Scblist_scr.Cmdarg; %End
			Perform H150_set_values thru H150_end
			Move "N" to Send_scr
			
		When (Scr_status of Scblist_scr = "CMD_FLTF20")
			Set F20 in Set_filter to true
			%Beg Filter_arg = Scblist_scr.Cmdarg; %End
			Perform H150_set_values thru H150_end
			Move "N" to Send_scr
			
		When (Scr_status of Scblist_scr = "CMD_MENU")
			CALL "MENU_PARSE" Using BY REFERENCE Cmdarg OF Scblist_scr RETURNING Ret_status
		    IF (Success_is in Ret_Status )
				Perform H300_reject_scr thru H300_end
				Perform H400_break thru H400_end
				%Beg Menu_xfr_vstr_ws = Null;  %End
				Move "Y" to Send_scr
				Move Zeros to W_s
				Call "MENU_TRANSFER" using by reference Menu_xfr_vstr_ws
		    Else
				%Beg  Menu_msg1 = Menu_Errmsg;  %End
				Move "N" to Send_scr
				Perform H200_reply_scr thru H200_end
    		End-if

		When ( Scr_status of Scblist_scr = "ENTR")
			%Beg
				BREAK: Ent_msg_history;
				Ref_index ^SEARCH (forward, eql, Key = Bnk_rpt_seq.Trn);
			%End
			If Success_is in Ref_index_status
				%Beg
					Ref_index CONN: Ent_msg_history(NOMOD);
					Ent_msg_history ^First;
				%End
				Perform Y100_make_msgp thru Y100_end  %^ Output is Prt_vstr80_text_seq, positioned on the 1st line
				Perform H300_reject_scr thru H300_end
				%Beg BREAK: Scblist_scr; %End
				Perform Y150_show_msgp thru Y150_end
				If Scr_status of Scb_msgprint = "TIMOUT"
			    	%Beg Menu_xfr_vstr_ws = "*TO*";  %End
			    	Call "MENU_TRANSFER" using by reference Menu_xfr_vstr_ws
			    	Move Zeros to W_s
					Move "Y" to Send_scr
				Else
					Move "Y" to Send_scr
				End-if
			Else
			 	%Beg Compose_ws ^Out(Err_str1) "TRN ", Bnk_rpt_seq.Trn, " not found. ", /; %End
				Move "N" to Send_scr
			End-if
			%Beg 
				Menu_msg1 = Err_str1; 
				Menu_msg2 = Err_str2; 
			%End

		When (Scr_status of Scblist_scr = "TIMOUT")
	    	Perform H300_reject_scr thru H300_end
	    	Perform H400_break thru H400_end
	    	%Beg Menu_xfr_vstr_ws = "*TO*";  %End
	    	Call "MENU_TRANSFER" using by reference Menu_xfr_vstr_ws
	    	Move Zeros to W_s
			Move "Y" to Send_scr
	End-evaluate.

H050_END.
	Exit.

H100_SEND_SCR.	
		 
%^ Break common menu screen subjects 
    %Beg
		BREAK: Scblist_scr;
		Err_str1 = Null;
		Err_str2 = Null;

%^ Allocate common menu screen subjects 
		ALLOC_TEMP: Scblist_scr;
	%End.

	%Beg
%^ Place cursor back on last selected menu option
		Scblist_scr.Attributes.cursor_position = Save_cursor;	
		Scblist_scr.Attributes.Disp_only = F;

%^ Initialize screen control set 

		Scblist_scr(
			.Attributes.Clrta = T,
			.Fkeys (
		       .Entr.Enable = T,
		       .Goldcancel.Enable = T,
		       .Goldcancel.Noedit = T,
		       .Rlse.Enable = F,
		       .Timout.Enable = T,
		       .Timout.Noedit = T ),
			.Cmds (
		       .Cmd_rlsall.Enable = T,
		       .Cmd_rlsall.Noedit = T,
		       .Cmd_fltall.Enable = T,
		       .Cmd_fltall.Noedit = T,
		       .Cmd_flttrn.Enable = T,
		       .Cmd_flttrn.Noedit = T,
		       .Cmd_fltdda.Enable = T,
		       .Cmd_fltdda.Noedit = T,
		       .Cmd_fltf20.Enable = T,
		       .Cmd_fltf20.Noedit = T,
		       .Cmd_vfy.Enable = F,
		       .Cmd_vfy.Noedit = F,
			   .Cmd_menu.Enable = T,
		       .Cmd_menu.Noedit = T),
		 	.msg1 = Menu_Msg1,
		 	.msg2 = Menu_Msg2 
		);
	%End.

	Evaluate True
		When ( RlsFlc_scr in Next_screen)
			%Beg Scblist_scr.Inq_name = "DISPLAY_INQ5"; %End
		When ( RlsS2b_scr in Next_screen)
			%Beg Scblist_scr.Inq_name = "DISPLAY_INQ4"; %End
	End-evaluate.

	%Beg
		SEND: Scblist_scr (
			.Menu_Bnk_Union send == Menu_Bnk_Union,
			.B_seq send == Bnk_rpt_seq );

	    Menu_msg1 = null;
	    Menu_msg2 = null;
    %End.

H100_END.
    Exit.

H150_SET_VALUES.
	Evaluate True
		When ( RlsFlc_scr in Next_screen)
			%Beg Q_name = "FAL1_PNDQ"; %End
		When ( RlsS2b_scr in Next_screen)
			%Beg Q_name = "S2B1_PNDQ"; %End
	End-evaluate.
	%Beg
	    Break: Bnk_rpt_seq;
	    Alloc_temp: Bnk_rpt_seq(mod);
	%End.
	%Beg  Break: Pndq; %End.
	%ACE_CONN_Q /<Menu_Bnk_Union.Bnk_id>///<Q_name> to Pndq for Read_only;
	%Beg Pndq ^First; %End.
	Move Zeros to Seq_cnt.
	Perform until Seq_end_is in Pndq_cursor
		%Beg
			Break: Ent_msg_history;
            Break: Ent_msg_union;
            Break: Ent_ftr_set;
		    Break: Ent_debit_seq;
		    Break: Ent_debit_set;
			Pndq CONN: Ent_msg_history (nomod,
                TOP: Ent_msg_union(nomod,
					.Ftr CONN: Ent_ftr_set(nomod) 
					.Dbt_seq Conn: Ent_debit_seq(notrap, nomod, ^First Conn:
						Ent_debit_set(nomod, notrap) )
			) );
		%End
		%Beg
			Compose_ws ^OUT(Desc_ws), Ent_ftr_set.trn_ref.trn_date, "-", Ent_ftr_set.trn_ref.trn_num,
						" Dbt: ", Ent_debit_set.Dbt_account.Idkey, 
%^						" Cdt ", Ent_credit_set.Cdt_account.IdKey, 
						" Ref: ", Ent_debit_set.Sbk_ref_num, " ", /;
%^						Ent_ftr_set.Amount(^Num(^American_format,^commas, ^dollar_sign) ), /;
		%End
		Evaluate True
			When ALL_TRNS in Set_filter
				%beg
					ALLOC_ELEM: Bnk_rpt_seq( (
						.Amount = <0>,
						.Trn = Ent_ftr_set.Trn_ref,
						.Desc = Desc_ws));
				%End
				Add 1 to Seq_cnt

			When DDA in Set_filter
				If Filter_arg = Idkey of Dbt_account of Ent_debit_set
					%beg
						ALLOC_ELEM: Bnk_rpt_seq( (
							.Amount = <0>,
							.Trn = Ent_ftr_set.Trn_ref,
							.Desc = Desc_ws));
					%End
					Add 1 to Seq_cnt
				End-if
			When TRN in Set_filter
				If Filter_arg = Trn_ref of Ent_ftr_set
					%beg
						ALLOC_ELEM: Bnk_rpt_seq( (
							.Amount = <0>,
							.Trn = Ent_ftr_set.Trn_ref,
							.Desc = Desc_ws));
					%End
					Add 1 to Seq_cnt
				End-if

			When F20 in Set_filter
				If Filter_arg =  FUNCTION UPPER-CASE(Sbk_ref_num of Ent_debit_set)
					%beg
						ALLOC_ELEM: Bnk_rpt_seq( (
							.Amount = <0>,
							.Trn = Ent_ftr_set.Trn_ref,
							.Desc = Desc_ws));
					%End
					Add 1 to Seq_cnt
				End-if
		End-evaluate
		If Seq_cnt > 300
			%Beg COMMIT_TEMP: Bnk_rpt_seq; %End
			Move Zeros to Seq_cnt
		End-if
		%Beg Pndq ^Next; %End
	End-perform.
	%Beg Bnk_rpt_seq ^First; %End.
	If Seq_end_is in Bnk_rpt_seq_cursor
		%Beg Menu_msg1 = "There are no transaction on the pending queue"; %End
	Else 
		If Menu_msg1 = Spaces
			%Beg Menu_msg1 = "Use command to release shown transactions."; %End
		End-if
	End-if.
H150_END.
	Exit.

H200_REPLY_SCR.	
	If Dbg_sw = "Y"
		display "1. H200_reply err msg -  ", menu_msg1
	End-if.

    If (Menu_msg1 NOT = Spaces)
	   	%Beg
	       Scblist_scr.Msg1 = Menu_msg1;
	       Menu_msg1 = null;
		%End
    End-if.

    If (Menu_msg2 NOT = Spaces)
	   	%Beg
	       Scblist_scr.Msg2 = Menu_msg2;
	       Menu_msg2 = null;
	   	%End
    End-if.

    %Beg
		Bnk_rpt_seq ^First;
	   	REPLY: Scblist_scr &;
	   	REPLY: Menu_Bnk_Union &;
		REPLY: Bnk_rpt_seq with: "VMSG$_RESTORE";
	
	   	Menu_msg1 = null;
	  	Menu_msg2 = null;
    %End.
H200_END.
    Exit.

H300_REJECT_SCR.
    %Beg
	    Scblist_scr(
			.Msg1 = null,
			.Msg2 = null );
	    Save_cursor = Scblist_scr.Attributes.Cursor_position;
		Menu_msg1 = null;
		Menu_msg2 = null;
    %End.
H300_END.
    Exit.

H400_BREAK.
	%Beg
		BREAK: Bnk_rpt_seq;
		BREAK: Scblist_scr; 
		BREAK: Pndq;
	%End.
H400_END.
    Exit.

H500_DO_RELEASE.
	Evaluate True
		When ( RlsFlc_scr in Next_screen)
			%Beg 
				Q_name = "FAL_VFYCMD"; 
				Vfy_name = "FAL_VFYPNDQ";
			%End
		When ( RlsS2b_scr in Next_screen)
			%Beg 
				Q_name = "S2B_VFYCMD"; 
				Vfy_name = "S2B_VFYPNDQ";
			%End
	End-evaluate.
    %Beg 
		BREAK: PndCmdq; 
		BREAK: PndVfyQ;
	%End.
	%ACE_CONN_Q /<Menu_Bnk_Union.Bnk_id>///<Q_name> to PndCmdq for insert;
	%ACE_CONN_Q /<Menu_Bnk_Union.Bnk_id>///<Vfy_name> to PndVfyq for insert;
	%Beg PndCmdq(notrap); %End.
	If Dbg_sw = "Y"
		display "1. H500_DO_REL - qname - ", q_name, "  vfy n - ", Vfy_name
	End-if.
%^ Create an entry to S2B_VFYCMD/FAL_VFYCMD
    %Beg
		Desc_ws = "";
		Compose_ws ^OUT(Desc_ws) "Release ", set_filter(^Oneof("ALL_TRNS","DDA","F20","TRN")), ":" filter_arg, /;
		ALLOC_ELEM: PndCmdq(
			.Vstr_key = Desc_ws,
			.Systime NOW,
			.Txt = Menu_opr_union.Opr_login_id,
			.Memo = Rls_memo);
	%End.
	If Dbg_sw = "Y"
		display "2. H500_DO_REL - descr - ", desc_ws, "  stat - ", PndCmdq_status
	End-if.
	If Success_is in PndCmdq_status
		If Dbg_sw = "Y"
			display "3. H500_DO_REL - doing release "
		End-if
		%Beg Bnk_rpt_seq ^First; %End
		Perform until Seq_end_is in Bnk_rpt_seq_Cursor
			Move "N" to Stat_sw
			Perform H600_Release_trn thru H600_end
			If Stat_sw = "N"
				%Beg Commit: TRAN;  %End
			Else
				%Beg Cancel: TRAN;  %End
			End-if
			If Dbg_sw = "Y"
				display "4. Releasing released: TRN - ", Trn of Bnk_rpt_seq
			End-if
			%Beg Bnk_rpt_seq ^Next; %End
		End-perform
	Else
		If Dbg_sw = "Y"
			display "4. H500_DO_REL - already there "
		End-if
		%Beg 
			Menu_msg1 = "This request was created and waiting verification."; 
			CANCEL: Tran;
		%End
	End-if.
	Set ALL_TRNS in Set_filter to True.
H500_END.
	Exit.

H600_RELEASE_TRN.
* See if the msg on the pending q.
	Move "N" to Q_found.
	%Beg
		BREAK: Ent_msg_history;
		Ref_index ^SEARCH (forward, eql, Key = Bnk_rpt_seq.Trn);
	%End.
	If Dbg_sw = "Y"
		display "1. Releasing TRN - ", Trn of Bnk_rpt_seq
	End-if.
	If Failure_is in Ref_index_status
		%Beg Compose_ws ^Out(Err_str1) "TRN ", Bnk_rpt_seq.Trn, " is not found ", /; %End
		Move "Y" to Stat_sw
		Go to H600_end
	Else
		%Beg Ref_index CONN: Ent_msg_history(NOMOD); %End
	End-if.

	If Dbg_sw = "Y"
		display "2. Releasing TRN is found - ", Trn of Bnk_rpt_seq
	End-if.
	Evaluate True
		When ( RlsFlc_scr in Next_screen)
			%Beg Q_name = "FAL1_PNDQ"; %End
		When ( RlsS2b_scr in Next_screen)
			%Beg Q_name = "S2B1_PNDQ"; %End
	End-evaluate.
	Perform X100_Find_pndq thru X100_end.
    	
	If Q_found = "N"
		%Beg Compose_ws ^Out(Err_str1) "TRN ", Bnk_rpt_seq.Trn, " is not on ", Q_name, /; %End
		Move "Y" to Stat_sw
		Go to H600_end
	End-if.
	If Dbg_sw = "Y"
		display "3. Releasing TRN on q - ", Q_name, " - ", Trn of Bnk_rpt_seq
	End-if.
	%Beg
		Compose_ws ^OUT(Tmp_mem1) Rls_memo, ". BY: ", Menu_opr_union.Opr_login_id, /;
		ALLOC_END: Ent_msg_history(mod,
		  .Qname(
			.Idprod = null,
			.Idbank = Menu_Bnk_Union.Bnk_id,
			.Idloc = null,
			.Idcust = null,
			.Idname = Vfy_name),
			.Qtype = "QTYP$_SAF_PND_QUE",
			.Memo = Tmp_mem1,
		  ALLOC_JOIN: PndVfyq( insert,
			.Seq1 = Pndq.Seq1,
			.Ref_num = Pndq.Ref_num,
			.Systime Now ) );
		DELETE: Pndq(insert);
		BREAK: Ent_msg_history;
		BREAK: Ent_msg_subhist;
 	%End.
	
H600_END.
	Exit.

* Verify release of msgs from Falcon/S2B Pending Queues.
I050_FRCS_SCR.
    If Send_scr = "Y"
		Evaluate True
			When ( VfyFlc_scr in Next_screen)
				%Beg Q_name = "FAL_VFYCMD"; %End
			When ( VfyS2b_scr in Next_screen)
				%Beg Q_name = "S2B_VFYCMD"; %End
		End-evaluate
		Perform I150_set_values thru I150_end
		Perform I100_send_scr Thru I100_end
	Else
		Perform I200_reply_scr thru I200_end
    End-if.

    Evaluate True
		When (Scr_status of Scblist_scr = "GOLDCANCEL")
			Set Main_scr in Next_screen to True
			Perform I300_reject_scr thru I300_end
			Perform I400_break thru I400_end
			Move "Y" to Send_scr

		When (Scr_status of Scblist_scr = "CMD_CAN")
%^  Find an oper init in the description field and compare with the current one.
			Move Desc of Bnk_rpt_seq to Tmp_ws
			Move Desc_length of Bnk_rpt_seq_lengths to Tmp_ws_length
			%Beg Parse (^notrap) ^IN(Tmp_ws) VfyCmd_key, "by: ", Rls_opr, " at:", ^STR,/; %End
			If Dbg_sw = "Y"
				display "  ---------   ", vfycmd_key (1:vfycmd_key_length)
				display "  ---------   ", tmp_ws (1:tmp_ws_length)
				display "  ---------   ", rls_opr(1:rls_opr_length)
				display "  -----------  ", Opr_login_id of Menu_opr_union
			End-if
			If Opr_login_id of Menu_opr_union NOT = Rls_opr
				Evaluate True
					When ( VfyFlc_scr in Next_screen)
						%Beg 
							Q_name = "FAL1_PNDQ";
							Vfy_name = "FAL_VFYPNDQ"; 
						%End
					When ( VfyS2b_scr in Next_screen)
						%Beg 
							Q_name = "S2B1_PNDQ";
							Vfy_name = "S2B_VFYPNDQ"; 
						%End
				End-evaluate
				%Beg 
					BREAK: PndQ; 
					BREAK: PndVfyQ; 
					Rls_memo = Scblist_scr.CmdArg;
				%End
				%ACE_CONN_Q /<Menu_Bnk_Union.Bnk_id>///<Q_name> to Pndq for insert;
				%ACE_CONN_Q /<Menu_Bnk_Union.Bnk_id>///<Vfy_name> to PndVfyq for insert;
				Evaluate True
					When Desc of Bnk_rpt_seq (9:3) = "TRN"
						%Beg Ref1 = Bnk_rpt_seq.Trn; %End
						Perform I500_Do_cancel thru I500_end
						If ( Failure_is IN Ret_status)
							Display "Error cancelling TRN: ", Ref1, " ", Err_str
							If Err_str_length > 40 
								Move 40 to Err_str_length
							End-if
							%Beg Compose_ws ^OUT(Menu_msg1) "Error cancelling TRN: ", Ref1, " ", Err_str, /; %End
						End-if
					When OTHER
						%Beg PndVfyQ ^First; %End
						Perform until Seq_end_is in PndVfyQ_cursor
							%Beg
								Break: Ent_msg_history;
								Break: Ent_msg_union;
								Break: Ent_ftr_set;
								Break: Ent_debit_seq;
								Break: Ent_debit_set;
								PndVfyq CONN: Ent_msg_history (nomod,
									TOP: Ent_msg_union(nomod,
										.Ftr CONN: Ent_ftr_set(nomod) 
										.Dbt_seq Conn: Ent_debit_seq(notrap, nomod, ^First Conn:
											Ent_debit_set(nomod, notrap) )
								) );
								Ref1 = Ent_ftr_set.Trn_ref;
							%End
							If Dbg_sw = "Y"
								Display "CANCEL - Bnk_rpt_seq: ", Desc of Bnk_rpt_seq
							End-if
							Evaluate True
								When Desc of Bnk_rpt_seq (9:3) = "ALL"
									Perform I500_Do_cancel thru I500_end
									If ( Failure_is IN Ret_status)
										Display "Error cancelling TRN: ", Trn_ref of Ent_ftr_set, " ", Err_str
										If Err_str_length > 40 
											Move 40 to Err_str_length
										End-if
										%Beg Compose_ws ^OUT(Menu_msg1) "Error cancelling ALL TRNs ", " ", Err_str, /; %End
									End-if
								When Desc of Bnk_rpt_seq (9:3) = "F20"
									If Dbg_sw = "Y"
										Display "F20: Bnk_rpt_seq: ", Desc of Bnk_rpt_seq, " F20 from msg: ", Sbk_ref_num of Ent_debit_set
									End-if
									If FUNCTION UPPER-CASE(Desc of Bnk_rpt_seq(13:Sbk_ref_num_length of Ent_debit_set_lengths)) = 
									   FUNCTION UPPER-CASE(Sbk_ref_num of Ent_debit_set)
										Perform I500_Do_cancel thru I500_end
										If ( Failure_is IN Ret_status)
											Display "Error cancelling TRN: ", Trn_ref of Ent_ftr_set, " ", Err_str
											If Err_str_length > 40 
												Move 40 to Err_str_length
											End-if
											%Beg Compose_ws ^OUT(Menu_msg1) "Error cancelling msgs for this reference number", Err_str, /; %End
										End-if
									End-if 
								When Desc of Bnk_rpt_seq (9:3) = "DDA"
									If Dbg_sw = "Y"
										Display " !!!  ", Desc of Bnk_rpt_seq(13:Idkey_length of Dbt_account_lengths of Ent_debit_set_lengths)
										Display "   !  ", Idkey of Dbt_account of Ent_debit_set
									End-if
									If Desc of Bnk_rpt_seq(13:Idkey_length of Dbt_account_lengths of Ent_debit_set_lengths) = Idkey of Dbt_account of Ent_debit_set
										Perform I500_Do_cancel thru I500_end
										If ( Failure_is IN Ret_status)
											Display "Error cancelling TRN: ", Trn_ref of Ent_ftr_set, " ", Err_str
											If Err_str_length > 40 
												Move 40 to Err_str_length
											End-if
											%Beg Compose_ws ^OUT(Menu_msg1) "Error cancelling msgs for this DDA", Err_str, /; %End
										End-if
									End-if 
							End-evaluate
							%Beg PndVfyQ ^Next; %End
						End-perform
						%Beg
							Break: Ent_msg_history;
							Break: Ent_msg_union;
							Break: Ent_ftr_set;
							Break: Ent_debit_seq;
							Break: Ent_debit_set;
						%End
				End-evaluate
				%Beg PndCmdQ ^SEARCH (forward, eql, Key = Vfycmd_key); %End
				If Success_is in PndCmdq_status
					%Beg 
						DELETE: PndCmdQ(insert); 
						COMMIT: TRAN; 
					%End
				End-if
			Else
				%Beg Compose_ws ^Out(Menu_msg1) "You CANNOT cancel your own work. ", /; %End
				Move "N" to Send_scr
			End-if
			
		When (Scr_status of Scblist_scr = "CMD_VFY")
%^  Find an oper init in the description field and compare with the current one.
			Move Desc of Bnk_rpt_seq to Tmp_ws
			Move Desc_length of Bnk_rpt_seq_lengths to Tmp_ws_length
			%Beg Parse (^notrap) ^IN(Tmp_ws) VfyCmd_key, "by: ", Rls_opr, " at:", ^STR,/; %End
			If Dbg_sw = "Y"
				display "  ---------   ", vfycmd_key (1:vfycmd_key_length)
				display "  ---------   ", tmp_ws (1:tmp_ws_length)
				display "  ---------   ", rls_opr(1:rls_opr_length)
				display "  -----------  ", Opr_login_id of Menu_opr_union
			End-if
			If Opr_login_id of Menu_opr_union NOT = Rls_opr
				Evaluate True
					When ( VfyFlc_scr in Next_screen)
						%Beg Vfy_name = "FAL_VFYPNDQ"; %End
					When ( VfyS2b_scr in Next_screen)
						%Beg Vfy_name = "S2B_VFYPNDQ"; %End
				End-evaluate
				%Beg 
					BREAK: PndVfyQ; 
					Tmp_ws = Scblist_scr.CmdArg;
				%End
				%ACE_CONN_Q /<Menu_Bnk_Union.Bnk_id>///<Vfy_name> to PndVfyq for insert;
				Evaluate True
					When Desc of Bnk_rpt_seq (9:3) = "TRN"
						Call "FLMOVE_SUBS"  Using Bnk_id of Menu_Bnk_Union, Vfy_name(1:3), Trn of Bnk_rpt_seq, Frc_sw, 
								 Dbg_sw, Vfy_sw, Opr_login_id of Menu_opr_union, Tmp_ws, Err_str RETURNING Ret_status
						If ( Failure_is IN Ret_status)
							Display "Error releasing TRN: ", Trn of Bnk_rpt_seq, " ", Err_str
							If Err_str_length > 40 
								Move 40 to Err_str_length
							End-if
							%Beg Compose_ws ^OUT(Menu_msg1) "Error releasing TRN: ", Bnk_rpt_seq.Trn, " ", Err_str, /; %End
						End-if
					When OTHER
						%Beg PndVfyQ ^First; %End
						Perform until Seq_end_is in PndVfyQ_cursor
							%Beg
								Break: Ent_msg_history;
								Break: Ent_msg_union;
								Break: Ent_ftr_set;
								Break: Ent_debit_seq;
								Break: Ent_debit_set;
								PndVfyq CONN: Ent_msg_history (nomod,
									TOP: Ent_msg_union(nomod,
										.Ftr CONN: Ent_ftr_set(nomod) 
										.Dbt_seq Conn: Ent_debit_seq(notrap, nomod, ^First Conn:
											Ent_debit_set(nomod, notrap) )
								) );
							%End
							If Dbg_sw = "Y"
								Display "VERIFY - Bnk_rpt_seq: ", Desc of Bnk_rpt_seq
							End-if
							Evaluate True
								When Desc of Bnk_rpt_seq (9:3) = "ALL"
									Call "FLMOVE_SUBS"  Using Bnk_id of Menu_Bnk_Union, Vfy_name(1:3), Trn_ref of Ent_ftr_set, Frc_sw, 
											 Dbg_sw, Vfy_sw, Opr_login_id of Menu_opr_union, Tmp_ws, Err_str RETURNING Ret_status
									If ( Failure_is IN Ret_status)
										Display "Error releasing TRN: ", Trn_ref of Ent_ftr_set, " ", Err_str
										If Err_str_length > 40 
											Move 40 to Err_str_length
										End-if
										%Beg Compose_ws ^OUT(Menu_msg1) "Error releasing ALL TRNs ", " ", Err_str, /; %End
									End-if
								When Desc of Bnk_rpt_seq (9:3) = "F20"
									If Dbg_sw = "Y"
										Display "Bnk_rpt_seq: ", Desc of Bnk_rpt_seq, " F20 MSG - ", Sbk_ref_num of Ent_debit_set
									End-if
									If FUNCTION UPPER-CASE(Desc of Bnk_rpt_seq(13:Sbk_ref_num_length of Ent_debit_set_lengths)) = 
									   FUNCTION UPPER-CASE(Sbk_ref_num of Ent_debit_set)
										Call "FLMOVE_SUBS"  Using Bnk_id of Menu_Bnk_Union, Vfy_name(1:3), Trn_ref of Ent_ftr_set, Frc_sw, 
												 Dbg_sw, Vfy_sw, Opr_login_id of Menu_opr_union, Tmp_ws, Err_str RETURNING Ret_status
										If ( Failure_is IN Ret_status)
											Display "Error releasing TRN: ", Trn_ref of Ent_ftr_set, " ", Err_str
											If Err_str_length > 40 
												Move 40 to Err_str_length
											End-if
											%Beg Compose_ws ^OUT(Menu_msg1) "Error releasing msgs for this reference number", Err_str, /; %End
										End-if
									End-if 
								When Desc of Bnk_rpt_seq (9:3) = "DDA"
									If Dbg_sw = "Y"
										Display " !!!  ", Desc of Bnk_rpt_seq(13:Idkey_length of Dbt_account_lengths of Ent_debit_set_lengths)
										Display "   !  ", Idkey of Dbt_account of Ent_debit_set
									End-if
									If Desc of Bnk_rpt_seq(13:Idkey_length of Dbt_account_lengths of Ent_debit_set_lengths) = Idkey of Dbt_account of Ent_debit_set
										Call "FLMOVE_SUBS"  Using Bnk_id of Menu_Bnk_Union, Vfy_name(1:3), Trn_ref of Ent_ftr_set, Frc_sw, 
												 Dbg_sw, Vfy_sw, Opr_login_id of Menu_opr_union, Tmp_ws, Err_str RETURNING Ret_status
										If ( Failure_is IN Ret_status)
											Display "Error releasing TRN: ", Trn_ref of Ent_ftr_set, " ", Err_str
											If Err_str_length > 40 
												Move 40 to Err_str_length
											End-if
											%Beg Compose_ws ^OUT(Menu_msg1) "Error releasing msgs for this DDA", Err_str, /; %End
										End-if
									End-if 
							End-evaluate
							%Beg PndVfyQ ^Next; %End
						End-perform
						%Beg
							Break: Ent_msg_history;
							Break: Ent_msg_union;
							Break: Ent_ftr_set;
							Break: Ent_debit_seq;
							Break: Ent_debit_set;
						%End
				End-evaluate
				If Vfycmd_key(9:8) = "ALL_TRNS"  %^ if ALL_TRNs clean up the cmdq .
					%Beg PndCmdQ ^First; %End
					Perform until Seq_end_is in PndCmdQ_cursor
						%Beg 
							DELETE: PndCmdQ(insert); 
							PndCmdQ ^Next; 
						%End
					End-perform
					%Beg COMMIT: TRAN; %End
				Else
					%Beg PndCmdQ ^SEARCH (forward, eql, Key = Vfycmd_key); %End
					If Success_is in PndCmdq_status
						%Beg 
							DELETE: PndCmdQ(insert); 
							COMMIT: TRAN; 
						%End
					End-if
				End-if
			Else
				%Beg Compose_ws ^Out(Menu_msg1) "You CANNOT verify your own work. ", /; %End
				Move "N" to Send_scr
			End-if
			
		When (Scr_status of Scblist_scr = "CMD_MENU")
			CALL "MENU_PARSE" Using BY REFERENCE Cmdarg OF Scblist_scr RETURNING Ret_status
		    IF (Success_is in Ret_Status )
				Perform I300_reject_scr thru I300_end
				Perform I400_break thru I400_end
				%Beg Menu_xfr_vstr_ws = Null;  %End
				Move "Y" to Send_scr
				Move Zeros to W_s
				Call "MENU_TRANSFER" using by reference Menu_xfr_vstr_ws
		    Else
				%Beg  Menu_msg1 = Menu_Errmsg;  %End
				Move "N" to Send_scr
				Perform I200_reply_scr thru i200_end
    		End-if

		When ( Scr_status of Scblist_scr = "ENTR")
			%Beg
				BREAK: Ent_msg_history;
				Ref_index ^SEARCH (forward, eql, Key = Bnk_rpt_seq.Trn);
			%End
			If Success_is in Ref_index_status
				%Beg
					Ref_index CONN: Ent_msg_history(NOMOD);
					Ent_msg_history ^First;
				%End
				Perform Y100_make_msgp thru Y100_end  %^ Output is Prt_vstr80_text_seq, positioned on the 1st line
				Perform I300_reject_scr thru I300_end
				%Beg BREAK: Scblist_scr; %End
				%Beg Menu_Msg1 = "Use Command on previous screen to verify this TRN"; %End
				Perform Y150_show_msgp thru Y150_end
				If Scr_status of Scb_msgprint = "TIMOUT"
			    	%Beg Menu_xfr_vstr_ws = "*TO*";  %End
			    	Call "MENU_TRANSFER" using by reference Menu_xfr_vstr_ws
			    	Move Zeros to W_s
					Move "Y" to Send_scr
				Else
					Move "Y" to Send_scr
				End-if
			Else
				If Trn of Bnk_rpt_seq = "1"
					%Beg Compose_ws ^Out(Err_str1) "Use command to verify this action. ", /; %End
				Else
					%Beg Compose_ws ^Out(Err_str1) "TRN ", Bnk_rpt_seq.Trn, " not found. ", /; %End
				End-if
				Move "N" to Send_scr
			End-if
			%Beg 
				Menu_msg1 = Err_str1; 
				Menu_msg2 = Err_str2; 
			%End

		When (Scr_status of Scblist_scr = "TIMOUT")
	    	Perform I300_reject_scr thru I300_end
	    	Perform I400_break thru I400_end
	    	%Beg Menu_xfr_vstr_ws = "*TO*";  %End
	    	Call "MENU_TRANSFER" using by reference Menu_xfr_vstr_ws
	    	Move Zeros to W_s
			Move "Y" to Send_scr
	End-evaluate.

I050_END.
	Exit.

I100_SEND_SCR.	
		 
%^ Break common menu screen subjects 
    %Beg
		BREAK: Scblist_scr;
		Err_str1 = Null;
		Err_str2 = Null;

%^ Allocate common menu screen subjects 
		ALLOC_TEMP: Scblist_scr;
	%End.

	%Beg
%^ Place cursor back on last selected menu option
		Scblist_scr.Attributes.cursor_position = Save_cursor;	
		Scblist_scr.Attributes.Disp_only = F;

%^ Initialize screen control set 

		Scblist_scr(
			.Attributes.Clrta = T,
			.Fkeys (
		       .Entr.Enable = T,
		       .Goldcancel.Enable = T,
		       .Goldcancel.Noedit = T,
		       .Rlse.Enable = F,
		       .Timout.Enable = T,
		       .Timout.Noedit = T ),
			.Cmds (
		       .Cmd_rlsall.Enable = F,
		       .Cmd_rlsall.Noedit = F,
		       .Cmd_fltall.Enable = F,
		       .Cmd_fltall.Noedit = F,
		       .Cmd_flttrn.Enable = F,
		       .Cmd_flttrn.Noedit = F,
		       .Cmd_fltdda.Enable = F,
		       .Cmd_fltdda.Noedit = F,
		       .Cmd_fltf20.Enable = F,
		       .Cmd_fltf20.Noedit = F,
		       .Cmd_vfy.Enable = T,
		       .Cmd_vfy.Noedit = T,
		       .Cmd_can.Enable = T,
		       .Cmd_can.Noedit = T,
			   .Cmd_menu.Enable = T,
		       .Cmd_menu.Noedit = T),
		 	.msg1 = Menu_Msg1,
		 	.msg2 = Menu_Msg2 
		);
	%End.

	Evaluate True
		When ( VfyFlc_scr in Next_screen)
			%Beg Scblist_scr.Inq_name = "DISPLAY_INQ6"; %End
		When ( VfyS2b_scr in Next_screen)
			%Beg Scblist_scr.Inq_name = "DISPLAY_INQ7"; %End
	End-evaluate.

	%Beg
		SEND: Scblist_scr (
			.Menu_Bnk_Union send == Menu_Bnk_Union,
			.B_seq send == Bnk_rpt_seq );

	    Menu_msg1 = null;
	    Menu_msg2 = null;
    %End.

I100_END.
    Exit.
	
I150_SET_VALUES.
	Evaluate True
		When ( VfyFlc_scr in Next_screen)
			%Beg Q_name = "FAL_VFYCMD"; %End
		When ( VfyS2b_scr in Next_screen)
			%Beg Q_name = "S2B_VFYCMD"; %End
	End-evaluate.
	%Beg BREAK: PndCmdq; %End.
	%ACE_CONN_Q /<Menu_Bnk_Union.Bnk_id>///<Q_name> to PndCmdq for insert;
	%Beg
	    Break: Bnk_rpt_seq;
	    Alloc_temp: Bnk_rpt_seq(mod);
	%End.
	%Beg PndCmdq ^First; %End.
	move Zeros to Seq_cnt.
	Perform until Seq_end_is in PndCmdq_cursor
		%Beg Timezone_bank_ws = Menu_bnk_union.Bnk_id; %End
        Call "TIMEZONE_TIME" using
         by reference Timezone_bank_ws
         by reference Systime of PndCmdQ
         by value     %siz(Time_zone_ws)
         by reference Time_zone_ws
         by reference Time_zone_ws_length
         by reference Time_delta_ws
         returning Subject_status_ws

        If Success_is in Subject_status_ws
			%Beg Timezone_time_ws = Time_delta_ws; %End
        Else  
			%Beg Timezone_time_ws = PndCmdq.Systime; %End
        End-if
		If Vstr_key of PndCmdq (1:12) = "Release TRN:"
			Move Vstr_key of PndCmdq (13:16) to Tr_str
		Else
			Move "1" to Tr_str
		End-if 
		%Beg
			Time_str_ws = Timezone_time_ws;
			Parse ^IN(Time_str_ws) Dd_fil, "-", mm_fil, "-", cc_fil, yy_fil, " ", tt_fil, ".", ^str<2>, /;
			Compose_ws ^OUT(Time_st) Dd_fil, "-", Mm_fil, " ", Tt_fil, /;
			Compose_ws (^notrap) ^OUT(Desc_ws), PndCmdq.Vstr_key,
						" by: ", PndCmdq.Txt,
						" at: ", Time_st, 
						" Memo: ", PndCmdq.Memo, /;
		%End
		If Failure_is in Compose_ws_status
			%Beg
				Compose_ws ^OUT(Err_str), PndCmdq.Vstr_key,
						" by: ", PndCmdq.Txt,
						" at: ", Time_st, 
						" Memo: ", PndCmdq.Memo, /;
			%End
			Move Err_str to Desc_ws
			Move 78 to Desc_ws_length
		End-if
		%beg
			ALLOC_ELEM: Bnk_rpt_seq( (
				.Amount = <0>,
				.Trn = Tr_str,
				.Desc = Desc_ws));
		%End
		If Seq_cnt > 300
			%Beg COMMIT_TEMP: Bnk_rpt_seq; %End
			Move Zeros to Seq_cnt
		End-if
		Add 1 to Seq_cnt
		%Beg PndCmdq ^Next; %End
	End-Perform.
	%Beg Bnk_rpt_seq ^First; %End.
	If Seq_end_is in Bnk_rpt_seq_cursor
		%Beg Menu_msg1 = "There is nothing to verify."; %End
	End-if.
I150_END.
	Exit.

I200_REPLY_SCR.	
    If (Menu_msg1 NOT = Spaces)
	   	%Beg
	       Scblist_scr.Msg1 = Menu_msg1;
	       Menu_msg1 = null;
		%End
    End-if.

    If (Menu_msg2 NOT = Spaces)
	   	%Beg
	       Scblist_scr.Msg2 = Menu_msg2;
	       Menu_msg2 = null;
	   	%End
    End-if.

    %Beg
		Bnk_rpt_seq ^First;
	   	REPLY: Scblist_scr &;
	   	REPLY: Menu_Bnk_Union &;
		REPLY: Bnk_rpt_seq with: "VMSG$_RESTORE";
	
	   	Menu_msg1 = null;
	  	Menu_msg2 = null;
    %End.
I200_END.
    Exit.

I300_REJECT_SCR.
    %Beg
	    Scblist_scr(
			.Msg1 = null,
			.Msg2 = null );
	    Save_cursor = Scblist_scr.Attributes.Cursor_position;
		Menu_msg1 = null;
		Menu_msg2 = null;
    %End.
I300_END.
    Exit.

I400_BREAK.
	%Beg
		BREAK: Bnk_rpt_seq;
		BREAK: Scblist_scr; 
		BREAK: Pndq;
	%End.
I400_END.
    Exit.
	
I500_DO_CANCEL.
	Set Success_is in Ret_status to True.

	%Beg
		BREAK: Ent_msg_history;
		Ref_index ^SEARCH (forward, eql, Key = Ref1);
	%End.
	If Failure_is in Ref_index_status
		%Beg Compose_ws ^Out(Err_str1) "TRN ", Ref1, " is not found ", /; %End
		Set Failure_is in Ret_status to True
		Go to I500_end
	Else
		%Beg Ref_index CONN: Ent_msg_history(NOMOD); %End
	End-if.

* See if the msg on the pending q. Q_name must be = to the VFYPNDQ!!
	Move "N" to Q_found.
	Perform X110_Find_vfypndq thru X110_end.
	If Q_found = "N"
		%Beg Compose_ws ^Out(Err_str1) "TRN ", Ref1, " is not on ", Q_name, /; %End
		Set Failure_is in Ret_status to True
		Go to I500_end
	End-if.
	%Beg
		ALLOC_END: Ent_msg_history(mod,
		  .Qname(
			.Idprod = null,
			.Idbank = Menu_Bnk_Union.Bnk_id,
			.Idloc = null,
			.Idcust = null,
			.Idname = Q_name),
			.Qtype = "QTYP$_SAF_PND_QUE",
			.Memo = Rls_memo,
		  ALLOC_JOIN: Pndq( insert,
			.Seq1 = PndVfyq.Seq1,
			.Ref_num = PndVfyq.Ref_num,
			.Systime Now ) );
		DELETE: PndVfyq(insert);
		COMMIT: Tran;
 	%End.
	
I500_END.
	Exit.

X100_FIND_PNDQ.
%^  Q_name MUST be defined prior calling this perform
	%Beg
		BREAK: Pndq; 
		Ent_msg_history ^Last; 
	%End.
	Perform until Seq_beg_is in Ent_msg_history_cursor or Q_found = "Y"
		If Idname of Qname of Ent_msg_history = Q_name
			%Beg 
				BREAK: Pndq;
				Ent_msg_history (notrap, CONN: Pndq (notrap));
				Subject_status_ws = Ent_msg_history Status;
				Ent_msg_history (etrap);
				Del_bit = Pndq STATE.DELETED;
				Pndq(etrap);
			%End
			If Failure_is in Subject_status_ws or Success_is in Del_bit
				Move "N" to Q_found
			Else
				Move "Y" to Q_found
			End-if
	    End-if
	    If Idname of Qname of Ent_msg_history = "*SUB_HISTORY"
		    %Beg
				BREAK: Ent_msg_subhist;
				Ent_msg_history CONN: Ent_msg_subhist(nomod);
				Ent_msg_subhist ^Last;
			%End
			Perform until Seq_beg_is in Ent_msg_subhist_cursor or Q_found = "Y"
				If Idname of Qname of Ent_msg_subhist = Q_name
						%Beg 
							BREAK: Pndq;
							Ent_msg_subhist (notrap, CONN: Pndq (notrap));
							Subject_status_ws = Ent_msg_subhist Status;
							Ent_msg_subhist (etrap);
							Del_bit = Pndq STATE.DELETED;
							Pndq(etrap);
						%End
					If Failure_is in Subject_status_ws or Success_is in Del_bit
						Move "N" to Q_found
					Else
						Move "Y" to Q_found
					End-if
			  	End-if
				%Beg Ent_msg_subhist ^Prev; %End
			End-perform
			%Beg Ent_msg_history ^Prev; %End
		Else
		    %Beg Ent_msg_history ^Prev; %End
		End-if
	End-perform.
X100_END.
	Exit.

X110_FIND_VFYPNDQ.
%^  Vfy_name MUST be defined prior calling this perform
	%Beg
		BREAK: PndVfyq; 
		Ent_msg_history ^Last; 
	%End.
	Perform until Seq_beg_is in Ent_msg_history_cursor or Q_found = "Y"
		If Idname of Qname of Ent_msg_history = Vfy_name
			%Beg 
				BREAK: PndVfyq;
				Ent_msg_history (notrap, CONN: PndVfyq (notrap));
				Subject_status_ws = Ent_msg_history Status;
				Ent_msg_history (etrap);
				Del_bit = PndVfyq STATE.DELETED;
				PndVfyq(etrap);
			%End
			If Failure_is in Subject_status_ws or Success_is in Del_bit
				Move "N" to Q_found
			Else
				Move "Y" to Q_found
			End-if
	    End-if
	    If Idname of Qname of Ent_msg_history = "*SUB_HISTORY"
		    %Beg
				BREAK: Ent_msg_subhist;
				Ent_msg_history CONN: Ent_msg_subhist(nomod);
				Ent_msg_subhist ^Last;
			%End
			Perform until Seq_beg_is in Ent_msg_subhist_cursor or Q_found = "Y"
				If Idname of Qname of Ent_msg_subhist = Vfy_name
						%Beg 
							BREAK: PndVfyq;
							Ent_msg_subhist (notrap, CONN: PndVfyq (notrap));
							Subject_status_ws = Ent_msg_subhist Status;
							Ent_msg_subhist (etrap);
							Del_bit = PndVfyq STATE.DELETED;
							PndVfyq(etrap);
						%End
					If Failure_is in Subject_status_ws or Success_is in Del_bit
						Move "N" to Q_found
					Else
						Move "Y" to Q_found
					End-if
			  	End-if
				%Beg Ent_msg_subhist ^Prev; %End
			End-perform
			%Beg Ent_msg_history ^Prev; %End
		Else
		    %Beg Ent_msg_history ^Prev; %End
		End-if
	End-perform.
X110_END.
	Exit.

Y100_MAKE_MSGP.
	%Beg
		BREAK: Ent_msg_union;
		BREAK: Ent_ftr_set;
		BREAK: Ent_debit_seq;
		BREAK: Ent_debit_set;
		Ent_msg_history (nomod,
		  	TOP: Ent_msg_union(nomod,
	  				.Ftr CONN: Ent_ftr_set(nomod) ) );
%^				Ent_msg_history (nomod,notrap,
%^			  	TOP: Ent_msg_union(notrap,nomod,
%^			  				.Ftr CONN: Ent_ftr_set(notrap,nomod) ) );
		Ent_ftr_set (mod);
	%End.

	%Beg
	    BREAK: Prt_vstr80_text_seq;
	    Alloc_temp: Prt_vstr80_text_seq(mod);
	    My_cmp ^Out (Prt_vstr80_text_seq);
	    Save_cursor = null;
	    Menu_msg1 = null;
	    Menu_msg2 = null;
	%End.
	Call "CUST_CHECK_FORM". %^ This one makes Print_text_seq. But in SCB it is empty stub. So, try to show ent_text_seq
	%Beg
			BREAK: Prt_vstr80_text_seq;
			BREAK: Ent_text_seq;
			BREAK: Ent_vstr10k_seq;
			ALLOC_TEMP: Prt_vstr80_text_seq(mod);
	%End.

	If Transport_format of Ent_ftr_set = "RTP" or Src_code of Ent_ftr_set = "CCE" or = "MRT"
		%Beg Ent_msg_union.Txt_vstr10k_seq CONN: Ent_vstr10k_seq; %End
	Else
		%Beg Ent_msg_union.txt CONN: Ent_text_seq ^FIRST; %End
	End-if.

	%Beg
		Parm_cli_present_sw = Null;
		Parm_testkey_sw	    = "QPRINT";
		Prt_compose ^OUT( Prt_vstr80_text_seq.Txt )
			"[ TRN: ",
			Ent_ftr_set.trn_ref.trn_date,
			"-",
			Ent_ftr_set.trn_ref.trn_num,
			" ]", 
			"    [ AMOUNT: ",
			Ent_ftr_set.Amount( ^NUMBER(  ^COMMAS ) ),
			" ]",  /, ^ALLOC_ELEM;
		My_cmp ^OUT( Prt_vstr80_text_seq.txt)  /, ^ALLOC_ELEM ;
	%End.

	Call "FTRPRINT" using
	    by reference Parm_testkey_sw.
	%Beg
		BREAK: Print_text_seq;
	    Alloc_temp: Print_text_seq(mod);
	%End.
	
	Call "PAYSEQ" using
	    by reference Parm_cli_present_sw
	    by reference Parm_testkey_sw.

%^ If PAYSEQ decides to populate this seq ( for whatever unknown reaon). Make sure we append the text in here.
	%Beg Print_text_seq ^First; %End.

	Perform with test before until (Failure_is in Print_text_seq_Status  )
	    %Beg 
			My_cmp ^OUT( Prt_vstr80_text_seq.Txt ) Print_text_seq.txt, /, ^ALLOC_ELEM ; 
			Print_text_seq ^Next; 
		%End
	End-perform.
*
	If (Failure_is in Ent_text_seq_Status and NOT (Transport_format of Ent_ftr_set = "RTP" or Src_code of Ent_ftr_set = "CCE" or = "MRT")) or
	   (Failure_is in Ent_vstr10k_seq_Status and (Transport_format of Ent_ftr_set = "RTP" or Src_code of Ent_ftr_set = "CCE" or = "MRT"))
		%Beg 
			My_cmp ^OUT( Prt_vstr80_text_seq.Txt )
				"    ****  NO MESSAGE TEXT  ****" , /, ^ALLOC_ELEM;
			My_cmp ^OUT( Prt_vstr80_text_seq.Txt)  /, ^ALLOC_ELEM ; 
		%End
		display "     here 2.1"
	Else
		If Src_code of Ent_ftr_set = "SWF" or = "CAL"
			%Beg
				BREAK: Txt_seq;
				BREAK: Ent_vstr10k_seq;
				Parm_testkey_sw = "QPRINT";
			%End
			If Transport_format of Ent_ftr_set = "RTP" or Src_code of Ent_ftr_set = "CCE" or = "MRT"
				%Beg Ent_msg_union.Txt_vstr10k_seq CONN: Ent_vstr10k_seq ^First; %End 
				Set Incoming_msg in Iso20022_txt_flag to true
				%Beg BREAK: Print_text_seq; %End
				Call "ISO20022_PRINT"
				%Beg Print_text_seq ^First; %End
				Perform until Seq_end_is in print_text_seq_cursor
					%Beg 
						My_cmp ^OUT( Prt_vstr80_text_seq.Txt ) Print_text_seq.txt, /, ^ALLOC_ELEM ; 
						Print_text_seq ^Next; 
					%End
				End-perform

			Else
 				%Beg Ent_msg_union.txt CONN: Txt_seq ^FIRST; %End
				Call "SWFPRINT" USING Parm_testkey_sw
			End-if

			%Beg 
				BREAK: Txt_seq; 
				BREAK: Ent_vstr10k_seq;
			%End
		Else
			%Beg 
		    	My_cmp ^OUT( Prt_vstr80_text_seq.Txt )
					"    **** MESSAGE TEXT ****", /,^ALLOC_ELEM;
		    	My_cmp ^OUT(Prt_vstr80_text_seq.txt) /, ^ALLOC_ELEM ; 
			%End
		End-if
	End-if.
	%Beg
	    BREAK: Ent_text_seq;
		BREAK: Ent_vstr10k_seq;
	    FIRST: Ent_msg_history ;
		My_cmp	^OUT( Prt_vstr80_text_seq.Txt )
				"    MESSAGE HISTORY SEQUENCE    ", /, ^ALLOC_ELEM;
	   	My_cmp ^OUT( Prt_vstr80_text_seq.txt)
				"--------------------------------", /, ^ALLOC_ELEM ;
	    BREAK: Mh_hist_seq ; 
	    BREAK: Mh_text_seq ;
		   	Ent_msg_history EQUATE: Mh_hist_seq;
	%End.
	Set Success_Is in msg_hist_arg to true.
			
	Call "MESSAGE_HISTORY" using
			by reference msg_hist_arg.		%^ Success_Is means detailed history, not summary.
			
	%Beg Mh_text_seq ^First; %End.
	Perform with test before until (Failure_is in Mh_text_seq_Status  )
	    %Beg 
				My_cmp ^OUT( Prt_vstr80_text_seq.Txt ) Mh_text_seq.txt, /, ^ALLOC_ELEM ; 
				Mh_text_seq ^Next; 
		%End
	End-perform.
Y100_END.
	Exit.

Y150_SHOW_MSGP.
%^ Break common menu screen subjects 
    %Beg
		   BREAK: Scb_msgprint;
%^ Allocate common menu screen subjects 
		   ALLOC_TEMP: Scb_msgprint;
	%End.

	%Beg
%^ Place cursor back on last selected menu option
%^		   Scb_msgprint.Attributes.cursor_position = Save_cursor;	
		Scb_msgprint.Attributes.Disp_only = F;

%^ Initialize screen control set 

	  	Scb_msgprint(
			.Attributes.Clrta = T,
			.Fkeys (
			   .Entr.Enable = F,
		       .Goldcancel.Enable = T,
		       .Goldcancel.Noedit = T,
		       .Rlse.Enable = F,
		       .Timout.Enable = T,
		       .Timout.Noedit = T ),
				.Cmds (
		       .Cmd_menu.Enable = F,
		       .Cmd_menu.Noedit = F),
		 		.msg1 = Menu_Msg1,
		 		.msg2 = Menu_Msg2 
		    );

		Prt_vstr80_text_seq ^First;
				
		SEND: Scb_msgprint (
			.Menu_Bnk_Union send == Menu_Bnk_Union,
			.R_seq send == Prt_vstr80_text_seq );

	    	Menu_msg1 = null;
	    	Menu_msg2 = null;
    %End.
	Evaluate True
		When (Scr_status of Scb_msgprint = "TIMOUT")
		When (Scr_status of Scb_msgprint = "GOLDCANCEL")
			%Beg
				Scb_msgprint(
		   			.Msg1 = null,
		   			.Msg2 = null );
%^				Save_cursor = Scb_msgprint.Attributes.Cursor_position;
				Menu_msg1 = null;
				Menu_msg2 = null;
				Break: Scb_msgprint;
			%End
	End-evaluate.	
Y150_END.
	Exit.

Z900_BREAK_ALL.
    Perform B400_break thru B400_end.
    Perform C400_break thru C400_end.
    Perform D400_break thru D400_end.
    Perform E400_break thru E400_end.
    Perform F400_break thru F400_end.
    Perform G400_break thru G400_end.
Z900_END.
    Exit.



%Module	REJECT;

*	This dummy module exist so that we can link it with parts of Inquiry
*	functions. We handle all rejects ourselves here.

%^ %MAR
%^ 	.default	displacement,long
%^ %End

%linkage
01	reject_value_ls		pic 9(4) comp.

%Procedure using reject_value_ls.

A1_MAIN.
	%EXIT PROGRAM.
