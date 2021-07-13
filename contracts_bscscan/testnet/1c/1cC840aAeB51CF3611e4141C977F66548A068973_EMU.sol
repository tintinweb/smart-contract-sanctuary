/**
 *Submitted for verification at BscScan.com on 2021-07-13
*/

//Elon Mask token
//https//:www.elonmaskup.com

/*
,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,              ,,,,,,,
,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,              ,,,,,,,,,
,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,              ,,,,,,,,,,,
,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,              ,,,,,,,,,,,,,
,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,              ,,,,,,,,,,,,,,,
,,,           ,,,,,,,,,,,,,,,,,,,,,,              ,,,,,,,,,,,,,,,,,
,,,,           ,,,,,,,,,,,,,,,,,,,              ,,,,,,,,,,,,,,,,,,,
,,,,,           ,,,,,,,,,,,,,,,,              ,,,,,,,,,,,,,,,,,,,,,
,,,,,,           ,,,,,,,,,,,,,              ,,,,,,,,,,,,,,,,,,,,,,,
,,,,,,,           ,,,,,,,,,,              ,,,,,,,,,,,,,,,,,,,,,,,,,
,,,,,,,,           ,,,,,,,              ,,,,,,,,,,,,,,,,,,,,,,,,,,,
,,,,,,,,,           ,,,,              ,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
,,,,,,,,,,           ,              ,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
,,,,,,,,,,,                       ,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
,,,,,,,,,,,,                    ,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
,,,,,,,,,,,,,                 ,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
,,,,,,,,,,,,,,              ,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
*/
//Taken from codes guhtoken
/*
MIT License

Copyright (c) 2018 requestnetwork
Copyright (c) 2018 Fragments, Inc.
Copyright (c) 2020 Ditto Money
Copyright (c) 2021 Goes Up Higher
Copyright (c) 2021 Elon Mask token
*/

pragma solidity 0.5.17;
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b);

    return c;
  }
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0);
    uint256 c = a / b;

    return c;
  }
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    uint256 c = a - b;

    return c;
  }
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);

    return c;
  }
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
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

interface ILP {
    function sync() external;
}


contract ERC20Detailed is IERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor (string memory name, string memory symbol, uint8 decimals) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
    }
    function name() public view returns (string memory) {
        return _name;
    }
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
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
        require(c != MIN_INT256 || (a & MIN_INT256) != (b & MIN_INT256));
        require((b == 0) || (c / b == a));
        return c;
    }
    function div(int256 a, int256 b)
        internal
        pure
        returns (int256)
    {
      
        require(b != -1 || a != MIN_INT256);

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
contract Ownable {
  address private _owner;

  event OwnershipRenounced(address indexed previousOwner);
  
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  constructor() public {
    _owner = msg.sender;
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


  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(_owner);
    _owner = address(0);
  }
  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0));
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}
contract EMU is ERC20Detailed, Ownable {
    using SafeMath for uint256;
    using SafeMathInt for int256;

    event LogRebase(uint256 indexed epoch, uint256 totalSupply);

    // Used for authentication
    address public master;
    
    // LP atomic sync
    address public lp;
    ILP public lpContract;

    modifier onlyMaster() {
        require(msg.sender == master);
        _;
    }
    
    // Only the owner can transfer tokens in the initial phase.
    // This is allow the AMM listing to happen in an orderly fashion.
    
    bool public initialDistributionFinished;
    
    mapping (address => bool) allowTransfer;
    
    modifier initialDistributionLock {
        require(initialDistributionFinished || isOwner() || allowTransfer[msg.sender]);
        _;
    }

    modifier validRecipient(address to) {
        require(to != address(0x0));
        require(to != address(this));
        _;
    }

    uint256 private constant DECIMALS = 9;
    uint256 private constant MAX_UINT256 = ~uint256(0);
    
    uint256 private constant INITIAL_FRAGMENTS_SUPPLY = 21000000 * 10**DECIMALS;

    // TOTAL_GONS is a multiple of INITIAL_FRAGMENTS_SUPPLY so that _gonsPerFragment is an integer.
    // Use the highest value that fits in a uint256 for max granularity.
    uint256 private constant TOTAL_GONS = MAX_UINT256 - (MAX_UINT256 % INITIAL_FRAGMENTS_SUPPLY);

    // MAX_SUPPLY = maximum integer < (sqrt(4*TOTAL_GONS + 1) - 1) / 2
    uint256 private constant MAX_SUPPLY = ~uint128(0);  // (2^128) - 1

    uint256 private _totalSupply;
    uint256 private _gonsPerFragment;
    mapping(address => uint256) private _gonBalances;

    // This is denominated in Fragments, because the gons-fragments conversion might change before
    // it's fully paid.
    mapping (address => mapping (address => uint256)) private _allowedFragments;

    /**
     * @dev Notifies Fragments contract about a new rebase cycle.
     * @param supplyDelta The number of new fragment tokens to add into circulation via expansion.
     * @return The total number of fragments after the supply adjustment.
     */
    function rebase(uint256 epoch, int256 supplyDelta)
        external
        onlyMaster
        returns (uint256)
    {
        if (supplyDelta == 0) {
            emit LogRebase(epoch, _totalSupply);
            return _totalSupply;
        }

        if (supplyDelta < 0) {
            _totalSupply = _totalSupply.sub(uint256(-supplyDelta));
        } else {
            _totalSupply = _totalSupply.add(uint256(supplyDelta));
        }

        if (_totalSupply > MAX_SUPPLY) {
            _totalSupply = MAX_SUPPLY;
        }

        _gonsPerFragment = TOTAL_GONS.div(_totalSupply);
        lpContract.sync();

        emit LogRebase(epoch, _totalSupply);
        return _totalSupply;
    }

    constructor()
        ERC20Detailed("Elon Mask Up", "EMU", uint8(DECIMALS))
        public
    {
        _totalSupply = INITIAL_FRAGMENTS_SUPPLY;
        _gonBalances[msg.sender] = TOTAL_GONS;
        _gonsPerFragment = TOTAL_GONS.div(_totalSupply);
        
        initialDistributionFinished = false;
        
        emit Transfer(address(0x0), msg.sender, _totalSupply);
    }

    /**
     * @notice Sets a new master
     */
    function setMaster(address _master)
        external
        onlyOwner
        returns (uint256)
    {
        master = _master;
    }
    
        /**
     * @notice Sets contract LP address
     */
    function setLP(address _lp)
        external
        onlyOwner
        returns (uint256)
    {
        lp = _lp;
        lpContract = ILP(_lp);
    }

    /**
     * @return The total number of fragments.
     */
    function totalSupply()
        external
        view
        returns (uint256)
    {
        return _totalSupply;
    }

    /**
     * @param who The address to query.
     * @return The balance of the specified address.
     */
    function balanceOf(address who)
        external
        view
        returns (uint256)
    {
        return _gonBalances[who].div(_gonsPerFragment);
    }
    function transfer(address to, uint256 value)
        external
        validRecipient(to)
        initialDistributionLock
        returns (bool)
    {
        uint256 gonValue = value.mul(_gonsPerFragment);
        _gonBalances[msg.sender] = _gonBalances[msg.sender].sub(gonValue);
        _gonBalances[to] = _gonBalances[to].add(gonValue);
        emit Transfer(msg.sender, to, value);
        return true;
    }

   
    function allowance(address owner_, address spender)
        external
        view
        returns (uint256)
    {
        return _allowedFragments[owner_][spender];
    }

  
    function transferFrom(address from, address to, uint256 value)
        external
        validRecipient(to)
        returns (bool)
    {
        _allowedFragments[from][msg.sender] = _allowedFragments[from][msg.sender].sub(value);

        uint256 gonValue = value.mul(_gonsPerFragment);
        _gonBalances[from] = _gonBalances[from].sub(gonValue);
        _gonBalances[to] = _gonBalances[to].add(gonValue);
        emit Transfer(from, to, value);

        return true;
    }

    function approve(address spender, uint256 value)
        external
        initialDistributionLock
        returns (bool)
    {
        _allowedFragments[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

   
    function increaseAllowance(address spender, uint256 addedValue)
        external
        initialDistributionLock
        returns (bool)
    {
        _allowedFragments[msg.sender][spender] =
            _allowedFragments[msg.sender][spender].add(addedValue);
        emit Approval(msg.sender, spender, _allowedFragments[msg.sender][spender]);
        return true;
    }

   
    function decreaseAllowance(address spender, uint256 subtractedValue)
        external
        initialDistributionLock
        returns (bool)
    {
        uint256 oldValue = _allowedFragments[msg.sender][spender];
        if (subtractedValue >= oldValue) {
            _allowedFragments[msg.sender][spender] = 0;
        } else {
            _allowedFragments[msg.sender][spender] = oldValue.sub(subtractedValue);
        }
        emit Approval(msg.sender, spender, _allowedFragments[msg.sender][spender]);
        return true;
    }
    
    function setInitialDistributionFinished()
        external 
        onlyOwner 
    {
        initialDistributionFinished = true;
    }
    
    function enableTransfer(address _addr)
        external 
        onlyOwner 
    {
        allowTransfer[_addr] = true;
    }
}