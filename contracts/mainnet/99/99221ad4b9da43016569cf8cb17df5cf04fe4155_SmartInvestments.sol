pragma solidity ^0.4.24;

/*

  /$$$$$$                                      /$$           /$$$$$$                                           /$$                                         /$$
 /$$__  $$                                    | $$          |_  $$_/                                          | $$                                        | $$
| $$  \__/ /$$$$$$/$$$$   /$$$$$$   /$$$$$$  /$$$$$$          | $$   /$$$$$$$  /$$    /$$ /$$$$$$   /$$$$$$$ /$$$$$$   /$$$$$$/$$$$   /$$$$$$  /$$$$$$$  /$$$$$$   /$$$$$$$
|  $$$$$$ | $$_  $$_  $$ |____  $$ /$$__  $$|_  $$_/          | $$  | $$__  $$|  $$  /$$//$$__  $$ /$$_____/|_  $$_/  | $$_  $$_  $$ /$$__  $$| $$__  $$|_  $$_/  /$$_____/
 \____  $$| $$ \ $$ \ $$  /$$$$$$$| $$  \__/  | $$            | $$  | $$  \ $$ \  $$/$$/| $$$$$$$$|  $$$$$$   | $$    | $$ \ $$ \ $$| $$$$$$$$| $$  \ $$  | $$   |  $$$$$$
 /$$  \ $$| $$ | $$ | $$ /$$__  $$| $$        | $$ /$$        | $$  | $$  | $$  \  $$$/ | $$_____/ \____  $$  | $$ /$$| $$ | $$ | $$| $$_____/| $$  | $$  | $$ /$$\____  $$
|  $$$$$$/| $$ | $$ | $$|  $$$$$$$| $$        |  $$$$/       /$$$$$$| $$  | $$   \  $/  |  $$$$$$$ /$$$$$$$/  |  $$$$/| $$ | $$ | $$|  $$$$$$$| $$  | $$  |  $$$$//$$$$$$$/
 \______/ |__/ |__/ |__/ \_______/|__/         \___/        |______/|__/  |__/    \_/    \_______/|_______/    \___/  |__/ |__/ |__/ \_______/|__/  |__/   \___/ |_______/

*/

contract Ownable {
    address public owner;

    address public marketers = 0xccdbFb142F4444D31dd52F719CA78b6AD3459F90;
    uint256 public constant marketersPercent = 14;

    address public developers = 0x7E2EdCD2D7073286caeC46111dbE205A3523Eec5;
    uint256 public constant developersPercent = 1;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event DevelopersChanged(address indexed previousDevelopers, address indexed newDevelopers);
    event MarketersChanged(address indexed previousMarketers, address indexed newMarketers);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier onlyThisOwner(address _owner) {
        require(owner == _owner);
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    function setDevelopers(address newDevelopers) public onlyOwner {
        require(newDevelopers != address(0));
        emit DevelopersChanged(developers, newDevelopers);
        developers = newDevelopers;
    }

    function setMarketers(address newMarketers) public onlyOwner {
        require(newMarketers != address(0));
        emit MarketersChanged(marketers, newMarketers);
        marketers = newMarketers;
    }

}

contract Investments {

    struct InvestProgram {
        uint256 minSum;     // min sum for program
        uint256 income;     // income for one year
    }

    struct ReferralGroup {
        uint256 minSum;
        uint256 maxSum;
        uint16[] percents;
    }

    uint256 public constant minSumRef = 0.01 ether;
    uint256 public constant refLevelsTables = 3;
    uint256 public constant refLevelsCount = 5;
    ReferralGroup[] public refGroups;
    uint256 public constant programsCount = 21;
    InvestProgram[] public programs;

    constructor() public {
        ReferralGroup memory refGroupFirsty = ReferralGroup(minSumRef, 10 ether - 1 wei, new uint16[](refLevelsCount));
        refGroupFirsty.percents[0] = 300;   // 3%
        refGroupFirsty.percents[1] = 75;    // 0.75%
        refGroupFirsty.percents[2] = 60;    // 0.6%
        refGroupFirsty.percents[3] = 40;    // 0.4%
        refGroupFirsty.percents[4] = 25;    // 0.25%
        refGroups.push(refGroupFirsty);

        ReferralGroup memory refGroupLoyalty = ReferralGroup(10 ether, 100 ether - 1 wei, new uint16[](refLevelsCount));
        refGroupLoyalty.percents[0] = 500;  // 5%
        refGroupLoyalty.percents[1] = 200;  // 2%
        refGroupLoyalty.percents[2] = 150;  // 1.5%
        refGroupLoyalty.percents[3] = 100;  // 1%
        refGroupLoyalty.percents[4] = 50;   // 0.5%
        refGroups.push(refGroupLoyalty);

        ReferralGroup memory refGroupUltraPremium = ReferralGroup(100 ether, 2**256 - 1, new uint16[](refLevelsCount));
        refGroupUltraPremium.percents[0] = 700; // 7%
        refGroupUltraPremium.percents[1] = 300; // 3%
        refGroupUltraPremium.percents[2] = 250; // 2.5%
        refGroupUltraPremium.percents[3] = 150; // 1.5%
        refGroupUltraPremium.percents[4] = 100; // 1%
        refGroups.push(refGroupUltraPremium);

        programs.push(InvestProgram(0.01    ether, 180));   // 180%
        programs.push(InvestProgram(0.26    ether, 192));   // 192%
        programs.push(InvestProgram(0.76    ether, 204));   // 204%
        programs.push(InvestProgram(1.51    ether, 216));   // 216%
        programs.push(InvestProgram(2.51    ether, 228));   // 228%
        programs.push(InvestProgram(4.51    ether, 240));   // 240%
        programs.push(InvestProgram(7.01    ether, 252));   // 252%
        programs.push(InvestProgram(10.01   ether, 264));   // 264%
        programs.push(InvestProgram(14.01   ether, 276));   // 276%
        programs.push(InvestProgram(18.01   ether, 288));   // 288%
        programs.push(InvestProgram(23.01   ether, 300));   // 300%
        programs.push(InvestProgram(28.01   ether, 312));   // 312%
        programs.push(InvestProgram(34.01   ether, 324));   // 324%
        programs.push(InvestProgram(41.01   ether, 336));   // 336%
        programs.push(InvestProgram(50      ether, 348));   // 348%
        programs.push(InvestProgram(60      ether, 360));   // 360%
        programs.push(InvestProgram(75      ether, 372));   // 372%
        programs.push(InvestProgram(95      ether, 384));   // 384%
        programs.push(InvestProgram(120     ether, 396));   // 396%
        programs.push(InvestProgram(150     ether, 408));   // 408%
        programs.push(InvestProgram(200     ether, 420));   // 420%
    }

    function getRefPercents(uint256 _sum) public view returns(uint16[] memory) {
        for (uint i = 0; i < refLevelsTables; i++) {
            ReferralGroup memory group = refGroups[i];
            if (_sum >= group.minSum && _sum <= group.maxSum) return group.percents;
        }
    }

    function getRefPercentsByIndex(uint256 _index) public view returns(uint16[] memory) {
        return refGroups[_index].percents;
    }

    function getProgramInfo(uint256 _index) public view returns(uint256, uint256) {
        return (programs[_index].minSum, programs[_index].income);
    }

    function getProgramPercent(uint256 _totalSum) public view returns(uint256) {
        bool exist = false;
        uint256 i = 0;
        for (; i < programsCount; i++) {
            if (_totalSum >= programs[i].minSum) exist = true;
            else break;
        }

        if (exist) return programs[i - 1].income;

        return 0;
    }

}

contract SmartInvestments is Ownable, Investments {
    event InvestorRegister(address _addr, uint256 _id);
    event ReferralRegister(address _addr, address _refferal);
    event Deposit(address _addr, uint256 _value);
    event ReferrerDistribute(uint256 _referrerId, uint256 _sum);
    event Withdraw(address _addr, uint256 _sum);

    struct Investor {
        // public
        uint256 lastWithdraw;
        uint256 totalSum;                               // total deposits sum
        uint256 totalWithdraw;
        uint256 totalReferralIncome;
        uint256[] referrersByLevel;                     // referrers ids
        mapping (uint8 => uint256[]) referralsByLevel;  // all referrals ids

        // private
        uint256 witharawBuffer;
    }

    uint256 public globalDeposit;
    uint256 public globalWithdraw;

    Investor[] public investors;
    mapping (address => uint256) addressToInvestorId;
    mapping (uint256 => address) investorIdToAddress;

    modifier onlyForExisting() {
        require(addressToInvestorId[msg.sender] != 0);
        _;
    }

    constructor() public payable {
        globalDeposit = 0;
        globalWithdraw = 0;
        investors.push(Investor(0, 0, 0, 0, new uint256[](refLevelsCount), 0));
    }

    function() external payable {
        if (msg.value > 0) {
            deposit(0);
        } else {
            withdraw();
        }
    }

    function getInvestorInfo(uint256 _id) public view returns(uint256, uint256, uint256, uint256, uint256[] memory, uint256[] memory) {
        Investor memory investor = investors[_id];
        return (investor.lastWithdraw, investor.totalSum, investor.totalWithdraw, investor.totalReferralIncome, investor.referrersByLevel, investors[_id].referralsByLevel[uint8(0)]);
    }

    function getInvestorId(address _address) public view returns(uint256) {
        return addressToInvestorId[_address];
    }

    function getInvestorAddress(uint256 _id) public view returns(address) {
        return investorIdToAddress[_id];
    }

    function investorsCount() public view returns(uint256) {
        return investors.length;
    }

    /// @notice update referrersByLevel and referralsByLevel of new investor
    /// @param _newInvestorId the ID of the new investor
    /// @param _refId the ID of the investor who gets the affiliate fee
    function _updateReferrals(uint256 _newInvestorId, uint256 _refId) private {
        if (_newInvestorId == _refId) return;
        investors[_newInvestorId].referrersByLevel[0] = _refId;

        for (uint i = 1; i < refLevelsCount; i++) {
            uint256 refId = investors[_refId].referrersByLevel[i - 1];
            investors[_newInvestorId].referrersByLevel[i] = refId;
            investors[refId].referralsByLevel[uint8(i)].push(_newInvestorId);
        }

        investors[_refId].referralsByLevel[0].push(_newInvestorId);
        emit ReferralRegister(investorIdToAddress[_newInvestorId], investorIdToAddress[_refId]);
    }

    /// @notice distribute value of tx to referrers of investor
    /// @param _investor the investor object who gets the affiliate fee
    /// @param _sum value of ethereum for distribute to referrers of investor
    function _distributeReferrers(Investor memory _investor, uint256 _sum) private {
        uint256[] memory referrers = _investor.referrersByLevel;

        for (uint i = 0; i < refLevelsCount; i++)  {
            uint256 referrerId = referrers[i];

            if (referrers[i] == 0) break;
            // if (investors[referrerId].totalSum < minSumReferral) continue;

            uint16[] memory percents = getRefPercents(investors[referrerId].totalSum);
            uint256 value = _sum * percents[i] / 10000;
            if (investorIdToAddress[referrerId] != 0x0) {
                investorIdToAddress[referrerId].transfer(value);
                investors[referrerId].totalReferralIncome = investors[referrerId].totalReferralIncome + value;
                globalWithdraw = globalWithdraw + value;
            }
        }
    }

    function _distribute(Investor storage _investor, uint256 _sum) private {
        _distributeReferrers(_investor, _sum);
        developers.transfer(_sum * developersPercent / 100);
        marketers.transfer(_sum * marketersPercent / 100);
    }

    function _registerIfNeeded(uint256 _refId) private returns(uint256) {
        if (addressToInvestorId[msg.sender] != 0) return 0;

        uint256 id = investors.push(Investor(now, 0, 0, 0, new uint256[](refLevelsCount), 0)) - 1;
        addressToInvestorId[msg.sender] = id;
        investorIdToAddress[id] = msg.sender;

        if (_refId != 0)
            _updateReferrals(id, _refId);

        emit InvestorRegister(msg.sender, id);
    }

    function deposit(uint256 _refId) public payable returns(uint256) {
        if (addressToInvestorId[msg.sender] == 0)
            _registerIfNeeded(_refId);

        Investor storage investor = investors[addressToInvestorId[msg.sender]];
        uint256 amount = withdrawAmount();
        investor.lastWithdraw = now;
        investor.witharawBuffer = amount;
        investor.totalSum = investor.totalSum + msg.value;

        globalDeposit = globalDeposit + msg.value;

        _distribute(investor, msg.value);

        emit Deposit(msg.sender, msg.value);
        return investor.totalSum;
    }

    function withdrawAmount() public view returns(uint256) {
        Investor memory investor = investors[addressToInvestorId[msg.sender]];
        return investor.totalSum * getProgramPercent(investor.totalSum) / 8760 * ((now - investor.lastWithdraw) / 3600) / 100 + investor.witharawBuffer;
    }

    function withdraw() public onlyForExisting returns(uint256) {
        uint256 amount = withdrawAmount();

        require(amount > 0);
        require(amount < address(this).balance);

        Investor storage investor = investors[addressToInvestorId[msg.sender]];
        investor.totalWithdraw = investor.totalWithdraw + amount;
        investor.lastWithdraw = now;
        investor.witharawBuffer = 0;

        globalWithdraw = globalWithdraw + amount;
        msg.sender.transfer(amount);

        emit Withdraw(msg.sender, amount);
    }

}