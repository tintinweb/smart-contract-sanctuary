// SPDX-License-Identifier: MIT

pragma solidity  ^0.6.1;

// PolyDefi IDO with lock tier function into 1 native pool only

import './IERC20.sol';
import './SafeMath.sol';
import "./IFarmLockTier.sol";

contract IDO

   {

    using SafeMath for uint256;
    
    
    // Info of each tier
    struct TierInfo {
        uint256 octagonMinLock;     // Min lock amount of OCTAGON into the 
        uint256 minInvestment;
        uint256 maxInvestment;
    }    
    
    // Tiers : 5 types (4 tiers)
    enum TiersType {noTier, bronze, silver, gold, platinum}      // 0, 1, 2, 3, 4
    
    TierInfo public bronze;
    TierInfo public silver;
    TierInfo public gold;
    TierInfo public platinum;
    
    // pool lock address / OCTAGON
    address public poolLockTierAddress;  
    
    //define the admin of IDO 
    address public owner;
    
    address public inputtoken;
    
    bool public inputToken6Decimal=false; //USDC on Polygon chain is 6 decimals
    
    address public outputtoken;
    
    bool noOutputToken;
    
    // total Supply for IDO
    uint256 public totalsupply;

    mapping (address => uint256)public userInvested;
    
    mapping (address => uint256)public userInvestedMemory;
    
    address[] public investors;
    
    mapping (address => bool) public existinguser;
    
    //uint256 public maxInvestment = 0; // pay attention to the decimals number of inputtoken
    
    //uint256 public minInvestment = 0; // pay attention to the decimals number of inputtoken
    
    //set number of out tokens per in tokens  
    uint256 public outTokenPriceInDollar;                   

    //hardcap 
    uint public IDOTarget;

    //define a state variable to track the funded amount
    uint public receivedFund=0;
    
    //define a state variable to track the input token fee amount (used to buyback and burn Lyptus after IDO)
    uint public receivedInTokenFee=0;
    
    //set the IDO status
    
    enum Status {inactive, active, stopped, completed}      // 0, 1, 2, 3
    
    Status private IDOStatus;
    
    uint public IDOStartTime=0;
    
    uint public IDOInTokenClaimTime=0;
    
    uint public IDOEndTime=0;
    
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
 
    constructor (
        
        address _poolLockTierAddress // OCTAGON only
        
        ) public  {
    
        owner = msg.sender;
        poolLockTierAddress = _poolLockTierAddress;
   
    }
 
    // Get locked amount in pool
    function getLock(address _user) public view returns (uint256) {
        (,,uint256 lockedAmount, ) = IFarmLockTier(poolLockTierAddress).userInfo(address(_user));
        return lockedAmount;      
    }
    
    // Get eligible tier for user account / depends the lockedAmount
    function getTier(address _user) public view returns (TiersType) {
        
        //get user lock into the pool
        uint256 _userLockedAmountPool = getLock(_user);
        
        if (_userLockedAmountPool > 0)
        {

        if (_userLockedAmountPool >= platinum.octagonMinLock) 
        {
            return TiersType.platinum;
        }
        else if (_userLockedAmountPool >= gold.octagonMinLock) 
        {
            return TiersType.gold;
        }   
        else if (_userLockedAmountPool >= silver.octagonMinLock) 
        {
            return TiersType.silver;
        } 
        else if (_userLockedAmountPool >= bronze.octagonMinLock) 
        {
            return TiersType.bronze;
        } 
        else
        {
            return TiersType.noTier;
        }    
            
        }
        else
        {
            return TiersType.noTier;
        } 
        
        
    }
    
    // Get min and max invest / depends the user tier
    function getMinMaxInvest(address _user) public view returns (uint256,uint256) {
        
        TiersType _userTier = getTier(_user);
        
        if (_userTier == TiersType.platinum)
        {
            return (platinum.minInvestment,platinum.maxInvestment);
        }
        else if (_userTier == TiersType.gold)
        {
            return (gold.minInvestment,gold.maxInvestment);
        } 
        else if (_userTier == TiersType.silver)
        {
            return (silver.minInvestment,silver.maxInvestment);
        }  
        else if (_userTier == TiersType.bronze)
        {
            return (bronze.minInvestment,bronze.maxInvestment);
        } 
        else
        {
            return (0,0);
        }      
        
    }    
 
    function setStopStatus() public onlyOwner  {
     
        IDOStatus = getIDOStatus();
        
        require(IDOStatus == Status.active, "Cannot Stop inactive or completed IDO ");   
        
        IDOStatus = Status.stopped;
    }

    function setActiveStatus() public onlyOwner {
    
        IDOStatus = getIDOStatus();
        
        require(IDOStatus == Status.stopped, "IDO not stopped");   
        
        IDOStatus = Status.active;
    }

    function getIDOStatus() public view returns(Status)  {
    
        
        if (IDOStatus == Status.stopped)
        {
            return Status.stopped;
        }
        
        else if (block.timestamp >=IDOStartTime && block.timestamp <=IDOEndTime)
        {
            return Status.active;
        }
        
        else if (block.timestamp <= IDOStartTime || IDOStartTime == 0)
        {
            return Status.inactive;
        }
        
        else
        {
            return Status.completed;
        }
    
    }

    function invest(uint256 _amount) public {
    
        (uint256 _minInvestment,uint256 _maxInvestment) = getMinMaxInvest(msg.sender);
        
        require(_minInvestment != 0, "No tier for that user");
        require(_maxInvestment != 0, "No tier for that user");
    
        // check IDO Status
        IDOStatus = getIDOStatus();
        
        require(IDOStatus == Status.active, "IDO in not active");
        
        //check for hard cap
        require(IDOTarget >= receivedFund + _amount, "Target Achieved. Investment not accepted");
        
        require(_amount >= _minInvestment , "min Investment not accepted");
        
        uint256 checkamount = userInvested[msg.sender] + _amount;

        //check maximum investment        
        require(checkamount <= _maxInvestment, "Investment not in allowed range"); 
        
        uint256 inTokenFeeAmount = 0;
        
            // Fee is payed in input token
            
            inTokenFeeAmount = _amount.mul(inTokenBurnFeeBP).div(10000);

        // check for existinguser
        if (existinguser[msg.sender]==false) {
        
            existinguser[msg.sender] = true;
            investors.push(msg.sender);
        }
        
        userInvested[msg.sender] += _amount.sub(inTokenFeeAmount); 
        //Duplicate to keep in memory after the IDO
        userInvestedMemory[msg.sender] += _amount.sub(inTokenFeeAmount);         
        
        receivedFund = receivedFund + _amount; 
        receivedInTokenFee = receivedInTokenFee + inTokenFeeAmount;
        IERC20(inputtoken).transferFrom(msg.sender,address(this), _amount); 

    }
     
     
    function claimTokens() public {

        require(existinguser[msg.sender] == true, "Already claim"); 

        require(outputtoken!=BURN_ADDRESS, "Outputtoken not yet available"); 
                
        // check IDO Status 
        IDOStatus = getIDOStatus();
        
        require(IDOStatus == Status.completed, "IDO in not complete yet");

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

        (,uint256 _maxInvestment) = getMinMaxInvest(_address);

        uint256 remaining = _maxInvestment - userInvested[_address];
        
        return remaining;
        
    }
    
    //  _token = 1 (outputtoken)        and         _token = 2 (inputtoken) 
    function checkIDObalance(uint8 _token) public view returns(uint256 _balance) {
    
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
        
        require(block.timestamp >= IDOInTokenClaimTime, "IDO in token claim time is not over yet");
        
        uint256 raisedamount = IERC20(inputtoken).balanceOf(address(this));
        
        IERC20(inputtoken).transfer(_admin, raisedamount);
    
    }
  
    function withdrawOutputToken(address _admin, uint256 _amount) public onlyOwner{

        IDOStatus = getIDOStatus();
        require(IDOStatus == Status.completed, "IDO in not complete yet");
        
        uint256 remainingamount = IERC20(outputtoken).balanceOf(address(this));
        
        require(remainingamount >= _amount, "Not enough token to withdraw");
        
        IERC20(outputtoken).transfer(_admin, _amount);
    }
    
    
    function resetIDO() public onlyOwner {
    
        for (uint256 i = 0; i < investors.length; i++) {
         
            if (existinguser[investors[i]]==true)
            {
                existinguser[investors[i]]=false;
                userInvested[investors[i]] = 0;
                userInvestedMemory[investors[i]] = 0;
            }
        }
        
        require(IERC20(outputtoken).balanceOf(address(this)) <= 0, "IDO is not empty");
        require(IERC20(inputtoken).balanceOf(address(this)) <= 0, "IDO is not empty");
        
        totalsupply = 0;
        IDOTarget = 0;
        IDOStatus = Status.inactive;
        IDOStartTime = 0;
        IDOInTokenClaimTime = 0;
        IDOEndTime = 0;
        inTokenBurnFeeBP = 0;
        receivedFund = 0;
        receivedInTokenFee = 0;
        inputtoken  =  0x0000000000000000000000000000000000000000;
        outputtoken =  0x0000000000000000000000000000000000000000;
        outTokenPriceInDollar = 0;
        
        delete investors;
    
    }

    //Must be done before initializeIDO
    function initializeTier(uint _tier, uint256 _octagonMinLock, uint256 _minInvestment, uint256 _maxInvestment) public onlyOwner {
    
        if (_tier == 1)
        {
            bronze.octagonMinLock = _octagonMinLock;
            bronze.minInvestment = _minInvestment;
            bronze.maxInvestment = _maxInvestment;
        }
        else if (_tier == 2)
        {
            silver.octagonMinLock = _octagonMinLock;
            silver.minInvestment = _minInvestment;
            silver.maxInvestment = _maxInvestment;
        }  
        else if (_tier == 3)
        {
            gold.octagonMinLock = _octagonMinLock;
            gold.minInvestment = _minInvestment;
            gold.maxInvestment = _maxInvestment;
        }   
        else if (_tier == 4)
        {
            platinum.octagonMinLock = _octagonMinLock;
            platinum.minInvestment = _minInvestment;
            platinum.maxInvestment = _maxInvestment;
        }  
    }
        
    //Must be done after initializeTier
    function initializeIDO(address _inputtoken, address _outputtoken, uint256 _startTime, uint256 _inTokenClaimTime, uint256 _endtime, uint16 _inTokenBurnFeeBP, uint256 _outTokenPriceInDollar, bool _inputToken6Decimal, uint256 _forceTotalSupply) public onlyOwner {
        
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
            IDOTarget = (totalsupply *  outTokenPriceInDollar) / 1000000000000 / 1000000000000000000;
        }
        else {
            IDOTarget = (totalsupply * outTokenPriceInDollar) / 1000000000000000000;
        }        
                
        IDOStatus = Status.active;
        IDOStartTime = _startTime;
        IDOInTokenClaimTime = _inTokenClaimTime;
        IDOEndTime = _endtime;
        inTokenBurnFeeBP = _inTokenBurnFeeBP;
        
        require (IDOTarget > platinum.maxInvestment, "Incorrect maxinvestment value");
        
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