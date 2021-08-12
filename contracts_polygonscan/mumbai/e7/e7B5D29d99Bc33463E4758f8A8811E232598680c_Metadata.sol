/**
 *Submitted for verification at polygonscan.com on 2021-08-11
*/

// Sources flattened with hardhat v2.6.0 https://hardhat.org

// File @openzeppelin/contracts/utils/[email protected]

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
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


// File @openzeppelin/contracts/access/[email protected]


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


// File contracts/Metadata.sol


contract Metadata is Ownable{

    /** @dev The hash for the global src img, this img will contain all nft imgs */
    string public HASHMASK_PROVENANCE = "";

    struct NFTData{
        string ipfsHash; 
        uint256 tierValue;
    }

    uint256 index;
    bool public allowNewEntries;
    mapping(uint256 => NFTData) metadata;

    constructor(){
        index = 0;
        allowNewEntries = true;
    }

    function addData( string memory _ipfsHash , uint256 _tierValue) public onlyOwner{
        require(allowNewEntries == true, "we cant add new data");

        metadata[index] = NFTData({
            ipfsHash: _ipfsHash,
            tierValue: _tierValue
        });

        index++;
    }

    function tokenURI(uint256 _tokenId) external view returns (string memory){
        return metadata[_tokenId].ipfsHash;
    }

    function getTokenTierValue (uint256 _tokenId) external view returns (uint256){
        return metadata[_tokenId].tierValue;
    }

    /** @dev Set provenance once it's calculated */
    function setProvenanceHash(string memory provenanceHash) public onlyOwner {
        HASHMASK_PROVENANCE = provenanceHash;
    }

    function notAllowNewEntries() public onlyOwner{
        allowNewEntries = false;
    }


}