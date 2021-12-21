// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

import "IERC721Receiver.sol";
import "IERC721.sol";
import "Ownable.sol";
import "HONOR.sol";

contract War is Ownable, IERC721Receiver {
    // struct to store a stake's token, owner, and earning values
    struct Stake {
        uint16 tokenId;
        uint80 value;
        address owner;
    }

    event TokenStaked(address owner, uint256 tokenId, uint256 value);
    event HONORClaimed(uint256 tokenId, uint256 earned, bool unstaked);

    // reference to the SamuraiDoge NFT contract
    IERC721 samuraidoge;
    // reference to the $HONOR contract for minting $HONOR earnings
    HONOR honor;

    // maps tokenId to stake
    mapping(uint256 => Stake) public war;

    // maps address to number of tokens staked
    mapping(address => uint256) public numTokensStaked;

    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // samuraidoge earn 10 $HONOR per day
    uint256 public constant DAILY_HONOR_RATE = 10 ether;

    // number of SamuraiDoge staked in the War
    uint256 public totalSamuraiDogeStaked;

    // the last time $HONOR can be claimed
    uint256 public lastClaimTimestamp;

    // whether staking is active
    bool public stakeIsActive = true;

    // Bonus $HONOR for elligible tokens
    uint256 public tokensElligibleForBonus;
    uint256 public bonusAmount;
    mapping(uint256 => bool) public bonusClaimed;

    /**
     * @param _samuraidoge reference to the SamuraiDoge NFT contract
     * @param _honor reference to the $HONOR token
     * @param _claimPeriod Period (in seconds) from contract creation when staked SamuraiDoges can earn $HON
     * @param _tokensElligibleForBonus Number of tokens elligible for bonus $HON (ordered by tokenId)
     * @param _bonusAmount Amount of $HON (in Wei) to be given out as bonus
     */
    constructor(
        address _samuraidoge,
        address _honor,
        uint256 _claimPeriod,
        uint256 _tokensElligibleForBonus,
        uint256 _bonusAmount
    ) {
        samuraidoge = IERC721(_samuraidoge);
        honor = HONOR(_honor);
        lastClaimTimestamp = block.timestamp + _claimPeriod;
        tokensElligibleForBonus = _tokensElligibleForBonus;
        bonusAmount = _bonusAmount;
    }

    /** STAKING */

    /**
     * adds SamuraiDoges to the War
     * @param tokenIds the IDs of the SamuraiDoge to stake
     */
    function addManyToWar(uint16[] calldata tokenIds) external {
        require(stakeIsActive, "Staking is paused");
        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(
                samuraidoge.ownerOf(tokenIds[i]) == msg.sender,
                "Not your token"
            );
            samuraidoge.transferFrom(msg.sender, address(this), tokenIds[i]);
            _addSamuraiDogeToWar(msg.sender, tokenIds[i]);
        }
    }

    /**
     * adds a single SamuraiDoge to the War
     * @param owner the address of the staker
     * @param tokenId the ID of the SamuraiDoge to add to the War
     */
    function _addSamuraiDogeToWar(address owner, uint256 tokenId) internal {
        war[tokenId] = Stake({
            owner: owner,
            tokenId: uint16(tokenId),
            value: uint80(block.timestamp)
        });
        _addTokenToOwnerEnumeration(owner, tokenId);
        totalSamuraiDogeStaked += 1;
        numTokensStaked[owner] += 1;
        emit TokenStaked(owner, tokenId, block.timestamp);
    }

    /** CLAIMING / UNSTAKING */

    /**
     * realize $HONOR earnings and optionally unstake tokens from the War
     * @param tokenIds the IDs of the tokens to claim earnings from
     * @param unstake whether or not to unstake ALL of the tokens listed in tokenIds
     */
    function claimManyFromWar(uint16[] calldata tokenIds, bool unstake)
        external
    {
        uint256 owed = 0;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            owed += _claimHonorFromWar(tokenIds[i], unstake);
        }
        if (owed == 0) return;
        honor.stakingMint(msg.sender, owed);
    }

    /**
     * realize $HONOR earnings for a single SamuraiDoge and optionally unstake it
     * @param tokenId the ID of the SamuraiDoge to claim earnings from
     * @param unstake whether or not to unstake the SamuraiDoge
     * @return owed - the amount of $HONOR earned
     */
    function _claimHonorFromWar(uint256 tokenId, bool unstake)
        internal
        returns (uint256)
    {
        Stake memory stake = war[tokenId];
        if (stake.owner == address(0)) {
            // Unstaked SD tokens
            require(
                samuraidoge.ownerOf(tokenId) == msg.sender,
                "Not your token"
            );
            uint256 owed = _getClaimableHonor(tokenId);
            bonusClaimed[tokenId] = true;
            emit HONORClaimed(tokenId, owed, unstake);
            return owed;
        } else {
            // Staked SD tokens
            require(stake.owner == msg.sender, "Not your token");
            uint256 owed = _getClaimableHonor(tokenId);
            if (_elligibleForBonus(tokenId)) {
                bonusClaimed[tokenId] = true;
            }
            if (unstake) {
                // Send back SamuraiDoge to owner
                samuraidoge.safeTransferFrom(
                    address(this),
                    msg.sender,
                    tokenId,
                    ""
                );
                _removeTokenFromOwnerEnumeration(stake.owner, stake.tokenId);
                delete war[tokenId];
                totalSamuraiDogeStaked -= 1;
                numTokensStaked[msg.sender] -= 1;
            } else {
                // Reset stake
                war[tokenId] = Stake({
                    owner: msg.sender,
                    tokenId: uint16(tokenId),
                    value: uint80(block.timestamp)
                });
            }
            emit HONORClaimed(tokenId, owed, unstake);
            return owed;
        }
    }

    /** GET CLAIMABLE AMOUNT */

    /**
     * Calculate total claimable $HONOR earnings from staked SamuraiDoges
     * @param tokenIds the IDs of the tokens to claim earnings from
     */
    function getClaimableHonorForMany(uint16[] calldata tokenIds)
        external
        view
        returns (uint256)
    {
        uint256 owed = 0;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            owed += _getClaimableHonor(tokenIds[i]);
        }
        return owed;
    }

    /**
     * Check if a SamuraiDoge token is elligible for bonus
     * @param tokenId the ID of the token to check for elligibility
     */
    function _elligibleForBonus(uint256 tokenId) internal view returns (bool) {
        return tokenId < tokensElligibleForBonus && !bonusClaimed[tokenId];
    }

    /**
     * Calculate claimable $HONOR earnings from a single staked SamuraiDoge
     * @param tokenId the ID of the token to claim earnings from
     */
    function _getClaimableHonor(uint256 tokenId)
        internal
        view
        returns (uint256)
    {
        uint256 owed = 0;
        if (tokenId < tokensElligibleForBonus && !bonusClaimed[tokenId]) {
            owed += bonusAmount;
        }
        Stake memory stake = war[tokenId];
        if (stake.value == 0) {} else if (
            block.timestamp < lastClaimTimestamp
        ) {
            owed +=
                ((block.timestamp - stake.value) * DAILY_HONOR_RATE) /
                1 days;
        } else if (stake.value > lastClaimTimestamp) {
            // $HONOR production stopped already
        } else {
            owed =
                ((lastClaimTimestamp - stake.value) * DAILY_HONOR_RATE) /
                1 days; // stop earning additional $HONOR after lastClaimTimeStamp
        }
        return owed;
    }

    /** ENUMERABLE */

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {numTokensStaked} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index)
        public
        view
        returns (uint256)
    {
        require(index < numTokensStaked[owner], "Owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param owner address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address owner, uint256 tokenId)
        private
    {
        uint256 length = numTokensStaked[owner];
        _ownedTokens[owner][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures.
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param owner address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address owner, uint256 tokenId)
        private
    {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = numTokensStaked[owner] - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[owner][lastTokenIndex];

            _ownedTokens[owner][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[owner][lastTokenIndex];
    }

    /** UTILS */

    /**
     * @dev Returns the owner address of a staked SamuraiDoge token
     * @param tokenId the ID of the token to check for owner
     */
    function ownerOf(uint256 tokenId) public view returns (address) {
        Stake memory stake = war[tokenId];
        return stake.owner;
    }

    /**
     * @dev Returns whether a SamuraiDoge token is staked
     * @param tokenId the ID of the token to check for staking
     */
    function isStaked(uint256 tokenId) public view returns (bool) {
        Stake memory stake = war[tokenId];
        return stake.owner != address(0);
    }

    /** ADMIN */

    /**
     * enables owner to pause / unpause staking
     */
    function setStakingStatus(bool _status) external onlyOwner {
        stakeIsActive = _status;
    }

    /**
     * allows owner to unstake tokens from the War, return the tokens to the tokens' owner, and claim $HON earnings
     * @param tokenIds the IDs of the tokens to claim earnings from
     * @param tokenOwner the address of the SamuraiDoge tokens owner
     */
    function rescueManyFromWar(uint16[] calldata tokenIds, address tokenOwner)
        external
        onlyOwner
    {
        uint256 owed = 0;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            owed += _rescueFromWar(tokenIds[i], tokenOwner);
        }
        if (owed == 0) return;
        honor.stakingMint(tokenOwner, owed);
    }

    /**
     * unstake a single SamuraiDoge from War and claim $HON earnings
     * @param tokenId the ID of the SamuraiDoge to rescue
     * @param tokenOwner the address of the SamuraiDoge token owner
     * @return owed - the amount of $HONOR earned
     */
    function _rescueFromWar(uint256 tokenId, address tokenOwner)
        internal
        returns (uint256)
    {
        Stake memory stake = war[tokenId];
        require(stake.owner == tokenOwner, "Not your token");
        uint256 owed = _getClaimableHonor(tokenId);
        if (_elligibleForBonus(tokenId)) {
            bonusClaimed[tokenId] = true;
        }
        // Send back SamuraiDoge to owner
        samuraidoge.safeTransferFrom(address(this), tokenOwner, tokenId, "");
        _removeTokenFromOwnerEnumeration(stake.owner, stake.tokenId);
        delete war[tokenId];
        totalSamuraiDogeStaked -= 1;
        numTokensStaked[tokenOwner] -= 1;
        emit HONORClaimed(tokenId, owed, true);
        return owed;
    }

    function onERC721Received(
        address,
        address from,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        require(from == address(0x0), "Cannot send tokens to War directly");
        return IERC721Receiver.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "IERC165.sol";

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

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "Context.sol";

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

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;
import "ERC20.sol";
import "Ownable.sol";

contract HONOR is ERC20, Ownable {
    // a mapping from an address to whether or not it can mint / burn
    mapping(address => bool) public controllers;

    // Staking supply
    uint256 public constant MAXIMUM_STAKING_SUPPLY = 184120000 ether;

    // Community fund supply
    uint256 public constant MAXIMUM_COMMUNITY_FUND_SUPPLY = 100000000 ether;

    // Public sale supply
    uint256 public constant MAXIMUM_PUBLIC_SALES_SUPPLY = 30000000 ether;

    // Team reserve supply
    uint256 public constant MAXIMUM_TEAM_RESERVE_SUPPLY = 60500000 ether;

    // Minted amount
    uint256 public totalStakingSupply;
    uint256 public totalCommunityFundSupply;
    uint256 public totalPublicSalesSupply;
    uint256 public totalTeamReserveSupply;

    constructor() ERC20("HONOR", "HON") {}

    /**
     * mints $HONOR from staking supply to a recipient
     * @param to the recipient of the $HONOR
     * @param amount the amount of $HONOR to mint
     */
    function stakingMint(address to, uint256 amount) external {
        require(controllers[msg.sender], "Only controllers can mint");
        require(
            totalStakingSupply + amount <= MAXIMUM_STAKING_SUPPLY,
            "Maximum staking supply exceeded"
        );
        _mint(to, amount);
        totalStakingSupply += amount;
    }

    /**
     * mints $HONOR from community fund supply to a recipient
     * @param to the recipient of the $HONOR
     * @param amount the amount of $HONOR to mint
     */
    function communityFundMint(address to, uint256 amount) external {
        require(controllers[msg.sender], "Only controllers can mint");
        require(
            totalCommunityFundSupply + amount <= MAXIMUM_COMMUNITY_FUND_SUPPLY,
            "Maximum community fund supply exceeded"
        );
        _mint(to, amount);
        totalCommunityFundSupply += amount;
    }

    /**
     * mints $HONOR from public sales supply to a recipient
     * @param to the recipient of the $HONOR
     * @param amount the amount of $HONOR to mint
     */
    function publicSalesMint(address to, uint256 amount) external {
        require(controllers[msg.sender], "Only controllers can mint");
        require(
            totalPublicSalesSupply + amount <= MAXIMUM_PUBLIC_SALES_SUPPLY,
            "Maximum public sales supply exceeded"
        );
        _mint(to, amount);
        totalPublicSalesSupply += amount;
    }

    /**
     * mints $HONOR from team reserve supply to a recipient
     * @param to the recipient of the $HONOR
     * @param amount the amount of $HONOR to mint
     */
    function teamReserveMint(address to, uint256 amount) external {
        require(controllers[msg.sender], "Only controllers can mint");
        require(
            totalTeamReserveSupply + amount <= MAXIMUM_TEAM_RESERVE_SUPPLY,
            "Maximum team reserve supply exceeded"
        );
        _mint(to, amount);
        totalTeamReserveSupply += amount;
    }

    /**
     * burns $HONOR from a holder
     * @param from the holder of the $HONOR
     * @param amount the amount of $HONOR to burn
     */
    function burn(address from, uint256 amount) external {
        require(controllers[msg.sender], "Only controllers can burn");
        _burn(from, amount);
    }

    /**
     * enables an address to mint / burn
     * @param controller the address to enable
     */
    function addController(address controller) external onlyOwner {
        controllers[controller] = true;
    }

    /**
     * disables an address from minting / burning
     * @param controller the address to disable
     */
    function removeController(address controller) external onlyOwner {
        controllers[controller] = false;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "IERC20.sol";
import "IERC20Metadata.sol";
import "Context.sol";

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

pragma solidity ^0.8.0;

import "IERC20.sol";

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