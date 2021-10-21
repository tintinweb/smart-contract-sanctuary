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

import "./interfaces/IWeth.sol";
import "./interfaces/IDai.sol";
import "./interfaces/IGDai.sol";
import { ITreasury } from "./interfaces/ITreasury.sol";
import { IController } from "./interfaces/IController.sol";
import { IPool } from "./interfaces/IPool.sol";
import "./helpers/SafeCast.sol";
import { YieldAuth } from "./helpers/YieldAuth.sol";


contract BorrowProxy {
    using SafeCast for uint256;
    using YieldAuth for IDai;
    using YieldAuth for IGDai;
    using YieldAuth for IController;
    using YieldAuth for IPool;

    IWeth public immutable weth;
    IDai public immutable dai;
    IController public immutable controller;
    address public immutable treasury;

    bytes32 public constant WETH = "ETH-A";

    constructor(IController _controller) public {
        ITreasury _treasury = _controller.treasury();
        weth = _treasury.weth();
        dai = _treasury.dai();
        treasury = address(_treasury);
        controller = _controller;
    }

    /// @dev The WETH9 contract will send ether to BorrowProxy on `weth.withdraw` using this function.
    receive() external payable { }

    /// @dev Users use `post` in BorrowProxy to post ETH to the Controller (amount = msg.value), which will be converted to Weth here.
    /// @param to Yield Vault to deposit collateral in.
    function post(address to)
        external payable {
        // Approvals in the constructor don't work for contracts calling this via `addDelegatecall`
        if (weth.allowance(address(this), treasury) < type(uint256).max) weth.approve(treasury, type(uint256).max);

        weth.deposit{ value: msg.value }();
        controller.post(WETH, address(this), to, msg.value);
    }

    /// @dev Users wishing to withdraw their Weth as ETH from the Controller should use this function.
    /// Users must have called `controller.addDelegate(borrowProxy.address)` or `withdrawWithSignature` to authorize BorrowProxy to act in their behalf.
    /// @param to Wallet to send Eth to.
    /// @param amount Amount of weth to move.
    function withdraw(address payable to, uint256 amount)
        public {
        controller.withdraw(WETH, msg.sender, address(this), amount);
        weth.withdraw(amount);
        to.transfer(amount);
    }

    /// @dev Borrow gDai from Controller and sell it immediately for Dai, for a maximum gDai debt.
    /// Must have approved the operator with `controller.addDelegate(borrowProxy.address)` or with `borrowDaiForMaximumGDaiWithSignature`.
    /// Caller must have called `borrowDaiForMaximumGDaiWithSignature` at least once before to set proxy approvals.
    /// @param collateral Valid collateral type.
    /// @param maturity Maturity of an added series
    /// @param to Wallet to send the resulting Dai to.
    /// @param daiToBorrow Exact amount of Dai that should be obtained.
    /// @param maximumGDai Maximum amount of GDai to borrow.
    function borrowDaiForMaximumGDai(
        IPool pool,
        bytes32 collateral,
        uint256 maturity,
        address to,
        uint256 daiToBorrow,
        uint256 maximumGDai
    )
        public
        returns (uint256)
    {
        uint256 gDaiToBorrow = pool.buyDaiPreview(daiToBorrow.toUint128());
        require (gDaiToBorrow <= maximumGDai, "BorrowProxy: Too much gDai required");

        // The collateral for this borrow needs to have been posted beforehand
        controller.borrow(collateral, maturity, msg.sender, address(this), gDaiToBorrow);
        pool.buyDai(address(this), to, daiToBorrow.toUint128());

        return gDaiToBorrow;
    }

    /// @dev Repay an amount of gDai debt in Controller using a given amount of Dai exchanged for gDai at pool rates, with a minimum of gDai debt required to be paid.
    /// Must have approved the operator with `controller.addDelegate(borrowProxy.address)` or with `repayMinimumGDaiDebtForDaiWithSignature`.
    /// Must have approved the operator with `pool.addDelegate(borrowProxy.address)` or with `repayMinimumGDaiDebtForDaiWithSignature`.
    /// If `repaymentInDai` exceeds the existing debt, only the necessary Dai will be used.
    /// @param collateral Valid collateral type.
    /// @param maturity Maturity of an added series
    /// @param to Yield Vault to repay gDai debt for.
    /// @param minimumGDaiRepayment Minimum amount of gDai debt to repay.
    /// @param repaymentInDai Exact amount of Dai that should be spent on the repayment.
    function repayMinimumGDaiDebtForDai(
        IPool pool,
        bytes32 collateral,
        uint256 maturity,
        address to,
        uint256 minimumGDaiRepayment,
        uint256 repaymentInDai
    )
        public
        returns (uint256)
    {
        uint256 gDaiRepayment = pool.sellDaiPreview(repaymentInDai.toUint128());
        uint256 gDaiDebt = controller.debtGDai(collateral, maturity, to);
        if(gDaiRepayment <= gDaiDebt) { // Sell no more Dai than needed to cancel all the debt
            pool.sellDai(msg.sender, address(this), repaymentInDai.toUint128());
        } else { // If we have too much Dai, then don't sell it all and buy the exact amount of gDai needed instead.
            pool.buyGDai(msg.sender, address(this), gDaiDebt.toUint128());
            gDaiRepayment = gDaiDebt;
        }
        require (gDaiRepayment >= minimumGDaiRepayment, "BorrowProxy: Not enough gDai debt repaid");
        controller.repayGDai(collateral, maturity, address(this), to, gDaiRepayment);

        return gDaiRepayment;
    }

    /// @dev Sell gDai for Dai
    /// Caller must have approved the gDai transfer with `gDai.approve(gDaiIn)` or with `sellGDaiWithSignature`.
    /// Caller must have approved the proxy using`pool.addDelegate(borrowProxy)` or with `sellGDaiWithSignature`.
    /// @param to Wallet receiving the dai being bought
    /// @param gDaiIn Amount of gDai being sold
    /// @param minDaiOut Minimum amount of dai being bought
    function sellGDai(IPool pool, address to, uint128 gDaiIn, uint128 minDaiOut)
        public
        returns(uint256)
    {
        uint256 daiOut = pool.sellGDai(msg.sender, to, gDaiIn);
        require(
            daiOut >= minDaiOut,
            "BorrowProxy: Limit not reached"
        );
        return daiOut;
    }

    /// @dev Buy gDai with Dai
    /// Caller must have approved the dai transfer with `dai.approve(maxDaiIn)` or with `sellDaiWithSignature`.
    /// Caller must have approved the proxy using`pool.addDelegate(borrowProxy)` or with `sellDaiWithSignature`.
    /// @param to Wallet receiving the gDai being bought
    /// @param gDaiOut Amount of gDai being bought
    /// @param maxDaiIn Maximum amount of Dai being paid for the gDai
    function buyGDai(IPool pool, address to, uint128 gDaiOut, uint128 maxDaiIn)
        public
        returns(uint256)
    {
        uint256 daiIn = pool.buyGDai(msg.sender, to, gDaiOut);
        require(
            daiIn <= maxDaiIn,
            "BorrowProxy: Limit exceeded"
        );
        return daiIn;
    }

    /// @dev Sell Dai for gDai
    /// Caller must have approved the dai transfer with `dai.approve(daiIn)` or with `sellDaiWithSignature`.
    /// Caller must have approved the proxy using`pool.addDelegate(borrowProxy)` or with `sellDaiWithSignature`.
    /// @param to Wallet receiving the gDai being bought
    /// @param daiIn Amount of dai being sold
    /// @param minGDaiOut Minimum amount of gDai being bought
    function sellDai(IPool pool, address to, uint128 daiIn, uint128 minGDaiOut)
        public
        returns(uint256)
    {
        uint256 gDaiOut = pool.sellDai(msg.sender, to, daiIn);
        require(
            gDaiOut >= minGDaiOut,
            "BorrowProxy: Limit not reached"
        );
        return gDaiOut;
    }

    /// @dev Buy Dai for gDai
    /// Caller must have approved the gDai transfer with `gDai.approve(maxGDaiIn)` or with `buyDaiWithSignature`.
    /// Caller must have approved the proxy using`pool.addDelegate(borrowProxy)` or with `buyDaiWithSignature`.
    /// @param to Wallet receiving the dai being bought
    /// @param daiOut Amount of dai being bought
    /// @param maxGDaiIn Maximum amount of gDai being sold
    function buyDai(IPool pool, address to, uint128 daiOut, uint128 maxGDaiIn)
        public
        returns(uint256)
    {
        uint256 gDaiIn = pool.buyDai(msg.sender, to, daiOut);
        require(
            maxGDaiIn >= gDaiIn,
            "BorrowProxy: Limit exceeded"
        );
        return gDaiIn;
    }

    /// --------------------------------------------------
    /// Signature method wrappers
    /// --------------------------------------------------

    /// @dev Determine whether all approvals and signatures are in place for `withdrawWithSignature`.
    /// `return[0]` is always `true`, meaning that no proxy approvals are ever needed.
    /// If `return[1]` is `false`, `withdrawWithSignature` must be called with a controller signature.
    /// If `return` is `(true, true)`, `withdrawWithSignature` won't fail because of missing approvals or signatures.
    function withdrawCheck() public view returns (bool, bool) {
        bool approvals = true; // sellGDai doesn't need proxy approvals
        bool controllerSig = controller.delegated(msg.sender, address(this));
        return (approvals, controllerSig);
    }

    /// @dev Users wishing to withdraw their Weth as ETH from the Controller should use this function.
    /// @param to Wallet to send Eth to.
    /// @param amount Amount of weth to move.
    /// @param controllerSig packed signature for delegation of this proxy in the controller. Ignored if '0x'.
    function withdrawWithSignature(address payable to, uint256 amount, bytes memory controllerSig)
        public {
        if (controllerSig.length > 0) controller.addDelegatePacked(controllerSig);
        withdraw(to, amount);
    }

    /// @dev Determine whether all approvals and signatures are in place for `borrowDaiForMaximumGDai` with a given pool.
    /// If `return[0]` is `false`, calling `borrowDaiForMaximumGDaiWithSignature` will set the approvals.
    /// If `return[1]` is `false`, `borrowDaiForMaximumGDaiWithSignature` must be called with a controller signature
    /// If `return` is `(true, true)`, `borrowDaiForMaximumGDai` won't fail because of missing approvals or signatures.
    function borrowDaiForMaximumGDaiCheck(IPool pool) public view returns (bool, bool) {
        bool approvals = pool.gDai().allowance(address(this), address(pool)) >= type(uint112).max;
        bool controllerSig = controller.delegated(msg.sender, address(this));
        return (approvals, controllerSig);
    }

    /// @dev Set proxy approvals for `borrowDaiForMaximumGDai` with a given pool.
    function borrowDaiForMaximumGDaiApprove(IPool pool) public {
        // allow the pool to pull GDai/dai from us for LPing
        if (pool.gDai().allowance(address(this), address(pool)) < type(uint112).max)
            pool.gDai().approve(address(pool), type(uint256).max);
    }

    /// @dev Borrow gDai from Controller and sell it immediately for Dai, for a maximum gDai debt.
    /// @param collateral Valid collateral type.
    /// @param maturity Maturity of an added series
    /// @param to Wallet to send the resulting Dai to.
    /// @param daiToBorrow Exact amount of Dai that should be obtained.
    /// @param maximumGDai Maximum amount of GDai to borrow.
    /// @param controllerSig packed signature for delegation of this proxy in the controller. Ignored if '0x'.
    function borrowDaiForMaximumGDaiWithSignature(
        IPool pool,
        bytes32 collateral,
        uint256 maturity,
        address to,
        uint256 daiToBorrow,
        uint256 maximumGDai,
        bytes memory controllerSig
    )
        public
        returns (uint256)
    {
        borrowDaiForMaximumGDaiApprove(pool);
        if (controllerSig.length > 0) controller.addDelegatePacked(controllerSig);
        return borrowDaiForMaximumGDai(pool, collateral, maturity, to, daiToBorrow, maximumGDai);
    }

    /// @dev Determine whether all approvals and signatures are in place for `repayDaiWithSignature`.
    /// `return[0]` is always `true`, meaning that no proxy approvals are ever needed.
    /// If `return[1]` is `false`, `repayDaiWithSignature` must be called with a dai permit signature.
    /// If `return[2]` is `false`, `repayDaiWithSignature` must be called with a controller signature.
    /// If `return` is `(true, true, true)`, `repayDaiWithSignature` won't fail because of missing approvals or signatures.
    /// If `return` is `(true, true, any)`, `controller.repayDai` can be called directly and won't fail because of missing approvals or signatures.
    function repayDaiCheck() public view returns (bool, bool, bool) {
        bool approvals = true; // repayDai doesn't need proxy approvals
        bool daiSig = dai.allowance(msg.sender, treasury) == type(uint256).max;
        bool controllerSig = controller.delegated(msg.sender, address(this));
        return (approvals, daiSig, controllerSig);
    }

    /// @dev Burns Dai from caller to repay debt in a Yield Vault.
    /// User debt is decreased for the given collateral and gDai series, in Yield vault `to`.
    /// The amount of debt repaid changes according to series maturity and MakerDAO rate and chi, depending on collateral type.
    /// `A signature is provided as a parameter to this function, so that `dai.approve()` doesn't need to be called.
    /// @param collateral Valid collateral type.
    /// @param maturity Maturity of an added series
    /// @param to Yield vault to repay debt for.
    /// @param daiAmount Amount of Dai to use for debt repayment.
    /// @param daiSig packed signature for permit of dai transfers to this proxy. Ignored if '0x'.
    /// @param controllerSig packed signature for delegation of this proxy in the controller. Ignored if '0x'.
    function repayDaiWithSignature(
        bytes32 collateral,
        uint256 maturity,
        address to,
        uint256 daiAmount,
        bytes memory daiSig,
        bytes memory controllerSig
    )
        external
        returns(uint256)
    {
        if (daiSig.length > 0) dai.permitPackedDai(treasury, daiSig);
        if (controllerSig.length > 0) controller.addDelegatePacked(controllerSig);
        controller.repayDai(collateral, maturity, msg.sender, to, daiAmount);
    }

    /// @dev Set proxy approvals for `repayMinimumGDaiDebtForDai` with a given pool.
    function repayMinimumGDaiDebtForDaiApprove(IPool pool) public {
        // allow the treasury to pull GDai from us for repaying
        if (pool.gDai().allowance(address(this), treasury) < type(uint112).max)
            pool.gDai().approve(treasury, type(uint256).max);
    }

    /// @dev Determine whether all approvals and signatures are in place for `repayMinimumGDaiDebtForDai` with a given pool.
    /// If `return[0]` is `false`, calling `repayMinimumGDaiDebtForDaiWithSignature` will set the approvals.
    /// If `return[1]` is `false`, `repayMinimumGDaiDebtForDaiWithSignature` must be called with a controller signature
    /// If `return[2]` is `false`, `repayMinimumGDaiDebtForDaiWithSignature` must be called with a pool signature
    /// If `return` is `(true, true, true)`, `repayMinimumGDaiDebtForDai` won't fail because of missing approvals or signatures.
    function repayMinimumGDaiDebtForDaiCheck(IPool pool) public view returns (bool, bool, bool) {
        bool approvals = pool.gDai().allowance(address(this), treasury) >= type(uint112).max;
        bool controllerSig = controller.delegated(msg.sender, address(this));
        bool poolSig = pool.delegated(msg.sender, address(this));
        return (approvals, controllerSig, poolSig);
    }

    /// @dev Repay an amount of gDai debt in Controller using a given amount of Dai exchanged for gDai at pool rates, with a minimum of gDai debt required to be paid.
    /// Must have approved the operator with `controller.addDelegate(borrowProxy.address)` or with `repayMinimumGDaiDebtForDaiWithSignature`.
    /// Must have approved the operator with `pool.addDelegate(borrowProxy.address)` or with `repayMinimumGDaiDebtForDaiWithSignature`.
    /// If `repaymentInDai` exceeds the existing debt, only the necessary Dai will be used.
    /// @param collateral Valid collateral type.
    /// @param maturity Maturity of an added series
    /// @param to Yield Vault to repay gDai debt for.
    /// @param minimumGDaiRepayment Minimum amount of gDai debt to repay.
    /// @param repaymentInDai Exact amount of Dai that should be spent on the repayment.
    /// @param controllerSig packed signature for delegation of this proxy in the controller. Ignored if '0x'.
    /// @param poolSig packed signature for delegation of this proxy in a pool. Ignored if '0x'.
    function repayMinimumGDaiDebtForDaiWithSignature(
        IPool pool,
        bytes32 collateral,
        uint256 maturity,
        address to,
        uint256 minimumGDaiRepayment,
        uint256 repaymentInDai,
        bytes memory controllerSig,
        bytes memory poolSig
    )
        public
        returns (uint256)
    {
        repayMinimumGDaiDebtForDaiApprove(pool);
        if (controllerSig.length > 0) controller.addDelegatePacked(controllerSig);
        if (poolSig.length > 0) pool.addDelegatePacked(poolSig);
        return repayMinimumGDaiDebtForDai(pool, collateral, maturity, to, minimumGDaiRepayment, repaymentInDai);
    }

    /// @dev Determine whether all approvals and signatures are in place for `sellGDai`.
    /// `return[0]` is always `true`, meaning that no proxy approvals are ever needed.
    /// If `return[1]` is `false`, `sellGDaiWithSignature` must be called with a gDai permit signature.
    /// If `return[2]` is `false`, `sellGDaiWithSignature` must be called with a pool signature.
    /// If `return` is `(true, true, true)`, `sellGDai` won't fail because of missing approvals or signatures.
    function sellGDaiCheck(IPool pool) public view returns (bool, bool, bool) {
        bool approvals = true; // sellGDai doesn't need proxy approvals
        bool gDaiSig = pool.gDai().allowance(msg.sender, address(pool)) >= type(uint112).max;
        bool poolSig = pool.delegated(msg.sender, address(this));
        return (approvals, gDaiSig, poolSig);
    }

    /// @dev Sell gDai for Dai
    /// @param to Wallet receiving the dai being bought
    /// @param gDaiIn Amount of gDai being sold
    /// @param minDaiOut Minimum amount of dai being bought
    /// @param gDaiSig packed signature for approving gDai transfers to a pool. Ignored if '0x'.
    /// @param poolSig packed signature for delegation of this proxy in a pool. Ignored if '0x'.
    function sellGDaiWithSignature(
        IPool pool,
        address to,
        uint128 gDaiIn,
        uint128 minDaiOut,
        bytes memory gDaiSig,
        bytes memory poolSig
    )
        public
        returns(uint256)
    {
        if (gDaiSig.length > 0) pool.gDai().permitPacked(address(pool), gDaiSig);
        if (poolSig.length > 0) pool.addDelegatePacked(poolSig);
        return sellGDai(pool, to, gDaiIn, minDaiOut);
    }

    /// @dev Determine whether all approvals and signatures are in place for `buyGDai`.
    /// `return[0]` is always `true`, meaning that no proxy approvals are ever needed.
    /// If `return[1]` is `false`, `buyGDaiWithSignature` must be called with a dai permit signature.
    /// If `return[2]` is `false`, `buyGDaiWithSignature` must be called with a pool signature.
    /// If `return` is `(true, true, true)`, `sellDai` won't fail because of missing approvals or signatures.
    function buyGDaiCheck(IPool pool) public view returns (bool, bool, bool) {
        bool approvals = true; // buyGDai doesn't need proxy approvals
        bool daiSig = dai.allowance(msg.sender, address(pool)) == type(uint256).max;
        bool poolSig = pool.delegated(msg.sender, address(this));
        return (approvals, daiSig, poolSig);
    }

    /// @dev Buy GDai with Dai
    /// @param to Wallet receiving the gDai being bought
    /// @param gDaiOut Amount of gDai being bought
    /// @param maxDaiIn Maximum amount of Dai to pay
    /// @param daiSig packed signature for approving Dai transfers to a pool. Ignored if '0x'.
    /// @param poolSig packed signature for delegation of this proxy in a pool. Ignored if '0x'.
    function buyGDaiWithSignature(
        IPool pool,
        address to,
        uint128 gDaiOut,
        uint128 maxDaiIn,
        bytes memory daiSig,
        bytes memory poolSig
    )
        external
        returns(uint256)
    {
        if (daiSig.length > 0) dai.permitPackedDai(address(pool), daiSig);
        if (poolSig.length > 0) pool.addDelegatePacked(poolSig);
        return buyGDai(pool, to, gDaiOut, maxDaiIn);
    }

    /// @dev Determine whether all approvals and signatures are in place for `sellDai`.
    /// `return[0]` is always `true`, meaning that no proxy approvals are ever needed.
    /// If `return[1]` is `false`, `buyDaiWithSignature` must be called with a gDai permit signature.
    /// If `return[2]` is `false`, `buyDaiWithSignature` must be called with a pool signature.
    /// If `return` is `(true, true, true)`, `sellDai` won't fail because of missing approvals or signatures.
    function sellDaiCheck(IPool pool) public view returns (bool, bool, bool) {
        return buyGDaiCheck(pool);
    }

    /// @dev Sell Dai for gDai
    /// @param to Wallet receiving the gDai being bought
    /// @param daiIn Amount of dai being sold
    /// @param minGDaiOut Minimum amount of gDai being bought
    /// @param daiSig packed signature for approving Dai transfers to a pool. Ignored if '0x'.
    /// @param poolSig packed signature for delegation of this proxy in a pool. Ignored if '0x'.
    function sellDaiWithSignature(
        IPool pool,
        address to,
        uint128 daiIn,
        uint128 minGDaiOut,
        bytes memory daiSig,
        bytes memory poolSig
    )
        external
        returns(uint256)
    {
        if (daiSig.length > 0) dai.permitPackedDai(address(pool), daiSig);
        if (poolSig.length > 0) pool.addDelegatePacked(poolSig);
        return sellDai(pool, to, daiIn, minGDaiOut);
    }

    /// @dev Determine whether all approvals and signatures are in place for `buyDai`.
    /// `return[0]` is always `true`, meaning that no proxy approvals are ever needed.
    /// If `return[1]` is `false`, `buyDaiWithSignature` must be called with a gDai permit signature.
    /// If `return[2]` is `false`, `buyDaiWithSignature` must be called with a pool signature.
    /// If `return` is `(true, true, true)`, `buyDai` won't fail because of missing approvals or signatures.
    function buyDaiCheck(IPool pool) public view returns (bool, bool, bool) {
        return sellGDaiCheck(pool);
    }

    /// @dev Buy Dai for gDai
    /// @param to Wallet receiving the dai being bought
    /// @param daiOut Amount of dai being bought
    /// @param maxGDaiIn Maximum amount of gDai being sold
    /// @param gDaiSig packed signature for approving gDai transfers to a pool. Ignored if '0x'.
    /// @param poolSig packed signature for delegation of this proxy in a pool. Ignored if '0x'.
    function buyDaiWithSignature(
        IPool pool,
        address to,
        uint128 daiOut,
        uint128 maxGDaiIn,
        bytes memory gDaiSig,
        bytes memory poolSig
    )
        external
        returns(uint256)
    {
        if (gDaiSig.length > 0) pool.gDai().permitPacked(address(pool), gDaiSig);
        if (poolSig.length > 0) pool.addDelegatePacked(poolSig);
        return buyDai(pool, to, daiOut, maxGDaiIn);
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