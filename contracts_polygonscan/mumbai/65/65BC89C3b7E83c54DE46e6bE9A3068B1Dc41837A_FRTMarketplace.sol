// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IFRTNFT {
    function mintNFT(address recipient, string memory _tokenURI) external returns (uint256);
    function approve(address to, uint256 tokenId) external returns (uint256);
    function ownerOf(uint256 tokenId) external view returns (address);
    function transferFrom( address from, address to, uint256 tokenId ) external;
    function tokenURI(uint256 tokenId) external view returns (string memory); 
    // function isApprovedForAll(address owner, address operator) external view returns (bool);
        
}

contract FRTMarketplace is Ownable{

    event MintNFT(uint256, address, string);
    event BuyNFT(uint256, address);
    event UnlistNFT(uint256);
    event ListNFT(uint256);

    IERC20 public baseToken;
    IFRTNFT public baseNFT;
    uint256 public baseTokenReward;
    uint256 public baseNFTPrice;
    mapping(string => bool) public mintedURIs;
    mapping(uint256 => bool) public listedNFTs;
    mapping(address => mapping(uint256 => bool)) public downloadAllowed;
    // mapping(address => uint256) private _baseTokenAllowance;


    constructor( address tokenAddress, address nftAddress ){
        
        baseToken = IERC20(tokenAddress);
        baseNFT = IFRTNFT(nftAddress);
        baseTokenReward = 5*(10**18);
        baseNFTPrice = 5*(10**18);
    }

    /******UPDATE BASE VARIABLES START******/
    function updateBaseAddresses(address _tokenAddress, address _nftAddress ) external onlyOwner{
        baseToken = IERC20(_tokenAddress);
        baseNFT = IFRTNFT(_nftAddress);
    }

    function updateTokenReward(uint256 _baseTokenReward) external onlyOwner{
       baseTokenReward = _baseTokenReward;
    }

    function updateNFTPrice(uint256 _baseNFTPrice) external onlyOwner{
       baseNFTPrice = _baseNFTPrice;
    }
    /******UPDATE BASE VARIABLES END******/

    /******HANDLE NFTs START******/
    function mintNFT(string memory _tokenHash) public{
        uint256 newItemId = baseNFT.mintNFT( msg.sender, _tokenHash);
        
        listedNFTs[newItemId] = true; // we need to list and approve one by one because nfts must be avaliable for sell immidiatly  
        
        if(!mintedURIs[_tokenHash]){
            baseToken.transfer(msg.sender, baseTokenReward);        
            mintedURIs[_tokenHash] = true;
        }
        emit MintNFT(newItemId, msg.sender, _tokenHash);

        // return newItemId;
    }

    function buyNFT(uint256 _tokenId) public {
        require(downloadAllowed[msg.sender][_tokenId] != true, "Already purchased");
        require(listedNFTs[_tokenId]  == true, "Token not listed for sale");
        require(checkAlowance(msg.sender) >= baseNFTPrice, "Transfer amount exceeds allowance");
        
        baseToken.transferFrom(msg.sender, baseNFT.ownerOf(_tokenId), baseNFTPrice);
        downloadAllowed[msg.sender][_tokenId]=true;
        emit BuyNFT(_tokenId, msg.sender);

        // return _rTokenId;
    }

    function downloadNFT(uint256 _tokenId) public view returns(string memory){
        require(downloadAllowed[msg.sender][_tokenId] == true, "Unauthorised!");
        
        return baseNFT.tokenURI(_tokenId);
    }

    // function isDownloadAllowed(address account, uint256 _tokenId) public view returns(bool){ // Only owner of a specific group of entities should be allowed to call this fucn but FOR NOW it's avaliable for anyone
    //     return downloadAllowed[account][_tokenId];
    // }

    function unlistNFT(uint256 _tokenId) public onlyOwner{
        delete listedNFTs[_tokenId];
        emit UnlistNFT(_tokenId);
    }

    function listNFT(uint256 _tokenId) public onlyOwner{
        require(listedNFTs[_tokenId]  != true, "NFT listed already");
        listedNFTs[_tokenId] = true;
        emit ListNFT(_tokenId);

    }
    /******HANDLE NFTs END******/

    /******HELPERS START******/
    function checkAlowance(address _operator) internal view returns (uint256){
        return baseToken.allowance(_operator, address(this));
    }

    function contractTokenBalance() public view returns(uint256){
        return baseToken.balanceOf(address(this));
    }

    function withdrawTokens() public onlyOwner {
        baseToken.transfer(msg.sender, baseToken.balanceOf(address(this)));
    }
    /******HELPERS END******/
 
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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