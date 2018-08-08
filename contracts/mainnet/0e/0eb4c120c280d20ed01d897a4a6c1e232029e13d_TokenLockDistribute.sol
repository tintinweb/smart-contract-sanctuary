pragma solidity ^0.4.23;

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

contract MultiOwnable {
    mapping (address => bool) owners;
    address unremovableOwner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event OwnershipExtended(address indexed host, address indexed guest);
    event OwnershipRemoved(address indexed removedOwner);

    modifier onlyOwner() {
        require(owners[msg.sender]);
        _;
    }

    constructor() public {
        owners[msg.sender] = true;
        unremovableOwner = msg.sender;
    }

    function addOwner(address guest) onlyOwner public {
        require(guest != address(0));
        owners[guest] = true;
        emit OwnershipExtended(msg.sender, guest);
    }

    function removeOwner(address removedOwner) onlyOwner public {
        require(removedOwner != address(0));
        require(unremovableOwner != removedOwner);
        delete owners[removedOwner];
        emit OwnershipRemoved(removedOwner);
    }

    function transferOwnership(address newOwner) onlyOwner public {
        require(newOwner != address(0));
        require(unremovableOwner != msg.sender);
        owners[newOwner] = true;
        delete owners[msg.sender];
        emit OwnershipTransferred(msg.sender, newOwner);
    }

    function isOwner(address addr) public view returns(bool){
        return owners[addr];
    }
}

contract TokenLock is MultiOwnable {
    ERC20 public token;
    mapping (address => uint256) public lockAmounts;
    mapping (address => uint256) public releaseBlocks;

    constructor (address _token) public {
        token = ERC20(_token);
    }

    function getLockAmount(address _addr) external view returns (uint256) {
        return lockAmounts[_addr];
    }

    function getReleaseBlock(address _addr) external view returns (uint256) {
        return releaseBlocks[_addr];
    }

    function lock(address _addr, uint256 _amount, uint256 _releaseBlock) external {
        require(owners[msg.sender]);
        require(_addr != address(0));
        lockAmounts[_addr] = _amount;
        releaseBlocks[_addr] = _releaseBlock;
    }

    function release(address _addr) external {
        require(owners[msg.sender] || msg.sender == _addr);
        require(block.number >= releaseBlocks[_addr]);
        uint256 amount = lockAmounts[_addr];
        lockAmounts[_addr] = 0;
        releaseBlocks[_addr] = 0;
        token.transfer(_addr, amount);
    }
}

contract TokenLockDistribute is Ownable {
    ERC20 public token;
    TokenLock public lock;

    constructor (address _token, address _lock) public {
        token = ERC20(_token);
        lock = TokenLock(_lock);
    }

    function distribute(address _to, uint256 _unlockedAmount, uint256 _lockedAmount, uint256 _releaseBlockNumber) public onlyOwner {
        require(_to != address(0));
        token.transfer(address(lock), _lockedAmount);
        lock.lock(_to, _lockedAmount, _releaseBlockNumber);
        token.transfer(_to, _unlockedAmount);

        emit Distribute(_to, _unlockedAmount, _lockedAmount, _releaseBlockNumber);
    }

    event Distribute(address indexed _to, uint256 _unlockedAmount, uint256 _lockedAmount, uint256 _releaseBlockNumber);
}