pragma solidity ^0.4.24;

/**
 * Utility library of inline functions on addresses
 */
library AddressUtils {

  /**
   * Returns whether the target address is a contract
   * @dev This function will return false if invoked during the constructor of a contract,
   * as the code is not actually created until after the constructor finishes.
   * @param addr address to check
   * @return whether the target address is a contract
   */
  function isContract(address addr) internal view returns (bool) {
    uint256 size;
    // XXX Currently there is no better way to check if there is a contract in an address
    // than to check the size of the code at that address.
    // See https://ethereum.stackexchange.com/a/14016/36603
    // for more details about how this works.
    // TODO Check this again before the Serenity release, because all addresses will be
    // contracts then.
    // solium-disable-next-line security/no-inline-assembly
    assembly { size := extcodesize(addr) }
    return size > 0;
  }

}

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return a / b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


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
   * @dev Allows the current owner to relinquish control of the contract.
   * @notice Renouncing to ownership will leave the contract without an owner.
   * It will not be possible to call the functions with the `onlyOwner`
   * modifier anymore.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

/**
 * @title Roles
 * @author Francisco Giordano (@frangio)
 * @dev Library for managing addresses assigned to a Role.
 * See RBAC.sol for example usage.
 */
library Roles {
  struct Role {
    mapping (address => bool) bearer;
  }

  /**
   * @dev give an address access to this role
   */
  function add(Role storage role, address addr)
    internal
  {
    role.bearer[addr] = true;
  }

  /**
   * @dev remove an address&#39; access to this role
   */
  function remove(Role storage role, address addr)
    internal
  {
    role.bearer[addr] = false;
  }

  /**
   * @dev check if an address has this role
   * // reverts
   */
  function check(Role storage role, address addr)
    view
    internal
  {
    require(has(role, addr));
  }

  /**
   * @dev check if an address has this role
   * @return bool
   */
  function has(Role storage role, address addr)
    view
    internal
    returns (bool)
  {
    return role.bearer[addr];
  }
}

/**
 * @title RBAC (Role-Based Access Control)
 * @author Matt Condon (@Shrugs)
 * @dev Stores and provides setters and getters for roles and addresses.
 * Supports unlimited numbers of roles and addresses.
 * See //contracts/mocks/RBACMock.sol for an example of usage.
 * This RBAC method uses strings to key roles. It may be beneficial
 * for you to write your own implementation of this interface using Enums or similar.
 */
contract RBAC {
  using Roles for Roles.Role;

  mapping (string => Roles.Role) private roles;

  event RoleAdded(address indexed operator, string role);
  event RoleRemoved(address indexed operator, string role);

  /**
   * @dev reverts if addr does not have role
   * @param _operator address
   * @param _role the name of the role
   * // reverts
   */
  function checkRole(address _operator, string _role)
    view
    public
  {
    roles[_role].check(_operator);
  }

  /**
   * @dev determine if addr has role
   * @param _operator address
   * @param _role the name of the role
   * @return bool
   */
  function hasRole(address _operator, string _role)
    view
    public
    returns (bool)
  {
    return roles[_role].has(_operator);
  }

  /**
   * @dev add a role to an address
   * @param _operator address
   * @param _role the name of the role
   */
  function addRole(address _operator, string _role)
    internal
  {
    roles[_role].add(_operator);
    emit RoleAdded(_operator, _role);
  }

  /**
   * @dev remove a role from an address
   * @param _operator address
   * @param _role the name of the role
   */
  function removeRole(address _operator, string _role)
    internal
  {
    roles[_role].remove(_operator);
    emit RoleRemoved(_operator, _role);
  }

  /**
   * @dev modifier to scope access to a single role (uses msg.sender as addr)
   * @param _role the name of the role
   * // reverts
   */
  modifier onlyRole(string _role)
  {
    checkRole(msg.sender, _role);
    _;
  }

  /**
   * @dev modifier to scope access to a set of roles (uses msg.sender as addr)
   * @param _roles the names of the roles to scope access to
   * // reverts
   *
   * @TODO - when solidity supports dynamic arrays as arguments to modifiers, provide this
   *  see: https://github.com/ethereum/solidity/issues/2467
   */
  // modifier onlyRoles(string[] _roles) {
  //     bool hasAnyRole = false;
  //     for (uint8 i = 0; i < _roles.length; i++) {
  //         if (hasRole(msg.sender, _roles[i])) {
  //             hasAnyRole = true;
  //             break;
  //         }
  //     }

  //     require(hasAnyRole);

  //     _;
  // }
}

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * See https://github.com/ethereum/EIPs/issues/179
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
  function allowance(address owner, address spender)
    public view returns (uint256);

  function transferFrom(address from, address to, uint256 value)
    public returns (bool);

  function approve(address spender, uint256 value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) internal balances;

  uint256 internal totalSupply_;

  /**
  * @dev Total number of tokens in existence
  */
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

  /**
  * @dev Transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_value <= balances[msg.sender]);
    require(_to != address(0));

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }

}

/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * https://github.com/ethereum/EIPs/issues/20
 * Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;

  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
    public
    returns (bool)
  {
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);
    require(_to != address(0));

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   * Beware that changing an allowance with this method brings the risk that someone may use both the old
   * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
   * race condition is to first reduce the spender&#39;s allowance to 0 and set the desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) public returns (bool) {
    require(_spender != address(0));
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
  function allowance(
    address _owner,
    address _spender
   )
    public
    view
    returns (uint256)
  {
    return allowed[_owner][_spender];
  }

  /**
   * @dev Increase the amount of tokens that an owner allowed to a spender.
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _addedValue The amount of tokens to increase the allowance by.
   */
  function increaseApproval(
    address _spender,
    uint256 _addedValue
  )
    public
    returns (bool)
  {
    require(_spender != address(0));
    allowed[msg.sender][_spender] = (
      allowed[msg.sender][_spender].add(_addedValue));
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  /**
   * @dev Decrease the amount of tokens that an owner allowed to a spender.
   * approve should be called when allowed[_spender] == 0. To decrement
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _subtractedValue The amount of tokens to decrease the allowance by.
   */
  function decreaseApproval(
    address _spender,
    uint256 _subtractedValue
  )
    public
    returns (bool)
  {
    require(_spender != address(0));
    uint256 oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue >= oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

contract IdaToken is Ownable, RBAC, StandardToken {
    using AddressUtils for address;
    using SafeMath for uint256;

    string public name    = "IDA";
    string public symbol  = "IDA";
    uint8 public decimals = 18;

    // 初始发行量 100 亿
    uint256 public constant INITIAL_SUPPLY          = 10000000000;
    // 基石轮额度 3.96 亿
    uint256 public constant FOOTSTONE_ROUND_AMOUNT  = 396000000;
    // 私募额度 12 亿
    uint256 public constant PRIVATE_SALE_AMOUNT     = 1200000000;
    // 2019/05/01 之前的 Owner 锁仓额度 50 亿
    uint256 public constant OWNER_LOCKED_IN_COMMON     = 5000000000;
    // 通用额度 72.04 亿 （IDA 基金会、研发、生态建设、社区建设、运营）
    uint256 public constant COMMON_PURPOSE_AMOUNT   = 7204000000;
    // 团队预留额度1 1.2 亿
    uint256 public constant TEAM_RESERVED_AMOUNT1   = 120000000;
    // 团队预留额度2 3.6 亿
    uint256 public constant TEAM_RESERVED_AMOUNT2   = 360000000;
    // 团队预留额度3 3.6 亿
    uint256 public constant TEAM_RESERVED_AMOUNT3   = 360000000;
    // 团队预留额度4 3.6 亿
    uint256 public constant TEAM_RESERVED_AMOUNT4   = 360000000;

    // 私募中的 Ether 兑换比率，1 Ether = 10000 IDA
    uint256 public constant EXCHANGE_RATE_IN_PRIVATE_SALE = 10000;

    // 2018/10/01 00:00:01 的时间戳常数
    uint256 public constant TIMESTAMP_OF_20181001000001 = 1538352001;
    // 2018/10/02 00:00:01 的时间戳常数
    uint256 public constant TIMESTAMP_OF_20181002000001 = 1538438401;
    // 2018/11/01 00:00:01 的时间戳常数
    uint256 public constant TIMESTAMP_OF_20181101000001 = 1541030401;
    // 2019/02/01 00:00:01 的时间戳常数
    uint256 public constant TIMESTAMP_OF_20190201000001 = 1548979201;
    // 2019/05/01 00:00:01 的时间戳常数
    uint256 public constant TIMESTAMP_OF_20190501000001 = 1556668801;
    // 2019/08/01 00:00:01 的时间戳常数
    uint256 public constant TIMESTAMP_OF_20190801000001 = 1564617601;
    // 2019/11/01 00:00:01 的时间戳常数
    uint256 public constant TIMESTAMP_OF_20191101000001 = 1572566401;
    // 2020/11/01 00:00:01 的时间戳常数
    uint256 public constant TIMESTAMP_OF_20201101000001 = 1604188801;
    // 2021/11/01 00:00:01 的时间戳常数
    uint256 public constant TIMESTAMP_OF_20211101000001 = 1635724801;

    // Role constant of Partner Whitelist
    string public constant ROLE_PARTNERWHITELIST = "partnerWhitelist";
    // Role constant of Privatesale Whitelist
    string public constant ROLE_PRIVATESALEWHITELIST = "privateSaleWhitelist";

    // 由 Owner 分发的总数额
    uint256 public totalOwnerReleased;
    // 所有 partner 的已分发额总数
    uint256 public totalPartnersReleased;
    // 所有私募代理人的已分发数额总数
    uint256 public totalPrivateSalesReleased;
    // 通用额度的已分发数额总数
    uint256 public totalCommonReleased;
    // 团队保留额度的已分发数额总数1
    uint256 public totalTeamReleased1;
    // 团队保留额度的已分发数额总数2
    uint256 public totalTeamReleased2;
    // 团队保留额度的已分发数额总数3
    uint256 public totalTeamReleased3;
    // 团队保留额度的已分发数额总数4
    uint256 public totalTeamReleased4;

    // Partner 地址数组
    address[] private partners;
    // Partner 地址在数组中索引
    mapping (address => uint256) private partnersIndex;
    // 私募代理人地址数组
    address[] private privateSaleAgents;
    // 私募代理人地址在数组中的索引
    mapping (address => uint256) private privateSaleAgentsIndex;

    // Partner 限额映射
    mapping (address => uint256) private partnersAmountLimit;
    // Partner 实际已转账额度映射
    mapping (address => uint256) private partnersWithdrawed;
    // 私募代理人实际转出（售出）的 token 数量映射
    mapping (address => uint256) private privateSalesReleased;

    // Owner 的钱包地址
    address ownerWallet;

    // Log 特定的转账函数操作
    event TransferLog(address from, address to, bytes32 functionName, uint256 value);

    /**
     * @dev 构造函数时需传入 Owner 指定的钱包地址
     * @param _ownerWallet Owner 的钱包地址
     */
    constructor(address _ownerWallet) public {
        ownerWallet = _ownerWallet;
        totalSupply_ = INITIAL_SUPPLY * (10 ** uint256(decimals));
        balances[msg.sender] = totalSupply_;
    }

    /**
     * @dev 变更 Owner 的钱包地址
     * @param _ownerWallet Owner 的钱包地址
     */
    function changeOwnerWallet(address _ownerWallet) public onlyOwner {
        ownerWallet = _ownerWallet;
    }

    /**
     * @dev 添加 partner 地址到白名单并设置其限额
     * @param _addr Partner 地址
     * @param _amount Partner 的持有限额
     */
    function addAddressToPartnerWhiteList(address _addr, uint256 _amount)
        public onlyOwner
    {
        // 仅允许在 2018/11/01 00:00:01 之前调用
        require(block.timestamp < TIMESTAMP_OF_20181101000001);
        // 如 _addr 不在白名单内，则执行添加处理
        if (!hasRole(_addr, ROLE_PARTNERWHITELIST)) {
            addRole(_addr, ROLE_PARTNERWHITELIST);
            // 把给定地址加入 partner 数组
            partnersIndex[_addr] = partners.length;
            partners.push(_addr);
        }
        // Owner 可以多次调用此函数以达到修改 partner 授权上限的效果
        partnersAmountLimit[_addr] = _amount;
    }

    /**
     * @dev 将 partner 地址从白名单移除
     * @param _addr Partner 地址
     */
    function removeAddressFromPartnerWhiteList(address _addr)
        public onlyOwner
    {
        // 仅允许在 2018/11/01 00:00:01 之前调用
        require(block.timestamp < TIMESTAMP_OF_20181101000001);
        // 仅允许 _addr 已在白名单内时使用
        require(hasRole(_addr, ROLE_PARTNERWHITELIST));

        removeRole(_addr, ROLE_PARTNERWHITELIST);
        partnersAmountLimit[_addr] = 0;
        // 把给定地址从 partner 数组中删除
        uint256 partnerIndex = partnersIndex[_addr];
        uint256 lastPartnerIndex = partners.length.sub(1);
        address lastPartner = partners[lastPartnerIndex];
        partners[partnerIndex] = lastPartner;
        delete partners[lastPartnerIndex];
        partners.length--;
        partnersIndex[_addr] = 0;
        partnersIndex[lastPartner] = partnerIndex;
    }

    /**
     * @dev 添加私募代理人地址到白名单并设置其限额
     * @param _addr 私募代理人地址
     * @param _amount 私募代理人的转账限额
     */
    function addAddressToPrivateWhiteList(address _addr, uint256 _amount)
        public onlyOwner
    {
        // 仅允许在 2018/10/02 00:00:01 之前调用
        require(block.timestamp < TIMESTAMP_OF_20181002000001);
        // 检查 _addr 是否已在白名单内以保证 approve 函数仅会被调用一次；
        // 后续如还需要更改授权额度，
        // 请直接使用安全的 increaseApproval 和 decreaseApproval 函数
        require(!hasRole(_addr, ROLE_PRIVATESALEWHITELIST));

        addRole(_addr, ROLE_PRIVATESALEWHITELIST);
        approve(_addr, _amount);
        // 把给定地址加入私募代理人数组
        privateSaleAgentsIndex[_addr] = privateSaleAgents.length;
        privateSaleAgents.push(_addr);
    }

    /**
     * @dev 将私募代理人地址从白名单移除
     * @param _addr 私募代理人地址
     */
    function removeAddressFromPrivateWhiteList(address _addr)
        public onlyOwner
    {
        // 仅允许在 2018/10/02 00:00:01 之前调用
        require(block.timestamp < TIMESTAMP_OF_20181002000001);
        // 仅允许 _addr 已在白名单内时使用
        require(hasRole(_addr, ROLE_PRIVATESALEWHITELIST));

        removeRole(_addr, ROLE_PRIVATESALEWHITELIST);
        approve(_addr, 0);
        // 把给定地址从私募代理人数组中删除
        uint256 agentIndex = privateSaleAgentsIndex[_addr];
        uint256 lastAgentIndex = privateSaleAgents.length.sub(1);
        address lastAgent = privateSaleAgents[lastAgentIndex];
        privateSaleAgents[agentIndex] = lastAgent;
        delete privateSaleAgents[lastAgentIndex];
        privateSaleAgents.length--;
        privateSaleAgentsIndex[_addr] = 0;
        privateSaleAgentsIndex[lastAgent] = agentIndex;
    }

    /**
     * @dev 允许接受转账的 fallback 函数
     */
    function() external payable {
        privateSale(msg.sender);
    }

    /**
     * @dev 私募处理
     * @param _beneficiary 收取 token 地址
     */
    function privateSale(address _beneficiary)
        public payable onlyRole(ROLE_PRIVATESALEWHITELIST)
    {
        // 仅允许 EOA 购买
        require(msg.sender == tx.origin);
        require(!msg.sender.isContract());
        // 仅允许在 2018/10/02 00:00:01 之前购买
        require(block.timestamp < TIMESTAMP_OF_20181002000001);

        uint256 purchaseValue = msg.value.mul(EXCHANGE_RATE_IN_PRIVATE_SALE);
        transferFrom(owner, _beneficiary, purchaseValue);
    }

    /**
     * @dev 人工私募处理
     * @param _addr 收取 token 地址
     * @param _amount 转账 token 数量
     */
    function withdrawPrivateCoinByMan(address _addr, uint256 _amount)
        public onlyRole(ROLE_PRIVATESALEWHITELIST)
    {
        // 仅允许在 2018/10/02 00:00:01 之前购买
        require(block.timestamp < TIMESTAMP_OF_20181002000001);
        // 仅允许 EOA 获得转账
        require(!_addr.isContract());

        transferFrom(owner, _addr, _amount);
    }

    /**
     * @dev 私募余额提取
     * @param _amount 提取 token 数量
     */
    function withdrawRemainPrivateCoin(uint256 _amount) public onlyOwner {
        // 仅允许在 2018/10/01 00:00:01 之后提取
        require(block.timestamp >= TIMESTAMP_OF_20181001000001);
        require(transfer(ownerWallet, _amount));
        emit TransferLog(owner, ownerWallet, bytes32("withdrawRemainPrivateCoin"), _amount);
    }

    /**
     * @dev 私募转账处理(从 Owner 持有的余额中转出)
     * @param _to 转入地址
     * @param _amount 转账数量
     */
    function _privateSaleTransferFromOwner(address _to, uint256 _amount)
        private returns (bool)
    {
        uint256 newTotalPrivateSaleAmount = totalPrivateSalesReleased.add(_amount);
        // 检查私募转账总额是否超限
        require(newTotalPrivateSaleAmount <= PRIVATE_SALE_AMOUNT.mul(10 ** uint256(decimals)));

        bool result = super.transferFrom(owner, _to, _amount);
        privateSalesReleased[msg.sender] = privateSalesReleased[msg.sender].add(_amount);
        totalPrivateSalesReleased = newTotalPrivateSaleAmount;
        return result;
    }

    /**
     * @dev 合约余额提取
     */
    function withdrawFunds() public onlyOwner {
        ownerWallet.transfer(address(this).balance);
    }

    /**
     * @dev 获取所有 Partner 地址
     * @return 所有 Partner 地址
     */
    function getPartnerAddresses() public onlyOwner view returns (address[]) {
        return partners;
    }

    /**
     * @dev 获取所有私募代理人地址
     * @return 所有私募代理人地址
     */
    function getPrivateSaleAgentAddresses() public onlyOwner view returns (address[]) {
        return privateSaleAgents;
    }

    /**
     * @dev 获得私募代理人地址已转出（售出）的 token 数量
     * @param _addr 私募代理人地址
     * @return 私募代理人地址的已转出的 token 数量
     */
    function privateSaleReleased(address _addr) public view returns (uint256) {
        return privateSalesReleased[_addr];
    }

    /**
     * @dev 获得 Partner 地址的提取限额
     * @param _addr Partner 的地址
     * @return Partner 地址的提取限额
     */
    function partnerAmountLimit(address _addr) public view returns (uint256) {
        return partnersAmountLimit[_addr];
    }

    /**
     * @dev 获得 Partner 地址的已提取 token 数量
     * @param _addr Partner 的地址
     * @return Partner 地址的已提取 token 数量
     */
    function partnerWithdrawed(address _addr) public view returns (uint256) {
        return partnersWithdrawed[_addr];
    }

    /**
     * @dev 给 Partner 地址分发 token
     * @param _addr Partner 的地址
     * @param _amount 分发的 token 数量
     */
    function withdrawToPartner(address _addr, uint256 _amount)
        public onlyOwner
    {
        require(hasRole(_addr, ROLE_PARTNERWHITELIST));
        // 仅允许在 2018/11/01 00:00:01 之前分发
        require(block.timestamp < TIMESTAMP_OF_20181101000001);

        uint256 newTotalReleased = totalPartnersReleased.add(_amount);
        require(newTotalReleased <= FOOTSTONE_ROUND_AMOUNT.mul(10 ** uint256(decimals)));

        uint256 newPartnerAmount = balanceOf(_addr).add(_amount);
        require(newPartnerAmount <= partnersAmountLimit[_addr]);

        totalPartnersReleased = newTotalReleased;
        transfer(_addr, _amount);
        emit TransferLog(owner, _addr, bytes32("withdrawToPartner"), _amount);
    }

    /**
     * @dev 计算 Partner 地址的可提取 token 数量，返回其与 _value 之间较小的那个值
     * @param _addr Partner 的地址
     * @param _value 想要提取的 token 数量
     * @return Partner 地址当前可提取的 token 数量，
     *         如果 _value 较小，则返回 _value 的数值
     */
    function _permittedPartnerTranferValue(address _addr, uint256 _value)
        private view returns (uint256)
    {
        uint256 limit = balanceOf(_addr);
        uint256 withdrawed = partnersWithdrawed[_addr];
        uint256 total = withdrawed.add(limit);
        uint256 time = block.timestamp;

        require(limit > 0);

        if (time >= TIMESTAMP_OF_20191101000001) {
            // 2019/11/01 00:00:01 之后可提取 100%
            limit = total;
        } else if (time >= TIMESTAMP_OF_20190801000001) {
            // 2019/08/01 00:00:01 之后最多提取 75%
            limit = total.mul(75).div(100);
        } else if (time >= TIMESTAMP_OF_20190501000001) {
            // 2019/05/01 00:00:01 之后最多提取 50%
            limit = total.div(2);
        } else if (time >= TIMESTAMP_OF_20190201000001) {
            // 2019/02/01 00:00:01 之后最多提取 25%
            limit = total.mul(25).div(100);
        } else {
            // 2019/02/01 00:00:01 之前不可提取
            limit = 0;
        }
        if (withdrawed >= limit) {
            limit = 0;
        } else {
            limit = limit.sub(withdrawed);
        }
        if (_value < limit) {
            limit = _value;
        }
        return limit;
    }

    /**
     * @dev 重写基础合约的 transferFrom 函数
     */
    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    )
        public
        returns (bool)
    {
        bool result;
        address sender = msg.sender;

        if (_from == owner) {
            if (hasRole(sender, ROLE_PRIVATESALEWHITELIST)) {
                // 仅允许在 2018/10/02 00:00:01 之前购买
                require(block.timestamp < TIMESTAMP_OF_20181002000001);

                result = _privateSaleTransferFromOwner(_to, _value);
            } else {
                revert();
            }
        } else {
            result = super.transferFrom(_from, _to, _value);
        }
        return result;
    }

    /**
     * @dev 通用额度提取
     * @param _amount 提取 token 数量
     */
    function withdrawCommonCoin(uint256 _amount) public onlyOwner {
        // 仅允许在 2018/11/01 00:00:01 之后提取
        require(block.timestamp >= TIMESTAMP_OF_20181101000001);
        require(transfer(ownerWallet, _amount));
        emit TransferLog(owner, ownerWallet, bytes32("withdrawCommonCoin"), _amount);
        totalCommonReleased = totalCommonReleased.add(_amount);
    }

    /**
     * @dev 团队预留额度1提取
     * @param _amount 提取 token 数量
     */
    function withdrawToTeamStep1(uint256 _amount) public onlyOwner {
        // 仅允许在 2019/02/01 00:00:01 之后提取
        require(block.timestamp >= TIMESTAMP_OF_20190201000001);
        require(transfer(ownerWallet, _amount));
        emit TransferLog(owner, ownerWallet, bytes32("withdrawToTeamStep1"), _amount);
        totalTeamReleased1 = totalTeamReleased1.add(_amount);
    }

    /**
     * @dev 团队预留额度2提取
     * @param _amount 提取 token 数量
     */
    function withdrawToTeamStep2(uint256 _amount) public onlyOwner {
        // 仅允许在 2019/11/01 00:00:01 之后提取
        require(block.timestamp >= TIMESTAMP_OF_20191101000001);
        require(transfer(ownerWallet, _amount));
        emit TransferLog(owner, ownerWallet, bytes32("withdrawToTeamStep2"), _amount);
        totalTeamReleased2 = totalTeamReleased2.add(_amount);
    }

    /**
     * @dev 团队预留额度3提取
     * @param _amount 提取 token 数量
     */
    function withdrawToTeamStep3(uint256 _amount) public onlyOwner {
        // 仅允许在 2020/11/01 00:00:01 之后提取
        require(block.timestamp >= TIMESTAMP_OF_20201101000001);
        require(transfer(ownerWallet, _amount));
        emit TransferLog(owner, ownerWallet, bytes32("withdrawToTeamStep3"), _amount);
        totalTeamReleased3 = totalTeamReleased3.add(_amount);
    }

    /**
     * @dev 团队预留额度4提取
     * @param _amount 提取 token 数量
     */
    function withdrawToTeamStep4(uint256 _amount) public onlyOwner {
        // 仅允许在 2021/11/01 00:00:01 之后提取
        require(block.timestamp >= TIMESTAMP_OF_20211101000001);
        require(transfer(ownerWallet, _amount));
        emit TransferLog(owner, ownerWallet, bytes32("withdrawToTeamStep4"), _amount);
        totalTeamReleased4 = totalTeamReleased4.add(_amount);
    }

    /**
     * @dev 重写基础合约的 transfer 函数
     */
    function transfer(address _to, uint256 _value) public returns (bool) {
        bool result;
        uint256 limit;

        if (msg.sender == owner) {
            limit = _ownerReleaseLimit();
            uint256 newTotalOwnerReleased = totalOwnerReleased.add(_value);
            require(newTotalOwnerReleased <= limit);
            result = super.transfer(_to, _value);
            totalOwnerReleased = newTotalOwnerReleased;
        } else if (hasRole(msg.sender, ROLE_PARTNERWHITELIST)) {
            limit = _permittedPartnerTranferValue(msg.sender, _value);
            if (limit > 0) {
                result = super.transfer(_to, limit);
                partnersWithdrawed[msg.sender] = partnersWithdrawed[msg.sender].add(limit);
            } else {
                revert();
            }
        } else {
            result = super.transfer(_to, _value);
        }
        return result;
    }

    /**
     * @dev 计算 Owner 的转账额度
     * @return Owner 的当前转账额度
     */
   function _ownerReleaseLimit() private view returns (uint256) {
        uint256 time = block.timestamp;
        uint256 limit;
        uint256 amount;

        // 基石轮额度作为默认限额
        limit = FOOTSTONE_ROUND_AMOUNT.mul(10 ** uint256(decimals));
        if (time >= TIMESTAMP_OF_20181001000001) {
            // 2018/10/1 之后，最大限额需要增加私募剩余额度
            amount = PRIVATE_SALE_AMOUNT.mul(10 ** uint256(decimals));
            if (totalPrivateSalesReleased < amount) {
                limit = limit.add(amount).sub(totalPrivateSalesReleased);
            }
        }
        if (time >= TIMESTAMP_OF_20181101000001) {
            // 2018/11/1 之后，最大限额需要增加通用提取额度中减去锁仓额度以外的额度
            limit = limit.add(COMMON_PURPOSE_AMOUNT.sub(OWNER_LOCKED_IN_COMMON).mul(10 ** uint256(decimals)));
        }
        if (time >= TIMESTAMP_OF_20190201000001) {
            // 2019/2/1 之后，最大限额需要增加团队预留额度1
            limit = limit.add(TEAM_RESERVED_AMOUNT1.mul(10 ** uint256(decimals)));
        }
        if (time >= TIMESTAMP_OF_20190501000001) {
            // 2019/5/1 之后，最大限额需要增加通用额度中的锁仓额度
            limit = limit.add(OWNER_LOCKED_IN_COMMON.mul(10 ** uint256(decimals)));
        }
        if (time >= TIMESTAMP_OF_20191101000001) {
            // 2019/11/1 之后，最大限额需要增加团队预留额度2
            limit = limit.add(TEAM_RESERVED_AMOUNT2.mul(10 ** uint256(decimals)));
        }
        if (time >= TIMESTAMP_OF_20201101000001) {
            // 2020/11/1 之后，最大限额需要增加团队预留额度3
            limit = limit.add(TEAM_RESERVED_AMOUNT3.mul(10 ** uint256(decimals)));
        }
        if (time >= TIMESTAMP_OF_20211101000001) {
            // 2021/11/1 之后，最大限额需要增加团队预留额度4
            limit = limit.add(TEAM_RESERVED_AMOUNT4.mul(10 ** uint256(decimals)));
        }
        return limit;
    }
}