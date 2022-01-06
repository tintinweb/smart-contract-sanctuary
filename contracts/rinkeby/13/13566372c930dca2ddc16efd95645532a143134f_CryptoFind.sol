/**
 *Submitted for verification at Etherscan.io on 2022-01-05
*/

// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;


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
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: contracts/cryptoFind.sol



pragma solidity ^0.8.0;


contract CryptoFind is Ownable {
    uint256 fee = 0.002 ether;

    struct Post {
        string Name;
        string ShortDescription;
        string Link;
    }

    Post[] public posts;
    Post[] public featuredPosts;


    function publishFeaturedPost(Post memory _post) external payable {
        if (msg.sender != owner()) {
            require(msg.value >= fee);
        }   
        featuredPosts.push(_post);
    }

    function publishPost(Post memory _post) external {
        posts.push(_post);
    }

    function deletePost(string memory _name) external onlyOwner {
        for (uint256 i=0; i<=posts.length; i++) {
            if (compareStringsbyBytes(posts[i].Name, _name)) {
                posts[i] = posts[posts.length-1];
                posts.pop();
            }
        }
    }

    function deleteFeaturedPost(string memory _name) external onlyOwner {
        for (uint256 i=0; i<=featuredPosts.length; i++) {
            if (compareStringsbyBytes(featuredPosts[i].Name, _name)) {
                featuredPosts[i] = featuredPosts[featuredPosts.length-1];
                featuredPosts.pop();
            }
        }
    }

    function compareStringsbyBytes(string memory s1, string memory s2) internal pure returns(bool){
        return (keccak256(abi.encodePacked((s1))) == keccak256(abi.encodePacked((s2))));
    }

}