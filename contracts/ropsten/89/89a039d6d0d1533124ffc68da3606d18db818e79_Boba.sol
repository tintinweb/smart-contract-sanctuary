pragma solidity ^0.4.24;

// File: openzeppelin-solidity/contracts/math/SafeMath.sol

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

// File: zos-lib/contracts/migrations/Migratable.sol

/**
 * @title Migratable
 * Helper contract to support intialization and migration schemes between
 * different implementations of a contract in the context of upgradeability.
 * To use it, replace the constructor with a function that has the
 * `isInitializer` modifier starting with `"0"` as `migrationId`.
 * When you want to apply some migration code during an upgrade, increase
 * the `migrationId`. Or, if the migration code must be applied only after
 * another migration has been already applied, use the `isMigration` modifier.
 * This helper supports multiple inheritance.
 * WARNING: It is the developer&#39;s responsibility to ensure that migrations are
 * applied in a correct order, or that they are run at all.
 * See `Initializable` for a simpler version.
 */
contract Migratable {
  /**
   * @dev Emitted when the contract applies a migration.
   * @param contractName Name of the Contract.
   * @param migrationId Identifier of the migration applied.
   */
  event Migrated(string contractName, string migrationId);

  /**
   * @dev Mapping of the already applied migrations.
   * (contractName => (migrationId => bool))
   */
  mapping (string => mapping (string => bool)) internal migrated;

  /**
   * @dev Internal migration id used to specify that a contract has already been initialized.
   */
  string constant private INITIALIZED_ID = "initialized";


  /**
   * @dev Modifier to use in the initialization function of a contract.
   * @param contractName Name of the contract.
   * @param migrationId Identifier of the migration.
   */
  modifier isInitializer(string contractName, string migrationId) {
    validateMigrationIsPending(contractName, INITIALIZED_ID);
    validateMigrationIsPending(contractName, migrationId);
    _;
    emit Migrated(contractName, migrationId);
    migrated[contractName][migrationId] = true;
    migrated[contractName][INITIALIZED_ID] = true;
  }

  /**
   * @dev Modifier to use in the migration of a contract.
   * @param contractName Name of the contract.
   * @param requiredMigrationId Identifier of the previous migration, required
   * to apply new one.
   * @param newMigrationId Identifier of the new migration to be applied.
   */
  modifier isMigration(string contractName, string requiredMigrationId, string newMigrationId) {
    require(isMigrated(contractName, requiredMigrationId), "Prerequisite migration ID has not been run yet");
    validateMigrationIsPending(contractName, newMigrationId);
    _;
    emit Migrated(contractName, newMigrationId);
    migrated[contractName][newMigrationId] = true;
  }

  /**
   * @dev Returns true if the contract migration was applied.
   * @param contractName Name of the contract.
   * @param migrationId Identifier of the migration.
   * @return true if the contract migration was applied, false otherwise.
   */
  function isMigrated(string contractName, string migrationId) public view returns(bool) {
    return migrated[contractName][migrationId];
  }

  /**
   * @dev Initializer that marks the contract as initialized.
   * It is important to run this if you had deployed a previous version of a Migratable contract.
   * For more information see https://github.com/zeppelinos/zos-lib/issues/158.
   */
  function initialize() isInitializer("Migratable", "1.2.1") public {
  }

  /**
   * @dev Reverts if the requested migration was already executed.
   * @param contractName Name of the contract.
   * @param migrationId Identifier of the migration.
   */
  function validateMigrationIsPending(string contractName, string migrationId) private {
    require(!isMigrated(contractName, migrationId), "Requested target migration ID has already been run");
  }
}

// File: contracts/Boba.sol

/** A contract for smart game
 *  feature:
    - powh
    - draw
    - team
*/
contract Boba is Migratable {
    // ----------------- START OF DEPLOYED STORAGE ---------------------
    // We are using ZeppelinOS migration pattern with Proxy contract keeping the internal state
    // there for do not change the following variable&#39;s order or value type
    //
    // See for details: https://docs.zeppelinos.org/docs/advanced.html#preserving-the-storage-structure
    using SafeMath for uint;


    address public owner = msg.sender;
    uint public growthPot = 0;
    uint public countDownPot = 0;
    uint public totalMicroKeys = 0;
    uint public contributorPot = 0;
    uint public airdropPot = 0;
    uint public lastBuyKeyTime = 0;
    address public lastBuyer = 0;

    enum AirdropType { NADA, SMALL, MID, BIG }
    uint public smallAirDropTracker = 0; // incremented each time a buy tx occurs. used to determine how close an airdrop will happen
    uint public midAirDropTracker = 0;
    uint public bigAirDropTracker = 0;
    uint public txId = 0;       // keep track of the nth tx to this contract for airdrops
    uint8 constant private SMALL_AIRDROP_DIV = 100; // 1%
    uint8 constant private MID_AIRDROP_DIV = 15;    // about 7%
    uint8 constant private BIG_AIRDROP_DIV = 4;     // 25%

    uint public constant ROUND_TIME_LIMIT = 1 days;

    uint public constant AIRDROP_POT_PERCENT = 35;
    uint public constant GROWTH_POT_PERCENT = 20;  // the p3d pot
    uint public constant REFER_BONUS_PERCENT = 20;  // the referral pot
    uint public constant CONTRIBUTOR_POT_PERCENT = 2;
    uint public constant COUNT_DOWN_POT_PERCENT = 23; // the final pot
    uint public constant HANDLE_PRICE = 1e16;
    uint public constant INITIAL_KEY_PRICE = 1e9; // Price in Wei per MicroKey
    uint public constant LINEAR_INFLATION_RATE_PER_MICRO_KEY = 1;
    mapping(address => uint) internal keyHolding;

    mapping(address => uint) public countDownPayout;
    mapping(address => uint) public referPayout;
    mapping(address => uint) public airdropPayout;

    mapping(bytes32 => address) handleToLead;
    mapping(address => bytes32) leadToHandle;
    mapping(address => bytes32) userBelongsToHandle;

    mapping(address => bool) winnerRecord;
    // ----------------- END OF DEPLOYED STORAGE ---------------------

    event OnBoughtMicroKeys(
        uint microKeys_, string tweet_,
        uint totalCurrentMicroKeys_, bytes32 joinFromHandle_, bytes32 joinToHandle_,
        address user_
    );

    event OnWithdrawnAll(uint microKeys_, uint wei_, address user_);
    event OnWin(address winner_, uint countDownPot_, uint winnerTakes_);
    event OnRegisteredHandle(bytes32 handle_, address lead_);

    modifier onlyMyself(address addr_) {
        require(addr_ == msg.sender, "sorry you have to be yourself.");
        _;
    }

    modifier onlyWinner() {
        require(winnerRecord[msg.sender] == true, "Must be the winner.");
        _;
    }

    modifier onlyBy(address _account)
    {
        require(msg.sender == _account);
        // Do not forget the "_;"! It will
        // be replaced by the actual function
        // body when the modifier is used.
        _;
    }
    // The price needed to pay for the micro key
    function getWeiPriceMicroKeys() public view returns (uint price_) {
        return INITIAL_KEY_PRICE + (totalMicroKeys * LINEAR_INFLATION_RATE_PER_MICRO_KEY);
    }

    // The value per key
    function getValuePerMicroKey() public view returns (uint) {
        if (growthPot == 0 || totalMicroKeys == 0) return 0;
        else return growthPot.div(totalMicroKeys);
    }

    function getTotalMicroKeys() public view returns (uint) {
        return totalMicroKeys;
    }

    function getLastKeyTime() public view returns (uint) {
        return lastBuyKeyTime;
    }

    function isHandleAvailable(bytes32 handle_) public view returns (bool) {
        if (handleToLead[handle_] == address(0x0)) return true;
        else return false;
    }

    function initialize() isInitializer("Boba", "0") public {
        // TODO do storage migration instead
        lastBuyKeyTime = block.timestamp;
    }

    function getHolding(address addr_) public view
        returns  (uint) {
        return keyHolding[addr_];
    }

    function isWinner() public view returns(bool) {
        if (block.timestamp.sub(lastBuyKeyTime) > ROUND_TIME_LIMIT) {
            return true;
        } else {
            return false;
        }
    }

    function distributeWinnerPot() private {
        uint winnerTakes = countDownPot.mul(48).div(100);
        contributorPot = contributorPot.add((countDownPot.mul(2).div(100)));
        countDownPayout[lastBuyer] = countDownPayout[lastBuyer].add(winnerTakes);
        growthPot = growthPot.add((countDownPot.mul(25).div(100)));
        countDownPot = countDownPot.mul(25).div(100);
        emit OnWin(lastBuyer, countDownPot, winnerTakes);
    }

    function registerHandle(bytes32 handle) public payable {
        require (msg.value >= HANDLE_PRICE);
        require (handleToLead[handle] == 0);  // it has not been registered
        handleToLead[handle] = msg.sender;
        leadToHandle[msg.sender] = handle;

        contributorPot += msg.value;

        emit OnRegisteredHandle(handle, msg.sender);
    }

    function buyMicroKeys(string tweet_) public payable {
        buyMicroKeysWithHandle(tweet_, "");
    }

    function buyMicroKeysWithHandle(string tweet_, bytes32 handle_) public payable {
        require(bytes(tweet_).length <= 140);
        address _from = msg.sender;
        address _referer = handleToLead[handle_];

        txId += 1;
        smallAirDropTracker += 1;
        midAirDropTracker += 1;
        bigAirDropTracker += 1;

        if (shouldAirdrop() != AirdropType.NADA) {
            uint _airdropAmount;
            if (shouldAirdrop() == AirdropType.SMALL) {
                smallAirDropTracker = 0;
                _airdropAmount = airdropPot.div(SMALL_AIRDROP_DIV);
            }
            if (shouldAirdrop() == AirdropType.MID) {
                midAirDropTracker = 0;
                _airdropAmount = airdropPot.div(MID_AIRDROP_DIV);
            }
            if (shouldAirdrop() == AirdropType.BIG) {
                bigAirDropTracker = 0;
                _airdropAmount = airdropPot.div(BIG_AIRDROP_DIV);
            }
            airdropPot -= _airdropAmount;
            airdropPayout[_from] = _airdropAmount;
        }

        if (isWinner()) {
            winnerRecord[lastBuyer] = true;
            distributeWinnerPot();
        } else {
            lastBuyKeyTime = block.timestamp;
            lastBuyer = _from;
        }

        growthPot = growthPot.add((msg.value.mul(GROWTH_POT_PERCENT).div(100)));
        contributorPot = contributorPot.add((msg.value.mul(CONTRIBUTOR_POT_PERCENT).div(100)));
        airdropPot = airdropPot.add((msg.value.mul(AIRDROP_POT_PERCENT).div(100)));
        countDownPot = countDownPot.add((msg.value.mul(COUNT_DOWN_POT_PERCENT).div(100)));

        bytes32 _oldHandle = userBelongsToHandle[_from];
        bytes32 _newHandle = "";
        if (handle_.length > 0 && _referer != 0) { // only change team when using a nonempty handle
            _newHandle = handle_;
            userBelongsToHandle[_from] = _newHandle;
            referPayout[_from] = referPayout[_from].add((msg.value.mul(REFER_BONUS_PERCENT/2).div(100)));
            referPayout[_referer] = referPayout[_referer].add(msg.value.mul(REFER_BONUS_PERCENT/2).div(100));
        } else {
            growthPot = growthPot.add((msg.value.mul(REFER_BONUS_PERCENT/2).div(100)));
            contributorPot = contributorPot.add((msg.value.mul(REFER_BONUS_PERCENT/2).div(100)));
        }

        uint issuedMicroKeys = msg.value / getWeiPriceMicroKeys();
        keyHolding[_from] += issuedMicroKeys;
        totalMicroKeys += issuedMicroKeys;
        emit OnBoughtMicroKeys(
            issuedMicroKeys,
            tweet_,
            keyHolding[_from],
            _oldHandle,
            _newHandle,
            _from
        );
    }

    function withdrawAll() public {
        require (keyHolding[msg.sender] > 0);
        uint payment = growthPot * keyHolding[msg.sender] / totalMicroKeys;
        emit OnWithdrawnAll(keyHolding[msg.sender], payment, msg.sender);
        growthPot -= payment;
        totalMicroKeys -= keyHolding[msg.sender];
        keyHolding[msg.sender] = 0;
        msg.sender.transfer(payment);
    }

    function withdrawWinner() onlyWinner() public {
        uint _payment = countDownPayout[msg.sender];
        countDownPayout[msg.sender] = 0;
        msg.sender.transfer(_payment);
    }

    /**
     * @dev check if we have an airdrop event
     * @return NADA: no airdrop; SMALL: every 10th tx; MID: every 100th tx; BIG: every 500th tx
     */
    function shouldAirdrop() private view returns(AirdropType) {
        if (txId % 500 == 0) {
            return(AirdropType.BIG);
        } else if (txId % 100 == 0) {
            return(AirdropType.MID);
        } else if(txId % 10 == 0) {
            return(AirdropType.SMALL);
        }
        return(AirdropType.NADA);
    }

    function shouldGetHighFive() public pure returns (string) {
        return "High Five!";
    }

    function withdrawContributorPot() public onlyBy(owner) {
        uint _payment = contributorPot;
        contributorPot = 0;
        msg.sender.transfer(_payment);
    }

}