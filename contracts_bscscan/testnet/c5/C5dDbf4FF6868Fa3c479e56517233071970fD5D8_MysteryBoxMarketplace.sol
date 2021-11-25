//SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./interfaces/IERC721Receiver.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/IERC721.sol";

contract MysteryBoxMarketplace is Initializable, OwnableUpgradeable, PausableUpgradeable, ReentrancyGuardUpgradeable, IERC721Receiver{
    address constant public BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;
    
    IERC20 public _elmonToken;
    IERC721 public _nft;

    address public _feeRecepientAddress;
    
    uint256 private _burningFeePercent;       //Multipled by 1000
    uint256 private _ecoFeePercent;       //Multipled by 1000
    uint256 constant public MULTIPLIER = 1000;
    
    //Mapping between tokenId and token price
    mapping(uint256 => uint256) public _tokenPrices;
    
    //Mapping between tokenId and owner of tokenId
    mapping(uint256 => address) public _tokenOwners;

    function initialize(address tokenAddress, address nftAddress, address feeRecepientAddress) public initializer {
        require(tokenAddress != address(0), "Address 0");
        require(nftAddress != address(0), "Address 0");

        __Pausable_init();
        __Ownable_init();
        __ReentrancyGuard_init();
        
        _elmonToken = IERC20(tokenAddress);
        _nft = IERC721(nftAddress);
        _feeRecepientAddress = feeRecepientAddress;
        _burningFeePercent = 2000;              //2%
        _ecoFeePercent = 2000;                  //2%

        emit OwnershipTransferred(address(0), _msgSender());
    }
    
    /**
     * @dev Create a sell order to sell ELEMON
     * User transfer his NFT to contract to create selling order
     * Event is used to retreive logs and histories
     */
    function createSellOrder(uint256 tokenId, uint256 price) external whenNotPaused nonReentrant returns(bool){
        require(price > 0, "Price should be greater than 0");
        require(_tokenOwners[tokenId] == address(0), "Can not create sell order for this token");
        require(_nft.ownerOf(tokenId) == _msgSender(), "You have no permission to create sell order for this token");
        
        //Transfer Elemon NFT to contract
        _nft.safeTransferFrom(_msgSender(), address(this), tokenId);
        
        _tokenOwners[tokenId] = _msgSender();
        _tokenPrices[tokenId] = price;
        
        emit NewSellOrderCreated(_msgSender(), tokenId, price, block.timestamp);
        
        return true;
    }
    
    /**
     * @dev User that created selling order cancels that order
     * Event is used to retreive logs and histories
     */ 
    function cancelSellOrder(uint256 tokenId) external nonReentrant returns(bool){
        require(_tokenOwners[tokenId] == _msgSender(), "Forbidden to cancel sell order");

        //Transfer Elemon NFT from contract to sender
        _nft.safeTransferFrom(address(this), _msgSender(), tokenId);
        
        _tokenOwners[tokenId] = address(0);
        _tokenPrices[tokenId] = 0;
        
        emit SellingOrderCanceled(tokenId, block.timestamp);
        
        return true;
    }

    function manualCancelSellingOrder(uint256 tokenId) external nonReentrant onlyOwner returns(bool){
        require(_tokenOwners[tokenId] != address(0), "Token does not exist on market");

        //Transfer Elemon NFT from contract to sender
        _nft.safeTransferFrom(address(this), _tokenOwners[tokenId], tokenId);
        
        _tokenOwners[tokenId] = address(0);
        _tokenPrices[tokenId] = 0;
        
        emit SellingOrderCanceled(tokenId, block.timestamp);
        
        return true;
    }
    
    /**
     * @dev Get token info about price and owner
     */ 
    function getTokenInfo(uint256 tokenId) external view returns(address, uint256){
        return (_tokenOwners[tokenId], _tokenPrices[tokenId]);
    }
    
    /**
     * @dev Get purchase fee percent, this fee is for seller
     */ 
    function getFeePercent() external view returns(uint256 burningFeePercent, uint256 ecoFeePercent){
        burningFeePercent = _burningFeePercent;
        ecoFeePercent = _ecoFeePercent;
    }
    
    function purchase(uint256 tokenId, uint256 requestPrice) external whenNotPaused nonReentrant returns(uint256){
        address tokenOwner = _tokenOwners[tokenId];
        require(tokenOwner != address(0),"Token has not been added");
        
        uint256 tokenPrice = _tokenPrices[tokenId];
        require(requestPrice == tokenPrice, "Invalid request price");

        uint256 ownerReceived = tokenPrice;
        if(tokenPrice > 0){
            uint256 feeAmount = 0;
            if(_burningFeePercent > 0){
                feeAmount = tokenPrice * _burningFeePercent / 100 / MULTIPLIER;
                if(feeAmount > 0){
                    require(_elmonToken.transferFrom(_msgSender(), BURN_ADDRESS, feeAmount), "Fail to transfer fee to address(0)");
                    ownerReceived -= feeAmount;
                }
            }
            if(_ecoFeePercent > 0){
                feeAmount = tokenPrice * _ecoFeePercent / 100 / MULTIPLIER;
                if(feeAmount > 0){
                    require(_elmonToken.transferFrom(_msgSender(), _feeRecepientAddress, feeAmount), "Fail to transfer fee to eco address");
                    ownerReceived -= feeAmount;
                }
            }
            require(_elmonToken.transferFrom(_msgSender(), tokenOwner, ownerReceived), "Fail to transfer token to owner");
        }
        
        //Transfer Elemon NFT from contract to sender
        _nft.transferFrom(address(this), _msgSender(), tokenId);
        
        _tokenOwners[tokenId] = address(0);
        _tokenPrices[tokenId] = 0;
        
        emit Purchased(_msgSender(), tokenOwner, tokenId, tokenPrice, block.timestamp);
        
        return tokenPrice;
    }

    function setFeeRecepientAddress(address newAddress) external onlyOwner{
        require(newAddress != address(0), "Zero address");
        _feeRecepientAddress = newAddress;
    }
    
    function setNft(address newAddress) external onlyOwner{
        require(newAddress != address(0), "Zero address");
        _nft = IERC721(newAddress);
    }
    
    function setElemonTokenAddress(address newAddress) external onlyOwner{
        require(newAddress != address(0), "Zero address");
        _elmonToken = IERC20(newAddress);
    }
    
    /**
     * @dev Get ELEMON token address 
     */
    function setFeePercent(uint256 burningFeePercent, uint256 ecoFeePercent) external onlyOwner{
        require(burningFeePercent < 100 * MULTIPLIER, "Invalid burning fee percent");
        require(ecoFeePercent < 100 * MULTIPLIER, "Invalid ecosystem fee percent");
        _burningFeePercent = burningFeePercent;
        _ecoFeePercent = ecoFeePercent;
    }

    /**
     * @dev Owner withdraws ERC20 token from contract by `tokenAddress`
     */
    function withdrawToken(address tokenAddress, address recepient) public onlyOwner{
        IERC20 token = IERC20(tokenAddress);
        token.transfer(recepient, token.balanceOf(address(this)));
    }

    /**
     * @dev Owner withdraws ERC20 token from contract by `tokenAddress`
     */
    function withdrawNft(uint256 tokenId, address recepient) public onlyOwner{
        _nft.safeTransferFrom(address(this), recepient, tokenId);
        emit NftWithdrawn(tokenId);
    }

    function pauseContract() external onlyOwner{
        _pause();
    }

    function unpauseContract() external onlyOwner{
        _unpause();
    }
    
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external view override returns (bytes4){
        return bytes4(
                keccak256("onERC721Received(address,address,uint256,bytes)")
            );
    }
    
    event NewSellOrderCreated(address seller, uint256 tokenId, uint256 price, uint256 time);
    event Purchased(address buyer, address seller, uint256 tokenId, uint256 price, uint256 time);
    event SellingOrderCanceled(uint256 tokenId, uint256 time);
    event NftWithdrawn(uint256 tokenId);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
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
    function __Pausable_init() internal initializer {
        __Context_init_unchained();
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}

//SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface IERC721Receiver {
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

//SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./IERC165.sol";

interface IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) external view returns (uint256 balance);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    function transferFrom(address from, address to, uint256 tokenId) external;

    function approve(address to, uint256 tokenId) external;

    function getApproved(uint256 tokenId) external view returns (address operator);

    function setApprovalForAll(address operator, bool _approved) external;

    function isApprovedForAll(address owner, address operator) external view returns (bool);

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
    
    function isExisted(uint256 tokenId) external view returns(bool);
}

//SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

//SPDX-License-Identifier: MIT

pragma solidity 0.8.9;
interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}