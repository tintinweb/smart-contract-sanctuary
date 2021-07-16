//SourceUnit: test.sol

pragma solidity 0.5.8;  /*


___________________________________________________________________
  _      _                                        ______           
  |  |  /          /                                /              
--|-/|-/-----__---/----__----__---_--_----__-------/-------__------
  |/ |/    /___) /   /   ' /   ) / /  ) /___)     /      /   )     
__/__|____(___ _/___(___ _(___/_/_/__/_(___ _____/______(___/__o_o_


 .----------------.  .----------------.  .----------------. 
| .--------------. || .--------------. || .--------------. |
| |  _________   | || |    _______   | || | ____    ____ | |
| | |_   ___  |  | || |   /  ___  |  | || ||_   \  /   _|| |
| |   | |_  \_|  | || |  |  (__ \_|  | || |  |   \/   |  | |
| |   |  _|      | || |   '.___`-.   | || |  | |\  /| |  | |
| |  _| |_       | || |  |`\____) |  | || | _| |_\/_| |_ | |
| | |_____|      | || |  |_______.'  | || ||_____||_____|| |
| |              | || |              | || |              | |
| '--------------' || '--------------' || '--------------' |
 '----------------'  '----------------'  '----------------' 

*/ 


interface IERC20 {
  function totalSupply() external view returns (uint256);
  function balanceOf(address who) external view returns (uint256);
  function allowance(address owner, address spender) external view returns (uint256);
  function transfer(address to, uint256 value) external returns (bool);
  function approve(address spender, uint256 value) external returns (bool);
  function transferFrom(address from, address to, uint256 value) external returns (bool);

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a / b;
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }

  function ceil(uint256 a, uint256 m) internal pure returns (uint256) {
    uint256 c = add(a,m);
    uint256 d = sub(c,1);
    return mul(div(d,m),m);
  }
}

contract ERC20Detailed is IERC20 {

  string private _name;
  string private _symbol;
  uint256 private _decimals;

  constructor(string memory name, string memory symbol, uint256 decimals) public {
    _name = name;
    _symbol = symbol;
    _decimals = decimals;
  }

  function name() public view returns(string memory) {
    return _name;
  }

  function symbol() public view returns(string memory) {
    return _symbol;
  }

  function decimals() public view returns(uint256) {
    return _decimals;
  }
}


contract owned {
    address payable public owner;
    address payable internal newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), owner);
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address payable _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }

    //this flow is to prevent transferring ownership to wrong wallet by mistake
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

contract FSM is owned, ERC20Detailed {

  using SafeMath for uint256;
  mapping (address => uint256) private _balances;
  mapping (address => mapping (address => uint256)) private _allowed;

  string constant private tokenName = "FSM";
  string constant private tokenSymbol = "FSM";
  uint256  constant private tokenDecimals = 18;
  uint256 private _totalSupply  = 1000000000 * (10**tokenDecimals);  // 1 Billion total supply
  uint256 public basePercent = 100;
  
  //ICO Variables
  uint256 public icoTokensAllocated = 450000000 * (10**tokenDecimals);  // 450 million tokens allocated for ICO. They will remain in smart contract, and rest will be sent to owner.
  uint256 public icoTRXReceived;                        // how many TRX Received through ICO
  uint256 public totalTokenSold;                        // how many tokens sold
  uint256 public totalTokensClaimed;                    // how many tokens claimed
  uint256 public minimumContribution = 1000000;         // Minimum amount to invest - 1 TRX (in SUN format)
  uint256 public icoStartTimeStamp = 1582848000;        // Friday, February 28, 2020 12:00:00 AM - GMT
  uint256 public icoEndTimeStamp = 1586448000;          // Thursday, April 9, 2020 4:00:00 PM - GMT
  mapping(address => uint256) public userICOInvestment; // user's contribution tracker.
  
  //ICO event
  event ICOInvestment(address indexed user, uint256 trxAmount, uint256 indexed timeStamp);


  constructor() public payable ERC20Detailed(tokenName, tokenSymbol, tokenDecimals) {
    _issue(msg.sender, _totalSupply - icoTokensAllocated);
    _issue(address(this), icoTokensAllocated);
  }
  

    /**
     * Fallback function. It accepts incoming fund and issue tokens.
     * User has to add more gas for this to work. If user only provide 2100 gas, which is default gas, then it will only accepts incoming TRX and will not update the user's contribution.
     * 
     */
    function () payable external {
        investICO();
    }

  function totalSupply() public view returns (uint256) {
    return _totalSupply;
  }

  function balanceOf(address owner) public view returns (uint256) {
    return _balances[owner];
  }

  function allowance(address owner, address spender) public view returns (uint256) {
    return _allowed[owner][spender];
  }

  function cut(uint256 value) public view returns (uint256)  {
    uint256 roundValue = value.ceil(basePercent);
    uint256 cutValue = roundValue.mul(basePercent).div(10000);
    return cutValue;
  }
  

  function transfer(address to, uint256 value) public returns (bool) {
    require(to != address(0));

    uint256 tokensToBurn = cut(value);
    uint256 tokensToTransfer = value.sub(tokensToBurn);

    _balances[msg.sender] = _balances[msg.sender].sub(value);
    _balances[to] = _balances[to].add(tokensToTransfer);

    _totalSupply = _totalSupply.sub(tokensToBurn);

    emit Transfer(msg.sender, to, tokensToTransfer);
    emit Transfer(msg.sender, address(0), tokensToBurn);
    return true;
  }

  function multiTransfer(address[] memory receivers, uint256[] memory amounts) public {
    uint256 length = receivers.length;
    require(length <= 150, 'Addresses can not be more than 150');
    for (uint256 i = 0; i < length; i++) {
      transfer(receivers[i], amounts[i]);
    }
  }

  function approve(address spender, uint256 value) public returns (bool) {
    require(spender != address(0));
    _allowed[msg.sender][spender] = value;
    emit Approval(msg.sender, spender, value);
    return true;
  }

  function transferFrom(address from, address to, uint256 value) public returns (bool) {
    require(value <= _balances[from]);
    require(value <= _allowed[from][msg.sender]);
    require(to != address(0));

    _balances[from] = _balances[from].sub(value);

    uint256 tokensToBurn = cut(value);
    uint256 tokensToTransfer = value.sub(tokensToBurn);

    _balances[to] = _balances[to].add(tokensToTransfer);
    _totalSupply = _totalSupply.sub(tokensToBurn);

    _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);

    emit Transfer(from, to, tokensToTransfer);
    emit Transfer(from, address(0), tokensToBurn);

    return true;
  }

  function upAllowance(address spender, uint256 addedValue) public returns (bool) {
    require(spender != address(0));
    _allowed[msg.sender][spender] = (_allowed[msg.sender][spender].add(addedValue));
    emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
    return true;
  }

  function downAllowance(address spender, uint256 subtractedValue) public returns (bool) {
    require(spender != address(0));
    _allowed[msg.sender][spender] = (_allowed[msg.sender][spender].sub(subtractedValue));
    emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
    return true;
  }

  function _issue(address account, uint256 amount) internal {
    require(amount != 0);
    _balances[account] = _balances[account].add(amount);
    emit Transfer(address(0), account, amount);
  }

  function destroy(uint256 amount) external {
    _destroy(msg.sender, amount);
  }

  function _destroy(address account, uint256 amount) internal {
    require(amount != 0);
    require(amount <= _balances[account]);
    _totalSupply = _totalSupply.sub(amount);
    _balances[account] = _balances[account].sub(amount);
    emit Transfer(account, address(0), amount);
  }

  function destroyFrom(address account, uint256 amount) external {
    require(amount <= _allowed[account][msg.sender]);
    _allowed[account][msg.sender] = _allowed[account][msg.sender].sub(amount);
    _destroy(account, amount);
  }
  
  
  function _transfer(address _from, address _to, uint256 _value) internal {
      //overflow/underflow handled by SafeMath
      _balances[_from] = _balances[_from].sub(_value);
      _balances[_to] = _balances[_to].add(_value);
      emit Transfer(_from, _to, _value);
  }
  
  /*===============================
    =         ICO FUNCTIONS       =
    ===============================*/
    /**
     * ICO LOGIC:
     * (1) users will invest while ICO is running.. all the fund will be sent to owner immediately.. and all investment will be tracked in smart contract.. and once the ICO is over, then users can claim the tokens..
     * (2) the share percentage to claim token is: user's invested trx / total trx invested * 100
     *      This percentage will be of the ico allocated tokens (450 million)
     */
    
    function investICO() payable public returns(bool)
    {
		//transaction data variables. This will reduce bit of gas cost as it will not read from the state multiple times.
		uint256 msgValue = msg.value;
		address msgSender = msg.sender;
		
		//checking conditions
        require(msgValue >= minimumContribution, "less then minimum contribution"); 
        require(icoStartTimeStamp <= now && now <= icoEndTimeStamp, 'Invalid ICO time');

        //updating state variables
        icoTRXReceived += msgValue;
        userICOInvestment[msgSender] += msgValue;
        
        //send fund to owner
        owner.transfer(msgValue);
        
        //emit an event
        emit ICOInvestment(msgSender, msgValue, now);
        
        return true;

    }
    
    
    function claimTokens() public returns(uint256){
        //transaction data variables. This will reduce bit of gas cost as it will not read from the state multiple times.
		address msgSender = msg.sender;
        
        //check conditions
        require(userICOInvestment[msgSender] > 0, 'User has not invested anything');
        require(icoEndTimeStamp <= now, 'Please wait until ICO ends');
        
        //the share percentage to claim token is: user's invested trx / total trx invested * 100
        //this percentage will be of the ico allocated tokens (450 million)
        uint256 tokens = icoTokensAllocated * userICOInvestment[msgSender] / icoTRXReceived;
        
        //transferring tokens from smart contract to user address.
        //this contract should hold enought tokens to send to users.
        _transfer(address(this), msgSender, tokens);
        
        //updating variables
        userICOInvestment[msgSender] = 0;
        totalTokensClaimed += tokens;
        
        //no need for event, as this can be tracked using Transfer event from smart contract to user address.
        
        return tokens;
    }
    
    function updateICOAllocatedAmount(uint256 _icoTokensAllocated) onlyOwner public returns (bool)
    {
        icoTokensAllocated = _icoTokensAllocated;
        return true;
    }
    
    
    function updateICOtimeStamp(uint256 _icoStartTimeStamp, uint256 _icoEndTimeStamp) onlyOwner public returns (bool)
    {
        //no input value check as owner can change the ICO dates unconditionally.
        icoStartTimeStamp = _icoStartTimeStamp;
        icoEndTimeStamp   = _icoEndTimeStamp;
        return true;
    }
    
    function setMinimumContribution(uint256 _minimumContributionSUN) onlyOwner public returns (bool)
    {
        minimumContribution = _minimumContributionSUN;
        return true;
    }
    
    function manualWithdrawTokens(uint256 tokenAmount) public onlyOwner returns(string memory){
        //sending tokens. This crowdsale contract must hold enough tokens.
        _transfer(address(this), msg.sender, tokenAmount);
        return "Tokens withdrawn to owner wallet";
    }

    function manualWithdrawTRX() public onlyOwner returns(string memory){
        address(owner).transfer(address(this).balance);
        return "Fund withdrawn to owner wallet";
    }
    
}

//****************************************************************************//
//---------------------           EASTER EGGS            ---------------------//
//****************************************************************************//
/*

1.The central creation myth is that an invisible and undetectable Flying Spaghetti Monster created the universe "after drinking heavily".
2.The Pastafarian conception of Heaven includes a beer volcano and a stripper (or sometimes prostitute) factory.The Pastafarian Hell is similar, except that the beer is stale and the strippers have sexually transmitted diseases.
3.Pirates are "absolute divine beings" and the original Pastafarians.
4.At the time of creation, the flying noodle god first created mountains, trees, and a "dwarf"
5.Every Friday is a holy day and a rest day, and believers can ask employers to rest on that basis.
6.According to these beliefs, the Monster's intoxication was the cause for a flawed Earth. Furthermore, according to Pastafarianism, all evidence for evolution was planted by the Flying Spaghetti Monster in an effort to test the faith of Pastafarians—parodying certain biblical literalists. When scientific measurements such as radiocarbon dating are taken, the Flying Spaghetti Monster "is there changing the results with His Noodly Appendage".

*/