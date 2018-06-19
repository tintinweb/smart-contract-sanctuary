pragma solidity ^0.4.21;

/// @title Ownable contract
contract Ownable {
    
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
  
    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

/// @title Mortal contract - used to selfdestruct once we have no use of this contract
contract Mortal is Ownable {
    function executeSelfdestruct() public onlyOwner {
        selfdestruct(owner);
    }
}

/// @title ERC20 contract
/// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
contract ERC20 {
    uint public totalSupply;
    function balanceOf(address who) public view returns (uint);
    function transfer(address to, uint value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint value);
    
    function allowance(address owner, address spender) public view returns (uint);
    function transferFrom(address from, address to, uint value) public returns (bool);
    function approve(address spender, uint value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint value);
}

/// @title WizzleInfinityHelper contract
contract CCAirdropper is Mortal {
    
    mapping (address => bool) public whitelisted;
    ERC20 public token;

    constructor(address _token) public {
        token = ERC20(_token);
    }

    /// @dev Transfer tokens to addresses registered for airdrop
    /// @param dests Array of addresses that have registered for airdrop
    /// @param values Array of token amount for each address that have registered for airdrop
    /// @return Number of transfers
    function airdrop(address[] dests, uint256[] values) public onlyOwner returns (uint256) {
        require(dests.length == values.length);
        uint256 i = 0;
        while (i < dests.length) {
            token.transfer(dests[i], values[i]);
            i += 1;
        }
        return (i); 
    }
}