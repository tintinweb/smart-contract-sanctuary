/**
 *Submitted for verification at Etherscan.io on 2021-12-21
*/

pragma solidity ^0.8.6;

contract TaskCrud {
    
    string mensaje = "Entrando a DAOs of Thrones"; 
    int numeroUsuarioNegativo = -66; 
    uint numeroUsuario = 33;
    bool fleg = true; 
    address miDireccion = 0xd3b7D6Baf660c3A6FDEB3148E43d51c49bDf906b; 
    address propietario; 
    string nombre; 

    event CambioNombre(address a);

 //   event Withdrawal(address indexed token, uint256 amount, uint256 value);

    constructor(string memory _nombre) {
      nombre = _nombre; 
      propietario = msg.sender;   
    }

    modifier soloPropietario {
      require(msg.sender == propietario);
      _;
    }

    function cambiarNombre(string memory _nombre) soloPropietario public {
      nombre = _nombre; 
      emit CambioNombre(msg.sender);
    }

   function leerVariables() soloPropietario public view returns (string memory,address) {
        return (nombre,propietario);
    }
    
    function leerVariablesInterno() public view returns (string memory,int,uint,bool,address) {
        return leerRepositorioVariables();
    }

    function leerRepositorioVariables() internal view returns (string memory,int,uint,bool,address) {
        return (mensaje,numeroUsuarioNegativo,numeroUsuario,fleg,miDireccion);
    }

    // CODIGO FIN KAMUS

    struct Task {
        uint id;
        string name;
        string description;
    }
    
    Task[] tasks;
    uint nextId; // default value 0, add public to see the value
    
    function createTask(string memory _name, string memory _description) public {
        tasks.push(Task(nextId, _name, _description));
        nextId++;
    }
    
    
    function findIndex(uint _id) internal view returns (uint) {
        for (uint i = 0; i < tasks.length; i++) {
            if (tasks[i].id == _id) {                
                return i;
            }
        }
        revert("Task not found");
    }
    
    function updateTask(uint _id, string memory _name, string memory _description) public {
        uint index =  findIndex(_id);
        tasks[index].name = _name;
        tasks[index].description = _description;
    }
    
    function readTask(uint _id) public view returns (uint, string memory, string memory) {
        uint index = findIndex(_id);
        return (tasks[index].id, tasks[index].name, tasks[index].description);
    }
    
    function deleteTask(uint _id) public {
        uint index = findIndex(_id);
        delete tasks[index];
    }
    
}