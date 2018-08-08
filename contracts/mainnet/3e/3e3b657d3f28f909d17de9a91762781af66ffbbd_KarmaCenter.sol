pragma solidity ^0.4.19;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

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
  * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
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


interface ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}


contract PostFactory {
    using SafeMath for uint256;

    string public name = "Karma Factory";
    string public constant SYMBOL = "KC";

    uint256 private postId = 1;
    // post IDs start at 1, just like arrays do :)

    mapping (address => mapping (uint256 => bool)) upvotedPost;

    mapping (address => mapping (uint256 => bool)) downvotedPost;

    // checks if a post exists
    mapping (uint256 => bool) postExists;

    struct Post {
        string link;
        address poster;
        uint256 voteCount;
        uint64 datePosted;
    }

    mapping (uint256 => Post) posts; // ties postId to a post

    mapping(string => uint256) linkToPostId; // Ties a post&#39;s link to it&#39;s ID

    function createPost(string _link) public returns(uint256) {

        Post memory post = Post({
            link: _link,
            poster: msg.sender,
            voteCount: 0,
            datePosted: uint64(now)
        });

        posts[postId] = post;
        linkToPostId[_link] = postId;
        postExists[postId] = true;

        uint256 currentPostId = postId;
        incrementpostId();

        return currentPostId;
    }

    function updoot(uint256 _postId) public {
        require(postExists[_postId]);
        upvotedPost[msg.sender][_postId] = true;
        downvotedPost[msg.sender][_postId] = false;
        posts[_postId].voteCount = posts[_postId].voteCount.add(1);
    }

    function downdoot(uint256 _postId) public {
        require(postExists[_postId]);
        require(posts[_postId].voteCount >= 1);
        upvotedPost[msg.sender][_postId] = false;
        downvotedPost[msg.sender][_postId] = true;
        posts[_postId].voteCount = posts[_postId].voteCount.sub(1);
    }

    function getPostLink(uint256 _postId) public view returns(string) {
        return posts[_postId].link;
    }

    function getPostPoster(uint256 _postId) public view returns(address) {
        return posts[_postId].poster;
    }

    function getPostVoteCount(uint256 _postId) public view returns(uint256) {
        return posts[_postId].voteCount;
    }

    function getLinkToPostId(string _link) public view returns(uint256) {
        return linkToPostId[_link];
    }

    function getDatePosted(uint256 _postId) public view returns(uint64) {
        return posts[_postId].datePosted;
    }

    function incrementpostId() internal {
        postId = postId.add(1);
    }

}


contract KarmaCenter is PostFactory {
    using SafeMath for uint256;

    // The KarmaCoin token being minted
    ERC20Basic public token;
    
    // My wallet
    address private controller;

    event GameWon(address indexed winner, uint256 valueUnlocked);

    //Constructor
    function KarmaCenter(ERC20Basic _token) public {
        token = _token;
        controller = msg.sender;
    }

    function () public payable {
        controller.transfer(msg.value);
    }

    function updoot(uint256 _postId) public {
        require(postExists[_postId]);
        require(token.balanceOf(msg.sender) > 0);
        upvotedPost[msg.sender][_postId] = true;
        downvotedPost[msg.sender][_postId] = false;
        posts[_postId].voteCount = posts[_postId].voteCount.add(1);
        address poster = posts[_postId].poster;
        token.transfer(poster, 1);
    }

    function downdoot(uint256 _postId) public {
        require(postExists[_postId]);
        require(posts[_postId].voteCount >= 1);
        upvotedPost[msg.sender][_postId] = false;
        downvotedPost[msg.sender][_postId] = true;
        posts[_postId].voteCount = posts[_postId].voteCount.sub(1);
    }

}