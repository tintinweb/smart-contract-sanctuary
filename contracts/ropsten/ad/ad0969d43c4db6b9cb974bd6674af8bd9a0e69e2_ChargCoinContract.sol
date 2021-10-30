/**
 *Submitted for verification at Etherscan.io on 2021-10-29
*/

pragma solidity ^0.4.26;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}


/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
    uint256 public totalSupply = 90000000 * 10 ** 18;

    function balanceOf(address who) public constant returns (uint256);

    function transfer(address to, uint256 value) public returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
}


/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public constant returns (uint256);

    function transferFrom(address from, address to, uint256 value) public returns (bool);

    function approve(address spender, uint256 value) public returns (bool);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}


/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic {
    using SafeMath for uint256;

    mapping (address => uint256) balances;

    /**
    * @dev transfer token for a specified address
    * @param _to The address to transfer to.
    * @param _value The amount to be transferred.
    */
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));

        // SafeMath.sub will throw if there is not enough balance.
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
    function balanceOf(address _owner) public constant returns (uint256 balance) {
        return balances[_owner];
    }

}


/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is ERC20, BasicToken {

    mapping (address => mapping (address => uint256)) allowed;


    /**
     * @dev Transfer tokens from one address to another
     * @param _from address The address which you want to send tokens from
     * @param _to address The address which you want to transfer to
     * @param _value uint256 the amount of tokens to be transferred
     */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));

        uint256 _allowance = allowed[_from][msg.sender];

        // Check is not needed because sub(_allowance, _value) will already throw if this condition is not met
        // require (_value <= _allowance);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = _allowance.sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    /**
     * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
     *
     * Beware that changing an allowance with this method brings the risk that someone may use both the old
     * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
     * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
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
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    /**
     * approve should be called when allowed[_spender] == 0. To increment
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     */
    function increaseApproval(address _spender, uint _addedValue) public returns (bool success) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function decreaseApproval(address _spender, uint _subtractedValue)
    public returns (bool success) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        }
        else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

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
    function transferOwnership(address newOwner) onlyOwner public {
        require(newOwner != address(0));
        owner = newOwner;
    }
}


/*
 * ChargCoinContract
 *
 * Simple ERC20 Token example, with crowdsale token creation
 */
contract ChargCoinContract is StandardToken, Ownable {

    string public standard = "CHG";
    string public name = "Charg Coin";
    string public symbol = "CHG";

    uint public decimals = 18;

    address public multisig = 0x482EFd447bE88748e7625e2b7c522c388970B790;

    struct ChargingData {
    address node;
    uint startTime;
    uint endTime;
    uint256 fixedRate;
    bool initialized;
    uint256 predefinedAmount;
    }

    struct ParkingData {
    address node;
    uint startTime;
    uint endTime;
    uint256 fixedRate;
    bool initialized;
    uint256 predefinedAmount;
    }

    mapping (address => uint256) public authorized;

    mapping (address => uint256) public rateOfCharging;
    mapping (address => uint256) public rateOfParking;

    mapping (address => ChargingData) public chargingSwitches;
    mapping (address => ParkingData) public parkingSwitches;

    mapping (address => uint256) public reservedFundsCharging;
    mapping (address => uint256) public reservedFundsParking;

    // 1 ETH = 800 CHARG tokens (1 CHARG = 0.59 USD)
    uint PRICE = 800;

    struct ContributorData {
    uint contributionAmount;
    uint tokensIssued;
    }

    function ChargCoinContract() public {
        balances[msg.sender] = totalSupply;
    }

    mapping (address => ContributorData) public contributorList;

    uint nextContributorIndex;

    mapping (uint => address) contributorIndexes;

    state public crowdsaleState = state.pendingStart;
    enum state {pendingStart, crowdsale, crowdsaleEnded}

    event CrowdsaleStarted(uint blockNumber);

    event CrowdsaleEnded(uint blockNumber);

    event ErrorSendingETH(address to, uint amount);

    event MinCapReached(uint blockNumber);

    event MaxCapReached(uint blockNumber);

    uint public constant BEGIN_TIME = 1512319965;

    uint public constant END_TIME = 1514764800;

    uint public minCap = 1 ether;

    uint public maxCap = 12500 ether;

    uint public ethRaised = 0;

    uint public totalSupply = 90000000 * 10 ** decimals;

    uint crowdsaleTokenCap = 10000000 * 10 ** decimals; // 11.11%
    uint foundersAndTeamTokens = 9000000 * 10 ** decimals; // 10%
    uint DistroFundTokens = 69000000 * 10 ** decimals; // 76.67%
	uint BountyTokens = 2000000 * 10 ** decimals; // 2.22%

    bool foundersAndTeamTokensClaimed = false;
    bool DistroFundTokensClaimed = false;
	bool BountyTokensClaimed = false;

    uint nextContributorToClaim;

    mapping (address => bool) hasClaimedEthWhenFail;

    function() payable public {
        require(msg.value != 0);
        require(crowdsaleState != state.crowdsaleEnded);
        // Check if crowdsale has ended

        bool stateChanged = checkCrowdsaleState();
        // Check blocks and calibrate crowdsale state

        if (crowdsaleState == state.crowdsale) {
            createTokens(msg.sender);
            // Process transaction and issue tokens

        }
        else {
            refundTransaction(stateChanged);
            // Set state and return funds or throw
        }
    }

    //
    // Check crowdsale state and calibrate it
    //
    function checkCrowdsaleState() internal returns (bool) {
        if (ethRaised >= maxCap && crowdsaleState != state.crowdsaleEnded) {// Check if max cap is reached
            crowdsaleState = state.crowdsaleEnded;
            emit CrowdsaleEnded(block.number);
            // Raise event
            return true;
        }

        if (now >= END_TIME) {
            crowdsaleState = state.crowdsaleEnded;
            emit CrowdsaleEnded(block.number);
            // Raise event
            return true;
        }

        if (now >= BEGIN_TIME && now < END_TIME) {// Check if we are in crowdsale state
            if (crowdsaleState != state.crowdsale) {// Check if state needs to be changed
                crowdsaleState = state.crowdsale;
                // Set new state
                emit CrowdsaleStarted(block.number);
                // Raise event
                return true;
            }
        }

        return false;
    }

    //
    // Decide if throw or only return ether
    //
    function refundTransaction(bool _stateChanged) internal {
        if (_stateChanged) {
            msg.sender.transfer(msg.value);
        }
        else {
            revert();
        }
    }

    function createTokens(address _contributor) payable public {

        uint _amount = msg.value;

        uint contributionAmount = _amount;
        uint returnAmount = 0;

        if (_amount > (maxCap - ethRaised)) {// Check if max contribution is lower than _amount sent
            contributionAmount = maxCap - ethRaised;
            // Set that user contibutes his maximum alowed contribution
            returnAmount = _amount - contributionAmount;
            // Calculate how much he must get back
        }

        if (ethRaised + contributionAmount > minCap && minCap > ethRaised) {
            emit MinCapReached(block.number);
        }

        if (ethRaised + contributionAmount == maxCap && ethRaised < maxCap) {
            emit MaxCapReached(block.number);
        }

        if (contributorList[_contributor].contributionAmount == 0) {
            contributorIndexes[nextContributorIndex] = _contributor;
            nextContributorIndex += 1;
        }

        contributorList[_contributor].contributionAmount += contributionAmount;
        ethRaised += contributionAmount;
        // Add to eth raised

        uint256 tokenAmount = calculateEthToChargcoin(contributionAmount);
        // Calculate how much tokens must contributor get
        if (tokenAmount > 0) {
            transferToContributor(_contributor, tokenAmount);
            contributorList[_contributor].tokensIssued += tokenAmount;
            // log token issuance
        }

        if (!multisig.send(msg.value)) {
            revert();
        }
    }


    function transferToContributor(address _to, uint256 _value)  public {
        balances[owner] = balances[owner].sub(_value);
        balances[_to] = balances[_to].add(_value);
    }

    function calculateEthToChargcoin(uint _eth) constant public returns (uint256) {

        uint tokens = _eth.mul(getPrice());
        uint percentage = 0;

        if (ethRaised > 0) {
            percentage = ethRaised * 100 / maxCap;
        }

        return tokens + getAmountBonus(tokens);
    }

    function getAmountBonus(uint tokens) pure public returns (uint) {
        uint amountBonus = 0;

        if (tokens >= 10000) amountBonus = tokens;
        else if (tokens >= 5000) amountBonus = tokens * 60 / 100;
        else if (tokens >= 1000) amountBonus = tokens * 30 / 100;
        else if (tokens >= 500) amountBonus = tokens * 10 / 100;
        else if (tokens >= 100) amountBonus = tokens * 5 / 100;
        else if (tokens >= 10) amountBonus = tokens * 1 / 100;

        return amountBonus;
    }

    // replace this with any other price function
    function getPrice() constant public returns (uint result) {
        return PRICE;
    }

    //
    // Owner can batch return contributors contributions(eth)
    //
    function batchReturnEthIfFailed(uint _numberOfReturns) onlyOwner public {
        require(crowdsaleState != state.crowdsaleEnded);
        // Check if crowdsale has ended
        require(ethRaised < minCap);
        // Check if crowdsale has failed
        address currentParticipantAddress;
        uint contribution;
        for (uint cnt = 0; cnt < _numberOfReturns; cnt++) {
            currentParticipantAddress = contributorIndexes[nextContributorToClaim];
            // Get next unclaimed participant
            if (currentParticipantAddress == 0x0) return;
            // Check if all the participants were compensated
            if (!hasClaimedEthWhenFail[currentParticipantAddress]) {// Check if participant has already claimed
                contribution = contributorList[currentParticipantAddress].contributionAmount;
                // Get contribution of participant
                hasClaimedEthWhenFail[currentParticipantAddress] = true;
                // Set that he has claimed
                balances[currentParticipantAddress] = 0;
                if (!currentParticipantAddress.send(contribution)) {// Refund eth
                    emit ErrorSendingETH(currentParticipantAddress, contribution);
                    // If there is an issue raise event for manual recovery
                }
            }
            nextContributorToClaim += 1;
            // Repeat
        }
    }

    //
    // Owner can set multisig address for crowdsale
    //
    function setMultisigAddress(address _newAddress) onlyOwner public {
        multisig = _newAddress;
    }

    //
    // Registers node with rate
    //
    function registerNode(uint256 chargingRate, uint256 parkingRate) public {
        if (authorized[msg.sender] == 1) revert();

        rateOfCharging[msg.sender] = chargingRate;
        rateOfParking[msg.sender] = parkingRate;
        authorized[msg.sender] = 1;
    }

    // 
    // Block node
    //
    function blockNode (address node) onlyOwner public {
        authorized[node] = 0;
    }

    //
    // Updates node charging rate
    // 
    function updateChargingRate (uint256 rate) public {
        rateOfCharging[msg.sender] = rate;
    }

    //
    // Updates node parking rate
    // 
    function updateParkingRate (uint256 rate) public {
        rateOfCharging[msg.sender] = rate;
    }

    function chargeOn (address node, uint time) public {
        // Prevent from not authorized nodes
        if (authorized[node] == 0) revert();
        // Prevent from double charging
        if (chargingSwitches[msg.sender].initialized) revert();

        // Determine endTime
        uint endTime = now + time;

        // Prevent from past dates
        if (endTime <= now) revert();

        // Calculate the amount of tokens has to be taken from users account
        uint256 predefinedAmount = (endTime - now) * rateOfCharging[node];

        if (balances[msg.sender] < predefinedAmount) revert();

        chargingSwitches[msg.sender] = ChargingData(node, now, endTime, rateOfCharging[node], true, predefinedAmount);
        balances[msg.sender] = balances[msg.sender].sub(predefinedAmount);
        reservedFundsCharging[msg.sender] = reservedFundsCharging[msg.sender].add(predefinedAmount);
    }

    function chargeOff (address node) public {
        // Check that initialization happened
        if (!chargingSwitches[msg.sender].initialized) revert();
        // Calculate the amount depending on rate
        uint256 amount = (now - chargingSwitches[msg.sender].startTime) * chargingSwitches[msg.sender].fixedRate;
        // Maximum can be predefinedAmount, if it less than that, return tokens
        amount = amount > chargingSwitches[msg.sender].predefinedAmount ? chargingSwitches[msg.sender].predefinedAmount : amount;

        // Take tokens from reserFunds and put it on balance
        balances[node] = balances[node] + amount;
        reservedFundsCharging[msg.sender] = reservedFundsCharging[msg.sender] - amount;

        // When amount is less than predefinedAmount, return other tokens to user
        if (reservedFundsCharging[msg.sender] > 0) {
            balances[msg.sender] = balances[msg.sender] + reservedFundsCharging[msg.sender];
            reservedFundsCharging[msg.sender] = 0;
        }

        // Uninitialize
        chargingSwitches[msg.sender].node = 0;
        chargingSwitches[msg.sender].startTime = 0;
        chargingSwitches[msg.sender].endTime = 0;
        chargingSwitches[msg.sender].fixedRate = 0;
        chargingSwitches[msg.sender].initialized = false;
        chargingSwitches[msg.sender].predefinedAmount = 0;
    }

    function parkingOn (address node, uint time) public {
        // Prevent from not authorized nodes
        if (authorized[node] == 0) revert();
        // Prevent from double charging
        if (parkingSwitches[msg.sender].initialized) revert();

        if (balances[msg.sender] < predefinedAmount) revert();

        uint endTime = now + time;

        // Prevent from past dates
        if (endTime <= now) revert();

        uint256 predefinedAmount = (endTime - now) * rateOfParking[node];

        parkingSwitches[msg.sender] = ParkingData(node, now, endTime, rateOfParking[node], true, predefinedAmount);
        balances[msg.sender] = balances[msg.sender].sub(predefinedAmount);
        reservedFundsParking[msg.sender] = reservedFundsParking[msg.sender].add(predefinedAmount);
    }

    // Parking off     
    function parkingOff (address node) public {
        if (!parkingSwitches[msg.sender].initialized) revert();

        // Calculate the amount depending on rate
        uint256 amount = (now - parkingSwitches[msg.sender].startTime) * parkingSwitches[msg.sender].fixedRate;
        // Maximum can be predefinedAmount, if it less than that, return tokens
        amount = amount > parkingSwitches[msg.sender].predefinedAmount ? parkingSwitches[msg.sender].predefinedAmount : amount;

        balances[node] = balances[node] + amount;
        reservedFundsParking[msg.sender] = reservedFundsParking[msg.sender] - amount;

        //  
        if (reservedFundsParking[msg.sender] > 0) {
            balances[msg.sender] = balances[msg.sender] + reservedFundsParking[msg.sender];
            // all tokens taken, set to 0
            reservedFundsParking[msg.sender] = 0;
        }

        // Uninitialize
        parkingSwitches[msg.sender].node = 0;
        parkingSwitches[msg.sender].startTime = 0;
        parkingSwitches[msg.sender].endTime = 0;
        parkingSwitches[msg.sender].fixedRate = 0;
        parkingSwitches[msg.sender].initialized = false;
        parkingSwitches[msg.sender].predefinedAmount = 0;
    }

}