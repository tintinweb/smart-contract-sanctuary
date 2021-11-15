// SPDX-License-Identifier: MIT
pragma solidity >=0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./interfaces/IController.sol";
import "./interfaces/IFIL.sol";
import "./utils/EnumerableMap.sol";

contract Factory is Ownable {
    using EnumerableMap for EnumerableMap.RequestMap;

    IController public controller;
    EnumerableMap.RequestMap mintRequests;
    EnumerableMap.RequestMap burnRequests;

    modifier onlyCustodian() {
        require(controller.custodian() == address(msg.sender), "sender not a custodian.");
        _;
    }

    event SetController(address indexed controller);
    event MintRequestAdd(
        address indexed requester,
        uint            amount,
        string          filDepositAddress,
        string          filCid,
        uint            timestamp,
        bytes32         hash
    );
    event MintRequestCancel(address indexed requester, string cid);
    event MintConfirmed(
        address indexed requester,
        uint            amount,
        string          filDepositAddress,
        string          filCid,
        uint            timestamp,
        bytes32         hash
    );
    event MintRejected(
        address indexed requester,
        uint            amount,
        string          filDepositAddress,
        string          filCid,
        uint            timestamp,
        bytes32         hash
    );
    event Burned(
        address indexed requester,
        uint            amount,
        string          filDepositAddress,
        uint            timestamp,
        bytes32         hash
    );
    event BurnConfirmed(
        address indexed requester,
        uint            amount,
        string          filDepositAddress,
        string          filCid,
        uint            timestamp,
        bytes32         hash
    );

    function setController(IController _controller) external onlyOwner {
        require(address(_controller) != address(0), "invalid controller address");
        controller = _controller;
        emit SetController(address(controller));
    }

    function addMintRequest(uint amount, string calldata filCid) external returns (bool) {
        uint timestamp = getTimestamp();
        bytes32 hash = calcRequestHash(filCid);
        string memory filDepositAddress = controller.filDepositAddress();

        EnumerableMap.Request memory request = EnumerableMap.Request({
            requester:         msg.sender,
            amount:            amount,
            filDepositAddress: filDepositAddress,
            filCid:            filCid,
            timestamp:         timestamp,
            status:            EnumerableMap.Status.PENDING,
            hash:              hash
        });

        require(mintRequests.add(request), "mint request has exists");
        emit MintRequestAdd(msg.sender, amount, filDepositAddress, filCid, timestamp, hash);

        return true;
    }

    function cancelMintRequest(string calldata cid) external returns (bool) {
        bytes32 key = calcRequestHash(cid);
        (bool exists, EnumerableMap.Request storage request) = mintRequests.getByKey(key);

        require(exists, "mint request does not exists");
        require(msg.sender == request.requester, "cancel sender is different than pending request initiator");
        require(request.status == EnumerableMap.Status.PENDING, "request has executed");
        require(mintRequests.remove(key), "request cancel error");

        emit MintRequestCancel(msg.sender, cid);
        return true;
    }

    function confirmMintRequest(string calldata cid) external onlyCustodian returns (bool) {
        bytes32 key = calcRequestHash(cid);
        (bool exists, EnumerableMap.Request storage request) = mintRequests.getByKey(key);

        require(exists, "mint request does not exists");
        require(request.status == EnumerableMap.Status.PENDING, "request has executed");

        request.status = EnumerableMap.Status.APPROVED;
        controller.mint(request.requester, request.amount);

        emit MintConfirmed(
            request.requester,
            request.amount,
            request.filDepositAddress,
            request.filCid,
            request.timestamp,
            request.hash
        );
        return true;
    }

    function rejectMintRequest(string calldata cid) external onlyCustodian returns (bool) {
        bytes32 key = calcRequestHash(cid);
        (bool exists, EnumerableMap.Request storage request) = mintRequests.getByKey(key);

        require(exists, "mint request does not exists");
        require(request.status == EnumerableMap.Status.PENDING, "request has executed");

        request.status = EnumerableMap.Status.REJECTED;
        emit MintRejected(
            request.requester,
            request.amount,
            request.filDepositAddress,
            request.filCid,
            request.timestamp,
            request.hash
        );
        return true;
    }

    function burn(uint amount, string calldata filDepositAddress) external returns (bool) {
        require(bytes(filDepositAddress).length != 0, "fil withdraw address was not set");

        IFIL eFIL = IFIL(controller.token());
        uint timestamp = getTimestamp();
        bytes32 key = calcRequestHash(msg.sender, amount, filDepositAddress, timestamp);

        EnumerableMap.Request memory request = EnumerableMap.Request({
            requester:         msg.sender,
            amount:            amount,
            filDepositAddress: filDepositAddress,
            filCid:            "",
            timestamp:         timestamp,
            status:            EnumerableMap.Status.PENDING,
            hash:              key
        });

        require(burnRequests.add(request), "burn request has exists");
        eFIL.transferFrom(msg.sender, address(controller), amount);
        controller.burn(amount);

        emit Burned(msg.sender, amount, filDepositAddress, timestamp, key);
        return true;
    }

    function confirmBurnRequest(bytes32 key, string calldata filCid) external onlyCustodian returns (bool) {
        require(key.length != 0, "withdraw hash was not set");
        require(bytes(filCid).length != 0, "fil cid was not set");

        (bool exists, EnumerableMap.Request storage request) = burnRequests.getByKey(key);
        require(exists, "mint request does not exists");
        require(request.status == EnumerableMap.Status.PENDING, "request has executed");

        request.status = EnumerableMap.Status.APPROVED;
        request.filCid = filCid;

        emit BurnConfirmed(
            request.requester,
            request.amount,
            request.filDepositAddress,
            filCid,
            request.timestamp,
            request.hash
        );
        return true;
    }

    /**
     * View functions
     */

    function getMintRequestsLength() external view returns (uint) {
        return mintRequests.getLen();
    }

    function getBurnRequestsLength() external view returns (uint) {
        return burnRequests.getLen();
    }

    function getMintRequest(uint index) external view returns (EnumerableMap.Request memory) {
        return mintRequests.getByIndex(index);
    }

    function getBurnRequest(uint index) external view returns (EnumerableMap.Request memory) {
        return burnRequests.getByIndex(index);
    }

    function getTimestamp() internal view returns (uint) {
        // timestamp is only used for data maintaining purpose, it is not relied on for critical logic.
        return block.timestamp; // solhint-disable-line not-rely-on-time
    }

    function calcRequestHash(string calldata cid) internal pure returns (bytes32){
        return keccak256(abi.encode(cid));
    }

    function calcRequestHash(
        address requester,
        uint amount,
        string calldata filDepositAddress,
        uint timestamp
    ) internal pure returns (bytes32) {
        return keccak256(abi.encode(requester, amount, filDepositAddress, timestamp));
    }

    function getStatusString(EnumerableMap.Status status) external pure returns (string memory) {
        if (status == EnumerableMap.Status.PENDING) {
            return "pending";
        } else if (status == EnumerableMap.Status.CANCELED) {
            return "canceled";
        } else if (status == EnumerableMap.Status.APPROVED) {
            return "approved";
        } else if (status == EnumerableMap.Status.REJECTED) {
            return "rejected";
        } else {
            return "unknown";
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    constructor () internal {
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

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.6;

interface IController {
    function mint(address _to, uint _amount) external;
    function burn(uint _amount) external;

    function token() external view returns (address);
    function custodian() external view returns (address);
    function filDepositAddress() external view returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IFIL is IERC20 {
    function mint(address _to, uint _amount) external;
    function burn(uint _amount) external;

    function pause() external;
    function unpause() external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.6;
pragma abicoder v2;

library EnumerableMap {
    enum Status { PENDING, CANCELED, APPROVED, REJECTED }

    struct Request {
        address requester;         // sender of the request.
        uint    amount;            // amount of eFil to mint/burn.
        string  filDepositAddress; // custodian's fil address in mint, member's fil address in burn.
        string  filCid;            // filecoin cid for sending/redeeming fil in the mint/burn process.
        uint    timestamp;         // time of the request creation.
        Status  status;            // status of the request.
        bytes32 hash;
    }

    struct RequestMap {
        // Storage of map keys and values
        Request[] _entries;

        // Position of the entry defined by a key in the `entries` array, plus 1
        // because index 0 means a key is not in the map.
        mapping(bytes32 => uint) _indexes;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function add(RequestMap storage map, Request memory value) internal returns (bool) {
        // We read and store the key's index to prevent multiple reads from the same storage slot
        uint256 keyIndex = map._indexes[value.hash];

        if (keyIndex == 0) { // Equivalent to !contains(map, key)
            map._entries.push(value);
            // The entry is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            map._indexes[value.hash] = map._entries.length;
            return true;
        } else {
            map._entries[keyIndex - 1] = value;
            return false;
        }
    }

    /**
     * @dev Removes a key-value pair from a map. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(RequestMap storage map, bytes32 key) internal returns (bool) {
        // We read and store the key's index to prevent multiple reads from the same storage slot
        uint256 keyIndex = map._indexes[key];

        if (keyIndex != 0) { // Equivalent to contains(map, key)
            // To delete a key-value pair from the _entries array in O(1), we swap the entry to delete with the last one
            // in the array, and then remove the last entry (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = keyIndex - 1;
            uint256 lastIndex = map._entries.length - 1;

            // When the entry to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            Request storage lastEntry = map._entries[lastIndex];

            // Move the last entry to the index where the entry to delete is
            map._entries[toDeleteIndex] = lastEntry;
            // Update the index for the moved entry
            map._indexes[lastEntry.hash] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved entry was stored
            map._entries.pop();

            // Delete the index for the deleted slot
            delete map._indexes[key];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function exists(RequestMap storage map, bytes32 key) internal view returns (bool) {
        return map._indexes[key] != 0;
    }

    /**
     * @dev Tries to returns the value associated with `key`.  O(1).
     * Does not revert if `key` is not in the map.
     */
    function getByKey(RequestMap storage map, bytes32 key) internal view returns (bool, Request storage) {
        uint256 keyIndex = map._indexes[key];
        if (keyIndex == 0) return (false, map._entries[0]); // Equivalent to contains(map, key)
        return (true, map._entries[keyIndex - 1]); // All indexes are 1-based
    }

   /**
    * @dev Returns the key-value pair stored at position `index` in the map. O(1).
    *
    * Note that there are no guarantees on the ordering of entries inside the
    * array, and it may change when more entries are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function getByIndex(RequestMap storage map, uint index) internal view returns (Request storage) {
        require(map._entries.length > index, "EnumerableMap: index out of bounds");

        Request storage entry = map._entries[index];
        return entry;
    }

    function getLen(RequestMap storage map) internal view returns (uint) {
        return map._entries.length;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

