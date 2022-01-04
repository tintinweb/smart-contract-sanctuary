//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "../shared/CommitReveal.sol";
import "./Graveyard1155Collection.sol";
import "./GraveyardMagicDispenser.sol";
import "./GraveyardRateLimit.sol";
import "./GraveyardUserBlacklist.sol";
import "./GraveyardCollectionWhitelist.sol";
import "./GraveyardRewardOdds.sol";
import "./Graveyard721Collection.sol";

contract Graveyard is 
    Graveyard1155Collection,
    Graveyard721Collection,
    GraveyardMagicDispenser, 
    GraveyardRateLimit, 
    GraveyardUserBlacklist, 
    GraveyardCollectionWhitelist,
    GraveyardRewardOdds,
    CommitReveal {

    struct GraveyardReward {
        uint256 magicTokens;
        address address721;
        address address1155;
        uint256 tokenId;
        uint256 tokenAmount;
    }

    // Commits tokens to be sent to the graveyard. Returns the commit id. Once receiveing the RandomCommitted event, the user
    // should call revealRewardFromGraveyard to claim their reward.
    function commitTokensToGraveyard(
        address _collectionAddress, 
        uint256[] calldata _tokenIds) 
    external 
    nonZeroAddress(_collectionAddress) 
    nonContract(msg.sender)
    magicContractIsSet()
    collectionsExist()
    returns(uint256) {

        require(!isUserBlacklisted(msg.sender), "User is blacklisted");
        require(isCollectionWhitelisted(_collectionAddress), "Collection not whitelisted");
        require(_tokenIds.length >= minTokensInKill && _tokenIds.length <= maxTokensInKill, "Num tokens out of range");
        require(canUserKill(msg.sender), "User has not reached time limit");

        uint256 commitId = commit();
        require(commitId != 0, "No commit Id");
        updateNextAvailableKill(msg.sender);

        // Add these tokens as options to hand out later. 
        // Hopefully they don't get them back as their reward. A cruel irony.
        addTo721Collection(_collectionAddress, _tokenIds);

        // After the state has changed, we make external calls to transfer the tokens to this contract.
        IERC721 _collection721 = IERC721(_collectionAddress);
        
        // Transfer ownership to smart contract
        for(uint256 i = 0; i < _tokenIds.length; i++) {
            // This will revert if not approved.
            _collection721.safeTransferFrom(msg.sender, address(this), _tokenIds[i]);
        }

        return commitId;
    }
    
    function revealRewardFromGraveyard() external magicContractIsSet() collectionsExist() returns(GraveyardReward memory) {

        require(!isUserBlacklisted(msg.sender), "User is blacklisted");

        // reveal() will handle checking that this user had a pending commit and that a random number has been seeded for it.
        // This also prevents re-entrance as it will change the state and remove the user's pending commit.
        uint256 _randomNumber = reveal();

        Reward _reward = getReward(_randomNumber);

        // Rescramble the random number. Certain numbers will pick certain types of reward using the % operator. This operator may be used
        // when determining how much of a token or magic to give. This should not return a similar result.
        uint256 _randomNumber2 = uint256(keccak256(abi.encode(_randomNumber, _randomNumber)));

        if(_reward == Reward.TOKEN1155) {
            (address _collectionAddress, uint256 _tokenId, uint256 _tokenAmount) = dispenseCollectionTokens(_randomNumber2);
            return GraveyardReward(0, address(0), _collectionAddress, _tokenId, _tokenAmount);
        } else if(_reward == Reward.TOKEN721) {
            (address _collectionAddress, uint256 _tokenId) = dispense721CollectionTokens(_randomNumber2);
            return GraveyardReward(0, _collectionAddress, address(0), _tokenId, 1);
        } else if(_reward == Reward.MAGIC) {
            uint256 _magicAmount = dispenseMagic(_randomNumber2);
            return GraveyardReward(_magicAmount, address(0), address(0), 0, 0);
        } else {
            return GraveyardReward(0, address(0), address(0), 0, 0);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Adminable.sol";

// Base implementation of CR for random elements to a contract.
// The random comes from off chain. Will be possible to allow a contract to be the admin when ChainLink VRF
// comes to arbitrum.
//
contract CommitReveal is Adminable {

    mapping(address => uint256) private accountToPendingCommitId;
    mapping(uint256 => uint256) private commitToRandomSeed;
    uint256 public lastIncrementBlockNum = 0; 
    uint256 public commitId = 1;
    uint256 public randomId = 1;
    uint256 public pendingCommits = 0;
    uint8 public numBlocksAfterIncrement = 1;

    function setNumBlocksAfterIncrement(uint8 _numBlocksAfterIncrement) external onlyAdminOrOwner {
        numBlocksAfterIncrement = _numBlocksAfterIncrement;
    }

    function incrementCommitId() external onlyAdminOrOwner {
        require(pendingCommits > 0, "No pending commits");
        commitId++;
        pendingCommits = 0;
        lastIncrementBlockNum = block.number;
    }

    // Adding the random number needs to be done AFTER incrementing the commit id on a separate transaction. If
    // these are done together, there is a potential vulnerability to front load a commit when the bad actor
    // sees the value of the random number.
    function addRandomForCommit(uint256 _seed) external onlyAdminOrOwner {
        require(block.number >= lastIncrementBlockNum + numBlocksAfterIncrement, "No random on same block");
        require(commitId > randomId, "Commit id must be higher");
    
        commitToRandomSeed[randomId] = _seed;
        randomId++;
    }

    function commit() internal returns(uint256) {
        
        require(accountToPendingCommitId[msg.sender] == 0, "Commit in progress");

        accountToPendingCommitId[msg.sender] = commitId;
        pendingCommits++;

        return commitId;
    }

    function reveal() internal returns(uint256) {
        uint256 _commitIdForUser = commitIdForUser(msg.sender);
        require(_commitIdForUser > 0, "No pending commit");

        uint256 _randomSeed = commitToRandomSeed[_commitIdForUser];
        require(_randomSeed > 0, "Random seed not set");

        delete accountToPendingCommitId[msg.sender];

        // Combine the seed with the sender's address so that each account for this commit will get a different number and outcome.
        uint256 randomNumber = uint256(keccak256(abi.encode(_randomSeed, msg.sender)));

        return randomNumber;
    }

    function commitIdForUser(address _address) public view returns(uint256) {
        return accountToPendingCommitId[_address];
    }

}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Receiver.sol";

import "../shared/Utilities.sol";

contract Graveyard1155Collection is Utilities, ERC1155Receiver {

    // An array of available collections to be used when the user kills tokens.
    address[] public collectionAddresses;
    mapping(address => mapping(uint256 => uint256)) public collectionToIdToAmount;
    mapping(address => uint256[]) public collectionToIds;

    uint256 public amountRewardLimit = 10;

    function setAmountRewardLimit(uint256 _amountRewardLimit) external onlyOwner {
        require(_amountRewardLimit > 0, "Invalid limit");
        amountRewardLimit = _amountRewardLimit;
    }

    function dispenseCollectionTokens(uint256 _randomNumber) internal returns(address, uint256, uint256) {
        require(collectionAddresses.length > 0, "No collections");

        uint256 _collectionIndex = _randomNumber % collectionAddresses.length;
        address _collectionAddress = collectionAddresses[_collectionIndex];

        _randomNumber = uint256(keccak256(abi.encode(_randomNumber, _randomNumber)));

        uint256 _tokenIndex = _randomNumber % collectionToIds[_collectionAddress].length;
        uint256 _tokenId = collectionToIds[_collectionAddress][_tokenIndex];

        _randomNumber = uint256(keccak256(abi.encode(_randomNumber, _randomNumber)));

        uint256 _maxAmount = amountRewardLimit;
        uint256 _amountHeld = collectionToIdToAmount[_collectionAddress][_tokenId];
        if(_amountHeld < _maxAmount) {
            _maxAmount = _amountHeld;
        }

        uint256 _amountGiven = (_randomNumber % _maxAmount) + 1;

        collectionToIdToAmount[_collectionAddress][_tokenId] -= _amountGiven;

        if(collectionToIdToAmount[_collectionAddress][_tokenId] == 0) {

            uint256 _numTokenIds = collectionToIds[_collectionAddress].length;

            if(_numTokenIds == 1) {
                // Emptied all of that specific token and it was the last token in our list for this collection.. We need to remove the collection entirely.
                delete collectionToIds[_collectionAddress];

                for(uint256 i = 0; i < collectionAddresses.length; i++) {
                    if(collectionAddresses[i] == _collectionAddress) {
                        collectionAddresses[i] = collectionAddresses[collectionAddresses.length - 1];
                        collectionAddresses.pop();
                    }
                }
            } else {
                // The amount is 0, so we should remove it as an option.
                collectionToIds[_collectionAddress][_tokenIndex] = collectionToIds[_collectionAddress][_numTokenIds - 1];
                collectionToIds[_collectionAddress].pop();
            }
        }

        IERC1155(_collectionAddress).safeTransferFrom(address(this), msg.sender, _tokenId, _amountGiven, "");

        return (_collectionAddress, _tokenId, _amountGiven);
    }

    // In case 1155 tokens need to be transfered out of the contract.
    function sendTokens(
        address _collectionAddress, 
        address _to, 
        uint256[] calldata _ids, 
        uint256[] calldata _amounts) 
    external onlyOwner nonZeroAddress(_collectionAddress) {
        IERC1155(_collectionAddress).safeBatchTransferFrom(address(this), _to, _ids, _amounts, "");
    }

    function addCollectionAndIds(address _collectionAddress, uint256[] memory _ids) private {
        bool found = false;
        for(uint i = 0; i < collectionAddresses.length; i++) {
            if(collectionAddresses[i] == _collectionAddress) {
                found = true;
                break;
            }
        }

        if(!found) {
            collectionAddresses.push(_collectionAddress);
        }

        uint256[] memory _existingIds = collectionToIds[_collectionAddress];

        for(uint i = 0; i < _ids.length; i++) {
            found = false;
            for(uint j = 0; j < _existingIds.length; j++) {
                if(_existingIds[j] == _ids[i]) {
                    found = true;
                    break;
                }
            }
            if(!found) {
                collectionToIds[_collectionAddress].push(_ids[i]);
            }
        }
    }

    function addToCollection(address _collectionAddress, uint256 _id, uint256 _value) private {
        // Add to the existing value.
        collectionToIdToAmount[_collectionAddress][_id] += _value;
    }

    function onERC1155Received(
        address,
        address,
        uint256 _id,
        uint256 _value,
        bytes memory
    ) public override returns (bytes4) {
        uint256[] memory _ids = new uint256[](1);
        _ids[0] = _id;
        addCollectionAndIds(msg.sender, _ids);

        addToCollection(msg.sender, _id, _value);

        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory _ids,
        uint256[] memory _values,
        bytes memory
    ) public override returns (bytes4) {
        require(_ids.length == _values.length, "Bad input");

        addCollectionAndIds(msg.sender, _ids);

        for(uint256 i = 0; i < _ids.length; i++) {
            addToCollection(msg.sender, _ids[i], _values[i]);
        }
        return this.onERC1155BatchReceived.selector;
    }

    modifier collectionsExist() {
        require(collectionAddresses.length > 0, "No collections set");
        _;
    }

}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../shared/Utilities.sol";

contract GraveyardMagicDispenser is Utilities {

    // Magics decimal is the same as eth.
    uint256 public maxMagicDispersed = 10 * 10**18;
    uint256 public minMagicDispersed = 1 * 10**18;
    IERC20 public magicContract;

    function setMagicContract(address _magicAddress) external onlyOwner nonZeroAddress(_magicAddress) {
        magicContract = IERC20(_magicAddress);
    }

    function setMagicRange(uint256 _minMagicDispersed, uint256 _maxMagicDispersed) external onlyOwner {
        require(_minMagicDispersed <= _maxMagicDispersed, "Invalid magic range");
        minMagicDispersed = _minMagicDispersed;
        maxMagicDispersed = _maxMagicDispersed;
    }

    function dispenseMagic(uint256 _randomNumber) internal returns(uint256) {

        uint256 range = maxMagicDispersed - minMagicDispersed + 1;

        uint256 amount = (_randomNumber % range) + minMagicDispersed;

        bool approval = magicContract.approve(address(this), amount);
        require(approval, "Approval failed");
        bool transfered = magicContract.transferFrom(address(this), msg.sender, amount);
        require(transfered, "Magic transfer failed");
        return amount;
    }

    // Backup to transfer magic away from this account.
    function sendMagic(address _to, uint256 _amount) external onlyOwner {
        bool approval = magicContract.approve(address(this), _amount);
        require(approval, "Approval failed");
        bool transfered = magicContract.transferFrom(address(this), _to, _amount);
        require(transfered, "Magic transfer failed");
    }

    modifier magicContractIsSet() {
        require(address(magicContract) != address(0), "No magic contract set");
        _;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../shared/Utilities.sol";

contract GraveyardRateLimit is Utilities {

    uint256 public minTokensInKill = 5;
    uint256 public maxTokensInKill = 100;
    uint256 public killWaitTimeSeconds = (15 * 60);
    mapping(address => uint256) private addressToNextAvailableKill;

    function updateTokensInKillRange(uint256 _minTokensInKill, uint256 _maxTokensInKill) external onlyOwner {
        require(_minTokensInKill <= _maxTokensInKill, "Min > max");
        require(_minTokensInKill > 0, "Need non-zero min num of tokens");
        minTokensInKill = _minTokensInKill;
        maxTokensInKill = _maxTokensInKill;
    }

    function updateKillWaitTime(uint256 _killWaitTimeSeconds) external onlyOwner {
        killWaitTimeSeconds = _killWaitTimeSeconds;
    }

    function canUserKill(address _address) public view returns (bool) {
        uint256 killTime = nextAvailableKill(_address);
        return (killTime == 0 || block.timestamp >= killTime);
    }

    function nextAvailableKill(address _address) public view returns (uint256) {
        return addressToNextAvailableKill[_address];
    }

    function updateNextAvailableKill(address _address) internal {
        addressToNextAvailableKill[_address] = block.timestamp + killWaitTimeSeconds;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../shared/Utilities.sol";

contract GraveyardUserBlacklist is Utilities {

    mapping(address => bool) public userBlacklist;

    function isUserBlacklisted(address _address) public view returns(bool) {
        return userBlacklist[_address];
    }

    function addToBlacklist(address[] calldata _addresses) external onlyOwner {
        for(uint256 i = 0; i < _addresses.length; i++) {
            require(_addresses[i] != address(0), "Zero address");
            userBlacklist[_addresses[i]] = true;
        }
    }

    function removeFromBlacklist(address[] calldata _addresses) external onlyOwner {
        for(uint256 i = 0; i < _addresses.length; i++) {
            require(_addresses[i] != address(0), "Zero address");
            userBlacklist[_addresses[i]] = false;
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../shared/Utilities.sol";

contract GraveyardCollectionWhitelist is Utilities {

    // Collections that are accepted to be killed. The whitelist can be disabled and enabled as needed.
    mapping(address => bool) public collectionWhitelist;
    bool public isCollectionWhitelistEnabled = false;

    // If whitelist is not enabled, will always return true.
    function isCollectionWhitelisted(address _address) public view returns(bool) {
        return (!isCollectionWhitelistEnabled || collectionWhitelist[_address]);
    }

    function updateCollectionWhitelistEnabled(bool enabled) external onlyOwner {
        isCollectionWhitelistEnabled = enabled;
    }

    function addToCollectionWhitelist(address[] calldata _addresses) external onlyOwner {
        for(uint256 i = 0; i < _addresses.length; i++) {
            require(_addresses[i] != address(0), "Zero address");
            collectionWhitelist[_addresses[i]] = true;
        }
    }

    function removeFromCollectionWhitelist(address[] calldata _addresses) external onlyOwner {
        for(uint256 i = 0; i < _addresses.length; i++) {
            require(_addresses[i] != address(0), "Zero address");
            collectionWhitelist[_addresses[i]] = false;
        }
    }

}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../shared/Utilities.sol";
import "./Graveyard721Collection.sol";

contract GraveyardRewardOdds is Graveyard721Collection {

    enum Reward {
        NOTHING,
        TOKEN721,
        TOKEN1155,
        MAGIC
    }

    struct Odds {
        uint32 nothing;
        uint32 token721;
        uint32 token1155;
        uint32 magic;
    }

    Odds internal odds = Odds(0, 45000, 45000, 10000);

    // Must add up to 100,000. Allows for rates as low as 1/100,000.
    function setOdds(uint32 _nothingOdds, uint32 _token721Odds, uint32 _token1155Odds, uint32 _magicOdds) external onlyOwner {
        require(_nothingOdds + _token721Odds + _token1155Odds + _magicOdds == 100000, "Invalid odds.");
        odds = Odds(_nothingOdds, _token721Odds, _token1155Odds, _magicOdds);
    }

    function getReward(uint256 _randomNumber) internal view returns(Reward) {
        // Number from 0-99999
        uint256 categoryNum = (_randomNumber % 100000);

        bool has721 = collectionAddresses721.length > 0;

        if(odds.nothing != 0 && odds.nothing - 1<= categoryNum) {
            return Reward.NOTHING;
        } else if((odds.token721 != 0) && odds.nothing + odds.token721 - 1 <= categoryNum) {
            // If there are no 721s to hand out, just add these "odds" to the 1155s.
            return has721 ? Reward.TOKEN721 : Reward.TOKEN1155;
        } else if(odds.token1155 != 0 && odds.nothing + odds.token721 + odds.token1155 - 1 <= categoryNum) {
            return Reward.TOKEN1155;
        } else {
            return Reward.MAGIC;
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

import "../shared/Utilities.sol";

contract Graveyard721Collection is Utilities, IERC721Receiver {

    address[] public collectionAddresses721;
    mapping(address => uint256[]) public collection721ToIds;

    function dispense721CollectionTokens(uint256 _randomNumber) internal returns(address, uint256) {
        require(collectionAddresses721.length > 0, "No collections");

        uint256 _collectionIndex = _randomNumber % collectionAddresses721.length;
        address _collectionAddress = collectionAddresses721[_collectionIndex];

        _randomNumber = uint256(keccak256(abi.encode(_randomNumber, _randomNumber)));

        uint256 _tokenIndex = _randomNumber % collection721ToIds[_collectionAddress].length;
        uint256 _tokenId = collection721ToIds[_collectionAddress][_tokenIndex];

        if(collection721ToIds[_collectionAddress].length == 1) {
            collectionAddresses721[_collectionIndex] = collectionAddresses721[collectionAddresses721.length - 1];
            collectionAddresses721.pop();
            delete collection721ToIds[_collectionAddress];
        } else {
            collection721ToIds[_collectionAddress][_tokenIndex] = collection721ToIds[_collectionAddress][collection721ToIds[_collectionAddress].length - 1];
            collection721ToIds[_collectionAddress].pop();
        }

        IERC721(_collectionAddress).safeTransferFrom(address(this), msg.sender, _tokenId, "");

        return (_collectionAddress, _tokenId);
    }

    function addTo721Collection(address _collectionAddress, uint256[] memory _ids) internal {
        bool found = false;
        for(uint i = 0; i < collectionAddresses721.length; i++) {
            if(collectionAddresses721[i] == _collectionAddress) {
                found = true;
                break;
            }
        }

        if(!found) {
            collectionAddresses721.push(_collectionAddress);
        }

        for(uint i = 0; i < _ids.length; i++) {
             collection721ToIds[_collectionAddress].push(_ids[i]);
        }
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Utilities.sol";

contract Adminable is Utilities {

    mapping(address => bool) private admins;

    function addAdmin(address _address) external onlyOwner {
        admins[_address] = true;
    }

    function removeAdmin(address _address) external onlyOwner {
        admins[_address] = false;
    }

    function isAdmin(address _address) external view returns(bool) {
        return admins[_address];
    }

    modifier onlyAdmin() {
        require(admins[msg.sender], "Not admin");
        _;
    }

    modifier onlyAdminOrOwner() {
        require(admins[msg.sender] || isOwner(), "Not admin or owner");
        _;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Utilities is Ownable {

    modifier nonZeroAddress(address _address) {
        require(address(0) != _address, "0 address");
        _;
    }

    modifier nonZeroLength(uint[] memory _array) {
        require(_array.length > 0, "Empty array");
        _;
    }

    modifier lengthsAreEqual(uint[] memory _array1, uint[] memory _array2) {
        require(_array1.length == _array2.length, "Unequal lengths");
        _;
    }

    modifier nonContract(address _address) {
        /* solhint-disable avoid-tx-origin */
        require(msg.sender == tx.origin, "No contracts");
        _;
    }

    function isOwner() internal view returns(bool) {
        return owner() == msg.sender;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../IERC1155Receiver.sol";
import "../../../utils/introspection/ERC165.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
    */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}