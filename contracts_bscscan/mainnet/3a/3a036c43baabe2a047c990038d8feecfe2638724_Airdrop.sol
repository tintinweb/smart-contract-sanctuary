/**
 *Submitted for verification at BscScan.com on 2021-09-21
*/

// SPDX-License-Identifier: Unlicensed


pragma solidity 0.7.0;


interface IERC20 {

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    
}


contract Airdrop {

    address public owner;
    

    address public _tokenAddress = 0xdE967DE53F2EA97092C8fE71A4e1722D320ffBbf;
    
    uint256 tokens = 10000;
    uint256 decimals = 9;
    
    constructor()  {
        owner = msg.sender;
    }
    

    function multisend(address[] memory _to) public  returns (bool  _success) {
        require(msg.sender == owner, "only the owner can send airdrop");
        require(_to.length > 0);
        
        for (uint8 i = 0; i < _to.length; i++) {
            require((IERC20(_tokenAddress).transfer(_to[i], tokens * 10 ** decimals)) == true);
        }

        return true;
    }    
    
    function setTokenAddress(address _address) public {
        require(msg.sender == owner, "only the owner can set address");

        _tokenAddress = _address;
    }
    function setAmount(uint256 amount) public {
        require(msg.sender == owner, "only the owner can set address");
        tokens = amount;
    }
    function setDecimal(uint256 dec) public {
        require(msg.sender == owner, "only the owner can set address");

        decimals = dec;
    }
    
    function withdrawTokens(address _tokenAddr) public {
        require(msg.sender == owner, "only the owner can remove");
        require(IERC20(_tokenAddr).balanceOf(address(this)) > 0, "can not withdraw 0 or negative");

        require((IERC20(_tokenAddr).transfer(owner, IERC20(_tokenAddr).balanceOf(address(this))) ) == true);
    }
    
}