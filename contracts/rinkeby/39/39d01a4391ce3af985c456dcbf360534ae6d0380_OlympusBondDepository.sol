/**
 *Submitted for verification at Etherscan.io on 2021-04-26
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
    function depositReserves( uint amount_, address token_ ) external returns ( bool );
    function depositPrinciple( uint amount_, address token_ ) external returns ( bool );
    function isReserveToken( address token_ ) external returns ( address );
    function isPrincipleToken( address token_ ) external returns ( address );
}

interface ICirculatingOHM {
    function OHMCirculatingSupply() external view returns ( uint );
}

interface IBondCalculator {
    function valuation( address LP_, uint amount_ ) external view returns ( uint );
    function markdown( address LP_ ) external view returns ( uint );
}

contract OlympusBondDepository is Ownable {

    using FixedPoint for *;
    using SafeERC20 for IERC20;
    using SafeMath for uint;

    struct DepositInfo {
        uint payoutRemaining; // OHM remaining to be paid
        uint lastBlock; // Last interaction
        uint vestingPeriod; // Blocks left to vest
        uint pricePaid;
        bool vested;
    }

    mapping( address => mapping( uint => DepositInfo ) ) public depositorInfo; 
    mapping( address => uint ) public lastIndex;
    mapping( address => uint ) public firstIndex;

    uint public DAOShare; // % = 1 / DAOShare
    uint public bondControlVariable; // Premium scaling variable
    uint[] public vestingTerms; // Block length to vest ( 0 = Reserve, 1 = Principle)
    uint public minPrice; // Floor for the premium

    //  Max a payout can be compared to the circulating supply, in hundreths. i.e. 50 = 0.5%
    uint public maxPayoutPercent;

    address public OHM;
    address public treasury;
    address public DAI;
    address public LP;

    uint256 public totalDebt; // Total value of outstanding bonds

    address public stakingContract;
    address public DAOWallet;
    address public circulatingOHMContract; // calculates circulating supply
    address public bondCalculator;

    bool public useCircForDebtRatio; // Use circulating or total supply to calc total debt

    constructor ( 
        address OHM_,
        address LP_,
        address DAI_,
        address treasury_, 
        address stakingContract_, 
        address DAOWallet_, 
        address circulatingOHMContract_,
        address bondCalculator_
    ) {
        OHM = OHM_;
        LP = LP_;
        DAI = DAI_;
        treasury = treasury_;
        stakingContract = stakingContract_;
        DAOWallet = DAOWallet_;
        circulatingOHMContract = circulatingOHMContract_;
        bondCalculator = bondCalculator_;
    }

    /**
        @notice set parameters of new bonds
        @param bondControlVariable_ uint
        @param vestingTerms_ uint[]
        @param minPrice_ uint
        @param maxPayout_ uint
        @param DAOShare_ uint
        @return bool
     */
    function setBondTerms( 
        uint bondControlVariable_, 
        uint[] memory vestingTerms_, 
        uint minPrice_, 
        uint maxPayout_,
        uint DAOShare_
    ) external onlyOwner() returns ( bool ) {
        bondControlVariable = bondControlVariable_;
        vestingTerms = vestingTerms_;
        minPrice = minPrice_;
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
        address depositor_,
        address token_
    ) external returns ( bool ) {
        _deposit( amount_, maxPremium_, depositor_, token_ ) ;
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
        address token_,
        uint deadline, 
        uint8 v, 
        bytes32 r, 
        bytes32 s 
    ) external returns ( bool ) {
        ERC20Permit( token_ ).permit( msg.sender, address(this), amount_, deadline, v, r, s );
        _deposit( amount_, maxPremium_, depositor_, token_ ) ;
        return true;
    }

    /**
        @notice deposit function like mint
        @param amount_ uint
        @param maxPrice_ uint
        @param depositor_ address
        @return bool
     */
    function _deposit( 
        uint amount_, 
        uint maxPrice_, 
        address depositor_,
        address token_ ) 
    internal returns ( bool ) {
        uint value; // ohm that can be minted against asset
        uint term; // vesting length in blocks
        uint price; // price of ohm against asset
        if ( token_ == DAI ) {
            value = amount_.div( 1e9 );
            term = vestingTerms[0];
            price = _calcPriceForDAI();
        } else if ( token_ == LP ) { // adjust for LP token
            value = IBondCalculator( bondCalculator ).valuation( token_ , amount_ );
            term = vestingTerms[1];
            price = _calcPriceForLP();
        } else { return false; }

        uint priceInDAI = _calcPriceForDAI();
        // slippage protection
        require( maxPrice_ >= priceInDAI, "More than max premium" );

        IERC20( token_ ).safeTransferFrom( msg.sender, address(this), amount_ );

        uint payout = calculateBondInterest( value, price );

        require( payout >= 10000000, "Bond too small" ); // must be > 0.01 OHM
        require( payout <= getMaxPayoutAmount(), "Payout too large");

        totalDebt = totalDebt.add( payout );

        // Deposit token to mint OHM
        IERC20( token_ ).approve( address( treasury ), amount_ );
        if ( token_ == DAI ) {
            ITreasury( treasury ).depositReserves( amount_, DAI );
        } else if ( token_ == LP ) {
            ITreasury( treasury ).depositPrinciple( amount_, LP );
        }
        
        uint daoProfit = payout.mul( DAOShare ).div( 10000 );
        uint profit = value.sub( payout ).sub( daoProfit );
        // Transfer profits to staking distributor and dao 
        IERC20( OHM ).safeTransfer( stakingContract, profit );
        IERC20( OHM ).safeTransfer( DAOWallet, daoProfit );

        // Store depositor info
        depositorInfo[ depositor_ ][ lastIndex[ depositor_ ] ] = DepositInfo({
            payoutRemaining: payout,
            lastBlock: block.number,
            vestingPeriod: term,
            pricePaid: priceInDAI,
            vested: false
        });
        lastIndex[ depositor_ ]++;
        return true;
    }

    /** 
        @notice redeem all unvested bonds
        @return bool
     */ 
    function redeem() external returns ( bool ) {
        for ( uint i = firstIndex[ msg.sender ]; i < lastIndex[ msg.sender ]; i++ ) {
            DepositInfo memory info = depositorInfo[ msg.sender ][ i ];

            if ( !info.vested ) {
                uint percentVested = _calculatePercentVested( msg.sender, i );

                if ( percentVested >= 10000 ) { // if fully vested
                    IERC20( OHM ).transfer( msg.sender, info.payoutRemaining );
                    totalDebt = totalDebt.sub( info.payoutRemaining );
                    depositorInfo[msg.sender][ i ] = DepositInfo({
                        payoutRemaining: 0,
                        lastBlock: block.number,
                        vestingPeriod: 0,
                        pricePaid: info.pricePaid,
                        vested: true
                    });
                } else {
                    // calculate and send vested OHM
                    uint payout = info.payoutRemaining.mul( percentVested ).div( 10000 );
                    IERC20( OHM ).transfer( msg.sender, payout );

                    // reduce total debt by vested amount
                    totalDebt = totalDebt.sub( payout );

                    uint blocksSinceLast = block.number.sub( info.lastBlock );
                    // store updated deposit info
                    depositorInfo[msg.sender][ i ] = DepositInfo({
                        payoutRemaining: info.payoutRemaining.sub( payout ),
                        lastBlock: block.number,
                        vestingPeriod: info.vestingPeriod.sub( blocksSinceLast ),
                        pricePaid: info.pricePaid,
                        vested: false
                    });
                }
            }
            if ( info.vested && i == firstIndex[ msg.sender ] ) {
                firstIndex[ msg.sender ] = i++;
            }
        }
        return true;
    }

    /**
        @notice get info of depositor
        @param address_ info
     */
    function getDepositorInfo( address address_, uint index_ ) external view returns ( 
        uint _payoutRemaining, 
        uint _lastBlock, 
        uint _vestingPeriod,
        uint _pricePaid,
        bool _vested 
    ) {
        DepositInfo memory info = depositorInfo[ address_ ][ index_ ];
        _payoutRemaining = info.payoutRemaining;
        _lastBlock = info.lastBlock;
        _vestingPeriod = info.vestingPeriod;
        _pricePaid = info.pricePaid;
        _vested = info.vested;
    }

    /**
        @notice use maxPayoutPercent to determine maximum bond available
        @return uint
     */
    function getMaxPayoutAmount() public view returns ( uint ) {
        uint circulatingOHM = ICirculatingOHM( circulatingOHMContract ).OHMCirculatingSupply();
        return circulatingOHM.mul( maxPayoutPercent ).div( 10000 );
    }

    /**
        @notice calculate how far into vesting period depositor is
        @param depositor_ address
        @return _percentVested uint
     */
    function calculatePercentVested( address depositor_, uint index_ ) external view returns ( uint _percentVested ) {
        _percentVested = _calculatePercentVested( depositor_, index_ );
    }

    function _calculatePercentVested( address depositor_, uint index_ ) internal view returns ( uint _percentVested ) {
        uint blocksSinceLast = block.number.sub( depositorInfo[ depositor_ ][ index_ ].lastBlock );
        uint vestingPeriod = depositorInfo[ depositor_ ][ index_ ].vestingPeriod;

        if ( vestingPeriod > 0 ) {
            _percentVested = blocksSinceLast.mul( 10000 ).div( vestingPeriod );
        } else {
            _percentVested = 0;
        }
    }

    /**
        @notice calculate amount of OHM available for claim by depositor
        @param depositor_ address
        @return _pendingPayout uint
     */
    function calculatePendingPayout( address depositor_, uint index_ ) external view returns ( uint _pendingPayout ) {
        uint percentVested = _calculatePercentVested( depositor_, index_ );
        uint payoutRemaining = depositorInfo[ depositor_ ][ index_ ].payoutRemaining;
        
        _pendingPayout = payoutRemaining.mul( percentVested ).div( 10000 );

        if ( percentVested >= 10000 ) {
            _pendingPayout = payoutRemaining;
        } 
    }

    /**
        @notice calculate interest due to new bonder
        @param value_ uint
        @return _interestDue uint
     */
    function calculateBondInterest( uint value_, uint price_ ) public pure returns ( uint ) {
        return FixedPoint.fraction( value_, price_ ).decode112with18().div( 1e16 );
    }

    /**
        @notice calculate current bond premium
        @return _premium uint
     */
    function calculatePriceInDAI() external view returns ( uint ) {
        return _calcPriceForDAI();
    }

    function _calcPriceForDAI() internal view returns ( uint _price ) {
        uint BCV = bondControlVariable;
        uint minimumPrice = minPrice;
        
        _price = BCV.mul( _calcDebtRatio() ).add( uint(1000000000) ).div( 1e7 );
        if ( _price < minimumPrice ) {
            _price = minimumPrice;
        }
    }

    function _calcPriceForLP() internal view returns ( uint _price ) {
        uint BCV = bondControlVariable.mul( 1e9 ).div( IBondCalculator( bondCalculator ).markdown( LP ) );
        uint minimumPrice = minPrice.mul( 1e9 ).div( IBondCalculator( bondCalculator ).markdown( LP ) );

        _price = BCV.mul( _calcDebtRatio() ).add( uint(1000000000) ).div( 1e7 );
        if ( _price < minimumPrice ) {
            _price = minimumPrice;
        }
    }

    /**
        @notice calculate current debt ratio
        @return _debtRatio uint
     */
    function calculateDebtRatio() external view returns ( uint _debtRatio ) {
        _debtRatio = _calcDebtRatio();
    }

    function _calcDebtRatio() internal view returns ( uint _debtRatio ) {   
        uint supply = ICirculatingOHM( circulatingOHMContract ).OHMCirculatingSupply();
        _debtRatio = FixedPoint.fraction( 
            // Must move the decimal to the right by 9 places to avoid math underflow error
            totalDebt.mul( 1e9 ), 
            supply
        ).decode112with18().div( 1e18 );
    }
}