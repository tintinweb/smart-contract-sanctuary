pragma solidity 0.5.8;

import { Ownable } from "./Ownable.sol" ;
import "./SafeMath.sol";
import "./SafeERC20.sol";

contract FcnPresell is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for ERC20;

    // Presell Basic
    bool public presellSwitchState = false;
    uint256 public presellStartTime;
    uint256 private decimals = 18;
    uint256 public presellTotalCount = 0;
    uint256 public presellAmountMax = 50000000000000 * 10 ** decimals;// 50 trillion FCN : 50_0000_0000_0000
    uint256 public presellSingleAmount = 50000000000 * 10 ** decimals;// 50 billion FCN : 500_0000_0000
    uint256 private convertUsdtAmount = 500 * 10 ** decimals;
    uint256 private convertBzzoneAmount = 10 * 10 ** decimals;

    // Presell Token
    ERC20 public fcnTokenContract;
    ERC20 public usdtTokenContract;
    ERC20 public bzzoneTokenContract;

    // Presell Account
    mapping(uint256 => PresellAccountOrder) public presellAccountOrders;
    struct PresellAccountOrder {
        uint256 index;
        address account;
        bool isExist;
        bool isRelease;
        uint256 joinConvertTime;
        uint256 releaseConvertTime;
    }

    // Events
    event FunctionRechargeRea(address indexed account,uint256 num);
    event SetPresellSwitchState(address indexed account,bool switchState);
    event PresellFcn(address indexed account,uint256 convertToken,uint256 presellTotalCount);
    event ReleaseFcn(address indexed account,uint256 presellTotalCount);

    // ================= Initial Value ===============

    constructor () public {
        fcnTokenContract = ERC20(0x3556D913A1813e5F6FCb9b4792643390FA17155b);
        usdtTokenContract = ERC20(0xd5aebC243cc1d7F25c9c71CCD572ABe28C5a8F8b);
        bzzoneTokenContract = ERC20(0x1abe45f37Ba3Eb61ceaC6D3d347e66F43FAaC95e);
    }

    // ================= Presell Operation  =================

    function presellFcn(uint _convertToken) public returns (bool) {
        // Data validation
        require(presellSwitchState,"-> presellSwitchState: Pre sale has not started yet.");
        require(presellTotalCount<1000,"-> presellTotalCount: Sold out.");// Up to 1000 pre-sale
        require(_convertToken==1||_convertToken==2,"-> _convertToken: Exchange currency not supported.");// 1=Usdt  2=Bzzone

        // Balance processing
        if(_convertToken==1){
            require(usdtTokenContract.balanceOf(msg.sender)>=convertUsdtAmount,"-> convertUsdtAmount: Insufficient address usdt balance.");
            usdtTokenContract.safeTransferFrom(address(msg.sender),address(this),convertUsdtAmount);
        }else{
            require(bzzoneTokenContract.balanceOf(msg.sender)>=convertBzzoneAmount,"-> convertBzzoneAmount: Insufficient address bzzone balance.");
            bzzoneTokenContract.safeTransferFrom(address(msg.sender),address(this),convertBzzoneAmount);
        }

        presellTotalCount += 1;// Total number + 1

        presellAccountOrders[presellTotalCount] = PresellAccountOrder(presellTotalCount,msg.sender,true,false,block.timestamp,block.timestamp);// add PresellAccountOrders

        emit PresellFcn(msg.sender,_convertToken,presellTotalCount);// set log
        return true;// return result
    }

    function releaseFcn() public returns (bool) {
        // Data validation
        require(presellTotalCount>0,"-> presellTotalCount: The number of participants is 0.");
        require(block.timestamp.sub(presellStartTime)>100*7,"-> presellStartTime: Release time not reached.");

        // Update presellAccountOrders
        for(uint256 i=1;i<=1000;i++){
            if(presellAccountOrders[i].isExist&&!presellAccountOrders[i].isRelease){
                if(presellAccountOrders[i].joinConvertTime.add(700)>block.timestamp){
                    fcnTokenContract.safeTransfer(presellAccountOrders[i].account,presellSingleAmount);// Transfer rea to destination address
                    presellAccountOrders[i].isRelease = true;
                    presellAccountOrders[i].releaseConvertTime = block.timestamp;
                }
            }
        }
        emit ReleaseFcn(msg.sender,presellTotalCount);// set log
        return true;// return result
    }

    // ================= Presell Query  =====================

    function presellTotalCount1() public view returns (uint256) {
        return presellTotalCount;
    }

    /* function presellAccountOrder(uint256 _index) public view returns (PresellAccountOrder) {
        return presellAccountOrders[_index];
    } */

    // ================= Initial Operation  =====================

    function functionRechargeFcn() public returns (bool) {
        fcnTokenContract.safeTransferFrom(address(msg.sender),address(this),presellAmountMax);// Transfer the owner fcn to the contract
        emit FunctionRechargeRea(msg.sender,presellAmountMax);// set log
        return true;// return result
    }

    function setPresellSwitchState(bool _setPresellSwitchState) public onlyOwner returns (bool) {
        presellSwitchState = _setPresellSwitchState;
        if(presellStartTime==0){
              presellStartTime = block.timestamp;// update presellStartTime
        }
        emit SetPresellSwitchState(msg.sender,_setPresellSwitchState);
        return true;
    }

}