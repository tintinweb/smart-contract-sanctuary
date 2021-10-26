pragma solidity 0.5.8;

import { Ownable } from "./Ownable.sol" ;
import "./SafeMath.sol";
import "./SafeERC20.sol";

contract IDO is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for ERC20;

    // IDO Basis
    uint256 private dayTime;
    ERC20 private usdtTokenContract;
    ERC20 private macTokenContract;
    address private officialAddress;

    bool private oneSwapSwitchState;
    bool private twoSwapSwitchState;

    bool private releaseOneSwitchState;
    bool private releaseTwoSwitchState;
    uint256 private oneNextReleaseTime;
    uint256 private twoNextReleaseTime;

    uint256 private oneSwapNowJoinAmount;
    uint256 private twoSwapNowJoinAmount;
    uint256 private swapNowJoinTotalCount;

    uint256 private oneSwapMax;
    uint256 private twoSwapMax;

    // Account
    mapping(address => IdoAccount) private idoAccounts;
    struct IdoAccount {
        uint256 totalJoinOneCount;
        uint256 totalJoinTwoCount;
        uint256 totalPayUsdtAmount;
        uint256 totalSwapMacAmount;
        uint256 [] joinOrdersIndex;
    }
    mapping(uint256 => JoinOrder) private joinOrders;
    struct JoinOrder {
        uint256 index;
        address account;
        uint256 joinTime;
        uint256 swapId;
        uint256 payUsdtAmount;
        uint256 swapMacAmount;
    }

    // Events
    event SedimentToken(address indexed _account,address  _erc20TokenContract, address _to, uint256 _amount);
    event AddressList(address indexed _account, address _usdtTokenContract, address _macTokenContract, address _officialAddress);
    event SwitchState(address indexed _account, bool _oneSwapSwitchState, bool _twoSwapSwitchState, bool _releaseOneSwitchState, bool _releaseTwoSwitchState);
    event JoinSwap(address indexed _account, uint256 _swapNowJoinTotalCount, uint256 _swapId, uint256 _payUsdtAmount, uint256 _swapMacAmount);
    event ReleaseOne(address indexed _account, uint256 _swapNowJoinTotalCount);
    event ReleaseTwo(address indexed _account, uint256 _swapNowJoinTotalCount);

    // ================= Initial Value ===============

    constructor () public {
          /* dayTime = 86400; */
          dayTime = 120;
          usdtTokenContract = ERC20(0x55d398326f99059fF775485246999027B3197955);
          macTokenContract = ERC20(0xDF33E6c6eA9BE9A2F8fC18e898caCaFc82d3a414);
          officialAddress = address(0x8F04b966d6FA78D087004E8ef624421511FAc0a4);
          oneSwapSwitchState = false;
          twoSwapSwitchState = false;
          releaseOneSwitchState = false;
          releaseTwoSwitchState = false;
          oneSwapMax = 3000000 * 10 ** 18; // max 300W
          twoSwapMax = 7000000 * 10 ** 18; // max 700W
    }

    // ================= Swap Operation  =====================

    function releaseTwo() public returns (bool) {
        // Data validation
        require(releaseTwoSwitchState,"-> releaseTwoSwitchState: release has not started yet.");
        require(block.timestamp>=twoNextReleaseTime,"-> twoNextReleaseTime: The start time has not been reached.");

        // Update presellAccountOrders
        for(uint256 i=1;i<=swapNowJoinTotalCount;i++){
            if(joinOrders[i].swapId==2){
                macTokenContract.safeTransfer(joinOrders[i].account,joinOrders[i].swapMacAmount.div(9));// Transfer mac to user address 1/9
            }
        }

        twoNextReleaseTime += dayTime.mul(30);// update twoNextReleaseTime

        emit ReleaseTwo(msg.sender,swapNowJoinTotalCount);// set log
        return true;// return result
    }

    function releaseOne() public returns (bool) {
        // Data validation
        require(releaseOneSwitchState,"-> releaseOneSwitchState: release has not started yet.");
        require(block.timestamp>=oneNextReleaseTime,"-> oneNextReleaseTime: The start time has not been reached.");

        // Update presellAccountOrders
        for(uint256 i=1;i<=swapNowJoinTotalCount;i++){
            if(joinOrders[i].swapId==1){
                macTokenContract.safeTransfer(joinOrders[i].account,joinOrders[i].swapMacAmount.div(12));// Transfer mac to user address 1/12
            }
        }

        oneNextReleaseTime += dayTime.mul(30);// update oneNextReleaseTime

        emit ReleaseOne(msg.sender,swapNowJoinTotalCount);// set log
        return true;// return result
    }

    function joinSwap(uint256 _payUsdtAmount,uint256 _swapId) public returns (bool) {
        // Data validation
        require(usdtTokenContract.balanceOf(msg.sender)>=_payUsdtAmount,"-> _payUsdtAmount: Insufficient address usdt balance.");

        uint256 swapMacAmount;
        if(_swapId==1){
            require(oneSwapSwitchState,"-> oneSwapSwitchState: Swap has not started yet.");
            swapMacAmount = _payUsdtAmount.div(60).mul(100);// swapRate = 0.6U
            require(oneSwapNowJoinAmount.add(swapMacAmount)<=oneSwapMax,"-> oneSwapMax: Add amount exceeds the maximum value.");
            oneSwapNowJoinAmount += swapMacAmount;

        }else if(_swapId==2){
            require(twoSwapSwitchState,"-> twoSwapSwitchState: Swap has not started yet.");
            swapMacAmount = _payUsdtAmount.div(80).mul(100);// swapRate = 0.8U
            require(twoSwapNowJoinAmount.add(swapMacAmount)<=twoSwapMax,"-> twoSwapMax: Add amount exceeds the maximum value.");
            twoSwapNowJoinAmount += swapMacAmount;

        }else{
            require(false,"-> _swapId: No this product.");
        }

        // Orders dispose
        usdtTokenContract.safeTransferFrom(address(msg.sender),officialAddress,_payUsdtAmount);// usdt to officialAddress

        swapNowJoinTotalCount += 1;
        if(_swapId==1){
            idoAccounts[msg.sender].totalJoinOneCount += 1;// add swapAccounts
        }else{
            idoAccounts[msg.sender].totalJoinTwoCount += 1;// add swapAccounts
        }
        idoAccounts[msg.sender].totalPayUsdtAmount += _payUsdtAmount;
        idoAccounts[msg.sender].totalSwapMacAmount += swapMacAmount;
        idoAccounts[msg.sender].joinOrdersIndex.push(swapNowJoinTotalCount);

        joinOrders[swapNowJoinTotalCount] = JoinOrder(swapNowJoinTotalCount,msg.sender,block.timestamp,_swapId,_payUsdtAmount,swapMacAmount);// add joinOrders

        emit JoinSwap(msg.sender, swapNowJoinTotalCount, _swapId, _payUsdtAmount, swapMacAmount);
        return true;
    }

    // ================= Contact Query  =====================

    function getIdoBasic() public view returns (uint256 DayTime,ERC20 UsdtTokenContract,ERC20 MacTokenContract,address OfficialAddress,bool OneSwapSwitchState,bool TwoSwapSwitchState,
      bool ReleaseOneSwitchState,bool ReleaseTwoSwitchState,uint256 OneNextReleaseTime,uint256 TwoNextReleaseTime,
      uint256 OneSwapNowJoinAmount,uint256 TwoSwapNowJoinAmount,uint256 SwapNowJoinTotalCount)
    {
        return (dayTime,usdtTokenContract,macTokenContract,officialAddress,oneSwapSwitchState,twoSwapSwitchState,releaseOneSwitchState,releaseTwoSwitchState,
          oneNextReleaseTime,twoNextReleaseTime,oneSwapNowJoinAmount,twoSwapNowJoinAmount,swapNowJoinTotalCount);
    }

    function idoAccountOf(address _account) public view returns (uint256 TotalJoinOneCount,uint256 TotalJoinTwoCount,uint256 TotalPayUsdtAmount,uint256 TotalSwapMacAmount,uint256 [] memory JoinOrdersIndex){
        IdoAccount storage account = idoAccounts[_account];
        return (account.totalJoinOneCount,account.totalJoinTwoCount,account.totalPayUsdtAmount,account.totalSwapMacAmount,account.joinOrdersIndex);
    }

    function joinOrdersOf(uint256 _index) public view returns (uint256 Index,address Account,uint256 JoinTime,uint256 SwapId,uint256 PayUsdtAmount,uint256 SwapMacAmount){
        JoinOrder storage order =  joinOrders[_index];
        return (order.index,order.account,order.joinTime,order.swapId,order.payUsdtAmount,order.swapMacAmount);
    }

    // ================= Owner Operation  =================

    function getSedimentToken(address _erc20TokenContract, address _to, uint256 _amount) public onlyOwner returns (bool) {
        require(ERC20(_erc20TokenContract).balanceOf(address(this))>=_amount,"_amount: The current token balance of the contract is insufficient.");
        ERC20(_erc20TokenContract).safeTransfer(_to, _amount);// Transfer token to destination address
        emit SedimentToken(msg.sender, _erc20TokenContract, _to, _amount);// set log
        return true;// return result
    }

    // ================= Initial Operation  =====================

    function setAddressList(address _usdtTokenContract,address _macTokenContract,address _officialAddress) public onlyOwner returns (bool) {
        usdtTokenContract = ERC20(_usdtTokenContract);
        macTokenContract = ERC20(_macTokenContract);
        officialAddress = _officialAddress;
        emit AddressList(msg.sender, _usdtTokenContract, _macTokenContract, _officialAddress);
        return true;
    }

    function setSwapSwitchState(bool _oneSwapSwitchState,bool _twoSwapSwitchState,bool _releaseOneSwitchState,bool _releaseTwoSwitchState) public onlyOwner returns (bool) {
        oneSwapSwitchState = _oneSwapSwitchState;
        twoSwapSwitchState = _twoSwapSwitchState;
        releaseOneSwitchState = _releaseOneSwitchState;
        releaseTwoSwitchState = _releaseTwoSwitchState;
        if(oneNextReleaseTime==0&&_releaseOneSwitchState){
           oneNextReleaseTime = block.timestamp;// set oneNextReleaseTime
        }
        if(twoNextReleaseTime==0&&_releaseTwoSwitchState){
           twoNextReleaseTime = block.timestamp;// set twoNextReleaseTime
        }
        emit SwitchState(msg.sender, _oneSwapSwitchState,_twoSwapSwitchState,_releaseOneSwitchState,_releaseOneSwitchState);
        return true;
    }
}