// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

interface IOwnable {
    function policy() external view returns (address);

    function renounceManagement() external;

    function pushManagement( address newOwner_ ) external;

    function pullManagement() external;
}

contract Ownable is IOwnable {

    address internal _owner;
    address internal _newOwner;

    event OwnershipPushed(address indexed previousOwner, address indexed newOwner);
    event OwnershipPulled(address indexed previousOwner, address indexed newOwner);

    constructor () {
        _owner = msg.sender;
        emit OwnershipPushed( address(0), _owner );
    }

    function policy() public view override returns (address) {
        return _owner;
    }

    modifier onlyPolicy() {
        require( _owner == msg.sender, "Ownable: caller is not the owner" );
        _;
    }

    function renounceManagement() public virtual override onlyPolicy() {
        emit OwnershipPushed( _owner, address(0) );
        _owner = address(0);
    }

    function pushManagement( address newOwner_ ) public virtual override onlyPolicy() {
        require( newOwner_ != address(0), "Ownable: new owner is the zero address");
        emit OwnershipPushed( _owner, newOwner_ );
        _newOwner = newOwner_;
    }

    function pullManagement() public virtual override {
        require( msg.sender == _newOwner, "Ownable: must be new owner to pull");
        emit OwnershipPulled( _owner, _newOwner );
        _owner = _newOwner;
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

    function sqrrt(uint256 a) internal pure returns (uint c) {
        if (a > 3) {
            c = a;
            uint b = add( div( a, 2), 1 );
            while (b < c) {
                c = b;
                b = div( add( div( a, b ), b), 2 );
            }
        } else if (a != 0) {
            c = 1;
        }
    }
}

library Address {

    function isContract(address account) internal view returns (bool) {

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }

    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
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

    function addressToString(address _address) internal pure returns(string memory) {
        bytes32 _bytes = bytes32(uint256(_address));
        bytes memory HEX = "0123456789abcdef";
        bytes memory _addr = new bytes(42);

        _addr[0] = '0';
        _addr[1] = 'x';

        for(uint256 i = 0; i < 20; i++) {
            _addr[2+i*2] = HEX[uint8(_bytes[i + 12] >> 4)];
            _addr[3+i*2] = HEX[uint8(_bytes[i + 12] & 0x0f)];
        }

        return string(_addr);

    }
}

interface IERC20 {
    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

abstract contract ERC20 is IERC20 {

    using SafeMath for uint256;

    // TODO comment actual hash value.
    bytes32 constant private ERC20TOKEN_ERC1820_INTERFACE_ID = keccak256( "ERC20Token" );

    mapping (address => uint256) internal _balances;

    mapping (address => mapping (address => uint256)) internal _allowances;

    uint256 internal _totalSupply;

    string internal _name;

    string internal _symbol;

    uint8 internal _decimals;

    constructor (string memory name_, string memory symbol_, uint8 decimals_) {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
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

    function _mint(address account_, uint256 ammount_) internal virtual {
        require(account_ != address(0), "ERC20: mint to the zero address");
        _beforeTokenTransfer(address( this ), account_, ammount_);
        _totalSupply = _totalSupply.add(ammount_);
        _balances[account_] = _balances[account_].add(ammount_);
        emit Transfer(address( this ), account_, ammount_);
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

    function _beforeTokenTransfer( address from_, address to_, uint256 amount_ ) internal virtual { }
}

interface IERC2612Permit {

    function permit(
        address owner,
        address spender,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function nonces(address owner) external view returns (uint256);
}

library Counters {
    using SafeMath for uint256;

    struct Counter {

        uint256 _value; // default: 0
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

abstract contract ERC20Permit is ERC20, IERC2612Permit {
    using Counters for Counters.Counter;

    mapping(address => Counters.Counter) private _nonces;

    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 public constant PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;

    bytes32 public DOMAIN_SEPARATOR;

    constructor() {
        uint256 chainID;
        assembly {
            chainID := chainid()
        }

        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes(name())),
                keccak256(bytes("1")), // Version
                chainID,
                address(this)
            )
        );
    }

    function permit(
        address owner,
        address spender,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual override {
        require(block.timestamp <= deadline, "Permit: expired deadline");

        bytes32 hashStruct =
        keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, amount, _nonces[owner].current(), deadline));

        bytes32 _hash = keccak256(abi.encodePacked(uint16(0x1901), DOMAIN_SEPARATOR, hashStruct));

        address signer = ecrecover(_hash, v, r, s);
        require(signer != address(0) && signer == owner, "ZeroSwapPermit: Invalid signature");

        _nonces[owner].increment();
        _approve(owner, spender, amount);
    }

    function nonces(address owner) public view override returns (uint256) {
        return _nonces[owner].current();
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
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

library FullMath {
    function fullMul(uint256 x, uint256 y) private pure returns (uint256 l, uint256 h) {
        uint256 mm = mulmod(x, y, uint256(-1));
        l = x * y;
        h = mm - l;
        if (mm < l) h -= 1;
    }

    function fullDiv(
        uint256 l,
        uint256 h,
        uint256 d
    ) private pure returns (uint256) {
        uint256 pow2 = d & -d;
        d /= pow2;
        l /= pow2;
        l += h * ((-pow2) / pow2 + 1);
        uint256 r = 1;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        return l * r;
    }

    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 d
    ) internal pure returns (uint256) {
        (uint256 l, uint256 h) = fullMul(x, y);
        uint256 mm = mulmod(x, y, d);
        if (mm > l) h -= 1;
        l -= mm;
        require(h < d, 'FullMath::mulDiv: overflow');
        return fullDiv(l, h, d);
    }
}
/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () internal {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

library FixedPoint {

    struct uq112x112 {
        uint224 _x;
    }

    struct uq144x112 {
        uint256 _x;
    }

    uint8 private constant RESOLUTION = 112;
    uint256 private constant Q112 = 0x10000000000000000000000000000;
    uint256 private constant Q224 = 0x100000000000000000000000000000000000000000000000000000000;
    uint256 private constant LOWER_MASK = 0xffffffffffffffffffffffffffff; // decimal of UQ*x112 (lower 112 bits)

    function decode(uq112x112 memory self) internal pure returns (uint112) {
        return uint112(self._x >> RESOLUTION);
    }

    function decode112with18(uq112x112 memory self) internal pure returns (uint) {

        return uint(self._x) / 5192296858534827;
    }

    function fraction(uint256 numerator, uint256 denominator) internal pure returns (uq112x112 memory) {
        require(denominator > 0, 'FixedPoint::fraction: division by zero');
        if (numerator == 0) return FixedPoint.uq112x112(0);

        if (numerator <= uint144(-1)) {
            uint256 result = (numerator << RESOLUTION) / denominator;
            require(result <= uint224(-1), 'FixedPoint::fraction: overflow');
            return uq112x112(uint224(result));
        } else {
            uint256 result = FullMath.mulDiv(numerator, Q112, denominator);
            require(result <= uint224(-1), 'FixedPoint::fraction: overflow');
            return uq112x112(uint224(result));
        }
    }
}

interface ITreasury {
    function deposit( uint _amount, address _token, uint _profit ) external returns ( uint send_ );
    function valueOf( address _token, uint _amount ) external view returns ( uint value_ );
}

interface IBondCalculator {
    function valuation( address _LP, uint _amount ) external view returns ( uint );
    function markdown( address _LP ) external view returns ( uint );
}

interface IsFHM {
    function balanceForGons( uint gons ) external view returns ( uint );
    function gonsForBalance( uint amount ) external view returns ( uint );
}

interface IStakingWarmupManager {
    function stake( uint _amount, address _recipient ) external returns ( bool );
    function claim( address _recipient ) external;
    function getEpochNumber() external view returns (uint);
}

interface IUSDBMinter {
    function getMarketPrice() external view returns (uint);
}

interface IFHMCirculatingSupply {
    function OHMCirculatingSupply() external view returns ( uint );
}
interface IwsFHM {
    function wrap(uint _amount) external returns (uint);
    function unwrap(uint _amount) external returns (uint);
    function sFHMValue(uint _amount) external view returns (uint);
    function wsFHMValue(uint _amount) external view returns (uint);
}
interface IStakingStaking {
    function deposit(address _user, uint _amount) external;
    function withdraw(address _to, uint256 _amount, bool _force) external;
    function claim(uint _claimPageSize) external;
    function userBalance(address _user) external view returns (uint, uint, uint);
}

contract BondStakingStakingDepository is Ownable, ReentrancyGuard {

    using FixedPoint for *;
    using SafeERC20 for IERC20;
    using SafeMath for uint;




    /* ======== EVENTS ======== */

    event BondCreated( address indexed recipient, uint _tokenDeposited, uint _fhmDeposited, uint _wsfhmDeposited, uint _fhmInWarmup, uint _wsfhmInWarmup, uint indexed priceInUSD );
    event BondMoved( address indexed _recipient, uint _fhmMoved, uint _wsfhmMoved, uint _expiresInSeconds, uint _expiresInBlocks);
    event BondRedeemed( address indexed _recipient, uint _fhmRedeemed, uint _wsfhmRedeemed, uint _fhmInWarmup, uint _wsfhmInWarmup);

    event BondPriceChanged( uint indexed priceInUSD, uint indexed internalPrice, uint indexed debtRatio );
    event ControlVariableAdjustment( uint initialBCV, uint newBCV, uint adjustment, bool addition );



    uint internal constant max = type(uint).max;
    /* ======== STATE VARIABLES ======== */

    address public immutable FHM; // reward from treasury which is staked for the time of the bond
    address public immutable sFHM; // token given as payment for bond
    address public immutable wsFHM; // wsfhm token
    address public immutable principle; // token used to create bond
    address public immutable treasury; // mints FHM when receives principle
    address public immutable DAO; // receives profit share from bond
    address public immutable usdbMinter; // `HUD minter
    address public immutable fhmCirculatingSupply; // FHM circulating supply

    bool public immutable isLiquidityBond; // LP and Reserve bonds are treated slightly different
    address public immutable bondCalculator; // calculates value of LP tokens

    address public stakingWarmupManager; // to move from warmup to pool
    address public stakingStaking; //6,6 pool
    uint public warmupPeriodCount; // just not hardcode it and dont have another dependency on staking

    Terms public terms; // stores terms for new bonds
    Adjust public adjustment; // stores adjustment to BCV data

    mapping( address => Bond ) public _bondInfo; // stores bond information for depositors

    uint public totalDebt; // total value of outstanding bonds; used for pricing
    uint public lastDecay; // reference block for debt decay
    uint public claimPageSize; // maximum iteration threshold

    uint public totalWsfhmDeposit; // total deposited (moved) wsFHM by this bond

    /* ======== STRUCTS ======== */

    // Info for creating new bonds
    struct Terms {
        uint controlVariable; // scaling variable for price
        uint vestingTermSeconds; // in seconds
        uint vestingTerm; // in blocks
        uint minimumPrice; // vs principle value
        uint maximumDiscount; // in hundreds of a %, 500 = 5%
        uint maxPayout; // in thousandths of a %. i.e. 500 = 0.5%
        uint fee; // as % of bond payout, in hundreds. ( 500 = 5% = 0.05 for every 1 paid)
        uint maxDebt; // 9 decimal debt ratio, max % total supply created as debt
    }

    // Info for bond holder
    struct Bond {
        uint gonsInWarmup; // sFHM deposited into warmup, needs to be moved
        uint fhmDepositedInWarmup; // FHM deposited into warmup, needs to be moved
        uint lastEpochNumber; // last epoch number of staked tokens in warmup
        uint wsfhmInPool; // wsfhm in pool

        uint vesting; // Blocks left to vest
        uint lastBlock; // Last interaction
        uint pricePaid; // In DAI, for front end viewing
        uint vestingSeconds; // Blocks left to vest
        uint lastTimestamp; // Last interaction
    }

    // Info for incremental adjustments to control variable
    struct Adjust {
        bool add; // addition or subtraction
        uint rate; // increment
        uint target; // BCV when adjustment finished
        uint buffer; // minimum length (in blocks) between adjustments
        uint lastBlock; // block when last adjustment made
    }




    /* ======== INITIALIZATION ======== */

    constructor (
        address _FHM,
        address _sFHM,
        address _wsFHM,
        address _principle,
        address _treasury,
        address _DAO,
        address _bondCalculator,
        address _usdbMinter,
        address _fhmCirculatingSupply,
        address _stakingStaking
    ) {
        require( _FHM != address(0) );
        FHM = _FHM;
        require( _sFHM != address(0) );
        sFHM = _sFHM;
        require( _principle != address(0) );
        principle = _principle;
        require( _treasury != address(0) );
        treasury = _treasury;
        require( _DAO != address(0) );
        DAO = _DAO;
        require( _usdbMinter != address(0) );
        usdbMinter = _usdbMinter;
        require( _fhmCirculatingSupply != address(0) );
        fhmCirculatingSupply = _fhmCirculatingSupply;
        require( _wsFHM != address(0) );
        wsFHM = _wsFHM;
        require( _stakingStaking != address(0) );
        stakingStaking = _stakingStaking;
        // bondCalculator should be address(0) if not LP bond
        bondCalculator = _bondCalculator;
        isLiquidityBond = ( _bondCalculator != address(0) );

        // approve as spender
        IERC20(_wsFHM).approve(_stakingStaking, max);
        IERC20(_sFHM).approve(_wsFHM, max);
    }

    /**
     *  @notice initializes bond parameters
     *  @param _controlVariable uint
     *  @param _vestingTermSeconds uint
     *  @param _vestingTerm uint
     *  @param _minimumPrice uint
     *  @param _maximumDiscount uint
     *  @param _maxPayout uint
     *  @param _fee uint
     *  @param _maxDebt uint
     *  @param _initialDebt uint
     *  @param _claimPageSize uint
     */
    function initializeBondTerms(
        uint _controlVariable,
        uint _vestingTermSeconds,
        uint _vestingTerm,
        uint _minimumPrice,
        uint _maximumDiscount,
        uint _maxPayout,
        uint _fee,
        uint _maxDebt,
        uint _initialDebt,
        uint _claimPageSize
    ) external onlyPolicy() {
        terms = Terms ({
        controlVariable: _controlVariable,
        vestingTerm: _vestingTerm,
        vestingTermSeconds: _vestingTermSeconds,
        minimumPrice: _minimumPrice,
        maximumDiscount: _maximumDiscount,
        maxPayout: _maxPayout,
        fee: _fee,
        maxDebt: _maxDebt
        });
        totalDebt = _initialDebt;
        lastDecay = block.number;
        claimPageSize = _claimPageSize;
    }




    /* ======== POLICY FUNCTIONS ======== */

    enum PARAMETER { VESTING, PAYOUT, FEE, DEBT, MIN_PRICE }
    /**
     *  @notice set parameters for new bonds
     *  @param _parameter PARAMETER
     *  @param _input uint
     */
    function setBondTerms ( PARAMETER _parameter, uint _input ) external onlyPolicy() {
        if ( _parameter == PARAMETER.VESTING ) { // 0
            require( _input >= 10000, "Vesting must be longer than 10000 blocks" );
            terms.vestingTerm = _input;
        } else if ( _parameter == PARAMETER.PAYOUT ) { // 1
            require( _input <= 1000, "Payout cannot be above 1 percent" );
            terms.maxPayout = _input;
        } else if ( _parameter == PARAMETER.FEE ) { // 2
            require( _input <= 10000, "DAO fee cannot exceed payout" );
            terms.fee = _input;
        } else if ( _parameter == PARAMETER.DEBT ) { // 3
            terms.maxDebt = _input;
        }  else if ( _parameter == PARAMETER.MIN_PRICE ) { // 4
            terms.minimumPrice = _input;
        }
    }

    /**
     *  @notice set control variable adjustment
     *  @param _addition bool
     *  @param _increment uint
     *  @param _target uint
     *  @param _buffer uint
     */
    function setAdjustment (
        bool _addition,
        uint _increment,
        uint _target,
        uint _buffer
    ) external onlyPolicy() {
        adjustment = Adjust({
        add: _addition,
        rate: _increment,
        target: _target,
        buffer: _buffer,
        lastBlock: block.number
        });
    }

    /**
     *  @notice set contract for auto stake
     *  @param _stakingWarmupManager address
     */
    function setStakingWarmupManager( address _stakingWarmupManager, uint _warmupPeriodCount ) external onlyPolicy() {
        require( _stakingWarmupManager != address(0) );
        stakingWarmupManager = _stakingWarmupManager;
        warmupPeriodCount = _warmupPeriodCount;
    }

    /**
     *  @notice set contract for auto stakeStake
     *  @param _stakingStaking address
     */
    function setStakingStaking( address _stakingStaking ) external onlyPolicy() {
        require( _stakingStaking != address(0) );
        stakingStaking = _stakingStaking;
    }

    /* ======== USER FUNCTIONS ======== */

    /**
     *  @notice deposit bond
     *  @param _amount uint
     *  @param _maxPrice uint
     *  @param _depositor address
     *  @return uint
     */
    function deposit(
        uint _amount,
        uint _maxPrice,
        address _depositor
    ) external nonReentrant returns ( uint ) {
        require( _depositor != address(0), "Invalid address" );

        decayDebt();
        require( totalDebt <= terms.maxDebt, "Max capacity reached" );

        uint priceInUSD = bondPriceInUSD(); // Stored in bond info
        uint nativePrice = _bondPrice();

        require( _maxPrice >= nativePrice, "Slippage limit: more than max price" ); // slippage protection

        uint value = ITreasury( treasury ).valueOf( principle, _amount );
        uint payout = payoutFor( value ); // payout to bonder is computed

        require( payout >= 10000000, "Bond too small" ); // must be > 0.01 FHM ( underflow protection )
        require( payout <= maxPayout(), "Bond too large"); // size protection because there is no slippage

        // profits are calculated
        uint fee = payout.mul( terms.fee ).div( 10000 );
        uint profit = value.sub( payout ).sub( fee );

        /**
            principle is transferred in
            approved and
            deposited into the treasury, returning (_amount - profit) FHM
         */
        IERC20( principle ).safeTransferFrom( msg.sender, address(this), _amount );
        IERC20( principle ).approve( address( treasury ), _amount );
        ITreasury( treasury ).deposit( _amount, principle, profit );

        if ( fee != 0 ) { // fee is transferred to dao
            IERC20( FHM ).safeTransfer( DAO, fee );
        }

        // total debt is increased
        totalDebt = totalDebt.add( value );

        IStakingStaking(stakingStaking).claim(claimPageSize);
        IERC20( FHM ).approve( stakingWarmupManager, payout );
        IStakingWarmupManager(stakingWarmupManager).stake( payout, address(this) );

        uint fhmInWarmup = IsFHM(sFHM).balanceForGons(_bondInfo[_depositor].gonsInWarmup).add(payout);

        // depositor info is stored
        _bondInfo[_depositor] = Bond({
            gonsInWarmup: IsFHM(sFHM).gonsForBalance(fhmInWarmup),
            fhmDepositedInWarmup: fhmInWarmup,
            lastEpochNumber: IStakingWarmupManager(stakingWarmupManager).getEpochNumber(),

            wsfhmInPool: _bondInfo[_depositor].wsfhmInPool,
            vestingSeconds: terms.vestingTermSeconds,
            vesting: terms.vestingTerm,
            lastBlock: block.number,
            lastTimestamp: block.timestamp,
            pricePaid: priceInUSD
        });

        // indexed events are emitted
        emit BondCreated( _depositor, _amount, payout, IwsFHM(wsFHM).wsFHMValue(payout), fhmInWarmup, IwsFHM(wsFHM).wsFHMValue(fhmInWarmup), priceInUSD );
        emit BondPriceChanged( bondPriceInUSD(), _bondPrice(), debtRatio() );

        adjust(); // control variable is adjusted
        return payout;
    }

    /**
      *  @notice deposit sfhm token to the pool
      *  @param _depositor address
     */
    function move(address _depositor) external nonReentrant returns(uint) {
        uint currentEpoch = IStakingWarmupManager(stakingWarmupManager).getEpochNumber();
        Bond storage info = _bondInfo[_depositor];

        require(info.fhmDepositedInWarmup > 0, "NOTHING_TO_MOVE");
        // cannot move if warmup is not ready yet
        require(info.lastEpochNumber + warmupPeriodCount >= currentEpoch, "WARMUP_PERIOD_NOT_DONE");

        IStakingWarmupManager(stakingWarmupManager).claim(address(this));

        //calculate sFHM amounts and wrap what was in warmup
        uint _amount = IsFHM( sFHM ).balanceForGons(info.gonsInWarmup);
        uint _wsfhmDeposit = IwsFHM(wsFHM).wrap(_amount);

        // remember wsfhm deposited into the pool to count real balance
        totalWsfhmDeposit = totalWsfhmDeposit.add(_wsfhmDeposit);
        
        // update balance in pool
        info.wsfhmInPool = info.wsfhmInPool.add(_wsfhmDeposit);

        // reset move statistics
        info.gonsInWarmup = 0;
        info.fhmDepositedInWarmup = 0;
        info.lastEpochNumber = 0;

        // update real vesting term
        info.vesting = terms.vestingTerm;
        info.vestingSeconds = terms.vestingTermSeconds;
        info.lastBlock = block.number;
        info.lastTimestamp = block.timestamp;

        emit BondMoved(_depositor, IwsFHM(wsFHM).sFHMValue(_wsfhmDeposit), _wsfhmDeposit, block.timestamp.add(terms.vestingTermSeconds), block.number.add( terms.vestingTerm ));

        // deposit token to the pool
        IStakingStaking(stakingStaking).deposit(address(this), _wsfhmDeposit);

        return _wsfhmDeposit;
    }

    /**
     *  @notice redeem bond for user
     *  @param _recipient address
     *  @param _stake bool
     *  @return uint
     */
    function redeem( address _recipient, bool _stake ) external nonReentrant  returns ( uint ) {
        uint percentVested = percentVestedFor( _recipient ); // (seconds since last interaction / vesting term remaining)
        uint percentVestedBlocks = percentVestedBlocksFor( _recipient ); // (blocks since last interaction / vesting term remaining)

        require ( percentVested >= 10000, "Wait for end timestamp of bond") ;
        require ( percentVestedBlocks >= 10000, "Wait for end block of bond") ;

        IStakingStaking(stakingStaking).claim(claimPageSize);

        uint wsfhmInPool = balanceOfPooled(_recipient);

        // withdraw deposit tokens from pool
        IStakingStaking(stakingStaking).withdraw(address(this), wsfhmInPool, false );

        // calc totalWsfhmDeposit and total rewards
        if (totalWsfhmDeposit > wsfhmInPool) {
            totalWsfhmDeposit = totalWsfhmDeposit.sub(wsfhmInPool);
        } else {
            totalWsfhmDeposit = 0;
        }

        Bond storage info = _bondInfo[_recipient];
        info.wsfhmInPool = 0;

        // delete user info if there are no tokens in warmup
        if (info.fhmDepositedInWarmup == 0) {
            delete _bondInfo[ _recipient ];
        }

        emit BondRedeemed( _recipient, IwsFHM(wsFHM).sFHMValue(wsfhmInPool), wsfhmInPool, info.fhmDepositedInWarmup, IwsFHM(wsFHM).wsFHMValue(info.fhmDepositedInWarmup)); // emit bond data

        IERC20( wsFHM ).transfer( _recipient, wsfhmInPool); // pay user everything due

        return wsfhmInPool;
    }

    /* ======== INTERNAL HELPER FUNCTIONS ======== */

    /**
     *  @notice makes incremental adjustment to control variable
     */
    function adjust() internal {
        uint blockCanAdjust = adjustment.lastBlock.add( adjustment.buffer );
        if( adjustment.rate != 0 && block.number >= blockCanAdjust ) {
            uint initial = terms.controlVariable;
            if ( adjustment.add ) {
                terms.controlVariable = terms.controlVariable.add( adjustment.rate );
                if ( terms.controlVariable >= adjustment.target ) {
                    adjustment.rate = 0;
                }
            } else {
                terms.controlVariable = terms.controlVariable.sub( adjustment.rate );
                if ( terms.controlVariable <= adjustment.target ) {
                    adjustment.rate = 0;
                }
            }
            adjustment.lastBlock = block.number;
            emit ControlVariableAdjustment( initial, terms.controlVariable, adjustment.rate, adjustment.add );
        }
    }

    /**
     *  @notice reduce total debt
     */
    function decayDebt() internal {
        totalDebt = totalDebt.sub( debtDecay() );
        lastDecay = block.number;
    }




    /* ======== VIEW FUNCTIONS ======== */

    /**
     *  @notice determine maximum bond size
     *  @return uint
     */
    function maxPayout() public view returns ( uint ) {
        return IFHMCirculatingSupply(fhmCirculatingSupply).OHMCirculatingSupply().mul( terms.maxPayout ).div( 100000 );
    }

    /**
     *  @notice calculate interest due for new bond
     *  @param _value uint
     *  @return uint
     */
    function payoutFor( uint _value ) public view returns ( uint ) {
        return FixedPoint.fraction( _value, bondPrice() ).decode112with18().div( 1e16 );
    }


    /// @notice get actual balance of wsFHM deposited and rewarded for current user
    /// @param _depositor user
    /// @return wsFHM amount
    function balanceOfPooled( address _depositor ) public view returns ( uint ) {
        if (totalWsfhmDeposit == 0) return 0;
        Bond memory info = _bondInfo[_depositor];

        // total deposited and unclaimed rewards for all users
        (uint stakedAndToClaim,,) = IStakingStaking(stakingStaking).userBalance(address(this));

        // calculate wsFHM amount
        uint totalRewards = 0;
        if (stakedAndToClaim > totalWsfhmDeposit) {
            totalRewards = stakedAndToClaim.sub(totalWsfhmDeposit);
        }
        uint userRewards = totalRewards.mul(info.wsfhmInPool).div(totalWsfhmDeposit);
        return info.wsfhmInPool.add(userRewards);
    }


    /**
     *  @notice calculate current bond premium
     *  @return price_ uint
     */
    function bondPrice() public view returns ( uint price_ ) {
        price_ = terms.controlVariable.mul( debtRatio() ).add( 1000000000 ).div( 1e7 );
        if ( price_ < terms.minimumPrice ) {
            price_ = terms.minimumPrice;
        }

        uint minimalPrice = getMinimalBondPrice();
        if (price_ < minimalPrice) {
            price_ = minimalPrice;
        }
    }

    /**
     *  @notice calculate current bond price and remove floor if above
     *  @return price_ uint
     */
    function _bondPrice() internal returns ( uint price_ ) {
        price_ = terms.controlVariable.mul( debtRatio() ).add( 1000000000 ).div( 1e7 );
        if ( price_ < terms.minimumPrice ) {
            price_ = terms.minimumPrice;
        } else if ( terms.minimumPrice != 0 ) {
            terms.minimumPrice = 0;
        }

        uint minimalPrice = getMinimalBondPrice();
        if (price_ < minimalPrice) {
            price_ = minimalPrice;
        }
    }

    function getMinimalBondPrice() public view returns (uint) {
        uint marketPrice = IUSDBMinter(usdbMinter).getMarketPrice();
        uint discount = marketPrice.mul(terms.maximumDiscount).div(10000);
        uint price = marketPrice.sub(discount);

        if (isLiquidityBond) {
            return price.mul(10 ** IERC20( principle ).decimals()).div(IBondCalculator(bondCalculator).markdown(principle));
        } else {
            return price;
        }
    }

    /**
     *  @notice converts bond price to DAI value
     *  @return price_ uint
     */
    function bondPriceInUSD() public view returns ( uint price_ ) {
        if( isLiquidityBond ) {
            price_ = bondPrice().mul( IBondCalculator( bondCalculator ).markdown( principle ) ).div( 100 );
        } else {
            price_ = bondPrice().mul( 10 ** IERC20( principle ).decimals() ).div( 100 );
        }
    }

    /**
     *  @notice return bond info with latest sFHM balance calculated from gons
     *  @param _depositor address
     *  @return payout uint all fhm worth in warmup and in the pool
     *  @return payoutInWsFHM uint all wsfhm worth in warmup and in the pool
     *  @return vesting uint
     *  @return lastBlock uint
     *  @return pricePaid uint
     *  @return vestingSeconds uint
     *  @return lastTimestamp uint
     *  @return lastEpochNumber uint when its 0, nothing is in warmup
     */
    function bondInfo(address _depositor) public view returns ( uint payout, uint payoutInWsFHM, uint vesting, uint lastBlock, uint pricePaid, uint vestingSeconds, uint lastTimestamp, uint lastEpochNumber) {
        Bond memory info = _bondInfo[ _depositor ];

        uint fhmInWarmup = IsFHM(sFHM).balanceForGons(info.gonsInWarmup);
        uint wsfhmInWarmup = IwsFHM(wsFHM).wsFHMValue(fhmInWarmup);
        uint wsfhmInPool = balanceOfPooled(_depositor);
        uint fhmInPool = IwsFHM(wsFHM).sFHMValue(wsfhmInPool);

        // here we will show actual sFHM value of wsFHM will all rewards
        payout = fhmInWarmup.add(fhmInPool);
        payoutInWsFHM = wsfhmInWarmup.add(wsfhmInPool);
        vesting = info.vesting;
        vestingSeconds = info.vestingSeconds;
        lastBlock = info.lastBlock;
        lastTimestamp = info.lastTimestamp;
        pricePaid = info.pricePaid;
        lastEpochNumber = info.lastEpochNumber;
    }

    /**
     *  @notice calculate current ratio of debt to FHM supply
     *  @return debtRatio_ uint
     */
    function debtRatio() public view returns ( uint debtRatio_ ) {
        uint supply = IFHMCirculatingSupply(fhmCirculatingSupply).OHMCirculatingSupply();
        debtRatio_ = FixedPoint.fraction(
            currentDebt().mul( 1e9 ),
            supply
        ).decode112with18().div( 1e18 );
    }

    /**
     *  @notice debt ratio in same terms for reserve or liquidity bonds
     *  @return uint
     */
    function standardizedDebtRatio() external view returns ( uint ) {
        if ( isLiquidityBond ) {
            return debtRatio().mul( IBondCalculator( bondCalculator ).markdown( principle ) ).div( 1e9 );
        } else {
            return debtRatio();
        }
    }

    /**
     *  @notice calculate debt factoring in decay
     *  @return uint
     */
    function currentDebt() public view returns ( uint ) {
        return totalDebt.sub( debtDecay() );
    }

    /**
     *  @notice amount to decay total debt by
     *  @return decay_ uint
     */
    function debtDecay() public view returns ( uint decay_ ) {
        uint blocksSinceLast = block.number.sub( lastDecay );
        decay_ = totalDebt.mul( blocksSinceLast ).div( terms.vestingTerm );
        if ( decay_ > totalDebt ) {
            decay_ = totalDebt;
        }
    }

    /**
     *  @notice calculate how far into vesting a depositor is
     *  @param _depositor address
     *  @return percentVested_ uint
     */
    function percentVestedFor( address _depositor ) public view returns ( uint percentVested_ ) {
        Bond memory bond = _bondInfo[ _depositor ];
        uint secondsSinceLast = block.timestamp.sub( bond.lastTimestamp );
        uint vestingSeconds = bond.vestingSeconds;

        if ( vestingSeconds > 0 ) {
            percentVested_ = secondsSinceLast.mul( 10000 ).div(vestingSeconds);
        } else {
            percentVested_ = 0;
        }
    }

    function percentVestedBlocksFor( address _depositor ) public view returns ( uint percentVested_ ) {
        Bond memory bond = _bondInfo[ _depositor ];
        uint blocksSinceLast = block.number.sub( bond.lastBlock );
        uint vesting = bond.vesting;

        if ( vesting > 0 ) {
            percentVested_ = blocksSinceLast.mul( 10000 ).div( vesting );
        } else {
            percentVested_ = 0;
        }
    }


    /**
     *  @notice calculate amount of FHM available for claim by depositor
     *  @param _depositor address
     *  @return pendingPayout_ uint
     */
    function pendingPayoutFor( address _depositor ) external view returns ( uint pendingPayout_ ) {
        uint percentVested = percentVestedFor( _depositor );
        uint percentVestedBlocks = percentVestedBlocksFor( _depositor );

        if ( percentVested >= 10000 && percentVestedBlocks >= 10000) {
            pendingPayout_ = balanceOfPooled(_depositor);
        } else {
            pendingPayout_ = 0;
        }
    }

    /* ======= AUXILLIARY ======= */

    /**
     *  @notice allow anyone to send lost tokens (excluding principle or FHM) to the DAO
     *  @return bool
     */
    function recoverLostToken( address _token ) external returns ( bool ) {
        require( _token != FHM);
        require( _token != sFHM);
        require( _token != wsFHM);
        require( _token != principle );
        IERC20( _token ).safeTransfer( DAO, IERC20( _token ).balanceOf( address(this) ) );
        return true;
    }
}