  %include "../defaults_bin.asm"

  mov al,TIMER0 | BOTH | MODE2 | BINARY
  out 0x43,al
  xor al,al
  out 0x40,al
  out 0x40,al

  cli

  mov ax,0
  mov ds,ax
  mov ax,cs
  mov word[0x20],interrupt8
  mov [0x22],ax

  mov ds,ax
  mov es,ax
  mov ss,ax
  mov sp,0

  mov si,experimentData
nextExperiment:
  xor bx,bx
  mov [lastQuotient],bx

  ; Print name of experiment
printLoop:
  lodsb
  cmp al,'$'
  je donePrint
  printCharacter
  inc bx
  jmp printLoop
donePrint:
  cmp bx,0
  jne printSpaces

  ; Finish
  complete

  ; Print spaces for alignment
printSpaces:
  mov cx,21  ; Width of column
  sub cx,bx
  jg spaceLoop
  mov cx,1
spaceLoop:
  printCharacter ' '
  loop spaceLoop

  mov cx,5    ; Number of repeats
repeatLoop:
  push cx

  mov cx,480+48  ; Number of iterations in primary measurement
  call doMeasurement
  push bx
  mov cx,48      ; Number of iterations in secondary measurement
  call doMeasurement
  pop ax         ; The primary measurement will have the lower value, since the counter counts down
  sub ax,bx      ; Subtract the secondary value, which will be higher, now AX is negative
  neg ax         ; Negate to get the positive difference.

  xor dx,dx
  mov cx,120
  div cx       ; Divide by 120 to get number of cycles (quotient) and number of extra tcycles (remainder)

  push dx      ; Store remainder

  ; Output quotient
  xor dx,dx
  mov [quotient],ax
  mov cx,10
  div cx
  add dl,'0'
  mov [output+2],dl
  xor dx,dx
  div cx
  add dl,'0'
  mov [output+1],dl
  xor dx,dx
  div cx
  add dl,'0'
  mov [output+0],dl

  ; Output remainder
  pop ax
  xor dx,dx
  div cx
  add dl,'0'
  mov [output+7],dl
  xor dx,dx
  div cx
  add dl,'0'
  mov [output+6],dl
  xor dx,dx
  div cx
  add dl,'0'
  mov [output+5],dl

  ; Emit the final result text
  push si
  mov ax,[quotient]
  cmp ax,[lastQuotient]
  jne fullPrint

  mov cx,6
  mov si,output+4
  jmp doPrint
fullPrint:
  mov [lastQuotient],ax
  mov cx,10
  mov si,output
doPrint:
  printString
  pop si
  pop cx
  loop repeatLoop1

  ; Advance to the next experiment
  lodsw
  add si,ax
  lodsw
  add si,ax

  printNewLine

  jmp nextExperiment

repeatLoop1:
  jmp repeatLoop

quotient: dw 0
lastQuotient: dw 0

output:
  db "000 +000  "


doMeasurement:
  push si
  push cx  ; Save number of iterations

  ; Copy init
  lodsw    ; Number of init bytes
  mov cx,ax
  mov di,timerStartEnd
  call codeCopy

  ; Copy code
  lodsw    ; Number of code bytes
  pop cx
iterationLoop:
  push cx

  push si
  mov si,codePreambleStart
  mov cx,codePreambleEnd-codePreambleStart
  call codeCopy
  pop si

  push si
  mov cx,ax
  call codeCopy
  pop si

  pop cx
  loop iterationLoop

  ; Copy timer end
  mov si,timerEndStart
  mov cx,timerEndEnd-timerEndStart
  call codeCopy


  ; Enable IRQ0
  mov al,0xfe  ; Enable IRQ 0 (timer), disable others
  out 0x21,al

  mov cx,256
  cli

  ; Increase refresh frequency to ensure all DRAM is refreshed before turning
  ; off refresh.
  mov al,TIMER1 | LSB | MODE2 | BINARY
  out 0x43,al
  mov al,2
  out 0x41,al  ; Timer 1 rate

  ; Delay for enough time to refresh 512 columns
  rep lodsw

  ; We now have about 1.5ms during which refresh can be off
  refreshOff

  ; Use IRQ0 to go into lockstep with timer 0
  mov al,TIMER0 | LSB | MODE2 | BINARY
  out 0x43,al
  mov al,0x04  ; Count = 0x0004 which should be after the hlt instruction has
  out 0x40,al  ; taken effect.
  sti
  hlt

  ; The actual measurement happens in the the IRQ0 handler which runs here and
  ; returns the timer value in BX.

  ; Pop the flags pushed when the interrupt occurred
  pop ax

  pop si
  ret

codeCopy:
  cmp cx,0
  je codeCopyDone
codeCopyLoop:
  cmp di,0
  je codeCopyOutOfSpace
  movsb
  loop codeCopyLoop
codeCopyDone:
  ret
codeCopyOutOfSpace:
  mov si,outOfSpaceMessage
  mov cx,outOfSpaceMessageEnd-outOfSpaceMessage
  printString
  complete

outOfSpaceMessage:
  db "Copy out of space - use fewer iterations"
outOfSpaceMessageEnd:


codePreambleStart:
;  mov al,0
;  mul cl
codePreambleEnd:

experimentData:

experimentPlasmaLockstep2:
  db "PlasmaLockstep2$"
  dw .endInit - ($+2)
  mov ax,0xb800
  mov es,ax
  mov ax,0x8000
  mov ds,ax
  mov ss,ax
  mov di,0
  mov si,0
  mov dx,0
  mov bp,0
.endInit
  dw .endCode - ($+2)

        lodsw
        add     ax,[bp+si]
        xlatb
        xchg al,ah
        xlatb

        stosb
        inc di
        mov al,ah
        stosb
        inc di
        xchg ax,cx
        stosb
        inc di
        mov al,ah
        stosb
        inc di
        xchg ax,dx
        stosb
        inc di
        mov al,ah
        stosb
        inc di

        lodsw
        add     ax,[bp+si]
        xlatb
        xchg al,ah
        xlatb
        xchg ax,cx

        lodsw
        add     ax,[bp+si]
        xlatb
        xchg al,ah
        xlatb

        stosb
        inc di
        mov al,ah
        stosb
        inc di
        xchg ax,cx
        stosb
        inc di
        mov al,ah
        stosb
        inc di

        lodsw
        add     ax,[bp+si]
        xlatb
        xchg al,ah
        xlatb
        xchg ax,cx

        lodsw
        add     ax,[bp+si]
        xlatb
        xchg al,ah
        xlatb
        xchg ax,dx

.endCode:

546/16 61/110

experimentPlasmaW2:
  db "PlasmaW2$"
  dw .endInit - ($+2)
  mov ax,0x7000
  mov es,ax
  mov ax,0x8000
  mov ds,ax
  mov ss,ax
  mov di,0
  mov si,0
  mov dx,0
  mov bp,0
.endInit
  dw .endCode - ($+2)
        lodsw
        add     ax,[bp+si]
        xlatb
        xchg al,ah
        xlatb
        stosw
.endCode:

experimentPlasmaW:
  db "PlasmaW$"
  dw .endInit - ($+2)
  mov ax,0xb800
  mov es,ax
  mov ax,0x8000
  mov ds,ax
  mov ss,ax
  mov di,0
  mov si,0
  mov dx,0
  mov bp,0
.endInit
  dw .endCode - ($+2)
        lodsw
        add     ax,[bp+si]
        xlatb
        stosb
        inc di
        mov al,ah
        xlatb
        stosb
        inc di
.endCode:

experimentBlit:
  db "Blit$"
  dw .endInit - ($+2)
  mov ax,0xb800
  mov es,ax
  mov ax,0x8000
  mov ds,ax
  mov di,0
  mov si,0
.endInit
  dw .endCode - ($+2)
  movsb
  inc di
.endCode:

experimentPlasmaScali2c:
  db "PlasmaScali2c$"
  dw .endInit - ($+2)
  mov ax,0x7000
  mov es,ax
  mov ax,0x8000
  mov ds,ax
  mov ss,ax
  mov di,0
  mov si,0
  mov dx,0
  mov bp,0
.endInit
  dw .endCode - ($+2)
        lodsb
        add     al,[bp+si]
        xlatb
        stosb
.endCode:


experimentPlasmaScali2b:
  db "PlasmaScali2b$"
  dw .endInit - ($+2)
  mov ax,0xb800
  mov es,ax
  mov ax,0x8000
  mov ds,ax
  mov ss,ax
  mov di,0
  mov si,0
  mov dx,0
  mov bp,0
.endInit
  dw .endCode - ($+2)
        lodsb
        add     al,[bp+si]
        xlatb
        stosw
.endCode:


experimentPlasmaScali2:
  db "PlasmaScali2$"
  dw .endInit - ($+2)
  mov ax,0xb800
  mov es,ax
  mov ax,0x8000
  mov ds,ax
  mov ss,ax
  mov di,0
  mov si,0
  mov dx,0
  mov bp,0
.endInit
  dw .endCode - ($+2)
        lodsb
        add     al,[bp+si]
        xlatb
        stosb
        inc     di
.endCode:

experimentPlasmaScali:
  db "PlasmaScali$"
  dw .endInit - ($+2)
  mov ax,0xb800
  mov es,ax
  mov ax,0x8000
  mov ds,ax
  mov ss,ax
  mov di,0
  mov si,0
  mov dx,0
  mov bp,0
.endInit
  dw .endCode - ($+2)
  lodsb
  add al,[bp]
  xlatb
  stosb
  inc di
  dec bp
.endCode:

experimentPlasmaMe:
  db "PlasmaMe$"
  dw .endInit - ($+2)
  mov ax,0xb800
  mov es,ax
  mov ax,0x8000
  mov ds,ax
  mov ss,ax
  mov di,0
  mov si,0
  mov dx,0
  mov bp,0
.endInit
  dw .endCode - ($+2)
        mov     bl,[si]
        add     bl,[bp+si]
        mov     al,[bx]
        stosb
        inc di
        inc si
.endCode:

experimentPlasma2:
  db "Plasma2$"
  dw .endInit - ($+2)
  mov ax,0xb800
  mov es,ax
  mov ax,0x8000
  mov ds,ax
  mov ss,ax
  mov di,0
  mov si,0
  mov dx,0
  mov bp,0
.endInit
  dw .endCode - ($+2)
        mov     bl,[si]
        add     bl,[bp+si]
        mov     al,[bx]
        stosb
        inc di
        mov al,dl
        stosb
        inc di
        mov al,dh
        stosb
        inc di
        mov al,ah
        stosb
        inc di
        inc     si
        mov     bl,[si]
        add     bl,[bp+si]
        mov     dl,[bx]
        inc     si
        mov     bl,[si]
        add     bl,[bp+si]
        mov     dh,[bx]
        inc     si
        mov     bl,[si]
        add     bl,[bp+si]
        mov     ah,[bx]
        inc     si
.endCode:


experimentCopyAttributes:
  db "CopyAttrs$"
  dw .endInit - ($+2)
  mov ax,0xb800
  mov es,ax
  mov ax,0x8000
  mov ds,ax
  mov ss,ax
  mov di,0
  mov si,0
  mov dx,0
  mov bp,0
.endInit
  dw .endCode - ($+2)
  stosb
  inc di
  mov al,dl
  stosb
  inc di
  mov al,dh
  stosb
  inc di
  mov al,ah
.endCode:

experimentCopyAttributes2:
  db "CopyAttrs2$"
  dw .endInit - ($+2)
  mov ax,0xb800
  mov es,ax
  mov ax,0x8000
  mov ds,ax
  mov ss,ax
  mov di,0
  mov si,0
  mov dx,0
  mov bp,0
.endInit
  dw .endCode - ($+2)
  stosb
  mov [es:di+1],dl
  mov [es:di+3],dh
  mov [es:di+5],ah
.endCode:

experimentCopyAttribute:
  db "CopyAttr$"
  dw .endInit - ($+2)
  mov ax,0xb800
  mov es,ax
  mov ax,0x8000
  mov ds,ax
  mov ss,ax
  mov di,0
  mov si,0
  mov dx,0
  mov bp,0
.endInit
  dw .endCode - ($+2)
  movsb
  inc di
.endCode:

experimentPlasma:
  db "Plasma$"
  dw .endInit - ($+2)
  mov ax,0xb800
  mov es,ax
  mov ax,0x8000
  mov ds,ax
  mov ss,ax
  mov di,0
  mov si,0
  mov dx,0
  mov bp,0
.endInit
  dw .endCode - ($+2)
        mov     bl,[si]
        add     bl,[bp+si]
        mov     al,[bx]
        stosb
        inc     di
        inc     si
.endCode:


experimentSSTTLUT:
  db "SSTTLUT$"
  dw .endInit - ($+2)
  mov ax,0xb800
  mov es,ax
  mov ax,0x8000
  mov ds,ax
  mov di,0
  mov si,0
.endInit
  dw .endCode - ($+2)
  mov ax,[bx+9999]
  stosw
.endCode:

experimentSSTTLUT_attributes:
  db "SSTTLUT_attr$"
  dw .endInit - ($+2)
  mov ax,0xb800
  mov es,ax
  mov ax,0x8000
  mov ds,ax
  mov di,0
  mov si,0
.endInit
  dw .endCode - ($+2)
  mov ax,[bx+9999]
  stosb
  inc di
.endCode:


experimentADDMOVW:
  db "ADDMOVW$"
  dw .endInit - ($+2)
  mov ax,0xb800
  mov es,ax
  mov ax,0x8000
  mov ds,ax
  mov di,0
  mov si,0
.endInit
  dw .endCode - ($+2)
  or di,0x101
  movsw
.endCode:


lastExperiment:
  db '$'


savedSS: dw 0
savedSP: dw 0
dummy: dw 0

timerEndStart:
  in al,0x40
  mov bl,al
  in al,0x40
  mov bh,al

  refreshOn

  mov al,0x20
  out 0x20,al

  mov ax,cs
  mov ds,ax
  mov es,ax
  mov ss,[savedSS]
  mov sp,[savedSP]

  ; Don't use IRET here - it'll turn interrupts back on and IRQ0 will be
  ; triggered a second time.
  popf
  retf
timerEndEnd:


  ; This must come last in the program so that the experiment code can be
  ; copied after it.

interrupt8:
  pushf

  mov al,TIMER1 | LSB | MODE2 | BINARY
  out 0x43,al
  mov al,19
  out 0x41,al  ; Timer 1 rate

  mov ax,cs
  mov ds,ax
  mov es,ax
  mov [savedSS],ss
  mov [savedSP],sp
  mov ss,ax
  mov dx,0;xffff
  mov cx,0
  mov bx,0
  mov ax,0
  mov si,0
  mov di,0
  mov bp,0
;  mov sp,0

times 528 push cs

  mov al,TIMER0 | BOTH | MODE2 | BINARY
  out 0x43,al
  mov al,0x00
  out 0x40,al
  out 0x40,al
timerStartEnd:

