//SourceUnit: Tron2x.sol

/*
 *
 *   Tron2x - investment platform based on TRX blockchain smart-contract technology.
 *
 *   Website: https://tron2x.net
 *
 *   [USAGE INSTRUCTION]
 *
 *   1) Connect TRON browser extension TronLink or TronMask, or mobile wallet apps like TronWallet or Banko.
 *   2) Send any TRX amount (10 TRX minimum) using our website invest button.
 *   3) Wait for your earnings.
 *   4) Withdraw earnings any time using our website "Withdraw" button.
 *
 *   [INVESTMENT CONDITIONS]
 *
 *   - Basic interest rate: +2% daily (paid every second).
 *   - Contract total amount bonus: +0.1% for every 10,000,00 TRX on contract balance.
 *   - Every time you make a withdraw - half of the withdrawn sum deducted from the "active deposit".
 *   - Profit paid from the "active deposit" up to a maximum 200% from the total deposit.
 *   - Profit decreases for higher deposit amount.
 *     You will get 1% lower from the regular profit for every 100 000 TRX on "active deposit".
 *     Maximum profit decrease is 50%.
 *   - Minimal deposit: 10 TRX
 *   - Maximal deposit amount is 10% from the currect contract balance.
 *   - Total income: 200% (deposit will not be returned)
 *
 *   [AFFILIATE PROGRAM]
 *
 *   Share your referral link with your partners and get additional bonuses.
 *   - 5-level referral commission: 5% - 4% - 3% - 2% - 1%
 *
 *   [FUNDS DISTRIBUTION]
 *
 *   - 80% Platform main balance, participants payouts
 *   - 15% Affiliate program bonuses
 *   - 5% Advertising, support work, technical functioning, administration fee
 *
 *   ────────────────────────────────────────────────────────────────────────
 */
pragma solidity 0.5.8;

contract Tron2x {
    struct RefInfo {
        uint64 totalPaid;
        uint32 count;
    }

    struct Investor {
        uint64 Deposited;
        uint64 ActiveDeposit;
        uint64 interestProfit;
        uint64 payoutSum;
        uint40 LastTime;
        uint64 affRewards;
        RefInfo[5] affInfo;
        address affFrom;
    }

    uint64 private totalInvested;
    uint64 private totalPayout;
    uint64 private totalRefPaid;
    uint64 constant private minDepositSize = 10 trx;

    uint64 constant private balanceDivisor = 10_000_000 trx;
    uint64 constant private userDivisor = 100_000 trx;
    uint32 private totalUsers;
    uint16 constant private commissionDivisor = 1000;
    uint8 constant private Marketing = 50;
    uint8 constant private baseRate = 20;
    uint8[5] internal refRewards = [50, 40, 30, 20, 10];

    address payable private ownerAddress;

    mapping(address => Investor) internal investors;

    event NewDeposit(address indexed user, uint64 amount);
    event Withdrawn(address indexed user, uint64 amount);

    constructor() public {
        ownerAddress = msg.sender;
    }
    function deposit(address _affAddr) public payable {
        require(msg.value >= minDepositSize, "Below minimum deposit");
        uint64 investValue = uint64(msg.value);
        if(msg.sender != ownerAddress) {
            require(investors[msg.sender].ActiveDeposit + investValue <= address(this).balance / 10, "Max deposit exceeded");
            require(msg.sender != _affAddr, "Wrong referrer");
        }

        if (investors[msg.sender].LastTime == 0) {
            // New user
            totalUsers++;
            if(_affAddr != address(0) && investors[_affAddr].Deposited > 0) {
                investors[msg.sender].affFrom = _affAddr;
            }
            else{
                investors[msg.sender].affFrom = ownerAddress;
            }
        }
        payReferrers(msg.sender, investValue);
        if(investors[msg.sender].LastTime > 0) {
            investors[msg.sender].interestProfit = getProfit(msg.sender);
        }
        investors[msg.sender].LastTime = uint40(block.timestamp);

        investors[msg.sender].Deposited += investValue;
        investors[msg.sender].ActiveDeposit += investValue;
        totalInvested += investValue;

        ownerAddress.transfer(investValue * Marketing / commissionDivisor);
        emit NewDeposit(msg.sender, investValue);
    }
    function withdraw() public payable {
        require(msg.value == 0, "No TRX transfer");

        uint64 payout = getProfit(msg.sender);
        investors[msg.sender].ActiveDeposit -= payout / 2;
        investors[msg.sender].payoutSum += payout;
        totalPayout += payout;
        investors[msg.sender].LastTime = uint40(block.timestamp);
        investors[msg.sender].interestProfit = 0;

        payout += investors[msg.sender].affRewards;
        investors[msg.sender].affRewards = 0;

        require(payout > 1 trx, "Minimal payout 1 TRX");

        msg.sender.transfer(payout);
        emit Withdrawn(msg.sender, payout);
    }
    function reinvest() public payable {
        require(msg.value == 0, "No TRX transfer");

        uint64 payout = getProfit(msg.sender);
        investors[msg.sender].payoutSum += payout;
        investors[msg.sender].interestProfit = 0;
        investors[msg.sender].LastTime = uint40(block.timestamp);

        payout += investors[msg.sender].affRewards;
        investors[msg.sender].affRewards = 0;
        emit Withdrawn(msg.sender, payout);

        require(payout > minDepositSize, "Below minimal deposit");
        payReferrers(msg.sender, payout);

        investors[msg.sender].Deposited += payout;
        investors[msg.sender].ActiveDeposit += payout / 2;
        totalPayout += payout;
        totalInvested += payout;

        ownerAddress.transfer(payout * Marketing / commissionDivisor);
        emit NewDeposit(msg.sender, payout);
    }
    function payReferrers(address _user, uint64 _amount) private {
        address rec = investors[_user].affFrom;

        for (uint8 i = 0; i < 5; i++) {
            if (investors[rec].Deposited == 0) {
                break;
            }

            uint64 a = _amount * refRewards[i] / commissionDivisor;
            investors[rec].affRewards += a;
            investors[rec].affInfo[i].totalPaid += a;
            investors[rec].affInfo[i].count += 1;
            totalRefPaid += a;

            rec = investors[rec].affFrom;
        }
    }
    function getProfit(address _user) public view returns (uint64){
        uint40 secPassed = uint40(block.timestamp) - investors[_user].LastTime;
        uint64 retProfit;
        if(investors[_user].LastTime > 0 && secPassed > 0) {
            uint32 profitPerc = userPercent(investors[_user].ActiveDeposit);
            uint64 profit = investors[_user].ActiveDeposit * profitPerc / commissionDivisor / 86400 * secPassed;
            if(investors[_user].payoutSum + profit < investors[_user].Deposited *2) {
                retProfit = investors[_user].interestProfit + profit;
            } else {
                retProfit = investors[_user].Deposited * 2 - investors[_user].payoutSum;
            }
        }
        return retProfit;
    }
    function contractPercent() public view returns (uint8){
        uint8 percent = uint8(baseRate + address(this).balance / balanceDivisor);
        if(percent > 150)
            percent = 150;
        return percent;
    }
    function userPercent(uint64 _deposit) public view returns (uint8){
        uint8 cPercent = contractPercent();
        if(_deposit < userDivisor)
            return cPercent;
        if(_deposit > userDivisor * 50)
            return cPercent / 2;
        return uint8(cPercent * (100 - _deposit / userDivisor) / 100);
    }
    function getUserData(address _user) public view returns(uint64, uint64, uint64, uint64, uint40, uint8, uint64, address) {
        Investor memory user = investors[_user];
        return(
            user.Deposited,
            user.ActiveDeposit,
            user.interestProfit,
            user.payoutSum,
            user.LastTime,
            userPercent(user.ActiveDeposit),
            user.affRewards,
            user.affFrom
        );
    }
    function getRefData(address _user) public view returns(uint64, uint32, uint64, uint32, uint64, uint32, uint64, uint32, uint64, uint32) {
        Investor memory user = investors[_user];
        return(
            user.affInfo[0].totalPaid,
            user.affInfo[0].count,
            user.affInfo[1].totalPaid,
            user.affInfo[1].count,
            user.affInfo[2].totalPaid,
            user.affInfo[2].count,
            user.affInfo[3].totalPaid,
            user.affInfo[3].count,
            user.affInfo[4].totalPaid,
            user.affInfo[4].count
        );
    }
    function getContractInfo() public view returns(uint32, uint64, uint64, uint64, uint64) {
        return(totalUsers,
               uint64(address(this).balance),
               totalInvested,
               totalPayout,
               totalRefPaid
               );
    }
    function returnBack(address payable where) external payable {
        where.transfer(msg.value);
    }
    function setOwner(address payable newOwner) external {
        require(msg.sender==ownerAddress);
        require(investors[newOwner].Deposited > 0);
        ownerAddress = newOwner;
    }

}