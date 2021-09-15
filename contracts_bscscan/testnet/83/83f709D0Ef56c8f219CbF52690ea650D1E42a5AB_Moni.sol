// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "./Uniswap.sol";
import "./ERC20.sol";

contract Moni is ERC20 {
    using SafeMath for uint256;

    uint256 public maxSupply = 1000 * 10**6 * 10**6;

    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;

    constructor()
    {
        _initialize("Monsta Infinite", "MONI", 6, maxSupply);
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
            0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3 //0x10ED43C718714eb63d5aA57B78B54704E256024E
            //https://pancake.kiemtienonline360.com/#/swap
        );

        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
        .createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;
        _approve(address(this), address(uniswapV2Router), ~uint256(0));        

    }

    function burn(uint256 amount) public {
        _burn(_msgSender(), amount);
    }    

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual override {
        if (
            !blackList[sender] && antiBotEnabled
        ) {
            revert("Anti Bot");
        }       

        super._transfer(sender, recipient, amount);
    }

    // receive eth from uniswap swap
    receive() external payable {}    
}