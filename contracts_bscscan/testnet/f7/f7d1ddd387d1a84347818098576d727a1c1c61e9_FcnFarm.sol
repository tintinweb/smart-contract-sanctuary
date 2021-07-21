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

    // LuckyJackpot
    uint256 private decimals = 18;
    uint256 public joinFarmAmountLimit = 1000000000 * 10 ** decimals;// 1 billion FCN : 10_0000_0000
    uint256 private joinLuckyJackpotLimit = 5000000000 * 10 ** decimals;// 5 billion FCN : 50_0000_0000
    uint256 public joinFarmTotalCount;
    mapping(address => bool) public isJoinFarmSuccess;
    mapping(uint256 => JoinFarmOrder) public joinFarmOrders;
    struct JoinFarmOrder {
        uint256 index;
        address account;
        bool isExist;
        uint256 joinFarmTime;
        uint256 earningsLuckyJackpot;
        uint256 receiveLuckyJackpotTotal;
        uint256 earningsCashDividends;
        uint256 receiveCashDividendsTotal;
    }
    uint256 private randNonce = 0;
    mapping(uint256 => address) public luckyJackpotAddress;

    // Events
    event CreateFcnTokenContract(address indexed _account, address indexed _fcnTokenContract);
    event FarmSwitchState(address indexed _account, bool _setFarmSwitchState);
    event FarmDistribute(address indexed _account,uint256 _allocableQuantity);
    event JoinFarm(address indexed _account,uint256 _joinFarmTotalCount);
    event ToBlackHoleFarm(address indexed _account,uint256 _nowBlackHole);
    event ToLuckyJackpotFarm(address indexed _account,uint256 _nowLuckyJackpot);

    // ================= Initial Value ===============

    constructor () public {}

    // ================= Farm Operation  =================

    function toRandomNumber100() public returns (bool) {
        uint256 randomNumberInt;
        for(uint256 i=1;i<=100;i++){
            randomNumberInt = randomNumber();// 1-10 int
            randomNumberInt = randomNumberInt.mul(10000).mod(5).add(1);  // 10000-100000 mol 5 ==> 1-5
        }
        return true;
    }

    function toLuckyJackpot() public returns (bool) {
        // Data validation
        require(farmSwitchState,"-> farmSwitchState: Farm has not started yet.");
        require(nowLuckyJackpot>0,"-> nowLuckyJackpot: The current available amount is 0.");
        require(joinFarmTotalCount>0,"-> joinFarmTotalCount: The total number of people joining the FARM must be greater than 0.");

        // Calculation of 1
        uint256 luckyJackpot5billionCount = 0;
        uint256 luckyJackpot1billionCount = 0;
        for(uint256 i=1;i<=joinFarmTotalCount;i++){
            if(fcnErc20Contract.balanceOf(joinFarmOrders[i].account)>=joinFarmAmountLimit){
                luckyJackpot1billionCount += 1;
                luckyJackpotAddress[luckyJackpot1billionCount] = joinFarmOrders[i].account;
            }
            if(fcnErc20Contract.balanceOf(joinFarmOrders[i].account)>=joinLuckyJackpotLimit){
                luckyJackpot5billionCount += 1;
            }
        }

        // Calculation 2
        if(luckyJackpot5billionCount<=0){
            fcnErc20Contract.safeTransfer(address(0),nowLuckyJackpot);// Transfer fnc to blackHole address
            nowLuckyJackpot = 0;
        }else{
            uint256 randomNumberInt;
            for(uint256 j=1;j<=luckyJackpot5billionCount;j++){
                randomNumberInt = randomNumber();// 0-9 into
                randomNumberInt = randomNumberInt.mul(10000).mod(luckyJackpot5billionCount).add(1);  // 10000-100000 mol 5 ==> 1-5
                fcnErc20Contract.safeTransfer(luckyJackpotAddress[j],nowLuckyJackpot.div(luckyJackpot5billionCount));// Transfer fnc to lucky address
            }
        }

        emit ToLuckyJackpotFarm(msg.sender,nowLuckyJackpot);// set log
        return true;// return result
    }

    function joinFarm() public returns (bool) {
        // Data validation
        require(farmSwitchState,"-> farmSwitchState: Farm has not started yet.");
        require(isJoinFarmSuccess[msg.sender]==false,"-> isJoinFarmSuccess: This address is already participating in FARM.");
        require(fcnErc20Contract.balanceOf(msg.sender)>=joinFarmAmountLimit,"-> joinFarmAmountLimit: Your holdings are not up to par.");

        joinFarmTotalCount += 1;// Total number + 1

        joinFarmOrders[joinFarmTotalCount] = JoinFarmOrder(joinFarmTotalCount,msg.sender,true,block.timestamp,0,0,0,0);// add JoinFarmOrder

        emit JoinFarm(msg.sender,joinFarmTotalCount);// set log
        return true;// return result
    }

    function toBlackHoleFarm() private returns (bool) {
        // Data validation
        require(farmSwitchState,"-> farmSwitchState: Farm has not started yet.");
        require(nowBlackHole>0,"-> nowBlackHole: The current available amount is 0.");

        // Calculation processing
        fcnErc20Contract.safeTransfer(address(0),nowBlackHole);// Transfer fnc to blackHole address
        nowBlackHole = 0;

        emit ToBlackHoleFarm(msg.sender,nowBlackHole);// set log
        return true;// return result
    }

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
        farmStartTime += block.timestamp;

        // toBlackHoleFarm()
        toBlackHoleFarm();

        emit FarmDistribute(msg.sender,allocableQuantity);// set log
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

    // Random return 1-10 integer
    function randomNumber() private returns(uint256) {
        uint256 rand = uint256(keccak256(abi.encodePacked(now, msg.sender, randNonce))) % 10;
        randNonce++;
        return rand.add(1);
    }

}