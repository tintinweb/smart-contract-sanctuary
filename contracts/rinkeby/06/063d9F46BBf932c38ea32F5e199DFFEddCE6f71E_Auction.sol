/**
 *Submitted for verification at Etherscan.io on 2021-03-22
*/

/**
 *Submitted for verification at Etherscan.io on 2021-03-12
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2;
interface IERC20 {
    
    function transfer(address , uint256) payable external returns(bool);
    function transferFrom(address ,address , uint256) payable external returns(bool) ;
    function balanceOf(address)  external view  returns(uint256);
    function approve(address , uint256) external payable  returns(bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function safetransferFrom(address ,address , uint256) payable external returns(bool);
}  

contract Auction{
    
    // //Receiver Address for DAI
    // address private Escrow_Address;
    
    //DAI contract Instance
    IERC20 private DaiInstance;
    
    //Suspend Auction Process
    bool public AuctionSuspended;
    
    //Address of contract owner
    address public contractOwner;
    
    //SLC contract address
    address public SLC_contract_address;
    
    //mapping to store each auction details;
    mapping(string => Auction_Details) public auction;
    
    //Save Auction Success Criteria 
    mapping(string => bool) public Auction_Success;
    
    //mapping of amount of DAIs transferred by Bidders
    mapping(string => mapping(address => uint)) public DAITransferred;
    
    //mapping to store quantity of DAI tokens to reclaim DAI
    mapping(string => mapping(address => uint)) public claimDAI;
    
    //Structure to store auction details
    struct Auction_Details {
        string unique_id;
        string property_id;
        uint auction_enlist_date;
        uint start_date;
        uint end_date;
        uint reserve_price;
        uint sl_reserve;
        uint no_of_tokens;
        uint collected_amount;
        bool auction_start;
        bool auction_end;
        bool auction_exist;
        address[] bidders;
    }
    
    //emit when an Auction is Created
    event AuctionCreated(string auc_id,uint time);
    
    //emit when a Bid is placed
    event BidPlaced(string auc_id,uint time,address bidder,uint price);
    
    //emit when Auction is Successfull
    event AuctionSuccess(string auc_id,bool state);
    
    constructor(IERC20 DAIcontractAddress) public{
        // Escrow_Address = escrow_account;
        DaiInstance = DAIcontractAddress;
        contractOwner = msg.sender;
    }
    
    modifier onlyOwner(){
        require(msg.sender == contractOwner,"Auction Enlist only By Contract Owner");
        _;
    }
    
    modifier isAuctionEnded(string memory auctionID){
        Auction_Details memory a = auction[auctionID];
        require(a.auction_end,"Auction not Ended");
        _;
    }
    
    modifier isAuctionNotSuspended(){
        require(AuctionSuspended == false,"Auction is Suspended");
        _;
    }
    
    modifier onlySLCcontract(){
        require(msg.sender == SLC_contract_address,"Auction Enlist can only call By SLC Contract");
        _;
    }
    
    //Save SLC contract address
    function setSLCContractAddress(address _address) public onlyOwner returns(bool){
        require(_address!=address(0));
        SLC_contract_address = _address;
        return true;
    }
    
    //Store Auction Suspend Status
    function SuspendAuction() public onlyOwner returns(bool){
        AuctionSuspended = true;
        return true;
    }
    
    // //Return escrow Account Address
    // function get_escrow_address() public view onlyOwner returns(address){
    //     return Escrow_Address;
    // }
    
    // //Change Escrow Account
    // function change_escow_address(address new_address) public onlyOwner returns(bool){
    //     require(new_address!=address(0));
    //     Escrow_Address = new_address;
    //     return true;
    // }
    
    //function to enlist or configure auction
    function Enlist_Auction(string memory uid,uint s_date,uint e_date,uint res_price,uint sl_reserve,uint noOfTokens,string memory property_id) 
    public onlySLCcontract isAuctionNotSuspended returns(bool){
        require(auction[uid].auction_exist == false,"Auction Already Exist with this id");
        auction[uid].auction_enlist_date = now;
        auction[uid].unique_id = uid;
        auction[uid].start_date = s_date;
        auction[uid].end_date = e_date;
        auction[uid].reserve_price = res_price;
        auction[uid].sl_reserve = sl_reserve;
        auction[uid].no_of_tokens = noOfTokens;
        auction[uid].auction_exist = true;
        auction[uid].property_id = property_id;
        emit AuctionCreated(uid,now);
        return true;
    }
    
    //function to bid in auction
    function saveBid(string memory auctionID,uint bid_amount,address Treasurer_Address) public isAuctionNotSuspended returns(bool){
        Auction_Details memory a = auction[auctionID];
        require(a.auction_exist,"Auction not exist with this id");
        require(a.start_date <= now,"Auction not started");
        require(now < a.end_date-30,"Auction deadline exceed");
        
        if(a.auction_exist && a.auction_start == false)
        auction[auctionID].auction_start = true;
        
        address[] memory temp = auction[auctionID].bidders;
        address Bidder_Address = msg.sender;
        uint i;
        for(i=0;i<temp.length;i++){
            if(temp[i] == Bidder_Address)
            break;
        }
        //Bidders Transfer DAIs in Treasurer_Address Account
        if(i == temp.length){
            //Bidder not present in auction array
            require(DaiInstance.balanceOf(Bidder_Address) >= (bid_amount));
            require(DaiInstance.transferFrom(msg.sender,Treasurer_Address,bid_amount),"DAI TRANSFER FAIL");
            DAITransferred[auctionID][msg.sender] += bid_amount;
            auction[auctionID].bidders.push(Bidder_Address);
            auction[auctionID].collected_amount += bid_amount;
            emit BidPlaced(auctionID,now,Bidder_Address,bid_amount);
        }
        else{
            require(DaiInstance.balanceOf(Bidder_Address) >= bid_amount);
            require(DaiInstance.transferFrom(msg.sender,Treasurer_Address,bid_amount),"DAI TRANSFER FAIL");
            DAITransferred[auctionID][msg.sender] += bid_amount;
            auction[auctionID].collected_amount += bid_amount;
            uint x = DAITransferred[auctionID][msg.sender];
            emit BidPlaced(auctionID,now,Bidder_Address,x);
        }
        require(now < a.end_date-10,"Auction deadline exceed");
        
    }
    
    //end auction and transfer collected amount to property owner and treasury account
    function End_Auction(string memory auction_id) public onlySLCcontract isAuctionNotSuspended returns(bool,uint,uint){
        Auction_Details memory a = auction[auction_id];
        require(a.auction_exist,"Auction not exist with this id");
        require(a.auction_end == false,"Auction already ended");
        require(now >= a.end_date,"Auction is not finished yet");
        bool Auction_State; //True if auction is succesfull and vice-versa
        
        if(a.collected_amount >= a.reserve_price+a.sl_reserve){
          Auction_State = true;
          Auction_Success[auction_id] = true;
          auction[auction_id].auction_exist = false;
          auction[auction_id].auction_end = true;
          emit AuctionSuccess(auction_id,Auction_State);
          return (true,a.collected_amount-a.sl_reserve,a.sl_reserve);
        }
        else{
          Auction_State = false;
          Auction_Success[auction_id] = false;
          auction[auction_id].auction_exist = false;
          auction[auction_id].auction_end = true;
        }
        emit AuctionSuccess(auction_id,Auction_State);
        return (Auction_State,0,0);
    }
    
    //get array of Bidders in particular Auction
    function getAuctionBidders(string memory auctionID) public view isAuctionNotSuspended returns(address[] memory){
        return auction[auctionID].bidders;
    }
    
    //Store Amount of DAI token which Bidder can claim after auction ended
    function StoreDaiClaimAmount(string memory auctionID,address[] memory Dai_Claimers,uint[] memory claim_amount) 
    public isAuctionNotSuspended onlyOwner isAuctionEnded(auctionID){
        for(uint i=0;i<Dai_Claimers.length;i++){
        claimDAI[auctionID][Dai_Claimers[i]] = claim_amount[i];
        }
    }
    
    //function to claim DAI tokens which are not used in auction
    //Trasury Account gives approval to this contract address after auction ends
    function claimDAIback(string memory auctionID,address from) 
    public isAuctionEnded(auctionID) isAuctionNotSuspended returns(bool){
        Auction_Details memory a = auction[auctionID];
        address Bidder_Address = msg.sender;
        require(now >= a.end_date,"Auction is not finished yet");
        require(claimDAI[auctionID][msg.sender] != 0,'token not availaible for reclaim');
        require(claimDAI[auctionID][msg.sender] <= DAITransferred[auctionID][Bidder_Address],'claim amount exceeds amount of tokens actually transferred');
        require(DaiInstance.transferFrom(from,msg.sender,claimDAI[auctionID][msg.sender]),"DAI TRANSFER FAIL");
        DAITransferred[auctionID][Bidder_Address] -= claimDAI[auctionID][msg.sender];
        delete claimDAI[auctionID][msg.sender];
        return true;
        
    }
    
    /*Check Bidders Eligibility*/
    function CheckBidderIdentity(string memory auctionID,address Bidder_Address) public onlySLCcontract isAuctionEnded(auctionID) returns(bool){
        require(Auction_Success[auctionID],"Auction Failed");
        address[] memory temp = auction[auctionID].bidders;
        uint i;
        for(i=0;i<temp.length;i++){
            if(temp[i] == Bidder_Address)
            break;
        }
        if(i != temp.length){
            delete auction[auctionID].bidders[i];
            return true;
        }
        return false;
    }
}