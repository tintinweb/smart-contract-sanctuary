pragma solidity 0.5.8;

import { Ownable } from "./Ownable.sol" ;
import "./SafeMath.sol";
import "./SafeERC20.sol";

contract Invite {
    function inviterAddressOf(address _account) public view returns (address InviterAddress);
}

contract LpFarm is Ownable {

    using SafeMath for uint256;
    using SafeERC20 for ERC20;

    // LpFarm Basic
    uint256 private dayTime;
    bool private farmSwitchState;
    uint256 private farmStartTime;
    uint256 private nextFarmYieldTime;
    uint256 private nowDailyReward;
    uint256 private farmJoinTotalCount;
    uint256 private farmAccountTotalCount;
    uint256 private farmNowTotalAmount;
    uint256 private joinMinAmount;
    uint256 private totalNetOutputDtu;

    // Address List
    Invite private inviteContract;
    ERC20 private lpTokenContract;
    ERC20 private dtuTokenContract;
    address private unionPoolAddress;// 3%
    address private developmentFundAddress;// 2%

    // Account Info
    mapping(uint256 => address) private orderAccounts;
    mapping(address => FarmAccount) private farmAccounts;
    struct FarmAccount {
        uint256 joinTotalCount;
        uint256 nowJoinAmount;
        uint256 nowProfitAmount;
        uint256 totalProfitAmount;
        uint256 [] ordersIndex;
    }
    mapping(uint256 => FarmOrder) private farmOrders;
    struct FarmOrder {
        uint256 index;
        address account;
        uint256 joinTime;
        uint256 joinAmount;
    }

    // Events
    event SedimentToken(address indexed _account,address  _erc20TokenContract, address _to, uint256 _amount);
    event AddressList(address indexed _account, address _inviteContract, address _lpTokenContract, address _dtuTokenContract, address _unionPoolAddress, address _developmentFundAddress);
    event SwitchState(address indexed _account, bool _farmSwitchState);
    event JoinFarm(address indexed _account, uint256 _farmJoinTotalCount, uint256 _joinAmount);
    event ExitFarm(address indexed _account, uint256 _nowJoinAmount);
    event Claim(address indexed _account, uint256 _nowProfitAmount, uint256 _claimProfitAmount);
    event FarmYield(address indexed _account, uint256 _dayNum, uint256 _dailyReward, uint256 _farmAccountTotalCount);
    event JoinMin(address indexed _account, uint256 _joinMinAmount);

    // ================= Initial Value ===============

    constructor () public {
          /* dayTime = 86400; */
          dayTime = 120;
          farmSwitchState = false;
          nowDailyReward = 178400 * 10 ** 18;// 178400 Reward
          inviteContract = Invite(0xe37495a91A7985e1afcdDcFd56c1FC848B510649);
          lpTokenContract = ERC20(0x72783C370f41117822de2A214C42Fe39fdFAD748);
          dtuTokenContract = ERC20(0x6f269df887c70536F895F7dFee415F78969Df7DB);
          unionPoolAddress = address(0x13e4A8ddB241AF74846f341dE2A506fdc6646748);
          developmentFundAddress = address(0x4952cE6E663a19eB58109f65419ED09aeE904b0B);
          joinMinAmount = 1 * 10 ** 18;// 1 LP
    }

    // ================= Farm Operation  =================

    function dailyRewardOf(uint256 _dayNum) public view returns (uint256 DailyReward){
        uint256 out1 = _dayNum.div(120);// 120
        uint256 out2 = _dayNum.div(60);// 60
        uint256 dayDailyReward = nowDailyReward;
        for(uint256 i = 0; i < out1 ; i++){
            dayDailyReward = dayDailyReward.mul(90).div(100);// 90%
        }

        if(out2>=6){
            dayDailyReward = dayDailyReward.mul(55).div(100); // 55%
        }else{
            dayDailyReward = dayDailyReward.mul(out2.mul(5).add(30)).div(100); // 30 + out2
        }

        return dayDailyReward;
    }

    function toFarmYield() public returns (bool) {
        // Data validation
        require(farmSwitchState,"-> farmSwitchState: farm has not started yet.");
        require(block.timestamp>=nextFarmYieldTime,"-> nextFarmYieldTime: The start time has not been reached.");

        // Yield dispose
        uint256 secondDiff = nextFarmYieldTime.sub(farmStartTime);
        uint256 dayNum = secondDiff.div(dayTime).add(15);// dayNum + 15 day
        uint256 dailyReward = dailyRewardOf(dayNum);
        for(uint256 i=1;i<=farmAccountTotalCount;i++){
            if(farmAccounts[orderAccounts[i]].nowJoinAmount>0){
                farmAccounts[orderAccounts[i]].nowProfitAmount += dailyReward.mul(farmAccounts[orderAccounts[i]].nowJoinAmount).div(farmNowTotalAmount);// update farmAccountProfit
            }
        }
        nextFarmYieldTime += dayTime;// update nextFarmYieldTime
        totalNetOutputDtu += dailyReward;

        emit FarmYield(msg.sender,dayNum,dailyReward,farmAccountTotalCount);// set log
        return true;// return result
    }

    function claim() public returns (bool) {
        // Data validation
        uint256 nowProfitAmount = farmAccounts[msg.sender].nowProfitAmount;
        require(nowProfitAmount>0,"-> nowProfitAmount: Your current withdrawable income is 0.");

        // Withdrawal dispose
        farmAccounts[msg.sender].nowProfitAmount = 0;

        uint256 payUnionPoolFeeAmount = nowProfitAmount.mul(3).div(100);
        uint256 payDevelopmentFundFeeAmount = nowProfitAmount.mul(2).div(100);
        uint256 claimProfitAmount = nowProfitAmount.sub(payUnionPoolFeeAmount.add(payDevelopmentFundFeeAmount));
        farmAccounts[msg.sender].totalProfitAmount += claimProfitAmount;// update farmAccountProfit

        // Transfer
        dtuTokenContract.safeTransfer(msg.sender, claimProfitAmount);// Transfer dtu to farm address
        dtuTokenContract.safeTransfer(unionPoolAddress, payUnionPoolFeeAmount);// Transfer dtu to unionPoolAddress Address
        dtuTokenContract.safeTransfer(developmentFundAddress, payDevelopmentFundFeeAmount);// Transfer dtu to developmentFundAddress Address

        emit Claim(msg.sender, nowProfitAmount, claimProfitAmount);// set log
        return true;// return result
    }

    function exitFarm() public returns (bool) {
        // Data validation
        FarmAccount storage account =  farmAccounts[msg.sender];
        require(account.nowJoinAmount>0,"-> nowJoinAmount: The current pledge amount is 0.");

        // Orders dispose
        farmNowTotalAmount -= account.nowJoinAmount;
        farmAccounts[msg.sender].nowJoinAmount = 0;

        // Transfer
        lpTokenContract.safeTransfer(address(msg.sender), account.nowJoinAmount);// Transfer lp to farm address

        emit ExitFarm(msg.sender, account.nowJoinAmount);// set log
        return true;// return result
    }

    function joinFarm(uint256 _joinAmount) public returns (bool) {
        // Invite check
        require(inviteContract.inviterAddressOf(msg.sender)!=address(0),"-> Invite: The address has not been added to the eco.");

        // Data validation
        require(farmSwitchState,"-> farmSwitchState: farm has not started yet.");
        require(_joinAmount>=joinMinAmount,"-> joinMinAmount: The pledge amount cannot be less than the minimum limit amount.");
        require(lpTokenContract.balanceOf(msg.sender)>=_joinAmount,"-> _joinAmount: Insufficient address lp balance.");

        // Orders dispose
        farmJoinTotalCount += 1;// total number + 1
        farmNowTotalAmount += _joinAmount;
        if(farmAccounts[msg.sender].joinTotalCount <= 0){
            farmAccountTotalCount += 1;// account number +1
            orderAccounts[farmAccountTotalCount] = msg.sender;
        }

        farmAccounts[msg.sender].joinTotalCount += 1;
        farmAccounts[msg.sender].nowJoinAmount += _joinAmount;
        farmAccounts[msg.sender].ordersIndex.push(farmJoinTotalCount);// add farmAccount
        farmOrders[farmJoinTotalCount] = FarmOrder(farmJoinTotalCount,msg.sender,block.timestamp,_joinAmount);// add farmOrders

        // Transfer
        lpTokenContract.safeTransferFrom(address(msg.sender),address(this),_joinAmount);// lp to this

        emit JoinFarm(msg.sender, farmJoinTotalCount, _joinAmount);// set log
        return true;// return result
    }

    // ================= Farm Query  =====================

    function getFarmBasic() public view returns (Invite InviteContract,ERC20 LpTokenContract,ERC20 DtuTokenContract,address UnionPoolAddress,address DevelopmentFundAddress,
      bool FarmSwitchState,uint256 FarmStartTime,uint256 NextFarmYieldTime,uint256 NowDailyReward,uint256 FarmJoinTotalCount,uint256 FarmAccountTotalCount,uint256 FarmNowTotalAmount,uint256 JoinMinAmount,uint256 TotalNetOutputDtu)
    {
        return (inviteContract,lpTokenContract,dtuTokenContract,unionPoolAddress,developmentFundAddress,
          farmSwitchState,farmStartTime,nextFarmYieldTime,nowDailyReward,farmJoinTotalCount,farmAccountTotalCount,farmNowTotalAmount,joinMinAmount,totalNetOutputDtu);
    }

    function farmAccountProfitOf(address _account) public view returns (uint256 JoinTotalCount,uint256 NowJoinAmount,uint256 NowProfitAmount,uint256 TotalProfitAmount,uint256 [] memory OrdersIndex){
        FarmAccount storage account =  farmAccounts[_account];
        return (account.joinTotalCount,account.nowJoinAmount,account.nowProfitAmount,account.totalProfitAmount,account.ordersIndex);
    }

    function farmOrdersOf(uint256 _joinOrderIndex) public view returns (uint256 Index,address Account,uint256 JoinTime,uint256 JoinAmount){
        FarmOrder storage order =  farmOrders[_joinOrderIndex];
        return (order.index,order.account,order.joinTime,order.joinAmount);
    }

    function orderAccountsOf(uint256 _index) public view returns (address Account){
        return orderAccounts[_index];
    }

    // ================= Owner Operation  =================

    function getSedimentToken(address _erc20TokenContract, address _to, uint256 _amount) public onlyOwner returns (bool) {
        require(ERC20(_erc20TokenContract).balanceOf(address(this))>=_amount,"_amount: The current token balance of the contract is insufficient.");
        ERC20(_erc20TokenContract).safeTransfer(_to, _amount);// Transfer wiki to destination address
        emit SedimentToken(msg.sender, _erc20TokenContract, _to, _amount);// set log
        return true;// return result
    }

    // ================= Initial Operation  =====================

    function setAddressList(address _inviteContract,address _lpTokenContract,address _dtuTokenContract,address _unionPoolAddress,address _developmentFundAddress) public onlyOwner returns (bool) {
        inviteContract = Invite(_inviteContract);
        lpTokenContract = ERC20(_lpTokenContract);
        dtuTokenContract = ERC20(_dtuTokenContract);
        unionPoolAddress = _unionPoolAddress;
        developmentFundAddress = _developmentFundAddress;
        emit AddressList(msg.sender, _inviteContract, _lpTokenContract, _dtuTokenContract, _unionPoolAddress, _developmentFundAddress);
        return true;
    }

    function setFarmSwitchState(bool _farmSwitchState) public onlyOwner returns (bool) {
        farmSwitchState = _farmSwitchState;
        if(farmStartTime==0&&farmSwitchState){
              farmStartTime = block.timestamp;// set farmStartTime
              nextFarmYieldTime = farmStartTime.add(dayTime);// set nextFarmYieldTime
        }
        emit SwitchState(msg.sender, _farmSwitchState);
        return true;
    }

    function setJoinMinAmount(uint256 _joinMinAmount) public onlyOwner returns (bool) {
        joinMinAmount = _joinMinAmount;
        emit JoinMin(msg.sender, _joinMinAmount);
        return true;
    }

}