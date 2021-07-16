//SourceUnit: PoolTrading.sol

pragma solidity ^0.5.4;

contract PoolTrading {

    using SafeMath for uint256;

    address private owner;
    address payable public addressTrading;

    uint public minDepositSize = 500000000; // 500 TRX
    uint public minWithdrawProfitSize = 100000000; // 100 TRX
    uint public minWithdrawDepositSize = 100000000; // 100 TRX
    uint public interestRateDivisor = 1000000000000;
    uint public minuteRate = 38580; // 0.33333333% diario = 10% mensual
    uint public totalInvestors;
    uint public totalInvested;
    uint public totalPayoutProfit;
    uint public totalPayoutDeposit;
    uint private secondsMinimunWithdrawDeposit = 2592000;// 30 días

    uint public releaseTime = 1598515254;

    struct Investor {
        uint deposit;
        uint time;
        uint timeMinimunWithdrawDeposit;
        uint totalProfit; // Profit Available
        uint totalPayoutProfit;
        uint totalPayoutDeposit;
    }

    mapping(address => Investor) public investors;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner, "owner calls only!");
        _;
    }

    function registerAddressTrading(address payable pAddressTrading) public onlyOwner {
        addressTrading = pAddressTrading;
    }

    function deposit() public payable {

        require(now >= releaseTime, "not time yet!");

        uint depositAmount = msg.value;
        address addressInvestor = msg.sender;

        require(depositAmount >= minDepositSize, "The minimum investment is 500 TRX");

        investorProcess(addressInvestor, depositAmount);

        transferAddressTraing(depositAmount);

    }

    function investorProcess(address pAddressInvestor, uint pDepositAmount) private {

        Investor storage investor = investors[pAddressInvestor];

        if (investor.time == 0) {
            investor.time = now;
            investor.timeMinimunWithdrawDeposit = investor.time.add(secondsMinimunWithdrawDeposit);
            totalInvestors++;
        }

        investor.deposit = investor.deposit.add(pDepositAmount);
        totalInvested = totalInvested.add(pDepositAmount);

    }

    function withdrawProfit() public {

        address addressInvestor = msg.sender;

        calculateInterestProfit(addressInvestor);

        Investor storage investor = investors[addressInvestor];

        require(investor.totalProfit >= minWithdrawProfitSize, "The minimun withdraw the profit is 100 TRX");

        transferPayoutProfit();
    }

    function withdrawDeposit() public {

        address addressInvestor = msg.sender;
        calculateInterestProfit(addressInvestor);

        Investor storage investor = investors[addressInvestor];
        require(now >= investor.timeMinimunWithdrawDeposit, "Deposit withdrawals are not allowed before the first 30 days");

        transferPayoutDesposit();
    }

    function calculateInterestProfit(address _addr) internal {

        Investor storage investor = investors[_addr];

        uint secPassed = now.sub(investor.time);
        if (secPassed > 0 && investor.time > 0) {
            uint collectProfit = (investor.deposit.mul(secPassed.mul(minuteRate))).div(interestRateDivisor);
            investor.totalProfit = investor.totalProfit.add(collectProfit);
            investor.time = investor.time.add(secPassed);
        }
    }

    function transferPayoutProfit() internal {

        address pAddressReceiver = msg.sender;
        require(pAddressReceiver != address(0), "The wallet is not from a valid investor");

        Investor storage investor = investors[pAddressReceiver];
        uint payout = investor.totalProfit;

        require(payout > 0, "The withdrawal value must be greater than zero");
        require(payout >= minWithdrawProfitSize, "The minimun withdraw is 100 TRX");

        uint contractBalance = address(this).balance;
        require(contractBalance > payout, "The contract does not have enough balance to make the payment");

        totalPayoutProfit = totalPayoutProfit.add(payout);

        investor.totalPayoutProfit = investor.totalPayoutProfit.add(payout);
        investor.totalProfit = investor.totalProfit.sub(payout);

        msg.sender.transfer(payout);

    }

    function transferPayoutDesposit() internal {

        address pAddressReceiver = msg.sender;
        require(pAddressReceiver != address(0), "The wallet is not from a valid investor");

        Investor storage investor = investors[pAddressReceiver];
        uint payout = investor.deposit;

        uint contractBalance = address(this).balance;
        require(contractBalance > payout, "The contract does not have enough balance to make the payment");

        totalPayoutDeposit = totalPayoutDeposit.add(payout);

        investor.totalPayoutDeposit = investor.totalPayoutDeposit.add(payout);
        investor.deposit = investor.deposit.sub(payout);

        msg.sender.transfer(payout);
    }


    function transferAddressTraing(uint pAmount) internal {
        require(pAmount > 0);
        addressTrading.transfer(pAmount);
    }

    function getNow() public view returns (uint){
        return now;
    }

}

library SafeMath {

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0);
        uint256 c = a / b;

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

}