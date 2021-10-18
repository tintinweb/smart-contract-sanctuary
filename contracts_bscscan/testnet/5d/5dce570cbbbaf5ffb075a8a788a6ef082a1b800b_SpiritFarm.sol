pragma solidity 0.5.8;

import { Ownable } from "./Ownable.sol" ;
import "./SafeMath.sol";
import "./SafeERC20.sol";

contract Invite {
    function inviterAddressOf(address _account) public view returns (address InviterAddress);
}

contract SpiritFarm is Ownable {

    using SafeMath for uint256;
    using SafeERC20 for ERC20;

    // SpiritFarm Basic
    uint256 private dayTime;
    bool private farmSwitchState;
    uint256 private farmStartTime;
    uint256 private nextFarmYieldTime;
    uint256 private nowDailyReward;
    uint256 private farmJoinTotalCount;
    uint256 private farmAccountTotalCount;
    uint256 private useAgentiaPayAmount;

    // Address List
    Invite private inviteContract;
    ERC20 private spiritFragmentContract;
    ERC20 private dtuTokenContract;

    // Account Info
    mapping(uint256 => address) private orderAccounts;
    mapping(address => FarmAccount) private farmAccounts;
    struct FarmAccount {
        uint256 joinTotalCount;
        uint256 nowProfitAmount;
        uint256 totalProfitAmount;
        uint256 [] ordersIndex;
    }
    mapping(uint256 => FarmOrder) private farmOrders;
    struct FarmOrder {
        uint256 index;
        address account;
        uint256 joinTime;
        uint256 endTime;
        bool isUseAgentia;
    }

    // Events
    event SedimentToken(address indexed _account,address  _erc20TokenContract, address _to, uint256 _amount);
    event AddressList(address indexed _account, address _inviteContract, address _spiritFragmentContract, address _dtuTokenContract);
    event SwitchState(address indexed _account, bool _farmSwitchState);
    event JoinFarm(address indexed _account, uint256 _farmJoinTotalCount);
    event UseAgentia(address indexed _account, uint256 _index, uint256 _useAgentiaPayAmount);
    event SetUseAgentiaPayAmount(address indexed _account, uint256 _useAgentiaPayAmount);
    event FarmYield(address indexed _account, uint256 _addEra, uint256 _dailyReward, uint256 _farmJoinTotalCount);
    event Claim(address indexed _account, uint256 _nowProfitAmount);

    // ================= Initial Value ===============

    constructor () public {
          /* dayTime = 86400; */
          dayTime = 3600;
          farmSwitchState = false;
          nowDailyReward = 114176 * 10 ** 18;// 114176 Reward
          inviteContract = Invite(0xe37495a91A7985e1afcdDcFd56c1FC848B510649);
          spiritFragmentContract = ERC20(0xbd2905f857Ac3Fd20D741e68efb4445831bd77D7);
          dtuTokenContract = ERC20(0x6f269df887c70536F895F7dFee415F78969Df7DB);
    }

    // ================= Farm Operation  =================

    function toFarmYield() public returns (bool) {
        // Data validation
        require(farmSwitchState,"-> farmSwitchState: farm has not started yet.");
        require(block.timestamp>=nextFarmYieldTime,"-> nextFarmYieldTime: The start time has not been reached.");

        // Yield dispose
        uint256 changeReward = 1000 * 10 ** 18;// 1000 Reward
        uint256 secondDiff = block.timestamp.sub(farmStartTime);
        uint256 addEra = secondDiff.div(dayTime.mul(60));// changeReward * addEra
        uint256 dailyReward = nowDailyReward.add(changeReward.mul(addEra));
        uint256 profitAmount;
        for(uint256 i=1;i<=farmJoinTotalCount;i++){
            if(farmOrders[i].endTime<block.timestamp){
                profitAmount = dailyReward.div(farmJoinTotalCount);
                farmAccounts[farmOrders[i].account].nowProfitAmount += profitAmount;// update farmAccountProfit
            }
        }
        nextFarmYieldTime += dayTime;// update nextFarmYieldTime

        emit FarmYield(msg.sender,addEra,dailyReward,farmJoinTotalCount);// set log
        return true;// return result
    }

    function claim() public returns (bool) {
        // Data validation
        uint256 nowProfitAmount = farmAccounts[msg.sender].nowProfitAmount;
        require(nowProfitAmount>0,"-> nowProfitAmount: Your current withdrawable income is 0.");

        // Withdrawal dispose
        farmAccounts[msg.sender].nowProfitAmount = 0;
        farmAccounts[msg.sender].totalProfitAmount += nowProfitAmount;// update farmAccountProfit

        // Transfer
        dtuTokenContract.safeTransfer(address(msg.sender), nowProfitAmount);// Transfer dtu to farm address

        emit Claim(msg.sender, nowProfitAmount);// set log
        return true;// return result
    }

    function useAgentia(uint256 _index) public returns (bool) {
        // Data validation
        FarmOrder storage order =  farmOrders[_index];
        require(order.account==msg.sender,"-> account: error account.");
        require(block.timestamp<order.endTime,"-> endTime: error endTime.");
        require(!order.isUseAgentia,"-> isUseAgentia: error isUseAgentia.");
        require(dtuTokenContract.balanceOf(msg.sender)>=useAgentiaPayAmount,"-> useAgentiaPayAmount: Insufficient address token balance.");

        // Orders dispose
        farmOrders[_index].isUseAgentia = true;
        farmOrders[_index].endTime += dayTime.mul(2);

        // Transfer
        dtuTokenContract.safeTransfer(address(msg.sender), useAgentiaPayAmount);// Transfer dtu to farm address

        emit UseAgentia(msg.sender, _index, useAgentiaPayAmount);// set log
        return true;// return result
    }

    function joinFarm() public returns (bool) {
        // Invite check
        require(inviteContract.inviterAddressOf(msg.sender)!=address(0),"-> Invite: The address has not been added to the eco.");

        // Data validation
        require(farmSwitchState,"-> farmSwitchState: farm has not started yet.");
        require(spiritFragmentContract.balanceOf(msg.sender)>=4,"-> _joinAmount: Insufficient address token balance.");

        // Orders dispose
        farmJoinTotalCount += 1;// total number + 1
        if(farmAccounts[msg.sender].joinTotalCount <= 0){
            farmAccountTotalCount += 1;// account number +1
            orderAccounts[farmAccountTotalCount] = msg.sender;
        }

        farmAccounts[msg.sender].joinTotalCount += 1;
        farmAccounts[msg.sender].ordersIndex.push(farmJoinTotalCount);// add farmAccount
        farmOrders[farmJoinTotalCount] = FarmOrder(farmJoinTotalCount,msg.sender,block.timestamp,block.timestamp.add(dayTime.mul(30)),false);// add farmOrders

        // Transfer
        spiritFragmentContract.safeTransferFrom(address(msg.sender),address(this),4);// spiritF to this

        emit JoinFarm(msg.sender, farmJoinTotalCount);// set log
        return true;// return result
    }

    // ================= Farm Query  =====================

    function getFarmBasic() public view returns (uint256 DayTime,Invite InviteContract,ERC20 SpiritFragmentContract,ERC20 DtuTokenContract,
      bool FarmSwitchState,uint256 FarmStartTime,uint256 NextFarmYieldTime,uint256 NowDailyReward,uint256 FarmJoinTotalCount,uint256 FarmAccountTotalCount,uint256 UseAgentiaPayAmount)
    {
        return (dayTime,inviteContract,spiritFragmentContract,dtuTokenContract,
          farmSwitchState,farmStartTime,nextFarmYieldTime,nowDailyReward,farmJoinTotalCount,farmAccountTotalCount,useAgentiaPayAmount);
    }

    function farmAccountOf(address _account) public view returns (uint256 JoinTotalCount,uint256 NowProfitAmount,uint256 TotalProfitAmount,uint256 [] memory OrdersIndex){
        FarmAccount storage account =  farmAccounts[_account];
        return (account.joinTotalCount,account.nowProfitAmount,account.totalProfitAmount,account.ordersIndex);
    }

    function farmOrdersOf(uint256 _joinOrderIndex) public view returns (uint256 Index,address Account,uint256 JoinTime,uint256 EndTime,bool IsUseAgentia) {
        FarmOrder storage order =  farmOrders[_joinOrderIndex];
        return (order.index,order.account,order.joinTime,order.endTime,order.isUseAgentia);
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

    function setAddressList(address _inviteContract,address _spiritFragmentContract,address _dtuTokenContract) public onlyOwner returns (bool) {
        inviteContract = Invite(_inviteContract);
        spiritFragmentContract = ERC20(_spiritFragmentContract);
        dtuTokenContract = ERC20(_dtuTokenContract);
        emit AddressList(msg.sender, _inviteContract, _spiritFragmentContract, _dtuTokenContract);
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

    function setUseAgentiaPayAmount(uint256 _useAgentiaPayAmount) public onlyOwner returns (bool) {
        useAgentiaPayAmount = _useAgentiaPayAmount;
        emit SetUseAgentiaPayAmount(msg.sender, _useAgentiaPayAmount);
        return true;
    }

}