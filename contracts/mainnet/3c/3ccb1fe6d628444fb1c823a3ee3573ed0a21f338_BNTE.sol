pragma solidity 0.5.2;

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

contract BNTE is ERC20 { 
    using SafeMath for uint256;
    //--- Token configurations ----// 
    string public constant name = "Bountie";
    string public constant symbol = "BNTE";
    uint8 public constant decimals = 18;
    uint256 public constant basePrice = 6500;
    uint public maxCap = 20000 ether;
    
    //--- Token allocations -------//
    uint256 public _totalsupply;
    uint256 public mintedTokens;
    uint256 public ETHcollected;

    //--- Address -----------------//
    address public owner;
    address payable public ethFundMain;
    address public novumAddress;
   
    //--- Milestones --------------//
    uint256 public presale1_startdate = 1537675200; // 23-9-2018
    uint256 public presale2_startdate = 1538712000; // 5-10-2018
    uint256 public presale3_startdate = 1539662400; // 16-10-2018
    uint256 public ico_startdate = 1540612800; // 27-10-2018
    uint256 public ico_enddate = 1541563200; // 7-11-2018
    
    //--- Variables ---------------//
    bool public lockstatus = true;
    bool public stopped = false;
    
    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;
    event Mint(address indexed from, address indexed to, uint256 amount);
    event Burn(address indexed from, uint256 amount);
    
    modifier onlyOwner() {
        require (msg.sender == owner);
        _;
    }

    modifier onlyICO() {
        require(now >= presale1_startdate && now < ico_enddate);
        _;
    }

    modifier onlyFinishedICO() {
        require(now >= ico_enddate);
        _;
    }
    
    constructor() public
    {
        owner = msg.sender;
        ethFundMain = 0xDEe3a6b14ef8E21B9df09a059186292C9472045D;
        novumAddress = 0xDEe3a6b14ef8E21B9df09a059186292C9472045D;
    }

    function totalSupply() public view returns (uint256 total_Supply) {
        total_Supply = _totalsupply;
    }
    
    function balanceOf(address _owner)public view returns (uint256 balance) {
        return balances[_owner];
    }

    function transferFrom( address _from, address _to, uint256 _amount ) public onlyFinishedICO returns (bool success)  {
        require( _to != address(0));
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
        require( _spender != address(0));
        allowed[msg.sender][_spender] = _amount;
        emit Approval(msg.sender, _spender, _amount);
        return true;
    }

    function allowance(address _owner, address _spender)public view returns (uint256 remaining) {
        require( _owner != address(0) && _spender != address(0));
        return allowed[_owner][_spender];
    }


    function transfer(address _to, uint256 _amount)public onlyFinishedICO returns (bool success) {
        require(!lockstatus);
        require( _to != address(0));
        require(balances[msg.sender] >= _amount && _amount >= 0);
        balances[msg.sender] = (balances[msg.sender]).sub(_amount);
        balances[_to] = (balances[_to]).add(_amount);
        emit Transfer(msg.sender, _to, _amount);
        return true;
    }

    function burn(uint256 value) public onlyOwner returns (bool success) {
        uint256 _value = value * 10 ** 18;
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

    function manualMint(address receiver, uint256 _tokenQuantity) external onlyOwner{
        uint256 tokenQuantity = _tokenQuantity * 10 ** 18;
        uint256 tokenPrice = calculatePrice();
        uint256 ethAmount = tokenQuantity.div(tokenPrice);
        ETHcollected = ETHcollected.add(ethAmount);
        require(ETHcollected <= maxCap);
        mintContract(owner, receiver, tokenQuantity);
    }

    function () external payable onlyICO {
        require(msg.value != 0 && msg.sender != address(0));
        require(!stopped && msg.sender != owner);
        uint256 tokenPrice = calculatePrice();
        uint256 tokenQuantity = (msg.value).mul(tokenPrice);
        ETHcollected = ETHcollected.add(msg.value);
        require(ETHcollected <= maxCap);
        mintContract(address(this), msg.sender, tokenQuantity);
    }

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
        emit Transfer(address(0), receiver, tokenQuantity);
        emit Mint(from, novumAddress, novumShare);
        emit Transfer(address(0), novumAddress, novumShare);
        emit Mint(from, owner, userManagement);
        emit Transfer(address(0), owner, userManagement);
    }
    
    function calculatePrice() private view returns (uint256){
        uint256 price_token = basePrice;
         
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
    
    function CrowdSale_Halt() external onlyOwner onlyICO {
        require(!stopped);
        stopped = true;
    }


    function CrowdSale_Resume() external onlyOwner onlyICO {
        require(stopped);
        stopped = false;
    }

    function CrowdSale_Change_ReceiveWallet(address payable New_Wallet_Address) external onlyOwner {
        require(New_Wallet_Address != address(0));
        ethFundMain = New_Wallet_Address;
    }

	function CrowdSale_AssignOwnership(address newOwner) public onlyOwner {
	    require(newOwner != address(0));
	    balances[newOwner] = (balances[newOwner]).add(balances[owner]);
	    balances[owner] = 0;
	    owner = newOwner;
	    emit Transfer(msg.sender, newOwner, balances[newOwner]);
	}

    function forwardFunds() external onlyOwner { 
        address myAddress = address(this);
        ethFundMain.transfer(myAddress.balance);
    }

    function modify_NovumAddress(address newAddress) public onlyOwner returns(bool) {
        require(newAddress != address(0) && novumAddress != newAddress);
        uint256 novumBalance = balances[novumAddress];
        address oldAddress = novumAddress;
        balances[newAddress] = (balances[newAddress]).add(novumBalance);
        balances[novumAddress] = 0;
        novumAddress = newAddress;
        emit Transfer(oldAddress, newAddress, novumBalance);
        return true;
    }
}