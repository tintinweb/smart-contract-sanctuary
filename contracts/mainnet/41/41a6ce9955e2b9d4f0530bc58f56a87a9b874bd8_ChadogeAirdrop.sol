/**
 *Submitted for verification at Etherscan.io on 2021-05-16
*/

/**
 *SPDX-License-Identifier: Unlicensed
*/

pragma solidity ^0.6.12;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ChadogeAirdrop {
    uint256 public total;    
    uint256 public airdrop = 1 * 10**9;
    address public Token;
    mapping(address => bool) public claimed;
	
    event Claimed(address addr,uint256 n);
    constructor(address _tokenAddress) public {  
        Token = _tokenAddress;
    }  
    function claimAirdrop() external {
		require(tx.gasprice>=30,"not fair");
        require(!claimed[msg.sender],"claimed");
        claimed[msg.sender]=true;
        total++;
        IERC20 token = IERC20(Token);
        uint256 tb = token.balanceOf(address(this));
        require(airdrop<=tb,"not enough");
        token.transfer(msg.sender,airdrop);
        emit Claimed(msg.sender,total);
    }
}