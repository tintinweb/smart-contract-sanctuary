/**
 *Submitted for verification at BscScan.com on 2021-07-18
*/

//SPDX-License-Identifier: UNLICENSED

// $VANITY V3 to $VNY Swap Smart Contract.
// Trade your V3 $VANITY AND GET THE NEW ONE!

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

contract Swap {
    address private owner;
    
    IERC20 private tokenA; // old token
    IERC20 private tokenB; // new token
    
    constructor(address _tokenA, address _tokenB) {
        owner = msg.sender;
        
        tokenA = IERC20(_tokenA);
        tokenB = IERC20(_tokenB);
    }
    
    //////////
    // Getters
    
    function getOwner() external view returns(address) {
        return(owner);
    }
    
    function getTokenA() external view returns(address) {
        return(address(tokenA));
    }
    
    function getTokenB() external view returns(address) {
        return(address(tokenB));
    }
    
    function getTokenBBalance() private view returns(uint256) {
        return(tokenB.balanceOf(address(this)));
    }
    
    ////////////////
    // Swap function

    function swapTokens(uint256 _amount) external {
        require(getTokenBBalance() >= _amount, "Contract doesn't have enough tokens to perform the swap!");
        
        // Sending tokenA from msg.sender to the contract
        tokenA.transferFrom(msg.sender, address(this), _amount);
        
        // Sending tokenB to the user
        tokenB.transfer(msg.sender, _amount);
    }
    
    //////////////////
    // Owner functions
    
    function setOwner(address _owner) external {
        require(msg.sender == owner, "msg.sender has to be the owner!");
        
        owner = _owner;
    }
    
    function withdrawTokenA(uint256 _amount, address _receiver) external {
        require(msg.sender == owner, "msg.sender has to be the owner!");
        
        tokenA.transfer(_receiver, _amount);
    }
    
    function withdrawTokenB(uint256 _amount, address _receiver) external {
        require(msg.sender == owner, "msg.sender has to be the owner!");
        
        tokenB.transfer(_receiver, _amount);
    }
    
    function withdrawToken(uint256 _amount, address _receiver, address _token) external {
        require(msg.sender == owner, "msg.sender has to be the owner!");
        
        IERC20(_token).transfer(_receiver, _amount);
    }
}