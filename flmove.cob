%MODULE FLMOVE <MAIN>;
**********************************************************
* Copyright (c) 2016 Standard Chartered Bank             *
* Aug 2016           Standard Chartered Bank             *
* Author: J.Novak                                        *
**********************************************************

%def		<ENTFTR>	%`SBJ_DD_PATH:ENTFTR_FSECT.DDL`		%end
%def		<ACE>			%`SBJ_DD_PATH:ACE_FSECT.DDL`			%end

%def		<FLMOVE_WS>
Err_str:		Vstr(160);
Ret_status: 	Boolean;
Dbg_sw:			Str(1);
Mode_sw:		Str(1) = "N";
Opr_id:			Str(6) = "$$$JN1";
Memo_ws:		Vstr(80);
%end


%Work
01  F57_start		Pic 9.
01  Force_sw		Pic X 		Value "N".
01  Trn_no 			Pic X(16).
01  Bnk				Pic X(3) 	Value "SCB".
01  Line_ws			Pic X(3).

%PROCEDURE.

A100_MAIN_PROGRAM.
*
	Display "Enter the line name (FAL or S2B) " No advancing.
	Accept Line_ws.
	Display "Enter TRN of the ", Line_ws, " " No advancing.
	Accept Trn_no.

	%Beg 
		Dbg_sw = "Y"; 
		Memo_ws = "Testing move program";
	%End.
	Call "FLMOVE_SUBS"  Using  Bnk, Line_ws, Trn_no, Force_sw, Dbg_sw, Opr_id, Memo_ws, Err_str
	RETURNING Ret_status.
    If ( Failure_is IN Ret_status)
	     Display "NO GOOD - Stat - ", Err_str
	Else
		Display Err_str(1:80)
		Display Err_str(81:)
	End-if.

%EXIT PROGRAM.

