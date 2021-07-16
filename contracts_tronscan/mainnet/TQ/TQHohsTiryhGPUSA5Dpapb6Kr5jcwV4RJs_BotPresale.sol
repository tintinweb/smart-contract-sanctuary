//SourceUnit: BotPresale.sol

pragma solidity 0.5.4;

contract Initializable {

  bool private initialized;
  bool private initializing;

  modifier initializer() {
    require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");

    bool wasInitializing = initializing;
    initializing = true;
    initialized = true;

    _;

    initializing = wasInitializing;
  }

    function isConstructor() private view returns (bool) {
    uint256 cs;
    assembly { cs := extcodesize(address) }
    return cs == 0;
  }

  uint256[50] private ______gap;
}

contract Ownable is Initializable {

  address private _owner;
  uint256 private _ownershipLocked;

  event OwnershipLocked(address lockedOwner);
  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


  function initialize(address sender) internal initializer {
    _owner = sender;
	_ownershipLocked = 0;
  }

  function owner() public view returns(address) {
    return _owner;
  }

  modifier onlyOwner() {
    require(isOwner());
    _;
  }

  function isOwner() public view returns(bool) {
    return msg.sender == _owner;
  }

  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }

  function _transferOwnership(address newOwner) internal {
    require(_ownershipLocked == 0);
    require(newOwner != address(0));
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
  
  // Set _ownershipLocked flag to lock contract owner forever
  function lockOwnership() public onlyOwner {
	require(_ownershipLocked == 0);
	emit OwnershipLocked(_owner);
    _ownershipLocked = 1;
  }

  uint256[50] private ______gap;
}

interface ITRC20 {
  function totalSupply() external view returns (uint256);

  function balanceOf(address who) external view returns (uint256);

  function allowance(address owner, address spender)
    external view returns (uint256);

  function transfer(address to, uint256 value) external returns (bool);

  function approve(address spender, uint256 value)
    external returns (bool);

  function transferFrom(address from, address to, uint256 value)
    external returns (bool);

  function burn(uint256 value)
    external returns (bool);

  event Transfer(
    address indexed from,
    address indexed to,
    uint256 value
  );

  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}


library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

contract BotPresale is Ownable {
    using SafeMath for uint256;

    uint256 public start_time = 1600552800;
    uint256 public end_time = 1600552800 + 2 weeks; //1600534800;
    uint256 public sold = 0;
    address payable   dev ;
    address payable constant  staff = address(0x41298914f59ab2d4ab371828716cb1797a748404ed);
    address payable constant  reserve = address(0x412348f00ce7d22c7eef37f239b7e78b40621c0da2);

    ITRC20 private BotToken; 
    
    event onBuy(address buyer , uint256 amount);

    mapping(address => uint256) public boughtOf;

    constructor(ITRC20 _BotToken) public {
        BotToken = _BotToken;
        dev = msg.sender;
		    Ownable.initialize(msg.sender);
    }

    function buy() public payable {
        require(msg.value >= 1 * 10**6 , "MINIMUM_500");
        require(now < end_time , "PRESALE_FINISHED");
        require(now > start_time , "PRESALE_NOT_STARTED");


        BotToken.transfer(msg.sender , msg.value);
        sold += msg.value;
        dev.transfer((msg.value*5)/100);
        staff.transfer((msg.value*10)/100);
        reserve.transfer((msg.value*85)/100);

        emit onBuy(msg.sender , msg.value);
    }

    function burnRemaining() public onlyOwner {
        BotToken.burn(BotToken.balanceOf(address(this)));
    }
}