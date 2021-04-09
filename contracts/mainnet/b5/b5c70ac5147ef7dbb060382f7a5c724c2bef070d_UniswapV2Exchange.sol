/**
 *Submitted for verification at Etherscan.io on 2021-04-09
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
}

interface Uni {
    function swapExactTokensForTokens(
        uint256,
        uint256,
        address[] calldata,
        address,
        uint256
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint amountOut, 
        uint amountInMax, 
        address[] calldata path, 
        address to, 
        uint deadline)
    external
    returns (uint[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint amountOutMin, 
        address[] calldata path, 
        address to, 
        uint deadline
    ) external payable returns (uint[] memory amounts);
}

library UniswapV2Exchange {
    address public constant DEX = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    function swapExactERC20ForERC20(
        address _from,
        address _to,
        address _recipient,
        uint256 _fromAmount
    ) external returns (uint256[] memory amounts) {
        if(_fromAmount == 0) { return amounts; }
        // approve tokens to the DEX 
        IERC20(_from).approve(DEX, _fromAmount);

        address[] memory _path = new address[](3);
        _path[0] = _from;
        _path[1] = WETH;
        _path[2] = _to;

        return
            Uni(DEX).swapExactTokensForTokens(
                _fromAmount,
                uint256(0),
                _path,
                _recipient,
                block.timestamp + 1800
            );
    }

    function swapERC20ForExactERC20(
        address _from,
        address _to,
        address _recipient,
        uint256 _amountOut
    ) external returns (uint256[] memory amounts) {
        uint256 _bal = IERC20(_from).balanceOf(address(this));
        if(_bal == 0) { return amounts; }
        // approve tokens to the DEX
        IERC20(_from).approve(DEX, _bal);

        address[] memory _path = new address[](3);
        _path[0] = _from;
        _path[1] = WETH;
        _path[2] = _to;

        return
            Uni(DEX).swapTokensForExactTokens(
                _amountOut,
                _bal,
                _path,
                _recipient,
                block.timestamp + 1800
            );
    }

    function swapERC20ForExactETH(
        address _from,
        address _recipient,
        uint256 _amountOut
    ) external returns (uint256[] memory amounts) {
        uint256 _bal = IERC20(_from).balanceOf(address(this));
        if(_bal == 0) { return amounts; }
        // approve tokens to the DEX
        IERC20(_from).approve(DEX, _bal);

        address[] memory _path = new address[](2);
        _path[0] = _from;
        _path[1] = WETH;

        return
            Uni(DEX).swapTokensForExactETH(
                _amountOut,
                _bal,
                _path,
                _recipient,
                block.timestamp + 1800
            );
    }

    function swapExactERC20ForETH(
        address _from,
        address _recipient,
        uint256 _amountIn
    ) external returns (uint256[] memory amounts) {
        if(_amountIn == 0) { return amounts; }
        // approve tokens to the DEX
        IERC20(_from).approve(DEX, _amountIn);

        address[] memory _path = new address[](2);
        _path[0] = _from;
        _path[1] = WETH;

        return
            Uni(DEX).swapExactTokensForETH(
                _amountIn,
                0,
                _path,
                _recipient,
                block.timestamp + 1800
            );
    }

    function swapETHForExactERC20(
        address _to,
        address _recipient,
        uint256 _amountOut
    ) external returns (uint256[] memory amounts) {
        if(address(this).balance == 0) { return amounts; }
        
        address[] memory _path = new address[](2);
        _path[0] = WETH;
        _path[1] = _to;

        bytes memory _data = abi.encodeWithSelector(Uni(DEX).swapETHForExactTokens.selector, _amountOut, _path, _recipient, block.timestamp + 1800);

        (bool success, bytes memory _amounts) = DEX.call{value:address(this).balance}(_data);
        require(success, "swapETHForExactERC20: uniswap swap failed.");

        (amounts) = abi.decode(
            _amounts,
            (uint256[])
        );
    }

    function swapExactETHForERC20(
        address _to,
        address _recipient,
        uint256 _amountOutMin
    ) external returns (uint256[] memory amounts) {
        if(address(this).balance == 0) { return amounts; }
        
        address[] memory _path = new address[](2);
        _path[0] = WETH;
        _path[1] = _to;

        bytes memory _data = abi.encodeWithSelector(Uni(DEX).swapExactETHForTokens.selector, _amountOutMin, _path, _recipient, block.timestamp + 1800);

        (bool success, bytes memory _amounts) = DEX.call{value:address(this).balance}(_data);
        require(success, "swapExactETHForERC20: uniswap swap failed.");

        (amounts) = abi.decode(
            _amounts,
            (uint256[])
        );
    }
}