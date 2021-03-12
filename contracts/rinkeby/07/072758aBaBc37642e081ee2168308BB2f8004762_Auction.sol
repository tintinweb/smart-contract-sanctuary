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
    function Approve_Auction_Contract(address from , address spender ,uint256 _value) external view returns(bool);
    function safetransferFrom(address ,address , uint256) payable external returns(bool);
}  

contract Auction{
    
    //Receiver Address for usdc
    address private Escrow_Address;
    
    //usdc contract Instance
    IERC20 public usdcInstance = IERC20(0xc7AD46e0b8a400Bb3C915120d284AafbA8fc4735);
    
    //Address of contract owner
    address public contractOwner;
    
    //SLC contract address
    address public SLC_contract_address;
    
    //mapping to store each auction details;
    mapping(string => Auction_Details) public auction;
    
    //Save Auction Success Criteria 
    mapping(string => bool) public Auction_Success;
    
    //mapping of tokens to be transferred
    mapping(string => mapping(address => uint)) public UsdcTransferred;
    
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
        bool auction_exist;
        address[] bidders;
    }
    
    event AuctionCreated(string auc_id,uint time);
    
    event BidPlaced(string auc_id,uint time,address bidder,uint price);
    
    event AuctionSuccess(string auc_id,bool state);
    
    constructor(address escrow_account) public{
        Escrow_Address = escrow_account;
        contractOwner = msg.sender;
    }
    
    modifier onlyOwner(){
        require(msg.sender == contractOwner,"Auction Enlist only By Contract Owner");
        _;
    }
    
    
    modifier onlySLCcontract(){
        require(msg.sender == SLC_contract_address,"Auction Enlist can only call By SLC Contract");
        _;
    }
    
    
    function setSLCContractAddress(address _address) public onlyOwner returns(bool){
        require(_address!=address(0));
        SLC_contract_address = _address;
        return true;
    }
    
    function get_escrow_address() public view onlyOwner returns(address){
        return Escrow_Address;
    }
    
     function change_escow_address(address new_address) public onlyOwner returns(bool){
        require(new_address!=address(0));
        Escrow_Address = new_address;
        return true;
    }
    
    function Enlist_Auction(string memory uid,uint s_date,uint e_date,uint res_price,uint sl_reserve,uint noOfTokens,string memory property_id) public onlySLCcontract returns(bool){
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
    
    function saveBid(string memory auctionID,uint bid_amount) public returns(bool){
        Auction_Details memory a = auction[auctionID];
        require(a.auction_exist,"Auction not exist with this id");
        require(a.start_date <= now,"Auction not started");
        require(now < a.end_date-10,"Auction deadline exceed");
        
        if(a.auction_exist && a.auction_start == false)
        auction[auctionID].auction_start = true;
        
        address[] memory temp = auction[auctionID].bidders;
        address Bidder_Address = msg.sender;
        uint i;
        for(i=0;i<temp.length;i++){
            if(temp[i] == Bidder_Address)
            break;
        }
        if(i == temp.length){
            //_ofBidder not present in auction array
            require(usdcInstance.balanceOf(Bidder_Address) >= (bid_amount));
            require(usdcInstance.transfer(Escrow_Address,bid_amount),"USDC TRANSFER FAIL");
            UsdcTransferred[auctionID][msg.sender] += bid_amount;
            auction[auctionID].bidders.push(Bidder_Address);
            auction[auctionID].collected_amount += bid_amount;
            emit BidPlaced(auctionID,now,Bidder_Address,bid_amount);
        }
        else{
            require(usdcInstance.balanceOf(Bidder_Address) >= bid_amount);
            require(usdcInstance.transfer(Escrow_Address,bid_amount),"USDC TRANSFER FAIL");
            UsdcTransferred[auctionID][msg.sender] += bid_amount;
            auction[auctionID].collected_amount += bid_amount;
            uint x = UsdcTransferred[auctionID][msg.sender];
            emit BidPlaced(auctionID,now,Bidder_Address,x);
        }
        
    }
    
    function End_Auction(string memory auction_id) public onlySLCcontract returns(bool,uint owner_money,uint treasury_money){
        Auction_Details memory a = auction[auction_id];
        require(a.auction_exist,"Auction not exist with this id");
        require(now >= a.end_date,"Auction is not finished yet");
        bool Auction_State; //True if auction is succesfull and vice-versa
        
        if(a.collected_amount >= a.reserve_price+a.sl_reserve){
          Auction_State = true;
          Auction_Success[auction_id] = true;
          auction[auction_id].auction_exist = false; 
          emit AuctionSuccess(auction_id,Auction_State);
          return (true,a.reserve_price,a.collected_amount-a.reserve_price);
        }
        else{
          Auction_State = false;
        }
        emit AuctionSuccess(auction_id,Auction_State);
        return (Auction_State,0,0);
    }
    
    function getAuctionBidders(string memory auctionID) public view returns(address[] memory){
        return auction[auctionID].bidders;
    }
    
    function claimUSDCback(string memory auctionID,address Bidder_Address) public onlyOwner returns(bool){
        require(Auction_Success[auctionID] == false,"Auction Success no need for back claim");
        require(UsdcTransferred[auctionID][Bidder_Address] != 0,'token not availaible for reclaim');
        require(usdcInstance.transfer(Bidder_Address,UsdcTransferred[auctionID][Bidder_Address]),"USDC TRANSFER FAIL");
        UsdcTransferred[auctionID][Bidder_Address] = 0;
        return true;
        
    }
    
    function CheckBidderIdentity(string memory auctionID,address Bidder_Address,uint tokens) public onlySLCcontract returns(bool){
        require(Auction_Success[auctionID],"Auction Failed");
        address[] memory temp = auction[auctionID].bidders;
        uint i;
        for(i=0;i<temp.length;i++){
            if(temp[i] == Bidder_Address && UsdcTransferred[auctionID][Bidder_Address] == tokens)
            break;
        }
        if(i != temp.length){
            delete auction[auctionID].bidders[i];
            return true;
        }
        return false;
    }
}