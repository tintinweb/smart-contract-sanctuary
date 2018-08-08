pragma solidity ^0.4.16;

/**
 * @title ERC20 interface
 * @dev cutdown simply to allow removal of tokens sent to contract
 */
contract ERC20 {
  function transfer(address to, uint256 value) returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() {
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
  function transferOwnership(address newOwner) onlyOwner {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
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
   * @dev modifier to allow actions only when the contract IS paused
   */
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  /**
   * @dev modifier to allow actions only when the contract IS NOT paused
   */
  modifier whenPaused {
    require(paused);
    _;
  }

  /**
   * @dev called by the owner to pause, triggers stopped state
   */
  function pause() onlyOwner whenNotPaused returns (bool) {
    paused = true;
    Pause();
    return true;
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() onlyOwner whenPaused returns (bool) {
    paused = false;
    Unpause();
    return true;
  }
}

// 200 000 000 ether = A56FA5B99019A5C8000000 = 88 bits. We have 256.
// we do NOT need safemath.

contract SimpleSale is Ownable,Pausable {

    address public multisig = 0xc862705dDA23A2BAB54a6444B08a397CD4DfCD1c;
    address public cs;
    uint256 public totalCollected;
    bool    public saleFinished;
    uint256 public startTime = 1505998800;
    uint256 public stopTime = 1508590800;

    mapping (address => uint256) public deposits;
    mapping (address => bool) public authorised; // just to annoy the heck out of americans

    /**
     * @dev throws if person sending is not contract owner or cs role
     */
    modifier onlyCSorOwner() {
        require((msg.sender == owner) || (msg.sender==cs));
        _;
    }

    /**
     * @dev throws if person sending is not authorised or sends nothing
     */
    modifier onlyAuthorised() {
        require (authorised[msg.sender]);
        require (msg.value > 0);
        require (now >= startTime);
        require (now <= stopTime);
        require (!saleFinished);
        require(!paused);
        _;
    }

    /**
     * @dev set start and stop times
     */
    function setPeriod(uint256 start, uint256 stop) onlyOwner {
        startTime = start;
        stopTime = stop;
    }
    
    /**
     * @dev authorise an account to participate
     */
    function authoriseAccount(address whom) onlyCSorOwner {
        authorised[whom] = true;
    }

    /**
     * @dev authorise a lot of accounts in one go
     */
    function authoriseManyAccounts(address[] many) onlyCSorOwner {
        for (uint256 i = 0; i < many.length; i++) {
            authorised[many[i]] = true;
        }
    }

    /**
     * @dev ban an account from participation (default)
     */
    function blockAccount(address whom) onlyCSorOwner {
        authorised[whom] = false;
    }

    /**
     * @dev set a new CS representative
     */
    function setCS(address newCS) onlyOwner {
        cs = newCS;
    }

    /**
     * @dev call an end (e.g. because cap reached)
     */
    function stopSale() onlyOwner {
        saleFinished = true;
    }
    
    function SimpleSale() {
        
    }

    /**
     * @dev fallback function received ether, sends it to the multisig, notes indivdual and group contributions
     */
    function () payable onlyAuthorised {
        multisig.transfer(msg.value);
        deposits[msg.sender] += msg.value;
        totalCollected += msg.value;
    }

    /**
     * @dev in case somebody sends ERC2o tokens...
     */
    function emergencyERC20Drain( ERC20 token, uint amount ) onlyOwner {
        token.transfer(owner, amount);
    }

}