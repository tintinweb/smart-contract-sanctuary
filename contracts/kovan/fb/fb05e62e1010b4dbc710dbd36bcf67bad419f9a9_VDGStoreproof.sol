/**
 *Submitted for verification at Etherscan.io on 2021-12-09
*/

pragma solidity >=0.4.22 <0.7.0;
/**
* @title Ownable
* @dev The Ownable contract has an owner address, and provides basic authorization control * functions, this simplifies the implementation of "user permissions".
*/
contract Ownable {
address public owner;
event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
/**
* @dev The Ownable constructor sets the original `owner` of the contract to the sender * account.
*/
constructor() public { 
    owner = msg.sender;
}
/**
* @dev Throws if called by any account other than the owner. */
modifier onlyOwner() { 
    require(msg.sender == owner); _;
}
/**
* @dev Allows the current owner to transfer control of the contract to a newOwner. * @param newOwner The address to transfer ownership to.
*/
function transferOwnership(address newOwner) public onlyOwner { require(newOwner != address(0));
emit OwnershipTransferred(owner, newOwner);
owner = newOwner;
} }
contract VDGStoreproof is Ownable{ mapping (string => bool) private proofs;
 //White listed address that can contribut Ether 
 mapping(address => bool) public whitelist;
function storeProof(string memory hash) public isWhitelisted(msg.sender) { proofs[hash]=true;
}
function checkProof(string memory hash) view public returns(bool){ return proofs[hash];
}

/**
* @dev Reverts if beneficiary is not whitelisted. Can be used when extending this contract. */
modifier isWhitelisted(address _beneficiary) { require(whitelist[_beneficiary]);
_;
}
/**
* @dev Adds single address to whitelist.
* @param _beneficiary Address to be added to the whitelist */
function addToWhitelist(address _beneficiary) external onlyOwner { whitelist[_beneficiary] = true;
}
/**
* @dev Adds list of addresses to whitelist. Not overloaded due to limitations with truffle testing. * @param _beneficiaries Addresses to be added to the whitelist
*/
function addManyToWhitelist(address[] calldata _beneficiaries) external onlyOwner { for (uint256 i = 0; i < _beneficiaries.length; i++) {
whitelist[_beneficiaries[i]] = true; }
}
/**
* @dev Removes single address from whitelist.
* @param _beneficiary Address to be removed to the whitelist */
function removeFromWhitelist(address _beneficiary) external onlyOwner { whitelist[_beneficiary] = false;

} }