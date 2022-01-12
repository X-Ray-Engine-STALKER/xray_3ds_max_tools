rollout xray_export_skl_rol "export motion (*.skl) ver.03"
(
button exportBtn "Export motion" width:160 --across:2
spinner SFrame type:#integer width:50 range:[0,999999,0] across:3 align:#left
spinner EFrame type:#integer width:50 range:[0,999999,100] offset:[4,0]
button GetAnimRange "*" align:#right height:16
pickbutton RootPick "no root selected" width:160 autoDisplay:true
checkbox IncludeRoot "include root" 

group ""
(
label ssssl "scale pos keys" align:#left across:2
spinner scale_pos width:60 align:#right scale:.001 range:[0, 1000000, 1]
)

fn get_hierarchy obj =
(
		local ch = obj.children, i, res = #(obj)
		
		for i in ch do 
			join res (get_hierarchy i)
		
		return res
)

fn get_top_object objs =
(
		local obj
		
		for obj in objs do
		(
				if obj.parent == undefined then return obj
				if (finditem objs obj.parent) == 0 then return obj
		)
		
		return undefined
)

fn Export_anim f objs robj FStart FEnd anim_name = 
(
		local EulerOrder = 5
		local FRate = 30.
		local Timer = timestamp ()
		
		writelong f 4608 	-- skl section ID
		writelong f 0 		-- skl section size
		
		writestring f anim_name -- A name
		
		local AStart = FStart --(animationRange.start as integer)/160
		local AEnd = FEnd --(animationRange.end as integer)/160
		local KeysCount = AStart - AEnd
		writelong f 0 --AStart 
		writelong f (AEnd-AStart)
		
		writefloat f FRate
		
		writeshort f 7 -- objs.count   -- unk "animated bones ?"
		writebyte f 0    --- flags
		writeshort f -1   -- unk flags
		writefloat f 1. -- speed
		writefloat f 2. -- accure
		writefloat f 2. -- fallof
		writefloat f 1. -- unk
		writeshort f (objs.count) -- NumBones
		
		local cnt = 1
		
		for obj in objs do
		(
				pushprompt ("[" + (cnt as string) + "/" + (objs.count as string) + "]:" + obj.name )
				cnt += 1
				pobj = obj.parent
				format "-- %\n" obj.name
				writestring f (xrToolsUtil.renameBone obj.name) -- bone name
				writebyte f 0 -- unk
				
				if obj != robj then 
						tms = for t = AStart to AEnd collect \
							#(at time t (obj.transform * (if pobj!=undefined then inverse pobj.transform else if robj!=undefined then inverse robj.transform else matrix3 1)),(t-AStart)/FRate)
				else
						tms = for t = AStart to AEnd collect #(at time t obj.transform,(t-AStart)/FRate)
				
				------------------------------------------------------------------------------------------ POSITIONS
				--format "\t writing X-pos:\n"
				writebyte f 1 -- unk
				writebyte f 1 -- unk
				writeshort f tms.count
						
				for i = 1 to tms.count do
				(
						writefloat f (tms[i][1].position.x*scale_pos.value)
						writefloat f tms[i][2]
						writebyte f 4
						--format "\t\t %: %\n" tms[i][2] tms[i][1].position.x
				)
				
				--format "\t writing Z-pos:\n"
				writebyte f 1 -- unk
				writebyte f 1 -- unk
				writeshort f tms.count
						
				for i = 1 to tms.count do
				(
						writefloat f (tms[i][1].position.z*scale_pos.value)
						writefloat f tms[i][2]
						writebyte f 4
						--format "\t\t %: %\n" tms[i][2] tms[i][1].position.z
				)
				
				--format "\t writing Y-pos:\n"
				writebyte f 1 -- unk
				writebyte f 1 -- unk
				writeshort f tms.count
						
				for i = 1 to tms.count do
				(
						writefloat f (tms[i][1].position.y*scale_pos.value)
						writefloat f tms[i][2]
						writebyte f 4
						--format "\t\t %: %\n" tms[i][2] tms[i][1].position.y
				)
				
				----------------------------------------------------------------------------------------- ROTATIONS
				--format "Rotations\n"
				
				for j = 1 to 3 do
				(
						--format "\t writing %:\n" j
						writebyte f 1 -- unk
						writebyte f 1 -- unk
						writeshort f tms.count
						
						for i = 1 to tms.count do
						(
								v = inverse tms[i][1].rotationpart
								v = QuatToEuler v order:EulerOrder
								v = if j == 1 then v.x else if j == 2 then v.y else v.z 
								writefloat f (degtorad v)
								writefloat f tms[i][2]
								writebyte f 4
								--format "\t\t %: %\n" (t/FRate) (degtorad v)
						)
				)
				
		)
		
		writelong f 0
		cursize = ftell f
		fseek f 4 #seek_set
		writelong f (cursize-8)
		
		timer = (timestamp() - Timer)/1000.
		format "\ndone at % sec\n" timer
		pushprompt ("export done (time = " + (timer as string) + " sec)")
) -- fn

--------------------
on RootPick rightclick do 
(
	RootPick.object = undefined
	RootPick.text = "no root selected"
)

on GetAnimRange pressed do
(
		SFrame.value = animationRange.start
		EFrame.value = animationRange.end
)

on exportBtn pressed do
		if $ == undefined then messagebox "nothing selected"
		else
		(
				clearlistener ()
				objs = if RootPick.object != undefined and IncludeRoot.checked then #(RootPick.object) else #()
				join objs (selection as array)
				
				if objs == undefined then format "error\n"
				else
				(
						fname = getsavefilename types:"anims|*.skl|" \
												filename:"C:\\Program Files\\X-Ray CoP SDK\\editors\\import\\"
						
						if fname != undefined then 
						(
							f = fopen fname "wb"
							if f == undefined then format "cant create file\n"
							else
							(
									format "Num objects = %\n" objs.count
									Export_anim f objs (if IncludeRoot.checked then RootPick.object else undefined) SFrame.value EFrame.value (getfilenamefile fname)
									fclose f
							)
						)
				)
		)

) -- rol


try (closeRolloutFloater xray_export_skl_flo) catch ()
xray_export_skl_flo = newRolloutFloater "x-ray tools" 200 180 40 130
addRollout  xray_export_skl_rol xray_export_skl_flo










