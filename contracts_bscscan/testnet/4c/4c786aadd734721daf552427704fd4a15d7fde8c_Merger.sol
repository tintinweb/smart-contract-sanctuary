/**
 *Submitted for verification at BscScan.com on 2021-12-12
*/

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


interface ICyberWayNFT {

    function transferFrom(address from, address to, uint256 tokenId) external;

    function mint(address to, uint8 kind_, uint8 newColorFrame_, uint8 rand_) external returns(uint256);

    function burn(uint256 tokenId) external;

    function getTokenKind(uint256 tokenId) external view returns(uint8);

    function getTokenColor(uint256 tokenId) external view returns(uint8);

    function getTokenRand(uint256 tokenId) external view returns(uint8);
}


contract Merger is Ownable {

    ICyberWayNFT public nft;

    event SplitCompleted(address recipient, uint256 id);

    constructor(address _nft) {
        nft = ICyberWayNFT(_nft);
    }


    function merge(uint256[3] memory _donors) public {
        require(nft.getTokenRand(_donors[0]) == nft.getTokenRand(_donors[1]) &&
        nft.getTokenRand(_donors[2]) == nft.getTokenRand(_donors[0])
            && nft.getTokenRand(_donors[0]) < 4,"Merger: rand not equal or max");

        require(nft.getTokenKind(_donors[0]) == nft.getTokenKind(_donors[1]) &&
            nft.getTokenKind(_donors[2]) == nft.getTokenKind(_donors[0]),"Merger:kind notEqual");

        require(nft.getTokenColor(_donors[0]) == nft.getTokenColor(_donors[1]) &&
            nft.getTokenColor(_donors[2]) == nft.getTokenColor(_donors[0]),"Merger:color notEqual");
        uint8 newKind = nft.getTokenKind(_donors[0]);
        uint8 newColor = nft.getTokenColor(_donors[0]);
        uint8 newRand = nft.getTokenRand(_donors[0]) + 1;

        for(uint i = 0; i < _donors.length; i++) {
            nft.transferFrom(msg.sender, address(this), _donors[i]);
            nft.burn(_donors[i]);
        }

        uint256 tokenId = nft.mint(msg.sender, newKind, newColor, newRand);
        emit SplitCompleted(msg.sender, tokenId);
    }

}