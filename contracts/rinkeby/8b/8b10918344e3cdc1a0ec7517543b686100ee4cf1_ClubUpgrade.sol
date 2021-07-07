/**
 *Submitted for verification at Etherscan.io on 2021-07-07
*/

// SPDX-License-Identifier: Unlicense

/**
 * ==================================================================
 * Title: Final Presentation
 * For: Programa en Desarrollo de Blockhains - Universidad de Palermo
 * Prof: Leandro Rawicz
 * Author: Mariano Chaves (@Nanonch)
 * Date: 07-07-2021
 * ==================================================================
 */

pragma solidity ^0.8.0;

/**
 * @title Owner
 * @dev Contrato que nos permite otorgar privilegios de exclusividad
 * a ciertas funciones reservadas para el Owner del contrato principal.
 * Al realizar el deploy, quien lo realice va a ser el Owner original.
 * 
 * El Owner actual en cualquier momentopuede reasignar el ownership 
 * a traves de la funcion {SetNewOwner}
 * 
 * Este contrato es heredado por los otros. Con el uso del modiicador
 * `isOwner` vamos a poder restringir en los demas contratos su uso.
 */
contract Owner {

    address internal owner;
    
    event SetOwner(address oldOwner, address newOwner);
    
    /**
     * @dev Limita el uso de una funcion al Owner y avisa en caso contrario
     */
    modifier isOwner() {
        require(msg.sender == owner, "You are not the Owner");
        _;
    }
    
    /**
     * @dev Quien hace el deploy queda seteado como Owner
     */
    constructor() {
        owner = msg.sender;
        emit SetOwner(address(0), owner);
    }
    
    /**
     * @dev se asigna un nuevo Owner
     * @param newOwner direccion del nuevo Owner
     */
    function SetNewOwner(address newOwner) public isOwner {
        emit SetOwner(owner, newOwner);
        owner = newOwner;
    }
    
}

/**
 * @title Projects
 * @dev Contrato que utiliza para dar de alta nuevos Proyectos. El unico
 * autorizado para crearlos es el Owner.
 * 
 * Cualquiera puede ver el nombre, saldo actual, y saldo para alcanzar su
 * objetivo de recaudacion.
 */
contract Projects is Owner{
   
    struct Project {
        address payable projectOwner;
        string projectName;
        uint256 projectBudget;
        uint256 projectBalance;
    }

    uint256 projectQuantity = 1;
    mapping (uint=>Project) project;

    /**
     * @dev genera nuevos Proyectos
     * @param _projectOwner aca se asigna el Owner del proyecto que se crea
     * @param _projectName el nombre del proyecto
     * @param _projectBudget el presupuesto que va a tener el proyecto
     * @return projectID el numero de proyecto. Importante para luego mandarle dinero
     */
    function NewProject (address payable _projectOwner,string memory _projectName, uint256 _projectBudget) public isOwner returns (uint256 projectID) {
        projectID = projectQuantity++;
        project[projectID] = Project(_projectOwner,_projectName, _projectBudget, 0);
    }
    
    /**
     * @dev devuelve el saldo restante para alcanzar el objetivo 
     * @param _projectID el ID del proyecto
     */
    function ProjectGoal (uint256 _projectID) public view returns (uint256) {
        Project storage p = project[_projectID];
        return p.projectBudget - p.projectBalance;
    }

    /**
     * @dev devuelve el nombre del proyecto 
     * @param _projectID el ID del proyecto
     */
    function ProjectName (uint256 _projectID) public view returns (string memory) {
        Project storage p = project[_projectID];
        return p.projectName;
    }

    /**
     * @dev devuelve los fondos con los que cuenta el proyecto
     * @param _projectID el ID del proyecto
     */
    function ProjectBalance (uint256 _projectID) public view returns (uint256) {
        Project storage p = project[_projectID];
        return p.projectOwner.balance;
    }
    
}

/**
 * @title ClubUpgrade
 * @dev Contrato principal, en el cual los miembros que depositan dineron en el Club
 * van a poder asignar el mismo a los distintos proyectos que el Owner crea.
 * 
 * Los miembros pueden tambier transferir al Owner los derechos sobre su dinero para que
 * el Owner los use segun su criterio.
 * 
 * Cualquier miembro puede, en caso de desearlo, retirar el dinero no utilizado que aun
 * tenga disponible y lo recibe en su cuenta.
 */
contract ClubUpgrade is Projects {
    
    address payable memberAddress;
    mapping (address=>uint256) memberBalance;
    mapping (address=> uint256) freeBalance;
    uint memberQuantity = 0;
    constructor () {
    }

    /**
     * @dev Transfiere dinero al contrato
     */
    function TransferToClub () public payable {
        memberBalance[msg.sender] += msg.value;
    }
    
    /**
     * @dev Getter del balance que tiene el contrato
     */
    function ClubBalance () public view returns (uint256) {
        return address(this).balance;
    }
    
    /**
     * @dev Getter del balance que tiene disponible el msg.sender para asignar a su criterio
     */
    function MyBalance () public view returns (uint256) {
        return memberBalance[msg.sender];
    }

    /**
     * @dev Getter del balance a disposicion del Owner para asignar a su criterio
     */
    function FreeBalance () public view returns (uint256) {
        return freeBalance[address(this)];
    }

    /**
     * @dev el msg.sender reclama para si el balance que tiene disponible
     */
    function ClaimBalance () public payable {
       payable(msg.sender).transfer(memberBalance[msg.sender]);
       memberBalance[msg.sender] = 0;
    }
    
    /**
     * @dev el msg.sender asigna, si tienebalance, dinero al proyecto que quiera.
     * El monto debe ser superior a su balance
     * El monto no debe ser superior al saldo del proyecto para alcanzar su presupuesto
     * @param _projectID ID del Project al cual vamos a enviar dinero
     * @param _amount el monto a enviar al proyecto
     */
    function AssignToProject (uint256 _projectID, uint256 _amount) public {
        Project storage p = project[_projectID];
        require (memberBalance[msg.sender] >= _amount, "You don't have that amount in your Balance");
        require(p.projectBalance + _amount <= p.projectBudget, "Amount excedes Budget. Check project balance for maximum allowed" );
        p.projectBalance += _amount;
        p.projectOwner.transfer(_amount);
        memberBalance[msg.sender] -= _amount;
    }
    
    /**
     * @dev el msg.sender transfiere, si tienebalance, dinero para que el Owner utilice a su criterio.
     * El monto debe ser superior a su balance
     * @param _amount monto que vamos a transferir
     */
    function Delegate (uint256 _amount) public {
        require (memberBalance[msg.sender] >= _amount, "You don't have that amount in your Balance");
        memberBalance[msg.sender] -= _amount;
        freeBalance[address(this)] += _amount;
    }
    
    /**
     * @dev el Owner asigna, si tienebalance, dinero al proyecto que quiera.
     * El monto debe ser superior a su balance
     * El monto no debe ser superior al saldo del proyecto para alcanzar su presupuesto
     * @param _projectID ID del Proyecto al cual vamos a enviar dinero
     * @param _amount el monto a enviar al proyecto
     */
    function UseFreeBalance (uint256 _projectID, uint256 _amount) public isOwner {
        Project storage p = project[_projectID];
        require (freeBalance[address(this)] >= _amount, "You don't have that amount in your Balance");
        require(p.projectBalance + _amount <= p.projectBudget, "Amount excedes Budget. Check project balance for maximum allowed" );
        p.projectBalance += _amount;
        p.projectOwner.transfer(_amount);
        freeBalance[address(this)] -= _amount;
    }
    
}