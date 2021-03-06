// Copyright (c) 2009, ConTEXT Project Ltd
// All rights reserved.
//
// Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
//
// Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
// Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
// Neither the name of ConTEXT Project Ltd nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

unit uCommon;

interface

{$I ConTEXT.inc}

uses
  Windows,
  Messages,
  SysUtils,
  Classes,
  Graphics,
  Forms,
  Dialogs,
  SynEditHighlighter,
  Registry,
  SynEdit,
  SynEditKeyCmds,
  uHighlighterProcs,
  SynEditAutoComplete,
  ShellAPI,
  ImgList,
  Controls,
  ComCtrls,
  Math,
  JclStrings,
  JclFileUtils;

const
  MAX_HIGHLIGHTERS_COUNT = 255;
  MAX_USEREXEC_SET_COUNT = 64;
  MAX_USEREXEC_KEYS_COUNT = 4;

  WM_REPAINTALLMDI = WM_USER + 1;
  WM_CLEAR_ICON_CAPTION = WM_USER + 2;
  WM_CHECK_FILETIMES = WM_USER + 4;
  WM_ACTIVATE_MAIN_WINDOW = WM_USER + 5;
  WM_FILE_EXPLORER_LOAD_DIR = WM_USER + 6;
  WM_CLOSE_PARENT_WINDOW = WM_USER + 7;
  WM_EDITING_FILE_CLOSING = WM_USER + 8;
  WM_EDITING_FILE_OPENING = WM_USER + 9;

type
  TStartAction = (saNone, saCreateNewDocument, saOpenLastFiles);

  TFgBg = record
    Fg: TColor;
    Bg: TColor;
  end;

  THighLighter = record
    name: string;
    ext: string;
    HelpFile: string;
    CommentBegStr: string;
    CommentEndStr: string;
    CommentLineStr: string;
    BlockAutoindent: boolean;
    BlockBegStr: string;
    BlockEndStr: string;
    HL: TSynCustomHighLighter;
    CT: TSynAutoComplete;
    ColorCurrentLine: boolean;
    OverrideTxtFgColor: boolean;
    Custom: boolean;
    ChangedAttr: boolean;
    //                       Multi            :boolean;
  end;

  pTHighLighter = ^THighLighter;

  THighLighters = array[0..MAX_HIGHLIGHTERS_COUNT - 1] of THighLighter;
  pTHighLighters = ^THighLighters;

  TUserExecSaveMode = (uesCurrentFile, uesAllFiles, uesNone);

  TUserExecDef = record
    ExecCommand: string[255];
    StartDir: string[255];
    Params: string[255];
    Window: integer;
    Hint: string[255];
    SaveMode: TUserExecSaveMode;
    UseShortName: boolean;
    CaptureOutput: boolean;
    ScrollConsole: boolean;
    PauseAfterExecution: boolean;
    IdlePriority: boolean;
    ParserRule: string[255];
  end;

  pTUserExecDef = ^TUserExecDef;

  TUserExecDefArray = array[0..MAX_USEREXEC_KEYS_COUNT - 1] of TUserExecDef;

  TUserExecCfg = array[0..MAX_USEREXEC_SET_COUNT - 1] of record
    Ext: string[255];
    Def: TUserExecDefArray;
  end;

  TTabsMode = (tmHardTabs, tmTabsToSpaces);
  TTextFormat = (tfNormal, tfUnix, tfMac, tfUnicode, tfUnicodeBigEndian, tfUTF8);

  TEditorCfg = record
    Options: TSynEditorOptions;
    FindTextAtCursor: boolean;
    ExtraLineSpacing: integer;
    InsertCaret: TSynEditCaretType;
    OverwriteCaret: TSynEditCaretType;
    RightEdge: integer;
    RightEdgeVisible: boolean;
    GutterWidth: integer;
    GutterVisible: boolean;
    TabWidth: integer;
    BlockIndent: integer;
    FontName: string;
    FontSize: integer;
    GutterFontName: string;
    GutterFontSize: integer;
    OEMFontName: string;
    OEMFontSize: integer;
    LineNumbers: boolean;
    UndoAfterSave: boolean;
    HideMouseWhenTyping: boolean;
    UserExecSetCount: integer;
    UserExecCfg: TUserExecCfg;
    ShowFindReplaceInfoDlg: boolean;
    ShowExecInfoDlg: boolean;
    Language: string;
    TabsMode: TTabsMode;
    ConsoleFontName: string;
    ConsoleFontSize: integer;
    C_BlockIndent: integer;
    DefaultHighlighter: string;
    DefaultTextFormat: TTextFormat;
    PrjManagerRelPath: boolean;
    LastOpenFilesList: TStringList;
    LastOpenProject: string;
    LastActiveFile: string;
    TrimTrailingSpaces: boolean;
    RulerVisible: boolean;
    WordwrapByDefault: boolean;
    ShowWordwrapGlyph: boolean;
  end;

  pTEditorCfg = ^TEditorCfg;

  TFindOrigin = (foFromCursor, foFromTop);
  TFindScope = (fsSelection, fsCurrentFile, fsAllFiles);
  TFindDirection = (fdNext, fdPrev);

  TFindDlgCfg = record
    Origin: TFindOrigin;
    Scope: TFindScope;
    CaseSensitive: boolean;
    WholeWords: boolean;
    RegExp: boolean;
    Direction: TFindDirection;
  end;

  pTFindDlgCfg = ^TFindDlgCfg;

  pTString = ^string;

  TApplyOtherColors = procedure of object;
  TApplyEditorOptions = procedure of object;

  TmyCustomHighLighter = class(TSynCustomHighLighter);

const
  DEFAULT_OPTIONS: TSynEditorOptions = [eoAltSetsColumnMode,
    eoAutoIndent, eoDragDropEditing, eoDropFiles,
    eoScrollPastEol, eoShowScrollHint,
    {eoTabsToSpaces,}eoSmartTabs, {eoTrimTrailingSpaces,}
    eoSpecialLineDefaultFg, eoTabIndent, {eoSmartTabDelete,}
    eoGroupUndo, eoHideShowScrollbars, eoAutoSizeMaxScrollWidth];

  DEFAULT_TAB_WIDTH = 8;

  ATTR_SELECTION_STR = 'Selection';
  ATTR_RIGHTEDGE_STR = 'Right edge';
  ATTR_CURRENT_LINE_STR = 'Current Line';
  ATTR_MATCHED_BRACES = 'Matched braces';

  DEFAULT_ALL_FILES_FILTER = 'All Files (*.*)|*.*';

  // DW should we change this at some stage in the future?
  CONTEXT_REG_KEY = '\Software\Eden\ConTEXT\';
  BOTTOM_WINDOW_OPTIONS_REG_KEY = CONTEXT_REG_KEY + 'fmBottomWindow\';
  BMP_MASK = $123456;

  IMPLEMENTED_HIGHLIGHTERS_COUNT = 17;

  ////////////////////////////////////
const
  CUSTOM_KEYCOMMANDS_COUNT = 24;

  ecLoCase = ecUserFirst + 0;
  ecUpCase = ecUserFirst + 1;
  ecToggleCase = ecUserFirst + 2;
  ecGoToLine = ecUserFirst + 3;
  ecReformatParagraph = ecUserFirst + 4;
  ecToggleSelectionMode = ecUserFirst + 5;
  ecFind = ecUserFirst + 6;
  ecFindNext = ecUserFirst + 7;
  ecFindPrevious = ecUserFirst + 8;
  ecSortBlock = ecUserFirst + 9;
  ecFillBlock = ecUserFirst + 10;
  ecRemoveTrailingSpaces = ecUserFirst + 11;
  ecToggleWordwrap = ecUserFirst + 12;
  ecToggleCommentBlock = ecUserFirst + 13;
  ecSelTextInBraces = ecUserFirst + 14;
  ecInsertTimeStamp = ecUserFirst + 15;
  ecCopyFilenameToClipboard = ecUserFirst + 16;
  ecParagraphBegin = ecUserFirst + 17;
  ecParagraphEnd = ecUserFirst + 18;
  ecSelParagraphBegin = ecUserFirst + 19;
  ecSelParagraphEnd = ecUserFirst + 20;
  ecConvertSpacesToTabs = ecUserFirst + 21;
  ecConvertTabsToSpaces = ecUserFirst + 22;
  ecRemoveComments = ecUserFirst + 23;

  CustomEditorCommandStrs: array[0..CUSTOM_KEYCOMMANDS_COUNT - 1] of TIdentMapEntry = (
    (Value: ecLoCase; Name: 'ecLoCase'),
    (Value: ecUpCase; Name: 'ecUpCase'),
    (Value: ecToggleCase; Name: 'ecToggleCase'),
    (Value: ecGoToLine; Name: 'ecGoToLine'),
    (Value: ecReformatParagraph; Name: 'ecReformatParagraph'),
    (Value: ecToggleSelectionMode; Name: 'ecToggleSelectionMode'),
    (Value: ecFind; Name: 'ecFind'),
    (Value: ecFindNext; Name: 'ecFindNext'),
    (Value: ecFindPrevious; Name: 'ecFindPrevious'),
    (Value: ecSortBlock; Name: 'ecSortBlock'),
    (Value: ecFillBlock; Name: 'ecFillBlock'),
    (Value: ecRemoveTrailingSpaces; Name: 'ecRemoveTrailingSpaces'),
    (Value: ecToggleWordwrap; Name: 'ecToggleWordwrap'),
    (Value: ecToggleCommentBlock; Name: 'ecToggleCommentBlock'),
    (Value: ecSelTextInBraces; Name: 'ecSelTextInBraces'),
    (Value: ecInsertTimeStamp; Name: 'ecInsertTimeStamp'),
    (Value: ecCopyFilenameToClipboard; Name: 'ecCopyFilenameToClipboard'),
    (Value: ecParagraphBegin; Name: 'ecParagraphBegin'),
    (Value: ecParagraphEnd; Name: 'ecParagraphEnd'),
    (Value: ecSelParagraphBegin; Name: 'ecSelParagraphBegin'),
    (Value: ecSelParagraphEnd; Name: 'ecSelParagraphEnd'),
    (Value: ecConvertSpacesToTabs; Name: 'ecConvertSpacesToTabs'),
    (Value: ecConvertTabsToSpaces; Name: 'ecConvertTabsToSpaces'),
    (Value: ecRemoveComments; Name: 'ecRemoveComments')
    );
  ////////////////////////////////////

var
  HIGHLIGHTERS_COUNT: integer;

  HighLighters: array[0..MAX_HIGHLIGHTERS_COUNT - 1] of THighLighter;

  EditorCfg: TEditorCfg;
  ApplicationDir: string;
  StartDir: string;

  OptionsChanged: boolean;
  KeyMapChanged: boolean;

  KeyMap: TSynEditKeyStrokes;
  KeyMapDefault: TSynEditKeyStrokes;

function GetHighlightersList: TStringList;

procedure AddAdditionalToHighlighter(HL: TSynCustomHighLighter);
function FindAttrIndex(name: string; HL: TSynCustomHighLighter): integer;
function GetHighlighterRec(HL: TSynCustomHighLighter): pTHighlighter;
function GetHighlighterRecByName(s: string): pTHighlighter;
function FindHighlighterForFile(fname: string): pTHighlighter;

function ReadRegistryString(reg: TRegistry; name: string; default: string): string;
function ReadRegistryInteger(reg: TRegistry; name: string; default: integer): integer;
function ReadRegistryBool(reg: TRegistry; name: string; default: boolean): boolean;
function ReadRegistryFloat(reg: TRegistry; name: string; default: double): double;

function TranslateShortcut(msg: TWMKey; var ShiftState: TShiftState): integer;
procedure SetLengthyOperation(Value: boolean);

procedure DlgErrorOpenFile(fname: string; ParentHandle: HWND = 0);
procedure DlgErrorSaveFile(fname: string; ParentHandle: HWND = 0);
function DlgReplaceFile(FileName: string; ParentHandle: HWND = 0): boolean;

function Q_SpacesToTabs(const S: string; TabStop: Integer): string;
function Q_TabsToSpaces(const S: string; TabStop: Integer): string;

function ExplorerFileListToStrings(List: string): TStringList;
procedure AddLastDir(fname: string);
function HighlighterToDlgFilterIndex(Filter: string; HL: TSynCustomHighLighter): integer;
function QuoteFilename(fname: string): string;
function RemoveQuote(fname: string): string;
function GetDefaultExtForFilterIndex(Filter: string; FilterIndex: integer): string;
procedure SetDefaultExtFromDlgFilter(var FileName: string; Filter: string; FilterIndex: integer);
procedure CopyExtToDefaultFilter(HL: pTHighlighter);
function DecomposeFileFilter(FullFilter: string; var FilterName, Filter: string): boolean;
function MakeDoubleAmpersand(s: string): string;
function GetFileLongName(S: string): string;

procedure GetDefaultAnimation;
procedure SetAnimation(Value: Boolean);
function Get16x16FileIcon(fname: string): TIcon;
function Get16x16FileIconBmp(fname: string): TBitmap;
function AddBitmapToImageList(ImageList: TImageList; ResourceName: string; MaskColor: TColor): integer;
function AddIconToImageList(ImageList: TImageList; ResourceName: string): integer;

procedure SelectListViewItem(ListView: TListView; Index: integer);
procedure ExchangeListViewItemProperties(Item1, Item2: TListItem; const CopyCaption: boolean = TRUE);
procedure CopyListViewItemProperties(Source, Destination: TListItem; const CopyCaption: boolean = TRUE);
procedure ShellExecuteExternalFile(Filename: string; const Params: string = '');

{$IFDEF DEBUG}
procedure _StartTimer;
procedure _StopTimer;
{$ENDIF}

implementation

uses
  uMultiLanguage,
  fMain,
  uEnvOptions;

{$IFDEF DEBUG}
var
  _PerformanceTimeFreq, _PerformanceStartTimeCount: Int64;
{$ENDIF}

  //------------------------------------------------------------------------------------------

function GetHighlightersList: TStringList;
var
  fHighlighters: TStringList;
begin
  fHighlighters := TStringList.Create;

  fHighlighters.Sorted := TRUE;
  GetHighlighters(fmMain, fHighlighters, FALSE);

  result := fHighlighters;
end;
//------------------------------------------------------------------------------------------

procedure AddAdditionalToHighlighter(HL: TSynCustomHighLighter);
var
  myHL: TmyCustomHighLighter;
  Attr: TSynHighlighterAttributes;
begin
  myHL := TmyCustomHighLighter(HL);

  Attr := TSynHighlighterAttributes.Create(ATTR_SELECTION_STR, ATTR_SELECTION_STR);
  Attr.Style := [];
  Attr.Foreground := clHighlightText;
  Attr.Background := clHighlight;
  myHL.AddAttribute(Attr);

  Attr := TSynHighlighterAttributes.Create(ATTR_RIGHTEDGE_STR, ATTR_RIGHTEDGE_STR);
  Attr.Style := [];
  Attr.Foreground := clSilver;
  Attr.Background := -1;
  myHL.AddAttribute(Attr);

  Attr := TSynHighlighterAttributes.Create(ATTR_CURRENT_LINE_STR, ATTR_CURRENT_LINE_STR);
  Attr.Style := [];
  Attr.Foreground := clBlack;
  Attr.Background := clYellow;
  myHL.AddAttribute(Attr);

  if (HL <> fmMain.hlTxt) then
  begin
    Attr := TSynHighlighterAttributes.Create(ATTR_MATCHED_BRACES, ATTR_MATCHED_BRACES);
    Attr.Style := [];
    Attr.Foreground := clRed;
    Attr.Background := clWindow;
    myHL.AddAttribute(Attr);
  end;
end;
//------------------------------------------------------------------------------------------

function FindHighlighterForFile(fname: string): pTHighlighter;
var
  s: string;
  i, ii: integer;
begin
  s := '*' + LowerCase(ExtractFileExt(fname));
  result := @HighLighters[0];

  if (Length(s) > 0) then
  begin
    i := 0;
    while (i < HIGHLIGHTERS_COUNT) do
    begin
      ii := Pos(s, LowerCase(HighLighters[i].ext));
      if (ii > 0) and (((Length(HighLighters[i].ext) > ii + Length(s)) and (HighLighters[i].ext[ii + Length(s)] = ';')) or (Length(HighLighters[i].ext) = Length(s) + ii - 1)) then
      begin
        result := @HighLighters[i];
        BREAK;
      end;
      inc(i);
    end;
  end;
end;
//------------------------------------------------------------------------------------------

function FindAttrIndex(name: string; HL: TSynCustomHighLighter): integer;
var
  i: integer;
  found: boolean;
begin
  i := 0;
  found := FALSE;
  name := UpperCase(name);

  if Assigned(HL) then
    while (i < HL.AttrCount) do
    begin
      found := (name = UpperCase(HL.Attribute[i].Name));
      if found then
        BREAK;
      inc(i);
    end;

  if found then
    result := i
  else
    result := 0;
end;
//------------------------------------------------------------------------------------------

function GetHighlighterRec(HL: TSynCustomHighLighter): pTHighlighter;
var
  i: integer;
begin
  result := nil;
  i := 0;
  while (i < HIGHLIGHTERS_COUNT) do
  begin
    if (Highlighters[i].HL = HL) then
    begin
      result := @Highlighters[i];
      BREAK;
    end;
    inc(i);
  end;
end;
//------------------------------------------------------------------------------------------

function GetHighlighterRecByName(s: string): pTHighlighter;
var
  i: integer;
begin
  result := nil;
  s := UpperCase(s);
  i := 0;
  while (i < HIGHLIGHTERS_COUNT) do
  begin
    if (UpperCase(Highlighters[i].Name) = s) then
    begin
      result := @Highlighters[i];
      BREAK;
    end;
    inc(i);
  end;
end;
//------------------------------------------------------------------------------------------

function ReadRegistryString(reg: TRegistry; name: string; default: string): string;
begin
  if reg.ValueExists(name) then
    result := reg.ReadString(name)
  else
    result := default;
end;
//------------------------------------------------------------------------------------------

function ReadRegistryInteger(reg: TRegistry; name: string; default: integer): integer;
begin
  if reg.ValueExists(name) then
    result := reg.ReadInteger(name)
  else
    result := default;
end;
//------------------------------------------------------------------------------------------

function ReadRegistryBool(reg: TRegistry; name: string; default: boolean): boolean;
begin
  if reg.ValueExists(name) then
    result := reg.ReadBool(name)
  else
    result := default;
end;
//------------------------------------------------------------------------------------------

function ReadRegistryFloat(reg: TRegistry; name: string; default: double): double;
begin
  if reg.ValueExists(name) then
    result := reg.ReadFloat(name)
  else
    result := default;
end;
//------------------------------------------------------------------------------------------

function TranslateShortcut(msg: TWMKey; var ShiftState: TShiftState): integer;
// poziva se is eventa OnShortCut, vra�a virtual key code i shiftstate
begin
  ShiftState := [];

  if ((GetKeyState(VK_SHIFT) and $80) > 0) then
    Include(ShiftState, ssShift);

  if ((GetKeyState(VK_MENU) and $80) > 0) then
    Include(ShiftState, ssAlt);

  if ((GetKeyState(VK_CONTROL) and $80) > 0) then
    Include(ShiftState, ssCtrl);

  result := msg.charcode;
end;
//------------------------------------------------------------------------------------------

procedure SetLengthyOperation(Value: boolean);
const
  cnt: integer = 0;
begin
  if Value then
    inc(cnt)
  else
    dec(cnt);

  cnt := Max(cnt, 0);

  if (cnt > 0) then
    Screen.Cursor := crHourGlass
  else
    Screen.Cursor := crDefault;
end;
//------------------------------------------------------------------------------------------

procedure DlgErrorOpenFile(fname: string; ParentHandle: HWND = 0);
begin
  if (ParentHandle = 0) then
    ParentHandle := Application.Handle;

  MessageBox(ParentHandle,
    PChar(Format(mlStr(ML_EDIT_ERR_OPENING, 'Error opening ''%s''.'), [fname])),
    PChar(mlStr(ML_EDIT_ERR_CAPTION, 'Error')),
    MB_ICONERROR + MB_OK);
end;
//------------------------------------------------------------------------------------------

procedure DlgErrorSaveFile(fname: string; ParentHandle: HWND = 0);
begin
  if (ParentHandle = 0) then
    ParentHandle := Application.Handle;

  MessageBox(ParentHandle,
    PChar(Format(mlStr(ML_EDIT_ERR_SAVING, 'Error saving ''%s''.'), [fname])),
    PChar(mlStr(ML_EDIT_ERR_CAPTION, 'Error')),
    MB_ICONERROR + MB_OK);
end;
//------------------------------------------------------------------------------------------

function DlgReplaceFile(FileName: string; ParentHandle: HWND = 0): boolean;
begin
  if FileExists(FileName) then
  begin
    if (ParentHandle = 0) then
      ParentHandle := Application.Handle;

    result := MessageBox(ParentHandle,
      PChar(Format(mlStr(ML_MAIN_OVERWRITE_WARNING, 'File ''%s'' already exists.'#13'Do you want to replace it?'), [FileName])),
      PChar(mlStr(ML_MAIN_CONFIRM_CAPT, 'Confirm')),
      MB_ICONWARNING + MB_OKCANCEL) = IDOK
  end
  else
    result := TRUE;
end;
//------------------------------------------------------------------------------------------

function Q_TabsToSpaces(const S: string; TabStop: Integer): string;
var
  I, L, T: Integer;
  P: ^Char;
begin
  T := TabStop;
  L := 0;
  for I := 1 to Length(S) do
    if S[I] <> #9 then
    begin
      Inc(L);
      Dec(T);
      if T = 0 then
        T := TabStop;
    end
    else
    begin
      Inc(L, T);
      T := TabStop;
    end;
  SetString(Result, nil, L);
  T := TabStop;
  P := Pointer(Result);
  for I := 1 to Length(S) do
    if S[I] <> #9 then
    begin
      P^ := S[I];
      Dec(T);
      Inc(P);
      if T = 0 then
        T := TabStop;
    end
    else
    begin
      repeat
        P^ := ' ';
        Dec(T);
        Inc(P);
      until T = 0;
      T := TabStop;
    end;
end;
//------------------------------------------------------------------------------------------

function Q_SpacesToTabs(const S: string; TabStop: Integer): string;
var
  I, L, SC, T: Integer;
  P: ^Char;
  C: Char;
begin
  L := 0;
  T := TabStop;
  SC := 0;
  for I := 1 to Length(S) do
  begin
    if T = 0 then
    begin
      Dec(SC);
      T := TabStop;
      if SC > 0 then
        Dec(L, SC);
      SC := 0;
    end;
    Inc(L);
    C := S[I];
    Dec(T);
    if C <> ' ' then
    begin
      if C = #9 then
        T := TabStop;
      SC := 0;
    end
    else
      Inc(SC);
  end;
  if T = 0 then
  begin
    Dec(SC);
    if SC > 0 then
      Dec(L, SC);
  end;
  SetString(Result, nil, L);
  T := TabStop;
  P := Pointer(Result);
  SC := 0;
  for I := 1 to Length(S) do
  begin
    if T = 0 then
    begin
      T := TabStop;
      if SC <> 0 then
      begin
        if SC > 1 then
          P^ := #9
        else
          P^ := ' ';
        Inc(P);
        SC := 0;
      end;
    end;
    C := S[I];
    Dec(T);
    if C <> ' ' then
    begin
      while SC <> 0 do
      begin
        P^ := ' ';
        Dec(SC);
        Inc(P);
      end;
      P^ := C;
      if C = #9 then
        T := TabStop;
      Inc(P);
    end
    else
      Inc(SC);
  end;
  if SC <> 0 then
    if T <> 0 then
      repeat
        P^ := ' ';
        Dec(SC);
        Inc(P);
      until SC = 0
    else if SC > 1 then
      P^ := #9
    else
      P^ := ' ';
end;
//------------------------------------------------------------------------------------------

function ExplorerFileListToStrings(List: string): TStringList;
var
  str: TStringList;
  n: integer;
begin
  str := TStringList.Create;

  while (Pos(';', List) > 0) do
  begin
    n := Pos(';', List);

    str.Add(Copy(List, 1, n - 1));
    Delete(List, 1, n);
  end;

  if (Length(List) > 0) then
    str.Add(List);

  result := str;
end;
//------------------------------------------------------------------------------------------

procedure AddLastDir(fname: string);
var
  s: string;
begin
  // zapamti zadnji dir ako nije floppy
  s := ExtractFilePath(ExpandFileName(fname));

  if (Length(s) > 0) and (not CharInSet(UpperCase(s)[1], ['A', 'B'])) then
    EnvOptions.LastDir := s;
end;
//------------------------------------------------------------------------------------------

function HighlighterToDlgFilterIndex(Filter: string; HL: TSynCustomHighLighter): integer;
var
  str: TStringList;
  i: integer;
begin
  result := 1;

  str := TStringList.Create;

  while (Length(Filter) > 0) do
  begin
    i := Pos('|', Filter);

    if (i > 0) then
    begin
      inc(i);
      while (i <= Length(Filter)) and (Filter[i] <> '|') do
        inc(i);
      str.Add(Copy(Filter, 1, i - 1));
      Delete(Filter, 1, i);
    end;
  end;

  i := str.IndexOf(HL.DefaultFilter);
  if (i > -1) then
    result := i + 1;

  str.Free;
end;
//------------------------------------------------------------------------------------------

function QuoteFilename(fname: string): string;
begin
  if (Length(fname) > 0) then
  begin
    if (fname[1] <> '"') then
      fname := '"' + fname;
    if (fname[Length(fname)] <> '"') then
      fname := fname + '"';
  end;

  result := fname;
end;
//------------------------------------------------------------------------------------------

function RemoveQuote(fname: string): string;
begin
  if (Length(fname) > 0) and (fname[1] = '"') then
    Delete(fname, 1, 1);
  if (Length(fname) > 0) and (fname[Length(fname)] = '"') then
    SetLength(fname, Length(fname) - 1);

  result := fname;
end;
//------------------------------------------------------------------------------------------

function GetDefaultExtForFilterIndex(Filter: string; FilterIndex: integer): string;
var
  n: integer;
  p: PChar;
  ext: string;
begin
  p := PChar(Filter);

  ext := '';
  n := 0;
  while (n <= FilterIndex) do
  begin
    while (p^ <> #0) do
    begin
      if p^ = '|' then
        inc(n);

      inc(p);

      if (n = (FilterIndex - 1) * 2 + 1) then
      begin
        while not CharInSet(p^, [#00, '|', ';']) do
        begin
          ext := ext + p^;
          inc(p);
        end;
        BREAK;
      end;
    end;
    inc(n);
  end;

  // obri�i sve zvjezdice i to�ku
  while (Pos('*', ext) > 0) do
    Delete(ext, Pos('*', ext), 1);
  while (Pos('.', ext) > 0) do
    Delete(ext, Pos('.', ext), 1);

  result := Trim(ext);
end;
//------------------------------------------------------------------------------------------

procedure SetDefaultExtFromDlgFilter(var FileName: string; Filter: string; FilterIndex: integer);
var
  ext: string;
begin
  ext := GetDefaultExtForFilterIndex(Filter, FilterIndex);

  if (Length(ext) > 0) then
  begin
    SetLength(FileName, Length(FileName) - Length(ExtractFileExt(FileName)));
    FileName := FileName + '.' + ext;
  end;
end;
//------------------------------------------------------------------------------------------

procedure CopyExtToDefaultFilter(HL: pTHighlighter);
var
  FilterName: string;
  FilterExt1: string;
  FilterExt2: string;
  n: integer;
begin
  n := Pos('|', HL^.HL.DefaultFilter);
  if (n = 0) then
    EXIT;

  if (Pos('(', HL^.HL.DefaultFilter) > 0) then
    FilterName := Trim(Copy(HL^.HL.DefaultFilter, 1, Pos('(', HL^.HL.DefaultFilter) - 1))
  else
    FilterName := Trim(Copy(HL^.HL.DefaultFilter, 1, n - 1));

  FilterExt1 := HL^.ext;

  FilterExt2 := FilterExt1;

  repeat
    n := Pos(';', FilterExt1);
    if (n > 0) then
      FilterExt1[n] := ',';
  until (n = 0);

  repeat
    n := Pos(' ', FilterExt2);
    if (n > 0) then
      Delete(FilterExt2, n, 1);
  until (n = 0);

  HL^.HL.DefaultFilter := Format('%s (%s)|%s', [FilterName, FilterExt1, FilterExt2]);
end;
//------------------------------------------------------------------------------------------

function DecomposeFileFilter(FullFilter: string; var FilterName, Filter: string): boolean;
var
  n: integer;
begin
  n := Pos('|', FullFilter);
  result := (n > 0);

  if result then
  begin
    FilterName := Copy(FullFilter, 1, n - 1);
    Filter := Copy(FullFilter, n + 1, 255);
  end;
end;
//------------------------------------------------------------------------------------------

function MakeDoubleAmpersand(s: string): string;
begin
  StrReplace(s, '&', '&&', [rfReplaceAll, rfIgnoreCase]);
  result := s;
end;
//------------------------------------------------------------------------------------------

function GetFileLongName(S: string): string;
begin
  if FileExists(S) then
    result := PathGetLongName(ExpandFileName(S))
  else
    result := S;
end;
//------------------------------------------------------------------------------------------

procedure GetDefaultAnimation;
var
  Info: TAnimationInfo;
begin
  Info.cbSize := SizeOf(TAnimationInfo);
  SystemParametersInfo(SPI_GETANIMATION, SizeOf(Info), @Info, 0);
  DefaultWindowsAnimated := BOOL(Info.iMinAnimate);
end;
//------------------------------------------------------------------------------------------

procedure SetAnimation(Value: Boolean);
var
  Info: TAnimationInfo;
begin
  if DefaultWindowsAnimated then
  begin
    Info.cbSize := SizeOf(TAnimationInfo);
    BOOL(Info.iMinAnimate) := Value;
    SystemParametersInfo(SPI_SETANIMATION, SizeOf(Info), @Info, 0);
  end;
end;
//------------------------------------------------------------------------------------------

function Get16x16FileIcon(fname: string): TIcon;
var
  icon: TIcon;
  FileInfo: TShFileInfo;
begin
  SHGetFileInfo(PChar(fname), 0, FileInfo, SizeOf(FileInfo), SHGFI_SMALLICON or SHGFI_ICON);

  icon := TIcon.Create;

  if (FileInfo.hIcon > 0) then
    icon.Handle := FileInfo.hIcon
  else
    icon.Handle := LoadIcon(hInstance, 'ICO_FILE_MISSING');

  result := icon;
end;
//------------------------------------------------------------------------------------------

function Get16x16FileIconBmp(fname: string): TBitmap;
var
  icon: TIcon;
  bmp: TBitmap;
  //  icobmp   :TBitmap;
begin
  icon := Get16x16FileIcon(fname);

  (* cudno! - ovo mi je radilo u D4, a u D5 daje neke buhice umjesto fine 16x16 bitmape...
    bmp:=TBitmap.Create;
    bmp.Width:=16;
    bmp.Height:=16;

    icobmp:=TBitmap.Create;
    icobmp.Width:=32;
    icobmp.Height:=32;
    icobmp.Canvas.Brush.Color:=BMP_MASK;
    icobmp.Canvas.FillRect(Bounds(0,0,32,32));
    icobmp.Canvas.Draw(0,0,icon);

    bmp.Canvas.StretchDraw(Bounds(0,0,16,16),icobmp);

    icon.Free;
    icobmp.Free;
  *)

  bmp := TBitmap.Create;
  bmp.Width := 16;
  bmp.Height := 16;
  bmp.Canvas.Brush.Color := BMP_MASK;
  bmp.Canvas.FillRect(Bounds(0, 0, 32, 32));
  bmp.Canvas.Draw(0, 0, icon);

  icon.Free;

  result := bmp;
end;
//------------------------------------------------------------------------------------------

function AddBitmapToImageList(ImageList: TImageList; ResourceName: string; MaskColor: TColor): integer;
var
  bmp: TBitmap;
begin
  bmp := TBitmap.Create;
  bmp.Handle := LoadBitmap(hInstance, PChar(ResourceName));
  result := ImageList.AddMasked(bmp, MaskColor);
  bmp.Free;
end;
//------------------------------------------------------------------------------------------

function AddIconToImageList(ImageList: TImageList; ResourceName: string): integer;
var
  icon: TIcon;
begin
  icon := TIcon.Create;
  icon.Handle := LoadIcon(hInstance, PChar(ResourceName));
  result := ImageList.AddIcon(icon);
  icon.Free;
end;
//------------------------------------------------------------------------------------------

procedure SelectListViewItem(ListView: TListView; Index: integer);
begin
  with ListView do
  begin
    if (Index > Items.Count - 1) then
      Index := Items.Count - 1;
    if (Index < 0) then
      Index := 0;

    if (Index >= 0) and (Index < Items.Count) and Assigned(Items[Index]) then
    begin
      Selected := Items[Index];
      ItemFocused := Selected;

      if Assigned(Selected) then
      begin
        Selected.Focused := TRUE;
        Selected.MakeVisible(FALSE);
      end;
    end;
  end;
end;
//------------------------------------------------------------------------------------------

procedure CopyListViewItemProperties(Source, Destination: TListItem; const CopyCaption: boolean = TRUE);
var
  i: integer;
begin
  Destination.SubItems.Clear;
  for i := 0 to Source.SubItems.Count - 1 do
    Destination.SubItems.Add(Source.SubItems[i]);
  Destination.Data := Source.Data;
  Destination.ImageIndex := Source.ImageIndex;

  if CopyCaption then
    Destination.Caption := Source.Caption;
end;
//------------------------------------------------------------------------------------------

procedure ExchangeListViewItemProperties(Item1, Item2: TListItem; const CopyCaption: boolean = TRUE);
var
  TmpItem: TListItem;
begin
  TmpItem := TListItem.Create(TListView(Item1.ListView).Items);
  CopyListViewItemProperties(Item1, TmpItem, CopyCaption);
  CopyListViewItemProperties(Item2, Item1, CopyCaption);
  CopyListViewItemProperties(TmpItem, Item2, CopyCaption);
  TmpItem.Free;
end;
//------------------------------------------------------------------------------------------

procedure ShellExecuteExternalFile(Filename: string; const Params: string = '');
begin
  ShellExecute(Application.Handle, 'open', PChar(Filename), PChar(Params), '', SW_SHOW);
end;
//------------------------------------------------------------------------------------------
{$IFDEF DEBUG}

procedure _StartTimer;
begin
  if (_PerformanceTimeFreq = 0) then
    QueryPerformanceFrequency(_PerformanceTimeFreq);

  QueryPerformanceCounter(_PerformanceStartTimeCount);
end;

procedure _StopTimer;
var
  _Time: int64;
  _EndTime: int64;
begin
  QueryPerformanceCounter(_EndTime);
  _Time := Round(((_EndTime - _PerformanceStartTimeCount) / _PerformanceTimeFreq) * 1000);

  ShowMessage(IntToStr(_Time));
end;
{$ENDIF}
//------------------------------------------------------------------------------------------

end.

