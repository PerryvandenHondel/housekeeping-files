//
//	HousekeepingFiles
//
//	Delete all old files from a folder based on last modified date
//
//
//		function ReadSettingKey(section: string; key: string): string;
//		function FileTimeToDTime(FTime: TFileTime): TDateTime;
//		procedure ProcessFile(p: string; sr: TSearchRec);
//		procedure FindFilesRecur(strFolderStart: string);
//

program HousekeepingFiles;


uses
	DateUtils,			// For DaysBetween
	Windows,
	SysUtils,
	UTextFile,
	USupportLibrary;
	

const
	CONF_NAME = 		'housekeeping-files.conf';
	
	
var
	sets: string;
	aSets: TStringArray;
	x: integer;
	folderStart: string;
	folderKeep: integer;


function ReadSettingKey(section: string; key: string): string;
//
//	Read a Key from a section from a config (.conf) file.
//
//	[Section]
//	Key1=10
//	Key2=Something
//
//	Usage:
//		WriteLn(ReadSettingKey('Section', 'Key2'));  > returns 'Something'
//		When not found, returns a empty string.
//		
//	Needs updates for checking, validating data.
//
var
	r: Ansistring;					// Return value of this function
	sectionName: string;
	inSection: boolean;
	l: Ansistring;					// Line buffer
	p: string;					// Path of the config file
	conf: CTextFile;			// Class Text File 
begin
	p := GetProgramFolder() + '\' + CONF_NAME;
	conf := CTextFile.Create(p);
	conf.OpenFileRead();

	r := '';
	sectionName := '['+ section + ']';
	inSection := false;
	repeat
		l := conf.ReadFromFile();
		//WriteLn(inSection, #9, l);
		
		if Pos(sectionName, l) > 0 then
		begin
			//WriteLn('FOUND SECTION: ', sectionName);
			inSection := true;
		end;
		
		if inSection = true then
		
		begin
			if (Pos(key, l) > 0) then
			begin
				//WriteLn('Found key ', key, ' found in section ', sectionName);
				r := RightStr(l, Length(l) - Length(key + '='));
				//WriteLn(r);
				Break; // break the loop
			end; // of if 
		end; // of if inSection
		
	until conf.GetEof();
	conf.CloseFile();
	ReadSettingKey := r;
	//WriteLn;
	//WriteLn('ReadSettingKey(): ', r, 'LEN=', Length(r));
end; // of function ReadSettingKey
	
	
function FileTimeToDTime(FTime: TFileTime): TDateTime;
//
//	Source: http://forum.lazarus.freepascal.org/index.php?topic=10869.0
//
var
	LocalFTime: TFileTime;
	STime: TSystemTime;
begin
	FileTimeToLocalFileTime(FTime, LocalFTime);
	FileTimeToSystemTime(LocalFTime, STime);
	FileTimeToDTime := SystemTimeToDateTime(STime);
end; // of function FileTimeToDTime

	
procedure ProcessFile(p: string; sr: TSearchRec; keepDays: integer);
//
//	Process a single file
//
//	p			Path of the file
//	sr			Search Record containing information about the file in p	
//	keepDays	Keep files younger the x days
//
var
	dtCreate: TDateTime;
	dtAccess: TDateTime;
	dtModified: TDateTime;
begin
	WriteLn('ProcessFile(): ', p);
	
	//dtCreate := FileTimeToDTime(SR.FindData.ftCreationTime);	  	// Created
	dtAccess := FileTimeToDTime(SR.FindData.ftLastAccessTime);		// Last Accessed
	//dtModified := FileTimeToDTime(SR.FindData.ftLastWriteTime);		// Last Modified
	
	WriteLn('            Size:    ', sr.Size);
	//WriteLn('         Created: ', FormatDateTime('YYYY-MM-DD hh:nn:ss', dtCreate), ' ', DaysBetween(Now(), dtCreate));
	WriteLn('   Last accessed: ', FormatDateTime('YYYY-MM-DD hh:nn:ss', dtAccess), ' ', DaysBetween(Now(), dtAccess));
	//WriteLn('   Last modified: ', FormatDateTime('YYYY-MM-DD hh:nn:ss', dtModified), ' ', DaysBetween(Now(), dtModified));
	
	if DaysBetween(Now(), dtAccess) > keepDays then
	begin
		WriteLn('*** DELETE FILE ***');
	end; // of if
	
	WriteLn;
end; // of procedure ProcessFile

	
procedure FindFilesRecur(strFolderStart: string; keepDays: integer);
//
//	Find all files in folder strFolderStart and keep files younger then keepDays old.
//
var
	sr: TSearchRec;
	//strPath: string;
	strFileSpec: string;
	intValid: integer;
	strFolderChild: string;
	strPathFoundFile: string;
begin
	//strPath := ExtractFilePath(strFolderStart); {keep track of the path ie: c:\folder\}
	strFileSpec := strFolderStart + '\*.*'; {keep track of the name or filter}
	WriteLn('FindFilesRecur(): ', strFolderStart);
	
	intValid := FindFirst(strFileSpec, faAnyFile, sr); { Find first file}
	//Writeln(intValid);
	
	while intValid = 0 do 
	begin
		if (sr.Name[1] <> '.') then
		begin
			if sr.Attr = faDirectory then
			begin
				//WriteLn('Dir:    ', sr.Name);
				strFolderChild := strFolderStart + '\' + sr.Name;
				FindFilesRecur(strFolderChild, keepDays);
			end
			else
			begin
				strPathFoundFile := strFolderStart + '\' + sr.Name;
				//WriteLn('File:    ', strPathFoundFile);
				ProcessFile(strPathFoundFile, sr, keepDays);
				//ProcessLprFile(strPathFoundFile);
				//ExtractEventsFromFile(strPathFoundFile);
			end;
		end;
		intValid := FindNext(sr);
	end; // of while.
end; // of procedure FindFilesRecur


begin
	sets := ReadSettingKey('Settings',  'Sets');
	WriteLn(sets);
	aSets := SplitString(sets, ';');
	for x := 0 to high(aSets) do
	begin
		WriteLn(aSets[x]);
		folderStart := ReadSettingKey(aSets[x], 'FolderStart');
		folderKeep := StrToInt(ReadSettingKey(aSets[x], 'KeepDays'));
		WriteLn(folderStart, '  >  ', folderKeep);
		FindFilesRecur(folderStart, folderKeep);
	end;
	//FindFilesRecur('D:\Temp');
end. // of program HousekeepingFiles