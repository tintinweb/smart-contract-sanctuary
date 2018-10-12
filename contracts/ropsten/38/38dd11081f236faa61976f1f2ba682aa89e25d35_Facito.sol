pragma solidity ^0.4.24; // Set compiler version

// Token contract
contract Facito {
    using SafeMath for uint256;

    string public constant name = "Facito"; // Name
    string public constant symbol = "FAC"; // Symbol
    uint8 public constant decimals = 18; // Set precision points
    uint256 public decimalUnits = 1000000000000000000;
    uint256 public totalSupply; // Store total supply
    uint256 public baseReward;

    mapping(bytes32 => Article) public articles; // Store articles

    event Transfer (
        address indexed _from,
        address indexed _to,
        uint256 _value
    );

    event Approve (
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );

    event NewArticle (
        bytes32 _ID,
        address _author,
        string _title
    );

    event ReadArticle (
        bytes32 _ID,
        address _author,
        address _reader,
        string _title
    );

    event UpvotedPost (
        bytes32 _ID, 
        address _author,
        address _upvoter,
        string _content
    );

    event DownvotedPost (
        bytes32 _ID, 
        address _author,
        address _downvoter,
        string _content
    );

    event ArticleError (
        string _message,
        address sender,
        bytes32 _ID
    );

    event FoundSpent (
        bool spent,
        address sender,
        bytes32 _ID
    );

    struct Article {
        string Title;
        bytes32 ID;
        string Content;
        string HeaderSource;
        address Author;
        uint256 BlockNumber;
        uint256 Views;

        uint256 Upvotes;
        mapping(address => uint) Upvoters; // 0: Not upvoted, 1: upvoted

        uint256 Downvotes;
        mapping(address => uint) Downvoters; // 0: Not downvoted, 1: downvoted

        mapping(address => uint) UnspentOutputs; // 0: unspent, 1: spent

        mapping(bytes32 => Thread) Threads;
    }

    struct Comment {
        bytes32 ID;
        string Content;
        address Author;
        uint256 BlockNumber;

        uint256 Upvotes;
        mapping(address => uint) Upvoters; // 0: Not upvoted, 1: upvoted

        uint256 Downvotes;
        mapping(address => uint) Downvoters; // 0: Not downvoted, 1: downvoted

        mapping(address => uint) UnspentOutputs; // 0: unspent, 1: spent
    }

    struct Thread {
        bytes32 ID;
        mapping(bytes32 => Comment) Comments;
        address Author;
        uint256 BlockNumber;
    }

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    constructor(uint256 _initialSupply) public {
        _initialSupply = _initialSupply.mul(decimalUnits); // Append decimal points

        balanceOf[this] = _initialSupply; // Set contract balance
        totalSupply = _initialSupply; // Set total supply
        baseReward = decimalUnits; // Append decimals to base reward
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value, "Insufficient balance"); // Check for invalid balance

        balanceOf[msg.sender] -= _value; // Set sender balance
        balanceOf[_to] += _value; // Set recipient balance

        emit Transfer(msg.sender, _to, _value); // Emit transfer event

        return true; // Return success
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value; // Set allowance

        emit Approve(msg.sender, _spender, _value); // Emit approve event

        return true; // Return success
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= balanceOf[_from], "Insufficient balance"); // Check allowance is valid
        require(_value <= allowance[_from][msg.sender], "Insufficient balance"); // Check allowance is valid

        balanceOf[_from] -= _value; // Remove from sender
        balanceOf[_to] += _value; // Add to destination

        allowance[_from][msg.sender] -= _value; // Remove allowance

        emit Transfer(_from, _to, _value); // Emit transfer event

        return true; // Return success
    }

    // END ERC20 IMPLEMENTATION

    /* BEGIN BASIC ARTICLE METHODS */

    function newArticle(string _title, string _content, string _headerSource) public returns (bool success) {
        bytes32 _id = keccak256(abi.encodePacked(_title, _content, _headerSource, msg.sender, block.number)); // Hash ID

        emit NewArticle(_id, msg.sender, _title); // Emit new article

        Article memory article = Article(_title, _id, _content, _headerSource, msg.sender, block.number, 0, 0, 0); // Initialize article

        articles[_id] = article; // Push new article

        return true; // Return success
    }

    function readArticle(bytes32 _id) public returns (bool success) {
        emit ReadArticle(_id, articles[_id].Author, msg.sender, articles[_id].Title); // Emit read article

        if (articles[_id].UnspentOutputs[msg.sender] == 1) {
            emit ArticleError("Article already read", msg.sender, _id); // Emit error
        } else if (articles[_id].Author == msg.sender) {
            emit ArticleError("Author cannot read own article", msg.sender, _id); // Emit error
        }

        require(articles[_id].UnspentOutputs[msg.sender] != 1, "Article already read"); // Check article hasn&#39;t already been read
        require(articles[_id].Author != msg.sender, "Author cannot read own article"); // Check author isn&#39;t reading own article

        articles[_id].Views++; // Increment view count

        articles[_id].UnspentOutputs[msg.sender] = 1; // Set spent

        uint256 reward = uint256(2).mul((balanceOf[this].div(totalSupply)).mul(uint256(100))).mul(baseReward);

        require(this.transfer(msg.sender, reward), "Transaction failed"); // Transfer coins to reader

        reward = uint256(10).mul((balanceOf[this].div(totalSupply)).mul(uint256(100))).mul(baseReward);

        require(this.transfer(articles[_id].Author, reward), "Transaction failed"); // Transfer coins to author

        return true; // Return success
    }

    /* END BASIC ARTICLE METHODS */

    /* BEGIN BASIC COMMENT METHODS */

    function newComment(bytes32 _postID, string _content) public returns (bool success) {
        bytes32 _id = keccak256(abi.encodePacked(_postID, _content, msg.sender, block.number)); // Hash ID

        Comment memory comment = Comment(_id, _content, msg.sender, block.number, 0, 0); // Initialize comment

        articles[_postID].Threads[_id].Comments[_id] = comment; // Add comment

        return true; // Return success
    }

    function newThreadComment(bytes32 _postID, bytes32 _threadID, string _content) public returns (bool success) {
        bytes32 _id = keccak256(abi.encodePacked(_postID, _threadID, _content, msg.sender, block.number)); // Hash ID

        Comment memory comment = Comment(_id, _content, msg.sender, block.number, 0, 0); // Initialize comment

        articles[_postID].Threads[_threadID].Comments[_id] = comment; // Add comment

        return true; // Return success
    }

    /* END BASIC COMMENT METHODS */

    /* POST UPVOTE/DOWNVOTE METHODs */

    function upvotePost(bytes32 _id) public {
        if (articles[_id].Upvoters[msg.sender] == 1) { // Check already upvoted
            articles[_id].Upvoters[msg.sender] == 0; // Remove upvote

            articles[_id].Upvotes--; // Decrement

            emit DownvotedPost(_id, articles[_id].Author, msg.sender, articles[_id].Title); // Emit event
        } else if (articles[_id].Upvoters[msg.sender] != 1) { // Check not already upvoted
            if (articles[_id].UnspentOutputs[msg.sender] != 1) { // Check not already spent
                emit FoundSpent(false, msg.sender, _id);

                uint256 reward = uint256(4).mul((balanceOf[this].div(totalSupply)).mul(uint256(100))).mul(baseReward);

                require(this.transfer(msg.sender, reward), "Transaction failed"); // Transfer coins to reader

                reward = uint256(15).mul((balanceOf[this].div(totalSupply)).mul(uint256(100))).mul(baseReward);

                require(this.transfer(articles[_id].Author, reward), "Transaction failed"); // Transfer coins to author
            } else {
                emit FoundSpent(true, msg.sender, _id);
            }

            articles[_id].Upvoters[msg.sender] == 1; // Add upvote

            articles[_id].Upvotes++; // Increment

            emit UpvotedPost(_id, articles[_id].Author, msg.sender, articles[_id].Title); // Emit event
        }
    }

    function downvotePost(bytes32 _id) public {
        if (articles[_id].Downvoters[msg.sender] == 1) { // Check already downvoted
            articles[_id].Downvoters[msg.sender] = 0; // Remove downvote

            articles[_id].Downvotes--; // Decrement

            emit UpvotedPost(_id, articles[_id].Author, msg.sender, articles[_id].Title); // Emit event
        } else if (articles[_id].Downvoters[msg.sender] != 1) { // Check not already downvoted
            articles[_id].Downvoters[msg.sender] = 1; // Add downvote

            articles[_id].Downvotes++; // Increment

            emit DownvotedPost(_id, articles[_id].Author, msg.sender, articles[_id].Title); // Emit event
        }
    }

    /* END POST UPVOTE/DOWNVOTE METHODS */

    /* COMMENT UPVOTE/DOWNVOTE METHODS */

    function upvoteComment(bytes32 _commentID, bytes32 _threadID, bytes32 _articleID) public {
        if (articles[_articleID].Threads[_threadID].Comments[_commentID].Upvoters[msg.sender] == 1) { // Check already upvoted
            articles[_articleID].Threads[_threadID].Comments[_commentID].Upvoters[msg.sender] = 0; // Remove upvote

            articles[_articleID].Threads[_threadID].Comments[_commentID].Upvotes--; // Decrement

            emit DownvotedPost(_commentID, articles[_articleID].Threads[_threadID].Comments[_commentID].Author, msg.sender, articles[_articleID].Threads[_threadID].Comments[_commentID].Content); // Emit event
        } else if (articles[_articleID].Threads[_threadID].Comments[_commentID].Upvoters[msg.sender] != 1) { // Check not already upvoted
            if (articles[_articleID].Threads[_threadID].Comments[_commentID].UnspentOutputs[msg.sender] != 1) { // Check not already spent
                emit FoundSpent(false, msg.sender, _commentID);

                uint256 reward = uint256(1).mul((balanceOf[this].div(totalSupply)).mul(uint256(100))).mul(baseReward);

                require(this.transfer(msg.sender, reward), "Transaction failed"); // Transfer coins to reader

                reward = uint256(5).mul((balanceOf[this].div(totalSupply)).mul(uint256(100))).mul(baseReward);

                require(this.transfer(articles[_articleID].Threads[_threadID].Comments[_commentID].Author, reward), "Transaction failed"); // Transfer coins to author
            } else {
                emit FoundSpent(false, msg.sender, _commentID);
            }

            articles[_articleID].Threads[_threadID].Comments[_commentID].Upvoters[msg.sender] = 1; // Add upvote

            articles[_articleID].Threads[_threadID].Comments[_commentID].Upvotes++; // Increment

            emit UpvotedPost(_commentID, articles[_articleID].Threads[_threadID].Comments[_commentID].Author, msg.sender, articles[_articleID].Threads[_threadID].Comments[_commentID].Content); // Emit event
        }
    }

    function downvoteComment(bytes32 _commentID, bytes32 _threadID, bytes32 _articleID) public {
        if (articles[_articleID].Threads[_threadID].Comments[_commentID].Downvoters[msg.sender] == 1) { // Check already downvoted
            articles[_articleID].Threads[_threadID].Comments[_commentID].Downvoters[msg.sender] = 0; // Remove downvote

            articles[_articleID].Threads[_threadID].Comments[_commentID].Downvotes--; // Decrement

            emit UpvotedPost(_commentID, articles[_articleID].Threads[_threadID].Comments[_commentID].Author, msg.sender, articles[_articleID].Threads[_threadID].Comments[_commentID].Content); // Emit event
        } else if (articles[_articleID].Threads[_threadID].Comments[_commentID].Downvoters[msg.sender] != 1) { // Check not already downvoted
            articles[_articleID].Threads[_threadID].Comments[_commentID].Downvoters[msg.sender] = 1; // Add downvote

            articles[_articleID].Threads[_threadID].Comments[_commentID].Downvotes++; // Increment

            emit DownvotedPost(_commentID, articles[_articleID].Threads[_threadID].Comments[_commentID].Author, msg.sender, articles[_articleID].Threads[_threadID].Comments[_commentID].Content); // Emit event
        }
    }

    /* END COMMENT UPVOTE/DOWNVOTE METHODS */
}

/*
TODO:
    - comment initializer
    - thread initializer
*/

/**
* @title SafeMath
* @dev Math operations with safety checks that revert on error
*/
library SafeMath {

    /**
    * @dev Multiplies two numbers, reverts on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring &#39;a&#39; not being zero, but the
        // benefit is lost if &#39;b&#39; is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "operation failed");

        return c;
    }

    /**
    * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "operation failed"); // Solidity only automatically asserts when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold

        return c;
    }

    /**
    * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "operation failed");
        uint256 c = a - b;

        return c;
    }

    /**
    * @dev Adds two numbers, reverts on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "operation failed");

        return c;
    }

    /**
    * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
    * reverts when dividing by zero.
    */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "operation failed");
        return a % b;
    }
}