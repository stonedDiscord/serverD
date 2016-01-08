Set objFS = CreateObject("Scripting.FileSystemObject")
Set objPlayer = createobject("wmplayer.ocx.7")
inFolder="U:\AOVanilla1.7.3\AOVanilla1.7.41\client\base\sounds\music" 'music folder here
outFile="U:\AOVanilla1.7.3\AOVanilla1.7.41\client\base\sounds\music\out.txt" 'musiclist here
Set objFile = objFS.CreateTextFile(outFile,True)
Set objFolder = objFS.GetFolder(inFolder)
For Each strFile In objFolder.Files
	If objFS.GetExtensionName(strFile) = "mp3" Then	   
		strFileName = strFile.Path
		objFile.Write objFS.GetFileName(strFileName) & "*" & CInt(objPlayer.mediaCollection.add(strFileName).duration) & vbCrLf
	End If	
Next 
objPlayer.close
objFile.Close