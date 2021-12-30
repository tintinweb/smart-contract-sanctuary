/// SPDX-License-Identifier: MIT
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

// File: flatten\contracts\token\ERC721\IERC721.sol

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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    unchecked {
        require(b <= a, errorMessage);
        return a - b;
    }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    unchecked {
        require(b > 0, errorMessage);
        return a % b;
    }
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this;
        // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

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
    constructor () {
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


/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface ILandsNftContract {
    function mintToken(address to, uint256 tokenId) external payable;

    function balanceOf(address owner) external view returns (uint256 balance);

    function totalSupply() external view returns (uint256);

    function tokenExists(uint256 tokenId) external view returns (bool);

    function isTransferAllowed(address to, uint delta) external view returns (bool);

    function mintTokens(address to, uint tokensNumber) external returns (uint[] memory);
}

contract Mint is Ownable, Pausable {

    using SafeMath for uint256;

    uint private _maxTokensPerTransaction;
    address _paymentWallet;

    uint _publicSaleStartTs;

    uint256 _landsSoldCounter = 0;

    IERC20 private _wethContract;
    ILandsNftContract public _nftsContract;

    mapping(uint256 => address) private _mintAllowedAddress;

    mapping(uint256 => address) private _reservedTokensOnSale;
    mapping(uint => uint256) private tokenSoldPrices;

    // WETH is with 18 decimals
    uint256 private _price1 = 10000000000000000;
    uint256 private _price2 = 20000000000000000;
    uint256 private _price3 = 30000000000000000;
    uint256 private _price4 = 40000000000000000;
    uint256 private _price5 = 50000000000000000;


    constructor(address wethContractAddress, address landTokenContractAddress, address paymentWallet_) {
        _wethContract = IERC20(wethContractAddress);
        _nftsContract = ILandsNftContract(landTokenContractAddress);
        _paymentWallet = paymentWallet_;
        _publicSaleStartTs = block.timestamp + 86400;
        // after 24h
        _maxTokensPerTransaction = 10;
    }



    function setPublicSaleStartTs(uint publicSaleStartTs) public onlyOwner {
        require(publicSaleStartTs > block.timestamp);
        _publicSaleStartTs = publicSaleStartTs;
    }

    function setPrices(uint256 price1, uint256 price2, uint256 price3, uint256 price4, uint256 price5) public onlyOwner {
        require(price1 > 0);
        require(price2 > 0);
        require(price3 > 0);
        require(price4 > 0);
        require(price5 > 0);
        _price1 = price1;
        _price2 = price2;
        _price3 = price3;
        _price4 = price4;
        _price5 = price5;
    }

    function isPublicSale() public view returns (bool) {
        return block.timestamp >= _publicSaleStartTs;
    }

    function setLimits(uint maxTokensPerTransaction_) public onlyOwner {
        require(maxTokensPerTransaction_ > 0, "maxTokensPerTransaction_ should be positive");
        _maxTokensPerTransaction = maxTokensPerTransaction_;
    }

    function buyToken(uint256 tokenId) public whenNotPaused {
        require(tokenIsAllowedToBuy(tokenId), "Specified token id is not available for purchase");
        require(tokenId >= 20000, "Token id is outside of tokens on sale");
        require(!_nftsContract.tokenExists(tokenId), "This token already minted");
        require(_nftsContract.isTransferAllowed(_msgSender(), 1), "Mint not allowed: exceeded max token number in target wallet");

        uint256 tokenPrice = getTokensPrice(_landsSoldCounter);
//        _wethContract.transferFrom(_msgSender(), _paymentWallet, tokenPrice);
//        _nftsContract.mintToken(_msgSender(), tokenId);
//
//        if (tokenId >= 10000 && tokenId < 20000) {
//            _reservedTokensOnSale[tokenId] = address(0);
//        }
//        saveTokenPrice(tokenPrice, tokenPrice);
//        _landsSoldCounter++;
    }

    // TODO cover _reservedTokensOnSale array, need to determine what price that will be sold
    function buyTokens(uint tokensNumber) public whenNotPaused {
        require(isPublicSale(), "Public sale is not started yet");
        require(tokensNumber <= _maxTokensPerTransaction, "Max tokens per transaction number exceeded");
        require(_nftsContract.isTransferAllowed(_msgSender(), tokensNumber), "Mint not allowed: exceeded max token number in target wallet");

        uint256[] memory tokenPrices = getTokensPrices(tokensNumber);
        _wethContract.transferFrom(_msgSender(), _paymentWallet, getTotalSum(tokenPrices));
        uint[] memory tokenIds = _nftsContract.mintTokens(_msgSender(), tokensNumber);

        _landsSoldCounter = _landsSoldCounter + tokensNumber;

        saveTokenPrices(tokenIds, tokenPrices);
    }

    function saveTokenPrice(uint256 tokenId, uint256 price) internal {
        tokenSoldPrices[tokenId] = price;
    }

    function saveTokenPrices(uint[] memory tokenIds, uint256[] memory prices) internal {
        for (uint i = 0; i < tokenIds.length; i++) {
            saveTokenPrice(tokenIds[i], prices[i]);
        }
    }

    function getTokenSoldPrice(uint tokenId) public view returns(uint256) {
        return tokenSoldPrices[tokenId];
    }

    function claimToken(uint256 tokenId) public whenNotPaused {
        require(tokenId >= 10000 && tokenId < 20000, "Token id is outside reserved tokens range");
        require(!_nftsContract.tokenExists(tokenId), "This token already minted");
        require(_nftsContract.isTransferAllowed(_msgSender(), 1), "Mint not allowed: exceeded max token number in target wallet");
        require(_mintAllowedAddress[tokenId] == _msgSender(), "Claim is not allowed");

        _nftsContract.mintToken(_msgSender(), tokenId);
    }

    function allowClaim(uint256 tokenId, address to) public onlyOwner {
        require(tokenId >= 10000 && tokenId < 20000, "Token id is outside reserved tokens range");
        require(!_nftsContract.tokenExists(tokenId), "This token already minted");
        _mintAllowedAddress[tokenId] = to;
    }

    // TODO add read write these data for the redeploy purposes
    function putReservedTokenForSale(uint256 tokenId, address seller) public onlyOwner {
        require(tokenId >= 10000 && tokenId < 20000, "Token id is outside reserved tokens range");
        require(!_nftsContract.tokenExists(tokenId), "This token already minted");
        _reservedTokensOnSale[tokenId] = seller;
    }



    function getTotalSum(uint256[] memory data) internal pure returns(uint256) {
        uint256 totalSum = 0;
        for (uint i = 0; i < data.length; i++) {
            totalSum = totalSum + data[i];
        }
        return totalSum;
    }

    function getTokensPrice(uint tokensNumber) public view returns (uint256) {
        uint256 price = 0;
        for (uint i = 0; i < tokensNumber; i++) {
            price = price + getTokenPrice(_landsSoldCounter + i);
        }
        return price;
    }

    function getTokensPrices(uint tokensNumber) public view returns (uint256[] memory) {
        uint[] memory prices = new uint[](tokensNumber);
        for (uint i = 0; i < tokensNumber; i++) {
            prices[i] = getTokenPrice(_landsSoldCounter + i);
        }
        return prices;
    }

    function getTokenPrice(uint256 landsSold) internal view returns (uint256) {
        if (landsSold < 10000) {
            return _price1;
        } else if (landsSold >= 10000 && landsSold < 40000) {
            return _price2;
        } else if (landsSold >= 40000 && landsSold < 70000) {
            return _price3;
        } else if (landsSold >= 70000 && landsSold < 100000) {
            return _price4;
        } else {
            return _price5;
        }
    }


    function tokenIsAllowedToBuy(uint256 tokenId) internal view returns (bool){
        if (tokenId < 10000) {
            return false;
            // tokens 0-9999 reserved for the XOIL team use
        }
        if (tokenId < 20000 && _reservedTokensOnSale[tokenId] == address(0)) {
            return false;
            // tokens from 10000 to 19999 should be put for sale manually, see {}
        }
        return true;
    }

    function setNftsContract(address nftsContractAddress) public onlyOwner {
        require(nftsContractAddress != address(this), "wrong address");
        _nftsContract = ILandsNftContract(nftsContractAddress);
    }

    function setPaymentWallet(address paymentWallet_) public onlyOwner {
        require(_paymentWallet != address(this), "wrong address");
        _paymentWallet = paymentWallet_;
    }

    function setWethContract(address wethContract) public onlyOwner {
        require(wethContract != address(this), "wrong address");
        _wethContract = IERC20(wethContract);
    }


}