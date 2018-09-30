pragma solidity 0.4.24;

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
  function totalSupply()public view returns (uint total_Supply);
  function balanceOf(address who)public view returns (uint256);
  function allowance(address owner, address spender)public view returns (uint);
  function transferFrom(address from, address to, uint value)public returns (bool ok);
  function approve(address spender, uint value)public returns (bool ok);
  function transfer(address to, uint value)public returns (bool ok);
  event Transfer(address indexed from, address indexed to, uint value);
  event Approval(address indexed owner, address indexed spender, uint value);
}

contract BNTE1 is ERC20 { 
    using SafeMath for uint256;
    //--- Token configurations ----// 
    string public constant name = "Bountie1";
    string public constant symbol = "BNTE1";
    uint8 public constant decimals = 18;
    uint256 public constant basePrice = 6500;
    uint public maxCap = 20000 ether;
    
    //--- Token allocations -------//
    uint256 public _totalsupply;
    uint256 public mintedTokens;
    uint256 public ETHcollected;

    //--- Address -----------------//
    address public owner;
    address public ethFundMain;
    address public novumAddress;
   
    //--- Milestones --------------//
    uint256 public presale1_startdate = 1537675200; // 23-9-2018
    uint256 public presale2_startdate = 1538712000; // 5-10-2018
    uint256 public presale3_startdate = 1539662400; // 16-10-2018
    uint256 public ico_startdate = 1540612800; // 27-10-2018
    uint256 public ico_enddate = 1541563200; // 7-11-2018
    
    //--- Variables ---------------//
    bool public lockstatus = false;
    bool public stopped = false;
    
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;
    event Mint(address indexed from, address indexed to, uint256 amount);
    event Burn(address indexed from, uint256 amount);
    
    //ok
    modifier onlyOwner() {
        require (msg.sender == owner);
        _;
    }

    //ok
    modifier onlyManual() {
        require(now < ico_enddate);
        _;
    }

    //ok
    modifier onlyICO() {
        require(now >= ico_startdate && now < ico_enddate);
        _;
    }

    //ok
    modifier onlyFinishedICO() {
        require(now >= ico_enddate);
        _;
    }
    
    //ok
    constructor() public
    {
        owner = msg.sender;
        ethFundMain = owner;
        novumAddress = 0x657Eb3CE439CA61e58FF6Cb106df2e962C5e7890;
    }

    //ok
    function totalSupply() public view returns (uint256 total_Supply) {
        total_Supply = _totalsupply;
    }
    
    //ok
    function balanceOf(address _owner)public view returns (uint256 balance) {
        return balances[_owner];
    }

    //ok
    function transferFrom( address _from, address _to, uint256 amount ) public onlyFinishedICO returns (bool success)  {
        uint256 _amount = amount * 10 ** 18;
        require( _to != 0x0);
        require(!lockstatus);
        require(balances[_from] >= _amount && allowed[_from][msg.sender] >= _amount && _amount >= 0);
        balances[_from] = (balances[_from]).sub(_amount);
        allowed[_from][msg.sender] = (allowed[_from][msg.sender]).sub(_amount);
        balances[_to] = (balances[_to]).add(_amount);
        emit Transfer(_from, _to, _amount);
        return true;
    }
    
    //ok
    function approve(address _spender, uint256 amount)public onlyFinishedICO returns (bool success)  {
        uint256 _amount = amount * 10 ** 18;
        require(!lockstatus);
        require( _spender != 0x0);
        allowed[msg.sender][_spender] = _amount;
        emit Approval(msg.sender, _spender, _amount);
        return true;
    }
  
    //ok
    function allowance(address _owner, address _spender)public view returns (uint256 remaining) {
        require( _owner != 0x0 && _spender !=0x0);
        return allowed[_owner][_spender];
    }

    //ok
    function transfer(address _to, uint256 amount)public onlyFinishedICO returns (bool success) {
        uint256 _amount = amount * 10 ** 18;
        require(!lockstatus);
        require( _to != 0x0);
        require(balances[msg.sender] >= _amount && _amount >= 0);
        balances[msg.sender] = (balances[msg.sender]).sub(_amount);
        balances[_to] = (balances[_to]).add(_amount);
        emit Transfer(msg.sender, _to, _amount);
        return true;
    }
    //ok
    function burn(uint256 value) public onlyOwner returns (bool success) {
        uint256 _value = value * 10 ** 18;
        require(balances[msg.sender] >= _value);   
        balances[msg.sender] = (balances[msg.sender]).sub(_value);            
        _totalsupply = _totalsupply.sub(_value);                     
        emit Burn(msg.sender, _value);
        return true;
    }
    //ok
    function burnFrom(address _from, uint256 value) public onlyOwner returns (bool success) {
        uint256 _value = value * 10 ** 18;
        require(balances[_from] >= _value);                
        require(_value <= allowed[_from][msg.sender]);    
        balances[_from] = (balances[_from]).sub(_value);                         
        allowed[_from][msg.sender] = (allowed[_from][msg.sender]).sub(_value);             
        _totalsupply = _totalsupply.sub(_value);                             
        emit Burn(_from, _value);
        return true;
    }

    //ok
    function stopTransferToken() external onlyOwner onlyFinishedICO {
        require(!lockstatus);
        lockstatus = true;
    }

    //ok
    function resumeTransferToken() external onlyOwner onlyFinishedICO {
        require(lockstatus);
        lockstatus = false;
    }

    //ok
    function manualMint(address receiver, uint256 _tokenQuantity) external onlyOwner onlyManual {
        uint256 tokenQuantity = _tokenQuantity * 10 ** 18;
        uint256 tokenPrice = calculatePrice();
        uint256 ethAmount = tokenQuantity.div(tokenPrice);
        ETHcollected = ETHcollected.add(ethAmount);
        require(ETHcollected <= maxCap);
        mintContract(owner, receiver, tokenQuantity);
    }

    //ok
    function () public payable onlyICO {
        require(msg.value != 0 && msg.sender != 0x0);
        require(!stopped && msg.sender != owner);
        require (now <= ico_enddate);
        uint256 tokenPrice = calculatePrice();
        uint256 tokenQuantity = (msg.value).mul(tokenPrice);
        ETHcollected = ETHcollected.add(msg.value);
        require(ETHcollected <= maxCap);
        mintContract(address(this), msg.sender, tokenQuantity);
    }

    //ok
    function mintContract(address from, address receiver, uint256 tokenQuantity) private {
        require(tokenQuantity > 0);
        mintedTokens = mintedTokens.add(tokenQuantity);
        uint256 novumShare = tokenQuantity * 4 / 65;
        uint256 userManagement = tokenQuantity * 31 / 65;
        balances[novumAddress] = balances[novumAddress].add(novumShare);
        balances[owner] = balances[owner].add(userManagement);
        _totalsupply = _totalsupply.add(tokenQuantity * 100 / 65);
        balances[receiver] = balances[receiver].add(tokenQuantity);
        emit Mint(from, receiver, tokenQuantity);
        emit Transfer(0, receiver, tokenQuantity);
        emit Mint(from, novumAddress, novumShare);
        emit Transfer(0, novumAddress, novumShare);
        emit Mint(from, owner, userManagement);
        emit Transfer(0, owner, userManagement);
    }
    
    //ok
    function calculatePrice() private view returns (uint){
         uint price_token = basePrice;
         
        if(now < presale1_startdate) {
            require(ETHcollected < 10000 ether);
            price_token = basePrice * 6 / 5;   
        }
        else  if (now < presale2_startdate) {
            require(ETHcollected < 11739 ether);
            price_token = basePrice * 23 / 20;   
        }
        else if (now < presale3_startdate) {
            require(ETHcollected < 13557 ether);
            price_token = basePrice * 11 / 10;
        }
        else if (now < ico_startdate) {
            require(ETHcollected < 15462 ether);
            price_token = basePrice * 21 / 20;
        }
        else {
            require(ETHcollected < maxCap);
            price_token = basePrice;
        }
        return price_token;
    }
    
    //ok
    function CrowdSale_Halt() external onlyOwner onlyICO {
        require(!stopped);
        stopped = true;
    }

    //ok
    function CrowdSale_Resume() external onlyOwner onlyICO {
        require(stopped);
        stopped = false;
    }
    //ok
    function CrowdSale_Change_ReceiveWallet(address New_Wallet_Address) external onlyOwner {
        require(New_Wallet_Address != 0x0);
        ethFundMain = New_Wallet_Address;
    }
    //ok
	function CrowdSale_AssignOwnership(address newOwner) public onlyOwner {
	    require(newOwner != 0x0);
	    balances[newOwner] = (balances[newOwner]).add(balances[owner]);
	    balances[owner] = 0;
	    owner = newOwner;
	    emit Transfer(msg.sender, newOwner, balances[newOwner]);
	}

    //ok
    function forwardFunds() external onlyOwner { 
        address myAddress = this;
        ethFundMain.transfer(myAddress.balance);
    }
    
    //ok
    function  forwardSomeFunds(uint256 ETHQuantity) external onlyOwner {
       uint256 fund = ETHQuantity * 10 ** 18;
       ethFundMain.transfer(fund);
    } 

    //ok
    function increaseMaxCap(uint256 value) public onlyOwner returns(bool) {
        maxCap = maxCap.add(value * 10 ** 18);
        return true;
    }
    
    //ok
    function modify_NovumAddress(address newAddress) public onlyOwner returns(bool) {
        require(newAddress != 0x0 && novumAddress != newAddress);
        uint256 novumBalance = balances[novumAddress];
        balances[newAddress] = (balances[newAddress]).add(novumBalance);
        balances[novumAddress] = 0;
        novumAddress = newAddress;
        emit Transfer(novumAddress, newAddress, novumBalance);
        return true;
    }
    //ok
    function modify_Presale1StartDate(uint256 newDate) public onlyOwner returns(bool) {
        presale1_startdate = newDate;
        return true;
    }
    //ok
    function modify_Presale2StartDate(uint256 newDate) public onlyOwner returns(bool) {
        presale2_startdate = newDate;
        return true;
    }
    //ok
    function modify_Presale3StartDate(uint256 newDate) public onlyOwner returns(bool) {
        presale3_startdate = newDate;
        return true;
    }
    //ok
    function modify_ICOStartDate(uint256 newDate) public onlyOwner returns(bool) {
        ico_startdate = newDate;
        return true;
    }
    //ok
    function modify_ICOEndDate(uint256 newDate) public onlyOwner returns(bool) {
        ico_enddate = newDate;
        return true;
    }
}