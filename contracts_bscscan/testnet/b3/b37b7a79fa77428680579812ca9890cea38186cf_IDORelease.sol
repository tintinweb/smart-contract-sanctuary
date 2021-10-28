pragma solidity 0.5.8;

import { Ownable } from "./Ownable.sol" ;
import "./SafeMath.sol";
import "./SafeERC20.sol";

contract IDORelease is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for ERC20;

    // Swap Basis
    uint256 private dayTime;
    ERC20 private dtuTokenContract;
    bool private releaseSwitchState;
    uint256 private releaseStartTime;
    uint256 private nowSwapJoinTotalCount;
    uint256 private nowReleaseJoinTotalCount;

    // Account
    mapping(address => SwapAccount) private swapAccounts;
    struct SwapAccount {
        uint256 totalSwapDtuAmount;
        uint256 [] swapOrdersIndex;
        uint256 [] releaseOrdersIndex;
    }

    mapping(uint256 => SwapOrder) private swapOrders;
    struct SwapOrder {
        uint256 index;
        address account;
        uint256 swapDtuAmount;
        bool isRelease;
        uint256 lastReleaseTime;
        uint256 lastDayNum;
    }

    // Release
    mapping(uint256 => ReleaseOrder) private releaseOrders;
    struct ReleaseOrder {
        uint256 index;
        address account;
        uint256 releaseTime;
        uint256 releaseAmount;
        uint256 dayRelease;
    }

    // Events
    event SedimentToken(address indexed _account,address  _erc20TokenContract, address _to, uint256 _amount);
    event AddressList(address indexed _account, address _dtuTokenContract);
    event SwitchState(address indexed _account, bool _releaseSwitchState);
    event JoinSwap(address indexed _account, address _joinAddress, uint256 _nowSwapJoinTotalCount, uint256 _swapDtuAmount);
    event Release(address indexed _account, uint256 _nowReleaseJoinTotalCount, uint256 _dayRelease, uint256 _nowDayNum, uint256 _swapDtuAmount, uint256 _releaseAmount);

    // ================= Initial Value ===============

    constructor () public {
          /* dayTime = 86400; */
          dayTime = 60;
          dtuTokenContract = ERC20(0x6f269df887c70536F895F7dFee415F78969Df7DB);
          releaseSwitchState = false;
    }

    // ================= Swap Operation  =====================

    function isTodayReleaseOf(uint256 _orderIndex) public view returns (bool IsTodayRelease) {
        // Data validation
        SwapOrder storage order =  swapOrders[_orderIndex];
        if(!releaseSwitchState){
            return false;
        }

        // Order dispose
        uint256 diffTime = block.timestamp.sub(releaseStartTime);
        uint256 dayRelease = diffTime.div(dayTime).add(1);
        if(dayRelease>180){
            dayRelease = 180;// MAX 180
        }
        uint256 nowDayNum = dayRelease.sub(order.lastDayNum);
        if(nowDayNum>=1){
            return true;
        }else{
            return false;
        }
    }

    function release(uint256 _orderIndex) public returns (bool) {
        // Data validation
        SwapOrder storage order =  swapOrders[_orderIndex];
        require(releaseSwitchState,"-> releaseSwitchState: release has not started yet.");
        require(!order.isRelease,"isRelease: Your deposit order does not in Release.");
        require(order.account==msg.sender,"account: not account.");

        // Order dispose
        uint256 diffTime = block.timestamp.sub(releaseStartTime);
        uint256 dayRelease = diffTime.div(dayTime).add(1);
        if(dayRelease>180){
            dayRelease = 180;// MAX 180
        }
        uint256 nowDayNum = dayRelease.sub(order.lastDayNum);
        require(nowDayNum>=1,"-> nowDayNum: You not can claim it for the time being.");
        if(dayRelease>=180){
            swapOrders[_orderIndex].isRelease = true;
        }
        swapOrders[_orderIndex].lastReleaseTime = block.timestamp;
        swapOrders[_orderIndex].lastDayNum = dayRelease;

        uint256 _releaseAmount = order.swapDtuAmount.mul(nowDayNum).div(180);

        // Total
        nowReleaseJoinTotalCount += 1;
        swapAccounts[msg.sender].releaseOrdersIndex.push(nowReleaseJoinTotalCount);
        releaseOrders[nowReleaseJoinTotalCount] = ReleaseOrder(nowReleaseJoinTotalCount,order.account,block.timestamp,_releaseAmount,dayRelease);// add swapOrders

        dtuTokenContract.safeTransfer(order.account,_releaseAmount);// Transfer dtu to user address
        emit Release(msg.sender,nowReleaseJoinTotalCount,dayRelease,nowDayNum,order.swapDtuAmount,_releaseAmount);// set log
        return true;// return result
    }

    function joinSwap(address _joinAddress,uint256 _swapDtuAmount) public onlyOwner returns (bool) {

        nowSwapJoinTotalCount += 1;// add swapAccounts
        swapAccounts[_joinAddress].totalSwapDtuAmount = _swapDtuAmount;
        swapAccounts[_joinAddress].swapOrdersIndex.push(nowSwapJoinTotalCount);

        swapOrders[nowSwapJoinTotalCount] = SwapOrder(nowSwapJoinTotalCount,_joinAddress,_swapDtuAmount,false,0,0);// add swapOrders

        emit JoinSwap(msg.sender, _joinAddress,nowSwapJoinTotalCount, _swapDtuAmount);
        return true;
    }

    // ================= Contact Query  =====================

    function getSwapBasic() public view returns (uint256 DayTime,ERC20 DtuTokenContract,bool ReleaseSwitchState,uint256 ReleaseStartTime,uint256 NowSwapJoinTotalCount,uint256 NowReleaseJoinTotalCount) {
        return (dayTime,dtuTokenContract,releaseSwitchState,releaseStartTime,nowSwapJoinTotalCount,nowReleaseJoinTotalCount);
    }

    function swapAccountOf(address _account) public view returns (uint256 TotalSwapDtuAmount,uint256 [] memory SwapOrdersIndex,uint256 [] memory ReleaseOrdersIndex){
        SwapAccount storage account = swapAccounts[_account];
        return (account.totalSwapDtuAmount,account.swapOrdersIndex,account.releaseOrdersIndex);
    }

    function swapOrdersOf(uint256 _index) public view returns (uint256 Index,address Account,uint256 SwapDtuAmount,bool IsRelease,uint256 LastReleaseTime,uint256 LastDayNum){
        SwapOrder storage order =  swapOrders[_index];
        return (order.index,order.account,order.swapDtuAmount,order.isRelease,order.lastReleaseTime,order.lastDayNum);
    }

    function releaseOrdersOf(uint256 _index) public view returns (uint256 Index,address Account,uint256 ReleaseTime,uint256 ReleaseAmount,uint256 DayRelease){
        ReleaseOrder storage order =  releaseOrders[_index];
        return (order.index,order.account,order.releaseTime,order.releaseAmount,order.dayRelease);
    }

    // ================= Owner Operation  =================

    function getSedimentToken(address _erc20TokenContract, address _to, uint256 _amount) public onlyOwner returns (bool) {
        require(ERC20(_erc20TokenContract).balanceOf(address(this))>=_amount,"_amount: The current token balance of the contract is insufficient.");
        ERC20(_erc20TokenContract).safeTransfer(_to, _amount);// Transfer token to destination address
        emit SedimentToken(msg.sender, _erc20TokenContract, _to, _amount);// set log
        return true;// return result
    }

    // ================= Initial Operation  =====================

    function setAddressList(address _dtuTokenContract) public onlyOwner returns (bool) {
        dtuTokenContract = ERC20(_dtuTokenContract);
        emit AddressList(msg.sender, _dtuTokenContract);
        return true;
    }

    function setSwapSwitchState(bool _releaseSwitchState) public onlyOwner returns (bool) {
        releaseSwitchState = _releaseSwitchState;
        if(releaseStartTime==0&&_releaseSwitchState){
            releaseStartTime = block.timestamp;
        }
        emit SwitchState(msg.sender, _releaseSwitchState);
        return true;
    }


}