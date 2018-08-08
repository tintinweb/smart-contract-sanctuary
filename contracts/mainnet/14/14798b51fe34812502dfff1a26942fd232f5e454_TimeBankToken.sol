pragma solidity ^0.4.21;

contract EIP20Interface {
    function name() public view returns (string);
    
    function symbol() public view returns (string);
    
    function decimals() public view returns (uint8);
    
    function totalSupply() public view returns (uint256);

    /// @param _owner The address from which the balance will be retrieved
    /// @return The balance
    function balanceOf(address _owner) public view returns (uint256 balance);

    /// @notice send `_value` token to `_to` from `msg.sender`
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transfer(address _to, uint256 _value) public returns (bool success);

    /// @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
    /// @param _from The address of the sender
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

    /// @notice `msg.sender` approves `_spender` to spend `_value` tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @param _value The amount of tokens to be approved for transfer
    /// @return Whether the approval was successful or not
    function approve(address _spender, uint256 _value) public returns (bool success);

    /// @param _owner The address of the account owning tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @return Amount of remaining tokens allowed to spent
    function allowance(address _owner, address _spender) public view returns (uint256 remaining);

    // solhint-disable-next-line no-simple-event-func-name
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract EIP20 is EIP20Interface {

    uint256 constant private MAX_UINT256 = 2**256 - 1;
    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) public allowed;
    /*
    NOTE:
    The following variables are OPTIONAL vanities. One does not have to include them.
    They allow one to customise the token contract & in no way influences the core functionality.
    Some wallets/interfaces might not even bother to look at this information.
    */
    string public tokenName;                   //fancy name: eg Simon Bucks
    uint8 public tokenDecimals;                //How many decimals to show.
    string public tokenSymbol;                 //An identifier: eg SBX
    uint256 public tokenTotalSupply;

    constructor(
        uint256 _initialAmount,
        string _tokenName,
        uint8 _decimalUnits,
        string _tokenSymbol
    ) public {
        balances[msg.sender] = _initialAmount;               // Give the creator all initial tokens
        tokenTotalSupply = _initialAmount;                        // Update total supply
        tokenName = _tokenName;                                   // Set the name for display purposes
        tokenDecimals = _decimalUnits;                            // Amount of decimals for display purposes
        tokenSymbol = _tokenSymbol;                               // Set the symbol for display purposes
    }
    
    function name() public view returns (string) {
        return tokenName;
    }
    
    function symbol() public view returns (string) {
        return tokenSymbol;
    }
    
    function decimals() public view returns (uint8) {
        return tokenDecimals;
    }
    
    function totalSupply() public view returns (uint256) {
        return tokenTotalSupply;
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balances[msg.sender] >= _value);
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value); //solhint-disable-line indent, no-unused-vars
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        uint256 allowance = allowed[_from][msg.sender];
        require(balances[_from] >= _value && allowance >= _value);
        balances[_to] += _value;
        balances[_from] -= _value;
        if (allowance < MAX_UINT256) {
            allowed[_from][msg.sender] -= _value;
        }
        emit Transfer(_from, _to, _value); //solhint-disable-line indent, no-unused-vars
        return true;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value); //solhint-disable-line indent, no-unused-vars
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
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

contract TimeBankToken is EIP20 {
  using SafeMath for uint;

  struct Vesting {
    uint256 startTime; // vesting start time
    uint256 initReleaseAmount;
    uint256 amount;
    uint256 interval; // release N% of amount each interval.
    uint256 periods; // count of periods
    uint256 withdrawed; // already used amount of released part
  }

  mapping (address => Vesting[]) vestings;
  
  address[] managerList;
  mapping (address => bool) managers;
  mapping (bytes32 => mapping (address => bool)) confirms;
  
  /*
  at least <threshold> confirmations
  */
  uint majorityThreshold;
  uint managementThreshold;

  address coinbase;
  address master;
  bool public paused;

  function checkAddress(address _addr) internal pure returns (bool) {
    return _addr != address(0);
  }

  // 1 with 28 zeros
  constructor(address _master, address[] _managers, uint _majorityThreshold, uint _managementThreshold) EIP20(10000000000000000000000000000, "Time Bank Token", 18, "TBT") public {
    require(checkAddress(_master));
    require(_managers.length >= _majorityThreshold);
    require(_managers.length >= _managementThreshold);
    
    paused = false;
    master = _master;
    coinbase = msg.sender;
    majorityThreshold = _majorityThreshold;
    managementThreshold = _managementThreshold;

    for (uint i=0; i<_managers.length; i++) {
      require(checkAddress(_managers[i]));
      managers[_managers[i]] = true;
    }
    managerList = _managers;

    // initial batch operations
    // internalPresaleVesting(0x0095F9DffeE386B650230eD3eC28891c1053aBE0, 10000, 60, 120, 240);
    // internalPresaleVesting(0x00D4fC2CC18B96c44D9755afB6D4e6804cF827ee, 20000, 60, 120, 240);
    // internalPresale(0x0092E41D42E834705fd07c9136Fd0b1028226bE3, 30000);
  }

  function pause() public isMaster isNotPaused {
    require(isEnoughConfirmed(msg.data, 1));
    paused = true;
  }

  function resume() public isMaster isPaused {
    require(isEnoughConfirmed(msg.data, 1));
    paused = false;
  }

  modifier isPaused {
    require(paused == true);
    _;
  }

  modifier isNotPaused {
    require(paused == false);
    _;
  }

  modifier isManager {
    require(managers[msg.sender]);
    _;
  }

  modifier isMaster {
    require(msg.sender == master);
    _;
  }

  modifier isNotCoinbase {
    require(msg.sender != coinbase);
    _;
  }

  function managersCount() public view returns (uint) {
    return managerList.length;
  }

  function isAddressManager(address _to) public view returns (bool) {
    return managers[_to];
  }

  function getMajorityThreshold() public view  returns (uint) {
    return majorityThreshold;
  }

  event MajorityThresholdChanged(uint oldThreshold, uint newThreshold);
  event ReplaceManager(address oldAddr, address newAddr);
  event RemoveManager(address manager);
  event AddManager(address manager);

  function setMajorityThreshold(uint _threshold) public isMaster isNotPaused {
    require(_threshold > 0);
    require(isEnoughConfirmed(msg.data, managementThreshold));
    uint oldThreshold = majorityThreshold;
    majorityThreshold = _threshold;
    removeConfirm(msg.data);
    emit MajorityThresholdChanged(oldThreshold, majorityThreshold);
  }

  function replaceManager(address _old, address _new) public isMaster isNotPaused {
    require(checkAddress(_old));
    require(checkAddress(_new));
    require(isEnoughConfirmed(msg.data, managementThreshold));
    internalRemoveManager(_old);
    internalAddManager(_new);
    rebuildManagerList();
    removeConfirm(msg.data);
    emit ReplaceManager(_old, _new);
  }

  function removeManager(address _manager) public isMaster isNotPaused {
    require(checkAddress(_manager));
    require(isEnoughConfirmed(msg.data, managementThreshold));
    require(managerList.length > managementThreshold);
    internalRemoveManager(_manager);
    rebuildManagerList();
    removeConfirm(msg.data);
    emit RemoveManager(_manager);
  }

  function internalRemoveManager(address _manager) internal {
    require(checkAddress(_manager));
    managers[_manager] = false;
  }

  function addManager(address _manager) public isMaster isNotPaused {
    require(checkAddress(_manager));
    require(isEnoughConfirmed(msg.data, managementThreshold));
    internalAddManager(_manager);
    rebuildManagerList();
    removeConfirm(msg.data);
    emit AddManager(_manager);
  }

  function internalAddManager(address _manager) internal {
    require(checkAddress(_manager));
    managers[_manager] = true;
    managerList.push(_manager);
  }

  mapping (address => bool) checked;

  function rebuildManagerList() internal {
    address[] memory res = new address[](managerList.length);
    for (uint k=0; k<managerList.length; k++) {
      checked[managerList[k]] = false;
    }
    uint j=0;
    for (uint i=0; i<managerList.length; i++) {
      address manager = managerList[i];
      if (managers[manager] && checked[manager] == false) {
        res[j] = manager;
        checked[manager] = true;
        j++;
      }
    }
    managerList = res;
    managerList.length = j;
  }

  function checkData(bytes data) internal pure returns (bool) {
    return data.length != 0;
  }

  event Confirm(address manager, bytes data);
  event Revoke(address manager, bytes data);

  /*
  manager use this function to confirm a operation
  confirm will not be call inside other functions, so it can be external to save some gas
  @param {bytes} data is the transaction&#39;s raw input
  */
  function confirm(bytes data) external isManager {
    checkData(data);
    bytes32 op = keccak256(data);
    if (confirms[op][msg.sender] == false) {
      confirms[op][msg.sender] = true;
    }
    emit Confirm(msg.sender, data);
  }

  /*
  manager use this function to revoke a confirm of the operation
  revoke will not be call inside other functions, so it can be external to save some gas
  @param {bytes} data is the transaction&#39;s raw input
  */
  function revoke(bytes data) external isManager {
    checkData(data);
    bytes32 op = keccak256(data);
    if (confirms[op][msg.sender] == true) {
      confirms[op][msg.sender] = false;
    }
    emit Revoke(msg.sender, data);
  }

  /*
  check a operation is confirmed or not
  */
  function isConfirmed(bytes data) public view isManager returns (bool) {
    bytes32 op = keccak256(data);
    return confirms[op][msg.sender];
  }

  function isConfirmedBy(bytes data, address manager) public view returns (bool) {
    bytes32 op = keccak256(data);
    return confirms[op][manager];
  } 

  function isMajorityConfirmed(bytes data) public view returns (bool) {
    return isEnoughConfirmed(data, majorityThreshold);
  }

  function isEnoughConfirmed(bytes data, uint count) internal view returns (bool) {
    bytes32 op = keccak256(data);
    uint confirmsCount = 0;
    for (uint i=0; i<managerList.length; i++) {
      if (confirms[op][managerList[i]] == true) {
        confirmsCount = confirmsCount.add(1);
      }
    }
    return confirmsCount >= count;
  }

  /*
  once the operation is executed, the confirm of the operation should be removed
  */
  function removeConfirm(bytes data) internal {
    bytes32 op = keccak256(data);
    for (uint i=0; i<managerList.length; i++) {
      confirms[op][managerList[i]] = false;
    }
  }

  /*
  sale coin with time locking
  only the manager can call this function
  and this operation should be confirmed
  */
  function presaleVesting(address _to, uint256 _startTime, uint256 _initReleaseAmount, uint256 _amount, uint256 _interval, uint256 _periods) public isManager isNotPaused {
    checkAddress(_to);
    require(isMajorityConfirmed(msg.data));
    internalPresaleVesting(_to, _startTime, _initReleaseAmount, _amount, _interval, _periods);
    removeConfirm(msg.data);
  }

  function batchPresaleVesting(address[] _to, uint256[] _startTime, uint256[] _initReleaseAmount, uint256[] _amount, uint256[] _interval, uint256[] _periods) public isManager isNotPaused {
    require(isMajorityConfirmed(msg.data));
    for (uint i=0; i<_to.length; i++) {
      internalPresaleVesting(_to[i], _startTime[i], _initReleaseAmount[i], _amount[i], _interval[i], _periods[i]);
    }
    removeConfirm(msg.data);
  }

  function internalPresaleVesting(address _to, uint256 _startTime, uint256 _initReleaseAmount, uint256 _amount, uint256 _interval, uint256 _periods) internal {
    require(balances[coinbase] >= _amount);
    require(_initReleaseAmount <= _amount);
    require(checkAddress(_to));
    vestings[_to].push(Vesting(
      _startTime, _initReleaseAmount, _amount, _interval, _periods, 0
    ));
    balances[coinbase] = balances[coinbase].sub(_amount);
    emit PresaleVesting(_to, _startTime, _amount, _interval, _periods);
  }

  /*
  sale coin without time locking
  only the manager can call this function
  and this operation should be confirmed
  */
  function presale(address _to, uint256 _value) public isManager isNotPaused {
    require(isMajorityConfirmed(msg.data));
    internalPresale(_to, _value);
    removeConfirm(msg.data);
  }

  function batchPresale(address[] _to, uint256[] _amount) public isManager isNotPaused {
    require(isMajorityConfirmed(msg.data));
    for (uint i=0; i<_to.length; i++) {
      internalPresale(_to[i], _amount[i]);
    }
    removeConfirm(msg.data);
  }

  function internalPresale(address _to, uint256 _value) internal {
    require(balances[coinbase] >= _value);
    require(checkAddress(_to));
    balances[_to] = balances[_to].add(_value);
    balances[coinbase] = balances[coinbase].sub(_value);
    emit Presale(_to, _value);
  }

  /*
  events
  */
  event Presale(address indexed to, uint256 value);
  event PresaleVesting(address indexed to, uint256 startTime, uint256 amount, uint256 interval, uint256 periods);

  /*
  math function used to calculate vesting curve
  */
  function vestingFunc(uint256 _currentTime, uint256 _startTime, uint256 _initReleaseAmount, uint256 _amount, uint256 _interval, uint256 _periods) public pure returns (uint256) {
    if (_currentTime < _startTime) {
      return 0;
    }
    uint256 t = _currentTime.sub(_startTime);
    uint256 end = _periods.mul(_interval);
    if (t >= end) {
      return _amount;
    }
    uint256 i_amount = _amount.sub(_initReleaseAmount).div(_periods);
    uint256 i = t.div(_interval);
    return i_amount.mul(i).add(_initReleaseAmount);
  }

  function queryWithdrawed(uint _idx) public view returns (uint256) {
    return vestings[msg.sender][_idx].withdrawed;
  }

  function queryVestingRemain(uint256 _currentTime, uint _idx) public view returns (uint256) {
    uint256 released = vestingFunc(
      _currentTime,
      vestings[msg.sender][_idx].startTime, vestings[msg.sender][_idx].initReleaseAmount, vestings[msg.sender][_idx].amount,
      vestings[msg.sender][_idx].interval, vestings[msg.sender][_idx].periods
    );
    return released.sub(vestings[msg.sender][_idx].withdrawed);
  }

  /*
  calculate the released amount of vesting coin
  it cannot be view, because this function relays on &#39;now&#39;
  */
  function vestingReleased(uint256 _startTime, uint256 _initReleaseAmount, uint256 _amount, uint256 _interval, uint256 _periods) internal view returns (uint256) {
    return vestingFunc(now, _startTime, _initReleaseAmount, _amount, _interval, _periods);
  }

  /*
  withdraw all released vesting coin to balance
  */
  function withdrawVestings(address _to) internal {
    uint256 sum = 0;
    for (uint i=0; i<vestings[_to].length; i++) {
      if (vestings[_to][i].amount == vestings[_to][i].withdrawed) {
        continue;
      }

      uint256 released = vestingReleased(
        vestings[_to][i].startTime, vestings[_to][i].initReleaseAmount, vestings[_to][i].amount,
        vestings[_to][i].interval, vestings[_to][i].periods
      );
      uint256 remain = released.sub(vestings[_to][i].withdrawed);
      if (remain >= 0) {
        vestings[_to][i].withdrawed = released;
        sum = sum.add(remain);
      }
    }
    balances[_to] = balances[_to].add(sum);
  }

  /*
  sum of all vestings balance (regardless of released or not)
  each vesting is amount - withdrawed
  */
  function vestingsBalance(address _to) public view returns (uint256) {
    uint256 sum = 0;
    for (uint i=0; i<vestings[_to].length; i++) {
      sum = sum.add(vestings[_to][i].amount.sub(vestings[_to][i].withdrawed));
    }
    return sum;
  }

  /*
  sum of all remaining vestings balance (only the released part)
  released - withdrawed
  */
  function vestingsReleasedRemain(address _to) internal view returns (uint256) {
    uint256 sum = 0;
    for (uint i=0; i<vestings[_to].length; i++) {
      uint256 released = vestingReleased(
        vestings[_to][i].startTime, vestings[_to][i].initReleaseAmount, vestings[_to][i].amount,
        vestings[_to][i].interval, vestings[_to][i].periods
      );
      sum = sum.add(released.sub(vestings[_to][i].withdrawed));
    }
    return sum;
  }

  /*
  total balance
  sum of vestings balance (includes not released part) and unlocking coin balance
  */
  function balanceOf(address _to) public view returns (uint256) {
    uint256 vbalance = vestingsBalance(_to);
    return vbalance.add(super.balanceOf(_to));
  }

  /*
  sum of vestings balance and unlocking coin balance
  */
  function vestingsRemainBalance(address _to) internal view returns (uint256) {
    return vestingsReleasedRemain(_to).add(super.balanceOf(_to));
  }

  /*
  transfer <_value> coin from <msg.sender> to <_to> address
  1. check remain balance
  2. withdraw all vesting coin to balance
  3. call original ERC20 transafer function
  */
  function transfer(address _to, uint256 _value) public isNotCoinbase isNotPaused returns (bool) {
    checkAddress(_to);
    uint256 remain = vestingsRemainBalance(msg.sender);
    require(remain >= _value);
    withdrawVestings(msg.sender);
    return super.transfer(_to, _value);
  }

  /*
  transferFrom <_value> coin from <_from> to <_to> address
  1. check remain balance
  2. withdraw all vesting coin to balance
  3. call original ERC20 transafer function
  */
  function transferFrom(address _from, address _to, uint256 _value) public isNotPaused returns (bool) {
    checkAddress(_from);
    checkAddress(_to);
    uint256 remain = vestingsRemainBalance(_from);
    require(remain >= _value);
    withdrawVestings(_from);
    return super.transferFrom(_from, _to, _value);
  }

  /*
  approve <_value> coin from <_from> to <_to> address
  1. check remain balance
  2. withdraw all vesting coin to balance
  3. call original ERC20 transafer function
  */
  function approve(address _spender, uint256 _value) public isNotCoinbase isNotPaused returns (bool) {
    checkAddress(_spender);
    uint256 remain = vestingsRemainBalance(msg.sender);
    require(remain >= _value);
    withdrawVestings(msg.sender);
    return super.approve(_spender, _value);
  }

  function allowance(address _owner, address _spender) public view returns (uint256) {
    return super.allowance(_owner, _spender);
  }
}