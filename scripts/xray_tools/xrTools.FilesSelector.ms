-- 

rollout xrGetFiles ""
(
	label pathInfo ""
	multilistbox lbfiles "" width:400 height:40
	
	button loadBtn "LOAD" across:2 width:80
	button cancelBtn "CANCEL" width:80
	
	on xrGetFiles open do
	(
		pathInfo.text = xrImportFilesPath
		lbfiles.items = for i in (getfiles(xrImportFilesPath + "\\*.object")) collect (filenamefrompath i)
	)
	
	on cancelBtn pressed do
	(
		xrImportFilesList = #()
		destroyDialog xrGetFiles
	)
	
	on loadBtn pressed do
	(
		xrImportFilesList = for i in lbfiles.selection collect (xrImportFilesPath + "\\" + lbfiles.items[i])
		destroyDialog xrGetFiles
	)
)

createDialog xrGetFiles pos:[500,80] width:420 height:xrGetFiles.height modal:true \
								style:#(#style_titlebar, #style_sysmenu, #style_resizing, #style_border)