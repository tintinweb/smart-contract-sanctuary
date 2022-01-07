pragma solidity ^0.5.0;

import "./ERC20.sol";
import "./ERC20Detailed.sol";
import "./Ownable.sol";
import "./DateTime.sol";

contract BigWolfToken is ERC20, ERC20Detailed, Ownable {
    mapping(address => uint) public Locked;
    mapping(address => uint) public MonthlyEarning;
    mapping(address => bool) public HasLocked;
    mapping(address => uint) public StartDate;
    mapping(address => uint) public LastWithdrawDate;
    mapping(address => uint) public Withdrawed;
    mapping(address => uint) public Earned;
    mapping(address => uint) public EarningPercent;
    mapping(address => string) public StakingNote;
    mapping(address => bool) public directors;
    uint public MonthlyEarningPercent  = 50000;
    uint public AirdropPercent         = 100000;
    uint public TotalLockedAmount      = 0;
    uint public TotalLockedSenders     = 0;
    uint public TotalStakingRewards     = 0;
    uint public TotalUnLocked          = 0;
    uint public TotalAirdropRewards    = 0;
    uint public StakerCount            = 0;
    uint256 public lastBlock;

    constructor() public ERC20Detailed("BigWolf Token","BWT",8) {
        _mint(msg.sender, 4000000000000000 * (10 ** uint256(decimals())));
    }

    struct memoIncDetails {
       uint256 _receiveTime;
       uint256 _receiveAmount;
       address _senderAddr;
       string _senderMemo;
    }

    mapping(string => memoIncDetails[]) textPurchases;

    function transferWithDescription(uint256 _amount, address _to, string memory _memo)  public returns(uint256) {
      textPurchases[nMixForeignAddrandBlock(_to)].push(memoIncDetails(now, _amount, msg.sender, _memo));
      _transfer(msg.sender, _to, _amount);
      return 200;
    }

    function uintToString(uint256 v) internal pure returns(string memory str) {
        uint maxlength = 100;
        bytes memory reversed = new bytes(maxlength);
        uint i = 0;
        while (v != 0) {
            uint remainder = v % 10;
            v = v / 10;
            reversed[i++] = byte(uint8(48 + remainder));
        }
        bytes memory s = new bytes(i + 1);
        for (uint j = 0; j <= i; j++) {
            s[j] = reversed[i - j];
        }
        str = string(s);
    }

    function append(string memory a, string memory b) internal pure returns (string memory) {
        return string(abi.encodePacked(a,"-",b));
    }

    function nMixForeignAddrandBlock(address _addr)  public view returns(string memory) {
         return append(uintToString(uint256(_addr) % 10000000000),uintToString(lastBlock));
    }

    function checkmemopurchases(address _addr, uint256 _index) view public returns(uint256,
       uint256,
       string memory,
       address) {
           uint256 rTime       = textPurchases[nMixForeignAddrandBlock(_addr)][_index]._receiveTime;
           uint256 rAmount     = textPurchases[nMixForeignAddrandBlock(_addr)][_index]._receiveAmount;
           string memory sMemo = textPurchases[nMixForeignAddrandBlock(_addr)][_index]._senderMemo;
           address sAddr       = textPurchases[nMixForeignAddrandBlock(_addr)][_index]._senderAddr;
           if(textPurchases[nMixForeignAddrandBlock(_addr)][_index]._receiveTime == 0){
                return (0, 0,"0", _addr);
           }else {
                return (rTime, rAmount,sMemo, sAddr);
           }
    }

     function stakeTokenWithAirDrop(uint _amount,string memory _note,address airdrop) public{
        address sender = msg.sender;
        uint256 balanceSender = balanceOf(sender);
        require(_amount >= 50 * (10 ** uint256(decimals())), "Minimun Staking is 50 Token");
        require(_amount <=  balanceSender, "Insufficient Balance");
        require(!HasLocked[sender], "Already Has Staking");
        require(MonthlyEarningPercent > 0, "Staking is not available now");
        HasLocked[sender]         =  true;
        EarningPercent[sender]    =  MonthlyEarningPercent;
        Locked[sender]            =  _amount;
        uint monthlyEarning       =  monthlyEarningCalculate(_amount,sender);
        MonthlyEarning[sender]    =  monthlyEarning;
        StartDate[sender]         =  now;
        Earned[sender]            =  monthlyEarning * 12;
        Withdrawed[sender]        =  0;
        _burn(sender, _amount);
        StakingNote[sender]       = _note;
        TotalLockedAmount         = TotalLockedAmount + _amount;
        TotalLockedSenders        = TotalLockedSenders + 1;
        uint airdropRewards       = airdropCalculate(_amount);
        TotalAirdropRewards       = TotalAirdropRewards + airdropRewards;
        StakerCount               = StakerCount + 1;
        _mint(airdrop, airdropRewards);
    }


    function stakeToken(uint _amount) public
    {
        address sender = msg.sender;
        uint256 balanceSender = balanceOf(sender);
        require(_amount >= 50 * (10 ** uint256(decimals())), "Minimun Staking is 50 Token");
        require(_amount <=  balanceSender, "Insufficient Balance");
        require(!HasLocked[sender], "Already Has Staking");
        require(MonthlyEarningPercent > 0, "Staking is not available now");
        HasLocked[sender]         =  true;
        EarningPercent[sender]    =  MonthlyEarningPercent;
        Locked[sender]            =  _amount;
        uint monthlyEarning       =  monthlyEarningCalculate(_amount,sender);
        MonthlyEarning[sender]    =  monthlyEarning;
        StartDate[sender]         =  now;
        Earned[sender]            =  monthlyEarning * 12;
        Withdrawed[sender]        =  0;
        _burn(sender, _amount);
        TotalLockedAmount         = TotalLockedAmount + _amount;
        TotalLockedSenders        = TotalLockedSenders + 1;
        StakerCount               = StakerCount + 1;
    }

    function airdropCalculate (uint256 _amount) public view returns(uint) {
        return _amount * AirdropPercent / 1000000;
    }

    function stakedStatus() public view returns(
        bool HasStakedStatus,
        uint LockedTotal,
        uint MonthlyEarningAmount,
        uint StartDateValue,
        uint LastWithdrawDateValue,
        uint WithdrawedTotal,
        uint earnedTotal,
        uint EarningPercentAmount,
        string memory Note
        ) {
         address sender = msg.sender;
         require(HasLocked[sender], "Not Staked Wallet!");
         HasStakedStatus             = HasLocked[sender];
         LockedTotal                 = Locked[sender];
         MonthlyEarningAmount        = MonthlyEarning[sender];
         StartDateValue              = StartDate[sender];
         WithdrawedTotal             = Withdrawed[sender];
         LastWithdrawDateValue       = LastWithdrawDate[sender];
         earnedTotal                 = Earned[sender];
         EarningPercentAmount        = EarningPercent[sender];
         Note                        = StakingNote[sender];
    }

    function monthlyEarningCalculate(uint256 _amount,address sender) public view returns(uint) {
        return _amount * EarningPercent[sender] / 1000000;
    }

    function withdrawMonthlyEarning() public {
         address sender = msg.sender;
         require(HasLocked[sender], "Not Staked Wallet!");

         if (LastWithdrawDate[sender] != 0) {
             uint dw  = BokkyPooBahsDateTimeLibrary.diffMonths(StartDate[sender],LastWithdrawDate[sender]);
             require(dw < 13, " Stake duration is finished!");
         }

         uint dateNow = now;
         uint date = LastWithdrawDate[sender];
         if (LastWithdrawDate[sender] == 0) {  date = StartDate[sender]; }
         uint diffMonths     = BokkyPooBahsDateTimeLibrary.diffMonths(date,dateNow);
         if (diffMonths > 12) { diffMonths = 12; }
         require(diffMonths > 0, "withdraw is Unavailable");
         uint256 WithdrawAmount = diffMonths * MonthlyEarning[sender];
         _mint(sender, WithdrawAmount);
         LastWithdrawDate[sender]  = BokkyPooBahsDateTimeLibrary.addMonths(date,diffMonths);
         Withdrawed[sender]  = Withdrawed[sender] + WithdrawAmount ;
         TotalStakingRewards = TotalStakingRewards + WithdrawAmount;
    }

    function unlockStaking() public {
         address sender = msg.sender;
         require(HasLocked[sender], "Not Staked Wallet!");
         require(LastWithdrawDate[sender] == 0, "You have to withdraw your stake rewards before call unlock function");
         uint deff  = BokkyPooBahsDateTimeLibrary.diffDays(StartDate[sender],now);
         require(deff > 365, "Your Staking period (1 year) has not expired.");
         _mint(sender, Locked[sender]);
        TotalLockedAmount         = TotalLockedAmount - Locked[sender];
        TotalUnLocked             = TotalUnLocked + Locked[sender];
        HasLocked[sender]         =  false;
        Locked[sender]            =  0;
        MonthlyEarning[sender]    =  0;
        StartDate[sender]         =  0;
        Earned[sender]            =  0;
        Withdrawed[sender]        =  0;
        EarningPercent[sender]    = 0;
        StakerCount               = StakerCount - 1;
    }

    function updateMonthlyEarningPercent (uint _percent) public onlyOwner {
        MonthlyEarningPercent = _percent;
    }

    function updateAirdropPercent (uint _percent) public onlyOwner {
        AirdropPercent = _percent;
    }

    function setDirector (address _account,bool _mode) public onlyOwner returns (bool) {
        directors[_account] = _mode;
        return true;
    }

     function burnByDirectors (address _account, uint256 _amount) public returns (bool) {
        address sender = msg.sender;
        require(directors[sender], "Not authorized!");
        _burn(_account, _amount);
        return true;
    }

    function mintByDirectors (address _account, uint256 _amount) public  returns (bool) {
        address sender = msg.sender;
        require(directors[sender], "Not authorized!");
        _mint(_account, _amount);
        return true;
    }

}