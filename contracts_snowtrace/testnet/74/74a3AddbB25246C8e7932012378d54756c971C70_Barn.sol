import "./Ownable.sol";
import "./Pausable.sol";
import "./ERC721Enumerable.sol";
import "./Hunter.sol";
import "./GEM.sol";

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Barn is Ownable, IERC721Receiver, Pausable {
    // maximum alpha score for a Hunter
    uint8 public constant MAX_ALPHA = 8;

    // struct to store a stake's token, owner, and earning values
    struct Stake {
        uint16 tokenId;
        uint80 value;
        address owner;
    }

    event TokenStaked(address owner, uint256 tokenId, uint256 value);
    event AdventurerClaimed(uint256 tokenId, uint256 earned, bool unstaked);
    event HunterClaimed(uint256 tokenId, uint256 earned, bool unstaked);

    // reference to the Hunter NFT contract
    Hunter hunter;
    // reference to the $GEM contract for minting $GEM earnings
    GEM gem;

    // maps tokenId to stake
    mapping(uint256 => Stake) public barn;
    // maps alpha to all hunter stakes with that alpha
    mapping(uint256 => Stake[]) public pack;
    // tracks location of each Hunter in Pack
    mapping(uint256 => uint256) public packIndices;
    // total alpha scores staked
    uint256 public totalAlphaStaked = 0;
    // any rewards distributed when no hunters are staked
    uint256 public unaccountedRewards = 0;
    // amount of $GEM due for each alpha point staked
    uint256 public gemPerAlpha = 0;

    // adventurer earn 10000 $GEM per day
    uint256 public constant DAILY_GEM_RATE = 10000 ether;
    // adventurer must have 2 days worth of $GEM to unstake or else it's too cold
    uint256 public constant MINIMUM_TO_EXIT = 2 days;
    // hunters take a 20% tax on all $GEM claimed
    uint256 public constant GEM_CLAIM_TAX_PERCENTAGE = 20;
    // there will only ever be (roughly) 2.4 billion $GEM earned through staking
    uint256 public MAXIMUM_GLOBAL_GEM = 2400000000 ether;
    //tax on claim
    uint256 public CLAIMING_FEE = 0.01 ether;

    // amount of $GEM earned so far
    uint256 public totalGemEarned;
    // number of Adventurer staked in the Barn
    uint256 public totalAdventurerStaked;
    // the last time $GEM was claimed
    uint256 public lastClaimTimestamp;

    // emergency rescue to allow unstaking without any checks but without $GEM
    bool public rescueEnabled = false;

    /**
     * @param _hunter reference to the Hunter NFT contract
     * @param _gem reference to the $GEM token
     */
    constructor(address _hunter, address _gem) {
        hunter = Hunter(_hunter);
        gem = GEM(_gem);
    }

    function setMAXIMUM_GLOBAL_GEM(uint256 _MAXIMUM_GLOBAL_GEM)
        external
        onlyOwner
    {
        MAXIMUM_GLOBAL_GEM = _MAXIMUM_GLOBAL_GEM;
    }

    //if its wrong
    function setClaimingFee(uint256 _newfee) external onlyOwner {
        CLAIMING_FEE = _newfee;
    }

    /** STAKING */

    /**
     * adds Adventurer and Hunters to the Barn and Pack
     * @param account the address of the staker
     * @param tokenIds the IDs of the Adventurer and Hunters to stake
     */
    function addManyToBarnAndPack(address account, uint16[] memory tokenIds)
        external
    {
        require(
            (account == _msgSender() && account == tx.origin) ||
                _msgSender() == address(hunter),
            "DONT GIVE YOUR TOKENS AWAY"
        );
        for (uint256 i = 0; i < tokenIds.length; i++) {
            if (_msgSender() != address(hunter)) {
                // dont do this step if its a mint + stake
                require(
                    hunter.ownerOf(tokenIds[i]) == _msgSender(),
                    "AINT YO TOKEN"
                );
                hunter.transferFrom(_msgSender(), address(this), tokenIds[i]);
            } else if (tokenIds[i] == 0) {
                continue; // there may be gaps in the array for stolen tokens
            }

            if (isAdventurer(tokenIds[i]))
                _addAdventurerToBarn(account, tokenIds[i]);
            else _addHunterToPack(account, tokenIds[i]);
        }
    }

    /**
     * adds a single Adventurer to the Barn
     * @param account the address of the staker
     * @param tokenId the ID of the Adventurer to add to the Barn
     */
    function _addAdventurerToBarn(address account, uint256 tokenId)
        internal
        whenNotPaused
        _updateEarnings
    {
        barn[tokenId] = Stake({
            owner: account,
            tokenId: uint16(tokenId),
            value: uint80(block.timestamp)
        });
        totalAdventurerStaked += 1;
        emit TokenStaked(account, tokenId, block.timestamp);
    }

    /**
     * adds a single Hunter to the Pack
     * @param account the address of the staker
     * @param tokenId the ID of the Hunter to add to the Pack
     */
    function _addHunterToPack(address account, uint256 tokenId) internal {
        uint256 alpha = _alphaForHunter(tokenId);
        totalAlphaStaked += alpha; // Portion of earnings ranges from 8 to 5
        packIndices[tokenId] = pack[alpha].length; // Store the location of the hunter in the Pack
        pack[alpha].push(
            Stake({
                owner: account,
                tokenId: uint16(tokenId),
                value: uint80(gemPerAlpha)
            })
        ); // Add the hunter to the Pack
        emit TokenStaked(account, tokenId, gemPerAlpha);
    }

    /** CLAIMING / UNSTAKING */

    /**
     * realize $GEM earnings and optionally unstake tokens from the Barn / Pack
     * to unstake a Adventurer it will require it has 2 days worth of $GEM unclaimed
     * @param tokenIds the IDs of the tokens to claim earnings from
     * @param unstake whether or not to unstake ALL of the tokens listed in tokenIds
     */
    function claimManyFromBarnAndPack(uint16[] memory tokenIds, bool unstake)
        external
        payable
        whenNotPaused
        _updateEarnings
    {
        //payable with the tax
        require(msg.value >= tokenIds.length * CLAIMING_FEE, "you didnt pay tax");
        uint256 owed = 0;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            if (isAdventurer(tokenIds[i]))
                owed += _claimAdventurerFromBarn(tokenIds[i], unstake);
            else owed += _claimHunterFromPack(tokenIds[i], unstake);
        }
        //fee transfer
        
        if (owed == 0) return;
        gem.mint(_msgSender(), owed);
    }

    function calculateRewards(uint256 tokenId)
        external
        view
        returns (uint256 owed)
    {
        Stake memory stake = barn[tokenId];
        if (hunter.getTokenTraits(tokenId).isAdventurer) {
            if (totalGemEarned < MAXIMUM_GLOBAL_GEM) {
                owed =
                    ((block.timestamp - stake.value) * DAILY_GEM_RATE) /
                    1 days;
            } else if (stake.value > lastClaimTimestamp) {
                owed = 0; // $GEM production stopped already
            } else {
                owed =
                    ((lastClaimTimestamp - stake.value) * DAILY_GEM_RATE) /
                    1 days; // stop earning additional $GEM if it's all been earned
            }
        } else {
            uint256 alpha = _alphaForHunter(tokenId);
            owed = (alpha) * (gemPerAlpha - stake.value);
        }
    }

    /**
     * realize $GEM earnings for a single Adventurer and optionally unstake it
     * if not unstaking, pay a 20% tax to the staked Hunters
     * if unstaking, there is a 50% chance all $GEM is stolen
     * @param tokenId the ID of the Adventurer to claim earnings from
     * @param unstake whether or not to unstake the Adventurer
     * @return owed - the amount of $GEM earned
     */
    function _claimAdventurerFromBarn(uint256 tokenId, bool unstake)
        internal
        returns (uint256 owed)
    {
        Stake memory stake = barn[tokenId];
        require(stake.owner == _msgSender(), "SWIPER, NO SWIPING");
        require(
            !(unstake && block.timestamp - stake.value < MINIMUM_TO_EXIT),
            "GONNA BE COLD WITHOUT TWO DAY'S GEM"
        );
        if (totalGemEarned < MAXIMUM_GLOBAL_GEM) {
            owed = ((block.timestamp - stake.value) * DAILY_GEM_RATE) / 1 days;
        } else if (stake.value > lastClaimTimestamp) {
            owed = 0; // $GEM production stopped already
        } else {
            owed =
                ((lastClaimTimestamp - stake.value) * DAILY_GEM_RATE) /
                1 days; // stop earning additional $GEM if it's all been earned
        }
        if (unstake) {
            if (random(tokenId) & 1 == 1) {
                // 50% chance of all $GEM stolen
                _payHunterTax(owed);
                owed = 0;
            }
            hunter.safeTransferFrom(address(this), _msgSender(), tokenId, ""); // send back Adventurer
            delete barn[tokenId];
            totalAdventurerStaked -= 1;
        } else {
            _payHunterTax((owed * GEM_CLAIM_TAX_PERCENTAGE) / 100); // percentage tax to staked hunters
            owed = (owed * (100 - GEM_CLAIM_TAX_PERCENTAGE)) / 100; // remainder goes to Adventurer owner
            barn[tokenId] = Stake({
                owner: _msgSender(),
                tokenId: uint16(tokenId),
                value: uint80(block.timestamp)
            }); // reset stake
        }
        emit AdventurerClaimed(tokenId, owed, unstake);
    }

    /**
     * realize $GEM earnings for a single Hunter and optionally unstake it
     * Hunters earn $GEM proportional to their Alpha rank
     * @param tokenId the ID of the hunter to claim earnings from
     * @param unstake whether or not to unstake the Hunter
     * @return owed - the amount of $GEM earned
     */
    function _claimHunterFromPack(uint256 tokenId, bool unstake)
        internal
        returns (uint256 owed)
    {
        require(
            hunter.ownerOf(tokenId) == address(this),
            "AINT A PART OF THE PACK"
        );
        uint256 alpha = _alphaForHunter(tokenId);
        Stake memory stake = pack[alpha][packIndices[tokenId]];
        require(stake.owner == _msgSender(), "SWIPER, NO SWIPING");
        owed = (alpha) * (gemPerAlpha - stake.value); // Calculate portion of tokens based on Alpha
        if (unstake) {
            totalAlphaStaked -= alpha; // Remove Alpha from total staked
            hunter.safeTransferFrom(address(this), _msgSender(), tokenId, ""); // Send back Hunter
            Stake memory lastStake = pack[alpha][pack[alpha].length - 1];
            pack[alpha][packIndices[tokenId]] = lastStake; // Shuffle last Hunter to current position
            packIndices[lastStake.tokenId] = packIndices[tokenId];
            pack[alpha].pop(); // Remove duplicate
            delete packIndices[tokenId]; // Delete old mapping
        } else {
            pack[alpha][packIndices[tokenId]] = Stake({
                owner: _msgSender(),
                tokenId: uint16(tokenId),
                value: uint80(gemPerAlpha)
            }); // reset stake
        }
        emit HunterClaimed(tokenId, owed, unstake);
    }

    /**
     * emergency unstake tokens
     * @param tokenIds the IDs of the tokens to claim earnings from
     */
    function rescue(uint256[] calldata tokenIds) external {
        require(rescueEnabled, "RESCUE DISABLED");
        uint256 tokenId;
        Stake memory stake;
        Stake memory lastStake;
        uint256 alpha;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            tokenId = tokenIds[i];
            if (isAdventurer(tokenId)) {
                stake = barn[tokenId];
                require(stake.owner == _msgSender(), "SWIPER, NO SWIPING");
                hunter.safeTransferFrom(
                    address(this),
                    _msgSender(),
                    tokenId,
                    ""
                ); // send back Adventurer
                delete barn[tokenId];
                totalAdventurerStaked -= 1;
                emit AdventurerClaimed(tokenId, 0, true);
            } else {
                alpha = _alphaForHunter(tokenId);
                stake = pack[alpha][packIndices[tokenId]];
                require(stake.owner == _msgSender(), "SWIPER, NO SWIPING");
                totalAlphaStaked -= alpha; // Remove Alpha from total staked
                hunter.safeTransferFrom(
                    address(this),
                    _msgSender(),
                    tokenId,
                    ""
                ); // Send back Hunter
                lastStake = pack[alpha][pack[alpha].length - 1];
                pack[alpha][packIndices[tokenId]] = lastStake; // Shuffle last Hunter to current position
                packIndices[lastStake.tokenId] = packIndices[tokenId];
                pack[alpha].pop(); // Remove duplicate
                delete packIndices[tokenId]; // Delete old mapping
                emit HunterClaimed(tokenId, 0, true);
            }
        }
    }

    /** ACCOUNTING */

    /**
     * add $GEM to claimable pot for the Pack
     * @param amount $GEM to add to the pot
     */
    function _payHunterTax(uint256 amount) internal {
        if (totalAlphaStaked == 0) {
            // if there's no staked hunters
            unaccountedRewards += amount; // keep track of $GEM due to hunters
            return;
        }
        // makes sure to include any unaccounted $GEM
        gemPerAlpha += (amount + unaccountedRewards) / totalAlphaStaked;
        unaccountedRewards = 0;
    }

    /**
     * tracks $GEM earnings to ensure it stops once 2.4 billion is eclipsed
     */
    modifier _updateEarnings() {
        if (totalGemEarned < MAXIMUM_GLOBAL_GEM) {
            totalGemEarned +=
                ((block.timestamp - lastClaimTimestamp) *
                    totalAdventurerStaked *
                    DAILY_GEM_RATE) /
                1 days;
            lastClaimTimestamp = block.timestamp;
        }
        _;
    }

    /** ADMIN */

    /**
     * allows owner to enable "rescue mode"
     * simplifies accounting, prioritizes tokens out in emergency
     */
    function setRescueEnabled(bool _enabled) external onlyOwner {
        rescueEnabled = _enabled;
    }

    /**
     * enables owner to pause / unpause minting
     */
    function setPaused(bool _paused) external onlyOwner {
        if (_paused) _pause();
        else _unpause();
    }

    /** READ ONLY */

    /**
     * checks if a token is a Adventurer
     * @param tokenId the ID of the token to check
     * @return adventurer - whether or not a token is a Adventurer
     */
    function isAdventurer(uint256 tokenId)
        public
        view
        returns (bool adventurer)
    {
        (adventurer, , , , , , , , ) = hunter.tokenTraits(tokenId);
    }

    /**
     * gets the alpha score for a Hunter
     * @param tokenId the ID of the Hunter to get the alpha score for
     * @return the alpha score of the Hunter (5-8)
     */
    function _alphaForHunter(uint256 tokenId) internal view returns (uint8) {
        (, , , , , , , , uint8 alphaIndex) = hunter.tokenTraits(tokenId);
        return MAX_ALPHA - alphaIndex; // alpha index is 0-3
    }

    /*
     * chooses a random Hunter thief when a newly minted token is stolen
     * @param seed a random value to choose a Hunter from
     * @return the owner of the randomly selected Hunter thief
     */
    function randomHunterOwner(uint256 seed) external view returns (address) {
        if (totalAlphaStaked == 0) return address(0x0);
        uint256 bucket = (seed & 0xFFFFFFFF) % totalAlphaStaked; // choose a value from 0 to total alpha staked
        uint256 cumulative;
        seed >>= 32;
        // loop through each bucket of Hunters with the same alpha score
        for (uint256 i = MAX_ALPHA - 3; i <= MAX_ALPHA; i++) {
            cumulative += pack[i].length * i;
            // if the value is not inside of that bucket, keep going
            if (bucket >= cumulative) continue;
            // get the address of a random Hunter with that alpha score
            return pack[i][seed % pack[i].length].owner;
        }
        return address(0x0);
    }

    /**
     * generates a pseudorandom number
     * @param seed a value ensure different outcomes for different sources in the same block
     * @return a pseudorandom value
     */
    function random(uint256 seed) internal view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        msg.sender,
                        blockhash(block.number - 1),
                        block.timestamp,
                        seed
                    )
                )
            );
    }

    function onERC721Received(
        address,
        address from,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        require(from == address(0x0), "Cannot send tokens to Barn directly");
        return IERC721Receiver.onERC721Received.selector;
    }


    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
}