/**
 *Submitted for verification at BscScan.com on 2022-01-22
*/

/**
 *Submitted for verification at BscScan.com on 2022-01-19
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrrt(uint256 a) internal pure returns (uint256 c) {
        if (a > 3) {
            c = a;
            uint256 b = add(div(a, 2), 1);
            while (b < c) {
                c = b;
                b = div(add(div(a, b), b), 2);
            }
        } else if (a != 0) {
            c = 1;
        }
    }

    function percentageAmount(uint256 total_, uint8 percentage_)
        internal
        pure
        returns (uint256 percentAmount_)
    {
        return div(mul(total_, percentage_), 1000);
    }

    function substractPercentage(uint256 total_, uint8 percentageToSub_)
        internal
        pure
        returns (uint256 result_)
    {
        return sub(total_, div(mul(total_, percentageToSub_), 1000));
    }

    function percentageOfTotal(uint256 part_, uint256 total_)
        internal
        pure
        returns (uint256 percent_)
    {
        return div(mul(part_, 100), total_);
    }

    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + (((a % 2) + (b % 2)) / 2);
    }

    function quadraticPricing(uint256 payment_, uint256 multiplier_)
        internal
        pure
        returns (uint256)
    {
        return sqrrt(mul(multiplier_, payment_));
    }

    function bondingCurve(uint256 supply_, uint256 multiplier_)
        internal
        pure
        returns (uint256)
    {
        return mul(multiplier_, supply_);
    }
}

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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

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

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract Draqle is Ownable {
    using SafeMath for uint256;

    uint256 public disputeCommission = 10;
    uint256 public tradeCommission = 5;

    address public tradeCommissionWallet = 0x87215FcFAe39232Aa01cd09Ca26357E63A0e8C94;
    address public disputeCommissionWallet = 0x87215FcFAe39232Aa01cd09Ca26357E63A0e8C94;

    struct PendingLog {
        address buyer;
        address seller;
        uint256 productId;
        uint256 pendingId;
        // uint256 depositTime;
        uint256 confirmedTime;
//        uint256 acceptedTime;
        uint256 depoAmount;
        bool confirmedBySeller;
        bool acceptedByBuyer;
        bool refundedByBuyer;
        bool disputedByBuyer;
        bool disputedBySeller;
        bool claimedBySeller;
        bool refundedBySeller;
    }

    struct UserLog {
        uint256 depositCount;
        uint256 totalDepositAmount;
        mapping(uint256 => bool) currentlyPending;
        uint256[] pendings;
    }

    struct ProductInfo {
        uint256 id;
        uint256 price;
        address productOwner;
        uint256 saled;
    }

    mapping(address => UserLog) public userInfo;
    uint256 public productCount;
    mapping(uint256 => ProductInfo) public products;

    uint256 public pendinglogsCount;
    mapping(uint256 => PendingLog) public pendinglogs;

    uint256[] public disputedPendings;

    event event_productAdded(address indexed productOwner, uint256 productId);
    event event_depositedByUser(address indexed buyer, uint256 pendingId);
    event event_confirmedBySeller(address indexed seller, uint256 pendingId);
    event event_acceptedByBuyer(address indexed buyer, uint256 pendingId);
    event event_claimedBySeller(address indexed seller, uint256 pendingId);
    event event_refundedByBuyer(address indexed buyer, uint256 pendingId);

    constructor() {
        productCount = 0;
    }

    function setDisputeCommissionPercentage(uint256 _percentage) external onlyOwner{
        disputeCommission = _percentage;
    }

    function setTradeCommissionPercentage(uint256 _percentage) external onlyOwner{
        tradeCommission = _percentage;
    }

    function setTradeCommissionWallet(address _address) external onlyOwner {
        tradeCommissionWallet = _address;
    }

    function setDisputeCommissionWallet(address _address) external onlyOwner {
        disputeCommissionWallet = _address;
    }

    function addProduct(uint256 _price) external returns (uint256) {
        products[productCount] = ProductInfo({
            id: productCount,
            price: _price,
            productOwner: msg.sender,
            saled: 0
        });
        productCount++;
        emit event_productAdded(msg.sender, productCount - 1);
        return productCount - 1;
    }

    function buyProduct(uint256 _id) external payable returns (uint256) {
        require(_id < productCount, "invalid id");
        require(
            msg.value >= products[_id].price,
            "You sent less than the price"
        );
        //  deposit 1 BNB or price BNB
        address seller1 = products[_id].productOwner;
        pendinglogs[pendinglogsCount] = PendingLog({
            productId: _id,
            pendingId: pendinglogsCount,
            depoAmount: msg.value,
            buyer: msg.sender,
            seller: products[_id].productOwner,
            confirmedBySeller: false,
            acceptedByBuyer: false,
            refundedByBuyer: false,
            claimedBySeller: false,
            disputedByBuyer: false,
            disputedBySeller: false,
            refundedBySeller : false,
            // depositTime: block.timestamp,
            confirmedTime: 0
            // acceptedTime: 0
        });

        userInfo[msg.sender].totalDepositAmount += msg.value;
        userInfo[msg.sender].currentlyPending[pendinglogsCount] = true;
        userInfo[msg.sender].depositCount++;
        userInfo[msg.sender].pendings.push(pendinglogsCount);
        userInfo[seller1].pendings.push(pendinglogsCount);
        pendinglogsCount++;
        emit event_depositedByUser(msg.sender, pendinglogsCount - 1);
        return pendinglogsCount - 1;
    }

    function rejectDisputeByBuyer(uint256 _id) external {
        require(_id < pendinglogsCount, "invalid _id of pendinglogs");
        require(
            pendinglogs[_id].buyer == msg.sender,
            "you are not the buyer of pending"
        );
        require(
            pendinglogs[_id].confirmedBySeller == true,
            "It is not confirmed yet"
        );
        require(
            pendinglogs[_id].disputedByBuyer == true,
            "It is already disputed by you"
        );
        require(
            pendinglogs[_id].refundedBySeller == false,
            "It is already Refunded by Seller"
        );
        pendinglogs[_id].disputedByBuyer = false;
    }

    function confirmBySeller(uint256 _id) external {
        require(_id < pendinglogsCount, "invalid _id of pendinglog");
        require(
            pendinglogs[_id].seller == msg.sender,
            "you are not the owner of product"
        );
        require(
            pendinglogs[_id].confirmedBySeller == false,
            "It is already confirmed"
        );
        require(
            pendinglogs[_id].refundedByBuyer == false,
            "It is refunded by buyer"
        );
        require(
            userInfo[pendinglogs[_id].buyer].currentlyPending[_id] == true,
            "It is not pended by buyer"
        );
        pendinglogs[_id].confirmedBySeller = true;
        pendinglogs[_id].confirmedTime = block.timestamp;

        emit event_confirmedBySeller(msg.sender, _id);
    }

    function disputeByBuyer(uint256 _id) external {
        require(_id < pendinglogsCount, "invalid _id of pendinglogs");
        require(
            pendinglogs[_id].buyer == msg.sender,
            "you are not the buyer of pending"
        );
        require(
            pendinglogs[_id].confirmedBySeller == true,
            "It is not confirmed yet"
        );
        require(
            pendinglogs[_id].disputedByBuyer == false,
            "It is already disputed by you"
        );

        require(
            pendinglogs[_id].acceptedByBuyer == false,
            "It is already accepted by you"
        );
        pendinglogs[_id].disputedByBuyer = true;
        disputedPendings.push(_id);
    }

    function refundBySeller(uint256 _id) external {
        require(_id < pendinglogsCount, "invalid _id of pendinglogs");
        require(
            pendinglogs[_id].seller == msg.sender,
            "you are not the owner of product"
        );
        require(
            pendinglogs[_id].disputedByBuyer == true, 
            "It is not disputed by buyer"
        );
        require(
            pendinglogs[_id].refundedBySeller == false,
            "It is already refunded by you"
        );
        pendinglogs[_id].refundedBySeller = true;
        address payable wallet = payable(pendinglogs[_id].buyer);
        wallet.transfer(products[pendinglogs[_id].productId].price);
    }
    function disputeBySeller(uint256 _id) external {
        require(_id < pendinglogsCount, "invalid _id of pendinglogs");
        require(
            pendinglogs[_id].seller == msg.sender,
            "you are not the owner of product"
        );
        require(
            pendinglogs[_id].disputedByBuyer == true, 
            "It is not disputed by buyer"
        );
        require(
            pendinglogs[_id].disputedBySeller == false, 
            "It is already disputed by Seller"
        );
        require(
            pendinglogs[_id].refundedBySeller == false,
            "It is already refunded by you"
        );
        pendinglogs[_id].disputedBySeller = true;
    }
    function refundByAdminToSeller(uint256 _id) external onlyOwner {
        require(_id < pendinglogsCount, "invalid _id of pendinglogs");
        require(
            pendinglogs[_id].disputedByBuyer == true, 
            "It is not disputed by buyer"
        );
        require(
            pendinglogs[_id].refundedBySeller == false,
            "It is already refunded by Seller"
        );

        pendinglogs[_id].disputedByBuyer = false;
        pendinglogs[_id].acceptedByBuyer = true;
        pendinglogs[_id].claimedBySeller = true;
        uint256 priceOfProduct = products[pendinglogs[_id].productId].price;
        uint256 disputeCommissionValue = priceOfProduct.mul(disputeCommission).div(100);
        uint256 userGetValue = priceOfProduct - disputeCommissionValue;
        address payable userWallet = payable(pendinglogs[_id].seller);
        address payable disputeAdminWallet = payable(disputeCommissionWallet);

        disputeAdminWallet.transfer(disputeCommissionValue);
        userWallet.transfer(userGetValue);
    }

    function refundByAdminToBuyer(uint256 _id) external onlyOwner {
        require(_id < pendinglogsCount, "invalid _id of pendinglogs");
        require(
            pendinglogs[_id].disputedByBuyer == true, 
            "It is not disputed by buyer"
        );
        require(
            pendinglogs[_id].refundedBySeller == false,
            "It is already refunded by Seller"
        );

        pendinglogs[_id].refundedBySeller = true;

        uint256 priceOfProduct = products[pendinglogs[_id].productId].price;
        uint256 disputeCommissionValue = priceOfProduct.mul(disputeCommission).div(100);
        uint256 userGetValue = priceOfProduct - disputeCommissionValue;
        address payable userWallet = payable(pendinglogs[_id].buyer);
        address payable disputeAdminWallet = payable(disputeCommissionWallet);

        disputeAdminWallet.transfer(disputeCommissionValue);
        userWallet.transfer(userGetValue);
    }

    function acceptByBuyer(uint256 _id) external {
        require(_id < pendinglogsCount, "invalid _id of pendinglogs");
        require(
            pendinglogs[_id].buyer == msg.sender,
            "you are not the buyer of pending"
        );
        require(
            pendinglogs[_id].refundedBySeller == false,
            "already refunded"
        );
        require(
            pendinglogs[_id].confirmedBySeller == true,
            "It is not confirmed yet"
        );
        require(
            pendinglogs[_id].disputedByBuyer == false,
            "It is already disputed"
        );
        require(
            pendinglogs[_id].acceptedByBuyer == false,
            "It is already accepted"
        );

        userInfo[msg.sender].totalDepositAmount.sub(
            products[pendinglogs[_id].productId].price
        );
        userInfo[msg.sender].currentlyPending[_id] = false;
        pendinglogs[_id].acceptedByBuyer = true;
//        pendinglogs[_id].acceptedTime = block.timestamp;

        address payable seller = payable(pendinglogs[_id].seller);

// Commission to TradecommissionWallet
        uint256 priceOfProduct = products[pendinglogs[_id].productId].price;
        uint256 tradeCommissionValue = priceOfProduct.mul(tradeCommission).div(100);
        uint256 userGetValue = priceOfProduct - tradeCommissionValue;
//        address payable userWallet = payable(pendinglogs[_id].buyer);
        address payable tradeAdminWallet = payable(tradeCommissionWallet);

        tradeAdminWallet.transfer(tradeCommissionValue);
        seller.transfer(userGetValue);


        products[pendinglogs[_id].productId].saled++;

        emit event_acceptedByBuyer(msg.sender, _id);
    }

    function refundByBuyer(uint256 _id) external {
        require(_id < pendinglogsCount, "invalid _id of pendinglogs");
        require(
            pendinglogs[_id].buyer == msg.sender,
            "you are not the buyer of this pending"
        );
        require(
            pendinglogs[_id].confirmedBySeller == false,
            "It is already confirmed yet"
        );
        require(
            pendinglogs[_id].refundedByBuyer == false,
            "It is already refunded yet"
        );
        require(
            userInfo[msg.sender].currentlyPending[_id] == true,
            "It is not currently pending"
        );
        //    require(block.timestamp > pendinglogs[_id].depositTime + 24 hours, "You can refund after 24 hours");

        pendinglogs[_id].refundedByBuyer = true;
//        pendinglogs[_id].refundedTime = block.timestamp;
        userInfo[msg.sender].currentlyPending[_id] = false;
        address payable buyer = payable(msg.sender);
        buyer.transfer(products[pendinglogs[_id].productId].price);
        emit event_refundedByBuyer(msg.sender, _id);
    }

    function claimBySeller(uint256 _id) external returns (uint256) {
        require(_id < pendinglogsCount, "invalid _id of pendinglog");
        require(
            pendinglogs[_id].disputedByBuyer == false, 
            "It is disputed by buyer"
        );
        require(
            pendinglogs[_id].seller == msg.sender,
            "you are not the owner of product"
        );
        require(
            pendinglogs[_id].claimedBySeller == false,
            "It is already claimed By seller"
        );
        require(
            pendinglogs[_id].confirmedBySeller == true,
            "It is not confirmed by you"
        );
        require(
            pendinglogs[_id].refundedByBuyer == false,
            "It is refunded by buyer"
        );
        require(
                (pendinglogs[_id].acceptedByBuyer == false &&
                    pendinglogs[_id].confirmedTime + 24 hours <
                    block.timestamp),
            "you could claim after 24 hours"
        );

        pendinglogs[_id].claimedBySeller = true;
//        pendinglogs[_id].claimedTime = block.timestamp;
        userInfo[pendinglogs[_id].buyer].totalDepositAmount.sub(
            products[pendinglogs[_id].productId].price
        );
        userInfo[pendinglogs[_id].buyer].currentlyPending[_id] = false;

        address payable seller = payable(pendinglogs[_id].seller);

// Commission to TradecommissionWallet
        uint256 priceOfProduct = products[pendinglogs[_id].productId].price;
        uint256 tradeCommissionValue = priceOfProduct.mul(tradeCommission).div(100);
        uint256 userGetValue = priceOfProduct - tradeCommissionValue;
//        address payable userWallet = payable(pendinglogs[_id].buyer);
        address payable tradeAdminWallet = payable(tradeCommissionWallet);

        tradeAdminWallet.transfer(tradeCommissionValue);
        seller.transfer(userGetValue);


        products[pendinglogs[_id].productId].saled++;

        emit event_claimedBySeller(msg.sender, _id);
        return _id;
    }

    function getPriceOfProduct(uint256 _proId) external view returns (uint256) {
        require(_proId < productCount, "invalid _id of product");
        return products[_proId].price;
    }

    function getPendingLogOfBuyer(address userAddress)
        external
        view
        returns (uint256[] memory)
    {
        return userInfo[userAddress].pendings;
    }
    function getPendingLogOfAdmin()
        external
        view
        returns (uint256[] memory)
    {
        return disputedPendings;
    }
}