// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/ISocialNetwork.sol";

contract SocialNetwork is ISocialNetwork, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _postIdCounter;
    mapping(uint256 => Post) public posts;

    modifier requireActivePost(uint256 postID) {
        require(postID < Counters.current(_postIdCounter), "SocialNetwork::requireActivePost: Post does not exist");
        require(posts[postID].owner != address(0), "SocialNetwork::requireActivePost: Post was deleted");
        _;
    }

    function getPost(uint256 postID) requireActivePost(postID) public view override returns (Post memory) {
        return posts[postID];
    }

    function createPost(string memory text) public override {
        require(bytes(text).length > 0, "SocialNetwork::createPost: Cannot create post without text");

        uint256 currentID = Counters.current(_postIdCounter);
        posts[currentID] = Post(block.timestamp, msg.sender, text);

        emit PostCreated(currentID, msg.sender, text);
        Counters.increment(_postIdCounter);
    }

    function deletePost(uint256 postID) requireActivePost(postID) public override {
        require(posts[postID].owner == msg.sender, "SocialNetwork::deletePost: Not the owner of post");

        delete posts[postID];
        emit PostDeleted(postID);
    }

    function sponsorPost(uint256 postID) requireActivePost(postID) public override payable {
        require(posts[postID].owner != msg.sender, "SocialNetwork::sponsorPost: Cannot sponsor your own post");
        require(msg.value > 0, "SocialNetwork::sponsorPost: Sponsor amount must be greater than 0");

        address payable postOwner = payable(posts[postID].owner);

        (bool sent,) = postOwner.call{value : msg.value}("");
        require(sent, "SocialNetwork::sponsorPost: Failed to send Ether to owner");

        emit PostSponsored(postID, msg.value, msg.sender);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface ISocialNetwork {

    struct Post {
        uint256 timestamp;
        address owner;
        string text;
    }

    event PostCreated(uint256 postID, address indexed owner, string text);
    event PostDeleted(uint256 postID);
    event PostSponsored(uint256 postID, uint256 sponsorAmount, address indexed sponsor);

    /**
    * Gets a post
    *
    * @param postID - ID of post to be retrieved
    *
    * @return Post struct with the specified postID
    */
    function getPost(uint256 postID) external view returns(Post memory);

    /**
     * Creates a new post
     *
     * @param text - Content of the post
     *
     * No return, reverts on error
     */
    function createPost(string memory text) external;

    /**
     * Deletes a post
     *
     * @param postID - ID of the post to be deleted
     *
     * No return, reverts on error
     */
    function deletePost(uint256 postID) external;

    /**
     * Transfers sponsorAmount from msg.sender to post owner
     *
     * @param postID - ID of the post to be sponsored
     *
     * No return, reverts on error
     */
    function sponsorPost(uint256 postID) external payable;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

{
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "devdoc",
        "userdoc",
        "metadata",
        "abi"
      ]
    }
  },
  "libraries": {}
}