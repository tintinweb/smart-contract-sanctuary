/**
 *Submitted for verification at Etherscan.io on 2021-05-24
*/

pragma solidity ^0.5.11;


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor() public {
        owner = msg.sender;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}


/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
    uint public totalSupply;
    function balanceOf(address who) external view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}


/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) external view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


/**
 * @title Airdrop Contract
 * @dev Airdrop tokens to whitelisted addresses
 */
contract Airdrop is Ownable {
    
    // event AirdropSent( address receiver, uint256 amount );
  
    /**
    * @dev airdrops given amount of tokens to whitelisted addresses
    * @param tokenAddr The token contract address.
    * @param whitelist The addresses where tokens will be transferred.
    * @param amount The amount to be transferred.
    */
    function multisend(address tokenAddr, address[] calldata whitelist, uint256 amount)
    external
    onlyOwner
    returns (uint256) {
        require( amount > 0, "Amount must be greater than 0." );
        uint256 i = 0;
        
        while (i < whitelist.length) {
           ERC20(tokenAddr).transfer(whitelist[i], amount);
           // emit AirdropSent( whitelist[i], amount );
           i += 1;
        }
        
        return(i);
    }
}