pragma solidity ^0.4.24; // Set compiler version

// Token contract
contract Facito {
    string public constant name = "Facito"; // Name
    string public constant symbol = "FAC"; // Symbol
    uint8 public constant decimals = 18; // Set precision points
    uint256 public totalSupply; // Store total supply

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
        balanceOf[this] = _initialSupply; // Set contract balance
        totalSupply = _initialSupply; // Set total supply
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

        require(this.transfer(msg.sender, (balanceOf[this]/totalSupply)*2), "Transaction failed"); // Transfer coins to reader
        require(this.transfer(articles[_id].Author, (balanceOf[this]/totalSupply)*10), "Transaction failed"); // Transfer coins to author

        return true; // Return success
    }

    /* POST UPVOTE/DOWNVOTE METHODs */

    function upvotePost(bytes32 _id) public {
        if (articles[_id].Upvoters[msg.sender] == 1) { // Check already upvoted
            articles[_id].Upvoters[msg.sender] == 0; // Remove upvote

            articles[_id].Upvotes--; // Decrement

            emit DownvotedPost(_id, articles[_id].Author, msg.sender, articles[_id].Title); // Emit event
        } else if (articles[_id].Upvoters[msg.sender] != 1) { // Check not already upvoted
            if (articles[_id].UnspentOutputs[msg.sender] != 1) { // Check not already spent
                require(this.transfer(msg.sender, (balanceOf[this]/totalSupply)*4), "Transaction failed"); // Transfer coins to reader
                require(this.transfer(articles[_id].Author, (balanceOf[this]/totalSupply)*15), "Transaction failed"); // Transfer coins to author
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
                require(this.transfer(msg.sender, (balanceOf[this]/totalSupply)*1), "Transaction failed"); // Transfer coins to reader
                require(this.transfer(articles[_articleID].Threads[_threadID].Comments[_commentID].Author, (balanceOf[this]/totalSupply)*5), "Transaction failed"); // Transfer coins to author
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