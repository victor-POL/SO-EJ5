#APL N. 2
#SCRIPT 5
#INTEGRANTES:
#Carballo, Facundo Nicolas (DNI: 42774931)
#Garcia Burgio, Matias Nicolas (DNI: 42649117)
#Mottura, Agostina Micaela (DNI: 41898101)
#Povoli Olivera, Victor (DNI: 43103780)
#Szust, Ángel Elías (DNI: 43098495)

<#
.SYNOPSIS
Generar json con el analisis de notas segun departamento y materia.

.DESCRIPTION
Generar json con la cantidad de alumnos aprobados, promocionados, en final y que abandonaron por cada materia y departamento
Los campos de los archivos de notas y materias deben estar separados por "|"
Se debe contar con permisos de lectura sobre los archivos de notas y materias y de escritura para el archivo de salida .json

PARAMETRO 1
-notas ARCHIVO : Ruta del archivo con el registro de las notas de los alumnos a procesar
Formato: DNI|IdMateria|PrimerParcial|SegundoParcial|Recuperatorio|Final

PARAMETRO 2
-materias ARCHIVO: Ruta del archivo con los datos de las materias para poder vincularlos al archivo de notas
Formato: IdMateria|Descripcion|Departamento


.PARAMETER notas
-notas ARCHIVO : Ruta del archivo con el registro de las notas de los alumnos a procesar
Formato: DNI|IdMateria|PrimerParcial|SegundoParcial|Recuperatorio|Final

.PARAMETER materias
-materias ARCHIVO: Ruta del archivo con los datos de las materias para poder vincularlos al archivo de notas
Formato: IdMateria|Descripcion|Departamento

.EXAMPLE
.\script.ps1 -notas notas_1.txt -materias materias.txt\

#>

Param(
    [ValidateScript({
            if (-Not ($_ | Test-Path) ) {
                throw "Archivo o carpeta inexistente" 
            }
            if (-Not ($_ | Test-Path -PathType Leaf) ) {
                throw "Las rutas deben ser de archivos. Rutas de carpeta no se permiten"
            }
            return $true
        })] [Parameter(Mandatory = $True)] [System.IO.FileInfo]$notas,
    [ValidateScript({
            if (-Not ($_ | Test-Path) ) {
                throw "Archivo inexistente" 
            }
            if (-Not ($_ | Test-Path -PathType Leaf) ) {
                throw "Las rutas deben ser de archivos. Rutas de carpeta no se permiten"
            }
            return $true
        })] [Parameter(Mandatory = $True)] [System.IO.FileInfo]$materias
)

# Inicializo las hash tables para contar el estado de las notas segun clave id de materia
$abandonos = @{ }
$promocionados = @{ }
$finales = @{ }
$recursantes = @{ }

# Procesamiento de las notas
# Importo el csv con las notas separadas por pipes
# Dependiendo la condicion de las notas se suma uno a la hash table correspondiente segun el id de materia unico
Import-CSV -Delimiter '|' -Path "$notas" | 
ForEach-Object {
    $FIN = $_.Final
    $P1 = $_.PrimerParcial
    $P2 = $_.SegundoParcial
    $REC = $_.Recuperatorio

    if ($FIN -eq "") {
        if ( ($P1 -eq "" -and $P2 -eq "") -or ( ($P1 -eq "" -or $P2 -eq "") -and $REC -eq "" ) ) {
            $abandonos[$_.IdMateria]++
        }
        elseif ( ( $P1 -ge 7 -and ($REC -gt 7 -or ($P2 -ge 7 -and $REC -eq "")) ) -or ( ($P1 -ge 4 -and $P1 -lt 7) -and ($P2 -ge 7 -and $REC -ge 7) ) -or ( $P1 -lt 4 -and ($P2 -ge 7 -and $REC -ge 7) ) ) {
            $promocionados[$_.IdMateria]++
        }
        elseif ( ( ($P1 -ge 7 -and ( ($REC -ge 4 -and $REC -lt 7) -or ($P2 -ge 4 -and $P2 -lt 7 -and $REC -eq ""))) ) -or ( ($P1 -ge 4 -and $P1 -lt 7) -and (($REC -ge 4 -and $REC -lt 7) -or ($P2 -ge 7 -and $REC -eq "") -or ($P2 -ge 4 -and $P2 -lt 7 -and ($REC -ge 4 -or $REC -eq "")) -or ($P2 -lt 4 -and $REC -ge 4)) ) -or ( $P1 -lt 4 -and (($P2 -ge 7 -and $REC -ge 4 -and $REC -lt 7) -or (($P2 -ge 4 -and $P2 -lt 7) -and ($REC -ge 4 -and $REC -lt 7))) ) ) {
            $finales[$_.IdMateria]++
        }
        elseif ( ( $P1 -ge 4 -and $REC -lt 4 ) -or ( $P1 -lt 4 -and ($REC -lt 4 -or $P2 -lt 4)  ) ) {
            $recursantes[$_.IdMateria]++
        }
        
    }
    elseif ($FIN -lt 4) {
        $recursantes[$_.IdMateria]++
    }
}

# Creo la lista donde voy a guardar los departamentos y sus notas
$listaDepartamentos = New-Object System.Collections.ArrayList

# Cargo el csv de las materias ordenandolo por departamento e id de materia para luego generar el json ordenado
$materiasCargadas = Import-CSV -Delimiter '|' -Path "$materias" | Sort-Object -Property Departamento, IdMateria

# De la lista de materias agrupo los departamentos para que no tenga repetidos y los agrego a la lista de
# departamentos y de paso inicializo para cada uno su lista de notas de cada materia
$materiasCargadas | Group-Object -Property Departamento | 
ForEach-Object {
    $objetoDepartamento = [PSCustomObject]@{
        id    = [int]$_.name
        notas = New-Object System.Collections.ArrayList
    }
    $listaDepartamentos.Add($objetoDepartamento) > $null
}

# Recorro las materias que estan ordenadas primero por el numero de departamento que pertenece y luego por su id
# Creo un objeto para cada uno y le asigno el procesamiento de sus notas
# Busco al departamento que pertenece y lo agrego a la lista de notas del departamento
foreach ($materia in $materiasCargadas) {
    $objetoMateria = [PSCustomObject]@{
        id_materia  = [int]$materia.IdMateria
        descripcion = $materia.Descripcion
        final       = If ($null -eq $finales[$materia.IdMateria]) { 0 } Else { $finales[$materia.IdMateria] }
        recursan    = If ($null -eq $recursantes[$materia.IdMateria]) { 0 } Else { $recursantes[$materia.IdMateria] }
        abandonaron = If ($null -eq $abandonos[$materia.IdMateria]) { 0 } Else { $abandonos[$materia.IdMateria] }
        promocionan = If ($null -eq $promocionados[$materia.IdMateria]) { 0 } Else { $promocionados[$materia.IdMateria] }
    }
    
    foreach ($dpto in $listaDepartamentos) {
        if ($dpto.id -eq $materia.Departamento) {
            $dpto.notas.Add($objetoMateria) > $null
        }
    }
}

# Genero el objeto de salida con toda la informacion para convertirlo en json
$salida = [PSCustomObject]@{
    departamentos = $listaDepartamentos;
}


# Verificacion de si existe otro archivo de salida con el mismo nombre
# si existe lo enumero para que nunca pise al existente
$fecha = get-date -format "yyyy-MM-dd"
$nombreSalida = "$fecha-salida"
$num = 2

if (Test-Path "$nombreSalida.json") {
    do {
        $nombreSalidaNuevo = $nombreSalida + " (" + $num + ")"
        $num++
    } while ((Test-Path "$nombreSalidaNuevo.json"))
    $nombreSalida = $nombreSalidaNuevo
}

# Genero el JSON y lo guardo con el formato especificado antes
ConvertTo-Json -InputObject $salida -Depth 100 > "$nombreSalida.json"
