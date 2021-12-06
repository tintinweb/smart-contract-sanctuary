// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./base/ScrewUpERC721MintWhitelistBase.sol";

contract ScrewUpERC721MintWhiteList is ScrewUpERC721MintWhitelistBase {

    mapping (address => uint256) private _whitelists;
   
    constructor(string memory title_,address toMintTokenAddr_) 
        ScrewUpERC721MintWhitelistBase(title_,toMintTokenAddr_){}
    
    function whitelistAddresses (address[] memory users,uint256 amountCanMint) external onlyOwner {
        //Set whitelist and total amount can mint
        for (uint i = 0; i < users.length; i++)
            _whitelists[users[i]] = amountCanMint;
    }
    function addWhitelistMintAmount(address[] memory users,uint256 addAmount) external onlyOwner {
        //Add amount can mint to whitelist if user not whitelist
        //it will automatic set as whitelist.
        for (uint i = 0; i < users.length; i++)
            _whitelists[users[i]] += addAmount;
    }
    function _getMintQuotaFor(address _addr) internal view virtual override returns (uint256){
        return (_addr != address(0)) ? _whitelists[_addr] : 0;
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

import "./ScrewUpMintWhitelistBase.sol";
import "../Interfaces/IScrewUpERC721Whitelist.sol";
import "../Interfaces/IScrewUpERC721Whitelist.sol";
import "../Interfaces/IScrewUpERC721MintForWhitelist.sol";

abstract contract ScrewUpERC721MintWhitelistBase is ScrewUpMintWhitelistBase,IScrewUpERC721Whitelist {

    using SafeMath for uint256;

    constructor(string memory title_ ,address toMintTokenAddr_) 
        ScrewUpMintWhitelistBase(title_,toMintTokenAddr_){}


    function getMintFee() external view virtual override returns(uint256){
        // return mint fee
        return _getBaseMintFee();
    }
    
    //Event when NFT fresh minted.
    event NewNFTMinted(address indexed minter, uint256 tokenId, string tokenURI,bool lastItem);

    function getMintableInfo(address _addr) external view virtual override returns (uint256 mintedCount,uint256 mintableCount){
        return _getMintableInfo(_addr);
    }
    function isWhitelist(address addr) external view virtual override returns(bool){
        return _isWhitelist(addr);
    }
     function canMintMoreAmount(address addr,uint256 add) external view virtual override returns(bool){
        return _canMintMoreAmount(addr,add);
    }
    function mintNFTs(string[] memory tokenURIs) external payable onlyWhitelist {
        //Reject if mint amount is zero.
        uint256 mintAmount = tokenURIs.length;
        require(mintAmount > 0,"Zero amount");
        
        address _tokenAddr = getToMintTokenAddress();
        require(_tokenAddr != address(0),"No token to mint");
        
        require(_canMintMoreAmount(msg.sender, mintAmount),"Limit or No WL");
        
        IScrewUpERC721MintForWhitelist _token = IScrewUpERC721MintForWhitelist(_tokenAddr);
        
        //Check payment in ETH is cover total mint fee.
        uint256 mintFee = _getBaseMintFee();
        uint256 totalMintFee = mintFee.mul(mintAmount);
        require(msg.value >= totalMintFee,"Lag mint fee");
        
        //Allocation minted items return buffer as memory.
        uint256[] memory mintedTokenIds = new uint256[](mintAmount);
        
        //Loop through to mint.
        for (uint256 i = 0; i < mintAmount; i++) 
            mintedTokenIds[i] = _token.whitelistMint(msg.sender,tokenURIs[i]);
        
        //Owner keep mint fee.
        payable(owner()).transfer(totalMintFee);

        //Refund change to minter
        uint256 refunded = msg.value.sub(totalMintFee);
        payable(msg.sender).transfer(refunded);

        for (uint256 i = 0; i < mintAmount; i++) 
            emit NewNFTMinted(msg.sender,mintedTokenIds[i],tokenURIs[i],((i + 1) == mintAmount));
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ScrewUpToMintTokenAddon.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

abstract contract ScrewUpMintWhitelistBase is ScrewUpToMintTokenAddon {

    using SafeMath for uint256;
    
    mapping (address => uint256) private _minterToMintedCount;
    
    //Base mint fee
    uint256 private _baseMintFee = 0.08 ether;

    string private _title;

    constructor(string memory title_ ,address toMintTokenAddr_)
        ScrewUpToMintTokenAddon(toMintTokenAddr_){
            _title = title_;
        }
    
    function getTitle() external view returns (string memory){return _title;}
    function setBaseMintFee (uint256 mintFee) external onlyOwner {
        _baseMintFee = mintFee; //set new base mint fee
    }
    
    function _getBaseMintFee() internal view returns(uint256){
        return  _baseMintFee; // return mint fee
    }
    function _advanceMintAmount (address addr,uint256 amount) internal {
         require(amount > 0,"SCRWL : Amount should more than zero");
        _minterToMintedCount[addr] = _minterToMintedCount[addr].add(amount);
    }
    function _getMintQuotaFor(address _addr) internal view virtual returns (uint256){
        require(_addr != address(0), "SCRWL : Address can't not be Null or Zero");
        return 0;
    }
    function _getMintableInfo(address _addr) internal view returns (uint256 mintedCount,uint256 mintableCount){
        
        require(_addr != address(0), "SCRWL : No mintable info for Zero or Null address");
        mintedCount = _minterToMintedCount[_addr]; //minted count.
        mintableCount = _getMintQuotaFor(_addr); //total mintable count.
    }
    function _isWhitelist(address addr) internal view returns(bool){
        //Check sender as whitelist.
        return (_getMintQuotaFor(addr) > 0);
    }
    function _canMintMoreAmount(address addr,uint256 add) internal view returns(bool){
       require(addr != address(0), "SCRWL : Address can not be Zero or Null address");
       uint256 nextMintAmount = _minterToMintedCount[addr].add(add);
       return nextMintAmount <= _getMintQuotaFor(addr);
    }
    modifier onlyWhitelist() {
        require(owner() == msg.sender || _isWhitelist(msg.sender), "Not Owner or WL");
        _;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of use for all of ScrewUp NFT token.
 */
interface IScrewUpERC721Whitelist {

    //Get Fee in ETH that use to mint.
    function getMintFee() external view returns(uint256);

    //Check address is white list or not.
    function isWhitelist(address addr) external view returns(bool);

    //Check can mint more amount.
    function canMintMoreAmount(address addr,uint256 add) external view returns(bool);

    //Get mintable amount and minted about for addr.
    function getMintableInfo(address addr) external view returns (uint256 mintedCount,uint256 mintableCount);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IScrewUpERC721MintForWhitelist {
    function whitelistMint(address _addr,string memory tokenUri) external returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../Interfaces/IScrewUpERC721Whitelist.sol";

abstract contract ScrewUpToMintTokenAddon is Ownable {

    address private _toMintokenAddress = address(0);

    constructor(address toMintTokenAddr_) {
       _setToMintTokenAddress(toMintTokenAddr_);
    }
    function setToMintTokenAddress (address tokenAddress) external onlyOwner {
       _setToMintTokenAddress(tokenAddress);
    }
    modifier onlyFromTokenToMint() {
        require((owner() == msg.sender || msg.sender == _toMintokenAddress) && (msg.sender != address(0)), "Owner or To mint token");
        _;
    }
    function _setToMintTokenAddress (address tokenAddress) internal {
         _toMintokenAddress = tokenAddress;
         _onToMintTokenAddressSetup(tokenAddress);
    }
    function _onToMintTokenAddressSetup(address tokenAddress) internal virtual{

    }
    function getToMintTokenAddress() public view returns (address){return _toMintokenAddress;}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}