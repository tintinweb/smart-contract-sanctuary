// SPDX-License-Identifier: MIT

pragma solidity 0.8.1;
pragma experimental ABIEncoderV2;

import { ReentrancyGuardUpgradeable } from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import { DataTypes, StableCoinsDataTypes as SCDataTypes } from "../../libraries/sushi/DataTypes.sol";
import { AssetLib , UserDepositInfoLib } from "../../libraries/sushi/AssetLib.sol";
import {SushiSLPBase, IERC20  } from "./SushiSLPBase.sol"; 
import { SafeMath } from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReceiptToken} from "../../tokens/ReceiptToken.sol";

contract SushiStableCoin is SushiSLPBase {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    using AssetLib for DataTypes.Asset;
    using UserDepositInfoLib for DataTypes.UserDepositInfo;
    
    mapping(address => DataTypes.Asset) public assets;
    // user => token
    mapping(address => mapping(address => DataTypes.UserDepositInfo)) public userInfo;
    function initialize (
        address _masterChef,
        address _sushiswapFactory,
        address _sushiswapRouter,
        address _weth,
        address _sushi,
        address payable _treasuryAddress,
        address payable _feeAddress
       ) external initializer {
          
          __SushiSLPBase_init(
            _masterChef,
            _sushiswapFactory,
            _sushiswapRouter,
            _weth,
            _sushi,
            _treasuryAddress,
            _feeAddress);
     }

    /**
     * @notice Deposit to this strategy for rewards
     * @param deadline Number of blocks until transaction expires
     */
    function deposit(address _asset, uint256 _amount,  uint256 slippage, uint256 ethPerToken, uint256 deadline) external nonReentrant {
        require(_asset != address(0), "!address__asset");
        require(assets[_asset].initialized, "!asset_initialized"); 

        _validateDeposit(deadline, _amount, assets[_asset].totalAmount, slippage);

        SCDataTypes.DepositData memory _data;
        // ----
        // swap half token to ETH 
        // ---
        IERC20(_asset).safeTransferFrom(msg.sender, address(this), _amount);
       
        uint256 _halfAmount = _amount.div(2);   
        address[] memory swapPath = new address[](2);
        swapPath[0] = _asset; 
        swapPath[1] =  weth;

        uint256 _obtainedEth = _swapTokenToEth(swapPath, _halfAmount, deadline, slippage, ethPerToken);   

        (
            _data.liquidityTokenAmount,
            _data.liquidityEthAmount,
            _data.liquidity
        ) = _addLiquidity(
            _asset,
            _obtainedEth,
            _halfAmount,
            deadline
        );

        DataTypes.UserDepositInfo storage _depositInfo = userInfo[msg.sender][_asset];

        assets[_asset].increaseAmount(_amount); 

        _depositInfo.increaseAmount(_amount);

        _deposit(_depositInfo, assets[_asset], _data.liquidity);
 
    }

    function withdraw(address  _asset, uint256 amount, uint256 tokensPerEth, uint256 slippage, uint256 deadline) external nonReentrant returns(uint256) {
        require(assets[_asset].initialized, "!asset");
        
        SCDataTypes.WithdrawData memory w;
        
        DataTypes.UserDepositInfo storage _depositInfo = userInfo[msg.sender][_asset];

        _validateWithdraw(
            deadline,
            amount,
            _depositInfo.amount,
            ReceiptToken(assets[_asset].receipt).balanceOf(msg.sender),
            _depositInfo.timestamp
        );


        (uint256 totalSushi, uint256 slpAmount)  =  _withdraw(_depositInfo, assets[_asset], amount);
               
        // remove liquidity & convert everything to deposited asset
        
        w.pair = sushiswapFactory.getPair(_asset, weth);
       
        (
            w.tokenLiquidityAmount,
            w.ethLiquidityAmount
        ) = _removeLiquidity(_asset, w.pair, slpAmount, deadline);

        require(w.tokenLiquidityAmount > 0, "TOKEN_LIQUIDITY_0");
        require(w.ethLiquidityAmount > 0, "ETH_LIQUIDITY_0");

        // -----
        // swap eth obtained from removing liquidity with token
        // -----
        if (w.ethLiquidityAmount > 0) { 
            w.swapPath[0] = weth;
            w.swapPath[1] = _asset; 
            w.obtainedToken = _swapEthToToken(w.swapPath, w.ethLiquidityAmount, deadline, slippage, tokensPerEth);
        }

         w.totalTokenAmount = w.tokenLiquidityAmount.add(w.obtainedToken);

        _depositInfo.decreaseAmount(w.totalTokenAmount);

         assets[_asset].decreaseAmount(w.totalTokenAmount); 

        // -----
        // calculate asset fee
        // -----
        uint256 _feeToken = 0;

        if (fee > 0) {
            //calculate fee
            _feeToken = _calculateFee(w.totalTokenAmount);
            w.totalTokenAmount = w.totalTokenAmount.sub(_feeToken);
            IERC20(_asset).safeTransfer(feeAddress, _feeToken);
            _depositInfo.increasePaidFees(_feeToken); 
        }

        IERC20(_asset).safeTransfer(msg.sender, w.totalTokenAmount);

        return totalSushi;
    }

    function totalAssetInvested(address _asset) external view returns(uint256) {
        return assets[_asset].totalAmount;
    }

    /**
     * @notice Update the pool id
     * @dev Can only be called by the owner
     * @param _pid pool id
     */
    function updatePoolId(address _asset, uint256 _pid) external onlyOwner {
        require(assets[_asset].initialized, "!initialized_asset_call_initAsset");
        emit ChangedValue("POOLID", assets[_asset].poolId, _pid);
        assets[_asset].poolId = _pid;
    }

    /**
     * @notice Update the address of TOKEN
     * @dev Can only be called by the owner
     * @param _asset Address of TOKEN
     */
    function updateTokenAddress(address _asset) external onlyOwner {
        require(_asset != address(0), "0x0");
        require(assets[_asset].initialized, "!initialized_asset_call_initAsset");
        emit ChangedAddress("TOKEN", address(assets[_asset].token), address(_asset));
        assets[_asset].token = _asset;
    }

    /**
     * @notice Update the address of TOKEN
     * @dev Can only be called by the owner
     * @param _slp Address of TOKEN
     */
    function updateSLP(address _asset, address _slp) external onlyOwner {
        require(_slp != address(0), "0x0");
        require(assets[_asset].initialized, "!initialized_asset_call_initAsset");
        emit ChangedAddress("TOKEN", address(assets[_asset].slp), address(_slp));
        assets[_asset].slp = _slp;
    }

    /**
     * @notice Update the address of TOKEN
     * @dev Can only be called by the owner
     * @param _receipt Address of TOKEN
     */
    function updateReceipt(address _asset, address _receipt) external onlyOwner {
        require(_receipt != address(0), "0x0");
        require(assets[_asset].initialized, "!initialized_asset_call_initAsset");
        emit ChangedAddress("TOKEN", address(assets[_asset].receipt), address(_receipt));
        assets[_asset].receipt = _receipt;
    }

    /**
    * @dev initializes an asset. i.e a supported stable coin which may be deposited
    * @param _asset address of the stable coin
    * @param _receipt address of receipt token
    * @param _slp address of slp token <_asset>-ETH
    * @param _poolId the masterchef pool id  
    */
    function initAsset(address _asset, address _receipt, address _slp, uint256 _poolId ) external onlyOwner{
        require(_asset != address(0), "!address__asset");
        require(_receipt != address(0), "!address__receipt");
        require(_slp != address(0), "!address_slp");
        
        assets[_asset].initialize(_asset, _receipt, _slp, _poolId);
    } 
 
    function receipt(address _asset) external view returns(address) {
        return assets[_asset].receipt;
    }

    receive() external payable {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

library DataTypes {
     struct Asset {
        address token; // token address
        address receipt; // receipt token address
        uint256 totalAmount;
        address slp; // slp token address for the token asset and eth pair <token>-eth
        uint256 poolId; 
        bool initialized;
    } 

    struct Balance {
      uint256 initialBalance;
      uint256 newBalance;
    }
    /// @notice Info of each user. 
 
    struct WithdrawData {
        address pair;
        uint256 slpAmount;
        uint256 totalSushi;
        uint256 treasurySushi;
        uint256 userSushi;
        //
        uint256 oldAmount;
        uint256 pendingSushiTokens;
        uint256 sushiBalance;
        uint256 feeSLP;
        uint256 feeSushi;
        uint256 receiptBalance;
    }
 
    struct UserDepositInfo {
        uint totalInvested;
        uint256 amount; // How many SLP tokens the user has provided.
        uint256 sushiRewardDebt; // Reward debt for Sushi rewards. See explanation below.
        uint256 userAccumulatedSushi; //how many rewards this user has
        uint256 timestamp; //first deposit timestamp; used for withdrawal lock time check 
        uint256 treasurySushi; //how much Sushi the user sent to treasury
        uint256 feeSushi; //how much Sushi the user sent to fee address 
        uint256 assetFees; // fees paid for the deposited asset
        uint256 earnedSushi; //how much Sushi the user earned so far
    }

}
 

library SushiSLPBaseDataTypes {
    struct DepositData {
        uint256 liquidity;
        uint256 pendingSushiTokens;
    } 
}

library SushiSLPDataTypes {       

   
}

library StableCoinsDataTypes {    

   
    struct DepositData {
        uint256 toSwapAmount;
        address[] swapPath;
        uint256[] swapAmounts;
        uint256 obtainedToken;
        uint256 liquidityTokenAmount;
        uint256 liquidityEthAmount;
        address pair;
        uint256 liquidity;
        uint256 pendingSushiTokens;
    }

    struct WithdrawData {
        uint256 toSwapAmount;
        address[] swapPath;
        uint256[] swapAmounts;
        uint256 obtainedToken;
        uint256 tokenLiquidityAmount;
        uint256 ethLiquidityAmount;
        address pair;
        uint256 liquidity;
        uint256 pendingSushiTokens;
        uint256 totalTokenAmount;
    }
   
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import { DataTypes } from "./DataTypes.sol";

library AssetLib{ 

    using SafeMath for uint256;

    function initialize(DataTypes.Asset storage _asset, address _token, address _receipt, address _slp, uint _poolId ) internal {    
        _asset.token = _token;   
        _asset.receipt = _receipt;
        _asset.slp = _slp;
        _asset.poolId = _poolId;
        _asset.initialized = true;
    } 
    function increaseAmount(DataTypes.Asset storage _asset, uint256 _amount ) internal {       
          _asset.totalAmount = _asset.totalAmount.add(_amount);
    }
    
     function decreaseAmount(DataTypes.Asset storage _asset, uint256 _amount ) internal {   

           if( _asset.totalAmount >= _amount) {
                _asset.totalAmount = _asset.totalAmount.sub(_amount);
           } else {
               _asset.totalAmount = 0;
           }
      
    }
}

library UserDepositInfoLib{ 

    using SafeMath for uint256; 
    function increaseAmount(DataTypes.UserDepositInfo storage _deposit, uint256 _amount ) internal {       
          _deposit.totalInvested = _deposit.totalInvested.add(_amount);
    }
    
     function decreaseAmount(DataTypes.UserDepositInfo storage _deposit, uint256 _amount ) internal {   

           if( _deposit.totalInvested >= _amount) {
                _deposit.totalInvested = _deposit.totalInvested.sub(_amount);
           } else {
               _deposit.totalInvested = 0;
           }
      
    }

    function increasePaidFees(DataTypes.UserDepositInfo storage _deposit, uint256 _amount ) internal {       
        _deposit.assetFees = _deposit.assetFees.add(_amount);
    } 
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./base/SushiBase.sol";
import { StrategyBase } from "../base/StrategyBase.sol";
import { DataTypes, SushiSLPBaseDataTypes } from "../../libraries/sushi/DataTypes.sol";
import { AssetLib  } from "../../libraries/sushi/AssetLib.sol";
import "../../tokens/ReceiptToken.sol";
/*
  |Strategy Flow| 
      - User shows up with an ETH/USDT-SLP, ETH/WBTC-SLP or ETH/yUSD-SLP
      - Then we deposit SLPs in MasterChef and we get SUSHI rewards

    - Withdrawal flow does same thing, but backwards. 
*/
abstract contract SushiSLPBase is StrategyBase, SushiBase,  ReentrancyGuardUpgradeable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using AssetLib for DataTypes.Asset;
    
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");

    /**
     * @notice Create a new SushiSLP contract
     * @param _masterChef SushiSwap MasterChef address
     * @param _sushiswapFactory Sushiswap Factory address
     * @param _sushiswapRouter Sushiswap Router address
     * @param _weth WETH address
     * @param _sushi SUSHI address
     * @param _treasuryAddress treasury address
     * @param _feeAddress fee address
     */
    function __SushiSLPBase_init (
        address _masterChef,
        address _sushiswapFactory,
        address _sushiswapRouter,
        address _weth,
        address _sushi,
        address payable _treasuryAddress,
        address payable _feeAddress) internal initializer  {
        __ReentrancyGuard_init();

        __SushiBase_init(
            _masterChef,
            _sushiswapFactory,
            _sushiswapRouter,
            _weth,
            _sushi,
            _treasuryAddress,
            _feeAddress,
            1000 * (10**18));
    }

    /// @notice Event emitted when user withdraws
    event MasterchefWithdrawComplete(
        address indexed user,
        address indexed origin,
        uint256 pid,
        uint256 userSlp,
        uint256 userSushi,
        uint256 treasurySushi,
        uint256 feeSushi
    );

    /**
     * @notice Deposit to this strategy for rewards
     */
    function _deposit(DataTypes.UserDepositInfo storage _user, DataTypes.Asset memory _asset, uint256 slpAmount) internal  {
       
        SushiSLPBaseDataTypes.DepositData memory results; 

        _user.timestamp = block.timestamp;

        ReceiptToken(_asset.receipt).mint(msg.sender, slpAmount);
        
        emit ReceiptMinted(msg.sender, slpAmount);

        // update rewards
        // -----
        (
            _user.amount,
            results.pendingSushiTokens,
            _user.sushiRewardDebt
        ) = _updatePool(_user.amount, _user.sushiRewardDebt, slpAmount, _asset.poolId);

        // -----
        // deposit into master chef
        // -----
        uint256 prevSushiBalance = IERC20(sushi).balanceOf(address(this));
        _increaseAllowance(_asset.slp, address(masterChef), slpAmount);
        masterChef.deposit(_asset.poolId, slpAmount);

        if (results.pendingSushiTokens > 0) {
            uint256 sushiBalance = IERC20(sushi).balanceOf(address(this));
            if (sushiBalance > prevSushiBalance) {
                uint256 actualSushiTokens = sushiBalance.sub(prevSushiBalance);

                if (results.pendingSushiTokens > actualSushiTokens) {
                    _user.userAccumulatedSushi = _user.userAccumulatedSushi.add(
                        actualSushiTokens
                    );
                } else {
                    _user.userAccumulatedSushi = _user.userAccumulatedSushi.add(
                        results.pendingSushiTokens
                    );
                }
             }
        }

         emit Deposit(msg.sender, tx.origin, _asset.poolId, slpAmount);
    }

    /**
     * @notice Withdraw tokens and claim rewards
     * @return Amount of ETH obtained
     */
    function _withdraw(DataTypes.UserDepositInfo storage _user, DataTypes.Asset storage _asset,  uint256 amount) internal  returns (uint256, uint256) {
 
        DataTypes.WithdrawData memory w;
 
        w.oldAmount = _user.amount;

        DataTypes.WithdrawData memory results;
        // -----
        // withdraw from sushi master chef
        // -----
        masterChef.updatePool(_asset.poolId);

        w.pendingSushiTokens =
            w.oldAmount
                .mul(masterChef.poolInfo(_asset.poolId).accSushiPerShare)
                .div(1e12)
                .sub(_user.sushiRewardDebt);

        results.slpAmount = _masterChefWithdraw(amount, _asset.slp, _asset.poolId);
        require(results.slpAmount > 0, "SLP_AMOUNT_0");

        // -----
        // burn parachain auction token
        // -----
        _burnParachainAuctionTokens(_asset.receipt, amount);

        _user.sushiRewardDebt = _user
            .amount
            .mul(masterChef.poolInfo(_asset.poolId).accSushiPerShare)
            .div(1e12);

        w.sushiBalance = IERC20(sushi).balanceOf(address(this));
        if (w.pendingSushiTokens > 0) {
            if (w.pendingSushiTokens > w.sushiBalance) {
                _user.userAccumulatedSushi = _user.userAccumulatedSushi.add(
                    w.sushiBalance
                );
            } else {
                _user.userAccumulatedSushi = _user.userAccumulatedSushi.add(
                    w.pendingSushiTokens
                );
            }
        }

        if (_user.userAccumulatedSushi > w.sushiBalance) {
            results.totalSushi = w.sushiBalance;
        } else {
            results.totalSushi = _user.userAccumulatedSushi;
        }

        results.treasurySushi = results.totalSushi.div(2);
        results.userSushi = results.totalSushi.sub(results.treasurySushi); 

        // -----
        // transfer Sushi to treasury
        // -----
        IERC20(sushi).safeTransfer(treasuryAddress, results.treasurySushi);
        _user.treasurySushi = _user.treasurySushi.add(results.treasurySushi);
        emit RewardsEarned(
            msg.sender,
            treasuryAddress,
            "Sushi",
            results.treasurySushi
        );

        // -----
        // calculate fee, remove liquidity for it and tranfer it to the fee address
        // -----
        w.feeSushi = 0;
        if (fee > 0) {
            //calculate fee 
            w.feeSushi = _calculateFee(results.userSushi);
            results.userSushi = results.userSushi.sub(w.feeSushi);
            IERC20(sushi).safeTransfer(feeAddress, w.feeSushi);
            _user.feeSushi = _user.feeSushi.add(w.feeSushi);
            emit RewardsEarned(msg.sender, feeAddress, "Sushi", w.feeSushi);
        }

        // -----
        // transfer Sushi to the user
        // -----
        IERC20(sushi).safeTransfer(msg.sender, results.userSushi);
        _user.earnedSushi = _user.earnedSushi.add(results.userSushi);
        emit RewardsEarned(msg.sender, msg.sender, "Sushi", results.userSushi);
   
   
        emit MasterchefWithdrawComplete(
            msg.sender,
            tx.origin,
            _asset.poolId,
            results.slpAmount,
            results.userSushi,
            results.treasurySushi,
            w.feeSushi
        );

        _user.userAccumulatedSushi = 0;

        return (results.totalSushi, results.slpAmount);
    }
    
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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
        return a + b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
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
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
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
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

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
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
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
pragma solidity 0.8.1;
import { ERC20Upgradeable as ERC20} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
// This contract is used for printing receipt tokens
// Whenever someone joins a pool, a receipt token will be printed for that person
contract ReceiptToken is ERC20, AccessControlUpgradeable {
    ERC20 public underlyingToken;
    address public underlyingStrategy;

    bytes32 public constant MINTER_ROLE = keccak256("Strategy.ReceiptToken.Minter");
    bytes32 public constant ADMIN_ROLE = keccak256("Strategy.ReceiptToken.Admin");

    function initialize (address underlyingAddress, address strategy) external initializer {
         __ERC20_init(
                string(abi.encodePacked("pAT-", ERC20(underlyingAddress).name())),
                string(abi.encodePacked("pAT-", ERC20(underlyingAddress).symbol()))
         );

           underlyingToken = ERC20(underlyingAddress);
           underlyingStrategy = strategy;

           _setupRole(MINTER_ROLE, strategy);
    }
    
    /**
     * @notice Mint new receipt tokens to some user
     * @param to Address of the user that gets the receipt tokens
     * @param amount Amount of receipt tokens that will get minted
     */
    function mint(address to, uint256 amount) public onlyMinter {
        _mint(to, amount);
    }

    /**
     * @notice Burn receipt tokens from some user
     * @param from Address of the user that gets the receipt tokens burne
     * @param amount Amount of receipt tokens that will get burned
     */
    function burn(address from, uint256 amount) public onlyMinter {
        _burn(from, amount);
    }

    modifier onlyMinter() {
        require(hasRole(MINTER_ROLE, _msgSender()), "ERROR::REQUIRES_MINTER_ROLE");
        _;
    }
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../../../interfaces/sushiswap/IUniswapFactory.sol";
import "../../../interfaces/sushiswap/IMasterChef.sol";
import "../../../interfaces/strategy/IStrategy.sol";
import "../../../interfaces/strategy/ISushi.sol";
import { StrategyBase } from "../../base/StrategyBase.sol";
import "./Storage.sol";

abstract contract SushiBase is Storage,  StrategyBase, ISushi, IStrategy {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    //-----------------------------------------------------------------------------------------------------------------//
    //------------------------------------ Events -------------------------------------------------//
    //-----------------------------------------------------------------------------------------------------------------//
    event RewardsExchanged(
        address indexed user,
        uint256 rewardsAmount,
        uint256 obtainedEth
    );
     event RewardsEarned(
        address indexed user,
        address indexed to,
        string indexed rewardType,
        uint256 amount
    );
    /// @notice Event emitted when owner changes the master chef pool id
    event PoolIdChanged(address indexed sender, uint256 oldPid, uint256 newPid);

    /// @notice Event emitted when user makes a deposit
    event Deposit(
        address indexed user,
        address indexed origin,
        uint256 pid,
        uint256 amount
    );

    /// @notice Event emitted when owner makes a rescue dust request
    event RescuedDust(string indexed dustType, uint256 amount);

      /**
     * @notice Create a new SushiETHSLP contract
     * @param _weth WETH address
     * @param _sushi SUSHI address
     * @param _sushiswapRouter Sushiswap Router address
     * @param _sushiswapFactory Sushiswap Factory address
     * @param _masterChef SushiSwap MasterChef address
     * @param _treasuryAddress treasury address
     * @param _feeAddress fee address
     */
    function __SushiBase_init(
        address _masterChef,
        address _sushiswapFactory,
        address _sushiswapRouter,
        address _weth,
        address _sushi,
        address payable _treasuryAddress,
        address payable _feeAddress,
        uint256 _cap) internal initializer {
       
        require(_masterChef != address(0), "CHEF_0x0");
        require(_sushiswapFactory != address(0), "FACTORY_0x0");
        require(_sushi != address(0), "SUSHI_0x0");
        require(_treasuryAddress != address(0), "TREASURY_0x0");
        require(_feeAddress != address(0), "FEE_0x0");

        __StrategyBase_init(_sushiswapRouter,  _weth, _treasuryAddress,  _feeAddress,_cap);

        sushi = _sushi;
        sushiswapFactory = IUniswapFactory(_sushiswapFactory);
        masterChef = IMasterChef(_masterChef);
        // masterChefPoolId = _poolId;
        // slp = _slp;
    }

    /**
     * @notice Update the address of Sushi
     * @dev Can only be called by the owner
     * @param _sushi Address of Sushi
     */
    function setSushiAddress(address _sushi) external override onlyOwner {
        require(_sushi != address(0), "0x0");
        emit ChangedAddress("SUSHI", address(sushi), address(_sushi));
        sushi = _sushi;
    }

    /**
     * @notice Update the address of Sushiswap Factory
     * @dev Can only be called by the owner
     * @param _sushiswapFactory Address of Sushiswap Factory
     */
    function setSushiswapFactory(address _sushiswapFactory)
        external
        override
        onlyOwner
    {
        require(_sushiswapFactory != address(0), "0x0");
        emit ChangedAddress(
            "SUSHISWAP_FACTORY",
            address(sushiswapFactory),
            address(_sushiswapFactory)
        );
        sushiswapFactory = IUniswapFactory(_sushiswapFactory);
    }

    /**
     * @notice Update the address of Sushiswap Masterchef
     * @dev Can only be called by the owner
     * @param _masterChef Address of Sushiswap Masterchef
     */
    function setMasterChef(address _masterChef) external override onlyOwner {
        require(_masterChef != address(0), "0x0");
        emit ChangedAddress(
            "MASTER_CHEF",
            address(masterChef),
            address(_masterChef)
        );
        masterChef = IMasterChef(_masterChef);
    }

    /**
     * @notice Rescue dust resulted from swaps/liquidity
     * @dev Can only be called by the owner
     */
    function rescueDust() external override onlyOwner {
        if (ethDust > 0) {
            safeTransferETH(treasuryAddress, ethDust);
            treasueryEthDust = treasueryEthDust.add(ethDust);
            emit RescuedDust("ETH", ethDust);
            ethDust = 0;
        } 
    }

    /**
     * @notice Rescue tiken dust resulted from swaps/liquidity
     * @dev Can only be called by the owner
     */
    function rescueTokenDust(address token) external onlyOwner {
        if (tokenDust > 0) {
            IERC20(token).safeTransfer(treasuryAddress, tokenDust);
            treasuryTokenDust = treasuryTokenDust.add(tokenDust);
            emit RescuedDust("TOKEN", tokenDust);
            tokenDust = 0;
        }
    }

    /**
     * @notice Rescue any non-reward token that was airdropped to this contract
     * @dev Can only be called by the owner
     */
    function rescueAirdroppedTokens(address _token, address to)
        external
        override
        onlyOwner
    {
        require(_token != address(0), "token_0x0");
        require(to != address(0), "to_0x0");
        require(_token != sushi, "rescue_reward_error");

        uint256 balanceOfToken = IERC20(_token).balanceOf(address(this));
        require(balanceOfToken > 0, "balance_0");

        require(IERC20(_token).transfer(to, balanceOfToken), "rescue_failed");
    }
    

    //-----------------------------------------------------------------------------------------------------------------//
    //------------------------------------ Internal methods -------------------------------------------------//
    //-----------------------------------------------------------------------------------------------------------------//
    function _validateWithdraw(
        uint256 deadline,
        uint256 amount,
        uint256 userAmount,
        uint256 receiptBalance,
        uint256 timestamp
    ) internal view {
        _validateCommon(deadline, amount, 1000);

        require(userAmount >= amount, "AMOUNT_GREATER_THAN_BALANCE");
 
        require(receiptBalance >= amount, "RECEIPT_AMOUNT");

        if (lockTime > 0) {
            require(timestamp.add(lockTime) <= block.timestamp, "LOCK_TIME");
        }
    }

    function _addLiquidity(
        address _token,
        uint256 amountEth,
        uint256 amount,
        uint256 deadline
    )
        internal
        returns (
            uint256 liquidityTokenAmount,
            uint256 liquidityEthAmount,
            uint256 liquidity
        )
    {
        _increaseAllowance(_token, address(sushiswapRouter), amount);
        
        (liquidityTokenAmount, liquidityEthAmount, liquidity) = sushiswapRouter
            .addLiquidityETH{value: amountEth}(
            _token,
            amount,
            uint256(0),
            uint256(0),
            address(this),
            deadline
        );
    }

    function _removeLiquidity(
        address _token,
        address _pair,
        uint256 slpAmount,
        uint256 deadline
    )
        internal
        returns (uint256 tokenLiquidityAmount, uint256 ethLiquidityAmount)
    {
        _increaseAllowance(_pair, address(sushiswapRouter), slpAmount);

        (tokenLiquidityAmount, ethLiquidityAmount) = sushiswapRouter
            .removeLiquidityETH(
            _token,
            slpAmount,
            uint256(0),
            uint256(0),
            address(this),
            deadline
        );
    }

    function _updatePool(
        uint256 amount,
        uint256 sushiRewardDebt,
        uint256 liquidity,
        uint256 masterChefPoolId
    )
        internal
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        masterChef.updatePool(masterChefPoolId);
        uint256 pendingSushiTokens =
            amount
                .mul(masterChef.poolInfo(masterChefPoolId).accSushiPerShare)
                .div(1e12)
                .sub(sushiRewardDebt);

        amount = amount.add(liquidity);

        masterChef.updatePool(masterChefPoolId);
        sushiRewardDebt = amount
            .mul(masterChef.poolInfo(masterChefPoolId).accSushiPerShare)
            .div(1e12);

        return (amount, pendingSushiTokens, sushiRewardDebt);
    }

    function _masterChefWithdraw(uint256 amount, address slp, uint256 masterChefPoolId) internal returns (uint256) {
        uint256 prevSlpAmount = IERC20(slp).balanceOf(address(this));

        masterChef.updatePool(masterChefPoolId);
        masterChef.withdraw(masterChefPoolId, amount);

        uint256 currentSlpAmount = IERC20(slp).balanceOf(address(this));
        if (currentSlpAmount <= prevSlpAmount) {
            return 0;
        }

        return currentSlpAmount.sub(prevSlpAmount);
    }

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "../../interfaces/sushiswap/IUniswapRouter.sol";
import "../../interfaces/strategy/IStrategyBase.sol";
import { ReceiptToken } from "../../tokens/ReceiptToken.sol";
import "./Storage.sol";
// import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
abstract contract StrategyBase is Storage, IStrategyBase, AccessControlUpgradeable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    /// @notice Event emitted when user makes a deposit and receipt token is minted
    event ReceiptMinted(address indexed user, uint256 amount);
    /// @notice Event emitted when user withdraws and receipt token is burned
    event ReceiptBurned(address indexed user, uint256 amount);
    /// @notice Event emitted when owner changes any contract address
    event ChangedAddress(string indexed addressType,address indexed oldAddress,address indexed newAddress );
    /// @notice Event emitted when owner changes any contract address
    event ChangedValue(string indexed valueType,uint256 indexed oldValue,uint256 indexed newValue);
    /// @notice Event emitted when Owner changes 
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    /**
     * @notice Create a new HarvestDAI contract
     * @param _sushiswapRouter Sushiswap Router address
     * @param _weth WETH address
     * @param _treasuryAddress treasury address
     * @param _feeAddress fee address
     */
    function __StrategyBase_init(
      address _sushiswapRouter, 
      address _weth,
      address payable _treasuryAddress, 
      address payable _feeAddress,
      uint256 _cap )  internal initializer {
        require(_sushiswapRouter != address(0), "ROUTER_0x0");
        require(_weth != address(0), "WETH_0x0");
        require(_treasuryAddress != address(0), "TREASURY_0x0");
        require(_feeAddress != address(0), "FEE_0x0");
         _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        sushiswapRouter = IUniswapRouter(_sushiswapRouter);
        weth = _weth;
        treasuryAddress = _treasuryAddress;
        feeAddress = _feeAddress; 
        cap = _cap;
    }

    function _validateCommon(uint256 deadline,uint256 amount, uint256 _slippage) internal view {
        require(deadline >= block.timestamp, "DEADLINE_ERROR");
        require(amount > 0, "AMOUNT_0");
        require(_slippage >= _minSlippage, "SLIPPAGE_ERROR");
        require(_slippage <= feeFactor, "MAX_SLIPPAGE_ERROR");
    }
    function _validateDeposit(uint256 deadline, uint256 amount,uint256 total,uint256 slippage ) internal view {
        _validateCommon(deadline, amount, slippage);
        if(cap > 0) {
            require(total.add(amount) <= cap, "CAP_REACHED");
        }
    }
    function _mintParachainAuctionTokens(address _receiptToken,uint256 _amount) internal {
         ReceiptToken(_receiptToken).mint(msg.sender, _amount);
        emit ReceiptMinted(msg.sender, _amount);
    }
    function _burnParachainAuctionTokens(address _receiptToken, uint256 _amount) internal {
        ReceiptToken(_receiptToken).burn(msg.sender, _amount);
        emit ReceiptBurned(msg.sender, _amount);
    }
    function _calculateFee(uint256 _amount) internal view returns (uint256) {
        return _calculatePortion(_amount, fee);
    }
    function _getBalance(address _token) internal view returns (uint256) {
        return IERC20(_token).balanceOf(address(this));
    }
    function _increaseAllowance(address _token,address _contract,uint256 _amount) internal {
        IERC20(_token).safeIncreaseAllowance(_contract, _amount);
    }
    function _getRatio(uint256 numerator,uint256 denominator,uint256 precision) internal pure returns (uint256) {
        if (numerator == 0 || denominator == 0) {
            return 0;
        }
        uint256 _numerator = numerator * 10**(precision + 1);
        uint256 _quotient = ((_numerator / denominator) + 5) / 10;
        return (_quotient);
    }

    function _swapTokenToEth(
        address[] memory swapPath,
        uint256 exchangeAmount,
        uint256 deadline,
        uint256 slippage,
        uint256 ethPerToken
    ) internal returns (uint256) {
        uint256[] memory amounts =
            sushiswapRouter.getAmountsOut(exchangeAmount, swapPath);
        uint256 sushiAmount = amounts[amounts.length - 1]; //amount of ETH
        uint256 portion = _calculatePortion(sushiAmount, slippage);
        uint256 calculatedPrice = (exchangeAmount.mul(ethPerToken)).div(10**18);
        uint256 decimals = ERC20(swapPath[0]).decimals();
        if (decimals < 18) {
            calculatedPrice = calculatedPrice.mul(10**(18 - decimals));
        }
        if (sushiAmount > calculatedPrice) {
            require(
                sushiAmount.sub(calculatedPrice) <= portion,
                "PRICE_ERROR_1"
            );
        } else {
            require(
                calculatedPrice.sub(sushiAmount) <= portion,
                "PRICE_ERROR_2"
            );
        }

        _increaseAllowance(
            swapPath[0],
            address(sushiswapRouter),
            exchangeAmount
        );
        uint256[] memory tokenSwapAmounts =
            sushiswapRouter.swapExactTokensForETH(
                exchangeAmount,
                _getMinAmount(sushiAmount, slippage),
                swapPath,
                address(this),
                deadline
            );
        return tokenSwapAmounts[tokenSwapAmounts.length - 1];
    }

    function _swapEthToToken(
        address[] memory swapPath,
        uint256 exchangeAmount,
        uint256 deadline,
        uint256 slippage,
        uint256 tokensPerEth
    ) internal returns (uint256) {
        uint256[] memory amounts =
            sushiswapRouter.getAmountsOut(exchangeAmount, swapPath);
        uint256 sushiAmount = amounts[amounts.length - 1];
        uint256 portion = _calculatePortion(sushiAmount, slippage);
        uint256 calculatedPrice =
            (exchangeAmount.mul(tokensPerEth)).div(10**18);
        uint256 decimals = ERC20(swapPath[0]).decimals();
        if (decimals < 18) {
            calculatedPrice = calculatedPrice.mul(10**(18 - decimals));
        }
        if (sushiAmount > calculatedPrice) {
            require(
                sushiAmount.sub(calculatedPrice) <= portion,
                "PRICE_ERROR_1"
            );
        } else {
            require(
                calculatedPrice.sub(sushiAmount) <= portion,
                "PRICE_ERROR_2"
            );
        }

        uint256[] memory swapResult =
            sushiswapRouter.swapExactETHForTokens{value: exchangeAmount}(
                _getMinAmount(sushiAmount, slippage),
                swapPath,
                address(this),
                deadline
            );

        return swapResult[swapResult.length - 1];
    }

    function _getMinAmount(uint256 amount, uint256 slippage) private pure returns (uint256) {
        uint256 portion = _calculatePortion(amount, slippage);
        return amount.sub(portion);
    }

    function _calculatePortion(uint256 _amount, uint256 _fee) private pure returns (uint256) {
        return (_amount.mul(_fee)).div(feeFactor);
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, "TransferHelper: ETH_TRANSFER_FAILED");
    }
    function setFee(uint256 _fee) external override  onlyOwner  {
        require(_fee <= uint256(9000), "FEE_TOO_HIGH");
        fee = _fee;
        emit ChangedValue("FEE", fee, _fee);
    }
    function setFeeAddress(address payable _feeAddress)external override onlyOwner {
        require(_feeAddress != address(0), "0x0");
        emit ChangedAddress("FEE", address(feeAddress), address(_feeAddress));
        feeAddress = _feeAddress;
    }
    /**
     * @notice Update the address for fees
     * @dev Can only be called by the owner
     * @param _treasuryAddress Treasury's address
     */
    function setTreasury(address payable _treasuryAddress) external override onlyOwner{
        require(_treasuryAddress != address(0), "0x0");
        emit ChangedAddress("TREASURY", address(treasuryAddress), address(_treasuryAddress));
        treasuryAddress = _treasuryAddress;
    }

    /**
     * @notice Update the address of WETH
     * @dev Can only be called by the owner
     * @param _weth Address of WETH
     */
    function setWethAddress(address _weth) external override onlyOwner {
        require(_weth != address(0), "0x0");
        emit ChangedAddress("WETH", address(weth), address(_weth));
        weth = _weth;
    }
    /**
     * @notice Set max ETH cap for this strategy
     * @dev Can only be called by the owner
     * @param _cap ETH amount
     */
    function setCap(uint256 _cap) external override onlyOwner {
        emit ChangedValue("CAP", cap, _cap);
        cap = _cap;
    }

     /**
     * @notice Set lock time
     * @dev Can only be called by the owner
     * @param _lockTime lock time in seconds
     */
    function setLockTime(uint256 _lockTime) external override onlyOwner {
        require(_lockTime > 0, "TIME_0");
        emit ChangedValue("LOCKTIME", lockTime, _lockTime);
        lockTime = _lockTime;
    }
    /**
     * @notice Update the address of Sushiswap Router
     * @dev Can only be called by the owner
     * @param _sushiswapRouter Address of Sushiswap Router
     */
    function setSushiswapRouter(address _sushiswapRouter)external override onlyOwner{
        require(_sushiswapRouter != address(0), "0x0");
        emit ChangedAddress("SUSHISWAP_ROUTER",address(sushiswapRouter), address(_sushiswapRouter));
        sushiswapRouter = IUniswapRouter(_sushiswapRouter);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "!address_newOwner");
        emit OwnershipTransferred(_msgSender(), newOwner);
        revokeRole(OWNER_ROLE, _msgSender());
        grantRole(OWNER_ROLE, newOwner);
    }

    function grantOwnerRole(address account) onlyAdmin override external  {
        grantRole(OWNER_ROLE, account);
    }
    

    modifier onlyOwner(){
        require(hasRole(OWNER_ROLE, _msgSender()), "Caller is not Owner");
        _;
    }

    modifier onlyAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Caller is not admin");
        _;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;
// Interface declarations

/* solhint-disable func-order */

interface IUniswapFactory {
    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);

    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.1;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IMasterChef {
    struct PoolInfo {
        IERC20 lpToken; // Address of LP token contract.
        uint256 allocPoint; // How many allocation points assigned to this pool. SUSHIs to distribute per block.
        uint256 lastRewardBlock; // Last block number that SUSHIs distribution occurs.
        uint256 accSushiPerShare; // Accumulated SUSHIs per share, times 1e12.
    }

 
    function poolLength() external view returns (uint256);

    function deposit(uint256 _pid, uint256 _amount) external;

    function withdraw(uint256 _pid, uint256 _amount) external;

    function poolInfo(uint256 _pid) external view returns (PoolInfo memory);

    function pendingSushi(uint256 _pid, address _user)
        external
        view
        returns (uint256);

    function updatePool(uint256 _pid) external;

    function sushiPerBlock() external view returns (uint256);

    function totalAllocPoint() external view returns (uint256);

    function getMultiplier(uint256 _from, uint256 _to)
        external
        view
        returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./IStrategyBase.sol";
interface IStrategy is IStrategyBase {

    function rescueDust() external;

    function rescueAirdroppedTokens(address _token, address to) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;
interface ISushi {

    function setSushiAddress(address _sushi) external;

    function setSushiswapFactory(address _sushiswapFactory) external;

    function setMasterChef(address _masterChef) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.1;
 
import { IUniswapFactory } from "../../../interfaces/sushiswap/IUniswapFactory.sol";
import { IMasterChef } from "../../../interfaces/sushiswap/IMasterChef.sol"; 

contract Storage { 
    address public sushi;
    uint256 public ethDust;
    uint256 public tokenDust;
    uint256 public treasueryEthDust;
    uint256 public treasuryTokenDust; 
    IUniswapFactory public sushiswapFactory;
    IMasterChef public masterChef; 
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./IStrategyAccessControl.sol";
interface IStrategyBase is IStrategyAccessControl {

    function setCap(uint256 _cap) external;

    function setTreasury(address payable _feeAddress) external;

    function setFeeAddress(address payable _feeAddress) external;

    function setFee(uint256 _fee) external; 

    function setWethAddress(address _weth) external;

    function setLockTime(uint256 _lockTime) external;

    function setSushiswapRouter(address _sushiswapRouter) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
interface IStrategyAccessControl {
      function grantOwnerRole(address account) external; 
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../utils/StringsUpgradeable.sol";
import "../utils/introspection/ERC165Upgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
    function hasRole(bytes32 role, address account) external view returns (bool);
    function getRoleAdmin(bytes32 role) external view returns (bytes32);
    function grantRole(bytes32 role, address account) external;
    function revokeRole(bytes32 role, address account) external;
    function renounceRole(bytes32 role, address account) external;
}

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable, IAccessControlUpgradeable, ERC165Upgradeable {
    function __AccessControl_init() internal initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __AccessControl_init_unchained();
    }

    function __AccessControl_init_unchained() internal initializer {
    }
    struct RoleData {
        mapping (address => bool) members;
        bytes32 adminRole;
    }

    mapping (bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{20}) is missing role (0x[0-9a-f]{32})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlUpgradeable).interfaceId
            || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{20}) is missing role (0x[0-9a-f]{32})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if(!hasRole(role, account)) {
            revert(string(abi.encodePacked(
                "AccessControl: account ",
                StringsUpgradeable.toHexString(uint160(account), 20),
                " is missing role ",
                StringsUpgradeable.toHexString(uint256(role), 32)
            )));
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        emit RoleAdminChanged(role, getRoleAdmin(role), adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.1;

// Interface declarations

/* solhint-disable func-order */

interface IUniswapRouter {
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.1;

import "../../tokens/ReceiptToken.sol";
import "../../interfaces/sushiswap/IUniswapRouter.sol";

contract Storage{
    address public weth;
    address payable public treasuryAddress;
    address payable public feeAddress;
    // address public token;
    IUniswapRouter public sushiswapRouter;
    uint256 internal _minSlippage = 10; //0.1%
    uint256 public lockTime = 1;
    uint256 public fee = uint256(100);
    uint256 constant feeFactor = uint256(10000);
    uint256 public cap;
    bytes32 public constant OWNER_ROLE = keccak256("STRATEGY.OWNER");

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant alphabet = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = alphabet[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal initializer {
        __ERC165_init_unchained();
    }

    function __ERC165_init_unchained() internal initializer {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165Upgradeable {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20Upgradeable.sol";
import "./extensions/IERC20MetadataUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable, IERC20MetadataUpgradeable {
    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The defaut value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    function __ERC20_init(string memory name_, string memory symbol_) internal initializer {
        __Context_init_unchained();
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal initializer {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
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

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
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
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

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

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

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

        _totalSupply += amount;
        _balances[account] += amount;
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

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;

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
    uint256[45] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

