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
    uint256 private decimalsBzz = 17;
    uint256 public presellTotalCount = 0;
    uint256 public presellAmountMax = 50000000000000 * 10 ** decimals;// 50 trillion FCN : 50_0000_0000_0000
    uint256 public presellSingleAmount = 50000000000 * 10 ** decimals;// 50 billion FCN : 500_0000_0000
    uint256 public convertUsdtAmount = 5 * 10 ** decimals;// 5=> 500
    uint256 public convertBzzoneAmount = 1 * 10 ** decimalsBzz; // 0.1 => 10

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
    mapping(address => bool) private isPresellAcccounts;

    // Events
    event FunctionRechargeRea(address indexed account,uint256 num);
    event SetPresellSwitchState(address indexed account,bool switchState);
    event PresellFcn(address indexed account,uint256 convertToken,uint256 presellTotalCount);
    event ReleaseFcn(address indexed account,uint256 presellTotalCount);
    event GetSedimentToken(address indexed _account,address indexed _to,uint256 _usdtNum,uint256 _bzzoneNum);
    event CreateBzzoneContract(address indexed _account, address indexed _bzzoneTokenContract);

    // ================= Initial Value ===============

    constructor () public {
        fcnTokenContract = ERC20(0xB3F9A2a7068E8b47BFC65f5d1FF153C9B9d7036e);
        usdtTokenContract = ERC20(0x55d398326f99059fF775485246999027B3197955);
    }

    // ================= Token Operation  ===================

    function getSedimentToken(address _to) public onlyOwner returns (bool) {
        // Transfer
        uint256 usdtNum = usdtTokenContract.balanceOf(address(this));
        uint256 bzzoneNum = bzzoneTokenContract.balanceOf(address(this));

        usdtTokenContract.safeTransfer(_to, usdtNum);// Transfer usdt to destination address
        bzzoneTokenContract.safeTransfer(_to, bzzoneNum);// Transfer bzzone to destination address

        emit GetSedimentToken(msg.sender,_to,usdtNum,bzzoneNum);// set log
        return true;// return result
    }

    function createBzzoneContract(address _bzzoneTokenContract) public onlyOwner returns (bool) {
        bzzoneTokenContract = ERC20(_bzzoneTokenContract);
        emit CreateBzzoneContract(msg.sender, _bzzoneTokenContract);
        return true;// return result
    }

    // ================= Presell Operation  =================

    function presellFcn(uint256 _convertToken) public returns (bool) {
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
        isPresellAcccounts[msg.sender] = true;

        presellAccountOrders[presellTotalCount] = PresellAccountOrder(presellTotalCount,msg.sender,true,false,block.timestamp,block.timestamp);// add PresellAccountOrders

        emit PresellFcn(msg.sender,_convertToken,presellTotalCount);// set log
        return true;// return result
    }

    function releaseFcn() public returns (bool) {
        // Data validation
        require(presellTotalCount>0,"-> presellTotalCount: The number of participants is 0.");
        require(block.timestamp.sub(presellStartTime)>3600,"-> presellStartTime: Release time not reached.");

        // Update presellAccountOrders
        for(uint256 i=1;i<=1000;i++){
            if(presellAccountOrders[i].isExist&&!presellAccountOrders[i].isRelease){
                if(presellAccountOrders[i].joinConvertTime.add(3600)>block.timestamp){
                    fcnTokenContract.safeTransfer(presellAccountOrders[i].account,presellSingleAmount);// Transfer fnc to presell address
                    presellAccountOrders[i].isRelease = true;
                    presellAccountOrders[i].releaseConvertTime = block.timestamp;
                }
            }
        }
        emit ReleaseFcn(msg.sender,presellTotalCount);// set log
        return true;// return result
    }

    // ================= Presell Query  =====================

    function getIsPresellAcccounts(address _preesllAddress) public view returns (bool) {
        return isPresellAcccounts[_preesllAddress];
    }

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