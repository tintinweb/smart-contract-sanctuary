pragma solidity 0.5.8;

import { Ownable } from "./Ownable.sol" ;
import "./SafeMath.sol";
import "./SafeERC20.sol";

contract FcnToken {
    function getTradeFeeTotal() public view returns (uint256);
}

contract FcnFarm is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for ERC20;

    // Farm Basis
    uint256 private ratioLuckyJackpot = 20;
    uint256 private ratioCashDividends = 50;
    uint256 private ratioRewardsCommunity = 20;
    uint256 private ratioBlackHole = 10;// Distribution ratio

    uint256 public nowLuckyJackpot;
    uint256 public nowCashDividends;
    uint256 public nowRewardsCommunity;
    uint256 public nowBlackHole;// Current to be allocated

    bool public farmSwitchState = false;
    uint256 public farmStartTime;
    uint256 public farmTradeFee;// Total service charge allocated

    // Farm Contract
    ERC20 private fcnErc20Contract;
    FcnToken public fcnTokenContract;

    // Events
    event CreateFcnTokenContract(address indexed _account, address indexed _fcnTokenContract);
    event FarmSwitchState(address indexed _account, bool _setFarmSwitchState);
    event FarmDistribute(address indexed _account,uint256 _allocableQuantity);
    event ToBlackHoleFarm(address indexed _account,uint256 _nowBlackHole);

    // ================= Initial Value ===============

    constructor () public {}

    // ================= Farm Operation  =================

    function farmDistribute() public returns (bool) {
        // Data validation
        require(farmSwitchState,"-> farmSwitchState: Farm has not started yet.");
        require(block.timestamp.sub(farmStartTime)>10*7,"-> farmStartTime: farm time not reached.");

        uint256 allocableQuantity = fcnTokenContract.getTradeFeeTotal().sub(farmTradeFee);
        require(allocableQuantity>100,"-> allocableQuantity: The current allocable quantity is 0.");

        // Current to be allocated
        nowLuckyJackpot += allocableQuantity.mul(ratioLuckyJackpot).div(100);
        nowCashDividends += allocableQuantity.mul(ratioCashDividends).div(100);
        nowRewardsCommunity += allocableQuantity.mul(ratioRewardsCommunity).div(100);
        nowBlackHole += allocableQuantity.mul(ratioBlackHole).div(100);

        farmTradeFee += allocableQuantity;// add farmTradeFee

        // toBlackHoleFarm()
        toBlackHoleFarm();

        emit FarmDistribute(msg.sender,allocableQuantity);// set log
        return true;// return result
    }

    function toBlackHoleFarm() public returns (bool) {
        // Data validation
        require(farmSwitchState,"-> farmSwitchState: Farm has not started yet.");
        require(nowBlackHole>0,"-> nowBlackHole: The current available amount is 0.");

        // Calculation processing
        fcnErc20Contract.safeTransfer(address(0),nowBlackHole);// Transfer fnc to blackHole address
        nowBlackHole = 0;

        emit ToBlackHoleFarm(msg.sender,nowBlackHole);// set log
        return true;// return result
    }

    // ================= Initial Operation  =================

    function createFcnTokenContract(address _fcnTokenContract) public onlyOwner returns (bool) {
        fcnErc20Contract = ERC20(_fcnTokenContract);
        fcnTokenContract = FcnToken(_fcnTokenContract);
        emit CreateFcnTokenContract(msg.sender, _fcnTokenContract);
        return true;// return result
    }

    function setFarmSwitchState(bool _setFarmSwitchState) public onlyOwner returns (bool) {
        farmSwitchState = _setFarmSwitchState;
        if(farmStartTime==0){
              farmStartTime = block.timestamp;// update farmStartTime
        }
        emit FarmSwitchState(msg.sender,_setFarmSwitchState);
        return true;
    }

    // ================= Contract Query  =================

    function getTradeFeeTotal() public view returns (uint256) {
        return fcnTokenContract.getTradeFeeTotal();
    }

}