pragma solidity ^0.4.24;

// File: zeppelin-solidity/contracts/token/ERC20/ERC20Basic.sol

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * See https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

// File: zeppelin-solidity/contracts/math/SafeMath.sol

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

// File: zeppelin-solidity/contracts/token/ERC20/BasicToken.sol

/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  uint256 totalSupply_;

  /**
  * @dev Total number of tokens in existence
  */
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

  /**
  * @dev Transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }

}

// File: zeppelin-solidity/contracts/token/ERC20/ERC20.sol

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

// File: zeppelin-solidity/contracts/token/ERC20/StandardToken.sol

/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * https://github.com/ethereum/EIPs/issues/20
 * Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
    public
    returns (bool)
  {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   * Beware that changing an allowance with this method brings the risk that someone may use both the old
   * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
   * race condition is to first reduce the spender&#39;s allowance to 0 and set the desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifying the amount of tokens still available for the spender.
   */
  function allowance(
    address _owner,
    address _spender
   )
    public
    view
    returns (uint256)
  {
    return allowed[_owner][_spender];
  }

  /**
   * @dev Increase the amount of tokens that an owner allowed to a spender.
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _addedValue The amount of tokens to increase the allowance by.
   */
  function increaseApproval(
    address _spender,
    uint256 _addedValue
  )
    public
    returns (bool)
  {
    allowed[msg.sender][_spender] = (
      allowed[msg.sender][_spender].add(_addedValue));
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  /**
   * @dev Decrease the amount of tokens that an owner allowed to a spender.
   * approve should be called when allowed[_spender] == 0. To decrement
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _subtractedValue The amount of tokens to decrease the allowance by.
   */
  function decreaseApproval(
    address _spender,
    uint256 _subtractedValue
  )
    public
    returns (bool)
  {
    uint256 oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

// File: zeppelin-solidity/contracts/ownership/Ownable.sol

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
   * @notice Renouncing to ownership will leave the contract without an owner.
   * It will not be possible to call the functions with the `onlyOwner`
   * modifier anymore.
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

// File: zeppelin-solidity/contracts/lifecycle/Pausable.sol

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

// File: contracts/MarketDataStorage.sol

contract MarketDataStorage is Ownable {
    // vars
    address[] supportedTokens;
    mapping (address => bool) public supportedTokensMapping; // same as supportedTokens just in a mapping for quicker lookup
    mapping (address => uint[]) public currentTokenMarketData; // represent the last token data
    mapping (bytes32 => bool) internal validIds; // for Oraclize callbacks
    address dataUpdater; // who is allowed to update data

    // modifiers
    modifier updaterOnly() {
        require(
            msg.sender == dataUpdater,
            "updater not allowed"
        );
        _;
    }

    modifier supportedTokenOnly(address token_address) {
        require(
            isTokenSupported(token_address),
            "Can&#39;t update a non supported token"
        );
        _;
    }

    constructor (address[] _supportedTokens, address _dataUpdater) Ownable() public {
        dataUpdater = _dataUpdater;

        // to populate supportedTokensMapping
        for (uint i=0; i<_supportedTokens.length; i++) {
            addSupportedToken(_supportedTokens[i]);
        }
    }

    function numberOfSupportedTokens() view public returns (uint) {
        return supportedTokens.length;
    }

    function getSupportedTokenByIndex(uint idx) view public returns (address token_address, bool supported_status) {
        address token = supportedTokens[idx];
        return (token, supportedTokensMapping[token]);
    }

    function getMarketDataByTokenIdx(uint idx) view public returns (address token_address, uint volume, uint depth, uint marketcap) {
        (address token, bool status) = getSupportedTokenByIndex(idx);

        (uint _volume, uint _depth, uint _marketcap) = getMarketData(token);

        return (token, _volume, _depth, _marketcap);
    }

    function getMarketData(address token_address) view public returns (uint volume, uint depth, uint marketcap) {
        // we do not throw an exception for non supported tokens, simply return 0,0,0
        if (!supportedTokensMapping[token_address]) {
            return (0,0,0);
        }

        uint[] memory data = currentTokenMarketData[token_address];
        return (data[0], data[1], data[2]);
    }

    function addSupportedToken(address token_address) public onlyOwner {
        require(
            isTokenSupported(token_address) == false,
            "Token already added"
        );

        supportedTokens.push(token_address);
        supportedTokensMapping[token_address] = true;

        currentTokenMarketData[token_address] = [0,0,0]; // until next update
    }

    function isTokenSupported(address token_address) view public returns (bool) {
        return supportedTokensMapping[token_address];
    }

    // update Data
    function updateMarketData(address token_address,
        uint volume,
        uint depth,
        uint marketcap)
    external
    updaterOnly
    supportedTokenOnly(token_address) {
        currentTokenMarketData[token_address] = [volume,depth,marketcap];
    }
}

// File: contracts/WarOfTokens.sol

contract WarOfTokens is Pausable {
    using SafeMath for uint256;

    struct AttackInfo {
        address attacker;
        address attackee;
        uint attackerScore;
        uint attackeeScore;
        bytes32 attackId;
        bool completed;
        uint hodlSpellBlockNumber;
        mapping (address => uint256) attackerWinnings;
        mapping (address => uint256) attackeeWinnings;
    }

    // events
    event Deposit(address token, address user, uint amount, uint balance);
    event Withdraw(address token, address user, uint amount, uint balance);
    event UserActiveStatusChanged(address user, bool isActive);
    event Attack (
        address indexed attacker,
        address indexed attackee,
        bytes32 attackId,
        uint attackPrizePercent,
        uint base,
        uint hodlSpellBlockNumber
    );
    event AttackCompleted (
        bytes32 indexed attackId,
        address indexed winner,
        uint attackeeActualScore
    );

    // vars
    /**
    *   mapping of token addresses to mapping of account balances (token=0 means Ether)
    */
    mapping (address => mapping (address => uint256)) public tokens;
    mapping (address => bool) public activeUsers;
    address public cdtTokenAddress;
    uint256 public minCDTToParticipate;
    MarketDataStorage public marketDataOracle;
    uint public maxAttackPrizePercent; // if attacker and attackee have the same score, whats the max % of their assets will be as prize
    uint attackPricePrecentBase = 1000; // since EVM doesn&#39;t support floating numbers yet.
    uint public maxOpenAttacks = 5;
    mapping (bytes32 => AttackInfo) public attackIdToInfo;
    mapping (address => mapping(address => bytes32)) public userToUserToAttackId;
    mapping (address => uint) public cntUserAttacks; // keeps track of how many un-completed attacks user has


    // modifiers
    modifier activeUserOnly(address user) {
        require(
            isActiveUser(user),
            "User not active"
        );
        _;
    }

    constructor(address _cdtTokenAddress,
        uint256 _minCDTToParticipate,
        address _marketDataOracleAddress,
        uint _maxAttackPrizeRatio)
    Pausable()
    public {
        cdtTokenAddress = _cdtTokenAddress;
        minCDTToParticipate = _minCDTToParticipate;
        marketDataOracle = MarketDataStorage(_marketDataOracleAddress);
        setMaxAttackPrizePercent(_maxAttackPrizeRatio);
    }

    // don&#39;t allow default
    function() public {
        revert("Please do not send ETH without calling the deposit function. We will not do it automatically to validate your intent");
    }

    // user management
    function isActiveUser(address user) view public returns (bool) {
        return activeUsers[user];
    }

    ////////////////////////////////////////////////////////
    //
    //  balances management
    //
    ////////////////////////////////////////////////////////

    // taken from https://etherscan.io/address/0x8d12a197cb00d4747a1fe03395095ce2a5cc6819#code
    /**
    *   disabled when contract is paused
    */
    function deposit() payable external whenNotPaused {
        tokens[0][msg.sender] = tokens[0][msg.sender].add(msg.value);
        emit Deposit(0, msg.sender, msg.value, tokens[0][msg.sender]);

        _validateUserActive(msg.sender);
    }

    /**
    *   disabled when contract is paused
    */
    function depositToken(address token, uint amount) external whenNotPaused {
        //remember to call StandardToken(address).approve(this, amount) or this contract will not be able to do the transfer on your behalf.
        require(
            token!=0,
            "unrecognized token"
        );
        assert(StandardToken(token).transferFrom(msg.sender, this, amount));
        tokens[token][msg.sender] =  tokens[token][msg.sender].add(amount);
        emit Deposit(token, msg.sender, amount, tokens[token][msg.sender]);

        _validateUserActive(msg.sender);
    }

    function withdraw(uint amount) external {
        tokens[0][msg.sender] = tokens[0][msg.sender].sub(amount);
        assert(msg.sender.call.value(amount)());
        emit Withdraw(0, msg.sender, amount, tokens[0][msg.sender]);

        _validateUserActive(msg.sender);
    }

    function withdrawToken(address token, uint amount) external {
        require(
            token!=0,
            "unrecognized token"
        );
        tokens[token][msg.sender] = tokens[token][msg.sender].sub(amount);
        assert(StandardToken(token).transfer(msg.sender, amount));
        emit Withdraw(token, msg.sender, amount, tokens[token][msg.sender]);

        _validateUserActive(msg.sender);
    }

    function balanceOf(address token, address user) view public returns (uint) {
        return tokens[token][user];
    }

    ////////////////////////////////////////////////////////
    //
    //  combat functions
    //
    ////////////////////////////////////////////////////////
    function setMaxAttackPrizePercent(uint newAttackPrize) onlyOwner public {
        require(
            newAttackPrize < 5,
            "max prize is 5 percent of funds"
        );
        maxAttackPrizePercent = newAttackPrize;
    }

    function setMaxOpenAttacks(uint newValue) onlyOwner public {
        maxOpenAttacks = newValue;
    }

    function openAttacksCount(address user) view public returns (uint) {
        return cntUserAttacks[user];
    }

    function isTokenSupported(address token_address) view public returns (bool) {
        return marketDataOracle.isTokenSupported(token_address);
    }

    function getUserScore(address user)
    view
    public
    whenNotPaused
    returns (uint) {
        uint cnt_supported_tokens = marketDataOracle.numberOfSupportedTokens();
        uint aggregated_score = 0;
        for (uint i=0; i<cnt_supported_tokens; i++) {
            (address token_address, uint volume, uint depth, uint marketcap) = marketDataOracle.getMarketDataByTokenIdx(i);
            uint256 user_balance = balanceOf(token_address, user);

            aggregated_score = aggregated_score + _calculateScore(user_balance, volume, depth, marketcap);
        }

        return aggregated_score;
    }

    function _calculateScore(uint256 balance, uint volume, uint depth, uint marketcap) pure internal returns (uint) {
        return balance * volume * depth * marketcap;
    }

    function attack(address attackee)
    external
    activeUserOnly(msg.sender)
    activeUserOnly(attackee)
    {
        require(
            msg.sender != attackee,
            "Can&#39;t attack yourself"
        );
        require(
            userToUserToAttackId[msg.sender][attackee] == 0,
            "Cannot attack while pending attack exists, please complete attack"
        );
        require(
            openAttacksCount(msg.sender) < maxOpenAttacks,
            "Too many open attacks for attacker"
        );
        require(
            openAttacksCount(attackee) < maxOpenAttacks,
            "Too many open attacks for attackee"
        );

        (uint attackPrizePercent, uint attackerScore, uint attackeeScore) = attackPrizeRatio(attackee);

        AttackInfo memory attackInfo = AttackInfo(
            msg.sender,
            attackee,
            attackerScore,
            attackeeScore,
            sha256(abi.encodePacked(msg.sender, attackee, block.blockhash(block.number-1))), // attack Id
            false,
            block.number // block after insertion of attack tx the complete function can be called
        );
        _registerAttack(attackInfo);

        _calculateWinnings(attackIdToInfo[attackInfo.attackId], attackPrizePercent);

        emit Attack(
            attackInfo.attacker,
            attackInfo.attackee,
            attackInfo.attackId,
            attackPrizePercent,
            attackPricePrecentBase,
            attackInfo.hodlSpellBlockNumber
        );
    }

    /**
    *   Returns the % of the attacker/ attackee funds are for winning/ loosing
    *   we multiple the values by a base since solidity does not support
    *   floating values.
    */
    function attackPrizeRatio(address attackee)
    view
    public
    returns (uint attackPrizePercent, uint attackerScore, uint attackeeScore) {
        uint _attackerScore = getUserScore(msg.sender);
        require(
            _attackerScore > 0,
            "attacker score is 0"
        );
        uint _attackeeScore = getUserScore(attackee);
        require(
            _attackeeScore > 0,
            "attackee score is 0"
        );

        uint howCloseAreThey = _attackeeScore.mul(attackPricePrecentBase).div(_attackerScore);

        return (howCloseAreThey, _attackerScore, _attackeeScore);
    }

    function attackerPrizeByToken(bytes32 attackId, address token_address) view public returns (uint256) {
        return attackIdToInfo[attackId].attackerWinnings[token_address];
    }

    function attackeePrizeByToken(bytes32 attackId, address token_address) view public returns (uint256) {
        return attackIdToInfo[attackId].attackeeWinnings[token_address];
    }

    // anyone can call the complete attack function.
    function completeAttack(bytes32 attackId) public {
        AttackInfo storage attackInfo = attackIdToInfo[attackId];

        (address winner, uint attackeeActualScore) = getWinner(attackId);

        // distribuite winngs
        uint cnt_supported_tokens = marketDataOracle.numberOfSupportedTokens();
        for (uint i=0; i<cnt_supported_tokens; i++) {
            (address token_address, bool status) = marketDataOracle.getSupportedTokenByIndex(i);

            if (attackInfo.attacker == winner) {
                uint winnings = attackInfo.attackerWinnings[token_address];

                if (winnings > 0) {
                    tokens[token_address][attackInfo.attackee] = tokens[token_address][attackInfo.attackee].sub(winnings);
                    tokens[token_address][attackInfo.attacker] = tokens[token_address][attackInfo.attacker].add(winnings);
                }
            }
            else {
                uint loosings = attackInfo.attackeeWinnings[token_address];

                if (loosings > 0) {
                    tokens[token_address][attackInfo.attacker] = tokens[token_address][attackInfo.attacker].sub(loosings);
                    tokens[token_address][attackInfo.attackee] = tokens[token_address][attackInfo.attackee].add(loosings);
                }
            }
        }

        // cleanup
        _unregisterAttack(attackId);

        emit AttackCompleted(
            attackId,
            winner,
            attackeeActualScore
        );
    }

    function getWinner(bytes32 attackId) public view returns(address winner, uint attackeeActualScore) {
        require(
            block.number >= attackInfo.hodlSpellBlockNumber,
            "attack can not be completed at this block, please wait"
        );

        AttackInfo storage attackInfo = attackIdToInfo[attackId];

        //  block.blockhash records only for the recent 256 blocks
        //  https://solidity.readthedocs.io/en/v0.3.1/units-and-global-variables.html#block-and-transaction-properties
        //  So... attacker has 256 blocks to call completeAttack
        //  otherwise win goes automatically to the attackee
        if (block.number - attackInfo.hodlSpellBlockNumber >= 256) {
            return (attackInfo.attackee, attackInfo.attackeeScore);
        }

        bytes32 blockHash = block.blockhash(attackInfo.hodlSpellBlockNumber);
        return _calculateWinnerBasedOnEntropy(attackInfo, blockHash);
    }

    ////////////////////////////////////////////////////////
    //
    //  internal functions
    //
    ////////////////////////////////////////////////////////

    // validates user active status
    function _validateUserActive(address user) private {
        // get CDT balance
        uint256 cdt_balance = balanceOf(cdtTokenAddress, user);

        bool new_active_state = cdt_balance >= minCDTToParticipate;
        bool current_active_state = activeUsers[user]; // could be false if never set up

        if (current_active_state != new_active_state) { // only emit on activity change
            emit UserActiveStatusChanged(user, new_active_state);
        }

        activeUsers[user] = new_active_state;
    }

    function _registerAttack(AttackInfo attackInfo) internal {
        userToUserToAttackId[attackInfo.attacker][attackInfo.attackee] = attackInfo.attackId;
        userToUserToAttackId[attackInfo.attackee][attackInfo.attacker] = attackInfo.attackId;

        attackIdToInfo[attackInfo.attackId] = attackInfo;

        // update open attacks counter
        cntUserAttacks[attackInfo.attacker] = cntUserAttacks[attackInfo.attacker].add(1);
        cntUserAttacks[attackInfo.attackee] = cntUserAttacks[attackInfo.attackee].add(1);
    }

    function _unregisterAttack(bytes32 attackId) internal {
        AttackInfo storage attackInfo = attackIdToInfo[attackId];

        cntUserAttacks[attackInfo.attacker] = cntUserAttacks[attackInfo.attacker].sub(1);
        cntUserAttacks[attackInfo.attackee] = cntUserAttacks[attackInfo.attackee].sub(1);

        delete userToUserToAttackId[attackInfo.attacker][attackInfo.attackee];
        delete userToUserToAttackId[attackInfo.attackee][attackInfo.attacker];

        delete attackIdToInfo[attackId];
    }

    /**
       if the attacker has a higher/ equal score to the attackee than the prize will be at max maxAttackPrizePercent
       if the attacker has lower score than the prize can be higher than maxAttackPrizePercent since he takes a bigger risk
   */
    function _calculateWinnings(AttackInfo storage attackInfo, uint attackPrizePercent) internal {
        // get all user balances and calc winnings from that
        uint cnt_supported_tokens = marketDataOracle.numberOfSupportedTokens();

        uint actualPrizeRation = attackPrizePercent
        .mul(maxAttackPrizePercent);


        for (uint i=0; i<cnt_supported_tokens; i++) {
            (address token_address, bool status) = marketDataOracle.getSupportedTokenByIndex(i);

            if (status) {
                // attacker
                uint256 _b1 = balanceOf(token_address, attackInfo.attacker);
                if (_b1 > 0) {
                    uint256 _w1 = _b1.mul(actualPrizeRation).div(attackPricePrecentBase * 100); // 100 since maxAttackPrizePercent has 100 basis
                    attackInfo.attackeeWinnings[token_address] = _w1;
                }

                // attackee
                uint256 _b2 = balanceOf(token_address, attackInfo.attackee);
                if (_b2 > 0) {
                    uint256 _w2 = _b2.mul(actualPrizeRation).div(attackPricePrecentBase * 100); // 100 since maxAttackPrizePercent has 100 basis
                    attackInfo.attackerWinnings[token_address] = _w2;
                }
            }
        }
    }

    //
    // winner logic:
    //  1) get difference in scores between players times 2
    //  2) get hodl spell block number (decided in the attack call), do hash % {result of step 1}
    //  3) block hash mod 10 to decide direction
    //  4) if result step 3 > 1 than we add result step 2 to attackee&#39;s score (80% chance for this to happen)
    //  5) else reduce attacke&#39;s score by result of step 2
    //
    //
    //
    // Since the attacker decides if to attack or not we give the attackee a defending chance by
    // adopting the random HODL spell.
    // if the attacker has a higher score than attackee than the HODL spell will randomly add (most probably) to the
    // attackee score. this might or might not be enought to beat the attacker.
    //
    // if the attacker has a lower score than the attackee than he takes a bigger chance in attacking and he will get a bigger reward.
    //
    //
    // just like in crypto life, HODLing has its risks and rewards. Be carefull in your trading decisions!
    function _calculateWinnerBasedOnEntropy(AttackInfo storage attackInfo, bytes32 entropy) view internal returns(address, uint) {
        uint attackeeActualScore = attackInfo.attackeeScore;
        uint modul = _absSubtraction(attackInfo.attackerScore, attackInfo.attackeeScore);
        modul = modul.mul(2); // attacker score is now right in the middle of the range
        uint hodlSpell = uint(entropy) % modul;
        uint direction = uint(entropy) % 10;
        uint directionThreshold = 1;

        // direction is 80% chance positive (meaning adding the hodl spell)
        // to the weakest player
        if (attackInfo.attackerScore < attackInfo.attackeeScore) {
            directionThreshold = 8;
        }

        // winner calculation
        if (direction > directionThreshold) {
            attackeeActualScore = attackeeActualScore.add(hodlSpell);
        }
        else {
            attackeeActualScore = _safeSubtract(attackeeActualScore, hodlSpell);
        }
        if (attackInfo.attackerScore > attackeeActualScore) { return (attackInfo.attacker, attackeeActualScore); }
        else { return (attackInfo.attackee, attackeeActualScore); }
    }

    // will subtract 2 uint and returns abs(result).
    // example: a=2,b=3 returns 1
    // example: a=3,b=2 returns 1
    function _absSubtraction(uint a, uint b) pure internal returns (uint) {
        if (b>a) {
            return b-a;
        }

        return a-b;
    }

    // example: a=2,b=3 returns 0
    // example: a=3,b=2 returns 1
    function _safeSubtract(uint a, uint b) pure internal returns (uint) {
        if (b > a) {
            return 0;
        }

        return a-b;
    }
}