// SPDX-License-Identifier: MIT
// Author: Warren Cheng - twtr: @warrenycheng
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
                                                                                 
// 88b           d88              88888888ba                             88         
// 888b         d888              88      "8b                            88         
// 88`8b       d8'88              88      ,8P                            88         
// 88 `8b     d8' 88   ,adPPYba,  88aaaaaa8P'  88       88  8b,dPPYba,   88   ,d8   
// 88  `8b   d8'  88  a8P_____88  88""""""'    88       88  88P'   `"8a  88 ,a8"    
// 88   `8b d8'   88  8PP"""""""  88           88       88  88       88  8888[      
// 88    `888'    88  "8b,   ,aa  88           "8a,   ,a88  88       88  88`"Yba,   
// 88     `8'     88   `"Ybbd8"'  88            `"YbbdP'Y8  88       88  88   `Y8a  

                                                                                 
interface Punk {
    function mint(address receiver) external returns (uint256 mintedTokenId);
}

contract MePunkAuction is Ownable, ReentrancyGuard, Pausable {
    address public mePunk;

    uint256 public remainingMintCount;
    uint256 public maxNFTPurchase;

    uint256 public auctionStartTime;
    uint256 public auctionEndTime;
    uint256 public auctionTimeStep = 60;
    uint256 public totalAuctionTimeSteps;

    uint256 public auctionStartPrice;
    uint256 public auctionEndPrice;

    uint256 public auctionPriceStep = 0.1 ether;
    

    constructor(address _mePunk) {
        mePunk = _mePunk;
        maxNFTPurchase = 3;
        remainingMintCount = 10;
    }

    /**********
     * EVENTS *
     **********/
    event AuctionConfigured(
        uint256 remainingMintCount,
        uint256 maxNFTPurchase,
        uint256 auctionStartTime,
        uint256 auctionEndTime,
        uint256 totalAuctionTimeSteps,
        uint256 auctionStartPrice,
        uint256 auctionEndPrice,
        uint256 auctionPriceStep,
        uint256 auctionTimeStep
    );

    event Minted(address receiver, uint256 numberOfMePunks);

    /******************
     * ADMIN FUNCTION *
     ******************/
    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function pause() external onlyOwner{
            _pause();
    }

    function unpause() external onlyOwner{
            _unpause();
    }

    function setAuction(
        uint256 _remainingMintCount,
        uint256 _maxNFTPurchase,
        uint256 _auctionStartTime,
        uint256 _auctionEndTime,
        uint256 _auctionStartPrice,
        uint256 _auctionEndPrice,
        uint256 _auctionPriceStep,
        uint256 _auctionTimeStep
    ) external onlyOwner {
        remainingMintCount = _remainingMintCount;
        maxNFTPurchase = _maxNFTPurchase;

        auctionStartTime = _auctionStartTime;
        auctionEndTime = _auctionEndTime;

        totalAuctionTimeSteps =
            (_auctionEndTime - _auctionStartTime) /
            _auctionTimeStep;

        auctionStartPrice = _auctionStartPrice;
        auctionEndPrice = _auctionEndPrice;

        auctionPriceStep = _auctionPriceStep;
        auctionTimeStep = _auctionTimeStep;

        emit AuctionConfigured(
            remainingMintCount,
            maxNFTPurchase,
            auctionStartTime,
            auctionEndTime,
            totalAuctionTimeSteps,
            auctionStartPrice,
            auctionEndPrice,
            auctionPriceStep,
            auctionTimeStep
        );
    }

    /*****************
     * USER FUNCTION *
     *****************/

    function getAuctionPrice() public view returns (uint256) {
        require(auctionStartTime != 0, "auctionStartTime not set");
        require(auctionEndTime != 0, "auctionEndTime not set");
        if (block.timestamp < auctionStartTime) {
            return auctionStartPrice;
        }
        uint256 timeSteps = (block.timestamp - auctionStartTime) /
            auctionTimeStep;
        if (timeSteps > totalAuctionTimeSteps) {
            timeSteps = totalAuctionTimeSteps;
        }
        uint256 discount = timeSteps * auctionPriceStep;
        return
            auctionStartPrice > discount
                ? auctionStartPrice - discount
                : auctionEndPrice;
    }

    function auctionBuyMePunk(uint256 numberOfMePunks) public payable whenNotPaused nonReentrant {
        require(tx.origin == msg.sender, "smart contract not allowed to mint");
        require(auctionStartTime != 0, "auctionStartTime not set");
        require(auctionEndTime != 0, "auctionEndTime not set");
        require(block.timestamp >= auctionStartTime, "not yet started");
        require(block.timestamp <= auctionEndTime, "has finished");
        require(
            numberOfMePunks > 0,
            "numberoOfTokens can not be less than or equal to 0"
        );
        require(
            numberOfMePunks <= maxNFTPurchase,
            "numberOfMePunks exceeds purchase limit per tx"
        );
        require(
            numberOfMePunks <= remainingMintCount,
            "numberOfMePunks would exceed remaining mint count for this batch"
        );
        uint256 price = getAuctionPrice();
        require(
            price * numberOfMePunks <= msg.value,
            "Sent ether value is incorrect"
        );
        remainingMintCount -= numberOfMePunks;
        for (uint256 i = 0; i < numberOfMePunks; i++) {
            Punk(mePunk).mint(msg.sender);
        }
        emit Minted(msg.sender, numberOfMePunks);
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
     * by making the `nonReentrant` function external, and make it call a
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