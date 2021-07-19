// SPDX-License-Identifier: bsl-1.1

pragma solidity 0.7.6;

import "./VaultParameters.sol";
import "./USDG.sol";
import "./helpers/SafeMath.sol";
import "./helpers/TransferHelper.sol";
import "./interfaces/IWETH.sol";

contract Vault is Auth {
    using SafeMath for uint;

    /**
        计算用常量定义
     */
    uint public constant DENOMINATOR_1E5 = 1e5;

    /**
        Token变量
     */
    address payable public immutable weth; 

    address public immutable usdg;

    /**
        业务相关变量
     */

    // 抵押品列表: collaterals[asset][user] = amount;
    mapping(address => mapping(address => uint)) public collaterals;

    // 债务列表: debts[asset][user] = amount;
    mapping(address => mapping(address => uint)) public debts;

    // 清算trigger触发时的block number
    mapping(address => mapping(address => uint)) public liquidationBlock;

    // 清算trigger触发时的资产等值usd value（减去清算折扣）
    mapping(address => mapping(address => uint)) public liquidationPrice;

    // 资产的债务
    mapping(address => uint) public tokenDebts;

    // 每个用户头寸的stabilityFee（保存update时的stabilityFee） 保留3位小数，例：5000=5%
    // stabilityFee[asset][user] = fee
    mapping(address => mapping(address => uint)) public stabilityFee;

    // 每个用户头寸的liquidationFee（保存update时的liquidationFee）保留0位小数，例：8=8%
    // liquidationFee[asset][user] = fee
    mapping(address => mapping(address => uint)) public liquidationFee;

    // 每个用户头寸的oracleType（保存头寸产生时的oracleType）
    // oracleType[asset][user] = type
    mapping(address => mapping(address => uint)) public oracleType;

    // 用户头寸最后更新的timestamp
    // lastUpdate[asset][user] = timestamp
    mapping(address => mapping(address => uint)) public lastUpdate;

    /**
        修饰符
     */

    // 确保资产没有在清算
    modifier notLiquidating(address asset, address user) {
        require(liquidationBlock[asset][user] == 0, "Atom Protocol: LIQUIDATING_POSITION");
        _;
    }

    /**
       构造函数
    */
    constructor(address _vaultParameters, address _usdg, address payable _weth) Auth(_vaultParameters) {
        weth = _weth;
        usdg = _usdg;
    }

    /**
       fallback函数
    */
    // 只接受weth合约过来的ETH Token
    receive() external payable {
        require(msg.sender == weth, "Atom Protocol: RESTRICTED");
    }

    /**
        业务函数
    */
    
    // 为用户创建新头寸 
    function spawn(address asset, address user, uint _oracleType) external hasVaultAccess notLiquidating(asset, user) {
        oracleType[asset][user] = _oracleType;
        delete liquidationBlock[asset][user];
    }

    // 清除用户头寸相关的变量信息
    function destroy(address asset, address user) public hasVaultAccess notLiquidating(asset, user) {
        delete stabilityFee[asset][user];
        delete liquidationFee[asset][user];
        delete oracleType[asset][user];
        delete lastUpdate[asset][user];
    }

    // 用户头寸添加抵押品（Token需要已经Approved）
    function depositMain(address asset, address user, uint amount) external hasVaultAccess notLiquidating(asset, user) {
        collaterals[asset][user] = collaterals[asset][user].add(amount);
        TransferHelper.safeTransferFrom(asset, user, address(this), amount);
    }

    // 将ETH转转未WETH, 然后添加到用户头寸
    function depositEth(address user) external payable notLiquidating(weth, user){
        IWETH(weth).deposit{value: msg.value};
        collaterals[weth][user] = collaterals[weth][user].add(msg.value);
    }

    // 用户提现头寸抵押品
    function withdrawMain(address asset, address user, uint amount) external hasVaultAccess notLiquidating(asset, user) {
        collaterals[asset][user] = collaterals[asset][user].sub(amount);
        TransferHelper.safeTransfer(asset, user, amount);
    }

    function WithdrawEth(address payable user, uint amount) external hasVaultAccess notLiquidating(weth, user) {
        collaterals[weth][user] = collaterals[weth][user].sub(amount);
        IWETH(weth).withdraw(amount);
        TransferHelper.safeTransferEth(user, amount);
    }

    // 借出USDG, 增加头寸债务 & 铸造USDG Token
    function borrow(address asset, address user, uint amount) external hasVaultAccess notLiquidating(weth, user) returns (uint) {
        require(vaultParameters.isOracleTypeEnabled(oracleType[asset][user], asset), "Atom Protocol: WRONG_ORACLE_TYPE");

        // 更新用户头寸参数，详细描述见函数定义
        update(asset, user);

        // 用户头寸添加债务
        debts[asset][user] = debts[asset][user].add(amount);

        // token添加总债务
        tokenDebts[asset] = tokenDebts[asset].add(amount);

        // 检查是否超出token limit
        require(tokenDebts[asset] <= vaultParameters.tokenDebtLimit(asset), "Atom Protocol: ASSET_DEBT_LIMIT");

        USDG(usdg).mint(user, amount);

        return debts[asset][user];
    }

    // 还款USDG, 减少头寸债务 & 销毁USDG Token
    function repay(address asset, address user, uint amount) external hasVaultAccess notLiquidating(weth, user) returns(uint) {
        uint debt = debts[asset][user];

        // 用户头寸债务减去还款金额
        debts[asset][user] = debt.sub(amount);

        // token总债务减去还款金额
        tokenDebts[asset] = tokenDebts[asset].sub(amount);

        USDG(usdg).burn(user, amount);
        
        return debts[asset][user];
    }

    /**
        清算相关函数
    */

    // 触发清算：删除头寸并将抵押品转移到清算系统
    function triggerLiquidation(address asset, address positionOwner, uint initialPrice) external hasVaultAccess notLiquidating(weth, positionOwner) {
        require(vaultParameters.isOracleTypeEnabled(oracleType[asset][positionOwner], asset), "Atom Protocol: WRONG_ORACLE_TYPE");

        // 更新头寸最新债务
        debts[asset][positionOwner] = getTotalDebt(asset, positionOwner);

        // 设置清算参数
        liquidationBlock[asset][positionOwner] = block.number;
        liquidationPrice[asset][positionOwner] = initialPrice;
    }

    /**
      @dev 执行清算流程
      @param asset 抵押品资产 
      @param positionOwner 头寸拥有者
      @param mainAssetToLiquidator 发送给"清算人"的"抵押品资产"数量
      @param mainAssetToPositionOwner 发送给"头寸所有者"的"抵押品资产"数量
      @param repayment USDG还款金额
      @param penalty USDG中的清算罚款
      @param liquidator "清算者"的地址
    **/
    function liquidate(
        address asset, 
        address positionOwner,
        uint mainAssetToLiquidator,
        uint mainAssetToPositionOwner,
        uint repayment,
        uint penalty,
        address liquidator
    ) external hasVaultAccess{
        // 确保头寸进入清算状态
        require(liquidationBlock[asset][positionOwner] !=0 ,"Atom Protocol: NOT_TRIGGERED_LIQUIDATION");

        // 头寸资产数量
        uint mainAssetInPotision = collaterals[asset][positionOwner];

        // 剩余资产转给foundation
        uint mainAssetToFoundation = mainAssetInPotision.sub(mainAssetToLiquidator).sub(mainAssetToPositionOwner);

        // 删除债务和清算信息
        delete debts[asset][positionOwner];
        delete liquidationBlock[asset][positionOwner];
        delete liquidationPrice[asset][positionOwner];

        // 清除用户头寸相关的变量信息
        destroy(asset, positionOwner);

        // 还款逻辑，清算者需要准备足够的USDG还款：
        if(repayment > penalty){
            // 还款金额 > 惩罚金额
            if(penalty != 0){
                // "清算者"将"清算罚款"转账给foundation
                TransferHelper.safeTransferFrom(usdg, liquidator, vaultParameters.foundation(), penalty);
            }
        }
        else{
            // 还款金额 <= 惩罚金额
            if(repayment != 0){
                // "清算者"将"还款金额"转账给foundation
                TransferHelper.safeTransferFrom(usdg, liquidator, vaultParameters.foundation(), repayment);
            }
        }

        // 转账流程：
        if(mainAssetToLiquidator != 0){
            TransferHelper.safeTransfer(asset, liquidator, mainAssetToLiquidator);
        }

        if(mainAssetToPositionOwner != 0){
            TransferHelper.safeTransfer(asset, positionOwner, mainAssetToPositionOwner);
        }

        if(mainAssetToFoundation != 0){
            TransferHelper.safeTransfer(asset, vaultParameters.foundation(), mainAssetToFoundation);
        }
    }

    /**
        工具函数
    */

    // 把fee转账到foundation账号
    function chargeFee(address asset, address user, uint amount) external hasVaultAccess notLiquidating(asset, user) {
        if(amount != 0){
            TransferHelper.safeTransferFrom(asset, user, vaultParameters.foundation(), amount);
        }
    }

    /**
       更新用户头寸参数
       1、更新用户债务本金+债务利息
       2、更新Token的总债务
       3、更新用户的sFee和lFee
       4、更新“最后更新”时间戳
     */
    function update(address asset, address user) public hasVaultAccess notLiquidating(asset, user) {
        // 获得债务本金+债务利息（采用之前保存到用户的stability fee）
        uint debtWithFee = getTotalDebt(asset, user);

        // 更新tokenDebt（先进去之前的debt，添加现在的debt，备：fee随着时间增加而增加）
        tokenDebts[asset] = tokenDebts[asset].sub(debts[asset][user]).add(debtWithFee);

        // 更新userDebt
        debts[asset][user] = debtWithFee;

        // 更新当前的stabilityFee，保存到用户，覆盖原来的sFee
        // 2000=2%(old),1500=1.5%(current) (stability fee percentage; 3 decimals)
        stabilityFee[asset][user] = vaultParameters.stabilityFee(asset);

        //  更新当前当前的liquidationFee，覆盖原来的lFee
        // 5=5%(old),6=6%(current) (stability fee percentage; 0 decimals)
        liquidationFee[asset][user] = vaultParameters.liquidationFee(asset);

        // 更新“最后更新”时间戳
        lastUpdate[asset][user] = block.timestamp;
    }

    //  计算用户某资产的总债务（根据经过的时间计算）
    function getTotalDebt(address asset, address user) public view returns (uint) {
        uint debt = debts[asset][user];

        // 如果开始清算，则直接返回debt（清算中debt不会继续增加）
        if(liquidationBlock[asset][user] != 0){
            return debt;
        }

        // 计算当前债务产生的利息fee
        uint fee = calculateFee(asset, user, debt);

        return debt.add(fee);
     }

    // 计算债务的stabilityFee(根据经过的时间和债务数量)
    function calculateFee(address asset, address user, uint debt) public view returns (uint) {
        // Stability fee = USDG一年的债务成本（2000=2% ）
        uint sFeePercent = stabilityFee[asset][user];

        uint timePast = block.timestamp.sub(lastUpdate[asset][user]);

        /**
            公式说明：
            amount.mul(sFeePercent) = amount的债务一年的成本
            amount.mul(sFeePercent).div(365 days) = amount的债务一秒的成本
            amount.mul(sFeePercent).mul(timePast).div(365 days) = amount的债务一秒的成本*时间经过了多少秒

            div(DENOMINATOR_1E5) = 因为stabilityFee(保留3位小数) 2000=2%(0.02),0.02*1e5=2000,所以需要除以1e5获得正确结果
         */
        return debt.mul(sFeePercent).mul(timePast).div(365 days).div(DENOMINATOR_1E5);
    }

    // 修改用户头寸的oracle类型（特情情况下修改，只允许Manager操作）
    function changeOracleType(address asset, address user, uint newOracleType) external onlyManager {
        oracleType[asset][user] = newOracleType;
    }
}

// SPDX-License-Identifier: bsl-1.1

pragma solidity 0.7.6;

/**
    @title Auth
    @dev 合约权限管理
 */
contract Auth{

    VaultParameters public vaultParameters;

    constructor(address _vaultParametersAddress){
        vaultParameters = VaultParameters(_vaultParametersAddress);
    }

    modifier onlyManager() {
       require(vaultParameters.isManager(msg.sender), "ATOM Protocol: AUTH_FAILED");
        _;
    }

    modifier hasVaultAccess() {
       require(vaultParameters.canModifyVault(msg.sender), "ATOM Protocol: AUTH_FAILED");
        _;
    }

    modifier onlyVault() {
       require(msg.sender == vaultParameters.vault(), "ATOM Protocol: AUTH_FAILED");
        _;
    }
}

/**
   @title VaultParameters
   @dev Vault参数
*/
contract VaultParameters is Auth {

   /**
      重要成员变量
    */
   address payable public vault;

   address public foundation;

   /**
     系统权限相关变量
   */
   mapping(address => bool) public isManager;

   mapping(address => bool) public canModifyVault;

   /**
     业务流程相关变量
   */
   // Stability Fee（借出USDG一年的债务费用百分比，保留3位小数，例：5000=5%）
   mapping(address => uint) public stabilityFee;

   // Liquidation Fee（清算费用百分比，保留0位小数，例：8=8%）
   mapping(address => uint) public liquidationFee;

   // token最大可以借出USDG的限额
   mapping(address => uint) public tokenDebtLimit;

   // Oracle type & Asset address 是否enanle
   mapping(uint => mapping(address => bool)) public isOracleTypeEnabled;

   /**
      构造函数
   */
   constructor(address payable _vault, address _foundation) Auth(address(this)) {
      require(_vault != address(0), "Atom Protocol: ZERO_ADDRESS");
      require(_foundation != address(0), "Atom Protocol: ZERO_ADDRESS");

      isManager[msg.sender] = true;
      vault = _vault;
      foundation = _foundation;
   }

   /**
      业务函数
   */
   function setCollateral(
      address asset,
      uint stabilityFeeValue,
      uint liquidationFeeValue,
      uint tokenDebtLimitValue,
      uint[] calldata oracles
   ) external onlyManager {
      setStabilityFee(asset, stabilityFeeValue);
      setLiquidationFee(asset, liquidationFeeValue);
      setTokenDebtLimit(asset, tokenDebtLimitValue);
      for (uint i=0; i < oracles.length; i++) {
         setOracleType(oracles[i], asset, true);
      }
   }

   function setFoundation(address newFoundation) external onlyManager {
      require(newFoundation != address(0), "Atom Protocol: ZERO_ADDRESS");
      foundation = newFoundation;
   }   

   function setManager(address who, bool isPermit) external onlyManager {
      isManager[who] = isPermit;
   }

   function setVaultAccess(address who, bool isPermit) external onlyManager {
      canModifyVault[who] = isPermit;
   }

   function setStabilityFee(address asset, uint fee) public onlyManager {
      stabilityFee[asset] = fee;
   }

   function setLiquidationFee(address asset, uint fee) public onlyManager {
      require(fee <= 100, "Atom Protocol: VALUE_OUT_OF_RANGE");
      liquidationFee[asset] = fee;
   }

   function setTokenDebtLimit(address asset, uint limit) public onlyManager {
      tokenDebtLimit[asset] = limit;
   }

   function setOracleType(uint _type, address asset, bool enable) public onlyManager {
      isOracleTypeEnabled[_type][asset] = enable;
   }
}

// SPDX-License-Identifier: bsl-1.1

pragma solidity 0.7.6;

import "./VaultParameters.sol";
import "./helpers/SafeMath.sol";

contract USDG is Auth{
    using SafeMath for uint;

    /**
        ERC20 属性/方法
     */

    string public constant name = "USDG Stablecoin";

    string public constant symbol = "USDG";

    string public constant version = "1";

    uint8 public constant decimals = 18;

    uint public totalSupply;

    mapping(address => uint) public balanceOf;

    mapping(address => mapping (address=>uint)) public allowance;

    /**
        ERC20 事件
     */
    event Approval(address indexed owner, address indexed spender,uint value);

    event Transfer(address indexed from, address indexed to, uint value);

    /**
       构造函数
    */
    constructor(address _vaultParameters) Auth(_vaultParameters) {
        // done.
    }

    function mint(address to, uint amount) external onlyVault {
        require(to != address(0), "Atom Protocol: ZERO_ADDRESS");

        balanceOf[to] =  balanceOf[to].add(amount);
        totalSupply = totalSupply.add(amount);

        emit Transfer(address(0), to, amount);
    }

    function burn(uint amount) external onlyManager {
        _burn(msg.sender, amount);
    }

    function burn(address from, uint amount) external onlyVault {
        _burn(from, amount);
    }

    function transfer(address to, uint amount) external returns (bool) {
        return transferFrom(msg.sender, to, amount);
    }

    function transferFrom(address from, address to, uint amount) public returns (bool) {
        require(to != address(0), "Atom Protocol: ZERO_ADDRESS");
        require(balanceOf[from] >= amount, "Atom Protocol: INSUFFICIENT_BALANCE");

        // 判断是否授权合约转账
        if(from != msg.sender) {
            // 判断授权金额
            require(allowance[from][msg.sender] >= amount, "Atom Protocol: INSUFFICIENT_BALANCE");

            // 减少授权金额
            _approve(from, msg.sender, allowance[from][msg.sender].sub(amount));
        }

        balanceOf[from] = balanceOf[from].sub(amount);
        balanceOf[to] = balanceOf[to].add(amount);

        emit Transfer(from, to, amount);

        return true;
    }

    function approve(address spender, uint amount) external returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function increaseAllowance(address spender, uint addedAmount) public virtual returns (bool) {
        _approve(msg.sender, spender, allowance[msg.sender][spender].add(addedAmount));
        return true;
    }

    function decreaseAllowance(address spender, uint subtractedAmount) public virtual returns (bool) {
        _approve(msg.sender, spender, allowance[msg.sender][spender].sub(subtractedAmount));
        return true;
    }

    function _approve(address owner, address spender, uint amount) internal virtual {
        require(owner != address(0), "Atom Protocol: approve from the zero address");
        require(spender != address(0), "Atom Protocol: approve to the zero address");

        allowance[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _burn(address from, uint amount) internal virtual {
        balanceOf[from] = balanceOf[from].sub(amount);
        totalSupply = totalSupply.sub(amount);

        emit Transfer(from, address(0), amount);
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

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.7.6;

// 采用低级函数调用的好处是：调用ERC20方法，不一定总会获得返回值
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "TransferHelper: APPROVE_FAILED");
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "TransferHelper: TRANSFER_FAILED");
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "TransferHelper: TRANSFER_FROM_FAILED");
    }

    function safeTransferEth(address to, uint value) internal {
        (bool success,) = to.call{value: value}(new bytes(0));
        require(success, "TransferHelper: ETH_TRANSFER_FAILED");
    }
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