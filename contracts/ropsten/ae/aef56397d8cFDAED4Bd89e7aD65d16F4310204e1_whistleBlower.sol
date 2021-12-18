// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10 <0.9.0;

contract whistleBlower {
	// Number of posts
	uint256 public postCount = 0;
	// Mapping fileId=>Struct
	mapping(uint256 => Post) public posts;
	mapping(uint32 => mapping(address => bool)) upVoteListGlobal;
	mapping(uint32 => mapping(address => bool)) downVoteListGlobal;

	// Struct
	struct Post {
		uint256 postId;
		string postHash;
		string postTitle;
		string postCategory;
		string postDescription;
		uint256 upvotes;
		uint256 downvotes;
		uint256 uploadTime;
		string[] comments;
		address payable uploader;
	}

	// Event
	event PostUploaded(
		uint256 postId,
		string postHash,
		string postTitle,
		string postCategory,
		string postDescription,
		uint256 upvotes,
		uint256 downvotes,
		uint256 uploadTime,
		string[] comments,
		address payable uploader
	);

	function postUpvoted(uint32 _postId) public returns (bool) {
		// checks if the user alredy up voted and the post is exist or not
		if (
			!upVoteListGlobal[_postId][msg.sender] && uint256(_postId) < postCount
		) {
			upVoteListGlobal[_postId][msg.sender] = true;
			posts[_postId].upvotes++;
			return true;
		} else {
			return false;
		}
	}

	function postDownvoted(uint32 _postId) public returns (bool) {
		// checks if the user alredy down voted and the post is exist or not
		if (
			!downVoteListGlobal[_postId][msg.sender] && uint256(_postId) < postCount
		) {
			downVoteListGlobal[_postId][msg.sender] = true;
			posts[_postId].downvotes++;
			return true;
		} else {
			return false;
		}
	}

	function addComment(uint256 _postId, string memory _comment) public {
		posts[_postId].comments.push(_comment);
	}

	//   function getComment(uint _id,uint i) public view returns(string memory){
	//       return posts[_id].comments[i];
	//   }

	// Upload post function
	function uploadPost(
		string memory _postHash,
		string memory _postTitle,
		string memory _postCategory,
		string memory _postDescription
	) public {
		// Make sure the post hash exists
		require(bytes(_postHash).length > 0);
		// Make sure  postTitle exists
		require(bytes(_postTitle).length > 0);
		// Make sure  postTitle exists
		require(bytes(_postCategory).length > 0);
		// Make sure post description exists
		require(bytes(_postDescription).length > 0);
		// Make sure uploader address exists
		require(msg.sender != address(0));

		string[] memory vector;
		// Add Post to the contract

		// upvoteListGlobal = Post
		posts[postCount] = Post(
			postCount,
			_postHash,
			_postTitle,
			_postCategory,
			_postDescription,
			0,
			0,
			block.timestamp,
			vector,
			payable(msg.sender)
		);

		// Increment post id
		postCount++;

		// Trigger an event
		emit PostUploaded(
			postCount,
			_postHash,
			_postTitle,
			_postCategory,
			_postDescription,
			0,
			0,
			block.timestamp,
			vector,
			payable(msg.sender)
		);
	}
}