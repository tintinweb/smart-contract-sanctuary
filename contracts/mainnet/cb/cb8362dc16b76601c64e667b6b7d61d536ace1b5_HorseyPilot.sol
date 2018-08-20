pragma solidity ^0.4.24;

// File: ..\openzeppelin-solidity\contracts\ownership\Ownable.sol

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
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }
}

// File: ..\openzeppelin-solidity\contracts\lifecycle\Pausable.sol

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

// File: ..\openzeppelin-solidity\contracts\math\SafeMath.sol

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

// File: contracts\HorseyExchange.sol

/**
 * @title ERC721 Non-Fungible Token Standard basic interface
 * @dev see https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
contract ERC721Basic {
    function balanceOf(address _owner) public view returns (uint256 _balance);
    function ownerOf(uint256 _tokenId) public view returns (address _owner);
    function exists(uint256 _tokenId) public view returns (bool _exists);

    function approve(address _to, uint256 _tokenId) public;
    function getApproved(uint256 _tokenId) public view returns (address _operator);

    function transferFrom(address _from, address _to, uint256 _tokenId) public;
}

/**
    @dev HorseyExchange contract - handles horsey market exchange which
    includes the following set of functions:
    1. Deposit to Exchange
    2. Cancel sale
    3. Purchase token
**/
contract HorseyExchange is Pausable { //also Ownable

    using SafeMath for uint256;

    event HorseyDeposit(uint256 tokenId, uint256 price);
    event SaleCanceled(uint256 tokenId);
    event HorseyPurchased(uint256 tokenId, address newOwner, uint256 totalToPay);

    /// @dev Fee applied to market maker - measured as percentage
    uint256 public marketMakerFee = 3;

    /// @dev Amount collected in fees
    uint256 collectedFees = 0;

    /// @dev  RoyalStables TOKEN
    ERC721Basic public token;

    /**
        @dev used to store the price and the owner address of a token on sale
    */
    struct SaleData {
        uint256 price;
        address owner;
    }

    /// @dev Market spec to lookup price and original owner based on token id
    mapping (uint256 => SaleData) market;

    /// @dev mapping of current tokens on market by owner
    mapping (address => uint256[]) userBarn;

    /// @dev initialize
    constructor() Pausable() public {
    }

    /**
        @dev Since the exchange requires the horsey contract and horsey contract
            requires exchange address, we cant initialize both of them in constructors
        @param _token Address of the stables contract
    */
    function setStables(address _token) external
    onlyOwner()
    {
        require(address(_token) != 0,"Address of token is zero");
        token = ERC721Basic(_token);
    }

    /**
        @dev Allows the owner to change market fees
        @param fees The new fees to apply (can be zero)
    */
    function setMarketFees(uint256 fees) external
    onlyOwner()
    {
        marketMakerFee = fees;
    }

    /// @return the tokens on sale based on the user address
    function getTokensOnSale(address user) external view returns(uint256[]) {
        return userBarn[user];
    }

    /// @return the token price with the fees
    function getTokenPrice(uint256 tokenId) public view
    isOnMarket(tokenId) returns (uint256) {
        return market[tokenId].price + (market[tokenId].price / 100 * marketMakerFee);
    }

    /**
        @dev User sends token to sell to exchange - at this point the exchange contract takes
            ownership, but will map token ownership back to owner for auotmated withdraw on
            cancel - requires that user is the rightful owner and is not
            asking for a null price
    */
    function depositToExchange(uint256 tokenId, uint256 price) external
    whenNotPaused()
    isTokenOwner(tokenId)
    nonZeroPrice(price)
    tokenAvailable() {
        require(token.getApproved(tokenId) == address(this),"Exchange is not allowed to transfer");
        //Transfers token from depositee to exchange (contract address)
        token.transferFrom(msg.sender, address(this), tokenId);
        
        //add the token to the market
        market[tokenId] = SaleData(price,msg.sender);

        //Add token to exchange map - tracking by owner of all tokens
        userBarn[msg.sender].push(tokenId);

        emit HorseyDeposit(tokenId, price);
    }

    /**
        @dev Allows true owner of token to cancel sale at anytime
        @param tokenId ID of the token to remove from the market
        @return true if user still has tokens for sale
    */
    function cancelSale(uint256 tokenId) external 
    whenNotPaused()
    originalOwnerOf(tokenId) 
    tokenAvailable() returns (bool) {
        //throws on fail - transfers token from exchange back to original owner
        token.transferFrom(address(this),msg.sender,tokenId);
        
        //Reset token on market - remove
        delete market[tokenId];

        //Reset barn tracker for user
        _removeTokenFromBarn(tokenId, msg.sender);

        emit SaleCanceled(tokenId);

        //Return true if this user is still &#39;active&#39; within the exchange
        //This will help with client side actions
        return userBarn[msg.sender].length > 0;
    }

    /**
        @dev Performs the purchase of a token that is present on the market - this includes checking that the
            proper amount is sent + appliced fee, updating seller&#39;s balance, updated collected fees and
            transfering token to buyer
            Only market tokens can be purchased
        @param tokenId ID of the token we wish to purchase
    */
    function purchaseToken(uint256 tokenId) external payable 
    whenNotPaused()
    isOnMarket(tokenId) 
    tokenAvailable()
    notOriginalOwnerOf(tokenId)
    {
        //Did the sender accidently pay over? - if so track the amount over
        uint256 totalToPay = getTokenPrice(tokenId);
        require(msg.value >= totalToPay, "Not paying enough");

        //fetch this tokens sale data
        SaleData memory sale = market[tokenId];

        //Add to collected fee amount payable to DEVS
        collectedFees += totalToPay - sale.price;

        //pay the seller
        sale.owner.transfer(sale.price);

        //Reset barn tracker for user
        _removeTokenFromBarn(tokenId,  sale.owner);

        //Reset token on market - remove
        delete market[tokenId];

        //Transfer the ERC721 to the buyer - we leave the sale amount
        //to be withdrawn by the user (transferred from exchange)
        token.transferFrom(address(this), msg.sender, tokenId);

        //Return over paid amount to sender if necessary
        if(msg.value > totalToPay) //overpaid
        {
            msg.sender.transfer(msg.value.sub(totalToPay));
        }

        emit HorseyPurchased(tokenId, msg.sender, totalToPay);
    }

    /// @dev Transfers the collected fees to the owner
    function withdraw() external
    onlyOwner()
    {
        assert(collectedFees <= address(this).balance);
        owner.transfer(collectedFees);
        collectedFees = 0;
    }

    /**
        @dev Internal function to remove a token from the users barn array
        @param tokenId ID of the token to remove
        @param barnAddress Address of the user selling tokens
    */
    function _removeTokenFromBarn(uint tokenId, address barnAddress)  internal {
        uint256[] storage barnArray = userBarn[barnAddress];
        require(barnArray.length > 0,"No tokens to remove");
        int index = _indexOf(tokenId, barnArray);
        require(index >= 0, "Token not found in barn");

        // Shift entire array :(
        for (uint256 i = uint256(index); i<barnArray.length-1; i++){
            barnArray[i] = barnArray[i+1];
        }

        // Remove element, update length, return array
        // this should be enough since https://ethereum.stackexchange.com/questions/1527/how-to-delete-an-element-at-a-certain-index-in-an-array
        barnArray.length--;
    }

    /**
        @dev Helper function which stores in memory an array which is passed in, and
        @param item element we are looking for
        @param array the array to look into
        @return the index of the item of interest
    */
    function _indexOf(uint item, uint256[] memory array) internal pure returns (int256){

        //Iterate over array to find indexOf(token)
        for(uint256 i = 0; i < array.length; i++){
            if(array[i] == item){
                return int256(i);
            }
        }

        //Item not found
        return -1;
    }

    /// @dev requires token to be on the market = current owner is exchange
    modifier isOnMarket(uint256 tokenId) {
        require(token.ownerOf(tokenId) == address(this),"Token not on market");
        _;
    }
    
    /// @dev Is the user the owner of this token?
    modifier isTokenOwner(uint256 tokenId) {
        require(token.ownerOf(tokenId) == msg.sender,"Not tokens owner");
        _;
    }

    /// @dev Is this the original owner of the token - at exchange level
    modifier originalOwnerOf(uint256 tokenId) {
        require(market[tokenId].owner == msg.sender,"Not the original owner of");
        _;
    }

    /// @dev Is this the original owner of the token - at exchange level
    modifier notOriginalOwnerOf(uint256 tokenId) {
        require(market[tokenId].owner != msg.sender,"Is the original owner");
        _;
    }

    /// @dev Is a nonzero price being sent?
    modifier nonZeroPrice(uint256 price){
        require(price > 0,"Price is zero");
        _;
    }

    /// @dev Do we have a token address
    modifier tokenAvailable(){
        require(address(token) != 0,"Token address not set");
        _;
    }
}

// File: contracts\EthorseHelpers.sol

/**
    @title Race contract - used for linking ethorse Race struct 
    @dev This interface is losely based on ethorse race contract
*/
contract EthorseRace {

    //Encapsulation of racing information 
    struct chronus_info {
        bool  betting_open; // boolean: check if betting is open
        bool  race_start; //boolean: check if race has started
        bool  race_end; //boolean: check if race has ended
        bool  voided_bet; //boolean: check if race has been voided
        uint32  starting_time; // timestamp of when the race starts
        uint32  betting_duration;
        uint32  race_duration; // duration of the race
        uint32 voided_timestamp;
    }

    address public owner;
    
    //Point to racing information
    chronus_info public chronus;

    //Coin index mapping to flag - true if index is winner
    mapping (bytes32 => bool) public winner_horse;
    /*
            // exposing the coin pool details for DApp
    function getCoinIndex(bytes32 index, address candidate) external constant returns (uint, uint, uint, bool, uint) {
        return (coinIndex[index].total, coinIndex[index].pre, coinIndex[index].post, coinIndex[index].price_check, voterIndex[candidate].bets[index]);
    }
    */
    // exposing the coin pool details for DApp
    function getCoinIndex(bytes32 index, address candidate) external constant returns (uint, uint, uint, bool, uint);
}

/**
    @title API contract - used to connect with Race contract and 
        encapsulate race information for token inidices and winner
        checking.
*/
contract EthorseHelpers {

    /// @dev Convert all symbols to bytes array
    bytes32[] public all_horses = [bytes32("BTC"),bytes32("ETH"),bytes32("LTC")];
    mapping(address => bool) public legitRaces;
    bool onlyLegit = false;

    /// @dev Used to add new symbol to the bytes array 
    function _addHorse(bytes32 newHorse) internal {
        all_horses.push(newHorse);
    }

    function _addLegitRace(address newRace) internal
    {
        legitRaces[newRace] = true;
        if(!onlyLegit)
            onlyLegit = true;
    }

    function getall_horsesCount() public view returns(uint) {
        return all_horses.length;
    }

    /**
        @param raceAddress - address of this race
        @param eth_address - user&#39;s ethereum wallet address
        @return true if user is winner + name of the winning horse (LTC,BTC,ETH,...)
    */
    function _isWinnerOf(address raceAddress, address eth_address) internal view returns (bool,bytes32)
    {
        //acquire race, fails if doesnt exist
        EthorseRace race = EthorseRace(raceAddress);
       
        //make sure the race is legit (only if legit races list is filled)
        if(onlyLegit)
            require(legitRaces[raceAddress],"not legit race");
        //acquire chronus
        bool  voided_bet; //boolean: check if race has been voided
        bool  race_end; //boolean: check if race has ended
        (,,race_end,voided_bet,,,,) = race.chronus();

        //cant be winner if race was refunded or didnt end yet
        if(voided_bet || !race_end)
            return (false,bytes32(0));

        //aquire winner race index
        bytes32 horse;
        bool found = false;
        uint256 arrayLength = all_horses.length;

        //Iterate over coin symbols to find winner - tie could be possible?
        for(uint256 i = 0; i < arrayLength; i++)
        {
            if(race.winner_horse(all_horses[i])) {
                horse = all_horses[i];
                found = true;
                break;
            }
        }
        //no winner horse? shouldnt happen unless this horse isnt registered
        if(!found)
            return (false,bytes32(0));

        //check the bet amount of the eth_address on the winner horse
        uint256 bet_amount = 0;
        if(eth_address != address(0)) {
            (,,,, bet_amount) = race.getCoinIndex(horse, eth_address);
        }
        
        //winner if the eth_address had a bet > 0 on the winner horse
        return (bet_amount > 0, horse);
    }
}

// File: contracts\HorseyToken.sol

contract RoyalStablesInterface {
    
    struct Horsey {
        address race;
        bytes32 dna;
        uint8 feedingCounter;
        uint8 tier;
    }

    mapping(uint256 => Horsey) public horseys;
    mapping(address => uint32) public carrot_credits;
    mapping(uint256 => string) public names;
    address public master;

    function getOwnedTokens(address eth_address) public view returns (uint256[]);
    function storeName(uint256 tokenId, string newName) public;
    function storeCarrotsCredit(address client, uint32 amount) public;
    function storeHorsey(address client, uint256 tokenId, address race, bytes32 dna, uint8 feedingCounter, uint8 tier) public;
    function modifyHorsey(uint256 tokenId, address race, bytes32 dna, uint8 feedingCounter, uint8 tier) public;
    function modifyHorseyDna(uint256 tokenId, bytes32 dna) public;
    function modifyHorseyFeedingCounter(uint256 tokenId, uint8 feedingCounter) public;
    function modifyHorseyTier(uint256 tokenId, uint8 tier) public;
    function unstoreHorsey(uint256 tokenId) public;
    function ownerOf(uint256 tokenId) public returns (address);
}

/**
    @title HorseyToken ERC721 Token
    @dev Horse contract - horse derives fro AccessManager built on top of ERC721 token and uses 
    @dev EthorseHelpers and AccessManager
*/
contract HorseyToken is EthorseHelpers,Pausable {
    using SafeMath for uint256;

    /// @dev called when someone claims a token
    event Claimed(address raceAddress, address eth_address, uint256 tokenId);
    
    /// @dev called when someone starts a feeding process
    event Feeding(uint256 tokenId);

    /// @dev called when someone ends a feeding process
    event ReceivedCarrot(uint256 tokenId, bytes32 newDna);

    /// @dev called when someone fails to end a feeding on the 255 blocks timer
    event FeedingFailed(uint256 tokenId);

    /// @dev called when a horsey is renamed
    event HorseyRenamed(uint256 tokenId, string newName);

    /// @dev called when a horsey is freed for carrots
    event HorseyFreed(uint256 tokenId);

    /// @dev address of the RoyalStables
    RoyalStablesInterface public stables;

    ///@dev multiplier applied to carrots received from burning a horsey
    uint8 public carrotsMultiplier = 1;

    ///@dev multiplier applied to rarity bounds when feeding horsey
    uint8 public rarityMultiplier = 1;

    ///@dev fee to pay when claiming a token
    uint256 public claimingFee = 0.000 ether;

    /**
        @dev Holds the necessary data to feed a horsey
            The user has to create begin feeding and wait for the block
            with the feeding transaction to be hashed
            Only then he can stop the feeding
    */
    struct FeedingData {
        uint256 blockNumber;    ///@dev Holds the block number where the feeding began
        uint256 horsey;         ///@dev Holds the horsey id
    }

    /// @dev Maps a user to his pending feeding
    mapping(address => FeedingData) public pendingFeedings;

    /// @dev Stores the renaming fees per character a user has to pay upon renaming a horsey
    uint256 public renamingCostsPerChar = 0.001 ether;

    /**
        @dev Contracts constructor
            Initializes token data
            is pausable,ownable
        @param stablesAddress Address of the official RoyalStables contract
    */
    constructor(address stablesAddress) 
    EthorseHelpers() 
    Pausable() public {
        stables = RoyalStablesInterface(stablesAddress);
    }

    /**
        @dev Changes multiplier for rarity on feed
        @param newRarityMultiplier The cost to charge in wei for each character of the name
    */
    function setRarityMultiplier(uint8 newRarityMultiplier) external 
    onlyOwner()  {
        rarityMultiplier = newRarityMultiplier;
    }

    /**
        @dev Sets a new muliplier for freeing a horse
        @param newCarrotsMultiplier the new multiplier for feeding
    */
    function setCarrotsMultiplier(uint8 newCarrotsMultiplier) external 
    onlyOwner()  {
        carrotsMultiplier = newCarrotsMultiplier;
    }

    /**
        @dev Sets a new renaming per character cost in wei
            Any CLevel can call this function
        @param newRenamingCost The cost to charge in wei for each character of the name
    */
    function setRenamingCosts(uint256 newRenamingCost) external 
    onlyOwner()  {
        renamingCostsPerChar = newRenamingCost;
    }

    /**
        @dev Sets a new claiming fee in wei
            Any CLevel can call this function
        @param newClaimingFee The cost to charge in wei for each claimed HRSY
    */
    function setClaimingCosts(uint256 newClaimingFee) external
    onlyOwner()  {
        claimingFee = newClaimingFee;
    }

    /**
        @dev Allows to add a race address for races validation
        @param newAddress the race address
    */
    function addLegitRaceAddress(address newAddress) external
    onlyOwner() {
        _addLegitRace(newAddress);
    }

    /**
        @dev Owner can withdraw the current balance
    */
    function withdraw() external 
    onlyOwner()  {
        owner.transfer(address(this).balance); //throws on fail
    }

    //allows owner to add a horse name to the possible horses list (BTC,ETH,LTC,...)
    /**
        @dev Adds a new horse index to the possible horses list (BTC,ETH,LTC,...)
            This is in case ethorse adds a new coin
            Any CLevel can call this function
        @param newHorse Index of the horse to add (same data type as the original ethorse erc20 contract code)
    */
    function addHorseIndex(bytes32 newHorse) external
    onlyOwner() {
        _addHorse(newHorse);
    }

    /**
        @dev Gets the complete list of token ids which belongs to an address
        @param eth_address The address you want to lookup owned tokens from
        @return List of all owned by eth_address tokenIds
    */
    function getOwnedTokens(address eth_address) public view returns (uint256[]) {
        return stables.getOwnedTokens(eth_address);
    }
    
    /**
        @dev Allows to check if an eth_address can claim a horsey from this contract
            should we also check if already claimed here?
        @param raceAddress The ethorse race you want to claim from
        @param eth_address The users address you want to claim the token for
        @return True only if eth_address is a winner of the race contract at raceAddress
    */
    function can_claim(address raceAddress, address eth_address) public view returns (bool) {
        bool res;
        (res,) = _isWinnerOf(raceAddress, eth_address);
        return res;
    }

    /**
        @dev Allows a user to claim a special horsey with the same dna as the race one
            Cant be used on paused
            The sender has to be a winner of the race and must never have claimed a special horsey from this race
        @param raceAddress The race&#39;s address
    */
    function claim(address raceAddress) external payable
    costs(claimingFee)
    whenNotPaused()
    {
        //call _isWinnerOf with a 0 address to simply get the winner horse
        bytes32 winner;
        bool res;
        (res,winner) = _isWinnerOf(raceAddress, address(0));
        require(winner != bytes32(0),"Winner is zero");
        require(res,"can_claim return false");
        //require(!exists(id)); should already be checked by mining function
        uint256 id = _generate_special_horsey(raceAddress, msg.sender, winner);
        emit Claimed(raceAddress, msg.sender, id);
    }

    /**
        @dev Allows a user to give a horsey a name or rename it
            This function is payable and its cost is renamingCostsPerChar * length(newname)
            Cant be called while paused
            If called with too low balance, the modifier will throw
            If called with too much balance, we try to return the remaining funds back
            Upon completion we update all ceos balances, maybe not very efficient?
        @param tokenId ID of the horsey to rename
        @param newName The name to give to the horsey
    */
    function renameHorsey(uint256 tokenId, string newName) external 
    whenNotPaused()
    onlyOwnerOf(tokenId) 
    costs(renamingCostsPerChar * bytes(newName).length)
    payable {
        uint256 renamingFee = renamingCostsPerChar * bytes(newName).length;
        //Return over paid amount to sender if necessary
        if(msg.value > renamingFee) //overpaid
        {
            msg.sender.transfer(msg.value.sub(renamingFee));
        }
        //store the new name
        stables.storeName(tokenId,newName);
        emit HorseyRenamed(tokenId,newName);
    }

    /**
        @dev Allows a user to burn a token he owns to get carrots
            The mount of carrots given is equal to the horsey&#39;s feedingCounter upon burning
            Cant be called on a horsey with a pending feeding
            Cant be called while paused
        @param tokenId ID of the token to burn
    */
    function freeForCarrots(uint256 tokenId) external 
    whenNotPaused()
    onlyOwnerOf(tokenId) {
        require(pendingFeedings[msg.sender].horsey != tokenId,"");
        //credit carrots
        uint8 feedingCounter;
        (,,feedingCounter,) = stables.horseys(tokenId);
        stables.storeCarrotsCredit(msg.sender,stables.carrot_credits(msg.sender) + uint32(feedingCounter * carrotsMultiplier));
        stables.unstoreHorsey(tokenId);
        emit HorseyFreed(tokenId);
    }

    /**
        @dev Returns the amount of carrots the user owns
            We have a getter to hide the carrots amount from public view
        @return The current amount of carrot credits the sender owns 
    */
    function getCarrotCredits() external view returns (uint32) {
        return stables.carrot_credits(msg.sender);
    }

    /**
        @dev Returns horsey data of a given token
        @param tokenId ID of the horsey to fetch
        @return (race address, dna, feedingCounter, name)
    */
    function getHorsey(uint256 tokenId) public view returns (address, bytes32, uint8, string) {
        RoyalStablesInterface.Horsey memory temp;
        (temp.race,temp.dna,temp.feedingCounter,temp.tier) = stables.horseys(tokenId);
        return (temp.race,temp.dna,temp.feedingCounter,stables.names(tokenId));
    }

    /**
        @dev Allows to feed a horsey to increase its feedingCounter value
            Gives a chance to get a rare trait
            The amount of carrots required is the value of current feedingCounter
            The carrots the user owns will be reduced accordingly upon success
            Cant be called while paused
        @param tokenId ID of the horsey to feed
    */
    function feed(uint256 tokenId) external 
    whenNotPaused()
    onlyOwnerOf(tokenId) 
    carrotsMeetLevel(tokenId)
    noFeedingInProgress()
    {
        pendingFeedings[msg.sender] = FeedingData(block.number,tokenId);
        uint8 feedingCounter;
        (,,feedingCounter,) = stables.horseys(tokenId);
        stables.storeCarrotsCredit(msg.sender,stables.carrot_credits(msg.sender) - uint32(feedingCounter));
        emit Feeding(tokenId);
    }

    /**
        @dev Allows user to stop feeding a horsey
            This will trigger a random rarity chance
    */
    function stopFeeding() external
    feedingInProgress() returns (bool) {
        uint256 blockNumber = pendingFeedings[msg.sender].blockNumber;
        uint256 tokenId = pendingFeedings[msg.sender].horsey;
        //you cant feed and stop feeding from the same block!
        require(block.number - blockNumber >= 1,"feeding and stop feeding are in same block");

        delete pendingFeedings[msg.sender];

        //solidity only gives you access to the previous 256 blocks
        //deny and remove this obsolete feeding if we cant fetch its blocks hash
        if(block.number - blockNumber > 255) {
            //the feeding is outdated = failed
            //the user can feed again but he lost his carrots
            emit FeedingFailed(tokenId);
            return false; 
        }

        //token could have been transfered in the meantime to someone else
        if(stables.ownerOf(tokenId) != msg.sender) {
            //the feeding is failed because the token no longer belongs to this user = failed
            //the user has lost his carrots
            emit FeedingFailed(tokenId);
            return false; 
        }
        
        //call horsey generation with the claim block hash
        _feed(tokenId, blockhash(blockNumber));
        bytes32 dna;
        (,dna,,) = stables.horseys(tokenId);
        emit ReceivedCarrot(tokenId, dna);
        return true;
    }

    /// @dev Only ether sent explicitly through the donation() function is accepted
    function() external payable {
        revert("Not accepting donations");
    }

    /**
        @dev Internal function to increase a horsey&#39;s rarity
            Uses a random value to assess if the feeding process increases rarity
            The chances of having a rarity increase are based on the current feedingCounter
        @param tokenId ID of the token to "feed"
        @param blockHash Hash of the block where the feeding began
    */
    function _feed(uint256 tokenId, bytes32 blockHash) internal {
        //Grab the upperbound for probability 100,100
        uint8 tier;
        uint8 feedingCounter;
        (,,feedingCounter,tier) = stables.horseys(tokenId);
        uint256 probabilityByRarity = 10 ** (uint256(tier).add(1));
        uint256 randNum = uint256(keccak256(abi.encodePacked(tokenId, blockHash))) % probabilityByRarity;

        //Scale probability based on horsey&#39;s level
        if(randNum <= (feedingCounter * rarityMultiplier)){
            _increaseRarity(tokenId, blockHash);
        }

        //Increment feedingCounter
        //Maximum allowed is 255, which requires 32385 carrots, so we should never reach that
        if(feedingCounter < 255) {
            stables.modifyHorseyFeedingCounter(tokenId,feedingCounter+1);
        }
    }

    /// @dev creates a special token id based on the race and the coin index
    function _makeSpecialId(address race, address sender, bytes32 coinIndex) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(race, sender, coinIndex)));
    }

    /**
        @dev Internal function to generate a SPECIAL horsey token
            we then use the ERC721 inherited minting process
            the dna is a bytes32 target for a keccak256. Not using blockhash
            finaly, a bitmask zeros the first 2 bytes for rarity traits
        @param race Address of the associated race
        @param eth_address Address of the user to receive the token
        @param coinIndex The index of the winning coin
        @return ID of the token
    */
    function _generate_special_horsey(address race, address eth_address, bytes32 coinIndex) internal returns (uint256) {
        uint256 id = _makeSpecialId(race, eth_address, coinIndex);
        //generate dna
        bytes32 dna = _shiftRight(keccak256(abi.encodePacked(race, coinIndex)),16);
         //storeHorsey checks if the token exists before minting already, so we dont have to here
        stables.storeHorsey(eth_address,id,race,dna,1,0);
        return id;
    }
    
    /**
        @dev Internal function called to increase a horsey rarity
            We generate a random zeros mask with a single 1 in the leading 16 bits
        @param tokenId Id of the token to increase rarity of
        @param blockHash hash of the block where the feeding began
    */
    function _increaseRarity(uint256 tokenId, bytes32 blockHash) private {
        uint8 tier;
        bytes32 dna;
        (,dna,,tier) = stables.horseys(tokenId);
        if(tier < 255)
            stables.modifyHorseyTier(tokenId,tier+1);
        uint256 random = uint256(keccak256(abi.encodePacked(tokenId, blockHash)));
        //this creates a mask of 256 bits such as one of the first 16 bits will be 1
        bytes32 rarityMask = _shiftLeft(bytes32(1), (random % 16 + 240));
        bytes32 newdna = dna | rarityMask; //apply mask to add the random flag
        stables.modifyHorseyDna(tokenId,newdna);
    }

    /// @dev shifts a bytes32 left by n positions
    function _shiftLeft(bytes32 data, uint n) internal pure returns (bytes32) {
        return bytes32(uint256(data)*(2 ** n));
    }

    /// @dev shifts a bytes32 right by n positions
    function _shiftRight(bytes32 data, uint n) internal pure returns (bytes32) {
        return bytes32(uint256(data)/(2 ** n));
    }

    /// @dev Modifier to ensure user can afford a rehorse
    modifier carrotsMeetLevel(uint256 tokenId){
        uint256 feedingCounter;
        (,,feedingCounter,) = stables.horseys(tokenId);
        require(feedingCounter <= stables.carrot_credits(msg.sender),"Not enough carrots");
        _;
    }

    /// @dev insures the caller payed the required amount
    modifier costs(uint256 amount) {
        require(msg.value >= amount,"Not enough funds");
        _;
    }

    /// @dev requires the address to be non null
    modifier validAddress(address addr) {
        require(addr != address(0),"Address is zero");
        _;
    }

    /// @dev requires that the user isnt feeding a horsey already
    modifier noFeedingInProgress() {
        //if the key does not exit, then the default struct data is used where blockNumber is 0
        require(pendingFeedings[msg.sender].blockNumber == 0,"Already feeding");
        _;
    }

    /// @dev requires that the user isnt feeding a horsey already
    modifier feedingInProgress() {
        //if the key does not exit, then the default struct data is used where blockNumber is 0
        require(pendingFeedings[msg.sender].blockNumber != 0,"No pending feeding");
        _;
    }

    /// @dev requires that the user isnt feeding a horsey already
    modifier onlyOwnerOf(uint256 tokenId) {
        require(stables.ownerOf(tokenId) == msg.sender, "Caller is not owner of this token");
        _;
    }
}

// File: contracts\HorseyPilot.sol

/**
    @title Adds rank management utilities and voting behavior
    @dev Handles equities distribution and levels of access

    EXCHANGE FUNCTIONS IT CAN CALL

    setClaimingFee OK 5
    setMarketFees OK 1
    withdraw

    TOKEN FUNCTIONS IT CAN CALL

    setRenamingCosts OK 0
    addHorseIndex OK 3
    setCarrotsMultiplier 8
    setRarityMultiplier 9
    addLegitDevAddress 2
    withdraw

    PAUSING OK 4
*/

contract HorseyPilot {

    /// @dev event that is fired when a new proposal is made
    event NewProposal(uint8 methodId, uint parameter, address proposer);

    /// @dev event that is fired when a proposal is accepted
    event ProposalPassed(uint8 methodId, uint parameter, address proposer);

    /// @dev minimum threshold that must be met in order to confirm
    /// a contract update
    uint8 constant votingThreshold = 2;

    /// @dev minimum amount of time a proposal can live
    /// after this time it can be forcefully invoked or killed by anyone
    uint256 constant proposalLife = 7 days;

    /// @dev amount of time until another proposal can be made
    /// we use this to eliminate proposal spamming
    uint256 constant proposalCooldown = 1 days;

    /// @dev used to reference the exact time the last proposal vetoed
    uint256 cooldownStart;

    /// @dev The addresses of the accounts (or contracts) that can execute actions within each roles.
    address public jokerAddress;
    address public knightAddress;
    address public paladinAddress;

    /// @dev List of all addresses allowed to vote
    address[3] public voters;

    /// @dev joker is the pool and gets the rest
    uint8 constant public knightEquity = 40;
    uint8 constant public paladinEquity = 10;

    /// @dev deployed exchange and token addresses
    address public exchangeAddress;
    address public tokenAddress;

    /// @dev Mapping to keep track of pending balance of contract owners
    mapping(address => uint) internal _cBalance;

    /// @dev Encapsulates information about a proposed update
    struct Proposal{
        address proposer;           /// @dev address of the CEO at the origin of this proposal
        uint256 timestamp;          /// @dev the time at which this propsal was made
        uint256 parameter;          /// @dev parameters associated with proposed method invocation
        uint8   methodId;           /// @dev id maps to function 0:rename horse, 1:change fees, 2:?    
        address[] yay;              /// @dev list of all addresses who voted     
        address[] nay;              /// @dev list of all addresses who voted against     
    }

    /// @dev the pending proposal
    Proposal public currentProposal;

    /// @dev true if the proposal is waiting for votes
    bool public proposalInProgress = false;

    /// @dev Value to keep track of avaible balance
    uint256 public toBeDistributed;

    /// @dev used to deploy contracts only once
    bool deployed = false;

    /**
        @param _jokerAddress joker
        @param _knightAddress knight
        @param _paladinAddress paladin
        @param _voters list of all allowed voting addresses
    */
    constructor(
    address _jokerAddress,
    address _knightAddress,
    address _paladinAddress,
    address[3] _voters
    ) public {
        jokerAddress = _jokerAddress;
        knightAddress = _knightAddress;
        paladinAddress = _paladinAddress;

        for(uint i = 0; i < 3; i++) {
            voters[i] = _voters[i];
        }

        //Set cooldown start to 1 day ago so that cooldown is irrelevant
        cooldownStart = block.timestamp - proposalCooldown;
    }

    /**
        @dev Used to deploy children contracts as a one shot call
    */
    function deployChildren(address stablesAddress) external {
        require(!deployed,"already deployed");
        // deploy token and exchange contracts
        exchangeAddress = new HorseyExchange();
        tokenAddress = new HorseyToken(stablesAddress);

        // the exchange requires horsey token address
        HorseyExchange(exchangeAddress).setStables(stablesAddress);

        deployed = true;
    }

    /**
        @dev Transfers joker ownership to a new address
        @param newJoker the new address
    */
    function transferJokerOwnership(address newJoker) external 
    validAddress(newJoker) {
        require(jokerAddress == msg.sender,"Not right role");
        _moveBalance(newJoker);
        jokerAddress = newJoker;
    }

    /**
        @dev Transfers knight ownership to a new address
        @param newKnight the new address
    */
    function transferKnightOwnership(address newKnight) external 
    validAddress(newKnight) {
        require(knightAddress == msg.sender,"Not right role");
        _moveBalance(newKnight);
        knightAddress = newKnight;
    }

    /**
        @dev Transfers paladin ownership to a new address
        @param newPaladin the new address
    */
    function transferPaladinOwnership(address newPaladin) external 
    validAddress(newPaladin) {
        require(paladinAddress == msg.sender,"Not right role");
        _moveBalance(newPaladin);
        paladinAddress = newPaladin;
    }

    /**
        @dev Allow CEO to withdraw from pending value always checks to update redist
            We ONLY redist when a user tries to withdraw so we are not redistributing
            on every payment
        @param destination The address to send the ether to
    */
    function withdrawCeo(address destination) external 
    onlyCLevelAccess()
    validAddress(destination) {
        //Check that pending balance can be redistributed - if so perform
        //this procedure
        if(toBeDistributed > 0){
            _updateDistribution();
        }
        
        //Grab the balance of this CEO 
        uint256 balance = _cBalance[msg.sender];
        
        //If we have non-zero balance, CEO may withdraw from pending amount
        if(balance > 0 && (address(this).balance >= balance)) {
            destination.transfer(balance); //throws on fail
            _cBalance[msg.sender] = 0;
        }
    }

    /// @dev acquire funds from owned contracts
    function syncFunds() external {
        uint256 prevBalance = address(this).balance;
        HorseyToken(tokenAddress).withdraw();
        HorseyExchange(exchangeAddress).withdraw();
        uint256 newBalance = address(this).balance;
        //add to
        toBeDistributed = toBeDistributed + (newBalance - prevBalance);
    }

    /// @dev allows a noble to access his holdings
    function getNobleBalance() external view
    onlyCLevelAccess() returns (uint256) {
        return _cBalance[msg.sender];
    }

    /**
        @dev Make a proposal and add to pending proposals
        @param methodId a string representing the function ie. &#39;renameHorsey()&#39;
        @param parameter parameter to be used if invocation is approved
    */
    function makeProposal( uint8 methodId, uint256 parameter ) external
    onlyCLevelAccess()
    proposalAvailable()
    cooledDown()
    {
        currentProposal.timestamp = block.timestamp;
        currentProposal.parameter = parameter;
        currentProposal.methodId = methodId;
        currentProposal.proposer = msg.sender;
        delete currentProposal.yay;
        delete currentProposal.nay;
        proposalInProgress = true;
        
        emit NewProposal(methodId,parameter,msg.sender);
    }

    /**
        @dev Call to vote on a pending proposal
    */
    function voteOnProposal(bool voteFor) external 
    proposalPending()
    onlyVoters()
    notVoted() {
        //cant vote on expired!
        require((block.timestamp - currentProposal.timestamp) <= proposalLife);
        if(voteFor)
        {
            currentProposal.yay.push(msg.sender);
            //Proposal went through? invoke it
            if( currentProposal.yay.length >= votingThreshold )
            {
                _doProposal();
                proposalInProgress = false;
                //no need to reset cooldown on successful proposal
                return;
            }

        } else {
            currentProposal.nay.push(msg.sender);
            //Proposal failed?
            if( currentProposal.nay.length >= votingThreshold )
            {
                proposalInProgress = false;
                cooldownStart = block.timestamp;
                return;
            }
        }
    }

    /**
        @dev Helps moving pending balance from one role to another
        @param newAddress the address to transfer the pending balance from the msg.sender account
    */
    function _moveBalance(address newAddress) internal
    validAddress(newAddress) {
        require(newAddress != msg.sender); /// @dev IMPORTANT or else the account balance gets reset here!
        _cBalance[newAddress] = _cBalance[msg.sender];
        _cBalance[msg.sender] = 0;
    }

    /**
        @dev Called at the start of withdraw to distribute any pending balances that live in the contract
            will only ever be called if balance is non-zero (funds should be distributed)
    */
    function _updateDistribution() internal {
        require(toBeDistributed != 0,"nothing to distribute");
        uint256 knightPayday = toBeDistributed / 100 * knightEquity;
        uint256 paladinPayday = toBeDistributed / 100 * paladinEquity;

        /// @dev due to the equities distribution, queen gets the remaining value
        uint256 jokerPayday = toBeDistributed - knightPayday - paladinPayday;

        _cBalance[jokerAddress] = _cBalance[jokerAddress] + jokerPayday;
        _cBalance[knightAddress] = _cBalance[knightAddress] + knightPayday;
        _cBalance[paladinAddress] = _cBalance[paladinAddress] + paladinPayday;
        //Reset balance to 0
        toBeDistributed = 0;
    }

    /**
        @dev Execute the proposal
    */
    function _doProposal() internal {
        /// UPDATE the renaming cost
        if( currentProposal.methodId == 0 ) HorseyToken(tokenAddress).setRenamingCosts(currentProposal.parameter);
        
        /// UPDATE the market fees
        if( currentProposal.methodId == 1 ) HorseyExchange(exchangeAddress).setMarketFees(currentProposal.parameter);

        /// UPDATE the legit dev addresses list
        if( currentProposal.methodId == 2 ) HorseyToken(tokenAddress).addLegitRaceAddress(address(currentProposal.parameter));

        /// ADD a horse index to exchange
        if( currentProposal.methodId == 3 ) HorseyToken(tokenAddress).addHorseIndex(bytes32(currentProposal.parameter));

        /// PAUSE/UNPAUSE the dApp
        if( currentProposal.methodId == 4 ) {
            if(currentProposal.parameter == 0) {
                HorseyExchange(exchangeAddress).unpause();
                HorseyToken(tokenAddress).unpause();
            } else {
                HorseyExchange(exchangeAddress).pause();
                HorseyToken(tokenAddress).pause();
            }
        }

        /// UPDATE the claiming fees
        if( currentProposal.methodId == 5 ) HorseyToken(tokenAddress).setClaimingCosts(currentProposal.parameter);

        /// UPDATE carrots multiplier
        if( currentProposal.methodId == 8 ){
            HorseyToken(tokenAddress).setCarrotsMultiplier(uint8(currentProposal.parameter));
        }

        /// UPDATE rarity multiplier
        if( currentProposal.methodId == 9 ){
            HorseyToken(tokenAddress).setRarityMultiplier(uint8(currentProposal.parameter));
        }

        emit ProposalPassed(currentProposal.methodId,currentProposal.parameter,currentProposal.proposer);
    }

    /// @dev requires the address to be non null
    modifier validAddress(address addr) {
        require(addr != address(0),"Address is zero");
        _;
    }

    /// @dev requires the sender to be on the contract owners list
    modifier onlyCLevelAccess() {
        require((jokerAddress == msg.sender) || (knightAddress == msg.sender) || (paladinAddress == msg.sender),"not c level");
        _;
    }

    /// @dev requires that a proposal is not in process or has exceeded its lifetime, and has cooled down
    /// after being vetoed
    modifier proposalAvailable(){
        require(((!proposalInProgress) || ((block.timestamp - currentProposal.timestamp) > proposalLife)),"proposal already pending");
        _;
    }

    // @dev requries that if this proposer was the last proposer, that he or she has reached the 
    // cooldown limit
    modifier cooledDown( ){
        if(msg.sender == currentProposal.proposer && (block.timestamp - cooldownStart < 1 days)){
            revert("Cool down period not passed yet");
        }
        _;
    }

    /// @dev requires a proposal to be active
    modifier proposalPending() {
        require(proposalInProgress,"no proposal pending");
        _;
    }

    /// @dev requires the voter to not have voted already
    modifier notVoted() {
        uint256 length = currentProposal.yay.length;
        for(uint i = 0; i < length; i++) {
            if(currentProposal.yay[i] == msg.sender) {
                revert("Already voted");
            }
        }

        length = currentProposal.nay.length;
        for(i = 0; i < length; i++) {
            if(currentProposal.nay[i] == msg.sender) {
                revert("Already voted");
            }
        }
        _;
    }

    /// @dev requires the voter to not have voted already
    modifier onlyVoters() {
        bool found = false;
        uint256 length = voters.length;
        for(uint i = 0; i < length; i++) {
            if(voters[i] == msg.sender) {
                found = true;
                break;
            }
        }
        if(!found) {
            revert("not a voter");
        }
        _;
    }
}