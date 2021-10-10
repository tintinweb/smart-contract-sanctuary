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
    uint256 private farmEndTime;
    uint256 private nextFarmYieldTime;
    uint256 private nowDailyReward;
    uint256 private farmJoinTotalCount;
    uint256 private farmNowTotalCount;
    uint256 private farmNowTotalAmount;

    // Address List
    Invite private inviteContract;
    ERC20 private lpTokenContract;
    ERC20 private dtuTokenContract;
    address private unionPoolAddress;// 3%
    address private developmentFundAddress;// 2%

    // Account Info
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
        uint256 joinAmount;
    }

    // Events
    event SedimentToken(address indexed _account,address  _erc20TokenContract, address _to, uint256 _amount);
    event AddressList(address indexed _account, address _inviteContract, address _lpTokenContract, address _dtuTokenContract, address _unionPoolAddress, address _developmentFundAddress);
    event SwitchState(address indexed _account, bool _farmSwitchState);
    event JoinFarm(address indexed _account, uint256 _farmJoinTotalCount);
    event ExitFarm(address indexed _account, uint256 _orderIndex);
    event WithdrawalFarmYield(address indexed _account, uint256 _nowProfitAmount);
    event FarmYield(address indexed _account, uint256 _addEra, uint256 _dailyReward, uint256 _farmNowTotalCount);

    // ================= Initial Value ===============

    constructor () public {
          /* dayTime = 86400; */
          dayTime = 1800;
          farmSwitchState = false;
          nowDailyReward = 53520 * 10 ** 18;// 53520 Reward
          inviteContract = Invite(0xe37495a91A7985e1afcdDcFd56c1FC848B510649);
          lpTokenContract = ERC20(0x72783C370f41117822de2A214C42Fe39fdFAD748);
          dtuTokenContract = ERC20(0xe3dfa273B6F964BAB41A10C204226eB66aBE3684);
          unionPoolAddress = address(0x13e4A8ddB241AF74846f341dE2A506fdc6646748);
          developmentFundAddress = address(0x4952cE6E663a19eB58109f65419ED09aeE904b0B);
    }

    // ================= Farm Operation  =================

    /* function toFarmYield() public returns (bool) {
        // Data validation
        require(farmSwitchState,"-> farmSwitchState: farm has not started yet.");
        require(block.timestamp<farmEndTime.add(dayTime),"-> farmEndTime: The mining cycle is over.");
        require(block.timestamp>=nextFarmYieldTime,"-> nextFarmYieldTime: The start time has not been reached.");

        // Yield dispose
        uint256 secondDiff = block.timestamp.sub(farmStartTime);
        uint256 addEra = secondDiff.div(dayTime.mul(30));// changeReward * addEra
        uint256 dailyReward = nowDailyReward.add(changeReward.mul(addEra));
        uint256 profitAmount;
        for(uint256 i=1;i<=farmJoinTotalCount;i++){
            if(farmOrders[i].isExist){
                profitAmount = dailyReward.mul(farmOrders[i].farmNeedWikiAmount).div(farmNowTotalAmountWiki);
                farmAccountProfit[farmOrders[i].account].nowProfitAmount += profitAmount;// update farmAccountProfit
                farmOrders[i].profitAmount += profitAmount;
            }
        }
        nextFarmYieldTime += dayTime;// update nextFarmYieldTime

        emit FarmYield(msg.sender,addEra,dailyReward,farmNowTotalCount);// set log
        return true;// return result
    }

    function withdrawalFarmYield() public returns (bool) {
        // Data validation
        uint256 nowProfitAmount = farmAccountProfit[msg.sender].nowProfitAmount;
        require(nowProfitAmount>0,"-> nowProfitAmount: Your current withdrawable income is 0.");

        // Withdrawal dispose
        farmAccountProfit[msg.sender].nowProfitAmount = 0;
        farmAccountProfit[msg.sender].totalProfitAmount += nowProfitAmount;// update farmAccountProfit

        // Transfer
        wikiTokenContract.safeTransfer(address(msg.sender), nowProfitAmount);// Transfer wiki to farm address

        emit WithdrawalFarmYield(msg.sender, nowProfitAmount);// set log
        return true;// return result
    }

    function exitFarm(uint256 _orderIndex) public returns (bool) {
        // Data validation
        FarmOrder storage order =  farmOrders[_orderIndex];
        require(order.isExist,"-> isExist: Your FarmOrder does not exist.");
        require(order.account==msg.sender,"-> account: This order is not yours.");

        // Orders dispose
        farmNowTotalCount -= 1;// now number -1
        farmNowTotalAmountWiki -= order.farmNeedWikiAmount;

        farmOrders[_orderIndex].isExist = false;
        farmOrders[_orderIndex].exitTime = block.timestamp;// update farmOrders

        // Transfer
        pangolinTokenContract.safeTransfer(address(msg.sender), order.farmNeedPangolinAmount);// Transfer pangolin to farm address
        bzzoneTokenContract.safeTransfer(address(msg.sender), order.farmNeedBzzoneAmount);// Transfer bzzone to farm address
        wikiTokenContract.safeTransfer(address(msg.sender), order.farmNeedWikiAmount);// Transfer wiki to farm address

        emit ExitFarm(msg.sender, _orderIndex);// set log
        return true;// return result
    }

    function joinFarm(uint256 _farmNeedWikiAmount) public returns (bool) {
        // Data validation
        require(farmSwitchState,"-> farmSwitchState: farm has not started yet.");
        uint256 farmNeedPangolinAmount = _farmNeedWikiAmount.mul(50);
        uint256 farmNeedBzzoneAmount = _farmNeedWikiAmount.mul(10);
        require(pangolinTokenContract.balanceOf(msg.sender)>=farmNeedPangolinAmount,"-> farmNeedPangolinAmount: Insufficient address pangolin balance.");
        require(bzzoneTokenContract.balanceOf(msg.sender)>=farmNeedBzzoneAmount,"-> farmNeedBzzoneAmount: Insufficient address bzzone balance.");
        require(wikiTokenContract.balanceOf(msg.sender)>=_farmNeedWikiAmount,"-> farmNeedWikiAmount: Insufficient address wiki balance.");

        // Orders dispose
        farmJoinTotalCount += 1;// total number + 1
        farmNowTotalCount += 1;// now number +1
        farmNowTotalAmountWiki += _farmNeedWikiAmount;

        farmOrders[farmJoinTotalCount] = FarmOrder(farmJoinTotalCount,msg.sender,true,block.timestamp,0,0,farmNeedPangolinAmount,farmNeedBzzoneAmount,_farmNeedWikiAmount);// add farmOrders
        farmAccountProfit[msg.sender].joinTotalCount += 1;
        farmAccountProfit[msg.sender].ordersIndex.push(farmJoinTotalCount);// add farmAccountProfit

        // Transfer
        pangolinTokenContract.safeTransferFrom(address(msg.sender),address(this),farmNeedPangolinAmount);// pangolin to this
        bzzoneTokenContract.safeTransferFrom(address(msg.sender),address(this),farmNeedBzzoneAmount);// bzzone to this
        wikiTokenContract.safeTransferFrom(address(msg.sender),address(this),_farmNeedWikiAmount);// wiki to this

        emit JoinFarm(msg.sender, farmJoinTotalCount);// set log
        return true;// return result
    } */

    // ================= Farm Query  =====================

    function getFarmBasic() public view returns (Invite InviteContract,ERC20 LpTokenContract,ERC20 DtuTokenContract,address UnionPoolAddress,address DevelopmentFundAddress,
      uint256 DayTime,bool FarmSwitchState,uint256 FarmStartTime,uint256 FarmEndTime,uint256 NextFarmYieldTime,uint256 NowDailyReward,uint256 FarmJoinTotalCount,uint256 FarmNowTotalCount,uint256 FarmNowTotalAmount)
    {
        return (inviteContract,lpTokenContract,dtuTokenContract,unionPoolAddress,developmentFundAddress,
          dayTime,farmSwitchState,farmStartTime,farmEndTime,nextFarmYieldTime,nowDailyReward,farmJoinTotalCount,farmNowTotalCount,farmNowTotalAmount);
    }

    function farmAccountProfitOf(address _account) public view returns (uint256 JoinTotalCount,uint256 NowProfitAmount,uint256 TotalProfitAmount,uint256 [] memory OrdersIndex){
        FarmAccount storage account =  farmAccounts[_account];
        return(account.joinTotalCount,account.nowProfitAmount,account.totalProfitAmount,account.ordersIndex);
    }

    function farmOrdersOf(uint256 _joinOrderIndex) public view returns (uint256 Index,address Account,uint256 JoinTime,uint256 JoinAmount){
        FarmOrder storage order =  farmOrders[_joinOrderIndex];
        return(order.index,order.account,order.joinTime,order.joinAmount);
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
              farmEndTime = farmStartTime.add(dayTime.mul(3600));// set farmEndTime
              nextFarmYieldTime = farmStartTime.add(dayTime);// set nextFarmYieldTime
        }
        emit SwitchState(msg.sender, _farmSwitchState);
        return true;
    }
}