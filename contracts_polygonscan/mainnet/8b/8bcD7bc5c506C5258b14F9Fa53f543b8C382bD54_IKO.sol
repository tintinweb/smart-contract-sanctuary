// SPDX-License-Identifier: MIT

//  .----------------.  .----------------.  .----------------.  .----------------.  .----------------. 
// | .--------------. || .--------------. || .--------------. || .--------------. || .--------------. |
// | |  ___  ____   | || |     ____     | || |      __      | || |   _____      | || |      __      | |
// | | |_  ||_  _|  | || |   .'    `.   | || |     /  \     | || |  |_   _|     | || |     /  \     | |
// | |   | |_/ /    | || |  /  .--.  \  | || |    / /\ \    | || |    | |       | || |    / /\ \    | |
// | |   |  __'.    | || |  | |    | |  | || |   / ____ \   | || |    | |   _   | || |   / ____ \   | |
// | |  _| |  \ \_  | || |  \  `--'  /  | || | _/ /    \ \_ | || |   _| |__/ |  | || | _/ /    \ \_ | |
// | | |____||____| | || |   `.____.'   | || ||____|  |____|| || |  |________|  | || ||____|  |____|| |
// | |              | || |              | || |              | || |              | || |              | |
// | '--------------' || '--------------' || '--------------' || '--------------' || '--------------' |
// '----------------'  '----------------'  '----------------'  '----------------'  '----------------' 

// website : https://koaladefi.finance/
// twitter : https://twitter.com/KoalaDefi

pragma solidity  ^0.6.1;

import './IERC20.sol';
import './SafeMath.sol';

// IKO contract : Initial Koala Offering
contract IKO 

   {

    using SafeMath for uint256;
    
    //define the admin of IKO 
    address public owner;
    
    address public inputtoken;
    
    bool public inputToken6Decimal=false; //USDC on Polygon chain is 6 decimals
    
    address public outputtoken;
    
    bool noOutputToken;
    
    // total Supply for IKO
    uint256 public totalsupply;

    mapping (address => uint256)public userInvested;
    
    mapping (address => uint256)public userInvestedMemory;
    
    address[] public investors;
    
    mapping (address => bool) public existinguser;
    
    uint256 public maxInvestment = 0; // pay attention to the decimals number of inputtoken
    
    uint256 public minInvestment = 0; // pay attention to the decimals number of inputtoken
    
    //set number of out tokens per in tokens  
    uint256 public outTokenPriceInDollar;                   

    //hardcap 
    uint public IKOTarget;

    //define a state variable to track the funded amount
    uint public receivedFund=0;
    
    //define a state variable to track the input token fee amount (used to buyback and burn Lyptus after IKO)
    uint public receivedInTokenFee=0;
    
    //set the IKO status
    
    enum Status {inactive, active, stopped, completed}      // 0, 1, 2, 3
    
    Status private IKOStatus;
    
    uint public IKOStartTime=0;
    
    uint public IKOInTokenClaimTime=0;
    
    uint public IKOEndTime=0;
    
    // Token burn rate in basis point
    uint16 public inTokenBurnFeeBP=0;  

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
     
        IKOStatus = getIKOStatus();
        
        require(IKOStatus == Status.active, "Cannot Stop inactive or completed IKO ");   
        
        IKOStatus = Status.stopped;
    }

    function setActiveStatus() public onlyOwner {
    
        IKOStatus = getIKOStatus();
        
        require(IKOStatus == Status.stopped, "IKO not stopped");   
        
        IKOStatus = Status.active;
    }

    function getIKOStatus() public view returns(Status)  {
    
        
        if (IKOStatus == Status.stopped)
        {
            return Status.stopped;
        }
        
        else if (block.timestamp >=IKOStartTime && block.timestamp <=IKOEndTime)
        {
            return Status.active;
        }
        
        else if (block.timestamp <= IKOStartTime || IKOStartTime == 0)
        {
            return Status.inactive;
        }
        
        else
        {
            return Status.completed;
        }
    
    }

    function invest(uint256 _amount) public {
    
        // check IKO Status
        IKOStatus = getIKOStatus();
        
        require(IKOStatus == Status.active, "IKO in not active");
        
        //check for hard cap
        require(IKOTarget >= receivedFund + _amount, "Target Achieved. Investment not accepted");
        
        require(_amount >= minInvestment , "min Investment not accepted");
        
        uint256 checkamount = userInvested[msg.sender] + _amount;

        //check maximum investment        
        require(checkamount <= maxInvestment, "Investment not in allowed range"); 
        
        uint256 inTokenFeeAmount = 0;
        
            // Fee is payed in input token
            
            inTokenFeeAmount = _amount.mul(inTokenBurnFeeBP).div(10000);

        // check for existinguser
        if (existinguser[msg.sender]==false) {
        
            existinguser[msg.sender] = true;
            investors.push(msg.sender);
        }
        
        userInvested[msg.sender] += _amount.sub(inTokenFeeAmount); 
        //Duplicate to keep in memory after the IKO
        userInvestedMemory[msg.sender] += _amount.sub(inTokenFeeAmount);         
        
        receivedFund = receivedFund + _amount; 
        receivedInTokenFee = receivedInTokenFee + inTokenFeeAmount;
        IERC20(inputtoken).transferFrom(msg.sender,address(this), _amount); 

    }
     
     
    function claimTokens() public {

        require(existinguser[msg.sender] == true, "Already claim"); 

        require(outputtoken!=BURN_ADDRESS, "Outputtoken not yet available"); 
                
        // check IKO Status 
        IKOStatus = getIKOStatus();
        
        require(IKOStatus == Status.completed, "IKO in not complete yet");

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
    function checkIKObalance(uint8 _token) public view returns(uint256 _balance) {
    
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
        
        require(block.timestamp >= IKOInTokenClaimTime, "IKO in token claim time is not over yet");
        
        uint256 raisedamount = IERC20(inputtoken).balanceOf(address(this));
        
        IERC20(inputtoken).transfer(_admin, raisedamount);
    
    }
  
    function withdrawOutputToken(address _admin, uint256 _amount) public onlyOwner{

        IKOStatus = getIKOStatus();
        require(IKOStatus == Status.completed, "IKO in not complete yet");
        
        uint256 remainingamount = IERC20(outputtoken).balanceOf(address(this));
        
        require(remainingamount >= _amount, "Not enough token to withdraw");
        
        IERC20(outputtoken).transfer(_admin, _amount);
    }
    
    
    function resetIKO() public onlyOwner {
    
        for (uint256 i = 0; i < investors.length; i++) {
         
            if (existinguser[investors[i]]==true)
            {
                existinguser[investors[i]]=false;
                userInvested[investors[i]] = 0;
                userInvestedMemory[investors[i]] = 0;
            }
        }
        
        require(IERC20(outputtoken).balanceOf(address(this)) <= 0, "IKO is not empty");
        require(IERC20(inputtoken).balanceOf(address(this)) <= 0, "IKO is not empty");
        
        totalsupply = 0;
        IKOTarget = 0;
        IKOStatus = Status.inactive;
        IKOStartTime = 0;
        IKOInTokenClaimTime = 0;
        IKOEndTime = 0;
        inTokenBurnFeeBP = 0;
        receivedFund = 0;
        receivedInTokenFee = 0;
        maxInvestment = 0;
        minInvestment = 0;
        inputtoken  =  0x0000000000000000000000000000000000000000;
        outputtoken =  0x0000000000000000000000000000000000000000;
        outTokenPriceInDollar = 0;
        
        delete investors;
    
    }
        
    function initializeIKO(address _inputtoken, address _outputtoken, uint256 _startTime, uint256 _inTokenClaimTime, uint256 _endtime, uint16 _inTokenBurnFeeBP, uint256 _outTokenPriceInDollar, uint256 _maxinvestment, uint256 _minInvestment, bool _inputToken6Decimal, uint256 _forceTotalSupply) public onlyOwner {
        
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
            IKOTarget = (totalsupply *  outTokenPriceInDollar) / 1000000000000 / 1000000000000000000;
        }
        else {
            IKOTarget = (totalsupply * outTokenPriceInDollar) / 1000000000000000000;
        }        
                
        IKOStatus = Status.active;
        IKOStartTime = _startTime;
        IKOInTokenClaimTime = _inTokenClaimTime;
        IKOEndTime = _endtime;
        inTokenBurnFeeBP = _inTokenBurnFeeBP;
        
        require (IKOTarget > maxInvestment, "Incorrect maxinvestment value");
        
        maxInvestment = _maxinvestment;
        minInvestment = _minInvestment;
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