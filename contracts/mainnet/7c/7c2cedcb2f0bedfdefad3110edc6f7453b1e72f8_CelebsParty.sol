pragma solidity ^0.4.19;

// File: contracts/includes/Ownable.sol

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
  function Ownable() public {
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
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

// File: contracts/includes/Claimable.sol

/**
 * @title Claimable
 * @dev Extension for the Ownable contract, where the ownership needs to be claimed.
 * This allows the new owner to accept the transfer.
 */
contract Claimable is Ownable {
  address public pendingOwner;

  /**
   * @dev Modifier throws if called by any account other than the pendingOwner.
   */
  modifier onlyPendingOwner() {
    require(msg.sender == pendingOwner);
    _;
  }

  /**
   * @dev Allows the current owner to set the pendingOwner address.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) onlyOwner public {
    pendingOwner = newOwner;
  }

  /**
   * @dev Allows the pendingOwner address to finalize the transfer.
   */
  function claimOwnership() onlyPendingOwner public {
    // emit OwnershipTransferred(owner, pendingOwner);
    owner = pendingOwner;
    pendingOwner = address(0);
  }
}

// File: contracts/includes/Pausable.sol

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
    Pause();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() onlyOwner whenPaused public {
    paused = false;
    Unpause();
  }
}

// File: contracts/CelebsPartyGate.sol

contract CelebsPartyGate is Claimable, Pausable {
  address public cfoAddress;
  
  function CelebsPartyGate() public {
    cfoAddress = msg.sender;
  }

  modifier onlyCFO() {
    require(msg.sender == cfoAddress);
    _;
  }

  function setCFO(address _newCFO) external onlyOwner {
    require(_newCFO != address(0));
    cfoAddress = _newCFO;
  }
}

// File: contracts/includes/SafeMath.sol

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
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
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  /**
  * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
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

// File: contracts/CelebsParty.sol

contract CelebsParty is CelebsPartyGate {
    using SafeMath for uint256;

    event AgentHired(uint256 identifier, address player, bool queued);
    event Birth(uint256 identifier, string name, address owner, bool queued);
    event CategoryCreated(uint256 indexed identifier, string name);
    event CelebrityBought(uint256 indexed identifier, address indexed oldOwner, address indexed newOwner, uint256 price);
    event CelebrityReleased(uint256 indexed identifier, address player);
    event FameAcquired(uint256 indexed identifier, address player, uint256 fame);
    event PriceUpdated(uint256 indexed identifier, uint256 price);
    event PrizeAwarded(address player, uint256 amount, string reason);
    event UsernameUpdated(address player, string username);

    struct Category {
        uint256 identifier;
        string name;
    }

    struct Celebrity {
        uint256 identifier;
        uint256[] categories;
        string name;
        uint256 price;
        address owner;
        bool isQueued;
        uint256 lastQueueBlock;
        address agent;
        uint256 agentAwe;
        uint256 famePerBlock;
        uint256 lastFameBlock;
    }

    mapping(uint256 => Category) public categories;
    mapping(uint256 => Celebrity) public celebrities;
    mapping(address => uint256) public fameBalance;
    mapping(address => string) public usernames;
    
    uint256 public categoryCount;
    uint256 public circulatingFame;
    uint256 public celebrityCount;
    uint256 public devBalance;
    uint256 public prizePool;

    uint256 public minRequiredBlockQueueTime;

    function CelebsParty() public {
        _initializeGame();
    }

    function acquireFame(uint256 _identifier) external {
        Celebrity storage celeb = celebrities[_identifier];
        address player = msg.sender;
        require(celeb.owner == player);
        uint256 acquiredFame = SafeMath.mul((block.number - celeb.lastFameBlock), celeb.famePerBlock);
        fameBalance[player] = SafeMath.add(fameBalance[player], acquiredFame);
        celeb.lastFameBlock = block.number;
        // increase the supply of the fame
        circulatingFame = SafeMath.add(circulatingFame, acquiredFame);
        FameAcquired(_identifier, player, acquiredFame);
    }

    function becomeAgent(uint256 _identifier, uint256 _agentAwe) public whenNotPaused {
        Celebrity storage celeb = celebrities[_identifier];
        address newAgent = msg.sender;
        address oldAgent = celeb.agent;
        uint256 currentAgentAwe = celeb.agentAwe;
        // ensure current agent is not the current player
        require(oldAgent != newAgent);
        // ensure the player can afford to become the agent
        require(fameBalance[newAgent] >= _agentAwe);
        // ensure the sent fame is more than the current agent sent
        require(_agentAwe > celeb.agentAwe);
        // if we are pre-drop, reset timer and give some fame back to previous bidder
        if (celeb.isQueued) {
            // reset the queue block timer
            celeb.lastQueueBlock = block.number;
            // give the old agent 50% of their fame back (this is a fame burn)
            if(oldAgent != address(this)) {
                uint256 halfOriginalFame = SafeMath.div(currentAgentAwe, 2);
                circulatingFame = SafeMath.add(circulatingFame, halfOriginalFame);
                fameBalance[oldAgent] = SafeMath.add(fameBalance[oldAgent], halfOriginalFame);
            }
        }
        // set the celebrity&#39;s agent to the current player
        celeb.agent = newAgent;
        // set the new min required bid
        celeb.agentAwe = _agentAwe;
        // deduct the sent fame amount from the current player&#39;s balance
        circulatingFame = SafeMath.sub(circulatingFame, _agentAwe);
        fameBalance[newAgent] = SafeMath.sub(fameBalance[newAgent], _agentAwe);
        AgentHired(_identifier, newAgent, celeb.isQueued);
    }

    function buyCelebrity(uint256 _identifier) public payable whenNotPaused {
        Celebrity storage celeb = celebrities[_identifier];
        // ensure that the celebrity is on the market and not queued
        require(!celeb.isQueued);
        address oldOwner = celeb.owner;
        uint256 salePrice = celeb.price;
        address newOwner = msg.sender;
        // ensure the current player is not the current owner
        require(oldOwner != newOwner);
        // ensure the current player can actually afford to buy the celebrity
        require(msg.value >= salePrice);
        address agent = celeb.agent;
        // determine how much fame the celebrity has generated
        uint256 generatedFame = uint256(SafeMath.mul((block.number - celeb.lastFameBlock), celeb.famePerBlock));
        // 91% of the sale will go the previous owner
        uint256 payment = uint256(SafeMath.div(SafeMath.mul(salePrice, 91), 100));
        // 4% of the sale will go to the celebrity&#39;s agent
        uint256 agentFee = uint256(SafeMath.div(SafeMath.mul(salePrice, 4), 100));
        // 3% of the sale will go to the developer of the game
        uint256 devFee = uint256(SafeMath.div(SafeMath.mul(salePrice, 3), 100));
        // 2% of the sale will go to the prize pool
        uint256 prizeFee = uint256(SafeMath.div(SafeMath.mul(salePrice, 2), 100));
        // calculate any excess wei that should be refunded
        uint256 purchaseExcess = SafeMath.sub(msg.value, salePrice);
        if (oldOwner != address(this)) {
            // only transfer the funds if the contract doesn&#39;t own the celebrity (no pre-mine)
            oldOwner.transfer(payment);
        } else {
            // if this is the first sale, main proceeds go to the prize pool
            prizePool = SafeMath.add(prizePool, payment);
        }
        if (agent != address(this)) {
            // send the agent their cut of the sale
            agent.transfer(agentFee);
        }
        // new owner gets half of the unacquired, generated fame on the celebrity
        uint256 spoils = SafeMath.div(generatedFame, 2);
        circulatingFame = SafeMath.add(circulatingFame, spoils);
        fameBalance[newOwner] = SafeMath.add(fameBalance[newOwner], spoils);
        // don&#39;t send the dev anything, but make a note of it
        devBalance = SafeMath.add(devBalance, devFee);
        // increase the prize pool balance
        prizePool = SafeMath.add(prizePool, prizeFee);
        // set the new owner of the celebrity
        celeb.owner = newOwner;
        // set the new price of the celebrity
        celeb.price = _nextPrice(salePrice);
        // destroy all unacquired fame by resetting the block number
        celeb.lastFameBlock = block.number;
        // the fame acquired per block increases by 1 every time the celebrity is purchased
        // this is capped at 100 fpb
        if(celeb.famePerBlock < 100) {
            celeb.famePerBlock = SafeMath.add(celeb.famePerBlock, 1);
        }
        // let the world know the celebrity has been purchased
        CelebrityBought(_identifier, oldOwner, newOwner, salePrice);
        // send the new owner any excess wei
        newOwner.transfer(purchaseExcess);
    }

    function createCategory(string _name) external onlyOwner {
        _mintCategory(_name);
    }

    function createCelebrity(string _name, address _owner, address _agent, uint256 _agentAwe, uint256 _price, bool _queued, uint256[] _categories) public onlyOwner {
        require(celebrities[celebrityCount].price == 0);
        address newOwner = _owner;
        address newAgent = _agent;
        if (newOwner == 0x0) {
            newOwner = address(this);
        }
        if (newAgent == 0x0) {
            newAgent = address(this);
        }
        uint256 newIdentifier = celebrityCount;
        Celebrity memory celeb = Celebrity({
            identifier: newIdentifier,
            owner: newOwner,
            price: _price,
            name: _name,
            famePerBlock: 0,
            lastQueueBlock: block.number,
            lastFameBlock: block.number,
            agent: newAgent,
            agentAwe: _agentAwe,
            isQueued: _queued,
            categories: _categories
        });
        celebrities[newIdentifier] = celeb;
        celebrityCount = SafeMath.add(celebrityCount, 1);
        Birth(newIdentifier, _name, _owner, _queued);
    }
    
    function getCelebrity(uint256 _identifier) external view returns
    (uint256 id, string name, uint256 price, uint256 nextPrice, address agent, uint256 agentAwe, address owner, uint256 fame, uint256 lastFameBlock, uint256[] cats, bool queued, uint256 lastQueueBlock)
    {
        Celebrity storage celeb = celebrities[_identifier];
        id = celeb.identifier;
        name = celeb.name;
        owner = celeb.owner;
        agent = celeb.agent;
        price = celeb.price;
        fame = celeb.famePerBlock;
        lastFameBlock = celeb.lastFameBlock;
        nextPrice = _nextPrice(price);
        cats = celeb.categories;
        agentAwe = celeb.agentAwe;
        queued = celeb.isQueued;
        lastQueueBlock = celeb.lastQueueBlock;
    }

    function getFameBalance(address _player) external view returns(uint256) {
        return fameBalance[_player];
    }

    function getUsername(address _player) external view returns(string) {
        return usernames[_player];
    }

    function releaseCelebrity(uint256 _identifier) public whenNotPaused {
        Celebrity storage celeb = celebrities[_identifier];
        address player = msg.sender;
        // ensure that enough blocks have been mined (no one has bid within this time period)
        require(block.number - celeb.lastQueueBlock >= minRequiredBlockQueueTime);
        // ensure the celebrity isn&#39;t already released!
        require(celeb.isQueued);
        // ensure current agent is the current player
        require(celeb.agent == player);
        // celebrity is no longer queued and can be displayed on the market
        celeb.isQueued = false;
        CelebrityReleased(_identifier, player);
    }

    function setCelebrityPrice(uint256 _identifier, uint256 _price) public whenNotPaused {
        Celebrity storage celeb = celebrities[_identifier];
        // ensure the current player is the owner of the celebrity
        require(msg.sender == celeb.owner);
        // the player can only set a price that is lower than the current asking price
        require(_price < celeb.price);
        // set the new price 
        celeb.price = _price;
        PriceUpdated(_identifier, _price);
    }

    function setRequiredBlockQueueTime(uint256 _blocks) external onlyOwner {
        minRequiredBlockQueueTime = _blocks;
    }

    function setUsername(address _player, string _username) public {
        // ensure the player to be changed is the current player
        require(_player == msg.sender);
        // set the username
        usernames[_player] = _username;
        UsernameUpdated(_player, _username);
    }

    function sendPrize(address _player, uint256 _amount, string _reason) external onlyOwner {
        uint256 newPrizePoolAmount = prizePool - _amount;
        require(prizePool >= _amount);
        require(newPrizePoolAmount >= 0);
        prizePool = newPrizePoolAmount;
        _player.transfer(_amount);
        PrizeAwarded(_player, _amount, _reason);
    }

    function withdrawDevBalance() external onlyOwner {
        require(devBalance > 0);
        uint256 withdrawAmount = devBalance;
        devBalance = 0;
        owner.transfer(withdrawAmount);
    }

    /**************************
        internal funcs
    ***************************/

    function _nextPrice(uint256 currentPrice) internal pure returns(uint256) {
        if (currentPrice < .1 ether) {
            return currentPrice.mul(200).div(100);
        } else if (currentPrice < 1 ether) {
            return currentPrice.mul(150).div(100);
        } else if (currentPrice < 10 ether) {
            return currentPrice.mul(130).div(100);
        } else {
            return currentPrice.mul(120).div(100);
        }
    }

    function _mintCategory(string _name) internal {
        uint256 newIdentifier = categoryCount;
        categories[newIdentifier] = Category(newIdentifier, _name);
        CategoryCreated(newIdentifier, _name);
        categoryCount = SafeMath.add(categoryCount, 1);
    }

    function _initializeGame() internal {
        categoryCount = 0;
        celebrityCount = 0;
        minRequiredBlockQueueTime = 1000;
        paused = true;
        _mintCategory("business");
        _mintCategory("film/tv");
        _mintCategory("music");
        _mintCategory("personality");
        _mintCategory("tech");
    }
}