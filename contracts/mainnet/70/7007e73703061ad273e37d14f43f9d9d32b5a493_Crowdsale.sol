pragma solidity ^0.4.18;

pragma solidity ^0.4.18;

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
    uint256 public totalSupply;
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
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
 * @title Basic contracts
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic {
    using SafeMath for uint256;

    mapping(address => uint256) balances;

    /**
    * @dev transfer contracts for a specified address
    * @param _to The address to transfer to.
    * @param _value The amount to be transferred.
    */
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);

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
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

}


/**
 * @title Burnable Token
 * @dev Token that can be irreversibly burned (destroyed).
 */
contract BurnableToken is BasicToken {

    event Burn(address indexed burner, uint256 value);

    /**
     * @dev Burns a specific amount of tokens.
     * @param _value The amount of contracts to be burned.
     */
    function burn(uint256 _value) public {
        require(_value <= balances[msg.sender]);
        // no need to require value <= totalSupply, since that would imply the
        // sender&#39;s balance is greater than the totalSupply, which *should* be an assertion failure

        address burner = msg.sender;
        balances[burner] = balances[burner].sub(_value);
        totalSupply = totalSupply.sub(_value);
        emit Burn(burner, _value);
    }
}


/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}



/**
 * @title Standard ERC20 contracts
 *
 * @dev Implementation of the basic standard contracts.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is ERC20, BasicToken {

    mapping (address => mapping (address => uint256)) internal allowed;


    /**
     * @dev Transfer tokens from one address to another
     * @param _from address The address which you want to send tokens from
     * @param _to address The address which you want to transfer to
     * @param _value uint256 the amount of tokens to be transferred
     */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
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
     *
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
    function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
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
    function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
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
 * @title Pausable token
 *
 * @dev StandardToken modified with pausable transfers.
 **/

contract PausableToken is StandardToken, Pausable {

    function transfer(address _to, uint256 _value) public whenNotPaused returns (bool) {
        return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool) {
        return super.transferFrom(_from, _to, _value);
    }

    function approve(address _spender, uint256 _value) public whenNotPaused returns (bool) {
        return super.approve(_spender, _value);
    }

    function increaseApproval(address _spender, uint _addedValue) public whenNotPaused returns (bool success) {
        return super.increaseApproval(_spender, _addedValue);
    }

    function decreaseApproval(address _spender, uint _subtractedValue) public whenNotPaused returns (bool success) {
        return super.decreaseApproval(_spender, _subtractedValue);
    }

}

contract PAXToken is BurnableToken, PausableToken {

    using SafeMath for uint;

    string public constant name = "Pax Token";

    string public constant symbol = "PAX";

    uint32 public constant decimals = 10;

    uint256 public constant INITIAL_SUPPLY = 999500000 * (10 ** uint256(decimals));

    /**
     * @dev Constructor that gives msg.sender all of existing tokens.
     * @param _company address reserve tokens (300000000)
     * @param _founders_1 address reserve tokens (300000000)
     * @param _founders_2 address reserve tokens (50000000)
     * @param _isPause bool (pause === true)
     */
    function PAXToken(address _company, address _founders_1, address _founders_2, bool _isPause) public {
        require(_company != address(0) && _founders_1 != address(0) && _founders_2 != address(0));
        paused = _isPause;
        totalSupply = INITIAL_SUPPLY;
        balances[msg.sender] = 349500000 * (10 ** uint256(decimals));
        balances[_company] = 300000000 * (10 ** uint256(decimals));
        balances[_founders_1] = 300000000 * (10 ** uint256(decimals));
        balances[_founders_2] = 50000000 * (10 ** uint256(decimals));
        emit Transfer(0x0, msg.sender, balances[msg.sender]);
        emit Transfer(0x0, _company, balances[_company]);
        emit Transfer(0x0, _founders_1, balances[_founders_1]);
        emit Transfer(0x0, _founders_2, balances[_founders_2]);

    }

    /**
    * @dev transfer contracts for a specified address, despite the pause state
    * @param _to The address to transfer to.
    * @param _value The amount to be transferred.
    */
    function ownersTransfer(address _to, uint256 _value) public onlyOwner returns (bool) {
        return BasicToken.transfer(_to, _value);
    }
}

contract Crowdsale is Pausable {

    struct stageInfo {
        uint start;
        uint stop;
        uint duration;
        uint bonus;
        uint limit;
    }

    /**
     * @dev Mapping with stageId = stageInfo
     */
    mapping (uint => stageInfo) public stages;

    /**
     * @dev Mapping with adress = with balance
     */
    mapping(address => uint) public balances;

    /**
     * @dev Softcap
     */
    uint public constant softcap = 2500 ether;

    /**
     * @dev xDecimals
     */
    uint public constant decimals = 1E10;

    /**
     * @dev ICO Period Number
     */
    uint public period = 5;

    /**
     * @dev Total number of minted tokens
     */
    uint public hardcap;

    /**
     * @dev Cost of the token
     */
    uint public rate;

    /**
     * @dev Number of sold tokens
     */
    uint public totalSold = 0;

    /**
     * @dev Assembled Eth
     */
    uint256 public sumWei;

    /**
     * @dev ICO Status
     */
    bool public state;

    /**
     * @dev Once call flag
     */
    bool public requireOnce = true;

    /**
     * @dev Once burning flag
     */
    bool public isBurned;

    /**
     * @dev Reserve tokens adress for company (300000000)
     */
    address public company;

    /**
     * @dev Reserve tokens adress for founders first (300000000)
     */
    address public founders_1;

    /**
     * @dev Reserve tokens adress for founders second (50000000)
     */
    address public founders_2;

    /**
     * @dev The address to which the received ether will be sent
     */
    address public multisig;

    /**
     * @dev Tokens classes
     */
    PAXToken public token;

    /**
     * @dev Number of coins for the typical period
     */
    uint private constant typicalBonus = 100;

    /**
     * @dev Sending tokens
     */
    uint private sendingTokens;

    /**
     * @dev Time left
     */
    uint private timeLeft;

    /**
     * @dev Pause date
     */
    uint private pauseDate;

    /**
     * @dev Paused by value flag
     */
    bool private pausedByValue;

    /**
     * @dev Manual pause flag
     */
    bool private manualPause;


    event StartICO();

    event StopICO();

    event BurnUnsoldTokens();

    event NewWalletAddress(address _to);

    event Refund(address _wallet, uint _val);

    event DateMoved(uint value);

    using SafeMath for uint;

    modifier saleIsOn() {
        require(state);
        uint stageId = getStageId();
        if (period != stageId || stageId == 5) {
            usersPause();
            (msg.sender).transfer(msg.value);
        }
        else
            _;
    }

    modifier isUnderHardCap() {
        uint tokenBalance = token.balanceOf(this);
        require(
            tokenBalance <= hardcap &&
            tokenBalance >= 500
        );
        _;
    }


    function Crowdsale(address _company, address _founders_1, address _founders_2, address _token) public {
        multisig = owner;
        rate = (uint)(1 ether).div(5000);

        stages[0] = stageInfo({
            start: 0,
            stop: 0,
            duration: 14 days,
            bonus: 130,
            limit:  44500000 * decimals
            });

        stages[1] = stageInfo({
            start: 0,
            stop: 0,
            duration: 14 days,
            bonus: 115,
            limit:  85000000 * decimals
            });

        stages[2] = stageInfo({
            start: 0,
            stop: 0,
            duration: 14 days,
            bonus: 110,
            limit:  100000000 * decimals
            });

        stages[3] = stageInfo({
            start: 0,
            stop: 0,
            duration: 14 days,
            bonus: 105,
            limit:  120000000 * decimals
            });

        hardcap = 349500000 * decimals;

        token = PAXToken(_token);

        company = _company;
        founders_1 = _founders_1;
        founders_2 = _founders_2;
    }


    /**
     * @dev Fallback function
     */
    function() whenNotPaused saleIsOn external payable {
        require (msg.value > 0);
        sendTokens(msg.value, msg.sender);
    }

    /**
     * @dev Manual sending tokens
     * @param _to address where sending tokens
     * @param _value uint256 value tokens for sending
     */
    function manualSendTokens(address _to, uint256 _value) public onlyOwner returns(bool) {
        uint tokens = _value;
        uint avalibleTokens = token.balanceOf(this);

        if (tokens < avalibleTokens) {
            if (tokens <= stages[3].limit) {
                stages[3].limit = (stages[3].limit).sub(tokens);
            } else if (tokens <= (stages[3].limit).add(stages[2].limit)) {
                stages[2].limit = (stages[2].limit).sub(tokens.sub(stages[3].limit));
                stages[3].limit = 0;
            } else if (tokens <= (stages[3].limit).add(stages[2].limit).add(stages[1].limit)) {
                stages[1].limit = (stages[1].limit).sub(tokens.sub(stages[3].limit).sub(stages[2].limit));
                stages[3].limit = 0;
                stages[2].limit = 0;
            } else if (tokens <= (stages[3].limit).add(stages[2].limit).add(stages[1].limit).add(stages[0].limit)) {
                stages[0].limit = (stages[0].limit).sub(tokens.sub(stages[3].limit).sub(stages[2].limit).sub(stages[1].limit));
                stages[3].limit = 0;
                stages[2].limit = 0;
                stages[1].limit = 0;
            }
        } else {
            tokens = avalibleTokens;
            stages[3].limit = 0;
            stages[2].limit = 0;
            stages[1].limit = 0;
            stages[0].limit = 0;
        }

        sendingTokens = sendingTokens.add(tokens);
        sumWei = sumWei.add(tokens.mul(rate).div(decimals));
        totalSold = totalSold.add(tokens);
        token.ownersTransfer(_to, tokens);

        return true;
    }

    /**
     * @dev Return Etherium all investors
     */
    function refund() public {
        require(sumWei < softcap && !state);
        uint value = balances[msg.sender];
        balances[msg.sender] = 0;
        emit Refund(msg.sender, value);
        msg.sender.transfer(value);
    }

    /**
     * @dev Burning all tokens on mintAddress
     */
    function burnUnsoldTokens() onlyOwner public returns(bool) {
        require(!state);
        require(!isBurned);
        isBurned = true;
        emit BurnUnsoldTokens();
        token.burn(token.balanceOf(this));
        if (token.paused()) {
            token.unpause();
        }
        return true;
    }

    /**
     * @dev Starting ICO
     */
    function startICO() public onlyOwner returns(bool) {
        require(stages[0].start >= now);
        require(requireOnce);
        requireOnce = false;
        state = true;
        period = 0;
        emit StartICO();
        token.ownersTransfer(company, (uint)(300000000).mul(decimals));
        token.ownersTransfer(founders_1, (uint)(300000000).mul(decimals));
        token.ownersTransfer(founders_2, (uint)(50000000).mul(decimals));
        return true;
    }

    /**
     * @dev Turning off the ICO
     */
    function stopICO() onlyOwner public returns(bool) {
        state = false;
        emit StopICO();
        if (token.paused()) {
            token.unpause();
        }
        return true;
    }

    /**
     * @dev called by the owner to pause, triggers stopped state
     */
    function pause() onlyOwner whenNotPaused public {
        manualPause = true;
        usersPause();
    }

    /**
     * @dev called by the owner to unpause, returns to normal state
     */
    function unpause() onlyOwner whenPaused public {
        uint shift = now.sub(pauseDate);
        dateMove(shift);
        period = getStageId();
        pausedByValue = false;
        manualPause = false;
        super.unpause();
    }

    /**
     * @dev Withdrawal Etherium from smart-contract
     */
    function withDrawal() public onlyOwner {
        if(!state && sumWei >= softcap) {
            multisig.transfer(address(this).balance);
        }
    }

    /**
     * @dev Returns stage id
     */
    function getStageId() public view returns(uint) {
        uint stageId;
        uint today = now;

        if (today < stages[0].stop) {
            stageId = 0;

        } else if (today >= stages[1].start &&
        today < stages[1].stop ) {
            stageId = 1;

        } else if (today >= stages[2].start &&
        today < stages[2].stop ) {
            stageId = 2;

        } else if (today >= stages[3].start &&
        today < stages[3].stop ) {
            stageId = 3;

        } else if (today >= stages[3].stop) {
            stageId = 4;

        } else {
            return 5;
        }

        uint tempId = (stageId > period) ? stageId : period;
        return tempId;
    }

    /**
     * @dev Returns Limit of coins for the period and Number of coins taking
     * into account the bonus for the period
     */
    function getStageData() public view returns(uint tempLimit, uint tempBonus) {
        uint stageId = getStageId();
        tempBonus = stages[stageId].bonus;

        if (stageId == 0) {
            tempLimit = stages[0].limit;

        } else if (stageId == 1) {
            tempLimit = (stages[0].limit).add(stages[1].limit);

        } else if (stageId == 2) {
            tempLimit = (stages[0].limit).add(stages[1].limit).add(stages[2].limit);

        } else if (stageId == 3) {
            tempLimit = (stages[0].limit).add(stages[1].limit).add(stages[2].limit).add(stages[3].limit);

        } else {
            tempLimit = token.balanceOf(this);
            tempBonus = typicalBonus;
            return;
        }
        tempLimit = tempLimit.sub(totalSold);
        return;
    }

    /**
     * @dev Returns the amount for which you can redeem all tokens for the current period
     */
    function calculateStagePrice() public view returns(uint price) {
        uint limit;
        uint bonusCoefficient;
        (limit, bonusCoefficient) = getStageData();

        price = limit.mul(rate).mul(100).div(bonusCoefficient).div(decimals);
    }

    /**
     * @dev Sending tokens to the recipient, based on the amount of ether that it sent
     * @param _etherValue uint Amount of sent ether
     * @param _to address The address which you want to transfer to
     */
    function sendTokens(uint _etherValue, address _to) internal isUnderHardCap {
        uint limit;
        uint bonusCoefficient;
        (limit, bonusCoefficient) = getStageData();
        uint tokens = (_etherValue).mul(bonusCoefficient).mul(decimals).div(100);
        tokens = tokens.div(rate);
        bool needPause;

        if (tokens > limit) {
            needPause = true;
            uint stageEther = calculateStagePrice();
            period++;
            if (period == 4) {
                balances[msg.sender] = balances[msg.sender].add(stageEther);
                sumWei = sumWei.add(stageEther);
                token.ownersTransfer(_to, limit);
                totalSold = totalSold.add(limit);
                _to.transfer(_etherValue.sub(stageEther));
                state = false;
                return;
            }
            balances[msg.sender] = balances[msg.sender].add(stageEther);
            sumWei = sumWei.add(stageEther);
            token.ownersTransfer(_to, limit);
            totalSold = totalSold.add(limit);
            sendTokens(_etherValue.sub(stageEther), _to);

        } else {
            require(tokens <= token.balanceOf(this));
            if (limit.sub(tokens) < 500) {
                needPause = true;
                period++;
            }
            balances[msg.sender] = balances[msg.sender].add(_etherValue);
            sumWei = sumWei.add(_etherValue);
            token.ownersTransfer(_to, tokens);
            totalSold = totalSold.add(tokens);
        }

        if (needPause) {
            pausedByValue = true;
            usersPause();
        }
    }

    /**
     * @dev called by the contract to pause, triggers stopped state
     */
    function usersPause() private {
        pauseDate = now;
        paused = true;
        emit Pause();
    }

    /**
     * @dev Moving date after the pause
     * @param _shift uint Time in seconds
     */
    function dateMove(uint _shift) private returns(bool) {
        require(_shift > 0);

        uint i;

        if (pausedByValue) {
            stages[period].start = now;
            stages[period].stop = (stages[period].start).add(stages[period].duration);

            for (i = period + 1; i < 4; i++) {
                stages[i].start = stages[i - 1].stop;
                stages[i].stop = (stages[i].start).add(stages[i].duration);
            }

        } else {
            if (manualPause) stages[period].stop = (stages[period].stop).add(_shift);

            for (i = period + 1; i < 4; i++) {
                stages[i].start = (stages[i].start).add(_shift);
                stages[i].stop = (stages[i].stop).add(_shift);
            }
        }

        emit DateMoved(_shift);

        return true;
    }

    /**
     * @dev Returns the total number of tokens available for sale
     */
    function tokensAmount() public view returns(uint) {
        return token.balanceOf(this);
    }

    /**
     * @dev Returns number of supplied tokens
     */
    function tokensSupply() public view returns(uint) {
        return token.totalSupply();
    }

    /**
     * @dev Set start date
     * @param _start uint Time start
     */
    function setStartDate(uint _start) public onlyOwner returns(bool) {
        require(_start > now);
        require(requireOnce);

        stages[0].start = _start;
        stages[0].stop = _start.add(stages[0].duration);
        stages[1].start = stages[0].stop;
        stages[1].stop = stages[1].start.add(stages[1].duration);
        stages[2].start = stages[1].stop;
        stages[2].stop = stages[2].start.add(stages[2].duration);
        stages[3].start = stages[2].stop;
        stages[3].stop = stages[3].start.add(stages[3].duration);

        return true;
    }

    /**
     * @dev Sets new multisig address to which the received ether will be sent
     * @param _to address
     */
    function setMultisig(address _to) public onlyOwner returns(bool) {
        require(_to != address(0));
        multisig = _to;
        emit NewWalletAddress(_to);
        return true;
    }

    /**
     * @dev Change first adress with reserve(300000000 tokens)
     * @param _company address
     */
    function setReserveForCompany(address _company) public onlyOwner {
        require(_company != address(0));
        require(requireOnce);
        company = _company;
    }

    /**
     * @dev Change second adress with reserve(300000000 tokens)
     * @param _founders_1 address
     */
    function setReserveForFoundersFirst(address _founders_1) public onlyOwner {
        require(_founders_1 != address(0));
        require(requireOnce);
        founders_1 = _founders_1;
    }

    /**
     * @dev Change third adress with reserve(50000000 tokens)
     * @param _founders_2 address
     */
    function setReserveForFoundersSecond(address _founders_2) public onlyOwner {
        require(_founders_2 != address(0));
        require(requireOnce);
        founders_2 = _founders_2;
    }

}