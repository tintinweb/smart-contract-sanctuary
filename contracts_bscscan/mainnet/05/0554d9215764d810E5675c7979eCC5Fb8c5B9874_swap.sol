/**
 *Submitted for verification at BscScan.com on 2021-09-07
*/

pragma solidity ^ 0.8.0;
//SPDX-License-Identifier:MIT

interface IERC20 {

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
    
    /**
     * TOKEN A = OLD TOKEN
     * TOKEN B = NEW TOKEN
     * When deploy approve the new tokens. Just approve one time !
     */
}

contract swap{
    address public owner;
    IERC20 public tokenA;
    IERC20 public tokenB;
    
    mapping(address => bool) public Claimed;
    
    constructor(address _tokenA, address _tokenB){
        owner = msg.sender;
        tokenA = IERC20(_tokenA);
        tokenB = IERC20(_tokenB);
    }
    
    function tokenswap()public{
        require(!Claimed[msg.sender] , "Claimable Once");
        uint256 amount = tokenA.balanceOf(msg.sender);
        tokenA.transferFrom(msg.sender,owner,amount);
        tokenB.transferFrom(owner,msg.sender,amount);
        Claimed[msg.sender] = true;
        
    }
}