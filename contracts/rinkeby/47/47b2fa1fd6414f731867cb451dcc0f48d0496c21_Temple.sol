// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

import "./IERC721Receiver.sol";
import "./Pausable.sol";
import "./God.sol";
import "./FAITH.sol";

contract Temple is Ownable, IERC721Receiver, Pausable {
    // maximum divinity score for a God
    uint8 public constant MAX_DIVINITY = 8;

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
    // maps divinity to all God stakes with that divinity
    mapping(uint256 => Stake[]) public pantheon;
    // tracks location of each Gods in Pantheon
    mapping(uint256 => uint256) public pantheonIndices;
    // total divinity scores staked
    uint256 public totalDivinityStaked = 0;
    // any rewards distributed when no gods are staked
    uint256 public unaccountedRewards = 0;
    // amount of $FAITH due for each divinity point staked
    uint256 public faithPerDivinity = 0;

    // worshipper earn 10000 $FAITH per day
    uint256 public constant DAILY_FAITH_RATE = 10000 ether;
    // worshipper must have 2 days worth of $FAITH to unstake or else it's too cold
    uint256 public constant MINIMUM_TO_EXIT = 2 days;
    // Gods take a 20% tax on all $FAITH claimed
    uint256 public constant FAITH_CLAIM_TAX_PERCENTAGE = 20;
    // there will only ever be (roughly) 2.4 billion $FAITH earned through staking
    uint256 public constant MAXIMUM_GLOBAL_FAITH = 2400000000 ether;

    // amount of $FAITH earned so far
    uint256 public totalFaithEarned;
    // number of Worshipper staked in the Temple
    uint256 public totalWorshipperStaked;
    // the last time $FAITH was claimed
    uint256 public lastClaimTimestamp;

    // emergency rescue to allow unstaking without any checks but without $FAITH
    bool public rescueEnabled = false;

    /**
     * @param _god reference to the god NFT contract
     * @param _faith reference to the $FAITH token
     */
    constructor(address _god, address _faith) {
        god = God(_god);
        faith = FAITH(_faith);
    }

    /** STAKING */

    /**
     * adds Worshipper and Gods to the Temple and Pantheon
     * @param account the address of the staker
     * @param tokenIds the IDs of the Worshipper and Gods to stake
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
     * adds a single Worshipper to the Temple
     * @param account the address of the staker
     * @param tokenId the ID of the Worshipper to add to the Temple
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
     * adds a single God to the Pantheon
     * @param account the address of the staker
     * @param tokenId the ID of the God to add to the Pantheon
     */
    function _addGodToPantheon(address account, uint256 tokenId) internal {
        uint256 divinity = _divinityForGod(tokenId);
        totalDivinityStaked += divinity; // Portion of earnings ranges from 8 to 5
        pantheonIndices[tokenId] = pantheon[divinity].length; // Store the location of the God in the Pantheon
        pantheon[divinity].push(
            Stake({
                owner: account,
                tokenId: uint16(tokenId),
                value: uint80(faithPerDivinity)
            })
        ); // Add the god to the Pantheon
        emit TokenStaked(account, tokenId, faithPerDivinity);
    }

    /** CLAIMING / UNSTAKING */

    /**
     * realize $FAITH earnings and optionally unstake tokens from the Temple / Pantheon
     * to unstake a Worshipper it will require it has 2 days worth of $FAITH unclaimed
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
     * realize $FAITH earnings for a single Worshipper and optionally unstake it
     * if not unstaking, pay a 20% tax to the staked Gods
     * if unstaking, there is a 50% chance all $FAITH is stolen
     * @param tokenId the ID of the Worshipper to claim earnings from
     * @param unstake whether or not to unstake the Worshipper
     * @return owed - the amount of $FAITH earned
     */
    function _claimWorshipperFromTemple(uint256 tokenId, bool unstake)
        internal
        returns (uint256 owed)
    {
        Stake memory stake = temple[tokenId];
        require(stake.owner == _msgSender(), "GODS NEVER DIE");
        require(
            !(unstake && block.timestamp - stake.value < MINIMUM_TO_EXIT),
            "NO MIRACLES WITHOUT TWO DAY'S OF FAITH"
        );
        if (totalFaithEarned < MAXIMUM_GLOBAL_FAITH) {
            owed = ((block.timestamp - stake.value) * DAILY_FAITH_RATE) / 1 days;
        } else if (stake.value > lastClaimTimestamp) {
            owed = 0; // $FAITH production stopped already
        } else {
            owed =
                ((lastClaimTimestamp - stake.value) * DAILY_FAITH_RATE) /
                1 days; // stop earning additional $FAITH if it's all been earned
        }
        if (unstake) {
            if (random(tokenId) & 1 == 1) {
                // 50% chance of all $FAITh stolen
                _payGodTax(owed);
                owed = 0;
            }
            god.safeTransferFrom(address(this), _msgSender(), tokenId, ""); // send back Worshipper
            delete temple[tokenId];
            totalWorshipperStaked -= 1;
        } else {
            _payGodTax((owed * FAITH_CLAIM_TAX_PERCENTAGE) / 100); // percentage tax to staked gods
            owed = (owed * (100 - FAITH_CLAIM_TAX_PERCENTAGE)) / 100; // remainder goes to worshipper owner
            temple[tokenId] = Stake({
                owner: _msgSender(),
                tokenId: uint16(tokenId),
                value: uint80(block.timestamp)
            }); // reset stake
        }
        emit WorshipperClaimed(tokenId, owed, unstake);
    }

    /**
     * realize $FAITH earnings for a single God and optionally unstake it
     * Gods earn $FAITH proportional to their divinity rank
     * @param tokenId the ID of the God to claim earnings from
     * @param unstake whether or not to unstake the God
     * @return owed - the amount of $FAITH earned
     */
    function _claimGodFromPantheon(uint256 tokenId, bool unstake)
        internal
        returns (uint256 owed)
    {
        require(
            god.ownerOf(tokenId) == address(this),
            "AINT A PART OF THE PANTHEON"
        );
        uint256 divinity = _divinityForGod(tokenId);
        Stake memory stake = pantheon[divinity][pantheonIndices[tokenId]];
        require(stake.owner == _msgSender(), "GODS ALMIGHTY");
        owed = (divinity) * (faithPerDivinity - stake.value); // Calculate portion of tokens based on Divinity
        if (unstake) {
            totalDivinityStaked -= divinity; // Remove Divinity from total staked
            god.safeTransferFrom(address(this), _msgSender(), tokenId, ""); // Send back God
            Stake memory lastStake = pantheon[divinity][pantheon[divinity].length - 1];
            pantheon[divinity][pantheonIndices[tokenId]] = lastStake; // Shuffle last God to current position
            pantheonIndices[lastStake.tokenId] = pantheonIndices[tokenId];
            pantheon[divinity].pop(); // Remove duplicate
            delete pantheonIndices[tokenId]; // Delete old mapping
        } else {
            pantheon[divinity][pantheonIndices[tokenId]] = Stake({
                owner: _msgSender(),
                tokenId: uint16(tokenId),
                value: uint80(faithPerDivinity)
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
        uint256 divinity;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            tokenId = tokenIds[i];
            if (isWorshipper(tokenId)) {
                stake = temple[tokenId];
                require(stake.owner == _msgSender(), "GREEK GOD SUPREMACY");
                god.safeTransferFrom(
                    address(this),
                    _msgSender(),
                    tokenId,
                    ""
                ); // send back Woshipper
                delete temple[tokenId];
                totalWorshipperStaked -= 1;
                emit WorshipperClaimed(tokenId, 0, true);
            } else {
                divinity = _divinityForGod(tokenId);
                stake = pantheon[divinity][pantheonIndices[tokenId]];
                require(stake.owner == _msgSender(), "DONT ANGER THE GODS");
                totalDivinityStaked -= divinity; // Remove divinity from total staked
                god.safeTransferFrom(
                    address(this),
                    _msgSender(),
                    tokenId,
                    ""
                ); // Send back God
                lastStake = pantheon[divinity][pantheon[divinity].length - 1];
                pantheon[divinity][pantheonIndices[tokenId]] = lastStake; // Shuffle last God to current position
                pantheonIndices[lastStake.tokenId] = pantheonIndices[tokenId];
                pantheon[divinity].pop(); // Remove duplicate
                delete pantheonIndices[tokenId]; // Delete old mapping
                emit GodClaimed(tokenId, 0, true);
            }
        }
    }

    /** ACCOUNTING */

    /**
     * add $FAITH to claimable pot for the Pantheon
     * @param amount $FAITH to add to the pot
     */
    function _payGodTax(uint256 amount) internal {
        if (totalDivinityStaked == 0) {
            // if there's no staked gods
            unaccountedRewards += amount; // keep track of $FAITH due to gods
            return;
        }
        // makes sure to include any unaccounted $FAITH
        faithPerDivinity += (amount + unaccountedRewards) / totalDivinityStaked;
        unaccountedRewards = 0;
    }

    /**
     * tracks $FAITH earnings to ensure it stops once 2.4 billion is eclipsed
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
     * checks if a token is a worshipper
     * @param tokenId the ID of the token to check
     * @return worshipper - whether or not a token is a worshipper
     */
    function isWorshipper(uint256 tokenId) public view returns (bool worshipper) {
        (worshipper, , , , , , , , , ) = god.tokenTraits(tokenId);
    }

    /**
     * gets the divinity score for a God
     * @param tokenId the ID of the God to get the divinity score for
     * @return the divinity score of the God (5-8)
     */
    function _divinityForGod(uint256 tokenId) internal view returns (uint8) {
        (, , , , , , , , , uint8 divinityIndex) = god.tokenTraits(tokenId);
        return MAX_DIVINITY - divinityIndex; // divinity index is 0-3
    }

    /**
     * chooses a random God thief when a newly minted token is stolen
     * @param seed a random value to choose a God from
     * @return the owner of the randomly selected God thief
     */
    function randomGodOwner(uint256 seed) external view returns (address) {
        if (totalDivinityStaked == 0) return address(0x0);
        uint256 bucket = (seed & 0xFFFFFFFF) % totalDivinityStaked; // choose a value from 0 to total divinity staked
        uint256 cumulative;
        seed >>= 32;
        // loop through each bucket of Gods with the same divinity score
        for (uint256 i = MAX_DIVINITY - 3; i <= MAX_DIVINITY; i++) {
            cumulative += pantheon[i].length * i;
            // if the value is not inside of that bucket, keep going
            if (bucket >= cumulative) continue;
            // get the address of a random God with that divinity score
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
        require(from == address(0x0), "Cannot send tokens to Temple directly");
        return IERC721Receiver.onERC721Received.selector;
    }
}