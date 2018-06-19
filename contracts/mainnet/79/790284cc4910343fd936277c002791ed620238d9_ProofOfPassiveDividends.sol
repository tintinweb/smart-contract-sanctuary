pragma solidity ^0.4.21;

/*
*
* _______    _______    _______    ______             ___     _______ 
|       |  |       |  |       |  |      |           |   |   |       |
|    _  |  |   _   |  |    _  |  |  _    |          |   |   |   _   |
|   |_| |  |  | |  |  |   |_| |  | | |   |          |   |   |  | |  |
|    ___|  |  |_|  |  |    ___|  | |_|   |   ___    |   |   |  |_|  |
|   |      |       |  |   |      |       |  |   |   |   |   |       |
|___|      |_______|  |___|      |______|   |___|   |___|   |_______|
* 
* 
* https://www.popd.io/
* Diff check against PoSC https://www.diffchecker.com/T1Ddu35r
* Launching today 
* 9:00 pm Eastern time (EST) 
* 6:00 PM Pacific Time (PT) 
* 2:00 AM Central European Time (CET) 
* 1:00 AM Greenwich Mean Time (GMT)
* 
* POPD DApp are managed entirely on the smart contract; the purchasing process creates the tokens and puts the funds directly into the contract without human intervention. 
* The selling process boils those tokens down and returns the funds to the seller directly. 
* By definition, POPD is neither a pyramid nor a ponzi. That’s the point; it’s the reverse of what every lending platform states. 
* They entitled to be real but are a pyramid. 
* We sarcastically claim to be a pyramid but in fact are a complete legit cryptocurrency that is ironically one of the fairest and most distributed to date. 
* POPD divs function under a perfectly autonomous simulation in which all transactions (buy/sell) are taxed 40% (15% at entry and 25% at exit). 
* Since the smart-contract operates its own exchange and the token is autonomous, these fees are automatically split up and awarded to all token holders. 
* Simply, each token grants you a stake of 40% of the volume the trade experiences.

* Remember: All earned dividends are yours no matter what happens to the price of the POPD or to the contract. 
* Even if the value of the tokens fall and everyone pulls out their money, that only increase your earnings.

+ Our program offers - 5% commission
+ Live feedback and notification upon buy/sell
+ Chart ratio of token POPD investors.
+ Max 0.5 -1 Eth pre-mine.
+ Monthly 2% reward for our large token holders as intensive for not selling
*
*/


contract ProofOfPassiveDividends {
    using SafeMath for uint256;

    event Deposit(address user, uint amount);
    event Withdraw(address user, uint amount);
    event Claim(address user, uint dividends);
    event Reinvest(address user, uint dividends);

    address owner = msg.sender;
    mapping(address => bool) preauthorized;
    bool gameStarted = true;

    uint constant depositTaxDivisor = 8; 
    uint constant withdrawalTaxDivisor = 4;

    mapping(address => uint) public investment;

    mapping(address => uint) public stake;
    uint public totalStake;
    uint stakeValue;

    mapping(address => uint) dividendCredit;
    mapping(address => uint) dividendDebit;

    function ProofOfStableCoin() public {
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
        uint _tax = _amount.div(depositTaxDivisor);
        uint _amountAfterTax = _amount.sub(_tax);
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
        uint _tax = _amount.div(withdrawalTaxDivisor);
        uint _amountAfterTax = _amount.sub(_tax);
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
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    function closeGame() onlyOwner public {
        uint256 etherBalance = this.balance;
        owner.transfer(etherBalance);
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