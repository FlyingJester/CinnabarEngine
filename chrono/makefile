
.if defined(OS) && (${OS} == "WIN")

chrono.lib:
	cl /Fowin32_time.obj /c win32_time.c /nologo
	lib /nologo /OUT:win32_time.lib win32_time.obj

.else



.endif
