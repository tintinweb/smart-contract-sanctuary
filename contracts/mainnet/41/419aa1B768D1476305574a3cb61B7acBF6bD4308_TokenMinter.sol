/**
 *Submitted for verification at Etherscan.io on 2021-02-25
*/

/**

  Source code of Opium Protocol
  Web https://opium.network
  Telegram https://t.me/opium_network
  Twitter https://twitter.com/opium_network

 */

// File: LICENSE

/**

The software and documentation available in this repository (the "Software") is protected by copyright law and accessible pursuant to the license set forth below. Copyright © 2020 Blockeys BV. All rights reserved.

Permission is hereby granted, free of charge, to any person or organization obtaining the Software (the “Licensee”) to privately study, review, and analyze the Software. Licensee shall not use the Software for any other purpose. Licensee shall not modify, transfer, assign, share, or sub-license the Software or any derivative works of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

// File: openzeppelin-solidity/contracts/token/ERC721/IERC721Receiver.sol

pragma solidity ^0.5.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
contract IERC721Receiver {
    /**
     * @notice Handle the receipt of an NFT
     * @dev The ERC721 smart contract calls this function on the recipient
     * after a {IERC721-safeTransferFrom}. This function MUST return the function selector,
     * otherwise the caller will revert the transaction. The selector to be
     * returned can be obtained as `this.onERC721Received.selector`. This
     * function MAY throw to revert and reject the transfer.
     * Note: the ERC721 contract address is always the message sender.
     * @param operator The address which called `safeTransferFrom` function
     * @param from The address which previously owned the token
     * @param tokenId The NFT identifier which is being transferred
     * @param data Additional data with no specified format
     * @return bytes4 `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
     */
    function onERC721Received(address operator, address from, uint256 tokenId, bytes memory data)
    public returns (bytes4);
}

// File: openzeppelin-solidity/contracts/math/SafeMath.sol

pragma solidity ^0.5.0;

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

// File: erc721o/contracts/Libs/UintArray.sol

pragma solidity ^0.5.4;

library UintArray {
  function indexOf(uint256[] memory A, uint256 a) internal pure returns (uint256, bool) {
    uint256 length = A.length;
    for (uint256 i = 0; i < length; i++) {
      if (A[i] == a) {
        return (i, true);
      }
    }
    return (0, false);
  }

  function contains(uint256[] memory A, uint256 a) internal pure returns (bool) {
    (, bool isIn) = indexOf(A, a);
    return isIn;
  }

  function difference(uint256[] memory A, uint256[] memory B) internal pure returns (uint256[] memory, uint256[] memory) {
    uint256 length = A.length;
    bool[] memory includeMap = new bool[](length);
    uint256 count = 0;
    // First count the new length because can't push for in-memory arrays
    for (uint256 i = 0; i < length; i++) {
      uint256 e = A[i];
      if (!contains(B, e)) {
        includeMap[i] = true;
        count++;
      }
    }
    uint256[] memory newUints = new uint256[](count);
    uint256[] memory newUintsIdxs = new uint256[](count);
    uint256 j = 0;
    for (uint256 i = 0; i < length; i++) {
      if (includeMap[i]) {
        newUints[j] = A[i];
        newUintsIdxs[j] = i;
        j++;
      }
    }
    return (newUints, newUintsIdxs);
  }

  function intersect(uint256[] memory A, uint256[] memory B) internal pure returns (uint256[] memory, uint256[] memory, uint256[] memory) {
    uint256 length = A.length;
    bool[] memory includeMap = new bool[](length);
    uint256 newLength = 0;
    for (uint256 i = 0; i < length; i++) {
      if (contains(B, A[i])) {
        includeMap[i] = true;
        newLength++;
      }
    }
    uint256[] memory newUints = new uint256[](newLength);
    uint256[] memory newUintsAIdxs = new uint256[](newLength);
    uint256[] memory newUintsBIdxs = new uint256[](newLength);
    uint256 j = 0;
    for (uint256 i = 0; i < length; i++) {
      if (includeMap[i]) {
        newUints[j] = A[i];
        newUintsAIdxs[j] = i;
        (newUintsBIdxs[j], ) = indexOf(B, A[i]);
        j++;
      }
    }
    return (newUints, newUintsAIdxs, newUintsBIdxs);
  }

  function isUnique(uint256[] memory A) internal pure returns (bool) {
    uint256 length = A.length;

    for (uint256 i = 0; i < length; i++) {
      (uint256 idx, bool isIn) = indexOf(A, A[i]);

      if (isIn && idx < i) {
        return false;
      }
    }

    return true;
  }
}

// File: openzeppelin-solidity/contracts/utils/Address.sol

pragma solidity ^0.5.5;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * This test is non-exhaustive, and there may be false-negatives: during the
     * execution of a contract's constructor, its address will be reported as
     * not containing a contract.
     *
     * IMPORTANT: It is unsafe to assume that an address for which this
     * function returns false is an externally-owned account (EOA) and not a
     * contract.
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != 0x0 && codehash != accountHash);
    }

    /**
     * @dev Converts an `address` into `address payable`. Note that this is
     * simply a type cast: the actual underlying value is not changed.
     *
     * _Available since v2.4.0._
     */
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
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
     *
     * _Available since v2.4.0._
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-call-value
        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

// File: openzeppelin-solidity/contracts/utils/ReentrancyGuard.sol

pragma solidity ^0.5.0;

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
 */
contract ReentrancyGuard {
    // counter to allow mutex lock with only one SSTORE operation
    uint256 private _guardCounter;

    constructor () internal {
        // The counter starts at one to prevent changing it from zero to a non-zero
        // value, which is a more expensive operation.
        _guardCounter = 1;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _guardCounter += 1;
        uint256 localCounter = _guardCounter;
        _;
        require(localCounter == _guardCounter, "ReentrancyGuard: reentrant call");
    }
}

// File: openzeppelin-solidity/contracts/introspection/IERC165.sol

pragma solidity ^0.5.0;

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

// File: openzeppelin-solidity/contracts/introspection/ERC165.sol

pragma solidity ^0.5.0;


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
    function supportsInterface(bytes4 interfaceId) external view returns (bool) {
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
    function _registerInterface(bytes4 interfaceId) internal {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
}

// File: openzeppelin-solidity/contracts/token/ERC721/IERC721.sol

pragma solidity ^0.5.0;


/**
 * @dev Required interface of an ERC721 compliant contract.
 */
contract IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of NFTs in `owner`'s account.
     */
    function balanceOf(address owner) public view returns (uint256 balance);

    /**
     * @dev Returns the owner of the NFT specified by `tokenId`.
     */
    function ownerOf(uint256 tokenId) public view returns (address owner);

    /**
     * @dev Transfers a specific NFT (`tokenId`) from one account (`from`) to
     * another (`to`).
     *
     *
     *
     * Requirements:
     * - `from`, `to` cannot be zero.
     * - `tokenId` must be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this
     * NFT by either {approve} or {setApprovalForAll}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public;
    /**
     * @dev Transfers a specific NFT (`tokenId`) from one account (`from`) to
     * another (`to`).
     *
     * Requirements:
     * - If the caller is not `from`, it must be approved to move this NFT by
     * either {approve} or {setApprovalForAll}.
     */
    function transferFrom(address from, address to, uint256 tokenId) public;
    function approve(address to, uint256 tokenId) public;
    function getApproved(uint256 tokenId) public view returns (address operator);

    function setApprovalForAll(address operator, bool _approved) public;
    function isApprovedForAll(address owner, address operator) public view returns (bool);


    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public;
}

// File: erc721o/contracts/Interfaces/IERC721O.sol

pragma solidity ^0.5.4;

contract IERC721O {
  // Token description
  function name() external view returns (string memory);
  function symbol() external view returns (string memory);
  function totalSupply() public view returns (uint256);
  function exists(uint256 _tokenId) public view returns (bool);

  function implementsERC721() public pure returns (bool);
  function tokenByIndex(uint256 _index) public view returns (uint256);
  function tokenOfOwnerByIndex(address _owner, uint256 _index) public view returns (uint256 _tokenId);
  function tokenURI(uint256 _tokenId) public view returns (string memory tokenUri);
  function getApproved(uint256 _tokenId) public view returns (address);
  
  function implementsERC721O() public pure returns (bool);
  function ownerOf(uint256 _tokenId) public view returns (address _owner);
  function balanceOf(address owner) public view returns (uint256);
  function balanceOf(address _owner, uint256 _tokenId) public view returns (uint256);
  function tokensOwned(address _owner) public view returns (uint256[] memory, uint256[] memory);

  // Non-Fungible Safe Transfer From
  function safeTransferFrom(address _from, address _to, uint256 _tokenId) public;
  function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory _data) public;

  // Non-Fungible Unsafe Transfer From
  function transferFrom(address _from, address _to, uint256 _tokenId) public;

  // Fungible Unsafe Transfer
  function transfer(address _to, uint256 _tokenId, uint256 _quantity) public;

  // Fungible Unsafe Transfer From
  function transferFrom(address _from, address _to, uint256 _tokenId, uint256 _quantity) public;

  // Fungible Safe Transfer From
  function safeTransferFrom(address _from, address _to, uint256 _tokenId, uint256 _amount) public;
  function safeTransferFrom(address _from, address _to, uint256 _tokenId, uint256 _amount, bytes memory _data) public;

  // Fungible Safe Batch Transfer From
  function safeBatchTransferFrom(address _from, address _to, uint256[] memory _tokenIds, uint256[] memory _amounts) public;
  function safeBatchTransferFrom(address _from, address _to, uint256[] memory _tokenIds, uint256[] memory _amounts, bytes memory _data) public;

  // Fungible Unsafe Batch Transfer From
  function batchTransferFrom(address _from, address _to, uint256[] memory _tokenIds, uint256[] memory _amounts) public;

  // Approvals
  function setApprovalForAll(address _operator, bool _approved) public;
  function approve(address _to, uint256 _tokenId) public;
  function getApproved(uint256 _tokenId, address _tokenOwner) public view returns (address);
  function isApprovedForAll(address _owner, address _operator) public view returns (bool isOperator);
  function isApprovedOrOwner(address _spender, address _owner, uint256 _tokenId) public view returns (bool);
  function permit(address _holder, address _spender, uint256 _nonce, uint256 _expiry, bool _allowed, bytes calldata _signature) external;

  // Composable
  function compose(uint256[] memory _tokenIds, uint256[] memory _tokenRatio, uint256 _quantity) public;
  function decompose(uint256 _portfolioId, uint256[] memory _tokenIds, uint256[] memory _tokenRatio, uint256 _quantity) public;
  function recompose(uint256 _portfolioId, uint256[] memory _initialTokenIds, uint256[] memory _initialTokenRatio, uint256[] memory _finalTokenIds, uint256[] memory _finalTokenRatio, uint256 _quantity) public;

  // Required Events
  event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
  event TransferWithQuantity(address indexed from, address indexed to, uint256 indexed tokenId, uint256 quantity);
  event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);
  event BatchTransfer(address indexed from, address indexed to, uint256[] tokenTypes, uint256[] amounts);
  event Composition(uint256 portfolioId, uint256[] tokenIds, uint256[] tokenRatio);
}

// File: erc721o/contracts/Interfaces/IERC721OReceiver.sol

pragma solidity ^0.5.4;

/**
 * @title ERC721O token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 *  from ERC721O contracts.
 */
contract IERC721OReceiver {
  /**
    * @dev Magic value to be returned upon successful reception of an amount of ERC721O tokens
    *  ERC721O_RECEIVED = `bytes4(keccak256("onERC721OReceived(address,address,uint256,uint256,bytes)"))` = 0xf891ffe0
    *  ERC721O_BATCH_RECEIVED = `bytes4(keccak256("onERC721OBatchReceived(address,address,uint256[],uint256[],bytes)"))` = 0xd0e17c0b
    */
  bytes4 constant internal ERC721O_RECEIVED = 0xf891ffe0;
  bytes4 constant internal ERC721O_BATCH_RECEIVED = 0xd0e17c0b;

  function onERC721OReceived(
    address _operator,
    address _from,
    uint256 tokenId,
    uint256 amount,
    bytes memory data
  ) public returns(bytes4);

  function onERC721OBatchReceived(
    address _operator,
    address _from,
    uint256[] memory _types,
    uint256[] memory _amounts,
    bytes memory _data
  ) public returns (bytes4);
}

// File: erc721o/contracts/Libs/ObjectsLib.sol

pragma solidity ^0.5.4;


library ObjectLib {
  // Libraries
  using SafeMath for uint256;

  enum Operations { ADD, SUB, REPLACE }

  // Constants regarding bin or chunk sizes for balance packing
  uint256 constant TYPES_BITS_SIZE   = 32;                     // Max size of each object
  uint256 constant TYPES_PER_UINT256 = 256 / TYPES_BITS_SIZE; // Number of types per uint256

  //
  // Objects and Tokens Functions
  //

  /**
  * @dev Return the bin number and index within that bin where ID is
  * @param _tokenId Object type
  * @return (Bin number, ID's index within that bin)
  */
  function getTokenBinIndex(uint256 _tokenId) internal pure returns (uint256 bin, uint256 index) {
    bin = _tokenId * TYPES_BITS_SIZE / 256;
    index = _tokenId % TYPES_PER_UINT256;
    return (bin, index);
  }


  /**
  * @dev update the balance of a type provided in _binBalances
  * @param _binBalances Uint256 containing the balances of objects
  * @param _index Index of the object in the provided bin
  * @param _amount Value to update the type balance
  * @param _operation Which operation to conduct :
  *     Operations.REPLACE : Replace type balance with _amount
  *     Operations.ADD     : ADD _amount to type balance
  *     Operations.SUB     : Substract _amount from type balance
  */
  function updateTokenBalance(
    uint256 _binBalances,
    uint256 _index,
    uint256 _amount,
    Operations _operation) internal pure returns (uint256 newBinBalance)
  {
    uint256 objectBalance;
    if (_operation == Operations.ADD) {
      objectBalance = getValueInBin(_binBalances, _index);
      newBinBalance = writeValueInBin(_binBalances, _index, objectBalance.add(_amount));
    } else if (_operation == Operations.SUB) {
      objectBalance = getValueInBin(_binBalances, _index);
      newBinBalance = writeValueInBin(_binBalances, _index, objectBalance.sub(_amount));
    } else if (_operation == Operations.REPLACE) {
      newBinBalance = writeValueInBin(_binBalances, _index, _amount);
    } else {
      revert("Invalid operation"); // Bad operation
    }

    return newBinBalance;
  }
  
  /*
  * @dev return value in _binValue at position _index
  * @param _binValue uint256 containing the balances of TYPES_PER_UINT256 types
  * @param _index index at which to retrieve value
  * @return Value at given _index in _bin
  */
  function getValueInBin(uint256 _binValue, uint256 _index) internal pure returns (uint256) {

    // Mask to retrieve data for a given binData
    uint256 mask = (uint256(1) << TYPES_BITS_SIZE) - 1;

    // Shift amount
    uint256 rightShift = 256 - TYPES_BITS_SIZE * (_index + 1);
    return (_binValue >> rightShift) & mask;
  }

  /**
  * @dev return the updated _binValue after writing _amount at _index
  * @param _binValue uint256 containing the balances of TYPES_PER_UINT256 types
  * @param _index Index at which to retrieve value
  * @param _amount Value to store at _index in _bin
  * @return Value at given _index in _bin
  */
  function writeValueInBin(uint256 _binValue, uint256 _index, uint256 _amount) internal pure returns (uint256) {
    require(_amount < 2**TYPES_BITS_SIZE, "Amount to write in bin is too large");

    // Mask to retrieve data for a given binData
    uint256 mask = (uint256(1) << TYPES_BITS_SIZE) - 1;

    // Shift amount
    uint256 leftShift = 256 - TYPES_BITS_SIZE * (_index + 1);
    return (_binValue & ~(mask << leftShift) ) | (_amount << leftShift);
  }

}

// File: erc721o/contracts/ERC721OBase.sol

pragma solidity ^0.5.4;






contract ERC721OBase is IERC721O, ERC165, IERC721 {
  // Libraries
  using ObjectLib for ObjectLib.Operations;
  using ObjectLib for uint256;

  // Array with all tokenIds
  uint256[] internal allTokens;

  // Packed balances
  mapping(address => mapping(uint256 => uint256)) internal packedTokenBalance;

  // Operators
  mapping(address => mapping(address => bool)) internal operators;

  // Keeps aprovals for tokens from owner to approved address
  // tokenApprovals[tokenId][owner] = approved
  mapping (uint256 => mapping (address => address)) internal tokenApprovals;

  // Token Id state
  mapping(uint256 => uint256) internal tokenTypes;

  uint256 constant internal INVALID = 0;
  uint256 constant internal POSITION = 1;
  uint256 constant internal PORTFOLIO = 2;

  // Interface constants
  bytes4 internal constant INTERFACE_ID_ERC721O = 0x12345678;

  // EIP712 constants
  bytes32 public DOMAIN_SEPARATOR;
  bytes32 public PERMIT_TYPEHASH;

  // mapping holds nonces for approval permissions
  // nonces[holder] => nonce
  mapping (address => uint) public nonces;

  modifier isOperatorOrOwner(address _from) {
    require((msg.sender == _from) || operators[_from][msg.sender], "msg.sender is neither _from nor operator");
    _;
  }

  constructor() public {
    _registerInterface(INTERFACE_ID_ERC721O);
    
    // Calculate EIP712 constants
    DOMAIN_SEPARATOR = keccak256(abi.encode(
      keccak256("EIP712Domain(string name,string version,address verifyingContract)"),
      keccak256(bytes("ERC721o")),
      keccak256(bytes("1")),
      address(this)
    ));
    PERMIT_TYPEHASH = keccak256("Permit(address holder,address spender,uint256 nonce,uint256 expiry,bool allowed)");
  }

  function implementsERC721O() public pure returns (bool) {
    return true;
  }

  /**
   * @dev Returns whether the specified token exists
   * @param _tokenId uint256 ID of the token to query the existence of
   * @return whether the token exists
   */
  function exists(uint256 _tokenId) public view returns (bool) {
    return tokenTypes[_tokenId] != INVALID;
  }

  /**
   * @dev return the _tokenId type' balance of _address
   * @param _address Address to query balance of
   * @param _tokenId type to query balance of
   * @return Amount of objects of a given type ID
   */
  function balanceOf(address _address, uint256 _tokenId) public view returns (uint256) {
    (uint256 bin, uint256 index) = _tokenId.getTokenBinIndex();
    return packedTokenBalance[_address][bin].getValueInBin(index);
  }

  /**
   * @dev Gets the total amount of tokens stored by the contract
   * @return uint256 representing the total amount of tokens
   */
  function totalSupply() public view returns (uint256) {
    return allTokens.length;
  }

  /**
   * @dev Gets Iterate through the list of existing tokens and return the indexes
   *        and balances of the tokens owner by the user
   * @param _owner The adddress we are checking
   * @return indexes The tokenIds
   * @return balances The balances of each token
   */
  function tokensOwned(address _owner) public view returns (uint256[] memory indexes, uint256[] memory balances) {
    uint256 numTokens = totalSupply();
    uint256[] memory tokenIndexes = new uint256[](numTokens);
    uint256[] memory tempTokens = new uint256[](numTokens);

    uint256 count;
    for (uint256 i = 0; i < numTokens; i++) {
      uint256 tokenId = allTokens[i];
      if (balanceOf(_owner, tokenId) > 0) {
        tempTokens[count] = balanceOf(_owner, tokenId);
        tokenIndexes[count] = tokenId;
        count++;
      }
    }

    // copy over the data to a correct size array
    uint256[] memory _ownedTokens = new uint256[](count);
    uint256[] memory _ownedTokensIndexes = new uint256[](count);

    for (uint256 i = 0; i < count; i++) {
      _ownedTokens[i] = tempTokens[i];
      _ownedTokensIndexes[i] = tokenIndexes[i];
    }

    return (_ownedTokensIndexes, _ownedTokens);
  }

  /**
   * @dev Will set _operator operator status to true or false
   * @param _operator Address to changes operator status.
   * @param _approved  _operator's new operator status (true or false)
   */
  function setApprovalForAll(address _operator, bool _approved) public {
    // Update operator status
    operators[msg.sender][_operator] = _approved;
    emit ApprovalForAll(msg.sender, _operator, _approved);
  }

  /// @notice Approve for all by signature
  function permit(address _holder, address _spender, uint256 _nonce, uint256 _expiry, bool _allowed, bytes calldata _signature) external {
    // Calculate hash
    bytes32 digest =
      keccak256(abi.encodePacked(
        "\x19\x01",
        DOMAIN_SEPARATOR,
        keccak256(abi.encode(
          PERMIT_TYPEHASH,
          _holder,
          _spender,
          _nonce,
          _expiry,
          _allowed
        ))
    ));

    // Divide the signature in r, s and v variables
    // ecrecover takes the signature parameters, and the only way to get them
    // currently is to use assembly.
    // solium-disable-next-line security/no-inline-assembly
    bytes32 r;
    bytes32 s;
    uint8 v;

    bytes memory signature = _signature;

    assembly {
      r := mload(add(signature, 32))
      s := mload(add(signature, 64))
      v := byte(0, mload(add(signature, 96)))
    }

    // Version of signature should be 27 or 28, but 0 and 1 are also possible versions
    if (v < 27) {
      v += 27;
    }

    address recoveredAddress;

    // If the version is correct return the signer address
    if (v != 27 && v != 28) {
      recoveredAddress = address(0);
    } else {
      // solium-disable-next-line arg-overflow
      recoveredAddress = ecrecover(digest, v, r, s);
    }

    require(_holder != address(0), "Holder can't be zero address");
    require(_holder == recoveredAddress, "Signer address is invalid");
    require(_expiry == 0 || now <= _expiry, "Permission expired");
    require(_nonce == nonces[_holder]++, "Nonce is invalid");
    
    // Update operator status
    operators[_holder][_spender] = _allowed;
    emit ApprovalForAll(_holder, _spender, _allowed);
  }

  /**
   * @dev Approves another address to transfer the given token ID
   * The zero address indicates there is no approved address.
   * There can only be one approved address per token at a given time.
   * Can only be called by the token owner or an approved operator.
   * @param _to address to be approved for the given token ID
   * @param _tokenId uint256 ID of the token to be approved
   */
  function approve(address _to, uint256 _tokenId) public {
    require(_to != msg.sender, "Can't approve to yourself");
    tokenApprovals[_tokenId][msg.sender] = _to;
    emit Approval(msg.sender, _to, _tokenId);
  }

  /**
   * @dev Gets the approved address for a token ID, or zero if no address set
   * @param _tokenId uint256 ID of the token to query the approval of
   * @return address currently approved for the given token ID
   */
  function getApproved(uint256 _tokenId, address _tokenOwner) public view returns (address) {
    return tokenApprovals[_tokenId][_tokenOwner];
  }

  /**
   * @dev Function that verifies whether _operator is an authorized operator of _tokenHolder.
   * @param _operator The address of the operator to query status of
   * @param _owner Address of the tokenHolder
   * @return A uint256 specifying the amount of tokens still available for the spender.
   */
  function isApprovedForAll(address _owner, address _operator) public view returns (bool isOperator) {
    return operators[_owner][_operator];
  }

  function isApprovedOrOwner(
    address _spender,
    address _owner,
    uint256 _tokenId
  ) public view returns (bool) {
    return (
      _spender == _owner ||
      getApproved(_tokenId, _owner) == _spender ||
      isApprovedForAll(_owner, _spender)
    );
  }

  function _updateTokenBalance(
    address _from,
    uint256 _tokenId,
    uint256 _amount,
    ObjectLib.Operations op
  ) internal {
    (uint256 bin, uint256 index) = _tokenId.getTokenBinIndex();
    packedTokenBalance[_from][bin] = packedTokenBalance[_from][bin].updateTokenBalance(
      index, _amount, op
    );
  }
}

// File: erc721o/contracts/ERC721OTransferable.sol

pragma solidity ^0.5.4;




contract ERC721OTransferable is ERC721OBase, ReentrancyGuard {
  // Libraries
  using Address for address;

  // safeTransfer constants
  bytes4 internal constant ERC721O_RECEIVED = 0xf891ffe0;
  bytes4 internal constant ERC721O_BATCH_RECEIVED = 0xd0e17c0b;

  function batchTransferFrom(address _from, address _to, uint256[] memory _tokenIds, uint256[] memory _amounts) public {
    // Batch Transfering
    _batchTransferFrom(_from, _to, _tokenIds, _amounts);
  }

  /**
    * @dev transfer objects from different tokenIds to specified address
    * @param _from The address to BatchTransfer objects from.
    * @param _to The address to batchTransfer objects to.
    * @param _tokenIds Array of tokenIds to update balance of
    * @param _amounts Array of amount of object per type to be transferred.
    * @param _data Data to pass to onERC721OReceived() function if recipient is contract
    * Note:  Arrays should be sorted so that all tokenIds in a same bin are adjacent (more efficient).
    */
  function safeBatchTransferFrom(
    address _from,
    address _to,
    uint256[] memory _tokenIds,
    uint256[] memory _amounts,
    bytes memory _data
  ) public nonReentrant {
    // Batch Transfering
    _batchTransferFrom(_from, _to, _tokenIds, _amounts);

    // Pass data if recipient is contract
    if (_to.isContract()) {
      bytes4 retval = IERC721OReceiver(_to).onERC721OBatchReceived(
        msg.sender, _from, _tokenIds, _amounts, _data
      );
      require(retval == ERC721O_BATCH_RECEIVED);
    }
  }

  function safeBatchTransferFrom(
    address _from,
    address _to,
    uint256[] memory _tokenIds,
    uint256[] memory _amounts
  ) public {
    safeBatchTransferFrom(_from, _to, _tokenIds, _amounts, "");
  }

  function transfer(address _to, uint256 _tokenId, uint256 _amount) public {
    _transferFrom(msg.sender, _to, _tokenId, _amount);
  }

  function transferFrom(address _from, address _to, uint256 _tokenId, uint256 _amount) public {
    _transferFrom(_from, _to, _tokenId, _amount);
  }

  function safeTransferFrom(address _from, address _to, uint256 _tokenId, uint256 _amount) public {
    safeTransferFrom(_from, _to, _tokenId, _amount, "");
  }

  function safeTransferFrom(address _from, address _to, uint256 _tokenId, uint256 _amount, bytes memory _data) public nonReentrant {
    _transferFrom(_from, _to, _tokenId, _amount);
    require(
      _checkAndCallSafeTransfer(_from, _to, _tokenId, _amount, _data),
      "Sent to a contract which is not an ERC721O receiver"
    );
  }

  /**
    * @dev transfer objects from different tokenIds to specified address
    * @param _from The address to BatchTransfer objects from.
    * @param _to The address to batchTransfer objects to.
    * @param _tokenIds Array of tokenIds to update balance of
    * @param _amounts Array of amount of object per type to be transferred.
    * Note:  Arrays should be sorted so that all tokenIds in a same bin are adjacent (more efficient).
    */
  function _batchTransferFrom(
    address _from,
    address _to,
    uint256[] memory _tokenIds,
    uint256[] memory _amounts
  ) internal isOperatorOrOwner(_from) {
    // Requirements
    require(_tokenIds.length == _amounts.length, "Inconsistent array length between args");
    require(_to != address(0), "Invalid to address");

    // Number of transfers to execute
    uint256 nTransfer = _tokenIds.length;

    // Don't do useless calculations
    if (_from == _to) {
      for (uint256 i = 0; i < nTransfer; i++) {
        emit Transfer(_from, _to, _tokenIds[i]);
        emit TransferWithQuantity(_from, _to, _tokenIds[i], _amounts[i]);
      }
      return;
    }

    for (uint256 i = 0; i < nTransfer; i++) {
      require(_amounts[i] <= balanceOf(_from, _tokenIds[i]), "Quantity greater than from balance");
      _updateTokenBalance(_from, _tokenIds[i], _amounts[i], ObjectLib.Operations.SUB);
      _updateTokenBalance(_to, _tokenIds[i], _amounts[i], ObjectLib.Operations.ADD);

      emit Transfer(_from, _to, _tokenIds[i]);
      emit TransferWithQuantity(_from, _to, _tokenIds[i], _amounts[i]);
    }

    // Emit batchTransfer event
    emit BatchTransfer(_from, _to, _tokenIds, _amounts);
  }

  function _transferFrom(address _from, address _to, uint256 _tokenId, uint256 _amount) internal {
    require(isApprovedOrOwner(msg.sender, _from, _tokenId), "Not approved");
    require(_amount <= balanceOf(_from, _tokenId), "Quantity greater than from balance");
    require(_to != address(0), "Invalid to address");

    _updateTokenBalance(_from, _tokenId, _amount, ObjectLib.Operations.SUB);
    _updateTokenBalance(_to, _tokenId, _amount, ObjectLib.Operations.ADD);
    emit Transfer(_from, _to, _tokenId);
    emit TransferWithQuantity(_from, _to, _tokenId, _amount);
  }

  function _checkAndCallSafeTransfer(
    address _from,
    address _to,
    uint256 _tokenId,
    uint256 _amount,
    bytes memory _data
  ) internal returns (bool) {
    if (!_to.isContract()) {
      return true;
    }

    bytes4 retval = IERC721OReceiver(_to).onERC721OReceived(msg.sender, _from, _tokenId, _amount, _data);
    return(retval == ERC721O_RECEIVED);
  }
}

// File: erc721o/contracts/Libs/LibPosition.sol

pragma solidity ^0.5.4;

library LibPosition {
  function getLongTokenId(bytes32 _hash) public pure returns (uint256 tokenId) {
    tokenId = uint256(keccak256(abi.encodePacked(_hash, "LONG")));
  }

  function getShortTokenId(bytes32 _hash) public pure returns (uint256 tokenId) {
    tokenId = uint256(keccak256(abi.encodePacked(_hash, "SHORT")));
  }
}

// File: erc721o/contracts/ERC721OMintable.sol

pragma solidity ^0.5.4;



contract ERC721OMintable is ERC721OTransferable {
  // Libraries
  using LibPosition for bytes32;

  // Internal functions
  function _mint(uint256 _tokenId, address _to, uint256 _supply) internal {
    // If the token doesn't exist, add it to the tokens array
    if (!exists(_tokenId)) {
      tokenTypes[_tokenId] = POSITION;
      allTokens.push(_tokenId);
    }

    _updateTokenBalance(_to, _tokenId, _supply, ObjectLib.Operations.ADD);
    emit Transfer(address(0), _to, _tokenId);
    emit TransferWithQuantity(address(0), _to, _tokenId, _supply);
  }

  function _burn(address _tokenOwner, uint256 _tokenId, uint256 _quantity) internal {
    uint256 ownerBalance = balanceOf(_tokenOwner, _tokenId);
    require(ownerBalance >= _quantity, "TOKEN_MINTER:NOT_ENOUGH_POSITIONS");

    _updateTokenBalance(_tokenOwner, _tokenId, _quantity, ObjectLib.Operations.SUB);
    emit Transfer(_tokenOwner, address(0), _tokenId);
    emit TransferWithQuantity(_tokenOwner, address(0), _tokenId, _quantity);
  }

  function _mint(address _buyer, address _seller, bytes32 _derivativeHash, uint256 _quantity) internal {
    _mintLong(_buyer, _derivativeHash, _quantity);
    _mintShort(_seller, _derivativeHash, _quantity);
  }
  
  function _mintLong(address _buyer, bytes32 _derivativeHash, uint256 _quantity) internal {
    uint256 longTokenId = _derivativeHash.getLongTokenId();
    _mint(longTokenId, _buyer, _quantity);
  }
  
  function _mintShort(address _seller, bytes32 _derivativeHash, uint256 _quantity) internal {
    uint256 shortTokenId = _derivativeHash.getShortTokenId();
    _mint(shortTokenId, _seller, _quantity);
  }

  function _registerPortfolio(uint256 _portfolioId, uint256[] memory _tokenIds, uint256[] memory _tokenRatio) internal {
    if (!exists(_portfolioId)) {
      tokenTypes[_portfolioId] = PORTFOLIO;
      emit Composition(_portfolioId, _tokenIds, _tokenRatio);
    }
  }
}

// File: erc721o/contracts/ERC721OComposable.sol

pragma solidity ^0.5.4;




contract ERC721OComposable is ERC721OMintable {
  // Libraries
  using UintArray for uint256[];
  using SafeMath for uint256;

  function compose(uint256[] memory _tokenIds, uint256[] memory _tokenRatio, uint256 _quantity) public {
    require(_tokenIds.length == _tokenRatio.length, "TOKEN_MINTER:TOKEN_IDS_AND_RATIO_LENGTH_DOES_NOT_MATCH");
    require(_quantity > 0, "TOKEN_MINTER:WRONG_QUANTITY");
    require(_tokenIds.length > 0, "TOKEN_MINTER:WRONG_QUANTITY");
    require(_tokenIds.isUnique(), "TOKEN_MINTER:TOKEN_IDS_NOT_UNIQUE");

    for (uint256 i = 0; i < _tokenIds.length; i++) {
      _burn(msg.sender, _tokenIds[i], _tokenRatio[i].mul(_quantity));
    }

    uint256 portfolioId = uint256(keccak256(abi.encodePacked(
      _tokenIds,
      _tokenRatio
    )));

    _registerPortfolio(portfolioId, _tokenIds, _tokenRatio);
    _mint(portfolioId, msg.sender, _quantity);
  }

  function decompose(uint256 _portfolioId, uint256[] memory _tokenIds, uint256[] memory _tokenRatio, uint256 _quantity) public {
    require(_tokenIds.length == _tokenRatio.length, "TOKEN_MINTER:TOKEN_IDS_AND_RATIO_LENGTH_DOES_NOT_MATCH");
    require(_quantity > 0, "TOKEN_MINTER:WRONG_QUANTITY");
    require(_tokenIds.length > 0, "TOKEN_MINTER:WRONG_QUANTITY");
    require(_tokenIds.isUnique(), "TOKEN_MINTER:TOKEN_IDS_NOT_UNIQUE");

    uint256 portfolioId = uint256(keccak256(abi.encodePacked(
      _tokenIds,
      _tokenRatio
    )));

    require(portfolioId == _portfolioId, "TOKEN_MINTER:WRONG_PORTFOLIO_ID");
    _burn(msg.sender, _portfolioId, _quantity);

    for (uint256 i = 0; i < _tokenIds.length; i++) {
      _mint(_tokenIds[i], msg.sender, _tokenRatio[i].mul(_quantity));
    }
  }

  function recompose(
    uint256 _portfolioId,
    uint256[] memory _initialTokenIds,
    uint256[] memory _initialTokenRatio,
    uint256[] memory _finalTokenIds,
    uint256[] memory _finalTokenRatio,
    uint256 _quantity
  ) public {
    require(_initialTokenIds.length == _initialTokenRatio.length, "TOKEN_MINTER:INITIAL_TOKEN_IDS_AND_RATIO_LENGTH_DOES_NOT_MATCH");
    require(_finalTokenIds.length == _finalTokenRatio.length, "TOKEN_MINTER:FINAL_TOKEN_IDS_AND_RATIO_LENGTH_DOES_NOT_MATCH");
    require(_quantity > 0, "TOKEN_MINTER:WRONG_QUANTITY");
    require(_initialTokenIds.length > 0, "TOKEN_MINTER:WRONG_QUANTITY");
    require(_finalTokenIds.length > 0, "TOKEN_MINTER:WRONG_QUANTITY");
    require(_initialTokenIds.isUnique(), "TOKEN_MINTER:TOKEN_IDS_NOT_UNIQUE");
    require(_finalTokenIds.isUnique(), "TOKEN_MINTER:TOKEN_IDS_NOT_UNIQUE");

    uint256 oldPortfolioId = uint256(keccak256(abi.encodePacked(
      _initialTokenIds,
      _initialTokenRatio
    )));

    require(oldPortfolioId == _portfolioId, "TOKEN_MINTER:WRONG_PORTFOLIO_ID");
    _burn(msg.sender, _portfolioId, _quantity);
    
    _removedIds(_initialTokenIds, _initialTokenRatio, _finalTokenIds, _finalTokenRatio, _quantity);
    _addedIds(_initialTokenIds, _initialTokenRatio, _finalTokenIds, _finalTokenRatio, _quantity);
    _keptIds(_initialTokenIds, _initialTokenRatio, _finalTokenIds, _finalTokenRatio, _quantity);

    uint256 newPortfolioId = uint256(keccak256(abi.encodePacked(
      _finalTokenIds,
      _finalTokenRatio
    )));

    _registerPortfolio(newPortfolioId, _finalTokenIds, _finalTokenRatio);
    _mint(newPortfolioId, msg.sender, _quantity);
  }

  function _removedIds(
    uint256[] memory _initialTokenIds,
    uint256[] memory _initialTokenRatio,
    uint256[] memory _finalTokenIds,
    uint256[] memory _finalTokenRatio,
    uint256 _quantity
  ) private {
    (uint256[] memory removedIds, uint256[] memory removedIdsIdxs) = _initialTokenIds.difference(_finalTokenIds);

    for (uint256 i = 0; i < removedIds.length; i++) {
      uint256 index = removedIdsIdxs[i];
      _mint(_initialTokenIds[index], msg.sender, _initialTokenRatio[index].mul(_quantity));
    }

    _finalTokenRatio;
  }

  function _addedIds(
      uint256[] memory _initialTokenIds,
      uint256[] memory _initialTokenRatio,
      uint256[] memory _finalTokenIds,
      uint256[] memory _finalTokenRatio,
      uint256 _quantity
  ) private {
    (uint256[] memory addedIds, uint256[] memory addedIdsIdxs) = _finalTokenIds.difference(_initialTokenIds);

    for (uint256 i = 0; i < addedIds.length; i++) {
      uint256 index = addedIdsIdxs[i];
      _burn(msg.sender, _finalTokenIds[index], _finalTokenRatio[index].mul(_quantity));
    }

    _initialTokenRatio;
  }

  function _keptIds(
      uint256[] memory _initialTokenIds,
      uint256[] memory _initialTokenRatio,
      uint256[] memory _finalTokenIds,
      uint256[] memory _finalTokenRatio,
      uint256 _quantity
  ) private {
    (uint256[] memory keptIds, uint256[] memory keptInitialIdxs, uint256[] memory keptFinalIdxs) = _initialTokenIds.intersect(_finalTokenIds);

    for (uint256 i = 0; i < keptIds.length; i++) {
      uint256 initialIndex = keptInitialIdxs[i];
      uint256 finalIndex = keptFinalIdxs[i];

      if (_initialTokenRatio[initialIndex] > _finalTokenRatio[finalIndex]) {
        uint256 diff = _initialTokenRatio[initialIndex] - _finalTokenRatio[finalIndex];
        _mint(_initialTokenIds[initialIndex], msg.sender, diff.mul(_quantity));
      } else if (_initialTokenRatio[initialIndex] < _finalTokenRatio[finalIndex]) {
        uint256 diff = _finalTokenRatio[finalIndex] - _initialTokenRatio[initialIndex];
        _burn(msg.sender, _initialTokenIds[initialIndex], diff.mul(_quantity));
      }
    }
  }
}

// File: erc721o/contracts/Libs/UintsLib.sol

pragma solidity ^0.5.4;

library UintsLib {
  function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
    if (_i == 0) {
      return "0";
    }

    uint j = _i;
    uint len;
    while (j != 0) {
      len++;
      j /= 10;
    }

    bytes memory bstr = new bytes(len);
    uint k = len - 1;
    while (_i != 0) {
      bstr[k--] = byte(uint8(48 + _i % 10));
      _i /= 10;
    }

    return string(bstr);
  }
}

// File: erc721o/contracts/ERC721OBackwardCompatible.sol

pragma solidity ^0.5.4;




contract ERC721OBackwardCompatible is ERC721OComposable {
  using UintsLib for uint256;

  // Interface constants
  bytes4 internal constant INTERFACE_ID_ERC721 = 0x80ac58cd;
  bytes4 internal constant INTERFACE_ID_ERC721_ENUMERABLE = 0x780e9d63;
  bytes4 internal constant INTERFACE_ID_ERC721_METADATA = 0x5b5e139f;

  // Reciever constants
  bytes4 internal constant ERC721_RECEIVED = 0x150b7a02;

  // Metadata URI
  string internal baseTokenURI;

  constructor(string memory _baseTokenURI) public ERC721OBase() {
    baseTokenURI = _baseTokenURI;
    _registerInterface(INTERFACE_ID_ERC721);
    _registerInterface(INTERFACE_ID_ERC721_ENUMERABLE);
    _registerInterface(INTERFACE_ID_ERC721_METADATA);
  }

  // ERC721 compatibility
  function implementsERC721() public pure returns (bool) {
    return true;
  }

  /**
    * @dev Gets the owner of a given NFT
    * @param _tokenId uint256 representing the unique token identifier
    * @return address the owner of the token
    */
  function ownerOf(uint256 _tokenId) public view returns (address) {
    if (exists(_tokenId)) {
      return address(this);
    }

    return address(0);
  }

  /**
   *  @dev Gets the number of tokens owned by the address we are checking
   *  @param _owner The adddress we are checking
   *  @return balance The unique amount of tokens owned
   */
  function balanceOf(address _owner) public view returns (uint256 balance) {
    (, uint256[] memory tokens) = tokensOwned(_owner);
    return tokens.length;
  }

  // ERC721 - Enumerable compatibility
  /**
   * @dev Gets the token ID at a given index of all the tokens in this contract
   * Reverts if the index is greater or equal to the total number of tokens
   * @param _index uint256 representing the index to be accessed of the tokens list
   * @return uint256 token ID at the given index of the tokens list
   */
  function tokenByIndex(uint256 _index) public view returns (uint256) {
    require(_index < totalSupply());
    return allTokens[_index];
  }

  function tokenOfOwnerByIndex(address _owner, uint256 _index) public view returns (uint256 _tokenId) {
    (, uint256[] memory tokens) = tokensOwned(_owner);
    require(_index < tokens.length);
    return tokens[_index];
  }

  // ERC721 - Metadata compatibility
  function tokenURI(uint256 _tokenId) public view returns (string memory tokenUri) {
    require(exists(_tokenId), "Token doesn't exist");
    return string(abi.encodePacked(
      baseTokenURI, 
      _tokenId.uint2str(),
      ".json"
    ));
  }

  /**
   * @dev Gets the approved address for a token ID, or zero if no address set
   * @param _tokenId uint256 ID of the token to query the approval of
   * @return address currently approved for the given token ID
   */
  function getApproved(uint256 _tokenId) public view returns (address) {
    if (exists(_tokenId)) {
      return address(this);
    }

    return address(0);
  }

  function safeTransferFrom(address _from, address _to, uint256 _tokenId) public {
    safeTransferFrom(_from, _to, _tokenId, "");
  }

  function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory _data) public nonReentrant {
    _transferFrom(_from, _to, _tokenId, 1);
    require(
      _checkAndCallSafeTransfer(_from, _to, _tokenId, _data),
      "Sent to a contract which is not an ERC721 receiver"
    );
  }

  function transferFrom(address _from, address _to, uint256 _tokenId) public {
    _transferFrom(_from, _to, _tokenId, 1);
  }

  /**
   * @dev Internal function to invoke `onERC721Received` on a target address
   * The call is not executed if the target address is not a contract
   * @param _from address representing the previous owner of the given token ID
   * @param _to target address that will receive the tokens
   * @param _tokenId uint256 ID of the token to be transferred
   * @param _data bytes optional data to send along with the call
   * @return whether the call correctly returned the expected magic value
   */
  function _checkAndCallSafeTransfer(
    address _from,
    address _to,
    uint256 _tokenId,
    bytes memory _data
  ) internal returns (bool) {
    if (!_to.isContract()) {
      return true;
    }
    bytes4 retval = IERC721Receiver(_to).onERC721Received(
        msg.sender, _from, _tokenId, _data
    );
    return (retval == ERC721_RECEIVED);
  }
}

// File: contracts/Errors/RegistryErrors.sol

pragma solidity 0.5.16;

contract RegistryErrors {
    string constant internal ERROR_REGISTRY_ONLY_INITIALIZER = "REGISTRY:ONLY_INITIALIZER";
    string constant internal ERROR_REGISTRY_ONLY_OPIUM_ADDRESS_ALLOWED = "REGISTRY:ONLY_OPIUM_ADDRESS_ALLOWED";
    
    string constant internal ERROR_REGISTRY_CANT_BE_ZERO_ADDRESS = "REGISTRY:CANT_BE_ZERO_ADDRESS";

    string constant internal ERROR_REGISTRY_ALREADY_SET = "REGISTRY:ALREADY_SET";
}

// File: contracts/Registry.sol

pragma solidity 0.5.16;


/// @title Opium.Registry contract keeps addresses of deployed Opium contracts set to allow them route and communicate to each other
contract Registry is RegistryErrors {

    // Address of Opium.TokenMinter contract
    address private minter;

    // Address of Opium.Core contract
    address private core;

    // Address of Opium.OracleAggregator contract
    address private oracleAggregator;

    // Address of Opium.SyntheticAggregator contract
    address private syntheticAggregator;

    // Address of Opium.TokenSpender contract
    address private tokenSpender;

    // Address of Opium commission receiver
    address private opiumAddress;

    // Address of Opium contract set deployer
    address public initializer;

    /// @notice This modifier restricts access to functions, which could be called only by initializer
    modifier onlyInitializer() {
        require(msg.sender == initializer, ERROR_REGISTRY_ONLY_INITIALIZER);
        _;
    }

    /// @notice Sets initializer
    constructor() public {
        initializer = msg.sender;
    }

    // SETTERS

    /// @notice Sets Opium.TokenMinter, Opium.Core, Opium.OracleAggregator, Opium.SyntheticAggregator, Opium.TokenSpender, Opium commission receiver addresses and allows to do it only once
    /// @param _minter address Address of Opium.TokenMinter
    /// @param _core address Address of Opium.Core
    /// @param _oracleAggregator address Address of Opium.OracleAggregator
    /// @param _syntheticAggregator address Address of Opium.SyntheticAggregator
    /// @param _tokenSpender address Address of Opium.TokenSpender
    /// @param _opiumAddress address Address of Opium commission receiver
    function init(
        address _minter,
        address _core,
        address _oracleAggregator,
        address _syntheticAggregator,
        address _tokenSpender,
        address _opiumAddress
    ) external onlyInitializer {
        require(
            minter == address(0) &&
            core == address(0) &&
            oracleAggregator == address(0) &&
            syntheticAggregator == address(0) &&
            tokenSpender == address(0) &&
            opiumAddress == address(0),
            ERROR_REGISTRY_ALREADY_SET
        );

        require(
            _minter != address(0) &&
            _core != address(0) &&
            _oracleAggregator != address(0) &&
            _syntheticAggregator != address(0) &&
            _tokenSpender != address(0) &&
            _opiumAddress != address(0),
            ERROR_REGISTRY_CANT_BE_ZERO_ADDRESS
        );

        minter = _minter;
        core = _core;
        oracleAggregator = _oracleAggregator;
        syntheticAggregator = _syntheticAggregator;
        tokenSpender = _tokenSpender;
        opiumAddress = _opiumAddress;
    }

    /// @notice Allows opium commission receiver address to change itself
    /// @param _opiumAddress address New opium commission receiver address
    function changeOpiumAddress(address _opiumAddress) external {
        require(opiumAddress == msg.sender, ERROR_REGISTRY_ONLY_OPIUM_ADDRESS_ALLOWED);
        require(_opiumAddress != address(0), ERROR_REGISTRY_CANT_BE_ZERO_ADDRESS);
        opiumAddress = _opiumAddress;
    }

    // GETTERS

    /// @notice Returns address of Opium.TokenMinter
    /// @param result address Address of Opium.TokenMinter
    function getMinter() external view returns (address result) {
        return minter;
    }

    /// @notice Returns address of Opium.Core
    /// @param result address Address of Opium.Core
    function getCore() external view returns (address result) {
        return core;
    }

    /// @notice Returns address of Opium.OracleAggregator
    /// @param result address Address of Opium.OracleAggregator
    function getOracleAggregator() external view returns (address result) {
        return oracleAggregator;
    }

    /// @notice Returns address of Opium.SyntheticAggregator
    /// @param result address Address of Opium.SyntheticAggregator
    function getSyntheticAggregator() external view returns (address result) {
        return syntheticAggregator;
    }

    /// @notice Returns address of Opium.TokenSpender
    /// @param result address Address of Opium.TokenSpender
    function getTokenSpender() external view returns (address result) {
        return tokenSpender;
    }

    /// @notice Returns address of Opium commission receiver
    /// @param result address Address of Opium commission receiver
    function getOpiumAddress() external view returns (address result) {
        return opiumAddress;
    }
}

// File: contracts/Errors/UsingRegistryErrors.sol

pragma solidity 0.5.16;

contract UsingRegistryErrors {
    string constant internal ERROR_USING_REGISTRY_ONLY_CORE_ALLOWED = "USING_REGISTRY:ONLY_CORE_ALLOWED";
}

// File: contracts/Lib/UsingRegistry.sol

pragma solidity 0.5.16;



/// @title Opium.Lib.UsingRegistry contract should be inherited by contracts, that are going to use Opium.Registry
contract UsingRegistry is UsingRegistryErrors {
    // Emitted when registry instance is set
    event RegistrySet(address registry);

    // Instance of Opium.Registry contract
    Registry internal registry;

    /// @notice This modifier restricts access to functions, which could be called only by Opium.Core
    modifier onlyCore() {
        require(msg.sender == registry.getCore(), ERROR_USING_REGISTRY_ONLY_CORE_ALLOWED);
        _;
    }

    /// @notice Defines registry instance and emits appropriate event
    constructor(address _registry) public {
        registry = Registry(_registry);
        emit RegistrySet(_registry);
    }

    /// @notice Getter for registry variable
    /// @return address Address of registry set in current contract
    function getRegistry() external view returns (address) {
        return address(registry);
    }
}

// File: contracts/TokenMinter.sol

pragma solidity 0.5.16;



/// @title Opium.TokenMinter contract implements ERC721O token standard for minting, burning and transferring position tokens
contract TokenMinter is ERC721OBackwardCompatible, UsingRegistry {
    /// @notice Calls constructors of super-contracts
    /// @param _baseTokenURI string URI for token explorers
    /// @param _registry address Address of Opium.registry
    constructor(string memory _baseTokenURI, address _registry) public ERC721OBackwardCompatible(_baseTokenURI) UsingRegistry(_registry) {}

    /// @notice Mints LONG and SHORT position tokens
    /// @param _buyer address Address of LONG position receiver
    /// @param _seller address Address of SHORT position receiver
    /// @param _derivativeHash bytes32 Hash of derivative (ticker) of position
    /// @param _quantity uint256 Quantity of positions to mint
    function mint(address _buyer, address _seller, bytes32 _derivativeHash, uint256 _quantity) external onlyCore {
        _mint(_buyer, _seller, _derivativeHash, _quantity);
    }

    /// @notice Mints only LONG position tokens for "pooled" derivatives
    /// @param _buyer address Address of LONG position receiver
    /// @param _derivativeHash bytes32 Hash of derivative (ticker) of position
    /// @param _quantity uint256 Quantity of positions to mint
    function mint(address _buyer, bytes32 _derivativeHash, uint256 _quantity) external onlyCore {
        _mintLong(_buyer, _derivativeHash, _quantity);
    }

    /// @notice Burns position tokens
    /// @param _tokenOwner address Address of tokens owner
    /// @param _tokenId uint256 tokenId of positions to burn
    /// @param _quantity uint256 Quantity of positions to burn
    function burn(address _tokenOwner, uint256 _tokenId, uint256 _quantity) external onlyCore {
        _burn(_tokenOwner, _tokenId, _quantity);
    }

    /// @notice ERC721 interface compatible function for position token name retrieving
    /// @return Returns name of token
    function name() external view returns (string memory) {
        return "Opium Network Position Token";
    }

    /// @notice ERC721 interface compatible function for position token symbol retrieving
    /// @return Returns symbol of token
    function symbol() external view returns (string memory) {
        return "ONP";
    }

    /// VIEW FUNCTIONS

    /// @notice Checks whether _spender is approved to spend tokens on _owners behalf or owner itself
    /// @param _spender address Address of spender
    /// @param _owner address Address of owner
    /// @param _tokenId address tokenId of interest
    /// @return Returns whether _spender is approved to spend tokens
    function isApprovedOrOwner(
        address _spender,
        address _owner,
        uint256 _tokenId
    ) public view returns (bool) {
        return (
        _spender == _owner ||
        getApproved(_tokenId, _owner) == _spender ||
        isApprovedForAll(_owner, _spender) ||
        isOpiumSpender(_spender)
        );
    }

    /// @notice Checks whether _spender is Opium.TokenSpender
    /// @return Returns whether _spender is Opium.TokenSpender
    function isOpiumSpender(address _spender) public view returns (bool) {
        return _spender == registry.getTokenSpender();
    }
}