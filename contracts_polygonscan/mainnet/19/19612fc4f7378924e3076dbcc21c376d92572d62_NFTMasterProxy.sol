/**
 *Submitted for verification at polygonscan.com on 2021-09-17
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

// File: contracts/NFTMasterProxy.sol

interface INFTMaster {
    function allNFTs(uint256 collectionId_) external view returns(
        address,
        uint256,
        address,
        uint256,
        uint256,
        uint256,
        uint256
    );

    function nftIdMap(address token_, uint256 id_) external view returns(uint256);

    function allCollections(uint256 collectionId_) external view returns(
        address,
        string memory,
        uint256,
        uint256,
        bool,
        uint256,
        uint256,
        uint256,
        uint256,
        uint256,
        uint256,
        uint256
    );

    function isCollaborator(uint256 collectionId_, address who_) external view returns(bool);

    function collaborators(uint256 collectionId_, uint256 index_) external view returns(address);

    function nftsByCollectionId(uint256 collectionId_, uint256 index_) external view returns(uint256);

    function slotMap(uint256 collectionId_, uint256 index_) external view returns(address, uint256);

    function isPublished(uint256 collectionId_) external view returns(bool);

    function getWinner(uint256 collectionId_, uint256 nftIndex_) external view returns(address);
}

contract NFTMasterProxy {

    bytes32 public constant OLD_SLOT = keccak256("com.blindboxes.old");
    bytes32 public constant NEW_SLOT = keccak256("com.blindboxes.new");

    constructor(address oldMaster_, address newMaster_) public {
        setOldMaster(oldMaster_);
        setNewMaster(newMaster_);
    }

    function oldMaster() external view returns (address) {
        return loadOldMaster();
    }

    function loadOldMaster() internal view returns (address) {
        address _impl;
        bytes32 position = OLD_SLOT;
        assembly {
            _impl := sload(position)
        }
        return _impl;
    }

    function setOldMaster(address oldMaster_) private {
        bytes32 position = OLD_SLOT;
        assembly {
            sstore(position, oldMaster_)
        }
    }

    function newMaster() external view returns (address) {
        return loadNewMaster();
    }

    function loadNewMaster() internal view returns (address) {
        address _impl;
        bytes32 position = NEW_SLOT;
        assembly {
            _impl := sload(position)
        }
        return _impl;
    }

    function setNewMaster(address newMaster_) private {
        bytes32 position = NEW_SLOT;
        assembly {
            sstore(position, newMaster_)
        }
    }

    function delegatedFwd(address _dst, bytes memory _calldata) internal {
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            let result := delegatecall(
                sub(gas(), 10000),
                _dst,
                add(_calldata, 0x20),
                mload(_calldata),
                0,
                0
            )
            let size := returndatasize()

            let ptr := mload(0x40)
            returndatacopy(ptr, 0, size)

            // revert instead of invalid() bc if the underlying call failed with invalid() it already wasted gas.
            // if the call returned error data, forward it
            switch result
                case 0 {
                    revert(ptr, size)
                }
                default {
                    return(ptr, size)
                }
        }
    }

    function allNFTs(uint256 collectionId_) external view returns(
        address,
        uint256,
        address,
        uint256,
        uint256,
        uint256,
        uint256
    ) {
        if (collectionId_ < 1e4) {
            return INFTMaster(loadOldMaster()).allNFTs(collectionId_);
        } else {
            return INFTMaster(loadNewMaster()).allNFTs(collectionId_);
        }
    }

    function nftIdMap(address token_, uint256 id_) external view returns(uint256) {
        uint256 result = INFTMaster(loadOldMaster()).nftIdMap(token_, id_);
        if (result > 0) {
            return result;
        }

        return INFTMaster(loadNewMaster()).nftIdMap(token_, id_);
    }

    function allCollections(uint256 collectionId_) external view returns(
        address,
        string memory,
        uint256,
        uint256,
        bool,
        uint256,
        uint256,
        uint256,
        uint256,
        uint256,
        uint256,
        uint256 
    ) {
        if (collectionId_ < 1e4) {
            return INFTMaster(loadOldMaster()).allCollections(collectionId_);
        } else {
            return INFTMaster(loadNewMaster()).allCollections(collectionId_);
        }
    }

    function isCollaborator(uint256 collectionId_, address who_) external view returns(bool) {
        if (collectionId_ < 1e4) {
            return INFTMaster(loadOldMaster()).isCollaborator(collectionId_, who_);
        } else {
            return INFTMaster(loadNewMaster()).isCollaborator(collectionId_, who_);
        }
    }
    
    function collaborators(uint256 collectionId_, uint256 index_) external view returns(address) {
        if (collectionId_ < 1e4) {
            return INFTMaster(loadOldMaster()).collaborators(collectionId_, index_);
        } else {
            return INFTMaster(loadNewMaster()).collaborators(collectionId_, index_);
        }
    }
    
    function nftsByCollectionId(uint256 collectionId_, uint256 index_) external view returns(uint256) {
        if (collectionId_ < 1e4) {
            return INFTMaster(loadOldMaster()).nftsByCollectionId(collectionId_, index_);
        } else {
            return INFTMaster(loadNewMaster()).nftsByCollectionId(collectionId_, index_);
        }
    }

    function slotMap(uint256 collectionId_, uint256 index_) external view returns(address, uint256) {
        if (collectionId_ < 1e4) {
            return INFTMaster(loadOldMaster()).slotMap(collectionId_, index_);
        } else {
            return INFTMaster(loadNewMaster()).slotMap(collectionId_, index_);
        }
    }

    function isPublished(uint256 collectionId_) external view returns(bool) {
        if (collectionId_ < 1e4) {
            return INFTMaster(loadOldMaster()).isPublished(collectionId_);
        } else {
            return INFTMaster(loadNewMaster()).isPublished(collectionId_);
        }
    }

    function getWinner(uint256 collectionId_, uint256 nftIndex_) public view returns(address) {
        if (collectionId_ < 1e4) {
            return INFTMaster(loadOldMaster()).getWinner(collectionId_, nftIndex_);
        } else {
            return INFTMaster(loadNewMaster()).getWinner(collectionId_, nftIndex_);
        }
    }

    function delegatedFwdByCollectionId(uint256 collectionId_) internal {
        if (collectionId_ < 1e4) {
            delegatedFwd(loadOldMaster(), msg.data);
        } else {
            delegatedFwd(loadNewMaster(), msg.data);
        }
    }

    function claimNFT(uint256 collectionId_, uint256 index_) external {
        delegatedFwdByCollectionId(collectionId_);
    }

    function claimRevenue(uint256 collectionId_, uint256 index_) external {
        delegatedFwdByCollectionId(collectionId_);
    }

    function claimCommission(uint256 collectionId_) external {
        delegatedFwdByCollectionId(collectionId_);
    }

    function claimFee(uint256 collectionId_) external {
        delegatedFwdByCollectionId(collectionId_);
    }

    function createCollection(
        string calldata name_,
        uint256 size_,
        uint256 commissionRate_,
        bool willAcceptBLES_,
        address[] calldata collaborators_
    ) external {
        delegatedFwd(loadNewMaster(), msg.data);
    }

    function changeCollaborators(uint256 collectionId_, address[] calldata collaborators_) external {
        delegatedFwdByCollectionId(collectionId_);
    }

    function addNFTToCollection(address tokenAddress_, uint256 tokenId_, uint256 collectionId_, uint256 price_) external {
        delegatedFwdByCollectionId(collectionId_);
    }

    function editNFTInCollection(uint256 nftId_, uint256 collectionId_, uint256 price_) external {
        delegatedFwdByCollectionId(collectionId_);
    }

    function removeNFTFromCollection(uint256 nftId_, uint256 collectionId_) external {
        delegatedFwdByCollectionId(collectionId_);
    }

    function publishCollection(uint256 collectionId_, address[] calldata path, uint256 amountInMax_, uint256 deadline_) external {
        delegatedFwdByCollectionId(collectionId_);
    }

    function unpublishCollection(uint256 collectionId_) external {
        delegatedFwdByCollectionId(collectionId_);
    }

    function drawBoxes(uint256 collectionId_, uint256 times_) external {
        delegatedFwdByCollectionId(collectionId_);
    }
}