pragma solidity 0.5.8;

import { Ownable } from "./Ownable.sol" ;
import "./SafeMath.sol";
import "./SafeERC20.sol";

contract IDO is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for ERC20;

    // Swap Basis
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

    // Account
    mapping(address => SwapAccount) private swapAccounts;
    struct SwapAccount {
        uint256 totalJoinCount;
        uint256 totalPayUsdtAmount;
        uint256 totalSwapDtuAmount;
        uint256 [] swapOrdersIndex;
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
    }

    // Events
    event SedimentToken(address indexed _account,address  _erc20TokenContract, address _to, uint256 _amount);
    event AddressList(address indexed _account, address _usdtTokenContract, address _dtuTokenContract, address _officialAddress);
    event SwitchState(address indexed _account, bool _oneSwapSwitchState, bool _twoSwapSwitchState, bool _threeSwapSwitchState, bool _releaseSwitchState);

    // ================= Initial Value ===============

    constructor () public {
          usdtTokenContract = ERC20(0xe3dfa273B6F964BAB41A10C204226eB66aBE3684);
          dtuTokenContract = ERC20(0x96B42591F42d0E7d5B0514D040d4CE726ab18712);
          officialAddress = address(0x5609fD3470F87B1A5A1Db191987858697bE00356);
          oneSwapSwitchState = true;
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

    /* function release() public returns (bool) {
        // Data validation
        require(releaseSwitchState,"-> releaseSwitchState: release has not started yet.");

        // Update presellAccountOrders
        for(uint256 i=1;i<=swapNowJoinTotalCount;i++){
            if(!swapOrders[i].isRelease){
                swapOrders[i].isRelease = true;
                cuseTokenContract.safeTransfer(swapOrders[i].account,swapOrders[i].swapCuseAmount);// Transfer cuse to user address
            }
        }
        emit Release(msg.sender,swapNowJoinTotalCount);// set log
        return true;// return result
    }

    function joinSwap(uint256 _payUsdtAmount,uint256 _swapId) public returns (bool) {
        // Data validation
        require(usdtTokenContract.balanceOf(msg.sender)>=_payUsdtAmount,"-> _payUsdtAmount: Insufficient address usdt balance.");
        require(swapAccounts[msg.sender].totalJoinCount<swapAccountJoinMaxCount,"-> swapAccountJoinMaxCount: One address can be bought up to five times.");

        uint256 swapCuseAmount;
        if(_swapId==1){
            require(oneSwapSwitchState,"-> oneSwapSwitchState: Swap has not started yet.");
            swapCuseAmount = _payUsdtAmount.div(15).mul(100);// swapRate = 0.15U
            require(oneSwapNowJoinAmount.add(swapCuseAmount)<=oneSwapMaxJoinAmount,"-> oneSwapMaxJoinAmount: The maximum amount cannot be exceeded.");
            oneSwapNowJoinAmount += swapCuseAmount;

        }else if(_swapId==2){
            require(twoSwapSwitchState,"-> twoSwapSwitchState: Swap has not started yet.");
            swapCuseAmount = _payUsdtAmount.div(20).mul(100);// swapRate = 0.2U
            require(twoSwapNowJoinAmount.add(swapCuseAmount)<=twoSwapMaxJoinAmount,"-> twoSwapMaxJoinAmount: The maximum amount cannot be exceeded.");
            twoSwapNowJoinAmount += swapCuseAmount;

        }else if(_swapId==3){
            require(threeSwapSwitchState,"-> threeSwapSwitchState: Swap has not started yet.");
            swapCuseAmount = _payUsdtAmount.div(25).mul(100);// swapRate = 0.25U
            require(threeSwapNowJoinAmount.add(swapCuseAmount)<=threeSwapMaxJoinAmount,"-> threeSwapMaxJoinAmount: The maximum amount cannot be exceeded.");
            threeSwapNowJoinAmount += swapCuseAmount;

        }else{
            require(false,"-> _swapId: No this product.");
        }

        // Orders dispose
        usdtTokenContract.safeTransferFrom(address(msg.sender),officialAddress,_payUsdtAmount);// usdt to officialAddress

        swapNowJoinTotalCount += 1;
        swapAccounts[msg.sender].totalJoinCount += 1;// add swapAccounts
        swapAccounts[msg.sender].totalPayUsdtAmount += _payUsdtAmount;
        swapAccounts[msg.sender].totalSwapCuseAmount += swapCuseAmount;
        swapAccounts[msg.sender].swapOrdersIndex.push(swapNowJoinTotalCount);

        swapOrders[swapNowJoinTotalCount] = SwapOrder(swapNowJoinTotalCount,msg.sender,block.timestamp,_swapId,_payUsdtAmount,swapCuseAmount,false);// add swapOrders

        emit JoinSwap(msg.sender, swapNowJoinTotalCount, _swapId, _payUsdtAmount, swapCuseAmount);
        return true;
    } */

    // ================= Contact Query  =====================
/*
    uint256 private oneSwapJoinAmount;
    uint256 private twoSwapJoinAmount;
    uint256 private threeSwapMinAmount;

    uint256 private oneSwapMaxAmount;
    uint256 private twoSwapMaxAmount;
    uint256 private threeSwapMaxAmount;

    uint256 private nowOneSwapJoinAmount;
    uint256 private nowTwoSwapJoinAmount;
    uint256 private nowThreeSwapJoinAmount;

    uint256 private nowSwapJoinTotalCount; */

    function getSwapBasic() public view returns (ERC20 UsdtTokenContract,ERC20 DtuTokenContract,address OfficialAddress,bool OneSwapSwitchState,bool TwoSwapSwitchState,bool ThreeSwapSwitchState,
      bool ReleaseSwitchState,uint256 OneSwapStartTime,uint256 TwoSwapStartTime,uint256 ThreeSwapStartTime,uint256 ReleaseStartTime)
    {
        return (usdtTokenContract,dtuTokenContract,officialAddress,oneSwapSwitchState,twoSwapSwitchState,threeSwapSwitchState,releaseSwitchState,
          oneSwapStartTime,twoSwapStartTime,threeSwapStartTime,releaseStartTime);
    }

    function swapAccountOf(address _account) public view returns (uint256 TotalJoinCount,uint256 TotalPayUsdtAmount,uint256 TotalSwapDtuAmount,uint256 [] memory SwapOrdersIndex){
        SwapAccount storage account = swapAccounts[_account];
        return (account.totalJoinCount,account.totalPayUsdtAmount,account.totalSwapDtuAmount,account.swapOrdersIndex);
    }

    function swapOrdersOf(uint256 _index) public view returns (uint256 Index,address Account,uint256 JoinTime,uint256 SwapId,uint256 PayUsdtAmount,uint256 SwapDtuAmount,
      bool IsRelease,uint256 LastReleaseTime){
        SwapOrder storage order =  swapOrders[_index];
        return (order.index,order.account,order.joinTime,order.swapId,order.payUsdtAmount,order.swapDtuAmount,order.isRelease,order.lastReleaseTime);
    }

    // ================= Owner Operation  =================

    function getSedimentToken(address _erc20TokenContract, address _to, uint256 _amount) public onlyOwner returns (bool) {
        require(ERC20(_erc20TokenContract).balanceOf(address(this))>=_amount,"_amount: The current token balance of the contract is insufficient.");
        ERC20(_erc20TokenContract).safeTransfer(_to, _amount);// Transfer token to destination address
        emit SedimentToken(msg.sender, _erc20TokenContract, _to, _amount);// set log
        return true;// return result
    }

    // ================= Initial Operation  =====================

    function setAddressList(address _usdtTokenContract,address _dtuTokenContract,address _officialAddress) public onlyOwner returns (bool) {
        usdtTokenContract = ERC20(_usdtTokenContract);
        dtuTokenContract = ERC20(_dtuTokenContract);
        officialAddress = _officialAddress;
        emit AddressList(msg.sender, _usdtTokenContract, _dtuTokenContract, _officialAddress);
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
}