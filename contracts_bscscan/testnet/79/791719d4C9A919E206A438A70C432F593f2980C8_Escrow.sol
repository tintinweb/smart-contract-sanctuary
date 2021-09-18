// SPDX-License-Identifier: MIT

import {IERC20} from "./IERC20.sol";
import "./SafeMath.sol";
import "./Address.sol";
import {IPancakeRouter02} from './pancakeRouter.sol';

pragma solidity ^0.8.0; 

contract Escrow {

    using SafeMath for uint256;
    using Address for address payable;

    enum State{initiated,delivered,paid,disputed}
    
    struct proposal{
        uint256 id;
        address buyer;
        address payable seller;
        uint256 amt;
        uint256 time;
        bool accepted;
        bool payType;
    }

    struct instance{
        uint256 id;
        address buyer;
        address payable seller;
        bool payType; // true if BNB/false if tokens
        uint256 totalAmt;
        uint256 amtPaid;
        bool sellerConfirmation;
        bool buyerConfirmation;
        uint256 start;
        uint256 timeInDays;
        State currentState;
        bytes32 message;
    }

    address payable public owner;
    
    address payable public liquidityPool;

    address payable public admin;

    address payable public burnAddress;
    
    uint256 public proposalCount;
    
    mapping(uint256=>proposal) public getProposal;

    mapping(uint256 => instance) public getEscrow;

    mapping(uint256=>uint256) public escrowAmtsBNB;

    mapping(uint256=>uint256) public escrowAmtsToken;

    mapping(address => uint256) public balances;

    address public token;

    uint8 public ownerCut;

    uint8 public PoolCut;

    uint8 public adminCutBNB;
    
    uint8 public adminCutLKN;

    uint8 public burnCutBNB;
    
    uint8 public burnCutLKN;
    
    uint8 public buyerRef;

    mapping (uint256=>bool) public approvedForWithdraw;

    mapping(uint256=> address) public disputedRaisedBy;

    mapping(address=>uint256) public AddressEscrowMap;

    uint256 public totalEscrows;

    uint256 public timeLimitInDays;

    uint256[] public disputedEscrows;

    event EscrowCreated(
        uint256 id,
        address buyer,
        address payable seller,
        bool payType,
        uint256 paid,
        uint256 start,
        uint256 timeInDays,
        State currentState,
        bytes32 message
    );
     event ProposalCreated(
        uint256 id,
        address buyer,
        address payable seller,
        bool payType,
        uint256 paid,
        uint256 start,
        uint256 timeInDays
    );

    event StateChanged(uint256 indexed id,State indexed _state);

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin);
        _;
    }

    modifier onlyBuyer(uint _id){
        require(msg.sender == getEscrow[_id].buyer);
        _;
    }

    modifier onlySeller(uint _id){
        require(msg.sender == getEscrow[_id].seller);
        _;
    }

    constructor(address payable _owner,address _token,uint256 _timeLimitInDays,address payable _admin,address payable _liquidityPool,address payable _burnAddress){
        owner = _owner;
        token = _token;
        burnAddress = _burnAddress;
        admin = _admin;
        liquidityPool = _liquidityPool;
        totalEscrows =0;
        timeLimitInDays = _timeLimitInDays;
    }

    function setFeesAdminPoolCut(uint8 fees,uint8 _adminBNB,uint8 _adminLKN,uint8 _poolCut,uint8 _burnCutBNB,uint8 _burnCutLKN,uint8 _buyerRef) public onlyOwner {
        ownerCut = fees;
        PoolCut = _poolCut;
        adminCutBNB=_adminBNB;
        adminCutLKN=_adminLKN;
        burnCutBNB=_burnCutBNB;
        burnCutLKN=_burnCutLKN;
        buyerRef= _buyerRef;
    }

    function arraySum(uint256[] memory array) internal pure returns (uint256) {
        require(array.length >1);
        uint256 sum = 0;
        for (uint256 i = 0; i < array.length-1; i++) {
            sum = SafeMath.add(sum,array[i]);
        }
        return sum;
    }
    
    function createProposal(uint256 amt,uint256 time,bool payType) public payable{
        require(msg.value >=amt);
        address payable _seller = payable(address(0));
        proposalCount++;
        uint256 _id = proposalCount;
        getProposal[_id]=proposal(_id,msg.sender,_seller,amt,time,false,payType);
        emit ProposalCreated(_id,msg.sender,_seller,payType,amt,block.timestamp,time);
    }
    
    function acceptProposal(uint256 _id) public {
        require(!getProposal[_id].accepted,"already accepted");
        getProposal[_id].seller = payable(msg.sender);
        getProposal[_id].accepted = true;
        proposal memory temp = getProposal[_id];
        if(temp.payType){
            createEscrowBNB(temp.buyer,temp.seller,temp.amt,temp.time,bytes32(0));   
        }else if(!temp.payType){
            createEscrowToken(temp.buyer,temp.seller,temp.amt,temp.time,bytes32(0));
        }
        
    }


    function createProposalMileStone(uint256[] calldata amounts,uint256 sum ,uint256[] calldata times,bool[] calldata payType) public payable{
           require(msg.value>=sum,"You arent depositing enough funds");
           uint256 len = amounts.length;
           for(uint256 i=0;i<len;i++){
                createProposal(amounts[i],times[i],payType[i]);
           }
           
           
    }
    
    function acceptProposalMilestone(uint256[] calldata _ids) public {
           uint256 len = _ids.length;
           for(uint256 i=0;i<len;i++){
                acceptProposal(_ids[i]);
           }
    }
    
    function addMessage(uint256 id,bytes32 _message) public {
        require(msg.sender == getEscrow[id].buyer || msg.sender == getEscrow[id].seller,"neither buyer or seller");
        getEscrow[id].message = _message;
    }

    function createEscrowBNB(address _buyer,address payable _seller,uint256 amt,uint256 timeInDays,bytes32 message) internal {
        require(timeInDays <= timeLimitInDays,"timePeriod more than limit");
        totalEscrows++;
        uint256 id = totalEscrows;
        getEscrow[id]= instance(id,_buyer,_seller,true,amt,0,false,false,block.timestamp,timeInDays,State.initiated,message);
        escrowAmtsBNB[id] = amt;
        AddressEscrowMap[_buyer] = id;
        approvedForWithdraw[id] = false;
        emit EscrowCreated(id,_buyer,_seller,true,amt,block.timestamp,timeInDays,State.initiated,message);
    }

    function createEscrowToken(address __buyer,address payable _seller,uint256 amt,uint256 timeInDays,bytes32 message) internal {
        require(timeInDays <= timeLimitInDays,"timePeriod more than limit");
        totalEscrows++;
        uint256 id = totalEscrows;
        getEscrow[id]= instance(id,__buyer,_seller,false,amt,0,false,false,block.timestamp,timeInDays,State.initiated,message);
        escrowAmtsToken[id] = amt;
        AddressEscrowMap[__buyer] = id;
        emit EscrowCreated(id,__buyer,_seller,false,amt,block.timestamp,timeInDays,State.initiated,message);
    }

    function updateSellerStatus(uint256 _id) public onlySeller(_id){
        require(block.timestamp <= block.timestamp+SafeMath.mul(getEscrow[_id].timeInDays,86000),"Escrow Period exceeded");
        require(getEscrow[_id].currentState == State.initiated);
        require(!approvedForWithdraw[_id]);
        require(!getEscrow[_id].buyerConfirmation,"buyer already confirmed");
        getEscrow[_id].sellerConfirmation = true;
        getEscrow[_id].currentState = State.delivered;
        emit StateChanged(_id,getEscrow[_id].currentState);
    }

    //TODO add fees and percents

    function releasePayment(uint256 _id) public {
        instance memory temp = getEscrow[_id];
        require(msg.sender == temp.seller);
        require(block.timestamp <= block.timestamp+SafeMath.mul(getEscrow[_id].timeInDays,86400),"Escrow Period exceeded");
        //require(getEscrow[_id].sellerConfirmation,"Seller has not Confirmed delivery");
        require(!getEscrow[_id].buyerConfirmation,"Buyer already confirmed");
        require(!approvedForWithdraw[_id]);
        delete getEscrow[_id];
        if(temp.payType){
            uint256 Temp= escrowAmtsBNB[_id];
            uint256 _PoolCut = ceilDiv(SafeMath.mul(PoolCut,Temp),10000);
            uint256 _adminCut = ceilDiv(SafeMath.mul(adminCutBNB,Temp),10000);//service fee
            uint256 _burnCut = ceilDiv(SafeMath.mul(burnCutBNB,Temp),10000);
            escrowAmtsBNB[_id] = 0;
            temp.seller.sendValue(Temp-_PoolCut-_adminCut-_burnCut);
            admin.sendValue(_adminCut);
            burnAddress.sendValue(_burnCut);
            liquidityPool.sendValue(_PoolCut);
            //PancakeRouter02(liquidityPool).addLiquidityETH(token,_PoolCut,_PoolCut,_PoolCut,address(this),block.timestamp+1000000);
        }else if(!temp.payType){
            uint256 _temp = escrowAmtsToken[_id];
            uint256 buyerReflection= ceilDiv(SafeMath.mul(buyerRef,_temp),10000);
            uint256 _adminCut = ceilDiv(SafeMath.mul(adminCutLKN,_temp),10000);
            uint256 _burnCut = ceilDiv(SafeMath.mul(burnCutLKN,_temp),10000);
            escrowAmtsToken[_id] = 0;   
            IERC20(token).transfer(temp.seller,_temp-buyerReflection-_adminCut-_burnCut);
            IERC20(token).transfer(admin,_adminCut);
            IERC20(token).transfer(burnAddress,_burnCut);
            IERC20(token).transfer(address(msg.sender),buyerReflection);
        }
        getEscrow[_id].buyerConfirmation=true;
        getEscrow[_id].currentState = State.paid;
    }

    function releaseMileStone(uint256 _id,uint256 amt) public {
        instance memory temp = getEscrow[_id];
        require(msg.sender == temp.buyer,"not buyer");
        require(amt < temp.totalAmt,"amount greater than totalAmt");
        if(temp.payType){
            escrowAmtsBNB[_id] = SafeMath.sub(escrowAmtsBNB[_id],amt);
            getEscrow[_id].amtPaid = amt;
            temp.seller.sendValue(amt);
        }else if(!temp.payType){
            escrowAmtsToken[_id] = escrowAmtsToken[_id] - amt;
            getEscrow[_id].amtPaid = amt;
            IERC20(token).transfer(temp.seller,amt);
        }
    }

    function raiseDispute(uint256 id) public{
        require(msg.sender == getEscrow[id].seller || msg.sender == getEscrow[id].buyer);
        require(!getEscrow[id].buyerConfirmation || !getEscrow[id].sellerConfirmation);
        require(!approvedForWithdraw[id]);
        require(getEscrow[id].currentState != State.disputed);
        getEscrow[id].currentState = State.disputed;
        disputedEscrows.push(id);
        disputedRaisedBy[id] == msg.sender;
        emit StateChanged(id, getEscrow[id].currentState);
    }

    function approveForWithdraw(uint256 id,bool withdrawParty) public {  //onlyOwner function
        // withdrawParty -- true if buyer,false if seller 
        require(getEscrow[id].currentState == State.disputed);
        if(withdrawParty){
            payable(getEscrow[id].buyer).sendValue(escrowAmtsBNB[id]);
        }
        else if(!withdrawParty){
            getEscrow[id].seller.sendValue(escrowAmtsBNB[id]);
        }
    }
    
    function cancelProposal(uint256[] calldata _ids) public {
        uint256 len = _ids.length;
        for(uint256 _id=0;_id<len;_id++){
        uint256 id = _ids[_id];    
        require(getProposal[id].buyer==msg.sender,"You havent created this Proposal");
        uint256 _amount = getProposal[id].amt;
        payable(msg.sender).sendValue(_amount);
        delete getProposal[id];
        }
    }
    
    function getDisputedEscrows() public view returns(uint256[] memory) {
        return disputedEscrows;
    }
    
     function changeToken(address _token) public onlyOwner{
        token = _token;
    }

    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }

    receive() external payable {
        balances[msg.sender] += msg.value;
    }
}