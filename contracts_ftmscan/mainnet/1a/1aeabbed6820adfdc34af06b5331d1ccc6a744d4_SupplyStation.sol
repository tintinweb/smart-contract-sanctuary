/**
 *Submitted for verification at FtmScan.com on 2021-12-18
*/

/**
 *Submitted for verification at FtmScan.com on 2021-12-10
*/

// SPDX-License-Identifier: MIT LICENSE

// Interface
////////////

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

interface IMarsWasteland {

    // struct to store each token's traits
    struct RobotSlime {
        bool isRobot;
        uint8 head;
        uint8 eyes;
        uint8 mouth;
        uint8 body;
        uint8 equipment;
        uint8 alphaIndex;
    }

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
 
    function transferFrom( address from, address to, uint256 tokenId) external;

    function getTokenTraits(uint256 tokenId) external view returns (RobotSlime memory);

    function tokenURI(uint256 tokenId) external view returns (string memory);
}

interface ICore {

    function mint(address to, uint256 amount) external;

}

// Abstract contract
////////////////////
pragma solidity ^0.8.0;

/*
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

pragma solidity ^0.8.0;

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

pragma solidity ^0.8.0;

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}




pragma solidity ^0.8.0;

contract SupplyStation is Ownable, IERC721Receiver, Pausable {
    
    // maximum alpha score for a Slime
    uint8 public constant MAX_ALPHA = 8;

    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;
    
    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    mapping(address => uint256) private _balances;

    // struct to store a stake's token, owner, and earning values
    struct Stake {
        address owner;
        uint32 tokenId;
        uint256 value;
    }

    event TokenStaked(address owner, uint256 tokenId, uint256 value);
    event RobotClaimed(uint256 tokenId, uint256 earned, bool unstaked);
    event SlimeClaimed(uint256 tokenId, uint256 earned, bool unstaked);

    // reference to the MarsWasteland NFT contract
    IMarsWasteland public marsWasteland;

    // reference to CORE;
    ICore public core;


    // maps tokenId to stake
    mapping(uint256 => Stake) public supplyStation;
    // maps alpha to all Slimes stakes with that alpha
    mapping(uint256 => Stake[]) public pack;
    // tracks location of each Slime in Pack
    mapping(uint256 => uint256) public packIndices;
    // total alpha scores staked
    uint256 public totalAlphaStaked = 0;
    // any rewards distributed when no Slimes are staked
     uint256 public unaccountedRewards = 0;
    // amount of $CORE due for each alpha point staked
    uint256 public corePerAlpha = 0;

    // robot earn 10000 $CORE per day
    uint256 public constant DAILY_CORE_RATE = 4000 ether;
    // robot must have 2 days worth of $CORE to unstake
    uint256 public constant MINIMUM_TO_EXIT = 2 days;
    // slimes take a 20% tax on all $CORE claimed
    uint256 public constant CORE_CLAIM_TAX_PERCENTAGE = 20;
    // there will only ever be (roughly) 7.2 billion $CORE earned through staking
    uint256 public constant MAXIMUM_GLOBAL_CORE = 7200000000 ether;

    // amount of $CORE earned so far
    uint256 public totalCoreEarned;
    // number of Robots staked in the SupplyStation
    uint256 public totalRobotStaked;
    // number of Slimes staked in the pack
    uint256 public totalSlimeStaked;
    // the last time $CORE was claimed
    uint256 public lastClaimTimestamp;

    // emergency rescue to allow unstaking without any checks and without $CORE
    bool public rescueEnabled = false;

    /**
     * @param marsWasteland_ reference to the MarsWasteland NFT contract
     * @param core_ reference to the $CORE token
     */
    constructor(address marsWasteland_, address core_) {
        marsWasteland = IMarsWasteland(marsWasteland_);
        core = ICore(core_);
    }

    /** STAKING */

    /**
     * adds Robots and Slimes to the Barn and Pack
     * @param account the address of the staker
     * @param tokenIds the IDs of the Robots and Slimes to stake
     */
    function addManyToStationAndPack(address account, uint32[] calldata tokenIds) external {
        address msgSender = _msgSender();
        require(tx.origin == msgSender || msgSender == address(marsWasteland), "Only EOA");
        require(account == msgSender || msgSender == address(marsWasteland), "DONT GIVE YOUR TOKENS AWAY");
        for (uint i = 0; i < tokenIds.length; i++) {
            if (msgSender != address(marsWasteland)) { // dont do this step if its a mint + stake
                require(marsWasteland.ownerOf(tokenIds[i]) == msgSender, "AINT YO TOKEN");
                marsWasteland.transferFrom(msgSender, address(this), tokenIds[i]);
            } else if (tokenIds[i] == 0) {
                continue; // there may be gaps in the array for stolen tokens
            }

            if (isRobot(tokenIds[i]))
                _addRobotToStation(account, tokenIds[i]);
            else
                _addSlimeToPack(account, tokenIds[i]);
        }
    }

    /**
     * adds a single Robot to the Station
     * @param account the address of the staker
     * @param tokenId the ID of the Robot to add to the Station
     */
    function _addRobotToStation(address account, uint256 tokenId) internal whenNotPaused _updateEarnings {
        supplyStation[tokenId] = Stake({
            owner: account,
            tokenId: uint32(tokenId),
            value: uint256(block.timestamp)
        });
        totalRobotStaked += 1;
        _addTokenToOwnerEnumeration(account, tokenId);
        emit TokenStaked(account, tokenId, block.timestamp);
    }

    /**
     * adds a single Slime to the Pack
     * @param account the address of the staker
     * @param tokenId the ID of the Slime to add to the Pack
     */
    function _addSlimeToPack(address account, uint256 tokenId) internal {
        uint256 alpha = _alphaForSlime(tokenId);
        totalAlphaStaked += alpha; // Portion of earnings ranges from 8 to 5
        totalSlimeStaked += 1;
        _addTokenToOwnerEnumeration(account, tokenId);
        packIndices[tokenId] = pack[alpha].length; // Store the location of the slime in the Pack
        pack[alpha].push(
            Stake({
                owner: account,
                tokenId: uint32(tokenId),
                value: uint256(corePerAlpha)
            })
        ); // Add the Slime to the Pack
        emit TokenStaked(account, tokenId, corePerAlpha);
    }

    /** CLAIMING / UNSTAKING */

    /**
     * realize $CORE earnings and optionally unstake tokens from the Station / Pack
     * to unstake a Robot it will require it has 2 days worth of $CORE unclaimed
     * @param tokenIds the IDs of the tokens to claim earnings from
     * @param unstake whether or not to unstake ALL of the tokens listed in tokenIds
     */
    function claimManyFromStationAndPack(uint32[] calldata tokenIds, bool unstake) external whenNotPaused _updateEarnings {
        address msgSender = _msgSender();
        require(tx.origin == msgSender, "Only EOA");
        uint256 owed = 0;
        for (uint i = 0; i < tokenIds.length; i++) {
            if (isRobot(tokenIds[i]))
                owed += _claimRobotFromStation(tokenIds[i], unstake);
            else
                owed += _claimSlimeFromPack(tokenIds[i], unstake);
        }
        if (owed == 0) return;
        core.mint(_msgSender(), owed);
    }

    /**
     * realize $CORE earnings for a single Robot and optionally unstake it
     * if not unstaking, pay a 20% tax to the staked Slimes
     * if unstaking, there is a 50% chance all $CORE is stolen
     * @param tokenId the ID of the Sheep to claim earnings from
     * @param unstake whether or not to unstake the Sheep
     * @return owed - the amount of $CORE earned
     */
    function _claimRobotFromStation(uint256 tokenId, bool unstake) internal returns (uint256 owed) {
        require(marsWasteland.ownerOf(tokenId) == address(this), "AINT A PART OF THE STATION");
        Stake memory stake = supplyStation[tokenId];
        require(stake.owner == _msgSender(), "SWIPER, NO SWIPING");
        require(!(unstake && block.timestamp - stake.value < MINIMUM_TO_EXIT), "GONNA BE COLD WITHOUT TWO DAY'S CORE");
        if (totalCoreEarned < MAXIMUM_GLOBAL_CORE) {
            owed = (block.timestamp - stake.value) * DAILY_CORE_RATE / 1 days;
        } else if (stake.value > lastClaimTimestamp) {
            owed = 0; // $CORE production stopped already
        } else {
            owed = (lastClaimTimestamp - stake.value) * DAILY_CORE_RATE / 1 days; // stop earning additional $CORE if it's all been earned
        }
    
        if (unstake) {
            if (random(tokenId + block.timestamp) & 1 == 1) { // 50% chance of all $CORE stolen
                _paySlimeTax(owed);
                owed = 0;
            }
            delete supplyStation[tokenId];
            totalRobotStaked -= 1;
            _removeTokenFromOwnerEnumeration(_msgSender(), tokenId);
            marsWasteland.safeTransferFrom(address(this), _msgSender(), tokenId, ""); // send back Robot
        } else {
            _paySlimeTax(owed * CORE_CLAIM_TAX_PERCENTAGE / 100); // percentage tax to staked Slimes
            owed = owed * (100 - CORE_CLAIM_TAX_PERCENTAGE) / 100; // remainder goes to Robot owner
            supplyStation[tokenId] = Stake({
                owner: _msgSender(),
                tokenId: uint32(tokenId),
                value: uint256(block.timestamp)
            }); // reset stake
        }
        emit RobotClaimed(tokenId, owed, unstake);
    }

    /**
     * realize $CORE earnings for a single Slime and optionally unstake it
     * Slimes earn $CORE proportional to their Alpha rank
     * @param tokenId the ID of the Slime to claim earnings from
     * @param unstake whether or not to unstake the Slime
     * @return owed - the amount of $CORE earned
     */
    function _claimSlimeFromPack(uint256 tokenId, bool unstake) internal returns (uint256 owed) {
        require(marsWasteland.ownerOf(tokenId) == address(this), "AINT A PART OF THE PACK");
        uint256 alpha = _alphaForSlime(tokenId);
        Stake memory stake = pack[alpha][packIndices[tokenId]];
        require(stake.owner == _msgSender(), "SWIPER, NO SWIPING");
        owed = (alpha) * (corePerAlpha - stake.value); // Calculate portion of tokens based on Alpha
        if (unstake) {
            totalAlphaStaked -= alpha; // Remove Alpha from total staked
            totalSlimeStaked -= 1;
            _removeTokenFromOwnerEnumeration(_msgSender(), tokenId);
            Stake memory lastStake = pack[alpha][pack[alpha].length - 1];
            pack[alpha][packIndices[tokenId]] = lastStake; // Shuffle last Slime to current position
            packIndices[lastStake.tokenId] = packIndices[tokenId];
            pack[alpha].pop(); // Remove duplicate
            delete packIndices[tokenId]; // Delete old mapping
            marsWasteland.safeTransferFrom(address(this), _msgSender(), tokenId, ""); // Send back Slime
        } else {
            pack[alpha][packIndices[tokenId]] = Stake({
                owner: _msgSender(),
                tokenId: uint32(tokenId),
                value: uint256(corePerAlpha)
            }); // reset stake
        }
        emit SlimeClaimed(tokenId, owed, unstake);
    }

    /**
     * emergency unstake tokens
     * @param tokenIds the IDs of the tokens to claim earnings from
     */
    function rescue(uint256[] calldata tokenIds) external {
        require(rescueEnabled, "RESCUE DISABLED");
        require(tx.origin == _msgSender(), "Only EOA");
        uint256 tokenId;
        Stake memory stake;
        Stake memory lastStake;
        uint256 alpha;
        for (uint i = 0; i < tokenIds.length; i++) {
            tokenId = tokenIds[i];
            if (isRobot(tokenId)) {
                stake = supplyStation[tokenId];
                require(stake.owner == _msgSender(), "SWIPER, NO SWIPING");
                delete supplyStation[tokenId];
                totalRobotStaked -= 1;
                _removeTokenFromOwnerEnumeration(_msgSender(), tokenId);
                marsWasteland.safeTransferFrom(address(this), _msgSender(), tokenId, ""); // send back Robot
                emit RobotClaimed(tokenId, 0, true);
            } else {
                alpha = _alphaForSlime(tokenId);
                stake = pack[alpha][packIndices[tokenId]];
                require(stake.owner == _msgSender(), "SWIPER, NO SWIPING");
                totalAlphaStaked -= alpha; // Remove Alpha from total staked
                totalSlimeStaked -= 1;
                _removeTokenFromOwnerEnumeration(_msgSender(), tokenId);
                lastStake = pack[alpha][pack[alpha].length - 1];
                pack[alpha][packIndices[tokenId]] = lastStake; // Shuffle last Slime to current position
                packIndices[lastStake.tokenId] = packIndices[tokenId];
                pack[alpha].pop(); // Remove duplicate
                delete packIndices[tokenId]; // Delete old mapping
                marsWasteland.safeTransferFrom(address(this), _msgSender(), tokenId, ""); // Send back Slime
                emit SlimeClaimed(tokenId, 0, true);
            }
        }
    }

    /** ACCOUNTING */

    /** 
     * add $CORE to claimable pot for the Pack
     * @param amount $CORE to add to the pot
     */
    function _paySlimeTax(uint256 amount) internal {
        if (totalAlphaStaked == 0) { // if there's no staked Slimes
            unaccountedRewards += amount; // keep track of $CORE due to no Simes
            return;
        }
        // makes sure to include any unaccounted $CORE 
        corePerAlpha += (amount + unaccountedRewards) / totalAlphaStaked;
        unaccountedRewards = 0;
    }

    /**
     * tracks $CORE earnings to ensure it stops once 2.4 billion is eclipsed
     */
    modifier _updateEarnings() {
        if (totalCoreEarned < MAXIMUM_GLOBAL_CORE) {
            totalCoreEarned += (block.timestamp - lastClaimTimestamp) * totalRobotStaked * DAILY_CORE_RATE / 1 days; 
            lastClaimTimestamp = block.timestamp;
        }
        _;
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view returns (uint256) {
        require(index < balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    function tokenURIOfOwnerByIndex(address owner, uint256 index) public view returns (string memory) {
        require(index < balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        uint256 tokenId = _ownedTokens[owner][index];
        return marsWasteland.tokenURI(tokenId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view returns (uint256) {
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
        _balances[from] -= 1;
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

    function setMarsWasteland(address marsWasteland_) external onlyOwner {
        marsWasteland = IMarsWasteland(marsWasteland_);
    }

    function setCore(address core_) external onlyOwner {
        core = ICore(core_);
    }

    /** READ ONLY */

    /**
     * checks if a token is a Robot
     * @param tokenId the ID of the token to check
     * @return isRobot - whether or not a token is a Robot
     */
    function isRobot(uint256 tokenId) public view returns (bool) {
        return marsWasteland.getTokenTraits(tokenId).isRobot;
    }

    /**
     * gets the alpha score for a Slime
     * @param tokenId the ID of the Slime to get the alpha score for
     * @return the alpha score of the Slime (5-8)
     */
    function _alphaForSlime(uint256 tokenId) internal view returns (uint8) {
        uint8 alphaIndex = marsWasteland.getTokenTraits(tokenId).alphaIndex;
        return MAX_ALPHA - alphaIndex; // alpha index is 0-3
    }

    /**
     * chooses a random Slime thief when a newly minted token is stolen
     * @param seed a random value to choose a Slime from
     * @return the owner of the randomly selected Slime thief
     */
  function randomSlimeOwner(uint256 seed) external view returns (address) {
        require(address(_msgSender()) == address(marsWasteland));
        if (totalAlphaStaked == 0) return address(0x0);
        uint256 bucket = (seed & 0xFFFFFFFF) % totalAlphaStaked; // choose a value from 0 to total alpha staked
        uint256 cumulative;
        seed >>= 32;
        // loop through each bucket of Slimes with the same alpha score
        for (uint i = MAX_ALPHA - 3; i <= MAX_ALPHA; i++) {
            cumulative += pack[i].length * i;
             // if the value is not inside of that bucket, keep going
            if (bucket >= cumulative) continue;
            // get the address of a random Slime with that alpha score
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
        return uint256(keccak256(abi.encodePacked(
            tx.origin,
            blockhash(block.number - 1),
            block.timestamp,
            seed
        )));
    }


    function onERC721Received(
        address,
        address from,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        require(from == address(0x0), "Cannot send tokens to SupplyStation directly");
        return IERC721Receiver.onERC721Received.selector;
    }
}