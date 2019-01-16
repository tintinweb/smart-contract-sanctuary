pragma solidity 0.5.1;

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

contract ITCO is ERC20 { 
    using SafeMath for uint256;
    //--- Token configurations ----// 
    string public constant name = "IT01";
    string public constant symbol = "IT01";
    uint8 public constant decimals = 18;
    uint public maxCap = 2000000000 ether;
    
    //--- Token allocations -------//
    uint256 public _totalsupply;
    uint256 public mintedTokens;

    //--- Address -----------------//
    address public owner;
    address payable public ethFundMain;
   
    //--- Milestones --------------//
    uint256 public icoStartDate = 1552536000;   // 14-03-2019 12:00 GMT+8
    uint256 public icoEndDate = 1555128000;     // 13-04-2019 12:00 GMT+8
    
    //--- Variables ---------------//
    bool public lockstatus = true;
    bool public stopped = false;
    
    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public allowed;
    mapping(address => bool) public locked;
    event Mint(address indexed from, address indexed to, uint256 amount);
    event Burn(address indexed from, uint256 amount);
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner is allowed");
        _;
    }

    modifier onlyICO() {
        require(now >= icoStartDate && now < icoEndDate, "CrowdSale is not running");
        _;
    }

    modifier onlyFinishedICO() {
        require(now >= icoEndDate, "CrowdSale is running");
        _;
    }

    constructor() public
    {
        owner = msg.sender;
        ethFundMain = 0x657Eb3CE439CA61e58FF6Cb106df2e962C5e7890;
    }

    function totalSupply() public view returns (uint256) {
        return _totalsupply;
    }
    
    function balanceOf(address _owner)public view returns (uint256) {
        return balances[_owner];
    }

    function transferFrom( address _from, address _to, uint256 _amount ) public onlyFinishedICO returns (bool)  {
        require( _to != address(0), "Receiver can not be 0x0");
        require(!lockstatus, "Token is locked now");
        require(balances[_from] >= _amount, "Source&#39;s balance is not enough");
        require(allowed[_from][msg.sender] >= _amount, "Allowance is not enough");
        require(!locked[_from], "From address is locked");
        balances[_from] = (balances[_from]).sub(_amount);
        allowed[_from][msg.sender] = (allowed[_from][msg.sender]).sub(_amount);
        balances[_to] = (balances[_to]).add(_amount);
        emit Transfer(_from, _to, _amount);
        return true;
    }
    
    function approve(address _spender, uint256 _amount) public onlyFinishedICO returns (bool)  {
        require(!lockstatus, "Token is locked now");
        require( _spender != address(0), "Address can not be 0x0");
        require(balances[msg.sender] >= _amount, "Balance does not have enough tokens");
        require(!locked[msg.sender], "Sender address is locked");
        allowed[msg.sender][_spender] = _amount;
        emit Approval(msg.sender, _spender, _amount);
        return true;
    }
  
    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }

    function transfer(address _to, uint256 _amount) public onlyFinishedICO returns (bool) {
        require(!lockstatus, "Token is locked now");
        require( _to != address(0), "Receiver can not be 0x0");
        require(balances[msg.sender] >= _amount, "Balance does not have enough tokens");
        require(!locked[msg.sender], "Sender address is locked");
        balances[msg.sender] = (balances[msg.sender]).sub(_amount);
        balances[_to] = (balances[_to]).add(_amount);
        emit Transfer(msg.sender, _to, _amount);
        return true;
    }

    function burn(uint256 value) public onlyOwner returns (bool) {
        uint256 _value = value * 10 ** 18;
        require(balances[msg.sender] >= _value, "Balance does not have enough tokens");   
        balances[msg.sender] = (balances[msg.sender]).sub(_value);            
        _totalsupply = _totalsupply.sub(_value);                     
        emit Burn(msg.sender, _value);
        return true;
    }

    function stopTransferToken() external onlyOwner onlyFinishedICO {
        require(!lockstatus, "Token is locked");
        lockstatus = true;
    }

    function startTransferToken() external onlyOwner onlyFinishedICO {
        require(lockstatus, "Token is transferable");
        lockstatus = false;
    }

    function () external payable onlyICO {
        require(!stopped, "CrowdSale is stopping");
    }

    function manualMint(address receiver, uint256 _value) public onlyOwner{
        uint256 value = _value.mul(10 ** 18);
        mint(owner, receiver, value);
    }

    function mint(address from, address receiver, uint256 value) internal {
        require(receiver != address(0), "Address can not be 0x0");
        require(value > 0, "Value should larger than 0");
        balances[receiver] = balances[receiver].add(value);
        _totalsupply = _totalsupply.add(value);
        mintedTokens = mintedTokens.add(value);
        require(_totalsupply <= maxCap, "CrowdSale hit max cap");
        emit Mint(from, receiver, value);
        emit Transfer(address(0), receiver, value);
    }
    
    function haltCrowdSale() external onlyOwner onlyICO {
        require(!stopped, "CrowdSale is stopping");
        stopped = true;
    }

    function resumeCrowdSale() external onlyOwner onlyICO {
        require(stopped, "CrowdSale is running");
        stopped = false;
    }

    function changeReceiveWallet(address payable newAddress) external onlyOwner {
        require(newAddress != address(0), "Address can not be 0x0");
        ethFundMain = newAddress;
    }

	function assignOwnership(address newOwner) external onlyOwner {
	    require(newOwner != address(0), "Address can not be 0x0");
	    owner = newOwner;
	}

    function forwardFunds() external onlyOwner { 
        ethFundMain.transfer(address(this).balance);
    }

    function haltTokenTransferFromAddress(address investor) external onlyOwner {
        locked[investor] = true;
    }

    function resumeTokenTransferFromAddress(address investor) external onlyOwner {
        locked[investor] = false;
    }

    // Removed on MainNet
    function modifyICOStartDate(uint256 newDate) external onlyOwner {
        icoStartDate = newDate;
    }

    function modifyICOEndDate(uint256 newDate) external onlyOwner {
        icoEndDate = newDate;
    }
}