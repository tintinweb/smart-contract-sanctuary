pragma solidity 0.4.25;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
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
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
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
}

contract ERC20 {
  function totalSupply()public view returns (uint256 total_Supply);
  function balanceOf(address who)public view returns (uint256);
  function allowance(address owner, address spender)public view returns (uint256);
  function transferFrom(address from, address to, uint256 value)public returns (bool ok);
  function approve(address spender, uint256 value)public returns (bool ok);
  function transfer(address to, uint256 value)public returns (bool ok);
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract WGP is ERC20 { 
    using SafeMath for uint256;
    //--- Token configurations ----// 
    string public constant name = "W GREEN PAY";
    string public constant symbol = "WGP";
    uint8 public constant decimals = 18;
    uint public maxCap = 1000000000 ether;
    
    //--- Token allocations -------//
    uint256 public _totalsupply;
    uint256 public mintedTokens;

    //--- Address -----------------//
    address public owner; //Management
    address public ethFundMain;
   
    //--- Milestones --------------//
    uint256 public icoStartDate = 1538366400; // 01-10-2018 12:00 pm
    uint256 public icoEndDate = 1539489600; // 14-10-2018 12:00 pm
    
    //--- Variables ---------------//
    bool public lockstatus = true;
    bool public stopped = false;
    
    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public allowed;
    event Mint(address indexed from, address indexed to, uint256 amount);
    event Burn(address indexed from, uint256 amount);
    
    modifier onlyOwner() {
        require (msg.sender == owner);
        _;
    }

    modifier onlyICO() {
        require(now >= icoStartDate && now < icoEndDate);
        _;
    }

    modifier onlyFinishedICO() {
        require(now >= icoEndDate);
        _;
    }
    
    constructor() public
    {
        owner = msg.sender;
        ethFundMain = 0x67fd4721d490A5E609cF8e09FCE0a217b91F1546;
    }

    function () public payable onlyICO {
        
    }

    function totalSupply() public view returns (uint256 total_Supply) {
        total_Supply = _totalsupply;
    }
    
    function balanceOf(address _owner)public view returns (uint256 balance) {
        return balances[_owner];
    }

    function transferFrom( address _from, address _to, uint256 _amount ) public onlyFinishedICO returns (bool success)  {
        require( _to != 0x0);
        require(!lockstatus);
        require(balances[_from] >= _amount && allowed[_from][msg.sender] >= _amount && _amount >= 0);
        balances[_from] = (balances[_from]).sub(_amount);
        allowed[_from][msg.sender] = (allowed[_from][msg.sender]).sub(_amount);
        balances[_to] = (balances[_to]).add(_amount);
        emit Transfer(_from, _to, _amount);
        return true;
    }
    
    function approve(address _spender, uint256 _amount)public onlyFinishedICO returns (bool success)  {
        require(!lockstatus);
        require( _spender != 0x0);
        require(balances[msg.sender] >= _amount);
        allowed[msg.sender][_spender] = _amount;
        emit Approval(msg.sender, _spender, _amount);
        return true;
    }
  
    function allowance(address _owner, address _spender)public view returns (uint256 remaining) {
        require( _owner != 0x0 && _spender !=0x0);
        return allowed[_owner][_spender];
    }

    function transfer(address _to, uint256 _amount)public onlyFinishedICO returns (bool success) {
        require(!lockstatus);
        require( _to != 0x0);
        require(balances[msg.sender] >= _amount && _amount >= 0);
        balances[msg.sender] = (balances[msg.sender]).sub(_amount);
        balances[_to] = (balances[_to]).add(_amount);
        emit Transfer(msg.sender, _to, _amount);
        return true;
    }

    function burn(uint256 value) public onlyOwner returns (bool success) {
        uint256 _value = value.mul(10 ** 18);
        require(balances[msg.sender] >= _value);   
        balances[msg.sender] = (balances[msg.sender]).sub(_value);            
        _totalsupply = _totalsupply.sub(_value);                     
        emit Burn(msg.sender, _value);
        return true;
    }

    function stopTransferToken() external onlyOwner onlyFinishedICO {
        require(!lockstatus);
        lockstatus = true;
    }

    function startTransferToken() external onlyOwner onlyFinishedICO {
        require(lockstatus);
        lockstatus = false;
    }

    function manualMint(address receiver, uint256 _value) public onlyOwner returns (bool){
        uint256 value = _value.mul(10 ** 18);
        require(receiver != 0x0 && _value > 0);

        balances[receiver] = balances[receiver].add(value);
        _totalsupply = _totalsupply.add(value);
        mintedTokens = mintedTokens.add(value);

        require(_totalsupply <= maxCap);
        emit Mint(owner, receiver, value);
        emit Transfer(0, receiver, value);
    }
    
    function haltCrowdSale() external onlyOwner onlyICO {
        require(!stopped);
        stopped = true;
    }

    function resumeCrowdSale() external onlyOwner onlyICO {
        require(stopped);
        stopped = false;
    }
    
    function changeReceiveWallet(address newAddress) external onlyOwner {
        require(newAddress != 0x0);
        ethFundMain = newAddress;
    }

	function assignOwnership(address newOwner) public onlyOwner {
	    require(newOwner != 0x0);
	    balances[newOwner] = (balances[newOwner]).add(balances[owner]);
	    balances[owner] = 0;
	    owner = newOwner;
	    emit Transfer(msg.sender, newOwner, balances[newOwner]);
	}

    function forwardFunds() external onlyOwner { 
        address myAddress = this;
        ethFundMain.transfer(myAddress.balance);
    }
}