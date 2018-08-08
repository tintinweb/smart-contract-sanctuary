pragma solidity 0.4.24;
  
//@title WitToken
//@author(luoyuanq233@gmail.com) 
//@dev 该合约参考自openzeppelin的erc20实现
//1.使用openzeppelin的SafeMath库防止运算溢出
//2.使用openzeppelin的Ownable,Roles,RBAC来做权限控制,自定义了ceo,coo,cro等角色  
//3.ERC20扩展了ERC20Basic，实现了授权转移
//4.BasicToken,StandardToken,PausableToken均是erc20的具体实现
//5.BlackListToken加入黑名单方法
//6.TwoPhaseToken可以发行和赎回资产,并采用经办复核的二阶段提交
//7.UpgradedStandardToken参考自TetherUSD合约,可以在另一个合约升级erc20的方法
//8.可以设置交易的手续费率


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
   constructor() public {
      owner = msg.sender;
  }


  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

  /**
 * @title Roles
 * @author Francisco Giordano (@frangio)
 * @dev Library for managing addresses assigned to a Role.
 *      See RBAC.sol for example usage.
 */
library Roles {
  struct Role {
    mapping (address => bool) bearer;
  }

  /**
   * @dev give an address access to this role
   */
  function add(Role storage role, address addr) internal {
    role.bearer[addr] = true;
  }

  /**
   * @dev remove an address&#39; access to this role
   */
  function remove(Role storage role, address addr) internal {
    role.bearer[addr] = false;
  }

  /**
   * @dev check if an address has this role
   * // reverts
   */
  function check(Role storage role, address addr) view internal {
    require(has(role, addr));
  }

  /**
   * @dev check if an address has this role
   * @return bool
   */
  function has(Role storage role, address addr) view internal returns (bool) {
    return role.bearer[addr];
  }
}

/**
 * @title RBAC (Role-Based Access Control)
 * @author Matt Condon (@Shrugs)
 * @dev Stores and provides setters and getters for roles and addresses.
 *      Supports unlimited numbers of roles and addresses.
 *      See //contracts/mocks/RBACMock.sol for an example of usage.
 * This RBAC method uses strings to key roles. It may be beneficial
 *  for you to write your own implementation of this interface using Enums or similar.
 * It&#39;s also recommended that you define constants in the contract, like ROLE_ADMIN below,
 *  to avoid typos.
 */
contract RBAC is Ownable {
  using Roles for Roles.Role;

  mapping (string => Roles.Role) private roles;

  event RoleAdded(address addr, string roleName);
  event RoleRemoved(address addr, string roleName);

  /**
   * A constant role name for indicating admins.
   */
  string public constant ROLE_CEO = "ceo";
  string public constant ROLE_COO = "coo";//运营
  string public constant ROLE_CRO = "cro";//风控
  string public constant ROLE_MANAGER = "manager";//经办员
  string public constant ROLE_REVIEWER = "reviewer";//审核员
  
  /**
   * @dev constructor. Sets msg.sender as ceo by default
   */
  constructor() public{
    addRole(msg.sender, ROLE_CEO);
  }
  
  /**
   * @dev reverts if addr does not have role
   * @param addr address
   * @param roleName the name of the role
   * // reverts
   */
  function checkRole(address addr, string roleName) view internal {
    roles[roleName].check(addr);
  }

  /**
   * @dev determine if addr has role
   * @param addr address
   * @param roleName the name of the role
   * @return bool
   */
  function hasRole(address addr, string roleName) view public returns (bool) {
    return roles[roleName].has(addr);
  }

  function ownerAddCeo(address addr) onlyOwner public {
    addRole(addr, ROLE_CEO);
  }
  
  function ownerRemoveCeo(address addr) onlyOwner public{
    removeRole(addr, ROLE_CEO);
  }

  function ceoAddCoo(address addr) onlyCEO public {
    addRole(addr, ROLE_COO);
  }
  
  function ceoRemoveCoo(address addr) onlyCEO public{
    removeRole(addr, ROLE_COO);
  }
  
  function cooAddManager(address addr) onlyCOO public {
    addRole(addr, ROLE_MANAGER);
  }
  
  function cooRemoveManager(address addr) onlyCOO public {
    removeRole(addr, ROLE_MANAGER);
  }
  
  function cooAddReviewer(address addr) onlyCOO public {
    addRole(addr, ROLE_REVIEWER);
  }
  
  function cooRemoveReviewer(address addr) onlyCOO public {
    removeRole(addr, ROLE_REVIEWER);
  }
  
  function cooAddCro(address addr) onlyCOO public {
    addRole(addr, ROLE_CRO);
  }
  
  function cooRemoveCro(address addr) onlyCOO public {
    removeRole(addr, ROLE_CRO);
  }

  /**
   * @dev add a role to an address
   * @param addr address
   * @param roleName the name of the role
   */
  function addRole(address addr, string roleName) internal {
    roles[roleName].add(addr);
    emit RoleAdded(addr, roleName);
  }

  /**
   * @dev remove a role from an address
   * @param addr address
   * @param roleName the name of the role
   */
  function removeRole(address addr, string roleName) internal {
    roles[roleName].remove(addr);
    emit RoleRemoved(addr, roleName);
  }


  /**
   * @dev modifier to scope access to ceo
   * // reverts
   */
  modifier onlyCEO() {
    checkRole(msg.sender, ROLE_CEO);
    _;
  }

  /**
   * @dev modifier to scope access to coo
   * // reverts
   */
  modifier onlyCOO() {
    checkRole(msg.sender, ROLE_COO);
    _;
  }
  
  /**
   * @dev modifier to scope access to cro
   * // reverts
   */
  modifier onlyCRO() {
    checkRole(msg.sender, ROLE_CRO);
    _;
  }
  
  /**
   * @dev modifier to scope access to manager
   * // reverts
   */
  modifier onlyMANAGER() {
    checkRole(msg.sender, ROLE_MANAGER);
    _;
  }
  
  /**
   * @dev modifier to scope access to reviewer
   * // reverts
   */
  modifier onlyREVIEWER() {
    checkRole(msg.sender, ROLE_REVIEWER);
    _;
  }

}


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}




/**
 * 
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}



/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic, RBAC {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  uint256 totalSupply_;
  
  uint256 public basisPointsRate;//手续费率 
  uint256 public maximumFee;//最大手续费 
  address public assetOwner;//收取的手续费和增发的资产都到这个地址上, 赎回资产时会从这个地址销毁资产 

  /**
  * @dev total number of tokens in existence
  */
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    uint256 fee = (_value.mul(basisPointsRate)).div(10000);
    if (fee > maximumFee) {
        fee = maximumFee;
    }
    uint256 sendAmount = _value.sub(fee);
    
    // SafeMath.sub will throw if there is not enough balance.
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(sendAmount);
    if (fee > 0) {
        balances[assetOwner] = balances[assetOwner].add(fee);
        emit Transfer(msg.sender, assetOwner, fee);
    }
    
    emit Transfer(msg.sender, _to, sendAmount);
    return true;
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }

}


/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is ERC20, BasicToken  {

  mapping (address => mapping (address => uint256)) internal allowed;


  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    uint256 fee = (_value.mul(basisPointsRate)).div(10000);
        if (fee > maximumFee) {
            fee = maximumFee;
        }
    uint256 sendAmount = _value.sub(fee);
    
    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(sendAmount);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    if (fee > 0) {
            balances[assetOwner] = balances[assetOwner].add(fee);
            emit Transfer(_from, assetOwner, fee);
        }
    emit Transfer(_from, _to, sendAmount);
    return true;
  }

  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   *
   * Beware that changing an allowance with this method brings the risk that someone may use both the old
   * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
   * race condition is to first reduce the spender&#39;s allowance to 0 and set the desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifying the amount of tokens still available for the spender.
   */
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

  /**
   * @dev Increase the amount of tokens that an owner allowed to a spender.
   *
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _addedValue The amount of tokens to increase the allowance by.
   */
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  /**
   * @dev Decrease the amount of tokens that an owner allowed to a spender.
   *
   * approve should be called when allowed[_spender] == 0. To decrement
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _subtractedValue The amount of tokens to decrease the allowance by.
   */
  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}




/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is RBAC {
  event Pause();
  event Unpause();

  bool public paused = false;

  /**
   * @dev Modifier to make a function callable only when the contract is not paused.
   */
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  /**
   * @dev Modifier to make a function callable only when the contract is paused.
   */
  modifier whenPaused() {
    require(paused);
    _;
  }

  /**
   * @dev called by the ceo to pause, triggers stopped state
   */
  function pause() onlyCEO whenNotPaused public {
    paused = true;
    emit Pause();
  }

  /**
   * @dev called by the ceo to unpause, returns to normal state
   */
  function unpause() onlyCEO whenPaused public {
    paused = false;
    emit Unpause();
  }
}



/**
 * @title Pausable token
 * @dev StandardToken modified with pausable transfers.
 **/
contract PausableToken is StandardToken, Pausable {

  function transfer(address _to, uint256 _value) public whenNotPaused returns (bool) {
    return super.transfer(_to, _value);
  }

  function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool) {
    return super.transferFrom(_from, _to, _value);
  }

  function approve(address _spender, uint256 _value) public whenNotPaused returns (bool) {
    return super.approve(_spender, _value);
  }

  function increaseApproval(address _spender, uint _addedValue) public whenNotPaused returns (bool success) {
    return super.increaseApproval(_spender, _addedValue);
  }

  function decreaseApproval(address _spender, uint _subtractedValue) public whenNotPaused returns (bool success) {
    return super.decreaseApproval(_spender, _subtractedValue);
  }
}


contract BlackListToken is PausableToken  {

  
    function getBlackListStatus(address _maker) external view returns (bool) {
        return isBlackListed[_maker];
    }

    mapping (address => bool) public isBlackListed;
    
    function addBlackList (address _evilUser) public onlyCRO {
        isBlackListed[_evilUser] = true;
        emit AddedBlackList(_evilUser);
    }

    function removeBlackList (address _clearedUser) public onlyCRO {
        isBlackListed[_clearedUser] = false;
        emit RemovedBlackList(_clearedUser);
    }

    function destroyBlackFunds (address _blackListedUser) public onlyCEO {
        require(isBlackListed[_blackListedUser]);
        uint dirtyFunds = balanceOf(_blackListedUser);
        balances[_blackListedUser] = 0;
        totalSupply_ = totalSupply_.sub(dirtyFunds);
        emit DestroyedBlackFunds(_blackListedUser, dirtyFunds);
    }

    event DestroyedBlackFunds(address _blackListedUser, uint _balance);

    event AddedBlackList(address _user);

    event RemovedBlackList(address _user);

}





/**
* 增发和赎回token由经办人和复核人配合完成
* 1.由经办人角色先执行submitIssue或submitRedeem;
* 2.复核人角色再来执行comfirmIsses或comfirmRedeem;
* 3.两者提交的参数一致，则增发和赎回才能成功
* 4.经办人提交数据后，复核人执行成功后，需要经办人再次提交才能再次执行
**/
contract TwoPhaseToken is BlackListToken{
    
    //保存经办人提交的参数
    struct MethodParam {
        string method; //方法名
        uint value;  //增发或者赎回的数量
        bool state;  //true表示经办人有提交数据,复核人执行成功后变为false
    }
    
    mapping (string => MethodParam) params;
    
    //方法名常量 
    string public constant ISSUE_METHOD = "issue";
    string public constant REDEEM_METHOD = "redeem";
    
    
    //经办人提交增发数量
    function submitIssue(uint _value) public onlyMANAGER {
        params[ISSUE_METHOD] = MethodParam(ISSUE_METHOD, _value, true);
        emit SubmitIsses(msg.sender,_value);
    }
    
    //复核人第二次确认增发数量并执行
    function comfirmIsses(uint _value) public onlyREVIEWER {
       
        require(params[ISSUE_METHOD].value == _value);
        require(params[ISSUE_METHOD].state == true);
        
        balances[assetOwner]=balances[assetOwner].add(_value);
        totalSupply_ = totalSupply_.add(_value);
        params[ISSUE_METHOD].state=false; 
        emit ComfirmIsses(msg.sender,_value);
    }
    
    //经办人提交赎回数量
    function submitRedeem(uint _value) public onlyMANAGER {
        params[REDEEM_METHOD] = MethodParam(REDEEM_METHOD, _value, true);
         emit SubmitRedeem(msg.sender,_value);
    }
    
    //复核人第二次确认赎回数量并执行
    function comfirmRedeem(uint _value) public onlyREVIEWER {
       
       require(params[REDEEM_METHOD].value == _value);
       require(params[REDEEM_METHOD].state == true);
       
       balances[assetOwner]=balances[assetOwner].sub(_value);
       totalSupply_ = totalSupply_.sub(_value);
       params[REDEEM_METHOD].state=false;
       emit ComfirmIsses(msg.sender,_value);
    }
    
    //根据方法名，查看经办人提交的参数
    function getMethodValue(string _method) public view returns(uint){
        return params[_method].value;
    }
    
    //根据方法名，查看经办人是否有提交数据
    function getMethodState(string _method) public view returns(bool) {
      return params[_method].state;
    }
   
     event SubmitRedeem(address submit, uint _value);
     event ComfirmRedeem(address comfirm, uint _value);
     event SubmitIsses(address submit, uint _value);
     event ComfirmIsses(address comfirm, uint _value);

    
}



contract UpgradedStandardToken {
    // those methods are called by the legacy contract
    function totalSupplyByLegacy() public view returns (uint256);
    function balanceOfByLegacy(address who) public view returns (uint256);
    function transferByLegacy(address origSender, address to, uint256 value) public returns (bool);
    function allowanceByLegacy(address owner, address spender) public view returns (uint256);
    function transferFromByLegacy(address origSender, address from, address to, uint256 value) public returns (bool);
    function approveByLegacy(address origSender, address spender, uint256 value) public returns (bool);
    function increaseApprovalByLegacy(address origSender, address spender, uint addedValue) public returns (bool);
    function decreaseApprovalByLegacy(address origSende, address spender, uint subtractedValue) public returns (bool);
}




contract WitToken is TwoPhaseToken {
    string  public  constant name = "Wealth in Tokens";
    string  public  constant symbol = "WIT";
    uint8   public  constant decimals = 18;
    address public upgradedAddress;
    bool public deprecated;

    modifier validDestination( address to ) {
        require(to != address(0x0));
        require(to != address(this));
        _;
    }

    constructor ( uint _totalTokenAmount ) public {
        basisPointsRate = 0;
        maximumFee = 0;
        totalSupply_ = _totalTokenAmount;
        balances[msg.sender] = _totalTokenAmount;
        deprecated = false;
        assetOwner = msg.sender;
        emit Transfer(address(0x0), msg.sender, _totalTokenAmount);
    }
    
    
    
     // Forward ERC20 methods to upgraded contract if this one is deprecated
     function totalSupply() public view returns (uint256) {
         if (deprecated) {
            return UpgradedStandardToken(upgradedAddress).totalSupplyByLegacy();
        } else {
            return totalSupply_;
        }
    }
    
    // Forward ERC20 methods to upgraded contract if this one is deprecated
    function balanceOf(address _owner) public view returns (uint256 balance) {
         if (deprecated) {
            return UpgradedStandardToken(upgradedAddress).balanceOfByLegacy( _owner);
        } else {
           return super.balanceOf(_owner);
        }
    }

    
    // Forward ERC20 methods to upgraded contract if this one is deprecated
    function transfer(address _to, uint _value) public validDestination(_to) returns (bool) {
        require(!isBlackListed[msg.sender]);
        if (deprecated) {
            return UpgradedStandardToken(upgradedAddress).transferByLegacy(msg.sender, _to, _value);
        } else {
            return super.transfer(_to, _value);
        }
        
    }


    // Forward ERC20 methods to upgraded contract if this one is deprecated
    function allowance(address _owner, address _spender) public view returns (uint256) {
        if (deprecated) {
            return UpgradedStandardToken(upgradedAddress).allowanceByLegacy(_owner, _spender);
        } else {
           return super.allowance(_owner, _spender);
        }
        
    }


    // Forward ERC20 methods to upgraded contract if this one is deprecated
    function transferFrom(address _from, address _to, uint _value) public validDestination(_to) returns (bool) {
        require(!isBlackListed[_from]);
        if (deprecated) {
            return UpgradedStandardToken(upgradedAddress).transferFromByLegacy(msg.sender, _from, _to, _value);
        } else {
            return super.transferFrom(_from, _to, _value);
        }
       
    }
    
    
     // Forward ERC20 methods to upgraded contract if this one is deprecated
     function approve(address _spender, uint256 _value) public returns (bool) {
          if (deprecated) {
            return UpgradedStandardToken(upgradedAddress).approveByLegacy(msg.sender, _spender, _value);
        } else {
            return super.approve(_spender, _value);
        } 
    }
    
    
    // Forward ERC20 methods to upgraded contract if this one is deprecated
    function increaseApproval(address _spender, uint _value) public returns (bool) {
         if (deprecated) {
            return UpgradedStandardToken(upgradedAddress).increaseApprovalByLegacy(msg.sender, _spender, _value);
        } else {
            return super.increaseApproval(_spender, _value);
        } 
    }


    // Forward ERC20 methods to upgraded contract if this one is deprecated
    function decreaseApproval(address _spender, uint _value) public returns (bool) {
        if (deprecated) {
            return UpgradedStandardToken(upgradedAddress).decreaseApprovalByLegacy(msg.sender, _spender, _value);
        } else {
            return super.decreaseApproval(_spender, _value);
        } 
   }
   
   
    // deprecate current contract in favour of a new one
    function deprecate(address _upgradedAddress) public onlyCEO whenPaused {
        deprecated = true;
        upgradedAddress = _upgradedAddress;
        emit Deprecate(_upgradedAddress);
    }
    
    // Called when contract is deprecated
    event Deprecate(address newAddress);
    
    
   /**
   * @dev Set up transaction fees
   * @param newBasisPoints  A few ten-thousandth (设置手续费率为万分之几)
   * @param newMaxFee Maximum fee (设置最大手续费,不需要添加decimals)
   */
    function setFeeParams(uint newBasisPoints, uint newMaxFee) public onlyCEO {
       
        basisPointsRate = newBasisPoints;
        maximumFee = newMaxFee.mul(uint(10)**decimals);
        emit FeeParams(basisPointsRate, maximumFee);
    }
    

    function transferAssetOwner(address newAssetOwner) public onlyCEO {
      require(newAssetOwner != address(0));
      assetOwner = newAssetOwner;
      emit TransferAssetOwner(assetOwner, newAssetOwner);
    }
    
    event TransferAssetOwner(address assetOwner, address newAssetOwner);
    
     // Called if contract ever adds fees
    event FeeParams(uint feeBasisPoints, uint maxFee);
    
    
    

}