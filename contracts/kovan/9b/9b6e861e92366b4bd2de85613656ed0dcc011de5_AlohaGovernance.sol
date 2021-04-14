/**
 *Submitted for verification at Etherscan.io on 2021-04-14
*/

/**
 *Submitted for verification at Etherscan.io on 2021-03-25
*/

// File: @openzeppelin/contracts/GSN/Context.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: @openzeppelin/contracts/math/SafeMath.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

// File: @openzeppelin/contracts/utils/ReentrancyGuard.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () internal {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// File: @openzeppelin/contracts/introspection/IERC165.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.2;


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
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

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
    function transferFrom(address from, address to, uint256 tokenId) external;

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
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

// File: contracts/IAlohaNFT.sol

pragma solidity 0.6.5;

interface IAlohaNFT {
    function awardItem(
        address wallet,
        uint256 tokenImage,
        uint256 tokenRarity,
        uint256 tokenBackground
    ) external returns (uint256);

    function tokenRarity(uint256 tokenId) external view returns (uint256);
}

// File: contracts/AlohaGovernanceRewards.sol

pragma solidity 0.6.5;
pragma experimental ABIEncoderV2;







contract AlohaGovernanceRewards is ReentrancyGuard {
    using SafeMath for uint256;
    using SafeMath for uint8;

    uint BIGNUMBER = 10 ** 18;

    /******************
    CONFIG
    ******************/
    address public alohaERC20;

    /******************
    EVENTS
    ******************/
    event Claimed(address indexed user, uint amount);
    event Rewarded(uint256 amount, uint256 totalStaked, uint date);

    /******************
    INTERNAL ACCOUNTING
    *******************/
    uint256 public totalStaked;
    uint256 public rewardPerUnit;

    // stakesMap[address] = amount 
    mapping (address => uint256) public stakesMap;
    // usersClaimableRewardsPerStake[address] = amount
    mapping (address => uint256) public usersClaimableRewardsPerStake;

    /******************
    CONSTRUCTOR
    *******************/
    constructor (address _alohaERC20) internal {
        alohaERC20 = _alohaERC20;
    }

    /******************
    PUBLIC FUNCTIONS
    *******************/
    function distribute() public {
        require(totalStaked != 0, "AlohaGovernanceRewards: Total staked must be more than 0");

        uint256 reward = IERC20(alohaERC20).balanceOf(address(this));
        rewardPerUnit = reward.div(totalStaked);

        emit Rewarded(reward, totalStaked, _getTime());
    }

    function calculateReward(address _user) public returns (uint256) {
        distribute();

        uint256 stakedAmount = stakesMap[_user];
        uint256 amountOwedPerToken = rewardPerUnit.sub(usersClaimableRewardsPerStake[_user]);
        uint256 claimableAmount = stakedAmount.mul(amountOwedPerToken); 
        
        return claimableAmount;
    }

    function claim() public {
        uint256 claimableAmount = calculateReward(msg.sender);

        usersClaimableRewardsPerStake[msg.sender] = rewardPerUnit;
        
        require(IERC20(alohaERC20).transfer(msg.sender, claimableAmount), "AlohaGovernanceRewards: Transfer failed");
        
        emit Claimed(msg.sender, claimableAmount);
    }


    /******************
    PRIVATE FUNCTIONS
    *******************/
    function _stake(uint256 _amount) internal {
        require(_amount != 0, "AlohaGovernanceRewards: Amount can't be 0");

        if (stakesMap[msg.sender] == 0) {
            stakesMap[msg.sender] = _amount;
            usersClaimableRewardsPerStake[msg.sender] = rewardPerUnit;
        }else{
            claim();
            stakesMap[msg.sender] = stakesMap[msg.sender].add(_amount);
        }

        totalStaked = totalStaked.add(_amount);
    }

    function _unstake(uint256 _amount) internal {
        require(_amount != 0, "AlohaGovernanceRewards: Amount can't be 0");
        
        claim();
        stakesMap[msg.sender] = stakesMap[msg.sender].sub(_amount);
        totalStaked = totalStaked.sub(_amount);
    }

    function _getTime() internal view returns (uint256) {
        return block.timestamp;
    }
}

// File: contracts/AlohaGovernance.sol

pragma solidity 0.6.5;








contract AlohaGovernance is Ownable, ReentrancyGuard, AlohaGovernanceRewards {
    using SafeMath for uint256;
    using SafeMath for uint8;

    /******************
    CONFIG
    ******************/
    uint256 public powerLimit = 4000;                   // User max vote power: 40%
    uint256 public votingDelay = 3 days;                // Time to wait before deposit power counts
    uint256 public withdrawalDelay = 7 days;            // Time to wait before can withdraw deposit
    uint256 public votingDuration = 7 days;             // Proposal voting duration
    uint256 public executeProposalDelay = 2 days;       // Time to wait before run proposal approved
    uint256 public submitProposalRequiredPower = 1;     // Minimal power to create a proposal
    address public proposalModerator;                   // Address who must review each proposal before voting starts
    uint256[] public powerByRarity = [1, 5, 50];        // Token power by rarity (1, 2 and 3)

    /******************
    EVENTS
    ******************/
    event ProcessedProposal(uint256 proposalId, address indexed proposer, string details, uint256 created);
    event ReviewedProposal(uint256 proposalId, address indexed proposalModerator, ReviewStatus newStatus, uint256 created);
    event VotedProposal(uint256 _proposalId, address indexed user, Vote vote, uint256 created);
    event ExecutedProposal(uint256 _proposalId, address indexed user);
    event Deposit(address indexed user, uint256 tokenId, uint256 power, uint256 date);
    event Withdrawal(address indexed user, uint256 tokenId, uint256 power, uint256 date);

    /******************
    INTERNAL ACCOUNTING
    *******************/
    address public alohaERC721;

    uint256 public proposalCount = 0;   // Total proposals submitted
    uint256 public totalPower = 0;      // Total users power

    // users[address] = User
    mapping (address => User) public users; 
    // tokenOwner[tokenId] = address
    mapping (uint256 => address) public tokenOwner; 
    // proposals[proposalId] = Proposal
    mapping(uint256 => Proposal) public proposals;

    struct User {
        uint256 canVote;        // Timestamp when user deposits delay ends
        uint256 canWithdraw;    // Timestamp when user withdraw delay ends
        uint256 power;          // Total value of the user votes
    }

    struct Action {
        address to;         // Address to call
        uint256 value;      // Call ETH transfer
        bytes data;         // Call data
        bool executed;      // Already executed or not
    }

    enum Vote {
        Null,
        Yes,
        No
    }

    enum ReviewStatus {
        Waiting,
        OK,
        KO
    }

    struct Proposal {
        address proposer;       // The account that submitted the proposal
        Action action;          // Proposal action to be exeuted
        string details;         // Proposal details URL
        uint256 starting;       // Min timestamp when users can start to vote
        uint256 yesVotes;       // Total YES votes
        uint256 noVotes;        // Total NO votes
        ReviewStatus review;
        uint256 created;        // Created timestamp
        mapping(address => Vote) votesByMember; // Votes by user
    }

    /******************
    PUBLIC FUNCTIONS
    *******************/
    constructor(
        address _alohaERC20,
        address _alohaERC721
    )
        public
        AlohaGovernanceRewards (_alohaERC20)
    {
        require(address(_alohaERC20) != address(0)); 
        require(address(_alohaERC721) != address(0));

        alohaERC20 = _alohaERC20;
        alohaERC721 = _alohaERC721;
        proposalModerator = msg.sender;
    }

    /**
    * @dev Users deposits ALOHA NFT and gain voting power based on the rarity of the token.
    */
    function deposit(uint256 _tokenId) public {
        IERC721(alohaERC721).transferFrom(msg.sender, address(this), _tokenId);

        uint256 rarity = IAlohaNFT(alohaERC721).tokenRarity(_tokenId);
        uint256 power = powerByRarity[rarity - 1];

        users[msg.sender].canVote = _getTime() + votingDelay;
        users[msg.sender].canWithdraw = _getTime() + withdrawalDelay;
        users[msg.sender].power += power;

        totalPower += power;
        tokenOwner[_tokenId] = msg.sender;

        _stake(power);

        emit Deposit(msg.sender, _tokenId, power, _getTime());
    }

    /**
    * @dev Users withdraws ALOHA NFT and lose voting power based on the rarity of the token.
    */
    function withdraw(uint256 _tokenId)
        public
        canWithdraw()
    {
        IERC721(alohaERC721).transferFrom(address(this), tokenOwner[_tokenId], _tokenId);

        uint256 rarity = IAlohaNFT(alohaERC721).tokenRarity(_tokenId);
        uint256 power = powerByRarity[rarity - 1];

        users[msg.sender].power -= power;
        totalPower -= power;
        tokenOwner[_tokenId] = address(0x0);

        _unstake(power);

        emit Withdrawal(msg.sender, _tokenId, power, _getTime());
    }

    /**
    * @dev Users submits a on-chain proposal
    */
    function submitOnChainProposal(
        address _actionTo,
        uint256 _actionValue,
        bytes memory _actionData,
        string memory _details
    )
        public
        canSubmitProposal()
        returns (uint256 proposalId)
    {
        return _submitProposal(_actionTo, _actionValue, _actionData, _details);
    }

    /**
    * @dev Users submits a on-chain proposal
    */
    function submitOffChainProposal(
        string memory _details
    )
        public
        returns (uint256 proposalId)
    {
       return _submitProposal(address(0x0), 0, '', _details);
    }

    /**
    * @dev Moderator reviews proposal
    */
    function reviewProposal(uint256 _proposalId, ReviewStatus newStatus)
        public
        onlyModerator()
        inWaitingStatus(_proposalId)
    {
        uint256 timeNow = _getTime();
        Proposal storage proposal = proposals[_proposalId];
        
        proposal.review = newStatus;

        if (newStatus == ReviewStatus.OK) {
            proposal.starting = timeNow;
        }

        emit ReviewedProposal(_proposalId, msg.sender, newStatus, timeNow);
    }

    /**
    * @dev Vote proposal
    */
    function voteProposal(uint256 _proposalId, Vote vote)
        public
        notAlreadyVoted(_proposalId)
        reviewedOK(_proposalId)
        notEnded(_proposalId)
        canVote()
        preventWhales()
    {
        require(vote == Vote.Yes || vote == Vote.No, "AlohaGovernance: Vote must be 1 (Yes) or 2 (No)");
        
        Proposal storage proposal = proposals[_proposalId];

        proposal.votesByMember[msg.sender] = vote;

        if (vote == Vote.Yes) {
            proposal.yesVotes = proposal.yesVotes.add(users[msg.sender].power);
        } else if (vote == Vote.No) {
            proposal.noVotes = proposal.noVotes.add(users[msg.sender].power);
        }

        emit VotedProposal(_proposalId, msg.sender, vote, _getTime());
    }

    /**
    * @dev Vote proposal
    */
    function executeProposal(uint256 _proposalId)
        public
        reviewedOK(_proposalId)
        onChainProposal(_proposalId)
        notExecuted(_proposalId)
        ended(_proposalId)
        didPass(_proposalId)
        checkDelayExecution(_proposalId)
        returns (bytes memory) 
    {
        Action memory action = proposals[_proposalId].action;

        proposals[_proposalId].action.executed = true;
        (bool success, bytes memory returnData) = action.to.call.value(action.value)(action.data);
        
        require(success, "AlohaGovernance: Execution failure");
        
        emit ExecutedProposal(_proposalId, msg.sender);
        
        return returnData;
    }

    /******************
    SETTERS FUNCTIONS
    *******************/
    function setVotingDelay(uint256 _votingDelay) public onlyOwner() {
        votingDelay = _votingDelay;
    }

    function setWithdrawalDelay(uint256 _withdrawalDelay) public onlyOwner() {
        withdrawalDelay = _withdrawalDelay;
    }

    function setProposalModerator(address _proposalModerator) public onlyOwner() {
        proposalModerator = _proposalModerator;
    }

    function setSubmitProposalRequiredPower(uint256 _submitProposalRequiredPower) public onlyOwner() {
        submitProposalRequiredPower = _submitProposalRequiredPower;
    }

    function setVotingDuration(uint256 _votingDuration) public onlyOwner() {
        votingDuration = _votingDuration;
    }

    function setPowerLimit(uint256 _powerLimit) public onlyOwner() {
        powerLimit = _powerLimit;
    }

    /******************
    PRIVATE FUNCTIONS
    *******************/
    function _submitProposal(
        address _actionTo,
        uint256 _actionValue,
        bytes memory _actionData,
        string memory _details
    )
        internal
        returns (uint256 proposalId)
    {
        uint256 timeNow = _getTime();
        uint256 newProposalId = proposalCount;
        proposalCount += 1;

        Action memory onChainAction = Action({
            value: _actionValue,
            to: _actionTo,
            executed: false,
            data: _actionData
        });

        proposals[newProposalId] = Proposal({
            proposer: msg.sender,
            action: onChainAction,
            details: _details,
            starting: 0,
            yesVotes: 0,
            noVotes: 0,
            review: ReviewStatus.Waiting,
            created: timeNow
        });

        emit ProcessedProposal(newProposalId, msg.sender, _details, timeNow);

        return newProposalId;
    }

    /******************
    MODIFIERS
    *******************/
    modifier canWithdraw() {
        require(
            _getTime() >= users[msg.sender].canWithdraw,
            "AlohaGovernance: User can't withdraw yet"
        );
        _;
    }

    modifier canSubmitProposal() {
        require(
            users[msg.sender].power >= submitProposalRequiredPower,
            "AlohaGovernance: User needs more power to submit proposal"
        );
        _;
         require(
            _getTime() >= users[msg.sender].canVote,
            "AlohaGovernance: User needs to wait some time in order to submit proposal"
        );
        _;
    }

    modifier canVote() {
         require(
            _getTime() >= users[msg.sender].canVote,
            "AlohaGovernance: User needs to wait some time in order to vote proposal"
        );
        _;
    }

    modifier preventWhales() {
        require(
            (users[msg.sender].power).mul(10000).div(totalPower) <= powerLimit,
            "AlohaGovernance: User has too much power"
        );
        _;
    }

    modifier notAlreadyVoted(uint256 _proposalId) {
        require(
            proposals[_proposalId].votesByMember[msg.sender] == Vote.Null,
            "AlohaGovernance: User has already voted"
        );
        _;
    }

    modifier onlyModerator() {
        require(
            msg.sender == proposalModerator,
            "AlohaGovernance: Only moderator can call this function"
        );
        _;
    }

    modifier inWaitingStatus(uint256 _proposalId) {
        require(
            proposals[_proposalId].review == ReviewStatus.Waiting,
            'AlohaGovernance: This proposal has already been reviewed'
        );
        _;
    }

    modifier reviewedOK(uint256 _proposalId) {
        require(
            proposals[_proposalId].review == ReviewStatus.OK,
            'AlohaGovernance: This proposal has not been accepted to vote'
        );
        _;
    }

    modifier notEnded(uint256 _proposalId) {
        require(
            proposals[_proposalId].starting + votingDuration >= _getTime(),
            'AlohaGovernance: This proposal voting timing has ended'
        );
        _;
    }

    modifier ended(uint256 _proposalId) {
        require(
            _getTime() >= proposals[_proposalId].starting + votingDuration,
            'AlohaGovernance: This proposal voting timing has not ended'
        );
        _;
    }

    modifier didPass(uint256 _proposalId) {
        require(
            proposals[_proposalId].yesVotes > proposals[_proposalId].noVotes,
            'AlohaGovernance: This proposal was denied'
        );
        _;
    }

    modifier onChainProposal(uint256 _proposalId) {
        require(
            proposals[_proposalId].action.to != address(0),
            'AlohaGovernance: Not on-chain proposal'
        );
        _;
    }

    modifier notExecuted(uint256 _proposalId) {
        require(
            proposals[_proposalId].action.executed == false,
            'AlohaGovernance: Already executed proposal'
        );
        _;
    }

    modifier checkDelayExecution(uint256 _proposalId) {
        require(
            _getTime() >= proposals[_proposalId].starting + votingDuration + executeProposalDelay,
            'AlohaGovernance: This proposal executing timing delay has not ended'
        );
        _;
    }
}