/**
 *Submitted for verification at BscScan.com on 2021-12-15
*/

// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

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
interface IPancakeRouter01 {
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
interface IPancakeRouter02 is IPancakeRouter01 {
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
contract Logic {
    mapping(address => bool) private _isWhitelistedBotAddress;
    mapping(address => bool) private _isWhitelistedTransferAddress;
    mapping(address => bool) private _isWhitelistedTokenAddress;

    // Modifiers

    modifier onlyProxyOwner() {
        require (msg.sender == proxyOwner(), "Not proxy owner");
        _;
    }

    modifier onlyWhitelistedBot() {
        require(_isWhitelistedBotAddress[msg.sender] == true, "Bot address not whitelisted");
        _;
    }


    // #####################
    // Public Calls
    // #####################


    function proxyOwner() public pure returns (address owner) {
        return(0xa7Ae2994d9D6DA33aB8dd90888d41A72685F672d); // This will be hardcoded and set to the Proxy Admin address
    }


    // #####################
    // Proxy owner, public Transacts
    // #####################


    function addWhitelistedBotAddresses(address[] calldata _botAddresses)
        external onlyProxyOwner
    {
        for (uint i; i < _botAddresses.length; i++) {
            _isWhitelistedBotAddress[_botAddresses[i]] = true;
        }
    }

    function removeWhitelistedBotAddresses(address[] calldata _botAddresses)
        external onlyProxyOwner
    {
        for (uint i; i < _botAddresses.length; i++) {
            _isWhitelistedBotAddress[_botAddresses[i]] = false;
        }
    }

    // ---------------

    function addWhitelistedTransferAddresses(address[] calldata _transferAddresses)
        external onlyProxyOwner
    {
        for (uint i; i < _transferAddresses.length; i++) {
            _isWhitelistedTransferAddress[_transferAddresses[i]] = true;
        }
    }

    function removeWhitelistedTransferAddresses(address[] calldata _transferAddresses)
        external onlyProxyOwner
    {
        for (uint i; i < _transferAddresses.length; i++) {
            _isWhitelistedTransferAddress[_transferAddresses[i]] = false;
        }
    }

    // ---------------

    function addWhitelistedTokenAddresses(address[] calldata _tokenAddresses)
        external onlyProxyOwner
    {
        for (uint i; i < _tokenAddresses.length; i++) {
            _isWhitelistedTokenAddress[_tokenAddresses[i]] = true;
        }
    }

    function removeWhitelistedTokenAddresses(address[] calldata _tokenAddresses)
        external onlyProxyOwner
    {
        for (uint i; i < _tokenAddresses.length; i++) {
            _isWhitelistedTokenAddress[_tokenAddresses[i]] = false;
        }
    }

    // ---------------

    function approveTokens(address[] calldata _tokenAddresses)
        external onlyProxyOwner
    {
        for (uint i; i < _tokenAddresses.length; i++) {
            IERC20(_tokenAddresses[i]).approve(0xD99D1c33F9fC3444f8101754aBC46c52416550D1, 115792089237316195423570985008687907853269984665640564039457584007913129639935); // Pancake Router address: 0x10ED43C718714eb63d5aA57B78B54704E256024E
        }
    }

    // ---------------

    function transferChainToken(address _to, uint256 _amount)
        external onlyProxyOwner
    {
        (bool success, ) = _to.call{value:_amount}("");
        require(success, "Transfer failed.");
    }

    function transferTokenAdmin(address _tokenAddress, address _to, uint256 _amount)
        external onlyProxyOwner
    {
        IERC20(_tokenAddress).transfer(_to, _amount);
    }


    // #####################
    // Bot, public Transacts
    // #####################


    function transferToken(address _tokenAddress, address _to, uint256 _amount)
        external onlyWhitelistedBot
    {
        require(_isWhitelistedTransferAddress[_to] == true, "Transfer address not whitelisted");
        IERC20(_tokenAddress).transfer(_to, _amount);
    }

    function swapExactTokensForTokens(
        uint _amountIn,
        uint _amountOutMin,
        address[] calldata _path,
        uint _deadline
    )
        external onlyWhitelistedBot
    {
        require(_isWhitelistedTokenAddress[_path[1]] == true, "Token address not whitelisted");
        IPancakeRouter02(0xD99D1c33F9fC3444f8101754aBC46c52416550D1).swapExactTokensForTokens( // Pancake Router address: 0x10ED43C718714eb63d5aA57B78B54704E256024E
            _amountIn,
            _amountOutMin,
            _path,
            0x6AF28c07A6102B40858e3C152B2A176ec28E569E, // This will be set to Proxy address once we know it after deployment
            _deadline
        );
    }

    function swapTokensForExactTokens(
        uint _amountOut,
        uint _amountInMax,
        address[] calldata _path,
        uint _deadline
    )
        external onlyWhitelistedBot
    {
        require(_isWhitelistedTokenAddress[_path[1]] == true, "Token address not whitelisted");
        IPancakeRouter02(0xD99D1c33F9fC3444f8101754aBC46c52416550D1).swapTokensForExactTokens( // Pancake Router address: 0x10ED43C718714eb63d5aA57B78B54704E256024E
            _amountOut,
            _amountInMax,
            _path,
            0x6AF28c07A6102B40858e3C152B2A176ec28E569E, // This will be set to Proxy address once we know it after deployment
            _deadline
        );
    }
}