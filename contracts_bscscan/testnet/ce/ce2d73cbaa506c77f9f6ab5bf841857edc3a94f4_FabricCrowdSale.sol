pragma solidity ^0.4.24;

import "./Fabric.sol";

contract FabricCrowdSale{
    
    uint256 public weiTokenPrice;
    uint256 public investmentReceived;
    uint256 public tokenSold;
    bool public isFinalized;
    
    
    mapping(address =>uint256) public investmentAmount;
    
    event LogInvestment(address indexed investor, uint256 value);
    event LogTokenAssignment( address indexed investor, uint256 numTokens);
    
    
    address public owner;
    
    Fabric public tokenContract;
    
    
     modifier onlyOwner(){
        require(msg.sender == owner);
        _;
    }
    
    constructor () public{
        
        owner = msg.sender;
        weiTokenPrice = 1500000000000;
        tokenContract = new Fabric(0);
        isFinalized = false;
        tokenSold = 0;
    }
    
   
    function buy() public payable{
        require(msg.value != 0);
        
        address investor = msg.sender;
        uint256 investment = msg.value;
        
        investmentAmount[investor] += investment;
        investmentReceived += investment;
        
        assignTokens(investor,investment);
        emit LogInvestment(investor,investment);
    }
    function assignTokens(address _beneficiary, uint256 _investment) internal{
        uint256 _numberOfTokens = calculateNumberOfTokens(_investment);
        tokenContract.mint(_beneficiary,_numberOfTokens);
        tokenSold += _numberOfTokens;
    }
    function calculateNumberOfTokens(uint256 _investment)internal view returns(uint256){
      return _investment/weiTokenPrice;  
    }
    function finalize() onlyOwner public{
        //if tokenSold = crowdsaleamount
        //any other condition fit...maybe total funds reached
        if(isFinalized) revert();
        else
        tokenContract.release();
        isFinalized = true;
    }
    function collect(uint256 amount) onlyOwner public{
        msg.sender.transfer(amount);
    }
    
}