// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "openzeppelin-solidity/contracts/access/Ownable.sol";
import "openzeppelin-solidity/contracts/security/Pausable.sol";
import "../common/utils/CloneFactory.sol";
import "./ICollection.sol";

contract CollectionFactory is Pausable, Ownable, CloneFactory {
    address public mastercopy; //address of mastercopy of Project contract.
    address public nftify; // address of nftify beneficiary
    uint256 public nftifyShares; // shares of nftify, eg. 15% = parseUnits(15,16) or toWei(0.15) or 15*10^16
    uint256 public upfrontFee; // upfront fee to start a new project
    uint256 public totalWithdrawn; // total amount of upfront fee withdrawn from Factory

    event CollectionCreated(address indexed project, address indexed admin); // emitted when new project contract is created

    /**
     * @dev constructor
     * @param _masterCopy address of implementation contract
     * @param _nftify  address of nftify beneficiary
     * @param _nftifyShares shares of nftify, eg. 15% = parseUnits(15,16) or toWei(0.15) or 15*10^16
     * @param _upfrontFee upfront fee to start a new project
     */
    constructor(
        address _masterCopy,
        address _nftify,
        uint256 _nftifyShares,
        uint256 _upfrontFee
    ) {
        require(
            _masterCopy != address(0),
            "CollectionFactory: Master Copy address cannot be zero"
        );
        require(
            _nftify != address(0),
            "CollectionFactory: NFTify address cannot be zero"
        );
        mastercopy = _masterCopy;
        nftify = _nftify;
        nftifyShares = _nftifyShares;
        upfrontFee = _upfrontFee;
    }

    /**
     * @dev set nftify beneficiary address
     * @param _nftify address of nftify beneficiary
     */
    function setNFTify(address _nftify) external onlyOwner {
        require(
            _nftify != address(0) && nftify != _nftify,
            "CollectionFactory: Invalid nftify address"
        );
        nftify = _nftify;
    }

    /**
     * @dev set new nftify shares
     * @param _nftifyShares shares of nftify, eg. 15% = parseUnits(15,16) or toWei(0.15) or 15*10^16
     */
    function setNFTifyShares(uint256 _nftifyShares) external onlyOwner {
        nftifyShares = _nftifyShares;
    }

    /**
     * @dev set new upfront fee
     * @param _upfrontFee upfront fee to start a new project
     */
    function setUpfrontFee(uint256 _upfrontFee) external onlyOwner {
        upfrontFee = _upfrontFee;
    }

    /**
     * @dev                  set mastercopy address that will be used for creating project clones
     * @param _newMastercopy address of new mastercopy
     */
    function setMastercopy(address _newMastercopy) external onlyOwner {
        require(
            _newMastercopy != address(0) && _newMastercopy != mastercopy,
            "CollectionFactory: Invalid mastercopy"
        );
        mastercopy = _newMastercopy;
    }

    /**
     * @dev create new collection contract clone
     * @param _baseCollection struct with params to setup base collection
     * @param _presaleable  struct with params to setup presaleable
     * @param _paymentSplitter struct with params to setup payment splitting
     * @param _revealable  struct with params to setup reveal details
     * @param _metadata ipfs hash or CID for the metadata of collection
     */
    function createProject(
        ICollection.BaseCollectionStruct memory _baseCollection,
        ICollection.PresaleableStruct memory _presaleable,
        ICollection.PaymentSplitterStruct memory _paymentSplitter,
        ICollection.RevealableStruct memory _revealable,
        string memory _metadata
    ) external payable whenNotPaused {
        require(
            msg.value == upfrontFee,
            "CollectionFactory: transfer exact value"
        );
        address collection = createClone(mastercopy);
        _paymentSplitter.nftify = nftify;
        _paymentSplitter.nftifyShares = nftifyShares;
        ICollection(collection).setMetadata(_metadata);
        ICollection(collection).setup(
            _baseCollection,
            _presaleable,
            _paymentSplitter,
            _revealable
        );
        emit CollectionCreated(collection, _baseCollection.admin);
    }

    /**
     * @dev withdraw the upfront fee
     * @param _value amount of fee to be withdrawn
     */
    function withdraw(uint256 _value) external onlyOwner {
        require(
            _value <= address(this).balance,
            "CollectionFactory: Low balance"
        );
        totalWithdrawn += _value;
        payable(nftify).transfer(_value);
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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface ICollection {
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
        address nftify;
        uint256 nftifyShares;
        address[] payees;
        uint256[] shares;
    }

    struct RevealableStruct {
        bytes32 projectURIProvenance;
        uint256 revealAfterTimestamp;
    }

    function setup(
        BaseCollectionStruct memory _baseCollection,
        PresaleableStruct memory _presaleable,
        PaymentSplitterStruct memory _paymentSplitter,
        RevealableStruct memory _revealable
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