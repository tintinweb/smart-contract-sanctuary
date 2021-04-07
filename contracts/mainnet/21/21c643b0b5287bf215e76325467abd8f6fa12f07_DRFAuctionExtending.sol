/**
 *Submitted for verification at Etherscan.io on 2021-04-07
*/

pragma solidity ^0.5.12;


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
 *
 * _Since v2.5.0:_ this module is now much more gas efficient, given net gas
 * metering changes introduced in the Istanbul hardfork.
 */
contract ReentrancyGuard {
    bool private _notEntered;

    constructor () internal {
        // Storing an initial non-zero value makes deployment a bit more
        // expensive, but in exchange the refund on every call to nonReentrant
        // will be lower in amount. Since refunds are capped to a percetange of
        // the total transaction's gas, it is best to keep them low in cases
        // like this one, to increase the likelihood of the full refund coming
        // into effect.
        _notEntered = true;
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
        require(_notEntered, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _notEntered = false;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _notEntered = true;
    }
}

/**
 * @title ERC165
 * @dev https://github.com/ethereum/EIPs/blob/master/EIPS/eip-165.md
 */
interface IERC165 {

    /**
     * @notice Query if a contract implements an interface
     * @dev Interface identification is specified in ERC-165. This function
     * uses less than 30,000 gas
     * @param _interfaceId The interface identifier, as specified in ERC-165
     */
    function supportsInterface(bytes4 _interfaceId)
    external
    view
    returns (bool);
}

/**
 * @dev ERC-1155 interface for accepting safe transfers.
 */
interface IERC1155TokenReceiver {

    /**
     * @notice Handle the receipt of a single ERC1155 token type
     * @dev An ERC1155-compliant smart contract MUST call this function on the token recipient contract, at the end of a `safeTransferFrom` after the balance has been updated
     * This function MAY throw to revert and reject the transfer
     * Return of other amount than the magic value MUST result in the transaction being reverted
     * Note: The token contract address is always the message sender
     * @param _operator  The address which called the `safeTransferFrom` function
     * @param _from      The address which previously owned the token
     * @param _id        The id of the token being transferred
     * @param _amount    The amount of tokens being transferred
     * @param _data      Additional data with no specified format
     * @return           `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     */
    function onERC1155Received(address _operator, address _from, uint256 _id, uint256 _amount, bytes calldata _data) external returns(bytes4);

    /**
     * @notice Handle the receipt of multiple ERC1155 token types
     * @dev An ERC1155-compliant smart contract MUST call this function on the token recipient contract, at the end of a `safeBatchTransferFrom` after the balances have been updated
     * This function MAY throw to revert and reject the transfer
     * Return of other amount than the magic value WILL result in the transaction being reverted
     * Note: The token contract address is always the message sender
     * @param _operator  The address which called the `safeBatchTransferFrom` function
     * @param _from      The address which previously owned the token
     * @param _ids       An array containing ids of each token being transferred
     * @param _amounts   An array containing amounts of each token being transferred
     * @param _data      Additional data with no specified format
     * @return           `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     */
    function onERC1155BatchReceived(address _operator, address _from, uint256[] calldata _ids, uint256[] calldata _amounts, bytes calldata _data) external returns(bytes4);

    /**
     * @notice Indicates whether a contract implements the `ERC1155TokenReceiver` functions and so can accept ERC1155 token types.
     * @param  interfaceID The ERC-165 interface ID that is queried for support.s
     * @dev This function MUST return true if it implements the ERC1155TokenReceiver interface and ERC-165 interface.
     *      This function MUST NOT consume more than 5,000 gas.
     * @return Wheter ERC-165 or ERC1155TokenReceiver interfaces are supported.
     */
    function supportsInterface(bytes4 interfaceID) external view returns (bool);

}

contract DRFTokenWrapper {
    using SafeMath for uint256;
    IERC20 public drf;

    constructor(address _drfAddress) public {
        drf = IERC20(_drfAddress);
    }

    uint256 private _totalSupply;
    // Objects balances [id][address] => balance
    mapping(uint256 => mapping(address => uint256)) internal _balances;
    mapping(uint256 => uint256) private _totalDeposits;

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function totalDeposits(uint256 id) public view returns (uint256) {
        return _totalDeposits[id];
    }

    function balanceOf(address account, uint256 id) public view returns (uint256) {
        return _balances[id][account];
    }

    function bid(uint256 id, uint256 amount) public {
        _totalSupply = _totalSupply.add(amount);
        _totalDeposits[id] = _totalDeposits[id].add(amount);
        _balances[id][msg.sender] = _balances[id][msg.sender].add(amount);
        drf.transferFrom(msg.sender, address(this), amount);
    }

    function withdraw(uint256 id) public {
        uint256 amount = balanceOf(msg.sender, id);
        _totalSupply = _totalSupply.sub(amount);
        _totalDeposits[id] = _totalDeposits[id].sub(amount);
        _balances[id][msg.sender] = _balances[id][msg.sender].sub(amount);
        drf.transfer(msg.sender, amount);
    }

    function _emergencyWithdraw(address account, uint256 id) internal {
        uint256 amount = _balances[id][account];

        _totalSupply = _totalSupply.sub(amount);
        _totalDeposits[id] = _totalDeposits[id].sub(amount);
        _balances[id][account] = _balances[id][account].sub(amount);
        drf.transfer(account, amount);
    }

    function _end(
        uint256 id,
        address highestBidder,
        address beneficiary,
        address runner,
        uint256 fee,
        uint256 amount
    ) internal {
        uint256 accountDeposits = _balances[id][highestBidder];
        require(accountDeposits == amount);

        _totalSupply = _totalSupply.sub(amount);
        uint256 drfFee = (amount.mul(fee)).div(100);

        _totalDeposits[id] = _totalDeposits[id].sub(amount);
        _balances[id][highestBidder] = _balances[id][highestBidder].sub(amount);
        drf.transfer(beneficiary, amount.sub(drfFee));
        drf.transfer(runner, drfFee);
    }
}

interface IERC1155 {
    function create(
        uint256 _maxSupply,
        uint256 _initialSupply,
        string calldata _uri,
        bytes calldata _data
    ) external returns (uint256 tokenId);

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _id,
        uint256 _amount,
        bytes calldata _data
    ) external;

    function safeBatchTransferFrom(
        address _from,
        address _to,
        uint256[] calldata _ids,
        uint256[] calldata _amounts,
        bytes calldata _data
    ) external;

    function balanceOf(address _owner, uint256 _id) external view returns (uint256);

    function balanceOfBatch(address[] calldata _owners, uint256[] calldata _ids)
    external
    view
    returns (uint256[] memory);

    function setApprovalForAll(address _operator, bool _approved) external;

    function isApprovedForAll(address _owner, address _operator) external view returns (bool isOperator);

    event TransferSingle(
        address indexed _operator,
        address indexed _from,
        address indexed _to,
        uint256 _id,
        uint256 _amount
    );

    event TransferBatch(
        address indexed _operator,
        address indexed _from,
        address indexed _to,
        uint256[] _ids,
        uint256[] _amounts
    );

    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    event URI(string _amount, uint256 indexed _id);
}

contract DRFAuctionExtending is Ownable, ReentrancyGuard, DRFTokenWrapper, IERC1155TokenReceiver {
    using SafeMath for uint256;

    address public drfLtdAddress;
    address public runner;

    // info about a particular auction
    struct AuctionInfo {
        address beneficiary;
        uint256 fee;
        uint256 auctionStart;
        uint256 auctionEnd;
        uint256 originalAuctionEnd;
        uint256 extension;
        uint256 nft;
        address highestBidder;
        uint256 highestBid;
        bool auctionEnded;
    }

    mapping(uint256 => AuctionInfo) public auctionsById;
    uint256[] public auctions;

    // Events that will be fired on changes.
    event BidPlaced(address indexed user, uint256 indexed id, uint256 amount);
    event Withdrawn(address indexed user, uint256 indexed id, uint256 amount);
    event Ended(address indexed user, uint256 indexed id, uint256 amount);

    constructor(
        address _runner,
        address _drfAddress,
        address _drfLtdAddress
    ) public DRFTokenWrapper(_drfAddress) {
        runner = _runner;
        drfLtdAddress = _drfLtdAddress;
    }

    function auctionStart(uint256 id) public view returns (uint256) {
        return auctionsById[id].auctionStart;
    }

    function beneficiary(uint256 id) public view returns (address) {
        return auctionsById[id].beneficiary;
    }

    function auctionEnd(uint256 id) public view returns (uint256) {
        return auctionsById[id].auctionEnd;
    }

    function drfLtdNft(uint256 id) public view returns (uint256) {
        return auctionsById[id].nft;
    }

    function highestBidder(uint256 id) public view returns (address) {
        return auctionsById[id].highestBidder;
    }

    function highestBid(uint256 id) public view returns (uint256) {
        return auctionsById[id].highestBid;
    }

    function ended(uint256 id) public view returns (bool) {
        return now >= auctionsById[id].auctionEnd;
    }

    function runnerFee(uint256 id) public view returns (uint256) {
        return auctionsById[id].fee;
    }

    function setRunnerAddress(address account) public onlyOwner {
        runner = account;
    }

    function create(
        uint256 id,
        address beneficiaryAddress,
        uint256 fee,
        uint256 start,
        uint256 duration,
        uint256 extension // in minutes
    ) public onlyOwner {
        AuctionInfo storage auction = auctionsById[id];
        require(auction.beneficiary == address(0), "DRFAuction::create: auction already created");

        auction.beneficiary = beneficiaryAddress;
        auction.fee = fee;
        auction.auctionStart = start;
        auction.auctionEnd = start.add(duration * 1 days);
        auction.originalAuctionEnd = start.add(duration * 1 days);
        auction.extension = extension * 60;

        auctions.push(id);

        uint256 tokenId = IERC1155(drfLtdAddress).create(1, 1, "", "");
        require(tokenId > 0, "DRFAuction::create: ERC1155 create did not succeed");
        auction.nft = tokenId;
    }

    function bid(uint256 id, uint256 amount) public nonReentrant {
        AuctionInfo storage auction = auctionsById[id];
        require(auction.beneficiary != address(0), "DRFAuction::bid: auction does not exist");
        require(now >= auction.auctionStart, "DRFAuction::bid: auction has not started");
        require(now <= auction.auctionEnd, "DRFAuction::bid: auction has ended");

        uint256 newAmount = amount.add(balanceOf(msg.sender, id));
        require(newAmount > auction.highestBid, "DRFAuction::bid: bid is less than highest bid");

        auction.highestBidder = msg.sender;
        auction.highestBid = newAmount;

        if (auction.extension > 0 && auction.auctionEnd.sub(now) <= auction.extension) {
            auction.auctionEnd = now.add(auction.extension);
        }

        super.bid(id, amount);
        emit BidPlaced(msg.sender, id, amount);
    }

    function withdraw(uint256 id) public nonReentrant {
        AuctionInfo storage auction = auctionsById[id];
        uint256 amount = balanceOf(msg.sender, id);
        require(auction.beneficiary != address(0), "DRFAuction::withdraw: auction does not exist");
        require(amount > 0, "DRFAuction::withdraw: cannot withdraw 0");

        require(
            auction.highestBidder != msg.sender,
            "DRFAuction::withdraw: you are the highest bidder and cannot withdraw"
        );

        super.withdraw(id);
        emit Withdrawn(msg.sender, id, amount);
    }

    function emergencyWithdraw(uint256 id) public onlyOwner {
        AuctionInfo storage auction = auctionsById[id];
        require(auction.beneficiary != address(0), "DRFAuction::create: auction does not exist");
        require(now >= auction.auctionEnd, "DRFAuction::emergencyWithdraw: the auction has not ended");
        require(!auction.auctionEnded, "DRFAuction::emergencyWithdraw: auction ended and item sent");

        _emergencyWithdraw(auction.highestBidder, id);
        emit Withdrawn(auction.highestBidder, id, auction.highestBid);
    }

    function end(uint256 id) public nonReentrant {
        AuctionInfo storage auction = auctionsById[id];
        require(auction.beneficiary != address(0), "DRFAuction::end: auction does not exist");
        require(now >= auction.auctionEnd, "DRFAuction::end: the auction has not ended");
        require(!auction.auctionEnded, "DRFAuction::end: auction already ended");

        auction.auctionEnded = true;
        _end(id, auction.highestBidder, auction.beneficiary, runner, auction.fee, auction.highestBid);
        IERC1155(drfLtdAddress).safeTransferFrom(address(this), auction.highestBidder, auction.nft, 1, "");
        emit Ended(auction.highestBidder, id, auction.highestBid);
    }

    function onERC1155Received(
        address _operator,
        address, // _from
        uint256, // _id
        uint256, // _amount
        bytes memory // _data
    ) public returns (bytes4) {
        require(msg.sender == address(drfLtdAddress), "DRFAuction::onERC1155BatchReceived:: invalid token address");
        require(_operator == address(this), "DRFAuction::onERC1155BatchReceived:: operator must be auction contract");

        // Return success
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address _operator,
        address, // _from,
        uint256[] memory, // _ids,
        uint256[] memory, // _amounts,
        bytes memory // _data
    ) public returns (bytes4) {
        require(msg.sender == address(drfLtdAddress), "DRFAuction::onERC1155BatchReceived:: invalid token address");
        require(_operator == address(this), "DRFAuction::onERC1155BatchReceived:: operator must be auction contract");

        // Return success
        return this.onERC1155BatchReceived.selector;
    }

    function supportsInterface(bytes4 interfaceID) external view returns (bool) {
        return
        interfaceID == 0x01ffc9a7 || // ERC-165 support
        interfaceID == 0x4e2312e0; // ERC-1155 `ERC1155TokenReceiver` support
    }
}