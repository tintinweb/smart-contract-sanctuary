pragma solidity ^0.4.23;


/**
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
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
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



contract BntyControllerInterface {
    function destroyTokensInBntyTokenContract(address _owner, uint _amount) public returns (bool);
}




contract Bounty0xStaking is Ownable, Pausable {

    using SafeMath for uint256;

    address public Bounty0xToken;
    uint public lockTime;

    mapping (address => uint) public balances;
    mapping (uint => mapping (address => uint)) public stakes; // mapping of submission ids to mapping of addresses that staked an amount of bounty token
    mapping (address => uint) public huntersLockDateTime;
    mapping (address => uint) public huntersLockAmount;
    
    
    event Deposit(address indexed depositor, uint amount, uint balance);
    event Withdraw(address indexed depositor, uint amount, uint balance);
    event Stake(uint indexed submissionId, address indexed hunter, uint amount, uint balance);
    event StakeReleased(uint indexed submissionId, address indexed from, address indexed to, uint amount);
    event Lock(address indexed hunter, uint amount, uint endDateTime);
    event Unlock(address indexed hunter, uint amount);


    constructor(address _bounty0xToken) public {
        Bounty0xToken = _bounty0xToken;
        lockTime = 30 days;
    }
    

    function deposit(uint _amount) external whenNotPaused {
        //remember to call Token(address).approve(this, amount) or this contract will not be able to do the transfer on your behalf.
        require(ERC20(Bounty0xToken).transferFrom(msg.sender, this, _amount));
        balances[msg.sender] = SafeMath.add(balances[msg.sender], _amount);

        emit Deposit(msg.sender, _amount, balances[msg.sender]);
    }
    
    function withdraw(uint _amount) external whenNotPaused {
        require(balances[msg.sender] >= _amount);
        balances[msg.sender] = SafeMath.sub(balances[msg.sender], _amount);
        require(ERC20(Bounty0xToken).transfer(msg.sender, _amount));

        emit Withdraw(msg.sender, _amount, balances[msg.sender]);
    }
    
    
    function lock(uint _amount) external whenNotPaused {
        require(_amount != 0);
        require(balances[msg.sender] >= _amount);
        
        balances[msg.sender] = SafeMath.sub(balances[msg.sender], _amount);
        huntersLockAmount[msg.sender] = SafeMath.add(huntersLockAmount[msg.sender], _amount);
        huntersLockDateTime[msg.sender] = SafeMath.add(now, lockTime);
        
        emit Lock(msg.sender, huntersLockAmount[msg.sender], huntersLockDateTime[msg.sender]);
    }
    
    function unlock() external whenNotPaused {
        require(huntersLockDateTime[msg.sender] <= now);
        uint amountLocked = huntersLockAmount[msg.sender];
        require(amountLocked != 0);
        
        huntersLockAmount[msg.sender] = SafeMath.sub(huntersLockAmount[msg.sender], amountLocked);
        balances[msg.sender] = SafeMath.add(balances[msg.sender], amountLocked);
        
        emit Unlock(msg.sender, amountLocked);
    }


    function stake(uint _submissionId, uint _amount) external whenNotPaused {
        require(balances[msg.sender] >= _amount);
        balances[msg.sender] = SafeMath.sub(balances[msg.sender], _amount);
        stakes[_submissionId][msg.sender] = SafeMath.add(stakes[_submissionId][msg.sender], _amount);

        emit Stake(_submissionId, msg.sender, _amount, balances[msg.sender]);
    }

    function stakeToMany(uint[] _submissionIds, uint[] _amounts) external whenNotPaused {
        uint totalAmount = 0;
        for (uint j = 0; j < _amounts.length; j++) {
            totalAmount = SafeMath.add(totalAmount, _amounts[j]);
        }
        require(balances[msg.sender] >= totalAmount);
        balances[msg.sender] = SafeMath.sub(balances[msg.sender], totalAmount);

        for (uint i = 0; i < _submissionIds.length; i++) {
            stakes[_submissionIds[i]][msg.sender] = SafeMath.add(stakes[_submissionIds[i]][msg.sender], _amounts[i]);

            emit Stake(_submissionIds[i], msg.sender, _amounts[i], balances[msg.sender]);
        }
    }


    function releaseStake(uint _submissionId, address _from, address _to) external onlyOwner {
        require(stakes[_submissionId][_from] != 0);

        balances[_to] = SafeMath.add(balances[_to], stakes[_submissionId][_from]);
        emit StakeReleased(_submissionId, _from, _to, stakes[_submissionId][_from]);
        
        stakes[_submissionId][_from] = 0;
    }

    function releaseManyStakes(uint[] _submissionIds, address[] _from, address[] _to) external onlyOwner {
        require(_submissionIds.length == _from.length &&
                _submissionIds.length == _to.length);

        for (uint i = 0; i < _submissionIds.length; i++) {
            require(_from[i] != address(0));
            require(_to[i] != address(0));
            require(stakes[_submissionIds[i]][_from[i]] != 0);
            
            balances[_to[i]] = SafeMath.add(balances[_to[i]], stakes[_submissionIds[i]][_from[i]]);
            emit StakeReleased(_submissionIds[i], _from[i], _to[i], stakes[_submissionIds[i]][_from[i]]);
            
            stakes[_submissionIds[i]][_from[i]] = 0;
        }
    }
    

    function changeLockTime(uint _periodInSeconds) external onlyOwner {
        lockTime = _periodInSeconds;
    }
    
    
    // Burnable mechanism

    address public bntyController;

    event Burn(uint indexed submissionId, address indexed from, uint amount);

    function changeBntyController(address _bntyController) external onlyOwner {
        bntyController = _bntyController;
    }


    function burnStake(uint _submissionId, address _from) external onlyOwner {
        require(stakes[_submissionId][_from] > 0);

        uint amountToBurn = stakes[_submissionId][_from];
        stakes[_submissionId][_from] = 0;

        require(BntyControllerInterface(bntyController).destroyTokensInBntyTokenContract(this, amountToBurn));
        emit Burn(_submissionId, _from, amountToBurn);
    }


    // in case of emergency
    function emergentWithdraw() external onlyOwner {
        require(ERC20(Bounty0xToken).transfer(msg.sender, this.balance));
    }
    
}