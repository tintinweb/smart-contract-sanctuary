// SPDX-License-Identifier: GPL-2.0

pragma solidity ^0.8.0;

import "./base/RouterBase.sol";
import "@pancakeswap/pancake-swap-lib/contracts/utils/TransferHelper.sol";
import "./interface/IBKPancake.sol";

contract SwapV2PoolRouter is  RouterBase {
    using SafeERC20 for IERC20;

    constructor(uint256 _goodwill, uint256 _affiliateSplit)
    RouterBase(_goodwill, _affiliateSplit){}

    /**
    @notice Add liquidity to Pancakeswap pools with ETH/ERC20 Tokens
    @param _addresses[0]  contract address to call   _addresses[1] The ERC20 token used (address(0x00) if ether)   _addresses[2] The Pancakeswap pair address
    @param _amount The amount of fromToken to invest
    @param _minPoolTokens Minimum quantity of pool tokens to receive. Reverts otherwise
    @param _swapTarget Excecution target for the first swap
    @param swapData DEX quote data
    @param affiliate Affiliate address
    @param transferResidual Set false to save gas by donating the residual remaining after a Zap
    @param shouldSellEntireBalance  If True transfers entrire allowable amount from another contract
    @return Amount of LP bought
     */
    function addLiquidity01(
        address[] calldata _addresses,
        uint256 _amount,
        uint256 _minPoolTokens,
        address _swapTarget,
        bytes calldata swapData,
        address affiliate,
        bool transferResidual,
        bool shouldSellEntireBalance
    ) external payable stopInEmergency returns (uint256) {
        require(_addresses.length == 3,"_addresses.length is not 3");
        uint256 toInvest = _pullTokens(_addresses[1], _amount, affiliate, true, shouldSellEntireBalance);
        if (_addresses[1]  != address(0)) {
            IERC20(_addresses[1]).safeTransfer(_addresses[0],toInvest);
        }
        uint256 LPBought = IBKPancakeIn(_addresses[0]).ZapIn(_addresses[1],_addresses[2],toInvest,_minPoolTokens,_swapTarget,swapData,transferResidual);
        IERC20(_addresses[2]).safeTransfer(msg.sender, LPBought);
        return LPBought;
    }

    /**
    @notice Add liquidity to Pancakeswap pools with two lp token
    @param _contractAddress  contract address to call
    @param _pairAddress The Pancakeswap pair address
    @param _amount0 The amount of fromToken to invest
    @param _amount1 The amount of fromToken to invest
    @param _minPoolTokens Minimum quantity of pool tokens to receive. Reverts otherwise
    @param affiliate Affiliate address
    @param transferResidual Set false to save gas by donating the residual remaining after a Zap
    @param shouldSellEntireBalance  If True transfers entrire allowable amount from another contract
    @return Amount of LP bought
     */
    function addLiquidity02(
        address _contractAddress,
        address _pairAddress,
        uint256 _amount0,
        uint256 _amount1,
        uint256 _minPoolTokens,
        address affiliate,
        bool transferResidual,
        bool shouldSellEntireBalance
    ) external  stopInEmergency returns (uint256) {
        (uint256 token0Bought,uint256 token1Bought) = _pullBothTokens(_amount0, _amount1, _pairAddress, affiliate, shouldSellEntireBalance);
        ( address token0, address token1) = _getPairTokens(_pairAddress);
        IERC20(token0).safeTransfer(_contractAddress,token0Bought);
        IERC20(token1).safeTransfer(_contractAddress,token1Bought);
        uint256 LPBought = IBKPancakeIn(_contractAddress).ZapIn01( _pairAddress, token0Bought,token1Bought, _minPoolTokens, transferResidual);
        IERC20(_pairAddress).safeTransfer(msg.sender, LPBought);
        return LPBought;
    }

//     **** REMOVE LIQUIDITY 02 ****
    function removeLiquidity02(
        address _contractAddress,
        address fromPoolAddress,
        uint256 incomingLP,
        address affiliate
    ) public stopInEmergency returns (uint amountA, uint amountB) {
        IUniswapV2Pair pair = IUniswapV2Pair(fromPoolAddress);
        require(address(pair) != address(0), "Pool Cannot be Zero Address");
        require(address(_contractAddress) != address(0), "Router Cannot be Zero Address");
        address token0 = pair.token0();
        address token1 = pair.token1();

        IERC20(fromPoolAddress).safeTransferFrom(msg.sender, address(this), incomingLP);
        address nativeToken = IBKPancakeOut(_contractAddress).getNativeToken();
        if (token0 == nativeToken || token1 == nativeToken) {
            address _token = token0 == nativeToken ? token1 : token0;
            ( amountA,  amountB)= IBKPancakeOut(_contractAddress).ZapOut2PairToken(fromPoolAddress, incomingLP);
            // subtract goodwill
            uint256 tokenGoodwill = _subtractGoodwill(_token, amountA, affiliate, true);
            uint256 ethGoodwill = _subtractGoodwill(ETHAddress, amountB, affiliate, true);
            // send tokens
            IERC20(_token).safeTransfer(msg.sender, amountA - tokenGoodwill);
            Address.sendValue(payable(msg.sender), amountB - ethGoodwill);
        } else {
            ( amountA,  amountB)= IBKPancakeOut(_contractAddress).ZapOut2PairToken(fromPoolAddress, incomingLP);
            // subtract goodwill
            uint256 tokenAGoodwill = _subtractGoodwill(token0, amountA, affiliate, true);
            uint256 tokenBGoodwill = _subtractGoodwill(token1, amountB, affiliate, true);
            // send tokens
            IERC20(token0).safeTransfer(msg.sender, amountA - tokenAGoodwill);
            IERC20(token1).safeTransfer(msg.sender, amountB - tokenBGoodwill);
        }
    }

    //     **** REMOVE LIQUIDITY 01 ****
    function removeLiquidity01(
        address _contractAddress,
        address toTokenAddress,
        address fromPoolAddress,
        uint256 incomingLP,
        uint256 minTokensRec,
        address[] memory swapTargets,
        bytes[] memory swapData,
        address affiliate,
        bool shouldSellEntireBalance
    ) public stopInEmergency returns (uint256 tokensRec) {
        uint256 amountLP = _pullTokens( fromPoolAddress, incomingLP, shouldSellEntireBalance);
        IERC20(fromPoolAddress).safeTransfer( _contractAddress, amountLP);
        tokensRec = IBKPancakeOut(_contractAddress).ZapOut( toTokenAddress, fromPoolAddress, amountLP, minTokensRec, swapTargets, swapData);
        uint256 totalGoodwillPortion;
        // transfer toTokens to sender
        if (toTokenAddress == address(0)) {
            totalGoodwillPortion = _subtractGoodwill( ETHAddress, tokensRec, affiliate, true);
            payable(msg.sender).transfer(tokensRec - totalGoodwillPortion);
        } else {
            totalGoodwillPortion = _subtractGoodwill( toTokenAddress, tokensRec, affiliate, true);
            IERC20(toTokenAddress).safeTransfer( msg.sender, tokensRec - totalGoodwillPortion);
        }

        tokensRec = tokensRec - totalGoodwillPortion;
    }

}

// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;

import "../lib/SafeERC20.sol";
import "./Operation.sol";
import "../interface/IBKPancake.sol";

abstract contract RouterBase is Operation{
    using SafeERC20 for IERC20;
    // if true, goodwill is not deducted
    mapping(address => bool) public feeWhitelist;

    uint256 public goodwill;
    // % share of goodwill (0-100 %)
    uint256 affiliateSplit;
    // restrict affiliates
    mapping(address => bool) public affiliates;
    // affiliate => token => amount
    mapping(address => mapping(address => uint256)) public affiliateBalance;
    // token => amount
    mapping(address => uint256) public totalAffiliateBalance;

    address internal constant ETHAddress = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    constructor(uint256 _goodwill, uint256 _affiliateSplit) {
        goodwill = _goodwill;
        affiliateSplit = _affiliateSplit;
    }

    function set_feeWhitelist(address zapAddress, bool status) external onlyOwner {
        feeWhitelist[zapAddress] = status;
    }

    function set_new_goodwill(uint256 _new_goodwill) public onlyOwner {
        require(_new_goodwill >= 0 && _new_goodwill <= 100, "GoodWill Value not allowed");
        goodwill = _new_goodwill;
    }

    function set_new_affiliateSplit(uint256 _new_affiliateSplit) external onlyOwner {
        require(_new_affiliateSplit <= 100, "Affiliate Split Value not allowed");
        affiliateSplit = _new_affiliateSplit;
    }

    function set_affiliate(address _affiliate, bool _status) external onlyOwner {
        affiliates[_affiliate] = _status;
    }

    ///@notice Withdraw goodwill share, retaining affilliate share
    function withdrawTokens(address[] calldata tokens) external onlyOwner {
        for (uint256 i = 0; i < tokens.length; i++) {
            uint256 qty;

            if (tokens[i] == ETHAddress) {
                qty = address(this).balance - totalAffiliateBalance[tokens[i]];
                Address.sendValue(payable(owner()), qty);
            } else {
                qty = IERC20(tokens[i]).balanceOf(address(this)) - totalAffiliateBalance[tokens[i]];
                IERC20(tokens[i]).safeTransfer(owner(), qty);
            }
        }
    }

    ///@notice Withdraw affilliate share, retaining goodwill share
    function affilliateWithdraw(address[] calldata tokens) external {
        uint256 tokenBal;
        for (uint256 i = 0; i < tokens.length; i++) {
            tokenBal = affiliateBalance[msg.sender][tokens[i]];
            affiliateBalance[msg.sender][tokens[i]] = 0;
            totalAffiliateBalance[tokens[i]] = totalAffiliateBalance[tokens[i]] - tokenBal;

            if (tokens[i] == ETHAddress) {
                Address.sendValue(payable(msg.sender), tokenBal);
            } else {
                IERC20(tokens[i]).safeTransfer(msg.sender, tokenBal);
            }
        }
    }

    function _subtractGoodwill(
        address token,
        uint256 amount,
        address affiliate,
        bool enableGoodwill
    ) internal returns (uint256 totalGoodwillPortion) {
        bool whitelisted = feeWhitelist[msg.sender];
        if (enableGoodwill && !whitelisted && goodwill > 0) {
            totalGoodwillPortion = (amount * goodwill) / 10000;

        if (affiliates[affiliate]){
            if (token == address(0)) {
                token = ETHAddress;
            }

          uint256 affiliatePortion = (totalGoodwillPortion * affiliateSplit) / 100;
          affiliateBalance[affiliate][token] += affiliatePortion;
          totalAffiliateBalance[token] += affiliatePortion;
        }
      }
    }

    function _getPairTokens(address _pairAddress)
    internal
    pure
    returns (address token0, address token1)
    {
        IUniswapV2Pair uniPair = IUniswapV2Pair(_pairAddress);
        token0 = uniPair.token0();
        token1 = uniPair.token1();
    }

    function _pullBothTokens(
        uint256 _amount0,
        uint256 _amount1,
        address _pairAddress,
        address affiliate,
        bool shouldSellEntireBalance
    ) internal returns (uint256 token0Bought,uint256 token1Bought) {
        ( address token0, address token1) = _getPairTokens(_pairAddress);
        token0Bought = _pullTokens( token0, _amount0, affiliate, true, shouldSellEntireBalance);
        token1Bought = _pullTokens( token1, _amount1, affiliate, true, shouldSellEntireBalance);
    }

    function _pullTokens(
        address token,
        uint256 amount,
        address affiliate,
        bool enableGoodwill,
        bool shouldSellEntireBalance
    ) internal returns (uint256 value) {
        uint256 totalGoodwillPortion;

        if (token == address(0)) {
            require(msg.value > 0, "No eth sent");
            // subtract goodwill
            totalGoodwillPortion = _subtractGoodwill( ETHAddress, msg.value, affiliate, enableGoodwill);

            return msg.value - totalGoodwillPortion;
        }
        require(amount > 0, "Invalid token amount");
        require(msg.value == 0, "Eth sent with token");

        //transfer token
        if (shouldSellEntireBalance) {
            require(Address.isContract(msg.sender), "ERR: shouldSellEntireBalance is true for EOA");
            amount = IERC20(token).allowance(msg.sender, address(this));
        }
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);

        // subtract goodwill
        totalGoodwillPortion = _subtractGoodwill(token, amount, affiliate, enableGoodwill);

        return amount - totalGoodwillPortion;
    }


    /**
        @dev Transfer tokens from msg.sender to this contract
        @param token The ERC20 token to transfer to this contract
        @param shouldSellEntireBalance If True transfers entrire allowable amount from another contract
        @return Quantity of tokens transferred to this contract
     */
    function _pullTokens(
        address token,
        uint256 amount,
        bool shouldSellEntireBalance
    ) internal returns (uint256) {
        if (shouldSellEntireBalance) {
            require(Address.isContract(msg.sender), "ERR: shouldSellEntireBalance is true for EOA");

            uint256 allowance = IERC20(token).allowance(msg.sender, address(this));
            IERC20(token).safeTransferFrom(msg.sender, address(this), allowance);

            return allowance;
        } else {
            IERC20(token).safeTransferFrom(msg.sender, address(this), amount);

            return amount;
        }
    }


    function _approveToken(address token, address spender, uint256 amount) internal {
        IERC20(token).safeApprove(spender, 0);
        IERC20(token).safeApprove(spender, amount);
    }

    function _approveToken(address token, address spender) internal {
        IERC20 _token = IERC20(token);
        if (_token.allowance(address(this), spender) > 0) return;
        else {
            _token.safeApprove(spender, type(uint256).max);
        }
    }

    receive() external payable {}
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.6.0;

// helper methods for interacting with BEP20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferBNB(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'TransferHelper: BNB_TRANSFER_FAILED');
    }
}

// SPDX-License-Identifier: GPL-2.0

pragma solidity ^0.8.0;

interface IBKPancakeIn {

    function ZapIn(address _FromTokenContractAddress, address _pairAddress, uint256 _amount, uint256 _minPoolTokens, address _swapTarget, bytes calldata swapData, bool transferResidual) external payable returns (uint256);
    function ZapIn01(address _pairAddress, uint256 amount0, uint256 amount1, uint256 _minPoolTokens, bool transferResidual) external   returns (uint256);
    function GetAnotherAmount(address token,address pair,uint256 amount) external view returns(uint256 another);

}

interface IBKPancakeOut {

    function ZapOut2PairToken(address fromPoolAddress, uint256 incomingLP) external  returns (uint256 amountA, uint256 amountB);
    function ZapOut(address toTokenAddress, address fromPoolAddress, uint256 incomingLP, uint256 minTokensRec, address[] memory swapTargets, bytes[] memory swapData) external  returns (uint256 tokensRec);
    function removeLiquidityReturn(address fromPoolAddress, uint256 liquidity) external view returns (uint256 amountA,uint256 amountB, address token0, address token1);
    function getNativeToken() external view returns(address);
}

interface IUniswapV2Pair {
    function token0() external pure returns (address);

    function token1() external pure returns (address);

    function balanceOf(address user) external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function getReserves() external view returns (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast);

    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./Address.sol";

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

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, value)
        );
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
    unchecked {
        uint256 oldAllowance = token.allowance(address(this), spender);
        require(
            oldAllowance >= value,
            "SafeERC20: decreased allowance below zero"
        );
        uint256 newAllowance = oldAllowance - value;
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
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

        bytes memory returndata =
        address(token).functionCall(
            data,
            "SafeERC20: low-level call failed"
        );
        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(
                abi.decode(returndata, (bool)),
                "SafeERC20: ERC20 operation did not succeed"
            );
        }
    }
}

// SPDX-License-Identifier: GPL-2.0
pragma solidity ^0.8.0;
import "../lib/Ownable.sol";
abstract contract Operation is Ownable{

    bool public stopped = false;
    // circuit breaker modifiers
    modifier stopInEmergency {
        if (stopped) {
            revert("Temporarily Paused");
        } else {
            _;
        }
    }

    // - to Pause the contract
    function toggleContractActive() public onlyOwner {
        stopped = !stopped;
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
    function transfer(address recipient, uint256 amount)
    external
    returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
    external
    view
    returns (uint256);

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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
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
        assembly {
            size := extcodesize(account)
        }
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
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
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
    function functionCall(address target, bytes memory data)
    internal
    returns (bytes memory)
    {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return
        functionCallWithValue(
            target,
            data,
            value,
            "Address: low-level call with value failed"
        );
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) =
        target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data)
    internal
    view
    returns (bytes memory)
    {
        return
        functionStaticCall(
            target,
            data,
            "Address: low-level static call failed"
        );
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
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
    function functionDelegateCall(address target, bytes memory data)
    internal
    returns (bytes memory)
    {
        return
        functionDelegateCall(
            target,
            data,
            "Address: low-level delegate call failed"
        );
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
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

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}