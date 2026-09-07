; ==========================================================================
;  08_relocation_detaillee.asm - LA RELOCATION A62, DEMONTREE ET TESTABLE
;
;  La relocation est le mecanisme le plus subtil de XASM2026-4. Ce programme la
;  demontre en la faisant TOURNER sur le Sharp (contrairement aux autres exemples
;  du dossier). Il :
;    1. copie un petit CORPS relogeable a une AUTRE adresse (demo_buffer) ;
;    2. SABOTE le message d'origine (pour prouver que la copie ne le lit plus) ;
;    3. applique la TABLE DE RELOCATION generee par 'rel' pour corriger la copie ;
;    4. execute la copie relocalisee.
;
;  Resultat a l'ecran :
;    - "RELOC. REUSSIE"  -> la copie lit son message A SA NOUVELLE ADRESSE : OK.
;    - "ECHEC RELOC."    -> (n'arrive pas) la copie aurait lu l'original sabote.
;
;  Deployer :   xasm2026-4 08_relocation_detaillee.asm -O RELODEMO.OBJ -B 08_relocation_detaillee.uu
;  Puis sur le Sharp :  LOADM "x:RELODEMO.OBJ"  puis  CALL &BF000
;
;  INSPECTER la relocation avec PEEK (apres le CALL) : le champ d'adresse du
;  'mv x' de la COPIE est en 0BF091h. Avant le CALL il vaudrait l'adresse a la
;  base ; apres, il a ete corrige vers la copie :
;     PRINT HEX$ PEEK &BF091; HEX$ PEEK &BF092; HEX$ PEEK &BF093
;  affiche  A3 F0 0B  (soit 0BF0A3h = le message DANS la copie).
; ==========================================================================

	org	0BF000H
	pre_on				; adressage RAM interne absolu

; --- constantes systeme ---
fcs_call:	equ	0FFFE4H		; appel FCS (affichage)
cl:		equ	0D6H		; handle : 0 = ecran

; --- macro A62 : 'bsr X' = 'rel call X' (rappel ; non utilisee ici) ---
#defmacro bsr
	rel call %0
#endmacro

; ==========================================================================
;  PROGRAMME (lance par CALL &BF000)
; ==========================================================================
start:
	popu	x			; pointeur de ligne BASIC
	pushu	x			; ... restitue -> retour propre (pas de Syntax error)

;  (1) COPIER le corps relogeable a demo_buffer (une autre adresse).
;      Le corps est assemble a 'corps' ; on le copie tel quel, ses adresses
;      absolues pointent donc encore vers 'corps' -> il faut les corriger.
	mv	i,fin_corps-corps
	mv	y,demo_buffer
	mv	x,corps
cp_lp:	mv	a,[x++]
	mv	[y++],a
	dec	i
	jrnz	cp_lp

;  (2) SABOTER l'original : ecraser le message d'origine par un message d'echec
;      (meme longueur). Ainsi, si la copie relisait l'original (relocation ratee),
;      on verrait "ECHEC RELOC.". La copie, elle, garde le bon message.
	mv	i,btm_ok-msg_ok
	mv	y,msg_ok
	mv	x,msg_echec
sb_lp:	mv	a,[x++]
	mv	[y++],a
	dec	i
	jrnz	sb_lp

;  (3) RELOCALISER la copie a l'aide de la table generee par 'rel'.
;      Le point de depart du parcours compense le fait que les deltas de la
;      table sont comptes depuis l'ORG (0BF000h), alors que la copie demarre
;      a demo_buffer :   depart = demo_buffer - (corps - ORG).
;      Pour chaque site : nouvelle_valeur = valeur - corps + demo_buffer.
	mv	x,demo_buffer
	mv	ba,corps-0BF000H	; offset de 'corps' depuis l'ORG (constante)
	sub	x,ba
	mv	y,x			; y = pointeur de parcours (walker)
	mv	x,table_reloc		; x = pointeur de lecture de la table
rl_lp:	mv	a,[x++]			; lire un octet de table
	cmp	a,0FFH
	jrz	rl_fin			; 0FFh -> fin de table
	and	a,7FH			; delta (on ignore le bit de largeur : on corrige 3 octets)
	add	y,a			; walker += delta -> pointe le champ d'adresse dans la copie
	pushu	x			; sauver le pointeur de table
	mv	x,[y]			; x = adresse gravee (3 octets)
	pushu	y
	mv	y,corps
	sub	x,y			; - base d'assemblage (corps)
	mv	y,demo_buffer
	add	x,y			; + adresse de destination (demo_buffer)
	popu	y			; restaurer le walker
	mv	[y],x			; reecrire l'adresse corrigee
	popu	x			; restaurer le pointeur de table
	jr	rl_lp
rl_fin:

;  (4) EXECUTER la copie relocalisee. Son 'mv x,msg_ok' a ete corrige pour
;      pointer le message DANS LA COPIE : elle affiche donc "RELOC. REUSSIE".
	callf	demo_buffer

	rc				; carry clair -> retour propre a BASIC
	retf

; ==========================================================================
;  LE CORPS RELOGEABLE  (copie en demo_buffer, puis relocalise)
;  Il ne contient qu'UNE adresse absolue a reloger : 'mv x,msg_ok'.
;  ('callf fcs_call' vise la ROM, adresse fixe : PAS relogee.)
; ==========================================================================
corps:
	rel	mv x,msg_ok		; <-- SITE de relocation (champ 3 octets)
	mv	y,btm_ok-msg_ok
	mv	(cl),0
	mv	il,4
	callf	fcs_call
	retf
msg_ok:	db	'RELOC. REUSSIE',13,10
btm_ok:
fin_corps:

; --------------------------------------------------------------------------
;  Donnees de l'installateur (NON copiees, apres fin_corps).
; --------------------------------------------------------------------------
msg_echec:	db	'ECHEC RELOC.  ',13,10	; MEME longueur que msg_ok

demo_buffer:	ds	64		; zone ou l'on copie le corps

;  'table_reloc' est place juste avant END : c'est donc l'adresse ou la table
;  de relocation generee sera ajoutee. Le programme la lit a cet endroit.
table_reloc:
	end
