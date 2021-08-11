pragma solidity 0.5.8;

import { Ownable } from "./Ownable.sol" ;
import "./SafeMath.sol";
import "./SafeERC20.sol";

contract McuLend is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for ERC20;

    // Lend Basic
    bool public lendSwitchState;
    uint256 public lendStartTime;
    uint256 private dayTime;

    // ERC20 Token
    ERC20 public mcuTokenContract;
    ERC20 public usdtTokenContract;

    // Deposit
    DepositDailyChemicalRate public depositDailyChemicalRate;
    struct DepositDailyChemicalRate {
        uint256 daily0;
        uint256 daily7;
        uint256 daily15;
        uint256 daily30;
        uint256 daily90;
        uint256 updateTime;
        uint256 depositMinAmount;
        uint256 nowDepositTotalAmount;
        uint256 nowDepositExitProfit;
        uint256 nowDepositTotalJoinCount;
        uint256 nowDepositTotalAccountCount;
    }
    mapping(address => uint256) public depositAccountJoinCount;
    mapping(address => mapping(uint256 => DepositAccountOrder)) public depositAccountOrders;
    struct DepositAccountOrder {
        address account;
        uint256 index;
        bool isExist;
        uint256 joinAmount;
        uint256 daily;
        uint256 rate;
        uint256 joinTime;
        uint256 exitTime;
        uint256 exitAmount;
    }

    // Lend
    LendDailyChemicalRate public lendDailyChemicalRate;
    struct LendDailyChemicalRate {
        uint256 num200;
        uint256 num1000;
        uint256 num3000;
        uint256 updateTime;
        uint256 lendMinAmount;
        uint256 nowLendTotalAmount;
        uint256 nowLendExitProfit;
        uint256 nowLendTotalJoinCount;
        uint256 nowLendTotalAccountCount;
        uint256 nowPledgeTotalAmount;
    }
    mapping(address => uint256) public lendAccountJoinCount;
    mapping(address => mapping(uint256 => LendAccountOrder)) public lendAccountOrders;
    struct LendAccountOrder {
        address account;
        uint256 index;
        bool isExist;
        uint256 pledgeAmount;
        uint256 mcuPriceUsdt;// 1 usdt = ? mcu  (*1000000)
        uint256 lendingRate;
        uint256 lendAmount;
        uint256 rate;
        uint256 joinTime;
        uint256 exitTime;
        uint256 exitAmount;
        uint256 clearingPrice;
        uint256 settlementType;// 0-unredeemed ; 1-settlementStart ; 2-settlementSuccess

    }
    uint256 public mcuPriceUsdt = 2000000;// 1 usdt = ? mcu  (*1000000)
    address public adminAddress;

    // Events
    event TokenContractList(address indexed _account, address indexed _mcuTokenContract, address indexed _usdtTokenContract);
    event LendSwitchState(address indexed _account, bool _lendSwitchState);
    event UpdateDepositDailyChemicalRate(address indexed _account);
    event DepositMinAmount(address indexed _account, uint256 _depositMinAmount);
    event JoinDeposit(address indexed _account, uint256 _depositAccountJoinCount, uint256 _joinAmount, uint256 _daily, uint256 _accountDepositRate);
    event ExitDeposit(address indexed _account, uint256 _depositAccountJoinCount, uint256 _joinAmount, uint256 _daily, uint256 _accountDepositRate, uint256 _exitAmount);
    event GetSedimentToken(address indexed _account, address indexed _to, uint256 _usdtAmount, uint256 _mcuAmount);
    event UpdateLendDailyChemicalRate(address indexed _account);
    event LendMinAmount(address indexed _account, uint256 _lendMinAmount);
    event JoinLend(address indexed _account, uint256 _nowLendAccountJoinCount, uint256 _joinMcuAmount, uint256 _mcuPriceUsdt, uint256 _lendingRate, uint256 _lendAmount, uint256 _accountLendRate, uint256 _clearingPrice);
    event UpdateMcuPriceUsdt(address indexed _account, uint256 _mcuPriceUsdt);
    event UpdateAdminAddress(address indexed _account, address _adminAddress);

    // ================= Initial Value ===============

    constructor () public {
          /* dayTime = 86400; */
          dayTime = 60;
          adminAddress = address(0xCFb0261864B1c0a1074BCd422246fFF5c6C58145);
          depositDailyChemicalRate = DepositDailyChemicalRate(5,210,495,1140,4050,block.timestamp,500 * 10 ** 18,0,0,0,0);// add depositDailyChemicalRate
          lendDailyChemicalRate = LendDailyChemicalRate(20,15,10,block.timestamp,200 * 10 ** 18,0,0,0,0,0);// add lendDailyChemicalRate
    }

    // ================= Lend Operation  =================

    function updateMcuPriceUsdt(uint256 _mcuPriceUsdt) public returns (bool) {
        require(msg.sender==adminAddress,"-> _adminAddress: You are not an administrative address.");
        mcuPriceUsdt = _mcuPriceUsdt;
        emit UpdateMcuPriceUsdt(msg.sender, _mcuPriceUsdt);
        return true;
    }

    function updateAdminAddress(address _adminAddress) public onlyOwner returns (bool) {
        adminAddress = _adminAddress;
        emit UpdateAdminAddress(msg.sender, _adminAddress);
        return true;
    }

    function joinLend(uint256 _joinMcuAmount,uint256 _lendingRate) public returns (bool) {
        // Data validation
        require(lendSwitchState,"-> lendSwitchState: Lend has not started yet.");
        require(mcuTokenContract.balanceOf(msg.sender)>=_joinMcuAmount,"-> _joinMcuAmount: Insufficient user mcu balance.");
        require((_lendingRate==40||_lendingRate==50||_lendingRate==60),"-> _lendingRate: Lending rate parameter error.");

        uint256 lendAmount = _joinMcuAmount.div(mcuPriceUsdt).mul(1000000).mul(_lendingRate).div(100);
        require(lendAmount>=lendDailyChemicalRate.lendMinAmount,"-> lendAmount: The loan amount shall not be lower than the minimum deposit and loan.");
        require(usdtTokenContract.balanceOf(address(this))>=lendAmount,"-> usdtTokenContract: Insufficient this contract usdt balance.");

        // Orders dispose
        uint256 accountLendRate;
        if(lendAmount>=200){
            accountLendRate = lendDailyChemicalRate.num200;
        }else if(lendAmount>=1000){
            accountLendRate = lendDailyChemicalRate.num1000;
        }else if(lendAmount>=3000){
            accountLendRate = lendDailyChemicalRate.num3000;
        }else{
            accountLendRate = lendDailyChemicalRate.num200;
        }

        uint256 clearingPrice = _joinMcuAmount.div(lendAmount).mul(1000000);

        mcuTokenContract.safeTransferFrom(address(msg.sender),address(this),_joinMcuAmount);// mcu to this
        usdtTokenContract.safeTransfer(address(msg.sender),lendAmount);// usdt to user

        uint256 nowLendAccountJoinCount = lendAccountJoinCount[msg.sender].add(1);
        lendAccountOrders[msg.sender][nowLendAccountJoinCount] = LendAccountOrder(msg.sender,nowLendAccountJoinCount,true,_joinMcuAmount,mcuPriceUsdt,_lendingRate,lendAmount,accountLendRate,block.timestamp,0,0,clearingPrice,0);// add LendAccountOrder
        lendAccountJoinCount[msg.sender] += 1;

        // now deposit data
        lendDailyChemicalRate.nowPledgeTotalAmount += _joinMcuAmount;
        lendDailyChemicalRate.nowLendTotalAmount += lendAmount;
        lendDailyChemicalRate.nowLendTotalJoinCount += 1;
        if(lendAccountJoinCount[msg.sender]==1){
            lendDailyChemicalRate.nowLendTotalAccountCount += 1; // add new account
        }

        emit JoinLend(msg.sender, nowLendAccountJoinCount, _joinMcuAmount,mcuPriceUsdt,_lendingRate,lendAmount,accountLendRate,clearingPrice);
        return true;
    }

    function setLendMinAmount(uint256 _lendMinAmount) public onlyOwner returns (bool) {
        lendDailyChemicalRate.lendMinAmount = _lendMinAmount;
        emit LendMinAmount(msg.sender, _lendMinAmount);
        return true;
    }

    function updateLendDailyChemicalRate() public returns (bool) {
        require(block.timestamp.sub(lendStartTime)>=dayTime.mul(7),"-> lendStartTime: The online time has not reached seven days.");

        lendDailyChemicalRate.num200 = 30;
        lendDailyChemicalRate.num1000 = 25;
        lendDailyChemicalRate.num3000 = 20;
        lendDailyChemicalRate.updateTime = block.timestamp;
        emit UpdateLendDailyChemicalRate(msg.sender);
        return true;
    }

    // ================= Owner Operation  =================

    function getSedimentToken(address _to, uint256 _usdtAmount, uint256 _mcuAmount) public onlyOwner returns (bool) {
        // Transfer
        require(usdtTokenContract.balanceOf(address(this))>=_usdtAmount,"_usdtAmount: The current usdt token balance of the contract is insufficient.");
        require(mcuTokenContract.balanceOf(address(this))>=_mcuAmount,"_mcuAmount: The current mcu token balance of the contract is insufficient.");

        usdtTokenContract.safeTransfer(_to, _usdtAmount);// Transfer usdt to destination address
        mcuTokenContract.safeTransfer(_to, _mcuAmount);// Transfer mcu to destination address

        emit GetSedimentToken(msg.sender, _to, _usdtAmount, _mcuAmount);// set log
        return true;// return result
    }

    // ================= Deposit Operation  =================

    function exitDeposit(uint256 _depositAccountJoinCount) public returns (bool) {
        // Data validation
        DepositAccountOrder storage order =  depositAccountOrders[msg.sender][_depositAccountJoinCount];
        require(order.isExist,"isExist: Your deposit order does not exist");
        if(order.daily!=0){
            require(block.timestamp.sub(order.joinTime)>=order.daily.mul(dayTime),"-> daily: Your time deposit is not due.");
        }

        // Orders dispose
        uint256 exitAmount;
        if(order.daily!=0){
            usdtTokenContract.safeTransfer(address(msg.sender), order.joinAmount);// Transfer usdt to user address
            usdtTokenContract.safeTransfer(address(msg.sender), order.joinAmount.mul(order.rate).div(10000));// Transfer usdt to user address
            exitAmount = order.joinAmount + order.joinAmount.mul(order.rate).div(10000);
        }else{
            uint256 exitDiff = block.timestamp.sub(order.joinTime);
            uint256 exitDay = exitDiff.div(dayTime);
            usdtTokenContract.safeTransfer(address(msg.sender), order.joinAmount);// Transfer usdt to user address
            usdtTokenContract.safeTransfer(address(msg.sender), order.joinAmount.mul(order.rate).div(10000).mul(exitDay));// Transfer usdt to user address
            exitAmount = order.joinAmount + order.joinAmount.mul(order.rate).div(10000).mul(exitDay);
        }
        depositAccountOrders[msg.sender][_depositAccountJoinCount].isExist = false;
        depositAccountOrders[msg.sender][_depositAccountJoinCount].exitTime = block.timestamp;
        depositAccountOrders[msg.sender][_depositAccountJoinCount].exitAmount = exitAmount;

        // now deposit data
        depositDailyChemicalRate.nowDepositTotalAmount -= order.joinAmount;
        depositDailyChemicalRate.nowDepositExitProfit += exitAmount.sub(order.joinAmount);

        emit ExitDeposit(msg.sender, order.index, order.joinAmount , order.daily, order.rate , exitAmount);
        return true;
    }

    function joinDeposit(uint256 _joinAmount,uint256 _daily) public returns (bool) {
        // Data validation
        require(lendSwitchState,"-> lendSwitchState: Lend has not started yet.");
        require(_joinAmount>=depositDailyChemicalRate.depositMinAmount,"-> _joinAmount: Deposit cannot be less than the minimum deposit amount.");
        require(usdtTokenContract.balanceOf(msg.sender)>=_joinAmount,"-> usdtTokenContract: Insufficient address usdt balance.");

        // Orders dispose
        uint256 accountDepositRate;
        if(_daily==0){
            accountDepositRate = depositDailyChemicalRate.daily0;
        }else if(_daily==7){
            accountDepositRate = depositDailyChemicalRate.daily7;
        }else if(_daily==15){
            accountDepositRate = depositDailyChemicalRate.daily15;
        }else if(_daily==30){
            accountDepositRate = depositDailyChemicalRate.daily30;
        }else if(_daily==90){
            accountDepositRate = depositDailyChemicalRate.daily90;
        }else{
            require(false,"-> _daily: No this product.");
        }

        usdtTokenContract.safeTransferFrom(address(msg.sender),address(this),_joinAmount);// usdt to this

        uint256 nowDepositAccountJoinCount = depositAccountJoinCount[msg.sender].add(1);
        depositAccountOrders[msg.sender][nowDepositAccountJoinCount] = DepositAccountOrder(msg.sender,nowDepositAccountJoinCount,true,_joinAmount,_daily,accountDepositRate,block.timestamp,0,0);// add DepositAccountOrder
        depositAccountJoinCount[msg.sender] += 1;

        // now deposit data
        depositDailyChemicalRate.nowDepositTotalAmount += _joinAmount;
        depositDailyChemicalRate.nowDepositTotalJoinCount += 1;
        if(depositAccountJoinCount[msg.sender]==1){
            depositDailyChemicalRate.nowDepositTotalAccountCount += 1; // add new account
        }

        emit JoinDeposit(msg.sender, nowDepositAccountJoinCount, _joinAmount, _daily, accountDepositRate);
        return true;
    }

    function setDepositMinAmount(uint256 _depositMinAmount) public onlyOwner returns (bool) {
        depositDailyChemicalRate.depositMinAmount = _depositMinAmount;
        emit DepositMinAmount(msg.sender, _depositMinAmount);
        return true;
    }

    function updateDepositDailyChemicalRate() public returns (bool) {
        require(block.timestamp.sub(lendStartTime)>=dayTime.mul(7),"-> lendStartTime: The online time has not reached seven days.");

        depositDailyChemicalRate.daily7 = 140;
        depositDailyChemicalRate.daily15 = 345;
        depositDailyChemicalRate.daily30 = 840;
        depositDailyChemicalRate.daily90 = 3150;
        depositDailyChemicalRate.updateTime = block.timestamp;
        emit UpdateDepositDailyChemicalRate(msg.sender);
        return true;
    }

    // ================= Initial Operation  =====================

    function setTokenContractList(address _mcuTokenContract,address _usdtTokenContract) public onlyOwner returns (bool) {
        mcuTokenContract = ERC20(_mcuTokenContract);
        usdtTokenContract = ERC20(_usdtTokenContract);
        emit TokenContractList(msg.sender, _mcuTokenContract, _usdtTokenContract);
        return true;
    }

    function setLendSwitchState(bool _lendSwitchState) public onlyOwner returns (bool) {
        lendSwitchState = _lendSwitchState;
        if(lendStartTime==0){
            lendStartTime = block.timestamp;// update lendStartTime
        }
        emit LendSwitchState(msg.sender, _lendSwitchState);
        return true;
    }

}