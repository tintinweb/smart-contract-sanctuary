/**
 *Submitted for verification at BscScan.com on 2022-01-22
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;


contract UsersFactory {
    address public owner;
    event ChildCreated(
        address childAddress,
        string _userName,
        string _profileImage
    );

    User[] children;

    function createUser(string memory _userName, string memory _profileImage)
        public
    {
        address _owner = msg.sender;
        User child = new User(_userName, _profileImage, _owner);
        children.push(child);
        emit ChildCreated(address(child), _userName, _profileImage);
    }

    function getChilds() public view returns (User[] memory) {
        return children;
    }
}

contract User {
    string userName;
    address owner;
    address admin;
    string bio = "default";
    string profileImage="default";
    string coverImage="default";
    struct Blog {
        address _address;
        uint256 timestamp;
        uint256 createdBlock;
    }
    Blog[] myBlogs;

    constructor(
        string memory _userName,
        string memory _profileImage,
        address _owner
    ) {
        userName = _userName;
        profileImage = _profileImage;
        owner = _owner;
    }

    // Function to add/update bio
    function updateBio(string memory _bio) public {
        bio = _bio;
    }

    // Function to add/update cover image

    function updateCoverImage(string memory _cover) public {
        coverImage = _cover;
    }

    // Function to update profile image

    function updateProfileImage(string memory _profileImg) public {
        profileImage = _profileImg;
    }

    function getFields()
        public
        view
        returns (
            string memory ,
            string memory ,
            string memory ,
            address ,
            Blog[] memory 
        )
    {
        return (userName, bio, profileImage, owner, myBlogs);
    }

    function createBlog(string memory blogIPFShash) public {
        address _owner = msg.sender;
        BlogContract child = new BlogContract(_owner, blogIPFShash);
        Blog memory newBlog = Blog(
            address(child),
            block.timestamp,
            block.number
        );
        myBlogs.push(newBlog);
    }
}

contract BlogContract {
    uint256 createdblock;
    uint256 timestamp;
    address owner;
    string blogIPFShash;

    constructor(address _owner, string memory _blogIPFShash) {
        createdblock = block.number;
        owner = _owner;
        blogIPFShash = _blogIPFShash;
        timestamp = block.timestamp;
    }

    function getFields()
        public
        view
        returns (
            uint256 ,
            uint256 ,
            address ,
            string memory
        )
    {
        return (createdblock, timestamp, owner, blogIPFShash);
    }
}