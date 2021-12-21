// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./IRiskToken.sol";

contract RiskMinter is Ownable, ReentrancyGuard {

    // ======== Supply =========
    uint256 public constant MAX_MINTS_PER_TX = 20;
    uint256 public maxMintsPerAddress;
    uint256 public maxTokens;

    // ======== Cost =========
    uint256 public constant TOKEN_COST = 0.07 ether;

    // ======== Sale status =========
    bool public saleIsActive = false;
    uint256 public preSaleStart; // When the whitelist claiming/minting starts
    uint256 public publicSaleStart; // Public sale start (20 mints per tx, max 200 mints per address)

    // ======== Claim Tracking =========
    mapping(address => uint256) private addressToMintCount;
    mapping(address => uint256) private saleWhitelist;

    // ======== External Storage Contract =========
    IRiskToken public riskToken;

    // ======== Constructor =========
    constructor(address riskNftAddress,
                uint256 preSaleStartTimestamp,
                uint256 publicSaleStartTimestamp,
                uint256 riskTokenSupply,
                uint256 maxMintsAddress) {
        riskToken = IRiskToken(riskNftAddress);
        preSaleStart = preSaleStartTimestamp;
        publicSaleStart = publicSaleStartTimestamp;
        maxTokens = riskTokenSupply;
        maxMintsPerAddress = maxMintsAddress;
    }

    // ======== Claim / Minting =========
    function mintPublic(uint amount) public payable nonReentrant {
        uint256 supply = riskToken.tokenCount();
        require(saleIsActive, "Sale must be active to claim!");
        require(block.timestamp >= preSaleStart, "Sale not started!");
        require(amount <= MAX_MINTS_PER_TX, "Exceeds max mint per tx!");
        require(addressToMintCount[msg.sender] + amount <= maxMintsPerAddress, "Exceeded wallet mint limit!");

        // Whitelist period
        if (block.timestamp < publicSaleStart) {
            require(saleWhitelist[msg.sender] > 0, "Must be on the sale whitelist");
        }

        require(supply + amount <= maxTokens, "Exceeds max hero supply!");
        require(msg.value >= TOKEN_COST * amount, "Invalid ETH value sent!");

        riskToken.mint(amount, msg.sender);

        addressToMintCount[msg.sender] += amount;
        
        if (block.timestamp < publicSaleStart) {
            saleWhitelist[msg.sender] -= amount;
        }
    }

    function reserveTeamTokens(address _to, uint256 _reserveAmount) public onlyOwner {
        uint256 supply = riskToken.tokenCount();
        require(supply + _reserveAmount <= maxTokens, "Exceeds max hero supply!");
        riskToken.mint(_reserveAmount, _to);
    }

    // ========  Whitelisting 
    function addWhitelisted(address[] memory _addresses, uint[] memory _tokensToClaim) external onlyOwner {
        require(_addresses.length == _tokensToClaim.length, "Invalid whitelist data");
        for (uint256 i = 0; i < _addresses.length; i++) {
            saleWhitelist[_addresses[i]] = _tokensToClaim[i];
        }
    }

    // ======== Max Minting =========
    function setMaxMintPerAddress(uint _max) public onlyOwner {
        maxMintsPerAddress = _max;
    }

    // ======== Utilities =========
    function remainingWhitelistTokensForClaim(address _address) external view returns (uint) {
        return saleWhitelist[_address];
    }

    function mintCount(address _address) external view returns (uint) {
        return addressToMintCount[_address];
    }

    function isPreSaleActive() external view returns (bool) {
        return block.timestamp >= preSaleStart && block.timestamp < publicSaleStart && saleIsActive;
    }

    function isPublicSaleActive() external view returns (bool) {
        return block.timestamp >= publicSaleStart && saleIsActive;
    }

    // ======== State management =========
    function flipSaleStatus() public onlyOwner {
        saleIsActive = !saleIsActive;
    }

    // ======== Withdraw =========
    function withdraw() public payable onlyOwner {
        uint balance = address(this).balance;
        require(payable(msg.sender).send(balance));
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

// Contract based on https://docs.openzeppelin.com/contracts/3.x/erc721
// SPDX-License-Identifier: MIT
/// @title Interface for RiskToken

pragma solidity ^0.8.6;

abstract contract IRiskToken {

    function setProvenanceHash(string memory _provenanceHash) virtual external;

    function mint(uint256 _count, address _recipient) virtual external;

    function setBaseURI(string memory baseURI) virtual external;

    function updateMinter(address _minter) virtual external;

    function lockMinter() virtual external;
    
    function tokenCount() virtual external returns (uint256);
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