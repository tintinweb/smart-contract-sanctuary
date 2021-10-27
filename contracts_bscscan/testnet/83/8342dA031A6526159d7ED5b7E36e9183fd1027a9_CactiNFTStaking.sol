/**
 *Submitted for verification at BscScan.com on 2021-10-26
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

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
abstract contract ReentrancyGuard {
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

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
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

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

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
        return a + b;
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
        return a - b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
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
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

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

contract CactiNFTStaking is IERC721Receiver, ReentrancyGuard {
    using SafeMath for uint256;

    IERC721 public nftToken;
    IERC20 public erc20Token;

    address public daoAdmin;

    uint256 public tokensPerBlock;
    uint256 public activeStakingPeriodIndex = 0;

    struct Stake {
        uint256 tokenId;
        uint256 stakedFromBlock;
        address owner;
    }
    struct StakingPeriod {
        uint256 startBlock;
        uint256 endBlock;
    }
    struct StakedTokens {
        uint256[] tokens;
    }
    struct PopulationChange {
        uint256 blockNumber;
        uint256 cactiCount;
    }
    // TokenID => Stake
    mapping(uint256 => Stake) public receipt;
    // Address => StakedTokens
    mapping(address => StakedTokens) user;
    // index => StakingPeriod
    StakingPeriod [] public stakingPeriods;
    // index => PopulationChange
    PopulationChange [] public populationChanges;

    event NftStaked(address indexed staker, uint256 tokenId, uint256 blockNumber);
    event NftUnStaked(address indexed staker, uint256 tokenId, uint256 blockNumber);
    event StakePayout(address indexed staker, uint256 tokenId, uint256 stakeAmount, uint256 fromBlock, uint256 toBlock);
    event StakeRewardUpdated(uint256 rewardPerBlock);
    event StakePeriod(uint256 _startBlock, uint256 _endBlock, uint256 _index);
    event StakePeriodIndex(uint256 _index);
    event ERC721TokenChanged(IERC721 _tokenAddress);
    event ERC20TokenChanged(IERC20 _erc20Token);
    event DaoAdminChanged(address _daoAdmin);
    event ClaimedTokens(uint256 _tokens);

    constructor(
        IERC721 _nftToken,
        IERC20 _erc20Token,
        address _daoAdmin,
        uint256 _tokensPerBlock
    ) {
        nftToken = _nftToken;
        erc20Token = _erc20Token;
        daoAdmin = _daoAdmin;
        tokensPerBlock = _tokensPerBlock;
        emit StakeRewardUpdated(tokensPerBlock);

        stakingPeriods.push(StakingPeriod({ startBlock: block.number, endBlock: (block.number + 576000) }));
        emit StakePeriod(block.number, (block.number + 576000), activeStakingPeriodIndex);
    }

    modifier onlyStaker(uint256 tokenId) {
        // require that this contract has the NFT
        require(nftToken.ownerOf(tokenId) == address(this), "onlyStaker: Contract is not owner of this NFT");

        // require that this token is staked
        require(receipt[tokenId].stakedFromBlock != 0, "onlyStaker: Token is not staked");

        // require that msg.sender is the owner of this nft
        require(receipt[tokenId].owner == msg.sender, "onlyStaker: Caller is not NFT stake owner");

        _;
    }

    modifier requireTimeElapsed(uint256 tokenId) {
        // require that some time has elapsed (IE you can not stake and unstake in the same block)
        require(
            receipt[tokenId].stakedFromBlock < block.number,
            "requireTimeElapsed: Can not stake/unStake/harvest in same block"
        );
        _;
    }

    modifier onlyDao() {
        require(msg.sender == daoAdmin, "reclaimTokens: Caller is not the DAO");
        _;
    }

    //User must give this contract permission to take ownership of it.
    function stakeNFT(uint256[] calldata tokenId) external nonReentrant returns (bool) {
        // allow for staking multiple NFTS at one time.
        for (uint256 i = 0; i < tokenId.length; i++) {
            _stakeNFT(tokenId[i]);
        }

        incrementPopulation(tokenId.length);

        return true;
    }

    function _stakeNFT(uint256 tokenId) internal returns (bool) {
        // require that farming hasn't been ended
        require(block.number < stakingPeriods[activeStakingPeriodIndex].endBlock, 'Stake: Farming has ended');

        // require this token is not already staked
        require(receipt[tokenId].stakedFromBlock == 0, "Stake: Token is already staked");

        // require this token is not already owned by this contract
        require(nftToken.ownerOf(tokenId) != address(this), "Stake: Token is already staked in this contract");

        // take possession of the NFT
        nftToken.safeTransferFrom(msg.sender, address(this), tokenId);

        // check that this contract is the owner
        require(nftToken.ownerOf(tokenId) == address(this), "Stake: Failed to take possession of NFT");

        // start the staking from this block.
        receipt[tokenId].tokenId = tokenId;
        receipt[tokenId].stakedFromBlock = block.number;
        receipt[tokenId].owner = msg.sender;
        user[msg.sender].tokens.push(tokenId);

        emit NftStaked(msg.sender, tokenId, block.number);

        return true;
    }

    function unStakeNFT(uint256[] calldata tokenId) external nonReentrant returns (bool) {
        // allow for unstaking multiple NFTS at one time.
        for (uint256 i = 0; i < tokenId.length; i++) {
            _unStakeNFT(tokenId[i]);
        }

        decrementPopulation(tokenId.length);

        return true;
    }

    function deleteStakedTokenFromUserByIndex(uint _index) internal returns(bool) {
        for (uint i = _index; i < user[msg.sender].tokens.length - 1; i++) {
            user[msg.sender].tokens[i] = user[msg.sender].tokens[i + 1];
        }
        
        user[msg.sender].tokens.pop();
        return true;
    } 

    function deleteStakedToken(address _user, uint256 _tokenId) internal {
        for (uint256 index = 0; index < user[_user].tokens.length; index++) {
            if(user[_user].tokens[index] == _tokenId) {
                deleteStakedTokenFromUserByIndex(index);
            }
        }
    } 

    function _unStakeNFT(uint256 tokenId) internal onlyStaker(tokenId) requireTimeElapsed(tokenId) returns (bool) {
        // payout stake, this should be safe as the function is non-reentrant
        _payoutStake(tokenId);

        // delete stake record, effectively unstaking it
        delete receipt[tokenId];
        deleteStakedToken(msg.sender, tokenId);
    
        // return token
        nftToken.safeTransferFrom(address(this), msg.sender, tokenId);
        emit NftUnStaked(msg.sender, tokenId, block.number);

        return true;
    }

    function harvest(uint256[] calldata tokenId) external nonReentrant returns (bool) {
        // allow for harvesting multiple NFTS at one time.
        for (uint256 i = 0; i < tokenId.length; i++) {
            _harvest(tokenId[i]);
        }

        return true;
    }

    function _harvest(uint256 tokenId) internal onlyStaker(tokenId) requireTimeElapsed(tokenId) returns (bool) {
        // This 'payout first' should be safe as the function is nonReentrant
        _payoutStake(tokenId);

        // update receipt with a new block number
        receipt[tokenId].stakedFromBlock = block.number;

        return true;
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 tokenId) external nonReentrant returns (bool) {
        require(receipt[tokenId].owner == msg.sender, 'emergencyWithdraw: This token does not belong to this address');
        // delete stake record, effectively unstaking it
        delete receipt[tokenId];
        deleteStakedToken(msg.sender, tokenId);

        // return token
        nftToken.safeTransferFrom(address(this), msg.sender, tokenId);
        emit NftUnStaked(msg.sender, tokenId, block.number);

        return true;
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    // This is only meant if the user can't unstake his NFT from the contract
    function emergencyWithdrawToUser(address _user, bool skipMassTokensStakedDelete, uint256 tokenId) external nonReentrant onlyDao returns (bool) {
        // delete stake record, effectively unstaking it
        delete receipt[tokenId];
        if(!skipMassTokensStakedDelete) {
            deleteStakedToken(_user, tokenId);
        }

        // return token
        nftToken.safeTransferFrom(address(this), _user, tokenId);
        emit NftUnStaked(_user, tokenId, block.number);

        return true;
    }

    // If something happend and user did not get his rewards. Dao can send him tokens for EMERGENCY ONLY.
    function emergencyPayout(address _user, uint256 _payout) external nonReentrant onlyDao returns (bool) {
        erc20Token.transfer(_user, _payout);
        emit StakePayout(_user, 0, _payout, 0, block.number);

        return true;
    }

    // Getters
    function _payoutStake(uint256 tokenId) internal {
        /* NOTE : Must be called from non-reentrant function to be safe!*/

        // double check that the receipt exists and we're not staking from block 0
        require(receipt[tokenId].stakedFromBlock > 0, "_payoutStake: Can not stake from block 0");

        // earned amount is difference between the stake start block, current block multiplied by stake amount
        uint256 payout = 0;
        if(_getTimeStaked(tokenId, msg.sender) >= 1) {
            uint256 timeStaked = _getTimeStaked(tokenId, msg.sender).sub(1); // don't pay for the tx block of withdrawl
            payout = timeStaked.mul(tokensPerBlock);
        }

        // double check that the balance of the erc-20 inside the contract is higher than the payout. The
        // NFT Won't be stuck because of the emergency backup call.
        require(erc20Token.balanceOf(address(this)) >= payout, "_payoutStake: Can not payout more than the ERC-20 balance of the contract");

        // payout stake
        erc20Token.transfer(receipt[tokenId].owner, payout);

        emit StakePayout(msg.sender, tokenId, payout, receipt[tokenId].stakedFromBlock, block.number);
    }

    function _getTimeStaked(uint256 tokenId, address _wallet) internal view returns (uint256) {
		if (receipt[tokenId].stakedFromBlock == 0) {
			return 0;
		}

		uint256 startStakeReceipt = receipt[tokenId].stakedFromBlock;
		uint256 totalBlocks = 0;
		uint256 nowBlock = block.number;
        uint256 nrOfCacti = user[_wallet].tokens.length;
		for (uint256 i = 0; i < stakingPeriods.length; i++) {
			uint256 startBlock = stakingPeriods[i].startBlock;
			uint256 endBlock = stakingPeriods[i].endBlock;
			// Old blocks (After period has ended)
			if(endBlock < nowBlock) {
				// The period end block must be higher than the user's receipt `stakedFromBlock`
				if(endBlock > startStakeReceipt) {
					// The user's receipt `stakedFromBlock` must be smaller than the current staking period block
					if(startBlock > startStakeReceipt) {
						// totalBlocks = totalBlocks.add(endBlock).sub(startBlock);
						totalBlocks = totalBlocks + _getStakeValue(nrOfCacti, startBlock, endBlock);
						// The user's receipt `stakedFromBlock` must be between de start and end block
					} else if(startStakeReceipt >= startBlock && startStakeReceipt <= endBlock) {
						// totalBlocks = totalBlocks.add(endBlock).sub(startStakeReceipt);
						totalBlocks = totalBlocks + _getStakeValue(nrOfCacti, startStakeReceipt, endBlock);
					}
				}
			} else if(startStakeReceipt >= startBlock && startStakeReceipt <= endBlock) {
				// The current active staking period in which you started.
				// totalBlocks = totalBlocks.add(nowBlock).sub(startStakeReceipt);
				totalBlocks = totalBlocks + _getStakeValue(nrOfCacti, startStakeReceipt, nowBlock);
			} else if (startStakeReceipt <= endBlock && nowBlock > startBlock) {
				// The current active staking period after you started.
				// totalBlocks = totalBlocks.add(nowBlock).sub(startBlock);
				totalBlocks = totalBlocks + _getStakeValue(nrOfCacti, startBlock, nowBlock);
			}
		}
		return totalBlocks;
	}

    function _getStakeValue(uint256 nrOfCacti, uint256 start, uint256 end) internal view returns (uint256) {
		uint256 total = 0;
		uint256 cactiFactor = 0; 

		for (uint256 i = 0; i < populationChanges.length; i++) {
            if (populationChanges[i].blockNumber <= start) {
                cactiFactor = nrOfCacti / populationChanges[i].cactiCount;
            } else if (populationChanges[i].blockNumber <= end) {
                total = total + (populationChanges[i].blockNumber - start) * cactiFactor;
                cactiFactor = nrOfCacti / populationChanges[i].cactiCount;
                start = populationChanges[i].blockNumber;
            }
		}
        if (start < end) {
            total = total + (end - start) * cactiFactor;
        }
        return total;
    }

    function getStakeContractBalance() external view returns (uint256) {
        return erc20Token.balanceOf(address(this));
    }

    function getCurrentStakeEarned(uint256 tokenId, address _wallet) external view returns (uint256) {
        return _getTimeStaked(tokenId, _wallet).mul(tokensPerBlock);
    }
    
    function getCurrentStakeEarnedOnAllTokens(address _wallet) external view returns (uint256) {
        uint256 staked = 0;
        uint256 lengthStaked = user[_wallet].tokens.length;
        for (uint256 index = 0; index < lengthStaked; index++) {
            uint256 token = user[_wallet].tokens[index];
            staked = staked.add(_getTimeStaked(token, _wallet).mul(tokensPerBlock));
        }
        return staked;
    }

    function getStakedTokens(address _wallet) external view returns (uint256 [] memory) {
        return user[_wallet].tokens;
    }

    function getStakedTokensLength(address _wallet) external view returns (uint256) {
        return user[_wallet].tokens.length;
    }

    function getAllowance(address owner) external view returns (bool) {
        return nftToken.isApprovedForAll(owner, address(this));
    }

    // Setters
    function incrementPopulation(uint256 _cactiCount) private onlyDao {
        uint256 lastCactiCount = 0;
        for (uint256 i = 0; i < populationChanges.length; i++) {
            if(populationChanges[i].blockNumber == block.number) {
                populationChanges[i].cactiCount = populationChanges[i].cactiCount.add(_cactiCount);
                return;
            }
            lastCactiCount = populationChanges[i].cactiCount;
        }
        
        populationChanges.push(PopulationChange({ blockNumber: block.number, cactiCount: lastCactiCount.add(_cactiCount) }));
    }

    function decrementPopulation(uint256 _cactiCount) private onlyDao {
        uint256 lastCactiCount = 0;
        for (uint256 i = 0; i < populationChanges.length; i++) {
            if(populationChanges[i].blockNumber == block.number) {
                populationChanges[i].cactiCount = populationChanges[i].cactiCount.sub(_cactiCount);
                return;
            }
            lastCactiCount = populationChanges[i].cactiCount;
        }
        
        populationChanges.push(PopulationChange({ blockNumber: block.number, cactiCount: lastCactiCount.sub(_cactiCount) }));
    }

    function setStakingPeriod(uint256 _startBlock, uint256 _endBlock, bool _activateNewIndex, uint256 _index) external onlyDao {
        require(_startBlock != 0, 'setStakingPeriod: Cannot be 0');
        require(_endBlock != 0, 'setStakingPeriod: Cannot be 0');
        
        // This check is for if you want to change the blocks but not want to start a new index.
        if(_activateNewIndex) {
            activeStakingPeriodIndex = _index;
            stakingPeriods.push(StakingPeriod({ startBlock: _startBlock, endBlock: _endBlock }));
        } else {
            stakingPeriods[_index].startBlock = _startBlock;
            stakingPeriods[_index].endBlock = _endBlock;
        }

        emit StakePeriod(_startBlock, _endBlock, _index);
    }

    function setTokensPerBlock(uint256 _tokensPerBlock) external onlyDao {
        require(_tokensPerBlock != 0, 'setTokensPerBlock: Cannot be 0');
        tokensPerBlock = _tokensPerBlock;

        emit StakeRewardUpdated(tokensPerBlock);
    }

    function setActiveStakingPeriodIndex(uint256 _index) external onlyDao {
        activeStakingPeriodIndex = _index;

        emit StakePeriodIndex(_index);
    }

    function setNFTToken(IERC721 _tokenAddress) external onlyDao {
        nftToken = _tokenAddress;

        emit ERC721TokenChanged(_tokenAddress);
    }

    function setERC20Token(IERC20 _erc20Token) external onlyDao {
        erc20Token = _erc20Token;

        emit ERC20TokenChanged(_erc20Token);
    }

    function setDaoAdmin(address _daoAdmin) external onlyDao {
        require(_daoAdmin != address(0), 'setDaoAdmin: Cannot be the 0 address');
        daoAdmin = _daoAdmin;

        emit DaoAdminChanged(_daoAdmin);
    }

    function reclaimTokens() external onlyDao {
        erc20Token.transfer(daoAdmin, erc20Token.balanceOf(address(this)));

        emit ClaimedTokens(erc20Token.balanceOf(address(this)));
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) external virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}