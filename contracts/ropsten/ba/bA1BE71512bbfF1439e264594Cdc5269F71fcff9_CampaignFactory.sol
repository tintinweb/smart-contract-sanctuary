// SPDX-License-Identifier: MIT

pragma solidity 0.4.22;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {require((c = a + b) >= b, "SafeMath: Add Overflow");}
    function sub(uint256 a, uint256 b) internal pure returns (uint256 c) {require((c = a - b) <= a, "SafeMath: Underflow");}
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {require(b == 0 || (c = a * b)/b == a, "SafeMath: Mul Overflow");}
    function to128(uint256 a) internal pure returns (uint128 c) {
        require(a <= uint128(-1), "SafeMath: uint128 Overflow");
        c = uint128(a);
    }
}

library SafeMath128 {
    function add(uint128 a, uint128 b) internal pure returns (uint128 c) {require((c = a + b) >= b, "SafeMath: Add Overflow");}
    function sub(uint128 a, uint128 b) internal pure returns (uint128 c) {require((c = a - b) <= a, "SafeMath: Underflow");}
}

contract CampaignFactory {
    Compaign[] public deployedCampaigns;

    function createCampaign(string memory campaigntitle) public {
        Compaign newCampaign = new Compaign(campaigntitle,msg.sender);
        deployedCampaigns.push(newCampaign);
    }

    function getDeployedCampaigns() public view returns (Compaign[] memory) {
        return deployedCampaigns;
    }
}

contract Compaign {
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
    event MultiTransfer(
        address indexed _from,
        uint indexed _value,
        address _to,
        uint _amount
    );
    
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
    
    constructor(string  memory campaigntitle,address owner) public {
        campaigner=owner;
        campaignStartingTime = block.timestamp;
        campaign=campaigntitle;
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
        //influencerRequestedToParticipate.pop();
    }
    
    function appveInvolvement(address influencer)public OnlyOwner{
        require(Request_Info[influencer].requested_at!=0,'Given influencer not Requested');
        Request_Info[influencer].approved=true;
        removeFromPendigRequestList(influencer);
    }
    
    function requestToparticipateInCampaign(uint followers, string  platform,uint timePeriodOfParticipation, uint noOfEngagementOffering) external {
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
    
    function getinvolveAsInfluencer(string  postURI) external {
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
          Request_Info[msg.sender]=request_Info(0,'',0,0,0,false);
    }
    
       // function payInfluencerMultiple(address[]  influencerAddress, uint[] memory totalLikesGet) payable public OnlyOwner  returns(bool){
          
        //  uint256 len = influencerAddress.length;
       //   for (uint256 i = 0; i < len; i++) {
          //  _payInfluencer(influencerAddress[i], totalLikesGet[i]);
        //   influencerAddress[i].transfer(totalLikesGet[i]);
       // }
       // }
    
     function payInfluencerMultiple(address[] memory _influencerAddress, uint[] memory _amounts)
    payable public returns(bool)
    {
        uint toReturn = msg.value;
        for (uint i = 0; i < _influencerAddress.length; i++) {
            _safeTransfer(_influencerAddress[i], _amounts[i]);
            toReturn = SafeMath.sub(toReturn, _amounts[i]);
        }
        _safeTransfer(msg.sender, toReturn);
        return true;
    }
    /// @notice `_safeTransfer` is used internally to transfer funds safely.
    function _safeTransfer(address  _to, uint  _amount) internal {
       
        _to.transfer(_amount);
    }
    
    
        function payInfluencer(address  influencerAddress, uint totalLikesGet) public OnlyOwner payable returns(bool){
        require(influencer_info[influencerAddress].contractSignedTime!=0,'Contract neverSigned');
        require(block.timestamp>=influencer_info[influencerAddress].contractEndTime,'ContractPeriod not Ended Yet');
        require(influencer_info[influencerAddress].totalEngagementSigned<=totalLikesGet,'Contract not fulfilled');
        require(influencer_info[influencerAddress].totalAmount!=0,'Already paid for the work');
        require(influencer_info[influencerAddress].totalAmount<=msg.value,'Amount less then the fee');
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
    
    function getFee(uint totalLikesGet) public returns (bool) {
        require(influencer_info[msg.sender].contractSignedTime!=0,'Contract neverSigned');
        require(block.timestamp>=influencer_info[msg.sender].contractEndTime,'ContractPeriod not Ended Yet');
        require(influencer_info[msg.sender].totalEngagementSigned<=totalLikesGet,'Contract not fulfilled');
        require(influencer_info[msg.sender].totalAmount!=0,'Already paid for the work');
        require(influencer_info[msg.sender].totalAmount<=getcontractBalance(),'ContractBalance is not sufficient');
        uint amount = influencer_info[msg.sender].totalAmount;
        influencer_info[msg.sender].paid=true;
        influencer_info[msg.sender].totalAmount=0;
        address  add=(msg.sender);
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
        require(msg.value > .01 ether);
        contractBalance+=msg.value;
    }
    
}

