/**
 *Submitted for verification at Etherscan.io on 2021-04-27
*/

// File: @openzeppelin/contracts/utils/Context.sol

// SPDX-License-Identifier: MIT

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
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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

// File: @openzeppelin/contracts/security/Pausable.sol



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
    constructor () {
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

// File: @openzeppelin/contracts/utils/math/SafeMath.sol



pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
            require(b <= a, errorMessage);
            return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
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

// File: @openzeppelin/contracts/utils/Address.sol



pragma solidity ^0.8.0;

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

// File: contracts/bid/GoodOneBidStorage.sol

// contracts/GoodOneBidStorage.sol


pragma solidity ^0.8.0;

/**
 * @title Interface for contracts conforming to ERC-20
 */
interface ERC20Interface {
    function balanceOf(address from) external view returns (uint256);
    function transfer(address _to, uint256 _value) external returns (bool success);
    function transferFrom(address from, address to, uint tokens) external returns (bool success);
    function allowance(address owner, address spender) external view returns (uint256);
    function mint(address account, uint256 amount) external;
}

/**
 * @title Interface for contracts conforming to ERC-1155
 */
interface ERC1155Interface {
    function balanceOf(address account, uint256 id) external view returns (uint256);
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;
    function supportsInterface(bytes4) external view returns (bool);
}


contract GoodOneBidStorage {
    uint256 public constant ONE_MILLION = 1000000;
    bytes4 public constant ERC1155_Interface = 0xd9b67a26;
    bytes4 public constant ERC1155_Received = 0xf23a6e61;
    
    struct Bid {
        // Bid Id
        bytes32 id;
        // Bidder address 
        address bidder;
        // ERC1155 address
        address tokenAddress;
        // ERC1155 token id
        uint256 tokenId;
        // Amount
        uint256 amount;
        // Price for the bid in wei 
        uint256 price;
    }

    // The token token
    ERC20Interface public goodOneToken;

    // The fee collector address
    address public feeCollector;
    // The inflation collector address
    address public inflationCollector;

    // Bid by token address => token id => bid
    mapping(address => mapping(uint256 => Bid)) public bidsByToken;
    
    // Bid by token address => token id => address
    mapping(address => mapping(uint256 => address)) public tokenOwnerPool;

    uint256 public inflationPerMillion;
    uint256 public bidFeePerMillion;
    uint256 public ownerCutPerMillion;

    // EVENTS
    event BidCreated(
      bytes32 _id,
      address indexed _tokenAddress,
      uint256 indexed _tokenId,
      uint256 _amount,
      address indexed _bidder,
      uint256 _price
    );
    
    event BidAccepted(
      bytes32 _id,
      address indexed _tokenAddress,
      uint256 indexed _tokenId,
      uint256 _amount,
      address _bidder,
      address indexed _seller,
      uint256 _price,
      uint256 _fee
    );

    event BidCancelled(
      bytes32 _id,
      address indexed _tokenAddress,
      uint256 indexed _tokenId,
      address indexed _bidder
    );

    event ChangedInflationPerMillion(uint256 inflationFeePerMillion);
    event ChangedBidFeePerMillion(uint256 bidFeePerMillion);
    event ChangedOwnerCutPerMillion(uint256 _ownerCutPerMillion);
}

// File: contracts/bid/GoodOneBid.sol

// contracts/ERC1155Bid.sol


pragma solidity ^0.8.0;






contract GoodOneBid is Ownable, Pausable, GoodOneBidStorage {
    using SafeMath for uint256;
    using Address for address;

    /**
    * @dev Constructor of the contract.
    * @param _goodOneToken - address of the GoodOne token
    * @param _owner - address of the owner for the contract
    * @param _feeCollector - address of the fee collector address 
    * @param _inflationCollector - address of the inflation collector address
    */
    constructor(address _goodOneToken, address _owner, address _feeCollector, address _inflationCollector) Ownable() Pausable() {
        goodOneToken = ERC20Interface(_goodOneToken);
        // Set owner
        transferOwnership(_owner);
        // Set fee collector address
        feeCollector = _feeCollector;
        // Set inflation fee collector address
        inflationCollector = _inflationCollector;
    }

    /**
    * @dev Place a bid for an ERC1155 token.
    * @param _tokenAddress - address of the ERC1155 token
    * @param _tokenId - uint256 of the token id
    * @param _price - uint256 of the price for the bid
    */
    function placeBid(
        address _tokenAddress, 
        uint256 _tokenId,
        uint256 _price,
        uint256 _amount)
        public
    {
        _placeBid(
            _tokenAddress, 
            _tokenId,
            _price,
            _amount
        );
    }


    /**
    * @dev Place a bid 
    * @notice Tokens can have multiple bids by different users.
    * Users can have only one bid per token.
    * If the user places a bid and has an active bid for that token,
    * the older one will be replaced with the new one.
    * @param _tokenAddress - address of the ERC1155 token
    * @param _tokenId - uint256 of the token id
    * @param _price - uint256 of the price for the bid
    */
    function _placeBid(
        address _tokenAddress, 
        uint256 _tokenId,
        uint256 _price,
        uint256 _amount
    )
        private
        whenNotPaused()
    {
        _requireERC1155(_tokenAddress);
        
        require(_price > 0, "Price should be bigger than 0");

        _requireBidderBalance(msg.sender, _price);       

        Bid memory highestBid = bidsByToken[_tokenAddress][_tokenId];
        
        require(_price > highestBid.price , "Price should be bigger than highest Bid");

        if(highestBid.bidder != address(0)) { 
            require(
                goodOneToken.transfer(highestBid.bidder, highestBid.price),
                "Refund failed"
            );    
        }

        require(
            goodOneToken.transferFrom(msg.sender, address(this), _price),
            "Transfering the bid amount to the marketplace failed"
        );

        uint256 feeAmount = 0;
        // Check if there's a bid fee and transfer the amount to marketplace owner
        if (bidFeePerMillion > 0) {
             // Calculate sale share
            feeAmount = _price.mul(bidFeePerMillion).div(1000000);

            require(
                goodOneToken.transferFrom(msg.sender, feeCollector, feeAmount),
                "Transfering the bid fee to the marketplace owner failed"
            );
        }

        _price = _price.sub(feeAmount);

        bytes32 bidId = keccak256(
            abi.encodePacked(
                block.timestamp,
                msg.sender,
                _tokenAddress,
                _tokenId,
                _amount,
                _price
            )
        );

        // Save Bid
        bidsByToken[_tokenAddress][_tokenId] = Bid({
            id: bidId,
            bidder: msg.sender,
            tokenAddress: _tokenAddress,
            tokenId: _tokenId,
            amount: _amount,
            price: _price
        });

        emit BidCreated(
            bidId,
            _tokenAddress,
            _tokenId,
            _amount,
            msg.sender,
            _price
        );
    }

    /**
    * @dev 
    * @param _operator The address which initiated the transfer (i.e. msg.sender)
    * @param _from The address which previously owned the token
    * @param _id The ID of the token being transferred
    * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address _operator,
        address _from,
        uint256 _id,
        uint256 /*_value*/,
        bytes memory /*_data*/)
        public
        whenNotPaused()
        returns (bytes4)
    {
        tokenOwnerPool[_operator][_id] = _from;
        
        return ERC1155_Received;
    }
    
     /**
    * @dev Accpect bid  
    * @param _tokenAddress the nft token address
    * @param _tokenId The NFT identifier which is being transferred
    * @param _amount The amount of tokens being transferred
    * @param _bidId The bid id
    */
    function accpetBid(
        address _tokenAddress, 
        uint256 _tokenId,
        uint256 _amount,
        bytes32 _bidId)
        public
        whenNotPaused()
    {
        Bid memory bid = _getBid(_tokenAddress, _tokenId);
        address nftOwner = tokenOwnerPool[_tokenAddress][_tokenId];
        require(
          msg.sender == nftOwner,
          "Sender must be the NFT owner"
        );

        // Check if the bid is valid.
        require(
            // solium-disable-next-line operator-whitespace
            bid.id == _bidId &&
            bid.amount == _amount,
            "Invalid bid"
        );

        require(
          ERC1155Interface(_tokenAddress).balanceOf(address(this), _tokenId) == _amount, 
          "Escow does not have NFT amount"
        );

        address bidder = bid.bidder;
        uint256 price = bid.price;
        
        // Check if bidder has funds
        _requireBidderBalance(bidder, price);

        // Delete bid references from contract storage
        delete bidsByToken[_tokenAddress][_tokenId];
        delete tokenOwnerPool[_tokenAddress][_tokenId];

        // Transfer token to bidder
        ERC1155Interface(_tokenAddress).safeTransferFrom(address(this), bidder, _tokenId, bid.amount, "");

        uint256 saleShareAmount = 0;
        if (ownerCutPerMillion > 0) {
            // Calculate sale share
            saleShareAmount = price.mul(ownerCutPerMillion).div(ONE_MILLION);
            // Transfer share amount to the bid conctract Owner
            require(
                goodOneToken.transfer(feeCollector, saleShareAmount),
                "Transfering the cut to the bid contract owner failed"
            );
        }

        // Transfer goodOneToken from bidder to seller
        require(
            goodOneToken.transfer(msg.sender, price.sub(saleShareAmount)),
            "Transfering GoodOneToken to nft owner failed"
        );
       
        if (inflationPerMillion > 0) {
            // Calculate mint tokens
            uint256 mintShareAmount = price.mul(inflationPerMillion).div(ONE_MILLION);
            // mint the new Good.ONE tokens to the inflationCollector
            goodOneToken.mint(inflationCollector, mintShareAmount);
        }

        emit BidAccepted(
            _bidId,
            msg.sender,
            _tokenId,
            bid.amount,
            bidder,
            nftOwner,
            price,
            saleShareAmount
        );
    }

    /**
    * @dev Get an ERC1155 token bid by index
    * @param _tokenAddress - address of the ERC1155 token
    * @param _tokenId - uint256 of the token id
    */
    function getBid(address _tokenAddress, uint256 _tokenId) 
        public 
        view
        returns (bytes32, address, uint256) 
    {
        
        Bid memory bid = _getBid(_tokenAddress, _tokenId);
        return (
            bid.id,
            bid.bidder,
            bid.price
        );
    }

    /**
    * @dev Get the active bid id and index by a bidder and an specific token. 
    * @notice If the index is not valid, it will revert.
    * @param _tokenAddress - address of the ERC1155 token
    * @param _tokenId - uint256 of the index
    * @return Bid
    */
    function _getBid(address _tokenAddress, uint256 _tokenId) 
        internal 
        view 
        returns (Bid memory)
    {
        return bidsByToken[_tokenAddress][_tokenId];
    }

    /**
    * @dev Sets the inflation that's we mint every transfer
    * @param _inflationPerMillion - inflation amount from 0 to 999,999
    */
    function setInflationPerMillion(uint256 _inflationPerMillion) external onlyOwner {
        require(_inflationPerMillion < 1000000, "The inflation should be between 0 and 999,999");

        inflationPerMillion = _inflationPerMillion;
        emit ChangedInflationPerMillion(inflationPerMillion);
    }

    /**
    * @dev Sets the bid fee that's charged to users to bid
    * @param _bidFeePerMillion - Fee amount from 0 to 999,999
    */
    function setBidFeePerMillion(uint256 _bidFeePerMillion) external onlyOwner {
        require(_bidFeePerMillion < 1000000, "The bid fee should be between 0 and 999,999");

        bidFeePerMillion = _bidFeePerMillion;
        emit ChangedBidFeePerMillion(bidFeePerMillion);
    }

    /**
    * @dev Sets the share cut for the owner of the contract that's
    * charged to the seller on a successful sale
    * @param _ownerCutPerMillion - Share amount, from 0 to 999,999
    */
    function setOwnerCutPerMillion(uint256 _ownerCutPerMillion) external onlyOwner {
        require(_ownerCutPerMillion < ONE_MILLION, "The owner cut should be between 0 and 999,999");

        ownerCutPerMillion = _ownerCutPerMillion;
        emit ChangedOwnerCutPerMillion(ownerCutPerMillion);
    }

    /** 
    * @dev Sets the fee collector address
    * @param _feeCollector - the fee collector address
    */
    function setFeeCollector(address _feeCollector) external onlyOwner {
        require(_feeCollector != address(0), "address can't be the zero address");

        feeCollector = _feeCollector;
    }

    /** 
    * @dev Sets the inflation collector address
    * @param _inflationCollector - the fee collector address
    */
    function setInflationCollector(address _inflationCollector) external onlyOwner {
        require(_inflationCollector != address(0), "address can't be the zero address");

        inflationCollector = _inflationCollector;
    }

    /** 
    * @dev Withderw the tokens from the contrcat
    * @param _withdrawAddress - The withdraw address
    * @param _amount - The withdraw amout
    */
    function withdraw(address _withdrawAddress, uint256 _amount) external onlyOwner {
        require(_withdrawAddress != address(0), "address can't be the zero address");

        require(
            goodOneToken.transfer(_withdrawAddress, _amount),
            "Withdraw failed"
        );     
    }

    /**
    * @dev Convert bytes to bytes32
    * @param _data - bytes
    * @return bytes32
    */
    function _bytesToBytes32(bytes memory _data) internal pure returns (bytes32) {
        require(_data.length == 32, "The data should be 32 bytes length");

        bytes32 bidId;
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            bidId := mload(add(_data, 0x20))
        }
        return bidId;
    }

    /**
    * @dev Check if the token has a valid ERC1155 implementation
    * @param _tokenAddress - address of the token
    */
    function _requireERC1155(address _tokenAddress) internal view {
        require(_tokenAddress.isContract(), "Token should be a contract");

        ERC1155Interface token = ERC1155Interface(_tokenAddress);
        require(
            token.supportsInterface(ERC1155_Interface),
            "Token has an invalid ERC1155_Interface implementation"
        );
    }

    /**
    * @dev Check if the bidder has balance and the contract has enough allowance
    * to use bidder erc on his belhalf
    * @param _bidder - address of bidder
    * @param _amount - uint256 of amount
    */
    function _requireBidderBalance(address _bidder, uint256 _amount) internal view {
        require(
            goodOneToken.balanceOf(_bidder) >= _amount,
            "Insufficient funds"
        );
        require(
            goodOneToken.allowance(_bidder, address(this)) >= _amount,
            "The contract is not authorized to use GoodOne token on bidder behalf"
        );        
    }
}