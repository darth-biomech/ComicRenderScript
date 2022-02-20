macroScript Macro3
	category:"DragAndDrop"
	toolTip:"Comic Render Passes"
(
------------------------------------------------------------------
-----      SCRIPT BEGINS HERE     --------------------------------
------------------------------------------------------------------
	
	detectedCameras=#()
	selectedCameraBit=#{}
	selectedCameras=#()
	LayersVisibility = #()
	dataNode = getNodeByName "!ComicData"
	
	attr = attributes custom_parameters attribID:#(0x7847187d, 0x4c3b92b5) version:1
	(
		parameters Comic_Params rollout:Comic
		(
			FX_pass type:#boolean default:false ui:FX_pass_ui
			Second_tonemap type:#boolean default:false ui:Second_tonemap_ui
			Colored_Lights type:#boolean default:false ui:Colored_Lights_ui
			LineWidth type:#float ui:LineWidth_ui
			Fisheye type:#boolean default:false ui:Fisheye_ui
			Fisheye_Dist type:#float default:1.012 ui:Fisheye_Dist_ui
			Fisheye_Curv type:#float default:0.35 ui:Fisheye_Curv_ui
		)
		rollout Comic "Comic Parameters"
		( 
			Checkbox FX_pass_ui "Has FX" type:#boolean
			Checkbox Second_tonemap_ui "Second tonemap" type:#boolean
			Checkbox Colored_Lights_ui "Colored Lights" type:#boolean
			spinner LineWidth_ui "Line Width" type:#worldunits 
			Checkbox Fisheye_ui "Enable Fisheye" type:#boolean
			spinner Fisheye_Dist_ui "Fisheye dist" type:#float 
			spinner Fisheye_Curv_ui "Fisheye curve" type:#float 
		)
	)
	
	function RegenerateCameras = (		
	detectedCameras = sort(for i in cameras collect i.name)
	sort detectedCameras
	selectedCameras = detectedCameras
for i = 1 to detectedCameras.count do selectedCameraBit[i] = true
		)
		
fn lerp minVal maxVal term = 
	(
		(maxVal - minVal) * term + minVal
	)
fn clamp minVal maxVal val =
	(
	if val < minVal then val = minVal
	else if val > maxVal then val = maxVal
	return val
	)
	function RestoreLayers store:true =
		(
			for i = 0 to (layermanager.count - 1) do
			(
				x = layermanager.getlayer i
				if store then 
					(
						LayersVisibility[i+1] = x.on
					)
				 else 
					(
						x.on = LayersVisibility[i+1]
					)
			)
		)
function ToggleLayer layername:"layer" showlayer:false  namemask:false =
	(
	for i = 0 to (layermanager.count - 1) do
		(
			x = layermanager.getlayer i
			test = x.name as string
			if namemask then (
				if matchpattern test pattern:layername do (
					if LayersVisibility[i+1] == true  do
						(
							x.on = showlayer
						)
					)
			) else (
				location = findString test layername
				if location == 1 do 
				(
					x.on = showlayer
				)
			)
		)
	)
	function RenderCurrentComicPanel mode:1 renderout:false savepath:"" = 
	(
		fxswitch = false		
		doPasses = true
		doLines = false
		doLights = false
		doFx = false				
		SaveWhole = false				
		SavePasses = true
		SaveLines = false
		SaveFx = false
		SaveAlpha = false
		outPathSuffix = ""		
				
		case mode of
			(
			1:(	-- Mode 1 - Shade
				doPasses = true
				doLines = false
				doFx = false
				doLights = true
				
				SaveWhole = false
				SaveAlpha = false
				
				SavePasses = true
				SaveLines = false
				SaveFx = false
				
				outPathSuffix = ""				
			)
			2:(	-- Mode 2 - lines
				doPasses = false
				doLines = true
				doFx = false
				doLights = false
				
				SaveWhole = false
				SaveAlpha = true
				
				SavePasses = false
				SaveLines = true
				SaveFx = false
				
				outPathSuffix = ""				
			)
			3:(	-- Mode 3 - fx
				doPasses = true
				doLines = false
				doFx = true
				doLights = false
				
				SaveWhole = true
				SaveAlpha = false
				
				SavePasses = false
				SaveLines = false
				SaveFx = true
				
				outPathSuffix = "_FX"				
			)
			4:(	-- Mode 4 - as is
				doPasses = true
				doLines = true
				doFx = true
				doLights = true
				
				SaveWhole = true
				SaveAlpha = true
				
				SavePasses = false
				SaveLines = false
				SaveFx = false
				
				outPathSuffix = "_Main"				
			)
			)
		
		vr=renderers.current 			
	--	showproperties renderers.current  
	curcam = try(getActiveCamera()) catch()
		camname = "none"
		
	if curcam != undefined  do (		
		renderSceneDialog.close()		
		select curcam
		camname = curcam.name as string		
		tokens = "( x )"
		camname = filterString camname tokens 
		camFrame = filterString camname[1] "_"
		slidertime = camFrame[2] as integer
		-- 1 is name, 2 is width, 3 is height
		renderWidth = camname[2] as integer *10
		renderHeight  = camname[3] as integer *10
		vr.output_width = camname[2] as integer *10
		vr.output_height  = camname[3] as integer *10
		outDefPath = "Q:/!Raharrs_and_all_about/!comic/SRC/BKG_src"
		outPath = ""
		outPathDot = ".png"
		
		
		pngio.setAlpha SaveAlpha
		
		camnameextra = camname[4] as string
		if camnameextra =="undefined" do camnameextra = ""
		if savepath != "" then (	
			outPath = savepath+ "/" + camname[1] + camnameextra
			)
		else  (	
			outPath = outDefPath+ "/" + camname[1] 
			)
		rendOutputFilename = (outPath +outPathDot)
		
		vr.camera_type = 0			
		dataNodeLoc = getNodeByName "!ComicData"
		if dataNodeLoc != undefined do 
		(
		if hasProperty dataNodeLoc.custom_parameters "FX_pass" do 
		(
			if dataNodeLoc.custom_parameters.FX_pass == true do 
			(				
				if doFx == true then (
						fxswitch = true					
					)
			)
		)
		
		if SaveFx == true and fxswitch == false do (
			print  "No FX necessary"
					return "No"
				)
		
		if hasProperty dataNodeLoc.custom_parameters "Fisheye" do 
		(
			if dataNodeLoc.custom_parameters.Fisheye == true do 
			(
				vr.camera_type = 5
				vr.camera_fish_autoDistance = false
				vr.camera_fish_distance = dataNodeLoc.custom_parameters.Fisheye_Dist
				vr.camera_fish_curve = dataNodeLoc.custom_parameters.Fisheye_Curv
			)
		)
		colorshadowpass = false
		if hasProperty dataNodeLoc.custom_parameters "Colored_Lights" do 
		(
			if dataNodeLoc.custom_parameters.Colored_Lights == true do 
			(				
				colorshadowpass = savepasses
			)
		)
	)
		vr.options_overrideMtl_on = fxswitch AND SaveFx
		vr.options_overrideMtl_excl_type = 1
		useEnvironmentMap = doLights
		oldEnvironmentColor = backgroundColor
		
		if dolines do
			(
				backgroundColor = color 255 255 255
			)
		rendAtmosphere = dolines
		vr.options_lights = doLights
		vr.options_shadows = doLights
		ToggleLayer layername:"Vraytoon_lines_additional" showlayer:dolines  namemask:false
		ToggleLayer layername:"ExcludeFromLineart" showlayer:(NOT dolines)  namemask:false
		ToggleLayer layername:"FX_*" showlayer:SaveFx  namemask:true

	lineartObjects = #()
	
	for i = 0 to (layermanager.count - 1) do
		(
			x = layermanager.getlayer i
			test = x.name as string
				if matchpattern test pattern:"FX_*" do (
					appendIfUnique  renderers.current.options_overrideMtl_excl_layers test
					)			
				if matchpattern test pattern:"*lines_additional" do (
			--		lineartObjects =  for i in $* where i.layer == x and classof i == Container collect i
					clearSelection()
					x.select true
					for i in getCurrentSelection() do (
						objname = i.name as string
						if NOT matchpattern objname pattern:"*line*" do (
							deselect i
							)
						)
					lineartObjects = getCurrentSelection()
					print "found lineart"
					clearSelection()
					select curcam
					)		
		)
		
		remCurrent = maxOps.GetCurRenderElementMgr()

		for i = 0 to remCurrent.NumRenderElements()-1 do --note render element manager is 0 based
		(
			re = remCurrent.GetRenderElement i
			re.enabled = savepasses
			if classOf re != VRayAlpha do
				(
			re.vrayVFB = savepasses	
				)
		--	re.fileOutGamma = 2.2
			
			if savewhole then(
				re.enabled = false
			if classOf re != VRayAlpha do
				(
			re.vrayVFB = savepasses	
				)
				case (classOf re) of
				(
				VRayDiffuseFilter:(
					thisname = re.elementName as string
					if matchpattern thisname pattern:"*FX*" then (
							re.elementName = "FX"
							re.vrayVFB = saveFx
						) 
					else ( re.elementName = "Colors" )
					)
				VRayAlpha:(
					re.enabled = SaveWhole
					re.elementName = "Alpha"
					)				
				)
			)
			else
			(
				case (classOf re) of
				(
				VRayExtraTex:(
					thisname = re.elementName as string
					if matchpattern thisname pattern:"*line*" do (
						re.elementName = "Lines"
					re.enabled = savelines		
					re.vrayVFB = savelines
					re.excludeList = lineartObjects
					)	
					if matchpattern thisname pattern:"*color*" do (
						re.elementName = "Colors_ex"
					re.enabled = savepasses		
					re.vrayVFB = savepasses
						)	
					if matchpattern thisname pattern:"*shadow*" do (
						re.elementName = "Shadows"
					re.enabled = savepasses		
					re.vrayVFB = savepasses
						)			
				) 
				VRayMtlID:(
					re.enabled = savelines		
					re.vrayVFB = savelines
					re.elementName = "Masks"
				)
				VRayDiffuseFilter:(
					thisname = re.elementName as string
					re.vrayVFB = savePasses
					if matchpattern thisname pattern:"*FX*" then (
							re.elementName = "FX"
							re.vrayVFB = savefx
					) else (
						re.elementName = "Colors"
					)
				)
				VRayRawLighting:(
					re.vrayVFB = colorshadowpass
					re.elementName = "ShadowColor"
				)
				VRaySpecular:(
					re.vrayVFB = savePasses
					re.elementName = "Highlights"
				)
				VRayAlpha:(
					re.enabled = SaveWhole
					re.elementName = "Alpha"
				)
				VRayZDepth:(
					re.vrayVFB = savePasses
					re.elementName = "ZDepth"
					re.invert_zdepth = false
					re.zdepth_max = 2000
				)
				)
			)
			remCurrent.SetRenderElementFilename i ""
		)
	-- end for i	
		if renderout ==true do (
			setVRaySilentMode()
			vr.output_on = false
			tempRenderSave = rendSaveFile
			rendSaveFile = true
--			outputpath = outPath + camname[1] + "_.png"
--			render filename: outputpath gamma:2.2 
			max quick render
			rendSaveFile = tempRenderSave
			vr.output_on = true
			rendOutputFilename = "" 
			if saveWhole == true then (
				
			print "Saving collapsed..."
				
				deletefile 									(outPath+outPathSuffix+outPathDot)
				
				copyFile 	(outPath+outPathDot) 	(outPath+outPathSuffix+outPathDot)
				
				deletefile 	(outPath+outPathDot)
				
				) else (				
			print "saving pass..."
				
				deletefile 			(outPath + outPathDot)
				
			)
			for x in (UIAccessor.GetPopupDialogs()) where (UIAccessor.GetWindowDllFileName x==((getdir #maxroot) + "bmm.dll")) do UIAccessor.CloseDialog x	
		)
		vr.camera_type = 0		
		backgroundColor = oldEnvironmentColor
	)
	-- end if curcam	
	--		ToggleLayer layername:"Vraytoon_lines_additional" showlayer:true namemask:false
	--		ToggleLayer layername:"ExcludeFromLineart" showlayer:true namemask:false
	--		ToggleLayer layername:"FX_*" showlayer:true namemask:true
		RestoreLayers store:false
		vr.options_overrideMtl_on = false
		useEnvironmentMap = true
	)
function SetVtoonWidth width:0.15 =
	(
	vtoon=#(getAtmospheric 1,getAtmospheric 2,getAtmospheric 3)		
	dataNode = getNodeByName "!ComicData"
	if dataNode != undefined then (
	for toon in vtoon do 
		(	
		if toon != undefined  do 
			(		
				
				toon.lineWorld = dataNode.custom_parameters.LineWidth
			)
		)
	) else (
	for toon in vtoon do 
		(	
		if toon != undefined  do 
			(		
				
				toon.lineWorld = width
			)
		)
	)
	)

rollout Render_comic_cameras "Scene cameras" width:245 height:310
	(
	multilistbox cameraList "" items:detectedCameras\
	height:22 width:220
		on Render_comic_cameras open do
			(
					cameraList.selection=selectedCameraBit
			)
		on cameraList selected val do 
			(
				selectedCameras = for i in cameraList.selection collect cameraList.items[i]
				selectedCameraBit = cameraList.selection
			)
	)
  try destroyDialog Render_comic catch()
rollout Render_comic "Render Comic" width:320 height:180
	(
	edittext savePath "Path" align:#center text:"Q:/!Raharrs_and_all_about/!comic/SRC/BKG_src" tooltip:"Without slash!"
	spinner pageNum "Page:" range:[0,1000,78] type:#integer fieldWidth: 32 align:#center offset: [-45,0]
	dropdownlist renderMode items:#("Collapsed", "All passes", "Shading only", "Lines only", "FX only") selection:2 width:85 align:#center offset: [45,-25]
	checkbox renderAway "Start Render" align:#center checked:true offset: [-100,0]
	checkbox renderAll "Batch All Pages" align:#center checked:true tooltip:"Render all cameras for all pages" offset: [0,-20]
	checkbox editLines "Change Lines" align:#center checked:true offset: [-100,0]
	spinner lineWidth "Default Line Width:" range:[0,100,0.984] type:#worldunits fieldWidth: 64 align:#center  offset: [40,-19]
	
	button btnApplySingle "Only Current" width:100 height:24 align:#center offset: [-50,3] tooltip:"Render only current camera"
	button btnApply "Render All" width:100 height:24 align:#center offset: [55,-29] tooltip:"Render all cameras for page or pages"
	button btnCameraList "CAM" width:24 height:24 align:#center offset: [120,-29] tooltip:"Select cameras"
	button btnSelectData "DATA" width:35 height:24 align:#center offset: [-125,-29] tooltip:"Select Comic Data"

--	subrollout Render_comic_subcam "Scene cameras" height:28 width:320 align:#center
	
	button btnSetRes "From Clipboard" width:80 height:20 align:#center  offset: [-90,10] tooltip:"Set render resolution from clipboard"
	button btnSetCam "Setup camera" width:80 height:20 align:#center offset: [0,-25] tooltip:"Set camera name"
	button btnCapture "Screenshot" width:80 height:20 align:#center offset: [90,-25] tooltip:"capture viewport screenshot into clipboard"
	spinner camClip "Camera Clip:" range:[0,10000,1500] type:#worldunits fieldWidth: 64 align:#center 
	
on btnSelectData pressed do
 	(
		select dataNode
 	--	addSubRollout Render_comic_subcam Render_comic_cameras rolledUp:true
	)	
on btnCameraList pressed do
 	(
	destroyDialog Render_comic_cameras 
	createDialog Render_comic_cameras
 	--	addSubRollout Render_comic_subcam Render_comic_cameras rolledUp:true
	)
		
function UpdateSettings = 
	(
	inifile = (getdir #plugcfg_ln) + "/ComicRender.ini"
	prefPath =savePath.text as string
	prefPage =pageNum.value as string
	prefLines = renderMode.selection as string
	prefRender = renderAway.state as string
	prefRenderAll = renderAll.state as string
	prefEditLines = editLines.state as string
	setINISetting inifile "ComicRenderSettings" "Path" prefPath
	setINISetting inifile "ComicRenderSettings" "Page" prefPage
	setINISetting inifile "ComicRenderSettings" "Line" prefLines
	setINISetting inifile "ComicRenderSettings" "EditLine" prefEditLines
	setINISetting inifile "ComicRenderSettings" "Render" prefRender
	setINISetting inifile "ComicRenderSettings" "RenderAll" prefRenderAll
	)		
	
	function RenderSelector mode:2 =(
		RestoreLayers store:true
		case mode of
			(
			1:(	-- Mode 1 - collapsed
					RenderCurrentComicPanel mode:4 renderout:renderAway.state savepath:savePath.text	-- Mode 4 - As Is		
			)
			2:(	-- Mode 2 - all
					RenderCurrentComicPanel mode:1 renderout:renderAway.state savepath:savePath.text	-- Mode 1 - Shade
					RenderCurrentComicPanel mode:2 renderout:renderAway.state savepath:savePath.text	-- Mode 2 - Lines
					RenderCurrentComicPanel mode:3 renderout:renderAway.state savepath:savePath.text	-- Mode 3 - FX
			)
			3:(	-- Mode 3 - passes
					RenderCurrentComicPanel mode:1 renderout:renderAway.state savepath:savePath.text	-- Mode 1 - Shade
			)
			4:(	-- Mode 4 - lines
					RenderCurrentComicPanel mode:2 renderout:renderAway.state savepath:savePath.text	-- Mode 2 - Lines
			)
			5:(	-- Mode 5 - fx
					RenderCurrentComicPanel mode:3 renderout:renderAway.state savepath:savePath.text	-- Mode 3 - FX
			)
		)
	)
on Render_comic close do 
	(
	UpdateSettings()
			 destroyDialog Render_comic_cameras
	)
	
on btnApplySingle pressed do
	(	
	UpdateSettings()
	
	thiscam = try(getActiveCamera()) catch()
		
	if thiscam != undefined  do 
		(		
			if matchpattern thiscam.name pattern:"P*_*(*)*" do
			(
				if editLines.state do SetVtoonWidth width:(lineWidth.value as float)
				
				RenderSelector mode:renderMode.selection
				
	--			if renderMode.selection != 3 do (
	--				RenderCurrentComicPanel dolines:false renderout:renderAway.state savepath:savePath.text fxpass:false
	--				RenderCurrentComicPanel dolines:false renderout:renderAway.state savepath:savePath.text fxpass:true
	--				)
	--			if renderMode.selection != 2 do RenderCurrentComicPanel dolines:true renderout:renderAway.state savepath:savePath.text fxpass:false
				
			)
		)
	)

on btnCapture pressed do
	(
	local hLight = hideByCategory.lights
	local	hCam = hideByCategory.cameras
	local	hHelp = hideByCategory.helpers 
	local	hWarp = hideByCategory.spacewarps
	local viewportbkg = viewport.DispBkgImage
		
	hideByCategory.lights = true
	hideByCategory.cameras = true
	hideByCategory.helpers = true
	hideByCategory.spacewarps = true
		
	viewport.DispBkgImage = false
		
	cui.expertModeOn()
	img = gw.getViewportDib gammaCorrect:false captureAlpha:true -- take a shot	
	
	local x = y = 0, v
	local s = getViewSize()
	local k = getRendImageAspect()
		
		
	if k < (s.x/s.y) then
	(
		v = [s.y*k,s.y]
		x = (s.x-v.x)/2 + 1
	)
	else
	(
		v = [s.x, s.x/k]
		y = (s.y-v.y)/2 + 1
	)
	bmp = bitmap v.x v.y
	pasteBitmap (img) bmp (box2 x y v.x v.y) [0,0]
	
	cui.expertModeOff()
	bmp2 = bitmap renderWidth renderHeight
	copy bmp bmp2
	retCode = setclipboardBitmap bmp2	
	
	hideByCategory.lights = hLight
	hideByCategory.cameras = hCam
	hideByCategory.helpers = hHelp
	hideByCategory.spacewarps = hWarp	
	viewport.DispBkgImage = viewportbkg
)

on btnApply pressed do
	(	
	startTime = timeGetTime()
	UpdateSettings()
	camNamePattern = ("P*"+pageNum.value as string+"_*(*)*")
		if renderAll.state == true then 
			(
				camNamePattern = "P*_*(*)*"				
			)
			
	for cam in cameras do 
		(	
			if (keyboard.escPressed==true) then abortSequence = true
			if abortSequence != true then 
			(
				if matchpattern cam.name pattern:camNamePattern then
				(
					if  findItem selectedCameras cam.name !=0 then 
					(						
						viewport.setCamera cam;
						camname = cam.name as string		
						tokens = "( x )"
						camname = filterString camname tokens 
						camFrame = filterString camname[1] "_"
						slidertime = camFrame[2] as integer
				
						if editLines.state then SetVtoonWidth width:(lineWidth.value as float) fov:cam.fov expo:lineExponent.value
				
						RenderSelector mode:renderMode.selection
					)
				)	
			)			
		)
		endTime = timeGetTime()		
		messagebox ("Batch Render finished! \n Render took "+(((endTime - startTime) / 1000.0)/60) as string +" minutes ("+((((endTime - startTime) / 1000.0)/60)/60) as string+" hours)")
	)
on btnSetRes pressed do
	(	
		clipboard = getclipboardBitmap()
		if clipboard != undefined do (
		renderSceneDialog.close()		
		renderWidth = ceil (clipboard.width as float/10)*10 as integer
		renderHeight  = ceil (clipboard.height as float/10)*10  as integer
		clipboardtmp = bitmap (clipboard.width/2) (clipboard.height/2) filename:((GetDir #preview)+"\TempFrame.png")
		copy clipboard clipboardtmp
		save clipboardtmp
		setAsBackground clipboardtmp
		viewport.DispBkgImage = true
		completeRedraw()
			)
		
	)
on btnSetCam pressed do
	(	
	curcam = try(getActiveCamera()) catch()
		
	if curcam == undefined  do 
		(
			focdistance = gw.GetFocalDist()
			tm = inverse (viewport.getTM())
			cp = ray tm[4] -tm[3]
			ct = targetobject position:(cp.pos+(cp.dir*focdistance))
			fov_value = getViewFOV()
			newCam = targetcamera pos:cp.pos target:ct
			newCam.fov = fov_value
			newCam.type = #free
			newCam.baseObject.targetDistance = focdistance
			curcam=newCam
			viewport.setCamera curcam
		)
		camname = "none"
		curtime = slidertime as integer / 160
	if curcam != undefined  do 
		(		f
		deleteKeys curcam
		curcam.name = ("P"+pageNum.value as string+"_"+curtime as string+"("+(floor(renderWidth/10)as integer) as string+"x"+(floor(renderHeight/10)as integer) as string+")")
		curcam.type = #free 
		curcam.farclip = camClip.value
		deleteKeys curcam
			
		camlayerexists = false
		for i = 0 to (layermanager.count - 1) do
		(
			x = layermanager.getlayer i
			test = x.name as string
			test = toLower test
			location = findString test "cameras"
				if location == 1 do 
				(
					x.addNode curcam
					camlayerexists = true
				)			
		)
		if (camlayerexists == false) do 
			(
				x = LayerManager.newLayer()
				x.setname "CAMERAS"
				x.addNode curcam
			)
		)	
	RegenerateCameras()
	)
-- end buttonpressed
)
	
function GenAttributes dataNode:undefined purge:false=
	(	
	if dataNode != undefined do (
		if purge do
		(
		b=custattributes.getdef dataNode 1
		custAttributes.delete dataNode b
		)
		
		custAttributes.add dataNode attr	
		)
	)	
	createDialog Render_comic

	RegenerateCameras()
	
inifile = (getdir #plugcfg_ln) + "/ComicRender.ini"
if hasINISetting inifile "ComicRenderSettings" do (
Render_comic.pageNum.value = getINISetting inifile "ComicRenderSettings" "Page" as integer	
Render_comic.savePath.text = getINISetting inifile "ComicRenderSettings" "Path" as string
Render_comic.renderMode.selection  = getINISetting inifile "ComicRenderSettings" "Line" as integer
Render_comic.renderAway.checked  = getINISetting inifile "ComicRenderSettings" "Render" as Booleanclass
Render_comic.renderAll.checked  = getINISetting inifile "ComicRenderSettings" "RenderAll" as Booleanclass
Render_comic.editLines.checked  = getINISetting inifile "ComicRenderSettings" "EditLine" as Booleanclass
)
	
	dataNode = getNodeByName "!ComicData"
	if dataNode != undefined do (
		
		if custattributes.getdef dataNode 1 == undefined do 
		(		
			print "Custom params not found, creating!"	
		GenAttributes dataNode:DataNode purge:false		
		)	
		
		if hasProperty dataNode.custom_parameters "lineWidth"  do 
		(				
		Render_comic.lineWidth.value = dataNode.custom_parameters.LineWidth
		)
	)
	if dataNode == undefined do (
		dataNode = point name:"!ComicData" box:true cross:false size:80
		datanode.wirecolor = color 255 0 0
		
		GenAttributes dataNode:DataNode purge:false
		
		dataNode.custom_parameters.LineWidth = Render_comic.lineWidth.value as float
			
	)
------------------------------------------------------------------
-----      SCRIPT ENDS HERE     --------------------------------
------------------------------------------------------------------
)
