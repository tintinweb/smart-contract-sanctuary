pragma solidity ^0.4.20;

/*
* Team Proof of Long Hodl presents..
*/

pragma solidity ^0.4.21;

contract ProofOfLongHodl {
    using SafeMath for uint256;

    event Deposit(address user, uint amount);
    event Withdraw(address user, uint amount);
    event Claim(address user, uint dividends);
    event Reinvest(address user, uint dividends);

    address owner;
    mapping(address => bool) preauthorized;
    bool gameStarted;

    uint constant depositTaxDivisor = 29;		// 29% of  deposits goes to  divs
    uint constant withdrawalTaxDivisor = 29;	// 29% of  withdrawals goes to  divs
    uint constant lotteryFee = 25; 				// 4% of deposits and withdrawals goes to lotteryPool

    mapping(address => uint) public investment;

    mapping(address => uint) public stake;
    uint public totalStake;
    uint stakeValue;

    mapping(address => uint) dividendCredit;
    mapping(address => uint) dividendDebit;

    function ProofOfLongHodl() public {
        owner = msg.sender;
        preauthorized[owner] = true;
    }

    function preauthorize(address _user) public {
        require(msg.sender == owner);
        preauthorized[_user] = true;
    }

    function startGame() public {
        require(msg.sender == owner);
        gameStarted = true;
    }

    function depositHelper(uint _amount) private {
    	require(_amount > 0);
        uint _tax = _amount.mul(depositTaxDivisor).div(100);
        uint _lotteryPool = _amount.div(lotteryFee); // add to lottery fee
        uint _amountAfterTax = _amount.sub(_tax).sub(_lotteryPool);

        lotteryPool = lotteryPool.add(_lotteryPool);

        // check if first deposit, and greater than and make user eligable for lottery
        if (isEligable[msg.sender] == false &&  _amount > 0.1 ether) {
        	isEligable[msg.sender] = true;
        	hasWithdrawed[msg.sender] = false;

        	lotteryAddresses.push(msg.sender);
        	eligableIndex[msg.sender] = lotteryAddresses.length - 1;      	
        }

        if (totalStake > 0)
            stakeValue = stakeValue.add(_tax.div(totalStake));
        uint _stakeIncrement = sqrt(totalStake.mul(totalStake).add(_amountAfterTax)).sub(totalStake);
        investment[msg.sender] = investment[msg.sender].add(_amountAfterTax);
        stake[msg.sender] = stake[msg.sender].add(_stakeIncrement);
        totalStake = totalStake.add(_stakeIncrement);
        dividendDebit[msg.sender] = dividendDebit[msg.sender].add(_stakeIncrement.mul(stakeValue));
    }

    function deposit() public payable {
        require(preauthorized[msg.sender] || gameStarted);
        depositHelper(msg.value);
        emit Deposit(msg.sender, msg.value);
    }

    function withdraw(uint _amount) public {
        require(_amount > 0);
        require(_amount <= investment[msg.sender]);
        uint _tax = _amount.mul(withdrawalTaxDivisor).div(100);
        uint _lotteryPool = _amount.div(lotteryFee); // add to lottery fee
        uint _amountAfterTax = _amount.sub(_tax).sub(_lotteryPool);

        lotteryPool = lotteryPool.add(_lotteryPool);

        // removing user from lotteryAddresses if it is first withdraw
        if (lotteryAddresses.length != 0 && !hasWithdrawed[msg.sender] ) {
        	hasWithdrawed[msg.sender] = true;
        	isEligable[msg.sender] = false;
        	totalWithdrawals = totalWithdrawals.add(_amountAfterTax);
        	withdrawalsCTR++;

        	// delete user from lottery addresses index to delete
        	uint indexToDelete = eligableIndex[msg.sender]; 
        	address lastAddress = lotteryAddresses[lotteryAddresses.length - 1];
        	lotteryAddresses[indexToDelete] = lastAddress;
        	lotteryAddresses.length--;

        	eligableIndex[lastAddress] = indexToDelete;
        	eligableIndex[msg.sender] = 0;

        	if (withdrawalsCTR > 9 && totalWithdrawals > 1 ether) {
        		// pick lottery winner and sent reward
			    uint256 winnerIndex = rand(lotteryAddresses.length);
			    address winner = lotteryAddresses[winnerIndex];

			    winner.transfer(lotteryPool);
			    totalWithdrawals = 0;
			    withdrawalsCTR = 0;
			    lotteryPool = 0;
			    lotteryRound++;
			    lastWinner = winner;
        	}
        }

        uint _stakeDecrement = stake[msg.sender].mul(_amount).div(investment[msg.sender]);
        uint _dividendCredit = _stakeDecrement.mul(stakeValue);
        investment[msg.sender] = investment[msg.sender].sub(_amount);
        stake[msg.sender] = stake[msg.sender].sub(_stakeDecrement);
        totalStake = totalStake.sub(_stakeDecrement);
        if (totalStake > 0)
            stakeValue = stakeValue.add(_tax.div(totalStake));
        dividendCredit[msg.sender] = dividendCredit[msg.sender].add(_dividendCredit);
        uint _creditDebitCancellation = min(dividendCredit[msg.sender], dividendDebit[msg.sender]);
        dividendCredit[msg.sender] = dividendCredit[msg.sender].sub(_creditDebitCancellation);
        dividendDebit[msg.sender] = dividendDebit[msg.sender].sub(_creditDebitCancellation);

        msg.sender.transfer(_amountAfterTax);
        emit Withdraw(msg.sender, _amount);
    }

    function claimHelper() private returns(uint) {
        uint _dividendsForStake = stake[msg.sender].mul(stakeValue);
        uint _dividends = _dividendsForStake.add(dividendCredit[msg.sender]).sub(dividendDebit[msg.sender]);
        dividendCredit[msg.sender] = 0;
        dividendDebit[msg.sender] = _dividendsForStake;

        return _dividends;
    }

    function claim() public {
        uint _dividends = claimHelper();
        msg.sender.transfer(_dividends);

        emit Claim(msg.sender, _dividends);
    }

    function reinvest() public {
        uint _dividends = claimHelper();
        depositHelper(_dividends);

        emit Reinvest(msg.sender, _dividends);
    }

    function dividendsForUser(address _user) public view returns (uint) {
        return stake[_user].mul(stakeValue).add(dividendCredit[_user]).sub(dividendDebit[_user]);
    }

    function min(uint x, uint y) private pure returns (uint) {
        return x <= y ? x : y;
    }

    function sqrt(uint x) private pure returns (uint y) {
        uint z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }

    // LOTTERY MODULE
    uint private lotteryPool = 0;
    uint private lotteryRound = 1;
    address private lastWinner;

    uint public withdrawalsCTR = 0;
    uint public totalWithdrawals = 0;

    mapping(address => uint256) internal eligableIndex; // 
    mapping(address => bool) internal isEligable; // for first deposit check
    mapping(address => bool) internal hasWithdrawed; // check if user already withdrawed

    address[] public lotteryAddresses;

    // Generate random number between 0 & max
    uint256 constant private FACTOR =  1157920892373161954235709850086879078532699846656405640394575840079131296399;
    function rand(uint max) constant public returns (uint256 result){
        uint256 factor = FACTOR * 100 / max;
        uint256 lastBlockNumber = block.number - 1;
        uint256 hashVal = uint256(block.blockhash(lastBlockNumber));
    
        return uint256((uint256(hashVal) / factor)) % max;
    }

    // check if address is withdrawed
    function checkIfEligable(address _address) public view returns (bool) {
    	return (isEligable[_address] && !hasWithdrawed[_address]) ;
    }

    function getLotteryData() public view returns( uint256, uint256, address) {
    	return (lotteryPool, lotteryRound, lastWinner);
    }

    function lotteryParticipants() public view returns(uint256) {
    	return lotteryAddresses.length;
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
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;                                                                                                                                                                                       
        }
        uint256 c = a * b;                                                                                                                                                                                  
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
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;                                                                                                                                                                                  
        assert(c >= a);                                                                                                                                                                                     
        return c;                                                                                                                                                                                           
    }
}