//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract CryptoAvisosV1 is Ownable {

    mapping(uint256 => Product) public productMapping;
    mapping(address => uint256) public claimableFee;
    uint256[] private productsIds;
    uint256 public fee;
    uint256 public lastUnlockTimeFee;
    uint256 public lastFeeToSet;

    event ProductSubmitted(uint256 productId);
    event ProductPaid(uint256 productId);
    event ProductReleased(uint256 productId);
    event ProductUpdated(uint256 productId);
    event ProductRefunded(uint256 productId);
    event ProductMarkAsPaid(uint256 productId);
    event FeeSetted(uint256 previousFee, uint256 newFee);
    event FeesClaimed(address receiver, address token, uint256 quantity);
    event PreparedFee(uint fee, uint unlockTime);

    constructor(uint256 newFee){
        _setFee(newFee);
    }

    struct Product {
        uint256 price; //In WEI
        Status status; 
        address payable seller;
        address payable buyer;
        address token; //Contract address or 0x00 if it's native coin
        uint256 feeCharged; //Holds charged fee, in case admin need to refund and fee has change between pay and refund time
    }

    enum Status {
        FORSELL,
        WAITING,
        SOLD
    }

    function getProductsIds() external view returns (uint256[] memory) {
        return productsIds;
    }

    function _setFee(uint256 newFee) internal {
        //Set fee. Example: 10e18 = 10%
        require(newFee <= 100e18, 'Fee bigger than 100%');
        uint256 previousFee = fee;
        fee = newFee;
        emit FeeSetted(previousFee, newFee);
    }

    function prepareFee(uint256 newFee) external onlyOwner {
        //Prepare to set fee (wait 7 days to set. Timelock kind of)
        lastUnlockTimeFee = block.timestamp + 7 days;
        lastFeeToSet = newFee;
        emit PreparedFee(newFee, lastUnlockTimeFee);
    }

    function implementFee() external onlyOwner {
        //Set fee after 7 days
        require(lastUnlockTimeFee > 0, "not prepared");
        require(lastUnlockTimeFee <= block.timestamp, "not unlocked yet");
        _setFee(lastFeeToSet);
        lastUnlockTimeFee = 0;
    }

    function claimFees(address token, uint256 quantity) external payable onlyOwner {
        //Claim fees originated of paying a product
        require(claimableFee[token] >= quantity, "not enough funds");
        claimableFee[token] -= quantity;
        if(token == address(0)){
            //ETH
            payable(msg.sender).transfer(quantity);
        }else{
            //ERC20
            IERC20(token).transfer(msg.sender, quantity);
        }
        emit FeesClaimed(msg.sender, token, quantity);
    }

    function submitProduct(uint256 productId, address payable seller, uint256 price, address token) external onlyOwner {
        //Submit a product
        require(productId != 0, "productId cannot be zero");
        require(price != 0, "price cannot be zero");
        require(seller != address(0), "seller cannot be zero address");
        require(productMapping[productId].seller == address(0), "productId already exist");
        Product memory product = Product(price, Status.FORSELL, seller, payable(address(0)), token, 0);
        productMapping[productId] = product;
        productsIds.push(productId);
        emit ProductSubmitted(productId);
    }

    function markAsPaid(uint256 productId) external onlyOwner {
        //This function mark as paid a product when is paid in other chain
        Product memory product = productMapping[productId];
        require(product.seller != address(0), "cannot mark as paid a non existing product");
        require(Status.SOLD != product.status, 'Product already sold');
        product.status = Status.SOLD;
        productMapping[productId] = product;
        emit ProductMarkAsPaid(productId);
    }

    function payProduct(uint256 productId) external payable {
        //Pay a specific product
        Product memory product = productMapping[productId];
        require(product.seller != address(0), "cannot pay a non existing product");
        require(Status.FORSELL == product.status, 'Product already sold');

        if (product.token == address(0)) {
            //Pay with ether (or native coin)
            require(msg.value >= product.price, 'Not enough ETH sended');
        }else{
            //Pay with token
            IERC20(product.token).transferFrom(msg.sender, address(this), product.price);
        }

        uint256 toFee = product.price * fee / 100e18;
        claimableFee[product.token] += toFee;

        product.feeCharged = toFee;
        product.status = Status.WAITING;
        product.buyer = payable(msg.sender);
        productMapping[productId] = product;
        emit ProductPaid(productId);
    }

    function releasePay(uint256 productId) external onlyOwner {
        //Release pay to seller
        Product memory product = productMapping[productId];
        require(product.seller != address(0), "cannot release pay for a non existing product");
        require(Status.WAITING == product.status, 'Not allowed to release pay');
        uint256 finalPrice = product.price - product.feeCharged;

        if (product.token == address(0)) {
            //Pay with ether (or native coin)
            product.seller.transfer(finalPrice);
        }else{
            //Pay with token
            IERC20(product.token).transfer(product.seller, finalPrice);
        }

        product.status = Status.SOLD;
        productMapping[productId] = product;
        emit ProductReleased(productId);
    }

    function updateProduct(uint256 productId, address payable seller, uint256 price, address token) external onlyOwner {
        //Update a product
        require(productId != 0, "productId cannot be zero");
        require(price != 0, "price cannot be zero");
        require(seller != address(0), "seller cannot be zero address");
        Product memory product = productMapping[productId];
        require(product.status == Status.FORSELL || product.status == Status.WAITING, "cannot update a sold product");
        require(product.seller != address(0), "cannot update a non existing product");
        product = Product(price, Status.FORSELL, seller, payable(address(0)), token, 0);
        productMapping[productId] = product;
        emit ProductUpdated(productId);
    }

    function refundProduct(uint256 productId) external onlyOwner {
        //Return funds to buyer
        require(productId != 0, "productId cannot be zero");
        Product memory product = productMapping[productId];
        require(product.seller != address(0), "cannot refund a non existing product");
        require(product.status == Status.WAITING, "cannot refund a non waiting product");
        if(product.token == address(0)){
            //ETH
            payable(product.buyer).transfer(product.price);
        }else{
            //ERC20
            IERC20(product.token).transfer(product.buyer, product.price);
        }
        claimableFee[product.token] -= product.feeCharged;
        product.status = Status.SOLD;
        productMapping[productId] = product;
        emit ProductRefunded(productId);
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

/*
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