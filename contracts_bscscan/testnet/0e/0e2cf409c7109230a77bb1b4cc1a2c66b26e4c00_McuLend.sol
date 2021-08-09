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
    /* uint256 private dayTime = 86400; */
    uint256 private dayTime = 600;

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
    }
    uint256 public depositMinAmount;
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
    mapping(address => uint256) public depositAccountJoinCount;

    // Events
    event TokenContractList(address indexed _account, address indexed _mcuTokenContract, address indexed _usdtTokenContract);
    event LendSwitchState(address indexed _account, bool _lendSwitchState);
    event UpdateDepositDailyChemicalRate(address indexed _account);
    event DepositMinAmount(address indexed _account, uint256 _depositMinAmount);
    event JoinDeposit(address indexed _account, uint256 _depositAccountJoinCount, uint256 _joinAmount, uint256 _daily, uint256 _accountDepositRate);
    event ExisDeposit(address indexed _account, uint256 _depositAccountJoinCount, uint256 _joinAmount, uint256 _daily, uint256 _accountDepositRate, uint256 _exitAmount);

    // ================= Initial Value ===============

    constructor () public {
          depositDailyChemicalRate = DepositDailyChemicalRate(5,210,495,1140,4050,block.timestamp);// add depositDailyChemicalRate
          depositMinAmount = 500 * 10 ** 18;
    }

    // ================= Lend Operation  =================

    // ================= Deposit Operation  =================

    function exisDeposit(uint256 _depositAccountJoinCount) public returns (bool) {
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

        emit ExisDeposit(msg.sender, order.index, order.joinAmount , order.daily, order.rate , exitAmount);
        return true;
    }

    function joinDeposit(uint256 _joinAmount,uint256 _daily) public returns (bool) {
        // Data validation
        require(lendSwitchState,"-> lendSwitchState: Lend has not started yet.");
        require(_joinAmount>=depositMinAmount,"-> _joinAmount: The number of deposit added must be greater than zero.");
        require(usdtTokenContract.balanceOf(msg.sender)>=_joinAmount,"-> usdtTokenContract: Insufficient address usdt balance.");
        if(_daily!=0&&_daily!=7&&_daily!=15&&_daily!=30&&_daily!=90){
            require(false,"-> _daily: No this product.");
        }

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
        }

        usdtTokenContract.safeTransferFrom(address(msg.sender),address(this),_joinAmount);// usdt to this

        uint256 nowDepositAccountJoinCount = depositAccountJoinCount[msg.sender].add(1);
        depositAccountOrders[msg.sender][nowDepositAccountJoinCount] = DepositAccountOrder(msg.sender,nowDepositAccountJoinCount,true,_joinAmount,_daily,accountDepositRate,block.timestamp,0,0);// add DepositAccountOrder
        depositAccountJoinCount[msg.sender] += 1;

        emit JoinDeposit(msg.sender, nowDepositAccountJoinCount, _joinAmount, _daily, accountDepositRate);
        return true;
    }

    function setDepositMinAmount(uint256 _depositMinAmount) public onlyOwner returns (bool) {
        depositMinAmount = _depositMinAmount;
        emit DepositMinAmount(msg.sender, _depositMinAmount);
        return true;
    }

    function updateDepositDailyChemicalRate() public onlyOwner returns (bool) {
        require(block.timestamp.sub(lendStartTime)>=604800,"-> lendStartTime: The online time has not reached seven days.");

        depositDailyChemicalRate.daily7 = 140;
        depositDailyChemicalRate.daily15 = 345;
        depositDailyChemicalRate.daily30 = 840;
        depositDailyChemicalRate.daily90 = 315;
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