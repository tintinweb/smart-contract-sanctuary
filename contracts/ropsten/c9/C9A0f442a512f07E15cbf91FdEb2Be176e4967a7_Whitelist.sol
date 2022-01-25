/**
 *Submitted for verification at Etherscan.io on 2022-01-24
*/

pragma solidity >=0.7.0 <0.9.0;
// SPDX-License-Identifier: GPL-3.0


/**
 * @title Whitelist es el contrato que contendrá la lista de validadores y la lista de addresses validadas para su ejecución 
 * @dev Set & change owner
 */
contract Whitelist{

    //whitelist tiene 2 valores, uno es el address del usuario al que se referencia, y el segudo es un string que indica el status en la plataforma.
    mapping(address => string) private whitelist ;
    uint whitelistSize = 0; 
    

    //validators define la lista de validadores y sus addresses. 
    mapping(address => string) private validators ;
    uint validatorSize = 0;

    address private owner;
    
    // event for EVM logging
    event OwnerSet(address indexed oldOwner, address indexed newOwner);
    



    function getWhitelistSize() external view returns (uint) {
        return whitelistSize;
    }
    function getValidatorsSize() external view returns (uint) {
        return validatorSize;
    }

    function addValidator(address _validator) external isOwner{
        validators[_validator] = "active";
        validatorSize++;
    }
    
    function addAddressToWhitelist(address _addrToWhitelist) external isValidator{
        whitelist[_addrToWhitelist] = "active";
        whitelistSize++;
    }

    function suspendValidator(address _suspvalidator) external isOwner{
        validators[_suspvalidator] = "suspended";
        validatorSize--;
    }
    function suspendAddrWhitelist(address _addrToWhitelist) external isValidator{
        whitelist[_addrToWhitelist] = "suspended";
        whitelistSize--;
    }


    // modifier to check if caller is owner
    modifier isOwner() {
        // If the first argument of 'require' evaluates to 'false', execution terminates and all
        // changes to the state and to Ether balances are reverted.
        // This used to consume all gas in old EVM versions, but not anymore.
        // It is often a good idea to use 'require' to check if functions are called correctly.
        // As a second argument, you can also provide an explanation about what went wrong.
        require(msg.sender == owner, "Caller is not owner");
        _;
    }
        // modifier to check if caller is validator
    modifier isValidator() {
        // If the first argument of 'require' evaluates to 'false', execution terminates and all
        // changes to the state and to Ether balances are reverted.
        // This used to consume all gas in old EVM versions, but not anymore.
        // It is often a good idea to use 'require' to check if functions are called correctly.
        // As a second argument, you can also provide an explanation about what went wrong.
        require(keccak256(bytes(validators[msg.sender])) == keccak256(bytes("active")), "Caller is not validator");
        //Forma de comparar 2 Strings
        _;
    }
    
    /**
     * @dev Set contract deployer as owner
     */
    constructor() {
        owner = msg.sender; // 'msg.sender' is sender of current call, contract deployer for a constructor
        emit OwnerSet(address(0), owner);
    }

    /**
     * @dev Change owner
     * @param newOwner address of new owner
     */
    function changeOwner(address newOwner) public isOwner {
        emit OwnerSet(owner, newOwner);
        owner = newOwner;
    }

    /**
     * @dev Return owner address 
     * @return address of owner
     */
    function getOwner() external view returns (address) {
        return owner;
    }
}