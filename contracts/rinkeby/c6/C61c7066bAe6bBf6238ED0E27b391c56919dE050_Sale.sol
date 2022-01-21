// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./Cards.sol";
import "./Staking.sol";
import "./RandomGenerator.sol";
import "./CardCatalog.sol";
import "./Erc20Token.sol";
import "./Artifacts.sol";
import "./CollectionCatalog.sol";

contract Sale {
    event Buy(
        address indexed buyer,
        uint indexed packType,
        uint256 count
    );

    struct Collector {
        address collectorAddress;
        uint16 allowedPermill;
    }

    uint8 constant private COMMON_RARITY_ID = 0;
    uint8 constant private RARE_RARITY_ID = 1;
    uint8 constant private LEGENDARY_RARITY_ID = 2;

    bool public isLocked = false;
    address public owner;

    uint256 public costCommon;
    uint256 public costRare;
    uint256 public costLegendary;

    uint256 public boughtCommonCount = 0;
    uint256 public boughtRareCount = 0;
    uint256 public boughtLegendaryCount = 0;

    uint256 public limitCommon;
    uint256 public limitRare;
    uint256 public limitLegendary;

    Collector[] private _collectors;
    mapping (address => uint256) private collectedByCollectors;
    uint256 private totalEarn;

    Cards public cardsContract;
    Artifacts public artifactsContract;
    RandomGenerator public randomGeneratorContract;
    CardCatalog public cardCatalogContract;
    CollectionCatalog public collectionCatalogContract;
    Staking public stakingContract;
    Erc20Token public erc20TokenContract;

    uint256 public saleStartTimestamp;
    uint256 public saleStopTimestamp;

/*
0,"Test cards token","TCT","http://localhost:3000/card/","Test artifacts","TA","http://localhost:3000/artifact/","Test ERC20 token","T20","1000000000000000000000000000","120000000000000000000000000"
*/
    constructor(
//        uint256 _costCommon,
//        uint256 _limitCommon,
//        uint256 _costRare,
//        uint256 _limitRare,
//        uint256 _costLegendary,
//        uint256 _limitLegendary,
        uint256 _saleStartTimestamp,

        string memory erc721CardsTokenName,
        string memory erc721CardsTokenSymbol,
        string memory erc721CardsTokenBaseUri,

        string memory erc721ArtifactsTokenName,
        string memory erc721ArtifactsTokenSymbol,
        string memory erc721ArtifactsTokenBaseUri,

        string memory erc20TokenName,
        string memory erc20TokenSymbol,
        uint256 erc20TokenMaxTotalSupply,
        uint256 erc20TokenInitialSupply
    ) {
        owner = msg.sender;
        //todo set costs and limits:
        costCommon = 50000000000000000;
        costRare = 150000000000000000;
        costLegendary = 500000000000000000;

        limitCommon = 100;
        limitRare = 100;
        limitLegendary = 100;
//        costCommon = _costCommon;
//        costRare = _costRare;
//        costLegendary = _costLegendary;
//
//        limitCommon = _limitCommon;
//        limitRare = _limitRare;
//        limitLegendary = _limitLegendary;

        saleStartTimestamp = _saleStartTimestamp;

        randomGeneratorContract = new RandomGenerator();

        cardCatalogContract = new CardCatalog(msg.sender, address(randomGeneratorContract));
        collectionCatalogContract = new CollectionCatalog(msg.sender);

        stakingContract = new Staking(
            address(cardCatalogContract)
        );

        cardsContract = new Cards(
            address(randomGeneratorContract),
            address(stakingContract),
            address(cardCatalogContract),
            erc721CardsTokenName,
            erc721CardsTokenSymbol,
            erc721CardsTokenBaseUri
        );

        artifactsContract = new Artifacts(
            address(randomGeneratorContract),
            address(stakingContract),
            address(cardCatalogContract),
            erc721ArtifactsTokenName,
            erc721ArtifactsTokenSymbol,
            erc721ArtifactsTokenBaseUri
        );

        erc20TokenContract = new Erc20Token(
            erc20TokenName,
            erc20TokenSymbol,
            erc20TokenMaxTotalSupply,
            erc20TokenInitialSupply,
            msg.sender,
            address(stakingContract)
        );
        stakingContract.setContracts(
            address(erc20TokenContract),
            address(cardsContract),
            address(artifactsContract)
        );
    }

    function setLocked(bool _isLocked) public onlyOwner{
        isLocked = _isLocked;
    }

    function setBuyParams(uint256 _costCommon, uint256 _limitCommon, uint256 _costRare, uint256 _limitRare, uint256 _costLegendary, uint256 _limitLegendary, uint256 _saleStartTimestamp) public onlyOwner {
        costCommon = _costCommon;
        costRare = _costRare;
        costLegendary = _costLegendary;
        limitCommon = _limitCommon;
        limitRare = _limitRare;
        limitLegendary = _limitLegendary;
        saleStartTimestamp = _saleStartTimestamp;
    }

    function setWithdrawers(Collector[] memory collectors) public  onlyOwner {
        require(_collectors.length == 0, "Withdrawers are already set");
        require(collectors.length > 0);
        uint256 i;
        uint256 permillSum = 0;
        for (i = 0; i < collectors.length; i ++) {
            permillSum += collectors[i].allowedPermill;
            _collectors.push(collectors[i]);
            for (uint256 j = i + 1; j < collectors.length; j++) {
                if (collectors[i].collectorAddress == collectors[j].collectorAddress) {
                    require(false, "Duplicating collector addresses");
                }
            }
        }
        require(permillSum == 1000, "Permill sum should be 1000");
    }

    receive() external payable {
        require(false, 'Do not send eth directly, call appropriate method');
    }

    function buyCommonPacks() public payable saleIsRunningModifier {
        uint256 packCount = msg.value / costCommon;
        require(packCount * costCommon == msg.value, "Invalid payment value");

        address packOwner = msg.sender;

        boughtCommonCount += packCount;
        require(boughtCommonCount <= limitCommon, "Not enough packs");
        totalEarn += msg.value;

        for (uint256 i = 0; i < packCount; i++) {
            cardsContract.mintCard(
                packOwner,
                cardCatalogContract.mintRandomCard(COMMON_RARITY_ID)
            );
            cardsContract.mintCard(
                packOwner,
                cardCatalogContract.mintRandomCard(COMMON_RARITY_ID)
            );
        }
        emit Buy(packOwner, COMMON_RARITY_ID, packCount);
    }

    function buyRarePacks() public payable saleIsRunningModifier {
        uint256 packCount = msg.value / costRare;
        require(packCount * costRare == msg.value, "Invalid payment value");

        address packOwner = msg.sender;

        boughtRareCount += packCount;
        require(boughtRareCount <= limitRare, "Not enough packs");
        totalEarn += msg.value;

        for (uint256 i = 0; i < packCount; i++) {
            cardsContract.mintCard(
                packOwner,
                cardCatalogContract.mintRandomCard(COMMON_RARITY_ID)
            );
            cardsContract.mintCard(
                packOwner,
                cardCatalogContract.mintRandomCard(COMMON_RARITY_ID)
            );
            cardsContract.mintCard(
                packOwner,
                cardCatalogContract.mintRandomCard(RARE_RARITY_ID)
            );
        }

        emit Buy(msg.sender, RARE_RARITY_ID, packCount);
    }

    function buyLegendaryPacks() public payable saleIsRunningModifier {
        uint256 packCount = msg.value / costLegendary;
        require(packCount * costLegendary == msg.value, "Invalid payment value");

        address packOwner = msg.sender;

        boughtLegendaryCount += packCount;
        require(boughtLegendaryCount <= limitLegendary, "Not enough packs");
        totalEarn += msg.value;

        for (uint256 i = 0; i < packCount; i++) {
            cardsContract.mintCard(
                packOwner,
                cardCatalogContract.mintRandomCard(COMMON_RARITY_ID)
            );
            cardsContract.mintCard(
                packOwner,
                cardCatalogContract.mintRandomCard(COMMON_RARITY_ID)
            );
            cardsContract.mintCard(
                packOwner,
                cardCatalogContract.mintRandomCard(COMMON_RARITY_ID)
            );
            cardsContract.mintCard(
                packOwner,
                cardCatalogContract.mintRandomCard(RARE_RARITY_ID)
            );
            cardsContract.mintCard(
                packOwner,
                cardCatalogContract.mintRandomCard(LEGENDARY_RARITY_ID)
            );
        }

        emit Buy(msg.sender, LEGENDARY_RARITY_ID, packCount);
    }

    function collectFunds() public {
        address msgSender = msg.sender;
        uint256 collectorIndex;
        for (collectorIndex = 0; collectorIndex < _collectors.length; collectorIndex++) {
            if (_collectors[collectorIndex].collectorAddress == msgSender) break;
        }
        require(collectorIndex < _collectors.length, "Collecting from this sender is not allowed");

        uint256 maxCollectAmount = (totalEarn * _collectors[collectorIndex].allowedPermill) / 1000;

        require(maxCollectAmount > collectedByCollectors[msgSender], "You have collected all allowed eth");

        uint256 ethToCollect = maxCollectAmount - collectedByCollectors[msgSender];

        (bool success, ) = msgSender.call{value: ethToCollect}("");
        require(success, "Transfer failed.");

        collectedByCollectors[msgSender] += ethToCollect;
    }

    function cardCatalogAddress() public view returns (address) {
        return address(cardCatalogContract);
    }

    function setBaseUris(
        string memory erc721CardsTokenBaseUri,
        string memory erc721ArtifactsTokenBaseUri) public onlyOwner {
        cardsContract.setBaseUri(erc721CardsTokenBaseUri);
        artifactsContract.setBaseUri(erc721ArtifactsTokenBaseUri);
    }

    function canMintArtifact(address owner, uint16 collectionId) public view returns (bool) {
        if (artifactsContract.isMinted(collectionId)) {
            return false;
        }

        uint256[] memory allTokenIds = cardsContract.getCardsByOwner(owner);
        uint16[] memory imageIdsFromCollection = new uint16[](cardCatalogContract.collectionCardCount(collectionId));
        uint256 imageIdsFromCollectionIndex = 0;

        for (uint256 i = 0; i < allTokenIds.length; i++) {
            uint16 imageId = cardsContract.getTokenImage(allTokenIds[i]);
            if (cardCatalogContract.getCard(imageId).collectionId == collectionId) {
                bool duplicateImageId = false;
                for (uint256 k = 0; k < imageIdsFromCollectionIndex && !duplicateImageId; k ++) {
                    duplicateImageId = imageIdsFromCollection[k] == imageId;
                }
                if (duplicateImageId) continue;
                imageIdsFromCollection[imageIdsFromCollectionIndex] = imageId;
                imageIdsFromCollectionIndex++;
            }
        }
        return cardCatalogContract.checkFullCollection(imageIdsFromCollection);
    }

    function mintArtifact(uint16 collectionId) public {
        require(canMintArtifact(msg.sender, collectionId), "You cannot mint artifact for this collection");
        artifactsContract.mintArtifact(msg.sender, collectionId);
        collectionCatalogContract.mintArtifact(collectionId, msg.sender);
    }

    function setSaleStopTimestamp(uint256 _saleStopTimestamp) public onlyOwner {
        require(saleStopTimestamp == 0 || block.timestamp < saleStopTimestamp, "Sale stop time is already set");
        saleStopTimestamp = _saleStopTimestamp;
    }

    function saleIsRunning() public view returns (bool) {
        return
            saleStartTimestamp <= block.timestamp &&
            (saleStopTimestamp == 0 || saleStopTimestamp >= block.timestamp) &&
            isLocked == false &&
            cardCatalogContract.setupComplete();
    }


    modifier onlyOwner {
        require(
            msg.sender == owner,
            "Only owner can call this function."
        );
        _;
    }

    modifier saleIsRunningModifier {
        require(
            saleIsRunning() == true,
            "Sale is not running"
        );
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./CardCatalog.sol";
import "./Cards.sol";
import "./Erc20Token.sol";
import "./Artifacts.sol";

contract Staking {
    event StakingAction (
        address indexed owner
    );

    Erc20Token _erc20Contract;

    struct StakingRecord {
        uint256 lastWithdrawTimestamp;
        uint256[] lockedTokenIds;
        uint256 collectionEnergy;
    }

    uint256 incrementationSpeedPerEnergyPerSecond =
        uint256(1e18)     /    uint256(3)   / uint256(24 * 3600);
        //  1 METR        /     3 days      /    seconds in day
    CardCatalog public cardCatalogContract;
    Cards public cardsContract;
    Artifacts public artifactsContract;

    StakingRecord[] private _cardTokenStakingRecords;

    //todo return to private:
//    mapping(uint256 => uint256[]) public _lockedCards;

    //todo return to private:
    mapping(address => uint256) public _internalBalance;

    //todo return to private:
    mapping(address => uint256[]) public _lockIdsByAddress;
    mapping(address => uint256[]) private _lockedArtifactIdsByAddress;

    constructor(
        address cardCatalogAddress
    ) {
        cardCatalogContract = CardCatalog(cardCatalogAddress);
    }

    //todo remove:
    function cardTokenStakingRecords(uint256 lockId) public view returns (StakingRecord memory) {
        return _cardTokenStakingRecords[lockId];
    }

    function stakeCardTokens(uint256[] memory tokenIds) public {
        uint16[] memory imageIds = new uint16[](tokenIds.length);
        address staker = msg.sender;
        uint16 totalCollectionEnergy = 0;

        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(cardsContract.ownerOf(tokenIds[i]) == staker, "You are not owner of the card you are trying to stake");
            require(! cardsContract.isLocked(tokenIds[i]), "Some tokens are already locked");
            imageIds[i] = cardsContract.getTokenImage(tokenIds[i]);
            totalCollectionEnergy += cardsContract.cardEnergy(tokenIds[i]);
        }

        require(cardCatalogContract.checkFullCollection(imageIds), "Tokens are not forming full collection");

        _cardTokenStakingRecords.push(
            StakingRecord(
                block.timestamp,
                tokenIds,
                totalCollectionEnergy
        ));

        uint256 lockId = _cardTokenStakingRecords.length - 1;

        _lockIdsByAddress[staker].push(lockId);
        cardsContract.lockTokens(tokenIds, lockId);
        emit StakingAction(staker);
    }

    function getLockOwner(uint256 lockId) public view returns (address) {
        require(_cardTokenStakingRecords[lockId].lastWithdrawTimestamp > 0, "Invalid lock id");
        address firstCardOwner = cardsContract.ownerOf(_cardTokenStakingRecords[lockId].lockedTokenIds[0]);
        return firstCardOwner;
    }

    //todo make private
    function getStakingDuration(uint256 lockId) public view returns(uint256) {
        uint256 now = block.timestamp;
        return now - _cardTokenStakingRecords[lockId].lastWithdrawTimestamp;
    }

    //todo remove:
    function getTime() public view returns(uint256) {
        return block.timestamp;
    }

    function getArtifactsBoostPercent(address account) public view returns(uint256) {
        uint256 artifactsSummaryPercent = 100;
        for (uint256 i = 0; i < _lockedArtifactIdsByAddress[account].length; i++) {
            artifactsSummaryPercent += artifactsContract.getArtifactPercent(_lockedArtifactIdsByAddress[account][i]);
        }

        return artifactsSummaryPercent;
    }

    function getStakingBalance(address account) public view returns(uint256) {
        uint256 now = block.timestamp;
        uint256 balance = 0;
        for (uint256 i = 0; i < _lockIdsByAddress[account].length; i++) {
            uint256 lockId = _lockIdsByAddress[account][i];
            uint256 energy = _cardTokenStakingRecords[lockId].collectionEnergy;
            uint256 stakingDuration = now - _cardTokenStakingRecords[lockId].lastWithdrawTimestamp;
            balance += energy * stakingDuration * incrementationSpeedPerEnergyPerSecond;
        }

        balance = (balance * getArtifactsBoostPercent(account)) / 100;
        return balance + _internalBalance[account];
    }

    function getTotalCollectionsEnergy(address account) public view returns(uint256) {
        uint256 collectionsEnergy = 0;
        for (uint256 i = 0; i < _lockIdsByAddress[account].length; i++) {
            uint256 lockId = _lockIdsByAddress[account][i];
            collectionsEnergy += _cardTokenStakingRecords[lockId].collectionEnergy;
        }

        return collectionsEnergy;
    }

    function getDailyRevenue(address account) public view returns(uint256) {
        uint256 collectionRevenuePerSecond = 0;
        for (uint256 i = 0; i < _lockIdsByAddress[account].length; i++) {
            uint256 lockId = _lockIdsByAddress[account][i];
            uint256 energy = _cardTokenStakingRecords[lockId].collectionEnergy;
            collectionRevenuePerSecond += energy * incrementationSpeedPerEnergyPerSecond;
        }

        uint256 collectionEnergyPerDay = getTotalCollectionsEnergy(account) * incrementationSpeedPerEnergyPerSecond * (3600 * 24);

        return (collectionEnergyPerDay * getArtifactsBoostPercent(account)) / 100;
    }

    function getStakingCollectionsCount(address account) public view returns(uint256) {
        return _lockIdsByAddress[account].length;
    }

    function getStakingArtifactsCount(address account) public view returns(uint256) {
        return _lockedArtifactIdsByAddress[account].length;
    }

    function unstakeCardTokens(uint256[] memory lockIds) public {
        address staker = msg.sender;

        for (uint256 lockIndex = 0; lockIndex < lockIds.length; lockIndex ++) {
            require(getLockOwner(lockIds[lockIndex]) == staker, "You can unstake only cards that you own");
        }

        uint256 balance = _resetInternalBalances(staker);
        for (uint256 lockIndex = 0; lockIndex < lockIds.length; lockIndex ++) {
            uint256 lockId = lockIds[lockIndex];

            cardsContract.unlockTokens(_cardTokenStakingRecords[lockId].lockedTokenIds);

            for (uint256 i = 0; i < _lockIdsByAddress[staker].length; i++) {
                if (_lockIdsByAddress[staker][i] == lockId) {
                    _lockIdsByAddress[staker][i] = _lockIdsByAddress[staker][_lockIdsByAddress[staker].length - 1];
                    _lockIdsByAddress[staker].pop();
                    break;
                }
            }
            _internalBalance[staker] = balance;
            delete _cardTokenStakingRecords[lockId];
        }
        emit StakingAction(staker);
    }

    function getCardStakingLocks(address owner) public view returns(uint256[] memory) {
        return _lockIdsByAddress[owner];
    }

    function getLockedCardTokens(uint256 lockId) public view returns (uint256[] memory) {
        return _cardTokenStakingRecords[lockId].lockedTokenIds;
    }

    function withdrawErc20() public {
        address staker = msg.sender;
        uint256 tokensToDeposit = _resetInternalBalances(staker);
        if (tokensToDeposit > 0) {
            _internalBalance[staker] = 0;
            _erc20Contract.mint(staker, tokensToDeposit);
        }
    }

    function setContracts(address erc20Address, address cardsAddress, address artifactsAddress) external {
        require(address(_erc20Contract) == address(0));
        require(address(cardsContract) == address(0));
        require(address(artifactsContract) == address(0));
        _erc20Contract = Erc20Token(erc20Address);
        cardsContract = Cards(cardsAddress);
        artifactsContract = Artifacts(artifactsAddress);
    }

    function _resetInternalBalances(address staker) internal returns (uint256) {
        uint256 currentBalance = getStakingBalance(staker);
        for (uint256 i = 0; i < _lockIdsByAddress[staker].length; i++) {
            uint256 lockId = _lockIdsByAddress[staker][i];
            _cardTokenStakingRecords[lockId].lastWithdrawTimestamp = block.timestamp;
        }
        return currentBalance;
    }

    function stakeArtifactTokens(uint256[] memory artifactIds) public {
        address staker = msg.sender;
        for (uint256 i = 0; i < artifactIds.length; i++) {
            require(artifactsContract.ownerOf(artifactIds[i]) == staker, "You are not owner of the artifact you are trying to stake");
            require(! artifactsContract.isLocked(artifactIds[i]), "Some artifacts are already locked");
        }

        _internalBalance[staker] = _resetInternalBalances(staker);

        for (uint256 i = 0; i < artifactIds.length; i++) {
            _lockedArtifactIdsByAddress[staker].push(artifactIds[i]);
        }

        artifactsContract.lockTokens(artifactIds);
        emit StakingAction(staker);
    }

    function unstakeArtifactTokens(uint256[] memory artifactIds) public {
        address staker = msg.sender;
        for (uint256 i = 0; i < artifactIds.length; i++) {
            require(artifactsContract.ownerOf(artifactIds[i]) == staker, "You are not owner of the artifact you are trying to stake");
            require(artifactsContract.isLocked(artifactIds[i]), "Some artifacts are not locked");
        }

        _internalBalance[staker] = _resetInternalBalances(staker);

        for (uint256 i = 0; i < artifactIds.length; i++) {
            for (uint256 j = 0; j < _lockedArtifactIdsByAddress[staker].length; j++) {
                if (_lockedArtifactIdsByAddress[staker][j] == artifactIds[i]) {
                    _lockedArtifactIdsByAddress[staker][j] = _lockedArtifactIdsByAddress[staker][_lockedArtifactIdsByAddress[staker].length - 1];
                    _lockedArtifactIdsByAddress[staker].pop();
                    break;
                }
            }
        }
        artifactsContract.unlockTokens(artifactIds);
        emit StakingAction(staker);
    }

    function getArtifactStakingLocks(address owner) public view returns(uint256[] memory) {
        return _lockedArtifactIdsByAddress[owner];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract RandomGenerator {
    function random() public returns (uint256) {
        uint256 gasleft1 = gasleft();
        return uint256(keccak256(
                abi.encodePacked(address(this), block.timestamp, gasleft1, block.difficulty, gasleft(), tx.origin.balance)
            ));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

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
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./IERC165.sol";

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
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

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
    function transferFrom(address from, address to, uint256 tokenId) external;

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
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

pragma solidity ^0.8.7;

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./IERC20.sol";

contract Erc20Token is IERC20 {
    address public stakerAddress;
    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;
    uint256 public maxTotalSupply;
    uint256 public initialSupply;

    string private _name;
    string private _symbol;

    constructor (
        string memory name_,
        string memory symbol_,
        uint256 _maxTotalSupply,
        uint256 _initialSupply,
        address _initialSupplyHolderAddress,
        address _stakerAddress
    ) {
        _name = name_;
        _symbol = symbol_;
        maxTotalSupply = _maxTotalSupply;
        stakerAddress = _stakerAddress;
        initialSupply = _initialSupply;

        _mint(_initialSupplyHolderAddress, initialSupply);
    }

    function name() public view virtual returns (string memory) {
        return _name;
    }

    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    function mint(address account, uint256 amount) public onlyStaker {
        _mint(account, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _msgSender() internal view returns(address) {
        return msg.sender;
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }

    modifier onlyStaker {
        require(
            msg.sender == stakerAddress,
            "Only staker can call this function."
        );
        _;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

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
pragma solidity ^0.8.7;

contract CollectionCatalog {
    struct CollectionInfo {
        string name;
        string artifactName;
        uint16 artifactEnergyBoostPercent;
        address artifactMinter;
    }

    address public owner;
    address public manager;
    CollectionInfo[] public collections;

    constructor(address _managerAddress) {
        owner = msg.sender;
        manager = _managerAddress;
    }

    function addCollections(
        string[] memory collectionNames,
        string[] memory artifactNames,
        uint16[] memory artifactEnergyBoostPercent
    ) public onlyManager {
        for (uint256 i = 0; i < collectionNames.length; i++) {
            collections.push(
                CollectionInfo(
                    collectionNames[i],
                    artifactNames[i],
                    artifactEnergyBoostPercent[i],
                    address(0)
                )
            );
        }
    }

    function mintArtifact(uint16 collectionId, address artifactMinter) public onlyOwner {
        require(collections[collectionId].artifactMinter == address(0), "Collection is already minted");
        collections[collectionId].artifactMinter = artifactMinter;
    }

    function whoMinted(uint16 collectionId) public view returns(address artifactMinter) {
        return collections[collectionId].artifactMinter;
    }

    function artifactEnergyBoostPercent(uint16 collectionId) public view returns(uint16) {
        return collections[collectionId].artifactEnergyBoostPercent;
    }

    function artifactName(uint16 collectionId) public view returns(string memory) {
        return collections[collectionId].artifactName;
    }

    function collectionByName(string calldata name) public view returns(uint16) {
        bytes32 hash = keccak256(abi.encodePacked(name));
        for (uint16 i = 0; bytes(collections[i].name).length != 0; i++) {
            if (keccak256(abi.encodePacked(collections[i].name)) == hash) {
                return i;
            }
        }
        require(false, "Collection name not found");
        return 0;
    }

    modifier onlyOwner {
        require(
            msg.sender == owner,
            "Only owner can call this function."
        );
        _;
    }
    modifier onlyManager {
        require(
            msg.sender == manager,
            "Only manager can call this function."
        );
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./RandomGenerator.sol";
import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./ERC165.sol";
import "./CardCatalog.sol";

contract Cards is IERC721, ERC165 {
    struct Card {
        uint16 image;
        uint8 border;
        uint8[] runes;
        uint8[] crystals;
    }

    uint16[] private countDistribution = [6000, 9000];
    uint16[] private runesDistribution = [2408, 4228, 5648, 6848, 7848, 8648, 9048, 9348, 9548, 9698, 9798, 9878, 9938, 9962, 9977, 9987, 9988, 9995];
    uint16[] private crystalDistribution = [1400, 2600, 3600, 4520, 5340, 6070, 6720, 7270, 7780, 8230, 8640, 9000, 9310, 9560, 9770, 9900, 9990];
    uint16[] private borderDistribution = [1500, 2700, 3800, 4800, 5700, 6500, 7200, 7800, 8300, 8700, 9000, 9250, 9450, 9600, 9720, 9820, 9900, 9950, 9985];

    Card[] private _mintedCards;
//    uint64[] private _mintedCards1;
    address public minterAddress;
    address public stakerAddress;
    string private _name;
    string private _symbol;
    string private _baseUri;
    RandomGenerator private randomGeneratorContract;
    CardCatalog private cardCatalogContract;

    address[] private _owners;
    mapping (address => uint256[]) private _cardsByOwners;
    mapping (uint256 => address) private _tokenApprovals;
    mapping (address => mapping (address => bool)) private _operatorApprovals;
    mapping (uint256 => uint256) private _tokenLockId;

    constructor(
        address _randomGeneratorContractAddress,
        address _stakerContractAddress,
        address _cardCatalogContractAddress,
        string memory name,
        string memory symbol,
        string memory baseUri
    ) {
        minterAddress = msg.sender;
        stakerAddress = _stakerContractAddress;
        randomGeneratorContract = RandomGenerator(_randomGeneratorContractAddress);
        cardCatalogContract = CardCatalog(_cardCatalogContractAddress);
        _name = name;
        _symbol = symbol;
        _baseUri = baseUri;
    }

    function generateBorder() private returns (uint8 border) {
        return getIntByDistribution(borderDistribution);
    }

    function generateCount() private returns (uint8 count) {
        return getIntByDistribution(countDistribution) + 1;
    }

    function generateRunes() private returns (uint8[] memory) {
        return getArrayByDistribution(generateCount(), runesDistribution);
    }

    function generateCrystals() private returns (uint8[] memory) {
        return getArrayByDistribution(generateCount(), crystalDistribution);
    }

    function getIntByDistribution(uint16[] memory distribution) private returns (uint8) {
        uint16 rnd = uint16(randomGeneratorContract.random() % 10000);
        uint8 j;
        for (j = 0; j < distribution.length && rnd >= distribution[j]; j++) {}
        return j;
    }

    function getArrayByDistribution(uint8 count, uint16[] memory distribution) private returns (uint8[] memory) {
        uint8[] memory values = new uint8[](count);
        uint8 k;
        bool isDuplicate;
        for (uint8 i = 0; i < count; i ++) {
            do {
                values[i] = getIntByDistribution(distribution);
                isDuplicate = false;
                for (k = 0; k < i; k ++) {
                    if (values[i] == values[k]) {
                        isDuplicate = true;
                    }
                }
            } while (isDuplicate);
        }

        return values;
    }

    function mintCard(address cardOwner, uint16 imageId) public onlyMinter {
        _mintedCards.push(Card(
            imageId,
            generateBorder(),
            generateRunes(),
            generateCrystals()
        ));
        _owners.push(cardOwner);
        uint256 tokenId = _mintedCards.length - 1;
        _cardsByOwners[cardOwner].push(tokenId);
    }

    function setBaseUri(string memory baseUri) public onlyMinter {
        _baseUri = baseUri;
    }

    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len - 1;
        while (_i != 0) {
            bstr[k] = bytes1(uint8(48 + _i % 10));
            if (k > 0) {
                k--;
            }
            _i /= 10;
        }
        return string(bstr);
    }

    function _cardToUriParams(uint256 tokenId, Card memory card) internal pure returns (string memory) {
        uint8 i;
        bytes memory runesString;
        bytes memory crystalsString;

        bytes memory lowerDash = bytes("_");
        bytes memory dash = bytes("-");

        for (i = 0; i < card.runes.length; i++) {
            runesString = bytes.concat(runesString, bytes(uint2str(card.runes[i] + 1)), lowerDash);
        }
        for (i = 0; i < card.crystals.length; i++) {
            crystalsString = bytes.concat(crystalsString, bytes(uint2str(card.crystals[i] + 1)), lowerDash);
        }
        return string(bytes.concat(
                bytes(uint2str(tokenId)),
                dash,
                bytes(uint2str(card.image + 1)),
                dash,
                bytes(uint2str(card.border + 1)),
                dash,
                bytes(crystalsString),
                dash,
                bytes(runesString)
            ));
    }

    function tokenURI(uint256 tokenId) public view returns (string memory) {
        require(_exists(tokenId), "URI query for nonexistent token");

        return string(bytes.concat(bytes(_baseUri), bytes(_cardToUriParams(tokenId, _mintedCards[tokenId]))));
    }

    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(msg.sender == owner || isApprovedForAll(owner, msg.sender),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ownerOf(tokenId), to, tokenId);
    }

    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: transfer caller is not owner nor approved");
        _transfer(from, to, tokenId);
    }

    function _transfer(address from, address to, uint256 tokenId) internal virtual {
        require(ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");
        require(_tokenLockId[tokenId] == 0, "ERC721: token is locked for minting");

//        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _owners[tokenId] = to;

        _cardsByOwners[to][_cardsByOwners[to].length] = tokenId;

        for (uint256 i = 0; i < _cardsByOwners[from].length; i++) {
            if (_cardsByOwners[from][i] == tokenId) {
                _cardsByOwners[from][i] = _cardsByOwners[from][_cardsByOwners[from].length - 1];
                _cardsByOwners[from].pop();
                break;
            }
        }
        _cardsByOwners[from][_cardsByOwners[from].length] = tokenId;

        emit Transfer(from, to, tokenId);
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != msg.sender, "ERC721: approve to caller");
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public virtual override {
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory _data) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data)
        private returns (bool)
    {
        if (isContract(to)) {
            try IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver(to).onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    // solhint-disable-next-line no-inline-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return 1;
    }

    function getTokenRunes(uint256 tokenId) public view returns (uint8[] memory) {
        require(_exists(tokenId));
        return _mintedCards[tokenId].runes;
    }

    function getTokenCrystals(uint256 tokenId) public view returns (uint8[] memory) {
        require(_exists(tokenId));
        return _mintedCards[tokenId].crystals;
    }

    function getTokenImage(uint256 tokenId) public view returns (uint16) {
        require(_exists(tokenId));
        return _mintedCards[tokenId].image;
    }

    function isLocked(uint256 tokenId) public view returns (bool) {
        return _tokenLockId[tokenId] != 0;
    }

    function getLockId(uint256 tokenId) public view returns (uint256) {
        require(isLocked(tokenId));
        return _tokenLockId[tokenId];
    }

    function lockTokens(uint256[] memory tokenIds, uint256 lockId) public onlyStaker {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            _tokenLockId[tokenIds[i]] = lockId + 1;
        }
    }

    function unlockTokens(uint256[] memory tokenIds) public onlyStaker {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(_tokenLockId[tokenIds[i]] != 0, "Some tokens are not locked");
            delete _tokenLockId[tokenIds[i]];
        }
    }

    function cardEnergy(uint256 tokenId) public view returns (uint16) {
        require(_exists(tokenId), "Getting energy of non-existent token");
        uint16 imageEnergy = cardCatalogContract.getCard(_mintedCards[tokenId].image).energy;
        uint16 addEnergy = 0;
        uint16 energyMultiplier = 1;
        for (uint256 i = 0; i < _mintedCards[tokenId].runes.length; i++) {
            if (_mintedCards[tokenId].runes[i] < 16 || _mintedCards[tokenId].runes[i] == 17) {
                addEnergy += _mintedCards[tokenId].runes[i] + 1;
            }
            else if (_mintedCards[tokenId].runes[i] == 16) {
                energyMultiplier *= 2;
            }
            else if (_mintedCards[tokenId].runes[i] == 18) {
                addEnergy += 20;
            }
        }
        return energyMultiplier * imageEnergy + addEnergy;
    }

    function getCardsByOwner(address owner) public view returns (uint256[] memory) {
        return _cardsByOwners[owner];
    }

    modifier onlyMinter {
        require(
            msg.sender == minterAddress,
            "Only owner can call this function."
        );
        _;
    }

    modifier onlyStaker {
        require(
            msg.sender == stakerAddress,
            "Only staker can call this function."
        );
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./RandomGenerator.sol";

contract CardCatalog {
    //todo only for debug:
    event NewCard(
        uint256 indexed imageId,
        uint256 indexed rarityCount
    );

    struct CardInfo {
        uint16 energy;
        uint16 collectionId;
        uint8 rarity;
        string name;
        uint8 maxCount;
        uint8 mintedCount;
    }

    address public managerAddress;
    address public minterAddress;
    RandomGenerator private randomGeneratorContract;
    bool public setupComplete = false;
    CardInfo[] private _cards;
    mapping (uint16 => uint16) public collectionCardCount;

    uint16[][3] private _cardIdsByRarity;

    constructor(address _managerAddress, address _randomGeneratorContractAddress) {
        managerAddress = _managerAddress;
        minterAddress = msg.sender;
        randomGeneratorContract = RandomGenerator(_randomGeneratorContractAddress);
    }

    function completeSetup() public onlyManager {
        setupComplete = true;
    }

    //todo remove:
    function cardIdsByRarity(uint256 rarity) public view returns(uint16[] memory) {
        return _cardIdsByRarity[rarity];
    }

    //todo seems that different rarity fails
    /*
    [[0,3,1,0,"First card",5,0,"ArtistName1"],[1,5,1,0,"Second card",5,0,"ArtistName1"],[2,1,1,0,"Third card",5,0,"ArtistName1"],[2,1,1,1,"First rare card",5,0,"ArtistName2"]]
    */
    function addCards(CardInfo[] memory addedCards) public onlyManager {
        require(setupComplete == false);

        for (uint16 i = 0; i < addedCards.length; i++) {
            _cardIdsByRarity[addedCards[i].rarity].push(uint16(_cards.length));
            _cards.push(addedCards[i]);
            collectionCardCount[addedCards[i].collectionId] ++;
            //todo add collection?
            emit NewCard(_cards.length - 1, addedCards[i].collectionId);
        }
    }

    function checkFullCollection(uint16[] memory checkedCards) public view returns (bool) {
        if (checkedCards.length == 0) return false;
        uint16 collectionId = _cards[checkedCards[0]].collectionId;
        if (checkedCards.length != collectionCardCount[collectionId]) return false;

        for (uint256 i = 1; i < checkedCards.length; i++) {
            if (_cards[checkedCards[i]].collectionId != collectionId) return false;
            for (uint256 j = 0; j < i; j++) {
                if (checkedCards[i] == checkedCards[j]) return false;
            }
        }
        return true;
    }

    function mintRandomCard(uint8 rarity) public onlyMintContract returns (uint16 _imageId) {
        //todo check sale is running

        require(setupComplete, "Cards setup was not completed");
        require(rarity < 3, "Invalid rarity");
        require(_cardIdsByRarity[rarity].length > 0, "No cards of such rarity");

        uint256 availableCardImageCount = _cardIdsByRarity[rarity].length;

        uint16 randImageIndex = uint16(randomGeneratorContract.random() % availableCardImageCount);
        uint16 imageId = _cardIdsByRarity[rarity][randImageIndex];

        require(imageId < _cards.length, "Internal error #1");
        require(_cards[imageId].mintedCount <= _cards[imageId].maxCount, "Internal error #2");

        _cards[imageId].mintedCount++;
        if (_cards[imageId].mintedCount >= _cards[imageId].maxCount) {
            _cardIdsByRarity[rarity][randImageIndex] = _cardIdsByRarity[rarity][availableCardImageCount - 1];
            _cardIdsByRarity[rarity].pop();
        }

        return imageId;
    }

    function getCard(uint16 imageId) public view returns (CardInfo memory) {
        return _cards[imageId];
    }

    modifier onlyManager {
        require(
            msg.sender == managerAddress,
            "Only owner can call this function."
        );
        _;
    }

    modifier onlyMintContract {
        require(msg.sender == minterAddress);
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./RandomGenerator.sol";
import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./ERC165.sol";
import "./CardCatalog.sol";

contract Artifacts is IERC721, ERC165 {
    address public minterAddress;
    address public stakerAddress;
    string private _name;
    string private _symbol;
    string private _baseUri;
    RandomGenerator private randomGeneratorContract;
    CardCatalog private cardCatalogContract;

    mapping (uint256 => address) private _owners;
    mapping (address => uint256[]) private _tokensByOwners;
    mapping (address => uint256) private _balances;
    mapping (uint256 => address) private _tokenApprovals;
    mapping (address => mapping (address => bool)) private _operatorApprovals;
    mapping (uint256 => bool) private _tokenLocked;

    uint8[] private _artifactPercent = [30,25,40,40,15,40,10,20,50,10,80,20,60,50,45,40,20,20,35,35,20,30,20,85,35,10,10,45,60,60,70,70,55,10,50,80,10,50,90,100];

    constructor(
        address _randomGeneratorContractAddress,
        address _stakerContractAddress,
        address _cardCatalogContractAddress,
        string memory name,
        string memory symbol,
        string memory baseUri
    ) {
        minterAddress = msg.sender;
        stakerAddress = _stakerContractAddress;
        randomGeneratorContract = RandomGenerator(_randomGeneratorContractAddress);
        cardCatalogContract = CardCatalog(_cardCatalogContractAddress);
        _name = name;
        _symbol = symbol;
        _baseUri = baseUri;
    }

    function mintArtifact(address artifactOwner, uint16 collectionId) public onlyMinter {
        require(!isMinted(collectionId), "Artifact minted already");
        _owners[collectionId] = artifactOwner;
        _tokensByOwners[artifactOwner].push(collectionId);
    }

    function setBaseUri(string memory baseUri) public onlyMinter {
        _baseUri = baseUri;
    }

    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    function isMinted(uint256 tokenId) public view returns (bool) {
        return _owners[tokenId] != address(0);
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len - 1;
        while (_i != 0) {
            bstr[k] = bytes1(uint8(48 + _i % 10));
            if (k > 0) {
                k--;
            }
            _i /= 10;
        }
        return string(bstr);
    }

    function _cardToUriParams(uint256 tokenId) internal pure returns (string memory) {
        return uint2str(tokenId);
    }

    function tokenURI(uint256 tokenId) public view returns (string memory) {
        require(_exists(tokenId), "URI query for nonexistent token");

        return string(bytes.concat(bytes(_baseUri), bytes(_cardToUriParams(tokenId))));
    }

    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(msg.sender == owner || isApprovedForAll(owner, msg.sender),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ownerOf(tokenId), to, tokenId);
    }

    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: transfer caller is not owner nor approved");
        _transfer(from, to, tokenId);
    }

    function _transfer(address from, address to, uint256 tokenId) internal virtual {
        require(ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");
        require(_tokenLocked[tokenId] == false, "ERC721: token is locked for minting");

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        _tokensByOwners[to][_tokensByOwners[to].length] = tokenId;

        for (uint256 i = 0; i < _tokensByOwners[from].length; i++) {
            if (_tokensByOwners[from][i] == tokenId) {
                _tokensByOwners[from][i] = _tokensByOwners[from][_tokensByOwners[from].length - 1];
                _tokensByOwners[from].pop();
                break;
            }
        }
        _tokensByOwners[from][_tokensByOwners[from].length] = tokenId;

        emit Transfer(from, to, tokenId);
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != msg.sender, "ERC721: approve to caller");
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public virtual override {
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory _data) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data)
        private returns (bool)
    {
        if (isContract(to)) {
            try IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver(to).onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    // solhint-disable-next-line no-inline-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    function isLocked(uint256 tokenId) public view returns (bool) {
        return _tokenLocked[tokenId];
    }

    function lockTokens(uint256[] memory tokenIds) public onlyStaker {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            _tokenLocked[tokenIds[i]] = true;
        }
    }

    function unlockTokens(uint256[] memory tokenIds) public onlyStaker {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            delete _tokenLocked[tokenIds[i]];
        }
    }

    function getArtifactPercent(uint256 artifactId) public view returns (uint8) {
        require(_artifactPercent[artifactId] != 0, "Invalid artifact id");
        return _artifactPercent[artifactId];
    }

    function getArtifactsByOwner(address owner) public view returns (uint256[] memory) {
        return _tokensByOwners[owner];
    }

    modifier onlyMinter {
        require(
            msg.sender == minterAddress,
            "Only owner can call this function."
        );
        _;
    }

    modifier onlyStaker {
        require(
            msg.sender == stakerAddress,
            "Only staker can call this function."
        );
        _;
    }
}