/**
 *Submitted for verification at Etherscan.io on 2021-11-27
*/

// File: @openzeppelin/contracts/utils/Context.sol



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
    constructor() {
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: contracts/HowlStore.sol


pragma solidity ^0.8.2;


interface IHowl {
    function equipProperties(
        address _caller,
        uint256 _tokenId,
        uint16[8] calldata _w
    ) external;
}

interface ISoul {
    function mint(address _address, uint256 _amount) external;

    function collectAndBurn(address _address, uint256 _amount) external;
}

contract HowlStore is Ownable {
    constructor(address _howlContractAddress, address _soulContractAddress)
        Ownable()
    {
        howlContractAddress = _howlContractAddress;
        soulContractAddress = _soulContractAddress;
    }

    address public howlContractAddress;
    address public soulContractAddress;

    function setHowlContractAddress(address _address) external onlyOwner {
        howlContractAddress = _address;
    }

    function setSoulContractAddress(address _address) external onlyOwner {
        soulContractAddress = _address;
    }

    event StorePurchase(
        uint256 indexed _tokenId,
        address indexed _address,
        uint16[8] _properties,
        uint16 _remainingQty
    );

    struct StoreItem {
        uint16[8] properties;
        uint16 qty;
        uint128 soulPrice;
    }

    mapping(uint256 => StoreItem) public store;

    function addStoreItem(
        uint256 _slot,
        uint16[8] calldata properties,
        uint16 _qty,
        uint128 _soulPrice
    ) external onlyOwner {
        store[_slot] = StoreItem(properties, _qty, _soulPrice);
    }

    function deleteStoreItems(uint256[] calldata _slotsToDelete)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < _slotsToDelete.length; i++) {
            delete store[_slotsToDelete[i]];
        }
    }

    function buyStoreItem(uint256 _tokenId, uint256 _slot) external {
        StoreItem storage item = store[_slot];

        require(item.qty > 0, "HOWL Store: item is sold out or doesn't exist");
        item.qty -= 1;

        ISoul(soulContractAddress).collectAndBurn(msg.sender, item.soulPrice);
        IHowl(howlContractAddress).equipProperties(
            msg.sender, // howl will verify that this address owns the token
            _tokenId,
            item.properties
        );

        emit StorePurchase(_tokenId, msg.sender, item.properties, item.qty);
    }
}