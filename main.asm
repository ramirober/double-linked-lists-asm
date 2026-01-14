# Comments/Strings only in Spanish
# 
# Ramiro Berbetoros
# Programa de creacion de Categorias y Objetos doblemente enlazados:
#
# Las "Categorias" son nodos de 16 bytes ubicados en una lista doblemente enlazada (contienen direcciones de nodos previos y siguientes)
# y tambien contienen en las 2 words de 4 bytes restantes un Nombre (ej.: Mamiferos, Reptiles, etc.) 
# y un puntero (o direccion) a una lista doblemente enlazada de "Objetos"
#
# Los "Objetos" son similares a las categorias, contienen un Nombre (ej.: Perro, Gato, etc.) y un dato de indice (0x1, 0x2, 0x3 o 0x4), 
# ya que pertenecen a otra lista doblemente enlazada de maximo 4 elementos
#
# Datos Categorias en memoria:
# +0 a +c: String del nombre terminado en NULL
# +10: Cat. Previa
# +14: Puntero a inicio de lista de Objetos
# +18: Direccion del Nombre de Categoria en ASCII (+0)
# +1c: Cat. Siguiente

# Datos Objetos en memoria:
# +0 a +c: String del nombre
# +10: Objeto Previo
# +14: Orden (0x1, 0x2, etc.)
# +18: Direccion del Nombre de Objeto en ASCII (+0)
# +1c: Objeto Siguiente

		.data
slist: 	.word 0 			# Puntero usado por smalloc y sfree para indicar el siguiente "espacio libre" dinamicamente
cclist: .word 0 			# Puntero de la lista de categorias desde el inicio
wclist: .word 0 			# Puntero de la categoria seleccionada
schedv: .space 32 			# Puntero a cada una de las opciones programadas (newcat, nextcat, prevcat, etc.)
menu: 	.ascii "\n\nColecciones y Objetos\n"
		.ascii "====================================\n\n"
		.ascii "1-Nueva categoria\n"
		.ascii "2-Siguiente categoria\n"
		.ascii "3-Categoria anterior\n"
		.ascii "4-Listar categorias\n"
		.ascii "5-Borrar categoria actual\n"
		.ascii "6-Anexar objeto a la categoria actual\n"
		.ascii "7-Listar objetos de la categoria\n"
		.ascii "8-Borrar objeto de la categoria\n"
		.ascii "0-Salir\n\n"
		.asciiz "Ingrese la opcion deseada: "
error: 	.asciiz "Error, intente nuevamente: "
retry:	.asciiz "Intente nuevamente: "
err201:	.asciiz "Error 201: No hay categorias creadas\n"
err202:	.asciiz "Error 202: Hay una sola categoria creada\n"
err301:	.asciiz "Error 301: No hay categorias creadas para listar\n"
err401: .asciiz "Error 401: No hay categorias\n"
err501: .asciiz "Error 501: No hay categoria seleccionada\n"
err601:	.asciiz "Error 601: No hay categorias creadas\n"
err602:	.asciiz "Error 602: No hay objetos en la categoria actual\n"
err701: .asciiz "Error 701: El objeto no se ha encontrado\n"
return: .asciiz "\n"
catName:.asciiz "Ingrese el nombre de una categoria: "
selCat: .asciiz "Se ha seleccionado la categoria: "
idObj: 	.asciiz "Ingrese el ID del objeto a eliminar: "
objName:.asciiz "Ingrese el nombre de un objeto: "
success:.asciiz "La operación se realizo con exito!\n"
selchar:.ascii "> "

		.globl main 		# Definimos la etiqueta main como la ejecucion principal

# EJECUCION DEL PROGRAMA

		.text
main:	la $t1, schedv		# Cargamos en $t0 la direccion de schedv
		
		la $t0, newcat		# Cargamos cada una de las funciones en el espacio reservado por schedv
		sw $t0, 0($t1)
		la $t0, nextcat
		sw $t0, 4($t1)
		la $t0, prevcat
		sw $t0, 8($t1)
		la $t0, listcat
		sw $t0, 12($t1)
		la $t0, delcat
		sw $t0, 16($t1)
		la $t0, newobj
		sw $t0, 20($t1)
		la $t0, listobj
		sw $t0, 24($t1)
		la $t0, delobj    
		sw $t0, 28($t1)
		
menu_p:	li $v0, 4			# Imprimimos todo el menu
		la $a0, menu
		syscall

menu_loop:
		li $v0, 4			# Imprimimos todo el menu
		la $a0, menu
		syscall

		li $v0, 5			# Leer número de opción
		syscall
		
		beqz $v0, exit		# Si es cero, cerramos el programa
		bgt $v0, 8, error_menu# Si es mas que 8, imprimimos error y volvemos al bucle
		blt $v0, 0, error_menu# Si es menos que 0, tambien
		
		la $t1, schedv		# Cargamos la direccion de schedv
		subi $v0, $v0, 1	# Restamos 1 al input, ya que asi entra en el margen
		sll $t2, $v0, 2		# Aplicamos sll para multiplicar por 4 (2 a la 2) el input y obtener un offset en bytes
		add $t3, $t1, $t2	# Usamos ese offset y se lo sumamos a schdev para ir a la funcion correcta
		lw $t4, ($t3)		# Cargamos su direccion...
		jalr $t4			# Y la ejecutamos. (setea $ra y saltamos a $t4)
		# Aca retornamos volviendo de cualquier funcion con jr $ra
		j menu_loop			# Una vez finaliza la ejecucion de la funcion (retorna a $ra) volvemos a ejecutar el menu

exit:	li $v0, 10			# Código de salida/fin del programa
		syscall

# FUNCIONES

# FUNCIONES PARA CATEGORIAS

# Nueva Categoria
newcat:	addiu $sp, $sp, -8 	# Seteamos sp (stack pointer) a -8 (crece en direcciones decrecientes) para reservar el espacio a usar por esta funcion CAMBIO
		sw $ra, 4($sp) 		# Guardamos la return address en el principio del stack (sp-4+4)
		sw $a0, 0($sp)		# Guardamos $a0 por si es necesario restaurar el valor posteriormente
		
		# IMPORTATE: Este desplazamiento y el guardado de ra en el stack lo hacemos para 
		# tener una referencia exacta de las funciones "en ejecucion" y su memoria, como para preservar valores de registros clave
		
		la $a0, catName 	# Cargamos la direcicon de la opcion del input del nombre de la nueva Categoria (catName)
		li $v0, 4			# Imprimimos la opcion
		syscall
		
		jal getblock
		
		la $a0, cclist 		# Cargamos en $a0 la direccion de la lista de categorias
		li $a1, 0 			# Guardamos en $a1 el dato 0, para en la categoria inicializar la lista de objetos en 0
		move $a2, $v0 		# Guardamos en a2 el puntero del bloque creado en getblock ($v0)
		jal addnode 		# Agregamos el nodo
		
		lw $t0, wclist 		# Cargamos en $t0 la categoria seleccionada
		bnez $t0, newcat_end# Si $t0 (la categoria actual) existe, vamos al final
		sw $v0, wclist 		# Si es la primera, guardamos $v0 (su puntero) en wclist, es decir la seleccionamos
		
		lw $t1, cclist		# Cargamos la lista de categorias nuevamente (su direccion de inicio)
		bnez $t1, newcat_end# Si ya tenemos una categoria inicial en la lista, vamos al final
		sw $v0, cclist		# Si es la primera, fijamos el punto de inicio
newcat_end:
		jal success_print	# Imprimimos "Exito!"
		
		lw $a0, 0($sp)		# Restauramos el valor original de $a0
		
		lw $ra, 4($sp) 		# Reestablecemos en $ra su valor original guardado en 4($sp)
		addiu $sp, $sp, 8 	# Restauramos el puntero de la pila para no tener un desborde
		jr $ra				# Retornamos la funcion para volver al menu

# Categoria siguiente
nextcat:addiu $sp, $sp, -8
		sw $ra, 4($sp)
		sw $a0, 0($sp)
		
		lw $t0, wclist		# Cargamos la direccion de la categoria actual
		beqz $t0, nocats_err#Si no existe una categoria seleccionada imprimimos error 201
		lw $t1, 12($t0)		# Cargamos la direccion de la siguiente categoría
		beq $t0, $t1, onecat_err# Si la siguiente es igual a la actual (es una sola) imprimimos error 202
		move $a0, $t1		# Movemos la dirección de la siguiente categoría a $a0 (argumento)
		sw $t1, wclist		# Guardamos la nueva categoría en wclist
		
		jal printselcat		# Imprimimos la seleccion de categoria
	
		lw $a0, 8($t1)		# Cargamos el valor de 8($t1), que es el puntero al nombre de la categoria seleccionada
		li $v0, 4
		syscall				# Imprimimos el nombre
		
		lw $ra, 4($sp)
		addiu $sp, $sp, 8
		jr $ra

# Categoria anterior
prevcat:addiu $sp, $sp, -8
		sw $ra, 4($sp)
		sw $a0, 0($sp)

		lw $t0, wclist		# Cargamos la direccion de la categoria actual
		beqz $t0, nocats_err#Si no existe una categoria seleccionada imprimimos error 201
		lw $t1, 0($t0)		# Cargamos la direccion de la categoria anterior
		beq $t0, $t1, onecat_err# Si la anterior es igual a la actual (es una sola) imprimimos error 202
		move $a0, $t1		# Movemos la dirección de la categoría anterior al argumento $a0
		sw $t1, wclist		# Guardamos la nueva categoría en wclist
		
		jal printselcat		# Imprimimos la seleccion de categoria
		
		lw $a0, 8($t1)		# Cargamos el valor de 8($t1), que es el puntero al nombre de la categoria seleccionada
		li $v0, 4
		syscall				# Imprimimos el nombre
		
		j selcat_ret

printselcat:
		la $a0, selCat	# Cargamos los datos necesarios para imprimir la categoria seleccionada
		li $v0, 4
		syscall
		
		jr $ra

nocats_err:
		la $a0, err201		# Imprimimos el error 201
		li $v0, 4
		syscall
		j selcat_ret

onecat_err:
		la $a0, err202		# Imprimimos el error 202
		li $v0, 4
		syscall		

selcat_ret:
		lw $ra, 4($sp)
		addiu $sp, $sp, 8
		jr $ra

# Listar categorias
listcat:lw $t0, cclist		# Cargamos en $t0 la lista de categorias
		beqz $t0, listcat_err# Si no hay categorias creadas (cclist tiene valor 0), imprimimos un error

listcat_loop:
		lw $t1, wclist		# Cargamos en $t1 la categoria actual, para poder imprimir el indicador de seleccion
		bne $t1, $t0, listcat_notsel# Si no esta seleccionada, no imprimimos nada
		
		la $a0, selchar		# Imprimimos el caracter de seleccion
		li $v0, 4
		syscall

listcat_notsel:
		lw $a0, 8($t0)		# Cargamos el nombre de la categoría en $a0
		li $v0, 4			# Imprimimos el string...
		syscall

		lw $t0, 12($t0)		# Cargamos en $t0 el siguiente nodo
		
		lw $t1, cclist		# Cargamos nuevamente cclist pero en t1
		beq $t0, $t1, listcat_end# Si ya recorrimos todos, vamos al final
		j listcat_loop		# Loopeamos...

listcat_err:
		la $a0, err301		# Imprimimos el error 301
		li $v0, 4
		syscall

listcat_end:
		jr $ra

# Borrar categoria
delcat:	addiu $sp, $sp, -8
		sw $ra, 4($sp)
		sw $a0, 0($sp)

		lw $t0, wclist		# Cargamos el puntero de la categoria seleccionada en $t0
		beqz $t0, delcat_err# Si no hay categoria seleccionada, mostramos el error 401
    
		lw $t1, 0($t0)		# Cargamos el puntero del anterior en $t1
		lw $t2, 12($t0)		# Cargamos el puntero del siguiente en $t2
		
		lw $t3, 4($t0)      # Cargamos la lista de objetos de la categoría en $t3
		beqz $t3, delcat_cont# Si la categoria no tiene objetos, la borramos directamente

delcat_obj_loop:
		lw $t4, 12($t3)		# Cargamos el siguiente del nodo que estamos analizando
		beq $t3, $t4, delobj_last
		
		move $a0, $t3       # Pasamos el objeto actual a $a0 para delnode
		la $a1, 4($t0)   	# También la dirección base de la lista de objetos
		jal delnode         # Borramos el objeto actual
		move $t3, $t4     	# Cargamos el siguiente objeto en $t3
		
		j delcat_obj_loop   # Repetimos el proceso para el siguiente objeto

delobj_last:
		move $a0, $t3		# Movemos a $a0 el ultimo objeto de la lista
		la $a1, 4($t3)		# Cargamos la direccion del dato de la lista de objetos en la categoria
		jal delnode			# Liberamos el espacio del nodo

delcat_cont:
		lw $a0, wclist		# Cargamos para delnode en $a0 la categoria activa (wclist) para borrarla
		la $a1, cclist		# Y en $a1 la direccion del comienzo de la lista de categorias
		
		jal delnode			# Liberamos el espacio del nodo

		lw $t0, cclist		# Cargamos la lista de categorías
		beqz $t0, wclist_reset# Si no hay mas categorias, reinciamos wclist tambien
		sw $t2, wclist		# Si queda al menos una categoría, asignamos la siguiente como seleccionada
		j delcat_done

wclist_reset:
		sw $zero, wclist

delcat_done:
		jal success_print	# Imprimimos mensaje de exito

		lw $a0, 0($sp)
		lw $ra, 4($sp)
		addiu $sp, $sp, 8
		jr $ra

delcat_err:la $a0, err401	# Mostrar error 401
		li $v0, 4
		syscall
		
		la $a0, retry		# Intentar nuevamente
		li $v0, 4
		syscall
		
		lw $a0, 0($sp)
		lw $ra, 4($sp)
		addiu $sp, $sp, 8
		jr $ra

## FUNCIONES PARA OBJETOS

# Nuevo objeto
newobj:	addiu $sp, $sp, -8	# Reservamos espacio en el stack
		sw $ra, 4($sp)		# Guardamos la dirección de retorno
		sw $a0, 0($sp)		# Guardamos el registro $a0 por si se necesita restaurar

		la $a0, objName		# Pedimos al usuario ingresar el nombre del objeto
		li $v0, 4
		syscall

		jal getblock		# Reservamos memoria para el nuevo objeto
   
		lw $t0, wclist
		beqz $t0, newobj_err# Si no hay categoria seleccionada, devolvemos error 501
		
		la $a0, 4($t0)
		li $a1, 0			# Inicializamos el indice en 0 (posteriormente se aumenta a 1)
		move $a2, $v0		# Guardamos el puntero del nuevo objeto en $a2
		jal addnode			# Agregamos el nodo a la lista de objetos de la categoría actual

		lw $t0, wclist		# Cargamos la categoría seleccionada en $t0
		beqz $t0, newobj_err# Si no hay categoría seleccionada, lanzamos error 501
		lw $t2, 4($t0)		# Cargamos el puntero actualizado en $t2 (para comenzar a loopear)

		move $t3, $t2		# Iniciamos el recorrido desde el primer objeto

newobj_loop:
		addi $a1, $a1, 1	# Adicionamos 1 para iniciar los indices en 1
		
		lw $t4, 12($t3)		# Cargamos el siguiente objeto en la lista
		beq $t2, $t4, add_obj_index# Si llegamos al final, insertamos el nuevo objeto
		move $t3, $t4		# Continuamos recorriendo la lista
		
 		j newobj_loop

add_obj_index:
		sw $a1, 4($t3)
		j newobj_end

newobj_end:
		jal success_print	# Imprimimos mensaje de éxito

		lw $a0, 0($sp)		# Restauramos el valor de $a0
		lw $ra, 4($sp)		# Restauramos la dirección de retorno
		addiu $sp, $sp, 8	# Restauramos el stack
		jr $ra				# Retornamos

newobj_err:
		la $a0, err501		# Mostramos error 501 (categoría no seleccionada)
		li $v0, 4
		syscall
		j newobj_end

# Listar objetos
listobj:addiu $sp, $sp, -8
    	sw $ra, 4($sp)
    	sw $a0, 0($sp)
		
		lw $t0, wclist		# Cargamos la categoria actual en $t0
		beqz $t0, list_nocat_err
		lw $t1, 4($t0)		# Y carmamos la lista de objetos en $t1
		move $t2, $t1		# Movemos para empezar el nodo activo a $t2
listobj_loop:
		beqz $t1, listobj_noobj# Si no hay categoria, devolvemos error
		lw $a0, 8($t2)		# Cargamos el nombre del objeto
		li $v0, 4			# Imprimimos el string
		syscall

		lw $t3, 12($t2)		# Nos movemos al siguiente objeto de $t2 cargando en $t3 la direccion
		beq $t1, $t3, list_ret# Si el principio es igual al final, recorrimos toda la lista y vamos al final
		move $t2, $t3
		
		j listobj_loop
		
listobj_noobj:
		la $a0, err602		# Imprimimos el error 602
		li $v0, 4
		syscall
		la $a0, retry		# Imprimimos Intente nuevamente
		li $v0, 4
		syscall

list_nocat_err:
		la $a0, err601		# Imprimimos el error 601
		li $v0, 4
		syscall
		la $a0, retry		# Intente nuevamente
		li $v0, 4
		syscall

list_ret:	
		lw $a0, 0($sp) 
		lw $ra, 4($sp)
		addiu $sp, $sp, 8
		jr $ra

# Borrar objeto
delobj:	addiu $sp, $sp, -8	# Reservar espacio en el stack
		sw $ra, 4($sp)		# Guardar la dirección de retorno
		sw $a0, 0($sp)		# Guardar $a0 por si se necesita restaurar

		la $a0, idObj		# Cargamos la opcion del menu
		li $v0, 4			# Imprimimos el string
		syscall

		li $v0, 5			# Leemos el entero (input) del ID
		syscall
		
		move $t1, $v0		# Guardamos en $t1 el ID del objeto
		
		lw $t0, wclist		# Cargamos la categoria actual en $t0
		la $a1, 4($t0)		# Cargamos la direccion del inicio de la lista de los objetos que contiene
		
		lw $a0, 4($t0)		# Cargamos la direccion del primero objeto de la lista
		move $t2, $a0		# Movemos a $t2 el primer nodo y vamos al loop...
id_loop:
		lw $t3, 4($t2)		# Cargamos el id del objeto
		bne $t3, $t1, nextobj# Si el ID ingresado no coincide con el del objeto, vamos al siguiente...
		move $a0, $t2		# Si coincide, movemos a $a0 el nodo encontrado para delnode
		jal delnode
		j delobj_end
				
nextobj:lw $t4, 12($t2)		# Cargamos el siguiente nodo...
		beq $t4, $a0, delobj_err# Si loopeamos toda la lista (el principio es igual al final) y no encontramos el ID, lanzamos error
		move $t2, $t4		# Pasamos el siguiente nodo al actual y seguimos el loop
		j id_loop
		
delobj_end:
		jal success_print	# Imprimimos "Exito!"
		j delobj_ret
delobj_err:
		la $a0, err701		# Imprimimos el error 701
		li $v0, 4
		syscall
		
		la $a0, retry		# Intente nuevamente
		li $v0, 4
		syscall
		
delobj_ret:
		lw $a0, 0($sp)
        lw $ra, 4($sp)
        addiu $sp, $sp, 8
        jr $ra

## FUNCIONES GENERALES

# error: Imprime un error de seleccion en el menu y reinicia el loop
error_menu:li $v0, 4
		la $a0, error
		syscall
		
		j menu_loop

# success_print: Imprime el mensaje de exito en la operacion
success_print:li $v0, 4
		la $a0, success
		syscall
		jr $ra

# addnode: Agrega un nodo a una Categoria u Objeto
# a0: Direcciones de la lista de categorias (Cat) y de objetos (Obj)
# a1: NULL/0 si es Categoria, Indice (desde 1) si es un Objeto
# a2: Direccion del nuevo nodo (Desde String ASCII)
# v0: Direccion del nuevo nodo (Desde datos)
addnode:addi $sp, $sp, -8 	# Desplazamos el puntero de stack a -8
		sw $ra, 8($sp) 		# Guardamos $ra (retorno) para preservarlo
		sw $a0, 4($sp) 		# Guardamos el dato de $a0 (cclist para Categorias, wclist en caso de objeto) en el stack
		
		jal smalloc 		# Alocamos memoria para la lista
		
		sw $a1, 4($v0) 		# Guardamos $a1 en el 2do dato del nodo. Inicialmente es 0 para categorias
		sw $a2, 8($v0) 		# Guardamos $a2 en el 3er dato del nodo. Este es el puntero al String en ASCII (principio del nodo)
		
		lw $a0, 4($sp) 		# Restauramos en $a0 cclist/wclist (Lista de Categorias o Categoria Activa)
		lw $t0, ($a0) 		# Cargamos en $t0 la direccion del primer nodo de cclist o bien el nodo de wclist
		beqz $t0, addnode_empty_list # Si es una direccion vacia... (Lista vacia)
		# Si agregamos el nodo al final...
addnode_to_end:lw $t1, ($t0)# Cargamos en $t1 la direccion del primer nodo de cclist
		sw $t1, 0($v0) 		# Guardamos puntero del primer nodo en el "anterior" del nuevo nodo
		sw $t0, 12($v0) 	# Guardamos puntero del primer nodo en el "siguiente" del nuevo nodo
		sw $v0, 12($t1) 	# Guardamos $v0 (nuevo nodo) en el siguiente del ultimo nodo
		sw $v0, 0($t0) 		# Guardamos $v0 (nuevo nodo) en primer nodo
		j addnode_exit 		# Terminamos la funcion...
		# Luego agregamos el nuevo nodo al final de la lista existente...
addnode_last_node:
		sw $a2, 12($v0) 	# Guardamos puntero del primer nodo en el "siguiente" del nuevo nodo
		sw $v0, 12($t0) 	# Guardamos $v0 (nuevo nodo) en el siguiente del ultimo nodo
		sw $v0, 0($t0) 		# Guardamos $v0 (nuevo nodo) en primer nodo
		j addnode_exit 		# Terminamos la funcion...
		# Si agregamos el nodo a una lista vacia...
addnode_empty_list:sw $v0, ($a0)# Guardamos $v0 (nodo creado) en la direccion $a0 
		sw $v0, 0($v0) 		# Guardamos $v0 (nodo creado) en la direccion que apunta $v0 (puntero al anterior en el nodo)
		sw $v0, 12($v0) 	# Guardamos $v0 en la direccion que apunta 12($v0) (puntero al siguiente en el nodo)
		j addnode_exit		# Terminamos...
		# Final de addnode
addnode_exit:lw $ra, 8($sp) # Cargamos en el retorno el puntero del principio del stack
		lw $a0, 4($sp)
		addi $sp, $sp, 8
		jr $ra 				# Terminamos la ejecucion

# delnode: Borrar nodo
# a0: Direccion del nodo a borrar
# a1: Direccion de comienzo de la lista (.data) que contiene el nodo a borrar (cclist en Categoria, wclist+4 en objetos)
delnode:addi $sp, $sp, -8 	# Desplazamos el stack en -8
		sw $ra, 8($sp) 		# Guardamos el retorno en sp+8
		sw $a0, 4($sp) 		# Guardamos $a0 (la direccion del nodo a borrar) en 4($sp)
		
		lw $a0, 8($a0) 		# Cargamos en $a0 la direccion del nodo desde el STRING
		jal sfree 			# Ejecutamos sfree para liberar el nodo entero
		
		lw $a0, 4($sp) 		# Cargamos en $a0 el argumento anterior ubicado en 4($sp) (nodo a borrar)
		lw $t0, 12($a0) 	# Cargamos en $t0 la direccion del siguiente nodo a $a0
		
		beq $a0, $t0, delnode_point_self # Si el nodo apunta a si mismo...
		
		# Ahora alteramos los punteros del siguiente/anterior a $a0...
		lw $t1, 0($a0) 		# Cargamos en $t1 la direccion del nodo anterior
		
		sw $t1, 0($t0) 		# Guardamos esa direccion en el siguiente nodo a $a0
		sw $t0, 12($t1) 	# Guardamos la direccion del nodo siguiente a $a0 en el "siguiente" del nodo anterior
		
		lw $t1, 0($a1) 		# Cargamos en $t1 la direccion del primer nodo de la lista
		bne $a0, $t1, delnode_exit# Si no borramos el primer nodo de la lista (cclist/wclist+4)...
		sw $t0, ($a1) 		# Hacemos apuntar la lista al siguiente nodo
		
		j delnode_exit
		
delnode_point_self:
		sw $zero, ($a1)		# Guardamos $zero en la direccion del comienzo de la lista
delnode_exit:
		# "Nulificamos" los punteros del nodo
		sw $zero, ($a0)		# Asignamos 0 al anterior del nodo a eliminar
		sw $zero, 12($a0)	# Asignamos 0 al siguiente del nodo a eliminar
		jal sfree
		lw $ra, 8($sp)
		addi $sp, $sp, 8
		jr $ra

# getblock: Crear Bloque (Categoria o Objeto), leyendo el input de su nombre y devuelve el puntero al string
getblock:
		addi $sp, $sp, -4	# Restamos 4 al puntero del stack... (crece)
		sw $ra, 4($sp) 		# Luego guardamos $ra en el principio del stack para preservarlo
		
		jal smalloc 		# Alocamos la memoria del el nuevo nodo/bloque
		move $a0, $v0 		# Copiamos $v0 dentro de $a0 (la direccion de slist inicial, antes de reservar con smalloc/sbrk mas espacio, es decir es el nodo creado)
		
		li $a1, 16 			# Cargamos el parametro de Maximos caracteres a leer de read string (syscall 8)
		li $v0, 8 			# read string. Leemos el nombre de la Categoria o el Objeto
		syscall 			# La lectura del input termina en $a0
		
		move $v0, $a0 		# Copiamos en $v0 el puntero del nuevo bloque desde el String
		
		lw $ra, 4($sp) 		# Restauramos en $ra el puntero original
		addi $sp, $sp, 4 	# Reubicamos el puntero del stack $sp
		jr $ra 				# ...y saltamos a la return adress (volvemos a la funcion que la ejecuto)
		
# smalloc: Alocacion/desplazamiento de memoria para cada nodo
smalloc:lw $t0, slist 		# Cargamos en el registro $t0 el puntero slist
		beqz $t0, sbrk 		# Si t0 es igual a zero (si no hay nodo), vamos a "sbrk"
		move $v0, $t0 		# Copiamos el contenido de $t0 (puntero a slist) a $v0
		lw $t0, 12($t0) 	# Cargamos la direccion desplazada de la siguiente categoria/objeto en $t0
		sw $t0, slist 		# Guardamos/sobreescribimos el nuevo puntero en slist
		jr $ra 				# Retornamos la funcion

# sfree: Libera espacio alocado
sfree:	lw $t0, slist 		# Cargamos en t0 slist (puntero a la lista)
		sw $t0, 12($a0) 	# Guardamos t0 en a0 desplazado
		sw $a0, slist 		# Guardamos $a0 en slist como punto de partida para la creacion del siguiente
		jr $ra 				# Retornamos la funcion
		
# sbrk: Ejecucion de sbrk (syscall 9)
sbrk:	li $v0, 9 			# Cargamos el syscall 9 (sbrk)
		li $a0, 16 			# El tamaño es fijo, de 4 words (16 bytes)
		syscall 			# Retorna en v0 la direccion del nodo

		jr $ra 				# Retornamos la funcion
