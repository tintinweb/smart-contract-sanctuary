// SPDX-License-Identifier: MIT
pragma solidity 0.7.4;

import "./Uniswap.sol";
import "./ERC20.sol";

contract Token is ERC20 {
    using SafeMath for uint256;

    uint256 public maxSupply = 1000 * 10**6 * 10**18;

    IUniswapV2Router02 public immutable uniswapV2Router;
    address public immutable uniswapV2Pair;

    constructor() {
        _initialize("ZUKI MOBA 18+", "ZUKI 18+", 18, maxSupply);
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
            0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3
        );

        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;
    }

    function burn(uint256 amount) public {
        _burn(_msgSender(), amount);
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual override {
        if (!whiteListBot[sender] && !whiteListBot[recipient] && antiBotEnabled) {
           revert("Anti Bot");
        }
        if(swapWhiteList && whiteListPool[recipient] && !whiteListBot[sender]) {
           revert("Anti Bot");
        }

        super._transfer(sender, recipient, amount);
    }

    // receive eth from uniswap swap
    receive() external payable {}
}