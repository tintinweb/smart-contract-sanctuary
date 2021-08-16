pragma solidity 0.5.8;

import { Ownable } from "./Ownable.sol" ;
import "./SafeMath.sol";
import "./SafeERC20.sol";

contract PledgeFarm is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for ERC20;

    // Pledge Basic
    bool public pledgeSwitchState = false;
    uint256 public pledgeStartTime;
    uint256 public pledgeTotalCount = 0;
    mapping(address => address) private inviterAddress;
    address public genesisAddress;

    // LP Token
    ERC20 public lpTokenContract;

    // Pledge Account
    mapping(uint256 => PledgeAccountOrder) public pledgeAccountOrders;
    struct PledgeAccountOrder {
        uint256 index;
        address account;
        bool isExist;
        uint256 firstJoinTime;
        uint256 lastJoinTime;
        uint256 lastExitTime;
        uint256 plegdeAmount;
    }
    mapping(address => uint256) private pledgeAccountOrderIndex;

    // Events
    event CreateLpTokenContract(address indexed _account, address indexed _lpTokenContract);
    event PledgeSwitchState(address indexed _account, bool _switchState);
    event GenesisAddress(address indexed _account, address indexed _genesisAddress);
    event JoinPledge(address indexed _account, uint256 _joinAmount);
    event ExitPledge(address indexed _account, uint256 _exitAmount);
    event BindingInvitation(address indexed _account,address indexed _inviterAddress);

    // ================= Initial Value ===============

    constructor () public {}

    // ================= Pledge Operation  =================

    function joinPledge(uint256 _joinAmount, address _inviterAddress) public returns (bool) {
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
    }

    function exitPledge() public returns (bool) {
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
    }

    // ================= Pledge Query  =====================

    function getPledgeAccountOrderIndex(address _pledgeAddress) public view returns (uint256) {
        return pledgeAccountOrderIndex[_pledgeAddress];
    }

    function getInviterAddress(address _pledgeAddress) public view returns (address) {
        return inviterAddress[_pledgeAddress];
    }

    // ================= Initial Operation  =====================

    function createLpTokenContract(address _lpTokenContract) public onlyOwner returns (bool) {
        lpTokenContract = ERC20(_lpTokenContract);
        emit CreateLpTokenContract(msg.sender, _lpTokenContract);
        return true;
    }

    function setPledgeSwitchState(bool _pledgeSwitchState) public onlyOwner returns (bool) {
        pledgeSwitchState = _pledgeSwitchState;
        if(pledgeStartTime==0){
              pledgeStartTime = block.timestamp;// update presellStartTime
        }
        emit PledgeSwitchState(msg.sender, _pledgeSwitchState);
        return true;
    }

    function setGenesisAddress(address _genesisAddress) public onlyOwner returns (bool) {
        genesisAddress = _genesisAddress;
        emit GenesisAddress(msg.sender, _genesisAddress);
        return true;
    }


}