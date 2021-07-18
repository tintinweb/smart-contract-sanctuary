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