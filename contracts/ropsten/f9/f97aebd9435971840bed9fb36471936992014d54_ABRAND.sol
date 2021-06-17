/**
 *Submitted for verification at Etherscan.io on 2021-06-17
*/

pragma solidity 0.8.0;


contract ABRAND {
    
    address campaigner;
    string  campaign;
    uint totalengagement;
    uint campaignStartingTime;
    uint contractEndTime;
    uint256 amountPerEngagement;
    mapping(address => influencer_Info) public influencer;
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
        uint amountForEachEngagement;
        uint totalAmount;
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
    
    function getinvolveAsInfluencer() external {
          require(Request_Info[msg.sender].requested_at!=0,'Please make request to participate in campaign before involve');
          require(Request_Info[msg.sender].approved==true,'Your request is not approved from caampaigner');
          influencer_Info memory info;
          info = influencer_Info(
              Request_Info[msg.sender].total_followers,
              Request_Info[msg.sender].platform,
              Request_Info[msg.sender].noOfEngagementOffering,
              block.timestamp,
              block.timestamp+Request_Info[msg.sender].timePeriod,
              amountOfferingPerEngagement(),
              Request_Info[msg.sender].noOfEngagementOffering*(amountOfferingPerEngagement()),
              true
              );
          influencer[msg.sender]=info;
    }
    
    
    function payInfluencer(address payable influencerAddress) public OnlyOwner returns(bool){
        require(influencer[msg.sender].contractSignedTime==0,'Contract neverSigned');
        require(block.timestamp>=influencer[msg.sender].contractEndTime,'ContractPeriod not Ended Yet');
        uint amount = influencer[msg.sender].totalAmount;
        influencer[msg.sender].totalAmount=0;
        if(!influencerAddress.send(1 ether)){
            influencer[msg.sender].totalAmount=amount;
            return false;
        }
        return true;
    }
    
    
    function getFee() public returns (bool) {
        require(influencer[msg.sender].contractSignedTime!=0,'Contract neverSigned');
        require(block.timestamp>=influencer[msg.sender].contractEndTime,'ContractPeriod not Ended Yet');
        uint amount = influencer[msg.sender].totalAmount;
        influencer[msg.sender].totalAmount=0;
        address payable add=payable(msg.sender);
        if(!add.send(1 ether)){
            influencer[msg.sender].totalAmount=amount;
            return false;
        }
        return true;
    }

    
    function addressOfRequestedAddress()external view OnlyOwner returns(address[] memory){
        return influencerRequestedToParticipate;
    }
    
    function appveInvolvement(address infuencer)public OnlyOwner{
        require(Request_Info[infuencer].requested_at!=0,'Given influencer not Requested');
        Request_Info[infuencer].approved=true;
    }
}