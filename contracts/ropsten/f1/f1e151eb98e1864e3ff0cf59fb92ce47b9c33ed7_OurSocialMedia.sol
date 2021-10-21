/**
 *Submitted for verification at Etherscan.io on 2021-10-21
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract OurSocialMedia {
    string public contractName = "Our Social Media (OSM)";
    // -------------start--profile,account-------------//
    struct Profile {
        string name;
        string userid; // uniq
        uint256 Followers;
    }

    mapping(address => bool) public isAccountCreatedOf;
    mapping(address => Profile) public profileOf;

    mapping(string => bool) public isUserIDExist;
    // mapping(string => Profile) public profileByID;

    // -------------end--profile,account-------------//

    // -------------start--Posts,comments,follow,tip-------------//
    uint256 public maxContentChar = 420;
    uint256 public maxCommentChar = 220;
    struct Post {
        uint256 id;
        uint256 createTime;
        string content; //text in post
        string media; // photo or video
        uint256 tipAmount; // money tipded by someone
        address payable author;
    }
    struct Comment {
        string comment;
        address by;
    }

    uint256 public totalPosts = 0;
    mapping(uint256 => Post) public allPosts;
    mapping(address => uint256[]) public postsOf;

    mapping(address => address[]) public userFollowTo;

    mapping(uint256 => Comment[]) public commentsOf;
    // -------------end--Posts,comments,follow,tip-------------//

    //events
    event postCreadedEvent(
        uint256 id,
        string content,
        string media,
        address author
    );

    event postTipedEvent(uint256 id, uint256 tipAmount, address by);
    event commentEvent(uint256 id, string comment, address by);

    constructor(uint256 _maxCharInPost, uint256 _maxCharInComment) {
        maxContentChar = _maxCharInPost;
        maxCommentChar = _maxCharInComment;
    }

    // -------------start--profile,account-------------//

    function createAccount(string memory _name, string memory _userid) public {
        require(
            getStringLength(_name) > 0 && getStringLength(_userid) > 0,
            "name or userid is not added"
        );
        require(!isAccountCreatedOf[msg.sender], "account already created");
        require(
            !isUserIDExist[_userid],
            "user id is already exist please select new"
        );
        profileOf[msg.sender] = Profile(_name, _userid, 0);
        isAccountCreatedOf[msg.sender] = true;
        isUserIDExist[_userid] = true;
    }

    // -------------end--profile,account-------------//

    modifier onlyUserWhoProfileCreated() {
        require(isAccountCreatedOf[msg.sender], "user's account not created. Please create account first.");
        _;
    }

    // -------------start--Posts,comments,follow,tip-------------//

    function createPost(string memory _content, string memory _media) public onlyUserWhoProfileCreated {
        require(
            getStringLength(_content) > 0 || getStringLength(_media) > 0,
            "Content or media is not added"
        );
        require(
            getStringLength(_content) <= maxContentChar,
            "total charcters in string must be less then maxContentChar"
        );

        totalPosts++;

        allPosts[totalPosts].id = totalPosts;
        allPosts[totalPosts].createTime = block.timestamp;
        allPosts[totalPosts].content = _content;
        allPosts[totalPosts].media = _media;
        allPosts[totalPosts].tipAmount = 0;
        allPosts[totalPosts].author = payable(msg.sender);

        postsOf[msg.sender].push(totalPosts);

        emit postCreadedEvent(totalPosts, _content, _media, msg.sender);
    }

    function commentOnPost(uint256 _id, string memory _comment) public onlyUserWhoProfileCreated {
        require(
            totalPosts >= _id && getStringLength(_comment) > 0,
            "id is wrong or comment is not written"
        );

        require(
            getStringLength(_comment) <= maxCommentChar,
            "total charcters in string must be less then maxCommentChar"
        );
        commentsOf[_id].push(Comment(_comment, msg.sender));

        emit commentEvent(_id, _comment, msg.sender);
    }

    function commentCountOfPost(uint256 _id) public view returns (uint256) {
        return commentsOf[_id].length;
    }

    function tipPost(uint256 _postId) public payable {
        require(totalPosts >= _postId);

        address payable _author = allPosts[_postId].author;
        _author.transfer(msg.value);
        allPosts[_postId].tipAmount += msg.value;

        emit postTipedEvent(_postId, msg.value, msg.sender);
    }

    function follow(address _address) public onlyUserWhoProfileCreated {
        require(!isFollowExist(_address), "already exist in follow list");
        userFollowTo[msg.sender].push(_address);
        profileOf[_address].Followers += 1;
    }

    function totalFollowCountOfUser(address _address)
        public
        view
        returns (uint256)
    {
        return userFollowTo[_address].length;
    }

    function totalPostsCountOfUser(address _address)
        public
        view
        returns (uint256)
    {
        return postsOf[_address].length;
    }

    // -------------end--Posts,comments,follow,tip-------------//

    // helping functions
    function isFollowExist(address _address) public view returns (bool) {
        for (uint256 i = 0; i < userFollowTo[msg.sender].length; i++) {
            if (userFollowTo[msg.sender][i] == _address) {
                return true;
            }
        }
        return false;
    }

    function getStringLength(string memory _string)
        public
        pure
        returns (uint256)
    {
        bytes memory strBytes = bytes(_string);
        return strBytes.length;
    }
}