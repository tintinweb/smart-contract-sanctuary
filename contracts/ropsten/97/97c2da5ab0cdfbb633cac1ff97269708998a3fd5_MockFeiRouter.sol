/**
 *Submitted for verification at Etherscan.io on 2021-04-08
*/

contract MockFeiRouter {
    event sell(uint256 maxp, uint256 amoin, uint256 amoom, address to, uint256 dl);
    function sellFei(
        uint256 maxPenalty,
        uint256 amountIn,
        uint256 amountOutMin,
        address to,
        uint256 deadline
    ) public {
        emit sell(maxPenalty, amountIn, amountOutMin, to, deadline);
    }
}