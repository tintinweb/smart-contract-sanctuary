pragma solidity 0.5.8;

import { Ownable } from "./Ownable.sol" ;
import "./SafeMath.sol";
import "./SafeERC20.sol";

contract PledgeFarm is Ownable {
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

    // Pledge Account Farm
    uint256 public oneFarmTotalCount = 0;
    uint256 public twoFarmTotalCount = 0;
    mapping(address => uint256) private oneFarmAccountOrderIndex;
    mapping(address => uint256) private twoFarmAccountOrderIndex;
    mapping(uint256 => FarmAccountOrder) public oneFarmAccountOrders;
    mapping(uint256 => FarmAccountOrder) public twoPledgeAccountOrders;
    struct FarmAccountOrder {
        uint256 index;
        address account;
        bool isExist;
        uint256 joinTime;
        uint256 exitTime;
        uint256 wnftFarmAmount;
        uint256 bzzoneFarmAmount;
        uint256 wikiProfitAmount;
    }

    // Events
    event ContractList(address indexed _account, address _wnftTokenContract,address _bzzoneTokenContract,address _wikiTokenContract);
    event FarmSwitchState(address indexed _account, bool _oneFarmSwitchState,bool _twoFarmSwitchState);
    event GenesisAddress(address indexed _account, address indexed _genesisAddress);
    event JoinPledge(address indexed _account, uint256 _joinAmount);
    event ExitPledge(address indexed _account, uint256 _exitAmount);
    event BindingInvitation(address indexed _account,address indexed _inviterAddress);

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

    /* function joinPledge(uint256 _joinAmount, address _inviterAddress) public returns (bool) {
        // Data validation
        require(pledgeSwitchState,"-> pledgeSwitchState: Pledge has not started yet.");
        require(_joinAmount>0,"-> _joinAmount: The number of pledges added must be greater than zero.");
        require(lpTokenContract.balanceOf(msg.sender)>=_joinAmount,"-> lpTokenContract: Insufficient address lp balance.");
        require(msg.sender!=_inviterAddress,"-> _inviterAddress: The inviter cannot be oneself.");

        // Orders dispose
        if(pledgeAccountOrderIndex[msg.sender]>=1){// exist orders
            pledgeAccountOrders[pledgeAccountOrderIndex[msg.sender]].plegdeAmount += _joinAmount;
            pledgeAccountOrders[pledgeAccountOrderIndex[msg.sender]].lastJoinTime = block.timestamp;
        }else{// first join
            if(_inviterAddress!=genesisAddress){
                require(pledgeAccountOrderIndex[_inviterAddress]>=1,"-> _inviterAddress: The invitee has not participated in the pledge yet.");
            }
            pledgeTotalCount += 1;// total number + 1
            pledgeAccountOrderIndex[msg.sender] = pledgeTotalCount;// add index in pledge orders
            pledgeAccountOrders[pledgeTotalCount] = PledgeAccountOrder(pledgeTotalCount,msg.sender,true,block.timestamp,block.timestamp,block.timestamp,_joinAmount);// add PledgeAccountOrder
            inviterAddress[msg.sender]  = _inviterAddress;// Write inviterAddress
            emit BindingInvitation(msg.sender, _inviterAddress);// set log
        }
        lpTokenContract.safeTransferFrom(address(msg.sender),address(this),_joinAmount);

        emit JoinPledge(msg.sender, _joinAmount);// set log
        return true;// return result
    } */

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

    // ================= Pledge Query  =====================

    function getInviterAddress(address _farmAddress) public view returns (address) {
        return inviterAddress[_farmAddress];
    }

    function getFarmBasic() public view returns (address genesisAddressOf,ERC20 wnftTokenContractOf,ERC20 bzzoneTokenContractOf,ERC20 wikiTokenContractOf,bool oneFarmSwitchStateOf,bool twoFarmSwitchStateOF,uint256 oneFarmStartTimeOf,uint256 twoFarmStartTimeOf) {
        return (genesisAddress,wnftTokenContract,bzzoneTokenContract,wikiTokenContract,oneFarmSwitchState,twoFarmSwitchState,oneFarmStartTime,twoFarmStartTime);
    }

    function getPledgeAccountOrderIndex(address _farmAddress) public view returns (uint256 oneFarmAccountOrderIndexOf,uint256 twoFarmAccountOrderIndexOf) {
        return (oneFarmAccountOrderIndex[_farmAddress],twoFarmAccountOrderIndex[_farmAddress]);
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