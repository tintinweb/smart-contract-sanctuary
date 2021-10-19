/**
 *Submitted for verification at Etherscan.io on 2021-10-19
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;

/**
 * @title Among All Insurance Model
 * @notice Do not use this contract in production
 * @dev All function calls are currently implemented without side effects
 */
contract AmongAll {
    
    // -------------Variables-------------

    // total_users
    uint256 total_users = 0;
    
    // total_claims
    uint256 total_claims = 0;
    
    // stable_value
    uint256 stable_value = 10;
    
    // minimum_accepts
    uint256 minimum_accepts = 2;
    
    // Balance total 
    uint256 totalBalance = 0;
    
    // Struct User
    struct User {
        uint mobile_price; // Precio del móvil
        bool registered;  // Estado del registro
        address address_user; // dirección del usuario
        Claim claim;   // Reclamación
    }
    
    // Struct Claim
    struct Claim {
        uint votes; // Número de votos
        C_type claim_type;  // Tipo de reclamación
        C_status claim_status; // Estado de la reclamación
        mapping(address => bool) voted; // Mapeo (address -> bool) para indicar si un usuario ha aceptado dicha reclamación o no
    }
    
    // Enumerado C_type
    enum C_type {None, Loss, Damage}

    // Enumerado C_status
    enum C_status {Unaccepted, Accepted}
    
    // Mapeo users
    mapping(address => User) users;
    
    // -------------Funciones-------------
    
    function register(uint _mobile_price) public payable returns (bool) {
        // Debe requerir que la aportación realizada por el usuario se corresponda con la Ecuación 1, recordando que el valor del móvil vendrá determinado en ETH.
        if (msg.value != (_mobile_price/stable_value)) {
            return false;
        }
        // La aportación debe ser igual o mayor que la constante definida en la Ecuación 1.
        if (msg.value < stable_value) {
            return false;
        }
        // No se puede registrar un móvil con valor 0 o menor que 0
        if (_mobile_price <= 0) {
            return false;
        }
        // Sólo se pueden registrar usuarios no registrados.
        if (users[msg.sender].registered) {
            return false;
        }
        // Cuando un usuario se registra su estado cambia a registrado.
        users[msg.sender].registered = true;
        // Se debe almacenar el valor del móvil registrado en la información del usuario.
        users[msg.sender].mobile_price = _mobile_price;
        users[msg.sender].claim.claim_type = C_type.None;
        users[msg.sender].claim.claim_status = C_status.Unaccepted;
        // Se debe actualizar el número de usuarios totales
        total_users++;
        totalBalance = totalBalance + msg.value;
        return true;
    }
    
    function createClaim(C_type _claim_type) public returns (bool) {
        // Solo se puede crear una reclamación si su tipo actual es “None”.
        if (users[msg.sender].claim.claim_type != C_type.None) {
            return false;
        }
        // Sólo se permite registrar reclamaciones a usuarios registrados.
        if (!users[msg.sender].registered) {
            return false;
        }
        // Una vez se crea la reclamación se debe actualizar el tipo de reclamación en función de lo que haya introducido el usuario en la información del usuario.
        // "La reclamación debe ser '1' para Loss o '2' para Damage"
        if (_claim_type == C_type.Loss) {
            users[msg.sender].claim.claim_type = C_type.Loss;
        } else if (_claim_type == C_type.Damage) {
            users[msg.sender].claim.claim_type = C_type.Damage;
        } else {
            return false;
        }
        // Se debe actualizar el número de reclamaciones totales
        total_claims++;
        return true;
    }
    
    function acceptClaim(address demander) public returns (bool) {
        // No se permite que un usuario se auto acepte una reclamación.
        if (msg.sender == demander) {
            return false;
        }
        // Sólo se pueden aceptar aquellas peticiones en estado “Unaccepted”.
        if (users[demander].claim.claim_status != C_status.Unaccepted) {
            return false;
        }
        // Sólo se permite aceptar reclamaciones a usuarios registrados.
        if (!users[msg.sender].registered) {
            return false;
        }
        // Un usuario sólo puede votar una vez la reclamación es realizada por un usuario.
        if (users[demander].claim.voted[msg.sender]) {
            return false;
        }
        // Si la petición no ha alcanzado el número mínimo de aprobaciones estipulado, el número de votos de la reclamación aumenta.
        if (users[demander].claim.votes <= minimum_accepts) {
            users[demander].claim.votes++;
        } 
        // Se debe actualizar el mapeo que almacena que un usuario ha aceptado una reclamación concreta.
        users[demander].claim.voted[msg.sender] = true;
        // En caso de que se llegue al número mínimo de aprobaciones, el estado de la reclamación pasa a “Accepted”.
        // Se debe tener en cuenta que si un usuario acepta la reclamación y esta aceptación coincide con el número de votos mínimo de aprobaciones necesarias, se debe actualizar el estado de la reclamación en esta misma transacción.
        if (users[demander].claim.votes >= minimum_accepts) {
            users[demander].claim.claim_status = C_status.Accepted;
        }
        return true;
    }

    function executeClaim() public payable returns (bool) {
        // Sólo se permite ejecutar la reclamación si tiene el estado “Accepted”.
        if (users[msg.sender].claim.claim_status != C_status.Accepted){
            return false;
        }
        // Se debe hacer una transferencia de fondos en función de lo estimado en el enunciado, dependiendo de si es una pérdida o ruptura, por lo tanto la cantidad será diferente para ambos casos.
        
        // Se determina la compensación correspondiente
        uint256 compensation = 0;
        if (users[msg.sender].claim.claim_type == C_type.Loss){
            compensation = users[msg.sender].mobile_price;
        } else if (users[msg.sender].claim.claim_type == C_type.Damage){
            compensation = users[msg.sender].mobile_price/2;
        } else {
            return false;
        }
        
        // Si el seguro no tiene solvencia: 
        // - No se emite transferencia
        // - Se mantiene la reclamación como "Accepted"
        // - No se resetea la información del usuario
        // - Se devuelve "false"
        // - Cuando haya solvencia, el usuario podrá volver a enviar la petición de ejecución de su reclamación y se le hará la transferencia correspondiente
        if (totalBalance < compensation) {
            return false;
        }
        
        // Se emite la transferencia al usuario
        totalBalance = totalBalance - compensation;
        address payable wallet = payable(msg.sender);
        if (wallet.send(compensation)) {
            // Se debe resetear toda la información del usuario y su petición asociada
            delete users[msg.sender];
            /*users[msg.sender].mobile_price = 0;
            users[msg.sender].registered = false;
            users[msg.sender].claim.votes = 0;
            users[msg.sender].claim.claim_type = C_type.None;
            users[msg.sender].claim.claim_status = C_status.Unaccepted; */
            total_users = total_users - 1;
            total_claims = total_claims - 1;
            delete users[msg.sender];
            return true;
        } else {
            totalBalance = totalBalance + compensation;
        }
        return false;
        
    }
    
    // receive ()
    receive() external payable{
        require(msg.value >0, "ERROR");
    }
    
    function getTotalBalance() public view returns (uint256) {
        return totalBalance;
    }

    function getTotalUsers() public view returns (uint256){
        return total_users;
    }

    function getTotalClaims() public view returns (uint256){
        return total_claims;
    }

    function getMobilePrice(address demander) public view returns (uint256) {
        return users[demander].mobile_price;
    }

    function getClaimStatus(address demander) public view returns (C_status) {
        if (users[demander].claim.claim_status == C_status.Unaccepted) {
            return C_status.Unaccepted;
        } else {
            return C_status.Accepted;
        }
    }
}