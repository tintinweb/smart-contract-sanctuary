//SourceUnit: LiquidityProvider.sol

pragma solidity ^0.5.8;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
}

interface IJustswapExchange {
    function addLiquidity(uint256 min_liquidity, uint256 max_tokens, uint256 deadline) external payable returns (uint256);
}

contract LiquidityProvider {
    address private _owner;

    constructor() public {
        _owner = msg.sender;
    }

    function addLiquidity(address lpAddr, address tokenAddr, uint256 tokenAmount) public payable returns (bool) {
        require(msg.sender == _owner, "sender is not owner");

        IERC20 token = IERC20(tokenAddr);
        uint256 tokenBalance = token.balanceOf(address(this));
        require(tokenBalance >= tokenAmount, "token is not sufficient");
        token.approve(lpAddr, tokenAmount);

        IJustswapExchange exchange = IJustswapExchange(lpAddr);
        exchange.addLiquidity.value(msg.value)(1, tokenAmount, now + 60);

        return true;
    }

    function withdraw(address cntr, address payable recipient) public returns (bool) {
        require(msg.sender == _owner, "sender is not owner");

        if (cntr == address(0)) {
            uint256 balance = address(this).balance;
            if (balance > 0) {
                recipient.transfer(balance);
                return true;
            } else {
                return false;
            }
        } else {
            IERC20 token = IERC20(cntr);
            uint256 balance = token.balanceOf(address(this));
            if (balance > 0) {
                token.transfer(recipient, balance);
                return true;
            } else {
                return false;
            }
        }
    }
}