// SPDX-License-Identifier: No License

pragma solidity ^0.8.0;

import "./interfaces/IProtocol.sol";
import "./interfaces/IFlashBorrower.sol";
import "./interfaces/IERC3156FlashLender.sol";
import "./interfaces/ICover.sol";
import "./interfaces/IBPool.sol";
import "./ERC20/IERC20.sol";
import "./ERC20/IYERC20.sol";
import "./ERC20/SafeERC20.sol";
import "./utils/Ownable.sol";

/**
 * @title Cover FlashBorrower
 * @author alan
 */
contract CoverFlashBorrower is Ownable, IFlashBorrower {
    using SafeERC20 for IERC20;

    IERC3156FlashLender public flashLender;
    IERC20 public constant dai = IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);
    IYERC20 public constant ydai = IYERC20(0x16de59092dAE5CcF4A1E6439D611fd0653f0Bd01);

    modifier onlySupportedCollaterals(address _collateral) {
        require(_collateral == address(dai) || _collateral == address(ydai), "only supports DAI and yDAI collaterals");
        _;
    }
    
    constructor (IERC3156FlashLender _flashLender) {
        flashLender = _flashLender;
    }

    /**
     * @dev Receive a flash loan.
     * @param initiator The initiator of the loan.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @param fee The additional amount of tokens to repay.
     * @param data Arbitrary data structure, intended to contain user-defined parameters.
     * @return The keccak256 hash of "ERC3156FlashBorrower.onFlashLoan"
     */
    function onFlashLoan(
        address initiator, 
        address token, 
        uint256 amount, 
        uint256 fee, 
        bytes calldata data
    ) external override returns(bytes32) {
        require(msg.sender == address(flashLender), "CoverFlashBorrower: Untrusted lender");
        require(initiator == address(this), "CoverFlashBorrower: Untrusted loan initiator");
        require(token == address(dai), "!dai"); // For v1, can only flashloan DAI
        uint256 amountOwed = amount + fee;
        FlashLoanData memory flashLoanData = abi.decode(data, (FlashLoanData));
        if (flashLoanData.isBuy) {
            _onFlashLoanBuyClaim(flashLoanData, amount, amountOwed);
        } else {
            _onFlashLoanSellClaim(flashLoanData, amount, amountOwed);
        }
        return keccak256("ERC3156FlashBorrower.onFlashLoan");
    }

    /**
     * @dev Flash loan the amount of collateral needed to mint `_amountCovTokens` covTokens
     * - If collateral is yDAI, `_amountCovTokens` is scaled by current price of yDAI to flash borrow enough DAI
     */
    function flashBuyClaim(
        IBPool _bpool,
        IProtocol _protocol, 
        address _collateral, 
        uint48 _timestamp, 
        uint256 _amountToBuy, 
        uint256 _maxAmountToSpend
    ) external override onlySupportedCollaterals(_collateral) {
        bytes memory data = abi.encode(FlashLoanData({
            isBuy: true,
            bpool: _bpool,
            protocol: _protocol,
            caller: msg.sender,
            collateral: _collateral,
            timestamp: _timestamp,
            amount: _amountToBuy,
            limit: _maxAmountToSpend
        }));
        uint256 amountDaiNeeded;
        if (_collateral == address(dai)) {
            amountDaiNeeded = _amountToBuy;
        } else if (_collateral == address(ydai)) {
            amountDaiNeeded = _amountToBuy * ydai.getPricePerFullShare();
        }
        require(amountDaiNeeded <= flashLender.maxFlashAmount(address(dai)), "_amount > lender reserves");
        uint256 _allowance = dai.allowance(address(this), address(flashLender));
        uint256 _fee = flashLender.flashFee(address(dai), amountDaiNeeded);
        uint256 _repayment = amountDaiNeeded + _fee;
        dai.approve(address(flashLender), _allowance + _repayment);
        flashLender.flashLoan(address(this), address(dai), amountDaiNeeded, data);
    }

    /**
     * @dev Flash loan the amount of DAI needed to buy enough NOCLAIM to redeem with CLAIM tokens
     */
    function flashSellClaim(
        IBPool _bpool,
        IProtocol _protocol, 
        address _collateral, 
        uint48 _timestamp, 
        uint256 _amountToSell, 
        uint256 _minAmountToReturn
    ) external override onlySupportedCollaterals(_collateral) {
        bytes memory data = abi.encode(FlashLoanData({
            isBuy: false,
            bpool: _bpool,
            protocol: _protocol,
            caller: msg.sender,
            collateral: _collateral,
            timestamp: _timestamp,
            amount: _amountToSell,
            limit: _minAmountToReturn
        }));
        (, IERC20 noclaimToken) = _getCovTokenAddresses(_protocol, _collateral, _timestamp);
        uint256 amountDaiNeeded = _calcInGivenOut(_bpool, address(dai), address(noclaimToken), _amountToSell);
        require(amountDaiNeeded <= flashLender.maxFlashAmount(address(dai)), "_amount > lender reserves");
        uint256 _allowance = dai.allowance(address(this), address(flashLender));
        uint256 _fee = flashLender.flashFee(address(dai), amountDaiNeeded);
        uint256 _repayment = amountDaiNeeded + _fee;
        dai.approve(address(flashLender), _allowance + _repayment);
        flashLender.flashLoan(address(this), address(dai), amountDaiNeeded, data);
    }

    function setFlashLender(address _flashLender) external override onlyOwner {
        require(_flashLender != address(0), "_flashLender is 0");
        flashLender = IERC3156FlashLender(_flashLender);
    }

    /// @notice Tokens that are accidentally sent to this contract can be recovered
    function collect(IERC20 _token) external override onlyOwner {
        uint256 balance = _token.balanceOf(address(this));
        require(balance > 0, "_token balance is 0");
        _token.transfer(msg.sender, balance);
    }

    function getBuyClaimCost(
        IBPool _bpool, 
        IProtocol _protocol, 
        address _collateral, 
        uint48 _timestamp, 
        uint256 _amountToBuy
    ) external override view onlySupportedCollaterals(_collateral) returns (uint256 totalCost) {
        uint256 amountDaiNeeded = _amountToBuy;
        if (_collateral == address(ydai)) {
            amountDaiNeeded = amountDaiNeeded * ydai.getPricePerFullShare();
        }
        uint256 flashFee = flashLender.flashFee(address(dai), amountDaiNeeded);
        uint256 daiReceivedFromSwap;
        {
            (, IERC20 noclaimToken) = _getCovTokenAddresses(_protocol, _collateral, _timestamp);
            daiReceivedFromSwap = _calcOutGivenIn(_bpool, address(noclaimToken), _amountToBuy, address(dai));
        }
        totalCost = amountDaiNeeded - daiReceivedFromSwap + flashFee;
    }

    function getSellClaimReturn(
        IBPool _bpool, 
        IProtocol _protocol, 
        address _collateral, 
        uint48 _timestamp, 
        uint256 _amountToSell,
        uint256 _redeemFeeNumerator
    ) external override view onlySupportedCollaterals(_collateral) returns (uint256 totalReturn) {
        (, IERC20 noclaimToken) = _getCovTokenAddresses(_protocol, _collateral, _timestamp);
        uint256 amountDaiNeeded = _calcInGivenOut(_bpool, address(dai), address(noclaimToken), _amountToSell);
        uint256 flashFee = flashLender.flashFee(address(dai), amountDaiNeeded);
        uint256 daiReceivedFromRedeem;
        if (_collateral == address(dai)) {
            daiReceivedFromRedeem = _amountToSell;
        } else if (_collateral == address(ydai)) {
            // Adjust for price of yDAI
            daiReceivedFromRedeem = _amountToSell * ydai.getPricePerFullShare();
        }
        // Adjust for redemption fee
        daiReceivedFromRedeem = daiReceivedFromRedeem * (10000 - _redeemFeeNumerator) / 10000;
        totalReturn = daiReceivedFromRedeem - amountDaiNeeded - flashFee;
    }

    /**
     * - If collateral is yDAI, wrap borrowed DAI
     * - Deposit collateral for covTokens
     * - Sell NOCLAIM tokens on Balancer to receive DAI
     * - Calculate amount user needs to pay to repay loan + slippage + fee
     * - Send minted CLAIM tokens to user
     */
    function _onFlashLoanBuyClaim(FlashLoanData memory data, uint256 amount, uint256 amountOwed) internal {
        uint256 mintAmount;

        // Wrap DAI to yDAI if necessary
        if (data.collateral == address(dai)) {
            mintAmount = amount;
            _approve(dai, address(data.protocol), mintAmount);
        } else if (data.collateral == address(ydai)) {
            _approve(dai, address(ydai), amount);
            uint256 ydaiBalBefore = ydai.balanceOf(address(this));
            ydai.deposit(amount);
            mintAmount = ydai.balanceOf(address(this)) - ydaiBalBefore;
            _approve(ydai, address(data.protocol), mintAmount);
        }

        // Mint claim and NOCLAIM tokens using collateral
        data.protocol.addCover(data.collateral, data.timestamp, mintAmount);
        (IERC20 claimToken, IERC20 noclaimToken) = _getCovTokenAddresses(
            data.protocol, 
            data.collateral, 
            data.timestamp
        );

        // Swap exact number of NOCLAIM tokens for DAI on Balancer
        _approve(noclaimToken, address(data.bpool), mintAmount);
        (uint256 daiReceived, ) = data.bpool.swapExactAmountIn(
            address(noclaimToken),
            mintAmount,
            address(dai),
            0,
            type(uint256).max
        );
        // Make sure cost is not greater than limit
        require(amountOwed - daiReceived <= data.limit, "cost exceeds limit");
        // User pays for slippage + flash loan fee
        dai.transferFrom(data.caller, address(this), amountOwed - daiReceived);
        // Resolve the flash loan
        dai.transfer(msg.sender, amountOwed);
        // Transfer claim tokens to caller
        claimToken.transfer(data.caller, mintAmount);
    }

    /**
     * - Sell DAI for NOCLAIM tokens
     * - Transfer CLAIM tokens from user to this contract
     * - Redeem CLAIM and NOCLAIM tokens for collateral
     * - If collateral is yDAI, unwrap to DAI
     * - Calculate amount user needs to repay loan + slippage + fee
     * - Send leftover DAI to user
     */
    function _onFlashLoanSellClaim(FlashLoanData memory data, uint256 amount, uint256 amountOwed) internal {
        uint256 daiAvailable = amount;
        _approve(dai, address(data.bpool), amount);
        (IERC20 claimToken, IERC20 noclaimToken) = _getCovTokenAddresses(
            data.protocol, 
            data.collateral, 
            data.timestamp
        );
        // Swap DAI for exact number of NOCLAIM tokens
        (uint256 daiSpent, ) = data.bpool.swapExactAmountOut(
            address(dai),
            amount,
            address(noclaimToken),
            data.amount,
            type(uint256).max
        );
        daiAvailable = daiAvailable - daiSpent;
        // Need an equal number of CLAIM and NOCLAIM tokens
        claimToken.transferFrom(data.caller, address(this), data.amount);
        
        // Redeem CLAIM and NOCLAIM tokens for collateral
        uint256 collateralBalBefore = IERC20(data.collateral).balanceOf(address(this));
        address cover = data.protocol.coverMap(data.collateral, data.timestamp);
        ICover(cover).redeemCollateral(data.amount);
        uint256 collateralReceived = IERC20(data.collateral).balanceOf(address(this)) - collateralBalBefore;
        // Unwrap yDAI to DAI if necessary
        if (data.collateral == address(dai)) {
            daiAvailable = daiAvailable + collateralReceived;
        } else if (data.collateral == address(ydai)) {
            _approve(ydai, address(ydai), collateralReceived);
            uint256 daiBalBefore = dai.balanceOf(address(this));
            ydai.withdraw(collateralReceived);
            uint256 daiReceived = dai.balanceOf(address(this)) - daiBalBefore;
            daiAvailable = daiAvailable + daiReceived;
        }
        // Make sure return is not less than limit
        require(daiAvailable - amountOwed >= data.limit, "returns are less than limit");
        // Resolve the flash loan
        dai.transfer(msg.sender, amountOwed);
        // Transfer leftover DAI to caller
        dai.transfer(data.caller, daiAvailable - amountOwed);
    }

    function _calcInGivenOut(IBPool _bpool, address _tokenIn, address _tokenOut, uint256 _tokenAmountOut) internal view returns (uint256 tokenAmountIn) {
        uint256 tokenBalanceIn = _bpool.getBalance(_tokenIn);
        uint256 tokenWeightIn = _bpool.getNormalizedWeight(_tokenIn);
        uint256 tokenBalanceOut = _bpool.getBalance(_tokenOut);
        uint256 tokenWeightOut = _bpool.getNormalizedWeight(_tokenOut);
        uint256 swapFee = _bpool.getSwapFee();

        tokenAmountIn = _bpool.calcInGivenOut(
            tokenBalanceIn,
            tokenWeightIn,
            tokenBalanceOut,
            tokenWeightOut,
            _tokenAmountOut,
            swapFee
        );
    }

    function _calcOutGivenIn(IBPool _bpool, address _tokenIn, uint256 _tokenAmountIn, address _tokenOut) internal view returns (uint256 tokenAmountOut) {
        uint256 tokenBalanceIn = _bpool.getBalance(_tokenIn);
        uint256 tokenWeightIn = _bpool.getNormalizedWeight(_tokenIn);
        uint256 tokenBalanceOut = _bpool.getBalance(_tokenOut);
        uint256 tokenWeightOut = _bpool.getNormalizedWeight(_tokenOut);
        uint256 swapFee = _bpool.getSwapFee();

        tokenAmountOut = _bpool.calcOutGivenIn(
            tokenBalanceIn,
            tokenWeightIn,
            tokenBalanceOut,
            tokenWeightOut,
            _tokenAmountIn,
            swapFee
        );
    } 

    function _getCovTokenAddresses(
        IProtocol _protocol, 
        address _collateral, 
        uint48 _timestamp
    ) internal view returns (IERC20 claimToken, IERC20 noclaimToken) {
        address cover = _protocol.coverMap(_collateral, _timestamp);
        claimToken = ICover(cover).claimCovToken();
        noclaimToken = ICover(cover).noclaimCovToken();
    }

    function _approve(IERC20 _token, address _spender, uint256 _amount) internal {
        if (_token.allowance(address(this), _spender) < _amount) {
            _token.approve(_spender, type(uint256).max);
        }
    }
}

// SPDX-License-Identifier: No License

pragma solidity ^0.8.0;

interface IProtocol {
  function coverMap(address _collateral, uint48 _expirationTimestamp) external view returns (address);
  function addCover(address _collateral, uint48 _timestamp, uint256 _amount) external returns (bool);
}

// SPDX-License-Identifier: No License

pragma solidity ^0.8.0;

import "./IERC3156FlashBorrower.sol";
import "./IProtocol.sol";
import "./ICover.sol";
import "./IBPool.sol";
import "../ERC20/IERC20.sol";

interface IFlashBorrower is IERC3156FlashBorrower {
    struct FlashLoanData {
        bool isBuy;
        IBPool bpool;
        IProtocol protocol;
        address caller;
        address collateral;
        uint48 timestamp;
        uint256 amount;
        uint256 limit;
    }

    function flashBuyClaim(
        IBPool _bpool,
        IProtocol _protocol, 
        address _collateral, 
        uint48 _timestamp, 
        uint256 _amountToBuy, 
        uint256 _maxAmountToSpend
    ) external;
    
    function flashSellClaim(
        IBPool _bpool,
        IProtocol _protocol, 
        address _collateral, 
        uint48 _timestamp, 
        uint256 _amountToSell, 
        uint256 _minAmountToReturn
    ) external;

    function getBuyClaimCost(
        IBPool _bpool, 
        IProtocol _protocol, 
        address _collateral, 
        uint48 _timestamp, 
        uint256 _amountToBuy
    ) external view returns (uint256 totalCost);

    function getSellClaimReturn(
        IBPool _bpool, 
        IProtocol _protocol, 
        address _collateral, 
        uint48 _timestamp, 
        uint256 _amountToSell,
        uint256 _redeemFeeNumerator
    ) external view returns (uint256 totalReturn);

    function setFlashLender(address _flashLender) external;
    function collect(IERC20 _token) external;
}

// SPDX-License-Identifier: No License

pragma solidity ^0.8.0;

interface IERC3156FlashLender {

    /**
     * @dev The amount of currency available to be lended.
     * @param token The loan currency.
     * @return The amount of `token` that can be borrowed.
     */
    function maxFlashAmount(
        address token
    ) external view returns (uint256);

    /**
     * @dev The fee to be charged for a given loan.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @return The amount of `token` to be charged for the loan, on top of the returned principal.
     */
    function flashFee(
        address token,
        uint256 amount
    ) external view returns (uint256);

    /**
     * @dev Initiate a flash loan.
     * @param receiver The receiver of the tokens in the loan, and the receiver of the callback.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @param data Arbitrary data structure, intended to contain user-defined parameters.
     */
    function flashLoan(
        address receiver,
        address token,
        uint256 amount,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: No License

pragma solidity ^0.8.0;

import "../ERC20/IERC20.sol";

interface ICover {
  function claimCovToken() external view returns (IERC20);
  function noclaimCovToken() external view returns (IERC20);
  function redeemCollateral(uint256 _amount) external;
}

// SPDX-License-Identifier: No License

pragma solidity ^0.8.0;

interface IBPool {
    function swapExactAmountIn(
        address tokenIn,
        uint256 tokenAmountIn,
        address tokenOut,
        uint256 minAmountOut,
        uint256 maxPrice
    ) external returns (uint256 tokenAmountOut, uint256 spotPriceAfter);

    function swapExactAmountOut(
        address tokenIn,
        uint256 maxAmountIn,
        address tokenOut,
        uint256 tokenAmountOut,
        uint256 maxPrice
    ) external returns (uint256 tokenAmountIn, uint256 spotPriceAfter);

    function calcOutGivenIn(
        uint256 tokenBalanceIn,
        uint256 tokenWeightIn,
        uint256 tokenBalanceOut,
        uint256 tokenWeightOut,
        uint256 tokenAmountIn,
        uint256 swapFee
    ) external view returns (uint256 tokenAmountOut);

    function calcInGivenOut(
        uint256 tokenBalanceIn,
        uint256 tokenWeightIn,
        uint256 tokenBalanceOut,
        uint256 tokenWeightOut,
        uint256 tokenAmountOut,
        uint256 swapFee
    ) external view returns (uint256 tokenAmountIn);

    function getNormalizedWeight(address token) external view returns (uint256);
    function getBalance(address token) external view returns (uint256);
    function getSwapFee() external view returns (uint256);
}

// SPDX-License-Identifier: No License

pragma solidity ^0.8.0;

/**
 * @title Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: No License

pragma solidity ^0.8.0;

import "./IERC20.sol";

interface IYERC20 is IERC20 {
    function deposit(uint256 _amount) external;
    function withdraw(uint256 _shares) external;
    function getPricePerFullShare() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "../utils/Address.sol";

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
        uint256 newAllowance = token.allowance(address(this), spender) - value;
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

pragma solidity ^0.8.0;

import "./Context.sol";
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

// SPDX-License-Identifier: No License

pragma solidity ^0.8.0;

interface IERC3156FlashBorrower {

    /**
     * @dev Receive a flash loan.
     * @param initiator The initiator of the loan.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @param fee The additional amount of tokens to repay.
     * @param data Arbitrary data structure, intended to contain user-defined parameters.
     * @return The keccak256 hash of "ERC3156FlashBorrower.onFlashLoan"
     */
    function onFlashLoan(
        address initiator,
        address token,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external returns (bytes32);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
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
        return _functionCallWithValue(target, data, 0, errorMessage);
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
        return _functionCallWithValue(target, data, value, errorMessage);
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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}