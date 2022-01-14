/**
 *Submitted for verification at Etherscan.io on 2022-01-14
*/

// Sources flattened with hardhat v2.8.2 https://hardhat.org

// File @openzeppelin/contracts/utils/[email protected]

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


// File @openzeppelin/contracts/access/[email protected]

// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

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


// File @openzeppelin/contracts/security/[email protected]

// OpenZeppelin Contracts v4.4.0 (security/Pausable.sol)

pragma solidity ^0.8.0;

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


// File @openzeppelin/contracts/security/[email protected]

// OpenZeppelin Contracts v4.4.0 (security/ReentrancyGuard.sol)

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


// File @openzeppelin/contracts/utils/cryptography/[email protected]

// OpenZeppelin Contracts v4.4.0 (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Trees proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merklee tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }
        return computedHash;
    }
}


// File contracts/IERC721Tradable.sol

pragma solidity ^0.8.0;


//Interface needed by crowdsale
abstract contract IERC721Tradable is Ownable{

    function mintTo(address _to) external virtual;

    function getCurrentTokenId() external virtual view returns (uint256);
}


// File contracts/NftCrowdsale.sol

pragma solidity ^0.8.0;






/**
 * @title NftCrowdsale
 * @dev Crowdsale for mintable and tradable ERC721 token.
 */
contract NftCrowdsale is Ownable, Pausable, ReentrancyGuard {
    //Emitted when received transfer is forwarded to the wallet
    event Sent(address indexed payee, uint256 amount);
    //Emitted when token purchased
    event Received(address indexed payer, uint tokenId, uint256 amount, uint256 balance);

    //Address of deployed token contract
    IERC721Tradable public nftTokenAddress;

    //Price of single token in wei
    uint256 public currentPrice;
    //Max amount of token to be minted
    uint256 public maxCap;
    // Address where funds are collected
    address payable private wallet;
    //Max amount of tokens to be minted at once
    uint8 public maxAtOnce;

    bytes32 public whitelistMerkleRoot;

    mapping(address => uint8) public whitelistClaimed;

    uint8 public maxPerWhitelistBuyer;

    uint256 public publicSaleTime;


    /**
    * 0 - initial
    * 1 - white list started
    * 2 - public sale started
    */
    uint8 public saleState;


    modifier whenWhitelistSaleStarted() {
        require(saleState == 1, "Whitelist Sale not active");
        _;
    }

    modifier whenPublicSaleStarted() {
        require(saleState == 2, "Public Sale not active");
        require(block.timestamp >= publicSaleTime, "Public Sale time is yet to come");
        _;
    }

    modifier whenInitialSaleState(){
        require(saleState == 0, "Sale has yet to begin!");
        _;
    }

    /**
   *  Crowdsale constructor
   *  @param _currentPrice - price in wei for single nft token
   *  @param _maxCap - maximum amount of nfts to be minted
   *  @param _wallet - address of the wallet, where the funds should be forwarded after token purchase
   *  @param _nftAddress - address of the already deployed nft token. It has to follow IERC721Tradable interface
   */
    constructor(uint256 _currentPrice, uint256 _maxCap, uint8 _maxAtOnce, uint8 _maxPerWhitelistBuyer, address payable _wallet, address _nftAddress) {
        require(_currentPrice > 0, "NftCrowdsale: price is less than 1.");
        require(_maxCap > 0, "NftCrowdsale: maxCap is less than 1.");
        require(_maxAtOnce > 0, "NftCrowdsale: maxAtOnce is less than 1.");
        require(_maxPerWhitelistBuyer > 0, "NftCrowdsale: maxPerWhitelistBuyer is less than 1.");
        require(_wallet != address(0), "NftCrowdsale: wallet is the zero address.");
        require(_wallet != address(0), "NftCrowdsale: nftAddress is the zero address.");
        nftTokenAddress = IERC721Tradable(_nftAddress);
        currentPrice = _currentPrice;
        maxCap = _maxCap;
        wallet = _wallet;
        maxAtOnce = _maxAtOnce;
        maxPerWhitelistBuyer = _maxPerWhitelistBuyer;
        saleState = 0;
        publicSaleTime = 2**256 - 1;
        _pause();
    }

    /**
    * @dev Purchase
    * mints a new token for the person calling this method (or transferring funds)
    *
    */
    function purchaseToken() public payable whenNotPaused whenPublicSaleStarted nonReentrant {
        require(msg.sender != address(0) && msg.sender != address(this));
        require(msg.value >= currentPrice, "NftCrowdsale: value to small.");
        uint256 currentTokenId = nftTokenAddress.getCurrentTokenId();
        require(currentTokenId < maxCap, "NftCrowdsale: max cap reached.");
        nftTokenAddress.mintTo(msg.sender);
        _forwardFunds();
        emit Received(msg.sender, currentTokenId + 1, msg.value, address(this).balance);
    }

    /**
    * @dev Purchase for receiver
    * mints amount of new tokens for the specified address. WARNING!! transaction can get reverted, if either the amount is too high
     */
    function purchaseTokensFor(address payable receiver, uint256 amount) public payable whenNotPaused whenPublicSaleStarted nonReentrant {
        _purchaseTokensFor(receiver, amount);
    }

    function whitelistPurchaseTokensFor(address payable receiver, bytes32 [] calldata merkleProof) public payable whenNotPaused nonReentrant whenWhitelistSaleStarted {
        require(MerkleProof.verify(merkleProof, whitelistMerkleRoot, keccak256(abi.encodePacked(msg.sender))), "Not on the whitelist.");
        require(whitelistClaimed[msg.sender] < maxPerWhitelistBuyer, "Address has already claimed all the tokens.");
        whitelistClaimed[msg.sender] = whitelistClaimed[msg.sender]++;
        _purchaseTokensFor(receiver, 1);
    }

    function _purchaseTokensFor(address payable receiver, uint256 amount) private {
        require(receiver != address(0) && receiver != address(this));
        require(msg.value >= currentPrice * amount, "NftCrowdsale: value to small.");
        uint256 currentTokenId = nftTokenAddress.getCurrentTokenId();
        require(currentTokenId + amount <= maxCap, "NftCrowdsale: max cap reached.");
        require(amount > 0 && amount <= maxAtOnce, "NftCrowdsale: amount not between 0 and maxAtOnce");

        for (uint i = 0; i < amount; i++) {
            _mintTokenFor(receiver, currentTokenId + i);
        }
        _forwardFunds();
    }


    /**
    * @dev mints token to receiver
    *  This method DOES NOT do any validations and should not be called directly!
    * mints a new token for the specified address
    */
    function _mintTokenFor(address payable receiver, uint256 currentTokenId) private {
        nftTokenAddress.mintTo(receiver);
        emit Received(receiver, currentTokenId + 1, msg.value, address(this).balance);
    }

    /**
       *the address where funds are collected.
       */
    function getWallet() public view returns (address payable) {
        return wallet;
    }

    /**
       *  changes the address where funds are collected.
       */
    function setWallet(address payable _newWallet) public onlyOwner nonReentrant {
        wallet = _newWallet;
    }

    function _forwardFunds() internal {
        wallet.transfer(msg.value);
        emit Sent(wallet, msg.value);
    }

    function setWhitelistMerkleRoot(bytes32 _merkleRoot) public onlyOwner
    {
        whitelistMerkleRoot = _merkleRoot;
    }

    function startWhitelistSale() public onlyOwner whenPaused whenInitialSaleState {
        _unpause();
        saleState = 1;
    }

    function startPublicSale(uint256 _publicSaleTime) public onlyOwner whenNotPaused whenWhitelistSaleStarted {
        saleState = 2;
        publicSaleTime = _publicSaleTime;
    }

    function setPublicSaleTime(uint256 _publicSaleTime) public onlyOwner{
        publicSaleTime = _publicSaleTime;
    }

    function setState(uint8 _newState) public onlyOwner{
        saleState = _newState;
    }

    receive() external payable {
        purchaseToken();
    }
}