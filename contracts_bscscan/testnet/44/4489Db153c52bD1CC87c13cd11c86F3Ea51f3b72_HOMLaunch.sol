//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
pragma abicoder v2;

import '@openzeppelin/contracts/security/ReentrancyGuard.sol';

import './Launch.sol';

interface HOMMint {
    function tofuMint(uint256 power, address buyer) external payable;

    function rareArtifactsPurchased() external view returns (uint256);

    function epicArtifactsPurchased() external view returns (uint256);

    function legendaryArtifactsPurchased() external view returns (uint256);

    function mythicArtifactsPurchased() external view returns (uint256);

    // uint256 quantity, string memory uri, uint256 price, uint256 tofuPrice
    function rareSupply()
        external
        view
        returns (
            uint256,
            string memory,
            uint256,
            uint256
        );

    function epicSupply()
        external
        view
        returns (
            uint256,
            string memory,
            uint256,
            uint256
        );

    function legendarySupply()
        external
        view
        returns (
            uint256,
            string memory,
            uint256,
            uint256
        );

    function mythicSupply()
        external
        view
        returns (
            uint256,
            string memory,
            uint256,
            uint256
        );
}

contract HOMLaunch is Launch, ReentrancyGuard {
    HOMMint public _nft;

    event BuyCrate(address indexed _from, uint256 indexed power);

    constructor(HOMMint nft, uint256 startTime) Launch(startTime, new uint256[](0)) {
        _nft = nft;
    }

    // update minter address
    function setNFT(HOMMint nft) external onlyOwner {
        _nft = nft;
    }

    // functions ---
    function buyCrate(uint256 power) public payable nonReentrant {
        uint256[4] memory prices = getPrices();
        require(msg.value >= prices[power], 'not enough money');

        // bypass 90% of the payment
        uint256 value = (msg.value * 9) / 10;
        // mint nft
        _nft.tofuMint{value: value}(power, msg.sender);
        // emit event
        emit BuyCrate(msg.sender, power);
    }

    function getPrices() public view returns (uint256[4] memory) {
        (, , uint256 p0, ) = _nft.rareSupply();
        (, , uint256 p1, ) = _nft.epicSupply();
        (, , uint256 p2, ) = _nft.legendarySupply();
        (, , uint256 p3, ) = _nft.mythicSupply();
        return [p0, p1, p2, p3];
    }

    function getSupplies() public view returns (uint256[4] memory) {
        (uint256 p0, , , ) = _nft.rareSupply();
        (uint256 p1, , , ) = _nft.epicSupply();
        (uint256 p2, , , ) = _nft.legendarySupply();
        (uint256 p3, , , ) = _nft.mythicSupply();
        return [
            p0 - _nft.rareArtifactsPurchased(),
            p1 - _nft.epicArtifactsPurchased(),
            p2 - _nft.legendaryArtifactsPurchased(),
            p3 - _nft.mythicArtifactsPurchased()
        ];
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

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
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/security/Pausable.sol';

abstract contract Launch is Ownable, Pausable {
    uint256 public startTime;
    uint256[] public quotas;

    constructor(uint256 startTime_, uint256[] memory quotas_) {
        startTime = startTime_;
        quotas = quotas_;
    }

    modifier whenStarted() {
        require(block.timestamp > startTime, 'not started yet');
        _;
    }

    modifier hasQuota(uint256 index, uint256 amount) {
        require(quotas[index] >= amount, 'max quota reached');
        _;
    }

    function setStart(uint256 newStart) public onlyOwner {
        startTime = newStart;
    }

    function withdraw(address to, uint256 amount) public onlyOwner {
        payable(to).transfer(amount);
    }

    function takeQuota(uint256 index, uint256 amount)
        internal
        virtual
        whenStarted
        hasQuota(index, amount)
    {
        quotas[index] -= amount;
    }

    function getQuotas() public view returns (uint256[] memory) {
        return quotas;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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