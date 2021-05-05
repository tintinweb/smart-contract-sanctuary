/**
 *Submitted for verification at Etherscan.io on 2021-05-04
*/

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

interface IOwnable {
  function manager() external view returns (address);

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

    function manager() public view override returns (address) {
        return _owner;
    }

    modifier onlyManager() {
        require( _owner == msg.sender, "Ownable: caller is not the owner" );
        _;
    }

    function renounceManagement() public virtual override onlyManager() {
        emit OwnershipPushed( _owner, address(0) );
        _owner = address(0);
    }

    function pushManagement( address newOwner_ ) public virtual override onlyManager() {
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
    function depositPrinciple( uint amount_ ) external returns ( bool );
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

    struct Bond {
        uint valueRemaining; // value of LP given
        uint payoutRemaining; // OHM remaining to be paid
        uint lastBlock; // Last interaction
        uint vestingPeriod; // Blocks left to vest
        uint pricePaid; // In DAI, for front end viewing
    }
    mapping( address => Bond ) public bondInfo; 

    // Bond terms
    uint public controlVariable;
    uint public vestingTerm;
    uint public minimumPrice;
    uint public DAOShare; 
    uint public maxPayoutPercent; //  compared to circulating supply, in hundreths. i.e. 50 = 0.5%

    uint256 public totalDebt; // Total value of outstanding bonds

    address public immutable OHM;
    address public immutable LP;

    address public immutable treasury;
    address public immutable distributor;
    address public immutable DAO;

    address public immutable circulatingOHMContract; // calculates circulating supply
    address public immutable bondCalculator;

    constructor ( 
        address OHM_,
        address LP_,
        address treasury_, 
        address distributor_, 
        address DAO_, 
        address circulatingOHMContract_,
        address bondCalculator_
    ) {
        require( OHM_ != address(0) );
        OHM = OHM_;
        require( LP_ != address(0) );
        LP = LP_;
        require( treasury_ != address(0) );
        treasury = treasury_;
        require( distributor_ != address(0) );
        distributor = distributor_;
        require( DAO_ != address(0) );
        DAO = DAO_;
        require( circulatingOHMContract_ != address(0) );
        circulatingOHMContract = circulatingOHMContract_;
        require( bondCalculator_ != address(0) );
        bondCalculator = bondCalculator_;
    }

    /**
        @notice set parameters of new bonds
        @param controlVariable_ uint
        @param vestingTerm_ uint
        @param minPrice_ uint
        @param maxPayout_ uint
        @param DAOShare_ uint
        @return bool
     */
    function setBondTerm( 
        uint controlVariable_, 
        uint vestingTerm_, 
        uint minPrice_,
        uint maxPayout_,
        uint DAOShare_
    ) external onlyManager() returns ( bool ) {
        controlVariable = controlVariable_;
        vestingTerm = vestingTerm_;
        minimumPrice = minPrice_;
        maxPayoutPercent = maxPayout_;
        DAOShare = DAOShare_;
        return true;
    }

    /**
        @notice deposit bond
        @param amount_ uint
        @param maxPremium_ uint
        @param depositor_ address
        @return uint
     */
    function deposit( 
        uint amount_, 
        uint maxPremium_,
        address depositor_
    ) external returns ( uint ) {
        return _deposit( amount_, maxPremium_, depositor_ );
    }

    function _deposit( 
        uint amount_, 
        uint maxPrice_,
        address depositor_
    ) internal returns ( uint ) {
        require( depositor_ != address(0), "Invalid address" );
        uint price = bondPriceInDAI(); // DAI price of bond (for depositor info)

        require( maxPrice_ >= bondPrice(), "Slippage limit: more than max price" ); // slippage protection

        uint value = IBondCalculator( bondCalculator ).valuation( LP, amount_ );
        uint payout = payoutFor( value );

        require( payout >= 10000000, "Bond too small" ); // must be > 0.01 OHM
        require( payout <= maxPayout(), "Bond too large");

        // Transfer in LP
        IERC20( LP ).safeTransferFrom( msg.sender, address(this), amount_ );
        // Deposit LP to mint OHM
        IERC20( LP ).approve( address( treasury ), amount_ );
        ITreasury( treasury ).depositPrinciple( amount_ );
        
        // calculate profits
        uint daoProfit = payout.mul( DAOShare ).div( 10000 );
        // small rounding errors may occur due to improved bond calculator not used by vault
        uint padding = value.div( 10000000 ); // leaves dust to ensure against underflow
        uint profit = value.sub( payout ).sub( daoProfit ).sub( padding );
        // Transfer profits to staking distributor and dao 
        IERC20( OHM ).safeTransfer( distributor, profit );
        IERC20( OHM ).safeTransfer( DAO, daoProfit );

        totalDebt = totalDebt.add( value ); // increase total debt
        
        // Store depositor info
        bondInfo[ depositor_ ] = Bond({
            valueRemaining: bondInfo[ depositor_ ].valueRemaining.add( value ),
            payoutRemaining: bondInfo[ depositor_ ].payoutRemaining.add( payout ),
            lastBlock: block.number,
            vestingPeriod: vestingTerm,
            pricePaid: price
        });
        return payout;
    }

    /** 
        @notice redeem all unvested bonds
        @return payout_ uint
     */ 
    function redeem() external returns ( uint ) {        
        Bond memory info = bondInfo[ msg.sender ];
        uint percentVested = percentVestedFor( msg.sender );

        if ( percentVested >= 10000 ) { // if fully vested, pay full amount & clear info
            delete bondInfo[msg.sender];
            totalDebt = totalDebt.sub( info.valueRemaining );
            IERC20( OHM ).transfer( msg.sender, info.payoutRemaining );
            return info.payoutRemaining;
        } else {
            // calculate reductions from vesting
            uint value = info.valueRemaining.mul( percentVested ).div( 10000 );
            uint payout = info.payoutRemaining.mul( percentVested ).div( 10000 );
            uint blocksSinceLast = block.number.sub( info.lastBlock );

            // store updated deposit info
            bondInfo[ msg.sender ] = Bond({
                valueRemaining: info.valueRemaining.sub( value ),
                payoutRemaining: info.payoutRemaining.sub( payout ),
                lastBlock: block.number,
                vestingPeriod: info.vestingPeriod.sub( blocksSinceLast ),
                pricePaid: info.pricePaid
            });

            // reduce total debt by vested amount
            totalDebt = totalDebt.sub( value );
            // send payout
            IERC20( OHM ).transfer( msg.sender, payout );

            return payout;
        }
    }

    /**
        @notice use maxPayoutPercent to determine maximum bond size
        @return uint
     */
    function maxPayout() public view returns ( uint ) {
        uint circulatingOHM = ICirculatingOHM( circulatingOHMContract ).OHMCirculatingSupply();
        return circulatingOHM.mul( maxPayoutPercent ).div( 10000 );
    }

    /**
        @notice calculate how far into vesting a depositor is
        @param depositor_ address
        @return _percentVested uint
     */
    function percentVestedFor( address depositor_ ) public view returns ( uint _percentVested ) {
        Bond memory bond = bondInfo[ depositor_ ];
        uint blocksSinceLast = block.number.sub( bond.lastBlock );
        uint vestingPeriod = bond.vestingPeriod;

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
    function pendingPayoutFor( address depositor_ ) external view returns ( uint _pendingPayout ) {
        uint percentVested = percentVestedFor( depositor_ );
        uint payoutRemaining = bondInfo[ depositor_ ].payoutRemaining;

        if ( percentVested >= 10000 ) {
            _pendingPayout = payoutRemaining;
        } else {
            _pendingPayout = payoutRemaining.mul( percentVested ).div( 10000 );
        }
    }

    /**
        @notice calculate interest due for new bond
        @param value_ uint
        @return _interestDue uint
     */
    function payoutFor( uint value_ ) public view returns ( uint ) {
        return FixedPoint.fraction( value_, bondPrice() ).decode112with18().div( 1e16 );
    }

    /**
        @notice calculate current bond premium
        @return _price uint
     */
    function bondPrice() public view returns ( uint _price ) {        
        _price = controlVariable.mul( _calcDebtRatio() ).add( 1000000000 ).div( 1e7 );
        if ( _price < minimumPrice ) {
            _price = minimumPrice;
        }
    }

    /**
        @notice calculate current bond premium without a minimum
        @return _price uint
     */
    function bondPriceWithoutFloor() external view returns ( uint _price ) {
        _price = controlVariable.mul( _calcDebtRatio() ).add( 1000000000 ).div( 1e7 );
    }

    /**
        @notice converts bond price to DAI value
        @return _price uint
     */
    function bondPriceInDAI() public view returns ( uint _price ) {
        _price = bondPrice().mul( IBondCalculator( bondCalculator ).markdown( LP ) ).div( 1e2 );
    }

    /**
        @notice calculate current debt ratio
        @return _debtRatio uint
     */
    function debtRatio() external view returns ( uint _debtRatio ) {
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

    /**
        @notice allow anyone to send lost tokens (excluding LP or OHM) to the DAO
        @return bool
     */
    function recoverLostToken( address token_ ) external returns ( bool ) {
        require( token_ != OHM );
        require( token_ != LP );
        IERC20( token_ ).safeTransfer( DAO, IERC20( token_ ).balanceOf( address(this) ) );
        return true;
    }
}