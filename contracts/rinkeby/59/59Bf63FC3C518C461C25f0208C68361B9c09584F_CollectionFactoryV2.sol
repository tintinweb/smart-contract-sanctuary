// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2022 SimplrDAO
pragma solidity 0.8.9;

import "openzeppelin-solidity/contracts/access/Ownable.sol";
import "openzeppelin-solidity/contracts/security/Pausable.sol";
import "openzeppelin-solidity/contracts/utils/Address.sol";
import "../../common/utils/CloneFactory.sol";
import "../interface/IAffiliateCollection.sol";

/**
 * @title Collection Factory v2
 * @dev   a single factory to create multiple and various clones of collection.
 */
contract CollectionFactoryV2 is Pausable, Ownable, CloneFactory {
    string public constant VERSION = "0.2";
    address public simplr; // address of simplr beneficiary
    address public affiliateRegistry; // address of affiliate registry
    uint256 public simplrShares; // shares of simplr, eg. 15% = parseUnits(15,16) or toWei(0.15) or 15*10^16
    uint256 public upfrontFee; // upfront fee to start a new collection
    uint256 public totalWithdrawn; // total amount of upfront fee withdrawn from Factory
    bytes32 public affiliateProjectId; // projectId that is used by affiliate registry
    mapping(uint256 => address) public mastercopies; // mapping of collection type to collection master copy

    event CollectionCreated(
        address indexed collection,
        address indexed admin,
        uint256 indexed collectionType
    ); // emitted when new collection contract is created
    event NewCollectionTypeAdded(
        uint256 indexed collectionType,
        address mastercopy,
        bytes data
    ); // emitted when new collection type is added

    /**
     * @dev constructor
     * @param _masterCopy address of implementation contract
     * @param _simplr  address of simplr beneficiary
     * @param _newRegistry upfront fee to start a new collection
     * @param _newProjectId upfront fee to start a new collection
     * @param _simplrShares shares of simplr, eg. 15% = parseUnits(15,16) or toWei(0.15) or 15*10^16
     * @param _upfrontFee upfront fee to start a new collection
     */
    constructor(
        address _masterCopy,
        bytes memory _data,
        address _simplr,
        address _newRegistry,
        bytes32 _newProjectId,
        uint256 _simplrShares,
        uint256 _upfrontFee
    ) {
        require(_masterCopy != address(0), "CFv2:001");
        require(_simplr != address(0), "CFv2:002");
        simplr = _simplr;
        simplrShares = _simplrShares;
        upfrontFee = _upfrontFee;
        affiliateRegistry = _newRegistry;
        affiliateProjectId = _newProjectId;
        _addNewCollectionType(_masterCopy, 1, _data);
    }

    /**
     * @dev set simplr beneficiary address
     * @param _simplr address of simplr beneficiary
     */
    function setSimplr(address _simplr) external onlyOwner {
        require(_simplr != address(0) && simplr != _simplr, "CFv2:003");
        simplr = _simplr;
    }

    /**
     * @dev set new simplr shares
     * @param _simplrShares shares of simplr, eg. 15% = parseUnits(15,16) or toWei(0.15) or 15*10^16
     */
    function setSimplrShares(uint256 _simplrShares) external onlyOwner {
        simplrShares = _simplrShares;
    }

    /**
     * @dev set new upfront fee
     * @param _upfrontFee upfront fee to start a new collection
     */
    function setUpfrontFee(uint256 _upfrontFee) external onlyOwner {
        upfrontFee = _upfrontFee;
    }

    /**
     * @dev set affiliate registry
     * @param _newRegistry upfront fee to start a new collection
     */
    function setAffiliateRegistry(address _newRegistry) external onlyOwner {
        affiliateRegistry = _newRegistry;
    }

    /**
     * @dev set affiliate project id
     * @param _newProjectId upfront fee to start a new collection
     */
    function setAffiliateProjectId(bytes32 _newProjectId) external onlyOwner {
        affiliateProjectId = _newProjectId;
    }

    /**
     * @dev set mastercopy address that will be used for creating collection clones
     * @param _newMastercopy address of new mastercopy
     * @param _type type of collection whose mastercopy needs to be updated
     */
    function setMastercopy(address _newMastercopy, uint256 _type)
        external
        onlyOwner
    {
        require(
            _newMastercopy != address(0) &&
                _newMastercopy != mastercopies[_type],
            "CFv2:004"
        );
        require(mastercopies[_type] != address(0), "CFv2:005");
        mastercopies[_type] = _newMastercopy;
    }

    /**
     * @dev create new collection contract clone
     * @param _baseCollection struct with params to setup base collection
     * @param _presaleable  struct with params to setup presaleable
     * @param _paymentSplitter struct with params to setup payment splitting
     * @param _revealable  struct with params to setup reveal details
     * @param _metadata ipfs hash or CID for the metadata of collection
     */
    function createCollection(
        uint256 _type,
        IAffiliateCollection.BaseCollectionStruct memory _baseCollection,
        IAffiliateCollection.PresaleableStruct memory _presaleable,
        IAffiliateCollection.PaymentSplitterStruct memory _paymentSplitter,
        IAffiliateCollection.RevealableStruct memory _revealable,
        LibPart.Part memory _royalties,
        uint256 _reserveTokens,
        string memory _metadata,
        bool _isAffiliable
    ) external payable whenNotPaused {
        require(msg.value == upfrontFee, "CFv2:006");
        require(mastercopies[_type] != address(0), "CFv2:005");
        address collection = createClone(mastercopies[_type]);
        _paymentSplitter.simplr = simplr;
        _paymentSplitter.simplrShares = simplrShares;
        IAffiliateCollection(collection).setMetadata(_metadata);
        if (_isAffiliable) {
            IAffiliateCollection(collection).setupWithAffiliate(
                _baseCollection,
                _presaleable,
                _paymentSplitter,
                _revealable,
                _royalties,
                _reserveTokens,
                IAffiliateRegistry(affiliateRegistry),
                affiliateProjectId
            );
        } else {
            IAffiliateCollection(collection).setup(
                _baseCollection,
                _presaleable,
                _paymentSplitter,
                _revealable,
                _royalties,
                _reserveTokens
            );
        }
        emit CollectionCreated(collection, _baseCollection.admin, _type);
    }

    /**
     * @dev withdraw the upfront fee
     * @param _value amount of fee to be withdrawn
     */
    function withdraw(uint256 _value) external onlyOwner {
        require(_value <= address(this).balance, "CFv2:008");
        totalWithdrawn += _value;
        Address.sendValue(payable(simplr), _value);
    }

    /**
     * @dev pause the factory, using OpenZeppelin's Pausable.sol
     */
    function pause() external onlyOwner whenNotPaused {
        _pause();
    }

    /**
     * @dev unpause the factory, using OpenZeppelin's Pausable.sol
     */
    function unpause() external onlyOwner whenPaused {
        _unpause();
    }

    /**
     * @dev only owner method to add new collection type
     * @param _mastercopy address of collection mastercopy
     * @param _type type of collection
     * @param _data bytes string to store  arbitrary data about the collection in emitted events eg. explaination about the  type
     */
    function addNewCollectionType(
        address _mastercopy,
        uint256 _type,
        bytes memory _data
    ) external onlyOwner {
        _addNewCollectionType(_mastercopy, _type, _data);
    }

    /**
     * @dev private method to add new collection type
     * @param _mastercopy address of collection mastercopy
     * @param _type type of collection
     * @param _data bytes string to store  arbitrary data about the collection in emitted events eg. explaination about the  type
     */
    function _addNewCollectionType(
        address _mastercopy,
        uint256 _type,
        bytes memory _data
    ) private {
        require(mastercopies[_type] == address(0), "CFv2:009");
        require(_mastercopy != address(0), "CFv2:001");
        mastercopies[_type] = _mastercopy;
        emit NewCollectionTypeAdded(_type, _mastercopy, _data);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

pragma solidity ^0.8.0;

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
    constructor() {
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
    constructor() {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Address.sol)

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
        assembly {
            size := extcodesize(account)
        }
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

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

/*
The MIT License (MIT)
Copyright (c) 2018 Murray Software, LLC.
Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:
The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/
//solhint-disable max-line-length
//solhint-disable no-inline-assembly

contract CloneFactory {
    function createClone(address target) internal returns (address result) {
        bytes20 targetBytes = bytes20(target);
        assembly {
            let clone := mload(0x40)
            mstore(
                clone,
                0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000
            )
            mstore(add(clone, 0x14), targetBytes)
            mstore(
                add(clone, 0x28),
                0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000
            )
            result := create(0, clone, 0x37)
        }
    }

    function isClone(address target, address query)
        internal
        view
        returns (bool result)
    {
        bytes20 targetBytes = bytes20(target);
        assembly {
            let clone := mload(0x40)
            mstore(
                clone,
                0x363d3d373d3d3d363d7300000000000000000000000000000000000000000000
            )
            mstore(add(clone, 0xa), targetBytes)
            mstore(
                add(clone, 0x1e),
                0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000
            )

            let other := add(clone, 0x40)
            extcodecopy(query, other, 0, 0x2d)
            result := and(
                eq(mload(clone), mload(other)),
                eq(mload(add(clone, 0xd)), mload(add(other, 0xd)))
            )
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2022 SimplrDAO
pragma solidity 0.8.9;

import "./ICollectionStruct.sol";
import "../affiliate/IAffiliateRegistry.sol";
import "../../@rarible/royalties/contracts/LibPart.sol";

/**
 * @title Affiliate Collection Interface
 * @dev   interface to interact with setup functionality of affiliate collection.
 */
interface IAffiliateCollection is ICollectionStruct {
    function setupWithAffiliate(
        BaseCollectionStruct memory _baseCollection,
        PresaleableStruct memory _presaleable,
        PaymentSplitterStruct memory _paymentSplitter,
        RevealableStruct memory _revealable,
        LibPart.Part memory _royalties,
        uint256 _reserveTokens,
        IAffiliateRegistry _registry,
        bytes32 _projectId
    ) external;

    function setup(
        BaseCollectionStruct memory _baseCollection,
        PresaleableStruct memory _presaleable,
        PaymentSplitterStruct memory _paymentSplitter,
        RevealableStruct memory _revealable,
        LibPart.Part memory _royalties,
        uint256 _reserveTokens
    ) external;

    function setMetadata(string memory _metadata) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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

// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2022 SimplrDAO
pragma solidity 0.8.9;

/**
 * @title Collection Struct Interface
 * @dev   interface to for all the struct required for setup parameters.
 */
interface ICollectionStruct {
    struct BaseCollectionStruct {
        string name;
        string symbol;
        address admin;
        uint256 maximumTokens;
        uint16 maxPurchase;
        uint16 maxHolding;
        uint256 price;
        uint256 publicSaleStartTime;
        string loadingURI;
    }

    struct PresaleableStruct {
        uint256 presaleReservedTokens;
        uint256 presalePrice;
        uint256 presaleStartTime;
        uint256 presaleMaxHolding;
        address[] presaleWhitelist;
    }

    struct PaymentSplitterStruct {
        address simplr;
        uint256 simplrShares;
        address[] payees;
        uint256[] shares;
    }

    struct RevealableStruct {
        bytes32 projectURIProvenance;
        uint256 revealAfterTimestamp;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2022 SimplrDAO
pragma solidity 0.8.9;

interface IAffiliateRegistry {
    function setAffiliateShares(uint256 _affiliateShares, bytes32 _projectId)
        external;

    function registerProject(string memory projectName, uint256 affiliateShares)
        external
        returns (bytes32 projectId);

    function getProjectId(string memory _projectName, address _projectOwner)
        external
        view
        returns (bytes32 projectId);

    function getAffiliateShareValue(
        bytes memory signature,
        address affiliate,
        bytes32 projectId,
        uint256 value
    ) external view returns (bool _isAffiliate, uint256 _shareValue);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library LibPart {
    bytes32 public constant TYPE_HASH =
        keccak256("Part(address account,uint96 value)");

    struct Part {
        address payable account;
        uint96 value;
    }

    function hash(Part memory part) internal pure returns (bytes32) {
        return keccak256(abi.encode(TYPE_HASH, part.account, part.value));
    }
}