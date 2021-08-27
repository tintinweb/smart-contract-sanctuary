/**
 *Submitted for verification at Etherscan.io on 2021-08-27
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title SkillCert
 * @dev Allows registration & awarding of skill certificates
 */
contract SkillCert {

    mapping(bytes32 => address) public registered_certificates;
    mapping(address => mapping(bytes32 => bool)) public awarded_certificates;

    /**
     * @dev Registers a new certificate awardable by the sender only if a certificate with the same name is not already registred
     * @param name certificate name
     */
    function register(bytes32 name) public {
        require(registered_certificates[name] == address(0), "Certificate already registered!");
        registered_certificates[name] = msg.sender;
    }
    
    /**
     * @dev Awards a certificate if the sender is its creator and if its not already been awarded to the receiver
     * @param name certificate name
     * @param receiver certificate receiver
     */
    function award(bytes32 name, address receiver) public {
        require(registered_certificates[name] == msg.sender, "You cannot award this certificate!");
        require(!awarded_certificates[receiver][name], "Certificate already awarded!");
        awarded_certificates[receiver][name] = true;
    }

    /**
     * @dev Verifies if an address is holding a certificate
     * @param holder certificate holder to verify
     * @param name certificate name
     * @return true if the certificate is hold false otherwise
     */
    function verify(address holder, bytes32 name) public view returns (bool){
        return awarded_certificates[holder][name];
    }
}