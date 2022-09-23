$departamentos = @()
$listaDepartamentos = @()

$materias = Import-CSV -Delimiter '|' -Path .\materias.txt | Sort-Object -Property Departamento, IdMateria
foreach ($materia in $materias) {
    $departamentos += $materia.Departamento
}

$departamentos = $departamentos | Select-Object -Unique

foreach ($dpto in $departamentos) {
    $objetoDepartamento = [PSCustomObject]@{
        id  = [int]$dpto
        notas = New-Object System.Collections.ArrayList
    }
    $listaDepartamentos += $objetoDepartamento
}

$abandonos = @{ }
$promocionados = @{ }
$finales = @{ }
$recursantes = @{ }

$notas = Import-CSV -Delimiter '|' -Path .\notas_1.txt
foreach ($nota in $notas) {
    $P1 = $nota.PrimerParcial
    $P2 = $nota.SegundoParcial
    $REC = $nota.Recuperatorio

    if ( ($P1 -eq "" -and $P2 -eq "") -or ( ($P1 -eq "" -or $P2 -eq "") -and $REC -eq "" ) ) {
        
        $abandonos[$nota.IdMateria]++
    }
    elseif ( ( $P1 -ge 7 -and ($REC -gt 7 -or ($P2 -ge 7 -and $REC -eq "")) ) -or ( ($P1 -ge 4 -and $P1 -lt 7) -and ($P2 -ge 7 -and $REC -ge 7) ) -or ( $P1 -lt 4 -and ($P2 -ge 7 -and $REC -ge 7) ) ) {
        $promocionados[$nota.IdMateria]++
    }
    elseif ( ( ($P1 -ge 7 -and ( ($REC -ge 4 -and $REC -lt 7) -or ($P2 -ge 4 -and $P2 -lt 7 -and $REC -eq ""))) ) -or ( ($P1 -ge 4 -and $P1 -lt 7) -and (($REC -ge 4 -and $REC -lt 7) -or ($P2 -ge 7 -and $REC -eq "") -or ($P2 -ge 4 -and $P2 -lt 7 -and ($REC -ge 4 -or $REC -eq "")) -or ($P2 -lt 4 -and $REC -ge 4)) ) -or ( $P1 -lt 4 -and (($P2 -ge 7 -and $REC -ge 4 -and $REC -lt 7) -or (($P2 -ge 4 -and $P2 -lt 7) -and ($REC -ge 4 -and $REC -lt 7))) ) ) {
        $finales[$nota.IdMateria]++
    }
    elseif ( ( $P1 -ge 4 -and $REC -lt 4 ) -or ( $P1 -lt 4 -and ($REC -lt 4 -or $P2 -lt 4)  ) ) {
        $recursantes[$nota.IdMateria]++
    }
}

foreach ($materia in $materias) {
    $objetoMateria = [PSCustomObject]@{
        id_materia  = [int]$materia.IdMateria
        descripcion = $materia.Descripcion
        final = If ($null -eq $finales[$materia.IdMateria]) {0} Else {$finales[$materia.IdMateria]}
        recursan = If ($null -eq $recursantes[$materia.IdMateria]) {0} Else {$recursantes[$materia.IdMateria]}
        abandonaron = If ($null -eq $abandonos[$materia.IdMateria]) {0} Else {$abandonos[$materia.IdMateria]}
        promocionan = If ($null -eq $promocionados[$materia.IdMateria]) {0} Else {$promocionados[$materia.IdMateria]}
    }

    foreach($dpto in $listaDepartamentos) {
        if($dpto.id -eq $materia.Departamento) {
            $dpto.notas.Add($objetoMateria) > $null
        }
    }
}

$salida = [PSCustomObject]@{
    departamentos = $listaDepartamentos;
}

ConvertTo-Json -InputObject $salida -Depth 100 > salida.json