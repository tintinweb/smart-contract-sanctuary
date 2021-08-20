// SPDX-License-Identifier: MIT
// Test

pragma solidity  ^0.6.1;

import './IERC20.sol';
import './SafeMath.sol';

// SWAP contract : While we build our own bridge : This contract exchange pNALIS with anyNALIS on both direction
contract SWAPpNalisWithanyNalis 

   {

    using SafeMath for uint256;
    
    //define the admin of SWAP 
    address public owner;
    
    address public pNalis;
    
    address public anyNalis;

    uint256 public maxSwapAmount = 0;
    
    uint256 public minSwapAmount = 0;
    
    //set number of out tokens per in tokens  
    uint256 public outTokenPerInToken;                   

    //set the SWAP status
    
    enum Status {inactive, active} // 0, 1
    
    Status private SWAPStatus;
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }   
    
    function transferOwnership(address _newowner) public onlyOwner {
        owner = _newowner;
    } 
 
    constructor (
        address _pNalis,
        address _anyNalis
        
        ) public  {

        owner = msg.sender;
        
        //Inactive by default
        SWAPStatus = Status.inactive;
        
        pNalis = _pNalis;
        anyNalis = _anyNalis;

    }

    function setmaxSwapAmount(uint256 _maxSwapAmount) public onlyOwner {
    
        maxSwapAmount = _maxSwapAmount;

    }
    
    function setminSwapAmount(uint256 _minSwapAmount) public onlyOwner {
    
        minSwapAmount = _minSwapAmount;

    }    
 
    function setActiveStatus() public onlyOwner {
    
        SWAPStatus = getSWAPStatus();
        
        require(SWAPStatus == Status.inactive, "SWAP already active");   
        
        SWAPStatus = Status.active;
    }
    
    function setInactiveStatus() public onlyOwner {
    
        SWAPStatus = getSWAPStatus();
        
        require(SWAPStatus == Status.active, "SWAP already inactive");   
        
        SWAPStatus = Status.inactive;
    }    

    function getSWAPStatus() public view returns(Status)  {
        if (SWAPStatus == Status.inactive)
        {
            return Status.inactive;
        }
        
        else if (SWAPStatus == Status.active)
        {
            return Status.active;
        }
    }

    function swappNalisToanyNALIS(uint256 _amount) public {
    
        // check SWAP Status
        SWAPStatus = getSWAPStatus();
        
        require(SWAPStatus == Status.active, "SWAP in not active");
        
        require(_amount >= minSwapAmount , "min amount not accepted");
        require(_amount < maxSwapAmount , "max amount not accepted");
        
        IERC20(pNalis).transferFrom(msg.sender,address(this), _amount);
        IERC20(anyNalis).transfer(msg.sender, _amount);

    }
    
    function swapanyNalisTopNALIS(uint256 _amount) public {
    
        // check SWAP Status
        SWAPStatus = getSWAPStatus();
        
        require(SWAPStatus == Status.active, "SWAP in not active");
        
        require(_amount >= minSwapAmount , "min amount not accepted");
        require(_amount < maxSwapAmount , "max amount not accepted");
        
        IERC20(anyNalis).transferFrom(msg.sender,address(this), _amount);
        IERC20(pNalis).transfer(msg.sender, _amount);

    }    

    //  _token = 1 (pNalis)        and         _token = 2 (anyNalis) 
    function checkSWAPbalance(uint8 _token) public view returns(uint256 _balance) {
    
        if (_token == 1) {
            return IERC20(pNalis).balanceOf(address(this));
        }
        else if (_token == 2) {
            return IERC20(anyNalis).balanceOf(address(this));  
        }
        else {
            return 0;
        }
    }

    function withdrawpNalis(address _admin) public onlyOwner{
        
        uint256 withdrawAmount = IERC20(pNalis).balanceOf(address(this));
        
        IERC20(pNalis).transfer(_admin, withdrawAmount);
    
    }
    
    function withdrawanyNalis(address _admin) public onlyOwner{
        
        uint256 withdrawAmount = IERC20(anyNalis).balanceOf(address(this));
        
        IERC20(anyNalis).transfer(_admin, withdrawAmount);
    
    }    
  

}