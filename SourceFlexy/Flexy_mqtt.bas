Rem --- eWON start section: Cyclic Section
eWON_cyclic_section:
Rem --- eWON user (start)
Rem --- eWON user (end)
End
Rem --- eWON end section: Cyclic Section
Rem --- eWON start section: Init Section
eWON_init_section:
Rem --- eWON user (start)
  ONCHANGE "trig","GOTO gettime" 

TSET 2,5
  ONTIMER 2, "GOTO SimulateTag"
 CLS
//////////////setting allll here//////////////
tagheader$ = "MY999952"
siteid$ = "METTUBE"
ip$="10.0.0.53"
Last_ConnStatus% = 0
//Configure MQTT Connection parameters
ClientID$ ="Flexy1"
//MQTTBrokerURL$="124.158.10.133"
MQTTBrokerURL$="192.168.0.23"
 //MQTTPort$ ="3003"
 MQTTPort$ ="1883"
 Topic$="Flexy/Data1"
Goto CONNECTMQTT 
Function GetTime$()
 $a$ = Time$
 $GetTime$ = $a$(7 To 10) + "-" + $a$(4 To 5) + "-" + $a$(1 To 2) + " " + $a$(12 To 13)+":"+$a$(15 To 16)+":"+$a$(18 To 19)
EndFn
CONNECTMQTT:
MQTT "OPEN", ClientID$ , MQTTBrokerURL$
//MQTT "SetParam", "Username", Username$
//MQTT "SetParam", "Password", Password$
MQTT "SETPARAM", "PORT", MQTTPort$ 
MQTT "SETPARAM", "KEEPALIVE", "10"
SETSYS PRG,"RESUMENEXT",1  //Continue in case of error at MQTT "CONNECT"
MQTT "CONNECT"
//If an error is raised --> Log a message
ErrorReturned% = GETSYS PRG,"LSTERR"
IF ErrorReturned% = 28 THEN 
  Print "[MQTT SCRIPT] WAN interface not yet ready"
  trig@ = 0
  SETSYS PRG,"RESUMENEXT",0
 ENDif 


ONTIMER 1, "GOTO SENDDATA"
TSET 1,1 //publish every 5 seconds
END

SENDDATA:
//Read MQTT Connection Status (5 = Connected, other values = Not connected)
ConnStatus% = MQTT "STATUS"
IF Last_ConnStatus% <> ConnStatus% THEN
  IF ConnStatus% = 5 THEN //Connection is back online
    trig@ = 1
    Print "[MQTT SCRIPT] Flexy connected to Broker"
  ELSE
    trig@ = 0
    Print "[MQTT SCRIPT] Flexy disconnected from Broker"
  ENDIF
  Last_ConnStatus% = ConnStatus%
ENDIF
//IF Connected --> Publish messages
IF ConnStatus% = 5 THEN //If connected --> Publish
  SETSYS PRG,"RESUMENEXT",1
 // MsgToPublish$ = SFMT <TAG_EWON>@,20,0,"%f"
  json$ =         '{'
	json$ = json$ +'"tag_header":"'+tagheader$+'",'
	json$ = json$ +'"site_id":"'+siteid$+'",'
	json$ = json$ +'"ip":"'+ip$+'",'
	json$ = json$ +'"datetime": "'+@GetTime$()+'",'
	json$ = json$ +    '"data": ['
	json$ = json$ +    '{"tagname":'+'"TT-GN21",'
	json$ = json$ +    '"define":'+'"Temperature",'
	json$ = json$ +    '"value":"' + STR$ Temperature@ + '"},'
	json$ = json$ +    '{"tagname":'+'"FT-GN21-RAW",'
	json$ = json$ +    '"define":'+'"Flow",'
	json$ = json$ +    '"value":"' + STR$ Flow@ + '"},'
	json$ = json$ +    '{"tagname":'+'"FT-GN21-COM",'
	json$ = json$ +    '"define":'+'"CompensatedFlow",'
	json$ = json$ +    '"value":"' + STR$ CompensatedFlow@ + '"},'
	json$ = json$ +    '{"tagname":'+'"PT-GN21",'
	json$ = json$ +    '"define":'+'"Pressure",'
	json$ = json$ +    '"value":"' + STR$ Pressure@ + '"},'
	json$ = json$ +    '{"tagname":'+'"FQ-GN21",'
	json$ = json$ +    '"define":'+'"Tier1",'
	json$ = json$ +    '"value":"' + STR$ Tier1@ + '"},'
	json$ = json$ +    '{"tagname":'+'"FQ-GN22",'
	json$ = json$ +    '"define":'+'"Tier2",'
	json$ = json$ +    '"value":"' + STR$ Tier2@ + '"}'
	json$ = json$ + ']}'
  MQTT "PUBLISH",  Topic$ , json$, 0,0
  PRINT "[MQTT SCRIPT] Message published to the MQTT broker"
  ErrorReturned = GETSYS PRG,"LSTERR"
  IF ErrorReturned=28 THEN  //ERROR while publishing --> No connection --> Better to close and open
   MQTT "CLOSE"
   GOTO CONNECTMQTT
  ENDIF
ELSE //If not connected --> Save message in file
  Print "[MQTT SCRIPT] Flexy not connected"
ENDIF
END

  //ONTIMER 2, "GOTO gettime"
SimulateTag:
simdata@ =simdata@+0.5
If simdata@>100 Then 
simdata@ =0 
Endif
Temperature@ = simdata@*1.2
Flow@ = simdata@*1.3
CompensatedFlow@ = simdata@*1.4
Pressure@ = simdata@*1.5
Tier1@ = simdata@*1.6
Tier2@ =simdata@*1.7 

END

gettime:
If trig@ =1 Then 
  Goto "reconnect"
Else 
  Goto "lost"
Endif
END

lost:
If flag@ = 0 Then
  temp$ = Time$
  //temp2$ = temp$(1 To 2) +"/" +temp$(4 To 5) +"/" +temp$(7 To 10) + " " + temp$(12 To 13) + ":"+temp$(15 To 16)+":"+ temp$(18 To 19)
  time_down% = GETSYS PRG, "TIMESEC"
  //time_down$ = Time$
  Print "record time down: " +temp$ +":"  STR$time_down% 
  flag@=1
Else 
  Print "done record time" 
Endif
END
reconnect:

temp3$ = Time$
temp4$ = temp3$(1 To 2) +"/" +temp3$(4 To 5) +"/" +temp3$(7 To 10) + " " + temp3$(12 To 13) + ":"+temp3$(15 To 16)+":"+ temp3$(18 To 19)
time_end% = GETSYS PRG, "TIMESEC"
Print "flexy reconnect to sever ! " +STR$time_end% 
//time_end$ = Time$
//time_duration% = FNCV time_end$, 40 - FNCV time_down$, 40 

time_duration% = time_end%  - time_down%
//time_hour4% = time_duration%/(3600*4)//get hour .

 time_hour4%= time_duration%/(60)
duration@ =  time_duration%/(5*3600)
count_h@ = duration@
start_down@ = SFMT time_down%, 40

end_down@ = SFMT time_end%, 40
print "duration " + time_hour4%
If (count_h@  <2 ) Then 
    Print "lost <4"+ STR$time_hour4%
      @send_ftp( "Temperature","TT_FN21",time_down% ,time_end% )
     @send_ftp( "Flow","FT-GN21-RAW",time_down% ,time_end% )
     @send_ftp( "CompensatedFlow","FT-GN21-COM",time_down% ,time_end% )
     @send_ftp( "Pressure","PT-GN21",time_down% ,time_end% )
     @send_ftp( "Tier1","FQ-GN21",time_down% ,time_end% )
     @send_ftp( "Tier2","FQ-GN22",time_down% ,time_end% )
  
Else 
  //time_start_s% = time_down% -30*60
  time_start_s% = time_down%
  FOR i% =1 TO count_h@ 
    time_end_c% = time_down% + 3600*5*i%
    //print "c1"+ STR$time_end_c%
    time_end_c1% = time_end_c% 

    @send_ftp( "Temperature","TT_FN21",time_start_s% ,time_end_c% )
    @send_ftp( "Flow","FT-GN21-RAW",time_start_s% ,time_end_c% )
    @send_ftp( "CompensatedFlow","FT-GN21-COM",time_start_s% ,time_end_c% )
    @send_ftp( "Pressure","PT-GN21",time_start_s% ,time_end_c% )
    @send_ftp( "Tier1","FQ-GN21",time_start_s% ,time_end_c% )
    @send_ftp( "Tier2","FQ-GN22",time_start_s% ,time_end_c% )


     time_start_s% = time_end_c%
    Print "FTP break file!"
    NEXT i%
    @send_ftp( "Temperature","TT_FN21",time_end_c% ,time_end% )
    @send_ftp( "Flow","FT-GN21-RAW",time_end_c% ,time_end% )
    @send_ftp( "CompensatedFlow","FT-GN21-COM",time_end_c% ,time_end% )
    @send_ftp( "Pressure","PT-GN21",time_end_c% ,time_end% )
    @send_ftp( "Tier1","FQ-GN21",time_end_c% ,time_end% )
    @send_ftp( "Tier2","FQ-GN22",time_end_c% ,time_end% )



  Print "time_from_start_end" + STR$time_duration%
Endif 

flag@ = 0
END
Function send_ftp($tagname$,$define$,$start_time%,$end_time%)
$start_time% =$start_time% 
start_time_parse$ = SFMT $start_time%, 40
time_start_ftp$ =  start_time_parse$(1 To 2) + start_time_parse$(4 To 5) + start_time_parse$(7 To 10) + "_" + start_time_parse$(12 To 13) + start_time_parse$(15 To 16)+ start_time_parse$(18 To 19)
 //$end_time% =  $end_time%
end_time_parse$ =  SFMT $end_time%, 40
time_end_ftp$  =  end_time_parse$(1 To 2) + end_time_parse$(4 To 5) + end_time_parse$(7 To 10) + "_" + end_time_parse$(12 To 13) + end_time_parse$(15 To 16)+ end_time_parse$(18 To 19)
Print "call ftp send" + time_start_ftp$  +":  :" +time_end_ftp$
filename1$ = tagheader$ +"_"+siteid$+"_"+$define$+"_"+$tagname$+"_"+ time_end_ftp$  +".csv"
stringfile$="[$dtHL$ftT$et"+time_end_ftp$+"$st"+time_start_ftp$ +"$fnirc_"+$tagname$+".txt$tn"+$tagname$+"]"
//PUTFTP filename$,"[$dtHL$ftT$et"+time_end_ftp$+"$st"+time_start_ftp$ +"$fnirc_"+$tagname$+".txt$tn"+$tagname$+"]"

PUTFTP filename1$,stringfile$
TSET 3,1
ONTIMER 3, "GOTO Delay"
ENDFN
Delay:
//PRINT " Send FTP file " + filename$+"  "+stringfile$
TSET 3,0
END
Rem --- eWON user (end)
End
Rem --- eWON end section: Init Section