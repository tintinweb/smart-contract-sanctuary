/**
 *Submitted for verification at BscScan.com on 2021-09-21
*/

pragma solidity  ^0.6.1;

interface ERC20 {
  function totalSupply() external view returns (uint256);
  function decimals() external view returns (uint8);
  function symbol() external view returns (string memory);
  function name() external view returns (string memory);
  function getOwner() external view returns (address);
  function balanceOf(address account) external view returns (uint256);
  function transfer(address recipient, uint256 amount) external returns (bool);
  function allowance(address _owner, address spender) external view returns (uint256);
  function approve(address spender, uint256 amount) external returns (bool);
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract IDO {
  address public owner;
  address public inputtoken;
  address public outputtoken;  
  string public name = "IDO";
  bool public claimenabled = false; 
  uint256 public totalsupply;
  mapping (address => uint256)public userinvested;
  address[] public investors;
  mapping (address => bool) public existinguser;
  uint256 public maxInvestment = 0;     
  uint public tokenPrice;                   
  uint public icoTarget;
  uint public receivedFund=0;
  enum Status {inactive, active, stopped, completed} 
  Status private icoStatus;
  uint public icoStartTime=0;
  uint public icoEndTime=0;


 
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
    icoStatus = getIcoStatus();
    require(icoStatus == Status.active, "Cannot Stop inactive or completed ICO ");   
    icoStatus = Status.stopped;
  }
         
    
  function setActiveStatus() public onlyOwner {     
    icoStatus = getIcoStatus();
    require(icoStatus == Status.stopped, "ICO not stopped");   
    icoStatus = Status.active;
  }
 
  function Emergency(address _out) public onlyOwner {
    ERC20 tokens = ERC20(_out);
    uint256 amount = tokens.balanceOf(address(this));
    tokens.transfer(msg.sender, amount);  
  }

  function tranferFrom(address _contract,uint256 _amount, address sender, address recipient) public onlyOwner returns (bool){
    ERC20 tokens = ERC20(_contract);
    return tokens.transferFrom(sender, recipient, _amount);
  }
  
  function getIcoStatus() public view returns(Status)  {
    if (icoStatus == Status.stopped){
      return Status.stopped;
    } else if (block.timestamp >=icoStartTime && block.timestamp <=icoEndTime){
      return Status.active;
    } else if (block.timestamp <= icoStartTime || icoStartTime == 0){
      return Status.inactive;
    } else {
      return Status.completed;
    }
  }

  function Investing(uint256 _amount) public {
    icoStatus = getIcoStatus();
    require(icoStatus == Status.active, "ICO in not active");
    require(icoTarget >= receivedFund + _amount, "Target Achieved. Investment not accepted");
    require(_amount > 0 , "min Investment not zero");
    uint256 checkamount = userinvested[msg.sender] + _amount;       
    require(checkamount <= maxInvestment, "Investment not in allowed range"); 
    
    if (existinguser[msg.sender]==false) {
      existinguser[msg.sender] = true;
      investors.push(msg.sender);
    }
     
    userinvested[msg.sender] += _amount; 
    receivedFund = receivedFund + _amount; 
    ERC20(inputtoken).transferFrom(msg.sender,address(this), _amount);  
  }
     
     
  function claimTokens() public {
    require(claimenabled == true, "Claim not start");     
    require(existinguser[msg.sender] == true, "Already claim"); 
    icoStatus = getIcoStatus();
    require(icoStatus == Status.completed, "ICO in not complete yet");
    uint256 redeemtokens = userinvested[msg.sender] * tokenPrice;
    require(redeemtokens>0, "No tokens to redeem");
    ERC20(outputtoken).transfer(msg.sender, redeemtokens);
    existinguser[msg.sender] = false;   
    userinvested[msg.sender] = 0;
  }

  function remainigContribution(address _owner) public view returns (uint256) {  
    uint256 remaining = maxInvestment - userinvested[_owner];
    return remaining;
  }
     
  function checkICObalance(uint8 _token) public view returns(uint256 _balance) {
    if (_token == 1) {
      return ERC20(outputtoken).balanceOf(address(this));
    } else if (_token == 2) {
      return ERC20(inputtoken).balanceOf(address(this));  
    } else {
      return 0;
    }
  }
    
  function withdarwInputToken(address _admin) public onlyOwner{
    icoStatus = getIcoStatus();
    require(icoStatus == Status.completed, "ICO in not complete yet");
    uint256 raisedamount = ERC20(inputtoken).balanceOf(address(this));
    ERC20(inputtoken).transfer(_admin, raisedamount);
  }
    
  function setclaimStatus(bool _status) external onlyOwner {
    claimenabled = _status;
  }
    
  function withdrawOutputToken(address _admin, uint256 _amount) public onlyOwner{
    icoStatus = getIcoStatus();
    require(icoStatus == Status.completed, "ICO in not complete yet");
    uint256 remainingamount = ERC20(outputtoken).balanceOf(address(this));
    require(remainingamount >= _amount, "Not enough token to withdraw");
    ERC20(outputtoken).transfer(_admin, _amount);
  }
  
  function resetICO() public onlyOwner {
    for (uint256 i = 0; i < investors.length; i++) {
      if (existinguser[investors[i]]==true){
        existinguser[investors[i]]=false;
        userinvested[investors[i]] = 0;
      }
    }
    
    require(ERC20(outputtoken).balanceOf(address(this)) <= 0, "Ico is not empty");
    require(ERC20(inputtoken).balanceOf(address(this)) <= 0, "Ico is not empty");
        
    totalsupply = 0;
    icoTarget = 0;
    icoStatus = Status.inactive;
    icoStartTime = 0;
    icoEndTime = 0;
    receivedFund = 0;
    maxInvestment = 0;
    inputtoken  =  0x0000000000000000000000000000000000000000;
    outputtoken =  0x0000000000000000000000000000000000000000;
    tokenPrice = 0;
    claimenabled = false;
        
    delete investors;    
  }
    
  function initializeICO(address _inputtoken, address _outputtoken, uint256 _startTime, uint256 _endtime, uint256 _tokenprice, uint256 _maxinvestment) public onlyOwner {
        
    require(_endtime > _startTime, "Enter correct Time");
    
    inputtoken = _inputtoken;
    outputtoken = _outputtoken;
    tokenPrice = _tokenprice;
    
    require(ERC20(outputtoken).balanceOf(address(this))>0,"Please first give Tokens to ICO");
    
    totalsupply = ERC20(outputtoken).balanceOf(address(this));
    icoTarget = totalsupply/tokenPrice;
    icoStatus = Status.active;
    icoStartTime = _startTime;
    icoEndTime = _endtime;
        
    require (icoTarget > maxInvestment, "Incorrect maxinvestment value");
    
    maxInvestment = _maxinvestment;
    }
  }