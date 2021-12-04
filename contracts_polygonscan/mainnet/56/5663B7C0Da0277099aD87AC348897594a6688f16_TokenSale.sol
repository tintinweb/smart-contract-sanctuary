// SPDX-License-Identifier: GPL-3.0

pragma solidity  >=0.7.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

interface PriceFeed {
    function decimals() external view returns (uint8);
    function latestAnswer() external view returns (int256);
}

contract TokenSale is Ownable {

    // Address validators
    IERC20 public tokenJAVA; 
    IERC20 public tokenUSDC;
    IERC721 public tokenJavaNFT;
    PriceFeed public priceFeed;
    
    // Min time for next transaction (Anti whale functions)
    uint256 public operationTime = 10 minutes;

    uint16 public minJavaBuy = 300;

    uint16 public beginTokenId = 1;
    
    struct UserInfo {
        uint256 shares; // number of shares for a user
        uint256 lastUserActionTime; // keeps track of the last user action time
        uint256 firstUserActionTime; // Keeps the time for first transaction
    }
    
    mapping(address => UserInfo) public userInfo;

    constructor () {  
        //TOken contract JAVA Matic Network
        tokenJAVA = IERC20(0x4aFaE971Ac146d4028c3Ed581Eb307A1615E59Fe);
        //TOken Contract USDC Matic Network
        tokenUSDC = IERC20(0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174);
        //Token contract Java NFT on Matic Network
        tokenJavaNFT = IERC721(0x7b30339338Ea8d7e1eC85CD383807CD068dEfaF3);
        //Price Feed Matic/Usd
        priceFeed = PriceFeed(0xAB594600376Ec9fD91F8e885dADF0CE036862dE0);
    }

    // Math funtions (sqrt and div)
    function sqrt (uint x) public pure returns (uint y) {
      uint z = (x + 1) / 2;
      y = x;
      while (z < y) {
          y = z;
          z = (x / z + z) / 2;
      }
    }
    
    //Modifiers for to do validations
    modifier validateOperationTime{
        UserInfo storage user = userInfo[msg.sender];
        require(block.timestamp > (user.lastUserActionTime + operationTime), "ERROR: User need wait 10 minutes for next action");
        _;
    }
    
    modifier notContract() {
        require(!_isContract(msg.sender), "contract not allowed");
        _;
    }

    
    function getMult(uint decimals) public pure returns (uint256){
        uint256 result = 1;
        
        for(uint i=0;i< decimals; i++){
            result = result * 10;
        }
        
        return result;
    }
    
    function calculateUsdcByJava(uint256 amountJava) public view returns (uint256){
        
        uint256 decimalsJava = getMult(tokenJAVA.decimals());
        
        require (amountJava >= minJavaBuy * decimalsJava, "ERROR: The amount is below to minimun to buy");
        
        UserInfo storage user = userInfo[msg.sender];
        
        // Get history of shares bought 
        uint256 totalAssetsBought = user.shares;
        
        uint256 totalBuy = amountJava + totalAssetsBought;
        
        require (totalBuy <= 12650 * decimalsJava, "ERROR: The amount is above to 12650 JAVAS");
        
        
        // Do Calcules Count with the amoung bought
        uint256 Buy33 = totalBuy>(4000 * decimalsJava)?(4000 * decimalsJava):totalBuy;
        totalBuy = totalBuy<(4000 * decimalsJava)?0:(totalBuy-(4000 * decimalsJava));
        
        uint256 Buy40 = totalBuy>(2000 * decimalsJava)?(2000 * decimalsJava):totalBuy;
        totalBuy = totalBuy<(2000 * decimalsJava)?0:(totalBuy-(2000 * decimalsJava));
        
        uint256 Buy50 = totalBuy>(2000 * decimalsJava)?(2000 * decimalsJava):totalBuy;
        totalBuy = totalBuy<(2000 * decimalsJava)?0:(totalBuy-(2000 * decimalsJava));
        
        uint256 Buy70 = totalBuy>(2000 * decimalsJava)?(2000 * decimalsJava):totalBuy;
        totalBuy = totalBuy<(2000 * decimalsJava)?0:(totalBuy-(2000 * decimalsJava));
        
        uint256 Buy95 = totalBuy;
        
        
        uint256 amountUSDC = 0; 
        
        // x.33 for the first 4000 Javas
        Buy33 = totalAssetsBought > Buy33?0:(Buy33 - totalAssetsBought);
        amountUSDC = Buy33 / (3030303030303);
        
        // Refresh for the next validation
        totalAssetsBought = totalAssetsBought<(4000 * decimalsJava)?0:(totalAssetsBought-(4000 * decimalsJava));
        
        //x.40 for the second 2000 Javas
        Buy40 = totalAssetsBought > Buy40?0:(Buy40 - totalAssetsBought);
        amountUSDC = amountUSDC + Buy40 / (2500000000000);
        
        // Refresh for the next validation
        totalAssetsBought = totalAssetsBought<(2000 * decimalsJava)?0:(totalAssetsBought-(2000 * decimalsJava));
        
        //x.50 for the second 2000 Javas
        Buy50 = totalAssetsBought > Buy50?0:(Buy50 - totalAssetsBought);
        amountUSDC = amountUSDC + Buy50 / (2000000000000);
        
        // Refresh for the next validation
        totalAssetsBought = totalAssetsBought<(2000 * decimalsJava)?0:(totalAssetsBought-(2000 * decimalsJava));
        
        //x.70 for the second 2000 Javas
        Buy70 = totalAssetsBought > Buy70?0:(Buy70 - totalAssetsBought);
        amountUSDC = amountUSDC + Buy70 / (1428571430000);
        
        // Refresh for the next validation
        totalAssetsBought = totalAssetsBought<(2000 * decimalsJava)?0:(totalAssetsBought-(2000 * decimalsJava));
        
        //x.95 for the second 2000 Javas
        Buy95 = Buy95 - totalAssetsBought;
        amountUSDC = amountUSDC + Buy95 / (1052631580000);
        
        return amountUSDC;
    }
    
    function calculateMaticByJava(uint256 amountJava) public view returns (uint256){

        uint256 decimalsJava = getMult(tokenJAVA.decimals());
          
        require (amountJava >= minJavaBuy * decimalsJava, "ERROR: The amount is below to minimun to buy");
        
        //Get latest price for Matic
        uint256 latestPrice = uint256(priceFeed.latestAnswer());
        
        UserInfo storage user = userInfo[msg.sender];
        
        // Get history of shares bought 
        uint256 totalAssetsBought = user.shares;
        
        uint256 totalBuy = amountJava + totalAssetsBought;
        
        require (totalBuy <= 12650 ether, "ERROR: The amount is above to 12650 JAVAS");
        
        // Do Calcules Count with the amoung bought
        uint256 Buy33 = totalBuy>(4000 ether)?(4000 ether):totalBuy;
        totalBuy = totalBuy<(4000 ether)?0:(totalBuy-(4000 ether));
        
        uint256 Buy40 = totalBuy>(2000 ether)?(2000 ether):totalBuy;
        totalBuy = totalBuy<(2000 ether)?0:(totalBuy-(2000 ether));
        
        uint256 Buy50 = totalBuy>(2000 ether)?(2000 ether):totalBuy;
        totalBuy = totalBuy<(2000 ether)?0:(totalBuy-(2000 ether));
        
        uint256 Buy70 = totalBuy>(2000 ether)?(2000 ether):totalBuy;
        totalBuy = totalBuy<(2000 ether)?0:(totalBuy-(2000 ether));
        
        uint256 Buy95 = totalBuy;
        
        uint256 amountMATIC = 0;
        
        // x.33 on MATIC Price for the first 4000 Javas
        Buy33 = totalAssetsBought > Buy33?0:(Buy33 - totalAssetsBought);
        amountMATIC = ( Buy33 / (3030303 * latestPrice)) * getMult(14);
        
        // Refresh for the next validation
        totalAssetsBought = totalAssetsBought<(4000 ether)?0:(totalAssetsBought-(4000 ether));
        
        // x.40 for the second 2000 Javas
        Buy40 = totalAssetsBought > Buy40?0:(Buy40 - totalAssetsBought);
        amountMATIC = amountMATIC + ( Buy40 / (2500000 * latestPrice)) * getMult(14);
 
        // Refresh for the next validation
        totalAssetsBought = totalAssetsBought<(2000 ether)?0:(totalAssetsBought-(2000 ether));
        
        // x.50 for the second 2000 Javas
        Buy50 = totalAssetsBought > Buy50?0:(Buy50 - totalAssetsBought);
        amountMATIC = amountMATIC + ( Buy50 / (2000000 * latestPrice)) * getMult(14);
        
        // Refresh for the next validation
        totalAssetsBought = totalAssetsBought<(2000 ether)?0:(totalAssetsBought-(2000 ether));
        
        // x.70 for the second 2000 Javas
        Buy70 = totalAssetsBought > Buy70?0:(Buy70 - totalAssetsBought);
        amountMATIC = amountMATIC + ( Buy70 / (1428571 * latestPrice)) * getMult(14);
        
        // Refresh for the next validation
        totalAssetsBought = totalAssetsBought<(2000 ether)?0:(totalAssetsBought-(2000 ether));
        
        // x.95 for the second 2000 Javas
        Buy95 = Buy95 - totalAssetsBought;
        amountMATIC = amountMATIC + ( Buy95 / (1052631 * latestPrice)) * getMult(14);
        
        return amountMATIC;
    }
    
    function getJavaBalance() public view returns (uint){
        return tokenJAVA.balanceOf(address(this));
    }
    
    function acceptSwapUSDC(uint256 amountJAVA) public validateOperationTime notContract{

        uint256 amountUSDC = calculateUsdcByJava(amountJAVA);
        
        
        // Validation Section About Amount of Java on the contract, and the allowance for tokens
        require (tokenJAVA.balanceOf(address(this))>=amountJAVA, "Amount tokens JAVA below for this transaction");
        
        require(
            tokenUSDC.allowance(msg.sender, address(this)) >= amountUSDC,
            "Token allowance too low"
        );
        
        // Tranfers token of swap
        tokenUSDC.transferFrom(msg.sender, owner(), amountUSDC);
        
        tokenJAVA.transfer(msg.sender, amountJAVA);
        
        // Update info user 
        UserInfo storage user = userInfo[msg.sender];
        
        user.shares = user.shares + amountJAVA;
        user.lastUserActionTime = block.timestamp; 
        
        if(user.firstUserActionTime == 0){
            user.firstUserActionTime = block.timestamp;
            tokenJavaNFT.transferFrom(address(this), msg.sender, beginTokenId);
            beginTokenId = beginTokenId + 1;
        }
        
    }
    
    function acceptSwapMATIC(uint256 amountJAVA) public payable validateOperationTime notContract{

        uint256 amountMATIC = calculateMaticByJava(amountJAVA);
        // Validation Section About Amount of Java on the contract, and the allowance for tokens
        require (tokenJAVA.balanceOf(address(this))>=amountJAVA, "Amount tokens JAVA below in this contrat for the transaction");
        
        // Validation Matic Amount
        require(amountMATIC <= msg.value + msg.value/100,"ERROR: Caller has not got enough ETH for Swap");
        
        // Tranfers token of swap
        payable(owner()).transfer(msg.value);
        
        tokenJAVA.transfer(msg.sender, amountJAVA);
        
        // Update info user 
        UserInfo storage user = userInfo[msg.sender];
        
        user.shares = user.shares + amountJAVA;
        user.lastUserActionTime = block.timestamp; 
        
        if(user.firstUserActionTime == 0){
            user.firstUserActionTime = block.timestamp;
            tokenJavaNFT.transferFrom(address(this), msg.sender, beginTokenId);
            beginTokenId = beginTokenId + 1;
        }
    }

    receive() external payable {}
    
    // Validations for whales
    function _isContract(address addr) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(addr)
        }
        return size > 0;
    }
    
     /**
     * @notice It allows the admin to recover wrong tokens sent to the contract
     * @param _tokenAddress: the address of the token to withdraw
     * @param _tokenAmount: the number of token amount to withdraw
     * @dev Only callable by owner.
     */
    function recoverWrongTokens(address _tokenAddress, uint256 _tokenAmount) external onlyOwner {
        IERC20(_tokenAddress).transfer(owner(), _tokenAmount);
    }
    
     /**
     * @notice It allows the admin to recover ethereum sent to the contract
     * @param _amount: the number of eth amount to withdraw
     * @dev Only callable by owner.
     */
    function recoverEthereum(uint256 _amount) external onlyOwner {
        payable(owner()).transfer(_amount);
    }

    function setMinJavaBuy(uint16 _minJavaBuy) external onlyOwner{
        minJavaBuy = _minJavaBuy;
    }

    function setBeginTokenId(uint16 _beginTokenId) external onlyOwner{
        beginTokenId = _beginTokenId;
    }
    
     /**
     * @notice It allows the admin to recover wrong tokens sent to the contract
     * @param _tokenAddress: the address of the token to withdraw
     * @param _tokenId: the id of token to withdraw
     * @dev Only callable by owner.
     */
    function recoverNFT(address _tokenAddress, uint256 _tokenId) external onlyOwner{
        IERC721(_tokenAddress).transferFrom(address(this), owner(), _tokenId);
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