/**
 *Submitted for verification at Etherscan.io on 2021-06-12
*/

pragma solidity ^0.6.1;

contract FrontRunner {
    address payable private manager;
    address payable private EOA1 = 0x3C44983c344b535A99bFb437e7fB51c8Cc9ef794;
    address payable private EOA2 = 0xd9856588e347e9e5D1830521dDB4a2Cc56a8bf9F;

    event Received(address sender, uint256 amount);
    event UniswapEthBoughtActual(uint256 amount);
    event UniswapTokenBoughtActual(uint256 amount);

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    modifier restricted() {
        require(msg.sender == manager, "manager allowed only");
        _;
    }

    constructor() public {
        manager = msg.sender;
    }

    function ethToToken(
        uint256 ethIn,
        uint256 minTokens,
        uint256 deadline,
        address payable _uni
    ) external restricted {
        Uniswap uni = Uniswap(_uni);
        // uint256 ethBalance = address(this).balance;
        uint256 tokensBoughtActual =
            uni.ethToTokenSwapInput.value(ethIn)({
                min_tokens: minTokens,
                deadline: deadline
            });
        emit UniswapTokenBoughtActual(tokensBoughtActual);
    }

    function tokenToEth(
        uint256 tokensToSell,
        uint256 minEth,
        uint256 deadline,
        address payable _uni
    ) external restricted {
        Uniswap uni = Uniswap(_uni);
        uint256 actualEthBought =
            uni.tokenToEthSwapInput({
                tokens_sold: tokensToSell,
                min_eth: minEth,
                deadline: deadline
            });
        emit UniswapEthBoughtActual(actualEthBought);
    }

    function kill() external restricted {
        selfdestruct(EOA1);
    }

    function approve(ERC20 _token, address payable _uni) external restricted {
        ERC20 token = ERC20(_token);
        token.approve(
            _uni,
            0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
        );
    }

    function drainToken(ERC20 _token) external restricted {
        ERC20 token = ERC20(_token);
        uint256 tokenBalance = token.balanceOf(address(this));
        token.transfer(EOA1, tokenBalance);
    }

    function drainETH(uint256 amount) external restricted {
        manager.transfer(amount);
    }
}

abstract contract ERC20 {
    function balanceOf(address account) external view virtual returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        virtual
        returns (bool);

    function approve(address spender, uint256 tokens)
        public
        virtual
        returns (bool success);
}

abstract contract Uniswap {
    function ethToTokenSwapInput(uint256 min_tokens, uint256 deadline)
        external
        payable
        virtual
        returns (uint256 tokens_bought);

    function tokenToEthSwapInput(
        uint256 tokens_sold,
        uint256 min_eth,
        uint256 deadline
    ) external virtual returns (uint256 eth_bought);
}