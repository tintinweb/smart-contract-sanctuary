// SPDX-License-Identifier: bsl-1.1

pragma solidity 0.7.6;

import "./VaultParameters.sol";

contract CollateralRegistry is Auth {

    /**
       业务相关变量
    */
    address[] public collateralList;
    mapping(address => uint) public collateralId;

    /**
       事件
    */
    event CollateralAdded(address indexed asset);
    event CollateralRemoved(address indexed asset);

    /**
       构造函数
    */
    constructor(address _vaultParameters, address[] memory assets) Auth(_vaultParameters) {
        for(uint i = 0; i < assets.length; i++){
            require(!isCollateral(assets[i]), "Atom Protocol: ALREADY_EXIST");
            
            collateralList.push(assets[i]);
            collateralId[assets[i]] = i;

            emit CollateralAdded(assets[i]);
        }
    }

    /**
        业务函数
     */
    function addCollateral(address asset) public onlyManager {
        require(asset != address(0), "Atom Protocol: ZERO_ADDRESS");
        require(!isCollateral(asset), "Atom Protocol: ALREADY_EXIST");

        collateralList.push(asset);
        collateralId[asset] = collateralList.length - 1; // length-1 = lastId

        emit CollateralAdded(asset);
    }

    function removeCollateral(address asset) public onlyManager {
        require(asset != address(0), "Atom Protocol: ZERO_ADDRESS");
        require(isCollateral(asset), "Atom Protocol: DOES_NOT_EXIST");

        // 删除需要"被删除的资产"的idx
        uint idx = collateralId[asset];
        delete collateralId[asset];

        uint lastIdx = collateralList.length - 1;

        // 删除数组中某个元素
        if(idx != lastIdx) {
            // 缓存"最后一个元素"
            address tempLastCollateral = collateralList[lastIdx];

            // 用"最后一个元素"覆盖需要"被删除的资产"
            collateralList[idx] = tempLastCollateral;

            // 用"被删除的资产"id赋值给"最后一个元素"
            collateralId[tempLastCollateral] = idx;
        }

        collateralList.pop();

        emit CollateralRemoved(asset);
    }

    /**
        工具函数
     */
    function isCollateral(address asset) public view returns (bool) {
        if(collateralList.length == 0) {
            return false;
        }
        // 有collateralId 或者 有collateralId==0（collateralList 0号元素）
        return collateralId[asset] !=0 || collateralList[0] == asset; 
    }

    function collaterals() external view returns (address[] memory) {
        return collateralList;
    }

    function collateralsCount() external view returns (uint) {
        return collateralList.length;
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

