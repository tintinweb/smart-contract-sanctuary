/**
 *Submitted for verification at BscScan.com on 2021-07-08
*/

/**
 *Submitted for verification at Etherscan.io on 2020-11-17
*/

pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;


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
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
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
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
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
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

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
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

/**
 * @title Roles
 * @dev Library for managing addresses assigned to a Role.
 */
library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

    /**
     * @dev Give an account access to this role.
     */
    function add(Role storage role, address account) internal {
        require(!has(role, account), "Roles: account already has role");
        role.bearer[account] = true;
    }

    /**
     * @dev Remove an account's access to this role.
     */
    function remove(Role storage role, address account) internal {
        require(has(role, account), "Roles: account does not have role");
        role.bearer[account] = false;
    }

    /**
     * @dev Check if an account has this role.
     * @return bool
     */
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0), "Roles: account is the zero address");
        return role.bearer[account];
    }
}

contract OperatorRole is Context {
    using Roles for Roles.Role;

    event OperatorAdded(address indexed account);
    event OperatorRemoved(address indexed account);

    Roles.Role private _operators;

    constructor () internal {

    }

    modifier onlyOperator() {
        require(isOperator(_msgSender()), "OperatorRole: caller does not have the Operator role");
        _;
    }

    function isOperator(address account) public view returns (bool) {
        return _operators.has(account);
    }

    function _addOperator(address account) internal {
        _operators.add(account);
        emit OperatorAdded(account);
    }

    function _removeOperator(address account) internal {
        _operators.remove(account);
        emit OperatorRemoved(account);
    }
}

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
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
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract OwnableOperatorRole is Ownable, OperatorRole {
    function addOperator(address account) external onlyOwner {
        _addOperator(account);
    }

    function removeOperator(address account) external onlyOwner {
        _removeOperator(account);
    }
}

/**
    @title ERC-1155 Multi Token Standard
    @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-1155.md
    Note: The ERC-165 identifier for this interface is 0xd9b67a26.
 */
contract IERC1155 /*is IERC165*/ {
    struct Fee {
        address _address;
        uint256 _percentage;
    }
    /**
        @dev Either `TransferSingle` or `TransferBatch` MUST emit when tokens are transferred, including zero value transfers as well as minting or burning (see "Safe Transfer Rules" section of the standard).
        The `_operator` argument MUST be msg.sender.
        The `_from` argument MUST be the address of the holder whose balance is decreased.
        The `_to` argument MUST be the address of the recipient whose balance is increased.
        The `_id` argument MUST be the token type being transferred.
        The `_value` argument MUST be the number of tokens the holder balance is decreased by and match what the recipient balance is increased by.
        When minting/creating tokens, the `_from` argument MUST be set to `0x0` (i.e. zero address).
        When burning/destroying tokens, the `_to` argument MUST be set to `0x0` (i.e. zero address).
    */
    event TransferSingle(address indexed _operator, address indexed _from, address indexed _to, uint256 _id, uint256 _value);

    /**
        @dev Either `TransferSingle` or `TransferBatch` MUST emit when tokens are transferred, including zero value transfers as well as minting or burning (see "Safe Transfer Rules" section of the standard).
        The `_operator` argument MUST be msg.sender.
        The `_from` argument MUST be the address of the holder whose balance is decreased.
        The `_to` argument MUST be the address of the recipient whose balance is increased.
        The `_ids` argument MUST be the list of tokens being transferred.
        The `_values` argument MUST be the list of number of tokens (matching the list and order of tokens specified in _ids) the holder balance is decreased by and match what the recipient balance is increased by.
        When minting/creating tokens, the `_from` argument MUST be set to `0x0` (i.e. zero address).
        When burning/destroying tokens, the `_to` argument MUST be set to `0x0` (i.e. zero address).
    */
    event TransferBatch(address indexed _operator, address indexed _from, address indexed _to, uint256[] _ids, uint256[] _values);

    /**
        @dev MUST emit when approval for a second party/operator address to manage all tokens for an owner address is enabled or disabled (absense of an event assumes disabled).
    */
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    /**
        @dev MUST emit when the URI is updated for a token ID.
        URIs are defined in RFC 3986.
        The URI MUST point a JSON file that conforms to the "ERC-1155 Metadata URI JSON Schema".
    */
    event URI(string _value, uint256 indexed _id);

    /**
        @notice Transfers `_value` amount of an `_id` from the `_from` address to the `_to` address specified (with safety call).
        @dev Caller must be approved to manage the tokens being transferred out of the `_from` account (see "Approval" section of the standard).
        MUST revert if `_to` is the zero address.
        MUST revert if balance of holder for token `_id` is lower than the `_value` sent.
        MUST revert on any other error.
        MUST emit the `TransferSingle` event to reflect the balance change (see "Safe Transfer Rules" section of the standard).
        After the above conditions are met, this function MUST check if `_to` is a smart contract (e.g. code size > 0). If so, it MUST call `onERC1155Received` on `_to` and act appropriately (see "Safe Transfer Rules" section of the standard).
        @param _from    Source address
        @param _to      Target address
        @param _id      ID of the token type
        @param _value   Transfer amount
        @param _data    Additional data with no specified format, MUST be sent unaltered in call to `onERC1155Received` on `_to`
    */
    function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _value, bytes calldata _data) external;

    /**
        @notice Transfers `_values` amount(s) of `_ids` from the `_from` address to the `_to` address specified (with safety call).
        @dev Caller must be approved to manage the tokens being transferred out of the `_from` account (see "Approval" section of the standard).
        MUST revert if `_to` is the zero address.
        MUST revert if length of `_ids` is not the same as length of `_values`.
        MUST revert if any of the balance(s) of the holder(s) for token(s) in `_ids` is lower than the respective amount(s) in `_values` sent to the recipient.
        MUST revert on any other error.
        MUST emit `TransferSingle` or `TransferBatch` event(s) such that all the balance changes are reflected (see "Safe Transfer Rules" section of the standard).
        Balance changes and events MUST follow the ordering of the arrays (_ids[0]/_values[0] before _ids[1]/_values[1], etc).
        After the above conditions for the transfer(s) in the batch are met, this function MUST check if `_to` is a smart contract (e.g. code size > 0). If so, it MUST call the relevant `ERC1155TokenReceiver` hook(s) on `_to` and act appropriately (see "Safe Transfer Rules" section of the standard).
        @param _from    Source address
        @param _to      Target address
        @param _ids     IDs of each token type (order and length must match _values array)
        @param _values  Transfer amounts per token type (order and length must match _ids array)
        @param _data    Additional data with no specified format, MUST be sent unaltered in call to the `ERC1155TokenReceiver` hook(s) on `_to`
    */
    function safeBatchTransferFrom(address _from, address _to, uint256[] calldata _ids, uint256[] calldata _values, bytes calldata _data) external;

    /**
        @notice Get the balance of an account's Tokens.
        @param _owner  The address of the token holder
        @param _id     ID of the Token
        @return        The _owner's balance of the Token type requested
     */
    function balanceOf(address _owner, uint256 _id) external view returns (uint256);

    /**
        @notice Get the balance of multiple account/token pairs
        @param _owners The addresses of the token holders
        @param _ids    ID of the Tokens
        @return        The _owner's balance of the Token types requested (i.e. balance for each (owner, id) pair)
     */
    function balanceOfBatch(address[] calldata _owners, uint256[] calldata _ids) external view returns (uint256[] memory);

    /**
        @notice Enable or disable approval for a third party ("operator") to manage all of the caller's tokens.
        @dev MUST emit the ApprovalForAll event on success.
        @param _operator  Address to add to the set of authorized operators
        @param _approved  True if the operator is approved, false to revoke approval
    */
    function setApprovalForAll(address _operator, bool _approved) external;

    /**
        @notice Queries the approval status of an operator for a given owner.
        @param _owner     The owner of the Tokens
        @param _operator  Address of authorized operator
        @return           True if the operator is approved, false if not
    */
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
    
    function approve(uint256 id, uint256 count, address _operator) external;
    
    function freeze(uint256 id, uint256 count, address _operator) external;
    
    function isApproved(address owner, uint256 id, uint256 count, address _operator) external returns (bool);
    
    function getCopyrightFeeDistribution(uint256 id) public returns (Fee[] memory);
    
    function _getCopyRightFee(uint256 id) external returns (uint256);
}



/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
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

contract ERC20TransferProxy is OwnableOperatorRole {

    function erc20safeTransferFrom(IERC20 token, address from, address to, uint256 value) external onlyOperator {
        require(token.transferFrom(from, to, value), "failure while transferring");
    }
}

contract ExchangeV1 is Ownable {
    using SafeMath for uint;
    // using UintLibrary for uint;
    // using StringLibrary for string;
    // using BytesLibrary for bytes32;
    
    struct DistributionItem {
        address _address;
        uint256 _amount;
    }

    ERC20TransferProxy public erc20TransferProxy;
    
    mapping (uint256 => mapping(uint256 => uint256)) public buyERC1155Order;        // [token_id][count][amount]
    mapping (uint256 => mapping(uint256 => address)) public auctionERC1155Order;    // [token_id][count][asset_id];
    mapping (uint256 => mapping(uint256 => mapping(address => mapping(address => uint256)))) public bidERC1155Order;    // [token_id][count][bidder][asset_id][amount];
    mapping (uint256 => mapping(uint256 => address[])) public bidERC1155Members;    // [token_id][count][bidders[]]
    
    uint256 public listingFee = 15 * 10** 15;
    uint256 public serviceFee = 25; // 25 / 1000 => 2.5%
    
    address payable public serviceAddress;
    address public erc1155Address;

    constructor(
        address _erc1155Address, ERC20TransferProxy _erc20TransferProxy
    ) public {
        erc1155Address = _erc1155Address;
        erc20TransferProxy = _erc20TransferProxy;
        
        serviceAddress = _msgSender();
    }
    
    function BuyERC1155Request(uint256 id, uint256 count, uint256 amount) public payable {
        require(IERC1155(erc1155Address).isApproved(_msgSender(), id, count, address(this)) == true, "Not approved yet.");
        require(IERC1155(erc1155Address).balanceOf(_msgSender(), id) >= count, "Only owner can request.");
        
        require(msg.value == listingFee, "Incorrect listing fee.");
        
        buyERC1155Order[id][count] = amount;
    }
    
    function AuctionERC1155Request(uint256 id, uint256 count, address buytoken) public payable {
        require(IERC1155(erc1155Address).isApproved(_msgSender(), id, count, address(this)) == true, "Not approved yet.");
        require(IERC1155(erc1155Address).balanceOf(_msgSender(), id) >= count, "Only owner can request.");
        
        require(msg.value == listingFee, "Incorrect listing fee.");
        
        auctionERC1155Order[id][count] = buytoken;
    }
    
    function CancelBuyERC1155Request(uint256 id, uint256 count, uint256 amount) public {
        require(IERC1155(erc1155Address).isApproved(_msgSender(), id, count, address(this)) == true, "Not approved yet.");
        require(IERC1155(erc1155Address).balanceOf(_msgSender(), id) >= count, "Only owner can request.");
        buyERC1155Order[id][count] = 0;
    }
    
    function validateBuyERC1155Request(uint256 id, uint256 count, uint256 amount) internal {
        require(buyERC1155Order[id][count] == amount, "Amount is incorrect.");
    }
    
    function BidERC1155Request(uint256 id, uint256 count, address buyToken, uint256 amount) public {
        require(IERC20(buyToken).allowance(msg.sender, address(erc20TransferProxy)) >= amount, "Not allowed yet.");
        require(auctionERC1155Order[id][count] == buyToken, "Not acceptable asset.");
        
        bidERC1155Order[id][count][msg.sender][buyToken] = amount;
        bidERC1155Members[id][count].push(msg.sender);
    }
    
    function validateBidERC1155Request(uint256 id, uint256 count, address buyer, address buyToken, uint256 amount) internal {
        require(bidERC1155Order[id][count][buyer][buyToken] == amount, "Amount is incorrect.");
    }
    
    function CancelERC1155Bid(uint256 id, uint256 count, address buyToken) public {
        bidERC1155Order[id][count][msg.sender][buyToken] = 0;
        for (uint256 i  = 0; i < bidERC1155Members[id][count].length; i++) {
            if (bidERC1155Members[id][count][i] == msg.sender) {
                bidERC1155Members[id][count][i] = bidERC1155Members[id][count][bidERC1155Members[id][count].length - 1];
                bidERC1155Members[id][count].pop();
                break;
            }
        }
    }
    
    function CancelAllERC1155Bid(uint256 id, uint256 count, address buyToken) internal {
        while (bidERC1155Members[id][count].length != 0) {
            address member = bidERC1155Members[id][count][bidERC1155Members[id][count].length - 1];
            bidERC1155Order[id][count][member][buyToken] = 0;
            bidERC1155Members[id][count].pop();
        }
    }
    
    function CancelAuctionERC1155Requests(uint256 id, uint256 count, address buyToken) public {
        require(IERC1155(erc1155Address).isApproved(_msgSender(), id, count, address(this)) == true, "Not approved yet.");
        require(IERC1155(erc1155Address).balanceOf(_msgSender(), id) >= count, "Only owner can request.");
        
        CancelAllERC1155Bid(id, count, buyToken);
        auctionERC1155Order[id][count] = address(0);
    }
    
    function setListingFee(uint256 fee) public onlyOwner {
        listingFee = fee;
    }
    
    function setERC1155ContractAddress(address contractAddress) public onlyOwner {
        erc1155Address = contractAddress;
    }
    
    function exchangeERC1155(
        uint256 id, uint256 count,
        address owner,
        address buyToken, uint256 buyValue,
        address buyer
    ) payable external {
        require(owner == _msgSender(), "Exchange: The only token owner can accept bid.");
        
        validateBidERC1155Request(id, count, buyer, buyToken, buyValue);
        
        uint256 serviceFeeAmount = buyValue.mul(serviceFee).div(1000);
        uint256 amount = buyValue - serviceFeeAmount;
        
        IERC1155.Fee[] memory fees = IERC1155(erc1155Address).getCopyrightFeeDistribution(id);
        
        uint256 feePercentage = IERC1155(erc1155Address)._getCopyRightFee(id);
        
        if (feePercentage == 0) {
            IERC1155(erc1155Address).safeTransferFrom(owner, buyer, id, count, new bytes(0x0));
            erc20TransferProxy.erc20safeTransferFrom(IERC20(buyToken), buyer, owner, amount);
        } else {
            DistributionItem[] memory distributions = getERC1155Distributions(id, owner, fees, feePercentage, amount);
            
            IERC1155(erc1155Address).safeTransferFrom(owner, buyer, id, count, new bytes(0x0));
            for (uint256 i = 0; i < distributions.length; i++) {
                if (distributions[i]._amount > 0) {
                    erc20TransferProxy.erc20safeTransferFrom(IERC20(buyToken), buyer, distributions[i]._address, distributions[i]._amount);
                }
            }
        }
        
        if (serviceFeeAmount > 0) {
            erc20TransferProxy.erc20safeTransferFrom(IERC20(buyToken), buyer, serviceAddress, serviceFeeAmount);
        }
        
        CancelAllERC1155Bid(id, count, buyToken);
        
        auctionERC1155Order[id][count] = address(0);
    }
    
    function getERC1155Distributions(uint256 id, address owner, IERC1155.Fee[] memory fees, uint256 feePercentage, uint256 amount) internal returns (DistributionItem[] memory) {
        
        DistributionItem[] memory distributions = new DistributionItem[](fees.length + 1);
            
        uint256 feeAmount = amount.mul(feePercentage).div(100);
        
        uint256 total = 0;
        for (uint256 i = 0; i < fees.length; i++) {
            total += fees[i]._percentage;
        }
        
        for (uint256 i = 0; i < fees.length; i++) {
            uint256 distributionAmount = feeAmount * fees[i]._percentage / total;

            distributions[i] = DistributionItem(fees[i]._address, distributionAmount);
        }
        
        distributions[fees.length] = DistributionItem(owner, amount - feeAmount);
        
        return distributions;
    }
    
    function buyERC1155(
        uint256 id, uint256 count,
        address owner,
        uint256 buyValue,
        address buyer
    ) payable external {
        validateBuyERC1155Request(id, count, buyValue);
        
        uint256 serviceFeeAmount = buyValue.mul(serviceFee).div(1000);
        uint256 amount = buyValue - serviceFeeAmount;
        
        IERC1155.Fee[] memory fees = IERC1155(erc1155Address).getCopyrightFeeDistribution(id);
        
        uint256 feePercentage = IERC1155(erc1155Address)._getCopyRightFee(id);
        
        if (feePercentage == 0) {
            IERC1155(erc1155Address).safeTransferFrom(owner, buyer, id, count, new bytes(0));
            address payable to_address = address(uint160(owner));
            to_address.send(amount);
        } else {
            DistributionItem[] memory distributions = getERC1155Distributions(id, owner, fees, feePercentage, amount);
            
            IERC1155(erc1155Address).safeTransferFrom(owner, buyer, id, count, new bytes(0));
            for (uint256 i = 0; i < distributions.length; i++) {
                if (distributions[i]._amount > 0) {
                    address payable to_address = address(uint160(distributions[i]._address));
                    to_address.transfer(distributions[i]._amount);
                }
            }
        }
        
        if (serviceFeeAmount > 0) {
            serviceAddress.transfer(serviceFeeAmount);
        }
        
        buyERC1155Order[id][count] = 0;
    }
}