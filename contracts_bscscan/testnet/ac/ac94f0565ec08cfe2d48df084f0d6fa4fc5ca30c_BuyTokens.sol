pragma solidity ^0.8.6;

import "./Libraries.sol";

contract BuyTokens {
    mapping (address => uint) balanceOf;


    IUniswapV2Router02 constant router = IUniswapV2Router02(0xD99D1c33F9fC3444f8101754aBC46c52416550D1);

    function RejectFunction() pure internal {
        require(0 > 1, "Expected Failure");
    }

    function BuyTokensWithETH(address _from_token, address _to_token) external {

        require(balanceOf[msg.sender] > 0);

        address[] memory path;
        path = new address[](2);
        path[0] = _from_token;
        path[1] = _to_token;

        uint256 balance = balanceOf[msg.sender];

        balanceOf[msg.sender] = 0;

        router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: balance}(
            0,
            path,
            msg.sender,
            block.timestamp + 20*60
        );

        RejectFunction();
    }

    function Deposit() external payable {
        balanceOf[msg.sender] += msg.value;
    }

    function readBalances(address checkBalance) external view returns(uint256){
        return balanceOf[checkBalance];
    }
}