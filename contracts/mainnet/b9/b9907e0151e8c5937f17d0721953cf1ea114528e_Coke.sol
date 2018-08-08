pragma solidity ^0.4.21;

/**
 * @title LinkedListLib
 * @author Darryl Morris (o0ragman0o) and Modular.network
 * 
 * This utility library was forked from https://github.com/o0ragman0o/LibCLL
 * into the Modular-Network ethereum-libraries repo at https://github.com/Modular-Network/ethereum-libraries
 * It has been updated to add additional functionality and be more compatible with solidity 0.4.18
 * coding patterns.
 *
 * version 1.0.0
 * Copyright (c) 2017 Modular Inc.
 * The MIT License (MIT)
 * https://github.com/Modular-Network/ethereum-libraries/blob/master/LICENSE
 * 
 * The LinkedListLib provides functionality for implementing data indexing using
 * a circlular linked list
 *
 * Modular provides smart contract services and security reviews for contract
 * deployments in addition to working on open source projects in the Ethereum
 * community. Our purpose is to test, document, and deploy reusable code onto the
 * blockchain and improve both security and usability. We also educate non-profits,
 * schools, and other community members about the application of blockchain
 * technology. For further information: modular.network
 *
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
 * OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
 * IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
 * CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
 * TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
 * SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/


library LinkedListLib {

    uint256 constant NULL = 0;
    uint256 constant HEAD = 0;
    bool constant PREV = false;
    bool constant NEXT = true;
    
    struct LinkedList{
        mapping (uint256 => mapping (bool => uint256)) list;
    }

    /// @dev returns true if the list exists
    /// @param self stored linked list from contract
    function listExists(LinkedList storage self)
        internal
        view returns (bool)
    {
        // if the head nodes previous or next pointers both point to itself, then there are no items in the list
        if (self.list[HEAD][PREV] != HEAD || self.list[HEAD][NEXT] != HEAD) {
            return true;
        } else {
            return false;
        }
    }

    /// @dev returns true if the node exists
    /// @param self stored linked list from contract
    /// @param _node a node to search for
    function nodeExists(LinkedList storage self, uint256 _node) 
        internal
        view returns (bool)
    {
        if (self.list[_node][PREV] == HEAD && self.list[_node][NEXT] == HEAD) {
            if (self.list[HEAD][NEXT] == _node) {
                return true;
            } else {
                return false;
            }
        } else {
            return true;
        }
    }
    
    /// @dev Returns the number of elements in the list
    /// @param self stored linked list from contract
    function sizeOf(LinkedList storage self) internal view returns (uint256 numElements) {
        bool exists;
        uint256 i;
        (exists,i) = getAdjacent(self, HEAD, NEXT);
        while (i != HEAD) {
            (exists,i) = getAdjacent(self, i, NEXT);
            numElements++;
        }
        return;
    }

    /// @dev Returns the links of a node as a tuple
    /// @param self stored linked list from contract
    /// @param _node id of the node to get
    function getNode(LinkedList storage self, uint256 _node)
        internal view returns (bool,uint256,uint256)
    {
        if (!nodeExists(self,_node)) {
            return (false,0,0);
        } else {
            return (true,self.list[_node][PREV], self.list[_node][NEXT]);
        }
    }

    /// @dev Returns the link of a node `_node` in direction `_direction`.
    /// @param self stored linked list from contract
    /// @param _node id of the node to step from
    /// @param _direction direction to step in
    function getAdjacent(LinkedList storage self, uint256 _node, bool _direction)
        internal view returns (bool,uint256)
    {
        if (!nodeExists(self,_node)) {
            return (false,0);
        } else {
            return (true,self.list[_node][_direction]);
        }
    }
    
    /// @dev Can be used before `insert` to build an ordered list
    /// @param self stored linked list from contract
    /// @param _node an existing node to search from, e.g. HEAD.
    /// @param _value value to seek
    /// @param _direction direction to seek in
    //  @return next first node beyond &#39;_node&#39; in direction `_direction`
    function getSortedSpot(LinkedList storage self, uint256 _node, uint256 _value, bool _direction)
        internal view returns (uint256)
    {
        if (sizeOf(self) == 0) { return 0; }
        require((_node == 0) || nodeExists(self,_node));
        bool exists;
        uint256 next;
        (exists,next) = getAdjacent(self, _node, _direction);
        while  ((next != 0) && (_value != next) && ((_value < next) != _direction)) next = self.list[next][_direction];
        return next;
    }
    
    /// @dev Can be used before `insert` to build an ordered list
    /// @param self stored linked list from contract
    /// @param _node an existing node to search from, e.g. HEAD.
    /// @param _value value to seek
    /// @param _direction direction to seek in
    //  @return next first node beyond &#39;_node&#39; in direction `_direction`
    function getSortedSpotByFunction(LinkedList storage self, uint256 _node, uint256 _value, bool _direction, function (uint, uint) view returns (bool) smallerComparator, int256 searchLimit)
        internal view returns (uint256 nextNodeIndex, bool found, uint256 sizeEnd)
    {
        if ((sizeEnd=sizeOf(self)) == 0) { return (0, true, sizeEnd); }
        require((_node == 0) || nodeExists(self,_node));
        bool exists;
        uint256 next;
        (exists,next) = getAdjacent(self, _node, _direction);
        while  ((--searchLimit >= 0) && (next != 0) && (_value != next) && (smallerComparator(_value, next) != _direction)) next = self.list[next][_direction];
        if(searchLimit >= 0)
            return (next, true, sizeEnd + 1);
        else return (0, false, sizeEnd); //We exhausted the search limit without finding a position!
    }

    /// @dev Creates a bidirectional link between two nodes on direction `_direction`
    /// @param self stored linked list from contract
    /// @param _node first node for linking
    /// @param _link  node to link to in the _direction
    function createLink(LinkedList storage self, uint256 _node, uint256 _link, bool _direction) internal  {
        self.list[_link][!_direction] = _node;
        self.list[_node][_direction] = _link;
    }

    /// @dev Insert node `_new` beside existing node `_node` in direction `_direction`.
    /// @param self stored linked list from contract
    /// @param _node existing node
    /// @param _new  new node to insert
    /// @param _direction direction to insert node in
    function insert(LinkedList storage self, uint256 _node, uint256 _new, bool _direction) internal returns (bool) {
        if(!nodeExists(self,_new) && nodeExists(self,_node)) {
            uint256 c = self.list[_node][_direction];
            createLink(self, _node, _new, _direction);
            createLink(self, _new, c, _direction);
            return true;
        } else {
            return false;
        }
    }
    
    /// @dev removes an entry from the linked list
    /// @param self stored linked list from contract
    /// @param _node node to remove from the list
    function remove(LinkedList storage self, uint256 _node) internal returns (uint256) {
        if ((_node == NULL) || (!nodeExists(self,_node))) { return 0; }
        createLink(self, self.list[_node][PREV], self.list[_node][NEXT], NEXT);
        delete self.list[_node][PREV];
        delete self.list[_node][NEXT];
        return _node;
    }

    /// @dev pushes an enrty to the head of the linked list
    /// @param self stored linked list from contract
    /// @param _node new entry to push to the head
    /// @param _direction push to the head (NEXT) or tail (PREV)
    function push(LinkedList storage self, uint256 _node, bool _direction) internal  {
        insert(self, HEAD, _node, _direction);
    }
    
    /// @dev pops the first entry from the linked list
    /// @param self stored linked list from contract
    /// @param _direction pop from the head (NEXT) or the tail (PREV)
    function pop(LinkedList storage self, bool _direction) internal returns (uint256) {
        bool exists;
        uint256 adj;

        (exists,adj) = getAdjacent(self, HEAD, _direction);

        return remove(self, adj);
    }
}

// ----------------------------------------------------------------------------
// &#39;Coke&#39; token contract
//
// Deployed to : 0xb9907e0151e8c5937f17d0721953cf1ea114528e
// Symbol      : COKE
// Name        : Coke Token
// Total supply: 875 000 000 000 000 micrograms (875 tons)
// Decimals    : 6 (micrograms)
//
// @2018 FC
// ----------------------------------------------------------------------------


// ----------------------------------------------------------------------------
// Safe maths
// ----------------------------------------------------------------------------
contract SafeMath {
    function safeAdd(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >= a && c >= b);
    }
    function safeSub(uint a, uint b) public pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function safeMul(uint a, uint b) public pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function safeDiv(uint a, uint b) public pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
    
    function min(uint x, uint y) internal pure returns (uint z) {
        return x <= y ? x : y;
    }
    function max(uint x, uint y) internal pure returns (uint z) {
        return x >= y ? x : y;
    }
}

contract Mutex {
    bool locked;
    modifier noReentrancy() {
        require(!locked);
        locked = true;
        _;
        locked = false;
    }
}

// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
// ----------------------------------------------------------------------------
contract ERC20Interface {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}


// ----------------------------------------------------------------------------
// Contract function to receive approval and execute function in one call
//
// ----------------------------------------------------------------------------
contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes data) public;
}

// ----------------------------------------------------------------------------
// Owned contract
// ----------------------------------------------------------------------------
contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    function Owned() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

// ----------------------------------------------------------------------------
// Contract "Recoverable", to allow a failsafe in case of user error, so users can recover their mistakenly sent Tokens or Eth
// https://github.com/ethereum/dapp-bin/blob/master/library/recoverable.sol
// ----------------------------------------------------------------------------
contract Recoverable is Owned {
    // ------------------------------------------------------------------------
    // Owner can transfer out any accidentally sent ERC20 tokens
    // ------------------------------------------------------------------------
    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }
    
    // ------------------------------------------------------------------------
    // Owner can transfer out any accidentally sent ETH
    // ------------------------------------------------------------------------
    function recoverLostEth(address toAddress, uint value) public onlyOwner returns (bool success) {
        toAddress.transfer(value);
        return true;
    }
}

/**
 * @title EmergencyProtectedMode
 * @dev Base contract which allows children to implement an emergency stop mechanism different than pausable. Useful for when we want to 
 * stop the normal business of the contract (using the Pausable contract), but still allow some operations like withdrawls for users.
 */
contract EmergencyProtectedMode is Owned {
  event EmergencyProtectedModeActivated();
  event EmergencyProtectedModeDeactivated();

  bool public emergencyProtectedMode = false;

  /**
   * @dev Modifier to make a function callable only when the contract is not paused.
   */
  modifier whenNotInEmergencyProtectedMode() {
    require(!emergencyProtectedMode);
    _;
  }

  /**
   * @dev Modifier to make a function callable only when the contract is paused.
   */
  modifier whenInEmergencyProtectedMode() {
    require(emergencyProtectedMode);
    _;
  }

  /**
   * @dev called by the owner to activate emergency protected mode, triggers stopped state, to use in case of last resort, and stop even last case operations (in case of a security compromise)
   */
  function activateEmergencyProtectedMode() onlyOwner whenNotInEmergencyProtectedMode public {
    emergencyProtectedMode = true;
    emit EmergencyProtectedModeActivated();
  }

  /**
   * @dev called by the owner to deactivate emergency protected mode, returns to normal state
   */
  function deactivateEmergencyProtectedMode() onlyOwner whenInEmergencyProtectedMode public {
    emergencyProtectedMode = false;
    emit EmergencyProtectedModeDeactivated();
  }
}

/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Owned {
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
 * @title Migratable
 * @dev Base contract which allows children to be migratable, that is it allows contracts to migrate to another contract (sucessor) that 
 * is a more advanced version of the previous contract (more functionality, improved security, etc.).
 */
contract Migratable is Owned {
    address public sucessor; //By default, sucessor will be address 0, meaning the current contract is still active and has no sucessor yet!
    function setSucessor(address _sucessor) onlyOwner public {
      sucessor=_sucessor;
    }
}

// ---------------------------------------------------------------------------------------------
// Directly Exchangeable token
// This will allow users to directly exchange between themselves tokens for Eth and vice versa, 
// while having the assurance the other party will be kept to their part of the agreement.
// ---------------------------------------------------------------------------------------------
contract DirectlyExchangeable {
    bool public isRatio; //Should be true if the prices used will be a Ratio, and not just a simple price, otherwise false.

    function sellToConsumer(address consumer, uint quantity, uint price) public returns (bool success);
    function buyFromTrusterDealer(address dealer, uint quantity, uint price) public payable returns (bool success);
    function cancelSellToConsumer(address consumer) public returns (bool success);
    function checkMySellerOffer(address consumer) public view returns (uint quantity, uint price, uint totalWeiCost);
    function checkSellerOffer(address seller) public view returns (uint quantity, uint price, uint totalWeiCost);

    //Events:
    event DirectOfferAvailable(address indexed seller, address indexed buyer, uint quantity, uint price);
    event DirectOfferCancelled(address indexed seller, address indexed consumer, uint quantity, uint price);
    event OrderQuantityMismatch(address indexed addr, uint expectedInRegistry, uint buyerValue);
    event OrderPriceMismatch(address indexed addr, uint expectedInRegistry, uint buyerValue);
}

// ---------------------------------------------------------------------------------------------
// Black Market Sellable token
// This will allow users to sell and buy from a black market, without knowing one another, 
// while having the assurance the other party will keep their part of the agreement.
// ---------------------------------------------------------------------------------------------
contract BlackMarketSellable {
    bool public isRatio; //Should be true if the prices used will be a Ratio, and not just a simple price, otherwise false.

    function sellToBlackMarket(uint quantity, uint price) public returns (bool success, uint numOrderCreated);
    function cancelSellToBlackMarket(uint quantity, uint price, bool continueAfterFirstMatch) public returns (bool success, uint numOrdersCanceled);
    function buyFromBlackMarket(uint quantity, uint priceLimit) public payable returns (bool success, bool partial, uint numOrdersCleared);
    function getSellOrdersBlackMarket() public view returns (uint[] memory r);
    function getSellOrdersBlackMarketComplete() public view returns (uint[] memory quantities, uint[] memory prices);
    function getMySellOrdersBlackMarketComplete() public view returns (uint[] memory quantities, uint[] memory prices);

    //Events:
    event BlackMarketOfferAvailable(uint quantity, uint price);
    event BlackMarketOfferBought(uint quantity, uint price, uint leftOver);
    event BlackMarketNoOfferForPrice(uint price);
    event BlackMarketOfferCancelled(uint quantity, uint price);
    event OrderInsufficientPayment(address indexed addr, uint expectedValue, uint valueReceived);
    event OrderInsufficientBalance(address indexed addr, uint expectedBalance, uint actualBalance);
}

// ----------------------------------------------------------------------------
// ERC20 Token, with the addition of symbol, name and decimals and assisted
// token transfers
// ----------------------------------------------------------------------------
contract Coke is ERC20Interface, Owned, Pausable, EmergencyProtectedMode, Recoverable, Mutex, Migratable, DirectlyExchangeable, BlackMarketSellable, SafeMath {
    string public symbol;
    string public  name;
    uint8 public decimals;
    uint public _totalSupply;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;

    //Needed setup for LinkedList needed for the market:
    using LinkedListLib for LinkedListLib.LinkedList;
    uint256 constant NULL = 0;
    uint256 constant HEAD = 0;
    bool constant PREV = false;
    bool constant NEXT = true;

    //Token specific properties:

    uint16 public constant yearOfProduction = 1997;
    string public constant protectedDenominationOfOrigin = "Colombia";
    string public constant targetDemographics = "The jet set / Top of the tops";
    string public constant securityAudit = "ExtremeAssets Team Ref: XN872 Approved";
    uint buyRatio; //Ratio to buy from the contract directly
    uint sellRatio; //Ratio to sell from the contract directly
    uint private _factorDecimalsEthToToken;
    uint constant undergroundBunkerReserves = 2500000000000;
    mapping(address => uint) changeToReturn; //The change to return to senders (in ETH value (Wei))
    mapping(address => uint) gainsToReceive; //The gains to receive (for sellers) (in ETH value (Wei))
    mapping(address => uint) tastersReceived; //Number of tokens received as a taster for each address
    mapping(address => uint) toFlush; //Keeps address to be flushed (the value stored is the number of the block of when coke can be really flushed from the system)

    event Flushed(address indexed addr);
    event ChangeToReceiveGotten(address indexed addr, uint weiToReceive, uint totalWeiToReceive);
    event GainsGotten(address indexed addr, uint weiToReceive, uint totalWeiToReceive);
    
    struct SellOffer {
        uint price;
        uint quantity;
    }
    struct SellOfferComplete {
        uint price;
        uint quantity;
        address seller;
    }
    mapping(address => mapping(address => SellOffer)) directOffers; //Direct offers
    LinkedListLib.LinkedList blackMarketOffersSorted;
    mapping(uint => SellOfferComplete) public blackMarketOffersMap;
    uint marketOfferCounter = 0; //Counter that will increment for each offer

    uint directOffersComissionRatio = 100; //Ratio of the comission to buy from the contract directly (1%)
    uint marketComissionRatio = 50; //Ratio of the comission to buy from the market (2%)
    int32 maxMarketOffers = 100; //Maximum of market offers at the same time (will only keep the N less costly offers)

    //Message board variables:
    struct Message {
        uint valuePayed;
        string msg;
        address from;
    }
    LinkedListLib.LinkedList topMessagesSorted;
    mapping(uint => Message) public topMessagesMap;
    uint topMessagesCounter = 0; //Counter that will increment for each message
    int32 maxMessagesTop = 20; //Maximum of top messages at the same time (will keep the N most payed messages)
    Message[] messages;
    int32 maxMessagesGlobal = 100; //Maximum number of messages at the same time (will keep the N most recently received messages)
    int32 firstMsgGlobal = 0; //Indexes that will mark the first and the last message received in the array of global messages (revolving array)
    int32 lastMsgGlobal = -1;
    uint maxCharactersMessage = 750; //The maximum of characters a message can have

    event NewMessageAvailable(address indexed from, string message);
    event ExceededMaximumMessageSize(uint messageSize, uint maximumMessageSize); //Message is bigger than maximum allowed characters for each message

    //Addresses to be used for random letItRain!
    address[] lastAddresses;
    int32 maxAddresses = 100; //Maximum number of addresses at the same time (will keep the N most recently mentioned addresses)
    int32 firstAddress = 0; //Indexes that will mark the first and the last address received in the array of last addresses (revolving array)
    int32 lastAddress = -1;
    
    event NoAddressesAvailable();
    
    // ------------------------------------------------------------------------
    // Confirms the user is not in the middle of a flushing process
    // ------------------------------------------------------------------------
    modifier whenNotFlushing() {
        require(toFlush[msg.sender] == 0);
        _;
    }

    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------
    function Coke() public {
        symbol = "Coke";
        name = "100 % Pure Cocaine";
        decimals = 6; //Micrograms
        _totalSupply = 875000000 * (uint(10)**decimals);
        _factorDecimalsEthToToken = uint(10)**(18);
        buyRatio = 10 * (uint(10)**decimals); //10g <- 1 ETH
        sellRatio = 20 * (uint(10)**decimals); //20g -> 1 ETH
        isRatio = true; //Buy and sell prices are ratios (and not simple prices) of how many tokens per 1 ETH
        balances[0] = _totalSupply - undergroundBunkerReserves;
        balances[msg.sender] = undergroundBunkerReserves;
        //blackMarketOffers.length = maxMarketOffers;
        //Do a reservation for msg.sender! Allow rest to be sold by contract!
        emit Transfer(address(0), msg.sender, undergroundBunkerReserves);
    }


    // ------------------------------------------------------------------------
    // Total supply
    // ------------------------------------------------------------------------
    function totalSupply() public constant returns (uint) {
        return _totalSupply /* - balances[address(0)] */;
    }


    // ------------------------------------------------------------------------
    // Get the token balance for account tokenOwner
    // ------------------------------------------------------------------------
    function balanceOf(address tokenOwner) public constant returns (uint balance) {
        return balances[tokenOwner];
    }


    function transferInt(address from, address to, uint tokens, bool updateTasters) internal returns (bool success) {
        if(updateTasters) {
            //Check if sender has received tasters:
            if(tastersReceived[from] > 0) {
                uint tasterTokens = min(tokens, tastersReceived[from]);
                tastersReceived[from] = safeSub(tastersReceived[from], tasterTokens);
                if(to != address(0)) {
                    tastersReceived[to] = safeAdd(tastersReceived[to], tasterTokens);
                }
            }
        }
        balances[from] = safeSub(balances[from], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(from, to, tokens);
        return true;
    }

    // ------------------------------------------------------------------------
    // Transfer the balance from token owner&#39;s account to to account
    // - Owner&#39;s account must have sufficient balance to transfer
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------
    function transfer(address to, uint tokens) public whenNotPaused returns (bool success) {
        return transferInt(msg.sender, to, tokens, true);
    }
    
    // ------------------------------------------------------------------------
    // Token owner can approve for spender to transferFrom(...) tokens
    // from the token owner&#39;s account
    //
    // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
    // recommends that there are no checks for the approval double-spend attack
    // as this should be implemented in user interfaces 
    // ------------------------------------------------------------------------
    function approve(address spender, uint tokens) public whenNotPaused returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }


    // ------------------------------------------------------------------------
    // Transfer tokens from the from account to the to account
    // 
    // The calling account must already have sufficient tokens approve(...)-d
    // for spending from the from account and
    // - From account must have sufficient balance to transfer
    // - Spender must have sufficient allowance to transfer
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------
    function transferFrom(address from, address to, uint tokens) public whenNotPaused returns (bool success) {
        //Update the allowance, the rest it business as usual for the transferInt method:
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
        return transferInt(from, to, tokens, true);
    }


    // ------------------------------------------------------------------------
    // Returns the amount of tokens approved by the owner that can be
    // transferred to the spender&#39;s account
    // ------------------------------------------------------------------------
    function allowance(address tokenOwner, address spender) public constant whenNotPaused returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }


    // ------------------------------------------------------------------------
    // Token owner can approve for spender to transferFrom(...) tokens
    // from the token owner&#39;s account. The spender contract function
    // receiveApproval(...) is then executed
    // ------------------------------------------------------------------------
    function approveAndCall(address spender, uint tokens, bytes data) public whenNotPaused returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, this, data);
        return true;
    }

    // ------------------------------------------------------------------------
    // Calculates the number of tokens (in unsigned integer form [decimals included]) corresponding to the weiValue passed, using the ratio specified
    // ------------------------------------------------------------------------
    function calculateTokensFromWei(uint weiValue, uint ratio) public view returns (uint numTokens) {
        uint calc1 = safeMul(weiValue, ratio);
        uint ethValue = calc1 / _factorDecimalsEthToToken;
        return ethValue;
    }

    // ------------------------------------------------------------------------
    // Calculates the Eth value (in wei) corresponding to the number of tokens passed (in unsigned integer form [decimals included]), using the ratio specified
    // ------------------------------------------------------------------------
    function calculateEthValueFromTokens(uint numTokens, uint ratio) public view returns (uint weiValue) {
        uint calc1 = safeMul(numTokens, _factorDecimalsEthToToken);
        uint retValue = calc1 / ratio;
        return retValue;
    }
    
    // ------------------------------------------------------------------------
    // Will buy tokens corresponding to the Ether sent (Own Token Specific Method)
    // - Contract supply of tokens must have enough balance
    // ------------------------------------------------------------------------
    function buyCoke() public payable returns (bool success) {
        //Calculate tokens corresponding to the Ether sent:
        uint numTokensToBuy = calculateTokensFromWei(msg.value, buyRatio);
        uint finalNumTokensToBuy = numTokensToBuy;
        if(numTokensToBuy > balances[0]) {
            //Adjust number of tokens to buy, to those available in stock:
            finalNumTokensToBuy = balances[0];
            //Update change to return for this sender (in Wei):
            //SAFETY CHECK: No need to use safeSub for (numTokensToBuy - finalNumTokensToBuy), as we already know that numTokensToBuy > finalNumTokensToBuy!
            uint ethValueFromTokens = calculateEthValueFromTokens(numTokensToBuy - finalNumTokensToBuy, buyRatio); //In Wei
            changeToReturn[msg.sender] = safeAdd(changeToReturn[msg.sender], ethValueFromTokens );
            emit ChangeToReceiveGotten(msg.sender, ethValueFromTokens, changeToReturn[msg.sender]);
        }
        if(finalNumTokensToBuy <= balances[0]) {
            /*
            balances[0] = safeSub(balances[0], finalNumTokensToBuy);
            balances[msg.sender] = safeAdd(balances[msg.sender], finalNumTokensToBuy);
            Transfer(address(0), msg.sender, finalNumTokensToBuy);
            */
            transferInt(address(0), msg.sender, finalNumTokensToBuy, false);
            return true;
        }
        else return false;
    }
    
    // ------------------------------------------------------------------------
    // Will show to the user that is asking the change he has to receive
    // ------------------------------------------------------------------------
    function checkChangeToReceive() public view returns (uint changeInWei) {
        return changeToReturn[msg.sender];
    }

    // ------------------------------------------------------------------------
    // Will show to the user that is asking the gains he has to receive
    // ------------------------------------------------------------------------
    function checkGainsToReceive() public view returns (uint gainsInWei) {
        return gainsToReceive[msg.sender];
    }

    // ------------------------------------------------------------------------
    // Will get change in ETH from the tokens that were not possible to buy in a previous order
    // - Contract supply of ETH must have enough balance (which should be in every case)
    // ------------------------------------------------------------------------
    function retrieveChange() public noReentrancy whenNotInEmergencyProtectedMode returns (bool success) {
        uint change = changeToReturn[msg.sender];
        if(change > 0) {
            //Set correct value of change before calling transfer method to avoid reentrance after sending to another contracts:
            changeToReturn[msg.sender] = 0;
            //Send corresponding ETH to sender:
            msg.sender.transfer(change);
            return true;
        }
        else return false;
    }

    // ------------------------------------------------------------------------
    // Will get gains in ETH from the tokens that the seller has previously sold
    // - Contract supply of ETH must have enough balance (which should be in every case)
    // ------------------------------------------------------------------------
    function retrieveGains() public noReentrancy whenNotInEmergencyProtectedMode returns (bool success) {
        uint gains = gainsToReceive[msg.sender];
        if(gains > 0) {
            //Set correct value of "gains to receive" before calling transfer method to avoid reentrance attack after possibly sending to another contract:
            gainsToReceive[msg.sender] = 0;
            //Send corresponding ETH to sender:
            msg.sender.transfer(gains);
            return true;
        }
        else return false;
    }

    // ------------------------------------------------------------------------
    // Will return N bought tokens to the contract
    // - User supply of tokens must have enough balance
    // ------------------------------------------------------------------------
    function returnCoke(uint ugToReturn) public noReentrancy whenNotPaused whenNotFlushing returns (bool success) {
        //require(ugToReturn <= balances[msg.sender]); //Check balance of user
        //Following require not needed anymore, will just pay the difference!
        //require(ugToReturn > tastersReceived[msg.sender]); //Check if the mg to return are greater than the ones received as a taster
        //Maximum possible number of mg to return, have to be lower than the balance of the user minus the tasters received:
        uint finalUgToReturnForEth = min(ugToReturn, safeSub(balances[msg.sender], tastersReceived[msg.sender])); //Subtract tasters received from the total amount to return
        //require(finalUgToReturnForEth <= balances[msg.sender]); //Check balance of user (No need for this extra check, as the minimum garantees at most the value of the balance[] to be returned)
        //Calculate tokens corresponding to the Ether sent:
        uint ethToReturn = calculateEthValueFromTokens(finalUgToReturnForEth, sellRatio); //Ethereum to return (in Wei)
        
        if(ethToReturn > 0) {
            //Will return eth in exchange for the coke!
            //Receive the coke:
            transfer(address(0), finalUgToReturnForEth);
            /*
            balances[0] = safeAdd(balances[0], finalUgToReturnForEth);
            balances[msg.sender] = safeSub(balances[msg.sender], finalUgToReturnForEth);
            Transfer(msg.sender, address(0), finalUgToReturnForEth);
            */
            
            //Return the Eth:
            msg.sender.transfer(ethToReturn);
            return true;
        }
        else return false;
    }

    // ------------------------------------------------------------------------
    // Will return all bought tokens to the contract
    // ------------------------------------------------------------------------
    function returnAllCoke() public returns (bool success) {
        return returnCoke(safeSub(balances[msg.sender], tastersReceived[msg.sender]));
    }

    // ------------------------------------------------------------------------
    // Sends a special taster package to recipient
    // - Contract supply of tokens must have enough balance
    // ------------------------------------------------------------------------
    function sendSpecialTasterPackage(address addr, uint ugToTaste) public whenNotPaused onlyOwner returns (bool success) {
        tastersReceived[addr] = safeAdd(tastersReceived[addr], ugToTaste);
        transfer(addr, ugToTaste);
        return true;
    }

    // ------------------------------------------------------------------------
    // Will transfer to selected address a load of tokens
    // - User supply of tokens must have enough balance
    // ------------------------------------------------------------------------
    function sendShipmentTo(address to, uint tokens) public returns (bool success) {
        return transfer(to, tokens);
    }

    // ------------------------------------------------------------------------
    // Will transfer a small sample to selected address
    // - User supply of tokens must have enough balance
    // ------------------------------------------------------------------------
    function sendTaster(address to) public returns (bool success) {
        //Sending in 0.000002 g (that is 2 micrograms):
        return transfer(to, 2);
    }

    function lengthAddresses() internal view returns (uint) {
        return (firstAddress > 0) ? lastAddresses.length : uint(lastAddress + 1);
    }

    // ------------------------------------------------------------------------
    // Will make it rain! Will throw some tokens from the user to some random addresses, spreading the happiness everywhere!
    // The greater the range, it will supply to addresses further away.
    // - User supply of tokens must have enough balance
    // ------------------------------------------------------------------------
    function letItRain(uint8 range, uint quantity) public returns (bool success) {
        require(quantity <= balances[msg.sender]);
        if(lengthAddresses() == 0) {
            emit NoAddressesAvailable();
            return false;
        }
        bytes32 hashBlock100 = block.blockhash(100); //Get hash of previous 100th block
        bytes32 randomHash = keccak256(keccak256(hashBlock100)); //SAFETY CHECK: Increase difficulty to reverse needed hashBlock100 (in case of attack by the miners)
        byte posAddr = randomHash[1]; //Check position one (to 10, maximum) of randomHash to use for the position(s) in the addresses array
        byte howMany = randomHash[30]; //Check position 30 of randomHash to use for how many addresses base
        
        uint8 posInt = (uint8(posAddr) + range * 2) % uint8(lengthAddresses()); //SAFETY CHECK: lengthAddresses() can&#39;t be greater than 256!!
        uint8 howManyInt = uint8(howMany) % uint8(lengthAddresses()); //SAFETY CHECK: lengthAddresses() can&#39;t be greater than 256!!
        howManyInt = howManyInt > 10 ? 10 : howManyInt; //At maximum distribute to 10 addresses
        howManyInt = howManyInt < 2 ? 2 : howManyInt; //At minimum distribute to 2 addresses
        
        address addr;
        
        uint8 counter = 0;
        uint quant = quantity / howManyInt;
        
        do {
            
            //Distribute to one random address:
            addr = lastAddresses[posInt];
            transfer(addr, quant);
            
            posInt = (uint8(randomHash[1 + counter]) + range * 2) % uint8(lengthAddresses());
            
            counter++;
            
            //SAFETY CHECK: As the integer divisions are truncated (--> (quant * howManyInt) <= quantity (always) ), the following code is not needed:
            /*
            //we have to ensure, in case of uneven division, to just use at maximum the quantity specified by the user:
            if(quantity > quant) {
                quantity = quantity - quant;
            }
            else {
                quant = quantity;
            }
            */
        }
        while(quantity > 0 && counter < howManyInt);
        
        return true;
    }

    // ------------------------------------------------------------------------
    // Method will be used to set a certain number of addresses periodically. These addresses will be the ones to receive randomly the tokens when somebody makes it rain!
    // The list of addresses should be gotten from the main ethereum, by checking for addresses used in the latest transactions.
    // ------------------------------------------------------------------------
    function setAddressesForRain(address[] memory addresses) public onlyOwner returns (bool success) {
        require(addresses.length <= uint(maxAddresses) && addresses.length > 0);
        lastAddresses = addresses;
        firstAddress = 0;
        lastAddress = int32(addresses.length) - 1;
        return true;
    }

    // ------------------------------------------------------------------------
    // Will get the Maximum of addresses to be used for making it rain
    // ------------------------------------------------------------------------
    function getMaxAddresses() public view returns (int32) {
        return maxAddresses;
    }

    // ------------------------------------------------------------------------
    // Will set the Maximum of addresses to be used for making it rain (Maximum of 255 Addresses)
    // ------------------------------------------------------------------------
    function setMaxAddresses(int32 _maxAddresses) public onlyOwner returns (bool success) {
        require(_maxAddresses > 0 && _maxAddresses < 256);
        maxAddresses = _maxAddresses;
        return true;
    }

    // ------------------------------------------------------------------------
    // Will get the Buy Ratio
    // ------------------------------------------------------------------------
    function getBuyRatio() public view returns (uint) {
        return buyRatio;
    }

    // ------------------------------------------------------------------------
    // Will set the Buy Ratio
    // ------------------------------------------------------------------------
    function setBuyRatio(uint ratio) public onlyOwner returns (bool success) {
        require(ratio != 0);
        buyRatio = ratio;
        return true;
    }

    // ------------------------------------------------------------------------
    // Will get the Sell Ratio
    // ------------------------------------------------------------------------
    function getSellRatio() public view returns (uint) {
        return sellRatio;
    }

    // ------------------------------------------------------------------------
    // Will set the Sell Ratio
    // ------------------------------------------------------------------------
    function setSellRatio(uint ratio) public onlyOwner returns (bool success) {
        require(ratio != 0);
        sellRatio = ratio;
        return true;
    }

    // ------------------------------------------------------------------------
    // Will set the Direct Offers Comission Ratio
    // ------------------------------------------------------------------------
    function setDirectOffersComissionRatio(uint ratio) public onlyOwner returns (bool success) {
        require(ratio != 0);
        directOffersComissionRatio = ratio;
        return true;
    }

    // ------------------------------------------------------------------------
    // Will get the Direct Offers Comission Ratio
    // ------------------------------------------------------------------------
    function getDirectOffersComissionRatio() public view returns (uint) {
        return directOffersComissionRatio;
    }

    // ------------------------------------------------------------------------
    // Will set the Market Comission Ratio
    // ------------------------------------------------------------------------
    function setMarketComissionRatio(uint ratio) public onlyOwner returns (bool success) {
        require(ratio != 0);
        marketComissionRatio = ratio;
        return true;
    }

    // ------------------------------------------------------------------------
    // Will get the Market Comission Ratio
    // ------------------------------------------------------------------------
    function getMarketComissionRatio() public view returns (uint) {
        return marketComissionRatio;
    }

    // ------------------------------------------------------------------------
    // Will set the Maximum of Market Offers
    // ------------------------------------------------------------------------
    function setMaxMarketOffers(int32 _maxMarketOffers) public onlyOwner returns (bool success) {
        uint blackMarketOffersSortedSize = blackMarketOffersSorted.sizeOf();
        if(blackMarketOffersSortedSize > uint(_maxMarketOffers)) {
            int32 diff = int32(blackMarketOffersSortedSize - uint(_maxMarketOffers));
            //require(diff < _maxMarketOffers);
            require(diff <= int32(blackMarketOffersSortedSize)); //SAFETY CHECK (recommended because of type conversions)!
            //Do the needed number of Pops to clear the market offers list if _maxMarketOffers (new) < maxMarketOffers (old)
            while  (diff > 0) {
                uint lastOrder = blackMarketOffersSorted.pop(PREV); //Pops element from the Tail!
                delete blackMarketOffersMap[lastOrder];
                diff--;
            }
        }
        
        maxMarketOffers = _maxMarketOffers;
        //blackMarketOffers.length = maxMarketOffers;
        return true;
    }

    // ------------------------------------------------------------------------
    // Internal function to calculate the number of extra blocks needed to flush, depending on the stash to flush (the greater the load, more difficult it will be)
    // ------------------------------------------------------------------------
    function calculateFactorFlushDifficulty(uint stash) internal pure returns (uint extraBlocks) {
        uint numBlocksToFlush = 10;
        uint16 factor;
        if(stash < 1000) {
            factor = 1;
        }
        else if(stash < 5000) {
            factor = 2;
        }
        else if(stash < 10000) {
            factor = 3;
        }
        else if(stash < 100000) {
            factor = 4;
        }
        else if(stash < 1000000) {
            factor = 5;
        }
        else if(stash < 10000000) {
            factor = 10;
        }
        else if(stash < 100000000) {
            factor = 50;
        }
        else if(stash < 1000000000) {
            factor = 500;
        }
        else {
            factor = 5000;
        }
        return numBlocksToFlush * factor;
    }

    // ------------------------------------------------------------------------
    // Throws away your stash (down the drain ;) ) immediately.
    // ------------------------------------------------------------------------
    function downTheDrainImmediate() internal returns (bool success) {
            //Clean any flushing that it still had if possible:
            toFlush[msg.sender] = 0;
            //Transfer to contract all the balance:
            transfer(address(0), balances[msg.sender]);
            tastersReceived[msg.sender] = 0;
            emit Flushed(msg.sender);
            return true;
    }
    
    // ------------------------------------------------------------------------
    // Throws away your stash (down the drain ;) ). It can take awhile to be completely flushed. You can send in 0.01 ether to speed up this process.
    // ------------------------------------------------------------------------
    function downTheDrain() public whenNotPaused payable returns (bool success) {
        if(msg.value < 0.01 ether) {
            //No hurry, will use default method to flush the coke (will take some time)
            toFlush[msg.sender] = block.number + calculateFactorFlushDifficulty(balances[msg.sender]);
            return true;
        }
        else return downTheDrainImmediate();
    }

    // ------------------------------------------------------------------------
    // Checks if the dump is complete and we can flush the whole stash!
    // ------------------------------------------------------------------------
    function flush() public whenNotPaused returns (bool success) {
        //Current block number is already greater than the limit to be flushable?
        if(block.number >= toFlush[msg.sender]) {
            return downTheDrainImmediate();
        }
        else return false;
    }
    
    
    // ------------------------------------------------------------------------
    // Comparator used to compare priceRatios inside the LinkedList
    // ------------------------------------------------------------------------
    function smallerPriceComparator(uint priceNew, uint nodeNext) internal view returns (bool success) {
        //When comparing ratios the smaller one will be the one with the greater ratio (cheaper price):
        //return priceNew < blackMarketOffersMap[nodeNext].price;
        return priceNew > blackMarketOffersMap[nodeNext].price; //If priceNew ratio is greater, it means it is a cheaper offer!
    }
    
    // ------------------------------------------------------------------------
    // Put order on the blackmarket to sell a certain quantity of coke at a certain price.
    // The price ratio is how much micrograms (ug) of material (tokens) the buyer will get per ETH (ug/ETH) (for example, to get 10g for 1 ETH, the ratio should be 10000000)
    // For sellers the lower the ratio the better, the more ETH the buyer will need to spend to get each token!
    // - Seller must have enough balance of tokens
    // ------------------------------------------------------------------------
    function sellToBlackMarket(uint quantity, uint priceRatio) public whenNotPaused whenNotFlushing returns (bool success, uint numOrderCreated) {
        //require(quantity <= balances[msg.sender]block.number >= toFlush[msg.sender]);
        //CHeck if user has sufficient balance to do a sell offer:
        if(quantity > balances[msg.sender]) {
            //Seller is missing funds: Abort order:
            emit OrderInsufficientBalance(msg.sender, quantity, balances[msg.sender]);
            return (false, 0);
        }

        //Insert order in the sorted list (from cheaper to most expensive)

        //Find an offer that is more expensive:
        //nodeMoreExpensive = 
        uint nextSpot;
        bool foundPosition;
        uint sizeNow;
        (nextSpot, foundPosition, sizeNow) = blackMarketOffersSorted.getSortedSpotByFunction(HEAD, priceRatio, NEXT, smallerPriceComparator, maxMarketOffers);
        if(foundPosition) {
            //Create new Sell Offer:
            uint newNodeNum = ++marketOfferCounter; //SAFETY CHECK: Doesn&#39;t matter if we cycle again from MAX_INT to 0, as we have only 100 maximum offers at a time, so there will never be some overwriting of valid offers!
            blackMarketOffersMap[newNodeNum].quantity = quantity;
            blackMarketOffersMap[newNodeNum].price = priceRatio;
            blackMarketOffersMap[newNodeNum].seller = msg.sender;
            
            //Insert cheaper offer before nextSpot:
            blackMarketOffersSorted.insert(nextSpot, newNodeNum, PREV);
    
            if(int32(sizeNow) > maxMarketOffers) {
                //Delete the tail element so we can keep the same number of max market offers:
                uint lastIndex = blackMarketOffersSorted.pop(PREV); //Pops and removes last element of the list!
                delete blackMarketOffersMap[lastIndex];
            }
            
            emit BlackMarketOfferAvailable(quantity, priceRatio);
            return (true, newNodeNum);
        }
        else {
            return (false, 0);
        }
    }
    
    // ------------------------------------------------------------------------
    // Cancel order on the blackmarket to sell a certain quantity of coke at a certain price.
    // If the seller has various order with the same quantity and priceRatio, and can put parameter "continueAfterFirstMatch" to true, 
    // so it will continue and cancel all those black market orders.
    // ------------------------------------------------------------------------
    function cancelSellToBlackMarket(uint quantity, uint priceRatio, bool continueAfterFirstMatch) public whenNotPaused returns (bool success, uint numOrdersCanceled) {
        //Get first node:
        bool exists;
        bool matchFound = false;
        uint offerNodeIndex;
        uint offerNodeIndexToProcess;
        (exists, offerNodeIndex) = blackMarketOffersSorted.getAdjacent(HEAD, NEXT);
        if(!exists)
            return (false, 0); //Black Market is empty of offers!

        do {

            offerNodeIndexToProcess = offerNodeIndex; //Store the current index that is being processed!
            (exists, offerNodeIndex) = blackMarketOffersSorted.getAdjacent(offerNodeIndex, NEXT); //Get next node
            //Analyse current node, to see if it is the one to cancel:
            if(   blackMarketOffersMap[offerNodeIndexToProcess].seller == msg.sender 
               && blackMarketOffersMap[offerNodeIndexToProcess].quantity == quantity
               && blackMarketOffersMap[offerNodeIndexToProcess].price == priceRatio) {
                   //Cancel current offer:
                   blackMarketOffersSorted.remove(offerNodeIndexToProcess);
                   delete blackMarketOffersMap[offerNodeIndexToProcess];
                   matchFound = true;
                   numOrdersCanceled++;
                   success = true;
                    emit BlackMarketOfferCancelled(quantity, priceRatio);
            }
            else {
                matchFound = false;
            }
            
        }
        while(offerNodeIndex != NULL && exists && (!matchFound || continueAfterFirstMatch));
        
        return (success, numOrdersCanceled);
    }
    
    function calculateAndUpdateGains(SellOfferComplete offerThisRound) internal returns (uint) {
        //Calculate values to be payed for this seller:
        uint weiToBePayed = calculateEthValueFromTokens(offerThisRound.quantity, offerThisRound.price);

        //Calculate fees and values to distribute:
        uint fee = safeDiv(weiToBePayed, marketComissionRatio);
        uint valueForSeller = safeSub(weiToBePayed, fee);

        //Update change values (seller will have to retrieve his/her gains by calling method "retrieveGains" to receive the Eth)
        gainsToReceive[offerThisRound.seller] = safeAdd(gainsToReceive[offerThisRound.seller], valueForSeller);
        emit GainsGotten(offerThisRound.seller, valueForSeller, gainsToReceive[offerThisRound.seller]);

        return weiToBePayed;
    }

    function matchOffer(uint quantity, uint nodeIndex, SellOfferComplete storage offer) internal returns (bool exists, uint offerNodeIndex, uint quantityRound, uint weiToBePayed, bool cleared) {
        uint quantityToCheck = min(quantity, offer.quantity); //Quantity to check for this seller offer)
        SellOfferComplete memory offerThisRound = offer;
        bool forceRemovalOffer = false;

        //Check token balance of seller:
        if(balances[offerThisRound.seller] < quantityToCheck) {
            //Invalid offer now, user no longer has sufficient balance
            quantityToCheck = balances[offerThisRound.seller];

            //Seller will no longer have balance: Clear offer from market!
            forceRemovalOffer = true;
        }

        offerThisRound.quantity = quantityToCheck;

        if(offerThisRound.quantity > 0) {
            //Seller of this offer will receive his Ether:

            //Calculate and update gains:
            weiToBePayed = calculateAndUpdateGains(offerThisRound);

            //Update current offer:
            offer.quantity = safeSub(offer.quantity, offerThisRound.quantity);
            
            //Emit event to signal an order was bought:
            emit BlackMarketOfferBought(offerThisRound.quantity, offerThisRound.price, offer.quantity);
            
            //Transfer tokens between seller and buyer:
            //SAFETY CHECK: No more transactions are made to other contracts!
            transferInt(offer.seller, msg.sender /* buyer */, offerThisRound.quantity, true);
        }
        
        //Keep a copy of next node:
        (exists, offerNodeIndex) = blackMarketOffersSorted.getAdjacent(nodeIndex, NEXT);
        
        //Check if current offer was completely fullfulled and remove it from market:
        if(forceRemovalOffer || offer.quantity == 0) {
            //Seller no longer has balance: Clear offer from market!
            //Or Seller Offer was completely fulfilled
            
            //Delete the first element so we can remove current order from the market:
            uint firstIndex = blackMarketOffersSorted.pop(NEXT); //Pops and removes first element of the list!
            delete blackMarketOffersMap[firstIndex];
            
            cleared = true;
        }
        
        quantityRound = offerThisRound.quantity;

        return (exists, offerNodeIndex, quantityRound, weiToBePayed, cleared);
    }

    // ------------------------------------------------------------------------
    // Put order on the blackmarket to sell a certain quantity of coke at a certain price.
    // The price ratio is how much micrograms (ug) of material (tokens) the buyer will get per ETH (ug/ETH) (for example, to get 10g for 1 ETH, the ratio should be 10000000)
    // For buyers the higher the ratio the better, the more they get!
    // - Buyer must have sent enough payment for the buy he wants
    // - If buyer sends more than needed, it will be available for him to get it back as change (through the retrieveChange method)
    // - Gains of sellers will be available through the retrieveGains method
    // ------------------------------------------------------------------------
    function buyFromBlackMarket(uint quantity, uint priceRatioLimit) public payable whenNotPaused whenNotFlushing noReentrancy returns (bool success, bool partial, uint numOrdersCleared) {
        numOrdersCleared = 0;
        partial = false;

        //Get cheapest offer on the market right now:
        bool exists;
        bool cleared = false;
        uint offerNodeIndex;
        (exists, offerNodeIndex) = blackMarketOffersSorted.getAdjacent(HEAD, NEXT);
        if(!exists) {
            //Abort buy from market!
            revert(); //Return Eth to buyer!
            //Maybe in the future, put the buyer offer in a buyer&#39;s offers list!
            //TODO: IMPROVEMENTS!
        }
        SellOfferComplete storage offer = blackMarketOffersMap[offerNodeIndex];
        
        uint totalToBePayedWei = 0;
        uint weiToBePayedRound = 0;
        uint quantityRound = 0;

        //When comparing ratios the smaller one will be the one with the greater ratio (cheaper price):
        //if(offer.price > priceRatioLimit) {
        if(offer.price < priceRatioLimit) {
            //Abort buy from market! Not one sell offer is cheaper than the priceRatioLimit
            //BlackMarketNoOfferForPrice(priceRatioLimit);
            //return (false, 0);
            revert(); //Return Eth to buyer!
            //Maybe in the future, put the buyer offer in a buyer&#39;s offers list!
            //TODO: IMPROVEMENTS!
        }
        
        bool abort = false;
        //Cycle through market seller offers:
        do {
        
            (exists /* Exists next offer to match */, 
             offerNodeIndex, /* Node index for Next Offer */
             quantityRound, /* Quantity that was matched in this round */
             weiToBePayedRound, /* Wei that was used to pay for this round */
             cleared /* Offer was completely fulfilled and was cleared! */
             ) = matchOffer(quantity, offerNodeIndex, offer);
            
            if(cleared) {
                numOrdersCleared++;
            }
    
            //Update total to be payed (in Wei):
            totalToBePayedWei = safeAdd(totalToBePayedWei, weiToBePayedRound);
    
            //Update quantity (still missing to be satisfied):
            quantity = safeSub(quantity, quantityRound);
    
            //Check if buyer send enough balance to buy the orders:        
            if(totalToBePayedWei > msg.value) {
                emit OrderInsufficientPayment(msg.sender, totalToBePayedWei, msg.value);
                //Abort transaction!:
                revert(); //Revert transaction, so Eth send are not transferred, and go back to user!
                //TODO: IMPROVEMENTS!
                //TODO: Improvements to allow a partial buy, if not possible to buy all!
            }

            //Confirm if next node exists:
            if(offerNodeIndex != NULL) {
    
                //Get Next Node (More Info):
                offer = blackMarketOffersMap[offerNodeIndex];
    
                //Check if next order is above the priceRatioLimit set by the buyer:            
                //When comparing ratios the smaller one will be the one with the greater ratio (cheaper price):
                //if(offer.price > priceRatioLimit) {
                if(offer.price < priceRatioLimit) {
                    //Abort buying more from the seller&#39;s market:
                    abort = true;
                    partial = true; //Partial buy order done! (no sufficient seller offer&#39;s below the priceRatioLimit)
                    //Maybe in the future, put the buyer offer in a buyer&#39;s offers list!
                    //TODO: IMPROVEMENTS!
                }
            }
            else {
                //Abort buying more from the seller&#39;s market (the end was reached!):
                abort = true;
            }
        }
        while (exists && quantity > 0 && !abort);
        //End Cycle through orders!

        //Final operations after checking all orders:
        if(totalToBePayedWei < msg.value) {
            //Give change back to the buyer:
            //Return change to the buyer (sender of the message in this case)
            changeToReturn[msg.sender] = safeAdd(changeToReturn[msg.sender], msg.value - totalToBePayedWei); //SAFETY CHECK: No need to use safeSub, as we already know that "msg.value" > "totalToBePayedWei"!
            emit ChangeToReceiveGotten(msg.sender, msg.value - totalToBePayedWei, changeToReturn[msg.sender]);
        }

        return (true, partial, numOrdersCleared);
    }
    
    // ------------------------------------------------------------------------
    // Gets the list of orders on the black market (ordered by cheapest to expensive).
    // ------------------------------------------------------------------------
    function getSellOrdersBlackMarket() public view returns (uint[] memory r) {
        r = new uint[](blackMarketOffersSorted.sizeOf());
        bool exists;
        uint prev;
        uint elem;
        (exists, prev, elem) = blackMarketOffersSorted.getNode(HEAD);
        if(exists) {
            uint size = blackMarketOffersSorted.sizeOf();
            for (uint i = 0; i < size; i++) {
              r[i] = elem;
              (exists, elem) = blackMarketOffersSorted.getAdjacent(elem, NEXT);
            }
        }
    }
    
    // ------------------------------------------------------------------------
    // Gets the list of orders on the black market (ordered by cheapest to expensive).
    // WARNING: Not Supported by Remix or Web3!! (Structure Array returns)
    // ------------------------------------------------------------------------
    /*
    function getSellOrdersBlackMarketComplete() public view returns (SellOffer[] memory r) {
        r = new SellOffer[](blackMarketOffersSorted.sizeOf());
        bool exists;
        uint prev;
        uint elem;
        (exists, prev, elem) = blackMarketOffersSorted.getNode(HEAD);
        if(exists) {
            for (uint i = 0; i < blackMarketOffersSorted.sizeOf(); i++) {
                SellOfferComplete storage offer = blackMarketOffersMap[elem];
                r[i].quantity = offer.quantity;
                r[i].price = offer.price;
                (exists, elem) = blackMarketOffersSorted.getAdjacent(elem, NEXT);
            }
        }
    }
    */
    function getSellOrdersBlackMarketComplete() public view returns (uint[] memory quantities, uint[] memory prices) {
        quantities = new uint[](blackMarketOffersSorted.sizeOf());
        prices = new uint[](blackMarketOffersSorted.sizeOf());
        bool exists;
        uint prev;
        uint elem;
        (exists, prev, elem) = blackMarketOffersSorted.getNode(HEAD);
        if(exists) {
            uint size = blackMarketOffersSorted.sizeOf();
            for (uint i = 0; i < size; i++) {
                SellOfferComplete storage offer = blackMarketOffersMap[elem];
                quantities[i] = offer.quantity;
                prices[i] = offer.price;
                //Get next element:
                (exists, elem) = blackMarketOffersSorted.getAdjacent(elem, NEXT);
            }
        }
    }

    function getMySellOrdersBlackMarketComplete() public view returns (uint[] memory quantities, uint[] memory prices) {
        quantities = new uint[](blackMarketOffersSorted.sizeOf());
        prices = new uint[](blackMarketOffersSorted.sizeOf());
        bool exists;
        uint prev;
        uint elem;
        (exists, prev, elem) = blackMarketOffersSorted.getNode(HEAD);
        if(exists) {
            uint size = blackMarketOffersSorted.sizeOf();
            uint j = 0;
            for (uint i = 0; i < size; i++) {
                SellOfferComplete storage offer = blackMarketOffersMap[elem];
                if(offer.seller == msg.sender) {
                    quantities[j] = offer.quantity;
                    prices[j] = offer.price;
                    j++;
                }
                //Get next element:
                (exists, elem) = blackMarketOffersSorted.getAdjacent(elem, NEXT);
            }
        }
        //quantities.length = j; //Memory Arrays can&#39;t be returned with dynamic size, we have to create arrays with a fixed size to be returned!
        //prices.length = j;
    }

    // ------------------------------------------------------------------------
    // Puts an offer on the market to a specific user (if an offer from the same seller to the same consumer already exists, the latest offer will replace it)
    // The price ratio is how much micrograms (ug) of material (tokens) the buyer will get per ETH (ug/ETH)
    // ------------------------------------------------------------------------
    function sellToConsumer(address consumer, uint quantity, uint priceRatio) public whenNotPaused whenNotFlushing returns (bool success) {
        require(consumer != address(0) && quantity > 0 && priceRatio > 0);
        //Mark offer to sell to consumer on registry:
        SellOffer storage offer = directOffers[msg.sender][consumer];
        offer.quantity = quantity;
        offer.price = priceRatio;
        emit DirectOfferAvailable(msg.sender, consumer, offer.quantity, offer.price);
        return true;
    }
    
    // ------------------------------------------------------------------------
    // Puts an offer on the market to a specific user
    // The price ratio is how much micrograms (ug) of material (tokens) the buyer will get per ETH (ug/ETH)
    // ------------------------------------------------------------------------
    function cancelSellToConsumer(address consumer) public whenNotPaused returns (bool success) {
        //Check if order exists with the correct values:
        SellOffer memory sellOffer = directOffers[msg.sender][consumer];
        if(sellOffer.quantity > 0 || sellOffer.price > 0) {
            //We found matching sell to consumer, delete it to cancel it!
            delete directOffers[msg.sender][consumer];
            emit DirectOfferCancelled(msg.sender, consumer, sellOffer.quantity, sellOffer.price);
            return true;
        }
        return false;
    }

    // ------------------------------------------------------------------------
    // Checks a seller offer from the seller side
    // The price ratio is how much micrograms (ug) of material (tokens) the buyer will get per ETH (ug/ETH)
    // ------------------------------------------------------------------------
    function checkMySellerOffer(address consumer) public view returns (uint quantity, uint priceRatio, uint totalWeiCost) {
        quantity = directOffers[msg.sender][consumer].quantity;
        priceRatio = directOffers[msg.sender][consumer].price;
        totalWeiCost = calculateEthValueFromTokens(quantity, priceRatio); //Value to be payed by the buyer (in Wei)
    }

    // ------------------------------------------------------------------------
    // Checks a seller offer to the user. Method used by the buyer to check an offer (direct offer) from a seller to him/her and to see 
    // how much he/she will have to pay for it (in Wei).
    // The price ratio is how much micrograms (ug) of material (tokens) the buyer will get per ETH (ug/ETH)
    // ------------------------------------------------------------------------
    function checkSellerOffer(address seller) public view returns (uint quantity, uint priceRatio, uint totalWeiCost) {
        quantity = directOffers[seller][msg.sender].quantity;
        priceRatio = directOffers[seller][msg.sender].price;
        totalWeiCost = calculateEthValueFromTokens(quantity, priceRatio); //Value to be payed by the buyer (in Wei)
    }
    
    // ------------------------------------------------------------------------
    // Buys from a trusted dealer.
    // The buyer has to send the needed Ether to pay for the quantity of material specified at that priceRatio (the buyer can use 
    // checkSellerOffer(), and input the seller address to know the quantity and priceRatio specified and also, of course, how much Ether in Wei
    // he/she will have to pay for it).
    // The price ratio is how much micrograms (ug) of material (tokens) the buyer will get per ETH (ug/ETH)
    // ------------------------------------------------------------------------
    function buyFromTrusterDealer(address dealer, uint quantity, uint priceRatio) public payable noReentrancy whenNotPaused returns (bool success) {
        //Check up on offer:
        require(directOffers[dealer][msg.sender].quantity > 0 && directOffers[dealer][msg.sender].price > 0); //Offer exists?
        if(quantity > directOffers[dealer][msg.sender].quantity) {
            emit OrderQuantityMismatch(dealer, directOffers[dealer][msg.sender].quantity, quantity);
            changeToReturn[msg.sender] = safeAdd(changeToReturn[msg.sender], msg.value); //Operation aborted: The buyer can get its ether back by using retrieveChange().
            emit ChangeToReceiveGotten(msg.sender, msg.value, changeToReturn[msg.sender]);
            return false;
        }
        if(directOffers[dealer][msg.sender].price != priceRatio) {
            emit OrderPriceMismatch(dealer, directOffers[dealer][msg.sender].price, priceRatio);
            changeToReturn[msg.sender] = safeAdd(changeToReturn[msg.sender], msg.value); //Operation aborted: The buyer can get its ether back by using retrieveChange().
            emit ChangeToReceiveGotten(msg.sender, msg.value, changeToReturn[msg.sender]);
            return false;
        }
        
        //Offer valid, start buying proccess:
        
        //Get values to be payed:
        uint weiToBePayed = calculateEthValueFromTokens(quantity, priceRatio);
        
        //Check eth payment from buyer:
        if(msg.value < weiToBePayed) {
            emit OrderInsufficientPayment(msg.sender, weiToBePayed, msg.value);
            changeToReturn[msg.sender] = safeAdd(changeToReturn[msg.sender], msg.value); //Operation aborted: The buyer can get its ether back by using retrieveChange().
            emit ChangeToReceiveGotten(msg.sender, msg.value, changeToReturn[msg.sender]);
            return false;
        }
        
        //Check balance from seller:
        if(quantity > balances[dealer]) {
            //Seller is missing funds: Abort order:
            emit OrderInsufficientBalance(dealer, quantity, balances[dealer]);
            changeToReturn[msg.sender] = safeAdd(changeToReturn[msg.sender], msg.value); //Operation aborted: The buyer can get its ether back by using retrieveChange().
            emit ChangeToReceiveGotten(msg.sender, msg.value, changeToReturn[msg.sender]);
            return false;
        }
        
        //Update balances of seller/buyer:
        balances[dealer] = balances[dealer] - quantity; //SAFETY CHECK: No need to use safeSub, as we already know that "balances[dealer]" >= "quantity"!
        balances[msg.sender] = safeAdd(balances[msg.sender], quantity);
        emit Transfer(dealer, msg.sender, quantity);

        //Update direct offers registry:
        if(quantity < directOffers[dealer][msg.sender].quantity) {
            //SAFETY CHECK: No need to use safeSub, as we already know that "directOffers[dealer][msg.sender].quantity" > "quantity"!
            directOffers[dealer][msg.sender].quantity = directOffers[dealer][msg.sender].quantity - quantity;
        }
        else {
            //Remove offer from registry (order completely filled)
            delete directOffers[dealer][msg.sender];
        }

        //Receive payment from one user and send it to another, minus the comission:
        //Calculate fees and values to distribute:
        uint fee = safeDiv(weiToBePayed, directOffersComissionRatio);
        uint valueForSeller = safeSub(weiToBePayed, fee);
        
        //SAFETY CHECK: Possible Denial of Service, by putting a fallback function impossible to run: No problem! As this is a direct offer between two users, if it doesn&#39;t work the first time, the user can just ignore the offer!
        //SAFETY CHECK: No Reentrancy possible: Modifier active!
        //SAFETY CHECK: Balances are all updated before transfer, and offer is removed/updated too! Only change is updated later, which is good as user can only retrieve the funds after this operations finishes with success!
        dealer.transfer(valueForSeller);

        //Set change to the buyer if he sent extra eth:
        uint changeToGive = safeSub(msg.value, weiToBePayed);

        if(changeToGive > 0) {
            //Update change values (user will have to retrieve the change calling method "retrieveChange" to receive the Eth)
            changeToReturn[msg.sender] = safeAdd(changeToReturn[msg.sender], changeToGive);
            emit ChangeToReceiveGotten(msg.sender, changeToGive, changeToReturn[msg.sender]);
        }

        return true;
    }
    
    /****************************************************************************
    // Message board management functions
    //***************************************************************************/

    // ------------------------------------------------------------------------
    // Comparator used to compare Eth payed for a message inside the top messages LinkedList
    // ------------------------------------------------------------------------
    function greaterPriceMsgComparator(uint valuePayedNew, uint nodeNext) internal view returns (bool success) {
        return valuePayedNew > (topMessagesMap[nodeNext].valuePayed);
    }
    
    // ------------------------------------------------------------------------
    // Place a message in the Message Board
    // The latest messages will be shown on the message board (usually it should display the 100 latest messages)
    // User can also spend some wei to put the message in the top 10/20 of messages, ordered by the most payed to the least payed.
    // ------------------------------------------------------------------------
    function placeMessage(string message, bool anon) public payable whenNotPaused returns (bool success, uint numMsgTop) {
        uint msgSize = bytes(message).length;
        if(msgSize > maxCharactersMessage) { //Check number of bytes of message
            //Message is bigger than maximum allowed: Reject message!
            emit ExceededMaximumMessageSize(msgSize, maxCharactersMessage);
            
            if(msg.value > 0) { //We have Eth to return, so we will return it!
                revert(); //Cancel transaction and Return Eth!
            }
            return (false, 0);
        }

        //Insert message in the sorted list (from most to least expensive) of top messages
        //If the value payed is enough for it to reach the top

        //Find an offer that is cheaper:
        //nodeLessExpensive = 
        uint nextSpot;
        bool foundPosition;
        uint sizeNow;
        (nextSpot, foundPosition, sizeNow) = topMessagesSorted.getSortedSpotByFunction(HEAD, msg.value, NEXT, greaterPriceMsgComparator, maxMessagesTop);
        if(foundPosition) {

            //Create new Message:
            uint newNodeNum = ++topMessagesCounter; //SAFETY CHECK: Doesn&#39;t matter if we cycle again from MAX_INT to 0, as we have only 10/20/100 maximum messages at a time, so there will never be some overwriting of valid offers!
            topMessagesMap[newNodeNum].valuePayed = msg.value;
            topMessagesMap[newNodeNum].msg = message;
            topMessagesMap[newNodeNum].from = anon ? address(0) : msg.sender;
            
            //Insert more expensive message before nextSpot:
            topMessagesSorted.insert(nextSpot, newNodeNum, PREV);
    
            if(int32(sizeNow) > maxMessagesTop) {
                //Delete the tail element so we can keep the same number of max top messages:
                uint lastIndex = topMessagesSorted.pop(PREV); //Pops and removes last element of the list!
                delete topMessagesMap[lastIndex];
            }
            
        }
        
        //Place message in the most recent messages (Will always be put here, even if the value payed is zero! Will only be ordered by time, from older to most recent):
        insertMessage(message, anon);

        emit NewMessageAvailable(anon ? address(0) : msg.sender, message);
        
        return (true, newNodeNum);
    }

    function lengthMessages() internal view returns (uint) {
        return (firstMsgGlobal > 0) ? messages.length : uint(lastMsgGlobal + 1);
    }

    function insertMessage(string message, bool anon) internal {
        Message memory newMsg;
        bool insertInLastPos = false;
        newMsg.valuePayed = msg.value;
        newMsg.msg = message;
        newMsg.from = anon ? address(0) : msg.sender;
        
        if(((lastMsgGlobal + 1) >= int32(messages.length) && int32(messages.length) < maxMessagesGlobal)) {
            //Still have space in the messages array, add new message at the end:
            messages.push(newMsg);
            //lastMsgGlobal++;
        } else {
            //Messages array is full, start rotating through it:
            insertInLastPos = true; 
        }
        
        //Rotating indexes in case we reach the end of the array!
        uint sizeMessages = lengthMessages(); //lengthMessages() depends on lastMsgGlobal, se we have to keep a temporary copy first!
        lastMsgGlobal = (lastMsgGlobal + 1) % maxMessagesGlobal; 
        if(lastMsgGlobal <= firstMsgGlobal && sizeMessages > 0) {
            firstMsgGlobal = (firstMsgGlobal + 1) % maxMessagesGlobal;
        }
        
        if(insertInLastPos) {
            messages[uint(lastMsgGlobal)] = newMsg;
        }
    }
    
    function strConcat(string _a, string _b, string _c) internal pure returns (string){
        bytes memory _ba = bytes(_a);
        bytes memory _bb = bytes(_b);
        bytes memory _bc = bytes(_c);
        string memory ab = new string(_ba.length + _bb.length + _bc.length);
        bytes memory ba = bytes(ab);
        uint k = 0;
        for (uint i = 0; i < _ba.length; i++) ba[k++] = _ba[i];
        for (i = 0; i < _bb.length; i++) ba[k++] = _bb[i];
        for (i = 0; i < _bc.length; i++) ba[k++] = _bc[i];
        return string(ba);
    }

    // ------------------------------------------------------------------------
    // Place a message in the Message Board
    // The latest messages will be shown on the message board (usually it should display the 100 latest messages)
    // User can also spend some wei to put the message in the top 10/20 of messages, ordered by the most payed to the least payed.
    // ------------------------------------------------------------------------
    function getMessages() public view returns (string memory r) {
        uint countMsg = lengthMessages(); //Take into account if messages was reset, and no new messages have been inserted until now!
        uint indexMsg = uint(firstMsgGlobal);
        bool first = true;
        while(countMsg > 0) {
            if(first) {
                r = messages[indexMsg].msg;
                first = false;
            }
            else {
                r = strConcat(r, " <||> ", messages[indexMsg].msg);
            }
            
            indexMsg = (indexMsg + 1) % uint(maxMessagesGlobal);
            countMsg--;
        }

        return r;
    }

    // ------------------------------------------------------------------------
    // Will set the Maximum of Global Messages
    // ------------------------------------------------------------------------
    function setMaxMessagesGlobal(int32 _maxMessagesGlobal) public onlyOwner returns (bool success) {
        if(_maxMessagesGlobal < maxMessagesGlobal) {
            //New value will be shorter than old value: reset values:
            //messages.clear(); //No need to clear the array completely (costs gas!): Just reinitialize the pointers!
            //lastMsgGlobal = firstMsgGlobal > 0 ? int32(messages.length) - 1 : lastMsgGlobal; //The last position will specify the real size of the array, that is, until the firstMsgGlobal is greater than zero, at that time we know the array is full, so the real size is the size of the complete array!
            lastMsgGlobal = int32(lengthMessages()) - 1; //The last position will specify the real size of the array, that is, until the firstMsgGlobal is greater than zero, at that time we know the array is full, so the real size is the size of the complete array!
            if(lastMsgGlobal != -1 && lastMsgGlobal > (int32(_maxMessagesGlobal) - 1)) {
                lastMsgGlobal = int32(_maxMessagesGlobal) - 1;
            }
            firstMsgGlobal = 0;
            messages.length = uint(_maxMessagesGlobal);
        }
        maxMessagesGlobal = _maxMessagesGlobal;
        return true;
    }

    // ------------------------------------------------------------------------
    // Will set the Maximum of Top Messages (usually Top 10 / 20)
    // ------------------------------------------------------------------------
    function setMaxMessagesTop(int32 _maxMessagesTop) public onlyOwner returns (bool success) {
        uint topMessagesSortedSize = topMessagesSorted.sizeOf();
        if(topMessagesSortedSize > uint(_maxMessagesTop)) {
            int32 diff = int32(topMessagesSortedSize - uint(_maxMessagesTop));
            require(diff <= int32(topMessagesSortedSize)); //SAFETY CHECK (recommended because of type conversions)!
            //Do the needed number of Pops to clear the top message list if _maxMessagesTop (new) < maxMessagesTop (old)
            while  (diff > 0) {
                uint lastMsg = topMessagesSorted.pop(PREV); //Pops element from the Tail!
                delete topMessagesMap[lastMsg];
                diff--;
            }
        }
        
        maxMessagesTop = _maxMessagesTop;
        return true;
    }

    // ------------------------------------------------------------------------
    // Gets the list of top 10 messages (ordered by most payed to least payed).
    // ------------------------------------------------------------------------
    function getTop10Messages() public view returns (string memory r) {
        bool exists;
        uint prev;
        uint elem;
        bool first = true;
        (exists, prev, elem) = topMessagesSorted.getNode(HEAD);
        if(exists) {
            uint size = min(topMessagesSorted.sizeOf(), 10);
            for (uint i = 0; i < size; i++) {
                if(first) {
                    r = topMessagesMap[elem].msg;
                    first = false;
                }
                else {
                    r = strConcat(r, " <||> ", topMessagesMap[elem].msg);
                }
                (exists, elem) = topMessagesSorted.getAdjacent(elem, NEXT);
            }
        }
        
        return r;
    }
    
    // ------------------------------------------------------------------------
    // Gets the list of top 11 to 20 messages (ordered by most payed to least payed).
    // ------------------------------------------------------------------------
    function getTop11_20Messages() public view returns (string memory r) {
        bool exists;
        uint prev;
        uint elem;
        bool first = true;
        (exists, prev, elem) = topMessagesSorted.getNode(HEAD);
        if(exists) {
            uint size = min(topMessagesSorted.sizeOf(), uint(maxMessagesTop));
            for (uint i = 0; i < size; i++) {
                if(i >= 10) {
                    if(first) {
                        r = topMessagesMap[elem].msg;
                        first = false;
                    }
                    else {
                        r = strConcat(r, " <||> ", topMessagesMap[elem].msg);
                    }
                }
                (exists, elem) = topMessagesSorted.getAdjacent(elem, NEXT);
            }
        }
        
        return r;
    }
    
    // ------------------------------------------------------------------------
    // Will set the Maximum Characters each message can have
    // ------------------------------------------------------------------------
    function setMessageMaxCharacters(uint _maxCharactersMessage) public onlyOwner returns (bool success) {
        maxCharactersMessage = _maxCharactersMessage;
        return true;
    }

    // ------------------------------------------------------------------------
    // Get the Maximum Characters each message can have
    // ------------------------------------------------------------------------
    function getMessageMaxCharacters() public view returns (uint maxChars) {
        return maxCharactersMessage;
    }

    // ------------------------------------------------------------------------
    // Default function
    // ------------------------------------------------------------------------
    function () public payable {
        buyCoke();
    }

}