pragma solidity ^0.8.5;
//SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/access/Ownable.sol";
import "./BlocksRewardsManager2.sol";


contract BlocksSpace2 is Ownable {
    struct Block {
        uint256 price;
        address owner;
        uint256 blockWhenClaimed;
    }

    struct BlockView {
        uint256 price;
        uint256 priceBls;
        address owner;
        uint256 blockWhenClaimed;
        uint16 blockNumber;
    }

    struct blocksArea {
        address owner;
        uint256 blockstart;
        uint256 blockend;
        string imghash;
        uint256 zindex;
    }

    struct BlockAreaLocation {
        uint256 startBlockX;
        uint256 startBlockY;
        uint256 endBlockX;
        uint256 endBlockY;
    }

    struct UserState {
        blocksArea lastBlocksAreaBought;
        uint256 lastPurchase;
    }

    uint256 constant PRICE_OF_LOGO_BLOCKS = 42 ether;
    BlocksRewardsManager2 public rewardsPool;
    uint256 public minTimeBetweenPurchases = 4 hours + 20 minutes;
    uint256 public maxBlsTakeoverAmount = 420 ether;
    uint256 public minBlsTakeoverAmount = 20 ether;
    uint256 public blsTakeoverTimeInBlocks = 42 * 60 * 60 / 3; // Amount of blocks that pass before high BLS rewards drop to base. (42 hours)
    uint256 public blsFreeTimeInBlocks = 1 * 60 * 60 / 3; // Amount of blocks that pass when there is 0 BLS for takeover (1h)
    uint256 blsTakeoverDecreasePerBlock = maxBlsTakeoverAmount / blsTakeoverTimeInBlocks;
    mapping(uint256 => Block) public blocks;
    mapping(address => UserState) public users;
    
    event MinTimeBetweenPurchasesUpdated(uint256 inSeconds);
    event BlocksAreaPurchased(address indexed blocksAreaOwner, uint256 blocksBought, uint256 paid);
    event BlockClaimPriceUpdated(uint256 newPrice);
    event MaxBlsTakeoverAmountUpdated(uint256 newAmount);
    event MinBlsTakeoverAmountUpdated(uint256 newAmount);
    event BlsTakeoverTimeInBlocksUpdated(uint256 amountSeconds);
    event BlsFreeTimeInBlocksUpdated(uint256 amountSeconds);

    constructor(address rewardsPoolContract_) {
        rewardsPool = BlocksRewardsManager2(rewardsPoolContract_);
        setPriceOfLogoBlocks(0, 301);
    }

    function setPriceOfLogoBlocks(uint256 startBlockId_, uint256 endBlockId_) internal {
        // 0 - 301
        (uint256 startBlockX, uint256 startBlockY) = (startBlockId_ / 100, startBlockId_ % 100);
        (uint256 endBlockX, uint256 endBlockY) = (endBlockId_ / 100, endBlockId_ % 100);
        for (uint256 i = startBlockX; i <= endBlockX; ++i) {
            for (uint256 j = startBlockY; j <= endBlockY; ++j) {
                Block storage currentBlock = blocks[i * 100 + j];
                currentBlock.price = PRICE_OF_LOGO_BLOCKS;
                currentBlock.owner = msg.sender;
            }
        }
    }

    uint256 public blockClaimPrice = 10 * 1e15; // 0.01 BNB

    function purchaseBlocksArea(
        uint256 startBlockId_,
        uint256 endBlockId_,
        string calldata imghash_
    ) external payable {
        BlockAreaLocation memory blocksArea = BlockAreaLocation(
            startBlockId_ / 100,
            startBlockId_ % 100,
            endBlockId_ / 100,
            endBlockId_ % 100
        );

        // 1. Checks
        uint256 paymentReceived = msg.value;
       
        require(
            block.timestamp >= users[msg.sender].lastPurchase + minTimeBetweenPurchases,
            "You must wait between buys"
        );
        require(isBlocksAreaValid(blocksArea), "blocksArea invalid");
        require(bytes(imghash_).length != 0, "Image hash cannot be empty");

        uint256 numberOfBlocks = calculateSizeOfBlocksArea(blocksArea);
        require(paymentReceived == (blockClaimPrice * numberOfBlocks), "You should pay exact amount");
        // Here we need to check if he paid enough BLS for takeover

        // 2. Storage operations
        (address[] memory previousBlockOwners, uint256[] memory previousOwnersPrices) = calculateBlocksOwnershipChanges(
            blocksArea,
            numberOfBlocks
        );
        updateUserState(msg.sender, startBlockId_, endBlockId_, imghash_);

        // 3. Transactions
        // Do transfer of tokens
        // Burn some percent and send rest to another contract for distribution

        // Send fresh info to RewardsPool contract, so buyer gets some sweet rewards
        rewardsPool.blocksAreaBoughtOnSpace{value: paymentReceived}(
            msg.sender,
            previousBlockOwners,
            previousOwnersPrices
        );

        // 4. Emit purchase event
        emit BlocksAreaPurchased(msg.sender, startBlockId_ * 10000 + endBlockId_, paymentReceived);
    }

    function calculateBlocksOwnershipChanges(
        BlockAreaLocation memory blocksArea,
        uint256 numberOfBlocks_
    ) internal returns (address[] memory, uint256[] memory) {
        // Go through all blocks that were paid for
        address[] memory previousBlockOwners = new address[](numberOfBlocks_);
        uint256[] memory previousOwnersPrices = new uint256[](numberOfBlocks_);
        uint256 arrayIndex;
        for (uint256 i = blocksArea.startBlockX; i <= blocksArea.endBlockX; ++i) {
            for (uint256 j = blocksArea.startBlockY; j <= blocksArea.endBlockY; ++j) {
                //Set new state of the Block
                Block storage currentBlock = blocks[i * 100 + j];
                // previousBlockOwners[arrayIndex] = currentBlock.owner;
                // previousOwnersPrices[arrayIndex] = currentBlock.price;
                currentBlock.price = blockClaimPrice; // Set constant price
                currentBlock.owner = msg.sender; // Set new owner of block
                currentBlock.blockWhenClaimed = block.number; // Set when it was claimed
                ++arrayIndex;
            }
        }
        return (previousBlockOwners, previousOwnersPrices);
    }

    function updateUserState(
        address user_,
        uint256 startBlockId_,
        uint256 endBlockId_,
        string calldata imghash_
    ) internal {
        UserState storage userState = users[user_];
        userState.lastBlocksAreaBought.owner = user_;
        userState.lastBlocksAreaBought.blockstart = startBlockId_;
        userState.lastBlocksAreaBought.blockend = endBlockId_;
        userState.lastBlocksAreaBought.imghash = imghash_;
        userState.lastBlocksAreaBought.zindex = block.number;
        userState.lastPurchase = block.timestamp;
    }

    function getPricesOfBlocks(uint256 startBlockId_, uint256 endBlockId_) external view returns (BlockView[] memory) {
        BlockAreaLocation memory blocksArea = BlockAreaLocation(
            startBlockId_ / 100,
            startBlockId_ % 100,
            endBlockId_ / 100,
            endBlockId_ % 100
        );

        require(isBlocksAreaValid(blocksArea), "blocksArea invalid");

        BlockView[42] memory blockAreaTemp;
        uint256 arrayCounter;
        for (uint256 i = blocksArea.startBlockX; i <= blocksArea.endBlockX; ++i) {
            for (uint256 j = blocksArea.startBlockY; j <= blocksArea.endBlockY; ++j) {
                uint16 index = uint16(i * 100 + j);
                Block memory currentBlock = blocks[index];
                uint256 takeoverPriceBls = 0;

                // Checking if block was already claimed, because that is important for takeover price in BLS
                if(currentBlock.blockWhenClaimed > 0){
                    // blsTakeoverTimeInBlocks
                    uint256 blocksSinceLastClaim = block.number - currentBlock.blockWhenClaimed;

                    if(blocksSinceLastClaim < blsTakeoverTimeInBlocks){
                        // First part of declining graph
                        takeoverPriceBls = maxBlsTakeoverAmount - (blocksSinceLastClaim * blsTakeoverDecreasePerBlock);
                    }else if(blocksSinceLastClaim > blsTakeoverTimeInBlocks + blsFreeTimeInBlocks){
                        takeoverPriceBls = minBlsTakeoverAmount;
                    }     
                }
                
                blockAreaTemp[arrayCounter] = BlockView(
                    currentBlock.price != 0 ? currentBlock.price : blockClaimPrice,
                    takeoverPriceBls, 
                    currentBlock.owner,
                    currentBlock.blockWhenClaimed,
                    index // block number
                );
                ++arrayCounter;
            }
        }

        // Shrink array and return only whats filled
        BlockView[] memory blockArea = new BlockView[](arrayCounter);
        for (uint256 i; i < arrayCounter; ++i) {
            blockArea[i] = blockAreaTemp[i];
        }
        return blockArea;
    }

    function calculateSizeOfBlocksArea(BlockAreaLocation memory blocksArea) internal view returns (uint256) {
        uint256 numberOfBlocks;
        for (uint256 i = blocksArea.startBlockX; i <= blocksArea.endBlockX; ++i) {
            for (uint256 j = blocksArea.startBlockY; j <= blocksArea.endBlockY; ++j) {
                ++numberOfBlocks;
            }
        }
        return numberOfBlocks;
    }

    function isBlocksAreaValid(BlockAreaLocation memory blocksArea) internal view returns (bool) {
        require(blocksArea.startBlockX < 42 && blocksArea.endBlockX < 42, "X blocks out of range. Oh Why?");
        require(blocksArea.startBlockY < 24 && blocksArea.endBlockY < 24, "Y blocks out of range. Oh Why?");

        uint256 blockWidth = blocksArea.endBlockX - blocksArea.startBlockX + 1; // +1 because its including
        uint256 blockHeight = blocksArea.endBlockY - blocksArea.startBlockY + 1; // +1 because its including
        uint256 blockArea = blockWidth * blockHeight;

        return blockWidth <= 7 && blockHeight <= 7 && blockArea <= 42;
    }

    function updateMinTimeBetweenPurchases(uint256 inSeconds_) external onlyOwner {
        minTimeBetweenPurchases = inSeconds_;
        emit MinTimeBetweenPurchasesUpdated(inSeconds_);
    }

    function updateBlockClaimPrice(uint256 newPrice) external onlyOwner {
        blockClaimPrice = newPrice;
        emit BlockClaimPriceUpdated(newPrice);
    }
    
    function updateMaxBlsTakeoverAmount(uint256 newAmount) external onlyOwner {
        maxBlsTakeoverAmount = newAmount;
        blsTakeoverDecreasePerBlock = maxBlsTakeoverAmount / blsTakeoverTimeInBlocks;
        emit MaxBlsTakeoverAmountUpdated(newAmount);
    }
    
    function updateminBlsTakeoverAmount(uint256 newAmount) external onlyOwner {
        minBlsTakeoverAmount = newAmount;
        emit MinBlsTakeoverAmountUpdated(newAmount);
    }
    
    function updateBlsTakeoverTimeInBlocks(uint256 amountSeconds) external onlyOwner {
        blsTakeoverTimeInBlocks = amountSeconds / 3; // Get amount of blocks from seconds
        blsTakeoverDecreasePerBlock = maxBlsTakeoverAmount / blsTakeoverTimeInBlocks;
        emit BlsTakeoverTimeInBlocksUpdated(amountSeconds);
    }
    
    function updateBlsFreeTimeInBlocks(uint256 amountSeconds) external onlyOwner {
        blsFreeTimeInBlocks = amountSeconds / 3; // Get amount of blocks from seconds
        emit BlsFreeTimeInBlocksUpdated(amountSeconds);
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

pragma solidity ^0.8.5;
//SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./BlocksStaking.sol";


contract BlocksRewardsManager2 is Ownable {
    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many blocks user owns currently.
        uint256 pendingRewards; // Rewards assigned, but not yet claimed
        uint256 rewardsDebt;
    }

    // Info of each blocks.space
    struct SpaceInfo {
        uint256 spaceId;
        uint256 amountOfBlocksBought; // Number of all blocks bought on this space
        address contractAddress; // Address of space contract.
        uint256 blsPerBlockAreaPerBlock; // Start with 830000000000000 wei (approx 24 BLS/block.area/day)
        uint256 blsRewardsAcc;
        uint256 blsRewardsAccLastUpdated;
    }

    // Management of splitting rewards
    uint256 constant MAX_TREASURY_FEE = 5;
    uint256 constant MAX_LIQUIDITY_FEE = 10;
    uint256 constant MAX_PREVIOUS_OWNER_FEE = 50;
    uint256 public treasuryFee = 5;
    uint256 public liquidityFee = 10;
    uint256 public previousOwnerFee = 25;

    address payable public treasury;
    IERC20 public blsToken;
    BlocksStaking public blocksStaking;
    SpaceInfo[] public spaceInfo;
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    mapping(address => uint256) public spaceIdMapping; // Not 0 based, but starts with id = 1
    // Variables that support calculation of proper bls rewards distributions
    uint256 public blsPerBlock;
    uint256 public blsLastRewardsBlock;
    uint256 public blsSpacesRewardsDebt; // bls rewards debt accumulated
    uint256 public blsSpacesDebtLastUpdatedBlock;
    uint256 public blsSpacesRewardsClaimed;

    event SpaceAdded(uint256 indexed spaceId, address indexed space, address indexed addedBy);
    event Claim(address indexed user, uint256 amount);
    event BlsPerBlockAreaPerBlockUpdated(uint256 spaceId, uint256 newAmount);
    event TreasuryFeeSet(uint256 newFee);
    event LiquidityFeeSet(uint256 newFee);
    event PreviousOwnerFeeSet(uint256 newFee);
    event BlocksStakingContractUpdated(address add);
    event TreasuryWalletUpdated(address newWallet);
    event BlsRewardsForDistributionDeposited(uint256 amount);

    constructor(IERC20 blsAddress_, address blocksStakingAddress_, address treasury_) {
        blsToken = IERC20(blsAddress_);
        blocksStaking = BlocksStaking(blocksStakingAddress_);
        treasury = payable(treasury_);
    }

    function spacesLength() external view returns (uint256) {
        return spaceInfo.length;
    }

    function addSpace(address spaceContract_, uint256 blsPerBlockAreaPerBlock_) external onlyOwner {
        require(spaceIdMapping[spaceContract_] == 0, "Space is already added.");
        require(spaceInfo.length < 20, "Max spaces limit reached.");
        uint256 spaceId = spaceInfo.length; 
        spaceIdMapping[spaceContract_] = spaceId + 1; // Only here numbering is not 0 indexed, because of check above
        SpaceInfo storage newSpace = spaceInfo.push();
        newSpace.contractAddress = spaceContract_;
        newSpace.spaceId = spaceId;
        newSpace.blsPerBlockAreaPerBlock = blsPerBlockAreaPerBlock_;
        emit SpaceAdded(spaceId, spaceContract_, msg.sender);
    }

    function updateBlsPerBlockAreaPerBlock(uint256 spaceId_, uint256 newAmount_) external onlyOwner {
        SpaceInfo storage space = spaceInfo[spaceId_];
        require(space.contractAddress != address(0), "SpaceInfo does not exist");

        massUpdateSpaces();

        uint256 oldSpaceBlsPerBlock = space.blsPerBlockAreaPerBlock * space.amountOfBlocksBought;
        uint256 newSpaceBlsPerBlock = newAmount_ * space.amountOfBlocksBought;
        blsPerBlock = blsPerBlock + newSpaceBlsPerBlock - oldSpaceBlsPerBlock;
        space.blsPerBlockAreaPerBlock = newAmount_;
        
        recalculateLastRewardBlock();
        emit BlsPerBlockAreaPerBlockUpdated(spaceId_, newAmount_);
    }

    function pendingBlsTokens(uint256 spaceId_, address user_) public view returns (uint256) {
        SpaceInfo storage space = spaceInfo[spaceId_];
        UserInfo storage user = userInfo[spaceId_][user_];
        uint256 rewards;
        if (user.amount > 0 && space.blsRewardsAccLastUpdated < block.number) {
            uint256 multiplier = getMultiplier(space.blsRewardsAccLastUpdated);
            uint256 blsRewards = multiplier * space.blsPerBlockAreaPerBlock;
            rewards = user.amount * blsRewards;
        }
        return user.amount * space.blsRewardsAcc + rewards + user.pendingRewards - user.rewardsDebt;
    }

    function getMultiplier(uint256 lastRewardCalcBlock) internal view returns (uint256) {
        if (block.number > blsLastRewardsBlock) {           
            if(blsLastRewardsBlock >= lastRewardCalcBlock){
                return blsLastRewardsBlock - lastRewardCalcBlock;
            }else{
                return 0;
            }
        } else {
            return block.number - lastRewardCalcBlock;  
        }
    }

    function massUpdateSpaces() public {
        uint256 length = spaceInfo.length;
        for (uint256 spaceId = 0; spaceId < length; ++spaceId) {
            updateSpace(spaceId);
        }      
        updateManagerState();
    }

    function updateManagerState() internal {
        blsSpacesRewardsDebt = blsSpacesRewardsDebt + getMultiplier(blsSpacesDebtLastUpdatedBlock) * blsPerBlock;
        blsSpacesDebtLastUpdatedBlock = block.number;
    }

    function updateSpace(uint256 spaceId_) internal {
        // If space was not yet updated, update rewards accumulated
        SpaceInfo storage space = spaceInfo[spaceId_];
        if (block.number <= space.blsRewardsAccLastUpdated) {
            return;
        }
        if (space.amountOfBlocksBought == 0) {
            space.blsRewardsAccLastUpdated = block.number;
            return;
        }
        if (block.number > space.blsRewardsAccLastUpdated) {
            uint256 multiplierSpace = getMultiplier(space.blsRewardsAccLastUpdated);
            space.blsRewardsAcc = space.blsRewardsAcc + multiplierSpace * space.blsPerBlockAreaPerBlock;
            space.blsRewardsAccLastUpdated = block.number;
        }
    }

    function blocksAreaBoughtOnSpace(
        address buyer_,
        address[] calldata previousBlockOwners_,
        uint256[] calldata previousOwnersPrices_
    ) external payable {

        // Here calling contract should be space and noone else
        uint256 spaceId_ = spaceIdMapping[msg.sender];
        require(spaceId_ > 0, "Call not from BlocksSpace");
        spaceId_ = spaceId_ - 1; // because this is now index
        updateSpace(spaceId_);

        SpaceInfo storage space = spaceInfo[spaceId_];
        UserInfo storage user = userInfo[spaceId_][buyer_];
        uint256 spaceBlsRewardsAcc = space.blsRewardsAcc;

        // If user already had some block.areas then calculate all rewards pending
        if (user.amount > 0) {
            user.pendingRewards = pendingBlsTokens(spaceId_, buyer_);
        }
        
        uint256 numberOfBlocksAddedToSpace;        
        uint256 allPreviousOwnersPaid;
        { // Stack too deep scoping
            //remove blocks from previous owners that this guy took over. Max 42 loops
            uint256 numberOfBlocksBought = previousBlockOwners_.length;      
            uint256 numberOfBlocksToRemove;
            for (uint256 i = 0; i < numberOfBlocksBought; ++i) {
                // If previous owners of block are non zero address, means we need to take block from them
                if (previousBlockOwners_[i] != address(0)) {
                    allPreviousOwnersPaid = allPreviousOwnersPaid + previousOwnersPrices_[i];
                    // Calculate previous users pending BLS rewards
                    UserInfo storage prevUser = userInfo[spaceId_][previousBlockOwners_[i]];
                    prevUser.pendingRewards = pendingBlsTokens(spaceId_, previousBlockOwners_[i]);
                    // Remove his ownership of block
                    --prevUser.amount;
                    prevUser.rewardsDebt = prevUser.amount * spaceBlsRewardsAcc;
                    ++numberOfBlocksToRemove;
                }
            }
            numberOfBlocksAddedToSpace = numberOfBlocksBought - numberOfBlocksToRemove;
            // Set user data
            user.amount = user.amount + numberOfBlocksBought;
            user.rewardsDebt = user.amount * spaceBlsRewardsAcc; // Reset debt, because at top we gave him rewards already
        }      

        // If amount of blocks on space changed, we need to update space and global state
        if (numberOfBlocksAddedToSpace > 0) {

            updateManagerState();

            blsPerBlock = blsPerBlock + space.blsPerBlockAreaPerBlock * numberOfBlocksAddedToSpace;
            space.amountOfBlocksBought = space.amountOfBlocksBought + numberOfBlocksAddedToSpace;

            // Recalculate what is last block eligible for BLS rewards
            recalculateLastRewardBlock();
        }

        // Calculate and subtract fees in first part
        // In second part, calculate how much rewards are being rewarded to previous block owners
        (uint256 rewardToForward, uint256[] memory prevOwnersRewards) = calculateAndDistributeFees(
            msg.value,
            previousOwnersPrices_,
            allPreviousOwnersPaid
        );

        // Send to distribution part
        blocksStaking.distributeRewards{value: rewardToForward}(previousBlockOwners_, prevOwnersRewards);
    }

    function calculateAndDistributeFees(
        uint256 rewardReceived_,
        uint256[] calldata previousOwnersPrices_,
        uint256 previousOwnersPaid_
    ) internal returns (uint256, uint256[] memory) {
        uint256 numberOfBlocks = previousOwnersPrices_.length;
        uint256 feesTaken;
        uint256 previousOwnersFeeValue;
        uint256[] memory previousOwnersRewardWei = new uint256[](numberOfBlocks);
        if (previousOwnerFee > 0 && previousOwnersPaid_ != 0) {
            previousOwnersFeeValue = (rewardReceived_ * previousOwnerFee) / 100; // Calculate how much is for example 25% of whole rewards gathered
            uint256 onePartForPreviousOwners = (previousOwnersFeeValue * 1e9) / previousOwnersPaid_; // Then calculate one part for previous owners sum
            for (uint256 i = 0; i < numberOfBlocks; ++i) {
                // Now we calculate exactly how much one user gets depending on his investment (it needs to be proportionally)
                previousOwnersRewardWei[i] = (onePartForPreviousOwners * previousOwnersPrices_[i]) / 1e9;
            }
        }
        // Can be max 5%
        if (treasuryFee > 0) {
            uint256 treasuryFeeValue = (rewardReceived_ * treasuryFee) / 100;
            if (treasuryFeeValue > 0) {
                feesTaken = feesTaken + treasuryFeeValue;
            }
        }
        // Can be max 10%
        if (liquidityFee > 0) {
            uint256 liquidityFeeValue = (rewardReceived_ * liquidityFee) / 100;
            if (liquidityFeeValue > 0) {
                feesTaken = feesTaken + liquidityFeeValue;
            }
        }
        // Send fees to treasury. Max together 15%. We use call, because it enables auto liqudity provisioning on DEX in future when token is trading
        if (feesTaken > 0) {
            (bool sent,) = treasury.call{value: feesTaken}("");
            require(sent, "Failed to send moneyz");
        }

        return (rewardReceived_ - feesTaken, previousOwnersRewardWei);
    }

    function claim(uint256 spaceId_) external {
        updateSpace(spaceId_);
        UserInfo storage user = userInfo[spaceId_][msg.sender];
        uint256 toClaimAmount = pendingBlsTokens(spaceId_, msg.sender);
        if (toClaimAmount > 0) {
            uint256 claimedAmount = safeBlsTransfer(msg.sender, toClaimAmount);
            emit Claim(msg.sender, claimedAmount);
            // This is also kinda check, since if user claims more than eligible, this will revert
            user.pendingRewards = toClaimAmount - claimedAmount;
            user.rewardsDebt = spaceInfo[spaceId_].blsRewardsAcc * user.amount;
            blsSpacesRewardsClaimed = blsSpacesRewardsClaimed + claimedAmount; // Globally claimed rewards, for proper end distribution calc
        }
    }

    // Safe BLS transfer function, just in case if rounding error causes pool to not have enough BLSs.
    function safeBlsTransfer(address to_, uint256 amount_) internal returns (uint256) {
        uint256 blsBalance = blsToken.balanceOf(address(this));
        if (amount_ > blsBalance) {
            blsToken.transfer(to_, blsBalance);
            return blsBalance;
        } else {
            blsToken.transfer(to_, amount_);
            return amount_;
        }
    }

    function setTreasuryFee(uint256 newFee_) external onlyOwner {
        require(newFee_ <= MAX_TREASURY_FEE);
        treasuryFee = newFee_;
        emit TreasuryFeeSet(newFee_);
    }

    function setLiquidityFee(uint256 newFee_) external onlyOwner {
        require(newFee_ <= MAX_LIQUIDITY_FEE);
        liquidityFee = newFee_;
        emit LiquidityFeeSet(newFee_);
    }

    function setPreviousOwnerFee(uint256 newFee_) external onlyOwner {
        require(newFee_ <= MAX_PREVIOUS_OWNER_FEE);
        previousOwnerFee = newFee_;
        emit PreviousOwnerFeeSet(newFee_);
    }

    function updateBlocksStakingContract(address address_) external onlyOwner {
        blocksStaking = BlocksStaking(address_);
        emit BlocksStakingContractUpdated(address_);
    }

    function updateTreasuryWallet(address newWallet_) external onlyOwner {
        treasury = payable(newWallet_);
        emit TreasuryWalletUpdated(newWallet_);
    }

    function depositBlsRewardsForDistribution(uint256 amount_) external onlyOwner {
        blsToken.transferFrom(address(msg.sender), address(this), amount_);

        massUpdateSpaces();
        recalculateLastRewardBlock();

        emit BlsRewardsForDistributionDeposited(amount_);    
    }

    function recalculateLastRewardBlock() internal {
        uint256 blsBalance = blsToken.balanceOf(address(this));
        if (blsBalance + blsSpacesRewardsClaimed >= blsSpacesRewardsDebt && blsPerBlock > 0) {
            uint256 blocksTillBlsRunOut = (blsBalance + blsSpacesRewardsClaimed - blsSpacesRewardsDebt) / blsPerBlock;
            blsLastRewardsBlock = block.number + blocksTillBlsRunOut;
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

pragma solidity 0.8.5;
//SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./BLSToken.sol";

/**
 * @dev This contract implements the logic for staking BLS amount. It
 * also handles BNB rewards distribution to users for their blocks taken
 * over (that got covered) and rewards for staked BLS amount.
 */
contract BlocksStaking is Ownable {
    using SafeERC20 for BLSToken;

    // Object with information for a user
    struct UserInfo {
        uint256 amount; // Amount of amount being staked
        uint256 rewardDebt;
        uint256 takeoverReward; // Reward for covered blocks
    }

    uint256 constant BURN_PERCENT_WITHDRAWAL = 1; // Withdrawals burning 1% of your tokens. Deflationary, adding value
    uint256 public rewardsDistributionPeriod = 24 days / 3; // How long are we distributing incoming rewards
    // Global staking variables
    uint256 public totalTokens; // Total amount of amount currently staked
    uint256 public rewardsPerBlock; // Multiplied by 1e12 for better division precision
    uint256 public rewardsFinishedBlock; // When will rewards distribution end
    uint256 public accRewardsPerShare; // Accumulated rewards per share
    uint256 public lastRewardCalculatedBlock; // Last time we calculated accumulation of rewards per share
    uint256 public allUsersRewardDebt; // Helper to keep track of proper account balance for distribution
    uint256 public takeoverRewards; // Helper to keep track of proper account balance for distribution

    // Mapping of UserInfo object to a wallet
    mapping(address => UserInfo) public userInfo;

    // The BLS token contract
    BLSToken private blsToken;

    // Event that is triggered when a user claims his rewards
    event Claim(address indexed user, uint256 reward);
    event Withdraw(address indexed user, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 amount);
    event Deposit(address indexed user, uint256 amount);
    event RewardDistributionPeriodSet(uint256 period);

    /**
     * @dev Provides addresses for BLS token contract
     */
    constructor(BLSToken blsTokenAddress_) {
        blsToken = BLSToken(blsTokenAddress_);
    }

    function setRewardDistributionPeriod(uint256 period_) external onlyOwner {
        rewardsDistributionPeriod = period_;
        emit RewardDistributionPeriodSet(period_);
    }

    // View function to see pending BLSs on frontend.
    function pendingRewards(address user_) public view returns (uint256) {
        UserInfo storage user = userInfo[user_];
        uint256 tempAccRewardsPerShare = accRewardsPerShare;
        if (user.amount > 0) {
            tempAccRewardsPerShare = tempAccRewardsPerShare + (rewardsPerBlock * getMultiplier()) / totalTokens;
        }
        return ((tempAccRewardsPerShare * user.amount) / 1e12) + user.takeoverReward - user.rewardDebt;
    }

    // View function for showing rewards counter on frontend. Its multiplied by 1e12
    function rewardsPerBlockPerToken() external view returns(uint256) {
        if (block.number > rewardsFinishedBlock || totalTokens <= 0) {
            return 0;
        } else {
            return rewardsPerBlock / totalTokens;
        }
    }

    function getMultiplier() internal view returns (uint256) {
        if (block.number > rewardsFinishedBlock) {
            if(rewardsFinishedBlock >= lastRewardCalculatedBlock){
                return rewardsFinishedBlock - lastRewardCalculatedBlock;
            }else{
                return 0;
            }
        }else{
            return block.number - lastRewardCalculatedBlock;
        }
    }

    function updateState() internal {
        if(totalTokens > 0){
            accRewardsPerShare = accRewardsPerShare + (rewardsPerBlock * getMultiplier()) / totalTokens;
        }
        lastRewardCalculatedBlock = block.number;
    }

    /**
     * @dev The user deposits BLS amount for staking.
     */
    function deposit(uint256 amount_) external {
        UserInfo storage user = userInfo[msg.sender];
        // if there are staked amount, fully harvest current reward
        if (user.amount > 0) {
            claim();
        }

        if (totalTokens > 0) {
            updateState();
        } else {
            calculateRewardsDistribution(); // Means first time any user deposits, so start distributing
            lastRewardCalculatedBlock = block.number;
        }    

        totalTokens = totalTokens + amount_; // sum of total staked amount
        uint256 userRewardDebtBefore = user.rewardDebt;
        user.amount = user.amount + amount_; // cache staked amount count for this wallet
        user.rewardDebt = (accRewardsPerShare * user.amount) / 1e12; // cache current total reward per token
        allUsersRewardDebt = allUsersRewardDebt + user.rewardDebt - userRewardDebtBefore;
        emit Deposit(msg.sender, amount_);
        // Transfer BLS amount from the user to this contract
        blsToken.safeTransferFrom(address(msg.sender), address(this), amount_);
    }

    /**
     * @dev The user withdraws staked BLS amount and claims the rewards.
     */
    function withdraw() external {
        UserInfo storage user = userInfo[msg.sender];
        uint256 amount = user.amount;
        require(amount > 0, "No amount deposited for withdrawal.");
        // Claim any available rewards
        claim();

        totalTokens = totalTokens - amount;

        // If after withdraw, there is noone else staking and there are still rewards to be distributed, then reset rewards debt
        if(totalTokens == 0 && rewardsFinishedBlock > block.number){
            allUsersRewardDebt = 0;
        }else{
            // Deduct whatever was added when it was claimed
            allUsersRewardDebt = allUsersRewardDebt - user.rewardDebt;
        }
        user.amount = 0;
        user.rewardDebt = 0;

        uint256 burnAmount = amount * BURN_PERCENT_WITHDRAWAL / 100;
        blsToken.burn(burnAmount);

        // Transfer BLS amount from this contract to the user
        uint256 amountWithdrawn = safeBlsTransfer(address(msg.sender), amount - burnAmount);
        emit Withdraw(msg.sender, amountWithdrawn);
    }
    
    /**
     * @dev The user just withdraws staked BLS amount and leaves any rewards.
     */
    function emergencyWithdraw() public {
        UserInfo storage user = userInfo[msg.sender];

        uint256 amount = user.amount;
        totalTokens = totalTokens - amount;
        allUsersRewardDebt = allUsersRewardDebt - user.rewardDebt;
        user.amount = 0;
        user.rewardDebt = 0;
        user.takeoverReward = 0;

        uint256 burnAmount = amount * BURN_PERCENT_WITHDRAWAL / 100;
        blsToken.burn(burnAmount);

        // Transfer BLS amount from this contract to the user
        uint256 amountWithdrawn = safeBlsTransfer(address(msg.sender), amount - burnAmount);
        emit EmergencyWithdraw(msg.sender, amountWithdrawn);
    }

    /**
     * @dev Claim rewards from staking and covered blocks.
     */
    function claim() public {
        // Update contract state
        updateState();

        uint256 reward = pendingRewards(msg.sender);
        if (reward <= 0) return; // skip if no rewards

        UserInfo storage user = userInfo[msg.sender];
        takeoverRewards = takeoverRewards - user.takeoverReward;
        user.rewardDebt = (accRewardsPerShare * user.amount) / 1e12; // reset: cache current total reward per token
        allUsersRewardDebt = allUsersRewardDebt + reward - user.takeoverReward;
        user.takeoverReward = 0; // reset takeover reward
        // transfer reward in BNBs to the user
        (bool success, ) = msg.sender.call{value: reward}("");
        require(success, "Transfer failed.");
        emit Claim(msg.sender, reward);
    }

    /**
     * @dev Distribute rewards for covered blocks, what remains goes for staked amount.
     */
    function distributeRewards(address[] calldata addresses_, uint256[] calldata rewards_) external payable {
        uint256 tmpTakeoverRewards;
        for (uint256 i = 0; i < addresses_.length; ++i) {
            // process each reward for covered blocks
            userInfo[addresses_[i]].takeoverReward = userInfo[addresses_[i]].takeoverReward + rewards_[i]; // each user that got blocks covered gets a reward
            tmpTakeoverRewards = tmpTakeoverRewards + rewards_[i];
        }
        takeoverRewards = takeoverRewards + tmpTakeoverRewards;

        // what remains is the reward for staked amount
        if (msg.value - tmpTakeoverRewards > 0 && totalTokens > 0) {
            // Update rewards per share because balance changes
            updateState();
            calculateRewardsDistribution();
        }
    }

    function calculateRewardsDistribution() internal {
        uint256 allReservedRewards = (accRewardsPerShare * totalTokens) / 1e12;
        uint256 availableForDistribution = (address(this).balance + allUsersRewardDebt - allReservedRewards - takeoverRewards);
        rewardsPerBlock = (availableForDistribution * 1e12) / rewardsDistributionPeriod;
        rewardsFinishedBlock = block.number + rewardsDistributionPeriod;
    }

    /**
     * @dev Safe BLS transfer function in case of a rounding error. If not enough amount in the contract, trensfer all of them.
     */
    function safeBlsTransfer(address to_, uint256 amount_) internal returns (uint256) {
        uint256 blsBalance = blsToken.balanceOf(address(this));
        if (amount_ > blsBalance) {
            blsToken.transfer(to_, blsBalance);
            return blsBalance;
        } else {
            blsToken.transfer(to_, amount_);
            return amount_;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

pragma solidity 0.8.5;
//SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract BLSToken is ERC20 {

    uint maxSupply = 42000000 ether; // 42 million max tokens

    constructor() ERC20("BlocksSpace Token", "BLS") {
        _mint(_msgSender(), maxSupply);
    }

    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
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

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

