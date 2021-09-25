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
    

    // Struct typed data structure to represent each Proposal and its information inside
    struct proposal{
        uint256 id;
        address buyer;
        address payable seller;
        uint256 amt;
        uint256 time;
        bool accepted;
        uint256 payTokenType;
    }

   // Struct typed data structure to represent each Escrow and its information inside
    struct instance{
        uint256 id;
        address buyer;
        address payable seller;
        uint256 payTokenType; // 0 if BNB/ 1 if LKN tokens /2 if BUSD Token
        uint256 totalAmt;
        uint256 amtPaid;
        bool sellerConfirmation;
        bool buyerConfirmation;
        uint256 start;
        uint256 timeInDays;
        State currentState;
    }
    
     // Info of each pool.
    struct PoolInfo {
        IERC20 token;           // Address of token contract.
    }

    //Owner address
    address payable public owner;
    
    //Liquiduty pool address
    address payable public liquidityPool;

    //Admin adress
    address payable public admin;

    // Burn Address
    address payable public burnAddress;
    
    // Total number of Proposals 
    uint256 public proposalCount;
    
    // Mapping for storing each proposal
    mapping(uint256=>proposal) public getProposal;

    // Mapping for storing each Escrow
    mapping(uint256 => instance) public getEscrow;

    //mapping for storing BNBamounts corresponding to each Escrow
    mapping(uint256=>uint256) public escrowAmtsBNB;
    
    //mapping for storing Tokenamounts corresponding to each Escrow
    mapping(uint256=>uint256) public escrowAmtsToken;

    // Mapping for BNB balances to store if they send directly to this smart contract
    mapping(address => uint256) balances;


    // Owner cut
    uint8 public ownerCut;

    // PoolCut
     uint8 public PoolCut;

    // Admin Cut for Non-Token Based
    uint8 public adminCutBNB;
    
    // Admin Cut Token Based
    uint8 public adminCutLKN;
    
    // Burn Cut for Non-Token Based
    uint8 public burnCutBNB;
    
    // Burn Cut for Token Based
    uint8 public burnCutLKN;
    
    // Buyer refelction
    uint8 public buyerRef;


    mapping (uint256=>bool) public approvedForWithdraw;

    //Mapping to store Disputed Escrow ID with the Disputer Address(Who raised dispute)
    mapping(uint256=> address) public disputedRaisedBy;

    //Mapping to store Escrow creator with Escrow Ids
    mapping(address=>uint256) public AddressEscrowMap;

    // Total Number of Escrows
    uint256 public totalEscrows;

    // Max number of time limit(in Days)
    uint256 public timeLimitInDays;

    // Array to store all disputed escrows
    uint256[] public disputedEscrows;
 
    // Array to store Info of each pool.
    PoolInfo[] public poolInfo;
    
    // Event emitter type when Escrow will be created
    event EscrowCreated(
        uint256 id,
        address buyer,
        address payable seller,
        uint256 payTokenType,
        uint256 paid,
        uint256 start,
        uint256 timeInDays,
        State currentState
    );
    // Proposal emitter type when Proposal will be created
     event ProposalCreated(
        uint256 id,
        address buyer,
        address payable seller,
        uint256 payTokenType,
        uint256 paid,
        uint256 start,
        uint256 timeInDays
    );
    
    // Add new Token event emitter
    event AddNewToken (
        address _tokenAddress,
        uint256 _id
        );
        
    // State change event emitter
    event StateChanged(uint256 indexed id,State indexed _state);

    // Onlyowner Access Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    // Onlyadmin Access Modifiers
    modifier onlyAdmin() {
        require(msg.sender == admin);
        _;
    }


    // OnlyBuyer Access Modifiers
    modifier onlyBuyer(uint _id){
        require(msg.sender == getEscrow[_id].buyer);
        _;
    }

    // OnlySeller Access Modifiers
    modifier onlySeller(uint _id){
        require(msg.sender == getEscrow[_id].seller);
        _;
    }
    

    constructor(address payable _owner,uint256 _timeLimitInDays,address payable _admin,address payable _liquidityPool,address payable _burnAddress){
        owner = _owner;
        burnAddress = _burnAddress;
        admin = _admin;
        liquidityPool = _liquidityPool;
        totalEscrows =0;
        timeLimitInDays = _timeLimitInDays;
    }
    
     // Add a new token to the pool. Can only be called by the owner.
    // XXX DO NOT add the same  token more than once. Rewards will be messed up if you do.
    function add( IERC20 _token) public onlyOwner {
        
        poolInfo.push(PoolInfo({
            token: _token
        }));
        emit AddNewToken(address(_token),poolInfo.length);
    }

    // Function to set tax %age and also update it and it can only be called by admin
    function setFeesAdminPoolCut(uint8 fees,uint8 _adminBNB,uint8 _adminLKN,uint8 _poolCut,uint8 _burnCutBNB,uint8 _burnCutLKN,uint8 _buyerRef) public onlyOwner {
        ownerCut = fees;
        PoolCut = _poolCut;
        adminCutBNB=_adminBNB;
        adminCutLKN=_adminLKN;
        burnCutBNB=_burnCutBNB;
        burnCutLKN=_burnCutLKN;
        buyerRef= _buyerRef;
    }
    // Function to create each proposal along with all the info needed
    function createProposal(uint256 amt,uint256 time,uint256 payType) public payable{
        require(msg.value >=amt);
        address payable _seller = payable(address(0));
        proposalCount++;
        uint256 _id = proposalCount;
        getProposal[_id]=proposal(_id,msg.sender,_seller,amt,time,false,payType);
        emit ProposalCreated(_id,msg.sender,_seller,payType,amt,block.timestamp,time);
    }
    
    // Function to accept each proposal along with all the info needed and Creating ESCROW in the end
    function acceptProposal(uint256 _id) public {
        require(!getProposal[_id].accepted,"already accepted");
        getProposal[_id].seller = payable(msg.sender);
        getProposal[_id].accepted = true;
        proposal memory temp = getProposal[_id];
        if(temp.payTokenType ==0){
            createEscrowBNB(temp.buyer,temp.seller,temp.amt,temp.time);   
        }else {
            createEscrowToken(temp.buyer,temp.payTokenType,temp.seller,temp.amt,temp.time);
        }
        
    }
     
     // Function to create proposals for Tokens based 
    function createProposalToken(uint256 amt,uint256 time,uint256 payTokenType) internal {
        PoolInfo storage pool = poolInfo[payTokenType-1];
        IERC20 token = pool.token;
        require(token.balanceOf(address(msg.sender))>=amt,"You dont have enough Tokens");
        address payable _seller = payable(address(0));
        proposalCount++;
        uint256 _id = proposalCount;
        token.transferFrom(address(msg.sender), address(this), amt);
        getProposal[_id]=proposal(_id,msg.sender,_seller,amt,time,false,payTokenType);
        emit ProposalCreated(_id,msg.sender,_seller,payTokenType,amt,block.timestamp,time);
    }

    // Function to create milestone proposals for Tokens based
    function createProposalMileStoneToken(uint256[] calldata amounts,uint256[] calldata times,uint256[] calldata payType) public{
           uint256 len = amounts.length;
           for(uint256 i=0;i<len;i++){
                createProposalToken(amounts[i],times[i],payType[i]);
           }
    }

    // Function to create milestone proposals for Non-Token based
    function createProposalMileStone(uint256[] calldata amounts,uint256 sum ,uint256[] calldata times,uint256[] calldata payType) public payable{
           require(msg.value>=sum,"You arent depositing enough funds");
           uint256 len = amounts.length;
           for(uint256 i=0;i<len;i++){
                createProposal(amounts[i],times[i],payType[i]);
           }
    }
    
    // Function to accept milestone proposals
    function acceptProposalMilestone(uint256[] calldata _ids) public {
           uint256 len = _ids.length;
           for(uint256 i=0;i<len;i++){
                acceptProposal(_ids[i]);
           }
    }
    
    // Function to create Escrow of type Non-Token Based
    function createEscrowBNB(address _buyer,address payable _seller,uint256 amt,uint256 timeInDays) internal {
        require(timeInDays <= timeLimitInDays,"timePeriod more than limit");
        totalEscrows++;
        uint256 id = totalEscrows;
        getEscrow[id]= instance(id,_buyer,_seller,0,amt,0,false,false,block.timestamp,timeInDays,State.initiated);
        escrowAmtsBNB[id] = amt;
        AddressEscrowMap[_buyer] = id;
        approvedForWithdraw[id] = false;
        emit EscrowCreated(id,_buyer,_seller,0,amt,block.timestamp,timeInDays,State.initiated);
    }

    // Function to create Escrow of type Token Based
    function createEscrowToken(address __buyer,uint256 _tokenID,address payable _seller,uint256 amt,uint256 timeInDays) internal {
        require(timeInDays <= timeLimitInDays,"timePeriod more than limit");
        totalEscrows++;
        uint256 id = totalEscrows;
        getEscrow[id]= instance(id,__buyer,_seller,_tokenID,amt,0,false,false,block.timestamp,timeInDays,State.initiated);
        escrowAmtsToken[id] = amt;
        AddressEscrowMap[__buyer] = id;
        emit EscrowCreated(id,__buyer,_seller,_tokenID,amt,block.timestamp,timeInDays,State.initiated);
    }

    // Function to release Payments associated with each Escrow ID
    function releasePayment(uint256 _id) public {
        instance memory temp = getEscrow[_id];
        require(msg.sender == temp.seller);
        require(block.timestamp <= block.timestamp+SafeMath.mul(getEscrow[_id].timeInDays,86400),"Escrow Period exceeded");
        //require(getEscrow[_id].sellerConfirmation,"Seller has not Confirmed delivery");
        require(!getEscrow[_id].buyerConfirmation,"Buyer already confirmed");
        require(!approvedForWithdraw[_id]);
        delete getEscrow[_id];
        if(temp.payTokenType ==0){
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
        }else{
            PoolInfo storage pool = poolInfo[temp.payTokenType-1];
            IERC20 token = pool.token;
            uint256 _temp = escrowAmtsToken[_id];
            uint256 buyerReflection= ceilDiv(SafeMath.mul(buyerRef,_temp),10000);
            uint256 _adminCut = ceilDiv(SafeMath.mul(adminCutLKN,_temp),10000);
            uint256 _burnCut = ceilDiv(SafeMath.mul(burnCutLKN,_temp),10000);
            escrowAmtsToken[_id] = 0;   
            token.transfer(temp.seller,_temp-buyerReflection-_adminCut-_burnCut);
            token.transfer(admin,_adminCut);
            token.transfer(burnAddress,_burnCut);
            token.transfer(address(msg.sender),buyerReflection);
        }
        getEscrow[_id].buyerConfirmation=true;
        getEscrow[_id].currentState = State.paid;
    }

    //Function to raise dispute by rightful users
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

    // Function to accept and cancel dispute and it can only be called by owner
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
    
    // Function to cancel proposal before User B accepts the proposal and created Escrow
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
    
    function getPoolInfo(uint256 _id) public view returns(PoolInfo memory){
        return poolInfo[_id];
    }
    
    //Function to get all disputed Escrows
    function getDisputedEscrows() public view returns(uint256[] memory) {
        return disputedEscrows;
    }
    

    // Function for Ceil Devision
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }

     // Fallback function which gets triggered when someone sends BNB to this contracts address directly
    receive() external payable {
        balances[msg.sender] += msg.value;
    }
}