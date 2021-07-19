// SPDX-License-Identifier: bsl-1.1

pragma solidity 0.7.6;

import "../interfaces/IVault.sol";
import "../interfaces/IVaultParameters.sol";
import "../interfaces/ICdpManagerParameters.sol";
import "../interfaces/ICDPRegistry.sol";

import "../helpers/ReentrancyGuard.sol";
import '../helpers/SafeMath.sol';

contract LiquidationAuction is ReentrancyGuard{
    using SafeMath for uint;

    /**
        计算常量
     */
    uint public constant DENOMINATOR_1E2 = 1e2;

    /**
        引用变量
     */
    IVault public immutable vault;
    ICdpManagerParameters public immutable cdpManagerParameters;
    ICDPRegistry public immutable cdpRegistry;

    /**
       事件
    */
    event Buyout(address indexed asset, address indexed owner, address indexed buyer, uint amount,uint price, uint penalty);

    modifier checkpoint(address asset, address owner) {
        _;
        cdpRegistry.checkpoint(asset, owner);
    }

    constructor(address _cdpManagerParameters, address _cdpRegistry){
        require(_cdpManagerParameters != address(0), "Atom Protocol: INVALID_ARGS");

        vault = IVault(IVaultParameters(ICdpManagerParameters(_cdpManagerParameters).vaultParameters()).vault());
        cdpManagerParameters = ICdpManagerParameters(_cdpManagerParameters);
        cdpRegistry = ICDPRegistry(_cdpRegistry);
    }

    /**
        买断清算资产
     */
    function buyout(address asset, address owner) public nonReentrant checkpoint(asset, owner) {
        // 确保资产清算状态已经触发
        require(vault.liquidationBlock(asset, owner) != 0, "Atom Protocol: LIQUIDATION_NOT_TRIGGERED");

        // 获取清算起始价格(资产等值的usd价格:100)
        uint startingPrice = vault.liquidationPrice(asset, owner);

        // 从清算开始到现在，过去了多少个block
        uint blocksPast = block.number.sub(vault.liquidationBlock(asset, owner));

        // 折旧期 usdt=3300 eth=1100，单位：block
        uint depreciationPeriod = cdpManagerParameters.devaluationPeriod(asset);

        // 获取债务（包含费用）
        uint debt = vault.getTotalDebt(asset, owner);

        // 清算惩罚 liquidationFee是 0 decimal，所以需要除以100 = DENOMINATOR_1E2换算成百分比 
        uint penalty = debt.mul(vault.liquidationFee(asset, owner)).div(DENOMINATOR_1E2);

        // 获取用户抵押品数量
        uint collateralInPosition = vault.collaterals(asset, owner);

        uint collateralToLiquidator;
        uint collateralToOwner;
        uint repayment;

        // 计算给"清算者"和"头寸所有者"的抵押品，repyament是还款费用
        (collateralToLiquidator, collateralToOwner, repayment) = _calcLiquidationParams(
            depreciationPeriod,
            blocksPast,
            startingPrice,
            debt.add(penalty),
            collateralInPosition
        );

        // 执行清算
        _liqudate(asset, owner, collateralToLiquidator, collateralToOwner, repayment, penalty);
    }

     /**
        内部函数
     */

    //  执行清算
    function _liqudate(
        address asset,
        address user,
        uint collateralToBuyer,
        uint collateralToOwner,
        uint repayment,
        uint penalty
    ) private {
        vault.liquidate(asset, user, collateralToBuyer, collateralToOwner, repayment, penalty, msg.sender);

        emit Buyout(asset, user, msg.sender, collateralToBuyer, repayment, penalty);
    }

    // 计算清算变量
    function _calcLiquidationParams(
        uint depreciationPeriod,    // 折旧期
        uint blocksPast,            // 从清算开始经过的block
        uint startingPrice,         // 抵押品usd价值
        uint debtWithPenalty,       // 债务+清算费
        uint collateralInPosition   // 抵押品数量
    ) internal pure returns(
        uint collateralToBuyer,
        uint collateralToOwner,
        uint price // repayment 还款金额
    ){
        // 判断是否超过折旧期
        if(depreciationPeriod > blocksPast){
            // 没有超过折旧期：

            // 距离折旧期还有多少个block：
            // depreciationPeriod = 3300
            // blocksPast = 1000
            // valuation = 3300-1000 = 2300
            uint valuation = depreciationPeriod.sub(blocksPast);

            // 资产价格：
            // 荷兰式拍卖：越早清算，价格越高
            // startingPrice = 100
            // collateralPrice（清算金额）
            // collateralPrice = 100*3300/3300 = 100.00000000 = (uint) 100 （过了0个block，理想情况）
            // collateralPrice = 100*3299/3300 = 99.969696970 = (uint) 99 （过了1个block）
            // collateralPrice = 100*2300/3300 = 69.696969697 = (uint) 69 （过了1000个block）
            // collateralPrice = 100*1300/3300 = 39.393939394 = (uint) 39 （过了2000个block）
            uint collateralPrice = startingPrice.mul(valuation).div(depreciationPeriod);

            // collateralPrice > debtWithPenalty:
            // 抵押品价格 > 欠的费用：还款费用=欠款费用，拿走欠款费用对应的抵押品数量，剩余的还给owner
            // 抵押品价格 <= 欠的费用：还款费用=清算价格，拿走所有抵押品
            if (collateralPrice > debtWithPenalty) {
                // 触发场景：
                // 清算金额 = 100*3299/3300 = 99.969696970 = (uint) 99 （过了1个block）
                // "清算金额" > "债务+惩罚" 如：ETH资产（资产价值100U），债务+惩罚=78+78*0.06=78+4.68=82.68
                // 99 > 82.68

                // 公式说明：
                // 计算给buyer的资产数量，为什么要这样计算？
                // 答：假设0.04eth = 100刀, 0.04*82.68 = x * 99
                // 答：0.04个eth有82.68刀债务，用99刀清算，等比例获得x个eth
                // x = collateralToBuyer = 0.04*82.68/99=0.033406061，获得0.033406061*100/0.04=83.5151525刀
                // 盈利：83.5151525-82.68 = 0.8351525刀
                collateralToBuyer = collateralInPosition.mul(debtWithPenalty).div(collateralPrice);

                // 按比例扣除asset，剩余的还给owner
                // collateralToOwner=0.04-0.033406061=0.006593939
                collateralToOwner = collateralInPosition.sub(collateralToBuyer);

                // 还款费用
                price = debtWithPenalty;
            }
            else{
                // 触发场景：
                // 清算金额 = 100*2300/3300 = 69.696969697 = (uint) 69 （过了1000个block）
                // "清算金额" <= "债务+惩罚" 如：ETH资产（资产价值100U），债务+惩罚=78+78*0.06=78+4.68=82.68
                // 69 <= 82.68
                // 用69刀清算所有资产

                // collateralInPosition 抵押品数量全部给buyer
                collateralToBuyer = collateralInPosition;

                // 还款费用
                price = collateralPrice;
            }
        }
        else{
            // 超过折旧期：
            // 所有资产给清算者（0还款费用进行清算）
            collateralToBuyer = collateralInPosition;
        }
    }
}

// SPDX-License-Identifier: bsl-1.1

pragma solidity 0.7.6;

interface IVault {
    /**
       计算用常量定义
    */
    function DENOMINATOR_1E5() external view returns (uint);
    
    /**
       Token变量
    */
    function weth() external view returns (address payable);
    function usdg() external view returns (address);
    
    /**
       业务相关变量
    */
    function collaterals(address, address) external view returns (uint);
    function debts(address, address) external view returns (uint);
    function liquidationBlock(address, address) external view returns (uint);
    function liquidationPrice(address, address) external view returns (uint);
    function tokenDebts(address) external view returns (uint);
    function stabilityFee(address, address) external view returns (uint);
    function liquidationFee(address, address) external view returns (uint);
    function oracleType(address, address) external view returns (uint);
    function lastUpdate(address, address) external view returns (uint);
    
    /**
        业务函数
    */
    function spawn(address asset, address user, uint _oracleType) external;
    function destroy(address asset, address user) external;
    function depositMain(address asset, address user, uint amount) external;
    function depositEth(address user) external payable;
    function withdrawMain(address asset, address user, uint amount) external;
    function WithdrawEth(address payable user, uint amount) external;
    function borrow(address asset, address user, uint amount) external returns (uint);
    function repay(address asset, address user, uint amount) external returns(uint) ;
    function triggerLiquidation(address asset, address positionOwner, uint initialPrice) external;
    function liquidate(address asset, address positionOwner, uint mainAssetToLiquidator, uint mainAssetToPositionOwner, uint repayment, uint penalty, address liquidator) external;

    /**
        工具函数
    */
    function chargeFee(address asset, address user, uint amount) external;
    function update(address asset, address user) external;
    function getTotalDebt(address asset, address user) external view returns (uint) ;
    function calculateFee(address asset, address user, uint debt) external view returns (uint) ;
    function changeOracleType(address asset, address user, uint newOracleType) external;
}

// SPDX-License-Identifier: bsl-1.1

pragma solidity 0.7.6;

interface IVaultParameters {
    
    /**
      重要成员变量
    */
    function vault() external view returns (address);
    function vaultParameters() external view returns (address);
    function foundation() external view returns (address);

    /**
      系统权限相关变量
    */
    function isManager(address) external view returns (bool);
    function canModifyVault(address) external view returns (bool);

    /**
      业务流程相关变量
    */
    function stabilityFee(address) external view returns (uint256);
    function liquidationFee(address) external view returns (uint256);
    function tokenDebtLimit(address) external view returns (uint256);
    function isOracleTypeEnabled(uint256, address) external view returns (bool);
    
    /**
       业务函数
    */
    function setCollateral(address asset, uint stabilityFeeValue, uint liquidationFeeValue, uint tokenDebtLimitValue, uint[] calldata oracles) external; 
    function setFoundation(address newFoundation) external;
    function setManager(address who, bool isPermit) external;
    function setVaultAccess(address who, bool isPermit) external;
    function setStabilityFee(address asset, uint fee) external;
    function setLiquidationFee(address asset, uint fee) external;
    function setTokenDebtLimit(address asset, uint limit) external;
    function setOracleType(uint _type, address asset, bool enable) external;
}

// SPDX-License-Identifier: bsl-1.1

pragma solidity 0.7.6;

interface ICdpManagerParameters {
    /**
       业务相关变量
    */
    function initialCollateralRatio(address) external view returns (uint256);
    function liquidationRatio(address) external view returns (uint256);
    function liquidationDiscount(address) external view returns (uint256);
    function devaluationPeriod(address) external view returns (uint256);
    function vaultParameters() external view returns (address);

    /**
        业务函数
    */
    function setCollateral(
        address asset,
        uint stabilityFeeValue,
        uint liquidationFeeValue,
        uint initialCollateralRatioValue,
        uint liquidationRatioValue,
        uint liquidationDiscountValue,
        uint devaluationPeriodValue,
        uint usdgLimit,
        uint[] calldata oracles
    ) external ;

    /**
        工具函数
    */
    function setInitialCollateralRatio(address asset, uint newValue) external;
    function setLiquidationRatio(address asset, uint newValue) external;
    function setLiquidationDiscount(address asset, uint newValue) external;
    function setDevaluationPeriod(address asset, uint newValue) external;
}

// SPDX-License-Identifier: bsl-1.1

pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

interface ICDPRegistry {
    struct CDP{
        address asset;
        address owner;
    }

    /**
       引用变量
    */
    function vault() external view returns (address);
    function collateralRegistry() external view returns (address);
    
    /**
       成员变量
    */
    function cdpList(address) external view returns (address[] memory);
    function cdpIndex(address, address) external view returns (uint256);
    
    /**
       业务函数
    */
    function checkpoint(address asset, address owner) external;
    function getCdpsByCollateral(address asset) external view returns (CDP[] memory cdps);
    function getCdpsByOwner(address owner) external view returns (CDP[] memory r);
    function getAllCdps() external view returns (CDP[] memory r);

    /**
       工具函数
    */
    function isAlive(address asset, address owner) external view returns (bool);
    function isListed(address asset, address owner) external view returns (bool);
    function getCdpsCount() external view returns (uint totalCdpCount);
    function getCdpsCountForCollateral(address asset) external view returns (uint);
    function batchCheckpointForAsset(address asset, address[] calldata owners) external;
    function batchCheckpoint(address[] calldata assets, address[] calldata owners) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: bsl-1.1

pragma solidity 0.7.6;


library SafeMath {

    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: division by zero");
        return a / b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}

{
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}