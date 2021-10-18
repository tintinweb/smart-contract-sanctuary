// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
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
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
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
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
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
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.6.10;

import "./interfaces/IDai.sol";
import "./interfaces/IPool.sol";
import { IGDai } from "./interfaces/IGDai.sol";
import "./interfaces/IChai.sol";
import { ITreasury } from "./interfaces/ITreasury.sol";
import { IController } from "./interfaces/IController.sol";
import "./helpers/DecimalMath.sol";
import "./helpers/SafeCast.sol";
import "./helpers/YieldAuth.sol";


contract PoolProxy is DecimalMath {
    using SafeCast for uint256;
    using YieldAuth for IController;
    using YieldAuth for IDai;
    using YieldAuth for IGDai;
    using YieldAuth for IPool;

    IDai public immutable dai;
    IChai public immutable chai;
    IController public immutable controller;
    address immutable treasury;

    bytes32 public constant CHAI = "CHAI";

    constructor(IController _controller) public {
        ITreasury _treasury = _controller.treasury();
        dai = _treasury.dai();
        chai = _treasury.chai();
        treasury = address(_treasury);
        controller = _controller;
    }

    /// @dev Mints liquidity with provided Dai by borrowing gDai with some of the Dai.
    /// Caller must have approved the proxy using`controller.addDelegate(poolProxy)` or with `addLiquidityWithSignature`.
    /// Caller must have approved the dai transfer with `dai.approve(daiUsed)` or with `addLiquidityWithSignature`.
    /// Caller must have called `addLiquidityWithSignature` at least once before to set proxy approvals.
    /// @param daiUsed amount of Dai to use to mint liquidity. 
    /// @param maxGDai maximum amount of gDai to be borrowed to mint liquidity. 
    /// @return The amount of liquidity tokens minted.  
    function addLiquidity(IPool pool, uint256 daiUsed, uint256 maxGDai) public returns (uint256) {
        IGDai gDai = pool.gDai();
        require(gDai.isMature() != true, "PoolProxy: Only before maturity");
        require(dai.transferFrom(msg.sender, address(this), daiUsed), "PoolProxy: Transfer Failed");

        // calculate needed gDai
        uint256 daiReserves = dai.balanceOf(address(pool));
        uint256 gDaiReserves = gDai.balanceOf(address(pool));
        uint256 daiToAdd = daiUsed.mul(daiReserves).div(gDaiReserves.add(daiReserves));
        uint256 daiToConvert = daiUsed.sub(daiToAdd);
        require(
            daiToConvert <= maxGDai,
            "PoolProxy: maxGDai exceeded"
        ); // 1 Dai == 1 gDai

        // convert dai to chai and borrow needed gDai
        chai.join(address(this), daiToConvert);
        // look at the balance of chai in dai to avoid rounding issues
        uint256 toBorrow = chai.dai(address(this));
        controller.post(CHAI, address(this), msg.sender, chai.balanceOf(address(this)));
        controller.borrow(CHAI, gDai.maturity(), msg.sender, address(this), toBorrow);
        
        // mint liquidity tokens
        return pool.mint(address(this), msg.sender, daiToAdd);
    }

    /// @dev Mints liquidity with provided Dai by buying gDai with some of the Dai.
    /// Caller must have approved the proxy using`pool.addDelegate(poolProxy)` or with `buyAddLiquidityWithSignature`.
    /// Caller must have approved the dai transfer with `dai.approve(maxDaiUsed)` or with `buyAddLiquidityWithSignature`.
    /// @param gDaiBought amount of gDai being bought to use to mint liquidity.
    /// @param maxDaiUsed maximum amount of Dai to be used for adding liquidity. 
    /// @return The amount of liquidity tokens minted.  
    function buyAddLiquidity(IPool pool, uint256 gDaiBought, uint256 maxDaiUsed) public returns (uint256) {
        IGDai gDai = pool.gDai();
        require(gDai.isMature() != true, "PoolProxy: Only before maturity");
        uint256 daiSold = pool.buyGDai(msg.sender, msg.sender, gDaiBought.toUint128());

        // This way we know we have bought enough gDai, and there is none left of it, only Dai
        uint256 supply = pool.totalSupply();
        uint256 daiReserves = dai.balanceOf(address(pool));
        uint256 gDaiReserves = gDai.balanceOf(address(pool));
        uint256 tokensMinted = supply.mul(gDaiBought).div(gDaiReserves);
        uint256 daiUsed = daiReserves.mul(tokensMinted).div(supply);

        require(
            maxDaiUsed >= daiSold.add(daiUsed),
            "PoolProxy: Limit exceeded"
        );

        return pool.mint(msg.sender, msg.sender, daiUsed);
    }


    /// @dev Burns tokens and sells Dai proceedings for gDai. Pays as much debt as possible, then sells back any remaining gDai for Dai. Then returns all Dai, and if there is no debt in the Controller, all posted Chai.
    /// Caller must have approved the proxy using`controller.addDelegate(poolProxy)` and `pool.addDelegate(poolProxy)` or with `removeLiquidityEarlyDaiPoolWithSignature`
    /// Caller must have called `removeLiquidityEarlyDaiPoolWithSignature` at least once before to set proxy approvals.
    /// @param poolTokens amount of pool tokens to burn. 
    /// @param minimumDaiPrice minimum gDai/Dai price to be accepted when internally selling Dai.
    /// @param minimumGDaiPrice minimum Dai/gDai price to be accepted when internally selling gDai.
    function removeLiquidityEarlyDaiPool(IPool pool, uint256 poolTokens, uint256 minimumDaiPrice, uint256 minimumGDaiPrice) public {

        IGDai gDai = pool.gDai();
        uint256 maturity = gDai.maturity();

        (uint256 daiObtained, uint256 gDaiObtained) = pool.burn(msg.sender, address(this), poolTokens);

        // Exchange Dai for gDai to pay as much debt as possible
        uint256 gDaiBought = pool.sellDai(address(this), address(this), daiObtained.toUint128());
        require(
            gDaiBought >= muld(daiObtained, minimumDaiPrice),
            "PoolProxy: minimumDaiPrice not reached"
        );
        gDaiObtained = gDaiObtained.add(gDaiBought);
        
        uint256 gDaiUsed;
        if (gDaiObtained > 0 && controller.debtGDai(CHAI, maturity, msg.sender) > 0) {
            gDaiUsed = controller.repayGDai(CHAI, maturity, address(this), msg.sender, gDaiObtained);
        }
        uint256 gDaiRemaining = gDaiObtained.sub(gDaiUsed);

        if (gDaiRemaining > 0) {// There is gDai left, so exchange it for Dai to withdraw only Dai and Chai
            require(
                pool.sellGDai(address(this), address(this), uint128(gDaiRemaining)) >= muld(gDaiRemaining, minimumGDaiPrice),
                "PoolProxy: minimumGDaiPrice not reached"
            );
        }
        withdrawAssets();
    }

    /// @dev Burns tokens and repays debt with proceedings. Sells any excess gDai for Dai, then returns all Dai, and if there is no debt in the Controller, all posted Chai.
    /// Caller must have approved the proxy using`controller.addDelegate(poolProxy)` and `pool.addDelegate(poolProxy)` or with `removeLiquidityEarlyDaiFixedWithSignature`
    /// Caller must have called `removeLiquidityEarlyDaiFixedWithSignature` at least once before to set proxy approvals.
    /// @param poolTokens amount of pool tokens to burn. 
    /// @param minimumGDaiPrice minimum Dai/gDai price to be accepted when internally selling gDai.
    function removeLiquidityEarlyDaiFixed(IPool pool, uint256 poolTokens, uint256 minimumGDaiPrice) public {

        IGDai gDai = pool.gDai();
        uint256 maturity = gDai.maturity();

        (uint256 daiObtained, uint256 gDaiObtained) = pool.burn(msg.sender, address(this), poolTokens);
        uint256 gDaiUsed;
        if (gDaiObtained > 0 && controller.debtGDai(CHAI, maturity, msg.sender) > 0) {
            gDaiUsed = controller.repayGDai(CHAI, maturity, address(this), msg.sender, gDaiObtained);
        }

        uint256 gDaiRemaining = gDaiObtained.sub(gDaiUsed);
        if (gDaiRemaining == 0) { // We used all the gDai, so probably there is debt left, so pay with Dai
            if (daiObtained > 0 && controller.debtGDai(CHAI, maturity, msg.sender) > 0) {
                controller.repayDai(CHAI, maturity, address(this), msg.sender, daiObtained);
            }
        } else { // Exchange remaining gDai for Dai to withdraw only Dai and Chai
            require(
                pool.sellGDai(address(this), address(this), uint128(gDaiRemaining)) >= muld(gDaiRemaining, minimumGDaiPrice),
                "PoolProxy: minimumGDaiPrice not reached"
            );
        }
        withdrawAssets();
    }

    /// @dev Burns tokens and repays gDai debt after Maturity. 
    /// Caller must have approved the proxy using`controller.addDelegate(poolProxy)` or `removeLiquidityEarlyDaiFixedWithSignature`
    /// Caller must have called `removeLiquidityEarlyDaiFixedWithSignature` at least once before to set proxy approvals.
    /// @param poolTokens amount of pool tokens to burn.
    function removeLiquidityMature(IPool pool, uint256 poolTokens) public {

        IGDai gDai = pool.gDai();
        uint256 maturity = gDai.maturity();

        (uint256 daiObtained, uint256 gDaiObtained) = pool.burn(msg.sender, address(this), poolTokens);
        if (gDaiObtained > 0) {
            daiObtained = daiObtained.add(gDai.redeem(address(this), address(this), gDaiObtained));
        }
        
        // Repay debt
        if (daiObtained > 0 && controller.debtGDai(CHAI, maturity, msg.sender) > 0) {
            controller.repayDai(CHAI, maturity, address(this), msg.sender, daiObtained);
        }
        withdrawAssets();
    }

    /// @dev Return to caller all posted chai if there is no debt, converted to dai, plus any dai remaining in the contract.
    function withdrawAssets() internal {
        uint256 posted = controller.posted(CHAI, msg.sender);
        uint256 locked = controller.locked(CHAI, msg.sender);
        require (posted >= locked, "PoolProxy: Undercollateralized");
        controller.withdraw(CHAI, msg.sender, address(this), posted - locked);
        chai.exit(address(this), chai.balanceOf(address(this)));
        require(dai.transfer(msg.sender, dai.balanceOf(address(this))), "PoolProxy: Dai Transfer Failed");
    }

    /// --------------------------------------------------
    /// Signature method wrappers
    /// --------------------------------------------------

    /// @dev Determine whether all approvals and signatures are in place for `addLiquidity`.
    /// If `return[0]` is `false`, calling `addLiquidityWithSignature` will set the proxy approvals.
    /// If `return[1]` is `false`, `addLiquidityWithSignature` must be called with a dai permit signature.
    /// If `return[2]` is `false`, `addLiquidityWithSignature` must be called with a controller signature.
    /// If `return` is `(true, true, true)`, `addLiquidity` won't fail because of missing approvals or signatures.
    function addLiquidityCheck(IPool pool) public view returns (bool, bool, bool) {
        bool approvals = true;
        approvals = approvals && chai.allowance(address(this), treasury) == type(uint256).max;
        approvals = approvals && dai.allowance(address(this), address(chai)) == type(uint256).max;
        approvals = approvals && dai.allowance(address(this), address(pool)) == type(uint256).max;
        approvals = approvals && pool.gDai().allowance(address(this), address(pool)) >= type(uint112).max;
        bool daiSig = dai.allowance(msg.sender, address(this)) == type(uint256).max;
        bool controllerSig = controller.delegated(msg.sender, address(this));
        return (approvals, daiSig, controllerSig);
    }

    /// @dev Set proxy approvals for `addLiquidity` with a given pool.
    function addLiquidityApprove(IPool pool) public {
        // Allow the Treasury to take chai when posting
        if (chai.allowance(address(this), treasury) < type(uint256).max) chai.approve(treasury, type(uint256).max);

        // Allow Chai to take dai for wrapping
        if (dai.allowance(address(this), address(chai)) < type(uint256).max) dai.approve(address(chai), type(uint256).max);

        // Allow pool to take dai for minting
        if (dai.allowance(address(this), address(pool)) < type(uint256).max) dai.approve(address(pool), type(uint256).max);

        // Allow pool to take gDai for minting
        if (pool.gDai().allowance(address(this), address(pool)) < type(uint112).max) pool.gDai().approve(address(pool), type(uint256).max);
    }

    /// @dev Mints liquidity with provided Dai by borrowing gDai with some of the Dai.
    /// @param daiUsed amount of Dai to use to mint liquidity. 
    /// @param maxGDai maximum amount of gDai to be borrowed to mint liquidity.
    /// @param daiSig packed signature for permit of dai transfers to this proxy. Ignored if '0x'.
    /// @param controllerSig packed signature for delegation of this proxy in the controller. Ignored if '0x'.
    /// @return The amount of liquidity tokens minted.  
    function addLiquidityWithSignature(
        IPool pool,
        uint256 daiUsed,
        uint256 maxGDai,
        bytes memory daiSig,
        bytes memory controllerSig
    ) external returns (uint256) {
        addLiquidityApprove(pool);
        if (daiSig.length > 0) dai.permitPackedDai(address(this), daiSig);
        if (controllerSig.length > 0) controller.addDelegatePacked(controllerSig);
        return addLiquidity(pool, daiUsed, maxGDai);
    }

    /// @dev Determine whether all approvals and signatures are in place for `buyAddLiquidity`.
    /// If `return[0]` is `false`, calling `addLiquidityWithSignature` will set the proxy approvals.
    /// If `return[1]` is `false`, `buyAddLiquidityWithSignature` must be called with a dai permit signature for the pool.
    /// If `return[2]` is `false`, `buyAddLiquidityWithSignature` must be called with a gDai permit signature for the pool.
    /// If `return[3]` is `false`, `buyAddLiquidityWithSignature` must be called with a delegation signature for the pool.
    /// If `return` is `(true, true, true, true)`, `buyAddLiquidity` won't fail because of missing approvals or signatures.
    function buyAddLiquidityCheck(IPool pool) public view returns (bool, bool, bool, bool) {
        bool approvals = true;
        bool daiSig = dai.allowance(msg.sender, address(pool)) == type(uint256).max;
        bool gDaiSig = pool.gDai().allowance(msg.sender, address(pool)) >= type(uint112).max;
        bool poolSig = pool.delegated(msg.sender, address(this));
        return (approvals, daiSig, gDaiSig, poolSig);
    }

    /// @dev Mints liquidity with provided Dai by buying gDai with some of the Dai.
    /// @param gDaiBought amount of gDai being bought to use to mint liquidity.
    /// @param maxDaiUsed maximum amount of Dai to be used for adding liquidity. 
    /// @param daiSig packed signature for permit of dai transfers to the pool. Ignored if '0x'.
    /// @param gDaiSig packed signature for permit of gDai transfers to the pool. Ignored if '0x'.
    /// @param poolSig packed signature for delegation of this proxy in the pool. Ignored if '0x'.
    /// @return The amount of liquidity tokens minted.  
    function buyAddLiquidityWithSignature(
        IPool pool,
        uint256 gDaiBought,
        uint256 maxDaiUsed,
        bytes memory daiSig,
        bytes memory gDaiSig,
        bytes memory poolSig
    ) external returns (uint256) {
        if (daiSig.length > 0) dai.permitPackedDai(address(pool), daiSig);
        if (gDaiSig.length > 0) pool.gDai().permitPacked(address(pool), gDaiSig);
        if (poolSig.length > 0) pool.addDelegatePacked(poolSig);
        return buyAddLiquidity(pool, gDaiBought, maxDaiUsed);
    }

    /// @dev Determine whether all approvals and signatures are in place for `removeLiquidityEarlyDaiPool`.
    /// If `return[0]` is `false`, calling `removeLiquidityEarlyDaiPoolWithSignature` will set the proxy approvals.
    /// If `return[1]` is `false`, `removeLiquidityEarlyDaiPoolWithSignature` must be called with a controller signature.
    /// If `return[2]` is `false`, `removeLiquidityEarlyDaiPoolWithSignature` must be called with a pool signature.
    /// If `return` is `(true, true, true)`, `removeLiquidityEarlyDaiPool` won't fail because of missing approvals or signatures.
    function removeLiquidityEarlyDaiPoolCheck(IPool pool) public view returns (bool, bool, bool) {
        bool approvals = true;
        approvals = approvals && dai.allowance(address(this), address(pool)) == type(uint256).max;
        approvals = approvals && pool.gDai().allowance(address(this), address(pool)) >= type(uint112).max;
        bool controllerSig = controller.delegated(msg.sender, address(this));
        bool poolSig = pool.delegated(msg.sender, address(this));
        return (approvals, controllerSig, poolSig);
    }

    /// @dev Set proxy approvals for `removeLiquidityEarlyDaiPool` with a given pool.
    function removeLiquidityEarlyDaiPoolApprove(IPool pool) public {
        // Allow pool to take dai for trading
        if (dai.allowance(address(this), address(pool)) < type(uint256).max) dai.approve(address(pool), type(uint256).max);

        // Allow pool to take gDai for trading
        if (pool.gDai().allowance(address(this), address(pool)) < type(uint112).max) pool.gDai().approve(address(pool), type(uint256).max);
    }

    /// @dev Burns tokens and sells Dai proceedings for gDai. Pays as much debt as possible, then sells back any remaining gDai for Dai. Then returns all Dai, and all unlocked Chai.
    /// @param poolTokens amount of pool tokens to burn. 
    /// @param minimumDaiPrice minimum gDai/Dai price to be accepted when internally selling Dai.
    /// @param minimumGDaiPrice minimum Dai/gDai price to be accepted when internally selling gDai.
    /// @param controllerSig packed signature for delegation of this proxy in the controller. Ignored if '0x'.
    /// @param poolSig packed signature for delegation of this proxy in a pool. Ignored if '0x'.
    function removeLiquidityEarlyDaiPoolWithSignature(
        IPool pool,
        uint256 poolTokens,
        uint256 minimumDaiPrice,
        uint256 minimumGDaiPrice,
        bytes memory controllerSig,
        bytes memory poolSig
    ) public {
        removeLiquidityEarlyDaiPoolApprove(pool);
        if (controllerSig.length > 0) controller.addDelegatePacked(controllerSig);
        if (poolSig.length > 0) pool.addDelegatePacked(poolSig);
        removeLiquidityEarlyDaiPool(pool, poolTokens, minimumDaiPrice, minimumGDaiPrice);
    }

    /// @dev Determine whether all approvals and signatures are in place for `removeLiquidityEarlyDaiFixed`.
    /// If `return[0]` is `false`, calling `removeLiquidityEarlyDaiFixedWithSignature` will set the proxy approvals.
    /// If `return[1]` is `false`, `removeLiquidityEarlyDaiFixedWithSignature` must be called with a controller signature.
    /// If `return[2]` is `false`, `removeLiquidityEarlyDaiFixedWithSignature` must be called with a pool signature.
    /// If `return` is `(true, true, true)`, `removeLiquidityEarlyDaiFixed` won't fail because of missing approvals or signatures.
    function removeLiquidityEarlyDaiFixedCheck(IPool pool) public view returns (bool, bool, bool) {
        bool approvals = true;
        approvals = approvals && dai.allowance(address(this), treasury) == type(uint256).max;
        approvals = approvals && pool.gDai().allowance(address(this), address(pool)) >= type(uint112).max;
        bool controllerSig = controller.delegated(msg.sender, address(this));
        bool poolSig = pool.delegated(msg.sender, address(this));
        return (approvals, controllerSig, poolSig);
    }

    /// @dev Set proxy approvals for `removeLiquidityEarlyDaiFixed` with a given pool.
    function removeLiquidityEarlyDaiFixedApprove(IPool pool) public {
        // Allow the Treasury to take dai for repaying
        if (dai.allowance(address(this), treasury) < type(uint256).max) dai.approve(treasury, type(uint256).max);

        // Allow pool to take gDai for trading
        if (pool.gDai().allowance(address(this), address(pool)) < type(uint112).max) pool.gDai().approve(address(pool), type(uint256).max);
    }

    /// @dev Burns tokens and repays debt with proceedings. Sells any excess gDai for Dai, then returns all Dai, and all unlocked Chai.
    /// @param poolTokens amount of pool tokens to burn. 
    /// @param minimumGDaiPrice minimum Dai/gDai price to be accepted when internally selling gDai.
    /// @param controllerSig packed signature for delegation of this proxy in the controller. Ignored if '0x'.
    /// @param poolSig packed signature for delegation of this proxy in a pool. Ignored if '0x'.
    function removeLiquidityEarlyDaiFixedWithSignature(
        IPool pool,
        uint256 poolTokens,
        uint256 minimumGDaiPrice,
        bytes memory controllerSig,
        bytes memory poolSig
    ) public {
        removeLiquidityEarlyDaiFixedApprove(pool);
        if (controllerSig.length > 0) controller.addDelegatePacked(controllerSig);
        if (poolSig.length > 0) pool.addDelegatePacked(poolSig);
        removeLiquidityEarlyDaiFixed(pool, poolTokens, minimumGDaiPrice);
    }

    /// @dev Determine whether all approvals and signatures are in place for `removeLiquidityMature`.
    /// If `return[0]` is `false`, calling `removeLiquidityMatureCheck` will set the proxy approvals.
    /// If `return[1]` is `false`, `removeLiquidityMatureCheck` must be called with a controller signature.
    /// If `return[2]` is `false`, `removeLiquidityMatureCheck` must be called with a pool signature.
    /// If `return` is `(true, true, true)`, `removeLiquidityMature` won't fail because of missing approvals or signatures.
    function removeLiquidityMatureCheck(IPool pool) public view returns (bool, bool, bool) {
        bool approvals = dai.allowance(address(this), treasury) == type(uint256).max;
        bool controllerSig = controller.delegated(msg.sender, address(this));
        bool poolSig = pool.delegated(msg.sender, address(this));
        return (approvals, controllerSig, poolSig);
    }

    /// @dev Set proxy approvals for `removeLiquidityMature`.
    function removeLiquidityMatureApprove() public {
        // Allow the Treasury to take dai for repaying
        if (dai.allowance(address(this), treasury) < type(uint256).max) dai.approve(treasury, type(uint256).max);
    }

    /// @dev Burns tokens and repays gDai debt after Maturity.
    /// @param poolTokens amount of pool tokens to burn.
    /// @param controllerSig packed signature for delegation of this proxy in the controller. Ignored if '0x'.
    /// @param poolSig packed signature for delegation of this proxy in a pool. Ignored if '0x'.
    function removeLiquidityMatureWithSignature(
        IPool pool,
        uint256 poolTokens,
        bytes memory controllerSig,
        bytes memory poolSig
    ) external {
        removeLiquidityMatureApprove();
        if (controllerSig.length > 0) controller.addDelegatePacked(controllerSig);
        if (poolSig.length > 0) pool.addDelegatePacked(poolSig);
        removeLiquidityMature(pool, poolTokens);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.6.10;
import "@openzeppelin/contracts/math/SafeMath.sol";


/// @dev Implements simple fixed point math mul and div operations for 27 decimals.
contract DecimalMath {
    using SafeMath for uint256;

    uint256 constant public UNIT = 1e27;

    /// @dev Multiplies x and y, assuming they are both fixed point with 27 digits.
    function muld(uint256 x, uint256 y) internal pure returns (uint256) {
        return x.mul(y).div(UNIT);
    }

    /// @dev Divides x between y, assuming they are both fixed point with 27 digits.
    function divd(uint256 x, uint256 y) internal pure returns (uint256) {
        return x.mul(UNIT).div(y);
    }

    /// @dev Multiplies x and y, rounding up to the closest representable number.
    /// Assumes x and y are both fixed point with `decimals` digits.
    function muldrup(uint256 x, uint256 y) internal pure returns (uint256)
    {
        uint256 z = x.mul(y);
        return z.mod(UNIT) == 0 ? z.div(UNIT) : z.div(UNIT).add(1);
    }

    /// @dev Divides x between y, rounding up to the closest representable number.
    /// Assumes x and y are both fixed point with `decimals` digits.
    function divdrup(uint256 x, uint256 y) internal pure returns (uint256)
    {
        uint256 z = x.mul(UNIT);
        return z.mod(y) == 0 ? z.div(y) : z.div(y).add(1);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.6.10;


library SafeCast {
    /// @dev Safe casting from uint256 to uint128
    function toUint128(uint256 x) internal pure returns(uint128) {
        require(
            x <= type(uint128).max,
            "SafeCast: Cast overflow"
        );
        return uint128(x);
    }

    /// @dev Safe casting from uint256 to int256
    function toInt256(uint256 x) internal pure returns(int256) {
        require(
            x <= uint256(type(int256).max),
            "SafeCast: Cast overflow"
        );
        return int256(x);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.6.10;

import "../interfaces/IERC2612.sol";
import "../interfaces/IDai.sol";
import "../interfaces/IDelegable.sol";

/// @dev This library encapsulates methods obtain authorizations using packed signatures
library YieldAuth {

    /// @dev Unpack r, s and v from a `bytes` signature.
    /// @param signature A packed signature.
    function unpack(bytes memory signature) internal pure returns (bytes32 r, bytes32 s, uint8 v) {
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }
    }

    /// @dev Use a packed `signature` to add this contract as a delegate of caller on the `target` contract.
    /// @param target The contract to add delegation to.
    /// @param signature A packed signature.
    function addDelegatePacked(IDelegable target, bytes memory signature) internal {
        bytes32 r;
        bytes32 s;
        uint8 v;

        (r, s, v) = unpack(signature);
        target.addDelegateBySignature(msg.sender, address(this), type(uint256).max, v, r, s);
    }

    /// @dev Use a packed `signature` to add this contract as a delegate of caller on the `target` contract.
    /// @param target The contract to add delegation to.
    /// @param user The user delegating access.
    /// @param delegate The address obtaining access.
    /// @param signature A packed signature.
    function addDelegatePacked(IDelegable target, address user, address delegate, bytes memory signature) internal {
        bytes32 r;
        bytes32 s;
        uint8 v;

        (r, s, v) = unpack(signature);
        target.addDelegateBySignature(user, delegate, type(uint256).max, v, r, s);
    }

    /// @dev Use a packed `signature` to approve `spender` on the `dai` contract for the maximum amount.
    /// @param dai The Dai contract to add delegation to.
    /// @param spender The address obtaining an approval.
    /// @param signature A packed signature.
    function permitPackedDai(IDai dai, address spender, bytes memory signature) internal {
        bytes32 r;
        bytes32 s;
        uint8 v;

        (r, s, v) = unpack(signature);
        dai.permit(msg.sender, spender, dai.nonces(msg.sender), type(uint256).max, true, v, r, s);
    }

    /// @dev Use a packed `signature` to approve `spender` on the target IERC2612 `token` contract for the maximum amount.
    /// @param token The contract to add delegation to.
    /// @param spender The address obtaining an approval.
    /// @param signature A packed signature.
    function permitPacked(IERC2612 token, address spender, bytes memory signature) internal {
        bytes32 r;
        bytes32 s;
        uint8 v;

        (r, s, v) = unpack(signature);
        token.permit(msg.sender, spender, type(uint256).max, type(uint256).max, v, r, s);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.6.10;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IERC2612.sol";

/// @dev interface for the chai contract
/// Taken from https://github.com/makerdao/developerguides/blob/master/dai/dsr-integration-guide/dsr.sol
interface IChai is IERC20, IERC2612 {
    function move(address src, address dst, uint wad) external returns (bool);
    function dai(address usr) external returns (uint wad);
    function join(address dst, uint wad) external;
    function exit(address src, uint wad) external;
    function draw(address src, uint wad) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.6.10;

import "./IDelegable.sol";
import "./ITreasury.sol";
import "./IGDai.sol";

interface IController is IDelegable {
    function treasury() external view returns (ITreasury);
    function series(uint256) external view returns (IGDai);
    function seriesIterator(uint256) external view returns (uint256);
    function totalSeries() external view returns (uint256);
    function containsSeries(uint256) external view returns (bool);
    function posted(bytes32, address) external view returns (uint256);
    function locked(bytes32, address) external view returns (uint256);
    function debtGDai(bytes32, uint256, address) external view returns (uint256);
    function debtDai(bytes32, uint256, address) external view returns (uint256);
    function totalDebtDai(bytes32, address) external view returns (uint256);
    function isCollateralized(bytes32, address) external view returns (bool);
    function inDai(bytes32, uint256, uint256) external view returns (uint256);
    function inGDai(bytes32, uint256, uint256) external view returns (uint256);
    function erase(bytes32, address) external returns (uint256, uint256);
    function shutdown() external;
    function post(bytes32, address, address, uint256) external;
    function withdraw(bytes32, address, address, uint256) external;
    function borrow(bytes32, uint256, address, address, uint256) external;
    function repayGDai(bytes32, uint256, address, address, uint256) external returns (uint256);
    function repayDai(bytes32, uint256, address, address, uint256) external returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.6.10;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IDai is IERC20 { // Doesn't conform to IERC2612
    function nonces(address user) external view returns (uint256);
    function permit(address holder, address spender, uint256 nonce, uint256 expiry,
                    bool allowed, uint8 v, bytes32 r, bytes32 s) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.6.10;


/// @dev Interface to interact with the `Join.sol` contract from MakerDAO using Dai
interface IDaiJoin {
    function rely(address usr) external;
    function deny(address usr) external;
    function cage() external;
    function join(address usr, uint WAD) external;
    function exit(address usr, uint WAD) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.6.10;


interface IDelegable {
    function addDelegate(address) external;
    function addDelegateBySignature(address, address, uint, uint8, bytes32, bytes32) external;
    function delegated(address, address) external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-or-later
// Code adapted from https://github.com/OpenZeppelin/openzeppelin-contracts/pull/2237/
pragma solidity ^0.6.0;

/**
 * @dev Interface of the ERC2612 standard as defined in the EIP.
 *
 * Adds the {permit} method, which can be used to change one's
 * {IERC20-allowance} without having to send a transaction, by signing a
 * message. This allows users to spend tokens without having to hold Ether.
 *
 * See https://eips.ethereum.org/EIPS/eip-2612.
 */
interface IERC2612 {
    /**
     * @dev Sets `amount` as the allowance of `spender` over `owner`'s tokens,
     * given `owner`'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(address owner, address spender, uint256 amount, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;

    /**
     * @dev Returns the current ERC2612 nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.6.10;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IERC2612.sol";

interface IGDai is IERC20, IERC2612 {
    function isMature() external view returns(bool);
    function maturity() external view returns(uint);
    function chi0() external view returns(uint);
    function rate0() external view returns(uint);
    function chiGrowth() external view returns(uint);
    function rateGrowth() external view returns(uint);
    function mature() external;
    function unlocked() external view returns (uint);
    function mint(address, uint) external;
    function burn(address, uint) external;
    function flashMint(uint, bytes calldata) external;
    function redeem(address, address, uint256) external returns (uint256);
    // function transfer(address, uint) external returns (bool);
    // function transferFrom(address, address, uint) external returns (bool);
    // function approve(address, uint) external returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.6.10;


/// @dev Interface to interact with the `Join.sol` contract from MakerDAO using ERC20
interface IGemJoin {
    function rely(address usr) external;
    function deny(address usr) external;
    function cage() external;
    function join(address usr, uint WAD) external;
    function exit(address usr, uint WAD) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.6.10;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IDelegable.sol";
import "./IERC2612.sol";
import { IGDai } from "./IGDai.sol";

interface IPool is IDelegable, IERC20, IERC2612 {
    function maturity() external view returns(uint256);
    function dai() external view returns(IERC20);
    function gDai() external view returns(IGDai);
    function getDaiReserves() external view returns(uint128);
    function getGDaiReserves() external view returns(uint128);
    function sellDai(address from, address to, uint128 daiIn) external returns(uint128);
    function buyDai(address from, address to, uint128 daiOut) external returns(uint128);
    function sellGDai(address from, address to, uint128 gDaiIn) external returns(uint128);
    function buyGDai(address from, address to, uint128 gDaiOut) external returns(uint128);
    function sellDaiPreview(uint128 daiIn) external view returns(uint128);
    function buyDaiPreview(uint128 daiOut) external view returns(uint128);
    function sellGDaiPreview(uint128 gDaiIn) external view returns(uint128);
    function buyGDaiPreview(uint128 gDaiOut) external view returns(uint128);
    function mint(address from, address to, uint256 daiOffered) external returns (uint256);
    function burn(address from, address to, uint256 tokensBurned) external returns (uint256, uint256);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.6.10;


/// @dev interface for the pot contract from MakerDao
/// Taken from https://github.com/makerdao/developerguides/blob/master/dai/dsr-integration-guide/dsr.sol
interface IPot {
    function chi() external view returns (uint256);
    function pie(address) external view returns (uint256); // Not a function, but a public variable.
    function rho() external returns (uint256);
    function drip() external returns (uint256);
    function join(uint256) external;
    function exit(uint256) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.6.10;

import "./IVat.sol";
import "./IDai.sol";
import "./IWeth.sol";
import "./IGemJoin.sol";
import "./IDaiJoin.sol";
import "./IPot.sol";
import "./IChai.sol";

interface ITreasury {
    function debt() external view returns(uint256);
    function savings() external view returns(uint256);
    function pushDai(address user, uint256 dai) external;
    function pullDai(address user, uint256 dai) external;
    function pushChai(address user, uint256 chai) external;
    function pullChai(address user, uint256 chai) external;
    function pushWeth(address to, uint256 weth) external;
    function pullWeth(address to, uint256 weth) external;
    function shutdown() external;
    function live() external view returns(bool);

    function vat() external view returns (IVat);
    function weth() external view returns (IWeth);
    function dai() external view returns (IDai);
    function daiJoin() external view returns (IDaiJoin);
    function wethJoin() external view returns (IGemJoin);
    function pot() external view returns (IPot);
    function chai() external view returns (IChai);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.6.10;


/// @dev Interface to interact with the vat contract from MakerDAO
/// Taken from https://github.com/makerdao/developerguides/blob/master/devtools/working-with-dsproxy/working-with-dsproxy.md
interface IVat {
    function can(address, address) external view returns (uint);
    function wish(address, address) external view returns (uint);
    function hope(address) external;
    function nope(address) external;
    function live() external view returns (uint);
    function ilks(bytes32) external view returns (uint, uint, uint, uint, uint);
    function urns(bytes32, address) external view returns (uint, uint);
    function gem(bytes32, address) external view returns (uint);
    // function dai(address) external view returns (uint);
    function frob(bytes32, address, address, address, int, int) external;
    function fork(bytes32, address, address, int, int) external;
    function move(address, address, uint) external;
    function flux(bytes32, address, address, uint) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.6.10;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


interface IWeth is IERC20 {
    function deposit() external payable;
    function withdraw(uint) external;
}