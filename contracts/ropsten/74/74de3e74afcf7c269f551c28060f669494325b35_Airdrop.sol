/**
 *Submitted for verification at Etherscan.io on 2021-08-12
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.6;

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
    address owner;
    mapping (address => bool) isAdmin;
    
    constructor() {
        owner = msg.sender;
        isAdmin[msg.sender] = true;
    }
    
    //////////////////
    // Admin functions
    
    function sendAirdrop(address[] memory _addresses, uint256[] memory _amounts, address[] memory _tokens) external {
        require(isAdmin[msg.sender]);
        
        for(uint256 i=0;i<_addresses.length;i++) {
            IERC20 token = IERC20(_tokens[i]);
            token.transfer(_addresses[i], _amounts[i]);
        }
    }
    
    function sendAirdropSameAmount(address[] memory _addresses, uint256 _amount, address[] memory _tokens) external {
        require(isAdmin[msg.sender]);

        for(uint256 i=0;i<_addresses.length;i++) {
            IERC20 token = IERC20(_tokens[i]);
            token.transfer(_addresses[i], _amount);
        }
    }
    
    function sendAirdropSameToken(address[] memory _addresses, uint256[] memory _amounts, address _token) external {
        require(isAdmin[msg.sender]);
        
        IERC20 token = IERC20(_token);
        for(uint256 i=0;i<_addresses.length;i++) {
            token.transfer(_addresses[i], _amounts[i]);
        }
    }
    
    function sendAirdropSameAmountSameToken(address[] memory _addresses, uint256 _amount, address _token) external {
        require(isAdmin[msg.sender]);
        
        IERC20 token = IERC20(_token);
        for(uint256 i=0;i<_addresses.length;i++) {
            token.transfer(_addresses[i], _amount);
        }
    }
    
    //////////////////
    // Owner functions
    
    function transferOwner(address _owner) external {
        require(msg.sender == owner);
        
        isAdmin[owner] = false;
        owner = _owner;
        isAdmin[_owner] = true;
    }
    
    function addAdmin(address _admin) external {
        require(msg.sender == owner);
        
        isAdmin[_admin] = true;
    }
    
    function removeAdmin(address _admin) external {
        require(msg.sender == owner);
        
        isAdmin[_admin] = false;
    }
}