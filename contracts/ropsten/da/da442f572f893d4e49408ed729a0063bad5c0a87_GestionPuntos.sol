pragma solidity ^0.4.24;

contract GestionPuntos{
    
    address profesor;
    uint curso;
    
    struct Alumno{
        uint matricula;
        string nombreCompleto;
        string campus;
        string grupo;
        int puntos;
    } 
    
    modifier soloProfesor {
        require(
            msg.sender == profesor,
            "Solo el profesor de este curso puede modificar los valores."
        );
        _;
    }
    
    //Constructor, se asigna el profesor y el curso al que pertenece este smart contract
    constructor(address _profesor, uint _curso) public{
        profesor = _profesor;
        curso = _curso;
    }
    
    mapping(uint => Alumno) mRegistros;
    
    //Funci&#243;n para el registro de los alumnos
    //Puede ser llamada publicamente para registro de alumnos
    function registrarAlumno(
        uint _matricula, 
        string _nombreCompleto,
        string _campus,
        string _grupo) public returns (bool ok){
        
        //Al registrar a un alumno con su matricula se le asignan 100 puntos
        mRegistros[_matricula] = Alumno(_matricula,_nombreCompleto,_campus,_grupo,100);
        
        return true;
    }
    
    //Funci&#243;n modificaPuntos para sumar o restar puntos a los alumnos
    //Puede ser llamada s&#243;lo por quien haya registrado el smart contract 
    //Que debe ser el address registrado como profesor
    function modificaPuntos(
        uint _matricula, 
        int _puntos) public soloProfesor returns (int saldo){
        
        Alumno storage al = mRegistros[_matricula];
        
        //validar si es resta
        if(_puntos < 0){
            int res = al.puntos + _puntos;
            
            if(res >= 0){
                al.puntos += _puntos;
            }
            else{
                //No puede tener saldo negativo
                al.puntos = 0;
            }
        }
        else{
            //suma
            al.puntos += _puntos;
        }
        
        return al.puntos;
    }
    
    function getPuntos(uint _matricula) public view returns(int puntos){
         Alumno storage al = mRegistros[_matricula];
         
         return al.puntos;
    }
    
    
    function modificaCurso(
    uint _curso) public soloProfesor returns (bool ok){
        
        curso = _curso;
        
        return true;
    }
       
    function getCurso() public view returns(uint thecurso){
         
         return curso;
    }  
    
    function getProfesor() public view returns(address theprofesor){
         
         return profesor;
    }
    
}