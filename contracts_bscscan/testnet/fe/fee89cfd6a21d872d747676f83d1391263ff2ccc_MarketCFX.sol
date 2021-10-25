/**
 *Submitted for verification at BscScan.com on 2021-10-24
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.6.8;


contract Ownable {
    address private _owner;
    bool private _inited;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


    constructor() internal {
        initOwner(msg.sender);
    }

    function initOwner(address owner) internal {

        require(!_inited, "Ownable: exist owner");
        require(owner != address(0), "Ownable: owner is zero address");
        _inited = true;
        _owner = owner;
        emit OwnershipTransferred(address(0), owner);
    }


    function owner() public view returns (address) {
        return _owner;
    }


    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }


    function renounceOwnership() external virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }


    function transferOwnership(address newOwner) external virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract Initializable {


  bool private initialized;


  bool private initializing;


  modifier initializer() {
    require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");

    bool isTopLevelCall = !initializing;
    if (isTopLevelCall) {
      initializing = true;
      initialized = true;
    }

    _;

    if (isTopLevelCall) {
      initializing = false;
    }
  }


  function isConstructor() private view returns (bool) {





    address self = address(this);
    uint256 cs;
    assembly { cs := extcodesize(self) }
    return cs == 0;
  }


  uint256[50] private ______gap;
}

interface IPriceOracle {

    event PriceChanged(address token, uint256 oldPrice, uint256 newPrice);


    function getPriceMan(address token) external view returns (uint256);


    function getLastPriceMan(address token) external view returns (uint256 updateAt, uint256 price);
}

interface IGuard {
    function owner() external returns (address);

    function flux() external returns (address);


    function margincall(address borrower) external;

    function tryToRepay(address mkt) external;


    function liquidate(address borrower) external;
}

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

interface IRModel {

    function borrowRate(
        uint256 cash,
        uint256 borrows,
        uint256 reserves
    ) external view returns (uint256);


    function supplyRate(
        uint256 cash,
        uint256 supplies,
        uint256 borrows,
        uint256 reserves
    ) external view returns (uint256);


    function utilizationRate(
        uint256 cash,
        uint256 borrows,
        uint256 reserves
    ) external view returns (uint256);

    function execute(
        uint256 cash,
        uint256 borrows,
        uint256 reserves
    ) external;
}

interface IMarket is IERC20 {
    function decimals() external view returns (uint8);

    function cashPrior() external view returns (uint256);

    function interestIndex() external view returns (uint256);

    function borrowAmount(address acct) external view returns (uint256);

    function underlying() external view returns (IERC20);

    function totalBorrows() external view returns (uint256);

    function underlyingPrice() external view returns (uint256);

    function isFluxMarket() external pure returns (bool);


    function exchangeRate() external view returns (uint256);


    function getAcctSnapshot(address acct)
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        );


    function accountValues(
        address acct,
        uint256 collRatioMan,
        uint256 addBorrows,
        uint256 subSupplies
    )
        external
        view
        returns (
            uint256 supplyValueMan,
            uint256 borrowValueMan,
            uint256 borrowLimitMan
        );


    function seize(
        address liquidator,
        address borrower,
        uint256 collTokens
    ) external;


    function calcCompoundInterest() external;


    function getAPY()
        external
        view
        returns (
            uint256 borrowRate,
            uint256 supplyRate,
            uint256 utilizationRate
        );


    function interestPreDay()
        external
        view
        returns (
            uint256 supplyRate,
            uint256 borrowRate,
            uint256 utilizationRate
        );
}

struct CheckPoint {
    uint256 borrows;
    uint256 interestIndex;
}

contract MarketStorage {

    IERC20 public underlying;
    IPriceOracle public oracle;
    IRModel public interestRateModel;
    IFluxApp public app;
    IGuard public guard;
    address payable public withdrawProxy;



    uint256 internal initialExchangeRateMan = 1e18;

    uint256 public lastAccrueInterest;

    uint256 public totalBorrows;

    uint256 public interestIndex = 1e18;

    mapping(address => CheckPoint) internal userFounds;

    uint256 public taxBalance;

    address public fluxCross;
}

interface INormalERC20 is IERC20 {

    function symbol() external view returns (string memory);


    function decimals() external view returns (uint8);
}

interface IStake is IERC20 {
    function totalStakeAt(uint256 snapID) external view returns (uint256 amount);

    function stakeAmountAt(address staker, uint256 snapID) external view returns (uint256 amount);

    function unStake(uint256 amount) external;

    function stake(uint256 amount) external;
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
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

contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;


    constructor (string memory name_, string memory symbol_) public {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
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


    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }


    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }


    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }


    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }


    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }


    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }


    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }


    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }


    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }


    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }


    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }


    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }


    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }


    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

library Math {

    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }


    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }


    function average(uint256 a, uint256 b) internal pure returns (uint256) {

        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

library Arrays {

    function findUpperBound(uint256[] storage array, uint256 element) internal view returns (uint256) {
        if (array.length == 0) {
            return 0;
        }

        uint256 low = 0;
        uint256 high = array.length;

        while (low < high) {
            uint256 mid = Math.average(low, high);



            if (array[mid] > element) {
                high = mid;
            } else {
                low = mid + 1;
            }
        }


        if (low > 0 && array[low - 1] == element) {
            return low - 1;
        } else {
            return low;
        }
    }
}

library Counters {
    using SafeMath for uint256;

    struct Counter {



        uint256 _value;
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {

        counter._value += 1;
    }

    function decrement(Counter storage counter) internal {
        counter._value = counter._value.sub(1);
    }
}

abstract contract ERC20Snapshot is ERC20 {



    using SafeMath for uint256;
    using Arrays for uint256[];
    using Counters for Counters.Counter;



    struct Snapshots {
        uint256[] ids;
        uint256[] values;
    }

    mapping (address => Snapshots) private _accountBalanceSnapshots;
    Snapshots private _totalSupplySnapshots;


    Counters.Counter private _currentSnapshotId;


    event Snapshot(uint256 id);


    function _snapshot() internal virtual returns (uint256) {
        _currentSnapshotId.increment();

        uint256 currentId = _currentSnapshotId.current();
        emit Snapshot(currentId);
        return currentId;
    }


    function balanceOfAt(address account, uint256 snapshotId) public view returns (uint256) {
        (bool snapshotted, uint256 value) = _valueAt(snapshotId, _accountBalanceSnapshots[account]);

        return snapshotted ? value : balanceOf(account);
    }


    function totalSupplyAt(uint256 snapshotId) public view returns(uint256) {
        (bool snapshotted, uint256 value) = _valueAt(snapshotId, _totalSupplySnapshots);

        return snapshotted ? value : totalSupply();
    }




    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override {
      super._beforeTokenTransfer(from, to, amount);

      if (from == address(0)) {

        _updateAccountSnapshot(to);
        _updateTotalSupplySnapshot();
      } else if (to == address(0)) {

        _updateAccountSnapshot(from);
        _updateTotalSupplySnapshot();
      } else {

        _updateAccountSnapshot(from);
        _updateAccountSnapshot(to);
      }
    }

    function _valueAt(uint256 snapshotId, Snapshots storage snapshots)
        private view returns (bool, uint256)
    {
        require(snapshotId > 0, "ERC20Snapshot: id is 0");

        require(snapshotId <= _currentSnapshotId.current(), "ERC20Snapshot: nonexistent id");















        uint256 index = snapshots.ids.findUpperBound(snapshotId);

        if (index == snapshots.ids.length) {
            return (false, 0);
        } else {
            return (true, snapshots.values[index]);
        }
    }

    function _updateAccountSnapshot(address account) private {
        _updateSnapshot(_accountBalanceSnapshots[account], balanceOf(account));
    }

    function _updateTotalSupplySnapshot() private {
        _updateSnapshot(_totalSupplySnapshots, totalSupply());
    }

    function _updateSnapshot(Snapshots storage snapshots, uint256 currentValue) private {
        uint256 currentId = _currentSnapshotId.current();
        if (_lastSnapshotId(snapshots.ids) < currentId) {
            snapshots.ids.push(currentId);
            snapshots.values.push(currentValue);
        }
    }

    function _lastSnapshotId(uint256[] storage ids) private view returns (uint256) {
        if (ids.length == 0) {
            return 0;
        } else {
            return ids[ids.length - 1];
        }
    }
}

library Address {

    function isContract(address account) internal view returns (bool) {




        uint256 size;

        assembly { size := extcodesize(account) }
        return size > 0;
    }


    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");


        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }


    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }


    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }


    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }


    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");


        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }


    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }


    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");


        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {

            if (returndata.length > 0) {



                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }


    function safeApprove(IERC20 token, address spender, uint256 value) internal {




        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }


    function _callOptionalReturn(IERC20 token, bytes memory data) private {




        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {

            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

interface IMarketERC20 {
    function redeem(uint256 ctokens) external;

    function borrow(uint256 ctokens) external;

    function repay(uint256 amount) external;

    function mint(uint256 amount) external;
}

interface IMarketPayable {
    function redeem(uint256 ctokens) external;

    function borrow(uint256 ctokens) external;

    function repay() external payable;

    function mint() external payable;
}

library MySafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "Math: addition overflow");

        return c;
    }


    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "Math: subtraction overflow");
    }


    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }


    function mul(uint256 a, uint256 b) internal pure returns (uint256) {



        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "Math: multiplication overflow");

        return c;
    }


    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "Math: division by zero");
    }


    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {

        require(b > 0, errorMessage);
        uint256 c = a / b;


        return c;
    }


    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "Math: modulo by zero");
    }


    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }


    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }


    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }


    function average(uint256 a, uint256 b) internal pure returns (uint256) {


        uint256 v = a / 2;
        v = add(v, b / 2);
        uint256 m = a % 2;
        m = add(m, b % 2);
        return add(v, m / 2);
    }
}

library EnumerableSet {









    struct Set {

        bytes32[] _values;


        mapping(bytes32 => uint256) _indexes;
    }


    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);


            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }


    function _remove(Set storage set, bytes32 value) private returns (bool) {

        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {





            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;




            bytes32 lastvalue = set._values[lastIndex];


            set._values[toDeleteIndex] = lastvalue;

            set._indexes[lastvalue] = toDeleteIndex + 1;


            set._values.pop();


            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }


    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }


    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }


    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }



    struct AddressSet {
        Set _inner;
    }


    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(value)));
    }


    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(value)));
    }


    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(value)));
    }


    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }


    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint256(_at(set._inner, index)));
    }



    struct UintSet {
        Set _inner;
    }


    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }


    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }


    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }


    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }


    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

enum MarketStatus {

    Unknown,

    Opened,


    Stopped
}

contract AppStroage {
    struct Market {

        MarketStatus status;

        uint256 collRatioMan;

        mapping(address => bool) accountMembership;
    }

    uint256 public constant CLOSE_FACTOR_MANTISSA = 1.1 * 1e18;

    uint256 public constant REDEEM_FACTOR_MANTISSA = 1.15 * 1e18;

    uint8 public constant JOINED_MKT_LIMIT = 20;


    bool public constant IS_FLUX = true;


    bool public disableSupply;

    bool public disableBorrow;

    bool public lockAllAction;


    bool public liquidateDisabled;


    mapping(IMarket => Market) public markets;


    IMarket[] public marketList;


    mapping(string => uint256) public configs;


    mapping(address => EnumerableSet.AddressSet) internal acctJoinedMkts;

    mapping(address => address) public supportTokens;

    mapping(address => uint256) public poolBorrowLimit;
}

contract AppStroageV2 is AppStroage {
    FluxMint public fluxMiner;
    IStake[] public stakePools;
    mapping(IStake => MarketStatus) public stakePoolStatus;

    mapping(address => LoanBorrowState) public LoanBorrowIndex;
}

struct LoanBorrowState {
    uint256 borrows;
    uint256 index;
}

contract AppStroageV3 is AppStroageV2 {

    uint256 public constant KILL_FACTOR_MANTISSA = 1.1 * 1e18;

    mapping(address => bool) public creditBorrowers;

    mapping(address => mapping(address => uint256)) public creditLimit;


    event CreditLoanChange(address indexed borrower, bool added);
    event CreditLoanLimitChange(address indexed borrower, address indexed market, uint256 limit, uint256 oldLimit);
}

struct Exp {
    uint256 mantissa;
}

library Exponential {
    using MySafeMath for uint256;
    uint256 private constant expScale = 1e18;
    uint256 private constant halfExpScale = expScale / 2;


    function get(uint256 num, uint256 denom) internal pure returns (Exp memory) {
        return Exp({ mantissa: num.mul(expScale).div(denom) });
    }


    function add(Exp memory a, Exp memory b) internal pure returns (Exp memory) {
        return Exp({ mantissa: a.mantissa.add(b.mantissa) });
    }


    function sub(Exp memory a, Exp memory b) internal pure returns (Exp memory) {
        return (Exp({ mantissa: a.mantissa.sub(b.mantissa) }));
    }


    function mulScalar(Exp memory a, uint256 scalar) internal pure returns (Exp memory) {
        return (Exp({ mantissa: a.mantissa.mul(scalar) }));
    }


    function mulScalarTruncate(Exp memory a, uint256 scalar) internal pure returns (uint256) {
        return (truncate(mulScalar(a, scalar)));
    }


    function mulScalarTruncateAddUInt(
        Exp memory a,
        uint256 scalar,
        uint256 addend
    ) internal pure returns (uint256) {
        return mulScalarTruncate(a, scalar).add(addend);
    }


    function divScalar(Exp memory a, uint256 scalar) internal pure returns (Exp memory) {
        return (Exp({ mantissa: a.mantissa.div(scalar) }));
    }


    function divScalarByExp(uint256 scalar, Exp memory divisor) internal pure returns (Exp memory) {



        return get(scalar.mul(expScale), divisor.mantissa);
    }


    function divScalarByExpTruncate(uint256 scalar, Exp memory divisor) internal pure returns (uint256) {
        return (truncate(divScalarByExp(scalar, divisor)));
    }


    function mul(Exp memory a, Exp memory b) internal pure returns (Exp memory) {
        uint256 doubleScaledProduct = a.mantissa.mul(b.mantissa);





        uint256 doubleScaledProductWithHalfScale = doubleScaledProduct.add(halfExpScale);

        return (Exp({ mantissa: doubleScaledProductWithHalfScale.div(expScale) }));
    }


    function mul(uint256 a, uint256 b) internal pure returns (Exp memory) {
        return mul(Exp({ mantissa: a }), Exp({ mantissa: b }));
    }


    function mul3(
        Exp memory a,
        Exp memory b,
        Exp memory c
    ) internal pure returns (Exp memory) {
        return mul(mul(a, b), c);
    }


    function div(Exp memory a, Exp memory b) internal pure returns (Exp memory) {
        return get(a.mantissa, b.mantissa);
    }


    function divAllowZero(Exp memory a, Exp memory b) internal pure returns (Exp memory) {
        if (b.mantissa == 0) {
            return Exp({ mantissa: 0 });
        }
        return get(a.mantissa, b.mantissa);
    }


    function truncate(Exp memory exp) internal pure returns (uint256) {

        return exp.mantissa / expScale;
    }


    function lessThan(Exp memory left, Exp memory right) internal pure returns (bool) {
        return left.mantissa < right.mantissa;
    }


    function lessThanOrEqual(Exp memory left, Exp memory right) internal pure returns (bool) {
        return left.mantissa <= right.mantissa;
    }


    function greaterThan(Exp memory left, Exp memory right) internal pure returns (bool) {
        return left.mantissa > right.mantissa;
    }


    function equal(Exp memory left, Exp memory right) internal pure returns (bool) {
        return left.mantissa == right.mantissa;
    }


    function isZero(Exp memory value) internal pure returns (bool) {
        return value.mantissa == 0;
    }
}

contract FluxApp is Ownable, Initializable, AppStroageV3 {
    using Exponential for Exp;
    using MySafeMath for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;
    uint256 private constant DECIMAL_UNIT = 1e18;
    string private constant CONFIG_TEAM_INCOME_ADDRESS = "FLUX_TEAM_INCOME_ADDRESS";
    string private constant CONFIG_TAX_RATE = "MKT_BORROW_INTEREST_TAX_RATE";
    string private constant CONFIG_LIQUIDITY_RATE = "MKT_LIQUIDATION_FEE_RATE";

    event MarketStatusChagned(IMarket market, MarketStatus oldStatus, MarketStatus newStatus);


    event ConfigChanged(string item, uint256 oldValue, uint256 newValue);

    event MarketApproved(IMarket market, uint256 collRatioMan);

    event MarketRemoved(IMarket market);


    event MarketCollRationChanged(IMarket market, uint256 oldValue, uint256 newValue);
    event FluxMintChanged(FluxMint oldValue, FluxMint newValue);
    event StakePoolApproved(IStake pool, uint256 weights);
    event StakePoolStatusChanged(IStake indexed pool, MarketStatus oldValue, MarketStatus newValue);
    event StakePoolBorrowLimitChanged(IStake indexed pool, uint256 oldValue, uint256 newValue);
    event StakePoolRemoved(IStake indexed pool);


    function initialize(address admin) external initializer {
        initOwner(admin);

        address incomeAddr = 0xd34008Af58BA1DC1e1E8d8804f2BF745A18f38Bd;
        configs[CONFIG_TEAM_INCOME_ADDRESS] = uint256(incomeAddr);
        configs[CONFIG_TAX_RATE] = 0.1 * 1e18;
        configs[CONFIG_LIQUIDITY_RATE] = 0.06 * 1e18;
    }


    function setConfig(string calldata item, uint256 newValue) external onlyOwner {
        uint256 old = configs[item];
        require(old != newValue, "NOTHING_MODIFIED");
        configs[item] = newValue;
        emit ConfigChanged(item, old, newValue);
    }


    function approveMarket(IMarket market, uint256 collRatioMan) external onlyOwner {
        require(market.isFluxMarket(), "NO_FLUX_MARKET");

        require(markets[market].status == MarketStatus.Unknown, "MARKET_REPEAT");

        require(1 * 1e18 < collRatioMan, "INVLIAD_COLLATERAL_RATE");



        address underlying = address(market.underlying());
        require(supportTokens[underlying] == address(0), "UNDERLYING_REPEAT");

        markets[market] = Market(MarketStatus.Opened, collRatioMan);
        marketList.push(market);
        supportTokens[underlying] = address(market);

        emit MarketApproved(market, collRatioMan);
    }


    function resetCollRatio(IMarket market, uint256 collRatioMan) external onlyOwner {
        Market storage info = markets[market];

        require(info.status != MarketStatus.Unknown, "MARKET_NOT_OPENED");
        require(info.collRatioMan != collRatioMan, "NOTHING_MODIFIED");


        require(1e18 < collRatioMan, "INVLIAD_COLLATERAL_RATE");
        uint256 old = info.collRatioMan;
        markets[market].collRatioMan = collRatioMan;
        emit MarketCollRationChanged(market, old, collRatioMan);
    }


    function removeMarket(IMarket market) external onlyOwner {
        Market storage mkt = markets[market];
        require(mkt.status == MarketStatus.Stopped, "MARKET_NOT_STOPPED");

        IERC20 underlying = market.underlying();
        require(underlying.balanceOf(address(market)) == 0, "MARKET_NOT_EMPTYE");


        mkt.status = MarketStatus.Unknown;
        mkt.collRatioMan = 0;
        delete markets[market];
        delete supportTokens[address(market.underlying())];

        emit MarketRemoved(market);

        fluxMiner.removePool(address(market));


        uint256 len = marketList.length;
        for (uint256 i = 0; i < len; i++) {
            if (marketList[i] == market) {

                if (i != len - 1) {
                    marketList[i] = marketList[len - 1];
                }
                marketList.pop();
                break;
            }
        }
    }


    function marketStatus(IMarket market) public view returns (uint256 ratio, MarketStatus status) {
        Market storage mkt = markets[market];
        return (mkt.collRatioMan, mkt.status);
    }

    struct ValuesVars {
        address user;
        uint256 supplyValueMan;
        uint256 borrowValueMan;
        uint256 borrowLimitMan;
    }


    function _calcAcct(
        address acct,
        address targetMarket,
        uint256 addBorrows,
        uint256 subSupplies
    )
        internal
        view
        returns (
            uint256 supplyValueMan,
            uint256 borrowValueMan,
            uint256 borrowLimitMan
        )
    {
        require(acct != address(0), "ADDRESS_IS_EMPTY");
        uint256 len = marketList.length;
        ValuesVars memory varsSum;
        ValuesVars memory vars;
        vars.user = acct;
        uint256 b;
        uint256 s;

        for (uint256 i = 0; i < len; i++) {
            IMarket m = marketList[i];
            if (address(m) == targetMarket) {
                b = addBorrows;
                s = subSupplies;
            } else {
                (b, s) = (0, 0);
            }
            (vars.supplyValueMan, vars.borrowValueMan, vars.borrowLimitMan) = m.accountValues(vars.user, markets[m].collRatioMan, b, s);
            varsSum.supplyValueMan = varsSum.supplyValueMan.add(vars.supplyValueMan);
            varsSum.borrowValueMan = varsSum.borrowValueMan.add(vars.borrowValueMan);
            varsSum.borrowLimitMan = varsSum.borrowLimitMan.add(vars.borrowLimitMan);
        }
        return (varsSum.supplyValueMan, varsSum.borrowValueMan, varsSum.borrowLimitMan);
    }


    function getAcctSnapshot(address acct)
        public
        view
        returns (
            uint256 supplyValueMan,
            uint256 borrowValueMan,
            uint256 borrowLimitMan
        )
    {
        return _calcAcct(acct, address(0), 0, 0);
    }


    function calcBorrow(
        address borrower,
        address borrowMkt,
        uint256 amount
    )
        public
        view
        returns (
            uint256 supplyValueMan,
            uint256 borrowValueMan,
            uint256 borrowLimitMan
        )
    {
        return _calcAcct(borrower, borrowMkt, amount, 0);
    }


    function liquidateAllowed(address borrower) public view returns (bool yes) {
        require(!liquidateDisabled, "RISK_LIQUIDATE_DISABLED");
        require(!creditBorrowers[borrower], "BORROWER_IS_CERDITLOAN");

        ValuesVars memory vars;
        (vars.supplyValueMan, vars.borrowValueMan, vars.borrowLimitMan) = getAcctSnapshot(borrower);
        if (vars.borrowValueMan == 0) {
            return false;
        }


        return Exp(vars.supplyValueMan).div(Exp(vars.borrowValueMan)).mantissa < CLOSE_FACTOR_MANTISSA;
    }


    function setAcctMarket(address acct, bool join) external {
        IMarket market = IMarket(msg.sender);
        require(markets[market].status == MarketStatus.Opened, "MARKET_NOT_OPENED");

        EnumerableSet.AddressSet storage set = acctJoinedMkts[acct];
        if (!join) {

            set.remove(address(market));
            delete markets[market].accountMembership[acct];
        } else {

            if (set.add(address(market))) {
                require(set.length() <= JOINED_MKT_LIMIT, "JOIN_TOO_MATCH");

                markets[market].accountMembership[acct] = true;
            }
        }
    }


    function mktCount() external view returns (uint256) {
        return marketList.length;
    }


    function mktExist(IMarket mkt) external view returns (bool) {
        return markets[mkt].status == MarketStatus.Opened;
    }

    function getJoinedMktInfoAt(address acct, uint256 index) external view returns (IMarket mkt, uint256 collRatioMan) {
        mkt = IMarket(acctJoinedMkts[acct].at(index));
        collRatioMan = markets[mkt].collRatioMan;
    }

    function getAcctJoinedMktCount(address acct) external view returns (uint256) {
        return acctJoinedMkts[acct].length();
    }


    function changeSupplyStatus(bool disable) external onlyOwner {
        require(disableSupply != disable, "NOTHING_MODIFIED");
        disableSupply = disable;
        emit ConfigChanged("DISABLE_SUPPLY", disable ? 1 : 0, disable ? 0 : 1);
    }


    function changeBorrowStatus(bool disable) external onlyOwner {
        require(disableBorrow != disable, "NOTHING_MODIFIED");
        disableBorrow = disable;
        emit ConfigChanged("DISABLE_BORROW", disable ? 1 : 0, disable ? 0 : 1);
    }


    function changeLiquidateStatus(bool disable) external onlyOwner {
        require(liquidateDisabled != disable, "NOTHING_MODIFIED");
        liquidateDisabled = disable;
        emit ConfigChanged("DISABLE_LIQUIDATE", disable ? 1 : 0, disable ? 0 : 1);
    }


    function changeAllActionStatus(bool disable) external onlyOwner {
        require(lockAllAction != disable, "NOTHING_MODIFIED");
        lockAllAction = disable;
        emit ConfigChanged("DISABLE_ALL_ACTION", disable ? 1 : 0, disable ? 0 : 1);
    }


    function setMarketStatus(IMarket market, MarketStatus status) external onlyOwner {
        Market storage mkt = markets[market];
        MarketStatus old = mkt.status;
        require(status != MarketStatus.Unknown, "INVLIAD_MARKET_STATUS");
        require(old != status, "INVLIAD_MARKET_STATUS");
        require(status <= MarketStatus.Stopped, "INVLIAD_MARKET_STATUS");
        mkt.status = status;
        emit MarketStatusChagned(market, old, status);
    }


    function setBorrowLimit(address[] calldata pools, uint256[] calldata limit) external onlyOwner {
        require(pools.length == limit.length, "INVLIAD_PARAMS");
        for (uint256 i = 0; i < pools.length; i++) {
            address pool = pools[i];
            uint256 oldValue = poolBorrowLimit[pool];
            uint256 newValue = limit[i];
            poolBorrowLimit[pool] = newValue;
            emit StakePoolBorrowLimitChanged(IStake(pool), oldValue, newValue);
        }
    }


    function redeemAllowed(
        address acct,
        address mkt,
        uint256 ftokens
    ) public view {
        ValuesVars memory vars;
        (vars.supplyValueMan, vars.borrowValueMan, vars.borrowLimitMan) = _calcAcct(acct, mkt, 0, ftokens);
        if (vars.borrowValueMan == 0) {
            return;
        }

        require(vars.borrowLimitMan >= vars.borrowValueMan, "REDEEM_INSUFFICIENT_COLLATERAL");

        require(Exp(vars.supplyValueMan).div(Exp(vars.borrowValueMan)).mantissa >= REDEEM_FACTOR_MANTISSA, "REDEEM_INSUFFICIENT_TOO_LOW");
    }

    function borrowAllowed(
        address borrower,
        address market,
        uint256 ctokens
    ) public view {
        require(ctokens > 0, "BORROW_IS_ZERO");
        require(!disableBorrow, "RISK_BORROW_DISABLED");
        _workingCheck(market);


        uint256 limit = poolBorrowLimit[market];
        require(limit == 0 || IMarket(market).totalBorrows().add(ctokens) <= limit, "POOL_BORROW_EXCEEDED");

        ValuesVars memory vars;
        (vars.supplyValueMan, vars.borrowValueMan, vars.borrowLimitMan) = _calcAcct(borrower, market, ctokens, 0);


        uint256 creditBorrowLimit = creditLimit[borrower][market];
        if (creditBorrowLimit > 0) {

            require(vars.borrowValueMan <= creditBorrowLimit, "BORROW_LIMIT_OUT");
            require(creditBorrowers[borrower], "NOT_FOUND_CERDITLOAN");
        } else {
            require(vars.borrowValueMan <= vars.borrowLimitMan, "BORROW_LIMIT_OUT");

            require(Exp(vars.supplyValueMan).div(Exp(vars.borrowValueMan)).mantissa >= CLOSE_FACTOR_MANTISSA, "REDEEM_INSUFFICIENT_TOO_LOW");
        }
    }


    function beforeSupply(
        address,
        address market,
        uint256
    ) external view {
        require(!disableSupply, "RISK_DISABLE_MINT");
        _workingCheck(market);
    }

    function beforeTransferLP(
        address market,
        address from,
        address to,
        uint256 amount
    ) external {
        if (from != address(0)) {
            _workingCheck(market);
            redeemAllowed(from, market, amount);
            _settleOnce(market, TradeType.Supply, from);
        }

        if (to != address(0)) {
            _settleOnce(market, TradeType.Supply, to);
        }
    }


    function _workingCheck(address market) private view {
        require(!lockAllAction, "RISK_DISABLE_ALL");

        require(markets[IMarket(market)].status == MarketStatus.Opened, "MARKET_NOT_OPENED");
    }


    function beforeBorrow(
        address borrower,
        address market,
        uint256 ctokens
    ) external {
        borrowAllowed(borrower, market, ctokens);
        _settleOnce(market, TradeType.Borrow, borrower);
    }


    function beforeRedeem(
        address redeemer,
        address market,
        uint256 ftokens
    ) external view {
        _workingCheck(market);
        redeemAllowed(redeemer, market, ftokens);
    }

    function beforeRepay(
        address borrower,
        address market,
        uint256
    ) external {
        _workingCheck(market);
        _settleOnce(market, TradeType.Borrow, borrower);
    }

    function beforeLiquidate(
        address,
        address borrower,
        uint256
    ) external {
        address market = msg.sender;
        _workingCheck(market);
        _settleOnce(market, TradeType.Supply, borrower);
        _settleOnce(market, TradeType.Borrow, borrower);
    }


    function getBorrowLimit(IMarket mkt, address acct) external view returns (uint256 limit, uint256 cash) {
        cash = mkt.underlying().balanceOf(address(mkt));
        ValuesVars memory vars;
        (vars.supplyValueMan, vars.borrowValueMan, vars.borrowLimitMan) = _calcAcct(acct, address(mkt), 0, 0);


        uint256 creditBorrowLimit = creditLimit[acct][address(mkt)];
        if (creditBorrowLimit > 0) {
            vars.borrowLimitMan = creditBorrowLimit;
        }


        if (vars.borrowLimitMan <= vars.borrowValueMan) {
            return (0, cash);
        }
        uint256 unusedMan = vars.borrowLimitMan - vars.borrowValueMan;
        uint256 priceMan = mkt.underlyingPrice();
        uint256 tokenUnit = 10**(uint256(mkt.decimals()));
        limit = tokenUnit.mul(unusedMan).div(priceMan);
    }


    function getWithdrawLimit(IMarket mkt, address acct) external view returns (uint256 limit, uint256 cash) {
        cash = mkt.underlying().balanceOf(address(mkt));

        ValuesVars memory vars;
        vars.user = acct;
        (vars.supplyValueMan, vars.borrowValueMan, vars.borrowLimitMan) = _calcAcct(vars.user, address(mkt), 0, 0);

        if (vars.supplyValueMan == 0) {
            return (0, cash);
        }
        uint256 balance = mkt.balanceOf(acct);
        uint256 xrate = mkt.exchangeRate();
        uint256 supply = Exp(xrate).mulScalarTruncate(balance);

        if (vars.borrowValueMan == 0) {

            return (supply, cash);
        }

        if (vars.borrowLimitMan <= vars.borrowValueMan) {
            return (0, cash);
        }

        if (Exp(vars.supplyValueMan).div(Exp(vars.borrowValueMan)).mantissa <= REDEEM_FACTOR_MANTISSA) {
            return (0, cash);
        }

        ValuesVars memory mktVars;
        uint256 collRatio = markets[mkt].collRatioMan;
        (mktVars.supplyValueMan, mktVars.borrowValueMan, mktVars.borrowLimitMan) = mkt.accountValues(vars.user, collRatio, 0, 0);

        uint256 otherBorrowLimit = vars.borrowLimitMan.sub(mktVars.borrowLimitMan);





        if (otherBorrowLimit >= vars.borrowValueMan) {
            return (supply, cash);
        }
        uint256 priceMan = mkt.underlyingPrice();
        uint256 used = vars.borrowValueMan - otherBorrowLimit;
        uint256 tokenUnit = 10**(uint256(mkt.decimals()));
        uint256 coll = tokenUnit.mul(used).mul(collRatio).div(priceMan).div(DECIMAL_UNIT);
        if (coll > supply) {
            limit = 0;
        } else {
            limit = supply - coll;
        }
    }



    function setFluxMint(FluxMint fluxMiner_) external onlyOwner {
        FluxMint old = fluxMiner;
        require(address(old) == address(0), "REPEAT_INIT");
        emit FluxMintChanged(old, fluxMiner_);
        fluxMiner = fluxMiner_;
    }


    function refreshMarkeFluxSeed() external {
        require(msg.sender == tx.origin, "#FutureCore: SENDER_NOT_HUMAN");


        uint256 len = marketList.length;
        for (uint256 i = 0; i < len; i++) {
            marketList[i].calcCompoundInterest();
        }
    }

    function _settleOnce(
        address pool,
        TradeType kind,
        address user
    ) private {
        FluxMint miner = fluxMiner;
        if (address(miner) != address(0)) {
            miner.settleOnce(pool, kind, user);
        }
    }




    function stakePoolApprove(IStake pool, uint256 seed) external onlyOwner {
        require(stakePoolStatus[pool] == MarketStatus.Unknown, "STAKEPOOL_EXIST");
        stakePools.push(pool);
        stakePoolStatus[pool] = MarketStatus.Opened;

        fluxMiner.setPoolSeed(address(pool), seed);
        emit StakePoolApproved(pool, seed);
        emit StakePoolStatusChanged(pool, MarketStatus.Unknown, MarketStatus.Opened);
    }

    function setStakePoolStatus(IStake pool, bool opened) external onlyOwner {
        require(stakePoolStatus[pool] != MarketStatus.Unknown, "STAKEPOOL_MISSING");
        MarketStatus oldValue = stakePoolStatus[pool];
        MarketStatus newValue = opened ? MarketStatus.Opened : MarketStatus.Stopped;
        stakePoolStatus[pool] = newValue;
        emit StakePoolStatusChanged(pool, oldValue, newValue);
    }

    function beforeStake(address user) external {
        require(stakePoolStatus[IStake(msg.sender)] == MarketStatus.Opened, "STAKEPOOL_NOT_OPEN");
        _settleOnce(msg.sender, TradeType.Stake, user);
    }

    function beforeUnStake(address user) external {
        require(stakePoolStatus[IStake(msg.sender)] != MarketStatus.Unknown, "STAKEPOOL_NOT_FOUND");
        _settleOnce(msg.sender, TradeType.Stake, user);
    }

    function removeStakePool(IStake pool) external onlyOwner {
        require(stakePoolStatus[pool] == MarketStatus.Stopped, "STAKEPOOL_IS_NOT_STOPPED");

        uint256 len = stakePools.length;
        for (uint256 i = 0; i < len; i++) {
            if (stakePools[i] == pool) {
                stakePools[i] = stakePools[len - 1];
                stakePools.pop();
                emit StakePoolRemoved(pool);
                break;
            }
        }
    }


    function getMarketList() external view returns (address[] memory list) {
        uint256 len = marketList.length;
        list = new address[](len);
        for (uint256 i = 0; i < len; i++) {
            list[i] = address(marketList[i]);
        }
    }

    function getStakePoolList() external view returns (address[] memory list) {
        uint256 len = stakePools.length;
        list = new address[](len);
        for (uint256 i = 0; i < len; i++) {
            list[i] = address(stakePools[i]);
        }
    }

    function getFluxTeamIncomeAddress() external view returns (address) {
        return address(configs[CONFIG_TEAM_INCOME_ADDRESS]);
    }






    function resetCreditLoan(address borrower, bool add) external onlyOwner {
        if (add) {
            creditBorrowers[borrower] = true;
        } else {
            require(creditBorrowers[borrower], "NOT_FOUND_CERDITLOAN");

            (, uint256 borrowValueMan, ) = getAcctSnapshot(borrower);
            require(borrowValueMan == 0, "EXIST_CERDITLOAN");


            uint256 len = marketList.length;
            for (uint256 i = 0; i < len; i++) {
                resetCreditLoanLimit(address(marketList[i]), borrower, 0);
            }

            creditBorrowers[borrower] = false;
        }
        emit CreditLoanChange(borrower, add);
    }


    function resetCreditLoanLimit(
        address market,
        address borrower,
        uint256 limit
    ) public onlyOwner {
        require(creditBorrowers[borrower], "NOT_FOUND_CERDITLOAN");
        uint256 oldLimit = creditLimit[borrower][market];
        creditLimit[borrower][market] = limit;
        emit CreditLoanLimitChange(borrower, market, limit, oldLimit);
    }


    function killAllowed(address borrower) external view returns (bool yes) {
        require(!liquidateDisabled, "RISK_LIQUIDATE_DISABLED");
        require(!creditBorrowers[borrower], "BORROWER_IS_CERDITLOAN");

        ValuesVars memory vars;
        (vars.supplyValueMan, vars.borrowValueMan, vars.borrowLimitMan) = getAcctSnapshot(borrower);
        if (vars.borrowValueMan == 0) {
            return false;
        }



        return Exp(vars.supplyValueMan).div(Exp(vars.borrowValueMan)).mantissa < KILL_FACTOR_MANTISSA;
    }
}

enum TradeType { Borrow, Supply, Stake }

struct FluxMarketState {

    uint256 index;

    uint256 block;
}

abstract contract FluxMintStorage {
    address public fluxAPP;


    address public teamFluxReceive;

    address public communityFluxReceive;

    uint256 public lastUnlockTime;
    uint256 public lastUnlockBlock;

    uint16 public borrowFluxWeights;
    uint16 public supplyFluxWeights;
    uint16 public teamFluxWeights;
    uint16 public communityFluxWeights;


    mapping(address => FluxMarketState[3]) public fluxIndexState;
    mapping(address => uint256) public fluxSeeds;

    mapping(address => mapping(address => uint256[3])) public fluxMintIndex;

    mapping(address => uint256) public remainFluxByUser;

    mapping(address => uint256[3]) internal defaultMintIndex;

    mapping(address => uint256) public genesisWeights;
}

contract FluxMint is Ownable, Initializable, FluxMintStorage {
    using MySafeMath for uint256;

    IERC20 public constant FLUX_TOKEN = IERC20(0x1aB6478B47270fF05Af11A012Ac17b098758e193);
    address public constant TEAM_COMMUNITY_WEIGHT_SLOT = 0x16c691bE1E5548dE0aC19e02C68A935C2D9FdEcC;
    uint256 private constant FLUX_START_BLOCK = 4008888;
    uint256 private constant FLUX_FIRST_BLOCK = 785674191168481602;
    uint256 private constant FLUX_PER_BLOCK_DEC = 19290123432;
    uint256 private constant FLUX_END_BLOCK = FLUX_START_BLOCK + 40729350;
    uint256 private constant FLUX_LAST_BLOCK = 3952026700;

    uint256 private constant ONEDAYBLOCKS = 28800;
    uint256 private constant GENESISMINING_BLOCKS = 14 * ONEDAYBLOCKS;
    uint256 private constant GENESISMINING_ENDTIME = FLUX_START_BLOCK + GENESISMINING_BLOCKS;
    uint256 private constant GENESISMINING_AMOUNT = 750000 * 1e18;
    uint256 private constant GENESISMINING_ONEBLOCK = GENESISMINING_AMOUNT / GENESISMINING_BLOCKS;

    uint16 private constant WEIGHT_UNIT = 1e4;
    uint256 private constant DECIMAL_UNIT = 1e18;
    uint256 private constant FLUX_AUTO_UNLOCK_INTERVAL = 1 * 24 hours;


    event FluxWeightsChanged(uint16 borrow, uint16 supply, uint16 stake, uint16 team, uint16 community);
    event GenesisMintWeightsChanged(address pool, uint256 oldWeight, uint256 newWeight);

    event FluxSeedChanged(address indexed pool, uint256 oldSeed, uint256 newSeed);
    event FluxMintIndexChanged(address indexed pool, TradeType indexed kind, uint256 startBlock, uint256 endBlock, uint256 factor, uint256 weights, uint256 seed, uint256 fluxMinted, uint256 oldIndex, uint256 newIndex);


    event DistributedFlux(address indexed pool, TradeType indexed kind, address indexed user, uint256 distribution, uint256 currIndex);

    event UnlockFlux(address recipient, uint256 amount, uint256 weights);


    event FluxGranted(address recipient, uint256 amount);

    event TeamAdressChanged(address oldTeam, address oldComm, address newTeam, address newComm);

    modifier onlyAppOrAdmin() {
        require(msg.sender == fluxAPP || msg.sender == owner(), "Ownable: caller is not the owner");
        _;
    }

    function initialize(address admin_, address fluxAPP_) external initializer {
        initOwner(admin_);


        require(FLUX_START_BLOCK > block.number, "INVALID_BLOCKNUMBER");

        fluxAPP = fluxAPP_;

        lastUnlockBlock = block.number;
        lastUnlockTime = block.timestamp;


        borrowFluxWeights = 0;
        supplyFluxWeights = 0;
        teamFluxWeights = 0;
        communityFluxWeights = 0;
    }


    function resetTeamAdress(address team, address comm) external onlyOwner {
        require(team != address(0), "EMPTY_ADDRESS");
        require(comm != address(0), "EMPTY_ADDRESS");
        emit TeamAdressChanged(teamFluxReceive, communityFluxReceive, team, comm);
        teamFluxReceive = team;
        communityFluxReceive = comm;
        _unlockDAOFlux();
    }


    function grantFlux(address recipient, uint256 amount) external onlyOwner {
        _transferFluxToken(recipient, amount);
        emit FluxGranted(recipient, amount);
    }


    function batchSetPoolWeight(address[] calldata pools, uint256[] calldata weights) external onlyOwner {
        require(pools.length == weights.length, "INVALID_INPUT");
        for (uint256 i = 0; i < pools.length; i++) {
            _setPoolSeed(pools[i], weights[i], true);
        }
    }

    function batchSetPoolGenesisWeight(address[] calldata pools, uint256[] calldata weights) external onlyOwner {
        require(pools.length == weights.length, "INVALID_INPUT");
        for (uint256 i = 0; i < pools.length; i++) {
            _setPoolSeed(pools[i], weights[i], false);
        }
    }

    function setPoolSeed(address pool, uint256 seed) external onlyAppOrAdmin {
        _setPoolSeed(pool, seed, true);
    }

    function _setPoolSeed(
        address pool,
        uint256 seed,
        bool isBase
    ) private {
        splitTowWeight(seed);

        if (pool == TEAM_COMMUNITY_WEIGHT_SLOT) {
            _unlockDAOFlux();
        } else if (FluxApp(fluxAPP).mktExist(IMarket(pool))) {

            _refreshFluxMintIndexAtMarket(pool);
        } else {

            _refreshFluxMintIndex(pool, TradeType.Stake, 0);
        }

        if (isBase) {
            uint256 oldSeed = fluxSeeds[pool];
            fluxSeeds[pool] = seed;
            emit FluxSeedChanged(pool, oldSeed, seed);
        } else {
            emit GenesisMintWeightsChanged(pool, genesisWeights[pool], seed);
            genesisWeights[pool] = seed;
        }
    }

    function removePool(address pool) external onlyAppOrAdmin {
        uint256 oldSeed = fluxSeeds[pool];
        delete fluxSeeds[pool];
        emit FluxSeedChanged(pool, oldSeed, 0);
    }

    function claimDaoFlux() external {
        uint256 last = lastUnlockBlock;
        require(last < block.number, "REPEAT_UNLOCK");

        require(lastUnlockTime + FLUX_AUTO_UNLOCK_INTERVAL <= block.timestamp, "REPEAT_UNLOCK");
        _unlockDAOFlux();
    }

    function refreshFluxMintIndex(address pool, uint256 interestIndex) external onlyAppOrAdmin {
        _refreshFluxMintIndex(pool, TradeType.Borrow, interestIndex);
        _refreshFluxMintIndex(pool, TradeType.Supply, 0);
    }

    function _refreshFluxMintIndexAtMarket(address pool) private returns (uint256 interestIndex) {
        IMarket(pool).calcCompoundInterest();
        interestIndex = IMarket(pool).interestIndex();
        _refreshFluxMintIndex(pool, TradeType.Borrow, interestIndex);
        _refreshFluxMintIndex(pool, TradeType.Supply, 0);
    }


    function refreshPoolFluxMintIndex() external {
        require(msg.sender == tx.origin, "SENDER_NOT_HUMAN");

        FluxApp app = FluxApp(fluxAPP);
        {
            address[] memory list = app.getMarketList();
            for (uint256 i = 0; i < list.length; i++) {
                _refreshFluxMintIndexAtMarket(list[i]);
            }
        }

        {
            address[] memory pools = app.getStakePoolList();
            for (uint256 i = 0; i < pools.length; i++) {
                _refreshFluxMintIndex(pools[i], TradeType.Stake, 0);
            }
        }
    }


    function claimFlux() external {
        FluxApp app = FluxApp(fluxAPP);
        address sender = msg.sender;
        {
            address[] memory list = app.getMarketList();
            for (uint256 i = 0; i < list.length; i++) {
                (uint256 ftokens, uint256 borrows, ) = IMarket(list[i]).getAcctSnapshot(sender);
                if (ftokens == 0 && borrows == 0) {
                    continue;
                }
                uint256 interestIndex = _refreshFluxMintIndexAtMarket(list[i]);
                if (borrows > 0) _distributeFlux(list[i], TradeType.Borrow, sender, interestIndex);
                if (ftokens > 0) _distributeFlux(list[i], TradeType.Supply, sender, 0);
            }
        }

        {
            address[] memory pools = app.getStakePoolList();
            for (uint256 i = 0; i < pools.length; i++) {
                uint256 stake = IStake(pools[i]).balanceOf(sender);
                if (stake > 0) {
                    _refreshFluxMintIndex(pools[i], TradeType.Stake, 0);
                    _distributeFlux(pools[i], TradeType.Stake, sender, 0);
                }
            }
        }
        uint256 balance = remainFluxByUser[sender];
        remainFluxByUser[sender] = 0;

        _transferFluxToken(sender, balance);
    }

    function settleOnce(
        address pool,
        TradeType kind,
        address user
    ) external onlyAppOrAdmin {
        if (block.number < FLUX_START_BLOCK) {
            return;
        }

        uint256 index;
        if (kind == TradeType.Borrow) {
            index = IMarket(pool).interestIndex();
        }

        _refreshFluxMintIndex(pool, kind, index);
        _distributeFlux(pool, kind, user, index);
    }

    struct MintVars {
        address pool;
        TradeType kind;
        uint256 newIndex;
        uint256 factor;
        uint256 weights;
        uint256 seed;
        uint256 fluxMinted;
        uint256 height;
        uint256 low;
    }

    function _calcFluxMintIndex(
        address pool,
        TradeType kind,
        uint256 interestIndex
    )
        private
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        FluxMarketState storage state = fluxIndexState[pool][uint8(kind)];
        uint256 stateBlock = state.block;
        uint256 blockNumber = block.number;
        uint256 deltaBlocks = blockNumber.sub(stateBlock);
        if (deltaBlocks == 0) {
            return (state.index, 0, 0, 0, 0);
        }

        MintVars memory vars;
        vars.kind = kind;
        vars.pool = pool;
        vars.seed = fluxSeeds[vars.pool];

        (vars.height, vars.low) = splitTowWeight(vars.seed);

        if (vars.kind == TradeType.Borrow) {
            IMarket mkt = IMarket(vars.pool);
            vars.factor = interestIndex > 0 ? mkt.totalBorrows().mul(DECIMAL_UNIT).div(interestIndex) : 0;
            vars.weights = vars.height;
        } else if (vars.kind == TradeType.Supply) {
            vars.factor = IMarket(vars.pool).totalSupply();
            vars.weights = vars.low;
        } else if (vars.kind == TradeType.Stake) {
            vars.factor = IStake(vars.pool).totalSupply();
            vars.weights = vars.low;
        } else {
            revert("UNKNOWN_KIND");
        }

        if (vars.factor > 0) {
            uint256 base = fluxsMinedBase(stateBlock, blockNumber);
            uint256 poolMinted = base.mul(vars.weights);
            (uint256 genusis, uint256 poolGenusis) = _calcGenusisMinted(vars.pool, vars.kind, stateBlock, blockNumber);

            uint256 oldIndex = state.index;
            vars.newIndex = (poolMinted.add(poolGenusis)).div(vars.factor).add(oldIndex);
            vars.fluxMinted = base + genusis;
            return (vars.newIndex, vars.factor, vars.weights, vars.seed, vars.fluxMinted);
        } else {
            return (state.index, vars.factor, vars.weights, vars.seed, 0);
        }
    }

    function _calcGenusisMinted(
        address pool,
        TradeType kind,
        uint256 fromBlock,
        uint256 toBlock
    ) private view returns (uint256 mined, uint256 poolMinted) {
        mined = fluxsMinedGenusis(fromBlock, toBlock);
        if (mined == 0) {
            return (0, 0);
        }
        (uint256 height, uint256 low) = splitTowWeight(genesisWeights[pool]);
        uint256 weight;
        if (kind == TradeType.Borrow) {
            weight = height;
        } else if (kind == TradeType.Supply) {
            weight = low;
        } else if (kind == TradeType.Stake) {
            weight = low;
        }
        poolMinted = mined.mul(weight);
    }

    function _refreshFluxMintIndex(
        address pool,
        TradeType kind,
        uint256 interestIndex
    ) private {
        FluxMarketState storage state = fluxIndexState[pool][uint8(kind)];
        uint256 oldNumber = state.block;
        if (oldNumber == block.number) {
            return;
        }
        (uint256 newIndex, uint256 factor, uint256 weights, uint256 seed, uint256 fluxMinted) = _calcFluxMintIndex(pool, kind, interestIndex);
        uint256 oldIndex = state.index;
        state.index = newIndex;
        state.block = block.number;


        if (newIndex > 0 && defaultMintIndex[pool][uint8(kind)] == 0) {
            defaultMintIndex[pool][uint8(kind)] = newIndex;
        }
        emit FluxMintIndexChanged(pool, kind, oldNumber, block.number, factor, weights, seed, fluxMinted, oldIndex, newIndex);
    }

    function _unlockDAOFlux() private returns (bool) {
        uint256 minted = calcFluxsMined(lastUnlockBlock, block.number);

        (uint256 teamWeight, uint256 communityWeight) = splitTowWeight(fluxSeeds[TEAM_COMMUNITY_WEIGHT_SLOT]);

        uint256 teamAmount = minted.mul(teamWeight).div(DECIMAL_UNIT);
        uint256 communityAmount = minted.mul(communityWeight).div(DECIMAL_UNIT);

        lastUnlockTime = block.timestamp;
        lastUnlockBlock = block.number;
        address team = teamFluxReceive;
        address comm = communityFluxReceive;
        emit UnlockFlux(comm, communityAmount, communityWeight);
        emit UnlockFlux(team, teamAmount, teamWeight);

        if (teamAmount + communityAmount > 0) {
            uint256 balance = FLUX_TOKEN.balanceOf(address(this));
            require(teamAmount + communityAmount <= balance, "FLUXBALANCE_EXCEED");

            require(team != address(0), "TEAM_RECEIVER_IS_EMPTY");
            require(comm != address(0), "COMM_RECEIVER_IS_EMPTY");
            _transferFluxToken(team, teamAmount);
            _transferFluxToken(comm, communityAmount);
        }
    }


    function getFluxRewards(
        address pool,
        TradeType kind,
        address user
    ) external view returns (uint256 reward) {
        uint256 interestIndex;
        if (kind == TradeType.Borrow) {
            interestIndex = IMarket(pool).interestIndex();
        }
        (uint256 newIndex, , , , ) = _calcFluxMintIndex(pool, kind, interestIndex);
        reward = _calcRewardFlux(pool, kind, user, interestIndex, newIndex);
    }


    function _calcRewardFlux(
        address pool,
        TradeType kind,
        address user,
        uint256 interestIndex,
        uint256 currIndex
    ) private view returns (uint256 reward) {
        if (currIndex == 0) currIndex = fluxIndexState[pool][uint8(kind)].index;
        uint256 lastIndex = fluxMintIndex[pool][user][uint256(kind)];

        if (lastIndex < 1e10) {
            lastIndex = defaultMintIndex[pool][uint8(kind)];
            if (lastIndex < 1e7) {

                if (kind == TradeType.Supply && pool == address(0x29134d1700512920BE5BFF759ee4C1e26C311b81)) {
                    lastIndex = 727846813893710183245363;
                } else {
                    return 0;
                }
            }
        }

        uint256 settleIndex = currIndex.sub(lastIndex);
        if (settleIndex == 0) {
            return 0;
        }

        uint256 weights;
        if (kind == TradeType.Borrow) {
            IMarket mkt = IMarket(pool);


            weights = interestIndex > 0 ? mkt.borrowAmount(user).mul(DECIMAL_UNIT).div(interestIndex) : 0;
        } else if (kind == TradeType.Supply) {
            weights = IMarket(pool).balanceOf(user);
        } else if (kind == TradeType.Stake) {
            weights = IStake(pool).balanceOf(user);
        } else {
            revert("UNKNOWN_KIND");
        }
        if (weights == 0) {
            return 0;
        }


        reward = settleIndex.mul(weights).div(DECIMAL_UNIT);
    }

    function _distributeFlux(
        address pool,
        TradeType kind,
        address user,
        uint256 interestIndex
    ) private {

        uint256 distribution = _calcRewardFlux(pool, kind, user, interestIndex, 0);
        remainFluxByUser[user] = remainFluxByUser[user].add(distribution);
        uint256 index = fluxIndexState[pool][uint8(kind)].index;
        fluxMintIndex[pool][user][uint256(kind)] = index;
        emit DistributedFlux(pool, kind, user, distribution, index);
    }


    function getFluxsByBlock(uint256 blockNo) external view returns (uint256) {
        if (blockNo == 0) blockNo = block.number;
        return calcFluxsMined(blockNo, blockNo + 1);
    }


    function calcFluxsMined(uint256 fromBlock, uint256 endBlock) public pure virtual returns (uint256) {
        uint256 base = fluxsMinedBase(fromBlock, endBlock);
        uint256 genusis = fluxsMinedGenusis(fromBlock, endBlock);
        return base.add(genusis);
    }

    function fluxsMinedBase(uint256 fromBlock, uint256 endBlock) public pure virtual returns (uint256) {
        if (endBlock < FLUX_START_BLOCK || fromBlock > FLUX_END_BLOCK || endBlock <= fromBlock) return 0;
        if (fromBlock < FLUX_START_BLOCK) fromBlock = FLUX_START_BLOCK;
        uint256 end = endBlock - 1;
        if (endBlock > FLUX_END_BLOCK) end = FLUX_END_BLOCK - 1;


        uint256 sum;
        if (end >= fromBlock) {
            uint256 a1 = _fluxBlock(fromBlock);
            uint256 an = _fluxBlock(end);
            sum = ((a1 + an) * (end - fromBlock + 1)) / 2;
        }
        if (endBlock > FLUX_END_BLOCK) sum += FLUX_LAST_BLOCK;

        return sum;
    }

    function fluxsMinedGenusis(uint256 fromBlock, uint256 endBlock) public pure virtual returns (uint256) {
        if (endBlock < FLUX_START_BLOCK || fromBlock > GENESISMINING_ENDTIME || endBlock <= fromBlock) return 0;
        if (fromBlock < FLUX_START_BLOCK) fromBlock = FLUX_START_BLOCK;
        uint256 blocks = endBlock <= GENESISMINING_ENDTIME ? endBlock - fromBlock : GENESISMINING_ENDTIME - fromBlock;
        return blocks.mul(GENESISMINING_ONEBLOCK);
    }

    function _fluxBlock(uint256 _block) private pure returns (uint256) {
        return FLUX_FIRST_BLOCK - (_block - FLUX_START_BLOCK) * FLUX_PER_BLOCK_DEC;
    }

    function _transferFluxToken(address receiver, uint256 amount) private {
        require(FLUX_TOKEN.transfer(receiver, amount), "TRANSDFER_FAILED");
    }

    function getPoolSeed(address pool) external view returns (uint256 height, uint256 low) {
        return splitTowWeight(fluxSeeds[pool]);
    }

    function getGenesisWeight(address pool) external view returns (uint256 height, uint256 low) {
        return splitTowWeight(genesisWeights[pool]);
    }

    function splitTowWeight(uint256 value) public pure returns (uint256 height, uint256 low) {
        height = value >> 128;
        low = uint256(value << 128) >> 128;


        require(height < DECIMAL_UNIT && low < DECIMAL_UNIT, "INVALID_WEIGHT");
    }

    function connectTwoUint128(uint128 a, uint128 b) public pure returns (uint256) {

        uint256 a2 = uint256(a) << 128;
        return a2 + uint256(b);
    }
}

interface IFluxApp {
    function IS_FLUX() external view returns (bool);

    function configs(string calldata key) external view returns (uint256);


    function marketStatus(IMarket market) external view returns (uint256 ratio, MarketStatus status);


    function getAcctSnapshot(address acct)
        external
        view
        returns (
            uint256 supplyValueMan,
            uint256 borrowValueMan,
            uint256 borrowLimitMan
        );


    function liquidateAllowed(address borrower) external view returns (bool yes);


    function mktCount() external view returns (uint256);


    function mktExist(IMarket mkt) external view returns (bool);

    function getJoinedMktInfoAt(address acct, uint256 index) external view returns (IMarket mkt, uint256 collRatioMan);

    function getAcctJoinedMktCount(address acct) external;


    function redeemAllowed(
        address acct,
        address mkt,
        uint256 ftokens
    ) external view;

    function borrowAllowed(
        address borrower,
        address market,
        uint256 ctokens
    ) external view;


    function beforeSupply(
        address,
        address market,
        uint256
    ) external view;

    function beforeTransferLP(
        address market,
        address from,
        address to,
        uint256 amount
    ) external;


    function beforeBorrow(
        address borrower,
        address market,
        uint256 ctokens
    ) external;


    function beforeRedeem(
        address redeemer,
        address market,
        uint256 ftokens
    ) external view;

    function beforeRepay(
        address borrower,
        address market,
        uint256
    ) external;

    function beforeLiquidate(
        address,
        address borrower,
        uint256
    ) external;


    function getBorrowLimit(IMarket mkt, address acct) external view returns (uint256 limit, uint256 cash);


    function getWithdrawLimit(IMarket mkt, address acct) external view returns (uint256 limit, uint256 cash);




    function refreshMarkeFluxSeed() external;



    function beforeStake(address user) external;

    function beforeUnStake(address user) external;


    function getMarketList() external view returns (address[] memory list);

    function getStakePoolList() external view returns (address[] memory list);

    function getFluxTeamIncomeAddress() external view returns (address);





    function killAllowed(address borrower) external view returns (bool yes);


    function setAcctMarket(address acct, bool join) external;
}

library PubContract {
    function getERC1820RegistryAddress() internal view returns (address) {
        return isConflux() ? 0x88887eD889e776bCBe2f0f9932EcFaBcDfCd1820 : 0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24;
    }

    function isConflux() internal view returns (bool) {
        uint32 size;


        assembly {

            size := extcodesize(0x8A3A92281Df6497105513B18543fd3B60c778E40)
        }
        return (size > 0);
    }
}

library Blocks {
    uint256 public constant DAY = 28800;
    uint256 public constant YEAR = DAY * 365;
}

contract FToken is Context, IERC20 {
    using MySafeMath for uint256;
    using Address for address;

    mapping(address => uint256) internal _balances;

    mapping(address => mapping(address => uint256)) internal _allowances;

    uint256 internal _totalSupply;

    string internal _name;
    string internal _symbol;
    uint8 internal _decimals;


    function name() external view returns (string memory) {
        return _name;
    }


    function symbol() external view returns (string memory) {
        return _symbol;
    }


    function decimals() external view returns (uint8) {
        return _decimals;
    }


    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }


    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }


    function transfer(address recipient, uint256 amount) external virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount, false);
        return true;
    }


    function allowance(address owner, address spender) external view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }


    function approve(address spender, uint256 amount) external virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }


    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external virtual override returns (bool) {
        _transfer(sender, recipient, amount, false);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "FTOKEN: transfer amount exceeds allowance"));
        return true;
    }


    function increaseAllowance(address spender, uint256 addedValue) external virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }


    function decreaseAllowance(address spender, uint256 subtractedValue) external virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "FTOKEN: decreased allowance below zero"));
        return true;
    }


    function _transfer(
        address sender,
        address recipient,
        uint256 amount,
        bool disableBeforeCall
    ) internal virtual {
        require(sender != address(0), "FTOKEN: transfer from the zero address");
        require(recipient != address(0), "FTOKEN: transfer to the zero address");
        if (!disableBeforeCall) {
            _beforeTokenTransfer(sender, recipient, amount);
        }

        _balances[sender] = _balances[sender].sub(amount, "FTOKEN: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);

        _afterTokenTransfer(sender, recipient, amount);

        emit Transfer(sender, recipient, amount);
    }


    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "FTOKEN: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        _afterTokenTransfer(address(0), account, amount);
        emit Transfer(address(0), account, amount);
    }


    function _burn(
        address account,
        uint256 amount,
        bool callBefore
    ) internal virtual {
        require(account != address(0), "FTOKEN: burn from the zero address");

        if (callBefore) {
            _beforeTokenTransfer(account, address(0), amount);
        }
        _balances[account] = _balances[account].sub(amount, "FTOKEN: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        _afterTokenTransfer(account, address(0), amount);
        emit Transfer(account, address(0), amount);
    }


    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "FTOKEN: approve from the zero address");
        require(spender != address(0), "FTOKEN: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }


    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }


    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}


    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

interface IFluxCross {
    function deposit(
        uint64 tragetChain,
        address receiver,
        address token,
        uint256 amount,
        uint256 maxFluxFee
    ) external payable;

    function withdraw(
        uint64 tragetChain,
        address receiver,
        address token,
        uint256 amount,
        uint256 maxFluxFee
    ) external payable;
}

abstract contract ReentrancyGuard {











    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () internal {
        _status = _NOT_ENTERED;
    }


    modifier nonReentrant() {

        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");


        _status = _ENTERED;

        _;



        _status = _NOT_ENTERED;
    }
}

abstract contract Market is Initializable, Ownable, FToken, ReentrancyGuard, MarketStorage {
    using MySafeMath for uint256;
    using Exponential for Exp;
    using SafeERC20 for IERC20;

    string private constant CONFIG_TAX_RATE = "MKT_BORROW_INTEREST_TAX_RATE";
    uint256 private constant MAX_LIQUIDATE_FEERATE = 0.1 * 1e18;


    event Supply(address indexed supplyer, uint256 ctokens, uint256 ftokens, uint256 balance);


    event Redeem(address indexed redeemer, string receiver, uint256 ftokens, uint256 ctokens);


    event Borrow(address indexed borrower, string receiver, uint256 ctokens, uint256 borrows, uint256 totalBorrows);


    event Repay(address indexed repayer, uint256 repaid, uint256 borrows, uint256 totalBorrows);


    event Liquidated(address indexed liquidator, address indexed borrower, uint256 supplies, uint256 borrows);
    event ChangeOracle(IPriceOracle oldValue, IPriceOracle newValue);


    function initialize(
        address guard_,
        address oracle_,
        address interestRateModel_,
        address underlying_,
        string calldata name_,
        string calldata symbol_
    ) external initializer {
        _name = name_;
        _symbol = symbol_;
        _decimals = INormalERC20(underlying_).decimals();
        interestIndex = 1e18;
        initialExchangeRateMan = 1e18;
        lastAccrueInterest = block.number;

        underlying = IERC20(underlying_);
        guard = IGuard(guard_);
        app = IFluxApp(guard.flux());
        oracle = IPriceOracle(oracle_);
        interestRateModel = IRModel(interestRateModel_);

        initOwner(guard.owner());


        uint256 price = underlyingPrice();
        bool ye = app.IS_FLUX();
        uint256 rate = getBorrowRate();
        require(price > 0, "UNDERLYING_PRICE_IS_ZERO");
        require(ye, "REQUIRE_FLUX");
        require(rate > 0, "BORROW_RATE_IS_ZERO");
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        app.beforeTransferLP(address(this), from, to, amount);
    }

    function _afterTokenTransfer(
        address from,
        address to,
        uint256
    ) internal override {
        if (from != address(0)) {
            _updateJoinStatus(from);
        }
        if (to != address(0)) {
            _updateJoinStatus(to);
        }
    }


    function changeOracle(IPriceOracle oracle_) external onlyOwner {
        emit ChangeOracle(oracle, oracle_);
        oracle = oracle_;

        underlyingPrice();
    }


    function cashPrior() public view virtual returns (uint256) {
        return underlying.balanceOf(address(this));
    }

    function underlyingTransferIn(address sender, uint256 amount) internal virtual returns (uint256 actualAmount);

    function underlyingTransferOut(address receipt, uint256 amount) internal virtual returns (uint256 actualAmount);

    function getBorrowRate() internal view returns (uint256 rateMan) {
        return interestRateModel.borrowRate(cashPrior(), totalBorrows, 0);
    }



    function calcCompoundInterest() public virtual {




        uint256 currentNumber = block.number;
        uint256 times = currentNumber.sub(lastAccrueInterest);

        if (times == 0) {
            return;
        }
        uint256 oldBorrows = totalBorrows;
        uint256 reserves = taxBalance;


        interestRateModel.execute(cashPrior(), oldBorrows, reserves);

        Exp memory rate = Exp(getBorrowRate()).mulScalar(times);
        uint256 oldIndex = interestIndex;
        uint256 interest = rate.mulScalarTruncate(oldBorrows);

        uint256 taxRate = getTaxRate();

        taxBalance = reserves.add(interest.mul(taxRate).div(1e18));

        totalBorrows = oldBorrows.add(rate.mulScalarTruncate(oldBorrows));
        interestIndex = oldIndex.add(rate.mulScalarTruncate(oldIndex));
        lastAccrueInterest = currentNumber;
    }

    function getTaxRate() public view returns (uint256 taxRate) {
        string memory key = string(abi.encodePacked("TAX_RATE_", _symbol));
        taxRate = app.configs(key);
        if (taxRate == 0) {
            taxRate = app.configs(CONFIG_TAX_RATE);
        }
    }

    function _supply(address minter, uint256 ctokens) internal nonReentrant {
        require(borrowBalanceOf(minter) == 0, "YOU_HAVE_BORROW");

        require(ctokens > 0, "SUPPLY_IS_ZERO");
        calcCompoundInterest();

        app.beforeSupply(minter, address(this), ctokens);

        require(underlyingTransferIn(msg.sender, ctokens) == ctokens, "TRANSFER_INVLIAD_AMOUNT");

        _mintStorage(minter, ctokens);
    }

    function _mintStorage(address minter, uint256 ctokens) private {
        Exp memory exchangeRate = Exp(_exchangeRate(ctokens));
        require(!exchangeRate.isZero(), "EXCHANGERATE_IS_ZERO");
        uint256 ftokens = Exponential.divScalarByExpTruncate(ctokens, exchangeRate);
        ftokens = ftokens == 0 && ctokens > 0 ? 1 : ftokens;
        _mint(minter, ftokens);
        emit Supply(minter, ctokens, ftokens, balanceOf(minter));
    }


    function _redeem(
        address redeemer,
        address to,
        uint256 amount,
        bool isWithdraw
    ) internal nonReentrant returns (uint256 actual) {
        calcCompoundInterest();

        uint256 ftokens;
        uint256 ctokenAmount;

        Exp memory exchangeRate = Exp(exchangeRate());
        require(!exchangeRate.isZero(), "EXCHANGERATE_IS_ZERO");



        if (isWithdraw && amount > 0) {
            ctokenAmount = amount;
            ftokens = Exponential.divScalarByExpTruncate(ctokenAmount, exchangeRate);
            ftokens = ftokens == 0 && ctokenAmount > 0 ? 1 : ftokens;
        } else {

            ftokens = amount == 0 ? balanceOf(redeemer) : amount;
            ctokenAmount = exchangeRate.mulScalarTruncate(ftokens);
            ctokenAmount = ftokens > 0 && ctokenAmount == 0 ? 1 : ctokenAmount;
        }



        _burn(redeemer, ftokens, isWithdraw);
        require(underlyingTransferOut(to, ctokenAmount) == ctokenAmount, "INVALID_TRANSFER_OUT");



        emit Redeem(redeemer, "", ftokens, ctokenAmount);
        return ctokenAmount;
    }


    function _borrow(address to, uint256 ctokens) internal nonReentrant {
        address borrower = msg.sender;
        require(balanceOf(borrower) == 0, "YOUR_HAVE_SUPPLY");

        calcCompoundInterest();

        require(ctokens >= 10**(uint256((_decimals * 2) / 5 + 1)), "BORROWS_TOO_SMALL");



        app.beforeBorrow(borrower, address(this), ctokens);

        totalBorrows = totalBorrows.add(ctokens);
        uint256 borrowsNew = borrowBalanceOf(borrower).add(ctokens);
        _borrowStorage(borrower, borrowsNew);

        require(underlyingTransferOut(to, ctokens) == ctokens, "INVALID_TRANSFER_OUT");
        emit Borrow(borrower, "", ctokens, borrowsNew, totalBorrows);
    }

    function _repay(address repayer, uint256 ctokens) internal {

        _repayFor(repayer, repayer, ctokens);
    }


    function _repayFor(
        address repayer,
        address borrower,
        uint256 ctokens
    ) internal nonReentrant {
        calcCompoundInterest();

        app.beforeRepay(repayer, address(this), ctokens);
        require(_repayBorrows(repayer, borrower, ctokens) > 0, "REPAY_IS_ZERO");
    }


    function _repayBorrows(
        address repayer,
        address borrower,
        uint256 repays
    ) private returns (uint256 actualRepays) {
        uint256 borrowsOld = borrowBalanceOf(borrower);
        if (borrowsOld == 0) {
            return 0;
        }

        if (repays == 0) {
            repays = actualRepays = borrowsOld;
        } else {
            actualRepays = MySafeMath.min(repays, borrowsOld);
        }

        require(underlyingTransferIn(repayer, actualRepays) == actualRepays, "TRANSFER_INVLIAD_AMOUNT");

        totalBorrows = totalBorrows.sub(actualRepays);
        uint256 borrowsNew = borrowsOld - actualRepays;
        _borrowStorage(borrower, borrowsNew);
        emit Repay(borrower, actualRepays, borrowsNew, totalBorrows);
    }


    function _borrowStorage(address borrower, uint256 borrowsNew) private {
        if (borrowsNew == 0) {
            delete userFounds[borrower];
            return;
        }
        CheckPoint storage user = userFounds[borrower];
        user.interestIndex = interestIndex;
        user.borrows = borrowsNew;
        _updateJoinStatus(borrower);
    }

    function liquidatePrepare(address borrower)
        external
        returns (
            IERC20 asset,
            uint256 ftokens,
            uint256 borrows
        )
    {
        calcCompoundInterest();
        asset = underlying;
        ftokens = balanceOf(borrower);
        borrows = borrowBalanceOf(borrower);
    }


    function liquidate(
        address liquidator,
        address borrower,
        address feeCollector,
        uint256 feeRate
    ) external returns (bool ok) {
        address guardAddr = address(guard);
        require(msg.sender == guardAddr, "LIQUIDATE_INVALID_CALLER");

        require(liquidator != borrower, "LIQUIDATE_DISABLE_YOURSELF");

        calcCompoundInterest();

        uint256 ftokens = balanceOf(borrower);
        uint256 borrows = borrowBalanceOf(borrower);


        if (borrows > 0) {
            require(underlyingTransferIn(msg.sender, borrows) == borrows, "TRANSFER_INVLIAD_AMOUNT");
            totalBorrows = totalBorrows.sub(borrows);
            _borrowStorage(borrower, 0);
        }


        uint256 supplies;
        if (ftokens > 0) {
            require(feeRate <= MAX_LIQUIDATE_FEERATE, "INVALID_FEERATE");
            Exp memory exchangeRate = Exp(exchangeRate());
            supplies = exchangeRate.mulScalarTruncate(ftokens);
            require(cashPrior() >= supplies, "MARKET_CASH_INSUFFICIENT");

            _burn(borrower, ftokens, false);
            uint256 fee = supplies.mul(feeRate).div(1e18);
            underlyingTransferOut(liquidator, supplies.sub(fee));
            if (fee > 0) {
                if (feeCollector != address(0)) {
                    uint256 feeHalf = fee / 2;
                    underlyingTransferOut(feeCollector, fee - feeHalf);
                    underlyingTransferOut(guardAddr, feeHalf);
                } else {
                    underlyingTransferOut(guardAddr, fee);
                }
            }
        }
        emit Liquidated(liquidator, borrower, supplies, borrows);
        return true;
    }


    function killLoan(address borrower) external returns (uint256 supplies, uint256 borrows) {
        address guardAddr = address(guard);

        require(msg.sender == guardAddr, "MARGINCALL_INVALID_CALLER");
        require(guardAddr != borrower, "DISABLE_KILL_GURAD");


        calcCompoundInterest();


        uint256 ftokens = balanceOf(borrower);

        app.beforeLiquidate(msg.sender, borrower, ftokens);

        if (ftokens > 0) {
            Exp memory exchangeRate = Exp(exchangeRate());
            supplies = exchangeRate.mulScalarTruncate(ftokens);

            uint256 cash = cashPrior();
            if (cash < supplies) {

                _transfer(borrower, guardAddr, ftokens, false);
            } else {
                _burn(borrower, ftokens, false);
                underlyingTransferOut(guardAddr, supplies);
            }
        }

        borrows = borrowBalanceOf(borrower);
        if (borrows > 0) {
            _borrowStorage(borrower, 0);
            _borrowStorage(guardAddr, borrowBalanceOf(guardAddr).add(borrows));
        }
        if (borrows > 0 || supplies > 0) {
            emit Liquidated(guardAddr, borrower, supplies, borrows);
        }
    }


    function _updateJoinStatus(address acct) internal {
        app.setAcctMarket(acct, balanceOf(acct) > 0 || borrowBalanceOf(acct) > 0);
    }




    function getAPY()
        external
        view
        returns (
            uint256 borrowRate,
            uint256 supplyRate,
            uint256 utilizationRate
        )
    {
        uint256 taxRate = getTaxRate();
        uint256 balance = cashPrior();

        uint256 blockBorrowRate = interestRateModel.borrowRate(balance, totalBorrows, 0);
        uint256 blockSupplyRate = interestRateModel.supplyRate(balance, totalSupply(), totalBorrows, 0);
        blockSupplyRate = blockSupplyRate.mul(1e18 - taxRate).div(1e18);
        utilizationRate = interestRateModel.utilizationRate(balance, totalBorrows, 0);

        return (blockBorrowRate.mul(Blocks.YEAR), blockSupplyRate.mul(Blocks.YEAR), utilizationRate);
    }


    function interestPreDay()
        external
        view
        returns (
            uint256 supplyRate,
            uint256 borrowRate,
            uint256 utilizationRate
        )
    {
        uint256 taxRate = getTaxRate();
        uint256 balance = cashPrior();

        uint256 borrows = totalBorrows;
        IRModel rmodel = interestRateModel;
        uint256 blockBorrowRate = rmodel.borrowRate(balance, borrows, 0);
        uint256 blockSupplyRate = rmodel.supplyRate(balance, totalSupply(), borrows, 0);
        uint256 units = 1e18;
        blockSupplyRate = blockSupplyRate.mul(units.sub(taxRate)).div(units);
        borrowRate = blockBorrowRate.mul(Blocks.DAY);
        supplyRate = blockSupplyRate.mul(Blocks.DAY);
        utilizationRate = rmodel.utilizationRate(balance, borrows, 0);
    }



    function exchangeRate() public view virtual returns (uint256) {
        return _exchangeRate(0);
    }


    function _exchangeRate(uint256 ctokens) private view returns (uint256) {
        uint256 totalSupply_ = totalSupply();
        if (totalSupply_ == 0) {

            return initialExchangeRateMan;
        }




        uint256 totalCash = cashPrior();
        totalCash = totalCash.sub(ctokens);
        uint256 cTokenAmount = totalCash.add(totalBorrows).sub(taxBalance);
        uint256 rate = Exponential.get(cTokenAmount, totalSupply_).mantissa;
        if (rate == 0) {
            return initialExchangeRateMan;
        }
        return rate;
    }


    function borrowBalanceOf(address acct) public view returns (uint256) {

        CheckPoint storage borrower = userFounds[acct];
        uint256 borrows = borrower.borrows;
        if (borrows == 0) {
            return 0;
        }
        uint256 index = borrower.interestIndex;
        if (index == 0) {
            return borrows;
        }
        Exp memory rate = Exponential.get(interestIndex, index);
        return rate.mulScalarTruncate(borrows);
    }


    function getAcctSnapshot(address acct)
        external
        view
        returns (
            uint256 ftokens,
            uint256 borrows,
            uint256 xrate
        )
    {
        return (balanceOf(acct), borrowBalanceOf(acct), exchangeRate());
    }


    struct CalcVars {
        uint256 supplies;
        uint256 borrows;
        uint256 priceMan;
        Exp borrowLimit;
        Exp supplyValue;
        Exp borrowValue;
    }


    function accountValues(
        address acct,
        uint256 collRatioMan,
        uint256 addBorrows,
        uint256 subSupplies
    )
        external
        view
        returns (
            uint256 supplyValueMan,
            uint256 borrowValueMan,
            uint256 borrowLimitMan
        )
    {
        CalcVars memory vars;


        vars.supplies = balanceOf(acct).sub(subSupplies, "TOKEN_INSUFFICIENT_BALANCE");

        vars.borrows = borrowBalanceOf(acct).add(addBorrows);
        if (vars.supplies == 0 && vars.borrows == 0) {
            return (0, 0, 0);
        }




        vars.priceMan = underlyingPrice();
        require(vars.priceMan > 0, "MARKET_ZERO_PRICE");

        if (vars.supplies > 0) {




            supplyValueMan = exchangeRate().mul(vars.supplies).mul(vars.priceMan).div(10**(18 + uint256(_decimals)));

            borrowLimitMan = supplyValueMan.mul(1e18).div(collRatioMan);
        }
        if (vars.borrows > 0) {


            borrowValueMan = vars.priceMan.mul(vars.borrows).div(10**uint256(_decimals));
        }
    }

    function underlyingPrice() public view returns (uint256) {
        return oracle.getPriceMan(address(underlying));
    }

    function isFluxMarket() external pure returns (bool) {
        return true;
    }

    function borrowAmount(address acct) external view returns (uint256) {
        return userFounds[acct].borrows;
    }


    function withdrawTax() external {
        address receiver = app.getFluxTeamIncomeAddress();
        require(receiver != address(0), "RECEIVER_IS_EMPTY");
        uint256 tax = taxBalance;
        require(tax > 0, "TAX_IS_ZERO");
        taxBalance = 0;
        require(underlyingTransferOut(receiver, tax) == tax, "TAX_TRANSFER_FAILED");
    }

    function enableCross(address fluxCrossHandler) external onlyOwner {
        fluxCross = fluxCrossHandler;
    }


    function crossRefinance(
        uint64 tragetChainId,
        uint256 amount,
        uint256 maxFluxFee
    ) external payable {
        address cross = fluxCross;
        require(cross != address(0), "CROSS_NOT_READY");
        uint256 actualAmount = _redeem(msg.sender, cross, amount, true);
        IFluxCross(cross).deposit{ value: msg.value }(tragetChainId, msg.sender, address(underlying), actualAmount, maxFluxFee);
    }

    function crossRedeem(
        uint64 tragetChainId,
        uint256 amount,
        uint256 maxFluxFee
    ) external payable {
        address cross = fluxCross;
        require(cross != address(0), "CROSS_NOT_READY");
        uint256 actualAmount = _redeem(msg.sender, cross, amount, true);
        IFluxCross(cross).withdraw{ value: msg.value }(tragetChainId, msg.sender, address(underlying), actualAmount, maxFluxFee);
    }

    function crossBorrow(
        uint64 tragetChainId,
        uint256 amount,
        uint256 maxFluxFee
    ) external payable {
        address cross = fluxCross;
        require(cross != address(0), "CROSS_NOT_READY");
        _borrow(cross, amount);
        IFluxCross(cross).withdraw{ value: msg.value }(tragetChainId, msg.sender, address(underlying), amount, maxFluxFee);
    }
}

interface IWrappedHT {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function withdraw(uint256 wad) external;

    function deposit() external payable;
}

contract WithdrawProxy {
    function withdrawTo(
        IWrappedHT wht,
        address to,
        uint256 amount
    ) external {
        wht.transferFrom(msg.sender, address(this), amount);
        wht.withdraw(amount);
        address payable user = address(uint160(to));
        user.transfer(amount);
    }

    receive() external payable {}
}

contract MarketCFX is Market, IMarketPayable {
    event WithdrawProxyChanged(address oldValue, address newValue);

    function initWithdrawProxy(WithdrawProxy wp) external onlyOwner {
        emit WithdrawProxyChanged(address(withdrawProxy), address(wp));
        withdrawProxy = address(wp);
        underlying.safeApprove(withdrawProxy, type(uint256).max);
    }


    function mint() external payable override {
        _supply(msg.sender, msg.value);
    }


    function redeem(uint256 ctokens) external override {
        _redeem(msg.sender, msg.sender, ctokens, true);
    }

    function borrow(uint256 ctokens) external override {
        _borrow(msg.sender, ctokens);
    }

    function repay(uint256 amount) external {
        _repay(msg.sender, amount);
    }

    function repay() external payable override {
        require(msg.value > 0, "REPAY_IS_ZERO");
        _repay(msg.sender, msg.value);
    }

    function underlyingTransferIn(address from, uint256 amount) internal override returns (uint256) {
        if (msg.value == 0) {

            underlying.safeTransferFrom(from, address(this), amount);
        } else {
            require(msg.value >= amount && amount > 0, "INVALID_UNDERLYING_TRANSFER");

            if (msg.value > amount) {
                payable(from).transfer(msg.value - amount);
            }

            IWrappedHT(address(underlying)).deposit{ value: amount }();
        }
        return amount;
    }

    function underlyingTransferOut(address receipt, uint256 amount) internal override returns (uint256) {
        IERC20 underlyingToken = underlying;

        require(underlyingToken.balanceOf(address(this)) >= amount, "CASH_EXECEEDS");

        if (receipt == address(guard)) {

            underlyingToken.safeTransfer(receipt, amount);
        } else {

            IWrappedHT token = IWrappedHT(address(underlyingToken));
            WithdrawProxy(withdrawProxy).withdrawTo(token, receipt, amount);
        }
        return amount;
    }

    function withdraw(address to, uint256 ctokens) external {
        require(to != address(0), "address is empty");
        _redeem(msg.sender, to, ctokens, true);
    }

    receive() external payable {
        _supply(msg.sender, msg.value);
    }
}