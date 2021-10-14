// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "./access/Ownable.sol";

contract MarketV1Storage is Ownable {
    struct Item {
        address owner;
        address currency;
        uint256 price;
    }
    mapping(uint256 => Item) public items;
    mapping(address => bool) whilelists;

    modifier onlyWhilelist() {
        require(whilelists[_msgSender()], "Storage: only whilelist");
        _;
    }

    function setWhilelist(address _user, bool _isWhilelist) external onlyOwner {
        whilelists[_user] = _isWhilelist;
    }

    function addItem(
        uint256 _nftId,
        address _owner,
        address _currency,
        uint256 _price
    ) public onlyWhilelist {
        items[_nftId] = Item(_owner, _currency, _price);
    }

    function addItems(
        uint256[] memory _nftIds,
        address[] memory _owners,
        address[] memory _currencies,
        uint256[] memory _prices
    ) external onlyWhilelist {
        for (uint256 i = 0; i < _nftIds.length; i++) {
            addItem(_nftIds[i], _owners[i], _currencies[i], _prices[i]);
        }
    }

    function deleteItem(uint256 _nftId) public onlyWhilelist {
        delete items[_nftId];
    }

    function deleteItems(uint256[] memory _nftIds) external onlyWhilelist {
        for (uint256 i = 0; i < _nftIds.length; i++) {
            deleteItem(_nftIds[i]);
        }
    }

    function updateItem(
        uint256 _nftId,
        address _owner,
        address _currency,
        uint256 _price
    ) external onlyWhilelist {
        items[_nftId] = Item(_owner, _currency, _price);
    }

    function getItem(uint256 _nftId)
        external
        view
        returns (
            address,
            address,
            uint256
        )
    {
        return (
            items[_nftId].owner,
            items[_nftId].currency,
            items[_nftId].price
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "../util/Context.sol";

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}