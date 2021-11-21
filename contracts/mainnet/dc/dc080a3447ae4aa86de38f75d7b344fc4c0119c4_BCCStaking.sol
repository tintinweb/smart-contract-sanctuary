/**
 *Submitted for verification at Etherscan.io on 2021-11-21
*/

// File: @openzeppelin/contracts/utils/Context.sol



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

// File: @openzeppelin/contracts/access/Ownable.sol



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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol



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

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol



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

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol



pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol



pragma solidity ^0.8.0;


/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// File: BCC.sol


pragma solidity 0.8.7;




contract BCCStaking is Ownable {
    
    // Modifiers
    
    modifier eoaOnly {
        require(msg.sender == tx.origin);
        _;
    }
    
    modifier whenNotPaused {
        require((!paused) || (msg.sender == owner()), 'The contract is paused!');
        _;
    }
    
    
    // Events
    
    event Staked(address indexed from, uint indexed tokenId, uint timestamp);
    event Unstaked(address indexed from, uint indexed tokenId, uint timestamp);
    event RewardChanged(uint oldReward, uint newReward, uint timestamp);
    
    
    // Storage Variables
    
    uint oldBaseReward;
    uint baseRewardPerSecond;
    uint rewardChangedAt;
    
    mapping(uint => address) public ownerOf;
    mapping(address => uint) public lastClaimOfAccount;
    mapping(address => uint[]) public addressToOwnedTokens;
    
    bool public paused = false;
    
    IERC721Enumerable nftContract;
    IERC20 bccContract;
    
    
    // Constructor
    
    constructor(IERC721Enumerable nftContract_, IERC20 bccContract_, uint baseRewardPerDay_, bool paused_) {
        bccContract = bccContract_;
        nftContract = nftContract_;
        paused = paused_;
        baseRewardPerSecond = ((baseRewardPerDay_ * 1e18) / 1 days) + 1;
    }
    
    
    // External functions
    
    function stakeAndUnstakeMultiple(uint[] memory stakeTokenIds, uint[] memory unstakeTokenIds) whenNotPaused eoaOnly external {
        require(nftContract.isApprovedForAll(msg.sender,address(this)),"Approve the contract to transfer your tokens first!");
        claimAll();
        for(uint i = 0; i < stakeTokenIds.length; i++) {
            stake(stakeTokenIds[i]);
        }
        for(uint i = 0; i < unstakeTokenIds.length; i++) {
            unstake(unstakeTokenIds[i]);
        }
    }
    
    function stakeMultiple(uint[] memory tokenIds) whenNotPaused eoaOnly external {
        require(nftContract.isApprovedForAll(msg.sender,address(this)),"Approve the contract to transfer your tokens first!");
        claimAll();
        for(uint i = 0; i < tokenIds.length; i++) {
            stake(tokenIds[i]);
        }
        
    }
    
    function unstakeMultiple(uint[] memory tokenIds) whenNotPaused eoaOnly external {
        claimAll();
        for(uint i = 0; i < tokenIds.length; i++) {
            unstake(tokenIds[i]);
        }
    }
    
    function claimAll() whenNotPaused eoaOnly public {
        uint reward = getClaimAmountOfAccount(msg.sender);
        if(reward > 0) {
            bccContract.transfer(msg.sender,reward);
        }
        lastClaimOfAccount[msg.sender] = block.timestamp;
    }
    
    
    // View Only
    
    function getTokensOfAccount(address account) external view returns(uint[] memory tokens) {
        return addressToOwnedTokens[account];
    }
    
    function getClaimAmountOfAccount(address account) public view returns(uint total) {
        uint tokens = addressToOwnedTokens[account].length;
        if(tokens == 0) {
            return 0;
        }
        uint rewardChangedAt_ = rewardChangedAt;
        uint lastClaim = lastClaimOfAccount[account];
        uint endTimestamp = block.timestamp;
        if(endTimestamp < rewardChangedAt_ || rewardChangedAt_ == 0) {
            return (((endTimestamp - lastClaim) * ( rewardChangedAt_ == 0 ? baseRewardPerSecond : oldBaseReward)) * tokens);
        } else if(lastClaim > rewardChangedAt_) {
            return (((endTimestamp - lastClaim) * baseRewardPerSecond) * tokens);
        } else {
            return ((((endTimestamp - rewardChangedAt_) * baseRewardPerSecond) + ((rewardChangedAt_ - lastClaim) * oldBaseReward)) * tokens);
        }
    }
    
    function balanceOf(address account) public view returns(uint balance) {
        return addressToOwnedTokens[account].length;
    }
    
    function rewardPerDayPerToken() external view returns(uint rewardPerDay) {
        if(block.timestamp < rewardChangedAt || rewardChangedAt == 0)
            return ((rewardChangedAt == 0 ? baseRewardPerSecond : oldBaseReward) * 86400) / 1e18;
        return (baseRewardPerSecond * 86400) / 1e18;
    }
    
    
    // Internal
    
    function stake(uint tokenId) internal {
        nftContract.transferFrom(msg.sender,address(this),tokenId);
        ownerOf[tokenId] = msg.sender;
        addressToOwnedTokens[msg.sender].push(tokenId);
        emit Staked(msg.sender,tokenId,block.timestamp);
    }
    
    function unstake(uint tokenId) internal {
        require(ownerOf[tokenId] == msg.sender, "Only the owner of the token can withdraw it!");
        bool removed = false;
        uint[] memory ownedTokens = addressToOwnedTokens[msg.sender];
        for( uint i = 0; i < ownedTokens.length; i++) {
            if(ownedTokens[i] == tokenId) {
                addressToOwnedTokens[msg.sender][i] = ownedTokens[ownedTokens.length - 1];
                addressToOwnedTokens[msg.sender].pop();
                removed = true;
                break;
            }
        }
        require(removed, "Internal error!");
        ownerOf[tokenId] = address(0);
        nftContract.transferFrom(address(this),msg.sender,tokenId);
        emit Unstaked(msg.sender,tokenId,block.timestamp);
    }
    
    
    // Owner Only
    
    function setBaseRewardPerDay(uint perDay, uint timestamp) external onlyOwner {
        oldBaseReward = baseRewardPerSecond;
        rewardChangedAt = timestamp;
        baseRewardPerSecond = ((perDay * 1e18) / 1 days) + 1;
        emit RewardChanged(oldBaseReward, baseRewardPerSecond, timestamp);
    }
    
    function airdrop(address[] memory targets,uint[] memory amounts) external onlyOwner {
        require(targets.length == amounts.length, "Invalid data");
        for(uint i = 0; i < targets.length; i++) {
            bccContract.transfer(targets[i],amounts[i]);
        }
    }
    
    function setContracts(IERC721Enumerable nftContract_, IERC20 bccContract_) external onlyOwner {
        bccContract = bccContract_;
        nftContract = nftContract_;
    }
    
    function setPaused(bool state) external onlyOwner {
        paused = state;
    }
    
    function setEmergency(bool state) external onlyOwner {
        emergency = state;
    }
    
    function emergencyWithdrawBCCTokens(uint amount) external onlyOwner {
        bccContract.transfer(msg.sender,amount);
    }
    
    
    // Emergency Only
    
    bool internal emergency = false;
    
    function emergencyReturnToken(uint tokenId) eoaOnly external {
        require(emergency, 'You can only use this function in case of an emergency');
        unstake(tokenId); 
    }
    
}