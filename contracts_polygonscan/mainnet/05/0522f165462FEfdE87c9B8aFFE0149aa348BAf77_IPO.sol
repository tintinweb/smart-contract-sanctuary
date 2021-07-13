// SPDX-License-Identifier: MIT

pragma solidity  ^0.6.1;

//  _ __   ___  __ _ _ __ ______ _ _ __  
// | '_ \ / _ \/ _` | '__|_  / _` | '_ \ 
// | |_) |  __/ (_| | |   / / (_| | |_) |
// | .__/ \___|\__,_|_|  /___\__,_| .__/ 
// | |                            | |    
// |_|                            |_|    

// https://pearzap.com/

import './IERC20.sol';
import './SafeMath.sol';

// IPO contract : Initial Pear Offering
contract IPO 

   {

    using SafeMath for uint256;
    
    //define the admin of IPO 
    address public owner;
    
    address public inputtoken;
    
    bool public inputToken6Decimal=false; //USDC on Polygon chain is 6 decimals
    
    address public outputtoken;
    
    bool noOutputToken;
    
    // total Supply for IPO
    uint256 public totalsupply;

    mapping (address => uint256)public userInvested;
    
    mapping (address => uint256)public userInvestedMemory;
    
    address[] public investors;
    
    address[] public whiteList;

    mapping (address => bool) public whiteListedUser;
    
    mapping (address => bool) public existinguser;
    
    uint256 public maxInvestment = 0; // pay attention to the decimals number of inputtoken
    
    uint256 public minInvestment = 0; // pay attention to the decimals number of inputtoken
    
    //set number of out tokens per in tokens  
    uint256 public outTokenPriceInDollar;                   

    //hardcap 
    uint public IPOTarget;

    //define a state variable to track the funded amount
    uint public receivedFund=0;
    
    //set the IPO status
    
    enum Status {inactive, active, stopped, completed}      // 0, 1, 2, 3
    
    Status private IPOStatus;
    
    uint public IPOStartTime=0;
    
    uint public IPOInTokenClaimTime=0;
    
    uint public IPOEndTime=0;
    
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
     
        IPOStatus = getIPOStatus();
        
        require(IPOStatus == Status.active, "Cannot Stop inactive or completed IPO ");   
        
        IPOStatus = Status.stopped;
    }

    function setActiveStatus() public onlyOwner {
    
        IPOStatus = getIPOStatus();
        
        require(IPOStatus == Status.stopped, "IPO not stopped");   
        
        IPOStatus = Status.active;
    }

    function getIPOStatus() public view returns(Status)  {
    
        
        if (IPOStatus == Status.stopped)
        {
            return Status.stopped;
        }
        
        else if (block.timestamp >=IPOStartTime && block.timestamp <=IPOEndTime)
        {
            return Status.active;
        }
        
        else if (block.timestamp <= IPOStartTime || IPOStartTime == 0)
        {
            return Status.inactive;
        }
        
        else
        {
            return Status.completed;
        }
    
    }

    function invest(uint256 _amount) public {
    
        require(whiteListedUser[msg.sender], "Address not in whitelist");
    
        // check IPO Status
        IPOStatus = getIPOStatus();
        
        require(IPOStatus == Status.active, "IPO in not active");
        
        //check for hard cap
        require(IPOTarget >= receivedFund + _amount, "Target Achieved. Investment not accepted");
        
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
        //Duplicate to keep in memory after the IPO
        userInvestedMemory[msg.sender] += _amount;
        
        receivedFund = receivedFund + _amount; 
        IERC20(inputtoken).transferFrom(msg.sender,address(this), _amount); 

    }
     
     
    function claimTokens() public {

        require(existinguser[msg.sender] == true, "Already claim"); 
        
        require(outputtoken!=BURN_ADDRESS, "Outputtoken not yet available"); 

        // check IPO Status 
        IPOStatus = getIPOStatus();
        
        require(IPOStatus == Status.completed, "IPO in not complete yet");

        uint256 redeemtokens = remainingClaim(msg.sender);

        require(redeemtokens>0, "No tokens to redeem");
        
        IERC20(outputtoken).transfer(msg.sender, redeemtokens);
        
        existinguser[msg.sender] = false; 
        userInvested[msg.sender] = 0;
    }

    // Display user token claim balance
    function remainingClaim(address _address) public view returns (uint256) {

        uint256 redeemtokens = 0;

        if (inputToken6Decimal) {
            redeemtokens = (userInvested[_address] * 1000000000000 * 1000000000000000000) / outTokenPriceInDollar;
        }
        else {
            redeemtokens = (userInvested[_address] * 1000000000000000000) / outTokenPriceInDollar;
        }
        
        return redeemtokens;
        
    }

    // Display user max available investment
    function remainingContribution(address _address) public view returns (uint256) {

        uint256 remaining = maxInvestment - userInvested[_address];
        
        return remaining;
        
    }
    
    //  _token = 1 (outputtoken)        and         _token = 2 (inputtoken) 
    function checkIPObalance(uint8 _token) public view returns(uint256 _balance) {
    
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
        
        require(block.timestamp >= IPOInTokenClaimTime, "IPO in token claim time is not over yet");
        
        uint256 raisedamount = IERC20(inputtoken).balanceOf(address(this));
        
        IERC20(inputtoken).transfer(_admin, raisedamount);
    
    }
  
    function withdrawOutputToken(address _admin, uint256 _amount) public onlyOwner{

        IPOStatus = getIPOStatus();
        require(IPOStatus == Status.completed, "IPO in not complete yet");
        
        uint256 remainingamount = IERC20(outputtoken).balanceOf(address(this));
        
        require(remainingamount >= _amount, "Not enough token to withdraw");
        
        IERC20(outputtoken).transfer(_admin, _amount);
    }
    
    
    function resetIPO() public onlyOwner {
    
        for (uint256 i = 0; i < investors.length; i++) {
         
            if (existinguser[investors[i]]==true)
            {
                existinguser[investors[i]]=false;
                userInvested[investors[i]] = 0;
                userInvestedMemory[investors[i]] = 0;
            }
        }
        
        require(IERC20(outputtoken).balanceOf(address(this)) <= 0, "IPO is not empty");
        require(IERC20(inputtoken).balanceOf(address(this)) <= 0, "IPO is not empty");
        
        totalsupply = 0;
        IPOTarget = 0;
        IPOStatus = Status.inactive;
        IPOStartTime = 0;
        IPOInTokenClaimTime = 0;
        IPOEndTime = 0;
        receivedFund = 0;
        maxInvestment = 0;
        minInvestment = 0;
        inputtoken  =  0x0000000000000000000000000000000000000000;
        outputtoken =  0x0000000000000000000000000000000000000000;
        outTokenPriceInDollar = 0;
        
        delete investors;
    
    }
        
    function initializeIPO(address _inputtoken, address _outputtoken, uint256 _startTime, uint256 _inTokenClaimTime, uint256 _endtime, uint256 _outTokenPriceInDollar, uint256 _maxinvestment, uint256 _minInvestment, bool _inputToken6Decimal, uint256 _forceTotalSupply) public onlyOwner {
        
        require(_endtime > _startTime, "Enter correct Time");
        
        inputtoken = _inputtoken;
        inputToken6Decimal = _inputToken6Decimal;
        outputtoken = _outputtoken;
        outTokenPriceInDollar = _outTokenPriceInDollar;
        require(outTokenPriceInDollar > 0, "token price not set");
        
        if (_outputtoken==BURN_ADDRESS) {
            require(_forceTotalSupply > 0, "Enter correct _forceTotalSupply");
            totalsupply = _forceTotalSupply;
            noOutputToken = true;
        }
        else
        {
            require(IERC20(outputtoken).balanceOf(address(this))>0,"Please first give Tokens to IPO");
            totalsupply = IERC20(outputtoken).balanceOf(address(this));
            noOutputToken = false;
        }

        if (inputToken6Decimal) {
            IPOTarget = (totalsupply *  outTokenPriceInDollar) / 1000000000000 / 1000000000000000000;
        }
        else {
            IPOTarget = (totalsupply * outTokenPriceInDollar) / 1000000000000000000;
        }        

        IPOStatus = Status.active;
        IPOStartTime = _startTime;
        IPOInTokenClaimTime = _inTokenClaimTime;
        IPOEndTime = _endtime;

        require (IPOTarget > _maxinvestment, "Incorrect maxinvestment value");
        
        maxInvestment = _maxinvestment;
        minInvestment = _minInvestment;
    }
    
    function getParticipantNumber() public view returns(uint256 _participantNumber) {
        return investors.length;
    }
   
    function setWhiteList(address[] memory _whiteListAdd) public onlyOwner  {

        for (uint256 i = 0; i < _whiteListAdd.length; i++) {
            whiteList.push(_whiteListAdd[i]);
        } 

        for (uint256 i = 0; i < whiteList.length; i++) {
            whiteListedUser[whiteList[i]] = true;
        }    
    }    
    
    function isWhiteListed(address _userAddress) public view returns(bool _isWhiteListed) {
                return whiteListedUser[_userAddress];
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