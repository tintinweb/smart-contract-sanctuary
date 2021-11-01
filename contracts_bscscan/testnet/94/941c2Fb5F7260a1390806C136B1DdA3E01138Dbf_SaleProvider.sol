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

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
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

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract SaleProvider is Ownable {
    IERC20Metadata public tokenSale;
    IERC20Metadata public tokenAccept;
    
    address public seller;
    address public receiver;
    address public feeReceiver;
    
    uint256 public price;
    uint256 public fee;
    uint256 public minBuy;
    
    bool public isActive;

    event Sold(address buyer, uint256 amount);

    /**
        khởi tạo contract

        Điều kiện:
        - _numTokenSale và _numTokenAccept lớn hơn 0 và được truyền vào dưới dạng đã nhân decimal.
        Ví dụ : bán 1 TokenA bằng 0.2 TokenB ( decimals TokenA = 18, decimals TokenB = 6)
        ==>  _numTokenSale = 1*10^18 và _numTokenAccept = 0.2*10^6

        - _numFee là số lớn hơn 0 đã nhân decimal, tính theo tokenAccept.
        Ví dụ : muốn lấy phí 1,5% với tokenAccept có decimal 18 
        ==> _numFee = 1,5*10^18  

        Công thức:
        _numTokenSale * price = _numTokenAccept;
        _numTokenAccept * fee = _numFee;

         - _minBuy là số lượng token nhỏ nhất có thể mua
    */

    constructor(IERC20Metadata _tokenSale,
                uint256 _numTokenSale,
                IERC20Metadata _tokenAccept,
                uint256 _numTokenAccept,
                uint256 _numFee,
                uint256 _minBuy,
                bool _isActive,
                address _receiver,
                address _feeReceiver) {
        require(_numTokenSale > 0);
        require(_numTokenAccept > 0);
        require(_receiver == address(_receiver),"Invalid address receiver");
        require(_feeReceiver == address(_feeReceiver),"Invalid address fee receiver");

        tokenSale = _tokenSale;
        tokenAccept = _tokenAccept;

        price = (_numTokenAccept*10**tokenSale.decimals())/_numTokenSale;
        fee = _numFee;

        isActive = _isActive;

        minBuy = _minBuy;

        seller = msg.sender;
        receiver = _receiver;
        feeReceiver = _feeReceiver;
    }

    /**
        mua token

        Điều Kiện Mua:
        - Đã approve đủ tokenAccept để mua tokenSale
        - param numberOfTokens truyên dưới dạng đã được nhân decimal
        Ví dụ : mua 2 token (decimal 18) ==> numberOfTokens = 2*10^18
     */

    function buyTokens(uint256 numberOfTokens) public {
        require(isActive == true);
        require(numberOfTokens <= tokenSale.allowance(seller,address(this)));
        require(numberOfTokens >= minBuy);

        uint256 amount = (numberOfTokens*price)/(10**tokenSale.decimals());
        require(amount != 0);
        uint256 feePayable = (amount*fee)/(100*10**tokenAccept.decimals());

        require(tokenAccept.transferFrom(msg.sender, receiver, amount));
        require(tokenAccept.transferFrom(msg.sender, feeReceiver, feePayable));
        require(tokenSale.transferFrom(seller, msg.sender, numberOfTokens));

        emit Sold(msg.sender, numberOfTokens);
    }

    function endSale() public onlyOwner() {
        require(isActive == true);
        
        isActive = false;
    }

    function startSale() public onlyOwner() {
        require(isActive == false);
        
        isActive = true;
    }

    /**
        Điều kiện như hàm khởi tạo
     */

    function updatePrice(uint256 _numTokenSale, uint256 _numTokenAccept) public onlyOwner() {
        require(_numTokenSale > 0);
        require(_numTokenAccept > 0);

        price = (_numTokenAccept*10**tokenSale.decimals())/_numTokenSale;
    }

    function updateFee(uint256 _numFee) public onlyOwner() {
        require(_numFee > 0);

        fee = _numFee;
    }

    function updateMinBuy(uint256 _minBuy) public onlyOwner() {
        minBuy = _minBuy;
    }

    function getRemainingTokenSale() public view returns (uint256) {
        return tokenSale.allowance(owner(),address(this));
    }

    function estimatePrice(uint256 numberOfTokens) public view returns (uint256) {
        require(numberOfTokens <= tokenSale.allowance(owner(),address(this)));
        require(numberOfTokens >= minBuy);

        uint256 amount = (numberOfTokens*price)/(10**tokenSale.decimals());
        require(amount != 0);

        return amount;
    }
}