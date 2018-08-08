pragma solidity ^0.4.23;

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

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address public owner;

    event OwnershipRenounced(
        address indexed previousOwner
    );
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
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 value
    );
}

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

/**
 * @title PoSTokenStandard
 * @dev the interface of PoSTokenStandard
 */
contract PoSTokenStandard {
    uint256 public stakeStartTime;
    uint256 public stakeMinAge;
    uint256 public stakeMaxAge;
    function mint() public returns (bool);
    function coinAge() public view returns (uint256);
    function annualInterest() public view returns (uint256);
    function calculateReward() public view returns (uint256);
    function calculateRewardAt(uint256 _now) public view returns (uint256);
    event Mint(
        address indexed _address,
        uint256 _reward
    );
}

/**
 * @title TrueDeck TDP Token
 * @dev ERC20, PoS Token for TrueDeck Platform
 */
contract TrueDeckToken is ERC20, PoSTokenStandard, Pausable {
    using SafeMath for uint256;

    event CoinAgeRecordEvent(
        address indexed who,
        uint256 value,
        uint64 time
    );
    event CoinAgeResetEvent(
        address indexed who,
        uint256 value,
        uint64 time
    );

    string public constant name = "TrueDeck";
    string public constant symbol = "TDP";
    uint8 public constant decimals = 18;

    mapping (address => uint256) balances;

    mapping (address => mapping (address => uint256)) internal allowed;

    uint256 totalSupply_;

    /**
    * @dev Total Number of TDP tokens that can ever be created.
    *      200M TDP Tokens
    */
    uint256 public MAX_TOTAL_SUPPLY = 200000000 * 10 ** uint256(decimals);

    /**
    * @dev Initial supply of TDP tokens.
    *      70M TDP Tokens
    *      35% of Maximum Total Supply
    *      Will be distributed as follows:
    *           5% : Platform Partners
    *           1% : Pre-Airdrop
    *          15% : Mega-Airdrop
    *           4% : Bounty (Vested over 6 months)
    *          10% : Development (Vested over 12 months)
    */
    uint256 public INITIAL_SUPPLY = 70000000 * 10 ** uint256(decimals);

    /**
    * @dev Time at which the contract was deployed
    */
    uint256 public chainStartTime;

    /**
    * @dev Ethereum Blockchain Block Number at time the contract was deployed
    */
    uint256 public chainStartBlockNumber;

    /**
    * @dev To keep the record of a single incoming token transfer
    */
    struct CoinAgeRecord {
        uint256 amount;
        uint64 time;
    }

    /**
    * @dev To keep the coin age record for all addresses
    */
    mapping(address => CoinAgeRecord[]) coinAgeRecordMap;

    /**
     * @dev Modifier to make contract mint new tokens only
     *      - Staking has started.
     *      - When total supply has not reached MAX_TOTAL_SUPPLY.
     */
    modifier canMint() {
        require(stakeStartTime > 0 && now >= stakeStartTime && totalSupply_ < MAX_TOTAL_SUPPLY);            // solium-disable-line
        _;
    }

    constructor() public {
        chainStartTime = now;                                                                               // solium-disable-line
        chainStartBlockNumber = block.number;

        stakeMinAge = 3 days;
        stakeMaxAge = 60 days;

        balances[msg.sender] = INITIAL_SUPPLY;
        totalSupply_ = INITIAL_SUPPLY;
    }

    /**
    * @dev total number of tokens in existence
    */
    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }

    /**
    * @dev Transfer the specified amount of tokens to the specified address.
    *      This function works the same with the previous one
    *      but doesn&#39;t contain `_data` param.
    *      Added due to backwards compatibility reasons.
    * @param _to The address to transfer to.
    * @param _value The amount to be transferred.
    */
    function transfer(address _to, uint256 _value) public whenNotPaused returns (bool) {
        require(_to != address(0));

        if (msg.sender == _to) {
            return mint();
        }

        require(_value <= balances[msg.sender]);

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);

        logCoinAgeRecord(msg.sender, _to, _value);

        return true;
    }


    /**
     * @dev Transfer tokens from one address to another
     * @param _from address The address which you want to send tokens from
     * @param _to address The address which you want to transfer to
     * @param _value uint256 the amount of tokens to be transferred
     */
    function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);

        // Coin age should not be recorded if receiver is the sender.
        if (_from != _to) {
            logCoinAgeRecord(_from, _to, _value);
        }

        return true;
    }

    /**
     * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
     *
     * Beware that changing an allowance with this method brings the risk that someone may use both the old
     * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
     * race condition is to first reduce the spender&#39;s allowance to 0 and set the desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     * @param _spender The address which will spend the funds.
     * @param _value The amount of tokens to be spent.
     */
    function approve(address _spender, uint256 _value) public whenNotPaused returns (bool) {
        require(_spender != address(0));
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
    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }

    /**
     * @dev Increase the amount of tokens that an owner allowed to a spender.
     *
     * approve should be called when allowed[_spender] == 0. To increment
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * @param _spender The address which will spend the funds.
     * @param _addedValue The amount of tokens to increase the allowance by.
     */
    function increaseApproval(address _spender, uint256 _addedValue) public whenNotPaused returns (bool) {
        require(_spender != address(0));
        allowed[msg.sender][_spender] = (allowed[msg.sender][_spender].add(_addedValue));
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    /**
     * @dev Decrease the amount of tokens that an owner allowed to a spender.
     *
     * approve should be called when allowed[_spender] == 0. To decrement
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * @param _spender The address which will spend the funds.
     * @param _subtractedValue The amount of tokens to decrease the allowance by.
     */
    function decreaseApproval(address _spender, uint256 _subtractedValue) public whenNotPaused returns (bool) {
        require(_spender != address(0));
        uint256 oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
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

    /**
    * @dev Mints new TDP token and rewards to caller as per the coin age.
    *      Deletes all previous coinage records and resets with new coin age record.
    */
    function mint() public whenNotPaused canMint returns (bool) {
        if (balances[msg.sender] <= 0) {
            return false;
        }

        if (coinAgeRecordMap[msg.sender].length <= 0) {
            return false;
        }

        uint256 reward = calculateRewardInternal(msg.sender, now);                                          // solium-disable-line
        if (reward <= 0) {
            return false;
        }

        if (reward > MAX_TOTAL_SUPPLY.sub(totalSupply_)) {
            reward = MAX_TOTAL_SUPPLY.sub(totalSupply_);
        }

        totalSupply_ = totalSupply_.add(reward);
        balances[msg.sender] = balances[msg.sender].add(reward);
        emit Mint(msg.sender, reward);
        emit Transfer(address(0), msg.sender, reward);

        uint64 _now = uint64(now);                                                                          // solium-disable-line
        delete coinAgeRecordMap[msg.sender];
        coinAgeRecordMap[msg.sender].push(CoinAgeRecord(balances[msg.sender], _now));
        emit CoinAgeResetEvent(msg.sender, balances[msg.sender], _now);

        return true;
    }

    /**
    * @dev Returns coinage for the caller address
    */
    function coinAge() public view returns (uint256) {
        return getCoinAgeInternal(msg.sender, now);                                                         // solium-disable-line
    }

    /**
    * @dev Returns current annual interest
    */
    function annualInterest() public view returns(uint256) {
        return getAnnualInterest(now);                                                                      // solium-disable-line
    }

    /**
    * @dev Calculates and returns proof-of-stake reward
    */
    function calculateReward() public view returns (uint256) {
        return calculateRewardInternal(msg.sender, now);                                                    // solium-disable-line
    }

    /**
    * @dev Calculates and returns proof-of-stake reward for provided time
    *
    * @param _now timestamp The time for which the reward will be calculated
    */
    function calculateRewardAt(uint256 _now) public view returns (uint256) {
        return calculateRewardInternal(msg.sender, _now);
    }

    /**
    * @dev Returns coinage record for the given address and index
    *
    * @param _address address The address for which coinage record will be fetched
    * @param _index index The index of coinage record for that address
    */
    function coinAgeRecordForAddress(address _address, uint256 _index) public view onlyOwner returns (uint256, uint64) {
        if (coinAgeRecordMap[_address].length > _index) {
            return (coinAgeRecordMap[_address][_index].amount, coinAgeRecordMap[_address][_index].time);
        } else {
            return (0, 0);
        }
    }

    /**
    * @dev Returns coinage for the caller address
    *
    * @param _address address The address for which coinage will be calculated
    */
    function coinAgeForAddress(address _address) public view onlyOwner returns (uint256) {
        return getCoinAgeInternal(_address, now);                                                           // solium-disable-line
    }

    /**
    * @dev Returns coinage for the caller address
    *
    * @param _address address The address for which coinage will be calculated
    * @param _now timestamp The time for which the coinage will be calculated
    */
    function coinAgeForAddressAt(address _address, uint256 _now) public view onlyOwner returns (uint256) {
        return getCoinAgeInternal(_address, _now);
    }

    /**
    * @dev Calculates and returns proof-of-stake reward for provided address and time
    *
    * @param _address address The address for which reward will be calculated
    */
    function calculateRewardForAddress(address _address) public view onlyOwner returns (uint256) {
        return calculateRewardInternal(_address, now);                                                      // solium-disable-line
    }

    /**
    * @dev Calculates and returns proof-of-stake reward for provided address and time
    *
    * @param _address address The address for which reward will be calculated
    * @param _now timestamp The time for which the reward will be calculated
    */
    function calculateRewardForAddressAt(address _address, uint256 _now) public view onlyOwner returns (uint256) {
        return calculateRewardInternal(_address, _now);
    }

    /**
    * @dev Sets the stake start time
    */
    function startStakingAt(uint256 timestamp) public onlyOwner {
        require(stakeStartTime <= 0 && timestamp >= chainStartTime && timestamp > now);                     // solium-disable-line
        stakeStartTime = timestamp;
    }

    /**
    * @dev Returns true if the given _address is a contract, false otherwise.
    */
    function isContract(address _address) private view returns (bool) {
        uint256 length;
        /* solium-disable-next-line */
        assembly {
            //retrieve the size of the code on target address, this needs assembly
            length := extcodesize(_address)
        }
        return (length>0);
    }


    /**
    * @dev Logs coinage record for sender and receiver.
    *      Deletes sender&#39;s previous coinage records if any.
    *      Doesn&#39;t record coinage for contracts.
    *
    * @param _from address The address which you want to send tokens from
    * @param _to address The address which you want to transfer to
    * @param _value uint256 the amount of tokens to be transferred
    */
    function logCoinAgeRecord(address _from, address _to, uint256 _value) private returns (bool) {
        if (coinAgeRecordMap[_from].length > 0) {
            delete coinAgeRecordMap[_from];
        }

        uint64 _now = uint64(now);                                                                          // solium-disable-line

        if (balances[_from] != 0 && !isContract(_from)) {
            coinAgeRecordMap[_from].push(CoinAgeRecord(balances[_from], _now));
            emit CoinAgeResetEvent(_from, balances[_from], _now);
        }

        if (_value != 0 && !isContract(_to)) {
            coinAgeRecordMap[_to].push(CoinAgeRecord(_value, _now));
            emit CoinAgeRecordEvent(_to, _value, _now);
        }

        return true;
    }

    /**
    * @dev Calculates and returns proof-of-stake reward for provided address
    *
    * @param _address address The address for which reward will be calculated
    * @param _now timestamp The time for which the reward will be calculated
    */
    function calculateRewardInternal(address _address, uint256 _now) private view returns (uint256) {
        uint256 _coinAge = getCoinAgeInternal(_address, _now);
        if (_coinAge <= 0) {
            return 0;
        }

        uint256 interest = getAnnualInterest(_now);

        return (_coinAge.mul(interest)).div(365 * 100);
    }

    /**
    * @dev Calculates the coin age for given address and time.
    *
    * @param _address address The address for which coinage will be calculated
    * @param _now timestamp The time for which the coinage will be calculated
    */
    function getCoinAgeInternal(address _address, uint256 _now) private view returns (uint256 _coinAge) {
        if (coinAgeRecordMap[_address].length <= 0) {
            return 0;
        }

        for (uint256 i = 0; i < coinAgeRecordMap[_address].length; i++) {
            if (_now < uint256(coinAgeRecordMap[_address][i].time).add(stakeMinAge)) {
                continue;
            }

            uint256 secondsPassed = _now.sub(uint256(coinAgeRecordMap[_address][i].time));
            if (secondsPassed > stakeMaxAge ) {
                secondsPassed = stakeMaxAge;
            }

            _coinAge = _coinAge.add((coinAgeRecordMap[_address][i].amount).mul(secondsPassed.div(1 days)));
        }
    }

    /**
    * @dev Returns the annual interest rate for given time
    *
    * @param _now timestamp The time for which the annual interest will be calculated
    */
    function getAnnualInterest(uint256 _now) private view returns(uint256 interest) {
        if (stakeStartTime > 0 && _now >= stakeStartTime && totalSupply_ < MAX_TOTAL_SUPPLY) {
            uint256 secondsPassed = _now.sub(stakeStartTime);
            // 1st Year = 30% annually
            if (secondsPassed <= 365 days) {
                interest = 30;
            } else if (secondsPassed <= 547 days) {  // 2nd Year, 1st Half = 25% annually
                interest = 25;
            } else if (secondsPassed <= 730 days) {  // 2nd Year, 2nd Half = 20% annually
                interest = 20;
            } else if (secondsPassed <= 911 days) {  // 3rd Year, 1st Half = 15% annually
                interest = 15;
            } else if (secondsPassed <= 1094 days) {  // 3rd Year, 2nd Half = 10% annually
                interest = 10;
            } else {  // 4th Year Onwards = 5% annually
                interest = 5;
            }
        } else {
            interest = 0;
        }
    }

    /**
    * @dev Batch token transfer. Used by contract creator to distribute initial tokens.
    *      Does not record any coinage for the owner.
    *
    * @param _recipients Array of address
    * @param _values Array of amount
    */
    function batchTransfer(address[] _recipients, uint256[] _values) public onlyOwner returns (bool) {
        require(_recipients.length > 0 && _recipients.length == _values.length);

        uint256 total = 0;
        for(uint256 i = 0; i < _values.length; i++) {
            total = total.add(_values[i]);
        }
        require(total <= balances[msg.sender]);

        uint64 _now = uint64(now);                                                                          // solium-disable-line
        for(uint256 j = 0; j < _recipients.length; j++){
            balances[_recipients[j]] = balances[_recipients[j]].add(_values[j]);
            balances[msg.sender] = balances[msg.sender].sub(_values[j]);
            emit Transfer(msg.sender, _recipients[j], _values[j]);

            coinAgeRecordMap[_recipients[j]].push(CoinAgeRecord(_values[j], _now));
            emit CoinAgeRecordEvent(_recipients[j], _values[j], _now);
        }

        return true;
    }
}