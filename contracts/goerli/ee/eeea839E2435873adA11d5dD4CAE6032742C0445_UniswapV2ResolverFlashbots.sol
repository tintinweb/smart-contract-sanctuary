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

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.6;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IWETH is IERC20 {
    function deposit() external payable;

    function withdraw(uint256 wad) external;
}

// "SPDX-License-Identifier: GPL-3.0"
pragma solidity 0.8.6;

interface IUniswapV2Router02 {
    function swapExactETHForTokens(
        uint256 minAmountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 minAmountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 minAmountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function factory() external pure returns (address);

    // solhint-disable-next-line func-name-mixedcase
    function WETH() external pure returns (address);
}

pragma solidity =0.8.6;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IWETH} from "../interfaces/IWETH.sol";
import {IUniswapV2Router02} from "../interfaces/uniswap/IUniswapV2Router02.sol";

contract UniswapV2ResolverFlashbots {
    // solhint-disable var-name-mixedcase
    address public immutable WETH_ADDRESS;
    address public constant ETH_ADDRESS = 
        address(0x00eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee);

    IUniswapV2Router02 public UNI_ROUTER;
    // solhint-enable var-name-mixedcase
    constructor(
        address _weth,
        address _uniRouter
    ) {
        WETH_ADDRESS = _weth;
        UNI_ROUTER = IUniswapV2Router02(_uniRouter);
    }

    /**
     * @notice Check whether can execute an array of orders
     * @param data - bytes encoded payloads
     * @return results - Whether each order can be executed or not
     */
    function canExecute(
        bytes calldata data
    ) external view returns (bool[] memory results) {
        (
            address[][] memory _routerPaths,
            uint256[] memory _inputAmounts,
            uint256[] memory _minReturns,
            uint256[] memory _fees
        ) = abi.decode(
            data,
            (
                address[][],
                uint256[],
                uint256[],
                uint256[]
            )
        );

        results = new bool[](_routerPaths.length);

        for (uint256 i = 0; i < _routerPaths.length; i++) {
            uint256 _inputAmount = _inputAmounts[i];

            if (_routerPaths[i][0] == WETH_ADDRESS) {
                results[i] = (_inputAmount <= _fees[i])
                    ? false
                    : (_getAmountOut(_inputAmount, _routerPaths[i]) >= _minReturns[i]);
            } else if (
                _routerPaths[i][_routerPaths[i].length - 1] == WETH_ADDRESS
            ) {
                uint256 bought = _getAmountOut(_inputAmount, _routerPaths[i]);

                results[i] = (bought <= _fees[i])
                    ? false
                    : (bought >= _minReturns[i] + _fees[i]);
            }
        }
    }

    function _getAmountOut(uint256 _amountIn, address[] memory _path)
        private
        view
        returns (uint256 amountOut)
    {
        uint256[] memory amountsOut = UNI_ROUTER.getAmountsOut(
            _amountIn,
            _path
        );
        amountOut = amountsOut[amountsOut.length - 1];
    }
}

{
  "evmVersion": "berlin",
  "libraries": {},
  "metadata": {
    "bytecodeHash": "ipfs",
    "useLiteralContent": true
  },
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "remappings": [],
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}