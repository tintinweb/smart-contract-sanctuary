// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import './IROCNFTMint.sol';

contract ROCBlindBoxOxbullAirdropByAdd20211115 is Ownable {

    struct BlindBoxInfo {
        uint256 baseTokenId;
        uint32 nextBoxIndex;
        uint32 totalCount;
        mapping(address => uint8) airdrops;
        uint32 airdropedCount;
    }

    BlindBoxInfo[2] public blindBoxInfos;
    mapping(address => bool) public userClaimed;

    IROCNFTMint public rocNFT;

    event BlindBoxOpened(
        address indexed payer,
        uint8 boxId,
        uint8 count,
        uint256 baseBoxIndex,
        uint256[] tokenIds,
        uint256 date
    );


    constructor(address rocNFTAddress) {
        rocNFT = IROCNFTMint(rocNFTAddress);
        setupBlindBoxInfo(0, 24001, 1000);
        setupBlindBoxInfo(1, 29001, 400);
    }

    modifier onlyNotClaimed() {
        require(!userClaimed[msg.sender], "ROCBlindBoxOxbullAirdrop20211115: caller has claimed");
        _;
    }

    function userHasAirdrop(address account) private view returns (bool) {
        for (uint8 boxId = 0; boxId < 2; boxId++) {
            uint8 count = blindBoxInfos[boxId].airdrops[account];
            if (count > 0) {
                return true;
            }
        }
        return false;
    }
    
    modifier boxIdIsValid(uint8 boxId) {
        require(boxId < blindBoxInfos.length, "boxId is not valid");
        _;
    }

    function canClaim(address account) public view returns (bool) {
        if (userClaimed[account]) {
            return false;
        }

        return userHasAirdrop(account);
    }

    function getAirdropBlindBoxCount(address account, uint8 boxId) public view boxIdIsValid(boxId) returns (uint8) {
        return blindBoxInfos[boxId].airdrops[account];
    }

    function setupBlindBoxInfo(uint8 boxId, uint256 pBaseTokenId, uint32 pTotalCount) private {
        BlindBoxInfo storage boxInfo = blindBoxInfos[boxId];
        boxInfo.baseTokenId = pBaseTokenId;
        boxInfo.nextBoxIndex = 0;
        boxInfo.totalCount = pTotalCount;
    }

    function addAirdrop(uint8 boxId, address[] memory accounts, uint8[] memory counts) external onlyOwner {
        require(accounts.length == counts.length, "ROCBlindBoxOxbull20211115: accounts and counts length mismatch");
        
        BlindBoxInfo storage boxInfo = blindBoxInfos[boxId];
        uint32 airdropedCount = boxInfo.airdropedCount;
        for (uint256 i = 0; i < accounts.length; i++) {
            address account = accounts[i];
            uint8 count = counts[i];
            require(boxInfo.totalCount - airdropedCount >= count, "ROCBlindBoxOxbull20211115: stock not enough");
            
            airdropedCount += count;
            boxInfo.airdrops[account] = count;
        }
        boxInfo.airdropedCount = airdropedCount;
    }
    
    function claim() external onlyNotClaimed {
        address account = msg.sender;

        require(userHasAirdrop(account), "ROCBlindBoxOxbullAirdrop20211115: caller do not have any airdrop");
        
        userClaimed[account] = true;
        for (uint8 boxId = 0; boxId < 2; boxId++) {
            BlindBoxInfo storage boxInfo = blindBoxInfos[boxId];
            uint8 count = boxInfo.airdrops[account];
            if (count > 0) {
                require(boxInfo.totalCount - boxInfo.nextBoxIndex >= count, "ROCBlindBoxOxbull20211115: stock not enough");
                uint256 baseBoxInx = boxInfo.nextBoxIndex;
                boxInfo.nextBoxIndex += count;
                uint256[] memory ids = new uint256[](5 * count);
                uint256[] memory amounts = new uint256[](5 * count);
                {
                    uint256 baseId = boxInfo.baseTokenId + baseBoxInx * 5;
                    for (uint256 j = 0; j < ids.length; j++) {
                        ids[j] = baseId + j;
                        amounts[j] = 1;
                    }
                }
                rocNFT.mintBatch(account, ids, amounts, "");
                
                emit BlindBoxOpened(account, boxId, count, baseBoxInx, ids, block.timestamp);
            }
        }
    }
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
pragma solidity ^0.8.0;

// for ROCNFTMinter
interface IROCNFTMint {

    // Admin use only, ERC1155 allow user own same nft
    function mint(address account, uint256 id, uint256 amount, bytes memory data) external;

    // Admin use only，ERC1155 allow user own same nft, and admin call with limited gas
    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) external;

    // Admin use only，ERC1155 allow user own same nft, and admin call with limited gas
    function mintBatch(address[] memory accounts, uint256[] memory ids, uint256[] memory amounts, bytes memory data) external;
}