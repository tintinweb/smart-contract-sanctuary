// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "./interface/ICrowdswap.sol";
import "./interface/IUniswapV2Router02.sol";
import "./interface/IBancorNetwork.sol";
import "./interface/IBalancerExchangeProxy.sol";
import "./interface/IBalancerExchangeProxy.sol";
import "./interface/IKyberNetworkProxy.sol";
import "./helpers/UniERC20.sol";
import "./helpers/Ownable.sol";

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract CrowdswapV1 is Ownable, ICrowdswap {

    using UniERC20 for IERC20;
    using SafeERC20 for IERC20;

    uint256 percentage = 10**17;//0.1

    address private uniswapV2Router02;
    address private sushiswapV2Router02;
    address private bancorContractRegistry;
    address private balancerExchangeProxy;
    address private kyberNetworkProxy;

    uint8 private constant _UNISWAPV2 = 0x01;
    uint8 private constant _UNISWAPV3 = 0x02;
    uint8 private constant _SUSHISWAP = 0x03;
    uint8 private constant _BALANCER = 0x04;
    uint8 private constant _BANCOR = 0x05;
    uint8 private constant _KYBER = 0x06;

    event SwapSucceedEvent(IERC20 _destToken, uint256 amountOut, uint256 fee);
    event WithdrawTokenSucceedEvent(IERC20 token, address receiver, uint256 amount);
    event WithdrawBaseTokenSucceedEvent(address receiver, uint256 amount);

    constructor(
        address _uniswap,
        address _sushiswap,
        address _balancer,
        address _bancor,
        address _kyber
    ){
        uniswapV2Router02 = _uniswap;
        sushiswapV2Router02 = _sushiswap;
        balancerExchangeProxy = _balancer;
        bancorContractRegistry = _bancor;
        kyberNetworkProxy = _kyber;
    }

    receive() external payable {}

    fallback() external {
        revert("ce01");
    }

    function setUniswapV2Router02(address uniswapAddress) public {
        require(uniswapAddress != address(0), "ce02");
        uniswapV2Router02 = uniswapAddress;
    }

    function getUniswapV2Router02() public view returns(address){
        return uniswapV2Router02;
    }

    function setSushiswapV2Router02(address sushiAddress) public {
        require(sushiAddress != address(0), "ce02");
        sushiswapV2Router02 = sushiAddress;
    }

    function getSushiswapV2Router02() public view returns(address){
        return sushiswapV2Router02;
    }

    function setBalancerExchangeProxy(address _balancer) public {
        require(_balancer != address(0), "ce02");
        kyberNetworkProxy = _balancer;
    }

    function getBalancerExchangeProxy() public view returns(address){
        return kyberNetworkProxy;
    }

    function setBancorContractRegistry(address _bancor) public {
        require(_bancor != address(0), "ce02");
        bancorContractRegistry = _bancor;
    }

    function getBancorContractRegistry() public view returns(address){
        return bancorContractRegistry;
    }

    function setKyberNetworkProxy(address _kyber) public {
        require(_kyber != address(0), "ce02");
        balancerExchangeProxy = _kyber;
    }

    function getKyberNetworkProxy() public view returns(address){
        return balancerExchangeProxy;
    }

    function swap(
        IERC20 _fromToken,
        IERC20 _destToken,
        address payable _receiver,
        SwapDescriptor calldata _desc,
        uint8 _dexFlag
    )
    external override payable returns (uint256 returnAmount){
        if (_fromToken == _destToken) {
            return 0;
        }
        //TODO: check if there is enough ETH funds to pay during swap
        (uint256 _beforeSwappingBalance,address _dexAddress) = _prepareSwap(_fromToken, _destToken, _desc.amountIn, _dexFlag);

        //TODO: prevent the “sandwich” attack
        uint256[] memory dexResult;
        if (_dexFlag == _UNISWAPV2 || _dexFlag == _SUSHISWAP) {
            if (_fromToken.isETH()) {
                dexResult = IUniswapV2Router02(_dexAddress).swapExactETHForTokens{value : msg.value}(
                    _desc.amountOutMin,
                    _desc.path,
                    address(this),
                    _desc.deadline
                );
            } else if (_destToken.isETH()) {
                dexResult = IUniswapV2Router02(_dexAddress).swapExactTokensForETH(
                    _desc.amountIn,
                    _desc.amountOutMin,
                    _desc.path,
                    address(this),
                    _desc.deadline);
            } else {
                dexResult = IUniswapV2Router02(_dexAddress).swapExactTokensForTokens(
                    _desc.amountIn,
                    _desc.amountOutMin,
                    _desc.path,
                    address(this),
                    _desc.deadline);
            }
        }
        else if (_dexFlag == _BALANCER) {
            revert("ce99");
        }
        else if (_dexFlag == _BANCOR) {
            dexResult = new uint256[](1);
            dexResult[0] = IBancorNetwork(_dexAddress).convertByPath{value : msg.value}(
                _desc.path,
                _desc.amountIn,
                _desc.amountOutMin,
                address(0),
                address(0),
                0
            );
        }
        else if (_dexFlag == _KYBER) {
            dexResult = new uint256[](1);
            dexResult[0] = IKyberNetworkProxy(_dexAddress).tradeWithHintAndFee{value : msg.value}(
                address(_fromToken),
                _desc.amountIn,
                address(_destToken),
                payable(this),
                _desc.amountOutMin,
                0,
                payable(address(0)),
                0,
                ""
            );
        }

        uint256 amountOut = uint256(dexResult[dexResult.length - 1]);
        amountOut = _augmentSwap(_receiver, _destToken, _beforeSwappingBalance, amountOut);

        return amountOut;
    }

    function swapViaBalancer(
        IERC20 _fromToken,
        IERC20 _destToken,
        address payable _receiver,
        Swap[][] memory _swapSequences,
        uint256 _totalAmountIn,
        uint256 _minTotalAmountOut
    )
    external override payable returns (uint256){
        if (_fromToken == _destToken) {
            return 0;
        }

        //TODO: check if there is enough ETH funds to pay during swap
        uint256 beforeSwappingBalance;
        address dexAddress;
        (beforeSwappingBalance, dexAddress) = _prepareSwap(_fromToken, _destToken, _totalAmountIn, 0x04);

        //TODO: prevent the “sandwich” attack
        uint256 _amountOut = IBalancerExchangeProxy(balancerExchangeProxy).multihopBatchSwapExactIn{value : msg.value}(
            _swapSequences,
            address(_fromToken),
            address(_destToken),
            _totalAmountIn,
            _minTotalAmountOut
        );

        _amountOut = _augmentSwap(_receiver, _destToken, beforeSwappingBalance, _amountOut);

        return _amountOut;
    }

    function withdrawAllToken(address _token) external onlyOwner {
        uint256 balance = IERC20(_token).balanceOf(address(this));
        withdrawToken(_token, balance);
    }

    function withdrawAllBaseToken() external onlyOwner {
        withdrawBaseToken(address(this).balance);
    }

    function withdrawToken(address _token, uint256 _amount) public onlyOwner {
        IERC20(_token).safeTransfer(owner(), _amount);
        emit WithdrawTokenSucceedEvent(IERC20(_token), owner(), _amount);
    }

    function withdrawBaseToken(uint256 _amount) public onlyOwner {
        payable(owner()).transfer(_amount);
        emit WithdrawBaseTokenSucceedEvent(owner(), _amount);
    }

    function _retrieveDexAddress(uint8 _dexFlag) private view returns (address){
        if (_dexFlag == _UNISWAPV2) {
            return uniswapV2Router02;
        }
        else if (_dexFlag == _SUSHISWAP) {
            return sushiswapV2Router02;
        }
        else if (_dexFlag == _BALANCER) {
            return balancerExchangeProxy;
        }
        else if (_dexFlag == _BANCOR) {
            return IBancorContractRegistry(bancorContractRegistry).addressOf('BancorNetwork');
        }
        else if (_dexFlag == _KYBER) {
            return kyberNetworkProxy;
        }
        return address(0);
    }

    function _feeCalculator(
        uint256 _withdrawalAmount,
        uint256 _percentage
    ) private pure returns (uint256){
        uint256 fee = _percentage * _withdrawalAmount/ (10 ** 18)  / 100;
    return fee;
    }
    
    function setPercentage(uint256 _percentage) public  {
        require(_percentage >= 0, "ce05");
        percentage = _percentage;
    }

    function getPercentage() public view returns (uint256){
        return percentage;
    }

    function getBalance() public view returns (uint256){
        return address(this).balance;
    }

    function _prepareSwap(
        IERC20 _fromToken,
        IERC20 _destToken,
        uint256 _amountIn,
        uint8 _dexFlag
    ) private returns (uint256, address){
        require(msg.value == (_fromToken.isETH() ? _amountIn : 0), "ce06");

        uint256 _beforeSwappingBalance = _destToken.uniBalanceOf(address(this));

        address _dexAddress = _retrieveDexAddress(_dexFlag);
        require(_dexAddress != address(0), "ce07");
        if (!_fromToken.isETH()) {
            _fromToken.safeTransferFrom(msg.sender, address(this), _amountIn);
            _fromToken.uniApprove(_dexAddress, _amountIn);
        }

        return (_beforeSwappingBalance, _dexAddress);
    }

    function _augmentSwap(
        address _receiver,
        IERC20 _destToken,
        uint256 _beforeSwappingBalance,
        uint256 _amountOut
    ) private returns (uint256){
        uint256 _afterSwappingBalance = _destToken.uniBalanceOf(address(this));
        require(_afterSwappingBalance - _beforeSwappingBalance == _amountOut, "ce08");

        uint256 _fee = _feeCalculator(_amountOut, percentage);
        _amountOut = _amountOut - _fee;
        _destToken.uniTransfer(payable(_receiver), _amountOut);

        emit SwapSucceedEvent(_destToken, _amountOut, _fee);

        return _amountOut;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IBalancerExchangeProxy.sol";

interface ICrowdswap {

    struct SwapDescriptor {
        uint256 amountIn;
        address[] path;
        uint256 amountOutMin;
        uint256 deadline;
    }

    function swap(
        IERC20 fromToken,
        IERC20 destToken,
        address payable receiver,
        SwapDescriptor calldata desc,
        uint8 dexFlag
    )
    external payable returns (uint256 returnAmount);


    function swapViaBalancer(
        IERC20 _fromToken,
        IERC20 _destToken,
        address payable _receiver,
        Swap[][] memory _swapSequences,
        uint256 _totalAmountIn,
        uint256 _minTotalAmountOut
    )
    external payable returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

interface IUniswapV2Router02 {

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline) external payable returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline) external returns (uint256[] memory amounts);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

interface IBancorContractRegistry {

    function addressOf(bytes32 _contractName) external view returns (address);
}


interface IBancorNetwork {

    function convertByPath(
        address[] calldata _path,
        uint256 _amount,
        uint256 _minReturn,
        address _beneficiary,
        address _affiliateAccount,
        uint256 _affiliateFee
    ) external payable returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;


struct Swap {
    address pool;
    address tokenIn;
    address tokenOut;
    uint swapAmount; // tokenInAmount / tokenOutAmount
    uint limitReturnAmount; // minAmountOut / maxAmountIn
    uint maxPrice;
}

interface IBalancerExchangeProxy {

    function multihopBatchSwapExactIn(
        Swap[][] memory swapSequences,
        address tokenIn,
        address tokenOut,
        uint totalAmountIn,
        uint minTotalAmountOut
    )
    external payable
    returns (uint totalAmountOut);

}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

interface IKyberNetworkProxy {

    function tradeWithHintAndFee(
        address srcToken,
        uint256 srcAmount,
        address destToken,
        address payable receiverAddress,
        uint256 maxDestAmount,
        uint256 minConversionRate,
        address payable platformWallet,
        uint256 platformFeeBps,
        bytes calldata hint
    ) external payable returns (uint256 destAmount);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";


library UniERC20 {
    using SafeERC20 for IERC20;

    IERC20 private constant _ETH_ADDRESS = IERC20(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);
    IERC20 private constant _ZERO_ADDRESS = IERC20(address(0));

    function isETH(IERC20 token) internal pure returns (bool) {
        return (token == _ZERO_ADDRESS || token == _ETH_ADDRESS);
    }

    function uniBalanceOf(IERC20 token, address account) internal view returns (uint256) {
        if (isETH(token)) {
            return account.balance;
        } else {
            return token.balanceOf(account);
        }
    }

    function uniTransfer(IERC20 token, address payable to, uint256 amount) internal {
        if (amount > 0) {
            if (isETH(token)) {
                to.transfer(amount);
            } else {
                token.safeTransfer(to, amount);
            }
        }
    }

    function uniApprove(IERC20 token, address to, uint256 amount) internal {
        require(!isETH(token), "ce09");

        if (amount == 0) {
            token.safeApprove(to, 0);
        } else {
            uint256 allowance = token.allowance(address(this), to);
            if (allowance < amount) {
                token.safeIncreaseAllowance(to, amount - allowance);
            }
        }
    }
}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address private _owner;
    address private _pendingOwner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor() public {
        _owner = msg.sender;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == _owner, "ce30");
        _;
    }

    /**
    * @dev Returns the address of the current owner.
    */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
    * @dev Returns the address of the pending owner.
    */
    function pendingOwner() public view returns (address) {
        return _pendingOwner;
    }

    /**
     * @dev Allows the current owner to set the pendingOwner address.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _pendingOwner = newOwner;
    }

    /**
     * @dev Allows the pendingOwner address to finalize the transfer.
     */
    function claimOwnership() public {
        require(msg.sender == _pendingOwner, "ce31");
        _owner = _pendingOwner;
        _pendingOwner = address(0);
        emit OwnershipTransferred(_owner, _pendingOwner);
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

