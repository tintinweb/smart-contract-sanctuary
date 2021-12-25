// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

import "./IERC721Receiver.sol";
import "./Pausable.sol";
import "./God.sol";
import "./FAITH.sol";

contract Temple is Ownable, IERC721Receiver, Pausable {
    // maximum alpha score for a Wolf
    uint8 public constant MAX_ALPHA = 8;

    // struct to store a stake's token, owner, and earning values
    struct Stake {
        uint16 tokenId;
        uint80 value;
        address owner;
    }

    event TokenStaked(address owner, uint256 tokenId, uint256 value);
    event WorshipperClaimed(uint256 tokenId, uint256 earned, bool unstaked);
    event GodClaimed(uint256 tokenId, uint256 earned, bool unstaked);

    // reference to the God NFT contract
    God god;
    // reference to the $FAITH contract for minting $FAITH earnings
    FAITH faith;

    // maps tokenId to stake
    mapping(uint256 => Stake) public temple;
    // maps alpha to all Wolf stakes with that alpha
    mapping(uint256 => Stake[]) public pantheon;
    // tracks location of each Wolf in Pack
    mapping(uint256 => uint256) public pantheonIndices;
    // total alpha scores staked
    uint256 public totalAlphaStaked = 0;
    // any rewards distributed when no wolves are staked
    uint256 public unaccountedRewards = 0;
    // amount of $WOOL due for each alpha point staked
    uint256 public faithPerAlpha = 0;

    // sheep earn 10000 $WOOL per day
    uint256 public constant DAILY_FAITH_RATE = 10000 ether;
    // sheep must have 2 days worth of $WOOL to unstake or else it's too cold
    uint256 public constant MINIMUM_TO_EXIT = 2 days;
    // wolves take a 20% tax on all $WOOL claimed
    uint256 public constant FAITH_CLAIM_TAX_PERCENTAGE = 20;
    // there will only ever be (roughly) 2.4 billion $WOOL earned through staking
    uint256 public constant MAXIMUM_GLOBAL_FAITH = 2400000000 ether;

    // amount of $WOOL earned so far
    uint256 public totalFaithEarned;
    // number of Sheep staked in the Barn
    uint256 public totalWorshipperStaked;
    // the last time $WOOL was claimed
    uint256 public lastClaimTimestamp;

    // emergency rescue to allow unstaking without any checks but without $WOOL
    bool public rescueEnabled = false;

    /**
     * @param _god reference to the Woolf NFT contract
     * @param _faith reference to the $WOOL token
     */
    constructor(address _god, address _faith) {
        god = God(_god);
        faith = FAITH(_faith);
    }

    /** STAKING */

    /**
     * adds Sheep and Wolves to the Barn and Pack
     * @param account the address of the staker
     * @param tokenIds the IDs of the Sheep and Wolves to stake
     */
    function addManyToTempleAndPantheon(address account, uint16[] calldata tokenIds)
        external
    {
        require(
            account == _msgSender() || _msgSender() == address(god),
            "DONT GIVE YOUR TOKENS AWAY"
        );
        for (uint256 i = 0; i < tokenIds.length; i++) {
            if (_msgSender() != address(god)) {
                // dont do this step if its a mint + stake
                require(
                    god.ownerOf(tokenIds[i]) == _msgSender(),
                    "AINT YO TOKEN"
                );
                god.transferFrom(_msgSender(), address(this), tokenIds[i]);
            } else if (tokenIds[i] == 0) {
                continue; // there may be gaps in the array for stolen tokens
            }

            if (isWorshipper(tokenIds[i])) _addWorshipperToTemple(account, tokenIds[i]);
            else _addGodToPantheon(account, tokenIds[i]);
        }
    }

    /**
     * adds a single Sheep to the Barn
     * @param account the address of the staker
     * @param tokenId the ID of the Sheep to add to the Barn
     */
    function _addWorshipperToTemple(address account, uint256 tokenId)
        internal
        whenNotPaused
        _updateEarnings
    {
        temple[tokenId] = Stake({
            owner: account,
            tokenId: uint16(tokenId),
            value: uint80(block.timestamp)
        });
        totalWorshipperStaked += 1;
        emit TokenStaked(account, tokenId, block.timestamp);
    }

    /**
     * adds a single Wolf to the Pack
     * @param account the address of the staker
     * @param tokenId the ID of the Wolf to add to the Pack
     */
    function _addGodToPantheon(address account, uint256 tokenId) internal {
        uint256 alpha = _alphaForGod(tokenId);
        totalAlphaStaked += alpha; // Portion of earnings ranges from 8 to 5
        pantheonIndices[tokenId] = pantheon[alpha].length; // Store the location of the wolf in the Pack
        pantheon[alpha].push(
            Stake({
                owner: account,
                tokenId: uint16(tokenId),
                value: uint80(faithPerAlpha)
            })
        ); // Add the wolf to the Pack
        emit TokenStaked(account, tokenId, faithPerAlpha);
    }

    /** CLAIMING / UNSTAKING */

    /**
     * realize $WOOL earnings and optionally unstake tokens from the Barn / Pack
     * to unstake a Sheep it will require it has 2 days worth of $WOOL unclaimed
     * @param tokenIds the IDs of the tokens to claim earnings from
     * @param unstake whether or not to unstake ALL of the tokens listed in tokenIds
     */
    function claimManyFromTempleAndPantheon(uint16[] calldata tokenIds, bool unstake)
        external
        whenNotPaused
        _updateEarnings
    {
        uint256 owed = 0;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            if (isWorshipper(tokenIds[i]))
                owed += _claimWorshipperFromTemple(tokenIds[i], unstake);
            else owed += _claimGodFromPantheon(tokenIds[i], unstake);
        }
        if (owed == 0) return;
        faith.mint(_msgSender(), owed);
    }

    /**
     * realize $WOOL earnings for a single Sheep and optionally unstake it
     * if not unstaking, pay a 20% tax to the staked Wolves
     * if unstaking, there is a 50% chance all $WOOL is stolen
     * @param tokenId the ID of the Sheep to claim earnings from
     * @param unstake whether or not to unstake the Sheep
     * @return owed - the amount of $WOOL earned
     */
    function _claimWorshipperFromTemple(uint256 tokenId, bool unstake)
        internal
        returns (uint256 owed)
    {
        Stake memory stake = temple[tokenId];
        require(stake.owner == _msgSender(), "GODS NEVER DIE");
        require(
            !(unstake && block.timestamp - stake.value < MINIMUM_TO_EXIT),
            "GONNA BE COLD WITHOUT TWO DAY'S WOOL"
        );
        if (totalFaithEarned < MAXIMUM_GLOBAL_FAITH) {
            owed = ((block.timestamp - stake.value) * DAILY_FAITH_RATE) / 1 days;
        } else if (stake.value > lastClaimTimestamp) {
            owed = 0; // $WOOL production stopped already
        } else {
            owed =
                ((lastClaimTimestamp - stake.value) * DAILY_FAITH_RATE) /
                1 days; // stop earning additional $WOOL if it's all been earned
        }
        if (unstake) {
            if (random(tokenId) & 1 == 1) {
                // 50% chance of all $WOOL stolen
                _payGodTax(owed);
                owed = 0;
            }
            god.safeTransferFrom(address(this), _msgSender(), tokenId, ""); // send back Sheep
            delete temple[tokenId];
            totalWorshipperStaked -= 1;
        } else {
            _payGodTax((owed * FAITH_CLAIM_TAX_PERCENTAGE) / 100); // percentage tax to staked wolves
            owed = (owed * (100 - FAITH_CLAIM_TAX_PERCENTAGE)) / 100; // remainder goes to Sheep owner
            temple[tokenId] = Stake({
                owner: _msgSender(),
                tokenId: uint16(tokenId),
                value: uint80(block.timestamp)
            }); // reset stake
        }
        emit WorshipperClaimed(tokenId, owed, unstake);
    }

    /**
     * realize $WOOL earnings for a single Wolf and optionally unstake it
     * Wolves earn $WOOL proportional to their Alpha rank
     * @param tokenId the ID of the Wolf to claim earnings from
     * @param unstake whether or not to unstake the Wolf
     * @return owed - the amount of $WOOL earned
     */
    function _claimGodFromPantheon(uint256 tokenId, bool unstake)
        internal
        returns (uint256 owed)
    {
        require(
            god.ownerOf(tokenId) == address(this),
            "AINT A PART OF THE PANTHEON"
        );
        uint256 alpha = _alphaForGod(tokenId);
        Stake memory stake = pantheon[alpha][pantheonIndices[tokenId]];
        require(stake.owner == _msgSender(), "GODS ARE ALMIGHTY");
        owed = (alpha) * (faithPerAlpha - stake.value); // Calculate portion of tokens based on Alpha
        if (unstake) {
            totalAlphaStaked -= alpha; // Remove Alpha from total staked
            god.safeTransferFrom(address(this), _msgSender(), tokenId, ""); // Send back Wolf
            Stake memory lastStake = pantheon[alpha][pantheon[alpha].length - 1];
            pantheon[alpha][pantheonIndices[tokenId]] = lastStake; // Shuffle last Wolf to current position
            pantheonIndices[lastStake.tokenId] = pantheonIndices[tokenId];
            pantheon[alpha].pop(); // Remove duplicate
            delete pantheonIndices[tokenId]; // Delete old mapping
        } else {
            pantheon[alpha][pantheonIndices[tokenId]] = Stake({
                owner: _msgSender(),
                tokenId: uint16(tokenId),
                value: uint80(faithPerAlpha)
            }); // reset stake
        }
        emit GodClaimed(tokenId, owed, unstake);
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
            if (isWorshipper(tokenId)) {
                stake = temple[tokenId];
                require(stake.owner == _msgSender(), "SWIPER, NO SWIPING");
                god.safeTransferFrom(
                    address(this),
                    _msgSender(),
                    tokenId,
                    ""
                ); // send back Sheep
                delete temple[tokenId];
                totalWorshipperStaked -= 1;
                emit WorshipperClaimed(tokenId, 0, true);
            } else {
                alpha = _alphaForGod(tokenId);
                stake = pantheon[alpha][pantheonIndices[tokenId]];
                require(stake.owner == _msgSender(), "SWIPER, NO SWIPING");
                totalAlphaStaked -= alpha; // Remove Alpha from total staked
                god.safeTransferFrom(
                    address(this),
                    _msgSender(),
                    tokenId,
                    ""
                ); // Send back Wolf
                lastStake = pantheon[alpha][pantheon[alpha].length - 1];
                pantheon[alpha][pantheonIndices[tokenId]] = lastStake; // Shuffle last Wolf to current position
                pantheonIndices[lastStake.tokenId] = pantheonIndices[tokenId];
                pantheon[alpha].pop(); // Remove duplicate
                delete pantheonIndices[tokenId]; // Delete old mapping
                emit GodClaimed(tokenId, 0, true);
            }
        }
    }

    /** ACCOUNTING */

    /**
     * add $WOOL to claimable pot for the Pack
     * @param amount $WOOL to add to the pot
     */
    function _payGodTax(uint256 amount) internal {
        if (totalAlphaStaked == 0) {
            // if there's no staked wolves
            unaccountedRewards += amount; // keep track of $WOOL due to wolves
            return;
        }
        // makes sure to include any unaccounted $WOOL
        faithPerAlpha += (amount + unaccountedRewards) / totalAlphaStaked;
        unaccountedRewards = 0;
    }

    /**
     * tracks $WOOL earnings to ensure it stops once 2.4 billion is eclipsed
     */
    modifier _updateEarnings() {
        if (totalFaithEarned < MAXIMUM_GLOBAL_FAITH) {
            totalFaithEarned +=
                ((block.timestamp - lastClaimTimestamp) *
                    totalWorshipperStaked *
                    DAILY_FAITH_RATE) /
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
     * checks if a token is a Sheep
     * @param tokenId the ID of the token to check
     * @return worshipper - whether or not a token is a Sheep
     */
    function isWorshipper(uint256 tokenId) public view returns (bool worshipper) {
        (worshipper, , , , , , , , , ) = god.tokenTraits(tokenId);
    }

    /**
     * gets the alpha score for a Wolf
     * @param tokenId the ID of the Wolf to get the alpha score for
     * @return the alpha score of the Wolf (5-8)
     */
    function _alphaForGod(uint256 tokenId) internal view returns (uint8) {
        (, , , , , , , , , uint8 alphaIndex) = god.tokenTraits(tokenId);
        return MAX_ALPHA - alphaIndex; // alpha index is 0-3
    }

    /**
     * chooses a random Wolf thief when a newly minted token is stolen
     * @param seed a random value to choose a Wolf from
     * @return the owner of the randomly selected Wolf thief
     */
    function randomGodOwner(uint256 seed) external view returns (address) {
        if (totalAlphaStaked == 0) return address(0x0);
        uint256 bucket = (seed & 0xFFFFFFFF) % totalAlphaStaked; // choose a value from 0 to total alpha staked
        uint256 cumulative;
        seed >>= 32;
        // loop through each bucket of Wolves with the same alpha score
        for (uint256 i = MAX_ALPHA - 3; i <= MAX_ALPHA; i++) {
            cumulative += pantheon[i].length * i;
            // if the value is not inside of that bucket, keep going
            if (bucket >= cumulative) continue;
            // get the address of a random Wolf with that alpha score
            return pantheon[i][seed % pantheon[i].length].owner;
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
                        tx.origin,
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
}