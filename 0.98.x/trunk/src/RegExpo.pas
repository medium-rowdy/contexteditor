// Copyright (c) 2009, ConTEXT Project Ltd
// All rights reserved.
//
// Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
//
// Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
// Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
// Neither the name of ConTEXT Project Ltd nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

unit regexpo;

interface

{$I ConTEXT.inc}

uses
  winprocs,wintypes,registry,classes,sysutils, dialogs;

const
  REG_KEY = '\Software\Eden\ConTEXT\';

{$I-}

Procedure ExportRegSettings;



implementation


Function dblBackSlash(t:string):string;
var k:longint;
begin
  result:=t;                                       {Strings are not allowed to have}
  for k:=length(t) downto 1 do                     {single backslashes}
     if result[k]='\' then insert('\',result,k);
end;






Procedure ExportBranch (rootsection : Integer;
                                regroot:String;
                                filename:String);

var reg:tregistry;
    f:textfile;
    p:PCHAR;


    Procedure ProcessBranch(root:string);                   {recursive sub-procedure}
    var values,keys:tstringlist; i,j,k:longint;
        s,t:string;                            {longstrings are on the heap, not on the stack!}
    begin
         Writeln(f);                           {write blank line}
         case rootsection of
           HKEY_CLASSES_ROOT    :s:='HKEY_CLASSES_ROOT';
           HKEY_CURRENT_USER    :s:='HKEY_CURRENT_USER';
           HKEY_LOCAL_MACHINE   :s:='HKEY_LOCAL_MACHINE';
           HKEY_USERS           :s:='HKEY_USERS';
           HKEY_PERFORMANCE_DATA:s:='HKEY_PERFORMANCE_DATA';
           HKEY_CURRENT_CONFIG  :s:='HKEY_CURRENT_CONFIG';
           HKEY_DYN_DATA        :s:='HKEY_DYN_DATA';
         end;
         Writeln(f,'['+s+'\'+root+']');       {write section name in brackets}


       reg.OpenKey(root,false);
       values:=tstringlist.create;
       keys:=tstringlist.create;
       keys.clear;
       values.clear;
       reg.getvaluenames (values);            {get all value names}
       reg.getkeynames   (keys);              {get all sub-branches}


       for i:=0 to values.count-1 do          {write all the values first}
       begin
            s:=values[i];
            t:=s;                             {s=value name}
            if s=''
                  then s:='@'                 {empty means "default value", write as @}
                  else s:='"' + s + '"';      {else put in quotes}
            write(f,dblbackslash(s)+'=');     {write the name of the key to the file}

            Case reg.Getdatatype(t) of        {What type of data is it?}

              rdString,rdExpandString:        {String-type}
                  Writeln(f,'"'      + dblbackslash(reg.readstring(t)+'"'));

              rdInteger      :                {32-bit unsigned long integer}
                  Writeln(f,'dword:' + inttohex(reg.readinteger(t),8));

                  
              {write an array of hex bytes if data is "binary." Perform a line feed
               after approx. 25 numbers so the line length stays within limits}

              rdBinary       :
              begin
                write(f,'hex:');
                j:=reg.getdatasize(t);      {determine size}
                getmem(p,j);                {Allocate memory}
                reg.ReadBinaryData(t,p^,J); {read in the data, treat as pchar}
                for k:=0 to j-1 do
                begin
                  Write(f,inttohex(byte(p[k]),2)); {Write byte as hex}
                  if k<>j-1 then                   {not yet last byte?}
                  begin
                    write(f,',');                  {then write Comma}
                    if (k>0) and ((k mod 25)=0)    {line too long?}
                       then writeln(f,'\');        {then write Backslash + lf}
                  end; {if}
                end;   {for}
                freemem(p,j);                      {free the memory}
                writeln(f);                        {Linefeed}
              end;
              ELSE writeln(f,'""'); {write an empty string if datatype illegal/unknown}
            end;{case}
       end; {for}

       reg.closekey;

       {value names all done, no longer needed}
       values.free;

       {Now al values are written, we process all subkeys}
       {Perform this process RECURSIVELY...}
       for i:=0 to keys.count-1 do
          ProcessBranch(root+'\'+keys[i]);

       keys.free; {this branch is ready}
    end;

begin
  if regroot[length(regroot)]='\' then        {No trailing backslash}
     setlength(regroot,length(regroot)-1);
  Assignfile(f,filename);                     {create a text file}
  rewrite(f);
  IF ioresult<>0 then EXIT;
  Writeln(f,'REGEDIT4');                      {"magic key" for regedit}

  reg:=tregistry.create;
  try
     reg.rootkey:=rootsection;
     ProcessBranch(regroot);                  {Call the function that writes the branch and all subbranches}
   finally
    reg.free;                                 {ready}
    close(f);
  end;
end;

Procedure ExportRegSettings;
var
  dlgSave :TSaveDialog;
  s       :string;
begin
  dlgSave:=TSaveDialog.Create(nil);

  try
    dlgSave.DefaultExt:='reg';
    dlgSave.Filter:='Registry files (*.reg)|*.reg|All files (*.*)|*.*';
    dlgSave.Options:=dlgSave.Options+[ofOverwritePrompt];

    if (dlgSave.Execute) then begin
      s:=REG_KEY;
      if s[1]='\' then Delete(s,1,1);
      ExportBranch(HKEY_CURRENT_USER,s,dlgSave.FileName);
    end;
  finally
    dlgSave.Free;
  end;
end;

end.

