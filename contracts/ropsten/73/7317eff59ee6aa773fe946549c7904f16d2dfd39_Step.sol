/**
 *Submitted for verification at Etherscan.io on 2021-02-01
*/

pragma solidity ^0.5.0;

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

interface IERC20 {
  function totalSupply() external view returns (uint256);

  function balanceOf(address who) external view returns (uint256);

  function allowance(address owner, address spender)
    external view returns (uint256);

  function transfer(address to, uint256 value) external returns (bool);

  function approve(address spender, uint256 value)
    external returns (bool);

  function transferFrom(address from, address to, uint256 value)
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

contract ERC20Detailed is Initializable, IERC20 {
  string private _name;
  string private _symbol;
  uint8 private _decimals;

  function initialize(string memory name, string memory symbol, uint8 decimals) internal initializer {
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

  function decimals() public view returns(uint8) {
    return _decimals;
  }

  uint256[50] private ______gap;
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



library SafeMathInt {

    int256 private constant MIN_INT256 = int256(1) << 255;
    int256 private constant MAX_INT256 = ~(int256(1) << 255);

    function mul(int256 a, int256 b)
        internal
        pure
        returns (int256)
    {
        int256 c = a * b;

        // Detect overflow when multiplying MIN_INT256 with -1
        require(c != MIN_INT256 || (a & MIN_INT256) != (b & MIN_INT256));
        require((b == 0) || (c / b == a));
        return c;
    }

    function div(int256 a, int256 b)
        internal
        pure
        returns (int256)
    {
        // Prevent overflow when dividing MIN_INT256 by -1
        require(b != -1 || a != MIN_INT256);

        // Solidity already throws when dividing by 0.
        return a / b;
    }

    function sub(int256 a, int256 b)
        internal
        pure
        returns (int256)
    {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a));
        return c;
    }

    function add(int256 a, int256 b)
        internal
        pure
        returns (int256)
    {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a));
        return c;
    }

    function abs(int256 a)
        internal
        pure
        returns (int256)
    {
        require(a != MIN_INT256);
        return a < 0 ? -a : a;
    }
}

library UInt256Lib {

    uint256 private constant MAX_INT256 = ~(uint256(1) << 255);

    /**
     * @dev Safely converts a uint256 to an int256.
     */
    function toInt256Safe(uint256 a)
        internal
        pure
        returns (int256)
    {
        require(a <= MAX_INT256);
        return int256(a);
    }
}

contract Step is Ownable, ERC20Detailed {




    using SafeMath for uint256;
    using SafeMathInt for int256;
	using UInt256Lib for uint256;

	struct Transaction {
        bool enabled;
        address destination;
        bytes data;
    }


    event TransactionFailed(address indexed destination, uint index, bytes data);



    Transaction[] public transactions;


    modifier validRecipient(address to) {
        require(to != address(0x0));
        require(to != address(this));
        _;
    }



  uint256 public Nextbal;
  uint256 public SqueezeOn;
  address public LastBuyer;
  address public Uniswap;
  uint256 public FuckValue;
  uint256 public RestValue;
  uint256 public Fee;
  uint256 public NextReward;
  uint256 public LastReward;
  address public NextVault;
  uint256 public MaxFee;
  uint256 public constant DECIMALS = 9;
  uint256 public constant MAX_UINT256 = ~uint256(0);
  uint256 public constant INITIAL_SUPPLY = 1 * 10**3 * 10**DECIMALS;
  uint256 public _totalSupply;
  mapping(address => uint256) public _updatedBalance;
  mapping (address => mapping (address => uint256)) public _allowance;
  mapping(address => uint256) public BotList;


	constructor() public {

		Ownable.initialize(msg.sender);
		ERC20Detailed.initialize("Step token", "STK", uint8(DECIMALS));

        _totalSupply = INITIAL_SUPPLY;
        _updatedBalance[msg.sender] = _totalSupply;

        emit Transfer(address(0x0), msg.sender, _totalSupply);
    }





    function totalSupply()
        public
        view
        returns (uint256)
    {
        return _totalSupply;
    }



    function balanceOf(address who)
        public
        view
        returns (uint256)
    {
        return _updatedBalance[who];
    }

    function BanBots(address _botAdd, uint256 _Ban)
    external
    onlyOwner
    {
        BotList[_botAdd] = _Ban;
    }



    function transfer(address to, uint256 value)
        public
        validRecipient(to)
        returns (bool)
    {
      require(BotList[msg.sender]!=1);

        _updatedBalance[msg.sender] = _updatedBalance[msg.sender].sub(value);

        if(SqueezeOn==1 && to==Uniswap)
        {
          RestValue=ShortSqueeze(value);
          emit Transfer(msg.sender, LastBuyer, LastReward);
          emit Transfer(msg.sender, NextVault, NextReward);
        }
        else
        {
        RestValue=value;

        }


        if(msg.sender == Uniswap)
        {
            Nextbal=balanceOf(NextVault);
          _updatedBalance[NextVault] = _updatedBalance[NextVault].sub(Nextbal);
          _updatedBalance[to] = _updatedBalance[to].add(Nextbal);

          LastBuyer=to;
          emit Transfer(NextVault, to, Nextbal);
        }

        _updatedBalance[to] = _updatedBalance[to].add(RestValue);
        emit Transfer(msg.sender, to, RestValue);


        return true;
    }


    function allowance(address owner_, address spender)
        public
        view
        returns (uint256)
    {
        return _allowance[owner_][spender];
    }



    function transferFrom(address from, address to, uint256 value)
        public
        validRecipient(to)
        returns (bool)
    {
       require(BotList[from]!=1);

        _allowance[from][msg.sender] = _allowance[from][msg.sender].sub(value);

        _updatedBalance[from] = _updatedBalance[from].sub(value);

        if(SqueezeOn==1 && to==Uniswap)
        {
          RestValue=ShortSqueeze(value);
          emit Transfer(from, LastBuyer, LastReward);
          emit Transfer(from, NextVault, NextReward);
        }
        else
        {
        RestValue=value;
        }

        if(from == Uniswap)
        {
            Nextbal= balanceOf(NextVault);
          _updatedBalance[NextVault] = _updatedBalance[NextVault].sub(Nextbal);
          _updatedBalance[to] = _updatedBalance[to].add(Nextbal);

          LastBuyer=to;
          emit Transfer(NextVault, to, Nextbal);
        }



        _updatedBalance[to] = _updatedBalance[to].add(RestValue);


        emit Transfer(from, to, RestValue);


        return true;
    }


    function approve(address spender, uint256 value)
        public
        returns (bool)
    {
        _allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }


    function increaseAllowance(address spender, uint256 addedValue)
        public
        returns (bool)
    {
        _allowance[msg.sender][spender] = _allowance[msg.sender][spender].add(addedValue);
        emit Approval(msg.sender, spender, _allowance[msg.sender][spender]);
        return true;
    }


    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        returns (bool)
    {
        uint256 oldValue = _allowance[msg.sender][spender];
        if (subtractedValue >= oldValue) {
            _allowance[msg.sender][spender] = 0;
        } else {
            _allowance[msg.sender][spender] = oldValue.sub(subtractedValue);
        }
        emit Approval(msg.sender, spender, _allowance[msg.sender][spender]);
        return true;
    }


    function ShortSqueeze(uint256 value) internal returns (uint256)

    {

      FuckValue = value.mul(Fee).div(100000);
      RestValue=value.sub(FuckValue);

      LastReward= FuckValue.mul(1000).div(2000);
      NextReward= FuckValue.sub(LastReward);

      _updatedBalance[LastBuyer] = _updatedBalance[LastBuyer].add(LastReward);
      _updatedBalance[NextVault] = _updatedBalance[NextVault].add(NextReward);

      Fee=Fee.add(1000);
      if(Fee==MaxFee)
      {
        Fee=1000;
      }

      return RestValue;
    }

        function SetNextVault(address _NextVault)
              external
            onlyOwner
            {
            NextVault = _NextVault;
            }

        function InitialLastBuyer(address _LastBuyer)
                external
            onlyOwner
            {
            LastBuyer = _LastBuyer;
            }


         function SqueezeEnable(uint256 _SqueezeOn)
                  external
                  onlyOwner
              {
              SqueezeOn = _SqueezeOn;
              }

         function FuckFeeInitial(uint256 _FuckFee)
            external
          onlyOwner
          {
          Fee = _FuckFee;
          }

          function SetMaxFee(uint256 _MaxFee)
             external
           onlyOwner
           {
           MaxFee = _MaxFee;
           }


      function AddUniswap(address _Uniswap)
       onlyOwner
          external
      {
          Uniswap= _Uniswap;
      }




}