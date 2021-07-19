// SPDX-License-Identifier: bsl-1.1

pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

import "../VaultParameters.sol";

contract OracleRegistry is Auth{
    
    struct Oracle {
        uint oracleType;
        address oracleAddress;
    }

    uint public maxOracleType;

    address public immutable WETH;

    // 根据oracle type查询oracle
    // oracleByType[type] = oracle
    mapping(uint => address) public oracleByType;

    // 根据oracle查询oracle type
    // oracleTypeByOracle[address] = type;
    mapping(address => uint) public oracleTypeByOracle;

    // 根据asset查询oracle type
    // oracleTypeByAsset[asset] = type;
    mapping(address => uint) public oracleTypeByAsset;

    event OracleType(uint indexed oracleType, address indexed oracle);
    event AssetOracle(address indexed asset, uint indexed oracleType);

    modifier validAddress(address asset) {
        require(asset != address(0), "Atom Protocol: ZERO_ADDRESS");
        _;
    }

    modifier validType(uint _type) {
        require(_type != 0, "Atom Ptorocol: INVALID_TYPE");
        _;
    }

    constructor(address _vaultParameters, address _weth) Auth(_vaultParameters) validAddress(_vaultParameters) validAddress(_weth) {
        WETH = _weth;
    }

    /**
        Oracle管理（增删改查）
     */
    function setOracle(uint oracleType, address oracle) public onlyManager validType(oracleType) validAddress(oracle) {
        if(oracleType > maxOracleType){
            maxOracleType = oracleType;
        }

        address oldOracle = oracleByType[oracleType];
        if(oldOracle != address(0)){
            delete oracleByType[oracleType];
        }

        uint oldOracleType = oracleTypeByOracle[oracle];
        if(oldOracleType != 0){
            delete oracleTypeByOracle[oracle];
        }

        oracleByType[oracleType] = oracle;
        oracleTypeByOracle[oracle] = oracleType;

        emit OracleType(oracleType, oracle);
    }

    function unsetOracle(uint oracleType) public onlyManager validType(oracleType) validAddress(oracleByType[oracleType]) {
        address oracle = oracleByType[oracleType];
        delete oracleByType[oracleType];
        delete oracleTypeByOracle[oracle];

        emit OracleType(oracleType, address(0));
    }

    function getOracles() external view returns (Oracle[] memory foundOracles){
        Oracle[] memory allOracles = new Oracle[](maxOracleType);

        uint actualOracleCount;

        for(uint _type=1; _type<=maxOracleType; _type++){
            if(oracleByType[_type] != address(0)){
                allOracles[actualOracleCount++] = Oracle(_type, oracleByType[_type]);
            }
        }

        foundOracles = new Oracle[](actualOracleCount);

        for(uint i=0; i<actualOracleCount; i++){
            foundOracles[i] = allOracles[i];
        }
    }

     /**
        Oracle与Asset相关操作
     */
     function setOracleTypeForAsset(address asset, uint oracleType) public onlyManager validAddress(asset) validType(oracleType) validAddress(oracleByType[oracleType]) {
         oracleTypeByAsset[asset] = oracleType;
         emit AssetOracle(asset, oracleType);
     }

     function setOracleTypeForAssets(address[] calldata assets, uint oracleType) public {
         for(uint i=0; i<assets.length; i++){
             setOracleTypeForAsset(assets[i], oracleType);
         }
     }

    function unsetOracleTypeForAsset(address asset) public onlyManager validAddress(asset) {
        delete oracleTypeByAsset[asset];
        emit AssetOracle(asset, 0);
    }
    
    function unsetOracleTypeForAssets(address[] calldata assets) public {
        for(uint i=0; i<assets.length; i++){
            unsetOracleTypeForAsset(assets[i]);
        }
    }

    function oracleByAsset(address asset) external view returns (address) {
        uint oracleType = oracleTypeByOracle[asset];
        if(oracleType == 0){
            return address(0);
        }
        return oracleByType[oracleType];
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