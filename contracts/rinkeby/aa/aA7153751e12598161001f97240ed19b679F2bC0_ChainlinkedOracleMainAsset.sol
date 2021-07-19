// SPDX-License-Identifier: bsl-1.1

pragma solidity 0.7.6;

import "../helpers/SafeMath.sol";
import "../VaultParameters.sol";
import "../interfaces/IOracleUsd.sol";
import "../interfaces/IOracleEth.sol";
import "../interfaces/IWETH.sol";
import "../interfaces/IAggregator.sol";
import "../interfaces/IToken.sol";

contract ChainlinkedOracleMainAsset is IOracleUsd, IOracleEth, Auth{
    using SafeMath for uint;

    /**
       常量定义
    */
    uint public constant Q112 = 2 ** 112;

    uint public constant USD_TYPE = 0;
    uint public constant ETH_TYPE = 1;

    /**
       成员变量
    */
    
    // usdAggregators[asset] = aggregator
    mapping(address => address) public usdAggregators;
    
    // ethAggregators[asset] = aggregator
    mapping(address => address) public ethAggregators;

    /**
        Token引用
     */
     address public immutable WETH;

    /**
       事件
    */
    event NewAggregator(address indexed asset, address indexed aggregator, uint aggType);

    /**
        构造函数

        tokenAddresses1: chainlink提供 asset/usd价格
        tokenAddresses2: chainlink提供 asset/eth价格
     */
    constructor(
        address[] memory tokenAddress1,
        address[] memory _usdAggregators,
        address[] memory tokenAddress2,
        address[] memory _ethAggregators,
        address _weth,
        address _vaultParameters
    ) Auth(_vaultParameters){
        require(tokenAddress1.length == _usdAggregators.length, "Atom Protocol: ARGUMENTS_LENGTH_MISMATCH");
        require(tokenAddress2.length == _ethAggregators.length, "Atom Protocol: ARGUMENTS_LENGTH_MISMATCH");
        require(_weth != address(0) && _vaultParameters != address(0), "Atom Protocol: ZERO_ADDRESS");

        WETH = _weth;

        for(uint i=0; i<tokenAddress1.length; i++){
            usdAggregators[tokenAddress1[i]] = _usdAggregators[i];
            emit NewAggregator(tokenAddress1[i], _usdAggregators[i], USD_TYPE);
        }

        for(uint i=0; i<tokenAddress2.length; i++){
            ethAggregators[tokenAddress2[i]] = _ethAggregators[i];
            emit NewAggregator(tokenAddress2[i], _ethAggregators[i], ETH_TYPE);
        }
    }

    function setAggregators(
        address[] memory tokenAddress1,
        address[] memory _usdAggregators,
        address[] memory tokenAddress2,
        address[] memory _ethAggregators
    ) external onlyManager {
        require(tokenAddress1.length == _usdAggregators.length, "Atom Protocol: ARGUMENTS_LENGTH_MISMATCH");
        require(tokenAddress2.length == _ethAggregators.length, "Atom Protocol: ARGUMENTS_LENGTH_MISMATCH");
        
        for(uint i=0; i<tokenAddress1.length; i++){
            usdAggregators[tokenAddress1[i]] = _usdAggregators[i];
            emit NewAggregator(tokenAddress1[i], _usdAggregators[i], USD_TYPE);
        }

        for(uint i=0; i<tokenAddress2.length; i++){
            ethAggregators[tokenAddress2[i]] = _ethAggregators[i];
            emit NewAggregator(tokenAddress2[i], _ethAggregators[i], ETH_TYPE);
        }
    }

    /**
       IOracleUsd 接口实现
    */
    function assetToUsd(address asset, uint amount) public override view returns (uint){
        if(amount == 0){
            return 0;
        }

        if(usdAggregators[asset] != address(0)){
            return _assetToUsd(asset, amount);
        }

        return ethToUsd(assetToEth(asset, amount));
    }

     /**
        IOracleEth 接口实现
     */
     function assetToEth(address asset, uint amount) public override view returns (uint) {
        if(amount == 0){
            return 0;
        }
        if(asset == WETH){
            return amount.mul(Q112);
        }
        IAggregator agg = IAggregator(ethAggregators[asset]);

        // 如果没有直接对应的agg，则先转成usd，再转成eth
        if(address(agg) == address(0)){
            require(usdAggregators[asset] != address(0), "Atom Protocol: AGGREGATOR_DOES_NOT_EXIST");
            return usdToEth(_assetToUsd(asset, amount));
        }

        // 获取预言机最新数据
        (, int256 answer, , uint256 updatedAt, ) = agg.latestRoundData();

        // 确保价格在24小时内更新过
        require(updatedAt > block.timestamp - 24 hours, "Atom Protocol: STALE_CHAINLINK_PRICE");

        // 确保价格不为负数
        require(answer >=0, "Atom Protocol: NEGATIVE_CHAINLINK_PRICE");

        // 确保返回值是1e18的精度
        int decimals = 18 - int(IToken(asset).decimals() - int(agg.decimals()));
        if(decimals <0 ){
            // ETH = 18-18-8=-8
            // agg精度 8 + eth精度 18 - 计算之后的decimals |-8| = 18
            return amount.mul(uint(answer)).mul(Q112).div(10 ** uint(-decimals));
        }
        else{
            // USDT= 18-6-8=4
            // agg精度 8 + usdt精度 6 + 计算之后的decimals 4 = 18
            return amount.mul(uint(answer)).mul(Q112).mul(10 ** uint(decimals));
        }

     }

     function ethToUsd(uint ethAmount) public override view returns (uint) {
         IAggregator agg = IAggregator(usdAggregators[WETH]);
         (, int256 answer, , uint256 updatedAt, ) = agg.latestRoundData();
         // 确保价格在6小时内更新过
         require(updatedAt > block.timestamp - 6 hours, "Atom Protocol: STALE_CHAINLINK_PRICE");
         return ethAmount.mul(uint(answer)).div(10 ** agg.decimals());
     }

     function usdToEth(uint usdAmount) public override view returns (uint) {
        IAggregator agg = IAggregator(usdAggregators[WETH]);
        (, int256 answer, , uint256 updatedAt, ) = agg.latestRoundData();
        // 确保价格在6小时内更新过
        require(updatedAt > block.timestamp - 6 hours, "Atom Protocol: STALE_CHAINLINK_PRICE");
        return usdAmount.mul(10 ** agg.decimals()).div(uint(answer));
     }

    /**
        工具函数（内部）
    */

    /**
        计算资产的usd价格

        返回值说明：
        returned value 10**18 * 2**112 is $1

        1 ETH:
        10997009730817894981449980545022455113349857280000000000/5192296858534827628530496329220096/1e18=2117.947033929999712

        100 USDT:
        519379016311134224495646169996437969960960000000000000/5192296858534827628530496329220096/1e18=100.02876
     */
    function _assetToUsd(address asset, uint amount) internal view returns (uint) {
        // 获取预言机最新数据
        IAggregator agg = IAggregator(usdAggregators[asset]);
        (, int256 answer, , uint256 updatedAt, ) = agg.latestRoundData();

        // 确保价格在24小时内更新过
        require(updatedAt > block.timestamp - 24 hours, "Atom Protocol: STALE_CHAINLINK_PRICE");

        // 确保价格不为负数
        require(answer >=0, "Atom Protocol: NEGATIVE_CHAINLINK_PRICE");

        // 确保返回值是1e18的精度
        int decimals = 18 - int(IToken(asset).decimals() - int(agg.decimals()));
        if(decimals <0 ){
            // ETH = 18-18-8=-8
            // agg精度 8 + eth精度 18 - 计算之后的decimals |-8| = 18
            return amount.mul(uint(answer)).mul(Q112).div(10 ** uint(-decimals));
        }
        else{
            // USDT= 18-6-8=4
            // agg精度 8 + usdt精度 6 + 计算之后的decimals 4 = 18
            return amount.mul(uint(answer)).mul(Q112).mul(10 ** uint(decimals));
        }
    }

    function _assetToUsdTest(address asset, uint amount) public view returns (int,int,int) {
        // 获取预言机最新数据
        IAggregator agg = IAggregator(usdAggregators[asset]);
        (, int256 answer, , uint256 updatedAt, ) = agg.latestRoundData();

        // 确保价格在24小时内更新过
        require(updatedAt > block.timestamp - 24 hours, "Atom Protocol: STALE_CHAINLINK_PRICE");

        // 确保价格不为负数
        require(answer >=0, "Atom Protocol: NEGATIVE_CHAINLINK_PRICE");

        // 确保返回值是1e18的精度
        int decimals = 18 - int(IToken(asset).decimals() - int(agg.decimals()));
        return (decimals, int(IToken(asset).decimals()), int(agg.decimals()) );
        // if(decimals <0 ){
        //     // ETH = 18-18-8=-8
        //     // agg精度 8 + eth精度 18 - 计算之后的decimals |-8| = 18
        //     return amount.mul(uint(answer)).mul(Q112).div(10 ** uint(-decimals));
        // }
        // else{
        //     // USDT= 18-6-8=4
        //     // agg精度 8 + usdt精度 6 + 计算之后的decimals 4 = 18
        //     return amount.mul(uint(answer)).mul(Q112).mul(10 ** uint(decimals));
        // }
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

interface IOracleUsd {
    
    // returns Q112-encoded value
    // returned value 10**18 * 2**112 is $1
    function assetToUsd(address asset, uint amount) external view returns (uint);
}

// SPDX-License-Identifier: bsl-1.1

pragma solidity 0.7.6;

interface IOracleEth {
    
    // returns Q112-encoded value
    // returned value 10**18 * 2**112 is 1 Eth
    function assetToEth(address asset, uint amount) external view returns (uint);

    // returns Q112-encoded value
    function ethToUsd(uint amount) external view returns (uint);

    // returns Q112-encoded value
    function usdToEth(uint amount) external view returns (uint);
}

// SPDX-License-Identifier: bsl-1.1

pragma solidity 0.7.6;

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

// SPDX-License-Identifier: bsl-1.1

pragma solidity 0.7.6;

interface IAggregator {
    function latestAnswer() external view returns (int256);
    function latestTimestamp() external view returns (uint256);
    function latestRound() external view returns (uint256);
    function getAnswer(uint256 roundId) external view returns (int256);
    function getTimestamp(uint256 roundId) external view returns (uint256);
    
    function latestRoundData() external view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );


    function decimals() external view returns (uint256);
    
    event AnswerUpdated(int256 indexed current, uint256 indexed roundId, uint256 updatedAt);
    event NewRound(uint256 indexed roundId, address indexed startedBy, uint256 startedAt);
}

// SPDX-License-Identifier: bsl-1.1

pragma solidity 0.7.6;

interface IToken {
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function balanceOf(address) external view returns (uint);
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