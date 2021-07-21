/**
 *Submitted for verification at polygonscan.com on 2021-07-21
*/

pragma solidity ^0.5.0;
// pragma experimental ABIEncoderV2;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Context {
    constructor () internal { }

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; 
        return msg.data;
    }
}

contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 _totalSupply;
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }
    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }
    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }
    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, _msgSender(), _allowances[account][_msgSender()].sub(amount, "ERC20: burn amount exceeds allowance"));
    }
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

contract ReentrancyGuard {
    uint256 private _guardCounter;

    constructor () internal {
        _guardCounter = 1;
    }

    modifier nonReentrant() {
        _guardCounter += 1;
        uint256 localCounter = _guardCounter;
        _;
        require(localCounter == _guardCounter, "ReentrancyGuard: reentrant call");
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor () internal {
        _owner = _msgSender();
        emit OwnershipTransferred(address(0), _owner);
    }
    function owner() public view returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
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
        // Solidity only automatically asserts when dividing by 0
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

library Address {
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;

        assembly { codehash := extcodehash(account) }
        return (codehash != 0x0 && codehash != accountHash);
    }
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
    }
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) {
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

interface Fulcrum {
    function mint(address receiver, uint256 amount) external payable returns (uint256 mintAmount);
    function burn(address receiver, uint256 burnAmount) external returns (uint256 loanAmountPaid);
    function assetBalanceOf(address _owner) external view returns (uint256 balance);
}

interface ILendingPoolAddressesProvider {
    function getLendingPool() external view returns (address);
}

interface Aave {
    function deposit(address _reserve, uint256 _amount, uint16 _referralCode) external;
}

interface AToken {
    function redeem(uint256 amount) external;
}

interface IIEarnManager {
    function recommend(address _token) external view returns (
      string memory choice,
      uint256 fapr,
      uint256 aapr
    );
}

contract Structs {
    struct Val {
        uint256 value;
    }

    enum ActionType {
        Deposit,   // supply tokens
        Withdraw  // borrow tokens
    }

    enum AssetDenomination {
        Wei // the amount is denominated in wei
    }

    enum AssetReference {
        Delta // the amount is given as a delta from the current value
    }

    struct AssetAmount {
        bool sign; // true if positive
        AssetDenomination denomination;
        AssetReference ref;
        uint256 value;
    }

    struct ActionArgs {
        ActionType actionType;
        uint256 accountId;
        AssetAmount amount;
        uint256 primaryMarketId;
        uint256 secondaryMarketId;
        address otherAddress;
        uint256 otherAccountId;
        bytes data;
    }

    struct Info {
        address owner;  // The address that owns the account
        uint256 number; // A nonce that allows a single address to control many accounts
    }

    struct Wei {
        bool sign; // true if positive
        uint256 value;
    }
}

interface LendingPoolAddressesProvider {
    function getLendingPool() external view returns (address);
    function getLendingPoolCore() external view returns (address);
}

contract xMATIC is ERC20, ERC20Detailed, ReentrancyGuard, Ownable, Structs {
  using SafeERC20 for IERC20;
  using Address for address;
  using SafeMath for uint256;

  uint256 public pool;
  address public token;
  address public fulcrum;
  address public aave;
  address public aaveToken;
  address public apr;

  enum Lender {
      NONE,
      AAVE,
      FULCRUM
  }

  Lender public provider = Lender.NONE;

  constructor () public ERC20Detailed("xend MATIC", "xMATIC", 8) {
    //mumbai network
    token = address(0xA02f6adc7926efeBBd59Fd43A84f4E0c0c91e832);
    apr = address(0xCC7986A6a8A0774070868Cf0D4aCe451DbEC76EF);
    aave = address(0x178113104fEcbcD7fF8669a0150721e231F0FD4B);
    fulcrum = address(0x178113104fEcbcD7fF8669a0150721e231F0FD4B);
    aaveToken = address(0xF45444171435d0aCB08a8af493837eF18e86EE27);

    // token = address(0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270);
    // apr = address(0xdD6d648C991f7d47454354f4Ef326b04025a48A8);
    // aave = address(0xd05e3E715d945B59290df0ae8eF85c1BdB684744);
    // fulcrum = address(0x2e1a74a16e3a9f8e3d825902ab9fb87c606cb13f);
    // aaveToken = address(0x8dF3aad3a84da6b69A4DA8aeC3eA40d9091B2Ac4);
    // approveToken();
  } 

  // Ownable setters incase of support in future for these systems
  function set_new_APR(address _new_APR) public onlyOwner {
      apr = _new_APR;
  }
  // Quick swap low gas method for pool swaps
  function deposit(uint256 _amount)
      external
      nonReentrant
  {
      require(_amount > 0, "deposit must be greater than 0");
      pool = _calcPoolValueInToken();

      IERC20(token).safeTransferFrom(msg.sender, address(this), _amount);

      // Calculate pool shares
      uint256 shares = 0;
      if (pool == 0) {
        shares = _amount;
        pool = _amount;
      } else {
        shares = (_amount.mul(_totalSupply)).div(pool);
      }
      pool = _calcPoolValueInToken();
      _mint(msg.sender, shares);
  }

  // No rebalance implementation for lower fees and faster swaps
  function withdraw(uint256 _shares)
      external
      nonReentrant
  {
      require(_shares > 0, "withdraw must be greater than 0");

      uint256 ibalance = balanceOf(msg.sender);
      require(_shares <= ibalance, "insufficient balance");

      // Could have over value from cTokens
      pool = _calcPoolValueInToken();
      // Calc to redeem before updating balances
      uint256 r = (pool.mul(_shares)).div(_totalSupply);


      _balances[msg.sender] = _balances[msg.sender].sub(_shares, "redeem amount exceeds balance");
      _totalSupply = _totalSupply.sub(_shares);

      emit Transfer(msg.sender, address(0), _shares);

      // Check balance
      uint256 b = IERC20(token).balanceOf(address(this));
      if (b < r) {
        _withdrawSome(r.sub(b));
      }

      IERC20(token).safeTransfer(msg.sender, r);
      pool = _calcPoolValueInToken();
  }

  function() external payable {

  }

  function recommend() public view returns (Lender) {
    (, uint256 fapr,uint256 aapr) = IIEarnManager(apr).recommend(token);
    uint256 max = 0;
    if (fapr > max) {
      max = fapr;
    }
    if (aapr > max) {
      max = aapr;
    }    
    Lender newProvider = Lender.NONE;
    if (max == aapr) {
      newProvider = Lender.AAVE;
    } else if (max == fapr) {
      newProvider = Lender.FULCRUM;
    }
    return newProvider;
  }

  function balance() public view returns (uint256) {
    return IERC20(token).balanceOf(address(this));
  }

  function getAave() public view returns (address) {
    return LendingPoolAddressesProvider(aave).getLendingPool();
  }
  function getAaveCore() public view returns (address) {
    return LendingPoolAddressesProvider(aave).getLendingPoolCore();
  }

  function approveToken() public {
      IERC20(token).safeApprove(getAaveCore(), uint(-1));
      IERC20(token).safeApprove(fulcrum, uint(-1));
  }

  function balanceFulcrumInToken() public view returns (uint256) {
    uint256 b = balanceFulcrum();
    if (b > 0) {
      b = Fulcrum(fulcrum).assetBalanceOf(address(this));
    }
    return b;
  }
  function balanceFulcrum() public view returns (uint256) {
    return IERC20(fulcrum).balanceOf(address(this));
  }
  function balanceAave() public view returns (uint256) {
    return IERC20(aaveToken).balanceOf(address(this));
  }

  function _balance() internal view returns (uint256) {
    return IERC20(token).balanceOf(address(this));
  }

  function _balanceFulcrumInToken() internal view returns (uint256) {
    uint256 b = balanceFulcrum();
    if (b > 0) {
      b = Fulcrum(fulcrum).assetBalanceOf(address(this));
    }
    return b;
  }
  function _balanceFulcrum() internal view returns (uint256) {
    return IERC20(fulcrum).balanceOf(address(this));
  }
  function _balanceAave() internal view returns (uint256) {
    return IERC20(aaveToken).balanceOf(address(this));
  }

  function _withdrawAll() internal {
    uint256  amount = _balanceFulcrum();
    if (amount > 0) {
      _withdrawFulcrum(amount);
    }
    amount = _balanceAave();
    if (amount > 0) {
      _withdrawAave(amount);
    }
  }

  function _withdrawSomeFulcrum(uint256 _amount) internal {
    uint256 b = balanceFulcrum(); // 1970469086655766652
    // Balance of token in fulcrum
    uint256 bT = balanceFulcrumInToken(); // 2000000803224344406
    require(bT >= _amount, "insufficient funds");
    // can have unintentional rounding errors
    uint256 amount = (b.mul(_amount)).div(bT).add(1);
    _withdrawFulcrum(amount);
  }

  function _withdrawSome(uint256 _amount) internal {
    if (provider == Lender.AAVE) {
      require(balanceAave() >= _amount, "insufficient funds");
      _withdrawAave(_amount);
    }
    if (provider == Lender.FULCRUM) {
      _withdrawSomeFulcrum(_amount);
    }
  }

  function rebalance() public {
    Lender newProvider = recommend();

    if (newProvider != provider) {
      _withdrawAll();
    }

    if (balance() > 0) {
      if (newProvider == Lender.FULCRUM) {
        supplyFulcrum(balance());
      } else if (newProvider == Lender.AAVE) {
        supplyAave(balance());
      }
    }

    provider = newProvider;
  }

  // Internal only rebalance for better gas in redeem
  function _rebalance(Lender newProvider) internal {
    if (_balance() > 0) {
      if (newProvider == Lender.FULCRUM) {
        supplyFulcrum(_balance());
      } else if (newProvider == Lender.AAVE) {
        supplyAave(_balance());
      }
    }
    provider = newProvider;
  }

  function supplyAave(uint amount) public {
      Aave(getAave()).deposit(token, amount, 0);
  }
  function supplyFulcrum(uint amount) public {
      require(Fulcrum(fulcrum).mint(address(this), amount) > 0, "FULCRUM: supply failed");
  }
  function _withdrawAave(uint amount) internal {
      AToken(aaveToken).redeem(amount);
  }
  function _withdrawFulcrum(uint amount) internal {
      require(Fulcrum(fulcrum).burn(address(this), amount) > 0, "FULCRUM: withdraw failed");
  }

  function _calcPoolValueInToken() internal view returns (uint) {
    return _balanceFulcrumInToken()
      .add(_balanceAave())
      .add(_balance());
  }

  function calcPoolValueInToken() public view returns (uint) {

    return balanceFulcrumInToken()
      .add(balanceAave())
      .add(balance());
  }

  function getPricePerFullShare() public view returns (uint) {
    uint _pool = calcPoolValueInToken();
    return _pool.mul(1e18).div(_totalSupply);
  }
}