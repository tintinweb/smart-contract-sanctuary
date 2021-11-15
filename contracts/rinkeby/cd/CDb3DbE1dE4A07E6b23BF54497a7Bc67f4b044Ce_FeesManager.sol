// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";

/**
 * @dev {IToken} interface:
 */
interface IToken {
    function transfer(address to, uint256 amount) external;
}

/**
 * @dev {IERC11554k} interface:
 */
interface IERC11554k {
    function originatorOf(uint256 id) external returns (address);
}

/**
 * @dev {FeesManager} contract
 *
 * The account that deploys the contract will be an owner of the contract,
 * which can be later transferred to a different account.
 */
contract FeesManager is Context, Ownable {
    uint256 private constant _percentageFactor = 100;
    uint256 private constant _feesFactor = 10000;
    // Fees splitting addresses.
    address[] public splitters;
    // Fees splitting percentages.
    uint256[] public percentages;
    // ERC11554k contract address.
    address public erc11554k;
    // Exchange contract.
    address public exchange;
    // Accumulated fees.
    mapping(address => mapping(address => uint256)) public fees;
    // Trading fees tiers.
    mapping(uint256 => uint256) public tradingFees;

    event ReceivedFees(uint256 id, address owner, address asset, uint256 fee);
    event ClaimFees(address user, uint256 fees);

    /**
     * @dev Sets `erc11554k` to `newERC11554k`.
     *
     * Requirements:
     *
     * - the caller must be the `owner`.
     */
    function setERC11554k(address newERC11554k) external onlyOwner {
        erc11554k = newERC11554k;
    }

    /**
     * @dev Sets trading fee for an item with `id`.
     *
     * Requirements:
     *
     * - the caller must have the `DEFAULT_ADMIN_ROLE`.
     */
    function setTradingFee(uint256 id, uint256 fee) external onlyOwner {
        tradingFees[id] = fee;
    }

    /**
     * @dev Sets trading fee for an item with `id`.
     *
     * Requirements:
     *
     * - the caller must be the `owner`.
     */
    function setTradingFees(uint256[] calldata ids, uint256[] calldata itemFees)
        external
        onlyOwner
    {
        require(ids.length == itemFees.length, "FeesManager: must have equal lengths");
        for (uint256 i = 0; i < ids.length; ++i) {
            tradingFees[ids[i]] = itemFees[i];
        }
    }

    /**
     * @dev Sets `exchange` to `newExchange`.
     *
     * Requirements:
     *
     * - the caller must be the `owner`.
     */
    function setExchange(address newExchange) external onlyOwner {
        exchange = newExchange;
    }

    /**
     * @dev Sets `percentages` and `splitters` to `newSplitters` and `newPercentages`.
     *
     * Requirements:
     *
     * - the caller must be the `owner`.
     */
    function setSplitting(address[] calldata newSplitters, uint256[] calldata newPercentages)
        external
        virtual
        onlyOwner
    {
        require(
            newSplitters.length >= 2 && newSplitters.length == newPercentages.length,
            "FeesManager: arguments satisfy splitting condition"
        );
        require(
            newSplitters[0] == address(0),
            "FeesManager: must be 0 address, this field for current item owner"
        );
        require(
            newSplitters[1] == address(0),
            "FeesManager: must be 0 address, this field for current item original owner"
        );
        uint256 sum = 0;
        for (uint256 i = splitters.length; i > 0; --i) {
            splitters.pop();
            percentages.pop();
        }
        for (uint256 i = 0; i < newPercentages.length; ++i) {
            sum += newPercentages[i];
            splitters.push(newSplitters[i]);
            percentages.push(newPercentages[i]);
        }
        require(sum == _percentageFactor, "FeesManager: percentages sum must be 100");
    }

    /**
     * @dev Receive fees `fee` from exchange for item with `id`.
     */
    function calculateFee(uint256 id, uint256 amount) public view virtual returns (uint256) {
        return (tradingFees[id] * amount) / _feesFactor;
    }

    /**
     * @dev Check if seizure by admin is allowed for an item with `id` from `owner`.
     */
    function isSeizureAllowed(uint256 id, address owner) public view virtual returns (bool) {
        return false;
    }

    /**
     * @dev Pays for storage of item with `id`.
     */
    function payStorage(uint256 id, address owner) public virtual {}

    /**
     * @dev Receive fees `fee` from exchange for item with `id`.
     * Requirements:
     *
     * - the caller must be the Exchange contract.
     */
    function receiveFees(
        uint256 id,
        address owner,
        address asset,
        uint256 fee
    ) external virtual {
        require(_msgSender() == exchange, "FeesManager: must receive fees from exchange contract");
        address originator = IERC11554k(erc11554k).originatorOf(id);
        fees[asset][owner] += (fee * percentages[0]) / _percentageFactor;
        fees[asset][originator] += (fee * percentages[1]) / _percentageFactor;
        for (uint256 i = 2; i < splitters.length; ++i) {
            fees[asset][splitters[i]] += (fee * percentages[i]) / _percentageFactor;
        }
        emit ReceivedFees(id, owner, asset, fee);
    }

    /**
     * @dev Claim `asset` fees from fees manager.
     */
    function claimFees(address asset) external {
        address claimer = _msgSender();
        uint256 claimed = fees[asset][claimer];
        fees[asset][claimer] = 0;
        if (claimed > 0) {
            IToken(asset).transfer(claimer, claimed);
        }
        emit ClaimFees(claimer, claimed);
    }
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

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

