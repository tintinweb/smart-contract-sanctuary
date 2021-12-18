/**
 *Submitted for verification at snowtrace.io on 2021-12-17
*/

/**
 *Submitted for verification at Etherscan.io on 2020-04-25
*/

pragma solidity ^0.5.1;

/**
 * @title Mapping contract
 * @dev Add and delete business contract
 */
contract IBMapping {
	mapping(string => address) private ContractAddress;						//	Business contract address
	mapping (address => bool) owners;										//	Superman address

	/**
    * @dev Initialization method
    */
	constructor () public {
		owners[msg.sender] = true;
	}
	
    /**
    * @dev Inquiry address
    * @param name String ID
    * @return contractAddress Contract address
    */
	function checkAddress(string memory name) public view returns (address contractAddress) {
		return ContractAddress[name];
	}
	
    /**
    * @dev Add address
    * @param name String ID
    * @param contractAddress Contract address
    */
	function addContractAddress(string memory name, address contractAddress) public {
		require(checkOwners(msg.sender) == true);
		ContractAddress[name] = contractAddress;
	}
	
	/**
    * @dev Add superman
    * @param superMan Superman address
    */
	function addSuperMan(address superMan) public {
	    require(checkOwners(msg.sender) == true);
	    owners[superMan] = true;
	}
	
	/**
    * @dev Delete superman
    * @param superMan Superman address
    */
	function deleteSuperMan(address superMan) public {
	    require(checkOwners(msg.sender) == true);
	    owners[superMan] = false;
	}
	
	/**
    * @dev Check superman
    * @param man Superman address
    * @return Permission or not
    */
	function checkOwners(address man) public view returns (bool){
	    return owners[man];
	}
}