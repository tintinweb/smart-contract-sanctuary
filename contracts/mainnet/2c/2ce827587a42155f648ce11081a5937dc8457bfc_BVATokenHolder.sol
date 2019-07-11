/**
 *Submitted for verification at Etherscan.io on 2019-07-11
*/

pragma solidity ^0.5.0;

// File: ERC20Interface.sol

// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
// ----------------------------------------------------------------------------
contract ERC20Interface {
    function totalSupply() public view returns (uint);
    function balanceOf(address tokenOwner) public view returns (uint balance);
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

// File: BVATokenHolder.sol

contract BVATokenHolder {
    ERC20Interface erc20Contract;
    address payable owner;
    string public name;


    modifier isOwner() {
        require(msg.sender == owner, "must be contract owner");
        _;
    }


    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------
    constructor(ERC20Interface ctr, string memory _name) public {
        erc20Contract = ctr;
        owner         = msg.sender;
        name          = _name;
    }


    // ------------------------------------------------------------------------
    // Unlock Tokens
    // ------------------------------------------------------------------------
    function transferTokens(address to, uint amount) external isOwner {
        erc20Contract.transfer(to, amount);
    }


    // ------------------------------------------------------------------------
    // Withdraw ETH from this contract to `owner`
    // ------------------------------------------------------------------------
    function withdrawEther(uint _amount) external isOwner {
        owner.transfer(_amount);
    }


    // ------------------------------------------------------------------------
    // accept ETH
    // ------------------------------------------------------------------------
    function () external payable {
    }
}