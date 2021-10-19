pragma solidity 0.5.8;

import { Ownable } from "./Ownable.sol" ;
import "./SafeMath.sol";
import "./SafeERC20.sol";

contract Invite {
    function inviterAddressOf(address _account) public view returns (address InviterAddress);
}

contract SpiritFarm {
    function isHaveSpiritOf(address _account) public view returns (uint256 JoinTotalCount);
}

contract Register is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for ERC20;

    // Register Basis
    uint256 private dayTime;
    Invite private inviteContract;
    SpiritFarm private spiritFarmContract;
    ERC20 private dtuTokenContract;

    bool private switchState;
    uint256 private startTime;
    uint256 private endTime;
    uint256 private nowJoinTotalCount;
    uint256 private nowClaimDtuAmount;

    // Account
    mapping(address => RegisterAccount) private registerAccounts;
    struct RegisterAccount {
        uint256 totalJoinCount;
        uint256 lastRegisterTime;
        uint256 canRegisterTime;
        bool isClaimAchievementOne;
        bool isClaimAchievementTwo;
    }

    // Events
    event SedimentToken(address indexed _account,address  _erc20TokenContract, address _to, uint256 _amount);
    event AddressList(address indexed _account, address _dtuTokenContract, address _inviteContract, address _spiritFarmContract);
    event SetSwitchState(address indexed _account, bool _switchState);
    event JoinRegister(address indexed _account, uint256 _nowJoinTotalCount, uint256 _totalJoinCount);
    event Claim(address indexed _account, uint256 _achievementId, uint256 _claimAmount);

    // ================= Initial Value ===============

    constructor () public {
          /* dayTime = 86400; */
          dayTime = 600;
          inviteContract = Invite(0xe37495a91A7985e1afcdDcFd56c1FC848B510649);
          dtuTokenContract = ERC20(0x6f269df887c70536F895F7dFee415F78969Df7DB);
    }

    // ================= Register Operation  =====================

    function claim(uint256 achievementId) public returns (bool) {
        // Invite check
        require(spiritFarmContract.isHaveSpiritOf(msg.sender)>0,"-> spiritFarm: The number of sprites you have ever owned is 0.");

        // Data validation
        uint256 claimAmount;
        if(achievementId==1){
            require(registerAccounts[msg.sender].totalJoinCount>=7,"-> isClaimAchievementOne: Failed achievement 1.");
            require(!registerAccounts[msg.sender].isClaimAchievementOne,"-> isClaimAchievementOne: Received.");
            claimAmount = 7 * 10 ** 18;
            registerAccounts[msg.sender].isClaimAchievementOne = true;

        }else if(achievementId==2){
            require(registerAccounts[msg.sender].totalJoinCount>=15,"-> isClaimAchievementOne: Failed achievement 2.");
            require(!registerAccounts[msg.sender].isClaimAchievementTwo,"-> isClaimAchievementOne: Received.");
            claimAmount = 8 * 10 ** 18;
            registerAccounts[msg.sender].isClaimAchievementTwo = true;

        }else{
            require(false,"-> achievementId: error.");
        }
        nowClaimDtuAmount += claimAmount;

        emit Claim(msg.sender, achievementId, claimAmount);
        return true;
    }

    function joinRegister() public returns (bool) {
        // Invite check
        require(inviteContract.inviterAddressOf(msg.sender)!=address(0),"-> Invite: The address has not been added to the eco.");

        // Data validation
        require(switchState,"-> switchState: Check in task is not enabled.");
        require(block.timestamp<endTime,"-> endTime: Check in task has ended.");
        require(block.timestamp>=registerAccounts[msg.sender].canRegisterTime,"-> canRegisterTime: The next check-in time is not reached.");

        // Orders dispose
        if(registerAccounts[msg.sender].totalJoinCount <= 0){
            nowJoinTotalCount += 1;
        }
        registerAccounts[msg.sender].totalJoinCount += 1;
        registerAccounts[msg.sender].lastRegisterTime = block.timestamp;
        registerAccounts[msg.sender].canRegisterTime = block.timestamp.add(dayTime);

        emit JoinRegister(msg.sender, nowJoinTotalCount, registerAccounts[msg.sender].totalJoinCount);
        return true;
    }

    // ================= Contact Query  =====================

    function getRegisterBasic() public view returns (uint256 DayTime,Invite InviteContract,SpiritFarm SpiritFarmContract,ERC20 DtuTokenContract,bool SwitchState,uint256 StartTime,uint256 EndTime,uint256 NowJoinTotalCount,uint256 NowClaimDtuAmount) {
        return (dayTime,inviteContract,spiritFarmContract,dtuTokenContract,switchState,startTime,endTime,nowJoinTotalCount,nowClaimDtuAmount);
    }

    function registerAccountOf(address _account) public view returns (uint256 TotalJoinCount,uint256 LastRegisterTime,uint256 CanRegisterTime,bool IsClaimAchievementOne,bool IsClaimAchievementTwo) {
        RegisterAccount storage account = registerAccounts[_account];
        return (account.totalJoinCount,account.lastRegisterTime,account.canRegisterTime,account.isClaimAchievementOne,account.isClaimAchievementTwo);
    }

    // ================= Owner Operation  =================

    function getSedimentToken(address _erc20TokenContract, address _to, uint256 _amount) public onlyOwner returns (bool) {
        require(ERC20(_erc20TokenContract).balanceOf(address(this))>=_amount,"_amount: The current token balance of the contract is insufficient.");
        ERC20(_erc20TokenContract).safeTransfer(_to, _amount);// Transfer token to destination address
        emit SedimentToken(msg.sender, _erc20TokenContract, _to, _amount);// set log
        return true;// return result
    }

    // ================= Initial Operation  =====================

    function setAddressList(address _dtuTokenContract,address _inviteContract,address _spiritFarmContract) public onlyOwner returns (bool) {
        dtuTokenContract = ERC20(_dtuTokenContract);
        inviteContract = Invite(_inviteContract);
        spiritFarmContract = SpiritFarm(_spiritFarmContract);
        emit AddressList(msg.sender, _dtuTokenContract, _inviteContract, _spiritFarmContract);
        return true;
    }

    function setSwapSwitchState(bool _switchState) public onlyOwner returns (bool) {
        switchState = _switchState;
        if(startTime==0&&switchState){
            startTime = block.timestamp;
            endTime = startTime.add(dayTime.mul(2800000));// 28 days in total
        }
        emit SetSwitchState(msg.sender, _switchState);
        return true;
    }

}