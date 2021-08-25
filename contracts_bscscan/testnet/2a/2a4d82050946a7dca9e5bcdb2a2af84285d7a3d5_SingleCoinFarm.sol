pragma solidity 0.5.8;

import { Ownable } from "./Ownable.sol" ;
import "./SafeMath.sol";
import "./SafeERC20.sol";

contract SingleCoinFarm is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for ERC20;

    // Farm Basic
    bool private farmSwitchState;
    uint256 private dayTime;
    uint256 private farmStartTime;
    uint256 private farmEndTime;
    uint256 private nextFarmYieldTime;
    uint256 private farmNeedPangolinAmount;
    uint256 private farmNeedBzzoneAmount;
    uint256 private farmNeedWikiAmount;
    uint256 private nowDailyReward;
    uint256 private changeReward;
    uint256 private farmJoinTotalCount;
    uint256 private farmNowTotalCount;

    // Contract List
    ERC20 private pangolinTokenContract;
    ERC20 private bzzoneTokenContract;
    ERC20 private wikiTokenContract;

    // Account Info
    mapping(address => FarmAccountProfit) private farmAccountProfit;
    struct FarmAccountProfit {
        uint256 joinTotalCount;
        uint256 nowProfitAmount;
        uint256 totalProfitAmount;
        uint256 [] ordersIndex;
    }
    mapping(uint256 => FarmOrder) private farmOrders;
    struct FarmOrder {
        uint256 index;
        address account;
        bool isExist;
        uint256 joinTime;
        uint256 exitTime;
        uint256 profitAmount;
    }

    // Events
    event SedimentToken(address indexed _account,address  _erc20TokenContract, address indexed _to, uint256 _amount);
    event AddressList(address indexed _account, address _pangolinTokenContract,address _bzzoneTokenContract,address _wikiTokenContract);
    event SwitchState(address indexed _account, bool _farmSwitchState);
    event JoinFarm(address indexed _account, uint256 _farmJoinTotalCount);
    event ExitFarm(address indexed _account, uint256 _orderIndex);
    event WithdrawalFarmYield(address indexed _account, uint256 _nowProfitAmount);
    event FarmYield(address indexed _account, uint256 _addEra, uint256 _dailyReward, uint256 _farmNowTotalCount, uint256 _profitAmount);

    // ================= Initial Value ===============

    constructor () public {
          /* dayTime = 86400; */
          dayTime = 60;
          farmSwitchState = true;
          farmNeedPangolinAmount =  50 * 10 ** 18;// 50 Pangolin;
          farmNeedBzzoneAmount =  1 * 10 ** 18;// 10 Bzzone;
          farmNeedWikiAmount =  10 * 10 ** 18;// 50 Wiki;
          nowDailyReward = 50 * 10 ** 18;// 100 Reward
          changeReward = 50 * 10 ** 18;// 100 Change add
          pangolinTokenContract = ERC20(0x5b8bf8d2EF9A00DB34c148Cd8534bac513Ec1793);
          bzzoneTokenContract = ERC20(0x99E7d9d8c39DBb99394Fba5cc54DB7bE822BBc30);
          wikiTokenContract = ERC20(0xFC3a5454367a235C7f8b42Fc9381D0AF95B7D71f);
    }

    // ================= Farm Operation  =================

    function toFarmYield() public returns (bool) {
        // Data validation
        require(farmSwitchState,"-> farmSwitchState: farm has not started yet.");
        require(block.timestamp<farmEndTime.add(dayTime),"-> farmEndTime: The mining cycle is over.");
        require(block.timestamp>=nextFarmYieldTime,"-> nextFarmYieldTime: The start time has not been reached.");

        // Yield dispose
        uint256 secondDiff = block.timestamp.sub(farmStartTime);
        uint256 addEra = secondDiff.div(dayTime.mul(30));// changeReward * addEra
        uint256 dailyReward = nowDailyReward.add(changeReward.mul(addEra));
        uint256 profitAmount = dailyReward.div(farmNowTotalCount);
        for(uint256 i=1;i<=farmJoinTotalCount;i++){
            if(farmOrders[i].isExist){
                farmAccountProfit[farmOrders[i].account].nowProfitAmount += profitAmount;// update farmAccountProfit
                farmOrders[i].profitAmount += profitAmount;
            }
        }
        nextFarmYieldTime += dayTime;// update nextFarmYieldTime

        emit FarmYield(msg.sender,addEra,dailyReward,farmNowTotalCount,profitAmount);// set log
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
        bzzoneTokenContract.safeTransfer(address(msg.sender), nowProfitAmount);// Transfer bzzone to farm address

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

        farmOrders[_orderIndex].isExist = false;
        farmOrders[_orderIndex].exitTime = block.timestamp;// update farmOrders

        // Transfer
        pangolinTokenContract.safeTransfer(address(msg.sender), farmNeedPangolinAmount);// Transfer pangolin to farm address
        bzzoneTokenContract.safeTransfer(address(msg.sender), farmNeedBzzoneAmount);// Transfer bzzone to farm address
        wikiTokenContract.safeTransfer(address(msg.sender), farmNeedWikiAmount);// Transfer wiki to farm address

        emit ExitFarm(msg.sender, _orderIndex);// set log
        return true;// return result
    }

    function joinFarm() public returns (bool) {
        // Data validation
        require(farmSwitchState,"-> farmSwitchState: farm has not started yet.");
        require(pangolinTokenContract.balanceOf(msg.sender)>=farmNeedPangolinAmount,"-> farmNeedPangolinAmount: Insufficient address pangolin balance.");
        require(bzzoneTokenContract.balanceOf(msg.sender)>=farmNeedBzzoneAmount,"-> farmNeedBzzoneAmount: Insufficient address bzzone balance.");
        require(wikiTokenContract.balanceOf(msg.sender)>=farmNeedWikiAmount,"-> farmNeedWikiAmount: Insufficient address wiki balance.");

        // Orders dispose
        farmJoinTotalCount += 1;// total number + 1
        farmNowTotalCount += 1;// now number +1

        farmOrders[farmJoinTotalCount] = FarmOrder(farmJoinTotalCount,msg.sender,true,block.timestamp,0,0);// add farmOrders
        farmAccountProfit[msg.sender].joinTotalCount += 1;
        farmAccountProfit[msg.sender].ordersIndex.push(farmJoinTotalCount);// add farmAccountProfit

        // Transfer
        pangolinTokenContract.safeTransferFrom(address(msg.sender),address(this),farmNeedPangolinAmount);// pangolin to this
        bzzoneTokenContract.safeTransferFrom(address(msg.sender),address(this),farmNeedBzzoneAmount);// bzzone to this
        wikiTokenContract.safeTransferFrom(address(msg.sender),address(this),farmNeedWikiAmount);// wiki to this

        emit JoinFarm(msg.sender, farmJoinTotalCount);// set log
        return true;// return result
    }

    // ================= Farm Query  =====================

    function getFarmBasic() public view returns (
      bool FarmSwitchState,uint256 FarmStartTime,uint256 FarmEndTime,uint256 NextFarmYieldTime,ERC20 PangolinTokenContract,ERC20 BzzoneTokenContract,ERC20 WikiTokenContract,
      uint256 FarmNeedPangolinAmount,uint256 FarmNeedBzzoneAmount,uint256 FarmNeedWikiAmount,uint256 NowDailyReward,uint256 FarmJoinTotalCount,uint256 FarmNowTotalCount)
    {
        return (farmSwitchState,farmStartTime,farmEndTime,nextFarmYieldTime,pangolinTokenContract,bzzoneTokenContract,wikiTokenContract,
          farmNeedPangolinAmount,farmNeedBzzoneAmount,farmNeedWikiAmount,nowDailyReward,farmJoinTotalCount,farmNowTotalCount);
    }

    function farmAccountProfitOf(address _account) public view returns (uint256 JoinTotalCount,uint256 NowProfitAmount,uint256 TotalProfitAmount,uint256 [] memory OrdersIndex){
        FarmAccountProfit storage profit =  farmAccountProfit[_account];
        return(profit.joinTotalCount,profit.nowProfitAmount,profit.totalProfitAmount,profit.ordersIndex);
    }

    function farmOrdersOf(uint256 _joinOrderIndex) public view returns (uint256 Index,address Account,bool IsExist,uint256 JoinTime,uint256 ExitTime,uint256 ProfitAmount){
        FarmOrder storage order =  farmOrders[_joinOrderIndex];
        return(order.index,order.account,order.isExist,order.joinTime,order.exitTime,order.profitAmount);
    }

    // ================= Owner Operation  =================

    function getSedimentToken(address _erc20TokenContract, address _to, uint256 _amount) public onlyOwner returns (bool) {
        require(ERC20(_erc20TokenContract).balanceOf(address(this))>=_amount,"_amount: The current token balance of the contract is insufficient.");
        ERC20(_erc20TokenContract).safeTransfer(_to, _amount);// Transfer wiki to destination address
        emit SedimentToken(msg.sender, _erc20TokenContract, _to, _amount);// set log
        return true;// return result
    }

    // ================= Initial Operation  =====================

    function setAddressList(address _pangolinTokenContract,address _bzzoneTokenContract,address _wikiTokenContract) public onlyOwner returns (bool) {
        pangolinTokenContract = ERC20(_pangolinTokenContract);
        bzzoneTokenContract = ERC20(_bzzoneTokenContract);
        wikiTokenContract = ERC20(_wikiTokenContract);
        emit AddressList(msg.sender, _pangolinTokenContract, _bzzoneTokenContract, _wikiTokenContract);
        return true;
    }

    function setFarmSwitchState(bool _farmSwitchState) public onlyOwner returns (bool) {
        farmSwitchState = _farmSwitchState;
        if(farmStartTime==0){
              farmStartTime = block.timestamp;// set farmStartTime
              farmEndTime = farmStartTime.add(dayTime.mul(360));// set farmEndTime
              nextFarmYieldTime = farmStartTime.add(dayTime);// set nextFarmYieldTime
        }
        emit SwitchState(msg.sender, _farmSwitchState);
        return true;
    }
}