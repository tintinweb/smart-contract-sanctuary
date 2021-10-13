pragma solidity ^0.5.3;

/**
* @author Maxxer.
*/

/**
* @title Ownable
* @dev The Ownable contract has an owner address, and provides basic authorization control
*      functions, this simplifies the implementation of "user permissions".
*/
contract Ownable {
    address public owner;
    
    constructor() internal{
        owner = msg.sender;
    }

    /**
    * @dev Throws if called by any account other than the owner.
    */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
}

/**
 * @title Authenticity
 * @dev Authenticity contract for authenticate ERC223 contracts.
*/
contract Authenticity is Ownable{
    
    address[] contracts;
    
    /**
    * @dev Throws if _addr address was not contract address.
    */
    modifier withContract(address _addr){
        uint length;
        assembly { length := extcodesize(_addr) }
        require(length > 0);
        _;
    }
    
    /**
    * @dev constructor for deploy Authenticity contract with _contractAddress.
    * @param _contractAddress address of ERC223 contract that need to authenticate.
    */
    constructor(address _contractAddress) public {
        contracts.push(_contractAddress);
    }

    /**
    * @dev getAddress for check checkAddress was authenticate or not.
    * @param checkAddress address of ERC223 contract that check for authenticate.
    * @return true if getAddress execute successfully.
    */
    function getAddress(address checkAddress) public view withContract(checkAddress) returns (bool success) {
        for(uint i = 0; i<contracts.length;i++ )
        if(checkAddress==contracts[i]) success=true;
    }
    
    /**
    * @dev addContract for add _contractAddress into authenticate contract.
    * @param _contractAddress address of ERC223 contract that need to authenticate.
    * @return true if addContract execute successfully.
    */
    function addContract(address _contractAddress) onlyOwner withContract(_contractAddress) public returns (bool success){
        if(!getAddress(_contractAddress)) contracts.push(_contractAddress);
        return true;
    }
    
    /**
    * @dev that return total number of authenticated contracts.
    * @return total authenticated addresses.
    */
    function getAddresses() public view returns (uint){
        return contracts.length;
    }
}