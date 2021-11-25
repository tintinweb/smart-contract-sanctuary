// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

import "./IERC721Receiver.sol";
import "./Pausable.sol";
import "./Doge.sol";
import "./WOOL.sol";
import "./ReentrancyGuard.sol";
import "./IRandomGenerator.sol";

contract Barn is Ownable, IERC721Receiver, Pausable, ReentrancyGuard {

    // maximum alpha score for a Doge
    uint8 public constant MAX_ALPHA = 8;

    // struct to store a stake's token, owner, and earning values
    struct Stake {
        uint16 tokenId;
        uint80 value;
        address owner;
    }

    event TokenStaked(address owner, uint256 tokenId, uint256 value);
    event SheepClaimed(uint256 tokenId, uint256 earned, bool unstaked);
    event DogeClaimed(uint256 tokenId, uint256 earned, bool unstaked);
    event WoolStolen(uint256 tokenId, uint256 left, uint256 burned, uint256 stolen);

    // reference to the Doge NFT contract
    Doge doge;
    // reference to the $WOOL contract for minting $WOOL earnings
    WOOL wool;
    IRandomGenerator randomGen;
    // reference to $WOOL burn address
    address burnAddress;

    // maps tokenId to stake
    mapping(uint256 => Stake) public barn;
    // maps alpha to all Doge stakes with that alpha
    mapping(uint256 => Stake[]) public pack;
    // tracks location of each Doge in Pack
    mapping(uint256 => uint256) public packIndices;
    // Mapping from owner to list of owned token IDs, copy form ERC721Eunmerable
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;
    // Mapping from token ID to index of the owner tokens list, copy form ERC721Eunmerable
    mapping(uint256 => uint256) private _ownedTokensIndex;
    // Mapping from owner to total owned tokens, copy form ERC721Eunmerable
    mapping(address => uint256) private _balances;

    // total alpha scores staked
    uint256 public totalAlphaStaked = 0;
    // any rewards distributed when no doges are staked
    uint256 public unaccountedRewards = 0;
    // amount of $WOOL due for each alpha point staked
    uint256 public woolPerAlpha = 0;

    // sheep earn 10000 $WOOL per day
    uint256 public constant DAILY_WOOL_RATE = 10000 ether;
    // sheep must have 2 days worth of $WOOL to unstake or else it's too cold
    uint256 public constant MINIMUM_TO_EXIT = 2 days;
    // doges take a 20% tax on all $WOOL claimed
    uint256 public constant WOOL_CLAIM_TAX_PERCENTAGE = 20;
    // sheep burn a 8% tax on all $WOOL claimed
    uint256 public constant SHEEP_CLAIM_BURN_PERCENTAGE = 8;
    // doge 50% chance steal a 90% $WOOL when sheep unstake claimed 
    uint256 public constant DOGE_STOLEN_TAX_PERCENTAGE = 90;
    // there will only ever be (roughly) 2.4 billion $WOOL earned through staking
    uint256 public constant MAXIMUM_GLOBAL_WOOL = 2400000000 ether;

    // amount of $WOOL earned so far
    uint256 public totalWoolEarned;
    // number of Sheep staked in the Barn
    uint256 public totalSheepStaked;
    // the last time $WOOL was claimed
    uint256 public lastClaimTimestamp;

    // emergency rescue to allow unstaking without any checks but without $WOOL
    bool public rescueEnabled = false;

    /**
     * @param _doge reference to the Doge NFT contract
     * @param _wool reference to the $WOOL token
     */
    constructor(address _doge, address _wool, address _burn, address _random) {
        doge = Doge(_doge);
        wool = WOOL(_wool);
        randomGen = IRandomGenerator(_random);
        burnAddress = _burn;
    }

    /** STAKING */

    /**
     * adds Sheep and Doges to the Barn and Pack
     * @param account the address of the staker
     * @param tokenIds the IDs of the Sheep and Doges to stake
     */
    function addManyToBarnAndPack(address account, uint16[] calldata tokenIds) external {
        require(account == _msgSender() || _msgSender() == address(doge), "DONT GIVE YOUR TOKENS AWAY");
        for (uint i = 0; i < tokenIds.length; i++) {
            if (_msgSender() != address(doge)) { // dont do this step if its a mint + stake
                require(doge.ownerOf(tokenIds[i]) == _msgSender(), "AINT YO TOKEN");
                doge.transferFrom(_msgSender(), address(this), tokenIds[i]);
            } else if (tokenIds[i] == 0) {
                continue; // there may be gaps in the array for stolen tokens
            }

            if (isSheep(tokenIds[i]))
                _addSheepToBarn(account, tokenIds[i]);
            else
                _addDogeToPack(account, tokenIds[i]);
        }
    }

    /**
     * adds a single Sheep to the Barn
     * @param account the address of the staker
     * @param tokenId the ID of the Sheep to add to the Barn
     */
    function _addSheepToBarn(address account, uint256 tokenId) internal whenNotPaused _updateEarnings {
        barn[tokenId] = Stake({
        owner: account,
        tokenId: uint16(tokenId),
        value: uint80(block.timestamp)
        });
        totalSheepStaked += 1;
        _addTokenToOwnerEnumeration(account, tokenId);
        emit TokenStaked(account, tokenId, block.timestamp);
    }

    /**
     * adds a single Doge to the Pack
     * @param account the address of the staker
     * @param tokenId the ID of the Doge to add to the Pack
     */
    function _addDogeToPack(address account, uint256 tokenId) internal {
        uint256 alpha = _alphaForDoge(tokenId);
        totalAlphaStaked += alpha; // Portion of earnings ranges from 8 to 5
        packIndices[tokenId] = pack[alpha].length; // Store the location of the doge in the Pack
        pack[alpha].push(Stake({
        owner: account,
        tokenId: uint16(tokenId),
        value: uint80(woolPerAlpha)
        })); // Add the doge to the Pack
        _addTokenToOwnerEnumeration(account, tokenId);
        emit TokenStaked(account, tokenId, woolPerAlpha);
    }

    /** CLAIMING / UNSTAKING */

    /**
     * realize $WOOL earnings and optionally unstake tokens from the Barn / Pack
     * to unstake a Sheep it will require it has 2 days worth of $WOOL unclaimed
     * @param tokenIds the IDs of the tokens to claim earnings from
     * @param unstake whether or not to unstake ALL of the tokens listed in tokenIds
     */
    function claimManyFromBarnAndPack(uint16[] calldata tokenIds, bool unstake) external whenNotPaused _updateEarnings nonReentrant {
        uint256 owed = 0;
        uint256 burned = 0;
        for (uint i = 0; i < tokenIds.length; i++) {
            if (isSheep(tokenIds[i])) {
                 (uint256 _owed, uint256 _burned) = _claimSheepFromBarn(tokenIds[i], unstake);
                 owed += _owed;
                 burned += _burned;
            } else {
                 owed += _claimDogeFromPack(tokenIds[i], unstake);
            }
              
        }
        if (owed == 0) return;
        wool.mint(_msgSender(), owed);
        if (burned == 0) return;
        wool.mint(burnAddress, burned);
    }

    /**
     * realize $WOOL earnings for a single Sheep and optionally unstake it
     * if not unstaking, pay a 20% tax to the staked Doges
     * if unstaking, there is a 50% chance all $WOOL is stolen
     * @param tokenId the ID of the Sheep to claim earnings from
     * @param unstake whether or not to unstake the Sheep
     * @return owed - the amount of $WOOL earned
     */
    function _claimSheepFromBarn(uint256 tokenId, bool unstake) internal returns (uint256 owed, uint256 burned) {
        Stake memory stake = barn[tokenId];
        require(stake.owner == _msgSender(), "SWIPER, NO SWIPING");
        require(!(unstake && block.timestamp - stake.value < MINIMUM_TO_EXIT), "GONNA BE COLD WITHOUT TWO DAY'S WOOL");
        if (totalWoolEarned < MAXIMUM_GLOBAL_WOOL) {
            owed = (block.timestamp - stake.value) * DAILY_WOOL_RATE / 1 days;
        } else if (stake.value > lastClaimTimestamp) {
            owed = 0; // $WOOL production stopped already
        } else {
            owed = (lastClaimTimestamp - stake.value) * DAILY_WOOL_RATE / 1 days; // stop earning additional $WOOL if it's all been earned
        }
        if (unstake) {
            if (randomGen.random(tokenId) & 1 == 1) { // 50% chance of 90% $WOOL stolen, 8% burn, 2% mercy
                _payDogeTax(owed * DOGE_STOLEN_TAX_PERCENTAGE / 100);
                burned = owed * SHEEP_CLAIM_BURN_PERCENTAGE / 100;
                owed = owed * (100 - DOGE_STOLEN_TAX_PERCENTAGE - SHEEP_CLAIM_BURN_PERCENTAGE) / 100;
                emit WoolStolen(tokenId, owed, burned, (owed * DOGE_STOLEN_TAX_PERCENTAGE / 100));
            }
            delete barn[tokenId];
            totalSheepStaked -= 1;
            _removeTokenFromOwnerEnumeration(_msgSender(), tokenId);
            doge.safeTransferFrom(address(this), _msgSender(), tokenId, ""); // send back Sheep
        } else {
            _payDogeTax(owed * WOOL_CLAIM_TAX_PERCENTAGE / 100); // percentage tax to staked doges
            burned = owed * SHEEP_CLAIM_BURN_PERCENTAGE / 100;
            owed = owed * (100 - WOOL_CLAIM_TAX_PERCENTAGE - SHEEP_CLAIM_BURN_PERCENTAGE) / 100; // remainder goes to Sheep owner
            barn[tokenId] = Stake({
            owner: _msgSender(),
            tokenId: uint16(tokenId),
            value: uint80(block.timestamp)
            }); // reset stake
        }
        emit SheepClaimed(tokenId, owed, unstake);
    }

    /**
     * realize $WOOL earnings for a single Doge and optionally unstake it
     * Doges earn $WOOL proportional to their Alpha rank
     * @param tokenId the ID of the Doge to claim earnings from
     * @param unstake whether or not to unstake the Doge
     * @return owed - the amount of $WOOL earned
     */
    function _claimDogeFromPack(uint256 tokenId, bool unstake) internal returns (uint256 owed) {
        require(doge.ownerOf(tokenId) == address(this), "AINT A PART OF THE PACK");
        uint256 alpha = _alphaForDoge(tokenId);
        Stake memory stake = pack[alpha][packIndices[tokenId]];
        require(stake.owner == _msgSender(), "SWIPER, NO SWIPING");
        owed = (alpha) * (woolPerAlpha - stake.value); // Calculate portion of tokens based on Alpha
        if (unstake) {
            totalAlphaStaked -= alpha; // Remove Alpha from total staked
            Stake memory lastStake = pack[alpha][pack[alpha].length - 1];
            pack[alpha][packIndices[tokenId]] = lastStake; // Shuffle last Doge to current position
            packIndices[lastStake.tokenId] = packIndices[tokenId];
            pack[alpha].pop(); // Remove duplicate
            delete packIndices[tokenId]; // Delete old mapping
            _removeTokenFromOwnerEnumeration(_msgSender(), tokenId);
            doge.safeTransferFrom(address(this), _msgSender(), tokenId, ""); // Send back Doge
        } else {
            pack[alpha][packIndices[tokenId]] = Stake({
            owner: _msgSender(),
            tokenId: uint16(tokenId),
            value: uint80(woolPerAlpha)
            }); // reset stake
        }
        emit DogeClaimed(tokenId, owed, unstake);
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
        for (uint i = 0; i < tokenIds.length; i++) {
            tokenId = tokenIds[i];
            if (isSheep(tokenId)) {
                stake = barn[tokenId];
                require(stake.owner == _msgSender(), "SWIPER, NO SWIPING");
                delete barn[tokenId];
                totalSheepStaked -= 1;
                _removeTokenFromOwnerEnumeration(_msgSender(), tokenId);
                doge.safeTransferFrom(address(this), _msgSender(), tokenId, ""); // send back Sheep
                emit SheepClaimed(tokenId, 0, true);
            } else {
                alpha = _alphaForDoge(tokenId);
                stake = pack[alpha][packIndices[tokenId]];
                require(stake.owner == _msgSender(), "SWIPER, NO SWIPING");
                totalAlphaStaked -= alpha; // Remove Alpha from total staked
                lastStake = pack[alpha][pack[alpha].length - 1];
                pack[alpha][packIndices[tokenId]] = lastStake; // Shuffle last Doge to current position
                packIndices[lastStake.tokenId] = packIndices[tokenId];
                pack[alpha].pop(); // Remove duplicate
                delete packIndices[tokenId]; // Delete old mapping
                _removeTokenFromOwnerEnumeration(_msgSender(), tokenId);
                doge.safeTransferFrom(address(this), _msgSender(), tokenId, ""); // Send back Doge
                emit DogeClaimed(tokenId, 0, true);
            }
        }
    }

    /** ACCOUNTING */

    /**
     * add $WOOL to claimable pot for the Pack
     * @param amount $WOOL to add to the pot
     */
    function _payDogeTax(uint256 amount) internal {
        if (totalAlphaStaked == 0) { // if there's no staked doges
            unaccountedRewards += amount; // keep track of $WOOL due to doges
            return;
        }
        // makes sure to include any unaccounted $WOOL
        woolPerAlpha += (amount + unaccountedRewards) / totalAlphaStaked;
        unaccountedRewards = 0;
    }

    /**
      * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
      */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual returns (uint256) {
      return _ownedTokens[owner][index];
    }
    /**
    * @dev See {IERC721-balanceOf}.
    */
    function balanceOf(address owner) public view virtual returns (uint256) {
      require(owner != address(0), "ERC721: balance query for the zero address");
      return _balances[owner];
    }
    /**
      * @dev Private function to add a token to this extension's ownership-tracking data structures.
      * @param to address representing the new owner of the given token ID
      * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
      */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
      uint256 length = _balances[to];
      _ownedTokens[to][length] = tokenId;
      _ownedTokensIndex[tokenId] = length;
      _balances[to] = length + 1;
    }
    /**
      * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
      * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
      * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
      * This has O(1) time complexity, but alters the order of the _ownedTokens array.
      * @param from address representing the previous owner of the given token ID
      * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
      */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
      // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
      // then delete the last slot (swap and pop).
      uint256 lastTokenIndex = _balances[from] - 1;
      uint256 tokenIndex = _ownedTokensIndex[tokenId];
      // When the token to delete is the last token, the swap operation is unnecessary
      if (tokenIndex != lastTokenIndex) {
          uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

          _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
          _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
      }

      // This also deletes the contents at the last position of the array
      delete _ownedTokensIndex[tokenId];
      delete _ownedTokens[from][lastTokenIndex];
      _balances[from] = _balances[from] - 1;
    }

    /**
     * tracks $WOOL earnings to ensure it stops once 2.4 billion is eclipsed
     */
    modifier _updateEarnings() {
        if (totalWoolEarned < MAXIMUM_GLOBAL_WOOL) {
            totalWoolEarned +=
            (block.timestamp - lastClaimTimestamp)
            * totalSheepStaked
            * DAILY_WOOL_RATE / 1 days;
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

    /**
     * enables owner to change burn contract
     */
    function setBurnAddress(address _burnAddr) external onlyOwner {
      burnAddress = _burnAddr;
    }

    /**
     * enables owner to change random generate contract
     */
    function setRandomGen(address _randomAddr) external onlyOwner {
      randomGen = IRandomGenerator(_randomAddr);
    }

    /** READ ONLY */

    /**
     * checks if a token is a Sheep
     * @param tokenId the ID of the token to check
   * @return sheep - whether or not a token is a Sheep
   */
    function isSheep(uint256 tokenId) public view returns (bool sheep) {
        (sheep, , , , , , , , , ) = doge.tokenTraits(tokenId);
    }

    /**
     * gets the alpha score for a Doge
     * @param tokenId the ID of the Doge to get the alpha score for
   * @return the alpha score of the Doge (5-8)
   */
    function _alphaForDoge(uint256 tokenId) internal view returns (uint8) {
        ( , , , , , , , , , uint8 alphaIndex) = doge.tokenTraits(tokenId);
        return MAX_ALPHA - alphaIndex; // alpha index is 0-3
    }

    /**
     * chooses a random Doge thief when a newly minted token is stolen
     * @param seed a random value to choose a Doge from
   * @return the owner of the randomly selected Doge thief
   */
    function randomDogeOwner(uint256 seed) external view returns (address) {
        if (totalAlphaStaked == 0) return address(0x0);
        uint256 bucket = (seed & 0xFFFFFFFF) % totalAlphaStaked; // choose a value from 0 to total alpha staked
        uint256 cumulative;
        seed >>= 32;
        // loop through each bucket of Doges with the same alpha score
        for (uint i = MAX_ALPHA - 3; i <= MAX_ALPHA; i++) {
            cumulative += pack[i].length * i;
            // if the value is not inside of that bucket, keep going
            if (bucket >= cumulative) continue;
            // get the address of a random Doge with that alpha score
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