pragma solidity 0.5.8;

import { Ownable } from "./Ownable.sol" ;
import "./SafeMath.sol";
import "./SafeERC20.sol";

contract WiKiFarm is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for ERC20;

    // Farm Basic
    uint256 private dayTime;
    bool private oneFarmSwitchState;
    bool private twoFarmSwitchState;
    uint256 private oneFarmStartTime;
    uint256 private twoFarmStartTime;
    address private genesisAddress;
    address private receiveRedeemPayWnftAddress;
    mapping(address => address) private inviterAddress;
    mapping(address => uint256) private inviterJoinTotalCount;
    mapping(address => uint256) private inviterJoinProfit;
    uint256 private inviterJoinRateNo1; // /10000
    uint256 private inviterJoinRateNo2; // /10000
    uint256 private inviterJoinRateNo3; // /10000

    // Contract List
    ERC20 private wnftTokenContract;
    ERC20 private bzzoneTokenContract;
    ERC20 private wikiTokenContract;

    // WiKI Account Farm
    mapping(address => uint256) private oneFarmAccountOrderCount;
    mapping(address => uint256) private twoFarmAccountOrderCount;
    mapping(address => mapping(uint256 => FarmAccountOrder)) public oneFarmAccountOrders;
    mapping(address => mapping(uint256 => FarmAccountOrder)) public twoFarmAccountOrders;
    struct FarmAccountOrder {
        uint256 index;
        address account;
        bool isExist;
        uint256 joinTime;
        uint256 withdrawalTime;
        uint256 exitTime;
        uint256 exitDay;
        uint256 wnftFarmAmount;
        uint256 bzzoneFarmAmount;
        uint256 wikiProfitAmount;
        uint256 exitFarmRedeemPayWnftAmount;
    }
    uint256 private oneFarmNowTotalCount;
    uint256 private twoFarmNowTotalCount;
    uint256 private oneFarmMaxTotalCount = 1000;
    uint256 private twoFarmMaxTotalCount = 1000;
    uint256 private oneFarmNeedWnftAmount = 1 * 10 ** 18;// 1 Wnft;
    uint256 private twoFarmNeedWnftAmount = 1 * 10 ** 18;// 1 Wnft;
    uint256 private oneFarmNeedBzzoneAmount = 2 * 10 ** 18;// 1 Wnft;
    uint256 private twoFarmNeedBzzoneAmount = 12 * 10 ** 18;// 1 Wnft;
    uint256 private oneFarmProfitWikiDayAmount = 25 * 10 ** 17;// 2.5 WiKi
    uint256 private twoFarmProfitWikiDayAmount = 30 * 10 ** 17;// 3 Wiki
    uint256 private nowTotalWikiProfitAmount;
    uint256 private nowTotalExitFarmRedeemPayWnftAmount;

    // Events
    event AddressList(address indexed _account, address _wnftTokenContract,address _bzzoneTokenContract,address _wikiTokenContract,address _genesisAddress,address _receiveRedeemPayWnftAddress);
    event FarmSwitchState(address indexed _account, bool _oneFarmSwitchState,bool _twoFarmSwitchState);
    event InviterJoinRateList(address indexed _account,uint256 _inviterJoinRateNo1,uint256 _inviterJoinRateNo2,uint256 _inviterJoinRateNo3);
    event GetSedimentToken(address indexed _account,address  _erc20TokenContract, address indexed _to, uint256 _amount);
    event BindingInvitation(address indexed _account,address indexed _inviterAddress);
    event JoinFarm(address indexed _account, uint256 _farmId, uint256 _farmNowTotalCount);
    event ExitFarm(address indexed _account, uint256 _farmId, uint256 _orderIndex, uint256 _exitDay, uint256 _farmRedeemPayWnftAmount, uint256 _exitDiff, uint256 _farmWikiProfitAmount);
    event ToInviterProfit(address indexed _account,address _inviterAddress,uint256 _exitFarmId, uint256 _exitOrderIndex, uint256 _exitFarmWikiProfitAmount, uint256 _levelNo, uint256 _rate, uint256 _inviterJoinProfitAmount);// set log
    event WithdrawalFarmYield(address indexed _account, uint256 _farmId, uint256 _orderIndex, uint256 _exitDiff, uint256 _twoFarmWikiProfitAmount);

    // ================= Initial Value ===============

    constructor () public {
          /* dayTime = 86400; */
          dayTime = 60;
          wnftTokenContract = ERC20(0x242529F5D0E253EF0F1DD72Bca9E17F3F602295a);
          bzzoneTokenContract = ERC20(0x99E7d9d8c39DBb99394Fba5cc54DB7bE822BBc30);
          wikiTokenContract = ERC20(0xFC3a5454367a235C7f8b42Fc9381D0AF95B7D71f);
          genesisAddress = address(0xd7128614a9d97aFd0869A61Bd25dDcc6a2D71DEa);
          receiveRedeemPayWnftAddress = address(0xd7128614a9d97aFd0869A61Bd25dDcc6a2D71DEa);
          oneFarmSwitchState = true;
          twoFarmSwitchState = true;
          inviterJoinRateNo1 = 1000;
          inviterJoinRateNo2 = 1000;
          inviterJoinRateNo3 = 2000;// /10000
    }

    // ================= Farm Operation  =================

    function withdrawalFarmYield(uint256 _farmId, uint256 _orderIndex) public returns (bool) {
        // Data validation
        require(_farmId==1||_farmId==2,"-> _farmId: farmId parameter error.");

        if(_farmId==1){
            FarmAccountOrder storage oneFarmOrder =  oneFarmAccountOrders[msg.sender][_orderIndex];
            require(oneFarmOrder.isExist,"-> isExist: Your oneFarmOrder does not exist.");

            uint256 exitDiff = block.timestamp.sub(oneFarmOrder.withdrawalTime);
            uint256 oneFarmWikiProfitAmount = oneFarmProfitWikiDayAmount.div(dayTime).mul(exitDiff);// 1day / dayTime = 1s profit

            // oneFarm withdrawal dispose
            oneFarmAccountOrders[msg.sender][_orderIndex].withdrawalTime += exitDiff;
            oneFarmAccountOrders[msg.sender][_orderIndex].wikiProfitAmount += oneFarmWikiProfitAmount;

            nowTotalWikiProfitAmount += oneFarmWikiProfitAmount;

            // Transfer
            wikiTokenContract.safeTransfer(address(msg.sender), oneFarmWikiProfitAmount);// Transfer wiki to farm address
            emit WithdrawalFarmYield(msg.sender, _farmId, _orderIndex, exitDiff, oneFarmWikiProfitAmount);// set log

            toInviterProfit(msg.sender,_farmId, _orderIndex,oneFarmWikiProfitAmount); // InviterProfit
        }else{
            FarmAccountOrder storage twoFarmOrder =  twoFarmAccountOrders[msg.sender][_orderIndex];
            require(twoFarmOrder.isExist,"-> isExist: Your twoFarmOrder does not exist.");

            uint256 exitDiff = block.timestamp.sub(twoFarmOrder.withdrawalTime);
            uint256 twoFarmWikiProfitAmount = twoFarmProfitWikiDayAmount.div(dayTime).mul(exitDiff);// 1day / dayTime = 1s profit

            // twoFarm withdrawal dispose
            twoFarmAccountOrders[msg.sender][_orderIndex].withdrawalTime += exitDiff;
            twoFarmAccountOrders[msg.sender][_orderIndex].wikiProfitAmount += twoFarmWikiProfitAmount;

            nowTotalWikiProfitAmount += twoFarmWikiProfitAmount;

            // Transfer
            wikiTokenContract.safeTransfer(address(msg.sender), twoFarmWikiProfitAmount);// Transfer wiki to farm address
            emit WithdrawalFarmYield(msg.sender, _farmId, _orderIndex, exitDiff, twoFarmWikiProfitAmount);// set log

            toInviterProfit(msg.sender,_farmId, _orderIndex,twoFarmWikiProfitAmount); // InviterProfit
        }
        return true;// return result
    }

    function toInviterProfit(address _exitAccount,uint256 _exitFarmId, uint256 _exitOrderIndex,uint256 _exitFarmWikiProfitAmount) private returns (bool) {

        // inviterLevelNo1
        address inviterLevelNo1 = inviterAddress[_exitAccount];
        uint256 inviterJoinProfitAmount;
        if(inviterLevelNo1!=address(0)&&inviterJoinTotalCount[inviterLevelNo1]>=1){
            inviterJoinProfitAmount = _exitFarmWikiProfitAmount.mul(inviterJoinRateNo1).div(10000);// no1 => 30%
            inviterJoinProfit[inviterLevelNo1] += inviterJoinProfitAmount;
            wikiTokenContract.safeTransfer(inviterLevelNo1, inviterJoinProfitAmount);// Transfer wiki to inviter address
            emit ToInviterProfit(msg.sender,inviterLevelNo1, _exitFarmId, _exitOrderIndex, _exitFarmWikiProfitAmount, 1, inviterJoinRateNo1,inviterJoinProfitAmount);// set log
        }

        // inviterLevelNo2
        address inviterLevelNo2 = inviterAddress[inviterLevelNo1];
        if(inviterLevelNo2!=address(0)&&inviterJoinTotalCount[inviterLevelNo2]>=3){
            inviterJoinProfitAmount = _exitFarmWikiProfitAmount.mul(inviterJoinRateNo2).div(10000);// no1 => 30%
            inviterJoinProfit[inviterLevelNo2] += inviterJoinProfitAmount;
            wikiTokenContract.safeTransfer(inviterLevelNo2, inviterJoinProfitAmount);// Transfer wiki to inviter address
            emit ToInviterProfit(msg.sender, inviterLevelNo2, _exitFarmId, _exitOrderIndex, _exitFarmWikiProfitAmount, 2, inviterJoinRateNo2,inviterJoinProfitAmount);// set log
        }

        // inviterLevelNo3
        address inviterLevelNo3 = inviterAddress[inviterLevelNo2];
        if(inviterLevelNo3!=address(0)&&inviterJoinTotalCount[inviterLevelNo3]>=5){
            inviterJoinProfitAmount = _exitFarmWikiProfitAmount.mul(inviterJoinRateNo3).div(10000);// no1 => 30%
            inviterJoinProfit[inviterLevelNo3] += inviterJoinProfitAmount;
            wikiTokenContract.safeTransfer(inviterLevelNo3, inviterJoinProfitAmount);// Transfer wiki to inviter address
            emit ToInviterProfit(msg.sender, inviterLevelNo3, _exitFarmId, _exitOrderIndex, _exitFarmWikiProfitAmount, 3, inviterJoinRateNo3,inviterJoinProfitAmount);// set log
        }
        return true;
    }

    function exitFarm(uint256 _farmId, uint256 _orderIndex) public returns (bool) {
        // Data validation
        require(_farmId==1||_farmId==2,"-> _farmId: farmId parameter error.");

        if(_farmId==1){
            FarmAccountOrder storage oneFarmOrder =  oneFarmAccountOrders[msg.sender][_orderIndex];
            require(oneFarmOrder.isExist,"-> isExist: Your oneFarmOrder does not exist.");

            uint256 exitDiff = block.timestamp.sub(oneFarmOrder.withdrawalTime);
            uint256 dayDiff = block.timestamp.sub(oneFarmOrder.joinTime);
            uint256 exitDay = dayDiff.div(dayTime);
            uint256 oneFarmRedeemPayWnftAmount;
            uint256 oneFarmWikiProfitAmount;
            if(exitDay<=30){
                oneFarmRedeemPayWnftAmount = oneFarmOrder.wnftFarmAmount.mul(50).div(100);// <=30   50%
            }else if(exitDay>=31&&exitDay<=60){
                oneFarmRedeemPayWnftAmount = oneFarmOrder.wnftFarmAmount.mul(60).div(100);// 31~60  60%
            }else if(exitDay>=61&&exitDay<=90){
                oneFarmRedeemPayWnftAmount = oneFarmOrder.wnftFarmAmount.mul(70).div(100);// 61~90  70%
            }else if(exitDay>=91&&exitDay<=120){
                oneFarmRedeemPayWnftAmount = oneFarmOrder.wnftFarmAmount.mul(80).div(100);// 91~120  80%
            }else if(exitDay>=120&&exitDay<=150){
                oneFarmRedeemPayWnftAmount = oneFarmOrder.wnftFarmAmount.mul(90).div(100);// 121~150  90%
            }else{
                oneFarmRedeemPayWnftAmount = oneFarmOrder.wnftFarmAmount;    // >=151  100%
            }
            oneFarmWikiProfitAmount = oneFarmProfitWikiDayAmount.div(dayTime).mul(exitDiff);// 1day / dayTime = 1s profit

            // oneFarm Exit dispose
            oneFarmAccountOrders[msg.sender][_orderIndex].isExist = false;
            oneFarmAccountOrders[msg.sender][_orderIndex].exitTime = block.timestamp;
            oneFarmAccountOrders[msg.sender][_orderIndex].withdrawalTime += exitDay;
            oneFarmAccountOrders[msg.sender][_orderIndex].exitDay = exitDay;
            oneFarmAccountOrders[msg.sender][_orderIndex].exitFarmRedeemPayWnftAmount = oneFarmRedeemPayWnftAmount;
            oneFarmAccountOrders[msg.sender][_orderIndex].wikiProfitAmount += oneFarmWikiProfitAmount;

            nowTotalExitFarmRedeemPayWnftAmount += oneFarmRedeemPayWnftAmount;
            nowTotalWikiProfitAmount += oneFarmWikiProfitAmount;

            // Transfer
            wnftTokenContract.safeTransfer(receiveRedeemPayWnftAddress, oneFarmRedeemPayWnftAmount);// Transfer wnft to receiveRedeemPayWnft Address
            wnftTokenContract.safeTransfer(address(msg.sender), oneFarmOrder.wnftFarmAmount.sub(oneFarmRedeemPayWnftAmount));// Transfer wnft to farm address
            bzzoneTokenContract.safeTransfer(address(msg.sender), oneFarmOrder.bzzoneFarmAmount);// Transfer bzzone to farm address
            wikiTokenContract.safeTransfer(address(msg.sender), oneFarmWikiProfitAmount);// Transfer wiki to farm address
            emit ExitFarm(msg.sender, _farmId, _orderIndex, exitDay, oneFarmRedeemPayWnftAmount, exitDiff, oneFarmWikiProfitAmount);// set log

            toInviterProfit(msg.sender,_farmId, _orderIndex,oneFarmWikiProfitAmount); // InviterProfit
        }else{
            FarmAccountOrder storage twoFarmOrder =  twoFarmAccountOrders[msg.sender][_orderIndex];
            require(twoFarmOrder.isExist,"-> isExist: Your twoFarmOrder does not exist.");

            uint256 exitDiff = block.timestamp.sub(twoFarmOrder.withdrawalTime);
            uint256 dayDiff = block.timestamp.sub(twoFarmOrder.joinTime);
            uint256 exitDay = dayDiff.div(dayTime);
            uint256 twoFarmRedeemPayWnftAmount;
            uint256 twoFarmWikiProfitAmount;
            if(exitDay<=30){
                twoFarmRedeemPayWnftAmount = twoFarmOrder.wnftFarmAmount.mul(50).div(100);// <=30   50%
            }else if(exitDay>=31&&exitDay<=60){
                twoFarmRedeemPayWnftAmount = twoFarmOrder.wnftFarmAmount.mul(60).div(100);// 31~60  60%
            }else if(exitDay>=61&&exitDay<=90){
                twoFarmRedeemPayWnftAmount = twoFarmOrder.wnftFarmAmount.mul(70).div(100);// 61~90  70%
            }else if(exitDay>=91&&exitDay<=120){
                twoFarmRedeemPayWnftAmount = twoFarmOrder.wnftFarmAmount.mul(80).div(100);// 91~120  80%
            }else if(exitDay>=120&&exitDay<=150){
                twoFarmRedeemPayWnftAmount = twoFarmOrder.wnftFarmAmount.mul(90).div(100);// 121~150  90%
            }else{
                twoFarmRedeemPayWnftAmount = twoFarmOrder.wnftFarmAmount;    // >=151  100%
            }
            twoFarmWikiProfitAmount = twoFarmProfitWikiDayAmount.div(dayTime).mul(exitDiff);// 1day / dayTime = 1s profit

            // twoFarm Exit dispose
            twoFarmAccountOrders[msg.sender][_orderIndex].isExist = false;
            twoFarmAccountOrders[msg.sender][_orderIndex].exitTime = block.timestamp;
            twoFarmAccountOrders[msg.sender][_orderIndex].withdrawalTime += exitDay;
            twoFarmAccountOrders[msg.sender][_orderIndex].exitDay = exitDay;
            twoFarmAccountOrders[msg.sender][_orderIndex].exitFarmRedeemPayWnftAmount = twoFarmRedeemPayWnftAmount;
            twoFarmAccountOrders[msg.sender][_orderIndex].wikiProfitAmount += twoFarmWikiProfitAmount;

            nowTotalExitFarmRedeemPayWnftAmount += twoFarmRedeemPayWnftAmount;
            nowTotalWikiProfitAmount += twoFarmWikiProfitAmount;

            // Transfer
            wnftTokenContract.safeTransfer(receiveRedeemPayWnftAddress, twoFarmRedeemPayWnftAmount);// Transfer wnft to receiveRedeemPayWnft Address
            wnftTokenContract.safeTransfer(address(msg.sender), twoFarmOrder.wnftFarmAmount.sub(twoFarmRedeemPayWnftAmount));// Transfer wnft to farm address
            bzzoneTokenContract.safeTransfer(address(msg.sender), twoFarmOrder.bzzoneFarmAmount);// Transfer bzzone to farm address
            wikiTokenContract.safeTransfer(address(msg.sender), twoFarmWikiProfitAmount);// Transfer wiki to farm address
            emit ExitFarm(msg.sender, _farmId, _orderIndex, exitDay, twoFarmRedeemPayWnftAmount, exitDiff, twoFarmWikiProfitAmount);// set log

            toInviterProfit(msg.sender,_farmId, _orderIndex,twoFarmWikiProfitAmount); // InviterProfit
        }
        return true;// return result
    }

    function joinFarm(uint256 _farmId, address _inviterAddress) public returns (bool) {
        // Data validation
        require(_farmId==1||_farmId==2,"-> _farmId: farmId parameter error.");
        require(msg.sender!=genesisAddress,"-> genesisAddress: Genesis address cannot participate in mining.");

        if(_farmId==1){
            require(oneFarmSwitchState,"-> oneFarmSwitchState: oneFarm has not started yet.");
            require(oneFarmNowTotalCount<oneFarmMaxTotalCount,"-> oneFarmMaxTotalCount: The current pool has reached the maximum number of participants.");
            require(wnftTokenContract.balanceOf(msg.sender)>=oneFarmNeedWnftAmount,"-> oneFarmNeedWnftAmount: Insufficient address wnft balance.");
            require(bzzoneTokenContract.balanceOf(msg.sender)>=oneFarmNeedBzzoneAmount,"-> oneFarmNeedBzzoneAmount: Insufficient address bzzone balance.");
        }else{
            require(twoFarmSwitchState,"-> twoFarmSwitchState: twoFarm has not started yet.");
            require(twoFarmNowTotalCount<twoFarmMaxTotalCount,"-> twoFarmMaxTotalCount: The current pool has reached the maximum number of participants.");
            require(wnftTokenContract.balanceOf(msg.sender)>=twoFarmNeedWnftAmount,"-> twoFarmNeedWnftAmount: Insufficient address wnft balance.");
            require(bzzoneTokenContract.balanceOf(msg.sender)>=twoFarmNeedBzzoneAmount,"-> twoFarmNeedBzzoneAmount: Insufficient address bzzone balance.");
        }

        require(msg.sender!=_inviterAddress,"-> _inviterAddress: The inviter cannot be oneself.");
        if(inviterAddress[msg.sender]==address(0)){
            if(_inviterAddress!=genesisAddress){
                require(oneFarmAccountOrderCount[_inviterAddress]>=1||twoFarmAccountOrderCount[_inviterAddress]>=1,"-> _inviterAddress: The invitee has not participated in the farm yet.");
            }
            inviterAddress[msg.sender]  = _inviterAddress;// Write inviterAddress
            inviterJoinTotalCount[_inviterAddress] += 1;// inviter Count +1
            emit BindingInvitation(msg.sender, _inviterAddress);// set log
        }

        // Orders dispose
        if(_farmId==1){
            oneFarmNowTotalCount += 1;// total number + 1
            oneFarmAccountOrderCount[msg.sender] += 1;// add account orders
            oneFarmAccountOrders[msg.sender][oneFarmAccountOrderCount[msg.sender]] = FarmAccountOrder(oneFarmAccountOrderCount[msg.sender],msg.sender,true,block.timestamp,block.timestamp,0,0,oneFarmNeedWnftAmount,oneFarmNeedBzzoneAmount,0,0);// add FarmAccountOrder

            wnftTokenContract.safeTransferFrom(address(msg.sender),address(this),oneFarmNeedWnftAmount);// wnft to this
            bzzoneTokenContract.safeTransferFrom(address(msg.sender),address(this),oneFarmNeedBzzoneAmount);// bzzone to this

            emit JoinFarm(msg.sender, _farmId, oneFarmNowTotalCount);// set log
        }else{
            twoFarmNowTotalCount += 1;// total number + 1
            twoFarmAccountOrderCount[msg.sender] += 1;// add account orders
            twoFarmAccountOrders[msg.sender][twoFarmAccountOrderCount[msg.sender]] = FarmAccountOrder(twoFarmAccountOrderCount[msg.sender],msg.sender,true,block.timestamp,block.timestamp,0,0,twoFarmNeedWnftAmount,twoFarmNeedBzzoneAmount,0,0);// add FarmAccountOrder

            wnftTokenContract.safeTransferFrom(address(msg.sender),address(this),twoFarmNeedWnftAmount);// wnft to this
            bzzoneTokenContract.safeTransferFrom(address(msg.sender),address(this),twoFarmNeedBzzoneAmount);// bzzone to this

            emit JoinFarm(msg.sender, _farmId, twoFarmNowTotalCount);// set log
        }
        return true;// return result
    }

    // ================= Farm Query  =====================

    function getInviterAddress(address _farmAddress) public view returns (address) {
        return inviterAddress[_farmAddress];
    }

    function getInviterJoinRateList() public view returns (uint256 InviterJoinRateNo1,uint256 InviterJoinRateNo2,uint256 InviterJoinRateNo3) {
        return (inviterJoinRateNo1,inviterJoinRateNo2,inviterJoinRateNo3);
    }

    function getAccountInviterJoinInfo(address _farmAddress) public view returns (uint256 InviterJoinTotalCount,uint256 InviterJoinProfit) {
        return (inviterJoinTotalCount[_farmAddress],inviterJoinProfit[_farmAddress]);
    }

    function getFarmAccountOrderCount(address _farmAddress) public view returns (uint256 OneFarmAccountOrderCount,uint256 TwoFarmAccountOrderCount) {
        return (oneFarmAccountOrderCount[_farmAddress],twoFarmAccountOrderCount[_farmAddress]);
    }

    function getFarmBasic() public view returns (address GenesisAddressOf,address ReceiveRedeemPayWnftAddressOf,ERC20 WnftTokenContract,ERC20 BzzoneTokenContract,ERC20 WikiTokenContract,
      bool OneFarmSwitchState,bool TwoFarmSwitchState,uint256 OneFarmStartTime,uint256 TwoFarmStartTime) {
        return (genesisAddress,receiveRedeemPayWnftAddress,wnftTokenContract,bzzoneTokenContract,wikiTokenContract,oneFarmSwitchState,twoFarmSwitchState,oneFarmStartTime,twoFarmStartTime);
    }

    function getFarmAmountInfo() public view returns (
        uint256 OneFarmNowTotalCount,uint256 OneFarmMaxTotalCount,uint256 OneFarmNeedWnftAmount,uint256 OneFarmNeedBzzoneAmount,uint256 OneFarmProfitWikiDayAmount,
        uint256 TwoFarmNowTotalCount,uint256 TwoFarmMaxTotalCount,uint256 TwoFarmNeedWnftAmount,uint256 TwoFarmNeedBzzoneAmount,uint256 TwoFarmProfitWikiDayAmount,
        uint256 NowTotalWikiProfitAmount,uint256 NowTotalExitFarmRedeemPayWnftAmount)
    {
        return (oneFarmNowTotalCount,oneFarmMaxTotalCount,oneFarmNeedWnftAmount,oneFarmNeedBzzoneAmount,oneFarmProfitWikiDayAmount,
          twoFarmNowTotalCount,twoFarmMaxTotalCount,twoFarmNeedWnftAmount,twoFarmNeedBzzoneAmount,twoFarmProfitWikiDayAmount,
          nowTotalWikiProfitAmount,nowTotalExitFarmRedeemPayWnftAmount);
    }

    function farmRedeemPayWnftAmountOf(address _account, uint256 _farmId, uint256 _orderIndex) public view returns (uint256) {
        require(_farmId==1||_farmId==2,"-> _farmId: farmId parameter error.");
        if(_farmId==1){
            FarmAccountOrder storage oneFarmOrder =  oneFarmAccountOrders[_account][_orderIndex];
            require(oneFarmOrder.isExist,"-> isExist: Your oneFarmOrder does not exist.");

            uint256 exitDiff = block.timestamp.sub(oneFarmOrder.joinTime);
            uint256 exitDay = exitDiff.div(dayTime);
            uint256 oneFarmRedeemPayWnftAmount;
            if(exitDay<=30){
                oneFarmRedeemPayWnftAmount = oneFarmOrder.wnftFarmAmount.mul(50).div(100);// <=30   50%
            }else if(exitDay>=31&&exitDay<=60){
                oneFarmRedeemPayWnftAmount = oneFarmOrder.wnftFarmAmount.mul(60).div(100);// 31~60  60%
            }else if(exitDay>=61&&exitDay<=90){
                oneFarmRedeemPayWnftAmount = oneFarmOrder.wnftFarmAmount.mul(70).div(100);// 61~90  70%
            }else if(exitDay>=91&&exitDay<=120){
                oneFarmRedeemPayWnftAmount = oneFarmOrder.wnftFarmAmount.mul(80).div(100);// 91~120  80%
            }else if(exitDay>=120&&exitDay<=150){
                oneFarmRedeemPayWnftAmount = oneFarmOrder.wnftFarmAmount.mul(90).div(100);// 121~150  90%
            }else{
                oneFarmRedeemPayWnftAmount = oneFarmOrder.wnftFarmAmount;    // >=151  100%
            }
            return oneFarmRedeemPayWnftAmount;
        }else{
            FarmAccountOrder storage twoFarmOrder =  twoFarmAccountOrders[_account][_orderIndex];
            require(twoFarmOrder.isExist,"-> isExist: Your twoFarmOrder does not exist.");

            uint256 exitDiff = block.timestamp.sub(twoFarmOrder.joinTime);
            uint256 exitDay = exitDiff.div(dayTime);
            uint256 twoFarmRedeemPayWnftAmount;
            if(exitDay<=30){
                twoFarmRedeemPayWnftAmount = twoFarmOrder.wnftFarmAmount.mul(50).div(100);// <=30   50%
            }else if(exitDay>=31&&exitDay<=60){
                twoFarmRedeemPayWnftAmount = twoFarmOrder.wnftFarmAmount.mul(60).div(100);// 31~60  60%
            }else if(exitDay>=61&&exitDay<=90){
                twoFarmRedeemPayWnftAmount = twoFarmOrder.wnftFarmAmount.mul(70).div(100);// 61~90  70%
            }else if(exitDay>=91&&exitDay<=120){
                twoFarmRedeemPayWnftAmount = twoFarmOrder.wnftFarmAmount.mul(80).div(100);// 91~120  80%
            }else if(exitDay>=120&&exitDay<=150){
                twoFarmRedeemPayWnftAmount = twoFarmOrder.wnftFarmAmount.mul(90).div(100);// 121~150  90%
            }else{
                twoFarmRedeemPayWnftAmount = twoFarmOrder.wnftFarmAmount;    // >=151  100%
            }
            return twoFarmRedeemPayWnftAmount;
        }
    }

    function farmWikiProfitAmountOf(address _account, uint256 _farmId, uint256 _orderIndex) public view returns (uint256) {
        require(_farmId==1||_farmId==2,"-> _farmId: farmId parameter error.");
        if(_farmId==1){
            FarmAccountOrder storage oneFarmOrder =  oneFarmAccountOrders[_account][_orderIndex];
            require(oneFarmOrder.isExist,"-> isExist: Your oneFarmOrder does not exist.");

            uint256 exitDiff = block.timestamp.sub(oneFarmOrder.withdrawalTime);
            return oneFarmProfitWikiDayAmount.div(dayTime).mul(exitDiff);// 1day / dayTime = 1s profit
        }else{
            FarmAccountOrder storage twoFarmOrder =  twoFarmAccountOrders[_account][_orderIndex];
            require(twoFarmOrder.isExist,"-> isExist: Your twoFarmOrder does not exist.");

            uint256 exitDiff = block.timestamp.sub(twoFarmOrder.withdrawalTime);
            return twoFarmProfitWikiDayAmount.div(dayTime).mul(exitDiff);// 1day / dayTime = 1s profit
        }
    }

    // ================= Owner Operation  =================

    function getSedimentToken(address _erc20TokenContract, address _to, uint256 _amount) public onlyOwner returns (bool) {
        require(ERC20(_erc20TokenContract).balanceOf(address(this))>=_amount,"_amount: The current token balance of the contract is insufficient.");
        ERC20(_erc20TokenContract).safeTransfer(_to, _amount);// Transfer wiki to destination address
        emit GetSedimentToken(msg.sender, _erc20TokenContract, _to, _amount);// set log
        return true;// return result
    }

    // ================= Initial Operation  =====================

    function setAddressList(address _wnftTokenContract,address _bzzoneTokenContract,address _wikiTokenContract,
      address _genesisAddress,address _receiveRedeemPayWnftAddress) public onlyOwner returns (bool) {
        wnftTokenContract = ERC20(_wnftTokenContract);
        bzzoneTokenContract = ERC20(_bzzoneTokenContract);
        wikiTokenContract = ERC20(_wikiTokenContract);
        genesisAddress = _genesisAddress;
        receiveRedeemPayWnftAddress = _receiveRedeemPayWnftAddress;
        emit AddressList(msg.sender, _wnftTokenContract, _bzzoneTokenContract, _wikiTokenContract, _genesisAddress, _receiveRedeemPayWnftAddress);
        return true;
    }

    function setFarmSwitchState(bool _oneFarmSwitchState,bool _twoFarmSwitchState) public onlyOwner returns (bool) {
        oneFarmSwitchState = _oneFarmSwitchState;
        twoFarmSwitchState = _twoFarmSwitchState;
        if(oneFarmStartTime==0&&oneFarmSwitchState){
              oneFarmStartTime = block.timestamp;// update oneFarmStartTime
        }
        if(twoFarmStartTime==0&&twoFarmSwitchState){
              twoFarmStartTime = block.timestamp;// update twoFarmStartTime
        }
        emit FarmSwitchState(msg.sender, _oneFarmSwitchState, _twoFarmSwitchState);
        return true;
    }

    function setInviterJoinRateList(uint256 _inviterJoinRateNo1,uint256 _inviterJoinRateNo2,uint256 _inviterJoinRateNo3) public onlyOwner returns (bool) {
        inviterJoinRateNo1 = _inviterJoinRateNo1;
        inviterJoinRateNo2 = _inviterJoinRateNo2;
        inviterJoinRateNo3 = _inviterJoinRateNo3;
        emit InviterJoinRateList(msg.sender, _inviterJoinRateNo1,_inviterJoinRateNo2,_inviterJoinRateNo3);
        return true;
    }

}