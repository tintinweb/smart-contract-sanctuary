// produced by the Solididy File Flattener (c) David Appleton 2018
// contact : <span class="__cf_email__" data-cfemail="4c282d3a290c2d2723212e2d622f2321">[email&#160;protected]</span>
// released under Apache 2.0 licence
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

contract EthBattle is Ownable {
    using SafeMath for uint256;

    uint256 constant TOKEN_USE_BONUS = 15; //%, adds weight of win on top of the market price
    uint256 constant REFERRAL_REWARD = 2 ether; // GTA, 10*19
    uint256 public MIN_PLAY_AMOUNT = 50 finney; //wei, equal 0.05 ETH

    uint256 public META_BET_WEIGHT = 10 finney; //wei, equal to 0.01 ETH

    uint256 public roundIndex = 0;
    mapping(uint256 => address) public rounds;

    address[] private currentRewardingAddresses;

    PlaySeedInterface private playSeedGenerator;
    GTAInterface public token;
    AMUStoreInterface public store;

    address public startersProxyAddress;

    mapping(address => address) public referralBacklog; //backlog of players and their referrals

    mapping(address => uint256) public tokens; //map of deposited tokens

    event RoundCreated(address createdAddress, uint256 index);
    event Deposit(address user, uint amount, uint balance);
    event Withdraw(address user, uint amount, uint balance);

    /**
    * @dev Default fallback function, just deposits funds to the pot
    */
    function () public payable {
        getLastRound().getDevWallet().transfer(msg.value);
    }

    /**
    * @dev The EthBattle constructor
    * @param _playSeedAddress address of the play seed generator
    * @param _tokenAddress GTA address
    * @param _storeAddress store contract address
    */
    constructor (address _playSeedAddress, address _tokenAddress, address _storeAddress, address _proxyAddress) public {
        playSeedGenerator = PlaySeedInterface(_playSeedAddress);
        token = GTAInterface(_tokenAddress);
        store = AMUStoreInterface(_storeAddress);
        startersProxyAddress = _proxyAddress;
    }

    modifier onlyProxy() {
        require(msg.sender == startersProxyAddress);
        _;
    }

    /**
    * @dev Try (must be allowed by the seed generator itself) to claim ownership of the seed generator
    */
    function claimSeedOwnership() onlyOwner public {
        playSeedGenerator.claimOwnership();
    }

    /**
    * @dev Inject the new round contract, and sets the round with a new index
    * NOTE! Injected round must have had transferred ownership to this EthBattle already
    * @param _roundAddress address of the new round to use
    */
    function startRound(address _roundAddress) onlyOwner public {
        RoundInterface round = RoundInterface(_roundAddress);

        round.claimOwnership();

        roundIndex++;
        rounds[roundIndex] = round;
        emit RoundCreated(round, roundIndex);
    }

    /**
    * @dev Player starts a new play providing
    * @param _referral (Optional) referral address is any
    * @param _gtaBet (Optional) additional bet in GTA
    */
    function play(address _referral, uint256 _gtaBet) public payable {
        address player = msg.sender;
        uint256 weiAmount = msg.value;

        require(player != address(0), "Player&#39;s address is missing");
        require(weiAmount >= MIN_PLAY_AMOUNT, "The bet is too low");
        require(_gtaBet <= balanceOf(player), "Player&#39;s got not enough GTA");

        uint256 _bet = aggregateBet(weiAmount, _gtaBet);

        playInternal(player, weiAmount, _bet, _referral, _gtaBet);
    }

    /**
    * @dev Etherless player starts a new play, when actually the gas fee is payed
    * by the sender and the bet is set by the proxy
    * @param _player The actual player
    * @param _referral (Optional) referral address is any
    * @param _gtaBet (Optional) additional bet in GTA
    */
    function playMeta(address _player, address _referral, uint256 _gtaBet) onlyProxy public payable {
        uint256 weiAmount = msg.value;

        require(_player != address(0), "Player&#39;s address is missing");
        require(_gtaBet <= balanceOf(_player), "Player&#39;s got not enough GTA");

        //Important! For meta plays the &#39;weight&#39; is not connected the the actual bet (since the bet comes from proxy)
        //but static and equals META_BET_WEIGHT
        uint256 _bet = aggregateBet(META_BET_WEIGHT, _gtaBet);

        playInternal(_player, weiAmount, _bet, _referral, _gtaBet);
    }

    function playInternal(address _player, uint256 _weiBet, uint256 _betWeight, address _referral, uint256 _gtaBet) internal {
        if (_referral != address(0) && referralBacklog[_player] == address(0)) {
            //new referral for this _player
            referralBacklog[_player] = _referral;
            //reward the referral. Tokens remains in this contract
            //but become available for withdrawal by _referral
            transferInternally(owner, _referral, REFERRAL_REWARD);
        }

        playSeedGenerator.newPlaySeed(_player);

        if (_gtaBet > 0) {
            //player&#39;s using GTA
            transferInternally(_player, owner, _gtaBet);
        }

        if (referralBacklog[_player] != address(0)) {
            //ongoing round might not know about the _referral
            //delegate the knowledge of the referral to the ongoing round
            getLastRound().setReferral(_player, referralBacklog[_player]);
        }
        getLastRound().playRound.value(_weiBet)(_player, _betWeight);
    }

    /**
    * @dev Player claims a win
    * @param _seed secret seed
    */
    function win(bytes32 _seed) public {
        address player = msg.sender;
        winInternal(player, _seed);
    }

    /**
    * @dev Player claims a win
    * @param _player etherless player claims
    * @param _seed secret seed
    */
    function winMeta(address _player, bytes32 _seed) onlyProxy public {
        winInternal(_player, _seed);
    }

    function winInternal(address _player, bytes32 _seed) internal {
        require(_player != address(0), "Winner&#39;s address is missing");
        require(playSeedGenerator.findSeed(_player) == _seed, "Wrong seed!");
        playSeedGenerator.cleanSeedUp(_player);

        getLastRound().win(_player);
    }

    function findSeedAuthorized(address player) onlyOwner public view returns (bytes32){
        return playSeedGenerator.findSeed(player);
    }

    function aggregateBet(uint256 _bet, uint256 _gtaBet) internal view returns (uint256) {
        //get market price of the GTA, multiply by bet, and apply a bonus on it.
        //since both &#39;price&#39; and &#39;bet&#39; are in &#39;wei&#39;, we need to drop 10*18 decimals at the end
        uint256 _gtaValueWei = store.getTokenBuyPrice().mul(_gtaBet).div(1 ether).mul(100 + TOKEN_USE_BONUS).div(100);

        //sum up with ETH bet
        uint256 _resultBet = _bet.add(_gtaValueWei);

        return _resultBet;
    }

    /**
    * @dev Calculates the prize amount for this player by now
    * Note: the result is not the final one and a subject to change once more plays/wins occur
    * @return The prize in wei
    */
    function prizeByNow() public view returns (uint256) {
        return getLastRound().currentPrize(msg.sender);
    }

    /**
    * @dev Calculates the prediction on the prize amount for this player and this bet
    * Note: the result is not the final one and a subject to change once more plays/wins occur
    * @param _bet hypothetical bet in wei
    * @param _gtaBet hypothetical bet in GTA
    * @return The prediction in wei
    */
    function prizeProjection(uint256 _bet, uint256 _gtaBet) public view returns (uint256) {
        return getLastRound().projectedPrizeForPlayer(msg.sender, aggregateBet(_bet, _gtaBet));
    }


    /**
    * @dev Deposit GTA to the EthBattle contract so it can be spent (used) immediately
    * Note: this call must follow the approve() call on the token itself
    * @param _amount amount to deposit
    */
    function depositGTA(uint256 _amount) public {
        require(token.transferFrom(msg.sender, this, _amount), "Insufficient funds");
        tokens[msg.sender] = tokens[msg.sender].add(_amount);
        emit Deposit(msg.sender, _amount, tokens[msg.sender]);
    }

    /**
    * @dev Withdraw GTA from this contract to the own (caller) address
    * @param _amount amount to withdraw
    */
    function withdrawGTA(uint256 _amount) public {
        require(tokens[msg.sender] >= _amount, "Amount exceeds the available balance");
        tokens[msg.sender] = tokens[msg.sender].sub(_amount);
        require(token.transfer(msg.sender, _amount), "Amount exceeds the available balance");
        emit Withdraw(msg.sender, _amount, tokens[msg.sender]);
    }

    /**
    * @dev Internal transfer of the token.
    * Funds remain in this contract but become available for withdrawal
    */
    function transferInternally(address _from, address _to, uint256 _amount) internal {
        require(tokens[_from] >= _amount, "Too much to transfer");
        tokens[_from] = tokens[_from].sub(_amount);
        tokens[_to] = tokens[_to].add(_amount);
    }

    /**
    * @dev Interrupts the round to enable participants to claim funds back
    */
    function interruptLastRound() onlyOwner public {
        getLastRound().enableRefunds();
    }

    /**
    * @dev End last round so no new plays is possible, but ongoing plays are fine to win
    */
    function finishLastRound() onlyOwner public {
        getLastRound().coolDown();
    }

    function getLastRound() public view returns (RoundInterface){
        return RoundInterface(rounds[roundIndex]);
    }

    function getLastRoundAddress() external view returns (address){
        return rounds[roundIndex];
    }

    function balanceOf(address _user) public view returns (uint256) {
        return tokens[_user];
    }

    function setPlaySeed(address _playSeedAddress) onlyOwner public {
        playSeedGenerator = PlaySeedInterface(_playSeedAddress);
    }

    function setStore(address _storeAddress) onlyOwner public {
        store = AMUStoreInterface(_storeAddress);
    }

    function getTokenBuyPrice() public view returns (uint256) {
        return store.getTokenBuyPrice();
    }

    function getTokenSellPrice() public view returns (uint256) {
        return store.getTokenSellPrice();
    }

    /**
    * @dev Recover the history of referrals in case of the contract migration.
    */
    function setReferralsMap(address[] _players, address[] _referrals) onlyOwner public {
        require(_players.length == _referrals.length, "Size of players must be equal to the size of referrals");
        for (uint i = 0; i < _players.length; ++i) {
            referralBacklog[_players[i]] = _referrals[i];
        }
    }

    function getStartersProxyAddress() external view returns (address) {
        return startersProxyAddress;
    }

    function setStartersProxyAddress(address _newProxyAddress) onlyOwner public  {
        startersProxyAddress = _newProxyAddress;
    }

    function setMetaBetWeight(uint256 _newMetaBet) onlyOwner public {
        META_BET_WEIGHT = _newMetaBet;
    }

    function setMinBet(uint256 _newMinBet) onlyOwner public {
        MIN_PLAY_AMOUNT = _newMinBet;
    }

}
/**
 * @title PlaySeed contract interface
 */
interface PlaySeedInterface {

    function newPlaySeed(address _player) external;

    function findSeed(address _player) external view returns (bytes32);

    function cleanSeedUp(address _player) external;

    function claimOwnership() external;

}

/**
 * @title GTA contract interface
 */
interface GTAInterface {

    function transferFrom(address _from, address _to, uint256 _value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

}

/**
 * @title EthBattleRound contract interface
 */
interface RoundInterface {

    function claimOwnership() external;

    function setReferral(address _player, address _referral) external;

    function playRound(address _player, uint256 _bet) external payable;

    function enableRefunds() external;

    function coolDown() external;

    function currentPrize(address _player) external view returns (uint256);

    function projectedPrizeForPlayer(address _player, uint256 _bet) external view returns (uint256);

    function win(address _player) external;

    function getDevWallet() external view returns (address);

}

/**
 * @title Ammu-Nation contract interface
 */
interface AMUStoreInterface {

    function getTokenBuyPrice() external view returns (uint256);

    function getTokenSellPrice() external view returns (uint256);

}