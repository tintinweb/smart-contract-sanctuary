// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "./interfaces/IBondCalculator.sol";
import "./interfaces/IERC20Extended.sol";
import "./interfaces/IStaking.sol";
import "./interfaces/ITreasury.sol";
import "./libraries/FixedPoint.sol";
import "./libraries/SafeMathExtended.sol";


contract BondDepository is Ownable {

    using FixedPoint for *;
    using SafeERC20 for IERC20;
    using SafeMathExtended for uint;
    using SafeMathExtended for uint32;

    event BondCreated( uint deposit, uint indexed payout, uint indexed expires, uint indexed priceInUSD );
    event BondRedeemed( address indexed recipient, uint payout, uint remaining );
    event BondPriceChanged( uint indexed priceInUSD, uint indexed internalPrice, uint indexed debtRatio );
    event ControlVariableAdjustment( uint initialBCV, uint newBCV, uint adjustment, bool addition );

    /* ======== STATE VARIABLES ======== */

    address public immutable KEEPER; // token given as payment for bond
    address public immutable principle; // token used to create bond
    address public immutable treasury; // mints KEEPER when receives principle
    address public immutable DAO; // receives profit share from bond

    address public immutable bondCalculator; // calculates value of LP tokens
    bool public immutable isLiquidityBond; // LP and Reserve bonds are treated slightly different

    address public staking; // to auto-stake payout
    Terms public terms; // stores terms for new bonds
    Adjust public adjustment; // stores adjustment to BCV data

    mapping( address => Bond ) public bondInfo; // stores bond information for depositors

    uint public totalDebt; // total value of outstanding bonds; used for pricing
    uint32 public lastDecay; // reference time for debt decay

    /* ======== STRUCTS ======== */

    // Info for creating new bonds
    struct Terms {
        uint controlVariable; // scaling variable for price
        uint minimumPrice; // vs principle value
        uint maxPayout; // in thousandths of a %. i.e. 500 = 0.5%
        uint fee; // as % of bond payout, in hundreths. ( 500 = 5% = 0.05 for every 1 paid)
        uint maxDebt; // 9 decimal debt ratio, max % total supply created as debt
        uint32 vestingTerm; // in seconds
    }

    // Info for bond holder
    struct Bond {
        uint payout; // KEEPER remaining to be paid
        uint pricePaid; // In DAI, for front end viewing
        uint32 vesting; // seconds left to vest
        uint32 lastTime; // Last interaction
    }

    // Info for incremental adjustments to control variable 
    struct Adjust {
        bool add; // addition or subtraction
        uint rate; // increment
        uint target; // BCV when adjustment finished
        uint32 buffer; // minimum length (in seconds) between adjustments
        uint32 lastTime; // timestamp when last adjustment made
    }

    constructor ( address _KEEPER, address _principle, address _staking, address _treasury, address _DAO, address _bondCalculator) {
        require( _KEEPER != address(0) );
        KEEPER = _KEEPER;
        require( _principle != address(0) );
        principle = _principle;
        require( _treasury != address(0) );
        treasury = _treasury;
        require( _DAO != address(0) );
        DAO = _DAO;
        require( _staking != address(0) );
        staking = _staking;
        // bondCalculator should be address(0) if not LP bond
        bondCalculator = _bondCalculator;
        isLiquidityBond = ( _bondCalculator != address(0) );
    }

    /**
     *  @notice initializes bond parameters
     *  @param _controlVariable uint
     *  @param _vestingTerm uint
     *  @param _minimumPrice uint
     *  @param _maxPayout uint
     *  @param _fee uint
     *  @param _maxDebt uint
     *  @param _initialDebt uint
     */
    function initializeBondTerms(uint _controlVariable, uint32 _vestingTerm, uint _minimumPrice, uint _maxPayout,
                                 uint _fee, uint _maxDebt, uint _initialDebt)
    external onlyOwner() {
        require( terms.controlVariable == 0 && terms.vestingTerm == 0, "Bonds must be initialized from 0" );
        terms = Terms ({
            controlVariable: _controlVariable,
            vestingTerm: _vestingTerm,
            minimumPrice: _minimumPrice,
            maxPayout: _maxPayout,
            fee: _fee,
            maxDebt: _maxDebt
        });
        totalDebt = _initialDebt;
        lastDecay = uint32(block.timestamp);
    }

    /* ======== POLICY FUNCTIONS ======== */

    enum PARAMETER { VESTING, PAYOUT, FEE, DEBT, MINPRICE }
    /**
     *  @notice set parameters for new bonds
     *  @param _parameter PARAMETER
     *  @param _input uint
     */
    function setBondTerms ( PARAMETER _parameter, uint _input ) external onlyOwner() {
        if ( _parameter == PARAMETER.VESTING ) { // 0
            require( _input >= 129600, "Vesting must be longer than 36 hours" );
            decayDebt();
            require( totalDebt == 0, "Debt should be 0." );
            terms.vestingTerm = uint32(_input);
        }
        else if ( _parameter == PARAMETER.PAYOUT ) { // 1
            require( _input <= 1000, "Payout cannot be above 1 percent" );
            terms.maxPayout = _input;
        } else if ( _parameter == PARAMETER.FEE ) { // 2
            require( _input <= 10000, "DAO fee cannot exceed payout" );
            terms.fee = _input;
        } else if ( _parameter == PARAMETER.DEBT ) { // 3
            terms.maxDebt = _input;
        } else if ( _parameter == PARAMETER.MINPRICE ) { // 4
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
    function setAdjustment ( bool _addition, uint _increment, uint _target, uint32 _buffer) external onlyOwner() {
        require( _increment <= terms.controlVariable.mul( 25 ).div( 1000 ), "Increment too large" );

        adjustment = Adjust({
            add: _addition,
            rate: _increment,
            target: _target,
            buffer: _buffer,
            lastTime: uint32(block.timestamp)
        });
    }

    /**
     *  @notice set contract for auto stake
     *  @param _staking address
     */
    // function setStaking( address _staking ) external onlyOwner() {
    //     require( _staking != address(0) );
    //     staking = _staking;
    // }


    /* ======== USER FUNCTIONS ======== */

    /**
     *  @notice deposit bond
     *  @param _amount uint
     *  @param _maxPrice uint
     *  @param _depositor address
     *  @return uint
     */
    function deposit( uint _amount, uint _maxPrice, address _depositor) external returns ( uint ) {
        require( _depositor != address(0), "Invalid address" );
        decayDebt();
        
        uint priceInUSD = bondPriceInUSD(); // Stored in bond info
        uint nativePrice = _bondPrice();

        require( _maxPrice >= nativePrice, "Slippage limit: more than max price" ); // slippage protection

        uint value = ITreasury( treasury ).valueOfToken( principle, _amount );
        uint payout = payoutFor( value ); // payout to bonder is computed

        require( payout >= 10000000, "Bond too small" ); // must be > 0.01 KEEPER ( underflow protection )
        require( payout <= maxPayout(), "Bond too large"); // size protection because there is no slippage

        // profits are calculated
        uint fee = payout.mul( terms.fee ).div( 10000 );
        uint profit = value.sub( payout ).sub( fee );

        /**
            principle is transferred in
            approved and
            deposited into the treasury, returning (_amount - profit) KEEPER
         */
        IERC20( principle ).safeTransferFrom( msg.sender, address(this), _amount );
        IERC20( principle ).approve( address( treasury ), _amount );
        ITreasury( treasury ).deposit( _amount, principle, profit );
        
        if ( fee != 0 ) { // fee is transferred to dao 
            IERC20( KEEPER ).safeTransfer( DAO, fee ); 
        }
        
        // total debt is increased
        totalDebt = totalDebt.add( value ); 
        require( totalDebt <= terms.maxDebt, "Max capacity reached" );
                
        // depositor info is stored
        bondInfo[ _depositor ] = Bond({ 
            payout: bondInfo[ _depositor ].payout.add( payout ),
            vesting: terms.vestingTerm,
            lastTime: uint32(block.timestamp),
            pricePaid: priceInUSD
        });

        // indexed events are emitted
        emit BondCreated( _amount, payout, block.timestamp.add( terms.vestingTerm ), priceInUSD );
        emit BondPriceChanged( bondPriceInUSD(), _bondPrice(), debtRatio() );

        adjust(); // control variable is adjusted
        return payout; 
    }

    /** 
     *  @notice redeem bond for user
     *  @param _recipient address
     *  @param _stake bool
     *  @return uint
     */ 
    function redeem( address _recipient, bool _stake, bool _wrap ) external returns ( uint ) {        
        Bond memory info = bondInfo[ _recipient ];
        uint percentVested = percentVestedFor( _recipient ); // (blocks since last interaction / vesting term remaining)

        if ( percentVested >= 10000 ) { // if fully vested
            delete bondInfo[ _recipient ]; // delete user info
            emit BondRedeemed( _recipient, info.payout, 0 ); // emit bond data
            return stakeOrSend( _recipient, _stake, _wrap, info.payout ); // pay user everything due

        } else { // if unfinished
            // calculate payout vested
            uint payout = info.payout.mul( percentVested ).div( 10000 );

            // store updated deposit info
            bondInfo[ _recipient ] = Bond({
                payout: info.payout.sub( payout ),
                vesting: info.vesting.sub32( uint32(block.timestamp).sub32( info.lastTime ) ),
                lastTime: uint32(block.timestamp),
                pricePaid: info.pricePaid
            });

            emit BondRedeemed( _recipient, payout, bondInfo[ _recipient ].payout );
            return stakeOrSend( _recipient, _stake, _wrap, payout );
        }
    }



    
    /* ======== INTERNAL HELPER FUNCTIONS ======== */

    /**
     *  @notice allow user to stake payout automatically
     *  @param _stake bool
     *  @param _amount uint
     *  @return uint
     */
    function stakeOrSend( address _recipient, bool _stake, bool _wrap, uint _amount ) internal returns ( uint ) {
        if ( !_stake ) { // if user does not want to stake
            IERC20( KEEPER ).transfer( _recipient, _amount ); // send payout
        } else { // if user wants to stake
            IERC20( KEEPER ).approve( staking, _amount );
            IStaking( staking ).stake( _amount, _recipient, _wrap );
        }
        return _amount;
    }

    /**
     *  @notice makes incremental adjustment to control variable
     */
    function adjust() internal {
        uint timeCanAdjust = adjustment.lastTime.add( adjustment.buffer );
        if( adjustment.rate != 0 && block.timestamp >= timeCanAdjust ) {
            uint initial = terms.controlVariable;
            if ( adjustment.add ) {
                terms.controlVariable = terms.controlVariable.add( adjustment.rate );
                if ( terms.controlVariable >= adjustment.target ) {
                    adjustment.rate = 0;
                }
            } else {
                terms.controlVariable = terms.controlVariable.sub( adjustment.rate );
                if ( terms.controlVariable <= adjustment.target || terms.controlVariable < adjustment.rate ) {
                    adjustment.rate = 0;
                }
            }
            adjustment.lastTime = uint32(block.timestamp);
            emit ControlVariableAdjustment( initial, terms.controlVariable, adjustment.rate, adjustment.add );
        }
    }

    /**
     *  @notice reduce total debt
     */
    function decayDebt() internal {
        totalDebt = totalDebt.sub( debtDecay() );
        lastDecay = uint32(block.timestamp);
    }



    /* ======== VIEW FUNCTIONS ======== */

    /**
     *  @notice determine maximum bond size
     *  @return uint
     */
    function maxPayout() public view returns ( uint ) {
        return IERC20( KEEPER ).totalSupply().mul( terms.maxPayout ).div( 100000 );
    }

    /**
     *  @notice calculate interest due for new bond
     *  @param _value uint
     *  @return uint
     */
    function payoutFor( uint _value ) public view returns ( uint ) {
        return FixedPoint.fraction( _value, bondPrice() ).decode112with18().div( 1e16 );
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
    }

    /**
     *  @notice converts bond price to DAI value
     *  @return price_ uint
     */
    function bondPriceInUSD() public view returns ( uint price_ ) {
        if( isLiquidityBond ) {
            price_ = bondPrice().mul( IBondCalculator( bondCalculator ).markdown( principle ) ).div( 100 );
        } else {
            price_ = bondPrice().mul( 10 ** IERC20Extended( principle ).decimals() ).div( 100 );
        }
    }


    /**
     *  @notice calculate current ratio of debt to KEEPER supply
     *  @return debtRatio_ uint
     */
    function debtRatio() public view returns ( uint debtRatio_ ) {   
        uint supply = IERC20( KEEPER ).totalSupply();
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
        uint32 timeSinceLast = uint32(block.timestamp).sub32( lastDecay );
        decay_ = totalDebt.mul( timeSinceLast ).div( terms.vestingTerm );
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
        Bond memory bond = bondInfo[ _depositor ];
        uint timeSinceLast = uint32(block.timestamp).sub( bond.lastTime );
        uint vesting = bond.vesting;

        if ( vesting > 0 ) {
            percentVested_ = timeSinceLast.mul( 10000 ).div( vesting );
        } else {
            percentVested_ = 0;
        }
    }

    /**
     *  @notice calculate amount of KEEPER available for claim by depositor
     *  @param _depositor address
     *  @return pendingPayout_ uint
     */
    function pendingPayoutFor( address _depositor ) external view returns ( uint pendingPayout_ ) {
        uint percentVested = percentVestedFor( _depositor );
        uint payout = bondInfo[ _depositor ].payout;

        if ( percentVested >= 10000 ) {
            pendingPayout_ = payout;
        } else {
            pendingPayout_ = payout.mul( percentVested ).div( 10000 );
        }
    }




    /* ======= AUXILLIARY ======= */

    /**
     *  @notice allow anyone to send lost tokens (excluding principle or KEEPER) to the DAO
     *  @return bool
     */
    function recoverLostToken( address _token ) external returns ( bool ) {
        require( _token != KEEPER );
        require( _token != principle );
        IERC20( _token ).safeTransfer( DAO, IERC20( _token ).balanceOf( address(this) ) );
        return true;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "../utils/Context.sol";
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
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

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

interface IBondCalculator {
    function markdown( address _LP ) external view returns ( uint );

    function valuation( address pair_, uint amount_ ) external view returns ( uint _value );
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.7.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IERC20Extended is IERC20 {
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

interface IStaking {
    function stake( uint _amount, address _recipient, bool _wrap ) external returns ( uint );

    function claim ( address _recipient ) external returns ( uint );

    function forfeit() external returns ( uint );

    function toggleLock() external;

    function unstake( uint _amount, bool _trigger ) external returns ( uint );

    function rebase() external;

    function index() external view returns ( uint );

    function contractBalance() external view returns ( uint );

    function totalStaked() external view returns ( uint );

    function supplyInWarmup() external view returns ( uint );
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;


interface ITreasury {

    function deposit( uint _amount, address _token, uint _profit ) external returns ( uint );
    
    function withdraw( uint _amount, address _token ) external;

    function valueOfToken( address _token, uint _amount ) external view returns ( uint value_ );
  
    function mint( address _recipient, uint _amount ) external;

    function mintRewards( address _recipient, uint _amount ) external;

    function incurDebt( uint amount_, address token_ ) external;
    
    function repayDebtWithReserve( uint amount_, address token_ ) external;
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity >=0.5.0 <0.8.0;

import "./FullMath.sol";


library Babylonian {

    function sqrt(uint256 x) internal pure returns (uint256) {
        if (x == 0) return 0;

        uint256 xx = x;
        uint256 r = 1;
        if (xx >= 0x100000000000000000000000000000000) {
            xx >>= 128;
            r <<= 64;
        }
        if (xx >= 0x10000000000000000) {
            xx >>= 64;
            r <<= 32;
        }
        if (xx >= 0x100000000) {
            xx >>= 32;
            r <<= 16;
        }
        if (xx >= 0x10000) {
            xx >>= 16;
            r <<= 8;
        }
        if (xx >= 0x100) {
            xx >>= 8;
            r <<= 4;
        }
        if (xx >= 0x10) {
            xx >>= 4;
            r <<= 2;
        }
        if (xx >= 0x8) {
            r <<= 1;
        }
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1; // Seven iterations should be enough
        uint256 r1 = x / r;
        return (r < r1 ? r : r1);
    }
}

library BitMath {

    function mostSignificantBit(uint256 x) internal pure returns (uint8 r) {
        require(x > 0, 'BitMath::mostSignificantBit: zero');

        if (x >= 0x100000000000000000000000000000000) {
            x >>= 128;
            r += 128;
        }
        if (x >= 0x10000000000000000) {
            x >>= 64;
            r += 64;
        }
        if (x >= 0x100000000) {
            x >>= 32;
            r += 32;
        }
        if (x >= 0x10000) {
            x >>= 16;
            r += 16;
        }
        if (x >= 0x100) {
            x >>= 8;
            r += 8;
        }
        if (x >= 0x10) {
            x >>= 4;
            r += 4;
        }
        if (x >= 0x4) {
            x >>= 2;
            r += 2;
        }
        if (x >= 0x2) r += 1;
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

    // square root of a UQ112x112
    // lossy between 0/1 and 40 bits
    function sqrt(uq112x112 memory self) internal pure returns (uq112x112 memory) {
        if (self._x <= uint144(-1)) {
            return uq112x112(uint224(Babylonian.sqrt(uint256(self._x) << 112)));
        }

        uint8 safeShiftBits = 255 - BitMath.mostSignificantBit(self._x);
        safeShiftBits -= safeShiftBits % 2;
        return uq112x112(uint224(Babylonian.sqrt(uint256(self._x) << safeShiftBits) << ((112 - safeShiftBits) / 2)));
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

library SafeMathExtended {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function add32(uint32 a, uint32 b) internal pure returns (uint32) {
        uint32 c = a + b;
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

    function sub32(uint32 a, uint32 b) internal pure returns (uint32) {
        return sub32(a, b, "SafeMath: subtraction overflow");
    }

    function sub32(uint32 a, uint32 b, string memory errorMessage) internal pure returns (uint32) {
        require(b <= a, errorMessage);
        uint32 c = a - b;

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

    function mul32(uint32 a, uint32 b) internal pure returns (uint32) {
        if (a == 0) {
            return 0;
        }

        uint32 c = a * b;
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
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
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity >=0.5.0 <0.8.0;

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

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "./interfaces/IBondCalculator.sol";
import "./interfaces/AggregateV3Interface.sol";
import "./interfaces/ITreasury.sol";
import "./interfaces/IsKEEPER.sol";
import "./interfaces/IwTROVE.sol";
import "./interfaces/IStaking.sol";
import "./libraries/FixedPoint.sol";
import "./libraries/SafeMathExtended.sol";


contract VLPBondStakeDepository is Ownable {
    using FixedPoint for *;
    using SafeERC20 for IERC20;
    using SafeMathExtended for uint;
    using SafeMathExtended for uint32;

    /* ======== EVENTS ======== */

    event BondCreated( uint deposit, uint indexed payout, uint indexed expires, uint indexed priceInUSD );
    event BondRedeemed( address indexed recipient, uint payout, uint remaining );
    event BondPriceChanged( uint indexed priceInUSD, uint indexed internalPrice, uint indexed debtRatio );
    event ControlVariableAdjustment( uint initialBCV, uint newBCV, uint adjustment, bool addition );

    /* ======== STATE VARIABLES ======== */

    address public immutable KEEPER; // token given as payment for bond
    address public immutable sKEEPER; // token given as payment for bond
    address public immutable wTROVE; // Wrap sKEEPER
    address public immutable principle; // token used to create bond
    address public immutable treasury; // mints KEEPER when receives principle

    address public immutable bondCalculator; // calculates value of LP tokens

    AggregatorV3Interface internal priceFeed;

    address public staking; // to auto-stake payout

    Terms public terms; // stores terms for new bonds
    Adjust public adjustment; // stores adjustment to BCV data

    mapping( address => Bond ) public bondInfo; // stores bond information for depositors

    uint public totalDebt; // total value of outstanding bonds; used for pricing
    uint32 public lastDecay; // reference block for debt decay


    /* ======== STRUCTS ======== */

    // Info for creating new bonds
    struct Terms {
        uint32 vestingTerm; // in seconds
        uint controlVariable; // scaling variable for price
        uint minimumPrice; // vs principle value. 4 decimals (1500 = 0.15)
        uint maxPayout; // in thousandths of a %. i.e. 500 = 0.5%
        uint maxDebt; // 9 decimal debt ratio, max % total supply created as debt
    }

    // Info for bond holder
    struct Bond {
        uint32 vesting; // seconds left to vest
        uint32 lastTime; // Last interaction
        uint gonsPayout; // KEEPER remaining to be paid
        uint pricePaid; // In DAI, for front end viewing
    }

    // Info for incremental adjustments to control variable 
    struct Adjust {
        bool add; // addition or subtraction
        uint rate; // increment
        uint target; // BCV when adjustment finished
        uint32 buffer; // minimum length (in blocks) between adjustments
        uint32 lastTime; // block when last adjustment made
    }

    /* ======== INITIALIZATION ======== */

    constructor ( address _KEEPER, address _sKEEPER, address _wTROVE, address _principle, address _staking, address _treasury, address _bondCalculator, address _feed) {
        require( _KEEPER != address(0) );
        KEEPER = _KEEPER;
        require( _sKEEPER != address(0) );
        sKEEPER = _sKEEPER;
        require( _wTROVE != address(0) );
        wTROVE = _wTROVE;
        require( _principle != address(0) );
        principle = _principle;
        require( _treasury != address(0) );
        treasury = _treasury;
        require( _staking != address(0) );
        staking = _staking;
        require( _bondCalculator != address(0) );
        bondCalculator = _bondCalculator;
        require( _feed != address(0) );
        priceFeed = AggregatorV3Interface( _feed );
    }

    /**
     *  @notice initializes bond parameters
     *  @param _controlVariable uint
     *  @param _vestingTerm uint
     *  @param _minimumPrice uint
     *  @param _maxPayout uint
     *  @param _maxDebt uint
     *  @param _initialDebt uint
     */
    function initializeBondTerms(uint _controlVariable, uint32 _vestingTerm, uint _minimumPrice, uint _maxPayout,
                                 uint _maxDebt, uint _initialDebt) external onlyOwner() {
        require( terms.controlVariable == 0 && terms.vestingTerm == 0, "Bonds must be initialized from 0" );
        terms = Terms ({
            controlVariable: _controlVariable,
            vestingTerm: _vestingTerm,
            minimumPrice: _minimumPrice,
            maxPayout: _maxPayout,
            maxDebt: _maxDebt
        });
        totalDebt = _initialDebt;
        lastDecay = uint32(block.timestamp);
    }


    
    /* ======== POLICY FUNCTIONS ======== */

    enum PARAMETER { VESTING, PAYOUT, DEBT, MINPRICE }
    /**
     *  @notice set parameters for new bonds
     *  @param _parameter PARAMETER
     *  @param _input uint
     */
    function setBondTerms ( PARAMETER _parameter, uint _input ) external onlyOwner() {
        if ( _parameter == PARAMETER.VESTING ) { // 0
            require( _input >= 129600, "Vesting must be longer than 36 hours" );
            require( currentDebt() == 0, "Debt should be 0." );
            terms.vestingTerm = uint32(_input);
        } else if ( _parameter == PARAMETER.PAYOUT ) { // 1
            require( _input <= 1000, "Payout cannot be above 1 percent" );
            terms.maxPayout = _input;
        } else if ( _parameter == PARAMETER.DEBT ) { // 2
            terms.maxDebt = _input;
        } else if ( _parameter == PARAMETER.MINPRICE ) { // 3
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
    function setAdjustment ( bool _addition, uint _increment, uint _target, uint32 _buffer ) external onlyOwner() {
        require( _increment <= terms.controlVariable.mul( 25 ).div( 1000 ), "Increment too large" );

        adjustment = Adjust({
            add: _addition,
            rate: _increment,
            target: _target,
            buffer: _buffer,
            lastTime: uint32(block.timestamp)
        });
    }

    /**
     *  @notice set contract for auto stake
     *  @param _staking address
     */
    // function setStaking( address _staking ) external onlyOwner() {
    //     require( _staking != address(0) );
    //     staking = _staking;
    // }


    /* ======== USER FUNCTIONS ======== */

    /**
     *  @notice deposit bond
     *  @param _amount uint
     *  @param _maxPrice uint
     *  @param _depositor address
     *  @return uint
     */
    function deposit( uint _amount, uint _maxPrice, address _depositor) external returns ( uint ) {
        require( _depositor != address(0), "Invalid address" );
        decayDebt();
        
        uint priceInUSD = bondPriceInUSD(); // Stored in bond info
        uint nativePrice = _bondPrice();

        require( _maxPrice >= nativePrice, "Slippage limit: more than max price" ); // slippage protection

        uint value = ITreasury( treasury ).valueOfToken( principle, _amount );
        uint payout = payoutFor( value ); // payout to bonder is computed

        require( payout >= 10000000, "Bond too small" ); // must be > 0.01 KEEPER ( underflow protection )
        require( payout <= maxPayout(), "Bond too large"); // size protection because there is no slippage

        /**
            asset carries risk and is not minted against
            asset transfered to treasury and rewards minted as payout
         */
        IERC20( principle ).safeTransferFrom( msg.sender, treasury, _amount );
        ITreasury( treasury ).mintRewards( address(this), payout );
        
        // total debt is increased
        totalDebt = totalDebt.add( value ); 
        require( totalDebt <= terms.maxDebt, "Max capacity reached" );
                
        IERC20( KEEPER ).approve( staking, payout );
        IStaking( staking ).stake( payout, address(this), false );
        IStaking( staking ).claim( address(this) );
        uint stakeGons = IsKEEPER(sKEEPER).gonsForBalance(payout);
                
        // depositor info is stored
        bondInfo[ _depositor ] = Bond({ 
            gonsPayout: bondInfo[ _depositor ].gonsPayout.add( stakeGons ),
            vesting: terms.vestingTerm,
            lastTime: uint32(block.timestamp),
            pricePaid: priceInUSD
        });

        // indexed events are emitted
        emit BondCreated( _amount, payout, block.timestamp.add( terms.vestingTerm ), priceInUSD );
        emit BondPriceChanged( bondPriceInUSD(), _bondPrice(), debtRatio() );

        adjust(); // control variable is adjusted
        return payout; 
    }

    /** 
     *  @notice redeem bond for user
     *  @param _recipient address
     *  @param _stake bool
     *  @return uint
     */ 
    function redeem( address _recipient, bool _stake, bool _wrap ) external returns ( uint ) {        
        Bond memory info = bondInfo[ _recipient ];
        uint percentVested = percentVestedFor( _recipient ); // (blocks since last interaction / vesting term remaining)

        if ( percentVested >= 10000 ) { // if fully vested
            delete bondInfo[ _recipient ]; // delete user info
            uint _amount = IsKEEPER(sKEEPER).balanceForGons(info.gonsPayout);
            emit BondRedeemed( _recipient, _amount, 0 ); // emit bond data
            return sendOrWrap( _recipient, _wrap, _amount ); // pay user everything due

        } else { // if unfinished
            // calculate payout vested
            uint gonsPayout = info.gonsPayout.mul( percentVested ).div( 10000 );
            // store updated deposit info
            bondInfo[ _recipient ] = Bond({
                gonsPayout: info.gonsPayout.sub( gonsPayout ),
                vesting: info.vesting.sub32( uint32(block.timestamp).sub32( info.lastTime ) ),
                lastTime: uint32(block.timestamp),
                pricePaid: info.pricePaid
            });

            uint _amount = IsKEEPER(sKEEPER).balanceForGons(gonsPayout);
            uint _remainingAmount = IsKEEPER(sKEEPER).balanceForGons(bondInfo[_recipient].gonsPayout);
            emit BondRedeemed( _recipient, _amount, _remainingAmount );
            return sendOrWrap( _recipient, _wrap, _amount );
        }
    }



    
    /* ======== INTERNAL HELPER FUNCTIONS ======== */

    /**
     *  @notice allow user to wrap payout automatically
     *  @param _wrap bool
     *  @param _amount uint
     *  @return uint
     */
    function sendOrWrap( address _recipient, bool _wrap, uint _amount ) internal returns ( uint ) {
        if ( _wrap ) { // if user wants to wrap
            IERC20(sKEEPER).approve( wTROVE, _amount );
            uint wrapValue = IwTROVE(wTROVE).wrap( _amount );
            IwTROVE(wTROVE).transfer( _recipient, wrapValue );
        } else { // if user wants to stake
            IERC20( sKEEPER ).transfer( _recipient, _amount ); // send payout
        }
        return _amount;
    }

    /**
     *  @notice makes incremental adjustment to control variable
     */
    function adjust() internal {
        uint timeCanAdjust = adjustment.lastTime.add( adjustment.buffer );
        if( adjustment.rate != 0 && block.timestamp >= timeCanAdjust ) {
            uint initial = terms.controlVariable;
            if ( adjustment.add ) {
                terms.controlVariable = terms.controlVariable.add( adjustment.rate );
                if ( terms.controlVariable >= adjustment.target ) {
                    adjustment.rate = 0;
                }
            } else {
                terms.controlVariable = terms.controlVariable.sub( adjustment.rate );
                if ( terms.controlVariable <= adjustment.target || terms.controlVariable < adjustment.rate ) {
                    adjustment.rate = 0;
                }
            }
            adjustment.lastTime = uint32(block.timestamp);
            emit ControlVariableAdjustment( initial, terms.controlVariable, adjustment.rate, adjustment.add );
        }
    }

    /**
     *  @notice reduce total debt
     */
    function decayDebt() internal {
        totalDebt = totalDebt.sub( debtDecay() );
        lastDecay = uint32(block.timestamp);
    }




    /* ======== VIEW FUNCTIONS ======== */

    /**
     *  @notice determine maximum bond size
     *  @return uint
     */
    function maxPayout() public view returns ( uint ) {
        return IERC20( KEEPER ).totalSupply().mul( terms.maxPayout ).div( 100000 );
    }

    /**
     *  @notice calculate interest due for new bond
     *  @param _value uint
     *  @return uint
     */
    function payoutFor( uint _value ) public view returns ( uint ) {
        return FixedPoint.fraction( _value, bondPrice() ).decode112with18().div( 1e14 );
    }


    /**
     *  @notice calculate current bond premium
     *  @return price_ uint
     */
    function bondPrice() public view returns ( uint price_ ) {        
        price_ = terms.controlVariable.mul( debtRatio() ).div( 1e5 );
        if ( price_ < terms.minimumPrice ) {
            price_ = terms.minimumPrice;
        }
    }

    /**
     *  @notice calculate current bond price and remove floor if above
     *  @return price_ uint
     */
    function _bondPrice() internal returns ( uint price_ ) {
        price_ = terms.controlVariable.mul( debtRatio() ).div( 1e5 );
        if ( price_ < terms.minimumPrice ) {
            price_ = terms.minimumPrice;        
        } else if ( terms.minimumPrice != 0 ) {
            terms.minimumPrice = 0;
        }
    }

    /**
     *  @notice get asset price from chainlink
     */
    function assetPrice() public view returns (int) {
        ( , int price, , , ) = priceFeed.latestRoundData();
        return price;
    }

    /**
     *  @notice converts bond price to DAI value
     *  @return price_ uint
     */
    function bondPriceInUSD() public view returns ( uint price_ ) {
        price_ = bondPrice()
                    .mul( IBondCalculator( bondCalculator ).markdown( principle ) )
                    .mul( uint( assetPrice() ) )
                    .div( 1e12 );
    }

    function getBondInfo(address _depositor) public view returns ( uint payout, uint vesting, uint lastTime, uint pricePaid ) {
        Bond memory info = bondInfo[ _depositor ];
        payout = IsKEEPER(sKEEPER).balanceForGons(info.gonsPayout);
        vesting = info.vesting;
        lastTime = info.lastTime;
        pricePaid = info.pricePaid;
    }

    /**
     *  @notice calculate current ratio of debt to KEEPER supply
     *  @return debtRatio_ uint
     */
    function debtRatio() public view returns ( uint debtRatio_ ) {   
        uint supply = IERC20( KEEPER ).totalSupply();
        debtRatio_ = FixedPoint.fraction( 
            currentDebt().mul( 1e9 ), 
            supply
        ).decode112with18().div( 1e18 );
    }

    /**
     *  @notice debt ratio in same terms as reserve bonds
     *  @return uint
     */
    function standardizedDebtRatio() external view returns ( uint ) {
        return debtRatio().mul( IBondCalculator( bondCalculator ).markdown( principle ) ).div( 1e9 );
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
        uint32 timeSinceLast = uint32(block.timestamp).sub32( lastDecay );
        decay_ = totalDebt.mul( timeSinceLast ).div( terms.vestingTerm );
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
        Bond memory bond = bondInfo[ _depositor ];
        uint timeSinceLast = uint32(block.timestamp).sub( bond.lastTime );
        uint vesting = bond.vesting;

        if ( vesting > 0 ) {
            percentVested_ = timeSinceLast.mul( 10000 ).div( vesting );
        } else {
            percentVested_ = 0;
        }
    }

    /**
     *  @notice calculate amount of KEEPER available for claim by depositor
     *  @param _depositor address
     *  @return pendingPayout_ uint
     */
    function pendingPayoutFor( address _depositor ) external view returns ( uint pendingPayout_ ) {
        uint percentVested = percentVestedFor( _depositor );
        uint payout = IsKEEPER(sKEEPER).balanceForGons(bondInfo[ _depositor ].gonsPayout);

        if ( percentVested >= 10000 ) {
            pendingPayout_ = payout;
        } else {
            pendingPayout_ = payout.mul( percentVested ).div( 10000 );
        }
    }

}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IsKEEPER is IERC20 {
    function rebase( uint256 profit_, uint epoch_) external returns (uint256);

    function circulatingSupply() external view returns (uint256);

    function balanceOf(address who) external override view returns (uint256);

    function gonsForBalance( uint amount ) external view returns ( uint );

    function balanceForGons( uint gons ) external view returns ( uint );
    
    function index() external view returns ( uint );
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IwTROVE is IERC20 {
    function wrap(uint _amount) external returns (uint);

    function unwrap(uint _amount) external returns (uint);
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "./interfaces/IBondCalculator.sol";
import "./interfaces/AggregateV3Interface.sol";
import "./interfaces/ITreasury.sol";
import "./interfaces/IStaking.sol";
import "./libraries/FixedPoint.sol";
import "./libraries/SafeMathExtended.sol";


contract VLPBondDepository is Ownable {
    using FixedPoint for *;
    using SafeERC20 for IERC20;
    using SafeMathExtended for uint;
    using SafeMathExtended for uint32;

    /* ======== EVENTS ======== */

    event BondCreated( uint deposit, uint indexed payout, uint indexed expires, uint indexed priceInUSD );
    event BondRedeemed( address indexed recipient, uint payout, uint remaining );
    event BondPriceChanged( uint indexed priceInUSD, uint indexed internalPrice, uint indexed debtRatio );
    event ControlVariableAdjustment( uint initialBCV, uint newBCV, uint adjustment, bool addition );

    /* ======== STATE VARIABLES ======== */

    address public immutable KEEPER; // token given as payment for bond
    address public immutable principle; // token used to create bond
    address public immutable treasury; // mints KEEPER when receives principle

    address public immutable bondCalculator; // calculates value of LP tokens

    AggregatorV3Interface internal priceFeed;

    address public staking; // to auto-stake payout

    Terms public terms; // stores terms for new bonds
    Adjust public adjustment; // stores adjustment to BCV data

    mapping( address => Bond ) public bondInfo; // stores bond information for depositors

    uint public totalDebt; // total value of outstanding bonds; used for pricing
    uint32 public lastDecay; // reference block for debt decay


    /* ======== STRUCTS ======== */

    // Info for creating new bonds
    struct Terms {
        uint32 vestingTerm; // in seconds
        uint controlVariable; // scaling variable for price
        uint minimumPrice; // vs principle value. 4 decimals (1500 = 0.15)
        uint maxPayout; // in thousandths of a %. i.e. 500 = 0.5%
        uint maxDebt; // 9 decimal debt ratio, max % total supply created as debt
    }

    // Info for bond holder
    struct Bond {
        uint32 vesting; // seconds left to vest
        uint32 lastTime; // Last interaction
        uint payout; // KEEPER remaining to be paid
        uint pricePaid; // In DAI, for front end viewing
    }

    // Info for incremental adjustments to control variable 
    struct Adjust {
        bool add; // addition or subtraction
        uint rate; // increment
        uint target; // BCV when adjustment finished
        uint32 buffer; // minimum length (in blocks) between adjustments
        uint32 lastTime; // block when last adjustment made
    }

    /* ======== INITIALIZATION ======== */

    constructor ( address _KEEPER, address _principle, address _staking, address _treasury, address _bondCalculator, address _feed) {
        require( _KEEPER != address(0) );
        KEEPER = _KEEPER;
        require( _principle != address(0) );
        principle = _principle;
        require( _treasury != address(0) );
        treasury = _treasury;
        require( _staking != address(0) );
        staking = _staking;
        require( _bondCalculator != address(0) );
        bondCalculator = _bondCalculator;
        require( _feed != address(0) );
        priceFeed = AggregatorV3Interface( _feed );
    }

    /**
     *  @notice initializes bond parameters
     *  @param _controlVariable uint
     *  @param _vestingTerm uint
     *  @param _minimumPrice uint
     *  @param _maxPayout uint
     *  @param _maxDebt uint
     *  @param _initialDebt uint
     */
    function initializeBondTerms(uint _controlVariable, uint32 _vestingTerm, uint _minimumPrice, uint _maxPayout,
                                 uint _maxDebt, uint _initialDebt) external onlyOwner() {
        require( terms.controlVariable == 0 && terms.vestingTerm == 0, "Bonds must be initialized from 0" );
        terms = Terms ({
            controlVariable: _controlVariable,
            vestingTerm: _vestingTerm,
            minimumPrice: _minimumPrice,
            maxPayout: _maxPayout,
            maxDebt: _maxDebt
        });
        totalDebt = _initialDebt;
        lastDecay = uint32(block.timestamp);
    }


    
    /* ======== POLICY FUNCTIONS ======== */

    enum PARAMETER { VESTING, PAYOUT, DEBT, MINPRICE }
    /**
     *  @notice set parameters for new bonds
     *  @param _parameter PARAMETER
     *  @param _input uint
     */
    function setBondTerms ( PARAMETER _parameter, uint _input ) external onlyOwner() {
        if ( _parameter == PARAMETER.VESTING ) { // 0
            require( _input >= 129600, "Vesting must be longer than 36 hours" );
            decayDebt();
            require( totalDebt == 0, "Debt should be 0." );
            terms.vestingTerm = uint32(_input);
        } else if ( _parameter == PARAMETER.PAYOUT ) { // 1
            require( _input <= 1000, "Payout cannot be above 1 percent" );
            terms.maxPayout = _input;
        } else if ( _parameter == PARAMETER.DEBT ) { // 2
            terms.maxDebt = _input;
        } else if ( _parameter == PARAMETER.MINPRICE ) { // 3
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
    function setAdjustment ( bool _addition, uint _increment, uint _target, uint32 _buffer ) external onlyOwner() {
        require( _increment <= terms.controlVariable.mul( 25 ).div( 1000 ), "Increment too large" );

        adjustment = Adjust({
            add: _addition,
            rate: _increment,
            target: _target,
            buffer: _buffer,
            lastTime: uint32(block.timestamp)
        });
    }

    /**
     *  @notice set contract for auto stake
     *  @param _staking address
     */
    // function setStaking( address _staking ) external onlyOwner() {
    //     require( _staking != address(0) );
    //     staking = _staking;
    // }


    /* ======== USER FUNCTIONS ======== */

    /**
     *  @notice deposit bond
     *  @param _amount uint
     *  @param _maxPrice uint
     *  @param _depositor address
     *  @return uint
     */
    function deposit( uint _amount, uint _maxPrice, address _depositor) external returns ( uint ) {
        require( _depositor != address(0), "Invalid address" );
        decayDebt();
        
        uint priceInUSD = bondPriceInUSD(); // Stored in bond info
        uint nativePrice = _bondPrice();

        require( _maxPrice >= nativePrice, "Slippage limit: more than max price" ); // slippage protection

        uint value = ITreasury( treasury ).valueOfToken( principle, _amount );
        uint payout = payoutFor( value ); // payout to bonder is computed

        require( payout >= 10000000, "Bond too small" ); // must be > 0.01 KEEPER ( underflow protection )
        require( payout <= maxPayout(), "Bond too large"); // size protection because there is no slippage

        /**
            asset carries risk and is not minted against
            asset transfered to treasury and rewards minted as payout
         */
        IERC20( principle ).safeTransferFrom( msg.sender, treasury, _amount );
        ITreasury( treasury ).mintRewards( address(this), payout );
        
        // total debt is increased
        totalDebt = totalDebt.add( value ); 
        require( totalDebt <= terms.maxDebt, "Max capacity reached" );
                
        // depositor info is stored
        bondInfo[ _depositor ] = Bond({ 
            payout: bondInfo[ _depositor ].payout.add( payout ),
            vesting: terms.vestingTerm,
            lastTime: uint32(block.timestamp),
            pricePaid: priceInUSD
        });

        // indexed events are emitted
        emit BondCreated( _amount, payout, block.timestamp.add( terms.vestingTerm ), priceInUSD );
        emit BondPriceChanged( bondPriceInUSD(), _bondPrice(), debtRatio() );

        adjust(); // control variable is adjusted
        return payout; 
    }

    /** 
     *  @notice redeem bond for user
     *  @param _recipient address
     *  @param _stake bool
     *  @return uint
     */ 
    function redeem( address _recipient, bool _stake, bool _wrap ) external returns ( uint ) {        
        Bond memory info = bondInfo[ _recipient ];
        uint percentVested = percentVestedFor( _recipient ); // (seconds since last interaction / vesting term remaining)

        if ( percentVested >= 10000 ) { // if fully vested
            delete bondInfo[ _recipient ]; // delete user info
            emit BondRedeemed( _recipient, info.payout, 0 ); // emit bond data
            return stakeOrSend( _recipient, _stake, _wrap, info.payout ); // pay user everything due

        } else { // if unfinished
            // calculate payout vested
            uint payout = info.payout.mul( percentVested ).div( 10000 );

            // store updated deposit info
            bondInfo[ _recipient ] = Bond({
                payout: info.payout.sub( payout ),
                vesting: info.vesting.sub32( uint32(block.timestamp).sub32( info.lastTime ) ),
                lastTime: uint32(block.timestamp),
                pricePaid: info.pricePaid
            });

            emit BondRedeemed( _recipient, payout, bondInfo[ _recipient ].payout );
            return stakeOrSend( _recipient, _stake, _wrap, payout );
        }
    }



    
    /* ======== INTERNAL HELPER FUNCTIONS ======== */

    /**
     *  @notice allow user to stake payout automatically
     *  @param _stake bool
     *  @param _amount uint
     *  @return uint
     */
    function stakeOrSend( address _recipient, bool _stake, bool _wrap, uint _amount ) internal returns ( uint ) {
        if ( !_stake ) { // if user does not want to stake
            IERC20( KEEPER ).transfer( _recipient, _amount ); // send payout
        } else { // if user wants to stake
            IERC20( KEEPER ).approve( staking, _amount );
            IStaking( staking ).stake( _amount, _recipient, _wrap );
        }
        return _amount;
    }

    /**
     *  @notice makes incremental adjustment to control variable
     */
    function adjust() internal {
        uint timeCanAdjust = adjustment.lastTime.add( adjustment.buffer );
        if( adjustment.rate != 0 && block.timestamp >= timeCanAdjust ) {
            uint initial = terms.controlVariable;
            if ( adjustment.add ) {
                terms.controlVariable = terms.controlVariable.add( adjustment.rate );
                if ( terms.controlVariable >= adjustment.target ) {
                    adjustment.rate = 0;
                }
            } else {
                terms.controlVariable = terms.controlVariable.sub( adjustment.rate );
                if ( terms.controlVariable <= adjustment.target || terms.controlVariable < adjustment.rate ) {
                    adjustment.rate = 0;
                }
            }
            adjustment.lastTime = uint32(block.timestamp);
            emit ControlVariableAdjustment( initial, terms.controlVariable, adjustment.rate, adjustment.add );
        }
    }

    /**
     *  @notice reduce total debt
     */
    function decayDebt() internal {
        totalDebt = totalDebt.sub( debtDecay() );
        lastDecay = uint32(block.timestamp);
    }




    /* ======== VIEW FUNCTIONS ======== */

    /**
     *  @notice determine maximum bond size
     *  @return uint
     */
    function maxPayout() public view returns ( uint ) {
        return IERC20( KEEPER ).totalSupply().mul( terms.maxPayout ).div( 100000 );
    }

    /**
     *  @notice calculate interest due for new bond
     *  @param _value uint
     *  @return uint
     */
    function payoutFor( uint _value ) public view returns ( uint ) {
        return FixedPoint.fraction( _value, bondPrice() ).decode112with18().div( 1e14 );
    }


    /**
     *  @notice calculate current bond premium
     *  @return price_ uint
     */
    function bondPrice() public view returns ( uint price_ ) {        
        price_ = terms.controlVariable.mul( debtRatio() ).div( 1e5 );
        if ( price_ < terms.minimumPrice ) {
            price_ = terms.minimumPrice;
        }
    }

    /**
     *  @notice calculate current bond price and remove floor if above
     *  @return price_ uint
     */
    function _bondPrice() internal returns ( uint price_ ) {
        price_ = terms.controlVariable.mul( debtRatio() ).div( 1e5 );
        if ( price_ < terms.minimumPrice ) {
            price_ = terms.minimumPrice;        
        } else if ( terms.minimumPrice != 0 ) {
            terms.minimumPrice = 0;
        }
    }

    /**
     *  @notice get asset price from chainlink
     */
    function assetPrice() public view returns (int) {
        ( , int price, , , ) = priceFeed.latestRoundData();
        return price;
    }

    /**
     *  @notice converts bond price to DAI value
     *  @return price_ uint
     */
    function bondPriceInUSD() public view returns ( uint price_ ) {
        price_ = bondPrice()
                    .mul( IBondCalculator( bondCalculator ).markdown( principle ) )
                    .mul( uint( assetPrice() ) )
                    .div( 1e12 );
    }


    /**
     *  @notice calculate current ratio of debt to KEEPER supply
     *  @return debtRatio_ uint
     */
    function debtRatio() public view returns ( uint debtRatio_ ) {   
        uint supply = IERC20( KEEPER ).totalSupply();
        debtRatio_ = FixedPoint.fraction( 
            currentDebt().mul( 1e9 ), 
            supply
        ).decode112with18().div( 1e18 );
    }

    /**
     *  @notice debt ratio in same terms as reserve bonds
     *  @return uint
     */
    function standardizedDebtRatio() external view returns ( uint ) {
        return debtRatio().mul( IBondCalculator( bondCalculator ).markdown( principle ) ).div( 1e9 );
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
        uint32 timeSinceLast = uint32(block.timestamp).sub32( lastDecay );
        decay_ = totalDebt.mul( timeSinceLast ).div( terms.vestingTerm );
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
        Bond memory bond = bondInfo[ _depositor ];
        uint timeSinceLast = uint32(block.timestamp).sub( bond.lastTime );
        uint vesting = bond.vesting;

        if ( vesting > 0 ) {
            percentVested_ = timeSinceLast.mul( 10000 ).div( vesting );
        } else {
            percentVested_ = 0;
        }
    }

    /**
     *  @notice calculate amount of KEEPER available for claim by depositor
     *  @param _depositor address
     *  @return pendingPayout_ uint
     */
    function pendingPayoutFor( address _depositor ) external view returns ( uint pendingPayout_ ) {
        uint percentVested = percentVestedFor( _depositor );
        uint payout = bondInfo[ _depositor ].payout;

        if ( percentVested >= 10000 ) {
            pendingPayout_ = payout;
        } else {
            pendingPayout_ = payout.mul( percentVested ).div( 10000 );
        }
    }

}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "./interfaces/AggregateV3Interface.sol";
import "./interfaces/ITreasury.sol";
import "./interfaces/IStaking.sol";
import "./libraries/FixedPoint.sol";
import "./libraries/SafeMathExtended.sol";


contract VBondDepository is Ownable {
    using FixedPoint for *;
    using SafeERC20 for IERC20;
    using SafeMathExtended for uint;
    using SafeMathExtended for uint32;

    /* ======== EVENTS ======== */

    event BondCreated( uint deposit, uint indexed payout, uint indexed expires, uint indexed priceInUSD );
    event BondRedeemed( address indexed recipient, uint payout, uint remaining );
    event BondPriceChanged( uint indexed priceInUSD, uint indexed internalPrice, uint indexed debtRatio );
    event ControlVariableAdjustment( uint initialBCV, uint newBCV, uint adjustment, bool addition );

    /* ======== STATE VARIABLES ======== */

    address public immutable KEEPER; // token given as payment for bond
    address public immutable principle; // token used to create bond
    address public immutable treasury; // mints KEEPER when receives principle
    address public immutable DAO; // receives profit share from bond

    AggregatorV3Interface internal priceFeed;

    address public staking; // to auto-stake payout

    Terms public terms; // stores terms for new bonds
    Adjust public adjustment; // stores adjustment to BCV data

    mapping( address => Bond ) public bondInfo; // stores bond information for depositors

    uint public totalDebt; // total value of outstanding bonds; used for pricing
    uint32 public lastDecay; // reference block for debt decay


    /* ======== STRUCTS ======== */

    // Info for creating new bonds
    struct Terms {
        uint32 vestingTerm; // in seconds
        uint controlVariable; // scaling variable for price
        uint minimumPrice; // vs principle value. 4 decimals (1500 = 0.15)
        uint maxPayout; // in thousandths of a %. i.e. 500 = 0.5%
        uint maxDebt; // 9 decimal debt ratio, max % total supply created as debt
    }

    // Info for bond holder
    struct Bond {
        uint32 vesting; // seconds left to vest
        uint32 lastTime; // Last interaction
        uint payout; // KEEPER remaining to be paid
        uint pricePaid; // In DAI, for front end viewing
    }

    // Info for incremental adjustments to control variable 
    struct Adjust {
        bool add; // addition or subtraction
        uint rate; // increment
        uint target; // BCV when adjustment finished
        uint32 buffer; // minimum length (in blocks) between adjustments
        uint32 lastTime; // block when last adjustment made
    }

    /* ======== INITIALIZATION ======== */

    constructor ( address _KEEPER, address _principle, address _staking, address _treasury, address _DAO, address _feed) {
        require( _KEEPER != address(0) );
        KEEPER = _KEEPER;
        require( _principle != address(0) );
        principle = _principle;
        require( _treasury != address(0) );
        treasury = _treasury;
        require( _DAO != address(0) );
        DAO = _DAO;
        require( _staking != address(0) );
        staking = _staking;
        require( _feed != address(0) );
        priceFeed = AggregatorV3Interface( _feed );
    }

    /**
     *  @notice initializes bond parameters
     *  @param _controlVariable uint
     *  @param _vestingTerm uint
     *  @param _minimumPrice uint
     *  @param _maxPayout uint
     *  @param _maxDebt uint
     *  @param _initialDebt uint
     */
    function initializeBondTerms(uint _controlVariable, uint32 _vestingTerm, uint _minimumPrice, uint _maxPayout,
                                 uint _maxDebt, uint _initialDebt) external onlyOwner() {
        require( terms.controlVariable == 0 && terms.vestingTerm == 0, "Bonds must be initialized from 0" );
        terms = Terms ({
            controlVariable: _controlVariable,
            vestingTerm: _vestingTerm,
            minimumPrice: _minimumPrice,
            maxPayout: _maxPayout,
            maxDebt: _maxDebt
        });
        totalDebt = _initialDebt;
        lastDecay = uint32(block.timestamp);
    }


    
    /* ======== POLICY FUNCTIONS ======== */

    enum PARAMETER { VESTING, PAYOUT, DEBT, MINPRICE }
    /**
     *  @notice set parameters for new bonds
     *  @param _parameter PARAMETER
     *  @param _input uint
     */
    function setBondTerms ( PARAMETER _parameter, uint _input ) external onlyOwner() {
        if ( _parameter == PARAMETER.VESTING ) { // 0
            require( _input >= 129600, "Vesting must be longer than 36 hours" );
            require( currentDebt() == 0, "Debt should be 0." );
            terms.vestingTerm = uint32(_input);
        } else if ( _parameter == PARAMETER.PAYOUT ) { // 1
            require( _input <= 1000, "Payout cannot be above 1 percent" );
            terms.maxPayout = _input;
        } else if ( _parameter == PARAMETER.DEBT ) { // 2
            terms.maxDebt = _input;
        } else if ( _parameter == PARAMETER.MINPRICE ) { // 3
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
    function setAdjustment ( bool _addition, uint _increment, uint _target, uint32 _buffer ) external onlyOwner() {
        require( _increment <= terms.controlVariable.mul( 25 ).div( 1000 ), "Increment too large" );

        adjustment = Adjust({
            add: _addition,
            rate: _increment,
            target: _target,
            buffer: _buffer,
            lastTime: uint32(block.timestamp)
        });
    }

    /**
     *  @notice set contract for auto stake
     *  @param _staking address
     */
    // function setStaking( address _staking ) external onlyOwner() {
    //     require( _staking != address(0) );
    //     staking = _staking;
    // }


    /* ======== USER FUNCTIONS ======== */

    /**
     *  @notice deposit bond
     *  @param _amount uint
     *  @param _maxPrice uint
     *  @param _depositor address
     *  @return uint
     */
    function deposit( uint _amount, uint _maxPrice, address _depositor) external returns ( uint ) {
        require( _depositor != address(0), "Invalid address" );
        decayDebt();
        
        uint priceInUSD = bondPriceInUSD(); // Stored in bond info
        uint nativePrice = _bondPrice();

        require( _maxPrice >= nativePrice, "Slippage limit: more than max price" ); // slippage protection

        uint value = ITreasury( treasury ).valueOfToken( principle, _amount );
        uint payout = payoutFor( value ); // payout to bonder is computed

        require( payout >= 10000000, "Bond too small" ); // must be > 0.01 KEEPER ( underflow protection )
        require( payout <= maxPayout(), "Bond too large"); // size protection because there is no slippage

        /**
            asset carries risk and is not minted against
            asset transfered to treasury and rewards minted as payout
         */
        IERC20( principle ).safeTransferFrom( msg.sender, treasury, _amount );
        ITreasury( treasury ).mintRewards( address(this), payout );
        
        // total debt is increased
        totalDebt = totalDebt.add( value ); 
        require( totalDebt <= terms.maxDebt, "Max capacity reached" );
                
        // depositor info is stored
        bondInfo[ _depositor ] = Bond({ 
            payout: bondInfo[ _depositor ].payout.add( payout ),
            vesting: terms.vestingTerm,
            lastTime: uint32(block.timestamp),
            pricePaid: priceInUSD
        });

        // indexed events are emitted
        emit BondCreated( _amount, payout, block.timestamp.add( terms.vestingTerm ), priceInUSD );
        emit BondPriceChanged( bondPriceInUSD(), _bondPrice(), debtRatio() );

        adjust(); // control variable is adjusted
        return payout; 
    }

    /** 
     *  @notice redeem bond for user
     *  @param _recipient address
     *  @param _stake bool
     *  @return uint
     */ 
    function redeem( address _recipient, bool _stake, bool _wrap ) external returns ( uint ) {        
        Bond memory info = bondInfo[ _recipient ];
        uint percentVested = percentVestedFor( _recipient ); // (seconds since last interaction / vesting term remaining)

        if ( percentVested >= 10000 ) { // if fully vested
            delete bondInfo[ _recipient ]; // delete user info
            emit BondRedeemed( _recipient, info.payout, 0 ); // emit bond data
            return stakeOrSend( _recipient, _stake, _wrap, info.payout ); // pay user everything due

        } else { // if unfinished
            // calculate payout vested
            uint payout = info.payout.mul( percentVested ).div( 10000 );

            // store updated deposit info
            bondInfo[ _recipient ] = Bond({
                payout: info.payout.sub( payout ),
                vesting: info.vesting.sub32( uint32(block.timestamp).sub32( info.lastTime ) ),
                lastTime: uint32(block.timestamp),
                pricePaid: info.pricePaid
            });

            emit BondRedeemed( _recipient, payout, bondInfo[ _recipient ].payout );
            return stakeOrSend( _recipient, _stake, _wrap, payout );
        }
    }



    
    /* ======== INTERNAL HELPER FUNCTIONS ======== */

    /**
     *  @notice allow user to stake payout automatically
     *  @param _stake bool
     *  @param _amount uint
     *  @return uint
     */
    function stakeOrSend( address _recipient, bool _stake, bool _wrap, uint _amount ) internal returns ( uint ) {
        if ( !_stake ) { // if user does not want to stake
            IERC20( KEEPER ).transfer( _recipient, _amount ); // send payout
        } else { // if user wants to stake
            IERC20( KEEPER ).approve( staking, _amount );
            IStaking( staking ).stake( _amount, _recipient, _wrap );
        }
        return _amount;
    }

    /**
     *  @notice makes incremental adjustment to control variable
     */
    function adjust() internal {
        uint timeCanAdjust = adjustment.lastTime.add( adjustment.buffer );
        if( adjustment.rate != 0 && block.timestamp >= timeCanAdjust ) {
            uint initial = terms.controlVariable;
            if ( adjustment.add ) {
                terms.controlVariable = terms.controlVariable.add( adjustment.rate );
                if ( terms.controlVariable >= adjustment.target ) {
                    adjustment.rate = 0;
                }
            } else {
                terms.controlVariable = terms.controlVariable.sub( adjustment.rate );
                if ( terms.controlVariable <= adjustment.target || terms.controlVariable < adjustment.rate ) {
                    adjustment.rate = 0;
                }
            }
            adjustment.lastTime = uint32(block.timestamp);
            emit ControlVariableAdjustment( initial, terms.controlVariable, adjustment.rate, adjustment.add );
        }
    }

    /**
     *  @notice reduce total debt
     */
    function decayDebt() internal {
        totalDebt = totalDebt.sub( debtDecay() );
        lastDecay = uint32(block.timestamp);
    }




    /* ======== VIEW FUNCTIONS ======== */

    /**
     *  @notice determine maximum bond size
     *  @return uint
     */
    function maxPayout() public view returns ( uint ) {
        return IERC20( KEEPER ).totalSupply().mul( terms.maxPayout ).div( 100000 );
    }

    /**
     *  @notice calculate interest due for new bond
     *  @param _value uint
     *  @return uint
     */
    function payoutFor( uint _value ) public view returns ( uint ) {
        return FixedPoint.fraction( _value, bondPrice() ).decode112with18().div( 1e14 );
    }


    /**
     *  @notice calculate current bond premium
     *  @return price_ uint
     */
    function bondPrice() public view returns ( uint price_ ) {        
        price_ = terms.controlVariable.mul( debtRatio() ).div( 1e5 );
        if ( price_ < terms.minimumPrice ) {
            price_ = terms.minimumPrice;
        }
    }

    /**
     *  @notice calculate current bond price and remove floor if above
     *  @return price_ uint
     */
    function _bondPrice() internal returns ( uint price_ ) {
        price_ = terms.controlVariable.mul( debtRatio() ).div( 1e5 );
        if ( price_ < terms.minimumPrice ) {
            price_ = terms.minimumPrice;        
        } else if ( terms.minimumPrice != 0 ) {
            terms.minimumPrice = 0;
        }
    }

    /**
     *  @notice get asset price from chainlink
     */
    function assetPrice() public view returns (int) {
        ( , int price, , , ) = priceFeed.latestRoundData();
        return price;
    }

    /**
     *  @notice converts bond price to DAI value
     *  @return price_ uint
     */
    function bondPriceInUSD() public view returns ( uint price_ ) {
        price_ = bondPrice().mul( uint( assetPrice() ) ).mul( 1e6 );
    }


    /**
     *  @notice calculate current ratio of debt to KEEPER supply
     *  @return debtRatio_ uint
     */
    function debtRatio() public view returns ( uint debtRatio_ ) {   
        uint supply = IERC20( KEEPER ).totalSupply();
        debtRatio_ = FixedPoint.fraction( 
            currentDebt().mul( 1e9 ), 
            supply
        ).decode112with18().div( 1e18 );
    }

    /**
     *  @notice debt ratio in same terms as reserve bonds
     *  @return uint
     */
    function standardizedDebtRatio() external view returns ( uint ) {
        return debtRatio().mul( uint( assetPrice() ) ).div( 1e8 ); // ETH feed is 8 decimals
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
        uint32 timeSinceLast = uint32(block.timestamp).sub32( lastDecay );
        decay_ = totalDebt.mul( timeSinceLast ).div( terms.vestingTerm );
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
        Bond memory bond = bondInfo[ _depositor ];
        uint timeSinceLast = uint32(block.timestamp).sub( bond.lastTime );
        uint vesting = bond.vesting;

        if ( vesting > 0 ) {
            percentVested_ = timeSinceLast.mul( 10000 ).div( vesting );
        } else {
            percentVested_ = 0;
        }
    }

    /**
     *  @notice calculate amount of KEEPER available for claim by depositor
     *  @param _depositor address
     *  @return pendingPayout_ uint
     */
    function pendingPayoutFor( address _depositor ) external view returns ( uint pendingPayout_ ) {
        uint percentVested = percentVestedFor( _depositor );
        uint payout = bondInfo[ _depositor ].payout;

        if ( percentVested >= 10000 ) {
            pendingPayout_ = payout;
        } else {
            pendingPayout_ = payout.mul( percentVested ).div( 10000 );
        }
    }




    /* ======= AUXILLIARY ======= */

    /**
     *  @notice allow anyone to send lost tokens (excluding principle or KEEPER) to the DAO
     *  @return bool
     */
    function recoverLostToken( address _token ) external returns ( bool ) {
        require( _token != KEEPER );
        require( _token != principle );
        IERC20( _token ).safeTransfer( DAO, IERC20( _token ).balanceOf( address(this) ) );
        return true;
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "./interfaces/ITreasury.sol";
import "./libraries/SafeMathExtended.sol";

contract StakingDistributor is Ownable {
    
    using SafeERC20 for IERC20;
    using SafeMathExtended for uint256;
    using SafeMathExtended for uint32;
    
    IERC20 immutable KEEPER;
    ITreasury immutable treasury;
    
    uint32 public immutable epochLength;
    uint32 public nextEpochTime;
    
    mapping( uint => Adjust ) public adjustments;

    /* ====== STRUCTS ====== */
        
    struct Info {
        uint rate; // in ten-thousandths ( 5000 = 0.5% )
        address recipient;
    }
    Info[] public info;
    
    struct Adjust {
        bool add;
        uint rate;
        uint target;
    }

    constructor( address _treasury, address _KEEPER, uint32 _epochLength, uint32 _nextEpochTime ) {        
        require( _treasury != address(0) );
        treasury = ITreasury( _treasury );
        require( _KEEPER != address(0) );
        KEEPER = IERC20( _KEEPER );
        epochLength = _epochLength;
        nextEpochTime = _nextEpochTime;
    }

    /**
        @notice send epoch reward to staking contract
     */
    function distribute() external returns (bool) {
        if ( nextEpochTime <= uint32(block.timestamp) ) {
            nextEpochTime = nextEpochTime.add32( epochLength ); // set next epoch block
            // distribute rewards to each recipient
            for ( uint i = 0; i < info.length; i++ ) {
                if ( info[ i ].rate > 0 ) {
                    treasury.mintRewards( // mint and send from treasury
                        info[ i ].recipient, 
                        nextRewardAt( info[ i ].rate ) 
                    );
                    adjust( i ); // check for adjustment
                }
            }
            return true;
        }
        else {
            return false;
        }
    }

    /**
        @notice increment reward rate for collector
     */
    function adjust( uint _index ) internal {
        Adjust memory adjustment = adjustments[ _index ];
        if ( adjustment.rate != 0 ) {
            if ( adjustment.add ) { // if rate should increase
                info[ _index ].rate = info[ _index ].rate.add( adjustment.rate ); // raise rate
                if ( info[ _index ].rate >= adjustment.target ) { // if target met
                    adjustments[ _index ].rate = 0; // turn off adjustment
                }
            } else { // if rate should decrease
                info[ _index ].rate = info[ _index ].rate.sub( adjustment.rate ); // lower rate
                if ( info[ _index ].rate <= adjustment.target || info[ _index ].rate < adjustment.rate) { // if target met
                    adjustments[ _index ].rate = 0; // turn off adjustment
                }
            }
        }
    }

    /* ====== VIEW FUNCTIONS ====== */

    /**
        @notice view function for next reward at given rate
        @param _rate uint
        @return uint
     */
    function nextRewardAt( uint _rate ) public view returns ( uint ) {
        return KEEPER.totalSupply().mul( _rate ).div( 1000000 );
    }

    /**
        @notice view function for next reward for specified address
        @param _recipient address
        @return uint
     */
    function nextRewardFor( address _recipient ) public view returns ( uint ) {
        uint reward;
        for ( uint i = 0; i < info.length; i++ ) {
            if ( info[ i ].recipient == _recipient ) {
                reward = nextRewardAt( info[ i ].rate );
            }
        }
        return reward;
    }
    
    
    
    /* ====== POLICY FUNCTIONS ====== */

    /**
        @notice adds recipient for distributions
        @param _recipient address
        @param _rewardRate uint
     */
    function addRecipient( address _recipient, uint _rewardRate ) external onlyOwner() {
        require( _recipient != address(0) );
        info.push( Info({
            recipient: _recipient,
            rate: _rewardRate
        }));
    }

    /**
        @notice removes recipient for distributions
        @param _index uint
        @param _recipient address
     */
    function removeRecipient( uint _index, address _recipient ) external onlyOwner() {
        require( _recipient == info[ _index ].recipient );
        info[ _index ] = info[info.length-1];
        info.pop();
    }

    /**
        @notice set adjustment info for a collector's reward rate
        @param _index uint
        @param _add bool
        @param _rate uint
        @param _target uint
     */
    function setAdjustment( uint _index, bool _add, uint _rate, uint _target ) external onlyOwner() {
        require(_add || info[ _index ].rate >= _rate, "Negative adjustment rate cannot be more than current rate.");
        adjustments[ _index ] = Adjust({
            add: _add,
            rate: _rate,
            target: _target
        });
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "./interfaces/IBondCalculator.sol";
import "./interfaces/IERC20Extended.sol";
import "./interfaces/IKeplerERC20.sol";

contract oldTreasury is Ownable {
    
    using SafeERC20 for IERC20Extended;
    using SafeMath for uint;

    event Deposit( address indexed token, uint amount, uint value );
    event Withdrawal( address indexed token, uint amount, uint value );
    event CreateDebt( address indexed debtor, address indexed token, uint amount, uint value );
    event RepayDebt( address indexed debtor, address indexed token, uint amount, uint value );
    event ReservesManaged( address indexed token, uint amount );
    event ReservesUpdated( uint indexed totalReserves );
    event ReservesAudited( uint indexed totalReserves );
    event RewardsMinted( address indexed caller, address indexed recipient, uint amount );
    event ChangeQueued( MANAGING indexed managing, address queued );
    event ChangeActivated( MANAGING indexed managing, address activated, bool result );

    enum MANAGING { RESERVEDEPOSITOR, RESERVESPENDER, RESERVETOKEN, RESERVEMANAGER, LIQUIDITYDEPOSITOR, LIQUIDITYTOKEN, LIQUIDITYMANAGER, DEBTOR, REWARDMANAGER, SKEEPER }

    IKeplerERC20 immutable KEEPER;
    uint public immutable secondsNeededForQueue;
    uint public constant keeperDecimals = 9;

    address[] public reserveTokens; // Push only, beware false-positives.
    mapping( address => bool ) public isReserveToken;
    mapping( address => uint ) public reserveTokenQueue; // Delays changes to mapping.

    address[] public reserveDepositors; // Push only, beware false-positives. Only for viewing.
    mapping( address => bool ) public isReserveDepositor;
    mapping( address => uint ) public reserveDepositorQueue; // Delays changes to mapping.

    address[] public reserveSpenders; // Push only, beware false-positives. Only for viewing.
    mapping( address => bool ) public isReserveSpender;
    mapping( address => uint ) public reserveSpenderQueue; // Delays changes to mapping.

    address[] public liquidityTokens; // Push only, beware false-positives.
    mapping( address => bool ) public isLiquidityToken;
    mapping( address => uint ) public LiquidityTokenQueue; // Delays changes to mapping.

    address[] public liquidityDepositors; // Push only, beware false-positives. Only for viewing.
    mapping( address => bool ) public isLiquidityDepositor;
    mapping( address => uint ) public LiquidityDepositorQueue; // Delays changes to mapping.

    mapping( address => address ) public bondCalculator; // bond calculator for liquidity token

    address[] public reserveManagers; // Push only, beware false-positives. Only for viewing.
    mapping( address => bool ) public isReserveManager;
    mapping( address => uint ) public ReserveManagerQueue; // Delays changes to mapping.

    address[] public liquidityManagers; // Push only, beware false-positives. Only for viewing.
    mapping( address => bool ) public isLiquidityManager;
    mapping( address => uint ) public LiquidityManagerQueue; // Delays changes to mapping.

    address[] public debtors; // Push only, beware false-positives. Only for viewing.
    mapping( address => bool ) public isDebtor;
    mapping( address => uint ) public debtorQueue; // Delays changes to mapping.
    mapping( address => uint ) public debtorBalance;

    address[] public rewardManagers; // Push only, beware false-positives. Only for viewing.
    mapping( address => bool ) public isRewardManager;
    mapping( address => uint ) public rewardManagerQueue; // Delays changes to mapping.

    address public sKEEPER;
    uint public sKEEPERQueue; // Delays change to sKEEPER address
    
    uint public totalReserves; // Risk-free value of all assets
    uint public totalDebt;

    constructor (address _KEEPER, address _USDC, address _DAI, uint _secondsNeededForQueue) {
        require( _KEEPER != address(0) );
        KEEPER = IKeplerERC20(_KEEPER);

        isReserveToken[ _USDC] = true;
        reserveTokens.push( _USDC );
        isReserveToken[ _DAI ] = true;
        reserveTokens.push( _DAI );
        // isLiquidityToken[ _KEEPERDAI ] = true;
        // liquidityTokens.push( _KEEPERDAI );

        secondsNeededForQueue = _secondsNeededForQueue;
    }

    /**
        @notice allow approved address to deposit an asset for KEEPER
        @param _amount uint
        @param _token address
        @param _profit uint
        @return send_ uint
     */
    function deposit( uint _amount, address _token, uint _profit ) external returns ( uint send_ ) {
        require( isReserveToken[ _token ] || isLiquidityToken[ _token ], "Not accepted" );
        IERC20Extended( _token ).safeTransferFrom( msg.sender, address(this), _amount );

        if ( isReserveToken[ _token ] ) {
            require( isReserveDepositor[ msg.sender ], "Not approved" );
        } else {
            require( isLiquidityDepositor[ msg.sender ], "Not approved" );
        }

        uint value = valueOfToken(_token, _amount);
        // mint KEEPER needed and store amount of rewards for distribution
        send_ = value.sub( _profit );
        KEEPER.mint( msg.sender, send_ );

        totalReserves = totalReserves.add( value );
        emit ReservesUpdated( totalReserves );
        emit Deposit( _token, _amount, value );
    }

    /**
        @notice allow approved address to burn KEEPER for reserves
        @param _amount uint
        @param _token address
     */
    function withdraw( uint _amount, address _token ) external {
        require( isReserveToken[ _token ], "Not accepted" ); // Only reserves can be used for redemptions
        require( isReserveSpender[ msg.sender ] == true, "Not approved" );

        uint value = valueOfToken( _token, _amount );
        KEEPER.burnFrom( msg.sender, value );

        totalReserves = totalReserves.sub( value );
        emit ReservesUpdated( totalReserves );

        IERC20Extended( _token ).safeTransfer( msg.sender, _amount );

        emit Withdrawal( _token, _amount, value );
    }

    /**
        @notice allow approved address to borrow reserves
        @param _amount uint
        @param _token address
     */
    function incurDebt( uint _amount, address _token ) external {
        require( isDebtor[ msg.sender ], "Not approved" );
        require( isReserveToken[ _token ], "Not accepted" );

        uint value = valueOfToken( _token, _amount );

        uint maximumDebt = IERC20Extended( sKEEPER ).balanceOf( msg.sender ); // Can only borrow against sKEEPER held
        uint availableDebt = maximumDebt.sub( debtorBalance[ msg.sender ] );
        require( value <= availableDebt, "Exceeds debt limit" );

        debtorBalance[ msg.sender ] = debtorBalance[ msg.sender ].add( value );
        totalDebt = totalDebt.add( value );

        totalReserves = totalReserves.sub( value );
        emit ReservesUpdated( totalReserves );
        IERC20Extended( _token ).transfer( msg.sender, _amount );
        emit CreateDebt( msg.sender, _token, _amount, value );
    }

    /**
        @notice allow approved address to repay borrowed reserves with reserves
        @param _amount uint
        @param _token address
     */
    function repayDebtWithReserve( uint _amount, address _token ) external {
        require( isDebtor[ msg.sender ], "Not approved" );
        require( isReserveToken[ _token ], "Not accepted" );

        IERC20Extended( _token ).safeTransferFrom( msg.sender, address(this), _amount );

        uint value = valueOfToken( _token, _amount );
        debtorBalance[ msg.sender ] = debtorBalance[ msg.sender ].sub( value );
        totalDebt = totalDebt.sub( value );

        totalReserves = totalReserves.add( value );
        emit ReservesUpdated( totalReserves );

        emit RepayDebt( msg.sender, _token, _amount, value );
    }

    /**
        @notice allow approved address to repay borrowed reserves with KEEPER
        @param _amount uint
     */
    function repayDebtWithKEEPER( uint _amount ) external {
        require( isDebtor[ msg.sender ], "Not approved" );
        KEEPER.burnFrom( msg.sender, _amount );
        debtorBalance[ msg.sender ] = debtorBalance[ msg.sender ].sub( _amount );
        totalDebt = totalDebt.sub( _amount );
        emit RepayDebt( msg.sender, address(KEEPER), _amount, _amount );
    }

    /**
        @notice allow approved address to withdraw assets
        @param _token address
        @param _amount uint
     */
    function manage( address _token, uint _amount ) external {
        if( isLiquidityToken[ _token ] ) {
            require( isLiquidityManager[ msg.sender ], "Not approved" );
        } else {
            require( isReserveManager[ msg.sender ], "Not approved" );
        }

        uint value = valueOfToken(_token, _amount);
        require( value <= excessReserves(), "Insufficient reserves" );

        totalReserves = totalReserves.sub( value );
        emit ReservesUpdated( totalReserves );
        IERC20Extended( _token ).safeTransfer( msg.sender, _amount );
        emit ReservesManaged( _token, _amount );
    }

    /**
        @notice send epoch reward to staking contract
     */
    function mintRewards( address _recipient, uint _amount ) external {
        require( isRewardManager[ msg.sender ], "Not approved" );
        require( _amount <= excessReserves(), "Insufficient reserves" );

        KEEPER.mint( _recipient, _amount );

        emit RewardsMinted( msg.sender, _recipient, _amount );
    } 

    /**
        @notice returns excess reserves not backing tokens
        @return uint
     */
    function excessReserves() public view returns ( uint ) {
        return totalReserves.sub( KEEPER.totalSupply().sub( totalDebt ) );
    }

    /**
        @notice takes inventory of all tracked assets
        @notice always consolidate to recognized reserves before audit
     */
    function auditReserves() external onlyOwner() {
        uint reserves;
        for( uint i = 0; i < reserveTokens.length; i++ ) {
            reserves = reserves.add ( 
                valueOfToken( reserveTokens[ i ], IERC20Extended( reserveTokens[ i ] ).balanceOf( address(this) ) )
            );
        }
        for( uint i = 0; i < liquidityTokens.length; i++ ) {
            reserves = reserves.add (
                valueOfToken( liquidityTokens[ i ], IERC20Extended( liquidityTokens[ i ] ).balanceOf( address(this) ) )
            );
        }
        totalReserves = reserves;
        emit ReservesUpdated( reserves );
        emit ReservesAudited( reserves );
    }

    /**
        @notice returns KEEPER valuation of asset
        @param _token address
        @param _amount uint
        @return value_ uint
     */
    function valueOfToken( address _token, uint _amount ) public view returns ( uint value_ ) {
        if ( isReserveToken[ _token ] ) {
            // convert amount to match KEEPER decimals
            value_ = _amount.mul( 10 ** keeperDecimals ).div( 10 ** IERC20Extended( _token ).decimals() );
        } else if ( isLiquidityToken[ _token ] ) {
            value_ = IBondCalculator( bondCalculator[ _token ] ).valuation( _token, _amount );
        }
    }

    /**
        @notice queue address to change boolean in mapping
        @param _managing MANAGING
        @param _address address
        @return bool
     */
    function queue( MANAGING _managing, address _address ) external onlyOwner() returns ( bool ) {
        require( _address != address(0) );
        if ( _managing == MANAGING.RESERVEDEPOSITOR ) { // 0
            reserveDepositorQueue[ _address ] = block.timestamp.add( secondsNeededForQueue );
        } else if ( _managing == MANAGING.RESERVESPENDER ) { // 1
            reserveSpenderQueue[ _address ] = block.timestamp.add( secondsNeededForQueue );
        } else if ( _managing == MANAGING.RESERVETOKEN ) { // 2
            reserveTokenQueue[ _address ] = block.timestamp.add( secondsNeededForQueue );
        } else if ( _managing == MANAGING.RESERVEMANAGER ) { // 3
            ReserveManagerQueue[ _address ] = block.timestamp.add( secondsNeededForQueue.mul( 2 ) );
        } else if ( _managing == MANAGING.LIQUIDITYDEPOSITOR ) { // 4
            LiquidityDepositorQueue[ _address ] = block.timestamp.add( secondsNeededForQueue );
        } else if ( _managing == MANAGING.LIQUIDITYTOKEN ) { // 5
            LiquidityTokenQueue[ _address ] = block.timestamp.add( secondsNeededForQueue );
        } else if ( _managing == MANAGING.LIQUIDITYMANAGER ) { // 6
            LiquidityManagerQueue[ _address ] = block.timestamp.add( secondsNeededForQueue.mul( 2 ) );
        } else if ( _managing == MANAGING.DEBTOR ) { // 7
            debtorQueue[ _address ] = block.timestamp.add( secondsNeededForQueue );
        } else if ( _managing == MANAGING.REWARDMANAGER ) { // 8
            rewardManagerQueue[ _address ] = block.timestamp.add( secondsNeededForQueue );
        } else if ( _managing == MANAGING.SKEEPER ) { // 9
            sKEEPERQueue = block.timestamp.add( secondsNeededForQueue );
        } else return false;

        emit ChangeQueued( _managing, _address );
        return true;
    }

    /**
        @notice verify queue then set boolean in mapping
        @param _managing MANAGING
        @param _address address
        @param _calculator address
        @return bool
     */
    function toggle( MANAGING _managing, address _address, address _calculator ) external onlyOwner() returns ( bool ) {
        require( _address != address(0) );
        bool result;
        if ( _managing == MANAGING.RESERVEDEPOSITOR ) { // 0
            if ( requirements( reserveDepositorQueue, isReserveDepositor, _address ) ) {
                reserveDepositorQueue[ _address ] = 0;
                if( !listContains( reserveDepositors, _address ) ) {
                    reserveDepositors.push( _address );
                }
            }
            result = !isReserveDepositor[ _address ];
            isReserveDepositor[ _address ] = result;
            
        } else if ( _managing == MANAGING.RESERVESPENDER ) { // 1
            if ( requirements( reserveSpenderQueue, isReserveSpender, _address ) ) {
                reserveSpenderQueue[ _address ] = 0;
                if( !listContains( reserveSpenders, _address ) ) {
                    reserveSpenders.push( _address );
                }
            }
            result = !isReserveSpender[ _address ];
            isReserveSpender[ _address ] = result;

        } else if ( _managing == MANAGING.RESERVETOKEN ) { // 2
            if ( requirements( reserveTokenQueue, isReserveToken, _address ) ) {
                reserveTokenQueue[ _address ] = 0;
                if( !listContains( reserveTokens, _address ) ) {
                    reserveTokens.push( _address );
                }
            }
            result = !isReserveToken[ _address ];
            isReserveToken[ _address ] = result;

        } else if ( _managing == MANAGING.RESERVEMANAGER ) { // 3
            if ( requirements( ReserveManagerQueue, isReserveManager, _address ) ) {
                reserveManagers.push( _address );
                ReserveManagerQueue[ _address ] = 0;
                if( !listContains( reserveManagers, _address ) ) {
                    reserveManagers.push( _address );
                }
            }
            result = !isReserveManager[ _address ];
            isReserveManager[ _address ] = result;

        } else if ( _managing == MANAGING.LIQUIDITYDEPOSITOR ) { // 4
            if ( requirements( LiquidityDepositorQueue, isLiquidityDepositor, _address ) ) {
                liquidityDepositors.push( _address );
                LiquidityDepositorQueue[ _address ] = 0;
                if( !listContains( liquidityDepositors, _address ) ) {
                    liquidityDepositors.push( _address );
                }
            }
            result = !isLiquidityDepositor[ _address ];
            isLiquidityDepositor[ _address ] = result;

        } else if ( _managing == MANAGING.LIQUIDITYTOKEN ) { // 5
            if ( requirements( LiquidityTokenQueue, isLiquidityToken, _address ) ) {
                LiquidityTokenQueue[ _address ] = 0;
                if( !listContains( liquidityTokens, _address ) ) {
                    liquidityTokens.push( _address );
                }
            }
            result = !isLiquidityToken[ _address ];
            isLiquidityToken[ _address ] = result;
            bondCalculator[ _address ] = _calculator;

        } else if ( _managing == MANAGING.LIQUIDITYMANAGER ) { // 6
            if ( requirements( LiquidityManagerQueue, isLiquidityManager, _address ) ) {
                LiquidityManagerQueue[ _address ] = 0;
                if( !listContains( liquidityManagers, _address ) ) {
                    liquidityManagers.push( _address );
                }
            }
            result = !isLiquidityManager[ _address ];
            isLiquidityManager[ _address ] = result;

        } else if ( _managing == MANAGING.DEBTOR ) { // 7
            if ( requirements( debtorQueue, isDebtor, _address ) ) {
                debtorQueue[ _address ] = 0;
                if( !listContains( debtors, _address ) ) {
                    debtors.push( _address );
                }
            }
            result = !isDebtor[ _address ];
            isDebtor[ _address ] = result;

        } else if ( _managing == MANAGING.REWARDMANAGER ) { // 8
            if ( requirements( rewardManagerQueue, isRewardManager, _address ) ) {
                rewardManagerQueue[ _address ] = 0;
                if( !listContains( rewardManagers, _address ) ) {
                    rewardManagers.push( _address );
                }
            }
            result = !isRewardManager[ _address ];
            isRewardManager[ _address ] = result;

        } else if ( _managing == MANAGING.SKEEPER ) { // 9
            sKEEPERQueue = 0;
            sKEEPER = _address;
            result = true;

        } else return false;

        emit ChangeActivated( _managing, _address, result );
        return true;
    }

    /**
        @notice checks requirements and returns altered structs
        @param queue_ mapping( address => uint )
        @param status_ mapping( address => bool )
        @param _address address
        @return bool 
     */
    function requirements( 
        mapping( address => uint ) storage queue_, 
        mapping( address => bool ) storage status_, 
        address _address 
    ) internal view returns ( bool ) {
        if ( !status_[ _address ] ) {
            require( queue_[ _address ] != 0, "Must queue" );
            require( queue_[ _address ] <= block.timestamp, "Queue not expired" );
            return true;
        } return false;
    }

    /**
        @notice checks array to ensure against duplicate
        @param _list address[]
        @param _token address
        @return bool
     */
    function listContains( address[] storage _list, address _token ) internal view returns ( bool ) {
        for( uint i = 0; i < _list.length; i++ ) {
            if( _list[ i ] == _token ) {
                return true;
            }
        }
        return false;
    }

}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IKeplerERC20 is IERC20 {

  function decimals() external view returns (uint8);

  function mint(uint256 amount_) external;

  function mint(address account_, uint256 ammount_) external;

  function burnFrom(address account_, uint256 amount_) external;

  function vault() external returns (address);
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

import "./interfaces/IStaking.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract StakingHelper {

    address public immutable staking;
    address public immutable KEEPER;

    constructor ( address _staking, address _KEEPER ) {
        require( _staking != address(0) );
        staking = _staking;
        require( _KEEPER != address(0) );
        KEEPER = _KEEPER;
    }

    function stake( uint _amount, bool _wrap ) external {
        IERC20( KEEPER ).transferFrom( msg.sender, address(this), _amount );
        IERC20( KEEPER ).approve( staking, _amount );
        IStaking( staking ).stake( _amount, msg.sender, _wrap );
        IStaking( staking ).claim( msg.sender );
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "./interfaces/IDistributor.sol";
import "./interfaces/IiKEEPER.sol";
import "./interfaces/IsKEEPER.sol";
import "./interfaces/IwTROVE.sol";
import "./libraries/SafeMathExtended.sol";

contract oldStaking is Ownable {
    
    using SafeERC20 for IERC20;
    using SafeERC20 for IsKEEPER;
    using SafeMathExtended for uint256;
    using SafeMathExtended for uint32;

    event DistributorSet( address distributor );
    event WarmupSet( uint warmup );
    event IKeeperSet( address iKEEPER );

    struct Epoch {
        uint32 length;
        uint32 endTime;
        uint32 number;
        uint distribute;
    }

    struct Claim {
        uint deposit;
        uint gons;
        uint expiry;
        bool lock; // prevents malicious delays
    }

    IERC20 public immutable KEEPER;
    IsKEEPER public immutable sKEEPER;
    IwTROVE public immutable wTROVE;
    Epoch public epoch;
    address public distributor;
    address public iKEEPER;
    mapping( address => Claim ) public warmupInfo;
    uint32 public warmupPeriod;
    uint gonsInWarmup;


    constructor (address _KEEPER, address _sKEEPER, address _wTROVE, uint32 _epochLength, uint32 _firstEpochNumber, uint32 _firstEpochTime) {
        require( _KEEPER != address(0) );
        KEEPER = IERC20( _KEEPER );
        require( _sKEEPER != address(0) );
        sKEEPER = IsKEEPER( _sKEEPER );
        require( _wTROVE != address(0) );
        wTROVE = IwTROVE( _wTROVE );
        epoch = Epoch({
            length: _epochLength,
            number: _firstEpochNumber,
            endTime: _firstEpochTime,
            distribute: 0
        });
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    /**
     * @notice stake KEEPER to enter warmup
     * @param _amount uint
     * @param _recipient address
     */
    function stake( uint _amount, address _recipient, bool _wrap ) external returns ( uint ) {
        rebase();

        KEEPER.safeTransferFrom( msg.sender, address(this), _amount );

        if ( warmupPeriod == 0 ) {
            return _send( _recipient, _amount, _wrap );
        }
        else {
            Claim memory info = warmupInfo[ _recipient ];
            if ( !info.lock ) {
                require( _recipient == msg.sender, "External deposits for account are locked" );
            }

            uint sKeeperGons = sKEEPER.gonsForBalance( _amount );
            warmupInfo[ _recipient ] = Claim ({
                deposit: info.deposit.add(_amount),
                gons: info.gons.add(sKeeperGons),
                expiry: epoch.number.add32(warmupPeriod),
                lock: info.lock
            });

            gonsInWarmup = gonsInWarmup.add(sKeeperGons);
            return _amount;
        }
    }


    function stakeInvest( uint _stakeAmount, uint _investAmount, address _recipient, bool _wrap ) external {
        rebase();
        uint keeperAmount = _stakeAmount.add(_investAmount.div(1e9));
        KEEPER.safeTransferFrom( msg.sender, address(this), keeperAmount );
        _send( _recipient, _stakeAmount, _wrap );
        sKEEPER.approve(iKEEPER, _investAmount);
        IiKEEPER(iKEEPER).wrap(_investAmount, _recipient);
    }

    /**
     * @notice retrieve stake from warmup
     * @param _recipient address
     */
    function claim ( address _recipient ) public returns ( uint ) {
        Claim memory info = warmupInfo[ _recipient ];
        if ( epoch.number >= info.expiry && info.expiry != 0 ) {
            delete warmupInfo[ _recipient ];
            gonsInWarmup = gonsInWarmup.sub(info.gons);
            return _send( _recipient, sKEEPER.balanceForGons( info.gons ), false);
        }
        return 0;
    }

    /**
     * @notice forfeit stake and retrieve KEEPER
     */
    function forfeit() external returns ( uint ) {
        Claim memory info = warmupInfo[ msg.sender ];
        delete warmupInfo[ msg.sender ];
        gonsInWarmup = gonsInWarmup.sub(info.gons);
        KEEPER.safeTransfer( msg.sender, info.deposit );
        return info.deposit;
    }

    /**
     * @notice prevent new deposits or claims from ext. address (protection from malicious activity)
     */
    function toggleLock() external {
        warmupInfo[ msg.sender ].lock = !warmupInfo[ msg.sender ].lock;
    }

    /**
     * @notice redeem sKEEPER for KEEPER
     * @param _amount uint
     * @param _trigger bool
     */
    function unstake( uint _amount, bool _trigger ) external returns ( uint ) {
        if ( _trigger ) {
            rebase();
        }
        uint amount = _amount;
        sKEEPER.safeTransferFrom( msg.sender, address(this), _amount );
        KEEPER.safeTransfer( msg.sender, amount );
        return amount;
    }

    /**
        @notice trigger rebase if epoch over
     */
    function rebase() public {
        if( epoch.endTime <= uint32(block.timestamp) ) {
            sKEEPER.rebase( epoch.distribute, epoch.number );
            epoch.endTime = epoch.endTime.add32(epoch.length);
            epoch.number++;            
            if ( distributor != address(0) ) {
                IDistributor( distributor ).distribute();
            }

            uint contractBalanceVal = contractBalance();
            uint totalStakedVal = totalStaked();
            if( contractBalanceVal <= totalStakedVal ) {
                epoch.distribute = 0;
            }
            else {
                epoch.distribute = contractBalanceVal.sub(totalStakedVal);
            }
        }
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    /**
     * @notice send staker their amount as sKEEPER or gKEEPER
     * @param _recipient address
     * @param _amount uint
     */
    function _send( address _recipient, uint _amount, bool _wrap ) internal returns ( uint ) {
        if (_wrap) {
            sKEEPER.approve( address( wTROVE ), _amount );
            uint wrapValue = wTROVE.wrap( _amount );
            wTROVE.transfer( _recipient, wrapValue );
        } else {
            sKEEPER.safeTransfer( _recipient, _amount ); // send as sKEEPER (equal unit as KEEPER)
        }
        return _amount;
    }

    /* ========== VIEW FUNCTIONS ========== */

    /**
        @notice returns the sKEEPER index, which tracks rebase growth
        @return uint
     */
    function index() public view returns ( uint ) {
        return sKEEPER.index();
    }

    /**
        @notice returns contract KEEPER holdings, including bonuses provided
        @return uint
     */
    function contractBalance() public view returns ( uint ) {
        return KEEPER.balanceOf( address(this) );
    }

    function totalStaked() public view returns ( uint ) {
        return sKEEPER.circulatingSupply();
    }

    function supplyInWarmup() public view returns ( uint ) {
        return sKEEPER.balanceForGons( gonsInWarmup );
    }



    /* ========== MANAGERIAL FUNCTIONS ========== */

    /**
        @notice sets the contract address for LP staking
        @param _address address
     */
    function setDistributor( address _address ) external onlyOwner() {
        distributor = _address;
        emit DistributorSet( _address );
    }
    
    /**
     * @notice set warmup period for new stakers
     * @param _warmupPeriod uint
     */
    function setWarmup( uint32 _warmupPeriod ) external onlyOwner() {
        warmupPeriod = _warmupPeriod;
        emit WarmupSet( _warmupPeriod );
    }


    function setIKeeper( address _iKEEPER ) external onlyOwner() {
        iKEEPER = _iKEEPER;
        emit IKeeperSet( _iKEEPER );
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

interface IDistributor {
    function distribute() external returns ( bool );
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IiKEEPER is IERC20 {
    function wrap(uint _amount, address _recipient) external;

    function unwrap(uint _amount) external;
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "./interfaces/AggregateV3Interface.sol";
import "./interfaces/IWETH9.sol";
import "./interfaces/ITreasury.sol";
import "./interfaces/IsKEEPER.sol";
import "./interfaces/IwTROVE.sol";
import "./interfaces/IStaking.sol";
import "./libraries/FixedPoint.sol";
import "./libraries/SafeMathExtended.sol";


contract EthBondStakeDepository is Ownable {
    using FixedPoint for *;
    using SafeERC20 for IERC20;
    using SafeMathExtended for uint;
    using SafeMathExtended for uint32;

    /* ======== EVENTS ======== */

    event BondCreated( uint deposit, uint indexed payout, uint indexed expires, uint indexed priceInUSD );
    event BondRedeemed( address indexed recipient, uint payout, uint remaining );
    event BondPriceChanged( uint indexed priceInUSD, uint indexed internalPrice, uint indexed debtRatio );
    event ControlVariableAdjustment( uint initialBCV, uint newBCV, uint adjustment, bool addition );

    /* ======== STATE VARIABLES ======== */

    address public immutable KEEPER; // token given as payment for bond
    address public immutable sKEEPER; // token given as payment for bond
    address public immutable wTROVE; // Wrap sKEEPER
    address public immutable principle; // token used to create bond
    address public immutable treasury; // mints KEEPER when receives principle
    address public immutable DAO; // receives profit share from bond

    AggregatorV3Interface internal priceFeed;

    address public staking; // to auto-stake payout

    Terms public terms; // stores terms for new bonds
    Adjust public adjustment; // stores adjustment to BCV data

    mapping( address => Bond ) public bondInfo; // stores bond information for depositors

    uint public totalDebt; // total value of outstanding bonds; used for pricing
    uint32 public lastDecay; // reference block for debt decay


    /* ======== STRUCTS ======== */

    // Info for creating new bonds
    struct Terms {
        uint32 vestingTerm; // in seconds
        uint controlVariable; // scaling variable for price
        uint minimumPrice; // vs principle value. 4 decimals (1500 = 0.15)
        uint maxPayout; // in thousandths of a %. i.e. 500 = 0.5%
        uint maxDebt; // 9 decimal debt ratio, max % total supply created as debt
    }

    // Info for bond holder
    struct Bond {
        uint32 vesting; // seconds left to vest
        uint32 lastTime; // Last interaction
        uint gonsPayout; // KEEPER remaining to be paid
        uint pricePaid; // In DAI, for front end viewing
    }

    // Info for incremental adjustments to control variable 
    struct Adjust {
        bool add; // addition or subtraction
        uint rate; // increment
        uint target; // BCV when adjustment finished
        uint32 buffer; // minimum length (in blocks) between adjustments
        uint32 lastTime; // block when last adjustment made
    }

    /* ======== INITIALIZATION ======== */

    constructor ( address _KEEPER, address _sKEEPER, address _wTROVE, address _principle, address _staking, address _treasury, address _DAO, address _feed) {
        require( _KEEPER != address(0) );
        KEEPER = _KEEPER;
        require( _sKEEPER != address(0) );
        sKEEPER = _sKEEPER;
        require( _wTROVE != address(0) );
        wTROVE = _wTROVE;
        require( _principle != address(0) );
        principle = _principle;
        require( _treasury != address(0) );
        treasury = _treasury;
        require( _DAO != address(0) );
        DAO = _DAO;
        require( _staking != address(0) );
        staking = _staking;
        require( _feed != address(0) );
        priceFeed = AggregatorV3Interface( _feed );
    }

    /**
     *  @notice initializes bond parameters
     *  @param _controlVariable uint
     *  @param _vestingTerm uint
     *  @param _minimumPrice uint
     *  @param _maxPayout uint
     *  @param _maxDebt uint
     *  @param _initialDebt uint
     */
    function initializeBondTerms(uint _controlVariable, uint32 _vestingTerm, uint _minimumPrice, uint _maxPayout,
                                 uint _maxDebt, uint _initialDebt) external onlyOwner() {
        require( terms.controlVariable == 0 && terms.vestingTerm == 0, "Bonds must be initialized from 0" );
        terms = Terms ({
            controlVariable: _controlVariable,
            vestingTerm: _vestingTerm,
            minimumPrice: _minimumPrice,
            maxPayout: _maxPayout,
            maxDebt: _maxDebt
        });
        totalDebt = _initialDebt;
        lastDecay = uint32(block.timestamp);
    }


    
    /* ======== POLICY FUNCTIONS ======== */

    enum PARAMETER { VESTING, PAYOUT, DEBT, MINPRICE }
    /**
     *  @notice set parameters for new bonds
     *  @param _parameter PARAMETER
     *  @param _input uint
     */
    function setBondTerms ( PARAMETER _parameter, uint _input ) external onlyOwner() {
        if ( _parameter == PARAMETER.VESTING ) { // 0
            require( _input >= 129600, "Vesting must be longer than 36 hours" );
            require( currentDebt() == 0, "Debt should be 0." );
            terms.vestingTerm = uint32(_input);
        } else if ( _parameter == PARAMETER.PAYOUT ) { // 1
            require( _input <= 1000, "Payout cannot be above 1 percent" );
            terms.maxPayout = _input;
        } else if ( _parameter == PARAMETER.DEBT ) { // 2
            terms.maxDebt = _input;
        } else if ( _parameter == PARAMETER.MINPRICE ) { // 3
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
    function setAdjustment ( bool _addition, uint _increment, uint _target, uint32 _buffer ) external onlyOwner() {
        require( _increment <= terms.controlVariable.mul( 25 ).div( 1000 ), "Increment too large" );

        adjustment = Adjust({
            add: _addition,
            rate: _increment,
            target: _target,
            buffer: _buffer,
            lastTime: uint32(block.timestamp)
        });
    }

    /**
     *  @notice set contract for auto stake
     *  @param _staking address
     */
    // function setStaking( address _staking ) external onlyOwner() {
    //     require( _staking != address(0) );
    //     staking = _staking;
    // }


    /* ======== USER FUNCTIONS ======== */

    /**
     *  @notice deposit bond
     *  @param _amount uint
     *  @param _maxPrice uint
     *  @param _depositor address
     *  @return uint
     */
    function deposit( uint _amount, uint _maxPrice, address _depositor) external payable returns ( uint ) {
        require( _depositor != address(0), "Invalid address" );
        decayDebt();
        
        uint priceInUSD = bondPriceInUSD(); // Stored in bond info
        uint nativePrice = _bondPrice();

        require( _maxPrice >= nativePrice, "Slippage limit: more than max price" ); // slippage protection

        uint value = ITreasury( treasury ).valueOfToken( principle, _amount );
        uint payout = payoutFor( value ); // payout to bonder is computed

        require( payout >= 10000000, "Bond too small" ); // must be > 0.01 KEEPER ( underflow protection )
        require( payout <= maxPayout(), "Bond too large"); // size protection because there is no slippage

        /**
            asset carries risk and is not minted against
            asset transfered to treasury and rewards minted as payout
         */
        if (address(this).balance >= _amount) {
            // pay with WETH9
            IWETH9(principle).deposit{value: _amount}(); // wrap only what is needed to pay
            IWETH9(principle).transfer(treasury, _amount);
        } else {
            IERC20( principle ).safeTransferFrom( msg.sender, treasury, _amount );
        }

        ITreasury( treasury ).mintRewards( address(this), payout );
        
        // total debt is increased
        totalDebt = totalDebt.add( value );
        require( totalDebt <= terms.maxDebt, "Max capacity reached" );

        IERC20( KEEPER ).approve( staking, payout );
        IStaking( staking ).stake( payout, address(this), false );
        IStaking( staking ).claim( address(this) );
        uint stakeGons = IsKEEPER(sKEEPER).gonsForBalance(payout);
                
        // depositor info is stored
        bondInfo[ _depositor ] = Bond({ 
            gonsPayout: bondInfo[ _depositor ].gonsPayout.add( stakeGons ),
            vesting: terms.vestingTerm,
            lastTime: uint32(block.timestamp),
            pricePaid: priceInUSD
        });

        // indexed events are emitted
        emit BondCreated( _amount, payout, block.timestamp.add( terms.vestingTerm ), priceInUSD );
        emit BondPriceChanged( bondPriceInUSD(), _bondPrice(), debtRatio() );

        adjust(); // control variable is adjusted
        refundETH(); //refund user if needed
        return payout; 
    }

    /** 
     *  @notice redeem bond for user
     *  @param _recipient address
     *  @param _stake bool
     *  @return uint
     */ 
    function redeem( address _recipient, bool _stake, bool _wrap ) external returns ( uint ) {        
        Bond memory info = bondInfo[ _recipient ];
        uint percentVested = percentVestedFor( _recipient ); // (blocks since last interaction / vesting term remaining)

        if ( percentVested >= 10000 ) { // if fully vested
            delete bondInfo[ _recipient ]; // delete user info
            uint _amount = IsKEEPER(sKEEPER).balanceForGons(info.gonsPayout);
            emit BondRedeemed( _recipient, _amount, 0 ); // emit bond data
            return sendOrWrap( _recipient, _wrap, _amount ); // pay user everything due

        } else { // if unfinished
            // calculate payout vested
            uint gonsPayout = info.gonsPayout.mul( percentVested ).div( 10000 );
            // store updated deposit info
            bondInfo[ _recipient ] = Bond({
                gonsPayout: info.gonsPayout.sub( gonsPayout ),
                vesting: info.vesting.sub32( uint32(block.timestamp).sub32( info.lastTime ) ),
                lastTime: uint32(block.timestamp),
                pricePaid: info.pricePaid
            });

            uint _amount = IsKEEPER(sKEEPER).balanceForGons(gonsPayout);
            uint _remainingAmount = IsKEEPER(sKEEPER).balanceForGons(bondInfo[_recipient].gonsPayout);
            emit BondRedeemed( _recipient, _amount, _remainingAmount );
            return sendOrWrap( _recipient, _wrap, _amount );
        }
    }



    
    /* ======== INTERNAL HELPER FUNCTIONS ======== */

    /**
     *  @notice allow user to wrap payout automatically
     *  @param _wrap bool
     *  @param _amount uint
     *  @return uint
     */
    function sendOrWrap( address _recipient, bool _wrap, uint _amount ) internal returns ( uint ) {
        if ( _wrap ) { // if user wants to wrap
            IERC20(sKEEPER).approve( wTROVE, _amount );
            uint wrapValue = IwTROVE(wTROVE).wrap( _amount );
            IwTROVE(wTROVE).transfer( _recipient, wrapValue );
        } else { // if user wants to stake
            IERC20( sKEEPER ).transfer( _recipient, _amount ); // send payout
        }
        return _amount;
    }

    /**
     *  @notice makes incremental adjustment to control variable
     */
    function adjust() internal {
        uint timeCanAdjust = adjustment.lastTime.add( adjustment.buffer );
        if( adjustment.rate != 0 && block.timestamp >= timeCanAdjust ) {
            uint initial = terms.controlVariable;
            if ( adjustment.add ) {
                terms.controlVariable = terms.controlVariable.add( adjustment.rate );
                if ( terms.controlVariable >= adjustment.target ) {
                    adjustment.rate = 0;
                }
            } else {
                terms.controlVariable = terms.controlVariable.sub( adjustment.rate );
                if ( terms.controlVariable <= adjustment.target || terms.controlVariable < adjustment.rate ) {
                    adjustment.rate = 0;
                }
            }
            adjustment.lastTime = uint32(block.timestamp);
            emit ControlVariableAdjustment( initial, terms.controlVariable, adjustment.rate, adjustment.add );
        }
    }

    /**
     *  @notice reduce total debt
     */
    function decayDebt() internal {
        totalDebt = totalDebt.sub( debtDecay() );
        lastDecay = uint32(block.timestamp);
    }




    /* ======== VIEW FUNCTIONS ======== */

    /**
     *  @notice determine maximum bond size
     *  @return uint
     */
    function maxPayout() public view returns ( uint ) {
        return IERC20( KEEPER ).totalSupply().mul( terms.maxPayout ).div( 100000 );
    }

    /**
     *  @notice calculate interest due for new bond
     *  @param _value uint
     *  @return uint
     */
    function payoutFor( uint _value ) public view returns ( uint ) {
        return FixedPoint.fraction( _value, bondPrice() ).decode112with18().div( 1e14 );
    }


    /**
     *  @notice calculate current bond premium
     *  @return price_ uint
     */
    function bondPrice() public view returns ( uint price_ ) {        
        price_ = terms.controlVariable.mul( debtRatio() ).div( 1e5 );
        if ( price_ < terms.minimumPrice ) {
            price_ = terms.minimumPrice;
        }
    }

    /**
     *  @notice calculate current bond price and remove floor if above
     *  @return price_ uint
     */
    function _bondPrice() internal returns ( uint price_ ) {
        price_ = terms.controlVariable.mul( debtRatio() ).div( 1e5 );
        if ( price_ < terms.minimumPrice ) {
            price_ = terms.minimumPrice;        
        } else if ( terms.minimumPrice != 0 ) {
            terms.minimumPrice = 0;
        }
    }

    /**
     *  @notice get asset price from chainlink
     */
    function assetPrice() public view returns (int) {
        ( , int price, , , ) = priceFeed.latestRoundData();
        return price;
    }

    /**
     *  @notice converts bond price to DAI value
     *  @return price_ uint
     */
    function bondPriceInUSD() public view returns ( uint price_ ) {
        price_ = bondPrice().mul( uint( assetPrice() ) ).mul( 1e6 );
    }

    function getBondInfo(address _depositor) public view returns ( uint payout, uint vesting, uint lastTime, uint pricePaid ) {
        Bond memory info = bondInfo[ _depositor ];
        payout = IsKEEPER(sKEEPER).balanceForGons(info.gonsPayout);
        vesting = info.vesting;
        lastTime = info.lastTime;
        pricePaid = info.pricePaid;
    }


    /**
     *  @notice calculate current ratio of debt to KEEPER supply
     *  @return debtRatio_ uint
     */
    function debtRatio() public view returns ( uint debtRatio_ ) {   
        uint supply = IERC20( KEEPER ).totalSupply();
        debtRatio_ = FixedPoint.fraction( 
            currentDebt().mul( 1e9 ), 
            supply
        ).decode112with18().div( 1e18 );
    }

    /**
     *  @notice debt ratio in same terms as reserve bonds
     *  @return uint
     */
    function standardizedDebtRatio() external view returns ( uint ) {
        return debtRatio().mul( uint( assetPrice() ) ).div( 1e8 ); // ETH feed is 8 decimals
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
        uint32 timeSinceLast = uint32(block.timestamp).sub32( lastDecay );
        decay_ = totalDebt.mul( timeSinceLast ).div( terms.vestingTerm );
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
        Bond memory bond = bondInfo[ _depositor ];
        uint timeSinceLast = uint32(block.timestamp).sub( bond.lastTime );
        uint vesting = bond.vesting;

        if ( vesting > 0 ) {
            percentVested_ = timeSinceLast.mul( 10000 ).div( vesting );
        } else {
            percentVested_ = 0;
        }
    }

    /**
     *  @notice calculate amount of KEEPER available for claim by depositor
     *  @param _depositor address
     *  @return pendingPayout_ uint
     */
    function pendingPayoutFor( address _depositor ) external view returns ( uint pendingPayout_ ) {
        uint percentVested = percentVestedFor( _depositor );
        uint payout = IsKEEPER(sKEEPER).balanceForGons(bondInfo[ _depositor ].gonsPayout);

        if ( percentVested >= 10000 ) {
            pendingPayout_ = payout;
        } else {
            pendingPayout_ = payout.mul( percentVested ).div( 10000 );
        }
    }




    /* ======= AUXILLIARY ======= */

    /**
     *  @notice allow anyone to send lost tokens (excluding principle or KEEPER) to the DAO
     *  @return bool
     */
    function recoverLostToken( address _token ) external returns ( bool ) {
        require( _token != KEEPER );
        require( _token != sKEEPER );
        require( _token != principle );
        IERC20( _token ).safeTransfer( DAO, IERC20( _token ).balanceOf( address(this) ) );
        return true;
    }

    function refundETH() internal {
        if (address(this).balance > 0) safeTransferETH(DAO, address(this).balance);
    }

    /// @notice Transfers ETH to the recipient address
    /// @dev Fails with `STE`
    /// @param to The destination of the transfer
    /// @param value The value to be transferred
    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'STE');
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IWETH9 is IERC20 {
    /// @notice Deposit ether to get wrapped ether
    function deposit() external payable;
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "./interfaces/IsKEEPER.sol";


contract wTROVE is ERC20 {

    using SafeMath for uint;
    address public immutable TROVE;


    constructor(address _TROVE) ERC20("Wrapped Trove", "wTROVE") {
        require(_TROVE != address(0));
        TROVE = _TROVE;
    }

    /**
        @notice wrap TROVE
        @param _amount uint
        @return uint
     */
    function wrap( uint _amount ) external returns ( uint ) {
        IsKEEPER( TROVE ).transferFrom( msg.sender, address(this), _amount );
        
        uint value = TROVETowTROVE( _amount );
        _mint( msg.sender, value );
        return value;
    }

    /**
        @notice unwrap TROVE
        @param _amount uint
        @return uint
     */
    function unwrap( uint _amount ) external returns ( uint ) {
        _burn( msg.sender, _amount );

        uint value = wTROVEToTROVE( _amount );
        IsKEEPER( TROVE ).transfer( msg.sender, value );
        return value;
    }

    /**
        @notice converts wTROVE amount to TROVE
        @param _amount uint
        @return uint
     */
    function wTROVEToTROVE( uint _amount ) public view returns ( uint ) {
        return _amount.mul( IsKEEPER( TROVE ).index() ).div( 10 ** decimals() );
    }

    /**
        @notice converts TROVE amount to wTROVE
        @param _amount uint
        @return uint
     */
    function TROVETowTROVE( uint _amount ) public view returns ( uint ) {
        return _amount.mul( 10 ** decimals() ).div( IsKEEPER( TROVE ).index() );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "../../utils/Context.sol";
import "./IERC20.sol";
import "../../math/SafeMath.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal virtual {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract USDC is ERC20, Ownable {
    using SafeMath for uint256;
    
    constructor() ERC20("USDC", "USDC") {
    }

    function mint(address account_, uint256 amount_) external onlyOwner() {
        _mint(account_, amount_);
    }

    function burn(uint256 amount) public virtual {
        _burn(msg.sender, amount);
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./interfaces/IStaking.sol";

contract sKeplerERC20 is ERC20 {

    using SafeMath for uint256;

    event StakingContractUpdated(address stakingContract);
    event LogSupply(uint256 indexed epoch, uint256 timestamp, uint256 totalSupply);
    event LogRebase(uint256 indexed epoch, uint256 rebase, uint256 index);

    address initializer;
    address public stakingContract; // balance used to calc rebase

    uint8 private constant _tokenDecimals = 9;
    uint INDEX; // Index Gons - tracks rebase growth
    uint _totalSupply;

    uint256 private constant MAX_UINT256 = ~uint256(0);
    uint256 private constant INITIAL_FRAGMENTS_SUPPLY = 5000000 * 10**_tokenDecimals;

    // TOTAL_GONS is a multiple of INITIAL_FRAGMENTS_SUPPLY so that _gonsPerFragment is an integer.
    // Use the highest value that fits in a uint256 for max granularity.
    uint256 private constant TOTAL_GONS = MAX_UINT256 - (MAX_UINT256 % INITIAL_FRAGMENTS_SUPPLY);

    // MAX_SUPPLY = maximum integer < (sqrt(4*TOTAL_GONS + 1) - 1) / 2
    uint256 private constant MAX_SUPPLY = ~uint128(0);  // (2^128) - 1

    uint256 private _gonsPerFragment;
    mapping(address => uint256) private _gonBalances;
    mapping (address => mapping (address => uint256)) private _allowedValue;

    struct Rebase {
        uint epoch;
        uint rebase; // 18 decimals
        uint totalStakedBefore;
        uint totalStakedAfter;
        uint amountRebased;
        uint index;
        uint timeOccured;
    }

    Rebase[] public rebases; // past rebase data    

    modifier onlyStakingContract() {
        require(msg.sender == stakingContract);
        _;
    }

    constructor() ERC20("Staked Keeper", "TROVE") {
        _setupDecimals(_tokenDecimals);
        initializer = msg.sender;
        _totalSupply = INITIAL_FRAGMENTS_SUPPLY;
        _gonsPerFragment = TOTAL_GONS.div(_totalSupply);
    }

    function setIndex(uint _INDEX) external {
        require(msg.sender == initializer);
        require(INDEX == 0);
        require(_INDEX != 0);
        INDEX = gonsForBalance(_INDEX);
    }

    // do this last
    function initialize(address _stakingContract) external {
        require(msg.sender == initializer);
        require(_stakingContract != address(0));
        stakingContract = _stakingContract;
        _gonBalances[ stakingContract ] = TOTAL_GONS;

        emit Transfer(address(0x0), stakingContract, _totalSupply);
        emit StakingContractUpdated(_stakingContract);
        
        initializer = address(0);
    }

    /**
        @notice increases sKEEPER supply to increase staking balances relative to _profit
        @param _profit uint256
        @return uint256
    */
    function rebase(uint256 _profit, uint _epoch) public onlyStakingContract() returns (uint256) {
        uint256 rebaseAmount;
        uint256 _circulatingSupply = circulatingSupply();

        if (_profit == 0) {
            emit LogSupply(_epoch, block.timestamp, _totalSupply);
            emit LogRebase(_epoch, 0, index());
            return _totalSupply;
        }
        else if (_circulatingSupply > 0) {
            rebaseAmount = _profit.mul(_totalSupply).div(_circulatingSupply);
        }
        else {
            rebaseAmount = _profit;
        }

        _totalSupply = _totalSupply.add(rebaseAmount);
        if (_totalSupply > MAX_SUPPLY) {
            _totalSupply = MAX_SUPPLY;
        }

        _gonsPerFragment = TOTAL_GONS.div(_totalSupply);
        _storeRebase(_circulatingSupply, _profit, _epoch);
        return _totalSupply;
    }

    /**
        @notice emits event with data about rebase
        @param _previousCirculating uint
        @param _profit uint
        @param _epoch uint
        @return bool
    */
    function _storeRebase(uint _previousCirculating, uint _profit, uint _epoch) internal returns (bool) {
        uint rebasePercent = _profit.mul(1e18).div(_previousCirculating);

        rebases.push(Rebase ({
            epoch: _epoch,
            rebase: rebasePercent, // 18 decimals
            totalStakedBefore: _previousCirculating,
            totalStakedAfter: circulatingSupply(),
            amountRebased: _profit,
            index: index(),
            timeOccured: uint32(block.timestamp)
        }));
        
        emit LogSupply(_epoch, block.timestamp, _totalSupply);
        emit LogRebase(_epoch, rebasePercent, index());
        return true;
    }

    /* =================================== VIEW FUNCTIONS ========================== */

    /**
     * @param who The address to query.
     * @return The balance of the specified address.
     */
    function balanceOf(address who) public view override returns (uint256) {
        return _gonBalances[ who ].div(_gonsPerFragment);
    }

    /**
     * @param who The address to query.
     * @return The gon balance of the specified address.
     */
    function scaledBalanceOf(address who) external view returns (uint256) {
        return _gonBalances[who];
    }

    function gonsForBalance(uint amount) public view returns (uint) {
        return amount * _gonsPerFragment;
    }

    function balanceForGons(uint gons) public view returns (uint) {
        return gons / _gonsPerFragment;
    }

    // Staking contract holds excess sKEEPER
    function circulatingSupply() public view returns (uint) {
        return _totalSupply.sub(balanceOf(stakingContract)).add(IStaking(stakingContract).supplyInWarmup());
    }

    function index() public view returns (uint) {
        return balanceForGons(INDEX);
    }

    function allowance(address owner_, address spender) public view override returns (uint256) {
        return _allowedValue[ owner_ ][ spender ];
    }

    /* ================================= MUTATIVE FUNCTIONS ====================== */

    function transfer(address to, uint256 value) public override returns (bool) {
        uint256 gonValue = value.mul(_gonsPerFragment);
        _gonBalances[ msg.sender ] = _gonBalances[ msg.sender ].sub(gonValue);
        _gonBalances[ to ] = _gonBalances[ to ].add(gonValue);
        emit Transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) public override returns (bool) {
       _allowedValue[ from ][ msg.sender ] = _allowedValue[ from ][ msg.sender ].sub(value);
       emit Approval(from, msg.sender,  _allowedValue[ from ][ msg.sender ]);

        uint256 gonValue = gonsForBalance(value);
        _gonBalances[ from ] = _gonBalances[from].sub(gonValue);
        _gonBalances[ to ] = _gonBalances[to].add(gonValue);
        emit Transfer(from, to, value);
        return true;
    }

    function _approve(address owner, address spender, uint256 value) internal override virtual {
        _allowedValue[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function approve(address spender, uint256 value) public override returns (bool) {
         _allowedValue[ msg.sender ][ spender ] = value;
         emit Approval(msg.sender, spender, value);
         return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public override returns (bool) {
        _allowedValue[ msg.sender ][ spender ] = _allowedValue[ msg.sender ][ spender ].add(addedValue);
        emit Approval(msg.sender, spender, _allowedValue[ msg.sender ][ spender ]);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public override returns (bool) {
        uint256 oldValue = _allowedValue[ msg.sender ][ spender ];
        if (subtractedValue >= oldValue) {
            _allowedValue[ msg.sender ][ spender ] = 0;
        } else {
            _allowedValue[ msg.sender ][ spender ] = oldValue.sub(subtractedValue);
        }
        emit Approval(msg.sender, spender, _allowedValue[ msg.sender ][ spender ]);
        return true;
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";


contract cKEEPER is ERC20, Ownable {
    using SafeMath for uint;

    bool public requireSellerApproval;

    mapping( address => bool ) public isApprovedSeller;
    
    constructor() ERC20("Call Keeper", "cKEEPER") {
        uint initSupply = 500000000 * 1e18;
        _addApprovedSeller( address(this) );
        _addApprovedSeller( msg.sender );
        _mint( msg.sender, initSupply );
        requireSellerApproval = true;
    }

    function allowOpenTrading() external onlyOwner() returns ( bool ) {
        requireSellerApproval = false;
        return requireSellerApproval;
    }

    function _addApprovedSeller( address approvedSeller_ ) internal {
        isApprovedSeller[approvedSeller_] = true;
    }

    function addApprovedSeller( address approvedSeller_ ) external onlyOwner() returns ( bool ) {
        _addApprovedSeller( approvedSeller_ );
        return isApprovedSeller[approvedSeller_];
    }

    function addApprovedSellers( address[] calldata approvedSellers_ ) external onlyOwner() returns ( bool ) {
        for( uint iteration_; iteration_ < approvedSellers_.length; iteration_++ ) {
          _addApprovedSeller( approvedSellers_[iteration_] );
        }
        return true;
    }

    function _removeApprovedSeller( address disapprovedSeller_ ) internal {
        isApprovedSeller[disapprovedSeller_] = false;
    }

    function removeApprovedSeller( address disapprovedSeller_ ) external onlyOwner() returns ( bool ) {
        _removeApprovedSeller( disapprovedSeller_ );
        return isApprovedSeller[disapprovedSeller_];
    }

    function removeApprovedSellers( address[] calldata disapprovedSellers_ ) external onlyOwner() returns ( bool ) {
        for( uint iteration_; iteration_ < disapprovedSellers_.length; iteration_++ ) {
            _removeApprovedSeller( disapprovedSellers_[iteration_] );
        }
        return true;
    }

    function _beforeTokenTransfer(address from_, address to_, uint256 amount_ ) internal override {
        require( (balanceOf(to_) > 0 || isApprovedSeller[from_] == true || !requireSellerApproval), "Account not approved to transfer cKEEPER." );
    }

    function burn(uint256 amount_) public virtual {
        _burn( msg.sender, amount_ );
    }

    function burnFrom( address account_, uint256 amount_ ) public virtual {
        _burnFrom( account_, amount_ );
    }

    function _burnFrom( address account_, uint256 amount_ ) internal virtual {
        uint256 decreasedAllowance_ = allowance( account_, msg.sender ).sub( amount_, "ERC20: burn amount exceeds allowance");
        _approve( account_, msg.sender, decreasedAllowance_ );
        _burn( account_, amount_ );
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

import "@openzeppelin/contracts/access/Ownable.sol";


interface IBond {
    function redeem( address _recipient, bool _stake ) external returns ( uint );
    function pendingPayoutFor( address _depositor ) external view returns ( uint pendingPayout_ );
}

contract RedeemHelper is Ownable {

    address[] public bonds;

    function redeemAll( address _recipient, bool _stake ) external {
        for( uint i = 0; i < bonds.length; i++ ) {
            if ( bonds[i] != address(0) ) {
                if ( IBond( bonds[i] ).pendingPayoutFor( _recipient ) > 0 ) {
                    IBond( bonds[i] ).redeem( _recipient, _stake );
                }
            }
        }
    }

    function addBondContract( address _bond ) external onlyOwner() {
        require( _bond != address(0) );
        bonds.push( _bond );
    }

    function removeBondContract( uint _index ) external onlyOwner() {
        bonds[ _index ] = address(0);
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract KEEPERCircSupply is Ownable {
    using SafeMath for uint;

    address public KEEPER;
    address[] public nonCirculatingKEEPERAddresses;

    constructor (address _KEEPER) {
        KEEPER = _KEEPER;
    }

    function KEEPERCirculatingSupply() external view returns (uint) {
        uint _totalSupply = IERC20( KEEPER ).totalSupply();
        uint _circulatingSupply = _totalSupply.sub( getNonCirculatingKEEPER() );
        return _circulatingSupply;
    }

    function getNonCirculatingKEEPER() public view returns ( uint ) {
        uint _nonCirculatingKEEPER;
        for( uint i=0; i < nonCirculatingKEEPERAddresses.length; i = i.add( 1 ) ) {
            _nonCirculatingKEEPER = _nonCirculatingKEEPER.add( IERC20( KEEPER ).balanceOf( nonCirculatingKEEPERAddresses[i] ) );
        }
        return _nonCirculatingKEEPER;
    }

    function setNonCirculatingKEEPERAddresses( address[] calldata _nonCirculatingAddresses ) external onlyOwner() returns ( bool ) {
        nonCirculatingKEEPERAddresses = _nonCirculatingAddresses;
        return true;
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "../interfaces/ITreasury.sol";
import "../interfaces/IStaking.sol";


interface IcKEEPER {
    function burnFrom( address account_, uint256 amount_ ) external;
}


contract cKeeperExercise is Ownable {
    using SafeMath for uint;
    using SafeERC20 for IERC20;

    address public immutable cKEEPER;
    address public immutable KEEPER;
    address public immutable USDC;
    address public immutable treasury;

    address public staking;
    uint private constant CLIFF = 250000 * 10**9;   // Minimum KEEPER supply to exercise
    uint private constant TOUCHDOWN = 5000000 * 10**9;    // Maximum KEEPER supply for percent increase
    uint private constant Y_INCREASE = 35000;    // Increase from CLIFF to TOUCHDOWN is 3.5%. 4 decimals used

    // uint private constant SLOPE = Y_INCREASE.div(TOUCHDOWN.sub(CLIFF));  // m = (y2 - y1) / (x2 - x1)

    struct Term {
        uint initPercent; // 4 decimals ( 5000 = 0.5% )
        uint claimed;
        uint max;
    }
    mapping(address => Term) public terms;
    mapping(address => address) public walletChange;


    constructor( address _cKEEPER, address _KEEPER, address _USDC, address _treasury, address _staking ) {
        require( _cKEEPER != address(0) );
        cKEEPER = _cKEEPER;
        require( _KEEPER != address(0) );
        KEEPER = _KEEPER;
        require( _USDC != address(0) );
        USDC = _USDC;
        require( _treasury != address(0) );
        treasury = _treasury;
        require( _staking != address(0) );
        staking = _staking;
    }

    function setStaking( address _staking ) external onlyOwner() {
        require( _staking != address(0) );
        staking = _staking;
    }

    // Sets terms for a new wallet
    function setTerms(address _vester, uint _amountCanClaim, uint _rate ) external onlyOwner() returns ( bool ) {
        terms[_vester].max = _amountCanClaim;
        terms[_vester].initPercent = _rate;
        return true;
    }

    // Sets terms for multiple wallets
    function setTermsMultiple(address[] calldata _vesters, uint[] calldata _amountCanClaims, uint[] calldata _rates ) external onlyOwner() returns ( bool ) {
        for (uint i=0; i < _vesters.length; i++) {
            terms[_vesters[i]].max = _amountCanClaims[i];
            terms[_vesters[i]].initPercent = _rates[i];
        }
        return true;
    }

    // Allows wallet to redeem cKEEPER for KEEPER
    function exercise( uint _amount, bool _stake, bool _wrap ) external returns ( bool ) {
        Term memory info = terms[ msg.sender ];
        require( redeemable( info ) >= _amount, 'Not enough vested' );
        require( info.max.sub( info.claimed ) >= _amount, 'Claimed over max' );

        uint usdcAmount = _amount.div(1e12);
        IERC20( USDC ).safeTransferFrom( msg.sender, address( this ), usdcAmount );
        IcKEEPER( cKEEPER ).burnFrom( msg.sender, _amount );

        IERC20( USDC ).approve( treasury, usdcAmount );
        uint KEEPERToSend = ITreasury( treasury ).deposit( usdcAmount, USDC, 0 );

        terms[ msg.sender ].claimed = info.claimed.add( _amount );

        if ( _stake ) {
            IERC20( KEEPER ).approve( staking, KEEPERToSend );
            IStaking( staking ).stake( KEEPERToSend, msg.sender, _wrap );
        } else {
            IERC20( KEEPER ).safeTransfer( msg.sender, KEEPERToSend );
        }

        return true;
    }

    // Allows wallet owner to transfer rights to a new address
    function pushWalletChange( address _newWallet ) external returns ( bool ) {
        require( terms[ msg.sender ].initPercent != 0 );
        walletChange[ msg.sender ] = _newWallet;
        return true;
    }

    // Allows wallet to pull rights from an old address
    function pullWalletChange( address _oldWallet ) external returns ( bool ) {
        require( walletChange[ _oldWallet ] == msg.sender, "wallet did not push" );
        walletChange[ _oldWallet ] = address(0);
        terms[ msg.sender ] = terms[ _oldWallet ];
        delete terms[ _oldWallet ];
        return true;
    }

    // Amount a wallet can redeem based on current supply
    function redeemableFor( address _vester ) public view returns (uint) {
        return redeemable( terms[ _vester ]);
    }

    function redeemable( Term memory _info ) internal view returns ( uint ) {
        if ( _info.initPercent == 0 ) {
            return 0;
        }
        uint keeperSupply = IERC20( KEEPER ).totalSupply();
        if (keeperSupply < CLIFF) {
            return 0;
        } else if (keeperSupply > TOUCHDOWN) {
            keeperSupply = TOUCHDOWN;
        }
        uint percent = Y_INCREASE.mul(keeperSupply.sub(CLIFF)).div(TOUCHDOWN.sub(CLIFF)).add(_info.initPercent);
        return ( keeperSupply.mul( percent ).mul( 1000 ) ).sub( _info.claimed );
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/IStaking.sol";


contract aKeeperStake2 is Ownable {
    using SafeMath for uint256;

    IERC20 public aKEEPER;
    IERC20 public KEEPER;
    address public staking;
    mapping( address => uint ) public depositInfo;

    uint public depositDeadline;
    uint public withdrawStart;
    uint public withdrawDeadline;

    
    constructor(address _aKEEPER, uint _depositDeadline, uint _withdrawStart, uint _withdrawDeadline) {
        require( _aKEEPER != address(0) );
        aKEEPER = IERC20(_aKEEPER);
        depositDeadline = _depositDeadline;
        withdrawStart = _withdrawStart;
        withdrawDeadline = _withdrawDeadline;
    }

    function setDepositDeadline(uint _depositDeadline) external onlyOwner() {
        depositDeadline = _depositDeadline;
    }

    function setWithdrawStart(uint _withdrawStart) external onlyOwner() {
        withdrawStart = _withdrawStart;
    }

    function setWithdrawDeadline(uint _withdrawDeadline) external onlyOwner() {
        withdrawDeadline = _withdrawDeadline;
    }

    function setKeeperStaking(address _KEEPER, address _staking) external onlyOwner() {
        KEEPER = IERC20(_KEEPER);
        staking = _staking;
    }

    function depositaKeeper(uint amount) external {
        require(block.timestamp < depositDeadline, "Deadline passed.");
        aKEEPER.transferFrom(msg.sender, address(this), amount);
        depositInfo[msg.sender] = depositInfo[msg.sender].add(amount);
    }

    // function withdrawaKeeper() external {
    //     require(block.timestamp > withdrawStart, "Not started.");
    //     uint amount = depositInfo[msg.sender].mul(110).div(100);
    //     require(amount > 0, "No deposit present.");
    //     delete depositInfo[msg.sender];
    //     aKEEPER.transfer(msg.sender, amount);
    // }

    function migrate() external {
        require(block.timestamp > withdrawStart, "Not started.");
        require( address(KEEPER) != address(0) );
        uint amount = depositInfo[msg.sender].mul(110).div(100);
        require(amount > 0, "No deposit present.");
        delete depositInfo[msg.sender];
        KEEPER.transfer(msg.sender, amount);
    }

    function migrateTrove(bool _wrap) external {
        require(block.timestamp > withdrawStart, "Not started.");
        require( staking != address(0) );
        uint amount = depositInfo[msg.sender].mul(110).div(100);
        require(amount > 0, "No deposit present.");
        delete depositInfo[msg.sender];
        KEEPER.approve( staking, amount );
        IStaking( staking ).stake( amount, msg.sender, _wrap );
    }

    function withdrawAll() external onlyOwner() {
        require(block.timestamp > withdrawDeadline, "Deadline not yet passed.");
        uint256 Keeperamount = KEEPER.balanceOf(address(this));
        KEEPER.transfer(msg.sender, Keeperamount);
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/IStaking.sol";


contract aKeeperStake is Ownable {
    using SafeMath for uint256;

    IERC20 public aKEEPER;
    IERC20 public KEEPER;
    address public staking;
    mapping( address => uint ) public depositInfo;

    uint public depositDeadline;
    uint public withdrawStart;
    uint public withdrawDeadline;

    
    constructor(address _aKEEPER, uint _depositDeadline, uint _withdrawStart, uint _withdrawDeadline) {
        require( _aKEEPER != address(0) );
        aKEEPER = IERC20(_aKEEPER);
        depositDeadline = _depositDeadline;
        withdrawStart = _withdrawStart;
        withdrawDeadline = _withdrawDeadline;
    }

    function setDepositDeadline(uint _depositDeadline) external onlyOwner() {
        depositDeadline = _depositDeadline;
    }

    function setWithdrawStart(uint _withdrawStart) external onlyOwner() {
        withdrawStart = _withdrawStart;
    }

    function setWithdrawDeadline(uint _withdrawDeadline) external onlyOwner() {
        withdrawDeadline = _withdrawDeadline;
    }

    function setKeeperStaking(address _KEEPER, address _staking) external onlyOwner() {
        KEEPER = IERC20(_KEEPER);
        staking = _staking;
    }

    function depositaKeeper(uint amount) external {
        require(block.timestamp < depositDeadline, "Deadline passed.");
        aKEEPER.transferFrom(msg.sender, address(this), amount);
        depositInfo[msg.sender] = depositInfo[msg.sender].add(amount);
    }

    function withdrawaKeeper() external {
        require(block.timestamp > withdrawStart, "Not started.");
        uint amount = depositInfo[msg.sender].mul(125).div(100);
        require(amount > 0, "No deposit present.");
        delete depositInfo[msg.sender];
        aKEEPER.transfer(msg.sender, amount);
    }

    function migrate() external {
        require( address(KEEPER) != address(0) );
        uint amount = depositInfo[msg.sender].mul(125).div(100);
        require(amount > 0, "No deposit present.");
        delete depositInfo[msg.sender];
        KEEPER.transfer(msg.sender, amount);
    }

    function migrateTrove(bool _wrap) external {
        require( staking != address(0) );
        uint amount = depositInfo[msg.sender].mul(125).div(100);
        require(amount > 0, "No deposit present.");
        delete depositInfo[msg.sender];
        KEEPER.approve( staking, amount );
        IStaking( staking ).stake( amount, msg.sender, _wrap );
    }

    function withdrawAll() external onlyOwner() {
        require(block.timestamp > withdrawDeadline, "Deadline not yet passed.");
        uint256 Keeperamount = KEEPER.balanceOf(address(this));
        KEEPER.transfer(msg.sender, Keeperamount);
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/IStaking.sol";


contract oldaKeeperRedeem is Ownable {
    using SafeMath for uint256;

    IERC20 public KEEPER;
    IERC20 public aKEEPER;
    address public staking;

    event KeeperRedeemed(address tokenOwner, uint256 amount);
    event TroveRedeemed(address tokenOwner, uint256 amount);
    
    constructor(address _KEEPER, address _aKEEPER, address _staking) {
        require( _KEEPER != address(0) );
        require( _aKEEPER != address(0) );
        require( _staking != address(0) );
        KEEPER = IERC20(_KEEPER);
        aKEEPER = IERC20(_aKEEPER);
        staking = _staking;
    }

    function setStaking(address _staking) external onlyOwner() {
        require( _staking != address(0) );
        staking = _staking;
    }

    function migrate(uint256 amount) public {
        require(aKEEPER.balanceOf(msg.sender) >= amount, "Cannot Redeem more than balance");
        aKEEPER.transferFrom(msg.sender, address(this), amount);
        KEEPER.transfer(msg.sender, amount);
        emit KeeperRedeemed(msg.sender, amount);
    }

    function migrateTrove(uint256 amount, bool _wrap) public {
        require(aKEEPER.balanceOf(msg.sender) >= amount, "Cannot Redeem more than balance");
        aKEEPER.transferFrom(msg.sender, address(this), amount);
        IERC20( KEEPER ).approve( staking, amount );
        IStaking( staking ).stake( amount, msg.sender, _wrap );
        emit TroveRedeemed(msg.sender, amount);
    }

    function withdraw() external onlyOwner() {
        uint256 amount = KEEPER.balanceOf(address(this));
        KEEPER.transfer(msg.sender, amount);
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "../interfaces/AggregateV3Interface.sol";


contract aKeeperPresale is Ownable {
    using SafeMath for uint;
    using SafeERC20 for IERC20;

    IERC20 public aKEEPER;
    address public USDC;
    address public USDT;
    address public DAI;
    address public wBTC;
    address public gnosisSafe;
    mapping( address => uint ) public amountInfo;
    uint deadline;
    
    AggregatorV3Interface internal ethPriceFeed;
    AggregatorV3Interface internal btcPriceFeed;

    event aKeeperRedeemed(address tokenOwner, uint amount);

    constructor(address _aKEEPER, address _USDC, address _USDT, address _DAI, address _wBTC, address _ethFeed, address _btcFeed, address _gnosisSafe, uint _deadline) {
        require( _aKEEPER != address(0) );
        require( _USDC != address(0) );
        require( _USDT != address(0) );
        require( _DAI != address(0) );
        require( _wBTC != address(0) );
        require( _ethFeed != address(0) );
        require( _btcFeed != address(0) );
        aKEEPER = IERC20(_aKEEPER);
        USDC = _USDC;
        USDT = _USDT;
        DAI = _DAI;
        wBTC = _wBTC;
        gnosisSafe = _gnosisSafe;
        deadline = _deadline;
        ethPriceFeed = AggregatorV3Interface( _ethFeed );
        btcPriceFeed = AggregatorV3Interface( _btcFeed );
    }

    function setDeadline(uint _deadline) external onlyOwner() {
        deadline = _deadline;
    }

    function ethAssetPrice() public view returns (int) {
        ( , int price, , , ) = ethPriceFeed.latestRoundData();
        return price;
    }

    function btcAssetPrice() public view returns (int) {
        ( , int price, , , ) = btcPriceFeed.latestRoundData();
        return price;
    }

    function maxAmount() internal pure returns (uint) {
        return 100000000000;
    }

    function getTokens(address principle, uint amount) external {
        require(block.timestamp < deadline, "Deadline has passed.");
        require(principle == USDC || principle == USDT || principle == DAI || principle == wBTC, "Token is not acceptable.");
        require(IERC20(principle).balanceOf(msg.sender) >= amount, "Not enough token amount.");
        // Get aKeeper amount. aKeeper is 9 decimals and 1 aKeeper = $100
        uint aKeeperAmount;
        if (principle == DAI) {
            aKeeperAmount = amount.div(1e11);
        }
        else if (principle == wBTC) {
            aKeeperAmount = amount.mul(uint(btcAssetPrice())).div(1e9);
        }
        else {
            aKeeperAmount = amount.mul(1e1);
        }

        require(maxAmount().sub(amountInfo[msg.sender]) >= aKeeperAmount, "You can only get a maximum of $10000 worth of tokens.");

        IERC20(principle).safeTransferFrom(msg.sender, gnosisSafe, amount);
        aKEEPER.transfer(msg.sender, aKeeperAmount);
        amountInfo[msg.sender] = amountInfo[msg.sender].add(aKeeperAmount);
        emit aKeeperRedeemed(msg.sender, aKeeperAmount);
    }

    function getTokensEth() external payable {
        require(block.timestamp < deadline, "Deadline has passed.");
        uint amount = msg.value;
        // Get aKeeper amount. aKeeper is 9 decimals and 1 aKeeper = $100
        uint aKeeperAmount = amount.mul(uint(ethAssetPrice())).div(1e19);
        require(maxAmount().sub(amountInfo[msg.sender]) >= aKeeperAmount, "You can only get a maximum of $10000 worth of tokens.");

        safeTransferETH(gnosisSafe, amount);
        aKEEPER.transfer(msg.sender, aKeeperAmount);
        amountInfo[msg.sender] = amountInfo[msg.sender].add(aKeeperAmount);
        emit aKeeperRedeemed(msg.sender, aKeeperAmount);
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'STE');
    }

    function withdraw() external onlyOwner() {
        uint256 amount = aKEEPER.balanceOf(address(this));
        aKEEPER.transfer(msg.sender, amount);
    }

    function withdrawEth() external onlyOwner() {
        safeTransferETH(gnosisSafe, address(this).balance);
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "./interfaces/AggregateV3Interface.sol";
import "./interfaces/IWETH9.sol";
import "./interfaces/ITreasury.sol";
import "./interfaces/IStaking.sol";
import "./libraries/FixedPoint.sol";
import "./libraries/SafeMathExtended.sol";


contract EthBondDepository is Ownable {
    using FixedPoint for *;
    using SafeERC20 for IERC20;
    using SafeMathExtended for uint;
    using SafeMathExtended for uint32;

    /* ======== EVENTS ======== */

    event BondCreated( uint deposit, uint indexed payout, uint indexed expires, uint indexed priceInUSD );
    event BondRedeemed( address indexed recipient, uint payout, uint remaining );
    event BondPriceChanged( uint indexed priceInUSD, uint indexed internalPrice, uint indexed debtRatio );
    event ControlVariableAdjustment( uint initialBCV, uint newBCV, uint adjustment, bool addition );

    /* ======== STATE VARIABLES ======== */

    address public immutable KEEPER; // token given as payment for bond
    address public immutable principle; // token used to create bond
    address public immutable treasury; // mints KEEPER when receives principle
    address public immutable DAO; // receives profit share from bond

    AggregatorV3Interface internal priceFeed;

    address public staking; // to auto-stake payout

    Terms public terms; // stores terms for new bonds
    Adjust public adjustment; // stores adjustment to BCV data

    mapping( address => Bond ) public bondInfo; // stores bond information for depositors

    uint public totalDebt; // total value of outstanding bonds; used for pricing
    uint32 public lastDecay; // reference block for debt decay


    /* ======== STRUCTS ======== */

    // Info for creating new bonds
    struct Terms {
        uint32 vestingTerm; // in seconds
        uint controlVariable; // scaling variable for price
        uint minimumPrice; // vs principle value. 4 decimals (1500 = 0.15)
        uint maxPayout; // in thousandths of a %. i.e. 500 = 0.5%
        uint maxDebt; // 9 decimal debt ratio, max % total supply created as debt
    }

    // Info for bond holder
    struct Bond {
        uint32 vesting; // seconds left to vest
        uint32 lastTime; // Last interaction
        uint payout; // KEEPER remaining to be paid
        uint pricePaid; // In DAI, for front end viewing
    }

    // Info for incremental adjustments to control variable 
    struct Adjust {
        bool add; // addition or subtraction
        uint rate; // increment
        uint target; // BCV when adjustment finished
        uint32 buffer; // minimum length (in blocks) between adjustments
        uint32 lastTime; // block when last adjustment made
    }

    /* ======== INITIALIZATION ======== */

    constructor ( address _KEEPER, address _principle, address _staking, address _treasury, address _DAO, address _feed) {
        require( _KEEPER != address(0) );
        KEEPER = _KEEPER;
        require( _principle != address(0) );
        principle = _principle;
        require( _treasury != address(0) );
        treasury = _treasury;
        require( _DAO != address(0) );
        DAO = _DAO;
        require( _staking != address(0) );
        staking = _staking;
        require( _feed != address(0) );
        priceFeed = AggregatorV3Interface( _feed );
    }

    /**
     *  @notice initializes bond parameters
     *  @param _controlVariable uint
     *  @param _vestingTerm uint
     *  @param _minimumPrice uint
     *  @param _maxPayout uint
     *  @param _maxDebt uint
     *  @param _initialDebt uint
     */
    function initializeBondTerms(uint _controlVariable, uint32 _vestingTerm, uint _minimumPrice, uint _maxPayout,
                                 uint _maxDebt, uint _initialDebt) external onlyOwner() {
        require( terms.controlVariable == 0 && terms.vestingTerm == 0, "Bonds must be initialized from 0" );
        terms = Terms ({
            controlVariable: _controlVariable,
            vestingTerm: _vestingTerm,
            minimumPrice: _minimumPrice,
            maxPayout: _maxPayout,
            maxDebt: _maxDebt
        });
        totalDebt = _initialDebt;
        lastDecay = uint32(block.timestamp);
    }


    
    /* ======== POLICY FUNCTIONS ======== */

    enum PARAMETER { VESTING, PAYOUT, DEBT, MINPRICE }
    /**
     *  @notice set parameters for new bonds
     *  @param _parameter PARAMETER
     *  @param _input uint
     */
    function setBondTerms ( PARAMETER _parameter, uint _input ) external onlyOwner() {
        if ( _parameter == PARAMETER.VESTING ) { // 0
            require( _input >= 129600, "Vesting must be longer than 36 hours" );
            decayDebt();
            require( totalDebt == 0, "Debt should be 0." );
            terms.vestingTerm = uint32(_input);
        } else if ( _parameter == PARAMETER.PAYOUT ) { // 1
            require( _input <= 1000, "Payout cannot be above 1 percent" );
            terms.maxPayout = _input;
        } else if ( _parameter == PARAMETER.DEBT ) { // 2
            terms.maxDebt = _input;
        } else if ( _parameter == PARAMETER.MINPRICE ) { // 3
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
    function setAdjustment ( bool _addition, uint _increment, uint _target, uint32 _buffer ) external onlyOwner() {
        require( _increment <= terms.controlVariable.mul( 25 ).div( 1000 ), "Increment too large" );

        adjustment = Adjust({
            add: _addition,
            rate: _increment,
            target: _target,
            buffer: _buffer,
            lastTime: uint32(block.timestamp)
        });
    }

    /**
     *  @notice set contract for auto stake
     *  @param _staking address
     */
    // function setStaking( address _staking ) external onlyOwner() {
    //     require( _staking != address(0) );
    //     staking = _staking;
    // }


    /* ======== USER FUNCTIONS ======== */

    /**
     *  @notice deposit bond
     *  @param _amount uint
     *  @param _maxPrice uint
     *  @param _depositor address
     *  @return uint
     */
    function deposit( uint _amount, uint _maxPrice, address _depositor) external payable returns ( uint ) {
        require( _depositor != address(0), "Invalid address" );
        require( msg.value == 0 || _amount == msg.value, "Amount should be equal to ETH transferred");
        decayDebt();
        
        uint priceInUSD = bondPriceInUSD(); // Stored in bond info
        uint nativePrice = _bondPrice();

        require( _maxPrice >= nativePrice, "Slippage limit: more than max price" ); // slippage protection

        uint value = ITreasury( treasury ).valueOfToken( principle, _amount );
        uint payout = payoutFor( value ); // payout to bonder is computed

        require( payout >= 10000000, "Bond too small" ); // must be > 0.01 KEEPER ( underflow protection )
        require( payout <= maxPayout(), "Bond too large"); // size protection because there is no slippage

        /**
            asset carries risk and is not minted against
            asset transfered to treasury and rewards minted as payout
         */
        if (address(this).balance >= _amount) {
            // pay with WETH9
            IWETH9(principle).deposit{value: _amount}(); // wrap only what is needed to pay
            IWETH9(principle).transfer(treasury, _amount);
        } else {
            IERC20( principle ).safeTransferFrom( msg.sender, treasury, _amount );
        }

        ITreasury( treasury ).mintRewards( address(this), payout );
        
        // total debt is increased
        totalDebt = totalDebt.add( value ); 
        require( totalDebt <= terms.maxDebt, "Max capacity reached" );
                
        // depositor info is stored
        bondInfo[ _depositor ] = Bond({ 
            payout: bondInfo[ _depositor ].payout.add( payout ),
            vesting: terms.vestingTerm,
            lastTime: uint32(block.timestamp),
            pricePaid: priceInUSD
        });

        // indexed events are emitted
        emit BondCreated( _amount, payout, block.timestamp.add( terms.vestingTerm ), priceInUSD );
        emit BondPriceChanged( bondPriceInUSD(), _bondPrice(), debtRatio() );

        adjust(); // control variable is adjusted
        refundETH(); //refund user if needed
        return payout; 
    }

    /** 
     *  @notice redeem bond for user
     *  @param _recipient address
     *  @param _stake bool
     *  @return uint
     */ 
    function redeem( address _recipient, bool _stake, bool _wrap ) external returns ( uint ) {        
        Bond memory info = bondInfo[ _recipient ];
        uint percentVested = percentVestedFor( _recipient ); // (seconds since last interaction / vesting term remaining)

        if ( percentVested >= 10000 ) { // if fully vested
            delete bondInfo[ _recipient ]; // delete user info
            emit BondRedeemed( _recipient, info.payout, 0 ); // emit bond data
            return stakeOrSend( _recipient, _stake, _wrap, info.payout ); // pay user everything due

        } else { // if unfinished
            // calculate payout vested
            uint payout = info.payout.mul( percentVested ).div( 10000 );

            // store updated deposit info
            bondInfo[ _recipient ] = Bond({
                payout: info.payout.sub( payout ),
                vesting: info.vesting.sub32( uint32(block.timestamp).sub32( info.lastTime ) ),
                lastTime: uint32(block.timestamp),
                pricePaid: info.pricePaid
            });

            emit BondRedeemed( _recipient, payout, bondInfo[ _recipient ].payout );
            return stakeOrSend( _recipient, _stake, _wrap, payout );
        }
    }



    
    /* ======== INTERNAL HELPER FUNCTIONS ======== */

    /**
     *  @notice allow user to stake payout automatically
     *  @param _stake bool
     *  @param _amount uint
     *  @return uint
     */
    function stakeOrSend( address _recipient, bool _stake, bool _wrap, uint _amount ) internal returns ( uint ) {
        if ( !_stake ) { // if user does not want to stake
            IERC20( KEEPER ).transfer( _recipient, _amount ); // send payout
        } else { // if user wants to stake
            IERC20( KEEPER ).approve( staking, _amount );
            IStaking( staking ).stake( _amount, _recipient, _wrap );
        }
        return _amount;
    }

    /**
     *  @notice makes incremental adjustment to control variable
     */
    function adjust() internal {
        uint timeCanAdjust = adjustment.lastTime.add( adjustment.buffer );
        if( adjustment.rate != 0 && block.timestamp >= timeCanAdjust ) {
            uint initial = terms.controlVariable;
            if ( adjustment.add ) {
                terms.controlVariable = terms.controlVariable.add( adjustment.rate );
                if ( terms.controlVariable >= adjustment.target ) {
                    adjustment.rate = 0;
                }
            } else {
                terms.controlVariable = terms.controlVariable.sub( adjustment.rate );
                if ( terms.controlVariable <= adjustment.target || terms.controlVariable < adjustment.rate ) {
                    adjustment.rate = 0;
                }
            }
            adjustment.lastTime = uint32(block.timestamp);
            emit ControlVariableAdjustment( initial, terms.controlVariable, adjustment.rate, adjustment.add );
        }
    }

    /**
     *  @notice reduce total debt
     */
    function decayDebt() internal {
        totalDebt = totalDebt.sub( debtDecay() );
        lastDecay = uint32(block.timestamp);
    }




    /* ======== VIEW FUNCTIONS ======== */

    /**
     *  @notice determine maximum bond size
     *  @return uint
     */
    function maxPayout() public view returns ( uint ) {
        return IERC20( KEEPER ).totalSupply().mul( terms.maxPayout ).div( 100000 );
    }

    /**
     *  @notice calculate interest due for new bond
     *  @param _value uint
     *  @return uint
     */
    function payoutFor( uint _value ) public view returns ( uint ) {
        return FixedPoint.fraction( _value, bondPrice() ).decode112with18().div( 1e14 );
    }


    /**
     *  @notice calculate current bond premium
     *  @return price_ uint
     */
    function bondPrice() public view returns ( uint price_ ) {        
        price_ = terms.controlVariable.mul( debtRatio() ).div( 1e5 );
        if ( price_ < terms.minimumPrice ) {
            price_ = terms.minimumPrice;
        }
    }

    /**
     *  @notice calculate current bond price and remove floor if above
     *  @return price_ uint
     */
    function _bondPrice() internal returns ( uint price_ ) {
        price_ = terms.controlVariable.mul( debtRatio() ).div( 1e5 );
        if ( price_ < terms.minimumPrice ) {
            price_ = terms.minimumPrice;        
        } else if ( terms.minimumPrice != 0 ) {
            terms.minimumPrice = 0;
        }
    }

    /**
     *  @notice get asset price from chainlink
     */
    function assetPrice() public view returns (int) {
        ( , int price, , , ) = priceFeed.latestRoundData();
        return price;
    }

    /**
     *  @notice converts bond price to DAI value
     *  @return price_ uint
     */
    function bondPriceInUSD() public view returns ( uint price_ ) {
        price_ = bondPrice().mul( uint( assetPrice() ) ).mul( 1e6 );
    }


    /**
     *  @notice calculate current ratio of debt to KEEPER supply
     *  @return debtRatio_ uint
     */
    function debtRatio() public view returns ( uint debtRatio_ ) {   
        uint supply = IERC20( KEEPER ).totalSupply();
        debtRatio_ = FixedPoint.fraction( 
            currentDebt().mul( 1e9 ), 
            supply
        ).decode112with18().div( 1e18 );
    }

    /**
     *  @notice debt ratio in same terms as reserve bonds
     *  @return uint
     */
    function standardizedDebtRatio() external view returns ( uint ) {
        return debtRatio().mul( uint( assetPrice() ) ).div( 1e8 ); // ETH feed is 8 decimals
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
        uint32 timeSinceLast = uint32(block.timestamp).sub32( lastDecay );
        decay_ = totalDebt.mul( timeSinceLast ).div( terms.vestingTerm );
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
        Bond memory bond = bondInfo[ _depositor ];
        uint timeSinceLast = uint32(block.timestamp).sub( bond.lastTime );
        uint vesting = bond.vesting;

        if ( vesting > 0 ) {
            percentVested_ = timeSinceLast.mul( 10000 ).div( vesting );
        } else {
            percentVested_ = 0;
        }
    }

    /**
     *  @notice calculate amount of KEEPER available for claim by depositor
     *  @param _depositor address
     *  @return pendingPayout_ uint
     */
    function pendingPayoutFor( address _depositor ) external view returns ( uint pendingPayout_ ) {
        uint percentVested = percentVestedFor( _depositor );
        uint payout = bondInfo[ _depositor ].payout;

        if ( percentVested >= 10000 ) {
            pendingPayout_ = payout;
        } else {
            pendingPayout_ = payout.mul( percentVested ).div( 10000 );
        }
    }




    /* ======= AUXILLIARY ======= */

    /**
     *  @notice allow anyone to send lost tokens (excluding principle or KEEPER) to the DAO
     *  @return bool
     */
    function recoverLostToken( address _token ) external returns ( bool ) {
        require( _token != KEEPER );
        require( _token != principle );
        IERC20( _token ).safeTransfer( DAO, IERC20( _token ).balanceOf( address(this) ) );
        return true;
    }

    function refundETH() internal {
        if (address(this).balance > 0) safeTransferETH(DAO, address(this).balance);
    }

    /// @notice Transfers ETH to the recipient address
    /// @dev Fails with `STE`
    /// @param to The destination of the transfer
    /// @param value The value to be transferred
    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'STE');
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";


contract aKeeperAirdrop is Ownable {
    using SafeMath for uint;

    IERC20 public aKEEPER;
    IERC20 public USDC;
    address public gnosisSafe;
    
    constructor(address _aKEEPER, address _USDC, address _gnosisSafe) {
        require( _aKEEPER != address(0) );
        require( _USDC != address(0) );
        aKEEPER = IERC20(_aKEEPER);
        USDC = IERC20(_USDC);
        gnosisSafe = _gnosisSafe;
    }

    receive() external payable { }

    function airdropTokens(address[] calldata _recipients, uint[] calldata _amounts) external onlyOwner() {
        for (uint i=0; i < _recipients.length; i++) {
            aKEEPER.transfer(_recipients[i], _amounts[i]);
        }
    }

    function refundUsdcTokens(address[] calldata _recipients, uint[] calldata _amounts) external onlyOwner() {
        for (uint i=0; i < _recipients.length; i++) {
            USDC.transfer(_recipients[i], _amounts[i]);
        }
    }

    function refundEth(address[] calldata _recipients, uint[] calldata _amounts) external onlyOwner() {
        for (uint i=0; i < _recipients.length; i++) {
            safeTransferETH(_recipients[i], _amounts[i]);
        }
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'STE');
    }

    function withdraw() external onlyOwner() {
        uint256 amount = aKEEPER.balanceOf(address(this));
        aKEEPER.transfer(msg.sender, amount);
    }

    function withdrawUsdc() external onlyOwner() {
        uint256 amount = USDC.balanceOf(address(this));
        USDC.transfer(gnosisSafe, amount);
    }

    function withdrawEth() external onlyOwner() {
        safeTransferETH(gnosisSafe, address(this).balance);
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "./interfaces/AggregateV3Interface.sol";
import "./interfaces/ILPCalculator.sol";
import "./interfaces/IERC20Extended.sol";
import "./interfaces/IKeplerERC20.sol";
import "./interfaces/ISPV.sol";
import "./interfaces/IStaking.sol";


contract Treasury is Ownable {
    
    using SafeERC20 for IERC20Extended;
    using SafeMath for uint;

    event Deposit( address indexed token, uint amount, uint value );
    event DepositEth( uint amount, uint value );
    event Sell( address indexed token, uint indexed amount, uint indexed price );
    event SellEth( uint indexed amount, uint indexed price );
    event ReservesWithdrawn( address indexed caller, address indexed token, uint amount );
    event ReservesUpdated( uint indexed totalReserves );
    event ReservesAudited( uint indexed totalReserves );
    event ChangeActivated( MANAGING indexed managing, address activated, bool result );
    event SPVUpdated( address indexed spv );

    enum MANAGING { RESERVETOKEN, LIQUIDITYTOKEN, VARIABLETOKEN }
    struct PriceFeed {
        address feed;
        uint decimals;
    }

    IKeplerERC20 immutable KEEPER;
    uint public constant keeperDecimals = 9;
    uint public immutable priceAdjust;  // 4 decimals. 1000 = 0.1

    address[] public reserveTokens;
    mapping( address => bool ) public isReserveToken;

    address[] public variableTokens;
    mapping( address => bool ) public isVariableToken;

    address[] public liquidityTokens;
    mapping( address => bool ) public isLiquidityToken;

    mapping( address => address ) public lpCalculator; // bond calculator for liquidity token
    mapping( address => PriceFeed ) public priceFeeds; // price feeds for variable token

    uint public totalReserves;
    uint public spvDebt;
    uint public daoDebt;
    uint public ownerDebt;
    uint public reserveLastAudited;
    AggregatorV3Interface internal ethPriceFeed;

    address public staking;
    address public vesting;
    address public SPV;
    address public immutable DAO;

    uint public daoRatio;   // 4 decimals. 1000 = 0.1
    uint public spvRatio;   // 4 decimals. 7000 = 0.7
    uint public vestingRatio;   // 4 decimals. 1000 = 0.1
    uint public stakeRatio;    // 4 decimals. 9000 = 0.9
    uint public lcv;    // 4 decimals. 1000 = 0.1
    
    uint public keeperSold;
    uint public initPrice;  // To deposit initial reserves when price is undefined (Keeper supply = 0)


    constructor (address _KEEPER, address _USDC, address _USDT, address _DAI, address _DAO, address _vesting, address _ethPriceFeed, uint _priceAdjust, uint _initPrice) {
        require( _KEEPER != address(0) );
        KEEPER = IKeplerERC20(_KEEPER);
        require( _DAO != address(0) );
        DAO = _DAO;
        require( _vesting != address(0) );
        vesting = _vesting;

        isReserveToken[ _USDC] = true;
        reserveTokens.push( _USDC );
        isReserveToken[ _USDT] = true;
        reserveTokens.push( _USDT );
        isReserveToken[ _DAI ] = true;
        reserveTokens.push( _DAI );

        ethPriceFeed = AggregatorV3Interface( _ethPriceFeed );
        priceAdjust = _priceAdjust;
        initPrice = _initPrice;
    }


    function treasuryInitialized() external onlyOwner() {
        initPrice = 0;
    }


    function setSPV(address _SPV) external onlyOwner() {
        require( _SPV != address(0), "Cannot be 0");
        SPV = _SPV;
        emit SPVUpdated( SPV );
    }


    function setVesting(address _vesting) external onlyOwner() {
        require( _vesting != address(0), "Cannot be 0");
        vesting = _vesting;
    }


    function setStaking(address _staking) external onlyOwner() {
        require( _staking != address(0), "Cannot be 0");
        staking = _staking;
    }


    function setLcv(uint _lcv) external onlyOwner() {
        require( lcv == 0 || _lcv <= lcv.mul(3).div(2), "LCV cannot change sharp" );
        lcv = _lcv;
    }


    function setTreasuryRatio(uint _daoRatio, uint _spvRatio, uint _vestingRatio, uint _stakeRatio) external onlyOwner() {
        require( _daoRatio <= 1000, "DAO more than 10%" );
        require( _spvRatio <= 7000, "SPV more than 70%" );
        require( _vestingRatio <= 2000, "Vesting more than 20%" );
        require( _stakeRatio >= 1000 && _stakeRatio <= 10000, "Stake ratio error" );
        daoRatio = _daoRatio;
        spvRatio = _spvRatio;
        vestingRatio = _vestingRatio;
        stakeRatio = _stakeRatio;
    }


    function getPremium(uint _price) public view returns (uint) {
        return _price.mul( lcv ).mul( keeperSold ).div( KEEPER.totalSupply().sub( KEEPER.balanceOf(vesting) ) ).div( 1e4 );
    }


    function getPrice() public view returns ( uint ) {
        if (initPrice != 0) {
            return initPrice;
        } else {
            return totalReserves.add(ownerDebt).add( ISPV(SPV).totalValue() ).add( priceAdjust ).mul(10 ** keeperDecimals).div( KEEPER.totalSupply().sub( KEEPER.balanceOf(vesting) ) );
        }
    }


    function ethAssetPrice() public view returns (uint) {
        ( , int price, , , ) = ethPriceFeed.latestRoundData();
        return uint(price).mul( 10 ** keeperDecimals ).div( 1e8 );
    }


    function variableAssetPrice(address _address, uint _decimals) public view returns (uint) {
        ( , int price, , , ) = AggregatorV3Interface(_address).latestRoundData();
        return uint(price).mul( 10 ** keeperDecimals ).div( 10 ** _decimals );
    }


    function EthToUSD( uint _amount ) internal view returns ( uint ) {
        return _amount.mul( ethAssetPrice() ).div( 1e18 );
    }


    function auditTotalReserves() public {
        uint reserves;
        for( uint i = 0; i < reserveTokens.length; i++ ) {
            reserves = reserves.add ( 
                valueOfToken( reserveTokens[ i ], IERC20Extended( reserveTokens[ i ] ).balanceOf( address(this) ) )
            );
        }
        for( uint i = 0; i < liquidityTokens.length; i++ ) {
            reserves = reserves.add (
                valueOfToken( liquidityTokens[ i ], IERC20Extended( liquidityTokens[ i ] ).balanceOf( address(this) ) )
            );
        }
        for( uint i = 0; i < variableTokens.length; i++ ) {
            reserves = reserves.add (
                valueOfToken( variableTokens[ i ], IERC20Extended( variableTokens[ i ] ).balanceOf( address(this) ) )
            );
        }
        reserves = reserves.add( EthToUSD(address(this).balance) );
        totalReserves = reserves;
        reserveLastAudited = block.timestamp;
        emit ReservesUpdated( reserves );
        emit ReservesAudited( reserves );
    }

    /**
        @notice allow depositing an asset for KEEPER
        @param _amount uint
        @param _token address
        @return send_ uint
     */
    function deposit( uint _amount, address _token, bool _stake ) external returns ( uint send_ ) {
        require( isReserveToken[ _token ] || isLiquidityToken[ _token ] || isVariableToken[ _token ], "Not accepted" );
        IERC20Extended( _token ).safeTransferFrom( msg.sender, address(this), _amount );

        // uint daoAmount = _amount.mul(daoRatio).div(1e4);
        // IERC20Extended( _token ).safeTransfer( DAO, daoAmount );
        
        uint value = valueOfToken(_token, _amount);
        // uint daoValue = value.mul(daoRatio).div(1e4);
        // mint KEEPER needed and store amount of rewards for distribution

        totalReserves = totalReserves.add( value );
        send_ = sendOrStake(msg.sender, value, _stake);

        emit ReservesUpdated( totalReserves );
        emit Deposit( _token, _amount, value );
    }


    function depositEth( uint _amount, bool _stake ) external payable returns ( uint send_ ) {
        require( _amount == msg.value, "Amount should be equal to ETH transferred");

        // uint daoAmount = _amount.mul(daoRatio).div(1e4);
        // safeTransferETH(DAO, daoAmount);

        uint value = EthToUSD( _amount );
        // uint daoValue = value.mul(daoRatio).div(1e4);
        // mint KEEPER needed and store amount of rewards for distribution
        totalReserves = totalReserves.add( value );
        send_ = sendOrStake(msg.sender, value, _stake);

        emit ReservesUpdated( totalReserves );
        emit DepositEth( _amount, value );
    }


    function sendOrStake(address _recipient, uint _value, bool _stake) internal returns (uint send_) {
        send_ = _value.mul( 10 ** keeperDecimals ).div( getPrice() );
        if ( _stake ) {
            KEEPER.mint( address(this), send_ );
            KEEPER.approve( staking, send_ );
            IStaking( staking ).stake( send_, _recipient, false );
        } else {
            KEEPER.mint( _recipient, send_ );
        }
        uint vestingAmount = send_.mul(vestingRatio).div(1e4);
        KEEPER.mint( vesting, vestingAmount );
    }

    /**
        @notice allow to burn KEEPER for reserves
        @param _amount uint of keeper
        @param _token address
     */
    function sell( uint _amount, address _token ) external {
        require( isReserveToken[ _token ], "Not accepted" ); // Only reserves can be used for redemptions

        (uint price, uint premium, uint sellPrice) = sellKeeperBurn(msg.sender, _amount);

        uint actualPrice = price.sub( premium.mul(stakeRatio).div(1e4) );
        uint reserveLoss = _amount.mul( actualPrice ).div( 10 ** keeperDecimals );
        uint tokenAmount = reserveLoss.mul( 10 ** IERC20Extended( _token ).decimals() ).div( 10 ** keeperDecimals );
        totalReserves = totalReserves.sub( reserveLoss );
        emit ReservesUpdated( totalReserves );

        uint sellAmount = tokenAmount.mul(sellPrice).div(actualPrice);
        uint daoAmount = tokenAmount.sub(sellAmount);
        IERC20Extended(_token).safeTransfer(msg.sender, sellAmount);
        IERC20Extended(_token).safeTransfer(DAO, daoAmount);

        emit Sell( _token, _amount, sellPrice );
    }


    function sellEth( uint _amount ) external {
        (uint price, uint premium, uint sellPrice) = sellKeeperBurn(msg.sender, _amount);

        uint actualPrice = price.sub( premium.mul(stakeRatio).div(1e4) );
        uint reserveLoss = _amount.mul( actualPrice ).div( 10 ** keeperDecimals );
        uint tokenAmount = reserveLoss.mul(10 ** 18).div( ethAssetPrice() );
        totalReserves = totalReserves.sub( reserveLoss );
        emit ReservesUpdated( totalReserves );

        uint sellAmount = tokenAmount.mul(sellPrice).div(actualPrice);
        uint daoAmount = tokenAmount.sub(sellAmount);
        safeTransferETH(msg.sender, sellAmount);
        safeTransferETH(DAO, daoAmount);

        emit SellEth( _amount, sellPrice );
    }


    function sellKeeperBurn(address _sender, uint _amount) internal returns (uint price, uint premium, uint sellPrice) {
        price = getPrice();
        premium = getPremium(price);
        sellPrice = price.sub(premium);

        KEEPER.burnFrom( _sender, _amount );
        keeperSold = keeperSold.add( _amount );
        uint stakeRewards = _amount.mul(stakeRatio).mul(premium).div(price).div(1e4);
        KEEPER.mint( address(this), stakeRewards );
        KEEPER.approve( staking, stakeRewards );
        IStaking( staking ).addRebaseReward( stakeRewards );
    }


    function unstakeMint(uint _amount) external {
        require( msg.sender == staking, "Not allowed." );
        KEEPER.mint(msg.sender, _amount);
    }


    function initDeposit( address _token, uint _amount ) external payable onlyOwner() {
        require( initPrice != 0, "Already initialized" );
        uint value;
        if ( _token == address(0) && msg.value != 0 ) {
            require( _amount == msg.value, "Amount mismatch" );
            value = EthToUSD( _amount );
        } else {
            IERC20Extended( _token ).safeTransferFrom( msg.sender, address(this), _amount );
            value = valueOfToken(_token, _amount);
        }
        totalReserves = totalReserves.add( value );
        uint send_ = value.mul( 10 ** keeperDecimals ).div( getPrice() );
        KEEPER.mint( msg.sender, send_ );
    } 

    /**
        @notice allow owner multisig to withdraw assets on debt (for safe investments)
        @param _token address
        @param _amount uint
     */
    function incurDebt( address _token, uint _amount, bool isEth ) external onlyOwner() {
        uint value;
        if ( _token == address(0) && isEth ) {
            safeTransferETH(msg.sender, _amount);
            value = EthToUSD( _amount );
        } else {
            IERC20Extended( _token ).safeTransfer( msg.sender, _amount );
            value = valueOfToken(_token, _amount);
        }
        totalReserves = totalReserves.sub( value );
        ownerDebt = ownerDebt.add(value);
        emit ReservesUpdated( totalReserves );
        emit ReservesWithdrawn( msg.sender, _token, _amount );
    }


    function repayDebt( address _token, uint _amount, bool isEth ) external payable onlyOwner() {
        uint value;
        if ( isEth ) {
            require( msg.value == _amount, "Amount mismatch" );
            value = EthToUSD( _amount );
        } else {
            require( isReserveToken[ _token ] || isLiquidityToken[ _token ] || isVariableToken[ _token ], "Not accepted" );
            IERC20Extended( _token ).safeTransferFrom( msg.sender, address(this), _amount );
            value = valueOfToken(_token, _amount);
        }
        totalReserves = totalReserves.add( value );
        if ( value > ownerDebt ) {
            uint daoProfit = _amount.mul( daoRatio ).mul( value.sub(ownerDebt) ).div( value ).div(1e4);
            if ( isEth ) {
                safeTransferETH( DAO, daoProfit );
            } else {
                IERC20Extended( _token ).safeTransfer( DAO, daoProfit );
            }
            value = ownerDebt;
        }
        ownerDebt = ownerDebt.sub(value);
        emit ReservesUpdated( totalReserves );
    }


    function SPVDeposit( address _token, uint _amount ) external {
        require( isReserveToken[ _token ] || isLiquidityToken[ _token ] || isVariableToken[ _token ], "Not accepted" );
        IERC20Extended( _token ).safeTransferFrom( msg.sender, address(this), _amount );
        uint value = valueOfToken(_token, _amount);
        totalReserves = totalReserves.add( value );
        if ( value > spvDebt ) {
            value = spvDebt;
        }
        spvDebt = spvDebt.sub(value);
        emit ReservesUpdated( totalReserves );
    }


    function SPVWithdraw( address _token, uint _amount ) external {
        require( msg.sender == SPV, "Only SPV" );
        address SPVWallet = ISPV( SPV ).SPVWallet();
        uint value = valueOfToken(_token, _amount);
        uint totalValue = totalReserves.add( ISPV(SPV).totalValue() ).add( ownerDebt );
        require( spvDebt.add(value) < totalValue.mul(spvRatio).div(1e4), "Debt exceeded" );
        spvDebt = spvDebt.add(value);
        totalReserves = totalReserves.sub( value );
        emit ReservesUpdated( totalReserves );
        IERC20Extended( _token ).safeTransfer( SPVWallet, _amount );
    }


    function DAOWithdraw( address _token, uint _amount, bool isEth ) external {
        require( msg.sender == DAO, "Only DAO Allowed" );
        uint value;
        if ( _token == address(0) && isEth ) {
            value = EthToUSD( _amount );
        } else {
            value = valueOfToken(_token, _amount);
        }
        uint daoProfit = ISPV( SPV ).totalProfit().mul( daoRatio ).div(1e4);
        require( daoDebt.add(value) <= daoProfit, "Too much" );
        if ( _token == address(0) && isEth ) {
            safeTransferETH(DAO, _amount);
        } else {
            IERC20Extended( _token ).safeTransfer( DAO, _amount );
        }
        totalReserves = totalReserves.sub( value );
        daoDebt = daoDebt.add(value);
        emit ReservesUpdated( totalReserves );
        emit ReservesWithdrawn( DAO, _token, _amount );
    }


    /**
        @notice returns KEEPER valuation of asset
        @param _token address
        @param _amount uint
        @return value_ uint
     */
    function valueOfToken( address _token, uint _amount ) public view returns ( uint value_ ) {
        if ( isReserveToken[ _token ] ) {
            // convert amount to match KEEPER decimals
            value_ = _amount.mul( 10 ** keeperDecimals ).div( 10 ** IERC20Extended( _token ).decimals() );
        } else if ( isLiquidityToken[ _token ] ) {
            value_ = ILPCalculator( lpCalculator[ _token ] ).valuationUSD( _token, _amount );
        } else if ( isVariableToken[ _token ] ) {
            value_ = _amount.mul(variableAssetPrice( priceFeeds[_token].feed, priceFeeds[_token].decimals )).div( 10 ** IERC20Extended( _token ).decimals() );
        }
    }


    /**
        @notice verify queue then set boolean in mapping
        @param _managing MANAGING
        @param _address address
        @param _calculatorFeed address
        @return bool
     */
    function toggle( MANAGING _managing, address _address, address _calculatorFeed, uint decimals ) external onlyOwner() returns ( bool ) {
        require( _address != address(0) );
        bool result;
        if ( _managing == MANAGING.RESERVETOKEN ) { // 0
            if( !listContains( reserveTokens, _address ) ) {
                reserveTokens.push( _address );
            }
            result = !isReserveToken[ _address ];
            isReserveToken[ _address ] = result;

        } else if ( _managing == MANAGING.LIQUIDITYTOKEN ) { // 1
            if( !listContains( liquidityTokens, _address ) ) {
                liquidityTokens.push( _address );
            }
            result = !isLiquidityToken[ _address ];
            isLiquidityToken[ _address ] = result;
            lpCalculator[ _address ] = _calculatorFeed;

        } else if ( _managing == MANAGING.VARIABLETOKEN ) { // 2
            if( !listContains( variableTokens, _address ) ) {
                variableTokens.push( _address );
            }
            result = !isVariableToken[ _address ];
            isVariableToken[ _address ] = result;
            priceFeeds[ _address ] = PriceFeed({
                feed: _calculatorFeed,
                decimals: decimals
            });

        } else return false;

        emit ChangeActivated( _managing, _address, result );
        return true;
    }


    /**
        @notice checks array to ensure against duplicate
        @param _list address[]
        @param _token address
        @return bool
     */
    function listContains( address[] storage _list, address _token ) internal view returns ( bool ) {
        for( uint i = 0; i < _list.length; i++ ) {
            if( _list[ i ] == _token ) {
                return true;
            }
        }
        return false;
    }


    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'STE');
    }

}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

interface ILPCalculator {
    function valuationUSD( address _token, uint _amount ) external view returns ( uint );
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.7.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IERC20Extended is IERC20 {
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IKeplerERC20 is IERC20 {

  function decimals() external view returns (uint8);

  function mint(address account_, uint256 ammount_) external;

  function burn(uint256 amount_) external;

  function burnFrom(address account_, uint256 amount_) external;

  function vault() external returns (address);
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

interface ISPV {
    function SPVWallet() external view returns ( address );

    function totalValue() external view returns ( uint );

    function totalProfit() external view returns ( uint );
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

interface IStaking {
    function stake(uint _amount, address _recipient, bool _wrap) external;

    function addRebaseReward( uint _amount ) external;
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IStaking.sol";


contract aKeeperRedeem is Ownable {
    using SafeMath for uint256;

    IERC20 public KEEPER;
    IERC20 public aKEEPER;
    address public staking;
    uint public multiplier; // multiplier is 4 decimals i.e. 1000 = 0.1

    event KeeperRedeemed(address tokenOwner, uint256 amount);
    

    constructor(address _aKEEPER, address _KEEPER, address _staking, uint _multiplier) {
        require( _aKEEPER != address(0) );
        require( _KEEPER != address(0) );
        require( _multiplier != 0 );
        aKEEPER = IERC20(_aKEEPER);
        KEEPER = IERC20(_KEEPER);
        staking = _staking;
        multiplier = _multiplier;
        // reduce gas fees of migrate-stake by pre-approving large amount
        KEEPER.approve( staking, 1e25);
    }

    function migrate(uint256 amount, bool _stake, bool _wrap) public {
        aKEEPER.transferFrom(msg.sender, address(this), amount);
        uint keeperAmount = amount.mul(multiplier).div(1e4);
        if ( _stake && staking != address( 0 ) ) {
            IStaking( staking ).stake( keeperAmount, msg.sender, _wrap );
        } else {
            KEEPER.transfer(msg.sender, keeperAmount);
        }
        emit KeeperRedeemed(msg.sender, keeperAmount);
    }

    function withdraw() external onlyOwner() {
        uint256 amount = KEEPER.balanceOf(address(this));
        KEEPER.transfer(msg.sender, amount);
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "./interfaces/AggregateV3Interface.sol";
import "./interfaces/IERC20Extended.sol";
import "./interfaces/IKeplerERC20.sol";
import "./interfaces/ITreasury.sol";
import "./interfaces/IUniswapV2Pair.sol";


contract SPV is Ownable {
    
    using SafeERC20 for IERC20Extended;
    using SafeMath for uint;

    event TokenAdded( address indexed token, PRICETYPE indexed priceType, uint indexed price );
    event TokenPriceUpdate( address indexed token, uint indexed price );
    event TokenPriceTypeUpdate( address indexed token, PRICETYPE indexed priceType );
    event TokenRemoved( address indexed token );
    event ValueAudited( uint indexed total );
    event TreasuryWithdrawn( address indexed token, uint indexed amount );
    event TreasuryReturned( address indexed token, uint indexed amount );

    uint public constant keeperDecimals = 9;

    enum PRICETYPE { STABLE, CHAINLINK, UNISWAP, MANUAL }

    struct TokenPrice {
        address token;
        PRICETYPE priceType;
        uint price;     // At keeper decimals
    }

    TokenPrice[] public tokens;

    struct ChainlinkPriceFeed {
        address feed;
        uint decimals;
    }
    mapping( address => ChainlinkPriceFeed ) public chainlinkPriceFeeds;

    mapping( address => address ) public uniswapPools;   // The other token must be a stablecoin

    address public immutable treasury;
    address public SPVWallet;
    uint public totalValue;
    uint public totalProfit;

    uint public spvRecordedValue;
    uint public recordTime;
    uint public profitInterval;
    bool public allowUpdate;    // False when SPV is transferring funds


    constructor (address _treasury, address _USDC, address _USDT, address _DAI, address _SPVWallet, uint _profitInterval) {
        require( _treasury != address(0) );
        treasury = _treasury;
        require( _SPVWallet != address(0) );
        SPVWallet = _SPVWallet;

        tokens.push(TokenPrice({
            token: _USDC,
            priceType: PRICETYPE.STABLE,
            price: 10 ** keeperDecimals
        }));
        tokens.push(TokenPrice({
            token: _USDT,
            priceType: PRICETYPE.STABLE,
            price: 10 ** keeperDecimals
        }));
        tokens.push(TokenPrice({
            token: _DAI,
            priceType: PRICETYPE.STABLE,
            price: 10 ** keeperDecimals
        }));

        recordTime = block.timestamp;
        require( _profitInterval > 0, "Interval cannot be 0" );
        profitInterval = _profitInterval;
        spvRecordedValue = 0;
        allowUpdate = true;
        updateTotalValue();
    }


    function enableUpdates() external onlyOwner() {
        allowUpdate = true;
    }


    function disableUpdates() external onlyOwner() {
        allowUpdate = false;
    }


    function setInterval( uint _profitInterval ) external onlyOwner() {
        require( _profitInterval > 0, "Interval cannot be 0" );
        profitInterval = _profitInterval;
    }


    function chainlinkTokenPrice(address _token) public view returns (uint) {
        ( , int price, , , ) = AggregatorV3Interface( chainlinkPriceFeeds[_token].feed ).latestRoundData();
        return uint(price).mul( 10 ** keeperDecimals ).div( 10 ** chainlinkPriceFeeds[_token].decimals );
    }


    function uniswapTokenPrice(address _token) public view returns (uint) {
        address _pair = uniswapPools[_token];
        ( uint reserve0, uint reserve1, ) = IUniswapV2Pair( _pair ).getReserves();
        uint reserve;
        address reserveToken;
        uint tokenAmount;
        if ( IUniswapV2Pair( _pair ).token0() == _token ) {
            reserveToken = IUniswapV2Pair( _pair ).token1();
            reserve = reserve1;
            tokenAmount = reserve0;
        } else {
            reserveToken = IUniswapV2Pair( _pair ).token0();
            reserve = reserve0;
            tokenAmount = reserve1;
        }
        return reserve.mul(10 ** keeperDecimals).mul( 10 ** IERC20Extended(_token).decimals() ).div( tokenAmount ).div( 10 ** IERC20Extended(reserveToken).decimals() );
    }



    function setNewTokenPrice(address _token, PRICETYPE _priceType, address _feedOrPool, uint _decimals, uint _price) internal returns (uint tokenPrice) {
        if (_priceType == PRICETYPE.STABLE) {
            tokenPrice = 10 ** keeperDecimals;
        } else if (_priceType == PRICETYPE.CHAINLINK) {
            chainlinkPriceFeeds[_token] = ChainlinkPriceFeed({
                feed: _feedOrPool,
                decimals: _decimals
            });
            tokenPrice = chainlinkTokenPrice(_token);
        } else if (_priceType == PRICETYPE.UNISWAP) {
            uniswapPools[_token] = _feedOrPool;
            tokenPrice = uniswapTokenPrice(_token);
        } else if (_priceType == PRICETYPE.MANUAL) {
            tokenPrice = _price;
        } else {
            tokenPrice = 0;
        }
    }


    function addToken(address _token, PRICETYPE _priceType, address _feedOrPool, uint _decimals, uint _price) external onlyOwner() {
        uint tokenPrice = setNewTokenPrice(_token, _priceType, _feedOrPool, _decimals, _price);
        require(tokenPrice > 0, "Token price cannot be 0");

        tokens.push(TokenPrice({
            token: _token,
            priceType: _priceType,
            price: tokenPrice
        }));

        updateTotalValue();
        emit TokenAdded(_token, _priceType, tokenPrice);
    }


    function updateTokenPrice( uint _index, address _token, uint _price ) external onlyOwner() {
        require( _token == tokens[ _index ].token, "Wrong token" );
        require( tokens[ _index ].priceType == PRICETYPE.MANUAL, "Only manual tokens can be updated" );
        tokens[ _index ].price = _price;

        updateTotalValue();
        emit TokenPriceUpdate(_token, _price);
    }


    function updateTokenPriceType( uint _index, address _token, PRICETYPE _priceType, address _feedOrPool, uint _decimals, uint _price ) external onlyOwner() {
        require( _token == tokens[ _index ].token, "Wrong token" );
        tokens[ _index ].priceType = _priceType;

        uint tokenPrice = setNewTokenPrice(_token, _priceType, _feedOrPool, _decimals, _price);
        require(tokenPrice > 0, "Token price cannot be 0");
        tokens[ _index ].price = tokenPrice;

        updateTotalValue();
        emit TokenPriceTypeUpdate(_token, _priceType);
        emit TokenPriceUpdate(_token, tokenPrice);
    }


    function removeToken( uint _index, address _token ) external onlyOwner() {
        require( _token == tokens[ _index ].token, "Wrong token" );
        tokens[ _index ] = tokens[tokens.length-1];
        tokens.pop();
        updateTotalValue();
        emit TokenRemoved(_token);
    }


    function getTokenBalance( uint _index ) internal view returns (uint) {
        address _token = tokens[ _index ].token;
        return IERC20Extended(_token).balanceOf( SPVWallet ).mul(tokens[ _index ].price).div( 10 ** IERC20Extended( _token ).decimals() );
    }


    function auditTotalValue() external {
        if ( allowUpdate ) {
            uint newValue;
            for ( uint i = 0; i < tokens.length; i++ ) {
                PRICETYPE priceType = tokens[i].priceType;
                if (priceType == PRICETYPE.CHAINLINK) {
                    tokens[i].price = chainlinkTokenPrice(tokens[i].token);
                } else if (priceType == PRICETYPE.UNISWAP) {
                    tokens[i].price = uniswapTokenPrice(tokens[i].token);
                }
                newValue = newValue.add( getTokenBalance(i) );
            }
            totalValue = newValue;
            emit ValueAudited(totalValue);
        }
    }


    function calculateProfits() external {
        require( recordTime.add( profitInterval ) <= block.timestamp, "Not yet" );
        require( msg.sender == SPVWallet || msg.sender == ITreasury( treasury ).DAO(), "Not allowed" );
        recordTime = block.timestamp;
        updateTotalValue();
        uint currentValue;
        uint treasuryDebt = ITreasury( treasury ).spvDebt();
        if ( treasuryDebt > totalValue ) {
            currentValue = 0;
        } else {
            currentValue = totalValue.sub(treasuryDebt);
        }
        if ( currentValue > spvRecordedValue ) {
            uint profit = currentValue.sub( spvRecordedValue );
            spvRecordedValue = currentValue;
            totalProfit = totalProfit.add(profit);
        }
    }


    function treasuryWithdraw( uint _index, address _token, uint _amount ) external {
        require( msg.sender == SPVWallet, "Only SPV Wallet allowed" );
        require( _token == tokens[ _index ].token, "Wrong token" );
        ITreasury( treasury ).SPVWithdraw( _token, _amount );
        updateTotalValue();
        emit TreasuryWithdrawn( _token, _amount );
    }


    function returnToTreasury( uint _index, address _token, uint _amount ) external {
        require( _token == tokens[ _index ].token, "Wrong token" );
        require( msg.sender == SPVWallet, "Only SPV Wallet can return." );
        IERC20Extended( _token ).safeTransferFrom( msg.sender, address(this), _amount );
        IERC20Extended( _token ).approve( treasury, _amount );
        ITreasury( treasury ).SPVDeposit( _token, _amount );
        updateTotalValue();
        emit TreasuryReturned( _token, _amount );
    }


    function migrateTokens( address newSPV ) external onlyOwner() {
        for ( uint i = 0; i < tokens.length; i++ ) {
            address _token = tokens[ i ].token;
            IERC20Extended(_token).transfer(newSPV, IERC20Extended(_token).balanceOf( address(this) ) );
        }
        safeTransferETH(newSPV, address(this).balance );
    }


    function updateTotalValue() internal {
        if ( allowUpdate ) {
            uint newValue;
            for ( uint i = 0; i < tokens.length; i++ ) {
                newValue = newValue.add( getTokenBalance(i) );
            }
            totalValue = newValue;
        }
    }


    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'STE');
    }

}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

interface ITreasury {
    function unstakeMint( uint _amount ) external;
    
    function SPVDeposit( address _token, uint _amount ) external;

    function SPVWithdraw( address _token, uint _amount ) external;

    function DAO() external view returns ( address );

    function spvDebt() external view returns ( uint );
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

import "./IUniswapV2ERC20.sol";

interface IUniswapV2Pair is IUniswapV2ERC20 {
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function token0() external view returns ( address );
    function token1() external view returns ( address );
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

interface IUniswapV2ERC20 {
    function totalSupply() external view returns (uint);
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "./interfaces/IERC20Extended.sol";
import "./interfaces/IUniswapV2ERC20.sol";
import "./interfaces/IUniswapV2Pair.sol";


contract LPCalculator {

    using SafeMath for uint;
    address public immutable KEEPER;
    uint public constant keeperDecimals = 9;


    constructor ( address _KEEPER ) {
        require( _KEEPER != address(0) );
        KEEPER = _KEEPER;
    }


    function getReserve( address _pair ) public view returns ( address reserveToken, uint reserve ) {
        ( uint reserve0, uint reserve1, ) = IUniswapV2Pair( _pair ).getReserves();
        if ( IUniswapV2Pair( _pair ).token0() == KEEPER ) {
            reserve = reserve1;
            reserveToken = IUniswapV2Pair( _pair ).token1();
        } else {
            reserve = reserve0;
            reserveToken = IUniswapV2Pair( _pair ).token0();
        }
    }

    function valuationUSD( address _pair, uint _amount ) external view returns ( uint ) {
        uint totalSupply = IUniswapV2Pair( _pair ).totalSupply();
        ( address reserveToken, uint reserve ) = getReserve( _pair );
        return _amount.mul( reserve ).mul(2).mul( 10 ** keeperDecimals ).div( totalSupply ).div( 10 ** IERC20Extended( reserveToken ).decimals() );
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "./interfaces/ITreasury.sol";


contract Staking is Ownable {
    using SafeMath for uint;
    using SafeERC20 for IERC20;

    event Stake( address indexed recipient, uint indexed amount, uint indexed timestamp );
    event Unstake( address indexed recipient, uint indexed amount, uint indexed timestamp );

    uint public constant keeperDecimals = 9;
    IERC20 public immutable KEEPER;
    address public immutable treasury;
    uint public rate;   // 6 decimals. 10000 = 0.01 = 1%
    uint public INDEX;  // keeperDecimals decimals
    uint public keeperRewards;

    struct Rebase {
        uint rebaseRate; // 6 decimals
        uint totalStaked;
        uint index;
        uint timeOccured;
    }

    struct Epoch {
        uint number;
        uint rebaseInterval;
        uint nextRebase;
    }
    Epoch public epoch;

    Rebase[] public rebases; // past rebase data    

    mapping(address => uint) public stakers;


    constructor( address _KEEPER, address _treasury, uint _rate, uint _INDEX, uint _rebaseInterval ) {
        require( _KEEPER != address(0) );
        KEEPER = IERC20(_KEEPER);
        require( _treasury != address(0) );
        treasury = _treasury;
        require( _rate != 0 );
        rate = _rate;
        require( _INDEX != 0 );
        INDEX = _INDEX;
        require( _rebaseInterval != 0 );

        epoch = Epoch({
            number: 1,
            rebaseInterval: _rebaseInterval,
            nextRebase: block.timestamp.add(_rebaseInterval)
        });
    }


    function setRate( uint _rate ) external onlyOwner() {
        require( _rate >= rate.div(2) && _rate <= rate.mul(3).div(2), "Rate change cannot be too sharp." );
        rate = _rate;
    }


    function stake( uint _amount, address _recipient, bool _wrap ) external {
        KEEPER.safeTransferFrom( msg.sender, address(this), _amount );
        uint _gonsAmount = getGonsAmount( _amount );
        stakers[ _recipient ] = stakers[ _recipient ].add( _gonsAmount );
        emit Stake( _recipient, _amount, block.timestamp );
        rebase();
    }


    function unstake( uint _amount ) external {
        rebase();
        require( _amount <= stakerAmount(msg.sender), "Cannot unstake more than possible." );
        if ( _amount > KEEPER.balanceOf( address(this) ) ) {
            ITreasury(treasury).unstakeMint( _amount.sub(KEEPER.balanceOf( address(this) ) ) );
        }
        uint gonsAmount = getGonsAmount( _amount );
        // Handle math precision error
        if ( gonsAmount > stakers[msg.sender] ) {
            gonsAmount = stakers[msg.sender];
        }
        stakers[msg.sender] = stakers[ msg.sender ].sub(gonsAmount);
        KEEPER.safeTransfer( msg.sender, _amount );
        emit Unstake( msg.sender, _amount, block.timestamp );
    }


    function rebase() public {
        if (epoch.nextRebase <= block.timestamp) {
            uint rebasingRate = rebaseRate();
            INDEX = INDEX.add( INDEX.mul( rebasingRate ).div(1e6) );
            epoch.nextRebase = epoch.nextRebase.add(epoch.rebaseInterval);
            epoch.number++;
            keeperRewards = 0;
            rebases.push( Rebase({
                rebaseRate: rebasingRate,
                totalStaked: KEEPER.balanceOf( address(this) ),
                index: INDEX,
                timeOccured: block.timestamp
            }) );
        }
    }


    function stakerAmount( address _recipient ) public view returns (uint) {
        return getKeeperAmount(stakers[ _recipient ]);
    }


    function rebaseRate() public view returns (uint) {
        uint keeperBalance = KEEPER.balanceOf( address(this) );
        if (keeperBalance == 0) {
            return rate;
        } else {
            return rate.add( keeperRewards.mul(1e6).div( KEEPER.balanceOf( address(this) ) ) );
        }
    }


    function addRebaseReward( uint _amount ) external {
        KEEPER.safeTransferFrom( msg.sender, address(this), _amount );
        keeperRewards = keeperRewards.add( _amount );
    }


    function getGonsAmount( uint _amount ) internal view returns (uint) {
        return _amount.mul(10 ** keeperDecimals).div(INDEX);
    }


    function getKeeperAmount( uint _gons ) internal view returns (uint) {
        return _gons.mul(INDEX).div(10 ** keeperDecimals);
    }

}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

import "@openzeppelin/contracts/access/Ownable.sol";

contract VaultOwned is Ownable {

  address internal _vault;

  function setVault(address vault_) external onlyOwner() returns (bool) {
    _vault = vault_;
    return true;
  }

  function vault() public view returns (address) {
    return _vault;
  }

  modifier onlyVault() {
    require(_vault == msg.sender, "VaultOwned: caller is not the Vault");
    _;
  }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./types/VaultOwned.sol";

contract MockKeplerERC20 is ERC20, VaultOwned {
    using SafeMath for uint256;
    
    constructor() ERC20("Keeper", "KEEPER") {
        _setupDecimals(9);
    }

    function mint(address account_, uint256 amount_) external {
        _mint(account_, amount_);
    }

    function burn(uint256 amount) public virtual {
        _burn(msg.sender, amount);
    }

    function burnFrom(address account_, uint256 amount_) public virtual {
        _burnFrom(account_, amount_);
    }

    function _burnFrom(address account_, uint256 amount_) public virtual {
        uint256 decreasedAllowance_ =
            allowance(account_, msg.sender).sub(
                amount_,
                "ERC20: burn amount exceeds allowance"
            );

        _approve(account_, msg.sender, decreasedAllowance_);
        _burn(account_, amount_);
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./types/VaultOwned.sol";

contract KeplerERC20 is ERC20, VaultOwned {
    using SafeMath for uint256;
    
    constructor() ERC20("Keeper", "KEEPER") {
        _setupDecimals(9);
    }

    function mint(address account_, uint256 amount_) external onlyVault() {
        _mint(account_, amount_);
    }

    function burn(uint256 amount) public virtual {
        _burn(msg.sender, amount);
    }

    function burnFrom(address account_, uint256 amount_) public virtual {
        _burnFrom(account_, amount_);
    }

    function _burnFrom(address account_, uint256 amount_) public virtual {
        uint256 decreasedAllowance_ =
            allowance(account_, msg.sender).sub(
                amount_,
                "ERC20: burn amount exceeds allowance"
            );

        _approve(account_, msg.sender, decreasedAllowance_);
        _burn(account_, amount_);
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";


contract KeeperVesting is Ownable {
    using SafeMath for uint;
    using SafeERC20 for IERC20;

    IERC20 public immutable KEEPER;
    event KeeperRedeemed(address redeemer, uint amount);

    struct Term {
        uint percent; // 6 decimals % ( 5000 = 0.5% = 0.005 )
        uint claimed;
    }
    mapping(address => Term) public terms;
    mapping(address => address) public walletChange;
    // uint public totalRedeemable;
    // uint public redeemableLastUpdated;
    uint public totalRedeemed;

    // address public redeemUpdater;


    constructor( address _KEEPER ) {
        require( _KEEPER != address(0) );
        KEEPER = IERC20(_KEEPER);
        // redeemUpdater = _redeemUpdater;
        // redeemableLastUpdated = block.timestamp;
    }


    // function setRedeemUpdater(address _redeemUpdater) external onlyOwner() {
    //     require( _redeemUpdater != address(0) );
    //     redeemUpdater = _redeemUpdater;
    // }

    // Sets terms for a new wallet
    function setTerms(address _vester, uint _percent ) external onlyOwner() returns ( bool ) {
        terms[_vester].percent = _percent;
        return true;
    }

    // Sets terms for multiple wallets
    function setTermsMultiple(address[] calldata _vesters, uint[] calldata _percents ) external onlyOwner() returns ( bool ) {
        for (uint i=0; i < _vesters.length; i++) {
            terms[_vesters[i]].percent = _percents[i];
        }
        return true;
    }


    // function updateTotalRedeemable() external {
    //     require( msg.sender == redeemUpdater, "Only redeem updater can call." );
    //     uint keeperBalance = KEEPER.balanceOf( address(this) );

    //     uint newRedeemable = keeperBalance.add(totalRedeemed).mul(block.timestamp.sub(redeemableLastUpdated)).div(31536000);
    //     totalRedeemable = totalRedeemable.add(newRedeemable);
    //     if (totalRedeemable > keeperBalance ) {
    //         totalRedeemable = keeperBalance;
    //     }
    //     redeemableLastUpdated = block.timestamp;
    // }

    // Allows wallet to redeem KEEPER
    function redeem( uint _amount ) external returns ( bool ) {
        Term memory info = terms[ msg.sender ];
        require( redeemable( info ) >= _amount, 'Not enough vested' );
        KEEPER.safeTransfer(msg.sender, _amount);
        terms[ msg.sender ].claimed = info.claimed.add( _amount );
        totalRedeemed = totalRedeemed.add(_amount);
        emit KeeperRedeemed(msg.sender, _amount);
        return true;
    }

    // Allows wallet owner to transfer rights to a new address
    function pushWalletChange( address _newWallet ) external returns ( bool ) {
        require( terms[ msg.sender ].percent != 0 );
        walletChange[ msg.sender ] = _newWallet;
        return true;
    }

    // Allows wallet to pull rights from an old address
    function pullWalletChange( address _oldWallet ) external returns ( bool ) {
        require( walletChange[ _oldWallet ] == msg.sender, "wallet did not push" );
        walletChange[ _oldWallet ] = address(0);
        terms[ msg.sender ] = terms[ _oldWallet ];
        delete terms[ _oldWallet ];
        return true;
    }

    // Amount a wallet can redeem
    function redeemableFor( address _vester ) public view returns (uint) {
        return redeemable( terms[ _vester ]);
    }

    function redeemable( Term memory _info ) internal view returns ( uint ) {
        uint maxRedeemable = KEEPER.balanceOf( address(this) ).add( totalRedeemed );
        if ( maxRedeemable > 1e17 ) {
            maxRedeemable = 1e17;
        }
        uint maxRedeemableUser = maxRedeemable.mul( _info.percent ).div(1e6);
        return maxRedeemableUser.sub(_info.claimed);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "@openzeppelin/contracts/access/Ownable.sol";


interface KeeperCompatibleInterface {
  function checkUpkeep(bytes calldata checkData) external returns (bool upkeepNeeded, bytes memory performData);

  function performUpkeep(bytes calldata performData) external;
}


interface IStaking {
    function rebase() external;
}

interface ITreasury {
    function auditTotalReserves() external;
}

interface ISPV {
    function auditTotalValue() external;
}


contract DailyUpkeep is KeeperCompatibleInterface, Ownable {
    /**
    * Use an interval in seconds and a timestamp to slow execution of Upkeep
    */
    uint public immutable interval;
    uint public nextTimeStamp;

    address public staking;
    address public treasury;
    address public spv;


    constructor(address _staking, address _treasury, address _spv, uint _nextTimeStamp, uint _interval) {
      staking = _staking;
      treasury = _treasury;
      spv = _spv;
      nextTimeStamp = _nextTimeStamp;
      interval = _interval;
    }


    function setStaking(address _staking) external onlyOwner() {
        staking = _staking;
    }


    function setTreasury(address _treasury) external onlyOwner() {
        treasury = _treasury;
    }


    function setSPV(address _spv) external onlyOwner() {
        spv = _spv;
    }


    function checkUpkeep(bytes calldata /* checkData */) external override returns (bool upkeepNeeded, bytes memory /* performData */) {
        upkeepNeeded = block.timestamp > nextTimeStamp;
    }


    function performUpkeep(bytes calldata /* performData */) external override {
        if (staking != address(0)) {
            IStaking(staking).rebase();
        }
        if (treasury != address(0)) {
            ITreasury(treasury).auditTotalReserves();
        }
        if (spv != address(0)) {
            ISPV(spv).auditTotalValue();
        }
        nextTimeStamp = nextTimeStamp + interval;
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

import "@openzeppelin/contracts/access/Ownable.sol";

contract VaultOwned is Ownable {

  address internal _vault;

  function setVault(address vault_) external onlyOwner() returns (bool) {
    _vault = vault_;
    return true;
  }

  function vault() public view returns (address) {
    return _vault;
  }

  modifier onlyVault() {
    require(_vault == msg.sender, "VaultOwned: caller is not the Vault");
    _;
  }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./types/VaultOwned.sol";

contract oldMockKeplerERC20 is ERC20, VaultOwned {
    using SafeMath for uint256;
    
    constructor() ERC20("Keeper", "KEEPER") {
        _setupDecimals(9);
    }

    function mint(address account_, uint256 amount_) external {
        _mint(account_, amount_);
    }

    function burn(uint256 amount) public virtual {
        _burn(msg.sender, amount);
    }

    function burnFrom(address account_, uint256 amount_) public virtual {
        _burnFrom(account_, amount_);
    }

    function _burnFrom(address account_, uint256 amount_) public virtual {
        uint256 decreasedAllowance_ =
            allowance(account_, msg.sender).sub(
                amount_,
                "ERC20: burn amount exceeds allowance"
            );

        _approve(account_, msg.sender, decreasedAllowance_);
        _burn(account_, amount_);
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./types/VaultOwned.sol";

contract oldKeplerERC20 is ERC20, VaultOwned {
    using SafeMath for uint256;
    
    constructor() ERC20("Keeper", "KEEPER") {
        _setupDecimals(9);
    }

    function mint(address account_, uint256 amount_) external onlyVault() {
        _mint(account_, amount_);
    }

    function burn(uint256 amount) public virtual {
        _burn(msg.sender, amount);
    }

    function burnFrom(address account_, uint256 amount_) public virtual {
        _burnFrom(account_, amount_);
    }

    function _burnFrom(address account_, uint256 amount_) public virtual {
        uint256 decreasedAllowance_ =
            allowance(account_, msg.sender).sub(
                amount_,
                "ERC20: burn amount exceeds allowance"
            );

        _approve(account_, msg.sender, decreasedAllowance_);
        _burn(account_, amount_);
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";


contract iKeeperIndexCalculator is Ownable {

    using SafeMath for uint;

    event AssetIndexAdded( uint indexed deposit, uint indexed price, address indexed token );
    event IndexUpdated( uint indexed fromIndex, uint indexed toIndex, uint oldPrice, uint newPrice );
    event DepositUpdated( uint indexed fromDeposit, uint indexed toDeposit );
    event AssetIndexWithdrawn( uint indexed deposit, uint price, uint indexed index, address indexed token );

    struct AssetIndex {
        uint deposit;   // In USD
        uint price;     // 6 decimals, in USD
        uint index;     // 9 decimals, starts with 1000000000
        address token;   // Token address of the asset
    }
    AssetIndex[] public indices;
    uint public netIndex;


    constructor(uint _netIndex) {
        require( _netIndex != 0, "Index cannot be 0" );
        netIndex = _netIndex;
    }


    function calculateIndex() public {
        uint indexProduct = 0;
        uint totalDeposit = 0;
        for (uint i=0; i < indices.length; i++) {
            uint deposit = indices[i].deposit;
            totalDeposit = totalDeposit.add(deposit);
            indexProduct = indexProduct.add( indices[i].index.mul( deposit ) );
        }
        netIndex = indexProduct.div(totalDeposit);
    }


    function addAssetIndex(uint _deposit, uint _price, address _token) external onlyOwner() {
        indices.push( AssetIndex({
            deposit: _deposit,
            price: _price,
            index: 1e9,
            token: _token
        }));
    }


    function updateIndex(uint _index, address _token, uint _newPrice) external onlyOwner() {
        AssetIndex storage assetIndex = indices[ _index ];
        require(assetIndex.token == _token, "Wrong index.");
        uint changeIndex = _newPrice.mul(1e9).div(assetIndex.price);
        uint fromIndex = assetIndex.index;
        uint oldPrice = assetIndex.price;
        assetIndex.index = fromIndex.mul(changeIndex).div(1e9);
        assetIndex.deposit = assetIndex.deposit.mul(changeIndex).div(1e9);
        assetIndex.price = _newPrice;
        emit IndexUpdated(fromIndex, assetIndex.index, oldPrice, _newPrice);
    }


    function updateDeposit(uint _index, address _token, uint _amount, bool _add) external onlyOwner() {
        require(_token == indices[ _index ].token, "Wrong index.");
        uint oldDeposit = indices[ _index ].deposit;
        require(_add || oldDeposit >= _amount, "Cannot withdraw more than deposit");
        if (!_add) {
            indices[ _index ].deposit = oldDeposit.sub(_amount);
        } else {
            indices[ _index ].deposit = oldDeposit.add(_amount);
        }
        emit DepositUpdated(oldDeposit, indices[ _index ].deposit);
    }


    function withdrawAsset(uint _index, address _token) external onlyOwner() {
        AssetIndex memory assetIndex = indices[ _index ];
        require(_token == assetIndex.token, "Wrong index.");
        indices[ _index ] = indices[indices.length-1];
        indices.pop();
        emit AssetIndexWithdrawn(assetIndex.deposit, assetIndex.price, assetIndex.index, assetIndex.token);
    }

}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "./interfaces/IsKEEPER.sol";
import "./interfaces/IStaking.sol";
// import "./interfaces/IIndexCalculator.sol";


contract iKEEPER is ERC20, Ownable {

    using SafeMath for uint;
    address public immutable TROVE;
    address public immutable staking;
    address public indexCalculator;


    constructor(address _TROVE, address _staking, address _indexCalculator) ERC20("Invest KEEPER", "iKEEPER") {
        require(_TROVE != address(0));
        TROVE = _TROVE;
        require(_staking != address(0));
        staking = _staking;
        require(_indexCalculator != address(0));
        indexCalculator = _indexCalculator;
    }

    // function setIndexCalculator( address _indexCalculator ) external onlyOwner() {
    //     require( _indexCalculator != address(0) );
    //     indexCalculator = _indexCalculator;
    // }

    // /**
    //     @notice get iKEEPER index (9 decimals)
    //     @return uint
    //  */
    // // function getIndex() public view returns (uint) {
    // //     return IIndexCalculator(indexCalculator).netIndex();
    // // }

    // // /**
    // //     @notice wrap KEEPER
    // //     @param _amount uint
    // //     @return uint
    // //  */
    // // function wrapKEEPER( uint _amount ) external returns ( uint ) {
    // //     IERC20( KEEPER ).transferFrom( msg.sender, address(this), _amount );

    // //     uint value = TROVEToiKEEPER( _amount );
    // //     _mint( msg.sender, value );
    // //     return value;
    // // }

    // /**
    //     @notice wrap TROVE
    //     @param _amount uint
    //     @return uint
    //  */
    // function wrap( uint _amount, address _recipient ) external returns ( uint ) {
    //     IsKEEPER( TROVE ).transferFrom( msg.sender, address(this), _amount );

    //     uint value = TROVEToiKEEPER( _amount );
    //     _mint( _recipient, value );
    //     return value;
    // }


    // // /**
    // //     @notice unwrap KEEPER
    // //     @param _amount uint
    // //     @return uint
    // //  */
    // // function unwrapKEEPER( uint _amount ) external returns ( uint ) {
    // //     _burn( msg.sender, _amount );

    // //     uint value = iKEEPERToTROVE( _amount );
    // //     uint keeperBalance = IERC20(KEEPER).balanceOf( address(this) );
    // //     if (keeperBalance < value ) {
    // //         uint difference = value.sub(keeperBalance);
    // //         require(IsKEEPER(TROVE).balanceOf(address(this)) >= difference, "Contract does not have enough TROVE");
    // //         IsKEEPER(TROVE).approve(staking, difference);
    // //         IStaking(staking).unstake(difference, false);
    // //     }
    // //     IERC20( KEEPER ).transfer( msg.sender, value );
    // //     return value;
    // // }


    // /**
    //     @notice unwrap TROVE
    //     @param _amount uint
    //     @return uint
    //  */
    // function unwrap( uint _amount ) external returns ( uint ) {
    //     _burn( msg.sender, _amount );

    //     uint value = iKEEPERToTROVE( _amount );
    //     IsKEEPER( TROVE ).transfer( msg.sender, value );
    //     return value;
    // }

    // /**
    //     @notice converts iKEEPER amount to TROVE
    //     @param _amount uint
    //     @return uint
    //  */
    // function iKEEPERToTROVE( uint _amount ) public view returns ( uint ) {
    //     return _amount.mul( getIndex() ).div( 10 ** decimals() );
    // }

    // /**
    //     @notice converts TROVE amount to iKEEPER
    //     @param _amount uint
    //     @return uint
    //  */
    // function TROVEToiKEEPER( uint _amount ) public view returns ( uint ) {
    //     return _amount.mul( 10 ** decimals() ).div( getIndex() );
    // }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "./interfaces/IBondCalculator.sol";
import "./interfaces/IERC20Extended.sol";
import "./interfaces/IsKEEPER.sol";
import "./interfaces/IwTROVE.sol";
import "./interfaces/IStaking.sol";
import "./interfaces/ITreasury.sol";
import "./libraries/FixedPoint.sol";
import "./libraries/SafeMathExtended.sol";


contract BondStakeDepository is Ownable {

    using FixedPoint for *;
    using SafeERC20 for IERC20;
    using SafeMathExtended for uint;
    using SafeMathExtended for uint32;

    event BondCreated( uint deposit, uint indexed payout, uint indexed expires, uint indexed priceInUSD );
    event BondRedeemed( address indexed recipient, uint payout, uint remaining );
    event BondPriceChanged( uint indexed priceInUSD, uint indexed internalPrice, uint indexed debtRatio );
    event ControlVariableAdjustment( uint initialBCV, uint newBCV, uint adjustment, bool addition );

    /* ======== STATE VARIABLES ======== */

    address public immutable KEEPER; // intermediate token
    address public immutable sKEEPER; // token given as payment for bond
    address public immutable wTROVE; // Wrap sKEEPER
    address public immutable principle; // token used to create bond
    address public immutable treasury; // mints KEEPER when receives principle
    address public immutable DAO; // receives profit share from bond

    address public immutable bondCalculator; // calculates value of LP tokens
    bool public immutable isLiquidityBond; // LP and Reserve bonds are treated slightly different

    address public staking; // to auto-stake payout
    Terms public terms; // stores terms for new bonds
    Adjust public adjustment; // stores adjustment to BCV data

    mapping( address => Bond ) public bondInfo; // stores bond information for depositors

    uint public totalDebt; // total value of outstanding bonds; used for pricing
    uint32 public lastDecay; // reference time for debt decay

    /* ======== STRUCTS ======== */

    // Info for creating new bonds
    struct Terms {
        uint controlVariable; // scaling variable for price
        uint minimumPrice; // vs principle value
        uint maxPayout; // in thousandths of a %. i.e. 500 = 0.5%
        uint fee; // as % of bond payout, in hundreths. ( 500 = 5% = 0.05 for every 1 paid)
        uint maxDebt; // 9 decimal debt ratio, max % total supply created as debt
        uint32 vestingTerm; // in seconds
    }

    // Info for bond holder
    struct Bond {
        uint gonsPayout; // sKEEPER remaining to be paid
        uint pricePaid; // In DAI, for front end viewing
        uint32 vesting; // seconds left to vest
        uint32 lastTime; // Last interaction
    }

    // Info for incremental adjustments to control variable 
    struct Adjust {
        bool add; // addition or subtraction
        uint rate; // increment
        uint target; // BCV when adjustment finished
        uint32 buffer; // minimum length (in seconds) between adjustments
        uint32 lastTime; // timestamp when last adjustment made
    }

    constructor ( address _KEEPER, address _sKEEPER, address _wTROVE, address _principle, address _staking, address _treasury, address _DAO, address _bondCalculator) {
        require( _KEEPER != address(0) );
        KEEPER = _KEEPER;
        require( _sKEEPER != address(0) );
        sKEEPER = _sKEEPER;
        require( _wTROVE != address(0) );
        wTROVE = _wTROVE;
        require( _principle != address(0) );
        principle = _principle;
        require( _treasury != address(0) );
        treasury = _treasury;
        require( _DAO != address(0) );
        DAO = _DAO;
        require( _staking != address(0) );
        staking = _staking;
        // bondCalculator should be address(0) if not LP bond
        bondCalculator = _bondCalculator;
        isLiquidityBond = ( _bondCalculator != address(0) );
    }

    /**
     *  @notice initializes bond parameters
     *  @param _controlVariable uint
     *  @param _vestingTerm uint
     *  @param _minimumPrice uint
     *  @param _maxPayout uint
     *  @param _fee uint
     *  @param _maxDebt uint
     *  @param _initialDebt uint
     */
    function initializeBondTerms(uint _controlVariable, uint32 _vestingTerm, uint _minimumPrice, uint _maxPayout,
                                 uint _fee, uint _maxDebt, uint _initialDebt)
    external onlyOwner() {
        require( terms.controlVariable == 0 && terms.vestingTerm == 0, "Bonds must be initialized from 0" );
        terms = Terms ({
            controlVariable: _controlVariable,
            vestingTerm: _vestingTerm,
            minimumPrice: _minimumPrice,
            maxPayout: _maxPayout,
            fee: _fee,
            maxDebt: _maxDebt
        });
        totalDebt = _initialDebt;
        lastDecay = uint32(block.timestamp);
    }

    /* ======== POLICY FUNCTIONS ======== */

    enum PARAMETER { VESTING, PAYOUT, FEE, DEBT, MINPRICE }
    /**
     *  @notice set parameters for new bonds
     *  @param _parameter PARAMETER
     *  @param _input uint
     */
    function setBondTerms ( PARAMETER _parameter, uint _input ) external onlyOwner() {
        if ( _parameter == PARAMETER.VESTING ) { // 0
            require( _input >= 129600, "Vesting must be longer than 36 hours" );
            require( currentDebt() == 0, "Debt should be 0." );
            terms.vestingTerm = uint32(_input);
        } else if ( _parameter == PARAMETER.PAYOUT ) { // 1
            require( _input <= 1000, "Payout cannot be above 1 percent" );
            terms.maxPayout = _input;
        } else if ( _parameter == PARAMETER.FEE ) { // 2
            require( _input <= 10000, "DAO fee cannot exceed payout" );
            terms.fee = _input;
        } else if ( _parameter == PARAMETER.DEBT ) { // 3
            terms.maxDebt = _input;
        } else if ( _parameter == PARAMETER.MINPRICE ) { // 4
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
    function setAdjustment ( bool _addition, uint _increment, uint _target, uint32 _buffer) external onlyOwner() {
        require( _increment <= terms.controlVariable.mul( 25 ).div( 1000 ), "Increment too large" );

        adjustment = Adjust({
            add: _addition,
            rate: _increment,
            target: _target,
            buffer: _buffer,
            lastTime: uint32(block.timestamp)
        });
    }

    /**
     *  @notice set contract for auto stake
     *  @param _staking address
     */
    // function setStaking( address _staking ) external onlyOwner() {
    //     require( _staking != address(0) );
    //     staking = _staking;
    // }


    /* ======== USER FUNCTIONS ======== */

    /**
     *  @notice deposit bond
     *  @param _amount uint
     *  @param _maxPrice uint
     *  @param _depositor address
     *  @return uint
     */
    function deposit( uint _amount, uint _maxPrice, address _depositor) external returns ( uint ) {
        require( _depositor != address(0), "Invalid address" );
        decayDebt();
        
        uint priceInUSD = bondPriceInUSD(); // Stored in bond info
        uint nativePrice = _bondPrice();

        require( _maxPrice >= nativePrice, "Slippage limit: more than max price" ); // slippage protection

        uint value = ITreasury( treasury ).valueOfToken( principle, _amount );
        uint payout = payoutFor( value ); // payout to bonder is computed

        require( payout >= 10000000, "Bond too small" ); // must be > 0.01 KEEPER ( underflow protection )
        require( payout <= maxPayout(), "Bond too large"); // size protection because there is no slippage

        // profits are calculated
        uint fee = payout.mul( terms.fee ).div( 10000 );
        uint profit = value.sub( payout ).sub( fee );

        /**
            principle is transferred in
            approved and
            deposited into the treasury, returning (_amount - profit) KEEPER
         */
        IERC20( principle ).safeTransferFrom( msg.sender, address(this), _amount );
        IERC20( principle ).approve( address( treasury ), _amount );
        ITreasury( treasury ).deposit( _amount, principle, profit );
        
        if ( fee != 0 ) { // fee is transferred to dao 
            IERC20( KEEPER ).safeTransfer( DAO, fee ); 
        }
        
        // total debt is increased
        totalDebt = totalDebt.add( value ); 
        require( totalDebt <= terms.maxDebt, "Max capacity reached" );

        IERC20( KEEPER ).approve( staking, payout );
        IStaking( staking ).stake( payout, address(this), false );
        IStaking( staking ).claim( address(this) );
        uint stakeGons = IsKEEPER(sKEEPER).gonsForBalance(payout);

        // depositor info is stored
        bondInfo[ _depositor ] = Bond({ 
            gonsPayout: bondInfo[ _depositor ].gonsPayout.add( stakeGons ),
            vesting: terms.vestingTerm,
            lastTime: uint32(block.timestamp),
            pricePaid: priceInUSD
        });

        // indexed events are emitted
        emit BondCreated( _amount, payout, block.timestamp.add( terms.vestingTerm ), priceInUSD );
        emit BondPriceChanged( bondPriceInUSD(), _bondPrice(), debtRatio() );

        adjust(); // control variable is adjusted
        return payout; 
    }

    /** 
     *  @notice redeem bond for user
     *  @param _recipient address
     *  @param _wrap bool
     *  @return uint
     */ 
    function redeem( address _recipient, bool _stake, bool _wrap ) external returns ( uint ) {        
        Bond memory info = bondInfo[ _recipient ];
        uint percentVested = percentVestedFor( _recipient ); // (blocks since last interaction / vesting term remaining)

        if ( percentVested >= 10000 ) { // if fully vested
            delete bondInfo[ _recipient ]; // delete user info
            uint _amount = IsKEEPER(sKEEPER).balanceForGons(info.gonsPayout);
            emit BondRedeemed( _recipient, _amount, 0 ); // emit bond data
            return sendOrWrap( _recipient, _wrap, _amount ); // pay user everything due

        } else { // if unfinished
            // calculate payout vested
            uint gonsPayout = info.gonsPayout.mul( percentVested ).div( 10000 );
            // store updated deposit info
            bondInfo[ _recipient ] = Bond({
                gonsPayout: info.gonsPayout.sub( gonsPayout ),
                vesting: info.vesting.sub32( uint32(block.timestamp).sub32( info.lastTime ) ),
                lastTime: uint32(block.timestamp),
                pricePaid: info.pricePaid
            });

            uint _amount = IsKEEPER(sKEEPER).balanceForGons(gonsPayout);
            uint _remainingAmount = IsKEEPER(sKEEPER).balanceForGons(bondInfo[_recipient].gonsPayout);
            emit BondRedeemed( _recipient, _amount, _remainingAmount );
            return sendOrWrap( _recipient, _wrap, _amount );
        }
    }



    
    /* ======== INTERNAL HELPER FUNCTIONS ======== */

    /**
     *  @notice allow user to wrap payout automatically
     *  @param _wrap bool
     *  @param _amount uint
     *  @return uint
     */
    function sendOrWrap( address _recipient, bool _wrap, uint _amount ) internal returns ( uint ) {
        if ( _wrap ) { // if user wants to wrap
            IERC20(sKEEPER).approve( wTROVE, _amount );
            uint wrapValue = IwTROVE(wTROVE).wrap( _amount );
            IwTROVE(wTROVE).transfer( _recipient, wrapValue );
        } else { // if user wants to stake
            IERC20( sKEEPER ).transfer( _recipient, _amount ); // send payout
        }
        return _amount;
    }

    /**
     *  @notice makes incremental adjustment to control variable
     */
    function adjust() internal {
        uint timeCanAdjust = adjustment.lastTime.add( adjustment.buffer );
        if( adjustment.rate != 0 && block.timestamp >= timeCanAdjust ) {
            uint initial = terms.controlVariable;
            if ( adjustment.add ) {
                terms.controlVariable = terms.controlVariable.add( adjustment.rate );
                if ( terms.controlVariable >= adjustment.target ) {
                    adjustment.rate = 0;
                }
            } else {
                terms.controlVariable = terms.controlVariable.sub( adjustment.rate );
                if ( terms.controlVariable <= adjustment.target || terms.controlVariable < adjustment.rate ) {
                    adjustment.rate = 0;
                }
            }
            adjustment.lastTime = uint32(block.timestamp);
            emit ControlVariableAdjustment( initial, terms.controlVariable, adjustment.rate, adjustment.add );
        }
    }

    /**
     *  @notice reduce total debt
     */
    function decayDebt() internal {
        totalDebt = totalDebt.sub( debtDecay() );
        lastDecay = uint32(block.timestamp);
    }



    /* ======== VIEW FUNCTIONS ======== */

    /**
     *  @notice determine maximum bond size
     *  @return uint
     */
    function maxPayout() public view returns ( uint ) {
        return IERC20( KEEPER ).totalSupply().mul( terms.maxPayout ).div( 100000 );
    }

    /**
     *  @notice calculate interest due for new bond
     *  @param _value uint
     *  @return uint
     */
    function payoutFor( uint _value ) public view returns ( uint ) {
        return FixedPoint.fraction( _value, bondPrice() ).decode112with18().div( 1e16 );
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
    }

    /**
     *  @notice converts bond price to DAI value
     *  @return price_ uint
     */
    function bondPriceInUSD() public view returns ( uint price_ ) {
        if( isLiquidityBond ) {
            price_ = bondPrice().mul( IBondCalculator( bondCalculator ).markdown( principle ) ).div( 100 );
        } else {
            price_ = bondPrice().mul( 10 ** IERC20Extended( principle ).decimals() ).div( 100 );
        }
    }


    function getBondInfo(address _depositor) public view returns ( uint payout, uint vesting, uint lastTime, uint pricePaid ) {
        Bond memory info = bondInfo[ _depositor ];
        payout = IsKEEPER(sKEEPER).balanceForGons(info.gonsPayout);
        vesting = info.vesting;
        lastTime = info.lastTime;
        pricePaid = info.pricePaid;
    }


    /**
     *  @notice calculate current ratio of debt to KEEPER supply
     *  @return debtRatio_ uint
     */
    function debtRatio() public view returns ( uint debtRatio_ ) {   
        uint supply = IERC20( KEEPER ).totalSupply();
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
        uint32 timeSinceLast = uint32(block.timestamp).sub32( lastDecay );
        decay_ = totalDebt.mul( timeSinceLast ).div( terms.vestingTerm );
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
        Bond memory bond = bondInfo[ _depositor ];
        uint timeSinceLast = uint32(block.timestamp).sub( bond.lastTime );
        uint vesting = bond.vesting;

        if ( vesting > 0 ) {
            percentVested_ = timeSinceLast.mul( 10000 ).div( vesting );
        } else {
            percentVested_ = 0;
        }
    }

    /**
     *  @notice calculate amount of KEEPER available for claim by depositor
     *  @param _depositor address
     *  @return pendingPayout_ uint
     */
    function pendingPayoutFor( address _depositor ) external view returns ( uint pendingPayout_ ) {
        uint percentVested = percentVestedFor( _depositor );
        uint payout = IsKEEPER(sKEEPER).balanceForGons(bondInfo[ _depositor ].gonsPayout);

        if ( percentVested >= 10000 ) {
            pendingPayout_ = payout;
        } else {
            pendingPayout_ = payout.mul( percentVested ).div( 10000 );
        }
    }




    /* ======= AUXILLIARY ======= */

    /**
     *  @notice allow anyone to send lost tokens (excluding principle or KEEPER) to the DAO
     *  @return bool
     */
    function recoverLostToken( address _token ) external returns ( bool ) {
        require( _token != KEEPER );
        require( _token != sKEEPER );
        require( _token != principle );
        IERC20( _token ).safeTransfer( DAO, IERC20( _token ).balanceOf( address(this) ) );
        return true;
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "./interfaces/IERC20Extended.sol";
import "./interfaces/IUniswapV2ERC20.sol";
import "./interfaces/IUniswapV2Pair.sol";
import "./libraries/FixedPoint.sol";

interface IBondingCalculator {
  function valuation( address pair_, uint amount_ ) external view returns ( uint _value );
}

contract StandardBondingCalculator is IBondingCalculator {

    using FixedPoint for *;
    using SafeMath for uint;
    using SafeMath for uint112;

    address public immutable KEEPER;

    constructor( address _KEEPER ) {
        require( _KEEPER != address(0) );
        KEEPER = _KEEPER;
    }

    function sqrrt(uint256 a) internal pure returns (uint c) {
        if (a > 3) {
            c = a;
            uint b = a.div(2).add(1);
            while (b < c) {
                c = b;
                b = a.div(b).add(b).div(2);
            }
        } else if (a != 0) {
            c = 1;
        }
    }

    function getKValue( address _pair ) public view returns( uint k_ ) {
        uint token0 = IERC20Extended( IUniswapV2Pair( _pair ).token0() ).decimals();
        uint token1 = IERC20Extended( IUniswapV2Pair( _pair ).token1() ).decimals();
        
        (uint reserve0, uint reserve1, ) = IUniswapV2Pair( _pair ).getReserves();
        
        uint totalDecimals = token0.add( token1 );
        uint pairDecimal = IERC20Extended( _pair ).decimals();
        
        if (totalDecimals < pairDecimal) {
            uint decimals = pairDecimal.sub(totalDecimals);
            k_ = reserve0.mul(reserve1).mul(10 ** decimals);
        }
        else {
            uint decimals = totalDecimals.sub(pairDecimal);
            k_ = reserve0.mul(reserve1).div(10 ** decimals);
        }
    }

    function getTotalValue( address _pair ) public view returns ( uint _value ) {
        _value = sqrrt(getKValue( _pair )).mul(2);
    }

    function valuation( address _pair, uint amount_ ) external view override returns ( uint _value ) {
        uint totalValue = getTotalValue( _pair );
        uint totalSupply = IUniswapV2Pair( _pair ).totalSupply();

        _value = totalValue.mul( FixedPoint.fraction( amount_, totalSupply ).decode112with18() ).div( 1e18 );
    }

    function markdown( address _pair ) external view returns ( uint ) {
        ( uint reserve0, uint reserve1, ) = IUniswapV2Pair( _pair ).getReserves();

        uint reserve;
        if ( IUniswapV2Pair( _pair ).token0() == KEEPER ) {
            reserve = reserve1;
        } else {
            reserve = reserve0;
        }
        return reserve.mul( 2 * ( 10 ** IERC20Extended( KEEPER ).decimals() ) ).div( getTotalValue( _pair ) );
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

interface IUniswapV2ERC20 {
    function totalSupply() external view returns (uint);
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

import "./IUniswapV2ERC20.sol";

interface IUniswapV2Pair is IUniswapV2ERC20 {
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function token0() external view returns ( address );
    function token1() external view returns ( address );
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";


contract aKEEPER is ERC20 {
    
    constructor() ERC20("Alpha Keeper", "aKEEPER") {
        _setupDecimals(9);
        _mint(msg.sender, 220000000000000);
    }

    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }
}