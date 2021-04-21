/**
 *Submitted for verification at Etherscan.io on 2021-04-21
*/

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

interface IOwnable {

    function owner() external view returns (address);

    function renounceOwnership() external;
  
    function transferOwnership( address newOwner_ ) external;
}

contract Ownable is IOwnable {
    
    address internal _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        _owner = msg.sender;
        emit OwnershipTransferred( address(0), _owner );
    }

    function owner() public view override returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require( _owner == msg.sender, "Ownable: caller is not the owner" );
        _;
    }

    function renounceOwnership() public virtual override onlyOwner() {
        emit OwnershipTransferred( _owner, address(0) );
        _owner = address(0);
    }

    function transferOwnership( address newOwner_ ) public virtual override onlyOwner() {
        require( newOwner_ != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred( _owner, newOwner_ );
        _owner = newOwner_;
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

    function percentageAmount( uint256 total_, uint8 percentage_ ) internal pure returns ( uint256 percentAmount_ ) {
        return div( mul( total_, percentage_ ), 1000 );
    }

    function substractPercentage( uint256 total_, uint8 percentageToSub_ ) internal pure returns ( uint256 result_ ) {
        return sub( total_, div( mul( total_, percentageToSub_ ), 1000 ) );
    }

    function percentageOfTotal( uint256 part_, uint256 total_ ) internal pure returns ( uint256 percent_ ) {
        return div( mul(part_, 100) , total_ );
    }

    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }

    function quadraticPricing( uint256 payment_, uint256 multiplier_ ) internal pure returns (uint256) {
        return sqrrt( mul( multiplier_, payment_ ) );
    }

  function bondingCurve( uint256 supply_, uint256 multiplier_ ) internal pure returns (uint256) {
      return mul( multiplier_, supply_ );
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
    function depositReserves( uint depositAmount_ ) external returns ( bool );
}

interface ICirculatingOHM {
    function OHMCirculatingSupply() external view returns ( uint );
}

interface IBondDepo {

    function getDepositorInfo( address _depositorAddress_ ) external view returns ( uint principleValue_, uint paidOut_, uint maxPayout, uint vestingPeriod_ );
    
    function deposit( uint256 amount_, uint maxPremium_, address depositor_ ) external returns ( bool );

    function depositWithPermit( uint256 amount_, uint maxPremium_, address depositor_, uint256 deadline, uint8 v, bytes32 r, bytes32 s ) external returns ( bool );

    function redeem() external returns ( bool );

    function calculatePercentVested( address depositor_ ) external view returns ( uint _percentVested );
    
    function calculatePendingPayout( address depositor_ ) external view returns ( uint _pendingPayout );
      
    function calculateBondInterest( uint value_ ) external view returns ( uint _interestDue );
        
    function calculatePremium() external view returns ( uint _premium );
}



contract OlympusDAIDepository is IBondDepo, Ownable {

    using FixedPoint for *;
    using SafeERC20 for IERC20;
    using SafeMath for uint;

    struct DepositInfo {
        uint value; // Value
        uint payoutRemaining; // OHM remaining to be paid
        uint lastBlock; // Last interaction
        uint vestingPeriod; // Blocks left to vest
    }

    mapping( address => DepositInfo ) public depositorInfo; 

    uint public DAOShare; // % = 1 / DAOShare
    uint public bondControlVariable; // Premium scaling variable
    uint public vestingPeriodInBlocks; 
    uint public minPremium; // Floor for the premium

    //  Max a payout can be compared to the circulating supply, in hundreths. i.e. 50 = 0.5%
    uint public maxPayoutPercent;

    address public treasury;
    address public DAI;
    address public OHM;

    uint256 public totalDebt; // Total value of outstanding bonds

    address public stakingContract;
    address public DAOWallet;
    address public circulatingOHMContract; // calculates circulating supply

    bool public useCircForDebtRatio; // Use circulating or total supply to calc total debt

    constructor ( 
        address DAI_, 
        address OHM_,
        address treasury_, 
        address stakingContract_, 
        address DAOWallet_, 
        address circulatingOHMContract_
    ) {
        DAI = DAI_;
        OHM = OHM_;
        treasury = treasury_;
        stakingContract = stakingContract_;
        DAOWallet = DAOWallet_;
        circulatingOHMContract = circulatingOHMContract_;
    }

    /**
        @notice set parameters of new bonds
        @param bondControlVariable_ uint
        @param vestingPeriodInBlocks_ uint
        @param minPremium_ uint
        @param maxPayout_ uint
        @param DAOShare_ uint
        @return bool
     */
    function setBondTerms( 
        uint bondControlVariable_, 
        uint vestingPeriodInBlocks_, 
        uint minPremium_, 
        uint maxPayout_,
        uint DAOShare_ ) 
    external onlyOwner() returns ( bool ) {
        bondControlVariable = bondControlVariable_;
        vestingPeriodInBlocks = vestingPeriodInBlocks_;
        minPremium = minPremium_;
        maxPayoutPercent = maxPayout_;
        DAOShare = DAOShare_;
        return true;
    }

    /**
        @notice deposit bond
        @param amount_ uint
        @param maxPremium_ uint
        @param depositor_ address
        @return bool
     */
    function deposit( 
        uint amount_, 
        uint maxPremium_,
        address depositor_ ) 
    external override returns ( bool ) {
        _deposit( amount_, maxPremium_, depositor_ ) ;
        return true;
    }

    /**
        @notice deposit bond with permit
        @param amount_ uint
        @param maxPremium_ uint
        @param depositor_ address
        @param v uint8
        @param r bytes32
        @param s bytes32
        @return bool
     */
    function depositWithPermit( 
        uint amount_, 
        uint maxPremium_,
        address depositor_, 
        uint deadline, 
        uint8 v, 
        bytes32 r, 
        bytes32 s ) 
    external override returns ( bool ) {
        ERC20Permit( DAI ).permit( msg.sender, address(this), amount_, deadline, v, r, s );
        _deposit( amount_, maxPremium_, depositor_ ) ;
        return true;
    }

    /**
        @notice deposit function like mint
        @param amount_ uint
        @param maxPremium_ uint
        @param depositor_ address
        @return bool
     */
    function _deposit( 
        uint amount_, 
        uint maxPremium_, 
        address depositor_ ) 
    internal returns ( bool ) {
        // slippage protection
        require( maxPremium_ >= _calcPremium(), "Slippage protection: more than max premium" );

        IERC20( DAI ).safeTransferFrom( msg.sender, address(this), amount_ );

        uint value_ = amount_.div( 1e9 );
        uint payout_ = calculateBondInterest( value_ );

        require( payout_ >= 10000000, "Bond too small" ); // must be > 0.01 OHM
        require( payout_ <= getMaxPayoutAmount(), "Bond too large");

        totalDebt = totalDebt.add( value_ );

        // Deposit token to mint OHM
        IERC20( DAI ).approve( address( treasury ), amount_ );
        ITreasury( treasury ).depositReserves( amount_ ); // Returns OHM

        uint profit_ = value_.sub( payout_ );
        uint DAOProfit_ = FixedPoint.fraction( profit_, DAOShare ).decode();
        // Transfer profits to staking distributor and dao
        IERC20( OHM ).safeTransfer( stakingContract, profit_.sub( DAOProfit_ ) );
        IERC20( OHM ).safeTransfer( DAOWallet, DAOProfit_ );

        // Store depositor info
        depositorInfo[ depositor_ ] = DepositInfo({
            value: depositorInfo[ depositor_ ].value.add( value_ ),
            payoutRemaining: depositorInfo[ depositor_ ].payoutRemaining.add( payout_ ),
            lastBlock: block.number,
            vestingPeriod: vestingPeriodInBlocks
        });
        return true;
    }

    /** 
        @notice redeem bond
        @return bool
     */ 
    function redeem() external override returns ( bool ) {
        uint payoutRemaining_ = depositorInfo[ msg.sender ].payoutRemaining;

        require( payoutRemaining_ > 0, "Sender is not due any interest." );

        uint value_ = depositorInfo[ msg.sender ].value;
        uint percentVested_ = _calculatePercentVested( msg.sender );

        if ( percentVested_ >= 10000 ) { // if fully vested
            delete depositorInfo[msg.sender];
            IERC20( OHM ).safeTransfer( msg.sender, payoutRemaining_ );
            totalDebt = totalDebt.sub( value_ );
            return true;
        }

        // calculate and send vested OHM
        uint payout_ = payoutRemaining_.mul( percentVested_ ).div( 10000 );
        IERC20( OHM ).safeTransfer( msg.sender, payout_ );

        // reduce total debt by vested amount
        uint valueUsed_ = value_.mul( percentVested_ ).div( 10000 );
        totalDebt = totalDebt.sub( valueUsed_ );

        uint vestingPeriod_ = depositorInfo[msg.sender].vestingPeriod;
        uint blocksSinceLast_ = block.number.sub( depositorInfo[ msg.sender ].lastBlock );

        // store updated deposit info
        depositorInfo[msg.sender] = DepositInfo({
            value: value_.sub( valueUsed_ ),
            payoutRemaining: payoutRemaining_.sub( payout_ ),
            lastBlock: block.number,
            vestingPeriod: vestingPeriod_.sub( blocksSinceLast_ )
        });
        return true;
    }

    /**
        @notice get info of depositor
        @param address_ info
     */
    function getDepositorInfo( address address_ ) external view override returns ( 
        uint _value, 
        uint _payoutRemaining, 
        uint _lastBlock, 
        uint _vestingPeriod ) 
    {
        DepositInfo memory info = depositorInfo[ address_ ];
        _value = info.value;
        _payoutRemaining = info.payoutRemaining;
        _lastBlock = info.lastBlock;
        _vestingPeriod = info.vestingPeriod;
    }

    /**
        @notice set contract to use circulating or total supply to calc debt
     */
    function toggleUseCircForDebtRatio() external onlyOwner() returns ( bool ) {
        useCircForDebtRatio = !useCircForDebtRatio;
        return true;
    }

    /**
        @notice use maxPayoutPercent to determine maximum bond available
        @return uint
     */
    function getMaxPayoutAmount() public view returns ( uint ) {
        uint circulatingOHM = ICirculatingOHM( circulatingOHMContract ).OHMCirculatingSupply();

        uint maxPayout = circulatingOHM.mul( maxPayoutPercent ).div( 10000 );

        return maxPayout;
    }

    /**
        @notice view function for _calculatePercentVested
        @param depositor_ address
        @return _percentVested uint
     */
    function calculatePercentVested( address depositor_ ) external view override returns ( uint _percentVested ) {
        _percentVested = _calculatePercentVested( depositor_ );
    }

    /**
        @notice calculate how far into vesting period depositor is
        @param depositor_ address
        @return _percentVested uint ( in hundreths - i.e. 10 = 0.1% )
     */
    function _calculatePercentVested( address depositor_ ) internal view returns ( uint _percentVested ) {
        uint vestingPeriod_ = depositorInfo[ depositor_ ].vestingPeriod;
        if ( vestingPeriod_ > 0 ) {
            uint blocksSinceLast_ = block.number.sub( depositorInfo[ depositor_ ].lastBlock );
            _percentVested = blocksSinceLast_.mul( 10000 ).div( vestingPeriod_ );
        } else {
            _percentVested = 0;
        }
    }

    /**
        @notice calculate amount of OHM available for claim by depositor
        @param depositor_ address
        @return uint
     */
    function calculatePendingPayout( address depositor_ ) external view override returns ( uint ) {
        uint percentVested_ = _calculatePercentVested( depositor_ );
        uint payoutRemaining_ = depositorInfo[ depositor_ ].payoutRemaining;
        
        uint pendingPayout = payoutRemaining_.mul( percentVested_ ).div( 10000 );

        if ( percentVested_ >= 10000 ) {
            pendingPayout = payoutRemaining_;
        } 
        return pendingPayout;
    }

    /**
        @notice calculate interest due to new bonder
        @param value_ uint
        @return _interestDue uint
     */
    function calculateBondInterest( uint value_ ) public view override returns ( uint _interestDue ) {
        _interestDue = FixedPoint.fraction( value_, _calcPremium() ).decode112with18().div( 1e16 );
    }

    /**
        @notice view function for _calcPremium()
        @return _premium uint
     */
    function calculatePremium() external view override returns ( uint _premium ) {
        _premium = _calcPremium();
    }

    /**
        @notice calculate current bond premium
        @return _premium uint
     */
    function _calcPremium() internal view returns ( uint _premium ) {
        _premium = bondControlVariable.mul( _calcDebtRatio() ).add( uint(1000000000) ).div( 1e7 );
        if ( _premium < minPremium ) {
            _premium = minPremium;
        }
    }

    /**
        @notice calculate current debt ratio
        @return _debtRatio uint
     */
    function _calcDebtRatio() internal view returns ( uint _debtRatio ) {   
        uint supply;

        if( useCircForDebtRatio ) {
            supply = ICirculatingOHM( circulatingOHMContract ).OHMCirculatingSupply();
        } else {
            supply = IERC20( OHM ).totalSupply();
        }

        _debtRatio = FixedPoint.fraction( 
            // Must move the decimal to the right by 9 places to avoid math underflow error
            totalDebt.mul( 1e9 ), 
            supply
        ).decode112with18().div( 1e18 );
        // Must move the decimal to the left 18 places to account for the 9 places added above and the 19 signnificant digits added by FixedPoint.
    }
}