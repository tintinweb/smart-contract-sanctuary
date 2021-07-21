//SourceUnit: T2XDice.sol

pragma solidity 0.5.10;

import "./TRC20.sol"; 

contract T2XDice is TRC20 {
    address public house = msg.sender;
	
    uint public jackpotFund;
	uint public jackpotPercent = 5;
	mapping (address => bool) private lastRollWasHouse;
	
    address private lastSender;
    address private lastOrigin;
    
    uint public startTime;
	
    uint private totalPlayers;
    uint private totalInvested;
	uint private totalRolls;
	uint private totalJackpots;
		
	uint public minBet = 1 * 10**8;
	uint public maxBet = 1000000 * 10**8;
	
	TRC20 private t2xToken;
    	
    mapping (address => bool) private registeredPlayer;
    mapping (address => uint) private invested;
	mapping (address => uint) private winnings;
	mapping (address => uint) private rolls;
	mapping (address => uint) private jackpots;
    
    event Dice(address indexed from, bool bettingOver, uint256 bet, uint256 prize, uint256 number, uint256 overOrUnder, bool jackpot);
    
    uint private seed;
 
	function stats() public view returns(uint tPlayers, uint tInvested, uint tRolls, uint tJackpots, uint pInvested, uint pWinnings, uint pRolls, uint pJackpots, uint min, uint max){
		return (totalPlayers, totalInvested, totalRolls, totalJackpots, invested[msg.sender], winnings[msg.sender], rolls[msg.sender], jackpots[msg.sender], minBet, maxBet);
	}
 
    modifier notContract() {
        lastSender = msg.sender;
        lastOrigin = tx.origin;
        require(lastSender == lastOrigin);
        _;
    }
    
    modifier onlyHouse() {
        require(msg.sender == house);
        _;
    }
   
    // uint256 to bytes32
    function toBytes(uint256 x) internal pure returns (bytes memory b) {
        b = new bytes(32);
        assembly {
            mstore(add(b, 32), x)
        }
    }

    function setMinMaxBet(uint min, uint max) external onlyHouse {
		minBet = min * 10**8;
		maxBet = max * 10**8;
    }	
	
    function setjackpotPercent(uint _jackpotPercent) external onlyHouse {
		jackpotPercent = _jackpotPercent;
    }	
	
	function getTokenAddress() public view returns(address token){
		return address(t2xToken);
	}
	
    function setT2xAddress(uint _t2xAddress) external onlyHouse {
		t2xToken = TRC20(_t2xAddress);
    }
	
	function getTokenContractBalance() public view returns(uint256 balance){
		return t2xToken.balanceOf(address(this));
	}

    function getHouseProfit(uint amount) external onlyHouse {
        uint max = t2xToken.balanceOf(address(this));
        t2xToken.transfer(house, amount < max ? amount : max);
    }
    
    function randomNumber(uint betNumber) internal returns (uint) {
        seed += block.timestamp + uint(msg.sender);
        return uint(sha256(toBytes(uint(blockhash(block.number - 1)) + seed))) % betNumber;
    }	
	
	function prelim(uint num, uint bet) private {
		require(t2xToken.balanceOf(msg.sender) > bet, "Not enough T2X to make this bet!");
        require(bet >= minBet && bet <= maxBet, "Bet amount outside min/max bet amount.");
        require(num >= 6 && num <= 94, "Under/over outside parameters.");
		require( t2xToken.transferFrom(msg.sender, address(this), bet), "Transfer from user failed.");
		        
        if (registeredPlayer[msg.sender] != true) {
            totalPlayers++;
            registeredPlayer[msg.sender] = true;
        }
                        
		totalInvested += bet;
		totalRolls++;
        invested[msg.sender] += bet;
		rolls[msg.sender]++;
	}
	
    function betUnder(uint underThis, uint betAmount) external notContract {
        prelim(underThis, betAmount);
		
        uint rolledNumber = randomNumber(100);
		if(rolledNumber < underThis){
			lastRollWasHouse[msg.sender] = false;
			
            uint prize = betAmount.mul(95).div(underThis);
			winnings[msg.sender] += prize;
			
            t2xToken.transfer(msg.sender, prize);
            emit Dice(msg.sender, false, betAmount, prize, rolledNumber, underThis, false);
			
        }else{
			if(rolledNumber == underThis){
				if(lastRollWasHouse[msg.sender] == true){
					winJackpot(msg.sender, false, betAmount, rolledNumber);
					return;
				}else
					lastRollWasHouse[msg.sender] = true;
			}else
				lastRollWasHouse[msg.sender] = false;
			
			jackpotFund += betAmount.mul(jackpotPercent).div(100);
			
			t2xToken.transfer(house, betAmount.div(10));
			emit Dice(msg.sender, false, betAmount, 0, rolledNumber, underThis, false);
        }
    }
	
    function betOver(uint overThis, uint betAmount) external notContract {  
		prelim(overThis, betAmount);
	
        uint rolledNumber = randomNumber(100);
		if(rolledNumber > overThis){
			lastRollWasHouse[msg.sender] = false;
			
            uint prize = betAmount.mul(95).div(100 - overThis);
			winnings[msg.sender] += prize;
			
            t2xToken.transfer(msg.sender, prize);
            emit Dice(msg.sender, true, betAmount, prize, rolledNumber, overThis, false);
			
        }else{
			if(rolledNumber == overThis){
				if(lastRollWasHouse[msg.sender] == true){
					winJackpot(msg.sender, true, betAmount, rolledNumber);
					return;
				}else
					lastRollWasHouse[msg.sender] = true;
			}else
				lastRollWasHouse[msg.sender] = false;
			
			jackpotFund += betAmount.mul(jackpotPercent).div(100);
			
			t2xToken.transfer(house, betAmount.div(10));
			emit Dice(msg.sender, true, betAmount, 0, rolledNumber, overThis, false);
        }
    }
	
	function winJackpot(address user, bool over, uint bet, uint num) private returns (bool){
		uint jPrize = jackpotFund.div(2);
		jackpotFund = jackpotFund.sub(jPrize);
		totalJackpots++;
		jackpots[user]++;
		
		t2xToken.transfer(user, jPrize);
		emit Dice(user, over, bet, jPrize, num, num, true);
	}

    constructor (address t2xAddress) public {
		t2xToken = TRC20(t2xAddress);
        startTime = now;
        house = msg.sender;
    }

}

//SourceUnit: TRC20.sol

pragma solidity 0.5.10;

contract TRC20 {
    using SafeMath for uint256;

    mapping (address => uint256) internal _balances;
    mapping (address => uint256) internal _tokenBalances;

    mapping (address => mapping (address => uint256)) internal _allowed;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    uint256 internal _totalSupply;
    uint256 internal _totalTokenSupply;

    /**
    * @dev Total number of tokens in existence
    */
    function totalSupply() public view returns (uint256, uint256) {
        return (_totalSupply, _totalTokenSupply);
    }

    /**
    * @dev Gets the balance of the specified address.
    * @param owner The address to query the balance of.
    * @return A uint256 representing the amount owned by the passed address.
    */
    function balanceOf(address owner) public view returns (uint256) {
        return _balances[owner];
    }

    /**
    * @dev Function to check the amount of tokens that an owner allowed to a spender.
    * @param owner address The address which owns the funds.
    * @param spender address The address which will spend the funds.
    * @return A uint256 specifying the amount of tokens still available for the spender.
    */
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowed[owner][spender];
    }

    /**
    * @dev Transfer token to a specified address
    * @param to The address to transfer to.
    * @param value The amount to be transferred.
    */
    function transfer(address to, uint256 value) public returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    /**
    * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
    * Beware that changing an allowance with this method brings the risk that someone may use both the old
    * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
    * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
    * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    * @param spender The address which will spend the funds.
    * @param value The amount of tokens to be spent.
    */
    function approve(address spender, uint256 value) public returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    /**
    * @dev Transfer tokens from one address to another.
    * Note that while this function emits an Approval event, this is not required as per the specification,
    * and other compliant implementations may not emit the event.
    * @param from address The address which you want to send tokens from
    * @param to address The address which you want to transfer to
    * @param value uint256 the amount of tokens to be transferred
    */
    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        _transfer(from, to, value);
        _approve(from, msg.sender, _allowed[from][msg.sender].sub(value));
        return true;
    }

    /**
    * @dev Increase the amount of tokens that an owner allowed to a spender.
    * approve should be called when _allowed[msg.sender][spender] == 0. To increment
    * allowed value is better to use this function to avoid 2 calls (and wait until
	* the first transaction is mined)
	* From MonolithDAO Token.sol
	* Emits an Approval event.
	* @param spender The address which will spend the funds.
	* @param addedValue The amount of tokens to increase the allowance by.
	*/
	function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
		_approve(msg.sender, spender, _allowed[msg.sender][spender].add(addedValue));
		return true;
	}

	/**
	* @dev Decrease the amount of tokens that an owner allowed to a spender.
	* approve should be called when _allowed[msg.sender][spender] == 0. To decrement
	* allowed value is better to use this function to avoid 2 calls (and wait until
	* the first transaction is mined)
	* From MonolithDAO Token.sol
	* Emits an Approval event.
	* @param spender The address which will spend the funds.
	* @param subtractedValue The amount of tokens to decrease the allowance by.
	*/
	function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
		_approve(msg.sender, spender, _allowed[msg.sender][spender].sub(subtractedValue));
		return true;
	}

	/**
	* @dev Transfer token for a specified addresses
	* @param from The address to transfer from.
	* @param to The address to transfer to.
	* @param value The amount to be transferred.
	*/
	function _transfer(address from, address to, uint256 value) internal {
		require(to != address(0));

		_balances[from] = _balances[from].sub(value);
		_balances[to] = _balances[to].add(value);
		emit Transfer(from, to, value);
	}

	/**
	* @dev Internal function that mints an amount of the token and assigns it to
	* an account. This encapsulates the modification of balances such that the
	* proper events are emitted.
	* @param account The account that will receive the created tokens.
	* @param value The amount that will be created.
	*/
	function _mint(address account, uint256 value) internal {
		require(account != address(0));

		_totalSupply = _totalSupply.add(value);
		_balances[account] = _balances[account].add(value);
		emit Transfer(address(0), account, value);
	}

	/**
	* @dev Internal function that burns an amount of the token of a given
	* account.
	* @param account The account whose tokens will be burnt.
	* @param value The amount that will be burnt.
	*/
	function _burn(address account, uint256 value) internal {
		require(account != address(0));

		_totalSupply = _totalSupply.sub(value);
		_balances[account] = _balances[account].sub(value);
		emit Transfer(account, address(0), value);
	}

	/**
	* @dev Approve an address to spend another addresses' tokens.
	* @param owner The address that owns the tokens.
	* @param spender The address that will spend the tokens.
	* @param value The number of tokens that can be spent.
	*/
	function _approve(address owner, address spender, uint256 value) internal {
		require(spender != address(0));
		require(owner != address(0));

		_allowed[owner][spender] = value;
		emit Approval(owner, spender, value);
	}

}


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
		// assert(a == b * c + a % b); // There is no case in which this doesn't hold
		return a / b;
	}

	/**
	* @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
	*/
	function sub(uint256 a, uint256 b) internal pure returns (uint256) {
		assert(b <= a);
		return a - b;
	}

	/* @dev Subtracts two numbers, else returns zero */
	function safeSub(uint a, uint b) internal pure returns (uint) {
		if (b > a) {
			return 0;
		} else {
			return a - b;
		}
	}

	/**
	* @dev Adds two numbers, throws on overflow.
	*/
	function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
		c = a + b;
		assert(c >= a);
		return c;
	}

	function max(uint256 a, uint256 b) internal pure returns (uint256) {
		return a >= b ? a : b;
	}

	function min(uint256 a, uint256 b) internal pure returns (uint256) {
		return a < b ? a : b;
	}
}