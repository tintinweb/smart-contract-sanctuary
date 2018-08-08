pragma solidity ^0.4.11;

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
    if (msg.sender != owner) {
      throw;
    }
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
    if (paused) throw;
    _;
  }

  /**
   * @dev modifier to allow actions only when the contract IS NOT paused
   */
  modifier whenPaused {
    if (!paused) throw;
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



/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) constant returns (uint256);
  function transfer(address to, uint256 value);
  event Transfer(address indexed from, address indexed to, uint256 value);
}


/**
 * Math operations with safety checks
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }

  function max64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a < b ? a : b;
  }

}



/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances. 
 */
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  /**
   * @dev Fix for the ERC20 short address attack.
   */
  modifier onlyPayloadSize(uint256 size) {
     if(msg.data.length < size + 4) {
       throw;
     }
     _;
  }

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) onlyPayloadSize(2 * 32) {
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of. 
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) constant returns (uint256 balance) {
    return balances[_owner];
  }

}



/**
 * @title Helps contracts guard agains rentrancy attacks.
 * @author Remco Bloemen <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="ec9e89818f83acde">[email&#160;protected]</a>π.com>
 * @notice If you mark a function `nonReentrant`, you should also
 * mark it `external`.
 */
contract ReentrancyGuard {

  /**
   * @dev We use a single lock for the whole contract. 
   */
  bool private rentrancy_lock = false;

  /**
   * @dev Prevents a contract from calling itself, directly or indirectly.
   * @notice If you mark a function `nonReentrant`, you should also
   * mark it `external`. Calling one nonReentrant function from
   * another is not supported. Instead, you can implement a
   * `private` function doing the actual work, and a `external`
   * wrapper marked as `nonReentrant`.
   */
  modifier nonReentrant() {
    if(rentrancy_lock == false) {
      rentrancy_lock = true;
      _;
      rentrancy_lock = false;
    } else {
      throw;
    }
  }

}

contract EtchReward is Pausable, BasicToken, ReentrancyGuard {

    // address public owner;                // Ownable
    // bool public paused = false;          // Pausable
    // mapping(address => uint) balances;   // BasicToken
    // uint public totalSupply;             // ERC20Basic
    // bool private rentrancy_lock = false; // ReentrancyGuard

    //
    // @dev constants
    //
    string public constant name   = "Etch Reward Token";
    string public constant symbol = "ETCHR";
    uint public constant decimals = 18;

    //
    // @dev the main address to be forwarded all ether
    //
    address public constant BENEFICIARY = 0x651A3731f717a17777c9D8d6f152Aa9284978Ea3;

    // @dev number of tokens one receives for every 1 ether they send
    uint public constant PRICE = 8;

    // avg block time = 15.2569 https://etherscan.io/chart/blocktime
    uint public constant AVG_BLOCKS_24H = 5663;  // 3600 * 24 / 15.2569 = 5663.011489883266
    uint public constant AVG_BLOCKS_02W = 79282; // 3600 * 24 * 14 / 15.2569 =  79282.16085836572

    uint public constant MAX_ETHER_24H = 40 ether;
    uint public constant ETHER_CAP     = 2660 ether;

    uint public totalEther = 0;
    uint public blockStart = 0;
    uint public block24h   = 0;
    uint public block02w   = 0;

    // @dev address of the actual ICO contract to be deployed later
    address public icoContract = 0x0;

    //
    // @dev owner authorized addresses to participate in this pre-ico
    //
    mapping(address => bool) contributors;


    // @dev constructor function
    function EtchReward(uint _blockStart) {
        blockStart  = _blockStart;
        block24h = blockStart + AVG_BLOCKS_24H;
        block02w = blockStart + AVG_BLOCKS_02W;
    }

    //
    // @notice the ability to transfer tokens is disabled
    //
    function transfer(address, uint) {
        throw;
    }

    //
    // @notice we DO allow sending ether directly to the contract address
    //
    function () payable {
        buy();
    }

    //
    // @dev modifiers
    //
    modifier onlyContributors() {
        if(contributors[msg.sender] != true) {
            throw;
        }
        _;
    }

    modifier onlyIcoContract() {
        if(icoContract == 0x0 || msg.sender != icoContract) {
            throw;
        }
        _;
    }

    //
    // @dev call this to authorize participants to this pre-ico sale
    // @param the authorized participant address
    //
    function addContributor(address _who) public onlyOwner {
        contributors[_who] = true;
    }

    // @dev useful for contributor to check before sending ether
    function isContributor(address _who) public constant returns(bool) {
        return contributors[_who];
    }

    //
    // @dev this will be later set by the owner of this contract
    //
    function setIcoContract(address _contract) public onlyOwner {
        icoContract = _contract;
    }

    //
    // @dev function called by the ICO contract to transform the tokens into ETCH tokens
    //
    function migrate(address _contributor) public
    onlyIcoContract
    whenNotPaused {

        if(getBlock() < block02w) {
            throw;
        }
        totalSupply = totalSupply.sub(balances[_contributor]);
        balances[_contributor] = 0;
    }

    function buy() payable
    nonReentrant
    onlyContributors
    whenNotPaused {

        address _recipient = msg.sender;
        uint blockNow = getBlock();

        // are we before or after the sale period?
        if(blockNow < blockStart || block02w <= blockNow) {
            throw;
        }

        if (blockNow < block24h) {

            // only one transaction is authorized
            if (balances[_recipient] > 0) {
                throw;
            }

            // only allowed to buy a certain amount
            if (msg.value > MAX_ETHER_24H) {
                throw;
            }
        }

        // make sure we don&#39;t go over the ether cap
        if (totalEther.add(msg.value) > ETHER_CAP) {
            throw;
        }

        uint tokens = msg.value.mul(PRICE);
        totalSupply = totalSupply.add(tokens);

        balances[_recipient] = balances[_recipient].add(tokens);
        totalEther.add(msg.value);

        if (!BENEFICIARY.send(msg.value)) {
            throw;
        }
    }

    uint public blockNumber = 0;

    function getBlock() public constant returns (uint) {
        if(blockNumber != 0) {
            return blockNumber;
        }
        return block.number;
    }

}