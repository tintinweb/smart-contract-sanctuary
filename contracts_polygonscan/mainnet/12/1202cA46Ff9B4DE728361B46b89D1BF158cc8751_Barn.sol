// SPDX-License-Identifier: MIT LICENSE
pragma solidity ^0.8.0;

import "./Pausable.sol";
import "./IERC721Receiver.sol";

import "./Woolf.sol";
import "./WOOL.sol";

contract Barn is Ownable, IERC721Receiver, Pausable {
    // maximum alpha score for a Wolf
    uint8 public constant MAX_ALPHA = 8;

    // struct to store a stake's token, owner, and earning values
    struct Stake {
        uint16 tokenId;
        uint80 value;
        address owner;
    }

    event TokenStaked(address owner, uint256 tokenId, uint256 value);
    event SheepClaimed(uint256 tokenId, uint256 earned, bool unstaked);
    event WolfClaimed(uint256 tokenId, uint256 earned, bool unstaked);

    // reference to the Woolf NFT contract
    Woolf woolf;
    // reference to the $FFWOOL contract for minting $FFWOOL earnings
    WOOL wool;
    // reference to Entropy
    IEntropy entropy;

    // maps tokenId to stake
    mapping(uint256 => Stake) public barn;
    // maps alpha to all Wolf stakes with that alpha
    mapping(uint256 => Stake[]) public pack;
    // tracks location of each Wolf in Pack
    mapping(uint256 => uint256) public packIndices;
    // total alpha scores staked
    uint256 public totalAlphaStaked = 0;
    // any rewards distributed when no wolves are staked
    uint256 public unaccountedRewards = 0;
    // amount of $FFWOOL due for each alpha point staked
    uint256 public woolPerAlpha = 0;

    // sheep earn 10000 $FFWOOL per day
    uint256 public constant DAILY_WOOL_RATE = 10000000000000;
    // sheep must have 2 days worth of $FFWOOL to unstake or else it's too cold
    uint256 public constant MINIMUM_TO_EXIT = 2 days;
    // wolves take a 20% tax on all $FFWOOL claimed
    uint256 public constant WOOL_CLAIM_TAX_PERCENTAGE = 20;
    // there will only ever be (roughly) 1.8 billion $FFWOOL earned through staking
    uint256 public constant MAXIMUM_GLOBAL_WOOL = 1800000000000000000;

    // amount of $FFWOOL earned so far
    uint256 public totalWoolEarned;
    // number of Sheep staked in the Barn
    uint256 public totalSheepStaked;
    // the last time $FFWOOL was claimed
    uint256 public lastClaimTimestamp;

    // emergency rescue to allow unstaking without any checks but without $FFWOOL
    bool public rescueEnabled = false;

    /**
     * @param _woolf reference to the Woolf NFT contract
     * @param _wool reference to the $FFWOOL token
     */
    constructor(address _woolf, address _wool) {
        woolf = Woolf(_woolf);
        wool = WOOL(_wool);
    }

    /** STAKING */

    /**
     * adds Sheep and Wolves to the Barn and Pack
     * @param account the address of the staker
     * @param tokenIds the IDs of the Sheep and Wolves to stake
     */
    function addManyToBarnAndPack(address account, uint16[] calldata tokenIds)
        external
    {
        require(
            account == _msgSender() || _msgSender() == address(woolf),
            "DO NOT GIVE YOUR TOKENS AWAY"
        );
        require(tx.origin == _msgSender());

        for (uint256 i = 0; i < tokenIds.length; i++) {
            // to ensure it's not in buffer
            require(woolf.totalSupply() >= tokenIds[i] + woolf.MAX_PER_MINT());

            if (_msgSender() != address(woolf)) {
                // dont do this step if its a mint + stake
                require(
                    woolf.ownerOf(tokenIds[i]) == _msgSender(),
                    "NOT YOUR TOKEN"
                );
                woolf.transferFrom(_msgSender(), address(this), tokenIds[i]);
            } else if (tokenIds[i] == 0) {
                continue; // there may be gaps in the array for stolen tokens
            }

            if (isSheep(tokenIds[i])) _addSheepToBarn(account, tokenIds[i]);
            else _addWolfToPack(account, tokenIds[i]);
        }
    }

    // ** INTERNAL * //

    /**
     * adds a single Sheep to the Barn
     * @param account the address of the staker
     * @param tokenId the ID of the Sheep to add to the Barn
     */
    function _addSheepToBarn(address account, uint256 tokenId)
        internal
        whenNotPaused
        _updateEarnings
    {
        barn[tokenId] = Stake({
            owner: account,
            tokenId: uint16(tokenId),
            value: uint80(block.timestamp)
        });
        totalSheepStaked += 1;

        emit TokenStaked(account, tokenId, block.timestamp);
    }

    /**
     * adds a single Wolf to the Pack
     * @param account the address of the staker
     * @param tokenId the ID of the Wolf to add to the Pack
     */
    function _addWolfToPack(address account, uint256 tokenId) internal {
        uint256 alpha = _alphaForWolf(tokenId);
        totalAlphaStaked += alpha; // Portion of earnings ranges from 8 to 5
        packIndices[tokenId] = pack[alpha].length; // Store the location of the wolf in the Pack
        pack[alpha].push(
            Stake({
                owner: account,
                tokenId: uint16(tokenId),
                value: uint80(woolPerAlpha)
            })
        ); // Add the wolf to the Pack

        emit TokenStaked(account, tokenId, woolPerAlpha);
    }

    // ** ----------- * //

    /** CLAIMING / UNSTAKING */

    /**
     * realize $FFWOOL earnings and optionally unstake tokens from the Barn / Pack
     * to unstake a Sheep it will require it has 2 days worth of $FFWOOL unclaimed
     * @param tokenIds the IDs of the tokens to claim earnings from
     * @param unstake whether or not to unstake ALL of the tokens listed in tokenIds
     */
    function claimManyFromBarnAndPack(uint16[] calldata tokenIds, bool unstake)
        external
        whenNotPaused
        _updateEarnings
    {
        require(tx.origin == _msgSender());

        uint256 owed = 0;

        for (uint256 i = 0; i < tokenIds.length; i++) {
            if (isSheep(tokenIds[i]))
                owed += _claimSheepFromBarn(tokenIds[i], unstake);
            else owed += _claimWolfFromPack(tokenIds[i], unstake);
        }

        if (owed == 0) return;

        wool.mint(_msgSender(), owed);
    }

    // ** INTERNAL * //

    /**
     * realize $FFWOOL earnings for a single Sheep and optionally unstake it
     * if not unstaking, pay a 20% tax to the staked Wolves
     * if unstaking, there is a 50% chance all $FFWOOL is stolen
     * @param tokenId the ID of the Sheep to claim earnings from
     * @param unstake whether or not to unstake the Sheep
     * @return owed - the amount of $FFWOOL earned
     */
    function _claimSheepFromBarn(uint256 tokenId, bool unstake)
        internal
        returns (uint256 owed)
    {
        Stake memory stake = barn[tokenId];

        require(stake.owner == _msgSender(), "SWIPER, NO SWIPING");
        require(
            !(unstake && block.timestamp - stake.value < MINIMUM_TO_EXIT),
            "IT WILL BE COLD WITHOUT TWO DAY'S FFWOOL"
        );

        if (totalWoolEarned < MAXIMUM_GLOBAL_WOOL) {
            owed = ((block.timestamp - stake.value) * DAILY_WOOL_RATE) / 1 days;
        } else if (stake.value > lastClaimTimestamp) {
            owed = 0; // $FFWOOL production stopped already
        } else {
            owed =
                ((lastClaimTimestamp - stake.value) * DAILY_WOOL_RATE) /
                1 days; // stop earning additional $FFWOOL if it's all been earned
        }

        if (unstake) {
            if (entropy.random(tokenId) & 1 == 1) {
                // 50% chance of all $FFWOOL stolen
                _payWolfTax(owed);
                owed = 0;
            }

            totalSheepStaked -= 1;
            woolf.safeTransferFrom(address(this), _msgSender(), tokenId, ""); // send back Sheep

            delete barn[tokenId];
        } else {
            _payWolfTax((owed * WOOL_CLAIM_TAX_PERCENTAGE) / 100); // percentage tax to staked wolves

            owed = (owed * (100 - WOOL_CLAIM_TAX_PERCENTAGE)) / 100; // remainder goes to Sheep owner
            // reset stake
            barn[tokenId] = Stake({
                owner: _msgSender(),
                tokenId: uint16(tokenId),
                value: uint80(block.timestamp)
            });
        }

        emit SheepClaimed(tokenId, owed, unstake);
    }

    /**
     * realize $FFWOOL earnings for a single Wolf and optionally unstake it
     * Wolves earn $FFWOOL proportional to their Alpha rank
     * @param tokenId the ID of the Wolf to claim earnings from
     * @param unstake whether or not to unstake the Wolf
     * @return owed - the amount of $FFWOOL earned
     */
    function _claimWolfFromPack(uint256 tokenId, bool unstake)
        internal
        returns (uint256 owed)
    {
        require(
            woolf.ownerOf(tokenId) == address(this),
            "NOT A PART OF THE PACK"
        );

        uint256 alpha = _alphaForWolf(tokenId);
        Stake memory stake = pack[alpha][packIndices[tokenId]];

        require(stake.owner == _msgSender(), "SWIPER, NO SWIPING");

        owed = (alpha) * (woolPerAlpha - stake.value); // Calculate portion of tokens based on Alpha

        if (unstake) {
            totalAlphaStaked -= alpha; // Remove Alpha from total staked

            Stake memory lastStake = pack[alpha][pack[alpha].length - 1];
            pack[alpha][packIndices[tokenId]] = lastStake; // Shuffle last Wolf to current position
            packIndices[lastStake.tokenId] = packIndices[tokenId];
            pack[alpha].pop(); // Remove duplicate

            delete packIndices[tokenId]; // Delete old mapping

            woolf.safeTransferFrom(address(this), _msgSender(), tokenId, ""); // Send back Wolf
        } else {
            pack[alpha][packIndices[tokenId]] = Stake({
                owner: _msgSender(),
                tokenId: uint16(tokenId),
                value: uint80(woolPerAlpha)
            }); // reset stake
        }

        emit WolfClaimed(tokenId, owed, unstake);
    }

    // ** ----------- * //

    /**
     * emergency unstake tokens
     * @param tokenIds the IDs of the tokens to claim earnings from
     */
    function rescue(uint256[] calldata tokenIds) external {
        require(rescueEnabled, "RESCUE DISABLED");
        require(tx.origin == _msgSender());

        uint256 tokenId;
        Stake memory stake;
        Stake memory lastStake;
        uint256 alpha;

        for (uint256 i = 0; i < tokenIds.length; i++) {
            tokenId = tokenIds[i];

            if (isSheep(tokenId)) {
                stake = barn[tokenId];
                require(stake.owner == _msgSender(), "SWIPER, NO SWIPING");

                delete barn[tokenId];
                totalSheepStaked -= 1;

                woolf.safeTransferFrom(
                    address(this),
                    _msgSender(),
                    tokenId,
                    ""
                ); // send back Sheep

                emit SheepClaimed(tokenId, 0, true);
            } else {
                alpha = _alphaForWolf(tokenId);
                stake = pack[alpha][packIndices[tokenId]];

                require(stake.owner == _msgSender(), "SWIPER, NO SWIPING");

                totalAlphaStaked -= alpha; // Remove Alpha from total staked
                lastStake = pack[alpha][pack[alpha].length - 1];
                pack[alpha][packIndices[tokenId]] = lastStake; // Shuffle last Wolf to current position
                packIndices[lastStake.tokenId] = packIndices[tokenId];
                pack[alpha].pop(); // Remove duplicate
                delete packIndices[tokenId]; // Delete old mapping

                woolf.safeTransferFrom(
                    address(this),
                    _msgSender(),
                    tokenId,
                    ""
                ); // Send back Wolf

                emit WolfClaimed(tokenId, 0, true);
            }
        }
    }

    /** ACCOUNTING */

    /**
     * add $FFWOOL to claimable pot for the Pack
     * @param amount $FFWOOL to add to the pot
     */
    function _payWolfTax(uint256 amount) internal {
        if (totalAlphaStaked == 0) {
            // if there's no staked wolves
            unaccountedRewards += amount; // keep track of $FFWOOL due to wolves
            return;
        }
        // makes sure to include any unaccounted $FFWOOL
        woolPerAlpha += (amount + unaccountedRewards) / totalAlphaStaked;
        unaccountedRewards = 0;
    }

    /**
     * tracks $FFWOOL earnings to ensure it stops once 1.8 billion is eclipsed
     */
    modifier _updateEarnings() {
        if (totalWoolEarned < MAXIMUM_GLOBAL_WOOL) {
            totalWoolEarned +=
                ((block.timestamp - lastClaimTimestamp) *
                    totalSheepStaked *
                    DAILY_WOOL_RATE) /
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

    function setEntropy(address _entropy) external onlyOwner {
        entropy = IEntropy(_entropy);
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
     * @return sheep - whether or not a token is a Sheep
     */
    function isSheep(uint256 tokenId) public view returns (bool sheep) {
        IWoolf.SheepWolf memory iSheepWolf = woolf.getTokenTraits(tokenId);
        return iSheepWolf.isSheep;
    }

    /**
     * gets the alpha score for a Wolf
     * @param tokenId the ID of the Wolf to get the alpha score for
     * @return the alpha score of the Wolf (5-8)
     */
    function _alphaForWolf(uint256 tokenId) internal view returns (uint8) {
        IWoolf.SheepWolf memory iSheepWolf = woolf.getTokenTraits(tokenId);
        // alpha index is 0-3
        return MAX_ALPHA - iSheepWolf.alphaIndex;
    }

    /**
     * chooses a random Wolf thief when a newly minted token is stolen
     * @param seed a random value to choose a Wolf from
     * @return the owner of the randomly selected Wolf thief
     */
    function randomWolfOwner(uint256 seed) external view returns (address) {
        require(address(msg.sender) == address(woolf));

        if (totalAlphaStaked == 0) return address(0x0);

        // choose a value from 0 to total alpha staked
        uint256 bucket = (seed & 0xFFFFFFFF) % totalAlphaStaked;
        uint256 cumulative;
        seed >>= 32;

        // loop through each bucket of Wolves with the same alpha score
        for (uint256 i = MAX_ALPHA - 3; i <= MAX_ALPHA; i++) {
            cumulative += pack[i].length * i;
            // if the value is not inside of that bucket, keep going
            if (bucket >= cumulative) continue;
            // get the address of a random Wolf with that alpha score
            return pack[i][seed % pack[i].length].owner;
        }

        return address(0x0);
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