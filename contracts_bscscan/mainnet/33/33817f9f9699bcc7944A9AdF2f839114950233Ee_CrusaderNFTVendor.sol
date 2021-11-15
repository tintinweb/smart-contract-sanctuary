// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.3;


import "./ICrusaderNFT.sol";
import "./ICrusaderConfiguration.sol";
import "./IUniswapV2Router02.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract CrusaderNFTVendor is Ownable, ReentrancyGuard {
    IERC721 public nft;

    IERC20 public token;

    address public escrow;

    ICrusaderConfiguration public crusaderConfiguration;
    uint public expeditionId;

    mapping(address => uint256) public lastVendorDay;

    bool public paused = false;

    uint256[] public holderBalanceTiers;
    uint256[] public holderCooldownTiers;

    uint256 public pricePerNft;

    IUniswapV2Router02 public uniswapV2Router;

    event ItemVendored(address indexed player, uint256 indexed gameId);

    // The following is a so-called natspec comment,
    // recognizable by the three slashes.
    // It will be shown when the user is asked to
    // confirm a transaction.

    /// sets the escrow account
    function setEscrow(address esc) public onlyOwner {
        escrow = esc;
    }

    /// sets the price per NFT
    function setPricePerNft(uint256 price) public onlyOwner {
        pricePerNft = price;
    }

    /// Set address and buff id for expedition pass, for reward calculation
    function assignConfiguration(address config, uint256 configId) public onlyOwner {
        crusaderConfiguration = ICrusaderConfiguration(config);
        expeditionId = configId;
    }

    ///set holder tiers for NFT vendor. Note that these arrays must be in order from lowest to highest balance
    function setHolderTiers(uint256[] memory balances, uint256[] memory cooldowns) public onlyOwner {
        require(balances.length == cooldowns.length, "holder tier arrays must be equal in length");

        holderBalanceTiers = balances;
        holderCooldownTiers = cooldowns;
    }

    /// set router, for example 0x10ED43C718714eb63d5aA57B78B54704E256024E
    function setRouter(address router) public onlyOwner {
        uniswapV2Router = IUniswapV2Router02(router);
    }

    /// set crusader token
    function setToken(address _token) public onlyOwner {
        token = IERC20(_token);
    }

    /// set crusader token
    function setNft(address nftAddress) public onlyOwner {
        nft = IERC721(nftAddress);
    }

    /// Cooldown until next available vendor
    function cooldown(address player) public view returns (uint256) {

        ICrusaderConfiguration.Config memory config = crusaderConfiguration.getConfiguration(player, expeditionId);

        uint256 currentDay = currentTime() / 86400;

        uint256 holderBalance = token.balanceOf(player);
        
        bool ownsExpedition = compareStrings(config.value, "true");

        if (ownsExpedition) {
            holderBalance += 100000000000 * 10 ** 9; //100B from pass
        }
        
        uint256 baseCooldown = 0;
        for (uint8 i = 0; i < holderBalanceTiers.length; i++) {
            if (holderBalance >= holderBalanceTiers[i]) {
                baseCooldown = holderCooldownTiers[i];
            }
        }

        if (baseCooldown == 0) {
            return 1000000; //return a dummy value for cooldown as there is no base cooldown set, meaning that the vendor is not available for this sender
        }

        //once we have the base cooldown, we compare to the last date and current time to see if there is any cooldown remaining
        uint lastClaimDay = lastVendorDay[player];

        if (lastClaimDay == 0) {
            return 0; //this player has sufficient balance, but has never vendored before, the base time is 0
        }

        if (currentDay == lastClaimDay) {
            return baseCooldown; //the person sold in the same day, so they have the full cooldown
        }

        if ((currentDay - lastClaimDay) > baseCooldown) {
            return 0; //no more remaining cooldown, NFT vendor is available
        }

        //return the difference (meaning there is still time before a cooldown elapses)
        return baseCooldown - (currentDay - lastClaimDay);
    }


    /// Sell you NFT to the vendor?
    function vendor(uint256 nftId, bool forCrusader) nonReentrant public {
        require(!paused, "NFT Vendor is currently paused. Try again later");

        uint256 currentDay = currentTime() / 86400;

        uint256 remainingCooldown = cooldown(msg.sender);

        require(remainingCooldown == 0, "Cooldown not yet over for NFT vendor");

        lastVendorDay[msg.sender] = currentDay;

        nft.transferFrom(msg.sender, escrow, nftId);

        if (forCrusader) {
            // generate the pancake pair path of token -> weth
            address[] memory path = new address[](2);
            path[0] = uniswapV2Router.WETH();
            path[1] = address(token);
            bool swapSuccess = false;
            // make the swap
            try uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: pricePerNft}( //try to swap for tokens, if it fails (bad contract, or whatever other reason, send BNB)
                1, // accept any amount of Tokens above 1 wei (so it will fail if nothing returns)
                path,
                address(msg.sender),
                block.timestamp + 360
            ){
                swapSuccess = true;
            }
            catch {
                swapSuccess = false;
            }

            require(swapSuccess, "Unable to swap for crusader token");
        } else {
            payable(msg.sender).transfer(pricePerNft);
        }

        emit ItemVendored(msg.sender, nftId);
    }


    function currentTime() internal view virtual returns (uint256) {
        return block.timestamp;
    }

    function withdrawBNB(uint256 amount) public onlyOwner {
        require(amount <= address(this).balance, "Contract has insufficient bnb for withdrawal");
        payable(msg.sender).transfer(amount);
    }

    ///withdraw pool
    function withdrawPool(address receiver) public onlyOwner {
        token.transferFrom(address(this), receiver, token.balanceOf(address(this)));
    }

    function setPausedState(bool isPaused) public onlyOwner() {
        paused = isPaused;
    }

    function compareStrings(string memory a, string memory b) internal pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }

    fallback () external payable  {
        //we allow the contract to accept BNB via the fallback
    }

    receive() external payable {
        //we allow the contract to accept BNB via the receive
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.3;

interface ICrusaderConfiguration {
    /**
     *  @dev gets configuration key for a specific player
     */
    function getConfiguration(address player, uint256 configKey) external view returns (Config memory);

    /**
     *  @dev sets configuration key for a specific player
     */
    function setConfiguration(address player, uint256 configKey, string memory configValue, uint256 expiration) external;

    struct Config {
        uint256 configId;
        uint256 expiry;
        string value;
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.3;

interface ICrusaderNFT {
    /**
     *  @dev create an NFT that ties to a specific game object. Must be by an approved minter
     */
    function createNFT(uint gameId) external returns (uint tokenId);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.3;

interface IUniswapV2Router02 {
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;

    function WETH() external pure returns (address);
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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

