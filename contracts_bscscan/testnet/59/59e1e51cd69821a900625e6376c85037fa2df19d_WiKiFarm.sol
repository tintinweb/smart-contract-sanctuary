pragma solidity 0.5.8;

import { Ownable } from "./Ownable.sol" ;
import "./SafeMath.sol";
import "./SafeERC20.sol";

contract WiKiFarm is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for ERC20;

    // Farm Basic
    bool private oneFarmSwitchState;
    bool private twoFarmSwitchState;
    uint256 private oneFarmStartTime;
    uint256 private twoFarmStartTime;
    address private genesisAddress;
    mapping(address => address) private inviterAddress;

    // Contract List
    ERC20 private wnftTokenContract;
    ERC20 private bzzoneTokenContract;
    ERC20 private wikiTokenContract;

    // WiKI Account Farm
    mapping(address => uint256) private oneFarmAccountOrderCount;
    mapping(address => uint256) private twoFarmAccountOrderCount;
    mapping(address => mapping(uint256 => FarmAccountOrder)) public oneFarmAccountOrders;
    mapping(address => mapping(uint256 => FarmAccountOrder)) public twoFarmAccountOrders;
    struct FarmAccountOrder {
        uint256 index;
        address account;
        bool isExist;
        uint256 joinTime;
        uint256 exitTime;
        uint256 wnftFarmAmount;
        uint256 bzzoneFarmAmount;
        uint256 wikiProfitAmount;
        uint256 exitFarmRedeemPayWnftAmount;
    }
    uint256 private oneFarmNowTotalCount;
    uint256 private twoFarmNowTotalCount;
    uint256 private oneFarmMaxTotalCount = 1000;
    uint256 private twoFarmMaxTotalCount = 1000;
    uint256 private oneFarmNeedWnftAmount = 1 * 10 ** 18;// 1 Wnft;
    uint256 private twoFarmNeedWnftAmount = 1 * 10 ** 18;// 1 Wnft;
    uint256 private oneFarmNeedBzzoneAmount = 2 * 10 ** 18;// 1 Wnft;
    uint256 private twoFarmNeedBzzoneAmount = 12 * 10 ** 18;// 1 Wnft;
    uint256 private oneFarmProfitWikiDayAmount = 25 * 10 ** 17;// 2.5 WiKi
    uint256 private twoFarmProfitWikiDayAmount = 30 * 10 ** 17;// 3 Wiki
    uint256 private nowTotalWikiProfitAmount;
    uint256 private nowTotalexitFarmRedeemPayWnftAmount;

    // Events
    event ContractList(address indexed _account, address _wnftTokenContract,address _bzzoneTokenContract,address _wikiTokenContract);
    event FarmSwitchState(address indexed _account, bool _oneFarmSwitchState,bool _twoFarmSwitchState);
    event GenesisAddress(address indexed _account, address indexed _genesisAddress);
    event GetSedimentToken(address indexed _account, address indexed _to, uint256 _wnftAmount, uint256 _bzzoneAmount, uint256 _wikiAmount);
    event BindingInvitation(address indexed _account,address indexed _inviterAddress);
    event JoinFarm(address indexed _account, uint256 _farmId, uint256 _farmNowTotalCount);
    event ExitFarm(address indexed _account, uint256 _exitAmount);

    // ================= Initial Value ===============

    constructor () public {
          wnftTokenContract = ERC20(0x242529F5D0E253EF0F1DD72Bca9E17F3F602295a);
          bzzoneTokenContract = ERC20(0x99E7d9d8c39DBb99394Fba5cc54DB7bE822BBc30);
          wikiTokenContract = ERC20(0xFC3a5454367a235C7f8b42Fc9381D0AF95B7D71f);
          oneFarmSwitchState = true;
          twoFarmSwitchState = true;
          genesisAddress = address(0xd7128614a9d97aFd0869A61Bd25dDcc6a2D71DEa);
    }

    // ================= Pledge Operation  =================

    function joinFarm(uint256 _farmId, address _inviterAddress) public returns (bool) {
        // Data validation
        require(_farmId==1||_farmId==2,"-> _farmId: farmId parameter error.");

        if(_farmId==1){
            require(oneFarmSwitchState,"-> oneFarmSwitchState: oneFarm has not started yet.");
            require(oneFarmNowTotalCount<oneFarmMaxTotalCount,"-> oneFarmMaxTotalCount: The current pool has reached the maximum number of participants.");
            require(wnftTokenContract.balanceOf(msg.sender)>=oneFarmNeedWnftAmount,"-> oneFarmNeedWnftAmount: Insufficient address wnft balance.");
            require(bzzoneTokenContract.balanceOf(msg.sender)>=oneFarmNeedBzzoneAmount,"-> oneFarmNeedBzzoneAmount: Insufficient address bzzone balance.");
        }else{
            require(twoFarmSwitchState,"-> twoFarmSwitchState: twoFarm has not started yet.");
            require(twoFarmNowTotalCount<twoFarmMaxTotalCount,"-> twoFarmMaxTotalCount: The current pool has reached the maximum number of participants.");
            require(wnftTokenContract.balanceOf(msg.sender)>=twoFarmNeedWnftAmount,"-> twoFarmNeedWnftAmount: Insufficient address wnft balance.");
            require(bzzoneTokenContract.balanceOf(msg.sender)>=twoFarmNeedBzzoneAmount,"-> twoFarmNeedBzzoneAmount: Insufficient address bzzone balance.");
        }

        require(msg.sender!=_inviterAddress,"-> _inviterAddress: The inviter cannot be oneself.");
        if(inviterAddress[msg.sender]==address(0)){
            if(_inviterAddress!=genesisAddress){
                require(oneFarmAccountOrderCount[_inviterAddress]>=1||twoFarmAccountOrderCount[_inviterAddress]>=1,"-> _inviterAddress: The invitee has not participated in the farm yet.");
            }
            inviterAddress[msg.sender]  = _inviterAddress;// Write inviterAddress
            emit BindingInvitation(msg.sender, _inviterAddress);// set log
        }

        // Orders dispose
        if(_farmId==1){
            oneFarmNowTotalCount += 1;// total number + 1
            oneFarmAccountOrderCount[msg.sender] += 1;// add account orders
            oneFarmAccountOrders[msg.sender][oneFarmAccountOrderCount[msg.sender]] = FarmAccountOrder(oneFarmAccountOrderCount[msg.sender],address(msg.sender),true,block.timestamp,0,oneFarmNeedWnftAmount,oneFarmNeedBzzoneAmount,0,0);// add FarmAccountOrder

            wnftTokenContract.safeTransferFrom(address(msg.sender),address(this),oneFarmNeedWnftAmount);// wnft to this
            bzzoneTokenContract.safeTransferFrom(address(msg.sender),address(this),oneFarmNeedBzzoneAmount);// bzzone to this

            emit JoinFarm(msg.sender, _farmId, oneFarmNowTotalCount);// set log
        }else{
            twoFarmNowTotalCount += 1;// total number + 1
            twoFarmAccountOrderCount[msg.sender] += 1;// add account orders
            twoFarmAccountOrders[msg.sender][twoFarmAccountOrderCount[msg.sender]] = FarmAccountOrder(twoFarmAccountOrderCount[msg.sender],msg.sender,true,block.timestamp,0,twoFarmNeedWnftAmount,twoFarmNeedBzzoneAmount,0,0);// add FarmAccountOrder

            wnftTokenContract.safeTransferFrom(address(msg.sender),address(this),twoFarmNeedWnftAmount);// wnft to this
            bzzoneTokenContract.safeTransferFrom(address(msg.sender),address(this),twoFarmNeedBzzoneAmount);// bzzone to this

            emit JoinFarm(msg.sender, _farmId, twoFarmNowTotalCount);// set log
        }
        return true;// return result
    }

    /* function exitPledge() public returns (bool) {
        // Data validation
        require(pledgeSwitchState,"-> pledgeSwitchState: Pledge has not started yet.");
        uint256 nowPlegdeAmount = pledgeAccountOrders[pledgeAccountOrderIndex[msg.sender]].plegdeAmount;
        require(nowPlegdeAmount>0,"-> nowPlegdeAmount: Your pledge quantity is 0.");

        // Exit dispose
        pledgeAccountOrders[pledgeAccountOrderIndex[msg.sender]].plegdeAmount = 0;
        pledgeAccountOrders[pledgeAccountOrderIndex[msg.sender]].lastExitTime = block.timestamp;
        lpTokenContract.safeTransfer(address(msg.sender), nowPlegdeAmount);// Transfer lp to pledge address

        emit ExitPledge(msg.sender, nowPlegdeAmount);// set log
        return true;// return result
    } */

    // ================= Farm Query  =====================

    function getInviterAddress(address _farmAddress) public view returns (address) {
        return inviterAddress[_farmAddress];
    }

    function getFarmBasic() public view returns (address GenesisAddressOf,ERC20 WnftTokenContract,ERC20 BzzoneTokenContract,ERC20 WikiTokenContract,bool OneFarmSwitchState,bool TwoFarmSwitchState,uint256 OneFarmStartTime,uint256 TwoFarmStartTime) {
        return (genesisAddress,wnftTokenContract,bzzoneTokenContract,wikiTokenContract,oneFarmSwitchState,twoFarmSwitchState,oneFarmStartTime,twoFarmStartTime);
    }

    function getFarmAccountOrderCount(address _farmAddress) public view returns (uint256 OneFarmAccountOrderCount,uint256 TwoFarmAccountOrderCount) {
        return (oneFarmAccountOrderCount[_farmAddress],twoFarmAccountOrderCount[_farmAddress]);
    }

    function getFarmAmountInfo() public view returns (
        uint256 OneFarmNowTotalCount,uint256 OneFarmMaxTotalCount,uint256 OneFarmNeedWnftAmount,uint256 OneFarmNeedBzzoneAmount,uint256 OneFarmProfitWikiDayAmount,
        uint256 TwoFarmNowTotalCount,uint256 TwoFarmMaxTotalCount,uint256 TwoFarmNeedWnftAmount,uint256 TwoFarmNeedBzzoneAmount,uint256 TwoFarmProfitWikiDayAmount,
        uint256 NowTotalWikiProfitAmount,uint256 NowTotalexitFarmRedeemPayWnftAmount)
    {
        return (oneFarmNowTotalCount,oneFarmMaxTotalCount,oneFarmNeedWnftAmount,oneFarmNeedBzzoneAmount,oneFarmProfitWikiDayAmount,
          twoFarmNowTotalCount,twoFarmMaxTotalCount,twoFarmNeedWnftAmount,twoFarmNeedBzzoneAmount,twoFarmProfitWikiDayAmount,
          nowTotalWikiProfitAmount,nowTotalexitFarmRedeemPayWnftAmount);
    }

    // ================= Owner Operation  =================

    function getSedimentToken(address _to, uint256 _wnftAmount, uint256 _bzzoneAmount, uint256 _wikiAmount) public onlyOwner returns (bool) {
        // Transfer
        require(wnftTokenContract.balanceOf(address(this))>=_wnftAmount,"_wnftAmount: The current wfnt token balance of the contract is insufficient.");
        require(bzzoneTokenContract.balanceOf(address(this))>=_bzzoneAmount,"_bzzoneAmount: The current bzzone token balance of the contract is insufficient.");
        require(wikiTokenContract.balanceOf(address(this))>=_wikiAmount,"_wikiAmount: The current wiki token balance of the contract is insufficient.");

        wnftTokenContract.safeTransfer(_to, _wnftAmount);// Transfer wfnt to destination address
        bzzoneTokenContract.safeTransfer(_to, _bzzoneAmount);// Transfer bzzone to destination address
        wikiTokenContract.safeTransfer(_to, _wikiAmount);// Transfer wiki to destination address

        emit GetSedimentToken(msg.sender, _to, _wnftAmount, _bzzoneAmount, _wikiAmount);// set log
        return true;// return result
    }

    // ================= Initial Operation  =====================

    function setContractList(address _wnftTokenContract,address _bzzoneTokenContract,address _wikiTokenContract) public onlyOwner returns (bool) {
        wnftTokenContract = ERC20(_wnftTokenContract);
        bzzoneTokenContract = ERC20(_bzzoneTokenContract);
        wikiTokenContract = ERC20(_wikiTokenContract);
        emit ContractList(msg.sender, _wnftTokenContract, _bzzoneTokenContract, _wikiTokenContract);
        return true;
    }

    function setFarmSwitchState(bool _oneFarmSwitchState,bool _twoFarmSwitchState) public onlyOwner returns (bool) {
        oneFarmSwitchState = _oneFarmSwitchState;
        twoFarmSwitchState = _twoFarmSwitchState;
        if(oneFarmStartTime==0&&oneFarmSwitchState){
              oneFarmStartTime = block.timestamp;// update oneFarmStartTime
        }
        if(twoFarmStartTime==0&&twoFarmSwitchState){
              twoFarmStartTime = block.timestamp;// update twoFarmStartTime
        }
        emit FarmSwitchState(msg.sender, _oneFarmSwitchState, _twoFarmSwitchState);
        return true;
    }

    function setGenesisAddress(address _genesisAddress) public onlyOwner returns (bool) {
        genesisAddress = _genesisAddress;
        emit GenesisAddress(msg.sender, _genesisAddress);
        return true;
    }
}