/**
 *Submitted for verification at polygonscan.com on 2021-09-10
*/

pragma solidity >=0.6.2;
interface IERC20 {
    
    function transfer(address , uint256) payable external returns(bool);
    function transferFrom(address ,address , uint256) payable external returns(bool) ;
    function balanceOf(address)  external view  returns(uint256);
    function approve(address , uint256) external payable  returns(bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function safetransferFrom(address ,address , uint256) payable external returns(bool);
}  

abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() internal {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

contract Auction is ReentrancyGuard{
    
    //Suspend Auction Process
    bool public AuctionSuspended;
    
    //Address of contract owner
    address public contractOwner;
    
    //Address of SLF contract
    address public SLF_CONTRACT_ADDRESS;
    
    //SLC contract address
    mapping(address => mapping(string =>bool)) public SLC_contract_address;
    
    //mapping to store each auction details;
    mapping(string => Auction_Details) public auction;
    
    //Save Auction Success Criteria 
    mapping(string => bool) public Auction_Success;
    
    //mapping of amount of Tokens transferred by Bidders
    mapping(address => mapping(string => mapping(address => uint))) public BidTokensTransferred;
    
    //mapping to store quantity of BID tokens to reclaim BID tokens
    mapping(address => mapping(string => mapping(address => uint))) public claimBidTokens;
    
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
    
    constructor(address _SLF_CONTRACT_ADDRESS) public{
        contractOwner = msg.sender;
        SLF_CONTRACT_ADDRESS = _SLF_CONTRACT_ADDRESS;
    }
    
    modifier onlyOwner(){
        require(msg.sender == contractOwner,"Auction Enlist only By Contract Owner");
        _;
    }
    
    modifier onlyOwnerAndSLFContract(){
        require(msg.sender == contractOwner || msg.sender == SLF_CONTRACT_ADDRESS,"Caller is not Owner or SLF contract");
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
    
    //change SLF contract address
    function Change_SLF_Contract_Address(address NEW_SLF_ADDRESS) public onlyOwner returns(bool){
        require(NEW_SLF_ADDRESS!=address(0));
        SLF_CONTRACT_ADDRESS = NEW_SLF_ADDRESS;
        return true;
    }
    
    //Save SLC contract address
    function Store_SLC_Contract_Address(address _address,string memory property_id) public onlyOwnerAndSLFContract returns(bool){
        require(_address!=address(0));
        SLC_contract_address[_address][property_id] = true;
        return true;
    }
    
    //Store Auction Suspend Status
    function SuspendAuction() public onlyOwner returns(bool){
        AuctionSuspended = true;
        return true;
    }
    

    
    //function to enlist or configure auction
    function Enlist_Auction(string calldata uid,uint s_date,uint e_date,uint res_price,uint sl_reserve,uint noOfTokens,string calldata property_id) 
    external  isAuctionNotSuspended returns(bool){
        require(SLC_contract_address[msg.sender][property_id],"Enlist Auction Error");
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
    function saveBid(string memory auctionID,uint bid_amount,address Treasurer_Address,address BidTokenAddress) public nonReentrant isAuctionNotSuspended returns(bool){
        Auction_Details memory a = auction[auctionID];
        require(msg.sender != address(0),"Caller is address zero");
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
        //Bidders Transfer Tokens in Treasurer_Address Account
        if(i == temp.length){
            //Bidder not present in auction array
            require(IERC20(BidTokenAddress).balanceOf(Bidder_Address) >= (bid_amount));
            require(IERC20(BidTokenAddress).transferFrom(msg.sender,Treasurer_Address,bid_amount),"BID TOKEN TRANSFER FAIL");
            BidTokensTransferred[BidTokenAddress][auctionID][msg.sender] += bid_amount;
            auction[auctionID].bidders.push(Bidder_Address);
            auction[auctionID].collected_amount += bid_amount;
            emit BidPlaced(auctionID,now,Bidder_Address,bid_amount);
        }
        else{
            require(IERC20(BidTokenAddress).balanceOf(Bidder_Address) >= bid_amount);
            require(IERC20(BidTokenAddress).transferFrom(msg.sender,Treasurer_Address,bid_amount),"BID TOKEN TRANSFER FAIL");
            BidTokensTransferred[BidTokenAddress][auctionID][msg.sender] += bid_amount;
            auction[auctionID].collected_amount += bid_amount;
            uint x = BidTokensTransferred[BidTokenAddress][auctionID][msg.sender];
            emit BidPlaced(auctionID,now,Bidder_Address,x);
        }
        require(now < a.end_date-10,"Auction deadline exceed");
        
    }
    
    //end auction and transfer collected amount to property owner and treasury account
    function End_Auction(string memory auction_id,string memory property_id) public isAuctionNotSuspended returns(bool,uint,uint){
        Auction_Details memory a = auction[auction_id];
        require(SLC_contract_address[msg.sender][property_id],"End Auction Error");
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
    
    //Store Amount of BID token which Bidder can claim after auction ended
    function StoreBidTokenClaimAmount(string memory auctionID,address[] memory Bid_Token_Claimers,uint[] memory claim_amount,address BidTokenAddress) 
    public isAuctionNotSuspended onlyOwner isAuctionEnded(auctionID){
        for(uint i=0;i<Bid_Token_Claimers.length;i++){
        claimBidTokens[BidTokenAddress][auctionID][Bid_Token_Claimers[i]] = claim_amount[i];
        }
    }
    
    //function to claim BID tokens which are not used in auction
    //Trasury Account gives approval to this contract address after auction ends
    function claimBidTokensback(string memory auctionID,address from,address BidTokenAddress) 
    public nonReentrant isAuctionEnded(auctionID) isAuctionNotSuspended returns(bool){
        Auction_Details memory a = auction[auctionID];
        address Bidder_Address = msg.sender;
        require(now >= a.end_date,"Auction is not finished yet");
        require(claimBidTokens[BidTokenAddress][auctionID][msg.sender] != 0,'token not availaible for reclaim');
        require(claimBidTokens[BidTokenAddress][auctionID][msg.sender] <= 
        BidTokensTransferred[BidTokenAddress][auctionID][Bidder_Address],'claim amount exceeds amount of tokens actually transferred');
        require(IERC20(BidTokenAddress).transferFrom(from,msg.sender,claimBidTokens[BidTokenAddress][auctionID][msg.sender]),"BID TOKEN TRANSFER FAIL");
        BidTokensTransferred[BidTokenAddress][auctionID][Bidder_Address] -= claimBidTokens[BidTokenAddress][auctionID][msg.sender];
        delete claimBidTokens[BidTokenAddress][auctionID][msg.sender];
        return true;
        
    }
    
}