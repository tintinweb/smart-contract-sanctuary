/**
 *Submitted for verification at BscScan.com on 2021-12-13
*/

pragma solidity ^0.8.10;

// ----------------------------------------------------------------------------
// --- Name   : AlphaDAO - [https://www.alphadao.financial/]
// --- Symbol : Format - {OX}
// --- Supply : Generated from DAO
// --- @title : the Beginning and the End 
// --- 01000110 01101111 01110010 00100000 01110100 01101000 01100101 00100000 01101100 
// --- 01101111 01110110 01100101 00100000 01101111 01100110 00100000 01101101 01111001 
// --- 00100000 01100011 01101000 01101001 01101100 01100100 01110010 01100101 01101110
// --- AlphaDAO.financial - EJS32 - 2021
// --- @dev pragma solidity version:0.8.10+commit.fc410830
// --- SPDX-License-Identifier: MIT
// ----------------------------------------------------------------------------

// ----------------------------------------------------------------------------
// --- Interface IOwnable
// ----------------------------------------------------------------------------

interface IOwnable {
  function policy() external view returns (address);

  function renounceManagement() external;
  
  function pushManagement( address newOwner_ ) external;
  
  function pullManagement() external;
}

// ----------------------------------------------------------------------------
// --- Contract Ownable
// ----------------------------------------------------------------------------

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

// ----------------------------------------------------------------------------
// --- Library SafeMath
// ----------------------------------------------------------------------------

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

// ----------------------------------------------------------------------------
// --- Library Address
// ----------------------------------------------------------------------------

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
        return _functionCallWithValue(target, data, 0, errorMessage);
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

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
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

    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");
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
        bytes32 _bytes = bytes32(uint256(uint160(_address)));
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




// ----------------------------------------------------------------------------
// --- Interface IERC20
// ----------------------------------------------------------------------------

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

// ----------------------------------------------------------------------------
// --- Library SafeERC20
// ----------------------------------------------------------------------------

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
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// ----------------------------------------------------------------------------
// --- Library FullMath 
// ----------------------------------------------------------------------------

library FullMath {

    function mulDiv(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {

            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(a, b, not(0))
                prod0 := mul(a, b)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }
        
            if (prod1 == 0) {
                require(denominator > 0);
                assembly {
                    result := div(prod0, denominator)
                }
                return result;
            }
        
            require(denominator > prod1);
        
            uint256 remainder;
            assembly {
                remainder := mulmod(a, b, denominator)
            }
            assembly {
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            uint256 twos = (type(uint256).max - denominator + 1) & denominator;

            assembly {
                denominator := div(denominator, twos)
            }
    
            assembly {
                prod0 := div(prod0, twos)
            }

            assembly {
                twos := add(div(sub(0, twos), twos), 1)
            }
            prod0 |= prod1 * twos;
    
            uint256 inv = (3 * denominator) ^ 2;

            inv *= 2 - denominator * inv; // inverse mod 2**8
            inv *= 2 - denominator * inv; // inverse mod 2**16
            inv *= 2 - denominator * inv; // inverse mod 2**32
            inv *= 2 - denominator * inv; // inverse mod 2**64
            inv *= 2 - denominator * inv; // inverse mod 2**128
            inv *= 2 - denominator * inv; // inverse mod 2**256
    
            result = prod0 * inv;
            return result;
        }
    }
}

// ----------------------------------------------------------------------------
// --- Library FixedPoint
// ----------------------------------------------------------------------------

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
    uint256 private constant LOWER_MASK = 0xffffffffffffffffffffffffffff;

    function decode(uq112x112 memory self) internal pure returns (uint112) {
        return uint112(self._x >> RESOLUTION);
    }

    function decode112with18(uq112x112 memory self) internal pure returns (uint) {
        return uint(self._x) / 5192296858534827;
    }

    function fraction(uint256 numerator, uint256 denominator) internal pure returns (uq112x112 memory) {
        require(denominator > 0, 'FixedPoint::fraction: division by zero');
        if (numerator == 0) return FixedPoint.uq112x112(0);

        if (numerator <= type(uint144).max) {
            uint256 result = (numerator << RESOLUTION) / denominator;
            require(result <= type(uint144).max, 'FixedPoint::fraction: overflow');
            return uq112x112(uint224(result));
        } else {
            uint256 result = FullMath.mulDiv(numerator, Q112, denominator);
            require(result <= type(uint144).max, 'FixedPoint::fraction: overflow');
            return uq112x112(uint224(result));
        }
    }
}

// ----------------------------------------------------------------------------
// --- Interface ITreasury
// ----------------------------------------------------------------------------

interface ITreasury {
    function deposit( uint _amount, address _token, uint _profit ) external returns ( bool );
    function valueOf( address _token, uint _amount ) external view returns ( uint value_ );
    function mintRewards( address _recipient, uint _amount ) external;
}

// ----------------------------------------------------------------------------
// --- Interface IStaking
// ----------------------------------------------------------------------------

interface IStaking {
    function stake( uint _amount, address _recipient ) external returns ( bool );
}

// ----------------------------------------------------------------------------
// --- Interface IStakingHelper
// ----------------------------------------------------------------------------

interface IStakingHelper {
    function stake( uint _amount, address _recipient ) external;
}

// ----------------------------------------------------------------------------
// --- Contract AlphaCVXBondDepository
// ----------------------------------------------------------------------------

contract AlphaCVXBondDepository is Ownable {

    using FixedPoint for *;
    using SafeERC20 for IERC20;
    using SafeMath for uint;
    event BondCreated( uint deposit, uint indexed payout, uint indexed expires, uint indexed priceInUSD );
    event BondRedeemed( address indexed recipient, uint payout, uint remaining );
    event BondPriceChanged( uint indexed internalPrice, uint indexed debtRatio );
    event ControlVariableAdjustment( uint initialBCV, uint newBCV, uint adjustment, bool addition );
    address public immutable OX;
    address public immutable principal;
    address public immutable treasury;
    address public immutable DAO;
    address public staking;
    address public stakingHelper;
    bool public useHelper;
    Terms public terms;
    Adjust public adjustment;
    mapping( address => Bond ) public bondInfo;
    uint public totalDebt;
    uint public lastDecay;
    
    struct Terms {
        uint controlVariable;
        uint vestingTerm;
        uint minimumPrice;
        uint maxPayout;
        uint maxDebt;
    }

    struct Bond {
        uint payout; 
        uint vesting; 
        uint lastBlock;
        uint pricePaid;
    }

    struct Adjust {
        bool add;
        uint rate;
        uint target;
        uint buffer;
        uint lastBlock;
    }

    constructor ( 
        address _OX,
        address _principal,
        address _treasury, 
        address _DAO
    ) {
        require( _OX != address(0) );
        OX = _OX;
        require( _principal != address(0) );
        principal = _principal;
        require( _treasury != address(0) );
        treasury = _treasury;
        require( _DAO != address(0) );
        DAO = _DAO;
    }

    function initializeBondTerms( 
        uint _controlVariable, 
        uint _vestingTerm,
        uint _minimumPrice,
        uint _maxPayout,
        uint _maxDebt,
        uint _initialDebt
    ) external onlyPolicy() {
        require( currentDebt() == 0, "Debt must be 0 for initialization" );
        terms = Terms ({
            controlVariable: _controlVariable,
            vestingTerm: _vestingTerm,
            minimumPrice: _minimumPrice,
            maxPayout: _maxPayout,
            maxDebt: _maxDebt
        });
        totalDebt = _initialDebt;
        lastDecay = block.number;
    }

    enum PARAMETER { VESTING, PAYOUT, DEBT }

    function setBondTerms ( PARAMETER _parameter, uint _input ) external onlyPolicy() {
        if ( _parameter == PARAMETER.VESTING ) { 
            require( _input >= 10000, "Vesting must be longer than 36 hours" );
            terms.vestingTerm = _input;
        } else if ( _parameter == PARAMETER.PAYOUT ) {
            require( _input <= 1000, "Payout cannot be above 1 percent" );
            terms.maxPayout = _input;
        } else if ( _parameter == PARAMETER.DEBT ) {
            terms.maxDebt = _input;
        }
    }

    function setAdjustment ( 
        bool _addition,
        uint _increment, 
        uint _target,
        uint _buffer 
    ) external onlyPolicy() {
        require( _increment <= terms.controlVariable.mul( 25 ).div( 1000 ), "Increment too large" );
        adjustment = Adjust({
            add: _addition,
            rate: _increment,
            target: _target,
            buffer: _buffer,
            lastBlock: block.number
        });
    }

    function setStaking( address _staking, bool _helper ) external onlyPolicy() {
        require( _staking != address(0) );
        if ( _helper ) {
            useHelper = true;
            stakingHelper = _staking;
        } else {
            useHelper = false;
            staking = _staking;
        }
    }

    function deposit( 
        uint _amount, 
        uint _maxPrice,
        address _depositor
    ) external returns ( uint ) {
        require( _depositor != address(0), "Invalid address" );
        decayDebt();
        require( totalDebt <= terms.maxDebt, "Max capacity reached" );
        uint nativePrice = _bondPrice();
        require( _maxPrice >= nativePrice, "Slippage limit: more than max price" ); 
        uint value = ITreasury( treasury ).valueOf( principal, _amount );
        uint payout = payoutFor( value ); 
        require( payout >= 10000000, "Bond too small" );
        require( payout <= maxPayout(), "Bond too large");

        IERC20( principal ).safeTransferFrom( msg.sender, treasury, _amount );
        ITreasury( treasury ).mintRewards( address(this), payout );
        totalDebt = totalDebt.add( value ); 

        bondInfo[ _depositor ] = Bond({ 
            payout: bondInfo[ _depositor ].payout.add( payout ),
            vesting: terms.vestingTerm,
            lastBlock: block.number,
            pricePaid: nativePrice
        });

        emit BondCreated( _amount, payout, block.number.add( terms.vestingTerm ), nativePrice );
        emit BondPriceChanged( _bondPrice(), debtRatio() );
        adjust(); 
        return payout; 
    }
 
    function redeem( address _recipient, bool _stake ) external returns ( uint ) {        
        Bond memory info = bondInfo[ _recipient ];
        uint percentVested = percentVestedFor( _recipient );

        if ( percentVested >= 10000 ) { 
            delete bondInfo[ _recipient ]; 
            emit BondRedeemed( _recipient, info.payout, 0 ); 
            return stakeOrSend( _recipient, _stake, info.payout ); 

        } else {
            uint payout = info.payout.mul( percentVested ).div( 10000 );
            bondInfo[ _recipient ] = Bond({
                payout: info.payout.sub( payout ),
                vesting: info.vesting.sub( block.number.sub( info.lastBlock ) ),
                lastBlock: block.number,
                pricePaid: info.pricePaid
            });

            emit BondRedeemed( _recipient, payout, bondInfo[ _recipient ].payout );
            return stakeOrSend( _recipient, _stake, payout );
        }
    }

    function stakeOrSend( address _recipient, bool _stake, uint _amount ) internal returns ( uint ) {
        if ( !_stake ) { 
            IERC20( OX ).safeTransfer( _recipient, _amount ); 
        } else { 
            if ( useHelper ) { 
                IERC20( OX ).approve( stakingHelper, _amount );
                IStakingHelper( stakingHelper ).stake( _amount, _recipient );
            } else {
                IERC20( OX ).approve( staking, _amount );
                IStaking( staking ).stake( _amount, _recipient );
            }
        }
        return _amount;
    }

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

    function decayDebt() internal {
        totalDebt = totalDebt.sub( debtDecay() );
        lastDecay = block.number;
    }

    function maxPayout() public view returns ( uint ) {
        return IERC20( OX ).totalSupply().mul( terms.maxPayout ).div( 100000 );
    }

    function payoutFor( uint _value ) public view returns ( uint ) {
        return FixedPoint.fraction( _value, bondPrice() ).decode112with18().div( 1e14 );
    }

    function bondPrice() public view returns ( uint price_ ) {        
        price_ = terms.controlVariable.mul( debtRatio() ).div( 1e5 );
        if ( price_ < terms.minimumPrice ) {
            price_ = terms.minimumPrice;
        }
    }

    function _bondPrice() internal returns ( uint price_ ) {
        price_ = terms.controlVariable.mul( debtRatio() ).div( 1e5 );
        if ( price_ < terms.minimumPrice ) {
            price_ = terms.minimumPrice;        
        } else if ( terms.minimumPrice != 0 ) {
            terms.minimumPrice = 0;
        }
    }

    function debtRatio() public view returns ( uint debtRatio_ ) {   
        uint supply = IERC20( OX ).totalSupply();
        debtRatio_ = FixedPoint.fraction( 
            currentDebt().mul( 1e9 ), 
            supply
        ).decode112with18().div( 1e18 );
    }

    function currentDebt() public view returns ( uint ) {
        return totalDebt.sub( debtDecay() );
    }

    function debtDecay() public view returns ( uint decay_ ) {
        uint blocksSinceLast = block.number.sub( lastDecay );
        decay_ = totalDebt.mul( blocksSinceLast ).div( terms.vestingTerm );
        if ( decay_ > totalDebt ) {
            decay_ = totalDebt;
        }
    }

    function percentVestedFor( address _depositor ) public view returns ( uint percentVested_ ) {
        Bond memory bond = bondInfo[ _depositor ];
        uint blocksSinceLast = block.number.sub( bond.lastBlock );
        uint vesting = bond.vesting;
        if ( vesting > 0 ) {
            percentVested_ = blocksSinceLast.mul( 10000 ).div( vesting );
        } else {
            percentVested_ = 0;
        }
    }

    function pendingPayoutFor( address _depositor ) external view returns ( uint pendingPayout_ ) {
        uint percentVested = percentVestedFor( _depositor );
        uint payout = bondInfo[ _depositor ].payout;
        if ( percentVested >= 10000 ) {
            pendingPayout_ = payout;
        } else {
            pendingPayout_ = payout.mul( percentVested ).div( 10000 );
        }
    }

    function recoverLostToken( address _token ) external returns ( bool ) {
        require( _token != OX );
        require( _token != principal );
        IERC20( _token ).safeTransfer( DAO, IERC20( _token ).balanceOf( address(this) ) );
        return true;
    }
}