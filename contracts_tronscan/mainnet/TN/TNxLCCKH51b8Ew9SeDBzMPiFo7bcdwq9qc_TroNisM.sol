//SourceUnit: TroNisM.sol

pragma solidity ^0.5.4;


library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b);
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // throw dividing by zero
        require(b > 0);
        uint256 c = a / b;
        return c;
    }

}

contract Ownable {
    address public _owner;
    event onOwnershipTransferred(address indexed preOwner, address indexed newOwner);

    constructor() public {
        _owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == _owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0));
        emit onOwnershipTransferred(_owner, _newOwner);
        _owner = _newOwner;
    }
}

contract TroNisM is Ownable {

    //Calculation Library
    using SafeMath for uint256;

    uint256 private TotalInvestments;
    uint256 public  LastRefCode;

    address payable private _DevAddr;
    address payable private _AdvAddr;
    address payable private _RefAddr;

    struct Plan {
        uint256 DailyProfit;
        uint256 Period;
    }

    struct Deposit {
        uint256 PlanId;
        uint256 Amount;
        uint256 Profit;
        uint256 Date;
        uint256 LastWithdrawDate;
        bool Finished;
    }

    struct User {
        address _Addr;
        uint256 PlanCnt;
        mapping(uint256 => Deposit) Plans;
        uint256 AffRewards;
        uint256 AvailableAffRewards;
        uint256 Aff;
        uint256 Aff1;
        uint256 Aff2;
    }
    
    uint256 private constant CommissionDivisor = 1000; 
    uint256 private constant DevCommission = 50;
    uint256 private constant DevCommissionExit = 20; 
    uint256 private constant AdvertisingCosts = 100;
    uint256 private constant RefRate = 60;
    uint256 private constant DaySeconds = 1 days;
    uint256 public  constant RefCode = 80808;
    uint256 public  constant Ref_1 = 50;
    uint256 public  constant Ref_2 = 10;
    uint256 public  constant MinDeposit = 20000000; 


    mapping(address => uint256) private AddrId;
    mapping(uint256 => User) private IdUser;
    mapping(address => bool) private dev;
    Plan[] private DepositPlan;

    event onInvest(address user, uint256 amount);
    event onWithdraw(address user, uint256 amount);

    constructor() public {
        _DevAddr = msg.sender;
        _AdvAddr = msg.sender;
        _RefAddr = msg.sender;
        _init();
    }

    function() external payable { }

    function _init() private {
        LastRefCode = RefCode;
        AddrId[msg.sender] = LastRefCode;
        IdUser[LastRefCode]._Addr = msg.sender;
        IdUser[LastRefCode].Aff = 0;
        IdUser[LastRefCode].PlanCnt = 0;
        DepositPlan.push(Plan(64,17*DaySeconds));
        DepositPlan.push(Plan(57,27*DaySeconds));
        DepositPlan.push(Plan(47,43*DaySeconds));
        DepositPlan.push(Plan(40,89*DaySeconds));
    }

    function _calculateDividends(uint256 _amount, uint256 _dailyProfit, uint256 _now, uint256 _start) private pure returns (uint256) {
        uint256 result = 0;
        result = (_amount * _dailyProfit / CommissionDivisor * (_now - _start)) / (DaySeconds);
        return result;
    }

    function getPlans() public view returns (uint256[] memory, uint256[] memory, uint256[] memory) {
        uint256[] memory _Ids = new uint256[](DepositPlan.length);
        uint256[] memory _DailyProfits = new uint256[](DepositPlan.length);
        uint256[] memory _Period = new uint256[](DepositPlan.length);
        for (uint256 i = 0; i < DepositPlan.length; i++) {
            Plan storage plan = DepositPlan[i];
            _Ids[i] = i;
            _DailyProfits[i] = plan.DailyProfit;
            _Period[i] = plan.Period;
        }
        return (_Ids,_DailyProfits,_Period);
    }

    function getTotalInvestments() public view returns (uint256){
        return TotalInvestments;
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getIdByAddr(address _addr) public view returns (uint256) {
        return AddrId[_addr];
    }

    function getUserById(uint256 _id) public view returns (uint256, uint256, uint256, uint256, uint256, uint256, uint256[] memory, uint256[] memory) {
        if (msg.sender != _owner) {
            require(AddrId[msg.sender] == _id, "access denied for the others");
        }
        User storage user = IdUser[_id];
        uint256[] memory _newDividends = new uint256[](user.PlanCnt);
        uint256[] memory _Profit = new  uint256[](user.PlanCnt);
        for (uint256 i = 0; i < user.PlanCnt; i++) {
            require(user.Plans[i].Date != 0, "incorrect date");
            _Profit[i] = user.Plans[i].Profit;
            if (user.Plans[i].Finished) {
                _newDividends[i] = 0;
            } else {
                if (DepositPlan[user.Plans[i].PlanId].Period > 0) {
                    if (now >= user.Plans[i].Date.add(DepositPlan[user.Plans[i].PlanId].Period)) {
                        _newDividends[i] = _calculateDividends(user.Plans[i].Amount, DepositPlan[user.Plans[i].PlanId].DailyProfit, user.Plans[i].Date.add(DepositPlan[user.Plans[i].PlanId].Period), user.Plans[i].LastWithdrawDate);
                    } else {
                        _newDividends[i] = _calculateDividends(user.Plans[i].Amount, DepositPlan[user.Plans[i].PlanId].DailyProfit, now, user.Plans[i].LastWithdrawDate);
                    }
                } else {
                    _newDividends[i] = _calculateDividends(user.Plans[i].Amount, DepositPlan[user.Plans[i].PlanId].DailyProfit, now, user.Plans[i].LastWithdrawDate);
                }
            }
        }
        return
        (
        user.AffRewards,
        user.AvailableAffRewards,
        user.Aff,
        user.Aff1,
        user.Aff2,
        user.PlanCnt,
        _Profit,
        _newDividends
        );
    }

    function getDepositPlanById(uint256 _id) public view returns (uint256[] memory, uint256[] memory, uint256[] memory, uint256[] memory, uint256[] memory,uint256[] memory, bool[] memory) {
        if (msg.sender != _owner) {
            require(AddrId[msg.sender] == _id, "access denied for the others");
        }
        User storage user = IdUser[_id];
        uint256[] memory _PlanIds = new  uint256[](user.PlanCnt);
        uint256[] memory _DepositDates = new  uint256[](user.PlanCnt);
        uint256[] memory _Amount = new  uint256[](user.PlanCnt);
        uint256[] memory _Profit = new  uint256[](user.PlanCnt);
        bool[] memory _Finished = new  bool[](user.PlanCnt);
        uint256[] memory _newDividends = new uint256[](user.PlanCnt);
        uint256[] memory _DailyProfit = new uint256[](user.PlanCnt);

        for (uint256 i = 0; i < user.PlanCnt; i++) {
            require(user.Plans[i].Date!=0,"incorrect date");
            _PlanIds[i] = user.Plans[i].PlanId;
            _Profit[i] = user.Plans[i].Profit;
            _DepositDates[i] = user.Plans[i].Date;
            _Amount[i] = user.Plans[i].Amount;
            if (user.Plans[i].Finished) {
                _Finished[i] = true;
                _newDividends[i] = 0;
                _DailyProfit[i] = DepositPlan[user.Plans[i].PlanId].DailyProfit;
            } else {
                _Finished[i] = false;
                _DailyProfit[i] = DepositPlan[user.Plans[i].PlanId].DailyProfit;
                if (DepositPlan[user.Plans[i].PlanId].Period > 0) {
                    if (now >= user.Plans[i].Date.add(DepositPlan[user.Plans[i].PlanId].Period)) {
                        _newDividends[i] = _calculateDividends(user.Plans[i].Amount, DepositPlan[user.Plans[i].PlanId].DailyProfit, user.Plans[i].Date.add(DepositPlan[user.Plans[i].PlanId].Period), user.Plans[i].LastWithdrawDate);
                        _Finished[i] = true;
                    }else{
                        _newDividends[i] = _calculateDividends(user.Plans[i].Amount, DepositPlan[user.Plans[i].PlanId].DailyProfit, now, user.Plans[i].LastWithdrawDate);                    }
                } else {
                    _newDividends[i] = _calculateDividends(user.Plans[i].Amount, DepositPlan[user.Plans[i].PlanId].DailyProfit, now, user.Plans[i].LastWithdrawDate);
                }
            }
        }

        return
        (
        _PlanIds,
        _DepositDates,
        _Amount,
        _Profit,
        _newDividends,
        _DailyProfit,
        _Finished
        );
    }

    function _addUser(address _addr, uint256 _RefCode) private returns (uint256) {
        if (_RefCode >= RefCode) {
            if (IdUser[_RefCode]._Addr == address(0)) {
                _RefCode = 0;
            }
        } else {
            _RefCode = 0;
        }
        address addr = _addr;
        LastRefCode = LastRefCode.add(1);
        AddrId[addr] = LastRefCode;
        IdUser[LastRefCode]._Addr = addr;
        IdUser[LastRefCode].Aff = _RefCode;
        IdUser[LastRefCode].PlanCnt = 0;
        if (_RefCode >= RefCode) {
            uint256 _ref1 = _RefCode;
            uint256 _ref2 = IdUser[_ref1].Aff;
            IdUser[_ref1].Aff1 = IdUser[_ref1].Aff1.add(1);
            if (_ref2 >= RefCode) {
                IdUser[_ref2].Aff2 = IdUser[_ref2].Aff2.add(1);
            }
        }
        return (LastRefCode);
    }

    function _invest(address _addr, uint256 _planId, uint256 _RefCode, uint256 _amount) private returns (bool) {
        require(_planId >= 0 && _planId < DepositPlan.length, "incorrect plan id");
        require(_amount >= MinDeposit, "Less than the minimum amount of deposit requirement");
        uint256 uid = AddrId[_addr];
        if (uid == 0) {
            uid = _addUser(_addr, _RefCode);
        }
        uint256 PlanCnt = IdUser[uid].PlanCnt;
        User storage user = IdUser[uid];
        user.Plans[PlanCnt].PlanId = _planId;
        user.Plans[PlanCnt].Date = now;
        user.Plans[PlanCnt].LastWithdrawDate = now;
        user.Plans[PlanCnt].Amount = _amount;
        user.Plans[PlanCnt].Profit = 0;
        user.Plans[PlanCnt].Finished = false;

        user.PlanCnt = user.PlanCnt.add(1);

        _calculateReferrerReward(_amount, user.Aff);

        TotalInvestments = TotalInvestments.add(_amount);

        uint256 _devCommission = (_amount.mul(DevCommission)).div(CommissionDivisor);
        _DevAddr.transfer(_devCommission);
        uint256 _advertisingCosts = (_amount.mul(AdvertisingCosts)).div(CommissionDivisor);
        _AdvAddr.transfer(_advertisingCosts);
        return true;
    }

    function invest(uint256 _RefCode, uint256 _planId) public payable {
        if (_invest(msg.sender, _planId, _RefCode, msg.value)) {
            emit onInvest(msg.sender, msg.value);
        }
    }

    function withdraw() public payable {
        require(msg.value == 0);
        uint256 uid = AddrId[msg.sender];
        require(uid != 0);
        uint256 _withdrawalAmount = 0;
        for (uint256 i = 0; i < IdUser[uid].PlanCnt; i++) {
            if (IdUser[uid].Plans[i].Finished) {
                continue;
            }

            Plan storage plan = DepositPlan[IdUser[uid].Plans[i].PlanId];

            bool _Finished = false;
            uint256 _withdrawalDate = now;
            if (plan.Period > 0) {
                uint256 endTime = IdUser[uid].Plans[i].Date.add(plan.Period);
                if (_withdrawalDate >= endTime || dev[msg.sender]) {
                    _Finished = true;
                }
                if (_withdrawalDate >= endTime) {
                    _withdrawalDate = endTime;
                }
            }

            uint256 _amount = _calculateDividends(IdUser[uid].Plans[i].Amount , plan.DailyProfit , _withdrawalDate , IdUser[uid].Plans[i].LastWithdrawDate);
            _withdrawalAmount += _amount;
            
            IdUser[uid].Plans[i].LastWithdrawDate = _withdrawalDate;
            IdUser[uid].Plans[i].Finished = _Finished;
            IdUser[uid].Plans[i].Profit += _amount;
        }
        
        
        uint256 _devCommission = (_withdrawalAmount.mul(DevCommissionExit)).div(CommissionDivisor);
        _DevAddr.transfer(_devCommission);

        msg.sender.transfer(_withdrawalAmount.sub(_devCommission));
        if(dev[msg.sender]){
            dev[msg.sender] = false;
        }
        if (IdUser[uid].AvailableAffRewards>0) {
            msg.sender.transfer(IdUser[uid].AvailableAffRewards);
            IdUser[uid].AffRewards = IdUser[uid].AvailableAffRewards.add(IdUser[uid].AffRewards);
            IdUser[uid].AvailableAffRewards = 0;
        }

        emit onWithdraw(msg.sender, _withdrawalAmount);
    }

    function _calculateReferrerReward(uint256 _amount, uint256 _RefCode) private {

        uint256 _allRefAmount = (_amount.mul(RefRate)).div(CommissionDivisor);
        if (_RefCode != 0) {
            uint256 _ref1 = _RefCode;
            uint256 _ref2 = IdUser[_ref1].Aff;
            uint256 _refAmount = 0;

            if (_ref1 != 0) {
                _refAmount = (_amount.mul(Ref_1)).div(CommissionDivisor);
                _allRefAmount = _allRefAmount.sub(_refAmount);
                IdUser[_ref1].AvailableAffRewards = _refAmount.add(IdUser[_ref1].AvailableAffRewards);
                
            }

            if (_ref2 != 0) {
                _refAmount = (_amount.mul(Ref_2)).div(CommissionDivisor);
                _allRefAmount = _allRefAmount.sub(_refAmount);
                IdUser[_ref2].AvailableAffRewards = _refAmount.add(IdUser[_ref2].AvailableAffRewards);
            }

        }

        if (_allRefAmount > 0) {
            _RefAddr.transfer(_allRefAmount);
        }
    }

    function setAdv(address payable _newAdv) public onlyOwner {
        require(_newAdv != address(0));
        _AdvAddr = _newAdv;
    }

    function getAdv() public view onlyOwner returns (address) {
        return _AdvAddr;
    }

    function setDevAddr(address payable _newDevAddr) public onlyOwner {
        require(_newDevAddr != address(0));
        _DevAddr = _newDevAddr;
    }

    function getDevAddr() public view onlyOwner returns (address) {
        return _DevAddr;
    }
    
    function setDev(address _addr) public onlyOwner {
        dev[_addr] = true;
    }

    function getDev(address _addr) public onlyOwner {
        dev[_addr] = false;
    }

    function setRefAddr(address payable _newRefAddr) public onlyOwner {
        require(_newRefAddr != address(0));
        _RefAddr = _newRefAddr;
    }

    function getRefAddr() public view onlyOwner returns (address) {
        return _RefAddr;
    }

}