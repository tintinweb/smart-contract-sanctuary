/**
 *Submitted for verification at Etherscan.io on 2021-01-23
*/

pragma solidity ^0.6.12;


interface IKeep3rV1 {
    function isKeeper(address) external returns (bool);
    function worked(address keeper) external;
}

interface IYaLINK {
    function over(uint) external view returns (uint);
    function rebalance() external;
}

interface IWethStrategy {
    function repayAmount() external view returns (uint);
    function repay() external;
}

contract YearnLiquidationKeep3r {
    modifier upkeep() {
        require(KP3R.isKeeper(msg.sender), "::isKeeper: keeper is not registered");
        _;
        KP3R.worked(msg.sender);
    }
    
    
    IYaLINK public constant YALINK = IYaLINK(0x29E240CFD7946BA20895a7a02eDb25C210f9f324);
    IWethStrategy public constant WETH = IWethStrategy(0x39AFF7827B9D0de80D86De295FE62F7818320b76);
    IKeep3rV1 public constant KP3R = IKeep3rV1(0x1cEB5cB57C4D4E2b2433641b95Dd330A33185A44);
    
    uint public constant YALINKMIN = 10000000000;
    uint public constant WETHMIN = 10000000000000000000000;
    
    function yaLINKDebt() external view returns (uint) {
        return YALINK.over(0);
    }
    
    function wethDebt() external view returns (uint) {
        return WETH.repayAmount();
    }
    
    function workable() public view returns (bool) {
        return (YALINK.over(0) > YALINKMIN || WETH.repayAmount() > WETHMIN);
    }
    
    function work() external upkeep {
        require(workable(), "YearnLiquidationKeep3r::work: !workable()");
        if (YALINK.over(0) > YALINKMIN) {
            YALINK.rebalance();
        }
        if (WETH.repayAmount() > WETHMIN) {
            WETH.repay();
        }
    }
    
    function workForFree() external {
        require(workable(), "YearnLiquidationKeep3r::work: !workable()");
        if (YALINK.over(0) > YALINKMIN) {
            YALINK.rebalance();
        }
        if (WETH.repayAmount() > WETHMIN) {
            WETH.repay();
        }
    }
}