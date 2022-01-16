// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./base/ScrewUpERC1155MintWhitelistBase.sol";

contract ScrewUpERC1155PublicMintWhitelist is ScrewUpERC1155MintWhitelistBase {

    uint256 private _hardcapPerPerson;
   
    constructor(string memory title_,address toMintTokenAddr_) 
        ScrewUpERC1155MintWhitelistBase(title_,toMintTokenAddr_){}
    
    function setHardcapPerPerson (uint256 amount) external onlyOwner {
        _hardcapPerPerson = amount;
    }
    function _getMintQuotaFor(address _addr) internal view virtual override returns (uint256){
        return (_addr != address(0)) ? _hardcapPerPerson : 0;
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

import "../Interfaces/IScrewUpERC1155Whitelist.sol";
import "./ScrewUpMintWhitelistBase.sol";
import "../Interfaces/IScrewUpERC1155MintForWhitelist.sol";

abstract contract ScrewUpERC1155MintWhitelistBase is ScrewUpMintWhitelistBase ,IScrewUpERC1155Whitelist {

    using SafeMath for uint256;
    
    //Token Id to mint fee (ETH)
    mapping(uint256 => uint256) _mintFees;
    
    uint256[] private _mintableTokenIds;

    event NewNFTMinted(address indexed minter, uint256 tokenIds,uint256 amount);
   
    constructor(string memory title_,address toMintTokenAddr_) 
        ScrewUpMintWhitelistBase(title_,toMintTokenAddr_){}
    
    function setTokenMintFee (uint256 tokenId, uint256 mintFee) external onlyOwner {
        _mintFees[tokenId] = mintFee; // set new mint fee for tokenId.
    }
    function setMintableTokenIds (uint256[] memory tokenIds) external onlyOwner {
        _mintableTokenIds = tokenIds;
    }

    function getMintFee(uint256 tokenId) external view virtual override returns(uint256){
        return  _getMintFee(tokenId);
    }
    function getMintFees(uint256[] memory tokenIds) external view returns (uint256[] memory){
        uint256[] memory _outFees = new uint256[](tokenIds.length);
        for(uint256 i = 0; i < tokenIds.length; i++)
            _outFees[i] = _getMintFee(tokenIds[i]);
        return _outFees;
    }
    function getMintableInfo(address _addr) external view virtual override returns (uint256 mintedCount,uint256 mintableCount){
        return _getMintableInfo(_addr);
    }
    function isWhitelist(address addr) external view virtual override returns(bool){
       return _isWhitelist(addr);
    }
    function  isMintableTokenId(uint256 tokenId) internal view returns (bool){
         for(uint256 i = 0; i < _mintableTokenIds.length; i++){
             if(_mintableTokenIds[i] == tokenId)
                return true;
         }
         return false;
    }
    function getMintableTokenIds() public view returns (uint256[] memory){
        return _mintableTokenIds;
    }
    function mintBatch(uint256[] memory tokenIds,uint256[] memory amounts) external payable onlyWhitelist {
        require(tokenIds.length == amounts.length,"TokenIds and Amount length mismatch");
        address _tokenAddr = getToMintTokenAddress();
        require(_tokenAddr != address(0),"No token to mint");
        
        IScrewUpERC1155MintForWhitelist _token = IScrewUpERC1155MintForWhitelist(_tokenAddr);
        
        uint256 totalAmount = 0;
        uint256 totalMintFee = 0;
        uint256[] memory trimedAmounts = new uint256[](tokenIds.length);

        for(uint256 i = 0; i < tokenIds.length; i++){
            require(isMintableTokenId(tokenIds[i]),"Id not available for mint");
            uint256 _mintFee = _getMintFee(tokenIds[i]);
            trimedAmounts[i] = _token.whitelistTrimAmountWithMaxSupply(tokenIds[i], amounts[i]);
            totalMintFee = totalMintFee.add(_mintFee.mul(trimedAmounts[i]));
            totalAmount = totalAmount.add(trimedAmounts[i]);
        }

        require(_canMintMoreAmount(msg.sender, totalAmount),"Reach Limit or No WL");

        address mintFeeTokenAddress = getMintFeeTokenAddress();
        bool hasMintFeeToken = (mintFeeTokenAddress != address(0));
        if(hasMintFeeToken)
            require(IERC20(mintFeeTokenAddress).balanceOf(msg.sender) >= totalMintFee,"Insufficient mint fee");
        else
            require(msg.value >= totalMintFee,"Insufficient mint fee");
        
        _token.whitelistMintBatch(msg.sender, tokenIds, trimedAmounts);

        _advanceMintAmount(msg.sender,totalAmount);

        if(hasMintFeeToken){
           IERC20 feeToken = IERC20(mintFeeTokenAddress);
           feeToken.transferFrom(msg.sender, owner(), totalMintFee);
        }
        else 
            payable(owner()).transfer(totalMintFee);
        for(uint256 i = 0; i < tokenIds.length; i++)
           emit NewNFTMinted(msg.sender,tokenIds[i],trimedAmounts[i]);
    }
    function canMintMoreAmount(address addr,uint256 add) external view virtual override returns(bool){
       return _canMintMoreAmount(addr,add);
    }
    function _getMintFee(uint256 tokenId) internal view returns(uint256){
        return  (_mintFees[tokenId] > 0) ? _mintFees[tokenId] : _getBaseMintFee(); // return mint fee
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

/**
 * @dev Interface of use for all of ScrewUp NFT token.
 */
interface IScrewUpERC1155Whitelist {

    //Get Fee in ETH that use to mint.
    function getMintFee(uint256 tokenId) external view returns(uint256);

    //Check address is white list or not.
    function isWhitelist(address addr) external view returns(bool);

    //Check can mint more amount.
    function canMintMoreAmount(address addr,uint256 add) external view returns(bool);

    //Get mintable amount and minted about for addr.
    function getMintableInfo(address addr) external view returns (uint256 mintedCount,uint256 mintableCount);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ScrewUpToMintTokenAddon.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

abstract contract ScrewUpMintWhitelistBase is ScrewUpToMintTokenAddon {

    using SafeMath for uint256;
    
    mapping (address => uint256) private _minterToMintedCount;
    
    //Base mint fee
    uint256 private _baseMintFee = 0;

    string private _title;

    address private _mintFeeTokenAddress = address(0);

    uint256 private _maxLimitToMint = 0;

    uint256 private _currentMintAmount = 0;

    constructor(string memory title_ ,address toMintTokenAddr_)
        ScrewUpToMintTokenAddon(toMintTokenAddr_){
            _title = title_;
        }
    
    function getTitle() external view returns (string memory){return _title;}
    
    function setMintFeeTokenAddress(address tokenAddress) external onlyOwner {
        _mintFeeTokenAddress = tokenAddress;
    }
    function getMintFeeTokenAddress() public view returns (address) {
        return _mintFeeTokenAddress;
    }
    function setBaseMintFee (uint256 mintFee) external onlyOwner {
        _baseMintFee = mintFee; //set new base mint fee
    }
    function setTotalLimitMintAmount(uint256 limit) external onlyOwner{
        require(limit >= _currentMintAmount);
        _maxLimitToMint = limit;
    }

    function _getBaseMintFee() internal view returns(uint256){
        return  _baseMintFee; // return mint fee
    }
    function _advanceMintAmount (address addr,uint256 amount) internal {
         require(amount > 0,"SCRWL : Amount should more than zero");
        _minterToMintedCount[addr] = _minterToMintedCount[addr].add(amount);
        _currentMintAmount = _currentMintAmount.add(amount);
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
       uint256 nextTotalMintAmount = _currentMintAmount.add(add);
       bool quotaPassed = nextMintAmount <= _getMintQuotaFor(addr);
       bool totalPassed = _hasMintLimit() ? (nextTotalMintAmount <= _maxLimitToMint) : true;
       return quotaPassed && totalPassed;
    }
    function _hasMintLimit() internal view returns(bool){
        return _maxLimitToMint > 0;
    }
    modifier onlyWhitelist() {
        require(owner() == msg.sender || _isWhitelist(msg.sender), "Not Owner or WL");
        _;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IScrewUpERC1155MintForWhitelist {
    
    function whitelistMintBatch(address _addr,uint256[] memory tokenIds,uint256[] memory amounts) external;
    function whitelistTrimAmountWithMaxSupply(uint256 tokenId,uint256 toMintAmount) external view returns (uint256);
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