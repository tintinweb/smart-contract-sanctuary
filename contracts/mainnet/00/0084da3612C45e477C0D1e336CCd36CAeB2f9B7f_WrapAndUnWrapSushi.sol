// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../proxyLib/OwnableUpgradeable.sol";
import "../interfaces/token/IWETH.sol";
import "../interfaces/token/ILPERC20.sol";
import "../interfaces/sushiswap/ISushiV2.sol";
import "../interfaces/sushiswap/ISushiSwapFactory.sol";

/// @title Plexus LP Wrapper Contract - SushiSwap
/// @author Team Plexus
contract WrapAndUnWrapSushi is OwnableUpgradeable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Contract state variables
    address public WETH_TOKEN_ADDRESS; // Contract address for WETH tokens
    bool public changeRecpientIsOwner;
    address private sushiAddress;
    address private sushiFactoryAddress;
    uint256 public fee;
    uint256 public maxfee;
    mapping(address => address[]) public lpTokenAddressToPairs;
    mapping(string => address) public stablecoins;
    mapping(address => mapping(address => address[])) public presetPaths;
    event WrapSushi(address lpTokenPairAddress, uint256 amount);
    event UnWrapSushi(uint256 amount);
    event RemixUnwrap(uint256 amount);
    event RemixWrap(address lpTokenPairAddress, uint256 amount);
    ISushiV2 private sushiExchange;
    ISushiSwapFactory private factory;

    constructor() payable {}

    /**
     * @notice Initialize the Sushi Wrapper contract
     * @param _weth Address to the WETH token contract
     * @param _sushiAddress Address to the SushiSwap contract
     * @param _sushiFactoryAddress Address to the SushiV2 factory contract
     */
    function initialize(
        address _weth,
        address _sushiAddress,
        address _sushiFactoryAddress
    )
        public
        initializeOnceOnly
    {
        WETH_TOKEN_ADDRESS = _weth;
        sushiAddress = _sushiAddress;
        sushiExchange = ISushiV2(sushiAddress);
        sushiFactoryAddress = _sushiFactoryAddress;
        factory = ISushiSwapFactory(sushiFactoryAddress);
        fee = 0;
        maxfee = 0;
        changeRecpientIsOwner = false;
    }

    /**
     * @notice Modifier check to ensure that a function is executed only if it
     * was called with a non-zero amount value
     * @param amount Amount value
     */
    modifier nonZeroAmount(uint256 amount) {
        require(amount > 0, "Amount specified is zero");
        _;
    }

    /**
     * @notice Executed on a call to the contract if none of the other
     * functions match the given function signature, or if no data was
     * supplied at all and there is no receive Ether function
     */
    fallback() external payable {}

     /**
     * @notice Function executed on plain ether transfers and on a call to the
     * contract with empty calldata
     */
    receive() external payable {}

    /**
     * @notice Allow owner to collect a small fee from trade imbalances on
     * LP conversions
     * @param changeRecpientIsOwnerBool If set to true, allows owner to collect
     * fees from pair imbalances
     */
    function updateChangeRecipientBool(bool changeRecpientIsOwnerBool)
        external
        onlyOwner
        returns (bool)
    {
        changeRecpientIsOwner = changeRecpientIsOwnerBool;
        return true;
    }

    /**
     * @notice Update the SushiSwap exchange contract address
     * @param newAddress SushiSwap exchange contract address to be updated
     */
    function updateSushiExchange(address newAddress)
        external
        onlyOwner
        returns (bool)
    {
        sushiExchange = ISushiV2(newAddress);
        sushiAddress = newAddress;
        return true;
    }

     /**
     * @notice Update the Uniswap factory contract address
     * @param newAddress Uniswap factory contract address to be updated
     */
    function updateSushiSwapFactory(address newAddress)
        external
        onlyOwner
        returns (bool)
    {
        factory = ISushiSwapFactory(newAddress);
        sushiFactoryAddress = newAddress;
        return true;
    }

    /**
     * @notice Retrieve the LP token address for a given pair of tokens
     * @param token1 Address to the first token in the LP pair
     * @param token2 Address to the second token in the LP pair
     * @return lpAddr Address to the LP token contract composed of the given
     * token pair
     */
    function getLPTokenByPair(
        address token1,
        address token2
    )
        external
        view
        returns (address lpAddr)
    {
        address thisPairAddress = factory.getPair(token1, token2);
        return thisPairAddress;
    }

    /**
     * @notice Retrieve the balance of a given token for a specified user
     * @param userAddress Address to the user's wallet
     * @param tokenAddress Address to the token for which the balance is to be
     * retrieved
     * @return Balance of the given token in the specified user wallet
     */
    function getUserTokenBalance(
        address userAddress,
        address tokenAddress
    )
        external
        view
        returns (uint256)
    {
        IERC20 token = IERC20(tokenAddress);
        return token.balanceOf(userAddress);
    }

    /**
    * @notice Allow admins to withdraw accidentally deposited tokens
    * @param token Address to the token to be withdrawn
    * @param amount Amount of specified token to be withdrawn
    * @param destination Address where the withdrawn tokens should be
    * transferred
    */
    function adminEmergencyWithdrawTokens(
        address token,
        uint256 amount,
        address payable destination
    )
        public
        onlyOwner
        returns (bool)
    {
        if (address(token) == address(0x0)) {
            destination.transfer(amount);
        } else {
            IERC20 token_ = IERC20(token);
            token_.safeTransfer(destination, amount);
        }
        return true;
    }

    /**
     * @notice Update the protocol fee rate
     * @param newFee Updated fee rate to be charged
     */
    function setFee(uint256 newFee) public onlyOwner returns (bool) {
        require(
            newFee <= maxfee,
            "Admin cannot set the fee higher than the current maxfee"
        );
        fee = newFee;
        return true;
    }

     /**
     * @notice Set the max protocol fee rate
     * @param newMax Updated maximum fee rate value
     */
    function setMaxFee(uint256 newMax) public onlyOwner returns (bool) {
        require(maxfee == 0, "Admin can only set max fee once and it is perm");
        maxfee = newMax;
        return true;
    }

    function swap(
        address sourceToken,
        address destinationToken,
        address[] memory path,
        uint256 amount,
        uint256 userSlippageTolerance,
        uint256 deadline
    ) private returns (uint256) {
        if (sourceToken != address(0x0)) {
            IERC20(sourceToken).safeTransferFrom(msg.sender, address(this), amount);
        }
        conductSushiSwap(sourceToken, destinationToken, path, amount, userSlippageTolerance, deadline);
        uint256 thisBalance = IERC20(destinationToken).balanceOf(address(this));
        IERC20(destinationToken).safeTransfer(msg.sender, thisBalance);
        return thisBalance;
    }

    function createWrap(
        address sourceToken,
        address[] memory destinationTokens,
        address[][] memory paths,
        uint256 amount,
        uint256 userSlippageTolerance,
        uint256 deadline,
        bool remixing
    ) private returns (address, uint256) {
        if (sourceToken == address(0x0)) {
            IWETH(WETH_TOKEN_ADDRESS).deposit{value: msg.value}();
            amount = msg.value;
        } else {
            if(!remixing) { // only transfer when not remixing
                IERC20(sourceToken).safeTransferFrom(msg.sender, address(this), amount);
            }
            
        }

        if (destinationTokens[0] == address(0x0)) {
            destinationTokens[0] = WETH_TOKEN_ADDRESS;
        }
        if (destinationTokens[1] == address(0x0)) {
            destinationTokens[1] = WETH_TOKEN_ADDRESS;
        }

        if (sourceToken != destinationTokens[0]) {
            conductSushiSwap(
                sourceToken,
                destinationTokens[0],
                paths[0],
                amount.div(2),
                userSlippageTolerance,
                deadline
            );
        }
        if (sourceToken != destinationTokens[1]) {
             conductSushiSwap(
                sourceToken,
                destinationTokens[1],
                paths[1],
                amount.div(2),
                userSlippageTolerance,
                deadline
            );
        }

        IERC20 dToken1 = IERC20(destinationTokens[0]);
        IERC20 dToken2 = IERC20(destinationTokens[1]);
        uint256 dTokenBalance1 = dToken1.balanceOf(address(this));
        uint256 dTokenBalance2 = dToken2.balanceOf(address(this));

        if (dToken1.allowance(address(this), sushiAddress) < dTokenBalance1.mul(2)) {
            dToken1.safeIncreaseAllowance(sushiAddress, dTokenBalance1.mul(3));
        }

        if (dToken2.allowance(address(this), sushiAddress) < dTokenBalance2.mul(2)) {
            dToken2.safeIncreaseAllowance(sushiAddress, dTokenBalance2.mul(3));
        }

        sushiExchange.addLiquidity(
            destinationTokens[0],
            destinationTokens[1],
            dTokenBalance1,
            dTokenBalance2,
            1,
            1,
            address(this),
            1000000000000000000000000000
        );

        address thisPairAddress =
            factory.getPair(destinationTokens[0], destinationTokens[1]);
        IERC20 lpToken = IERC20(thisPairAddress);
        uint256 thisBalance = lpToken.balanceOf(address(this));

        if (fee > 0) {
            uint256 totalFee = (thisBalance.mul(fee)).div(10000);
            if (totalFee > 0) {
                lpToken.safeTransfer(owner(), totalFee);
            }
            thisBalance = lpToken.balanceOf(address(this));
            lpToken.safeTransfer(msg.sender, thisBalance);
        } else {
            lpToken.safeTransfer(msg.sender, thisBalance);
        }

        // Transfer any change to changeRecipient
        // (from a pair imbalance. Should never be more than a few basis points)
        address changeRecipient = msg.sender;
        if (changeRecpientIsOwner == true) {
            changeRecipient = owner();
        }
        if (dToken1.balanceOf(address(this)) > 0) {
            dToken1.safeTransfer(changeRecipient, dToken1.balanceOf(address(this)));
        }
        if (dToken2.balanceOf(address(this)) > 0) {
            dToken2.safeTransfer(changeRecipient, dToken2.balanceOf(address(this)));
        }
        return (thisPairAddress, thisBalance);
    }

    /**
     * @notice Wrap a source token based on the specified
     * destination token(s)
     * @param sourceToken Address to the source token contract
     * @param destinationTokens Array describing the token(s) which the source
     * @param paths Paths for uniswap
     * token will be wrapped into
     * @param amount Amount of source token to be wrapped
     * @param userSlippageTolerance Maximum permissible user slippage tolerance
     * @return Address to the token contract for the destination token and the
     * amount of wrapped tokens
     */
    function wrap(
        address sourceToken,
        address[] memory destinationTokens,
        address[][] memory paths,
        uint256 amount,
        uint256 userSlippageTolerance,
        uint256 deadline
    )
        public
        payable
        returns (address, uint256)
    {
        if (destinationTokens.length == 1) {
            uint256 swapAmount = swap(sourceToken, destinationTokens[0], paths[0], amount, userSlippageTolerance, deadline);
            return (destinationTokens[0], swapAmount);
        } else {
            bool remixing = false;
            (address lpTokenPairAddress, uint256 lpTokenAmount) = createWrap(sourceToken, destinationTokens, paths, amount, userSlippageTolerance, deadline, remixing);
            emit WrapSushi(lpTokenPairAddress, lpTokenAmount);
            return (lpTokenPairAddress, lpTokenAmount);
        }
    }

    function removeWrap(
        address sourceToken,
        address destinationToken,
        address[][] memory paths,
        uint256 amount,
        uint256 userSlippageTolerance,
        uint256 deadline,
        bool remixing
    )
        private
        returns (uint256)
    {
        address originalDestinationToken = destinationToken;
      
        IERC20 sToken = IERC20(sourceToken);
        if (destinationToken == address(0x0)) {
            destinationToken = WETH_TOKEN_ADDRESS;
        }

        if (sourceToken != address(0x0)) {
            sToken.safeTransferFrom(msg.sender, address(this), amount);
        }

        ILPERC20 thisLpInfo = ILPERC20(sourceToken);
        address token0 = thisLpInfo.token0();
        address token1 = thisLpInfo.token1();

        if (sToken.allowance(address(this), sushiAddress) < amount.mul(2)) {
            sToken.safeIncreaseAllowance(sushiAddress, amount.mul(3));
        }

        sushiExchange.removeLiquidity(
            token0,
            token1,
            amount,
            0,
            0,
            address(this),
            1000000000000000000000000000
        );

        uint256 pTokenBalance = IERC20(token0).balanceOf(address(this));
        uint256 pTokenBalance2 = IERC20(token1).balanceOf(address(this));

        if (token0 != destinationToken) {
            conductSushiSwap(
                token0,
                destinationToken,
                paths[0],
                pTokenBalance,
                userSlippageTolerance,
                deadline
            );
        }

        if (token1 != destinationToken) {
            conductSushiSwap(
                token1,
                destinationToken,
                paths[1],
                pTokenBalance2,
                userSlippageTolerance,
                deadline
            );
        }

        IERC20 dToken = IERC20(destinationToken);
        uint256 destinationTokenBalance = dToken.balanceOf(address(this));
    
        if (remixing) {
            
            emit RemixUnwrap(destinationTokenBalance);
        }
        else { // we only transfer the tokens to the user when not remixing
            if (originalDestinationToken == address(0x0)) {
                IWETH(WETH_TOKEN_ADDRESS).withdraw(destinationTokenBalance);
                if (fee > 0) {
                    uint256 totalFee = (address(this).balance.mul(fee)).div(10000);
                    if (totalFee > 0) {
                        payable(owner()).transfer(totalFee);
                    }
                        payable(msg.sender).transfer(address(this).balance);
                } else {
                    payable(msg.sender).transfer(address(this).balance);
                }
            } else {
                if (fee > 0) {
                    uint256 totalFee = (destinationTokenBalance.mul(fee)).div(10000);
                    if (totalFee > 0) {
                        dToken.safeTransfer(owner(), totalFee);
                    }
                    destinationTokenBalance = dToken.balanceOf(address(this));
                    dToken.safeTransfer(msg.sender, destinationTokenBalance);
                } else {
                    dToken.safeTransfer(msg.sender, destinationTokenBalance);
                }
            }

        }
       
        return destinationTokenBalance;
    }

    /**
     * @notice Unwrap a source token based to the specified destination token
     * @param sourceToken Address to the source token contract
     * @param destinationToken Address to the destination token contract
     * @param paths Paths for uniswap
     * @param lpTokenPairAddress address for lp token
     * @param amount Amount of source token to be unwrapped
     * @param userSlippageTolerance Maximum permissible user slippage tolerance
     * @return Amount of the destination token returned from unwrapping the
     * source token
     */
    function unwrap(
        address sourceToken,
        address destinationToken,
        address lpTokenPairAddress,
        address[][] calldata paths,
        uint256 amount,
        uint256 userSlippageTolerance,
        uint256 deadline
    )
        public
        payable
        returns (uint256)
    {

        if (lpTokenPairAddress == address(0x0)) {
            return swap(sourceToken, destinationToken, paths[0], amount, userSlippageTolerance, deadline);
        } else {
            bool remixing = false; //flag indicates whether we're remixing or not
            uint256 destAmount = removeWrap(lpTokenPairAddress, destinationToken, paths, amount, userSlippageTolerance, deadline, remixing);
            emit UnWrapSushi(destAmount);
            return destAmount;
        }
    }

     /**
     * @notice Unwrap a source token and wrap it into a different destination token 
     * @param lpTokenPairAddress Address for the LP pair to remix
     * @param unwrapOutputToken Address for the initial output token of remix
     * @param destinationTokens Address to the destination tokens to be remixed to
     * @param unwrapPaths Paths best sushi trade paths for doing the unwrapping
     * @param wrapPaths Paths best sushi trade paths for doing the wrapping to the new LP token
     * @param amount Amount of LP Token to be remixed
     * @param userSlippageTolerance Maximum permissible user slippage tolerance
     * @return Amount of the destination token returned from unwrapping the
     * source LP token
     */
    function remix(
        address lpTokenPairAddress,
        address unwrapOutputToken,
        address[] memory destinationTokens,
        address[][] calldata unwrapPaths,
        address[][] calldata wrapPaths,
        uint256 amount,
        uint256 userSlippageTolerance,
        uint256 deadline
    )
        public
        payable
        returns (uint256)
    {
        bool remixing = true; //flag indicates whether we're remixing or not
        uint256 destAmount = removeWrap(lpTokenPairAddress, unwrapOutputToken, unwrapPaths, amount, userSlippageTolerance, deadline, remixing);

        IERC20 dToken = IERC20(unwrapOutputToken);
        uint256 destinationTokenBalance = dToken.balanceOf(address(this));

        require(destAmount == destinationTokenBalance, "Error: Remix output balance not correct");
       
        // then now we create the new LP token
        address outputToken = unwrapOutputToken;
        address [] memory dTokens = destinationTokens;
        address [][] calldata paths = wrapPaths;
        uint256 slippageTolerance = userSlippageTolerance;
        uint256 timeout = deadline;
        bool remixingToken = true; //flag indicates whether we're remixing or not

        (address remixedLpTokenPairAddress, uint256 lpTokenAmount) = createWrap(outputToken, dTokens, paths, destinationTokenBalance, slippageTolerance, timeout, remixingToken);
                                                                
        emit RemixWrap(remixedLpTokenPairAddress, lpTokenAmount);
        return lpTokenAmount;
        
    }


    /**
     * @notice Given an input asset amount and an array of token addresses,
     * calculates all subsequent maximum output token amounts for each pair of
     * token addresses in the path using SushiSwap
     * @param theAddresses Array of addresses that form the Routing swap path
     * @param amount Amount of input asset token
     * @return amounts1 Array with maximum output token amounts for all token
     * pairs in the swap path
     */
    function getPriceFromSushiswap(
        address[] memory theAddresses,
        uint256 amount
    )
        public
        view
        returns (uint256[] memory amounts1)
    {
        try sushiExchange.getAmountsOut(
            amount,
            theAddresses
        ) returns (uint256[] memory amounts) {
            return amounts;
        } catch {
            uint256[] memory amounts2 = new uint256[](2);
            amounts2[0] = 0;
            amounts2[1] = 0;
            return amounts2;
        }
    }

    /**
     * @notice Retrieve minimum output amount required based on uniswap routing
     * path and maximum permissible slippage
     * @param theAddresses Array list describing the SushiSwap swap path
     * @param amount Amount of input tokens to be swapped
     * @param userSlippageTolerance Maximum permissible user slippage tolerance
     * @return Minimum amount of output tokens the input token can be swapped
     * for, based on the Uniswap prices and Slippage tolerance thresholds
     */
    function getAmountOutMin(
        address[] memory theAddresses,
        uint256 amount,
        uint256 userSlippageTolerance
    )
        public
        view
        returns (uint256)
    {
        uint256[] memory assetAmounts = getPriceFromSushiswap(
            theAddresses,
            amount
        );
        require(
            userSlippageTolerance <= 100,
            "userSlippageTolerance can not be larger than 100"
        );

          // this is the index of the output token we're swapping to based on the paths
        uint outputTokenIndex = assetAmounts.length - 1;
        return
            SafeMath.div(
                SafeMath.mul(assetAmounts[outputTokenIndex], (100 - userSlippageTolerance)),
                100
            );
    }

     /**
     * @notice Perform a SushiSwap transaction to swap between a given pair of
     * tokens of the specified amount
     * @param sellToken Address to the token being sold as part of the swap
     * @param buyToken Address to the token being bought as part of the swap
     * @param amount Transaction amount denoted in terms of the token sold
     * @param userSlippageTolerance Maximum permissible slippage limit
     * @return amounts1 Tokens received once the swap is completed
     */
    function conductSushiSwap(
        address sellToken,
        address buyToken,
        address[] memory path,
        uint256 amount,
        uint256 userSlippageTolerance,
        uint256 deadline
    )
        internal
        returns (uint256 amounts1)
    {
        if (sellToken == address(0x0) && buyToken == WETH_TOKEN_ADDRESS) {
            IWETH(buyToken).deposit{value: msg.value}();
            return amount;
        }

        if (sellToken == address(0x0)) {
            // addresses[0] = WETH_TOKEN_ADDRESS;
            // addresses[1] = buyToken;
            uint256 amountOutMin = getAmountOutMin(path, amount, userSlippageTolerance);
            sushiExchange.swapExactETHForTokens{value: msg.value}(
                amountOutMin,
                path,
                address(this),
                deadline
            );
        } else {
            IERC20 sToken = IERC20(sellToken);
            if (sToken.allowance(address(this), sushiAddress) < amount.mul(2)) {
                sToken.safeIncreaseAllowance(sushiAddress, amount.mul(3));
            }

            uint256[] memory amounts = conductSushiSwapT4T(
                path,
                amount,
                userSlippageTolerance,
                deadline
            );
            uint256 resultingTokens = amounts[amounts.length - 1];
            return resultingTokens;
        }
    }

    /**
     * @notice Using SushiSwap, exchange an exact amount of input tokens for as
     * many output tokens as possible, along the route determined by the path.
     * @param theAddresses Array of addresses representing the path where the
     * first address is the input token and the last address is the output
     * token
     * @param amount Amount of input tokens to be swapped
     * @param userSlippageTolerance Maximum permissible slippage tolerance
     * @return amounts1 The input token amount and all subsequent output token
     * amounts
     */
    function conductSushiSwapT4T(
        address[] memory theAddresses,
        uint256 amount,
        uint256 userSlippageTolerance,
        uint256 deadline
    )
        internal
        returns (uint256[] memory amounts1)
    {
        uint256 amountOutMin = getAmountOutMin(
            theAddresses,
            amount,
            userSlippageTolerance
        );
        uint256[] memory amounts = sushiExchange.swapExactTokensForTokens(
            amount,
            amountOutMin,
            theAddresses,
            address(this),
            deadline
        );
        return amounts;
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
    event Approval(address indexed owner, address indexed spender, uint256 value);
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

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
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
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
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
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;
pragma experimental ABIEncoderV2;

import './OwnableProxied.sol';

contract OwnableUpgradeable is OwnableProxied {
    /*
     * @notice Modifier to make body of function only execute if the contract has not already been initialized.
     */
    address payable public proxy;
    modifier initializeOnceOnly() {
         if(!initialized[target]) {
             initialized[target] = true;
             emit EventInitialized(target);
             _;
         } else revert();
     }

    modifier onlyProxy() {
        require(msg.sender == proxy);
        _;
    }

    /**
     * @notice Will always fail if called. This is used as a placeholder for the contract ABI.
     * @dev This is code is never executed by the Proxy using delegate call
     */
    function upgradeTo(address) public pure override {
        assert(false);
    }

    /**
     * @notice Initialize any state variables that would normally be set in the contructor.
     * @dev Initialization functionality MUST be implemented in inherited upgradeable contract if the child contract requires
     * variable initialization on creation. This is because the contructor of the child contract will not execute
     * and set any state when the Proxy contract targets it.
     * This function MUST be called stright after the Upgradeable contract is set as the target of the Proxy. This method
     * can be overwridden so that it may have arguments. Make sure that the initializeOnceOnly() modifier is used to protect
     * from being initialized more than once.
     * If a contract is upgraded twice, pay special attention that the state variables are not initialized again
     */
    /*function initialize() public initializeOnceOnly {
        // initialize contract state variables here
    }*/

    function setProxy(address payable theAddress) public onlyOwner {
        proxy = theAddress;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint256 value) external returns (bool);
    function withdraw(uint256) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

interface ILPERC20 {
    function token0() external view returns (address);
    function token1() external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

interface ISushiV2 {
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB, uint256 liquidity);

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);

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

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);
    
    function getAmountsOut(
        uint256 amountIn,
        address[] calldata path
    ) external view returns (uint256[] memory amounts);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

interface ISushiSwapFactory {
    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);
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
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
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
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

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
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

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

pragma solidity >=0.8.0 <0.9.0;
pragma experimental ABIEncoderV2;

import "./Ownable.sol";

/*
 * @title Proxied v0.5
 * @author Jack Tanner
 * @notice The Proxied contract acts as the parent contract to Proxy and Upgradeable with and creates space for
 * state variables, functions and events that will be used in the upgraeable system.
 *
 * @dev Both the Proxy and Upgradeable need to hae the target and initialized state variables stored in the exact
 * same storage location, which is why they must both inherit from Proxied. Defining them in the saparate contracts
 * does not work.
 *
 * @param target - This stores the current address of the target Upgradeable contract, which can be modified by
 * calling upgradeTo()
 *
 * @param initialized - This mapping records which targets have been initialized with the Upgradeable.initialize()
 * function. Target Upgradeable contracts can only be intitialed once.
 */
abstract contract OwnableProxied is Ownable {
    address public target;
    mapping(address => bool) public initialized;

    event EventUpgrade(
        address indexed newTarget,
        address indexed oldTarget,
        address indexed admin
    );
    event EventInitialized(address indexed target);

    function upgradeTo(address _target) public virtual;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/utils/Context.sol";

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

    function changeOwner(address newOwner) public onlyOwner returns (bool) {
        _owner = newOwner;
        return true;
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
        return msg.data;
    }
}

