pragma solidity ^0.4.25;

/*
* Token Contract
*/
contract ERC20 {
  uint public totalSupply;
  function balanceOf(address who) public constant returns (uint);
  function allowance(address owner, address spender) public constant returns (uint);
  function transfer(address to, uint value) public ;
  function transferFrom(address from, address to, uint value) public returns (bool ok);
  function approve(address spender, uint value) public returns (bool ok);
  function mintToken(address to, uint256 value) public returns (uint256);
  function changeTransfer(bool allowed) public;
}

/*
* SafeMathLib Library
*/
library SafeMathLib {

  function times(uint a, uint b) public pure returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
  
}

/*
* Amplifi Campaign Contract
*/
contract AmplifiCampaign {
    using SafeMathLib for uint;
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
    uint public maxSubLimit;
    uint public postCount;
    uint public verifierStake = 5000000000000000000000; // 5000 AMP
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
    event ReceivedTokens(address _from, uint256 _value, address _token, bytes _type);
    
    constructor(address[] _addresses,uint _campaignID,uint _start,uint _end,uint[] _tiers,uint[] _tierPayouts,uint[] _feeDetails,uint[] _durationDetails,uint _maxSubLimit) public {
        require(_tiers.length != 0 && _tierPayouts.length != 0 && _tiers.length == _tierPayouts.length);
        require(_addresses.length==2 && _feeDetails.length==2 && _durationDetails.length==3);
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
        verifierPayouts[msg.sender] = verifierPayouts[msg.sender].add(verifiPayout);
    }
    
    /*  Arbify action for verified post.
        _company: true- CompanyArbifi, false - Influencer Arbifi
    */
    function arbifi(uint _postID,bool _company) public isOpen {
        //require(now > verifiEnd + 1 minutes && now < arbifiEnd);
        require(token.transferFrom(msg.sender,address(this),arbifiFee));
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
                verifierPayouts[post.verifiedBy] = verifierPayouts[post.verifiedBy].sub(verifiPayout);
                //token.transfer(post.arbifiedBy,arbifiFee);
                token.transferFrom(company,post.arbifiedBy,arbifiFee);
            }
            post.reVerifiedBy = msg.sender;
        }
        else{
            require(post.status == uint(PostStatus.ArbifiedInfluencer));
            if(_decision){
                post.payout = tier.payout;
                post.status = uint(PostStatus.Approved);
                verifierPayouts[post.verifiedBy] = verifierPayouts[post.verifiedBy].sub(verifiPayout);
                //token.transfer(post.arbifiedBy,arbifiFee);
                token.transferFrom(company,post.arbifiedBy,arbifiFee);
            }
            else{
                post.payout = 0;
                post.status = uint(PostStatus.Declined);
            }
            post.reVerifiedBy = msg.sender;
        }
        verifierPayouts[msg.sender] = verifierPayouts[msg.sender].add(verifiPayout);
    }
    
    /*  Ether withdraw for influencer to a single post*/
    function withdraw(uint _postID) public {
        //require(now > arbifiEnd + 1 minutes);
        require(posts[_postID].status == uint(PostStatus.Approved) && posts[_postID].postedBy ==  msg.sender);
        require(posts[_postID].payout < address(this).balance);
        Post storage post = posts[_postID];
        post.status = uint(PostStatus.Paid);
        uint payout = post.payout;
        msg.sender.transfer(payout);
    }
    
    /*  Token withdraw for verifier.
        The contract create user must pay this contract to spend tokens.
    */
    function withdrawToken() public {
        //require(now > arbifiEnd + 1 minutes);
        require(verifierPayouts[msg.sender] > 0);
        uint payout = verifierPayouts[msg.sender];
        verifierPayouts[msg.sender] = 0;
        //token.transfer(msg.sender,payout);
        token.transferFrom(company,msg.sender,payout);
    }
    
    /* Ether pay function */
    function() public payable { }
    
    /* Transfer unused ether back to admin account */
    function transferToAdmin() onlyAdmin public returns(bool) {
        admin.transfer(address(this).balance);
        return true;
    }
}