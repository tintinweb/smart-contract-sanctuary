pragma solidity ^0.4.23;

contract ERC20 {
  uint public totalSupply;
  function balanceOf(address who) public constant returns (uint);
  function allowance(address owner, address spender) public constant returns (uint);
  function transfer(address to, uint value) public returns (bool ok);
  function transferFrom(address from, address to, uint value) public returns (bool ok);
  function approve(address spender, uint value) public returns (bool ok);
  function mintToken(address to, uint256 value) public returns (uint256);
  function changeTransfer(bool allowed) public;
}

contract AmplifiCampaign {
    
    ERC20 public token; 
    address public admin; 
    address public company; 
    uint public campaignID; 
    uint public campaignStart;
    uint public campaignEnd;
    uint public verifiEnd;
    uint public arbifiEnd;
    uint public reVerifiEnd;
    bool public open;
    uint public verifiPayout;
    uint public arbifiFee;
    uint public arbifiRefundFee;
    uint public arbifiPlatformFee;
    uint public reVerifiPayout;
    uint public maxSubLimit;
    uint public postCount;
    uint public verifierStake = 5000;
    
    struct Post{
        address postedBy;
        uint tierID;
        uint postID;
        uint status;
        address verifiedBy;
        address arbifiedBy;
        address reVerifiedBy;
        uint256 payout;
    }
    mapping (uint => Post) public posts;
    uint[] public postList;
    
    struct Tier{
        uint tierID;
        uint payout;
    }
    mapping (uint => Tier) public tiers;
    
    mapping(address => uint256) public verifierPayouts;

    enum Type { Influencer, Company, Verifier }
    enum PostStatus { New, Approved, Declined, ArbifiedCompany, ArbifiedInfluencer, Paid }
    enum Status { Success, Failed }
    event ReceivedTokens(address _from, uint256 _value, address _token, string _type);
    
    constructor(address[] _addresses,uint _campaignID,uint _start,uint _end,uint[] _tiers,uint[] _tierPayouts,uint[] _feeDetails,uint[] _durationDetails,uint _maxSubLimit) public {
        require(_tiers.length != 0 && _tierPayouts.length != 0 && _tiers.length == _tierPayouts.length);
        require(_addresses.length==2 && _feeDetails.length==5 && _durationDetails.length==3);
        //require(_start != 0 && _start > now);
        require(_end != 0 && _end > now);
        require(_start < _end);
        open = true;  
        campaignID = _campaignID;
        campaignStart = _start;
        campaignEnd = _end;  
        admin = _addresses[0];
        token = ERC20(_addresses[1]);
        company = msg.sender;
        
        for(uint i=0; i< _tiers.length; i++) {
            Tier storage tier = tiers[_tiers[i]];
            tier.tierID = _tiers[i];
            tier.payout = _tierPayouts[i];
        }
        
        verifiPayout = _feeDetails[0];
        arbifiFee = _feeDetails[1];
        arbifiRefundFee = _feeDetails[2];
        arbifiPlatformFee = _feeDetails[3];
        reVerifiPayout = _feeDetails[4];
        verifiEnd = _durationDetails[0];
        arbifiEnd = _durationDetails[1];
        reVerifiEnd = _durationDetails[2];
        maxSubLimit = _maxSubLimit;
    }
    
    modifier isOpen() {
        require(open);
        _;
    }
    
    modifier onlyAdmin() {
        require (msg.sender == admin);
        _;
    }

    /* Post Submission */
    function addPost(uint _postID,uint _tierID) public isOpen { 
        // require(now > campaignStart && now < verifiEnd - 1 days);
        require(postCount < maxSubLimit && _postID!=0 && _tierID!=0 && posts[_postID].postID == 0);
        Post storage post = posts[_postID];
        post.postedBy       = msg.sender;
        post.tierID         = _tierID;
        post.postID         = _postID;
        postList.push(_postID);
        postCount++;
    }
    
    /*  Verify action for a post submission.
        _decision: true - approve, false - decline 
    */
    function verifiPost(uint _postID, bool _decision) public  isOpen { 
        //require(now > campaignEnd + 1 minutes && now < verifiEnd && token.balanceOf(msg.sender) >= verifierStake);
        require(posts[_postID].status == uint(PostStatus.New) && posts[_postID].verifiedBy == address(0));
        Post storage post = posts[_postID];
        if(_decision){
            Tier memory tier = tiers[posts[_postID].tierID];
            post.payout = tier.payout;
            post.status = uint(PostStatus.Approved);
        }
        else{
            post.status = uint(PostStatus.Declined);
        }
        post.verifiedBy = msg.sender;
        verifierPayouts[msg.sender] += verifiPayout;
    }
    
    /*  Arbify action for verified post.
        _company: true- CompanyArbifi, false - Influencer Arbifi
    */
    function arbifi(uint _postID,bool _company) public isOpen {
        //require(now > verifiEnd + 1 minutes && now < arbifiEnd);
        require(posts[_postID].arbifiedBy == address(0));
        Post storage post = posts[_postID];
        if(_company){
            require(company == msg.sender && post.status == uint(PostStatus.Approved));
            post.status = uint(PostStatus.ArbifiedCompany);    
            post.arbifiedBy = msg.sender;
        }
        else{
            require(posts[_postID].postedBy == msg.sender && post.status == uint(PostStatus.Declined));
            post.status = uint(PostStatus.ArbifiedInfluencer);
            post.arbifiedBy = msg.sender;
        }
    }
    
    /*  Reverify action for arbified post.
        _decision: true - approve, false - decline.
        _company: true- CompanyArbifi, false - Influencer Arbifi
    */
    function reVerifiPost(uint _postID,bool _decision,bool _company) public isOpen { 
        //require(now > verifiEnd + 1 minutes && now < reVerifiEnd && token.balanceOf(msg.sender) >= verifierStake);
        require(posts[_postID].reVerifiedBy == address(0));
        Post storage post = posts[_postID];
        Tier memory tier = tiers[posts[_postID].tierID];
        if(_company){
            require(post.status == uint(PostStatus.ArbifiedCompany));
            if(_decision){
                post.payout = tier.payout;
                post.status = uint(PostStatus.Approved);
            }
            else{
                post.payout = 0;
                post.status = uint(PostStatus.Declined);
                // TO DO:  Reduce token from previous verifier.    
            }
            post.reVerifiedBy = msg.sender;
        }
        else{
            require(post.status == uint(PostStatus.ArbifiedInfluencer));
            if(_decision){
                post.payout = tier.payout;
                post.status = uint(PostStatus.Approved);
                // TO DO:  Reduce token from previous verifier.    
            }
            else{
                post.payout = 0;
                post.status = uint(PostStatus.Declined);
            }
            post.reVerifiedBy = msg.sender;
        }
        verifierPayouts[msg.sender] += verifiPayout;
    }
    
    /*  Ether withdraw for influencer to a single post*/
    function withdraw(uint _postID) public {
        //require(now > arbifiEnd + 1 minutes);
        require(posts[_postID].status == uint(PostStatus.Approved) && posts[_postID].postedBy ==  msg.sender);
        require(posts[_postID].payout < address(this).balance);
        Post storage post = posts[_postID];
        post.status = uint(PostStatus.Paid);
        uint256 payout = post.payout;
        msg.sender.transfer(payout);
    }
    
    /*  Token withdraw for verifier.
        The contract create user must approve this contract to spend tokens on behalf.
    */
    function withdrawToken() public {
        //require(now > arbifiEnd + 1 minutes);
        require(verifierPayouts[msg.sender] > 0);
        uint256 payout = verifierPayouts[msg.sender];
        token.transferFrom(company,msg.sender,payout);
        verifierPayouts[msg.sender] = 0;
    }
    
    /* Ether pay function */
    function() public payable { }
    
    /* Transfer unused ether back to admin account */
    function transferToAdmin() onlyAdmin public returns(bool) {
        admin.transfer(address(this).balance);
        return true;
    }
    
    function receiveApproval(address _from, uint256 _value, address _token, string _data) public {
        ERC20 t = ERC20(_token);
        require(t.transferFrom(_from,  this, _value));
        emit ReceivedTokens(_from, _value, _token, _data);
    }
}