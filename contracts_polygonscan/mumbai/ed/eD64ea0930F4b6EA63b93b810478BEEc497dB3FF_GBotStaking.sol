/**
 *Submitted for verification at polygonscan.com on 2022-01-21
*/

// File: contracts/utils/access/IERC173.sol



pragma solidity >=0.7.6 <0.8.0;

/**
 * @title ERC-173 Contract Ownership Standard
 * Note: the ERC-165 identifier for this interface is 0x7f5828d0
 */
interface IERC173 {
    /**
     * Event emited when ownership of a contract changes.
     * @param previousOwner the previous owner.
     * @param newOwner the new owner.
     */
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * Get the address of the owner
     * @return The address of the owner.
     */
    function owner() external view returns (address);

    /**
     * Set the address of the new owner of the contract
     * Set newOwner to address(0) to renounce any ownership.
     * @dev Emits an {OwnershipTransferred} event.
     * @param newOwner The address of the new owner of the contract. Using the zero address means renouncing ownership.
     */
    function transferOwnership(address newOwner) external;
}

// File: contracts/interfaces/IGBotInventory.sol



pragma solidity >=0.7.6 <0.8.0;

interface IGBotInventory {
    function mintGBot(address to, uint256 nftId, uint256 metadata, bytes memory data) external;
    function getMetadata(uint256 tokenId) external view returns (uint256 metadata);
    function upgradeGBot(uint256 tokenId, uint256 newMetadata) external;

    /**
     * Gets the balance of the specified address
     * @param owner address to query the balance of
     * @return balance uint256 representing the amount owned by the passed address
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * Gets the owner of the specified ID
     * @param tokenId uint256 ID to query the owner of
     * @return owner address currently marked as the owner of the given ID
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

        /**
     * Safely transfers the ownership of a given token ID to another address
     *
     * If the target address is a contract, it must implement `onERC721Received`,
     * which is called upon a safe transfer, and return the magic value
     * `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`; otherwise,
     * the transfer is reverted.
     *
     * @dev Requires the msg sender to be the owner, approved, or operator
     * @param from current owner of the token
     * @param to address to receive the ownership of the given token ID
     * @param tokenId uint256 ID of the token to be transferred
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
}
// File: contracts/metatx/ManagedIdentity.sol



pragma solidity >=0.7.6 <0.8.0;

/*
 * Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner.
 */
abstract contract ManagedIdentity {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        return msg.data;
    }
}
// File: contracts/utils/access/Ownable.sol



pragma solidity >=0.7.6 <0.8.0;



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
abstract contract Ownable is ManagedIdentity, IERC173 {
    address internal _owner;

    /**
     * Initializes the contract, setting the deployer as the initial owner.
     * @dev Emits an {IERC173-OwnershipTransferred(address,address)} event.
     */
    constructor(address owner_) {
        _owner = owner_;
        emit OwnershipTransferred(address(0), owner_);
    }

    /**
     * Gets the address of the current contract owner.
     */
    function owner() public view virtual override returns (address) {
        return _owner;
    }

    /**
     * See {IERC173-transferOwnership(address)}
     * @dev Reverts if the sender is not the current contract owner.
     * @param newOwner the address of the new owner. Use the zero address to renounce the ownership.
     */
    function transferOwnership(address newOwner) public virtual override {
        _requireOwnership(_msgSender());
        _owner = newOwner;
        emit OwnershipTransferred(_owner, newOwner);
    }

    /**
     * @dev Reverts if `account` is not the contract owner.
     * @param account the account to test.
     */
    function _requireOwnership(address account) internal virtual {
        require(account == this.owner(), "Ownable: not the owner");
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
}
// File: contracts/token/ERC721/IERC721Receiver.sol



pragma solidity >=0.7.6 <0.8.0;

/**
 * @title ERC721 Non-Fungible Token Standard, Tokens Receiver.
 * Interface for any contract that wants to support safeTransfers from ERC721 asset contracts.
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 * @dev Note: The ERC-165 identifier for this interface is 0x150b7a02.
 */
interface IERC721Receiver {
    /**
     * Handles the receipt of an NFT.
     * @dev The ERC721 smart contract calls this function on the recipient
     *  after a {IERC721-safeTransferFrom}. This function MUST return the function selector,
     *  otherwise the caller will revert the transaction. The selector to be
     *  returned can be obtained as `this.onERC721Received.selector`. This
     *  function MAY throw to revert and reject the transfer.
     * @dev Note: the ERC721 contract address is always the message sender.
     * @param operator The address which called `safeTransferFrom` function
     * @param from The address which previously owned the token
     * @param tokenId The NFT identifier which is being transferred
     * @param data Additional data with no specified format
     * @return bytes4 `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// File: contracts/introspection/IERC165.sol



pragma solidity >=0.7.6 <0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165.
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
// File: contracts/token/ERC721/ERC721Receiver.sol



pragma solidity >=0.7.6 <0.8.0;



/**
 * @title ERC721 Safe Transfers Receiver Contract.
 * @dev The function `onERC721Received(address,address,uint256,bytes)` needs to be implemented by a child contract.
 */
abstract contract ERC721Receiver is IERC165, IERC721Receiver {
    bytes4 internal constant _ERC721_RECEIVED = type(IERC721Receiver).interfaceId;
    bytes4 internal constant _ERC721_REJECTED = 0xffffffff;

    //======================================================= ERC165 ========================================================//

    /// @inheritdoc IERC165
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId || interfaceId == type(IERC721Receiver).interfaceId;
    }
}

// File: contracts/utils/Address.sol



pragma solidity >=0.6.2 <=0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}
// File: contracts/math/SafeMath.sol



pragma solidity >=0.6.0 <=0.8.0;

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
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
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
        return a / b;
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}
// File: contracts/game/GBotStaking/GBotStaking_V2/ERC721Stakeable.sol


pragma solidity >=0.7.6 <0.8.0;




abstract contract ERC721Stakeable is Ownable{

    using SafeMath for uint256;

    /**
    * @dev Constructor since this contract is not meant to be used without inheritance
    * push once to stakeholders for it to work proplerly
     */
    constructor(address owner) Ownable(owner) {
        // This push is needed so we avoid index 0 causing bug of index-1
        stakeholders.push();
    }

    uint256 internal _periodStarted;

    /**
    * @dev
    * The duration of the staking event, this will be initiated in days
    */
    uint256 public DURATION;

    /**
    * @dev
    * Reward points in the pool
    */
    uint256 internal _totalWeight;

    /**
    * @dev
    * Total rewards in the pool
    */
    uint256 internal _totalRewardsPool;

    /**
    * @dev
    * GBots Rarity
    */
    uint256 internal constant GBOT_RARITY_STARTER = 0;
    uint256 internal constant GBOT_RARITY_COMMON = 1;
    uint256 internal constant GBOT_RARITY_RARE = 2;
    uint256 internal constant GBOT_RARITY_EPIC = 3;
    uint256 internal constant GBOT_RARITY_LEGENDARY = 4;
    uint256 internal constant GBOT_RARITY_MYTHICAL = 5;
    uint256 internal constant GBOT_RARITY_ULTIMATE = 6;

    /**
    * @dev
    * Rarity points per rarity
    */
    uint256 internal constant RARITY_POINTS_COMMON = 1;
    uint256 internal constant RARITY_POINTS_RARE = 5;
    uint256 internal constant RARITY_POINTS_EPIC = 20;
    uint256 internal constant RARITY_POINTS_LEGENDARY = 50;
    uint256 internal constant RARITY_POINTS_MYTHICAL = 100;
    uint256 internal constant RARITY_POINTS_ULTIMATE = 0; // N/A

    /**
     * @dev
     * A stake struct is used to represent the way we store stakes, 
     * A Stake will contain the users address, the amount staked and a timestamp, 
     * Since which is when the stake was made
     */
    struct Stake{
        address user;
        uint256 tokenId;
        uint256 since;
        uint256 rarity;
    }
    /**
    * @dev Stakeholder is a staker that has active stakes
     */
    struct Stakeholder{
        address user;
        Stake[] address_stakes;
    }
    /**
    * @dev 
    *   This is an array where we store all Stakes that are performed on the Contract
    *   The stakes for each address are stored at a certain index, the index can be found using the stakes mapping
    */
    Stakeholder[] internal stakeholders;
    /**
    * @dev 
    * stakes is used to keep track of the INDEX for the stakers in the stakes array
     */
    mapping(address => uint256) internal stakes;

    /**
    * @dev 
    * unclaimedPrizes are the prizes users have accumulated over the previous periods, but haven't claimed
     */
    mapping(address => uint256) public unclaimedPrizes;

    /**
     * @dev _addStakeholder takes care of adding a stakeholder to the stakeholders array
     */
    function _addStakeholder(address staker) internal returns (uint256){
        // Push a empty item to the Array to make space for our new stakeholder
        stakeholders.push();
        // Calculate the index of the last item in the array by Len-1
        uint256 userIndex = stakeholders.length - 1;
        // Assign the address to the new index
        stakeholders[userIndex].user = staker;
        // Add index to the stakeHolders
        stakes[staker] = userIndex;
        return userIndex; 
    }

    /**
    * @dev
    * _Stake is used to make a stake for an sender. It will remove the amount staked from the stakers account and place those tokens inside a stake container
    * StakeID 
    */
    function _stake(uint256 tokenId, uint256 rarity) internal returns (uint256) {        
        // Mappings in solidity creates all values, but empty, so we can just check the address
        uint256 index = stakes[msg.sender];
        uint256 timestamp = block.timestamp;
        // See if the staker already has a staked index or if its the first time
        if(index == 0){
            // This stakeholder stakes for the first time
            // We need to add him to the stakeHolders and also map it into the Index of the stakes
            // The index returned will be the index of the stakeholder in the stakeholders array
            index = _addStakeholder(msg.sender);
        }
        // Use the index to push a new Stake
        // push a newly created Stake with the current block timestamp.
        stakeholders[index].address_stakes.push(Stake(msg.sender, tokenId, timestamp, rarity));
        // Calculate Reward Points and add to the total supply
        _totalWeight += _calculateRewardPoints(rarity);
        return index;
    }
    
    /**
      * @dev
      * calculateStakeReward is used to calculate how much a user should be rewarded for their stakes
      * and the duration the stake has been active
     */
    function calculateStakeReward(Stake memory _current_stake) internal view returns(uint256) {
        // Make sure that the timestamp calculated is until the end of the duration
        // No reward is given after
        uint256 timestamp = block.timestamp;
        if (timestamp > DURATION ){
            timestamp = DURATION;
        }
        uint256 rewardPerRarity = _calculateRewardPoints(_current_stake.rarity);
        uint256 fullReward = _totalRewardsPool.div(_totalWeight).mul(rewardPerRarity);
        uint256 rewardPerMinute = fullReward.div(((DURATION - _periodStarted) / 1 minutes));
        uint256 stakeReward = ((timestamp - _current_stake.since) / 1 minutes).mul(rewardPerMinute);

        return stakeReward;
    }

    /**
     * @dev
     * withdrawStake takes in an amount and a index of the stake and will remove tokens from that stake
     * Notice index of the stake is the users stake counter, starting at 0 for the first stake
     * Will also calculateStakeReward and reset timer
    */
    function _withdrawStake(uint256 tokenId, address owner) internal {
         // Grab user_index which is the index to use to grab the Stake[]
        uint256 user_index = stakes[owner];
        // Grab the index for the stake
        uint256 index = _getStakeIndex(owner, tokenId);
        Stake memory current_stake = stakeholders[user_index].address_stakes[index];

         // Calculate available Reward first before we start modifying data
         uint256 reward = calculateStakeReward(current_stake);

        // On completion remove the stake from the stakeholders
         delete stakeholders[user_index].address_stakes[index];
        // Remove weight from total weight
        _totalWeight -= _calculateRewardPoints(current_stake.rarity);
        unclaimedPrizes[owner] += reward;
        _totalRewardsPool -= reward;
    }

    /**
     * @dev
     * _claimAllPrizes gets the total prizes for a staker
     * It will reset the timer (since) of the stakes, but not unstake them
    */
    function _claimAllPrizes(address owner) internal returns(uint256) {
        // Get reward for this period
        uint256 periodPrize = _getTotalPrizesForPeriod(owner);
        // Get reward from previous periods, if exists
        uint256 unclaimedPrize = unclaimedPrizes[owner];

        _resetStakerTimers(owner);
        _totalRewardsPool -= periodPrize;
        unclaimedPrizes[owner] = 0;
        return periodPrize + unclaimedPrize;
    }

    /**
     * @dev
     * _claimCurrentPrizes gets the prizes for a staker, for the running period
     * It will reset the timer (since) of the stakes, but not unstake them
    */
    function _claimCurrentPrizes(address owner) internal returns(uint256) {
        // Get reward for this period
        uint256 periodPrize = _getTotalPrizesForPeriod(owner);
        _resetStakerTimers(owner);
        _totalRewardsPool -= periodPrize;
        return periodPrize;
    }
     
    /**
     * @dev
     * _saveUnclaimedPrizes saves prizes from previous periods
     * It will save the unclaimed prices for users, to use in other periods
    */
    function _saveUnclaimedPrizes() internal {
        uint256 totalStakes = stakeholders.length;
        // Loop for every user
        for (uint256 s = 0; s < totalStakes; s += 1) {
            address currentUser = stakeholders[s].user;
            // Get current rewards for user, store them and reset timers
            unclaimedPrizes[currentUser] += _claimCurrentPrizes(currentUser);
        }
    }

    /**
    * @dev
    * _getTotalPrizes gets the total prizes for a staker
    */
    function _getTotalPrizesForPeriod(address owner) internal view returns (uint256) {
        uint256 totalRewardGmee;
        // Grab user_index which is the index to use to grab the Stake[]
        uint256 user_index = stakes[owner];
        Stake[] memory existingStakes = stakeholders[user_index].address_stakes;

        for (uint256 s = 0; s < existingStakes.length; s += 1) {
            if (existingStakes[s].tokenId != 0) {
            // Add the reward to the total sum
            totalRewardGmee += calculateStakeReward(existingStakes[s]);
            }
       }
        return totalRewardGmee;
     }

    /**
    * @dev
    * _getTotalPrizes gets the total prizes for a staker
    */
    function _getTotalPrizes(address owner) internal view returns (uint256) {
        return _getTotalPrizesForPeriod(owner) + unclaimedPrizes[owner];
    }

    /**
    * @dev
    * isRightfulOwner is used to check if an account was the true owner before staking
    */
    function _isRightfulOwner(address owner, uint256 tokenId) internal view returns(bool) {
        // Get user stakes
        Stake[] memory existingStakes = stakeholders[stakes[owner]].address_stakes;
        uint256 sumStakes = existingStakes.length;
        for (uint256 s = 0; s < sumStakes; s += 1) {
            if (tokenId == existingStakes[s].tokenId) {
                return true;
            }
       }
        return false;
    }

    /**
    * @dev
    * _getStakeIndex gets the index of the stake we need to withdraw
    * @notice This function must be called after _isRightfulOwner, to check if the tokenId exists at all
    * otherwise, it will return 0
    */
    function _getStakeIndex(address owner, uint256 tokenId) internal view returns(uint256) {
        // Get user stakes
        Stake[] memory existingStakes = stakeholders[stakes[owner]].address_stakes;
        uint256 sumStakes = existingStakes.length;
        for (uint256 s = 0; s < sumStakes; s += 1) {
            if (tokenId == existingStakes[s].tokenId) {
                return s;
            }
       }
        return 0;
    }

    /**
    * @dev
    * Based on rarity, calculate Reward points for G-Bot
    *  
    */
    function _calculateRewardPoints(uint256 rarity) internal pure returns (uint256 rewardPoints) {
         if (rarity == GBOT_RARITY_COMMON) {
          return RARITY_POINTS_COMMON;
        }
        if (rarity == GBOT_RARITY_RARE) {
          return RARITY_POINTS_RARE;         
        }
        if (rarity == GBOT_RARITY_EPIC) {
          return RARITY_POINTS_EPIC;
        }
        if (rarity == GBOT_RARITY_LEGENDARY) {
          return RARITY_POINTS_LEGENDARY;
        }
        if (rarity == GBOT_RARITY_MYTHICAL) {
          return RARITY_POINTS_MYTHICAL;
        }
        if (rarity == GBOT_RARITY_ULTIMATE) {
          return RARITY_POINTS_ULTIMATE;
        }
    }

    /**
    * @dev
    * _resetStakerTimers resets timers after a prize claim
    */
    function _resetStakerTimers(address owner) internal {
        // Grab user_index which is the index to use to grab the Stake[]
        uint256 user_index = stakes[owner];
        Stake[] memory existingStakes = stakeholders[user_index].address_stakes;

        for (uint256 s = 0; s < existingStakes.length; s += 1) {
         // Reset timer of stakes
        stakeholders[user_index].address_stakes[s].since = block.timestamp;   
       }
    }

    function _ownerTokenIds(address owner) internal view returns(uint256[] memory) {
        // Keep a summary in memory since we need to calculate this
        Stake[] memory existingStakes = stakeholders[stakes[owner]].address_stakes;
        uint256[] memory tokenIds = new uint256[](existingStakes.length);

        for (uint256 s = 0; s < existingStakes.length; s += 1) {
            tokenIds[s] = (existingStakes[s].tokenId);
       }
        return tokenIds;
    }

    function _ownerTotalWeight(address owner) internal view returns(uint256) {
        uint256 ownerWeight;
        Stake[] memory existingStakes = stakeholders[stakes[owner]].address_stakes;

        for (uint256 s = 0; s < existingStakes.length; s += 1) {
            ownerWeight += _calculateRewardPoints(existingStakes[s].rarity);
       }
        return ownerWeight;
    }

    modifier stakingNotFinished() {
        require(block.timestamp < DURATION, "ERC721Stakeable: Event is finished");
        _;
    }

    modifier stakingFinished() {
        require(block.timestamp > DURATION, "ERC721Stakeable: Event is not finished");
        _;
    }

}
// File: contracts/token/ERC20/IERC20.sol



pragma solidity >=0.7.6 <0.8.0;

/**
 * @title ERC20 Token Standard, basic interface.
 * @dev See https://eips.ethereum.org/EIPS/eip-20
 * @dev Note: The ERC-165 identifier for this interface is 0x36372b07.
 */
interface IERC20 {
    /**
     * @dev Emitted when tokens are transferred, including zero value transfers.
     * @param _from The account where the transferred tokens are withdrawn from.
     * @param _to The account where the transferred tokens are deposited to.
     * @param _value The amount of tokens being transferred.
     */
    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    /**
     * @dev Emitted when a successful call to {IERC20-approve(address,uint256)} is made.
     * @param _owner The account granting an allowance to `_spender`.
     * @param _spender The account being granted an allowance from `_owner`.
     * @param _value The allowance amount being granted.
     */
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    /**
     * @notice Returns the total token supply.
     * @return The total token supply.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @notice Returns the account balance of another account with address `owner`.
     * @param owner The account whose balance will be returned.
     * @return The account balance of another account with address `owner`.
     */
    function balanceOf(address owner) external view returns (uint256);

    /**
     * Transfers `value` amount of tokens to address `to`.
     * @dev Reverts if `to` is the zero address.
     * @dev Reverts if the sender does not have enough balance.
     * @dev Emits an {IERC20-Transfer} event.
     * @dev Transfers of 0 values are treated as normal transfers and fire the {IERC20-Transfer} event.
     * @param to The receiver account.
     * @param value The amount of tokens to transfer.
     * @return True if the transfer succeeds, false otherwise.
     */
    function transfer(address to, uint256 value) external returns (bool);

    /**
     * @notice Transfers `value` amount of tokens from address `from` to address `to`.
     * @dev Reverts if `to` is the zero address.
     * @dev Reverts if `from` does not have at least `value` of balance.
     * @dev Reverts if the sender is not `from` and has not been approved by `from` for at least `value`.
     * @dev Emits an {IERC20-Transfer} event.
     * @dev Transfers of 0 values are treated as normal transfers and fire the {IERC20-Transfer} event.
     * @param from The emitter account.
     * @param to The receiver account.
     * @param value The amount of tokens to transfer.
     * @return True if the transfer succeeds, false otherwise.
     */
    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    /**
     * Sets `value` as the allowance from the caller to `spender`.
     *  IMPORTANT: Beware that changing an allowance with this method brings the risk
     *  that someone may use both the old and the new allowance by unfortunate
     *  transaction ordering. One possible solution to mitigate this race
     *  condition is to first reduce the spender's allowance to 0 and set the
     *  desired value afterwards: https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     * @dev Reverts if `spender` is the zero address.
     * @dev Emits the {IERC20-Approval} event.
     * @param spender The account being granted the allowance by the message caller.
     * @param value The allowance amount to grant.
     * @return True if the approval succeeds, false otherwise.
     */
    function approve(address spender, uint256 value) external returns (bool);

    /**
     * Returns the amount which `spender` is allowed to spend on behalf of `owner`.
     * @param owner The account that has granted an allowance to `spender`.
     * @param spender The account that was granted an allowance by `owner`.
     * @return The amount which `spender` is allowed to spend on behalf of `owner`.
     */
    function allowance(address owner, address spender) external view returns (uint256);
}

// File: contracts/token/ERC20/SafeERC20.sol



pragma solidity >=0.6.0 <=0.8.0;




/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}
// File: contracts/game/GBotStaking/GBotStaking_V2/GBotStaking_V2.sol



pragma solidity >=0.7.6 <0.8.0;






contract GBotStaking is ERC721Receiver, ERC721Stakeable {

    using SafeERC20 for IERC20;

    IERC20 public immutable rewardToken;
    IGBotInventory private GBotContract;

    event GBotStaked(address indexed user, uint256 tokenId, uint256 index);
    event GBotWithdrawn(address indexed user, uint256 tokenId);
    event EventFinished(uint256 totalStakes, uint256 totalReward);

    constructor (
        address gBotInventory_,
        address rewardToken_ ) 
        ERC721Stakeable(msg.sender) {
        require(rewardToken_ != address(0), "GBot Staking: Reward token not set");
        require(gBotInventory_ != address(0), "GBot Staking: GBot inventory not set");
        rewardToken = IERC20(rewardToken_);
        GBotContract = IGBotInventory(gBotInventory_);
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }


    // stake
    function stake(uint256 tokenId) stakingNotFinished public {
        // Check if token is not allready staked
        require(_isRightfulOwner(_msgSender(), tokenId) == false, "ERC721Stakeable: Token already staked!");
        
        // Check owner
        address owner = GBotContract.ownerOf(tokenId);
        require(owner==_msgSender(), "GBot Staking: Not the rightful owner");

        // Get metadata
        uint256 metadata = GBotContract.getMetadata(tokenId);

        // Get rarity
        uint256 rarity = getRarity(metadata);
        // Gbot cannot be starter
        require(rarity != GBOT_RARITY_STARTER, "GBot Staking: Cannot stake STARTER GBot");

        // Transfer the GBot to the Staker
        GBotContract.safeTransferFrom(_msgSender(), address(this), tokenId);

        // Stake the token
        uint256 index =_stake(tokenId, rarity);

        emit GBotStaked(_msgSender(), tokenId, index);
    }

    // claim prize
    function claimPrizes() public {        
        // Get reward for owner
        uint256 reward = _claimAllPrizes(_msgSender());
                
        // Transfer GMEE reward to user
        rewardToken.safeTransfer(_msgSender(), reward);
    }

    // withdraw
    function withdraw(uint256 tokenId) public {        
        // Check is user rightful owner
        require(_isRightfulOwner(_msgSender(), tokenId), "ERC721Stakeable: Not rightful owner");

        // withdraw stake
        _withdrawStake(tokenId, _msgSender());

        // Transfer the GBot to the user
        GBotContract.safeTransferFrom(address(this), _msgSender(), tokenId);

        emit GBotWithdrawn(_msgSender(), tokenId);
    }

    // withdraw all
    function withdrawAll() virtual public {
    uint256[] memory currentTokens = _ownerTokenIds(_msgSender());
    
    // Loop through every stake the current user has
    for (uint256 i = 0; i < currentTokens.length; i += 1) {
                // Make sure the token is not withdrawed
                if (currentTokens[i] != 0){
                    // Withdraw stake with current index
                    _withdrawStake(currentTokens[i], _msgSender());
                    // Transfer GBot back to user
                    GBotContract.safeTransferFrom(address(this), _msgSender(), currentTokens[i]);
                }
    }
    // Claim all prizes for user
    claimPrizes();
    }

    //================================== PUBLIC FUNCTIONS ==================================//
    function ownerTotalPrize() virtual public view returns (uint256) {
        return _getTotalPrizes(_msgSender());
    }

    function ownerStakedNfts() virtual public view returns (uint256[] memory) {
        return _ownerTokenIds(_msgSender());
    }

    function ownerTotalWeight() virtual public view returns (uint256) {
        return _ownerTotalWeight(_msgSender());
    } 

    function totalWeight() public view returns (uint256) {
        return _totalWeight;
    }

    function totalRewardsPool() public view returns (uint256) {
        return _totalRewardsPool;
    }
 
    //================================== OWNER ONLY FUNCTIONS ==================================//
   
    /**
     * Actvates, or 'starts' another period of staking 
     * @notice to be called after the amount of reward tokens is sent to the contract
     * @param duration The duration of the contract (in minutes)
     * @dev Reverts if called by any other than the contract owner.
     * @dev Reverts if amount specified is not allready in the contract
     */
    function confirmPoolAndStart(uint256 amount, uint256 duration) external {
        _requireOwnership(_msgSender());
        _saveUnclaimedPrizes();
        uint256 balance = rewardToken.balanceOf(address(this));
        require (amount <= balance, "GBotStaking: Not enough balance to confirm");
        DURATION = block.timestamp + (duration * 1 minutes);
       _totalRewardsPool = amount;
       _periodStarted = block.timestamp;
    }

    function finishEvent() external stakingFinished {
        uint256 totalRewardGmee;
        _requireOwnership(_msgSender());
        uint256 totalStakes = stakeholders.length;
        // Loop for every user
        for (uint256 s = 0; s < totalStakes; s += 1) {
            address currentUser = stakeholders[s].user;
            // Get current tokenIds for user
            uint256[] memory currentTokens = _ownerTokenIds(currentUser);

            // Loop through every stake the current user has
            for (uint256 i = 0; i < currentTokens.length; i += 1) {
                // Make sure the token is not withdrawed
                if (currentTokens[i] != 0){
                    // Withdraw stake with current index
                    _withdrawStake(i, currentUser);
                    // Transfer GBot back to user
                    GBotContract.safeTransferFrom(address(this), currentUser, currentTokens[i]);
                }
            }

            // Get reward for owner
            uint256 reward = _claimAllPrizes(currentUser);        
            // Transfer GMEE reward to user
            rewardToken.safeTransfer(_msgSender(), reward);
        }
        emit EventFinished(totalStakes, totalRewardGmee);
    }

    //================================== HELPER FUNCTIONS ==================================//


    function getRarity(uint256 metadataId) private pure returns (uint256) {
        uint bits = 8;
        uint256 RARITY_BITS = 223;
        uint256 ONES = uint(~0);
        return metadataId >> RARITY_BITS & ONES >> 256 - bits;
    }

}