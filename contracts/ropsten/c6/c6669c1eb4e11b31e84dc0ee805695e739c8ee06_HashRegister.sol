// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./Pausable.sol";
import "./AccessControl.sol";
import "./Ownable.sol";

///@title HashRegister
///@notice Contrato para el registro de hashes
contract HashRegister is Pausable, Ownable, AccessControl {

    struct HashBlockNumer {
        bytes32 hash;
        uint256 blockNumber;
    }

    bytes32 private constant USER_ROLE = keccak256("USER_ROLE");


    mapping(bytes32 => uint256) private timestampByHash;
    mapping(bytes32 => HashBlockNumer []) private bnHistoryById;
    mapping(bytes32 => HashBlockNumer) private id2hash;

    constructor() {
        _setupRole(USER_ROLE, msg.sender);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    ///@notice Registra un hash sin asociarlo a ningun ID.
    ///@param huella El hash a registrar
    ///@dev El parametro {_hash} no puede ser cero.
    function registerHash(bytes32 huella) public whenNotPaused onlyRole(USER_ROLE) {
        require (huella != 0);
        if(timestampByHash[huella] == 0) {
            timestampByHash[huella] = block.timestamp;
        }
    }

    ///@notice Registra un hash asociandolo a un ID externo. 
    ///@param huella El hash a registrar. No puede ser cero.
    ///@param externalId El id externo al que se va a asociar el hash. Por ejemplo su identificador en la base de datos. No puede ser cero.
    ///@param appId El nombre de la aplicacion que registra el hash: Xej:Biomasa. No puede ser cero.
    ///@dev Se recomienda el que se garantice que el ID sea único.
    function registerHashWithId(bytes32 huella, string calldata externalId, string calldata appId) external whenNotPaused onlyRole(USER_ROLE){
        require(!isEmpty(appId) && !isEmpty(externalId));
        registerHash(huella);

        bytes32 id = keccak256(abi.encode(appId, externalId));
        HashBlockNumer memory actual = id2hash[id];
        bool esPrimeraVez = (actual.blockNumber == 0);

        id2hash[id] = HashBlockNumer(huella, block.number);

        if(!esPrimeraVez && actual.hash != huella) {
            HashBlockNumer [] storage history = bnHistoryById[id];
            history.push(actual);
        }
    }



    ///@notice Devuelve el timestamp asociado a un hash, si este hash está almacenado en el SC, en otro caso devuelve cero.
    ///@param huella El hash a buscar
    function getTimestampByHash(bytes32 huella) public view returns (uint256 timestamp) {
        return timestampByHash[huella];
    }
    
    ///@notice Devuelve el último hash asociado a un ID y su timestamp si el ID tiene algún hash almacenado en el SC, en otro caso devuelve (0 - 0).
    ///@param externalId El id externo por el que buscar el hash. Por ejemplo su identificador en la base de datos
    ///@param appId El nombre de la aplicacion que registró el hash: Xej:Biomasa
    ///@return huella El hash asociado al id, timestamp El timestamp en el que se registró el hash, hasOlderVersions Boolean true si tiene versiones pasadas ,false en caso contrario
    function getHashById(string calldata externalId, string calldata appId) external view returns (bytes32 huella, uint256 timestamp, bool hasOlderVersions) {
        bytes32 id = keccak256(abi.encode(appId, externalId));

        HashBlockNumer memory actual = id2hash[id];
        uint256 ts = getTimestampByHash(actual.hash);

        HashBlockNumer [] memory history = bnHistoryById[id];
        bool tieneVersionesAntiguas = (history.length > 0);

        return (actual.hash, ts, tieneVersionesAntiguas);
    }

    ///@notice Devuelve el historico de hashes asociado a un ID si el ID tiene algún hash almacenado en el SC, en otro caso devuelve un array vacio.
    ///@param externalId El id externo por el que buscar el hash. Por ejemplo su identificador en la base de datos
    ///@param appId El nombre de la aplicacion que registró el hash: Xej:Biomasa
    function getHashesHistoryById(string calldata externalId, string calldata appId) external view returns (HashBlockNumer [] memory hashes) {
        bytes32 id = keccak256(abi.encode(appId, externalId));
        HashBlockNumer memory current = id2hash[id]; 
        if (current.blockNumber == 0) {
            return new HashBlockNumer [] (0);
        }

        HashBlockNumer [] storage history = bnHistoryById[id];
        HashBlockNumer [] memory arrayHistorico = new HashBlockNumer [] (history.length + 1);

        for (uint256 i = 0; i<arrayHistorico.length-1; i++) {
                arrayHistorico[i] = history[i];
        }
        arrayHistorico[arrayHistorico.length-1] = current;

        return arrayHistorico;
    }

    ///@notice Transfiere la propiedad del contrato a la address especificada
    ///@param newOwner La address del nuevo propietario
    ///@dev La address del nuevo propietario no puede ser la misma que el actual, además tampoco puede ser cero.
    function transferOwnership(address newOwner) public override onlyOwner {
        require(msg.sender != newOwner);
        _setupRole(DEFAULT_ADMIN_ROLE, newOwner);
        _setupRole(USER_ROLE, newOwner);
        super.transferOwnership(newOwner);
        super.revokeRole(USER_ROLE, msg.sender);
        super.revokeRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    ///@notice Asigna un rol a una cuenta espeficica
    ///@param role El rol a asignar
    ///@param account La cuenta a la cual se va a asignar el rol
    ///@dev El rol de DEFAULT_ADMIN_ROLE no puede ser asignado de esta manera.
    function grantRole(bytes32 role, address account) public override onlyRole(DEFAULT_ADMIN_ROLE) {
        require(role != DEFAULT_ADMIN_ROLE);
        super.grantRole(role, account);
    }

    ///@notice Elimina el rol especificado de la cuenta especificada.
    ///@param role El rol a eliminar
    ///@param account La cuenta de la cual se va a eliminar el rol
    ///@dev El rol de DEFAULT_ADMIN_ROLE no puede ser revocado de esta manera.
    function revokeRole(bytes32 role, address account) public override onlyRole(DEFAULT_ADMIN_ROLE) {
        require(role != DEFAULT_ADMIN_ROLE); //sobrescribir grantrole
        super.revokeRole(role, account);
    }

    ///@notice Añade el rol USER_ROLE A la address especificada
    ///@param _userAddress La cuenta a la cual se va a dar el rol USER_ROLE
    function grantUserRole(address _userAddress) external onlyRole(DEFAULT_ADMIN_ROLE) {
        grantRole(USER_ROLE, _userAddress);
    }

    ///@notice Pausa el contrato bloqueando aquellas funciones que requieran que el contrato esté activo para ejecutarse.
    ///@dev aquellas funciones maracdas con el decorador WhenNotPaused revertirán si son llamadas con el contrato pausado.
    function pause() external onlyOwner {
        _pause();
    }

    ///@notice Activa el contrato desbloqueando aquellas funciones que requieran que el contrato esté activo para ejecutarse.
    ///@dev aquellas funciones marcadas con el decorador WhenNotPaused revertirán si son llamadas con el contrato pausado.
    function unpause() external onlyOwner {
        _unpause();
    }

    ///@notice Funcion que determina si un string está vacío o no
    ///@param str El string a comprobar
    ///@return True si el string está vacío, False en otro caso.
    function isEmpty(string memory str) private pure returns (bool){
        bytes memory tempEmptyStringTest = bytes(str); 
        return tempEmptyStringTest.length == 0;
    }

}