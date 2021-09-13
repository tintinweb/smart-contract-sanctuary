/**
 *Submitted for verification at BscScan.com on 2021-09-13
*/

pragma solidity ^0.4.24;

library SafeMath {
    function safeAdd(uint256 a, uint256 b) internal pure returns(uint256)
    {
        uint256 c = a + b;
        require(c >= a);
        return c;
    }
    function safeSub(uint256 a, uint256 b) internal pure returns(uint256)
    {
        require(b <= a);
        return a - b;
    }
    function safeMul(uint256 a, uint256 b) internal pure returns(uint256)
    {
        if (a == 0) {
        return 0;
        }
        uint256 c = a * b;
        require(c / a == b);
        return c;
    }
    function safeDiv(uint256 a, uint256 b) internal pure returns(uint256)
    {
        require(b != 0);
        uint256 c = a / b;
        return c;
    }
}
pragma solidity ^0.4.24;
contract Ownable {
    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
    }
}
pragma solidity ^0.4.24;
contract Pausable is Ownable {
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
   * @dev called by the owner to pause, triggers stopped state
   */
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    emit Pause();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() onlyOwner whenPaused public {
    paused = false;
    emit Unpause();
  }
}

pragma solidity ^0.4.24;
contract EIP20Interface {
    /* This is a slight change to the ERC20 base standard.
    function totalSupply() constant returns (uint256 supply);
    is replaced with:
    uint256 public totalSupply;
    This automatically creates a getter function for the totalSupply.
    This is moved to the base contract since public getter functions are not
    currently recognised as an implementation of the matching abstract
    function by the compiler.
    */
    /// total amount of tokens
    uint256 public totalSupply;

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
pragma solidity ^0.4.24;
contract LockInterface {
     function putDonateReward(address _addr, uint256 _value) public returns (bool _result);
     function putInviterReward(address _addr, uint256 _value) public returns (bool _result);
     function putNodeReward(address _addr, uint256 _value) public returns (bool _result);
     
     function withdraw() public returns (bool _result);
     function getUserDonateReward(address _addr) public view returns (uint256 _value);
}

contract LockUp is  Ownable, LockInterface, Pausable{
    using SafeMath for uint256;
    uint constant public PERCENTS_DIVIDER = 10**5;
    uint constant public DAY_BLOCKNUMBER = 28800;
    address public donate;
    EIP20Interface public eip20;
    uint public startBlock;
    uint releaseDays = 100;
    uint firstReleaseRatio = 10000;
    
    mapping (address => User) public users;
    
    struct User {
        uint256 donateReward;
        uint256 inviterReward;
        uint256 nodeReward;
        uint256 lastBlock;
        uint256 totalLockOf;
        uint256 remainLockOf;
    }
    
    event Withdraw(address indexed from, address indexed to, uint256 value);
    
    constructor(
        address _holder, 
        address _donateAddr, 
        uint _startBlock, 
        uint _releaseDays, 
        address _targetCoin) public {
        owner =_holder;
        donate =_donateAddr;
        eip20 = EIP20Interface(_targetCoin);
        startBlock =_startBlock;
        releaseDays =_releaseDays;
    }
    
    /* setDonate */
    function setDonateAddr(address _donateAddr) public onlyOwner whenNotPaused returns (bool _result) {
        require(_donateAddr != address(0), 'address must != 0 ');
        donate = _donateAddr;
        _result = true;
    }
    
    /* start */
    function strat(uint _startBlock) public onlyOwner whenNotPaused returns(bool _result) {
        require(_startBlock > block.number && startBlock != 0, 'has running! ');
        startBlock = _startBlock;
        _result = true;
    }
    
    /* put Called by donate contract */
    function putDonateReward(address _userAddress, uint256 _value) public whenNotPaused returns(bool _result) {
        _put(_userAddress);
        User storage _user = users[_userAddress];
        _user.donateReward = _user.donateReward.safeAdd(_value);
        _user.totalLockOf = _user.totalLockOf.safeAdd(_value);
        _user.remainLockOf = _user.remainLockOf.safeAdd(_value);
        
        _result = true;
    }
    
        /* put Called by donate contract */
    function putInviterReward(address _userAddress, uint256 _value) public whenNotPaused returns(bool _result) {
        _put(_userAddress);
        User storage _user = users[_userAddress];
        _user.inviterReward = _user.inviterReward.safeAdd(_value);
        _user.totalLockOf = _user.totalLockOf.safeAdd(_value);
        _user.remainLockOf = _user.remainLockOf.safeAdd(_value);
        
        _result = true;
    }
    
        /* put Called by donate contract */
    function putNodeReward(address _userAddress, uint256 _value) public whenNotPaused returns(bool _result) {
        _put(_userAddress);
        User storage _user = users[_userAddress];
        _user.nodeReward = _user.nodeReward.safeAdd(_value);
        _user.totalLockOf = _user.totalLockOf.safeAdd(_value);
        _user.remainLockOf = _user.remainLockOf.safeAdd(_value);
        
        _result = true;
    }
    
    function _put(address _addr) private view whenNotPaused {
        require(_addr != address(0), 'address must != 0 !');
        require(startBlock == 0, 'lock contract is running !');
        require(msg.sender == donate, 'refuse !');
    }
    
    /* get User Available  */
    function getUserAvailable(address _userAddress) public view returns(uint256 _available) {
        _available = _userAvailable(_userAddress);
    }
    
     /* get User Available  */
    function getUserDonateReward(address _userAddress) public view returns(uint256 _value) {
       _value = users[_userAddress].donateReward;
    }
    
    /* withdraw */
    function withdraw() public whenNotPaused returns(bool _result) {
        require(users[msg.sender].lastBlock > 0 && startBlock < block.number, 'not open !!!');
        uint256 _reward =  _userAvailable(msg.sender);
        User storage _user = users[msg.sender];
        eip20.transfer(msg.sender, _reward);
        _user.lastBlock = block.number;
        _user.remainLockOf -= _reward;
        emit Withdraw(msg.sender, donate , _reward);
        _result = true;
    }
    
    /* _userAvailable */
    function _userAvailable(address _userAddress) private view returns(uint256 _result){
        uint blockNumber = block.number;
        
        uint256 reward = 0;
        if(users[_userAddress].remainLockOf > 0 && startBlock <= blockNumber && startBlock > 0) {
            uint last = users[_userAddress].lastBlock;
            if(last == 0) {
                reward +=  users[_userAddress].totalLockOf.safeMul(firstReleaseRatio).safeDiv(PERCENTS_DIVIDER);
                last = startBlock;
            }
            reward += users[_userAddress].totalLockOf.safeMul(PERCENTS_DIVIDER.safeSub(firstReleaseRatio)).safeDiv(PERCENTS_DIVIDER); // first release total remain 
            reward = reward.safeMul(blockNumber.safeSub(last)).safeDiv(DAY_BLOCKNUMBER.safeMul(releaseDays)); // 
        }
        
        _result = users[_userAddress].remainLockOf >= reward ? reward : users[_userAddress].remainLockOf;
    }
}