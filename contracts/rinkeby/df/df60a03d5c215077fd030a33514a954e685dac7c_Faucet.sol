/**
 *Submitted for verification at Etherscan.io on 2021-06-10
*/

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface IERC20 {
    function mint(address _to, uint256 _value) external;
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);
    function transfer(address _to, uint _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint _value) external returns (bool success);
    function balanceOf(address _owner) external view returns (uint balance);
}

/// @title Faucet
/// @author Anton Davydov - <[email protected]>
contract Faucet {
    
    address owner;
    modifier isOwner() {
        require(msg.sender == owner, "Caller is not owner");
        _;
    }
    
    mapping (address => mapping (address => bool)) internal userTokenDropped;
    
    constructor() {
        owner = msg.sender;
    }
    
    function transferOwnership(address newOwnerAddress) public isOwner {
        owner = newOwnerAddress;
    }
    
    function drop(IERC20 token) public {
        require(!userTokenDropped[msg.sender][address(token)], "Already requested");
        uint amount = 100 * 1e18;
        require(token.balanceOf(address(this)) >= amount);
        require(token.transfer(msg.sender, amount));
        userTokenDropped[msg.sender][address(token)] = true;
    }
    
    function reclaim(IERC20 token) public isOwner {
        token.transfer(msg.sender, token.balanceOf(address(this)));   
    }
}