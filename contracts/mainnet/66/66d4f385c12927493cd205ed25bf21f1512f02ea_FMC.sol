pragma solidity ^0.4.25;
// produced by the Solididy File Flattener (c) David Appleton 2018
// contact : <a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="086c697e6d48696367656a69266b6765">[email&#160;protected]</a>
// released under Apache 2.0 licence
// input  D:\Project\java\FanMei\src\main\solidity\FMC.sol
// flattened :  Wednesday, 09-Jan-19 14:12:44 UTC
library SafeMath {
  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
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
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
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
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;
  mapping(address => uint256) balances;
  uint256 totalSupply_;
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
    require(_to != address(0));
    require(_value <= balances[msg.sender]);
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
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);
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
    uint256 oldValue = allowed[msg.sender][_spender];
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
contract FMC is StandardToken, Ownable {
    using SafeMath for uint256;
    string public constant name = "Fan Mei Chain (FMC)";
    string public constant symbol = "FMC";
    uint8 public constant decimals = 18;
    //总配额2亿
    uint256 constant INITIAL_SUPPLY = 200000000 * (10 ** uint256(decimals));
    //设置代币官网短URL(32字节以内)，供管理平台自动查询
    string public website = "www.fanmeichain.com";
    //设置代币icon短URL(32字节以内)，供管理平台自动查询
    string public icon = "/icon/fmc.png";
    //冻结账户
    address public frozenAddress;
    //锁仓信息
    mapping(address=>Info) internal fellowInfo;
    // fellow info
    struct Info{
        uint256[] defrozenDates;                    //解冻日期
        mapping(uint256=>uint256) frozenValues;     //冻结金额
        uint256 totalFrozenValue;                   //全部冻结资产总额
    }
    // 事件定义
    event Frozen(address user, uint256 value, uint256 defrozenDate, uint256 totalFrozenValue);
    event Defrozen(address user, uint256 value, uint256 defrozenDate, uint256 totalFrozenValue);
    // Constructor that gives msg.sender all of existing tokens.
    constructor(address _frozenAddress) public {
        require(_frozenAddress != address(0) && _frozenAddress != msg.sender);
        frozenAddress = _frozenAddress;
        totalSupply_ = INITIAL_SUPPLY;
        balances[msg.sender] = INITIAL_SUPPLY;
        emit Transfer(0x0, msg.sender, INITIAL_SUPPLY);
    }
    /**
   * @dev Transfer token for a specified address
   * @param _to The address to transfer to.
   * @param _value The amount to be transferred.
   */
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);
        //normal transfer
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        if(_to == frozenAddress){
            //defrozing
            Info storage _info = fellowInfo[msg.sender];
            if(_info.totalFrozenValue > 0){
                for(uint i=0; i< _info.defrozenDates.length; i++){
                    uint256 _date0 = _info.defrozenDates[i];
                    if(_info.frozenValues[_date0] > 0 && now >= _date0){
                        //defrozen...
                        uint256 _defrozenValue = _info.frozenValues[_date0];
                        require(balances[frozenAddress] >= _defrozenValue);
                        balances[frozenAddress] = balances[frozenAddress].sub(_defrozenValue);
                        balances[msg.sender] = balances[msg.sender].add(_defrozenValue);
                        _info.totalFrozenValue = _info.totalFrozenValue.sub(_defrozenValue);
                        _info.frozenValues[_date0] = 0;
                        emit Transfer(frozenAddress, msg.sender, _defrozenValue);
                        emit Defrozen(msg.sender, _defrozenValue, _date0, _info.totalFrozenValue);
                    }
                }
            }
        }
        return true;
    }
    // issue in batch with forzen
    function issue(address[] payees, uint256[] values, uint16[] deferDays) public onlyOwner returns(bool) {
        require(payees.length > 0 && payees.length == values.length);
        uint256 _now0 = _getNow0();
        for (uint i = 0; i<payees.length; i++) {
            require(balances[owner] >= values[i], "Issuer balance is insufficient.");
            //地址为空或者发行额度为零
            if (payees[i] == address(0) || values[i] == uint256(0)) {
                continue;
            }
            balances[owner] = balances[owner].sub(values[i]);
            balances[payees[i]] = balances[payees[i]].add(values[i]);
            emit Transfer(owner, payees[i], values[i]);
            uint256 _date0 = _now0.add(deferDays[i]*24*3600);
            //判断是否需要冻结
            if(_date0 > _now0){
                //frozen balance
                Info storage _info = fellowInfo[payees[i]];
                uint256 _fValue = _info.frozenValues[_date0];
                if(_fValue == 0){
                    //_date0 doesn&#39;t exist in defrozenDates
                    _info.defrozenDates.push(_date0);
                }
                //冻结总量增加_value
                _info.totalFrozenValue = _info.totalFrozenValue.add(values[i]);
                _info.frozenValues[_date0] = _info.frozenValues[_date0].add(values[i]);

                balances[payees[i]] = balances[payees[i]].sub(values[i]);
                balances[frozenAddress] = balances[frozenAddress].add(values[i]);
                emit Transfer(payees[i], frozenAddress, values[i]);
                emit Frozen(payees[i], values[i], _date0, _info.totalFrozenValue);
            }
        }
        return true;
    }
    // airdrop in with same value and deferDays
    function airdrop(address[] payees, uint256 value, uint16 deferDays) public onlyOwner returns(bool) {
        require(payees.length > 0 && value > 0);
        uint256 _amount = value.mul(payees.length);
        require(balances[owner] > _amount);
        uint256 _now0 = _getNow0();
        uint256 _date0 = _now0.add(deferDays*24*3600);
        for (uint i = 0; i<payees.length; i++) {
            require(balances[owner] >= value, "Issuer balance is insufficient.");
            //地址为空或者发行额度为零
            if (payees[i] == address(0)) {
                _amount = _amount.sub(value);
                continue;
            }
            //circulating
            balances[payees[i]] = balances[payees[i]].add(value);
            emit Transfer(owner, payees[i], value);
            //判断是否需要冻结
            if(_date0 > _now0){
                //frozen balance
                Info storage _info = fellowInfo[payees[i]];
                uint256 _fValue = _info.frozenValues[_date0];
                if(_fValue == 0){
                    //_date0 doesn&#39;t exist in defrozenDates
                    _info.defrozenDates.push(_date0);
                }
                //冻结总量增加_value
                _info.totalFrozenValue = _info.totalFrozenValue.add(value);
                _info.frozenValues[_date0] = _info.frozenValues[_date0].add(value);
                balances[payees[i]] = balances[payees[i]].sub(value);
                balances[frozenAddress] = balances[frozenAddress].add(value);
                emit Transfer(payees[i], frozenAddress, value);
                emit Frozen(payees[i], value, _date0, _info.totalFrozenValue);
            }
        }
        balances[owner] = balances[owner].sub(_amount);
        return true;
    }
    // update frozen address
    function updateFrozenAddress(address newFrozenAddress) public onlyOwner returns(bool){
        //要求：
        //1. 新地址不能为空
        //2. 新地址不能为owner
        //3. 新地址不能与旧地址相同
        require(newFrozenAddress != address(0) && newFrozenAddress != owner && newFrozenAddress != frozenAddress);
        //要求：新地址账本为零
        require(balances[newFrozenAddress] == 0);
        //转移冻结账本
        balances[newFrozenAddress] = balances[frozenAddress];
        balances[frozenAddress] = 0;
        emit Transfer(frozenAddress, newFrozenAddress, balances[newFrozenAddress]);
        frozenAddress = newFrozenAddress;
        return true;
    }
    //平台解冻指定资产
    function defrozen(address fellow) public onlyOwner returns(bool){
        require(fellow != address(0));
        Info storage _info = fellowInfo[fellow];
        require(_info.totalFrozenValue > 0);
        for(uint i = 0; i< _info.defrozenDates.length; i++){
            uint256 _date0 = _info.defrozenDates[i];
            if(_info.frozenValues[_date0] > 0 && now >= _date0){
                //defrozen...
                uint256 _defrozenValue = _info.frozenValues[_date0];
                require(balances[frozenAddress] >= _defrozenValue);
                balances[frozenAddress] = balances[frozenAddress].sub(_defrozenValue);
                balances[fellow] = balances[fellow].add(_defrozenValue);
                _info.totalFrozenValue = _info.totalFrozenValue.sub(_defrozenValue);
                _info.frozenValues[_date0] = 0;
                emit Transfer(frozenAddress, fellow, _defrozenValue);
                emit Defrozen(fellow, _defrozenValue, _date0, _info.totalFrozenValue);
            }
        }
        return true;
    }
    // check own assets include: balance, totalForzenValue, defrozenDates, defrozenValues
    function getOwnAssets() public view returns(uint256, uint256, uint256[], uint256[]){
        return getAssets(msg.sender);
    }
    // check own assets include: balance, totalForzenValue, defrozenDates, defrozenValues
    function getAssets(address fellow) public view returns(uint256, uint256, uint256[], uint256[]){
        uint256 _value = balances[fellow];
        Info storage _info = fellowInfo[fellow];
        uint256 _totalFrozenValue = _info.totalFrozenValue;
        uint256 _size = _info.defrozenDates.length;
        uint256[] memory _values = new uint256[](_size);
        for(uint i = 0; i < _size; i++){
            _values[i] = _info.frozenValues[_info.defrozenDates[i]];
        }
        return (_value, _totalFrozenValue, _info.defrozenDates, _values);
    }
    // 设置token官网和icon信息
    function setWebInfo(string _website, string _icon) public onlyOwner returns(bool){
        website = _website;
        icon = _icon;
        return true;
    }
    //返回当前区块链时间: 年月日时
    function getNow() public view returns(uint256){
        return now;
    }
    // @dev An internal pure function to calculate date in XX:00:00
    function _calcDate0(uint256 _timestamp) internal pure returns(uint256){
        return _timestamp.sub(_timestamp % (60*24));
    }
    // 获取当前日期零点时间戳
    function _getNow0() internal view returns(uint256){
        return _calcDate0(now);
    }
}