/**
 *Submitted for verification at Etherscan.io on 2021-09-27
*/

pragma solidity ^0.5.17;
pragma experimental ABIEncoderV2;

contract ERC20 {
	function balanceOf(address who) external returns (uint256);
	function transfer(address to, uint256 value) external returns (bool);
}

contract BalancerRouter {
    
    struct BatchSwapStep {
        bytes32 poolId;
        uint256 assetInIndex;
        uint256 assetOutIndex;
        uint256 amount;
        bytes userData;
    }
    
    struct FundManagement {
        address sender;
        bool fromInternalBalance;
        address recipient;
        bool toInternalBalance;
    }
    function batchSwap(
        uint8 kind,
        BatchSwapStep[] calldata swaps,
        address[] calldata assets,
        FundManagement calldata funds,
        int256[] calldata limits,
        uint256 deadline
    ) external returns (int256[] memory assetDeltas);
    
}

contract BalancerFactory {
    BalancerRouter router;
    constructor(BalancerRouter r) public {
        router = r;
    }
    
    function swapBalanceToken(uint256 amountIn, address[] calldata path, bytes32[] calldata balancerPoolId) external returns (uint256) {
        uint256 index;
        // BalancerRouter.BatchSwapStep[] memory stepArray = new BalancerRouter.BatchSwapStep[](balancerPoolId.length);
        BalancerRouter.BatchSwapStep[] memory stepArray;
        int256[] memory limits;
        for (uint256 i = 0; i < balancerPoolId.length; i++) {
            BalancerRouter.BatchSwapStep memory step = BalancerRouter.BatchSwapStep(balancerPoolId[i], index, ++index, amountIn, new bytes(0));
            stepArray[i] = step;
            limits[i] = 0;
        }
        limits[0] = (int256)(amountIn);
        BalancerRouter.FundManagement memory funds = BalancerRouter.FundManagement(msg.sender, false, msg.sender, false);
        uint256 deadline = 115792089237316195423570985008687907853269984665640564039457584007913129639935;
        router.batchSwap((uint8)(0), stepArray, path, funds, limits, deadline);
    }
}