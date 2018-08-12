pragma solidity ^0.4.24;

/**
* MXC Smart Contract for Ethereum
* 
* Copyright 2018 MXC Foundation
*
*/


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


/**
* @title ERC20Basic
* @dev Simpler version of ERC20 interface
*/
contract ERC20Basic {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}


/**
* @title ERC20 interface
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


/**
* @title Standard ERC20 token
*
* @dev Implementation of the basic standard token.
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
    * race condition is to first reduce the spender&#39;s allowance to 0 and set the desired value afterwards,
    * i.e. clients SHOULD make sure to create user interfaces in such a way 
    * that they set the allowance first to 0 before setting it to another value for the same spender. 
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


contract MXCToken is StandardToken {

    string public constant name = "MXCToken";
    string public constant symbol = "MXC";
    uint8 public constant decimals = 18;

    uint256 constant MONTH = 3600*24*30;

    struct TimeLock {
        // total amount of tokens that is granted to the user
        uint256 amount;

        // total amount of tokens that have been vested
        uint256 vestedAmount;

        // total amount of vested months (tokens are vested on a monthly basis)
        uint16 vestedMonths;

        // token timestamp start
        uint256 start;

        // token timestamp release start (when user can start receive vested tokens)
        uint256 cliff;

        // token timestamp release end (when all the tokens can be vested)
        uint256 vesting;

        address from;
    }

    mapping(address => TimeLock) timeLocks;

    event NewTokenGrant(address indexed _from, address indexed _to, uint256 _amount, uint256 _start, uint256 _cliff, uint256 _vesting);
    event VestedTokenRedeemed(address indexed _to, uint256 _amount, uint256 _vestedMonths);
    event GrantedTokenReturned(address indexed _from, address indexed _to, uint256 _amount);

    /**
    * @dev Constructor that gives msg.sender all of existing tokens.
    */
    constructor() public {
        totalSupply_ = 2664965800 * (10 ** uint256(decimals));
        balances[msg.sender] = totalSupply_;
        emit Transfer(address(0), msg.sender, totalSupply_);
    }

    function vestBalanceOf(address who)
        public view
        returns (uint256 amount, uint256 vestedAmount, uint256 start, uint256 cliff, uint256 vesting)
    {
        require(who != address(0));
        amount = timeLocks[who].amount;
        vestedAmount = timeLocks[who].vestedAmount;
        start = timeLocks[who].start;
        cliff = timeLocks[who].cliff;
        vesting = timeLocks[who].vesting;
    }

    /**
    * @dev Function to grant the amount of tokens that will be vested later.
    * @param _to The address which will own the tokens.
    * @param _amount The amount of tokens that will be vested later.
    * @param _start Token timestamp start.
    * @param _cliff Token timestamp release start.
    * @param _vesting Token timestamp release end.
    */
    function grantToken(
        address _to,
        uint256 _amount,
        uint256 _start,
        uint256 _cliff,
        uint256 _vesting
    )
        public
        returns (bool success)
    {
        require(_to != address(0));
        require(_amount <= balances[msg.sender], "Not enough balance to grant token.");
        require(_amount > 0, "Nothing to transfer.");
        require((timeLocks[_to].amount.sub(timeLocks[_to].vestedAmount) == 0), "The previous vesting should be completed.");
        require(_cliff >= _start, "_cliff must be >= _start");
        require(_vesting > _start, "_vesting must be bigger than _start");
        require(_vesting > _cliff, "_vesting must be bigger than _cliff");

        balances[msg.sender] = balances[msg.sender].sub(_amount);
        timeLocks[_to] = TimeLock(_amount, 0, 0, _start, _cliff, _vesting, msg.sender);

        emit NewTokenGrant(msg.sender, _to, _amount, _start, _cliff, _vesting);
        return true;
    }

    /**
    * @dev Function to grant the amount of tokens that will be vested later.
    * @param _to The address which will own the tokens.
    * @param _amount The amount of tokens that will be vested later.
    * @param _cliffMonths Token release start in months from now.
    * @param _vestingMonths Token release end in months from now.
    */
    function grantTokenStartNow(
        address _to,
        uint256 _amount,
        uint256 _cliffMonths,
        uint256 _vestingMonths
    )
        public
        returns (bool success)
    {
        return grantToken(
            _to,
            _amount,
            now,
            now.add(_cliffMonths.mul(MONTH)),
            now.add(_vestingMonths.mul(MONTH))
            );
    }

    /**
    * @dev Function to calculate the amount of tokens that can be vested at this moment.
    * @param _to The address which will own the tokens.
    * @return amount - A uint256 specifying the amount of tokens available to be vested at this moment.
    * @return vestedMonths - A uint256 specifying the number of the vested months since the last vesting.
    * @return curTime - A uint256 specifying the current timestamp.
    */
    function calcVestableToken(address _to)
        internal view
        returns (uint256 amount, uint256 vestedMonths, uint256 curTime)
    {
        uint256 vestTotalMonths;
        uint256 vestedAmount;
        uint256 vestPart;
        amount = 0;
        vestedMonths = 0;
        curTime = now;
        
        require(timeLocks[_to].amount > 0, "Nothing was granted to this address.");
        
        if (curTime <= timeLocks[_to].cliff) {
            return (0, 0, curTime);
        }

        vestedMonths = curTime.sub(timeLocks[_to].start) / MONTH;
        vestedMonths = vestedMonths.sub(timeLocks[_to].vestedMonths);

        if (curTime >= timeLocks[_to].vesting) {
            return (timeLocks[_to].amount.sub(timeLocks[_to].vestedAmount), vestedMonths, curTime);
        }

        if (vestedMonths > 0) {
            vestTotalMonths = timeLocks[_to].vesting.sub(timeLocks[_to].start) / MONTH;
            vestPart = timeLocks[_to].amount.div(vestTotalMonths);
            amount = vestedMonths.mul(vestPart);
            vestedAmount = timeLocks[_to].vestedAmount.add(amount);
            if (vestedAmount > timeLocks[_to].amount) {
                amount = timeLocks[_to].amount.sub(timeLocks[_to].vestedAmount);
            }
        }

        return (amount, vestedMonths, curTime);
    }

    /**
    * @dev Function to redeem tokens that can be vested at this moment.
    * @param _to The address which will own the tokens.
    */
    function redeemVestableToken(address _to)
        public
        returns (bool success)
    {
        require(_to != address(0));
        require(timeLocks[_to].amount > 0, "Nothing was granted to this address!");
        require(timeLocks[_to].vestedAmount < timeLocks[_to].amount, "All tokens were vested!");

        (uint256 amount, uint256 vestedMonths, uint256 curTime) = calcVestableToken(_to);
        require(amount > 0, "Nothing to redeem now.");

        TimeLock storage t = timeLocks[_to];
        balances[_to] = balances[_to].add(amount);
        t.vestedAmount = t.vestedAmount.add(amount);
        t.vestedMonths = t.vestedMonths + uint16(vestedMonths);
        t.cliff = curTime;

        emit VestedTokenRedeemed(_to, amount, vestedMonths);
        return true;
    }

    /**
    * @dev Function to return granted token to the initial sender.
    * @param _amount - A uint256 specifying the amount of tokens to be returned.
    */
    function returnGrantedToken(uint256 _amount)
        public
        returns (bool success)
    {
        address to = timeLocks[msg.sender].from;
        require(to != address(0));
        require(_amount > 0, "Nothing to transfer.");
        require(timeLocks[msg.sender].amount > 0, "Nothing to return.");
        require(_amount <= timeLocks[msg.sender].amount.sub(timeLocks[msg.sender].vestedAmount), "Not enough granted token to return.");

        timeLocks[msg.sender].amount = timeLocks[msg.sender].amount.sub(_amount);
        balances[to] = balances[to].add(_amount);

        emit GrantedTokenReturned(msg.sender, to, _amount);
        return true;
    }

}