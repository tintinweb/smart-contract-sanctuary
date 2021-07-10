/**
 *Submitted for verification at Etherscan.io on 2021-07-10
*/

pragma solidity ^0.4.21;

//Aqui se establecen las variables de estado y los mappings que usamos para interactuar con los Structs
contract RegistroCivil {
    address public Owner;
    mapping (address => Persona) public _PERSONA;
    mapping (address => PartidaDeNacimiento) public _PARTIDADENACIMIENTO;
    mapping (address => Matrimonio) public _MATRIMONIO;
    address RegistroCivil; //Esta es la address que imita al Registro Civil, como indica la consigan. 
    

constructor() public {
        Owner=msg.sender;
        RegistroCivil = 0x9a975AA7D0aDF6d1E21BBB1456fa140e93E9f74d; //Esta es la direccion de una address con el nombre de RegistroCivil
    }
    
    
    //Este es el struct que contiene la informacion de las Personas. 
    struct Persona {
        address _id;
        string  Genero;
        string  nombre;
        string  Localidad;
        string  EstadoCivil;  
        uint256 Edad;
        uint256 FechaDeNacimiento;
        uint256 DNI;
        bool    Vive;
        }
    
    //Este otro imita a una partida de nacimiento, la cual puede ser creada directamente por los padre, haciendolo mas eficiente.
    struct PartidaDeNacimiento {
        address id_Padre;
        address id_Madre;
        string  Nombre_Padre;
        string  Nombre_Madre;
        string  NombreDelNino;
        string  LugarDeNacimiento;
        uint256 FechaDeNacimiento;
        uint256 HoraDeNacimiento;
        }   
        
    //Este struct permie crear Matrimonio utilizando solamente su informacion.
    struct Matrimonio {
        address Marido;
        address Mujer;
        string  NombreMarido;
        string  NombreMujer;
        uint256 DNIMarido;
        uint256 DNIMujer;
        uint256 FechaDeMatrimonio;
        }
    
    
    //Esta funcion permite registrarte utilizando el struct Persona
    function RegistrarPersona(address id, string Genero, string Nombre, string Localidad, string Estadocivil, uint256 Edad, uint256 FechaDeNacimiento, uint256 DNI, bool Vive) public {
        Persona memory persona = Persona( id, Genero, Nombre, Localidad, Estadocivil, Edad, FechaDeNacimiento, DNI, Vive);
    }
    
    //Con esta funcion se registra un naciminetnto, para eso se almacena una informacion similar a la de un acta de nacimiento fisica. 
    function RegistrarNacimiento(address idPadre, address idMadre, string NombrePadre, string NombreMadre, string NombreNino, string LugarDeNacimiento, uint256 FechaDeNacimiento, uint256 HoraDeNacimiento) {
        PartidaDeNacimiento memory partidaDeNacimiento = PartidaDeNacimiento(idPadre, idMadre,  NombrePadre,  NombreMadre, NombreNino, LugarDeNacimiento,  FechaDeNacimiento, HoraDeNacimiento);
    }
    
    //Esta funcion registra matrimonios en el struct de Matrimonio, sin la necesidad de acudir al Poder Judicial o de hacer algun tramite. 
    function CrearMatrimonio(address Marido, address Mujer, string NombreMarido, string NombreMujer, uint256 DNIMarido, uint256 DNIMujer, uint256 FechaDeMatrimonio) {
        Matrimonio memory matrimonio = Matrimonio( Marido, Mujer, NombreMarido, NombreMujer, DNIMarido, DNIMujer, FechaDeMatrimonio);   
    }
}