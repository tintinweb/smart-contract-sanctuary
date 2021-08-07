// SPDX-License-Identifier: bsl-1.1

pragma solidity 0.7.6;

import "../helpers/SafeMath.sol";
import "../helpers/ReentrancyGuard.sol";
import "../interfaces/IVault.sol";
import "../interfaces/IVaultParameters.sol";
import "../interfaces/ICdpManagerParameters.sol";
import "../interfaces/IOracleRegistry.sol";
import "../interfaces/ICDPRegistry.sol";
import "../interfaces/IToken.sol";
import "../interfaces/IOracleUsd.sol";
import "../interfaces/IWETH.sol";

contract CDPManager is ReentrancyGuard{
    using SafeMath for uint;

    /**
        计算常量定义
     */
    uint public constant Q112 = 2 ** 112;
    uint public constant DENOMINATOR_1E5 = 1e5;

    /**
        变量引用
     */
    // ICdpManagerParameters public immutable cdpManagerParameters;
    // IVault public immutable vault;
    // IOracleRegistry public immutable oracleRegistry;
    // ICDPRegistry public immutable cdpRegistry;

    // address payable public immutable WETH;

    ICdpManagerParameters public  cdpManagerParameters;
    IVault public  vault;
    IOracleRegistry public  oracleRegistry;
    ICDPRegistry public  cdpRegistry;

    address payable public  WETH;

    modifier checkpoint(address asset, address owner) {
        _;
        cdpRegistry.checkpoint(asset, owner);
    }

    /**
       事件
    */
    event Join(address indexed asset, address indexed owner, uint main, uint usdg);
    event Exit(address indexed asset, address indexed owner, uint main, uint usdg);
    event LiquidationTriggered(address indexed asset, address indexed owner);

    constructor(address _cdpManagerParameters, address _oracleRegistry, address _cdpRegistry){
        require(
            _cdpManagerParameters != address(0) && 
            _oracleRegistry != address(0) &&
            _cdpRegistry != address(0)
            , "Atom Protocol: ZERO_ADDRESS");
        
        cdpManagerParameters = ICdpManagerParameters(_cdpManagerParameters);
        oracleRegistry = IOracleRegistry(_oracleRegistry);
        cdpRegistry = ICDPRegistry(_cdpRegistry);
        vault = IVault(IVaultParameters(ICdpManagerParameters(_cdpManagerParameters).vaultParameters()).vault());
        WETH  = IVault(IVaultParameters(ICdpManagerParameters(_cdpManagerParameters).vaultParameters()).vault()).weth();
    }

    /**
       fallback函数
    */
    // 只接受weth合约过来的ETH Token
    receive() external payable {
        require(msg.sender == WETH, "Atom Protocol: RESTRICTED");
    }

    /**
        借/还业务函数
     */
    function join(address asset, uint assetAmount, uint usdgAmount) public nonReentrant checkpoint(asset, msg.sender) {
        require(assetAmount!=0 || usdgAmount!=0, "Atom Protocol: USELESS_TX");
        require(IToken(asset).decimals()<=18, "Atom Protocol: NOT_SUPPORTED_DECIMALS");

        if(usdgAmount == 0){
            // 只存抵押品，不兑换usdp
            // deposit:存什么币，谁存，存多少
            vault.depositMain(asset, msg.sender, assetAmount);
        }
        else{
            // 存抵押品，且兑换usdp

            // 确保asset的oracle正常
            _ensureOracle(asset);

            // 判断是否已经产生头寸
            bool spawned = vault.debts(asset, msg.sender) != 0;

            if(!spawned){
                vault.spawn(asset, msg.sender, oracleRegistry.oracleTypeByAsset(asset));
            }
            
            if(assetAmount != 0){
                vault.depositMain(asset, msg.sender, assetAmount);
            }

            vault.borrow(asset, msg.sender, usdgAmount);

            // 判断借出金额是否超过抵押物价值，如果超过则报错回滚。
            _ensurePositionCollateralization(asset, msg.sender);
        }

        emit Join(asset, msg.sender, assetAmount, usdgAmount);
    }

    function join_Eth(uint usdgAmount) public payable {
        if(msg.value != 0){
            IWETH(WETH).deposit{value: msg.value}();
            require(IWETH(WETH).transfer(msg.sender, msg.value), "Atom Protocol: WETH_TRANSFER_FAILED");
        }

        join(WETH, msg.value, usdgAmount);
    }

    function exit(address asset, uint assetAmount, uint usdgAmount) public nonReentrant checkpoint(asset, msg.sender) returns (uint) {
        require(assetAmount!=0 || usdgAmount!=0, "Atom Protocol: USELESS_TX");

        // 获取用户债务
        uint debt = vault.debts(asset, msg.sender);

        // 如果还款金额超过债务，则设置成还款最大值
        if(usdgAmount > debt){
            usdgAmount = debt;
        }

        if(assetAmount == 0){
            // 只还款，不提取金额
            _repay(asset, msg.sender, usdgAmount);
        }
        else{
            if(debt == usdgAmount){
                // 还款所有债务，并提取资产：

                // 提取资产
                vault.withdrawMain(asset, msg.sender, assetAmount);

                // 还款
                if(usdgAmount !=0){
                    _repay(asset, msg.sender, usdgAmount);
                }
            }
            else{
                // 还款部分债务/不还款，并提取资产

                _ensureOracle(asset);

                // 提取资产
                vault.withdrawMain(asset, msg.sender, assetAmount);

                // 还款
                if(usdgAmount !=0){
                    _repay(asset, msg.sender, usdgAmount);
                }

                vault.update(asset, msg.sender);
                _ensurePositionCollateralization(asset, msg.sender);
            }
        }

        emit Exit(asset, msg.sender, assetAmount, usdgAmount);

        return usdgAmount;
    }

    function exit_targetRepayment(address asset, uint assetAmount, uint repayment) public returns (uint) {
        // 计算偿还的USDP本金(扣除利息)
        uint usdpAmount = _calcPrincipal(asset, msg.sender, repayment);
        return exit(asset, assetAmount, usdpAmount);
    }

    function exit_Eth(uint ethAmount, uint usdgAmount) public returns (uint) {
        usdgAmount = exit(WETH, ethAmount, usdgAmount);
        require(IWETH(WETH).transferFrom(msg.sender, address(this), ethAmount), "Atom Protocol: WETH_TRANSFER_FROM_FAILED");
        IWETH(WETH).withdraw(ethAmount);
        (bool success,) = msg.sender.call{value:ethAmount}("");
        require(success, "Atom Protocol: ETH_TRANSFER_FAILED");
        return usdgAmount;
    }

    function exit_Eth_targetRepayment(uint ethAmount, uint repayment) public returns (uint) {
        // 计算偿还的USDP本金(扣除利息)
        uint usdpAmount = _calcPrincipal(WETH, msg.sender, repayment);
        return exit_Eth(ethAmount, usdpAmount);
    }

    /**
       清算业务函数
    */
    // 触发清算逻辑
    function triggerLiquidation(address asset, address owner) external nonReentrant {
        _ensureOracle(asset);

        uint usdValue_q112 = getCollateralUsdValue_q112(asset, owner);

        // 确保头寸达到清算要求
        require(_isLiquidatablePosition(asset, owner, usdValue_q112), "Atom Protocol: SAFE_POSITION");

        uint liquidationDiscount_q112 = usdValue_q112.mul(cdpManagerParameters.liquidationDiscount(asset)).div(DENOMINATOR_1E5);

        uint initialLiquidationPrice = usdValue_q112.sub(liquidationDiscount_q112).div(Q112);

        vault.triggerLiquidation(asset, owner, initialLiquidationPrice);

        emit LiquidationTriggered(asset, owner);
    }

    // 判断头寸是否可清算
    function isLiquidatablePosition(address asset, address owner) public view returns (bool) { 
        uint usdValue_q112 = getCollateralUsdValue_q112(asset, owner);
        return _isLiquidatablePosition(asset, owner, usdValue_q112);
    }

    /**
       工具函数
    */

    // 获取用户抵押品asset等值的usd金额（q112）
    function getCollateralUsdValue_q112(address asset, address owner) public view returns (uint) {
        return IOracleUsd(oracleRegistry.oracleByAsset(asset)).assetToUsd(asset, vault.collaterals(asset, owner));
    }

    // 计算当前头寸利用率
    function utillizationRatio(address asset, address owner) public view returns (uint) {
        uint debt = vault.getTotalDebt(asset, owner);
        if(debt == 0){
            return 0;
        }

        // 抵押品的价值usd_q112
        uint usdValue_q112 = getCollateralUsdValue_q112(asset, owner);

        // 最大可借出的usdLimit_q112
        uint usdLimit_q112 = usdValue_q112 * cdpManagerParameters.initialCollateralRatio(asset) / 100;

        return debt.mul(100).mul(Q112).div(usdLimit_q112);
    }

    // 清算单价=债务/清算比例/资产数量（假设"实际债务清算比例"与"系统设置清算比例"相同的情况下的"清算单价"）
    function liquidationPrice_q112(address asset, address owner) external view returns (uint) {
        uint debt = vault.getTotalDebt(asset, owner);
        if(debt == 0){
            return uint(-1);
        }

        uint collateralLiqPrice = debt.mul(100).mul(Q112).div(cdpManagerParameters.liquidationRatio(asset));

        require(IToken(asset).decimals() <= 18, "Atom Protocol: NOT_SUPPORTED_DECIMALS");

        return collateralLiqPrice / vault.collaterals(asset, owner) / 10 ** (18 - IToken(asset).decimals());
    } 

    /**
       工具函数（内部）
    */

    // 还款
    function _repay(address asset, address owner, uint usdgAmount) internal{
        // vault.calculateFee算出来的钱与(_calcPrincipal本金*费率)不一致？（JS验算时候小数需要强转成int，验算结果一致）
        uint fee = vault.calculateFee(asset, owner, usdgAmount);

        // 把Fee充值去foundation address
        vault.chargeFee(vault.usdg(), owner, fee);

        // burn usdg
        uint debtAfter = vault.repay(asset, owner, usdgAmount);

        // 如果债务为0，则清除用户头寸相关的变量信息
        if(debtAfter == 0){
            vault.destroy(asset, owner);
        }
    }

    // 计算USDG还款金额中的本金（本金=还款金额-利息）
    function _calcPrincipal(address asset, address owner, uint repayment) internal view returns (uint) {
        // 公式说明：
        // vault.stabilityFee(asset, owner) = 获取某资产，用户当时保存的sFee（ "一年" 的债务成本）
        // vault.stabilityFee(asset, owner)/365 days = 获取某资产，用户当时保存的sFee（ "一秒" 的债务成本）
        // fee = 一秒的成本(百分比) * 时间经过了多少秒, 153.99441907661085=0.15399441907661085%
        uint fee = vault.stabilityFee(asset, owner) * (block.timestamp - vault.lastUpdate(asset, owner)) /  365 days;

        /**
            公式说明：
            一、计算原理如下：
                总额3505 1% 税率，本金计算：
                    3505/(1+0.01) = 3470.29702970297

                税率乘以1e2，改为整数的计算:
                    3505*1e2 /(1e2 + 1) = 3470.29702970297
                
                验算：
                    3470.3 + 3470.3*0.01 = 3505

            二、推导：
                本金 + 本金 * 0.00135 = 50(repayment)
                本金*(1+0.00135)=50
                本金=50/(1+0.00135)
                本金=50*1e5/(1+0.00135)*1e5=50*1e5/(1e5+135)

            三、验算：
                本金=49.932591002
                费用=49.932591002*0.00135=0.067408998
                本金+费用=49.932591002+0.067408998=50
        */
        return repayment * 1E5 / (1E5 + fee);
    }

    // 判断头寸是否可清算
    function _isLiquidatablePosition(address asset, address owner, uint usdValue_q112) internal view returns (bool) {
        uint debt = vault.getTotalDebt(asset, owner);

        if(debt == 0){
            return false;
        }

        // cdpManagerParameters.liquidationRatio(USDT) = 98 (98%) The liquidation ratio (0 decimals)
        /**
            公式说明：
            债务/资产总价 = 债务比例 , 债务比例>=清算比例 则可以清算
            totalDebt*100*q112/usdValue_q112 等价于 totalDebt*100/(usdValue_q112/q112)
            备注：乘以100的原因，因为liquidationRatio是0 decimal的，计算出来百分比小数的需要乘以100才能匹配（0.7285=72.85%*100=72.85）
         */
         return debt.mul(100).mul(Q112).div(usdValue_q112) >= cdpManagerParameters.liquidationRatio(asset);
    }

    // 确保asset对应的的oracle正常
    function _ensureOracle(address asset) internal view{
        uint oracleType = oracleRegistry.oracleTypeByAsset(asset);
        require(oracleType !=0, "Atom Protocol: IVALID_ORACLE_TYPE");
        address oracle = oracleRegistry.oracleByType(oracleType);
        require(oracle != address(0), "Atom Protocol: DISABLED_ORACLE");
    }

    // 判断借出金额是否超过抵押物价值，如果超过则报错回滚。
    function _ensurePositionCollateralization(address asset, address owner) internal view {
        // 计算抵押品等值usd金额
        // returned value 10**18 * 2**112 is $1
        uint usdValue_q112 = getCollateralUsdValue_q112(asset, owner);

        // 计算最大借出usd限制
        // initialCollateralRatio是百分比，需要除以100得到正确金额
        uint usdLimit = usdValue_q112 * cdpManagerParameters.initialCollateralRatio(asset) / Q112 / 100;

        require(vault.getTotalDebt(asset, owner) <= usdLimit, "Atom Protocol: UNDERCOLLATERALIZED");
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

interface IOracleRegistry{

    struct Oracle {
        uint oracleType;
        address oracleAddress;
    }

    /**
       业务相关变量
    */
    function vaultParameters() external view returns (address);
    function maxOracleType() external view returns (uint256);
    function WETH() external view returns (address);
    function oracleByType(uint256) external view returns (address);
    function oracleTypeByOracle(address) external view returns (uint256);
    function oracleTypeByAsset(address) external view returns (uint256);

    /**
       Oracle管理（增删改查）
    */
    function setOracle(uint oracleType, address oracle) external;
    function unsetOracle(uint oracleType) external;
    function getOracles() external view returns (Oracle[] memory foundOracles);

    /**
       Oracle与Asset相关操作
    */
    function setOracleTypeForAsset(address asset, uint oracleType) external;
    function setOracleTypeForAssets(address[] calldata assets, uint oracleType) external;
    function unsetOracleTypeForAsset(address asset) external;
    function unsetOracleTypeForAssets(address[] calldata assets) external;
    function oracleByAsset(address asset) external view returns (address);
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

// SPDX-License-Identifier: bsl-1.1

pragma solidity 0.7.6;

interface IToken {
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function balanceOf(address) external view returns (uint);
}

// SPDX-License-Identifier: bsl-1.1

pragma solidity 0.7.6;

interface IOracleUsd {
    
    // returns Q112-encoded value
    // returned value 10**18 * 2**112 is $1
    function assetToUsd(address asset, uint amount) external view returns (uint);
}

// SPDX-License-Identifier: bsl-1.1

pragma solidity 0.7.6;

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
    function withdraw(uint) external;
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