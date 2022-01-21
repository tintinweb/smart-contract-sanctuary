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

    enum MANAGING { RESERVETOKEN, LIQUIDITYTOKEN, VARIABLETOKEN, DEPOSITOR }
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

    address[] public depositors;
    mapping( address => bool ) public isDepositor;

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
        require( isDepositor[ msg.sender ], "Not Approved" );
        IERC20Extended( _token ).safeTransferFrom( msg.sender, address(this), _amount );

        // uint daoAmount = _amount.mul(daoRatio).div(1e4);
        // IERC20Extended( _token ).safeTransfer( DAO, daoAmount );
        
        uint value = valueOfToken(_token, _amount);
        // uint daoValue = value.mul(daoRatio).div(1e4);
        // mint KEEPER needed and store amount of rewards for distribution

        send_ = sendOrStake(msg.sender, value, _stake);

        totalReserves = totalReserves.add( value );
        emit ReservesUpdated( totalReserves );
        emit Deposit( _token, _amount, value );
    }


    function depositEth( uint _amount, bool _stake ) external payable returns ( uint send_ ) {
        require( _amount == msg.value, "Amount should be equal to ETH transferred");
        require( isDepositor[ msg.sender ], "Not Approved" );

        // uint daoAmount = _amount.mul(daoRatio).div(1e4);
        // safeTransferETH(DAO, daoAmount);

        uint value = EthToUSD( _amount );
        // uint daoValue = value.mul(daoRatio).div(1e4);
        // mint KEEPER needed and store amount of rewards for distribution
        send_ = sendOrStake(msg.sender, value, _stake);

        totalReserves = totalReserves.add( value );
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
            if ( !result ) {
                listRemove( reserveTokens, _address );
            }

        } else if ( _managing == MANAGING.LIQUIDITYTOKEN ) { // 1
            if( !listContains( liquidityTokens, _address ) ) {
                liquidityTokens.push( _address );
            }
            result = !isLiquidityToken[ _address ];
            isLiquidityToken[ _address ] = result;
            lpCalculator[ _address ] = _calculatorFeed;
            if ( !result ) {
                listRemove( liquidityTokens, _address );
            }

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
            if ( !result ) {
                listRemove( variableTokens, _address );
            }

        } else if ( _managing == MANAGING.DEPOSITOR ) { // 3
            if( !listContains( depositors, _address ) ) {
                depositors.push( _address );
            }
            result = !isDepositor[ _address ];
            isDepositor[ _address ] = result;
            if ( !result ) {
                listRemove( depositors, _address );
            }
        } 
        else return false;

        auditTotalReserves();
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


    function listRemove( address[] storage _list, address _token ) internal {
        bool removedItem = false;
        for( uint i = 0; i < _list.length; i++ ) {
            if( _list[ i ] == _token ) {
                _list[ i ] = _list[ _list.length-1 ];
                removedItem = true;
                break;
            }
        }
        if ( removedItem ) {
            _list.pop();
        }
    }


    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'STE');
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

    function transfer(address _recipient, uint _gonsAmount) external;

    function getGonsAmount(uint _amount) external view returns (uint);
    
    function getKeeperAmount(uint _gons) external view returns (uint);

    function addRebaseReward( uint _amount ) external;
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