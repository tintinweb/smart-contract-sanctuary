// SPDX-License-Identifier: ISC

pragma solidity >=0.6.0 <0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title ERC721
 * @dev Abstract base implementation for ERC721 functions utilized within dispensary contract.
 */
abstract contract ERC721 {
    function ownerOf(uint256 id) public virtual returns (address owner);

    function balanceOf(address owner) public virtual returns (uint256 balance);

    function tokenOfOwnerByIndex(address owner, uint256 index) public virtual returns (uint256 id);
}

/**
 * @title ERC20
 * @dev Abstract base implementation for ERC20 functions utilized within dispensary contract.
 */
abstract contract ERC20 {
    function transfer(address to, uint256 value) public virtual;
}


/**
 * @title BohoTokenDispensary
 * @dev Responsible for oversight of dispensed $BOHO tokens for BOHOBONES holders.
 */
contract BohoTokenDispensary is Ownable {
    // Mapping to keep track of token claims
    mapping(uint256 => bool) bohoClaims;

    // Variables for Bones ERC721 and Boho ERC20 contracts 
    ERC721 bonesContract;
    ERC20 bohoContract;

    // Bool to pause/unpause dispenser
    bool isActive = false;

    // Deployer address
    address deployer;

    // Dispense amount
    uint256 amount = 7777 * 1 ether;

    /**
     * @param amount Amount dispensed.
     * @param bonesId Bones token ID for the given claim.
     */
    event Dispense(uint256 amount, uint256 bonesId);

    // Constructor
    constructor(address bonesContractAddress, address bohoContractAddress) {
        // Load ERC721 and ERC20 contracts
        bonesContract = ERC721(bonesContractAddress);
        bohoContract = ERC20(bohoContractAddress);
    }

    /**
     * Prevents a function from running if contract is paused
     */
    modifier dispensaryIsActive() {
        require(isActive == true, "BohoTokenClaim: Contract is paused.");
        _;
    }

    /**
     * @param bonesId ID of the Bohemian Bone checking claimed $BOHO status for.
     * Prevents repeat claims for a given Bohemian Bone.
     */
    modifier isNotClaimed(uint256 bonesId) {
        bool claimed = isClaimed(bonesId);
        require(claimed == false, "BohoTokenClaim: Tokens for this Bohemian have already been claimed!");
        _;
    }

    /**
     * @param newBonesContractAddress Address of the new ERC721 contract.
     * @dev Sets the address for the referenced Bohemian Bone ERC721 contract.
     * @dev Can only be called by contract owner.
     */
    function setBonesContractAddress(address newBonesContractAddress) public onlyOwner {
        bonesContract = ERC721(newBonesContractAddress);
    }

    /**
     * @param newBohoContractAddress Address of the new ERC20 contract.
     * @dev Sets the address for the referenced $BOHO ERC20 contract.
     * @dev Can only be called by contract owner.
     */
    function setBohoContractAddress(address newBohoContractAddress) public onlyOwner {
        bohoContract = ERC20(newBohoContractAddress);
    }
    
    /**
     * @param bonesId ID of the Bohemian Bone we are checking claimed status for.
     * @dev Returns a boolean indicating if $BOHO have been claimed for this Bohemian Bone.
     */
    function isClaimed(uint256 bonesId) public view returns (bool) {
        return bohoClaims[bonesId];
    }

    /**
     * @dev Sets the dispensary to unpaused if paused, and paused if unpaused.
     * @dev Can only be called by contract owner.
     */
    function flipDispensaryState() public onlyOwner {
        isActive = !isActive;
    }

    /**
     * @param newAmount The new amount $BOHO to dispense per claim.
     * @dev Changes the amount of $BOHO handed out per claim.
     * @dev Can only be called by contract owner.
     */
    function setAmount(uint256 newAmount) public onlyOwner {
        amount = newAmount;
    }

    /**
     * @param withdrawAmount Amount of $BOHO to withdraw into dispensary contract.
     * @dev Provides method for withdrawing $BOHO from contract, if necessary.
     * @dev Can only be called by contract owner.
     */
    function withdraw(uint256 withdrawAmount) public onlyOwner dispensaryIsActive {
        bohoContract.transfer(msg.sender, withdrawAmount);
    }

    /**
     * @param bonesId ID of the Bohemian Bone to claim $BOHO for.
     * @dev Claims the $BOHO for the given Bohemian Bone ID.
     * @dev Can only be called when dispensary is active.
     * @dev Cannot be called again once a claim has already been made for the given ID.
     */
    function claimBoho(uint256 bonesId) public dispensaryIsActive isNotClaimed(bonesId) {
        address bohoOwner = bonesContract.ownerOf(bonesId);
        require(msg.sender == bohoOwner, 'caller is not owner of this boho');

        bohoClaims[bonesId] = true;
        bohoContract.transfer(msg.sender, amount);

        emit Dispense(amount, bonesId);
    }


    /**
     * @param bonesIds IDs of the Bohemian Bones to claim $BOHO for.
     * @dev Claims the $BOHO for the given list of Bohemian Bone IDs.
     * @dev Can only be called when dispensary is active.
     */
    function multiClaimBoho(uint256[] memory bonesIds) public dispensaryIsActive {
        for (uint256 i = 0; i < bonesIds.length; i++) {
            bool claimed = isClaimed(bonesIds[i]);
            if (!claimed) claimBoho(bonesIds[i]);
        }
    }

    /**
     * @dev Claims the $BOHO for all Bohemian Bone IDs owned by caller.
     * @dev Can only be called when dispensary is active.
     */
    function megaClaimBoho() public dispensaryIsActive {
        uint256 bohoBalance = bonesContract.balanceOf(msg.sender);
        for (uint256 i = 0; i < bohoBalance; i++) {
            uint256 tokenId = bonesContract.tokenOfOwnerByIndex(msg.sender, i);
            bool claimed = isClaimed(tokenId);
            if (!claimed) claimBoho(tokenId);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    constructor () internal {
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

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

