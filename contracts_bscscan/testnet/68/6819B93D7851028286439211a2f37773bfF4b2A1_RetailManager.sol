// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./access/Ownable.sol";

contract RetailManager is Ownable {
    struct NftInfo {
        bool whitelisted;                       // Flag for if this NFT has been whitelisted for use
        uint maxUsesPerId;                      // The maximum number of times a given tokenID can be used
        uint totalUses;                         // Counter of how many times the NFT has been used in total
        mapping (uint => uint) uses;            // Mapping to track how many times each tokenID has been used
    }

    address public api;                         // The address of the API
    mapping (address => NftInfo) public nfts;   // Mapping of the NFT address to it's details

    // Function to check if a given NFT tokenID is available for use
    function checkUsable(address _nft, uint _id) public view returns (bool) {
        if (!nfts[_nft].whitelisted) return false;
        if (nfts[_nft].maxUsesPerId == 0) return true;
        return nfts[_nft].uses[_id] < nfts[_nft].maxUsesPerId;
    }

    // Function for the owner to set the API address
    function setApi(address _api) public onlyOwner() { api = _api; }

    // Function for the owner to set the details of a NFT
    function setNft(address _nft, bool _whitelisted, uint _maxUsesPerId) public onlyOwner() {
        nfts[_nft].whitelisted = _whitelisted;
        nfts[_nft].maxUsesPerId = _maxUsesPerId;
    }

    // Function for the API to update the used counts of a NFT tokenID
    function setUsed(address _nft, uint _id) public {
        require(msg.sender == api, 'This function can only be called by the Rug Zombie API');
        nfts[_nft].uses[_id]++;
        nfts[_nft].totalUses++;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./Context.sol";

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
    constructor()  {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

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

    function _msgData() internal view virtual returns ( bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}