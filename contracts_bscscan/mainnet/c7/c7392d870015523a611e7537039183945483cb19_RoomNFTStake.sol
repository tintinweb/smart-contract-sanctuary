/**
 *Submitted for verification at BscScan.com on 2021-07-21
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

// "IERC165.sol";
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

// "ERC165.sol";
/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts may inherit from this and call {_registerInterface} to declare
 * their support of an interface.
 */
contract ERC165 is IERC165 {
    /*
     * bytes4(keccak256('supportsInterface(bytes4)')) == 0x01ffc9a7
     */
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

    /**
     * @dev Mapping of interface ids to whether or not it's supported.
     */
    mapping(bytes4 => bool) private _supportedInterfaces;

    constructor () internal {
        // Derived contracts need only register support for their own interfaces,
        // we register support for ERC165 itself here
        _registerInterface(_INTERFACE_ID_ERC165);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     *
     * Time complexity O(1), guaranteed to always use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) public view override returns (bool) {
        return _supportedInterfaces[interfaceId];
    }

    /**
     * @dev Registers the contract as an implementer of the interface defined by
     * `interfaceId`. Support of the actual ERC165 interface is automatic and
     * registering its interface id is not required.
     *
     * See {IERC165-supportsInterface}.
     *
     * Requirements:
     *
     * - `interfaceId` cannot be the ERC165 invalid interface (`0xffffffff`).
     */
    function _registerInterface(bytes4 interfaceId) internal virtual {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
}

// "IERC1155.sol";
/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transfered from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(address indexed operator, address indexed from, address indexed to, uint256[] ids, uint256[] values);

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids) external view returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(address from, address to, uint256[] calldata ids, uint256[] calldata amounts, bytes calldata data) external;
}


// "IERC1155Receiver.sol";
/**
 * _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {

    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    )
        external
        returns(bytes4);

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
    */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    )
        external
        returns(bytes4);
}

// "SafeMath.sol";
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

// "IERC20"
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


contract RoomNFTStake is IERC1155Receiver, ReentrancyGuard {

    using SafeMath for uint256;
    
    struct bulkInputStructure{
        address account;
        uint256 roomStakedAmount;
        uint256 recoverRewards;
    }

    IERC20 public constant roomToken = IERC20(0xAd4f86a25bbc20FfB751f2FAC312A0B4d8F88c64);

    // todo: set the correct ROOm NFT
    IERC1155 public constant NFTToken = IERC1155(0x40c45a58aeFF1c55Bd268e1c0b3fdaFD1E33CDf0);

    uint256 public finishBlock;
    address public roomTokenRewardsReservoirAddress = 0x5419F0b9e40EF0EeC44640800eD21272491D4CEC;

    mapping(uint256 => mapping(address => bool)) _nftLockedToStakeRoom;

    mapping(uint256 => uint256) private _totalStaked;
    mapping(uint256 => mapping(address => uint256)) private _balances;

    mapping(uint256 => uint256) public lastUpdateBlock;
    mapping(uint256 => uint256) private _accRewardPerToken;
    mapping(uint256 => uint256) private _rewardPerBlock;

    mapping(uint256 => mapping(address => uint256)) private _prevAccRewardPerToken; // previous accumulative reward per token (for a user)
    mapping(uint256 => mapping(address => uint256)) private _rewards; // rewards balances

    event Staked(uint256 poolId, address indexed user, uint256 amount);
    event Unstaked(uint256 poolId, address indexed user, uint256 amount);
    event ClaimReward(uint256 poolId, address indexed user, uint256 reward);

    event RewardTransferFailed(TransferRewardState failure);

    enum TransferRewardState {
        Succeeded,
        RewardWalletEmpty
    }

    function onERC1155Received(address, address, uint256, uint256, bytes calldata) external override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(address, address, uint256[] calldata, uint256[] calldata, bytes calldata) external override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

    function supportsInterface(bytes4) external override view returns (bool) {
        return true;
    }
    
    address owner;

    constructor () public {
        
        owner = msg.sender;
        
        //TODO: claculate the remaning rewards
        uint256 rewardBlockCount = 864000;  // 1200 * 24 * 30; one month = 864,000 blocks

        uint256 totalRewards0 = 4156e18; // 24,937 room Token total rewards for pool0 (Tier1)
        uint256 totalRewards1 = 5153e18; // 30,922 room Token total rewards for pool1 (Tier2)
        uint256 totalRewards2 = 6151e18; // 36,907 room Token total rewards for pool2 (Tier3)
        uint256 totalRewards3 = 7481e18; // 44,887 room Token total rewards for pool3 (Tier4)
        uint256 totalRewards4 = 10390e18; // 62,344 room Token total rewards for pool4 (Tier5)

        finishBlock = blockNumber().add(rewardBlockCount);

        _rewardPerBlock[0] = totalRewards0 * (1e18) / rewardBlockCount; // mul(1e18) for math precision
        _rewardPerBlock[1] = totalRewards1 * (1e18) / rewardBlockCount; // mul(1e18) for math precision
        _rewardPerBlock[2] = totalRewards2 * (1e18) / rewardBlockCount; // mul(1e18) for math precision
        _rewardPerBlock[3] = totalRewards3 * (1e18) / rewardBlockCount; // mul(1e18) for math precision
        _rewardPerBlock[4] = totalRewards4 * (1e18) / rewardBlockCount; // mul(1e18) for math precision

        lastUpdateBlock[0] = blockNumber();
        lastUpdateBlock[1] = blockNumber();
        lastUpdateBlock[2] = blockNumber();
        lastUpdateBlock[3] = blockNumber();
        lastUpdateBlock[4] = blockNumber();
    }

    function stake(uint256 poolId, uint256 amount) external {
        updateReward(poolId, msg.sender);

        if (amount > 0) {
            if (_nftLockedToStakeRoom[poolId][msg.sender] == false) {
                _nftLockedToStakeRoom[poolId][msg.sender] = true;
                NFTToken.safeTransferFrom(msg.sender, address(this), poolId, 1, "");
            }

            _totalStaked[poolId] = _totalStaked[poolId].add(amount);
            _balances[poolId][msg.sender] = _balances[poolId][msg.sender].add(amount);

            roomToken.transferFrom(msg.sender, address(this), amount);

            emit Staked(poolId, msg.sender, amount);
        }
    }

    function unstake(uint256 poolId, uint256 amount, bool claim) public returns(uint256 reward, TransferRewardState reason)  {
        updateReward(poolId, msg.sender);

        _totalStaked[poolId] = _totalStaked[poolId].sub(amount);
        _balances[poolId][msg.sender] = _balances[poolId][msg.sender].sub(amount);
        // Send Room token staked to the original owner.
        roomToken.transfer(msg.sender, amount);

        if (claim) {
            (reward, reason) = _executeRewardTransfer(poolId, msg.sender);
        }

        emit Unstaked(poolId, msg.sender, amount);
    }

    function exit(uint256 poolId) public nonReentrant{
        unstake(poolId, _balances[poolId][msg.sender], true);
        if (_nftLockedToStakeRoom[poolId][msg.sender]) {
            _nftLockedToStakeRoom[poolId][msg.sender] = false;
            NFTToken.safeTransferFrom(address(this), msg.sender, poolId, 1, "");
        }
    }

    function claimReward(uint256 poolId) external returns (uint256 reward, TransferRewardState reason) {
        updateReward(poolId, msg.sender);
        return _executeRewardTransfer(poolId, msg.sender);
    }

    function _executeRewardTransfer(uint256 poolId, address account) internal returns(uint256 reward, TransferRewardState reason) {
        reward = _rewards[poolId][account];
        if (reward > 0) {
            
            roomToken.transferFrom(roomTokenRewardsReservoirAddress, msg.sender, reward);
            emit ClaimReward(poolId, msg.sender, reward);
        }
    }

    function updateReward(uint256 poolId, address account) public {
        // reward algorithm
        // in general: rewards = (reward per token ber block) user balances
        uint256 cnBlock = blockNumber();

        // update accRewardPerToken, in case totalSupply is zero; do not increment accRewardPerToken
        if (_totalStaked[poolId] > 0) {

            uint256 lastRewardBlock = cnBlock < finishBlock ? cnBlock : finishBlock;
            if (lastRewardBlock > lastUpdateBlock[poolId]) {
                _accRewardPerToken[poolId] = lastRewardBlock.sub(lastUpdateBlock[poolId])
                .mul(_rewardPerBlock[poolId]).div(_totalStaked[poolId])
                .add(_accRewardPerToken[poolId]);
            }
        }

        lastUpdateBlock[poolId] = cnBlock;

        if (account != address(0)) {

            uint256 accRewardPerTokenForUser = _accRewardPerToken[poolId].sub(_prevAccRewardPerToken[poolId][account]);

            if (accRewardPerTokenForUser > 0) {
                _rewards[poolId][account] =
                _balances[poolId][account]
                .mul(accRewardPerTokenForUser)
                .div(1e18)
                .add(_rewards[poolId][account]);

                _prevAccRewardPerToken[poolId][account] = _accRewardPerToken[poolId];
            }
        }
    }

    function rewards(uint256 poolId, address account) external view returns (uint256 reward) {
        // read version of update
        uint256 cnBlock = blockNumber();
        uint256 accRewardPerToken = _accRewardPerToken[poolId];

        // update accRewardPerToken, in case totalSupply is zero; do not increment accRewardPerToken
        if (_totalStaked[poolId] > 0) {
            uint256 lastRewardBlock = cnBlock < finishBlock ? cnBlock : finishBlock;
            if (lastRewardBlock > lastUpdateBlock[poolId]) {
                accRewardPerToken = lastRewardBlock.sub(lastUpdateBlock[poolId])
                .mul(_rewardPerBlock[poolId]).div(_totalStaked[poolId])
                .add(accRewardPerToken);
            }
        }

        reward = _balances[poolId][account]
        .mul(accRewardPerToken.sub(_prevAccRewardPerToken[poolId][account]))
        .div(1e18)
        .add(_rewards[poolId][account]);
    }

    function totalStaked(uint256 poolId) public view returns (uint256){
        return _totalStaked[poolId];
    }

    function balanceOf(uint256 poolId, address account) public view returns (uint256) {
        return _balances[poolId][account];
    }


    function blockNumber() public view returns (uint256) {
        return block.number;
    }
    
    function getNftLockedToStakeRoom(uint256 id, address account) external view returns(bool){
        return _nftLockedToStakeRoom[id][account];
    }
    
    function stakeForAccount(address account, uint256 poolId, uint256 amount) internal {
        updateReward(poolId, account);

        if (amount > 0) {

            _totalStaked[poolId] = _totalStaked[poolId].add(amount);
            _balances[poolId][account] = _balances[poolId][account].add(amount);

            roomToken.transferFrom(msg.sender, address(this), amount);

            emit Staked(poolId, account, amount);
        }
    }
    
    function bulkStakeForAccount(uint256 poolId, bulkInputStructure[] memory inputArray) public{
        require(msg.sender == owner, "Only deployer can called this function");

        for(uint256 index=0; index< inputArray.length; index++){
            bulkInputStructure memory inputAccount = inputArray[index];
            _rewards[poolId][inputAccount.account] = _rewards[poolId][inputAccount.account].add(inputAccount.recoverRewards);
           stakeForAccount(inputAccount.account,poolId, inputAccount.roomStakedAmount);
       }

    }
    
    // recover any tokens send to this contract ( for emergancey, or tokens send by mistake)
    function retrieveToken(IERC20 tokenAddress, uint256 amount) public{
        require(msg.sender == owner, "Only deployer can called this function");
        if(amount == 0){
            amount = tokenAddress.balanceOf(address(this));
        }
        tokenAddress.transfer(owner, amount);
    }

}