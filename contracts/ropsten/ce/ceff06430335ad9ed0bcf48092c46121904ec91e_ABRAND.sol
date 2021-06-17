/**
 *Submitted for verification at Etherscan.io on 2021-06-17
*/

pragma solidity 0.8.0;


contract ABRAND {
    uint contractBalance;
    
    address campaigner;
    string  campaign;
    uint totalengagement;
    uint campaignStartingTime;
    uint contractEndTime;
    uint256 amountPerEngagement=1;
    mapping(address => influencer_Info) public influencer_info;
    mapping(address => request_Info) public Request_Info;
   
    address[] influencerRequestedToParticipate;
    
    struct request_Info{
        uint total_followers;
        string platform;
        uint requested_at;
        uint timePeriod;
        uint noOfEngagementOffering;
        bool approved;
    }
    
    struct influencer_Info {
        uint total_followers;
        string platform;
        uint totalEngagementSigned;
        uint contractSignedTime;
        uint contractEndTime;
        string postURI;
        uint amountForEachEngagement;
        uint totalAmount;
        bool paid;
        bool signed;
    }
    
    constructor() {
        campaigner=msg.sender;
        campaignStartingTime = block.timestamp;
        campaign="CampaignTitle";
    }
    
    modifier OnlyOwner()
    {
     _;
     require(msg.sender == campaigner, 'NOT_CURRENT_OWNER');
    }
    
    function getCampaignTitle()public view returns(string memory){
        return campaign;
    }
    
    function getCampaigner() public view returns (address){
        return campaigner;
    }
    
    function campaignStartedAt() public view returns (uint){
        return campaignStartingTime;
    }
    
    function amountOfferingPerEngagement() public view returns (uint256){
        return amountPerEngagement;
    }
    
    function setAmountOfferingPerEngagement(uint256 value) public OnlyOwner{
        amountPerEngagement=value;
    }
    
    function removeFromPendigRequestList(address add) internal{
        uint256 i=0;
         while (influencerRequestedToParticipate[i] != add) {
            i++;
        }
        
         while (i<influencerRequestedToParticipate.length-1) {   
              influencerRequestedToParticipate[i] = influencerRequestedToParticipate[i+1];
            i++;
         }
        // influencerRequestedToParticipate.pop();
    }
    
    
    function appveInvolvement(address influencer)public OnlyOwner{
        require(Request_Info[influencer].requested_at!=0,'Given influencer not Requested');
        Request_Info[influencer].approved=true;
        removeFromPendigRequestList(influencer);
    }
    
    function requestToparticipateInCampaign(uint followers, string memory platform,uint timePeriodOfParticipation, uint noOfEngagementOffering) external {
        request_Info memory info;
        info= request_Info(
            followers,
            platform,
            block.timestamp,
            timePeriodOfParticipation,
            noOfEngagementOffering,
            false
            );
            Request_Info[msg.sender]=info;
            influencerRequestedToParticipate.push(msg.sender);
    }
    
    function getinvolveAsInfluencer(string memory postURI) external {
          require(Request_Info[msg.sender].requested_at!=0,'Please make request to participate in campaign before involve');
          require(Request_Info[msg.sender].approved==true,'Your request is not approved from caampaigner');
          influencer_Info memory info;
          info = influencer_Info(
              Request_Info[msg.sender].total_followers,
              Request_Info[msg.sender].platform,
              Request_Info[msg.sender].noOfEngagementOffering,
              block.timestamp,
              block.timestamp+Request_Info[msg.sender].timePeriod,
              postURI,
              amountOfferingPerEngagement(),
              Request_Info[msg.sender].noOfEngagementOffering*(amountOfferingPerEngagement()),
              false,
              true
              );
          influencer_info[msg.sender]=info;
    }
    
    function payInfluencer(address payable influencerAddress) public OnlyOwner payable returns(bool){
        require(influencer_info[influencerAddress].contractSignedTime!=0,'Contract neverSigned');
        require(block.timestamp>=influencer_info[influencerAddress].contractEndTime,'ContractPeriod not Ended Yet');
        require(influencer_info[influencerAddress].totalAmount!=0,'Already paid for the work');
        uint amount = influencer_info[influencerAddress].totalAmount;
        influencer_info[influencerAddress].paid=true;
        influencer_info[influencerAddress].totalAmount=0;
        if(!influencerAddress.send(amount)){
            influencer_info[influencerAddress].totalAmount=amount;
            influencer_info[influencerAddress].paid=false;
            return false;
        }
        return true;
    }
    
    function getFee() public returns (bool) {
        require(influencer_info[msg.sender].contractSignedTime!=0,'Contract neverSigned');
        require(block.timestamp>=influencer_info[msg.sender].contractEndTime,'ContractPeriod not Ended Yet');
        require(influencer_info[msg.sender].totalAmount!=0,'Already paid for the work');
        uint amount = influencer_info[msg.sender].totalAmount;
        influencer_info[msg.sender].paid=true;
        influencer_info[msg.sender].totalAmount=0;
        address payable add=payable(msg.sender);
        if(!add.send(amount)){
            influencer_info[msg.sender].totalAmount=amount;
            influencer_info[msg.sender].paid=false;
            return false;
        }
        
        return true;
    }

    function influencersRequestedToParticipate()external view OnlyOwner returns(address[] memory){
        return influencerRequestedToParticipate;
    }
    
    function getcontractBalance() public view returns (uint) {
        return address(this).balance;
    }
    
    function getBalance(address add) public view returns (uint) {
        return address(add).balance;
    }
    
    function addContractBalance() public payable OnlyOwner {
        // This function is no longer recommended for sending Ether.
        contractBalance+=msg.value;
    }
    
  
}