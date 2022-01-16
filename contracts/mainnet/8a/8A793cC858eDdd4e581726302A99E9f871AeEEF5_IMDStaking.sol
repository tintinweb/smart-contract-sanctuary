// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/interfaces/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/ICollegeCredit.sol";
import "./CollegeCredit.sol";

contract IMDStaking is Ownable {
    event Staked(address indexed user, address indexed token, uint256[] tokenIds, uint256 timestamp);
    event Unstaked(address indexed user, address indexed token, uint256[] tokenIds, uint256 timestamp);
    event ClaimDividend(address indexed user, address indexed token, uint256 amount);

    struct StakedToken {
        uint256 stakeTimestamp;
        uint256 nextToken;
        address owner;
    }

    struct StakableTokenAttributes {
        /**
         * The minimum yield per period.
         */
        uint256 minYield;
        /**
         * The maximum yield per period.
         */
        uint256 maxYield;
        /**
         * The amount that yield increases per period.
         */
        uint256 step;
        /**
         * The amount of time needed to earn 1 yield.
         */
        uint256 yieldPeriod;
        /**
         * A mapping from token ids to information about that token's staking.
         */
        mapping(uint256 => StakedToken) stakedTokens;
        /**
         * A mapping from the user's address to their root staked token
         */
        mapping(address => uint256) firstStaked;
        /**
         * A mapping of modifiers to rewards for each staker's
         * address.
         */
        mapping(address => int256) rewardModifier;
    }

    /**
     * The reward token (college credit) to be issued to stakers.
     */
    ICollegeCredit public rewardToken;

    /**
     * A mapping of token addresses to staking configurations.
     */
    mapping(address => StakableTokenAttributes) public stakableTokenAttributes;

    /**
     * The constructor for the staking contract, builds the initial reward token and stakable token.
     * @param _token the first stakable token address.
     * @param _minYield the minimum yield for the stakable token.
     * @param _maxYield the maximum yield for the stakable token.
     * @param _step the amount yield increases per yield period.
     * @param _yieldPeriod the length (in seconds) of a yield period (the amount of period after which a yield is calculated)
     */
    constructor(
        address _token,
        uint256 _minYield,
        uint256 _maxYield,
        uint256 _step,
        uint256 _yieldPeriod
    ) {
        _addStakableToken(_token, _minYield, _maxYield, _step, _yieldPeriod);

        rewardToken = new CollegeCredit();
    }

    /**
     * Mints the reward token to an account.
     * @dev owner only.
     * @param _recipient the recipient of the minted tokens.
     * @param _amount the amount of tokens to mint.
     */
    function mintRewardToken(address _recipient, uint256 _amount)
        external
        onlyOwner
    {
        rewardToken.mint(_recipient, _amount);
    }

    /**
     * Adds a new token that can be staked in the contract.
     * @param _token the first stakable token address.
     * @param _minYield the minimum yield for the stakable token.
     * @param _maxYield the maximum yield for the stakable token.
     * @param _step the amount yield increases per yield period.
     * @param _yieldPeriod the length (in seconds) of a yield period (the amount of period after which a yield is calculated).
     * @dev owner only, doesn't allow adding already staked tokens.
     */
    function addStakableToken(
        address _token,
        uint256 _minYield,
        uint256 _maxYield,
        uint256 _step,
        uint256 _yieldPeriod
    ) external onlyOwner {
        require(!_isStakable(_token), "Already exists");
        _addStakableToken(_token, _minYield, _maxYield, _step, _yieldPeriod);
    }

    /**
     * Stakes a given token id from a given contract.
     * @param _token the address of the stakable token.
     * @param _tokenId the id of the token to stake.
     * @dev the contract must be approved to transfer that token first.
     *      the address must be a stakable token.
     */
    function stake(address _token, uint256 _tokenId) external {
        require(_isStakable(_token), "Not stakable");

        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = _tokenId;

        _bulkStakeFor(msg.sender, _token, tokenIds);
        emit Staked(msg.sender, _token, tokenIds, block.timestamp);
    }

    /**
     * Stakes a given token id from a given contract.
     * @param _token the address of the stakable token.
     * @param _tokenIds the ids of the tokens to stake.
     * @dev the contract must be approved to transfer that token first.
     *      the address must be a stakable token.
     */
    function stakeMany(address _token, uint256[] calldata _tokenIds) external {
        require(_isStakable(_token), "Not stakable");
        _bulkStakeFor(msg.sender, _token, _tokenIds);

        emit Staked(msg.sender, _token, _tokenIds, block.timestamp);
    }

    /**
     * Unstakes a given token held by the calling user.
     * @param _token the address of the token contract that the token belongs to.
     * @param _tokenId the id of the token to unstake.
     * @dev reverts if the token is not owned by the caller.
     */
    function unstake(address _token, uint256 _tokenId) external {
        require(_isStakable(_token), "Not stakable");
        require(
            stakableTokenAttributes[_token].stakedTokens[_tokenId].owner ==
                msg.sender,
            "Not owner"
        );

        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = _tokenId;

        _unstake(_token, _tokenId);
        emit Unstaked(msg.sender, _token, tokenIds, block.timestamp);
    }

    /**
     * Unstakes the given tokens held by the calling user.
     * @param _token the address of the token contract that the tokens belong to.
     * @param _tokenIds the ids of the tokens to unstake.
     * @dev reverts if the token(s) are not owned by the caller.
     */
    function unstakeMany(address _token, uint256[] calldata _tokenIds)
        external
    {
        require(_isStakable(_token), "Not stakable");
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            require(
                stakableTokenAttributes[_token]
                    .stakedTokens[_tokenIds[i]]
                    .owner == msg.sender,
                "Not owner"
            );

            _unstake(_token, _tokenIds[i]);
        }

        emit Unstaked(msg.sender, _token, _tokenIds, block.timestamp);
    }

    /**
     * Claims the rewards for the caller.
     * @param _token the token for which we are claiming rewards.
     */
    function claimRewards(address _token) external {
        require(_isStakable(_token), "Not stakable");
        uint256 dividend = _withdrawRewards(msg.sender, _token);

        emit ClaimDividend(msg.sender, _token, dividend);
    }

    /**
     * Gets the College Credit dividend of the provided user.
     * @param _user the user whose dividend we are checking.
     * @param _token the token in which we are checking.
     */
    function dividendOf(address _user, address _token)
        external
        view
        returns (uint256)
    {
        require(_isStakable(_token), "Not stakable");
        return _dividendOf(_user, _token);
    }

    /**
     * Unstakes a given token held by the calling user AND withdraws all dividends.
     * @param _token the address of the token contract that the token belongs to.
     * @param _tokenId the id of the token to unstake.
     * @dev reverts if the token is not owned by the caller.
     */
    function unstakeAndClaimRewards(address _token, uint256 _tokenId) external {
        require(_isStakable(_token), "Not stakable");
        require(
            stakableTokenAttributes[_token].stakedTokens[_tokenId].owner ==
                msg.sender,
            "Not owner"
        );
        uint256 dividend = _withdrawRewards(msg.sender, _token);
        _unstake(_token, _tokenId);

        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = _tokenId;

        emit ClaimDividend(msg.sender, _token, dividend);
        emit Unstaked(msg.sender, _token, tokenIds, block.timestamp);
    }

    /**
     * Unstakes the given tokens held by the calling user AND withdraws all dividends.
     * @param _token the address of the token contract that the token belongs to.
     * @param _tokenIds the ids of the tokens to unstake.
     * @dev reverts if the tokens are not owned by the caller.
     */
    function unstakeManyAndClaimRewards(
        address _token,
        uint256[] calldata _tokenIds
    ) external {
        require(_isStakable(_token), "Not stakable");
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            require(
                stakableTokenAttributes[_token]
                    .stakedTokens[_tokenIds[i]]
                    .owner == msg.sender,
                "Not owner"
            );
            _unstake(_token, _tokenIds[i]);
        }
        uint256 dividend = _withdrawRewards(msg.sender, _token);

        emit ClaimDividend(msg.sender, _token, dividend);
        emit Unstaked(msg.sender, _token, _tokenIds, block.timestamp);
    }

    /**
     * Gets the total amount of tokens staked for the given user in the given contract.
     * @param _user the user whose stakes are being counted.
     * @param _token the address of the contract whose staked tokens we are skimming.
     * @dev reverts if called on an invalid token address.
     */
    function totalStakedFor(address _user, address _token)
        external
        view
        returns (uint256)
    {
        require(_isStakable(_token), "Not stakable");
        return _totalStaked(_user, _token);
    }

    /**
     * Gets the total amount staked for a given token address.
     * @param _token the address to get the amount staked from.
     */
    function totalStaked(address _token) external view returns (uint256) {
        require(_isStakable(_token), "Not stakable");
        return _totalStaked(_token);
    }

    /**
     * Gets all of the token ids that a user has staked from a given contract.
     * @param _user the user whose token ids are being analyzed.
     * @param _token the address of the token contract being analyzed.
     * @return an array of token ids staked by that user.
     * @dev reverts if called on an invalid token address.
     */
    function stakedTokenIds(address _user, address _token)
        external
        view
        returns (uint256[] memory)
    {
        require(_isStakable(_token), "Not stakable");
        return _stakedTokenIds(_user, _token);
    }

    // --------------- INTERNAL FUNCTIONS -----------------

    /**
     * Gets the total amount staked for a given token address.
     * @param _token the address to get the amount staked from.
     */
    function _totalStaked(address _token) internal view returns (uint256) {
        return IERC721(_token).balanceOf(address(this));
    }

    /**
     * @return if the given token address is stakable.
     * @param _token the address to a token to query for stakability.
     * @dev does not check if is ERC721, that is up to the user.
     */
    function _isStakable(address _token) internal view returns (bool) {
        return stakableTokenAttributes[_token].maxYield != 0;
    }

    /**
     * Adds a given token to the list of stakable tokens.
     * @param _token the first stakable token address.
     * @param _minYield the minimum yield for the stakable token.
     * @param _maxYield the maximum yield for the stakable token.
     * @param _step the amount yield increases per yield period.
     * @param _yieldPeriod the length (in seconds) of a yield period (the amount of period after which a yield is calculated).
     * @dev checks constraints to ensure _isStakable works as well as other logic. Does not check if is already stakable.
     */
    function _addStakableToken(
        address _token,
        uint256 _minYield,
        uint256 _maxYield,
        uint256 _step,
        uint256 _yieldPeriod
    ) internal {
        require(_maxYield > 0, "Invalid max");
        require(_minYield > 0, "Invalid min");
        require(_yieldPeriod >= 1 minutes, "Invalid period");

        stakableTokenAttributes[_token].maxYield = _maxYield;
        stakableTokenAttributes[_token].minYield = _minYield;
        stakableTokenAttributes[_token].step = _step;
        stakableTokenAttributes[_token].yieldPeriod = _yieldPeriod;
    }

    /**
     * Stakes the given token ids from a given contract.
     * @param _user the user from which to transfer the token.
     * @param _token the address of the stakable token.
     * @param _tokenIds the ids of the tokens to stake.
     * @dev the contract must be approved to transfer that token first.
     *      the address must be a stakable token.
     */
    function _bulkStakeFor(
        address _user,
        address _token,
        uint256[] memory _tokenIds
    ) internal {
        uint256 lastStaked = _lastStaked(_user, _token);

        for (uint256 i = 0; i < _tokenIds.length; i++) {
            IERC721(_token).transferFrom(_user, address(this), _tokenIds[i]);

            StakedToken memory token;
            token.owner = _user;
            token.stakeTimestamp = block.timestamp;

            if (lastStaked == 0)
                stakableTokenAttributes[_token].firstStaked[_user] = _tokenIds[i];
            else
                stakableTokenAttributes[_token]
                    .stakedTokens[lastStaked]
                    .nextToken = _tokenIds[i];

            lastStaked = _tokenIds[i];
            stakableTokenAttributes[_token].stakedTokens[_tokenIds[i]] = token;
        }
    }

    /**
     * Retrieves the dividend owed on a particular token with a given timestamp.
     * @param _tokenAttributes the attributes of the token provided.
     * @param _timestamp the timestamp at which the token was staked.
     * @return the dividend owed for that specific token.
     */
    function _tokenDividend(
        StakableTokenAttributes storage _tokenAttributes,
        uint256 _timestamp
    ) internal view returns (uint256) {
        if (_timestamp == 0) return 0;

        uint256 periods = (block.timestamp - _timestamp) /
            _tokenAttributes.yieldPeriod;

        uint256 dividend = 0;
        uint256 i = 0;
        for (i; i < periods; i++) {
            uint256 uncappedYield = _tokenAttributes.minYield +
                i *
                _tokenAttributes.step;

            if (uncappedYield > _tokenAttributes.maxYield) {
                dividend += _tokenAttributes.maxYield;
                i++;
                break;
            }
            dividend += uncappedYield;
        }

        dividend += (periods - i) * _tokenAttributes.maxYield;

        return dividend;
    }

    /**
     * Gets the total amount of tokens staked for the given user in the given contract.
     * @param _user the user whose stakes are being counted.
     * @param _token the address of the contract whose staked tokens we are skimming.
     * @dev does not check if the token address is stakable.
     */
    function _totalStaked(address _user, address _token)
        internal
        view
        returns (uint256)
    {
        uint256 tokenCount = 0;

        uint256 nextToken = stakableTokenAttributes[_token].firstStaked[_user];
        if (nextToken == 0) return 0;

        while (nextToken != 0) {
            tokenCount++;
            nextToken = stakableTokenAttributes[_token]
                .stakedTokens[nextToken]
                .nextToken;
        }

        return tokenCount;
    }

    /**
     * Gets the last token ID staked by the user.
     * @param _user the user whose last stake is being found.
     * @param _token the address of the contract whose staked tokens we are skimming.
     * @dev does not check if the token address is stakable.
     */
    function _lastStaked(address _user, address _token)
        internal
        view
        returns (uint256)
    {
        uint256 nextToken = stakableTokenAttributes[_token].firstStaked[_user];
        if (nextToken == 0) return 0;

        while (
            stakableTokenAttributes[_token].stakedTokens[nextToken].nextToken !=
            0
        ) {
            nextToken = stakableTokenAttributes[_token]
                .stakedTokens[nextToken]
                .nextToken;
        }

        return nextToken;
    }

    /**
     * Gets the token before the given token id owned by the user.
     * @param _user the user staked tokens are being traversed.
     * @param _token the address of the contract whose staked tokens we are skimming.
     * @param _tokenId the id of the token whose precedent we are looking for
     * @dev does not check if the token address is stakable. throws if not found
     */
    function _tokenBefore(
        address _user,
        address _token,
        uint256 _tokenId
    ) internal view returns (uint256) {
        uint256 nextToken = stakableTokenAttributes[_token].firstStaked[_user];
        require(nextToken != 0, "None staked");

        if (nextToken == _tokenId) return 0;

        while (nextToken != 0) {
            uint256 next = stakableTokenAttributes[_token]
                .stakedTokens[nextToken]
                .nextToken;
            if (next == _tokenId) return nextToken;
            nextToken = next;
        }

        revert("Token not found");
    }

    /**
     * Gets all of the token ids that a user has staked from a given contract.
     * @param _user the user whose token ids are being analyzed.
     * @param _token the address of the token contract being analyzed.
     * @return an array of token ids staked by that user.
     * @dev does not check if the token address is stakable.
     */
    function _stakedTokenIds(address _user, address _token)
        internal
        view
        returns (uint256[] memory)
    {
        uint256 numStaked = _totalStaked(_user, _token);
        uint256[] memory tokenIds = new uint256[](numStaked);

        if (numStaked == 0) return tokenIds;
        uint256 nextToken = stakableTokenAttributes[_token].firstStaked[_user];

        uint256 index = 0;
        while (nextToken != 0) {
            tokenIds[index] = nextToken;
            nextToken = stakableTokenAttributes[_token]
                .stakedTokens[nextToken]
                .nextToken;
            index++;
        }

        return tokenIds;
    }

    /**
     * Gets the College Credit dividend of the provided user.
     * @param _user the user whose dividend we are checking.
     * @param _token the token whose dividends we are checking.
     */
    function _dividendOf(address _user, address _token)
        internal
        view
        returns (uint256)
    {
        uint256 dividend = 0;
        uint256 nextToken = stakableTokenAttributes[_token].firstStaked[_user];

        while (nextToken != 0) {
            dividend += _tokenDividend(
                stakableTokenAttributes[_token],
                stakableTokenAttributes[_token]
                    .stakedTokens[nextToken]
                    .stakeTimestamp
            );

            nextToken = stakableTokenAttributes[_token]
                .stakedTokens[nextToken]
                .nextToken;
        }

        int256 resultantDividend = int256(dividend) +
            stakableTokenAttributes[_token].rewardModifier[_user];

        require(resultantDividend >= 0, "Underflow");
        return uint256(resultantDividend);
    }

    /**
     * Unstakes a given token id.
     * @param _token the address of the token contract that the token belongs to.
     * @param _tokenId the id of the token to unstake.
     * @dev does not check permissions.
     */
    function _unstake(address _token, uint256 _tokenId) internal {
        address owner = stakableTokenAttributes[_token]
            .stakedTokens[_tokenId]
            .owner;

        // will fail to get dividend if not staked or bad token contract
        uint256 dividend = _tokenDividend(
            stakableTokenAttributes[_token],
            stakableTokenAttributes[_token]
                .stakedTokens[_tokenId]
                .stakeTimestamp
        );

        stakableTokenAttributes[_token].rewardModifier[owner] += int256(
            dividend
        );

        // remove link in chain
        uint256 tokenBefore = _tokenBefore(owner, _token, _tokenId);
        if (tokenBefore == 0)
            stakableTokenAttributes[_token].firstStaked[
                owner
            ] = stakableTokenAttributes[_token]
                .stakedTokens[_tokenId]
                .nextToken;
        else
            stakableTokenAttributes[_token]
                .stakedTokens[tokenBefore]
                .nextToken = stakableTokenAttributes[_token]
                .stakedTokens[_tokenId]
                .nextToken;

        delete stakableTokenAttributes[_token].stakedTokens[_tokenId];

        IERC721(_token).safeTransferFrom(address(this), owner, _tokenId);
    }

    /**
     * Claims the dividend for the user.
     * @param _user the user whose rewards are being withdrawn.
     * @param _token the token from which rewards are being withdrawn.
     * @dev does not check is the user has permission to withdraw. Reverts on zero dividend.
     * @return dividend
     */
    function _withdrawRewards(address _user, address _token) internal returns (uint256) {
        uint256 dividend = _dividendOf(_user, _token);
        require(dividend > 0, "Zero dividend");

        stakableTokenAttributes[_token].rewardModifier[_user] -= int256(
            dividend
        );

        rewardToken.mint(_user, dividend);
        return dividend;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC721.sol)

pragma solidity ^0.8.0;

import "../token/ERC721/IERC721.sol";

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

pragma solidity ^0.8.7;
// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ICollegeCredit is IERC20 {
    function mint(address recipient, uint256 amount) external;
}

pragma solidity ^0.8.7;
// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/ICollegeCredit.sol";

contract CollegeCredit is ERC20, Ownable, ICollegeCredit {
    constructor() ERC20("College Credit", "CREDIT") {}
    
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }
    
    function mint(address recipient, uint256 amount) override external onlyOwner {
        _mint(recipient, amount);
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/ERC20.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

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