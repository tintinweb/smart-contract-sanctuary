/**
 *Submitted for verification at BscScan.com on 2021-08-27
*/

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

library SafeMath {
    function safeAdd(uint256 a, uint256 b) internal pure returns(uint256)
    {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
    function safeSub(uint256 a, uint256 b) internal pure returns(uint256)
    {
        assert(b <= a);
        return a - b;
    }
    function safeMul(uint256 a, uint256 b) internal pure returns(uint256)
    {
        if (a == 0) {
        return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }
    function safeDiv(uint256 a, uint256 b) internal pure returns(uint256)
    {
        uint256 c = a / b;
        return c;
    }
}

contract LockInterface {
     function put(address _addr, uint256 _value) public returns (bool success);
     function withdraw() public returns (bool success);
}



contract LockUp is  Ownable, LockInterface, Pausable{
    using SafeMath for uint256;
    uint constant public PERCENTS_DIVIDER = 100000;
    uint constant public DAY_BLOCKNUMBER = 28800;
    address public donate;
    EIP20Interface eip20;
    uint public startBlcok;
    uint releaseDays = 100;
    uint firstRes = 10000;
    mapping (address => uint256)  public nowLockOf;
    mapping (address => uint256)  public lockOf;
    mapping (address => uint) public lastBlock;
    
    event Withdraw(address indexed from, address indexed cont, uint256 value);
    
    constructor(
        address _holder, 
        address _donateAddr, 
        uint _startBlcok, 
        uint _releaseDays, 
        address _targetCoin) public {
        owner =_holder;
        donate =_donateAddr;
        eip20 = EIP20Interface(_targetCoin);
        startBlcok =_startBlcok;
        releaseDays =_releaseDays;
    }
    
    /* setDonate */
    function setDonateAddr(address _addr) public onlyOwner whenNotPaused returns (bool success) {
        require(_addr != address(0), 'address must != 0');
        donate = _addr;
        return true;
    }
    
    /* start */
    function strat(uint _startBlcok) public onlyOwner whenNotPaused returns(bool success) {
        require(_startBlcok> block.number && startBlcok !=0, 'has running');
        startBlcok = _startBlcok;
        return true;
    }
    
    /* put Called by donate contract */
    function put(address _addr, uint256 _value) public whenNotPaused returns(bool success) {
        require(_addr != address(0), 'address must != 0 !');
        require(msg.sender == donate, 'refuse !');
        lockOf[_addr] = lockOf[_addr].safeAdd(_value);
        nowLockOf[_addr] = nowLockOf[_addr].safeAdd(_value);
        return true;
    }
    
    /* get User Available  */
    function getUserAvailable(address _userAddress) public view returns(uint256 available) {
        uint blockNumber = block.number;
        
        uint256 reward = 0;
        if(nowLockOf[_userAddress] > 0 && startBlcok <= blockNumber) {
            uint last = lastBlock[_userAddress];
            if(last == 0) {
                reward +=  lockOf[_userAddress].safeMul(firstRes).safeDiv(PERCENTS_DIVIDER);
                last = startBlcok;
            }
            reward += (lockOf[_userAddress].safeSub(reward)).safeMul(blockNumber.safeSub(last)).safeDiv(DAY_BLOCKNUMBER.safeMul(releaseDays));
        }
        return nowLockOf[_userAddress] >= reward ? reward : nowLockOf[_userAddress];
    }
    
    /* withdraw */
    function withdraw() public whenNotPaused returns(bool success) {
        uint blockNumber = block.number;
        require(startBlcok > 0 && startBlcok < blockNumber, 'not open !');
        if(nowLockOf[msg.sender] > 0) {
            uint256 reward = 0;
            uint last = lastBlock[msg.sender];
            if(last == 0){
                reward +=  lockOf[msg.sender].safeMul(firstRes).safeDiv(PERCENTS_DIVIDER);
                last = startBlcok;
            }
            reward += (lockOf[msg.sender].safeSub(reward)).safeMul(blockNumber.safeSub(last)).safeDiv(DAY_BLOCKNUMBER.safeMul(releaseDays));
            reward = nowLockOf[msg.sender] >= reward ? reward : nowLockOf[msg.sender];
            eip20.transfer(msg.sender, reward);
            lastBlock[msg.sender] = blockNumber;
            nowLockOf[msg.sender] -= reward;
            emit Withdraw(msg.sender, donate , reward);
        }
        return true;
    }
}