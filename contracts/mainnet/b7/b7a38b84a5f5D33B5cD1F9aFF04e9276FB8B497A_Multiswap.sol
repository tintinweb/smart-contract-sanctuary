// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./interfaces/IUniswapV2Router02.sol";
import "./libraries/SafeMath.sol";
import "./libraries/SafeERC20.sol";

contract Multiswap {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // WETH Address
    address private immutable WETH;

    // Uniswap Router for swaps
    IUniswapV2Router02 private immutable uniswapRouter;

    // Referral data
    mapping (address => bool) private referrers;
    mapping (address => uint256) private referralFees;

    // Data struct
    struct ContractData {
        uint160 owner;
        uint16 swapFeeBase;
        uint16 swapFeeToken;
        uint16 referralFee;
        uint16 maxFee;
    }
    
    ContractData private data;

    // Modifier for only owner functions
    modifier onlyOwner {
        require(msg.sender == address(data.owner), "Not allowed");
        _;
    }

    /**
     * @dev Constructor sets values for Uniswap, WETH, and fee data
     * 
     * These values are the immutable state values for Uniswap and WETH.
     *
    */
    constructor() {
        uniswapRouter = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        WETH = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
        
        data.owner = uint160(msg.sender);
        // add extra two digits to percent for accuracy (30 = 0.3)
        data.swapFeeBase = uint16(30); // 0.3%
        data.swapFeeToken = uint16(20); // 0.2% per token
        data.referralFee = uint16(4500); // 45% for referrals
        data.maxFee = uint16(150); // 1.5% max fee

        // Add standard referrers
        referrers[address(this)] = true;
        referrers[address(0x1190074795DAD0E61b61270De48e108427f8f817)] = true;
    }
    
    /**
     * @dev Enables receiving ETH with no function call
    */
    receive() external payable {}
    fallback() external payable {}

    /**
     * @dev Checks and returns expected output fom ETH swap.
    */
    function checkOutputsETH(
        address[] memory _tokens,
        uint256[] memory _percent,
        uint256 _total
    ) external view returns (address[] memory, uint256[] memory, uint256)
    {
        require(_tokens.length == _percent.length);

        uint256 _totalPercent = 0;
        (uint256 valueToSend, uint256 feeAmount) = applyFeeETH(_total, _tokens.length);

        uint256[] memory _outputAmount = new uint256[](_tokens.length);

        for (uint256 i = 0; i < _tokens.length; i++) {
            _totalPercent += _percent[i];
            (_outputAmount[i],) = calcOutputEth(
                _tokens[i],
                valueToSend.mul(_percent[i]).div(100)
            );
        }

        require(_totalPercent == 100);

        return (_tokens, _outputAmount, feeAmount);
    }

    /**
     * @dev Checks and returns expected output from token swap.
    */
    function checkOutputsToken(
        address[] memory _tokens,
        uint256[] memory _percent,
        address _base,
        uint256 _total
        ) external view returns (address[] memory, uint256[] memory)
    {
        require(_tokens.length == _percent.length);
        
        uint256 _totalPercent = 0;
        uint256[] memory _outputAmount = new uint256[](_tokens.length);
        address[] memory path = new address[](3);
        path[0] = _base;
        path[1] = WETH;
        
        for (uint256 i = 0; i < _tokens.length; i++) {
            _totalPercent += _percent[i];
            path[2] = _tokens[i];
            uint256[] memory expected = uniswapRouter.getAmountsOut(_total.mul(_percent[i]).div(100), path);
            _outputAmount[i] = uint256(expected[1]);
        }
        
        require(_totalPercent == 100);
        
        return (_tokens, _outputAmount);
    }
    
    /**
     * @dev Checks and returns ETH value of token amount.
    */
    function checkTokenValueETH(address _token, uint256 _amount)
        public
        view
        returns (uint256)
    {
        address[] memory path = new address[](2);
        path[0] = _token;
        path[1] = WETH;
        uint256[] memory expected = uniswapRouter.getAmountsOut(_amount, path);
        return expected[1];
    }
    
    /**
     * @dev Checks and returns ETH value of portfolio.
    */
    function checkAllValue(address[] memory _tokens, uint256[] memory _amounts)
        public
        view
        returns (uint256)
    {
        uint256 totalValue;
        
        for (uint i = 0; i < _tokens.length; i++) {
            totalValue += checkTokenValueETH(_tokens[i], _amounts[i]);
        }
        
        return totalValue;
    }
    
    /**
     * @dev Internal function to calculate the output from one ETH swap.
    */
    function calcOutputEth(address _token, uint256 _value)
        internal
        view
        returns (uint256, address[] memory)
    {
        address[] memory path = new address[](2);
        path[0] = WETH;
        path[1] = _token;
        
        uint256[] memory expected = uniswapRouter.getAmountsOut(_value, path);
        
        return (expected[1], path);
    }

    /**
     * @dev Internal function to calculate the output from one token swap.
    */
    function calcOutputToken(address[] memory _path, uint256 _value)
        internal
        view
        returns (uint256[] memory expected)
    {
        
        expected = uniswapRouter.getAmountsOut(_value, _path);
        return expected;
    }

    /**
     * @dev Execute ETH swap for each token in portfolio.
    */
    function makeETHSwap(address[] memory _tokens, uint256[] memory _percent, address _referrer)
        external
        payable
        returns (uint256[] memory)
    {
        (uint256 valueToSend, uint256 feeAmount) = applyFeeETH(msg.value, _tokens.length);
        uint256 totalPercent;
        uint256[] memory outputs = new uint256[](_tokens.length);
        address[] memory path = new address[](2);
        path[0] = WETH;

        for (uint256 i = 0; i < _tokens.length; i++) {
            totalPercent += _percent[i];
            require(totalPercent <= 100, 'Exceeded 100%');

            path[1] = _tokens[i];

            uint256 swapVal = valueToSend.mul(_percent[i]).div(100);
            uint256[] memory expected = uniswapRouter.getAmountsOut(swapVal, path);
            uint256[] memory out = uniswapRouter.swapExactETHForTokens{value: swapVal}(
                expected[1],
                path,
                msg.sender,
                block.timestamp + 1200
            );
            outputs[i] = out[1];
        }

        require(totalPercent == 100, 'Percent not 100');
        
        if (_referrer != address(this)) {
            uint256 referralFee = takeReferralFee(feeAmount, _referrer);
            (bool sent, ) = _referrer.call{value: referralFee}("");
            require(sent, 'Failed to send referral fee');
        }
        
        return outputs;
    }

    /**
     * @dev Execute token swap for each token in portfolio.
    */
    function makeTokenSwap(
        address[] memory _tokens,
        uint256[] memory _percent,
        address _base,
        uint256 _total)
        external returns (uint256[] memory)
    {
        IERC20 token = IERC20(_base);
        uint256 totalPercent = 0;
        uint256[] memory outputs = new uint256[](_tokens.length);

        token.safeTransferFrom(msg.sender, address(this), _total);

        require(token.approve(address(uniswapRouter), _total), 'Uniswap approval failed');
        
        address[] memory path = new address[](3);
        path[0] = _base;
        path[1] = WETH;
        
        for (uint256 i = 0; i < _tokens.length; i++) {
            totalPercent += _percent[i];

            require(totalPercent <= 100, 'Exceeded 100');
            
            path[2] = _tokens[i];            
            uint256 swapVal = _total.mul(_percent[i]).div(100);
            uint256[] memory expected = uniswapRouter.getAmountsOut(swapVal, path);

            uint256[] memory out = uniswapRouter.swapExactTokensForTokens(
                expected[0],
                expected[1],
                path,
                msg.sender,
                block.timestamp + 1200
            );
            
            outputs[i] = out[1];
        }

        require(totalPercent == 100, 'Percent not 100');
        
        return outputs;
    }
    
    /**
     * @dev Swap tokens for ETH
    */
    function makeTokenSwapForETH(
        address[] memory _tokens,
        uint256[] memory _amounts,
        address _referrer
    ) external payable returns (uint256)
    {
        address[] memory path = new address[](2);
        path[1] = WETH;
        uint256 totalOutput;
        
        for (uint i = 0; i < _tokens.length; i++) {
            path[0] = _tokens[i];
            IERC20 token = IERC20(_tokens[i]);
            token.transferFrom(msg.sender, address(this), _amounts[i]);
            token.approve(address(uniswapRouter), _amounts[i]);
            uint256[] memory expected = uniswapRouter.getAmountsOut(_amounts[i], path);
            uint256[] memory swapOutput = uniswapRouter.swapExactTokensForETH(expected[0], expected[1], path, address(this), block.timestamp + 1200);
            totalOutput = totalOutput.add(swapOutput[1]);
        }

        (uint256 valueToSend, uint256 feeAmount) = applyFeeETH(totalOutput, _tokens.length);

        if (_referrer != address(this)) {
            uint256 referralFee = takeReferralFee(feeAmount, _referrer);
            (bool sent, ) = _referrer.call{value: referralFee}("");
            require(sent, 'Failed to send referral fee');
        }
        
       (bool delivered, ) = msg.sender.call{value: valueToSend}("");
       require(delivered, 'Failed to send swap output');
        
        return valueToSend;
    }

    /**
     * @dev Apply fee to total value amount for ETH swap.
    */
    function applyFeeETH(uint256 _amount, uint256 _numberOfTokens)
        private
        view
        returns (uint256 valueToSend, uint256 feeAmount)
    {
        uint256 feePercent = _numberOfTokens.mul(data.swapFeeToken);
        feePercent -= data.swapFeeToken;
        feePercent += data.swapFeeBase;

        feeAmount = _amount.mul(feePercent).div(10000);
        valueToSend = _amount.sub(feeAmount);

        return (valueToSend, feeAmount);
    }

    /**
     * @dev Take referral fee and distribute
    */
    function takeReferralFee(uint256 _fee, address _referrer) internal returns (uint256) {
        require(referrers[_referrer], 'Not signed up as referrer');
        uint256 referralFee = _fee.mul(data.referralFee).div(10000);
        referralFees[_referrer] = referralFees[_referrer].add(referralFee);
        
        return referralFee;
    }

    /**
     * @dev Owner only function to update contract fees.
    */
    function updateFee(
        uint16 _newFeeBase,
        uint16 _newFeeToken,
        uint16 _newFeeReferral,
        uint16 _newMaxFee
    ) public onlyOwner returns (bool) {
        data.swapFeeBase = _newFeeBase;
        data.swapFeeToken = _newFeeToken;
        data.referralFee = _newFeeReferral;
        data.maxFee = _newMaxFee;
        
        return true;
    }

    /**
     * @dev Returns current app fees.
    */
    function getCurrentFee()
        external
        view
        returns (
            uint16,
            uint16,
            uint16,
            uint16
        )
    {
        return (data.swapFeeBase, data.swapFeeToken, data.referralFee, data.maxFee);
    }

    /**
     * @dev Owner only function to change contract owner.
    */
    function changeOwner(address newOwner) external onlyOwner returns (bool) {
        data.owner = uint160(newOwner);
        return true;
    }

    /**
     * @dev Owner only function to change contract owner.
    */
    function addReferrer(address _referrer) external onlyOwner returns (bool) {
        referrers[_referrer] = true;
        return true;
    }

    /**
     * @dev Owner only function to change contract owner.
    */
    function removeReferrer(address _referrer) external onlyOwner returns (bool) {
        referrers[_referrer] = false;
        return true;
    }

    /**
     * @dev Return owner address
    */
    function getOwner() external view returns (address) {
        return address(data.owner);
    }
    
    /**
     * @dev Function to see referral balancees
    */
    function getReferralFees(address _referrer) external view returns (uint256) {
        return referralFees[_referrer];
    }

    /**
     * @dev Owner only function to retreive ETH fees
    */
    function retrieveEthFees() external onlyOwner {
        (bool sent, ) = address(data.owner).call{value: address(this).balance}("");
        require(sent, 'Transfer failed');
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

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

// SPDX-License-Identifier: Unlicensed

pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
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
        return verifyCallResult(success, returndata, errorMessage);
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
        return verifyCallResult(success, returndata, errorMessage);
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
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
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

pragma solidity ^0.8.0;

import "../interfaces/IERC20.sol";
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

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

