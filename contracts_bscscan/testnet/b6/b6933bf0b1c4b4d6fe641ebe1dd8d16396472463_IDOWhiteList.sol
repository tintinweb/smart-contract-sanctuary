pragma solidity 0.5.8;

import { Ownable } from "./Ownable.sol" ;
import "./SafeMath.sol";
import "./SafeERC20.sol";

contract IDOWhiteList is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for ERC20;

    // IDOWhiteList Basis
    uint256 private dayTime;
    ERC20 private usdtTokenContract;
    ERC20 private macTokenContract;
    address private officialAddress;

    bool private swapSwitchState;
    bool private releaseSwitchState;
    uint256 private nextReleaseTime;

    uint256 private swapNowJoinTotalCount;
    uint256 private swapNowJoinTotalUsdtAmount;
    uint256 private payUsdtAmountOne;
    uint256 private payUsdtAmountTwo;
    bool public sendBackState;

    // Account
    mapping(address => IdoAccount) private idoAccounts;
    struct IdoAccount {
        uint256 totalJoinCount;
        uint256 [] joinOrdersIndex;
    }
    mapping(uint256 => JoinOrder) private joinOrders;
    struct JoinOrder {
        uint256 index;
        address account;
        uint256 joinTime;
        uint256 payUsdtAmount;
        uint256 swapMacAmount;
    }

    // Events
    event SedimentToken(address indexed _account,address  _erc20TokenContract, address _to, uint256 _amount);
    event AddressList(address indexed _account, address _usdtTokenContract, address _macTokenContract, address _officialAddress);
    event SwitchState(address indexed _account, bool _swapSwitchState, bool _releaseOneSwitchState);
    event JoinSwap(address indexed _account, uint256 _swapNowJoinTotalCount, uint256 _payUsdtAmount, uint256 _swapMacAmount);
    event Release(address indexed _account, uint256 _swapNowJoinTotalCount);
    event BackState(address indexed _account, uint256 _backStateCount);

    // ================= Initial Value ===============

    constructor () public {
          dayTime = 86400;
          usdtTokenContract = ERC20(0x2700BC595607F154163471Ac2bD46eA8987d4cf0);
          macTokenContract = ERC20(0xDF33E6c6eA9BE9A2F8fC18e898caCaFc82d3a414);
          officialAddress = address(0x8F04b966d6FA78D087004E8ef624421511FAc0a4);
          swapSwitchState = false;
          releaseSwitchState = false;
          payUsdtAmountOne = 500 * 10 ** 18;
          payUsdtAmountTwo = 1000 * 10 ** 18;
    }

    // ================= Swap Operation  =====================

    function sendBack() public onlyOwner returns (bool) {
        // Data validation
        require(!sendBackState,"-> sendBackState: not false.");
        require(swapNowJoinTotalCount>800,"-> swapNowJoinTotalCount: not 800.");

        // Update presellAccountOrders
        for(uint256 i=801; i<=swapNowJoinTotalCount; i++){
            usdtTokenContract.safeTransfer(joinOrders[i].account,joinOrders[i].payUsdtAmount);// Transfer user to user address
        }

        sendBackState = true;
        emit BackState(msg.sender,swapNowJoinTotalCount.sub(800));// set log
        return true;// return result
    }

    function release() public returns (bool) {
        // Data validation
        require(swapSwitchState,"-> releaseOneSwitchState: release has not started yet.");
        require(block.timestamp>=nextReleaseTime,"-> nextReleaseTime: The start time has not been reached.");

        // Update presellAccountOrders
        uint256 endIndex;
        if(swapNowJoinTotalCount>800){
            endIndex = 800;
        }else{
            endIndex = swapNowJoinTotalCount;
        }
        for(uint256 i=1; i<=endIndex; i++){
            macTokenContract.safeTransfer(joinOrders[i].account,joinOrders[i].swapMacAmount.div(12));// Transfer mac to user address 1/12
        }

        nextReleaseTime += dayTime.mul(30);// update nextReleaseTime

        emit Release(msg.sender,endIndex);// set log
        return true;// return result
    }

    function joinSwap(uint256 _payUsdtAmount) public returns (bool) {
        // Data validation
        require(swapSwitchState,"-> swapSwitchState: Swap has not started yet.");
        require(idoAccounts[msg.sender].totalJoinCount<=0,"-> totalJoinCount: totalJoinCount error.");
        require(_payUsdtAmount>=payUsdtAmountOne&&_payUsdtAmount<=payUsdtAmountTwo,"-> _payUsdtAmount: _payUsdtAmount error.");
        require(usdtTokenContract.balanceOf(msg.sender)>=_payUsdtAmount,"-> _payUsdtAmount: Insufficient address usdt balance.");

        // Orders dispose
        uint256 swapMacAmount = _payUsdtAmount.div(60).mul(100);// swapRate = 0.6U

        swapNowJoinTotalCount += 1;
        swapNowJoinTotalUsdtAmount += _payUsdtAmount;
        idoAccounts[msg.sender].totalJoinCount = 1;
        idoAccounts[msg.sender].joinOrdersIndex.push(swapNowJoinTotalCount);
        joinOrders[swapNowJoinTotalCount] = JoinOrder(swapNowJoinTotalCount,msg.sender,block.timestamp,_payUsdtAmount,swapMacAmount);// add joinOrders

        // Amount dispose
        if(swapNowJoinTotalCount<=800){
            usdtTokenContract.safeTransferFrom(address(msg.sender),officialAddress,_payUsdtAmount);// usdt to officialAddress
        }else if(swapNowJoinTotalCount<=1000){
            usdtTokenContract.safeTransferFrom(address(msg.sender),address(this),_payUsdtAmount);// usdt to officialAddress
        }else{
            require(false,"-> swapNowJoinTotalCount: max error.");
        }

        emit JoinSwap(msg.sender, swapNowJoinTotalCount, _payUsdtAmount, swapMacAmount);
        return true;
    }

    // ================= Contact Query  =====================

    function getIdoBasic() public view returns (uint256 DayTime,ERC20 UsdtTokenContract,ERC20 MacTokenContract,address OfficialAddress,bool SwapSwitchState,bool ReleaseSwitchState,
      uint256 NextReleaseTime,uint256 SwapNowJoinTotalCount,uint256 SwapNowJoinTotalUsdtAmount,uint256 PayUsdtAmountOne,uint256 PayUsdtAmountTwo)
    {
        return (dayTime,usdtTokenContract,macTokenContract,officialAddress,swapSwitchState,releaseSwitchState,nextReleaseTime,swapNowJoinTotalCount,swapNowJoinTotalUsdtAmount,
            payUsdtAmountOne,payUsdtAmountTwo);
    }

    function idoAccountOf(address _account) public view returns (uint256 TotalJoinCount,uint256 [] memory JoinOrdersIndex){
        IdoAccount storage account = idoAccounts[_account];
        return (account.totalJoinCount,account.joinOrdersIndex);
    }

    function joinOrdersOf(uint256 _index) public view returns (uint256 Index,address Account,uint256 JoinTime,uint256 PayUsdtAmount,uint256 SwapMacAmount){
        JoinOrder storage order =  joinOrders[_index];
        return (order.index,order.account,order.joinTime,order.payUsdtAmount,order.swapMacAmount);
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

    function setSwapSwitchState(bool _swapSwitchState,bool _releaseSwitchState) public onlyOwner returns (bool) {
        swapSwitchState = _swapSwitchState;
        releaseSwitchState = _releaseSwitchState;
        if(nextReleaseTime==0&&_releaseSwitchState){
           nextReleaseTime = block.timestamp;// set nextReleaseTime
        }
        emit SwitchState(msg.sender, _swapSwitchState, _releaseSwitchState);
        return true;
    }
}