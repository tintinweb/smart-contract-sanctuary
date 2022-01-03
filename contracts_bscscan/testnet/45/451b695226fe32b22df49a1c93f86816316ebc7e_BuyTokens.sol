pragma solidity ^0.8.6;

import "./Libraries.sol";

contract TokenContract {
    function balanceOf(address who) external view returns (uint256){}
    function allowance(address owner, address spender) external view returns (uint256){}
    function approve(address spender, uint256 amount) external returns (bool){}
}

contract BuyTokens {
    mapping (address => uint) balanceOf;
    address owner_;

    address constant PancakeRouterAddr = 0xD99D1c33F9fC3444f8101754aBC46c52416550D1;

    constructor() {
        owner_ = msg.sender;
    }

    address wbnb_token = 0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd;

    IUniswapV2Router02 constant router = IUniswapV2Router02(PancakeRouterAddr);


    function SellTokens(address _from_token) external {
        TokenContract token = TokenContract(_from_token);
        uint256 token_balance = token.balanceOf(address(this));

        if(token.allowance(address(this), PancakeRouterAddr) == 0) {
            token.approve(PancakeRouterAddr, 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        }

        address[] memory path;
        path = new address[](2);
        path[0] = _from_token;
        path[1] = wbnb_token;

        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            token_balance,
            0,
            path,
            msg.sender,
            block.timestamp + 20*60
        );
    }

    function BuyTokensWithETH(address _from_token, address _to_token) external {

        require(balanceOf[msg.sender] > 0);

        address[] memory path;
        path = new address[](2);
        path[0] = _from_token;
        path[1] = _to_token;

        uint256 balance = balanceOf[msg.sender];

        balanceOf[msg.sender] = 0;

        router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: balance/2}(
            0,
            path,
            address(this),
            block.timestamp + 20*60
        );

        // SellTokens(_to_token);
    }

    function Deposit() external payable {
        balanceOf[msg.sender] += msg.value;
    }

    function readBalances(address checkBalance) external view returns(uint256){
        return balanceOf[checkBalance];
    }
}