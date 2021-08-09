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

    // ERC20 Token
    ERC20 public mcuTokenContract;
    ERC20 public usdtTokenContract;

    // Events
    event TokenContractList(address indexed _account, address indexed _mcuTokenContract, address indexed _usdtTokenContract);
    event LendSwitchState(address indexed _account, bool _lendSwitchState);

    // Deposit
    DepositDailyChemicalRate public depositDailyChemicalRate;
    struct DepositDailyChemicalRate {
        uint256 daily7;
        uint256 daily15;
        uint256 daily30;
        uint256 daily90;
    }

    // ================= Initial Value ===============

    constructor () public {
          depositDailyChemicalRate = DepositDailyChemicalRate(210,495,1140,4050);// add depositDailyChemicalRate
    }

    // ================= Lend Operation  =================
    // ================= Deposit Operation  =================

    // ================= Pledge Query  =====================

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