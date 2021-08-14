// SPDX-License-Identifier: MIT

pragma solidity  ^0.6.1;

import './IERC20.sol';
import './SafeMath.sol';

// SWAP contract : Initial polygon NALIS Offering : Swap 1:1 between AnyNALIS token to NALIS on polygon side
contract SWAP 

   {

    using SafeMath for uint256;
    
    //define the admin of SWAP 
    address public owner;
    
    address public inputtoken;
    
    address public outputtoken;
    
    bool noOutputToken;
    
    // total Supply for SWAP
    uint256 public totalsupply;

    mapping (address => uint256)public userInvested;
    
    mapping (address => uint256)public userInvestedMemory;
    
    address[] public investors;
    
    mapping (address => bool) public existinguser;
    
    uint256 public maxInvestment = 0; // pay attention to the decimals number of inputtoken
    
    uint256 public minInvestment = 0; // pay attention to the decimals number of inputtoken
    
    //set number of out tokens per in tokens  
    uint256 public outTokenPerInToken;                   

    //hardcap 
    uint public SWAPTarget;

    //define a state variable to track the funded amount
    uint public receivedFund=0;
    
    //set the SWAP status
    
    enum Status {inactive, active, stopped, completed}      // 0, 1, 2, 3
    
    Status private SWAPStatus;
    
    uint public SWAPStartTime=0;
    
    uint public SWAPInTokenClaimTime=0;
    
    uint public SWAPEndTime=0;
    
    // Burn address
    address public constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;    
    

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }   
    
    function transferOwnership(address _newowner) public onlyOwner {
        owner = _newowner;
    } 
 
    constructor () public  {
    
        owner = msg.sender;
    
    }
 
    function setStopStatus() public onlyOwner  {
     
        SWAPStatus = getSWAPStatus();
        
        require(SWAPStatus == Status.active, "Cannot Stop inactive or completed SWAP ");   
        
        SWAPStatus = Status.stopped;
    }

    function setActiveStatus() public onlyOwner {
    
        SWAPStatus = getSWAPStatus();
        
        require(SWAPStatus == Status.stopped, "SWAP not stopped");   
        
        SWAPStatus = Status.active;
    }

    function getSWAPStatus() public view returns(Status)  {
    
        
        if (SWAPStatus == Status.stopped)
        {
            return Status.stopped;
        }
        
        else if (block.timestamp >=SWAPStartTime && block.timestamp <=SWAPEndTime)
        {
            return Status.active;
        }
        
        else if (block.timestamp <= SWAPStartTime || SWAPStartTime == 0)
        {
            return Status.inactive;
        }
        
        else
        {
            return Status.completed;
        }
    
    }

    function invest(uint256 _amount) public {
    
        // check SWAP Status
        SWAPStatus = getSWAPStatus();
        
        require(SWAPStatus == Status.active, "SWAP in not active");
        
        //check for hard cap
        require(SWAPTarget >= receivedFund + _amount, "Target Achieved. Investment not accepted");
        
        require(_amount >= minInvestment , "min Investment not accepted");
        
        uint256 checkamount = userInvested[msg.sender] + _amount;

        //check maximum investment        
        require(checkamount <= maxInvestment, "Investment not in allowed range"); 
        
        // check for existinguser
        if (existinguser[msg.sender]==false) {
        
            existinguser[msg.sender] = true;
            investors.push(msg.sender);
        }
        
        userInvested[msg.sender] += _amount;
        //Duplicate to keep in memory after the SWAP
        userInvestedMemory[msg.sender] += _amount;
        
        receivedFund = receivedFund + _amount; 
        IERC20(inputtoken).transferFrom(msg.sender,address(this), _amount); 

    }
     
     
    function claimTokens() public {

        require(existinguser[msg.sender] == true, "Already claim"); 
        
        require(outputtoken!=BURN_ADDRESS, "Outputtoken not yet available"); 

        // check SWAP Status 
        SWAPStatus = getSWAPStatus();
        
        require(SWAPStatus == Status.completed, "SWAP in not complete yet");

        uint256 redeemtokens = remainingClaim(msg.sender);

        require(redeemtokens>0, "No tokens to redeem");
        
        IERC20(outputtoken).transfer(msg.sender, redeemtokens);
        
        existinguser[msg.sender] = false; 
        userInvested[msg.sender] = 0;
    }

    // Display user token claim balance
    function remainingClaim(address _address) public view returns (uint256) {

        uint256 redeemtokens = 0;

        redeemtokens = userInvested[_address] * outTokenPerInToken;

        return redeemtokens;
        
    }

    // Display user max available investment
    function remainingContribution(address _address) public view returns (uint256) {

        uint256 remaining = maxInvestment - userInvested[_address];
        
        return remaining;
        
    }
    
    //  _token = 1 (outputtoken)        and         _token = 2 (inputtoken) 
    function checkSWAPbalance(uint8 _token) public view returns(uint256 _balance) {
    
        if (_token == 1) {
            return getOutputTokenBalance();
        }
        else if (_token == 2) {
            return IERC20(inputtoken).balanceOf(address(this));  
        }
        else {
            return 0;
        }
    }

    function withdrawInputToken(address _admin) public onlyOwner{
        
        require(block.timestamp >= SWAPInTokenClaimTime, "SWAP in token claim time is not over yet");
        
        uint256 raisedamount = IERC20(inputtoken).balanceOf(address(this));
        
        IERC20(inputtoken).transfer(_admin, raisedamount);
    
    }
  
    function withdrawOutputToken(address _admin, uint256 _amount) public onlyOwner{

        SWAPStatus = getSWAPStatus();
        require(SWAPStatus == Status.completed, "SWAP in not complete yet");
        
        uint256 remainingamount = IERC20(outputtoken).balanceOf(address(this));
        
        require(remainingamount >= _amount, "Not enough token to withdraw");
        
        IERC20(outputtoken).transfer(_admin, _amount);
    }
    
    
    function resetSWAP() public onlyOwner {
    
        for (uint256 i = 0; i < investors.length; i++) {
         
            if (existinguser[investors[i]]==true)
            {
                existinguser[investors[i]]=false;
                userInvested[investors[i]] = 0;
                userInvestedMemory[investors[i]] = 0;
            }
        }
        
        require(IERC20(outputtoken).balanceOf(address(this)) <= 0, "SWAP is not empty");
        require(IERC20(inputtoken).balanceOf(address(this)) <= 0, "SWAP is not empty");
        
        totalsupply = 0;
        SWAPTarget = 0;
        SWAPStatus = Status.inactive;
        SWAPStartTime = 0;
        SWAPInTokenClaimTime = 0;
        SWAPEndTime = 0;
        receivedFund = 0;
        maxInvestment = 0;
        minInvestment = 0;
        inputtoken  =  0x0000000000000000000000000000000000000000;
        outputtoken =  0x0000000000000000000000000000000000000000;
        outTokenPerInToken = 0;
        
        delete investors;
    
    }
        
    function initializeSWAP(address _inputtoken, address _outputtoken, uint256 _startTime, uint256 _inTokenClaimTime, uint256 _endtime, uint256 _outTokenPerInToken, uint256 _maxinvestment, uint256 _minInvestment, uint256 _forceTotalSupply) public onlyOwner {
        
        require(_endtime > _startTime, "Enter correct Time");
        
        inputtoken = _inputtoken;
        outputtoken = _outputtoken;
        outTokenPerInToken = _outTokenPerInToken;
        require(outTokenPerInToken > 0, "out token per in token not set");
        
        if (_outputtoken==BURN_ADDRESS) {
            require(_forceTotalSupply > 0, "Enter correct _forceTotalSupply");
            totalsupply = _forceTotalSupply;
            noOutputToken = true;
        }
        else
        {
            require(IERC20(outputtoken).balanceOf(address(this))>0,"Please first give Tokens to SWAP");
            totalsupply = IERC20(outputtoken).balanceOf(address(this));
            noOutputToken = false;
        }

        //TODO clean up
        SWAPTarget = totalsupply * outTokenPerInToken;

        SWAPStatus = Status.active;
        SWAPStartTime = _startTime;
        SWAPInTokenClaimTime = _inTokenClaimTime;
        SWAPEndTime = _endtime;

        require (SWAPTarget > _maxinvestment, "Incorrect maxinvestment value");
        
        maxInvestment = _maxinvestment;
        minInvestment = _minInvestment;
    }


    function updateSWAPEndTime(uint _endtime) public onlyOwner {
        SWAPEndTime = _endtime;
    } 
    
    function getParticipantNumber() public view returns(uint256 _participantNumber) {
        return investors.length;
    }
   
    function getOutputTokenBalance() internal view returns(uint256 _outputTokenBalance) {
        if (noOutputToken) {
            return totalsupply;
        }
        else {
            return IERC20(outputtoken).balanceOf(address(this));
        }          
    }    
    
}