// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.4;

import "../../../../../interfaces/exchanges/IUniV3.sol";
import "../../../../../interfaces/markets/tokens/IERC20.sol";

library UniswapV3Exchange {

    address public constant DEX = 0xE592427A0AEce92De3Edee1F18E0157C05861564;
    address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
        bool isInputEth;
    }

    struct ExactInputParams {
        bytes path;
        address tokenIn;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        bool isInputEth;
    }

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
        bool isInputEth;
    }

    struct ExactOutputParams {
        bytes path;
        address tokenIn;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        bool isInputEth;
    }

    struct MultiCall {
        bytes[] data;
        address tokenIn;
        uint256 amountIn;
        bool isInputEth;
    }

    function _checkCallResult(bool _success) internal pure {
        if (!_success) {
            // Copy revert reason from call
            assembly {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }
    }

    function _approve(address _token, uint256 _amount, bool isInputEth) internal {
        if (!isInputEth) {
            if (IERC20(_token).allowance(address(this), DEX) < _amount) {
                IERC20(_token).approve(DEX, ~uint256(0));
            }
        }
    }

    function exactInputSingle(ExactInputSingleParams calldata params) external {
        // approve token if needed
        _approve(params.tokenIn, params.amountIn, params.isInputEth);
        
        bytes memory _data = abi.encodeWithSelector(
            IUniV3.exactInputSingle.selector,
            params.tokenIn,
            params.tokenOut,
            params.fee,
            params.recipient,
            params.deadline,
            params.amountIn,
            params.amountOutMinimum,
            params.sqrtPriceLimitX96
        );
        
        (bool success, ) = DEX.call{value: params.isInputEth ? params.amountIn : 0}(_data);
        
        _checkCallResult(success);
    }

    function exactInput(ExactInputParams calldata params) external {
        // approve token if needed
        _approve(params.tokenIn, params.amountIn, params.isInputEth);

        bytes memory _data = abi.encodeWithSelector(
            IUniV3.exactInput.selector,
            params.path,
            params.recipient,
            params.deadline,
            params.amountIn,
            params.amountOutMinimum
        );
        
        (bool success, ) = DEX.call{value: params.isInputEth ? params.amountIn : 0}(_data);
        
        _checkCallResult(success);
    }

    function exactOutputSingle(ExactOutputSingleParams calldata params) external {
        // approve token if needed
        _approve(params.tokenIn, params.amountInMaximum, params.isInputEth);

        bytes memory _data = abi.encodeWithSelector(
            IUniV3.exactOutputSingle.selector,
            params.tokenIn,
            params.tokenOut,
            params.fee,
            params.recipient,
            params.deadline,
            params.amountOut,
            params.amountInMaximum,
            params.sqrtPriceLimitX96
        );
        
        (bool success, ) = DEX.call{value: params.isInputEth ? params.amountInMaximum : 0}(_data);
        
        _checkCallResult(success);
    }

    function exactOutput(ExactOutputParams calldata params) external {
        // approve token if needed
        _approve(params.tokenIn, params.amountInMaximum, params.isInputEth);

        bytes memory _data = abi.encodeWithSelector(
            IUniV3.exactOutputSingle.selector,
            params.path,
            params.recipient,
            params.deadline,
            params.amountOut,
            params.amountInMaximum
        );
        
        (bool success, ) = DEX.call{value: params.isInputEth ? params.amountInMaximum : 0}(_data);
        
        _checkCallResult(success);
    }

    function multicall(MultiCall calldata params) external {
        // approve token if needed
        _approve(params.tokenIn, params.amountIn, params.isInputEth);
        
        bytes memory _data = abi.encodeWithSelector(
            IUniV3.multicall.selector,
            params.data
        );

        (bool success, ) = DEX.call{value: params.isInputEth ? params.amountIn : 0}(_data);
        
        _checkCallResult(success);
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.4;

interface IUniV3 {
    
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
    }
    
    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);

    /// @notice Enables calling multiple methods in a single call to the contract
    function multicall(bytes[] calldata data) external payable returns (bytes[] memory results);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.4;

interface IERC20 {
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
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);
}

{
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}