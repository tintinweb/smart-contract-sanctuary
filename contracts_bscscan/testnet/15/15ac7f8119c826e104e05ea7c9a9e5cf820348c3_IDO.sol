pragma solidity 0.5.8;

import { Ownable } from "./Ownable.sol" ;
import "./SafeMath.sol";
import "./SafeERC20.sol";

contract Invite {
    function inviterAddressOf(address _account) public view returns (address InviterAddress);
}

contract IDO is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for ERC20;

    Invite public inviteContract;

    // Swap Basis
    uint256 private dayTime;
    ERC20 private usdtTokenContract;
    ERC20 private dtuTokenContract;
    address private officialAddress;

    bool private oneSwapSwitchState;
    bool private twoSwapSwitchState;
    bool private threeSwapSwitchState;
    bool private releaseSwitchState;
    uint256 private oneSwapStartTime;
    uint256 private twoSwapStartTime;
    uint256 private threeSwapStartTime;
    uint256 private releaseStartTime;

    // Amount Basis
    uint256 private oneSwapJoinAmount;
    uint256 private twoSwapJoinAmount;
    uint256 private threeSwapMinAmount;

    uint256 private oneSwapMaxAmount;
    uint256 private twoSwapMaxAmount;
    uint256 private threeSwapMaxAmount;

    uint256 private nowOneSwapJoinAmount;
    uint256 private nowTwoSwapJoinAmount;
    uint256 private nowThreeSwapJoinAmount;

    uint256 private nowSwapJoinTotalCount;
    uint256 private nowReleaseJoinTotalCount;

    // Account
    mapping(address => SwapAccount) private swapAccounts;
    struct SwapAccount {
        uint256 totalJoinCount;
        uint256 totalPayUsdtAmount;
        uint256 totalSwapDtuAmount;
        uint256 [] swapOrdersIndex;
        uint256 [] releaseOrdersIndex;
    }
    mapping(uint256 => SwapOrder) private swapOrders;
    struct SwapOrder {
        uint256 index;
        address account;
        uint256 joinTime;
        uint256 swapId;
        uint256 payUsdtAmount;
        uint256 swapDtuAmount;
        bool isRelease;
        uint256 lastReleaseTime;
        uint256 lastDayNum;
    }

    // WiteList
    mapping(address => bool) private whiteListAccounts;
    uint256 public whiteListCount;

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
    event AddressList(address indexed _account, address _usdtTokenContract, address _dtuTokenContract, address _officialAddress, address _inviteContract);
    event SwitchState(address indexed _account, bool _oneSwapSwitchState, bool _twoSwapSwitchState, bool _threeSwapSwitchState, bool _releaseSwitchState);
    event JoinSwap(address indexed _account, uint256 _nowSwapJoinTotalCount, uint256 _swapId, uint256 _payUsdtAmount, uint256 _swapDtuAmount);
    event SetThreeSwapMaxAmount(address indexed _account, uint256 _threeSwapMaxAmount);
    event AddWhiteList(address indexed _account, uint256 _witeListCount, address _whiteAccount);
    event Release(address indexed _account, uint256 nowReleaseJoinTotalCount, uint256 _dayRelease, uint256 _nowDayNum, uint256 _swapDtuAmount, uint256 _releaseAmount);

    // ================= Initial Value ===============

    constructor () public {
          /* dayTime = 86400; */
          dayTime = 180;
          usdtTokenContract = ERC20(0xe3dfa273B6F964BAB41A10C204226eB66aBE3684);
          dtuTokenContract = ERC20(0x96B42591F42d0E7d5B0514D040d4CE726ab18712);
          officialAddress = address(0x6E0e0eFC0d4d945D90b2C1247a45691Ba53Aa92f);
          inviteContract = Invite(0xe37495a91A7985e1afcdDcFd56c1FC848B510649);
          oneSwapSwitchState = false;
          twoSwapSwitchState = false;
          threeSwapSwitchState = false;
          releaseSwitchState = false;
          oneSwapJoinAmount = 2000 * 10 ** 18; // account 2000u
          twoSwapJoinAmount = 1000 * 10 ** 18;// account 1000u
          threeSwapMinAmount = 100 * 10 ** 18;// min 100 u
          oneSwapMaxAmount = 200000 * 10 ** 18;// max 20W u
          twoSwapMaxAmount = 160000 * 10 ** 18;// max 10W u
          threeSwapMaxAmount = 200000 * 10 ** 18;// max 10W u
    }

    // ================= Swap Operation  =====================

    function isTodayReleaseOf(uint256 _orderIndex) public view returns (bool IsTodayRelease) {
        // Data validation
        SwapOrder storage order =  swapOrders[_orderIndex];

        // Order dispose
        uint256 diffTime = block.timestamp.sub(releaseStartTime);
        uint256 dayRelease = diffTime.div(dayTime).add(1);
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

    function whiteListOf(address _account) public view returns (bool IsWhiteList) {
        return whiteListAccounts[_account];
    }

    function addWhiteList(address _whiteAccount) public onlyOwner returns (bool) {
        whiteListCount += 1;
        whiteListAccounts[_whiteAccount] = true;
        emit AddWhiteList(msg.sender,whiteListCount,_whiteAccount);
        return true;
    }

    function joinSwap(uint256 _payUsdtAmount,uint256 _swapId) public returns (bool) {
        // Invite check
        require(inviteContract.inviterAddressOf(msg.sender)!=address(0),"-> Invite: The address has not been added to the eco.");

        // Data validation
        require(usdtTokenContract.balanceOf(msg.sender)>=_payUsdtAmount,"-> _payUsdtAmount: Insufficient address usdt balance.");
        require(swapAccounts[msg.sender].totalJoinCount<1,"-> swapAccountJoinMaxCount: One address can be bought up to one times.");

        uint256 swapDtuAmount;
        if(_swapId==1){
            require(oneSwapSwitchState,"-> oneSwapSwitchState: Swap has not started yet.");
            require(whiteListOf(msg.sender),"-> whiteList: Not whiteList.");
            require(_payUsdtAmount==oneSwapJoinAmount,"-> _payUsdtAmount: _payUsdtAmount error.");
            swapDtuAmount = _payUsdtAmount.div(10).mul(100);// swapRate = 0.10U
            require(nowOneSwapJoinAmount.add(_payUsdtAmount)<=oneSwapMaxAmount,"-> oneSwapMaxAmount: The maximum amount cannot be exceeded.");
            nowOneSwapJoinAmount += _payUsdtAmount;

        }else if(_swapId==2){
            require(twoSwapSwitchState,"-> twoSwapSwitchState: Swap has not started yet.");
            require(_payUsdtAmount==twoSwapJoinAmount,"-> _payUsdtAmount: _payUsdtAmount error.");
            swapDtuAmount = _payUsdtAmount.div(16).mul(100);// swapRate = 0.16U
            require(nowTwoSwapJoinAmount.add(_payUsdtAmount)<=twoSwapMaxAmount,"-> twoSwapMaxAmount: The maximum amount cannot be exceeded.");
            nowTwoSwapJoinAmount += _payUsdtAmount;

        }else if(_swapId==3){
            require(threeSwapSwitchState,"-> threeSwapSwitchState: Swap has not started yet.");
            require(_payUsdtAmount>=threeSwapMinAmount,"-> _payUsdtAmount: _payUsdtAmount error.");
            swapDtuAmount = _payUsdtAmount.div(20).mul(100);// swapRate = 0.2U
            require(nowThreeSwapJoinAmount.add(_payUsdtAmount)<=threeSwapMaxAmount,"-> threeSwapMaxAmount: The maximum amount cannot be exceeded.");
            nowThreeSwapJoinAmount += _payUsdtAmount;

        }else{
            require(false,"-> _swapId: No this product.");
        }

        // Orders dispose
        usdtTokenContract.safeTransferFrom(address(msg.sender),officialAddress,_payUsdtAmount);// usdt to officialAddress

        nowSwapJoinTotalCount += 1;
        swapAccounts[msg.sender].totalJoinCount += 1;// add swapAccounts
        swapAccounts[msg.sender].totalPayUsdtAmount += _payUsdtAmount;
        swapAccounts[msg.sender].totalSwapDtuAmount += swapDtuAmount;
        swapAccounts[msg.sender].swapOrdersIndex.push(nowSwapJoinTotalCount);

        swapOrders[nowSwapJoinTotalCount] = SwapOrder(nowSwapJoinTotalCount,msg.sender,block.timestamp,_swapId,_payUsdtAmount,swapDtuAmount,false,0,0);// add swapOrders

        emit JoinSwap(msg.sender, nowSwapJoinTotalCount, _swapId, _payUsdtAmount, swapDtuAmount);
        return true;
    }

    // ================= Contact Query  =====================

    function getSwapBasic() public view returns (uint256 DayTime,ERC20 UsdtTokenContract,ERC20 DtuTokenContract,address OfficialAddress,
      Invite InviteContract,bool OneSwapSwitchState,bool TwoSwapSwitchState,bool ThreeSwapSwitchState,
      bool ReleaseSwitchState,uint256 OneSwapStartTime,uint256 TwoSwapStartTime,uint256 ThreeSwapStartTime,uint256 ReleaseStartTime)
    {
        return (dayTime,usdtTokenContract,dtuTokenContract,officialAddress,inviteContract,
          oneSwapSwitchState,twoSwapSwitchState,threeSwapSwitchState,releaseSwitchState,
          oneSwapStartTime,twoSwapStartTime,threeSwapStartTime,releaseStartTime);
    }

    function getAmountBasic() public view returns (uint256 OneSwapJoinAmount,uint256 TwoSwapJoinAmount,uint256 ThreeSwapMinAmount,
      uint256 OneSwapMaxAmount,uint256 TwoSwapMaxAmount,uint256 ThreeSwapMaxAmount,
      uint256 NowOneSwapJoinAmount,uint256 NowTwoSwapJoinAmount,uint256 NowThreeSwapJoinAmount,uint256 NowSwapJoinTotalCount,uint256 NowReleaseJoinTotalCount)
    {
        return (oneSwapJoinAmount,twoSwapJoinAmount,threeSwapMinAmount,oneSwapMaxAmount,twoSwapMaxAmount,threeSwapMaxAmount,
          nowOneSwapJoinAmount,nowTwoSwapJoinAmount,nowThreeSwapJoinAmount,nowSwapJoinTotalCount,nowReleaseJoinTotalCount);
    }

    function swapAccountOf(address _account) public view returns (uint256 TotalJoinCount,uint256 TotalPayUsdtAmount,uint256 TotalSwapDtuAmount,uint256 [] memory SwapOrdersIndex
      ,uint256 [] memory ReleaseOrdersIndex){
        SwapAccount storage account = swapAccounts[_account];
        return (account.totalJoinCount,account.totalPayUsdtAmount,account.totalSwapDtuAmount,account.swapOrdersIndex,account.releaseOrdersIndex);
    }

    function swapOrdersOf(uint256 _index) public view returns (uint256 Index,address Account,uint256 JoinTime,uint256 SwapId,uint256 PayUsdtAmount,uint256 SwapDtuAmount,
      bool IsRelease,uint256 LastReleaseTime){
        SwapOrder storage order =  swapOrders[_index];
        return (order.index,order.account,order.joinTime,order.swapId,order.payUsdtAmount,order.swapDtuAmount,order.isRelease,order.lastReleaseTime);
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

    function setAddressList(address _usdtTokenContract,address _dtuTokenContract,address _officialAddress,address _inviteContract) public onlyOwner returns (bool) {
        usdtTokenContract = ERC20(_usdtTokenContract);
        dtuTokenContract = ERC20(_dtuTokenContract);
        officialAddress = _officialAddress;
        inviteContract = Invite(_inviteContract);
        emit AddressList(msg.sender, _usdtTokenContract, _dtuTokenContract, _officialAddress, _inviteContract);
        return true;
    }

    function setSwapSwitchState(bool _oneSwapSwitchState,bool _twoSwapSwitchState,bool _threeSwapSwitchState,bool _releaseSwitchState) public onlyOwner returns (bool) {
        oneSwapSwitchState = _oneSwapSwitchState;
        twoSwapSwitchState = _twoSwapSwitchState;
        threeSwapSwitchState = _threeSwapSwitchState;
        releaseSwitchState = _releaseSwitchState;
        if(oneSwapStartTime==0){
            oneSwapStartTime = block.timestamp;
        }
        if(twoSwapStartTime==0){
            twoSwapStartTime = block.timestamp;
        }
        if(threeSwapStartTime==0){
            threeSwapStartTime = block.timestamp;
        }
        if(releaseStartTime==0){
            releaseStartTime = block.timestamp;
        }
        emit SwitchState(msg.sender, _oneSwapSwitchState,_twoSwapSwitchState,_threeSwapSwitchState,_releaseSwitchState);
        return true;
    }

    function setThreeSwapMaxAmount(uint256 _threeSwapMaxAmount) public onlyOwner returns (bool) {
        threeSwapMaxAmount = _threeSwapMaxAmount;
        emit SetThreeSwapMaxAmount(msg.sender, _threeSwapMaxAmount);
        return true;
    }

}