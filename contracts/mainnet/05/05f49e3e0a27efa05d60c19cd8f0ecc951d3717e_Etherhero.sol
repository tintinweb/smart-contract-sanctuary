pragma solidity 0.4.25;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

    function mul(uint256 a, uint256 b) internal pure returns(uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns(uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns(uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns(uint256) {
        uint256 c = a + b;
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
        require(msg.sender == owner, &#39;Only the owner can call this method&#39;);
        _;
    }
}

/**
 * In the event of the shortage of funds for the level payments
 * stabilization the contract of the stabilization fund provides backup support to the investment fund. 
 */
contract EtherheroStabilizationFund {

    address public etherHero;
    uint public investFund;
    uint estGas = 200000;
    event MoneyWithdraw(uint balance);
    event MoneyAdd(uint holding);

    constructor() public {
        etherHero = msg.sender;
    }
    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyHero() {
        require(msg.sender == etherHero, &#39;Only Hero call&#39;);
        _;
    }

    function ReturnEthToEtherhero() public onlyHero returns(bool) {

        uint balance = address(this).balance;
        require(balance > estGas, &#39;Not enough funds for transaction&#39;);

        if (etherHero.call.value(address(this).balance).gas(estGas)()) {
            emit MoneyWithdraw(balance);
            investFund = address(this).balance;
            return true;
        } else {
            return false;
        }
    }

    function() external payable {
        investFund += msg.value;
        emit MoneyAdd(msg.value);
    }
}

contract Etherhero is Ownable {

    using SafeMath
    for uint;
    // array containing information about beneficiaries
    mapping(address => uint) public userDeposit;
    //array containing information about the time of payment
    mapping(address => uint) public userTime;
    //fund fo transfer percent
    address public projectFund = 0xf846f84841b3242Ccdeac8c43C9cF73Bd781baA7;
    EtherheroStabilizationFund public stubF = new EtherheroStabilizationFund();
    uint public percentProjectFund = 10;
    uint public percentDevFund = 1;
    uint public percentStubFund = 10;
    address public addressStub;
    //Gas cost
    uint estGas = 150000;
    uint standartPercent = 30; //3%
    uint responseStubFundLimit = 150; //15%
    uint public minPayment = 5 finney;
    //time through which you can take dividends
    uint chargingTime = 1 days;

    event NewInvestor(address indexed investor, uint deposit);
    event dividendPayment(address indexed investor, uint value);
    event NewDeposit(address indexed investor, uint value);

    //public variables for DAPP
    uint public counterDeposits;
    uint public counterPercents;
    uint public counterBeneficiaries;
    uint public timeLastayment;

    //Memory for user for DAPP
    struct Beneficiaries {
        address investorAddress;
        uint registerTime;
        uint percentWithdraw;
        uint ethWithdraw;
        uint deposits;
        bool real;
    }

    mapping(address => Beneficiaries) beneficiaries;

    constructor() public {
        addressStub = stubF;
    }
    //Add beneficiary record
    function insertBeneficiaries(address _address, uint _percentWithdraw, uint _ethWithdraw, uint _deposits) private {

        Beneficiaries storage s_beneficiaries = beneficiaries[_address];

        if (!s_beneficiaries.real) {
            s_beneficiaries.real = true;
            s_beneficiaries.investorAddress = _address;
            s_beneficiaries.percentWithdraw = _percentWithdraw;
            s_beneficiaries.ethWithdraw = _ethWithdraw;
            s_beneficiaries.deposits = _deposits;
            s_beneficiaries.registerTime = now;
            counterBeneficiaries += 1;
        } else {
            s_beneficiaries.percentWithdraw += _percentWithdraw;
            s_beneficiaries.ethWithdraw += _ethWithdraw;
        }
    }
    
    //Get beneficiary record
    function getBeneficiaries(address _address) public view returns(address investorAddress, uint persentWithdraw, uint ethWithdraw, uint registerTime) {

        Beneficiaries storage s_beneficiaries = beneficiaries[_address];

        require(s_beneficiaries.real, &#39;Investor Not Found&#39;);

        return (
            s_beneficiaries.investorAddress,
            s_beneficiaries.percentWithdraw,
            s_beneficiaries.ethWithdraw,
            s_beneficiaries.registerTime
        );
    }

    modifier isIssetUser() {
        require(userDeposit[msg.sender] > 0, "Deposit not found");
        _;
    }

    modifier timePayment() {
        require(now >= userTime[msg.sender].add(chargingTime), "Too fast payout request");
        _;
    }

    function calculationOfPayment() public view returns(uint) {
        uint interestRate = now.sub(userTime[msg.sender]).div(chargingTime);
        //If the contribution is less than 1 ether, dividends can be received only once a day
        if (userDeposit[msg.sender] < 10 ether) {
            if (interestRate >= 1) {
                return (1);
            } else {
                return (interestRate);
            }
        }
        //If the contribution is less than 10 ether, dividends can be received only once a 3 day
        if (userDeposit[msg.sender] >= 10 ether && userDeposit[msg.sender] < 50 ether) {
            if (interestRate > 3) {
                return (3);
            } else {
                return (interestRate);
            }
        }
        //If the contribution is less than 50 ether, dividends can be received only once a 7 day
        if (userDeposit[msg.sender] >= 50 ether) {
            if (interestRate > 7) {
                return (7);
            } else {
                return (interestRate);
            }
        }
    }
    
    function receivePercent() isIssetUser timePayment internal {
       // verification that funds on the balance sheet are more than 15% of the total number of deposits
        uint balanceLimit = counterDeposits.mul(responseStubFundLimit).div(1000);
        uint payoutRatio = calculationOfPayment();
        //calculate 6% of total deposits
        uint remain = counterDeposits.mul(6).div(100);
        
        if(addressStub.balance > 0){
            if (address(this).balance < balanceLimit) {
                stubF.ReturnEthToEtherhero();
            }
        }
        //If the balance is less than 6% of total deposits, stop paying
        require(address(this).balance >= remain, &#39;contract balance is too small&#39;);

        uint rate = userDeposit[msg.sender].mul(standartPercent).div(1000).mul(payoutRatio);
        userTime[msg.sender] = now;
        msg.sender.transfer(rate);
        counterPercents += rate;
        timeLastayment = now;
        insertBeneficiaries(msg.sender, standartPercent, rate, 0);
        emit dividendPayment(msg.sender, rate);
    }

    function makeDeposit() private {
        uint value = msg.value;
        uint calcProjectPercent = value.mul(percentProjectFund).div(100);
        uint calcStubFundPercent = value.mul(percentStubFund).div(100);
        
        if (msg.value > 0) {
            //check for minimum deposit 
            require(msg.value >= minPayment, &#39;Minimum deposit 1 finney&#39;);
            
            if (userDeposit[msg.sender] == 0) {
                emit NewInvestor(msg.sender, msg.value);
            }
            
            userDeposit[msg.sender] = userDeposit[msg.sender].add(msg.value);
            userTime[msg.sender] = now;
            insertBeneficiaries(msg.sender, 0, 0, msg.value);
            projectFund.transfer(calcProjectPercent);
            stubF.call.value(calcStubFundPercent).gas(estGas)();
            counterDeposits += msg.value;
            emit NewDeposit(msg.sender, msg.value);
        } else {
            receivePercent();
        }
    }

    function() external payable {
        if (msg.sender != addressStub) {
            makeDeposit();
        }
    }
}