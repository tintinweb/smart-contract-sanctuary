/**
 *Submitted for verification at BscScan.com on 2021-09-05
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

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
        this;
        // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

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
abstract contract MultiOwner is Context {
    address private _owner;
    address[] _owners;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        _owners.push(msgSender);
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     * @return address
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev checks a given address against the array of owners
     * @return bool true if address is an owner, false otherwise
     */
    function isOwner(address _address) public view virtual returns (bool){
        for (uint8 i = 0; i < _owners.length; i++) {
            if (_owners[i] == _address)
                return true;
        }
        return false;
    }

    /**
     * @dev adds the address into the owners array
     */
    function addOwner(address _address) public virtual onlyMainOwner {
        _owners.push(_address);
    }

    function removeOwner(address _address) public virtual onlyMainOwner {

    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(_msgSender()), "Ownable: caller is not the owner");
        _;
    }

    modifier onlyMainOwner(){
        require(owner() == _msgSender(), "Ownable: caller is not the main owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyMainOwner {
        emit OwnershipTransferred(_owner, address(0));
        delete _owners;
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyMainOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        delete _owners;
        emit OwnershipTransferred(_owner, newOwner);
        _owners.push(newOwner);
        _owner = newOwner;
    }
}

/**
 * @title CommissionReceiver
 * @dev Implementation of the CommissionReceiver
 */
contract CommissionReceiver is MultiOwner {
    using SafeMath for uint256;

    mapping(bytes32 => uint256) private _prices;
    mapping(bytes32 => Discount) private _discounts;
    mapping(address => bool) private _excluded;
    mapping(bytes32 => Affiliate) private _affiliateCodes;
    address private _balanceDrainer;
    uint256 private _totalPaid;
    uint256 private _totalDeployments;

    Drainer[] private _balanceDrainers;

    struct Discount {
        uint256 discount;
        uint256 tickets;
    }

    struct Affiliate {
        address affiliateAddress;
        uint256 commission;
        uint256 discount;
        uint256 sales;
        bool isValid;
    }

    struct Drainer {
        address drainerAddress;
        uint256 percentages;
    }

    event Created(string serviceName, address indexed serviceAddress);
    event AffiliateCodeUsed(address affiliate, uint256 commission, uint256 totalSales);

    function pay(string memory serviceName, string memory discountCode) public payable {
        if (!_excluded[_msgSender()]) {
            uint256 price = getPriceWithDiscountCode(serviceName, discountCode);
            require(msg.value == price, "CommissionReceiver: incorrect price");
            if (price != 0) {
                decrementDiscountTicketsIfUsed(discountCode);
                if (isAffiliateCode(discountCode)) {
                    Affiliate storage aff = _affiliateCodes[_toBytes32(discountCode)];
                    require(_msgSender() != aff.affiliateAddress, "CommissionReceiver: Affiliate cannot use their own code");
                    uint256 commission = getPrice(serviceName) * aff.commission / 10 ** 4;
                    payable(aff.affiliateAddress).transfer(commission);
                    _totalPaid += commission;
                    aff.sales++;
                    aff.commission = getNewCommissionValueForAffiliate(aff);
                    aff.discount = getNewDiscountValueForAffiliate(aff);
                    emit AffiliateCodeUsed(aff.affiliateAddress, commission, aff.sales);
                }
                splitWithdrawalToDrainers();
            }
        }
        _totalDeployments += 1;
        emit Created(serviceName, _msgSender());
    }

    /**
     * @dev splits the contracts balance between addresses in the {_balanceDrainers} array
     */
    function splitWithdrawalToDrainers() internal {
        uint256 balance = address(this).balance;
        for (uint i = 0; i < _balanceDrainers.length; i++) {
            payable(_balanceDrainers[i].drainerAddress)
            .transfer(balance.div(10 ** 4).mul(_balanceDrainers[i].percentages));
        }
    }

    function getPrice(string memory serviceName) public view returns (uint256) {
        return _prices[_toBytes32(serviceName)];
    }

    /**
     * @dev returns the new commission percentage (2 decimals) for a given Affiliate object.
     * Note: Affiliate sales should be updated prior to calling this method.
     */
    function getNewCommissionValueForAffiliate(Affiliate memory aff) internal pure returns (uint256){
        if (aff.commission > 2500) return aff.commission;
        if (aff.sales < 10) return 1000;
        if (aff.sales >= 30) return 2500;
        if (aff.sales >= 20) return 2000;
        return 1500;
    }

    /**
     * @dev returns the new discount percentage (2 decimals) for a given Affiliate object.
     * Note: Affiliate sales should be updated prior to calling this method.
     */
    function getNewDiscountValueForAffiliate(Affiliate memory aff) internal pure returns (uint256){
        if (aff.discount > 1500) return aff.discount;
        if (aff.sales < 20) return 1000;
        if (aff.sales < 30) return 1200;
        return 1500;
    }

    function setPrice(string memory serviceName, uint256 amount) public onlyMainOwner {
        _prices[_toBytes32(serviceName)] = amount;
    }

    /**
     * @dev Manually drain the contract for all ETH.
     *
     * Note: Drained ETH goes into the {owner}'s wallet.
     */
    function withdraw() public onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    /**
     * @dev checks whether or not the given {discountCode} is an Affiliate code, or a normal discount
     * @return bool true if {discountCode} is an Affiliate, false otherwise
     *
     * Note: This doesn't check for discountCode validity.
     */
    function isAffiliateCode(string memory discountCode) public view returns (bool){
        return _affiliateCodes[_toBytes32(discountCode)].isValid;
    }

    /**
     * @dev checks if the given {discountCode} is valid (if it has any tickets left).
     *
     * Note: Always returns false for Affiliate codes.
     */
    function discountCodeExists(string memory discountCode) public view returns (bool) {
        return _discounts[_toBytes32(discountCode)].tickets != 0;
    }

    /**
     * @dev if the {discountCode} exists, subtract 1 ticket. If this method is called, we can assume the code will be used.
     *
     * Note: This method should only be called ONCE per transaction.
     */
    function decrementDiscountTicketsIfUsed(string memory discountCode) private {
        if (!discountCodeExists(discountCode)) return;
        _discounts[_toBytes32(discountCode)].tickets--;
    }

    /**
    * @dev returns the given {serviceName}'s price calculated with a given {discountCode}
    *
    * Note: Discount and Affiliate codes are, in this method, interchangeable.
    */
    function getPriceWithDiscountCode(string memory serviceName, string memory discountCode) public view returns (uint256) {
        if (isAffiliateCode(discountCode)) {
            (uint256 _discount,) = getAffiliateCodeValues(discountCode);
            return getPrice(serviceName) - (getPrice(serviceName) * (_discount) / 10 ** 4);
        }
        Discount memory discount = _discounts[_toBytes32(discountCode)];
        if (discount.tickets == 0)
            return getPrice(serviceName);
        return getPrice(serviceName) - (getPrice(serviceName) * (discount.discount) / (10 ** 4));
    }

    /**
    * @dev returns the discount value along with remaining tickets for a given discount code
    *
    * Note: If the tickets amount is zero it should be considered invalid.
    */
    function getDiscountCodeValues(string memory discountCode) public view returns (uint256, uint256){
        Discount memory discount = _discounts[_toBytes32(discountCode)];
        return (discount.discount, discount.tickets);
    }

    /**
    * @dev returns the affiliate values for a given affiliate code
    *
    * Note: This doesn't check for code validity, use Affiliate.isValid to check validity.
    */
    function getAffiliateCodeValues(string memory affiliateCode) public view returns (uint256, uint256){
        Affiliate memory aff = _affiliateCodes[_toBytes32(affiliateCode)];
        return (aff.discount, aff.commission);
    }

    /**
    * @dev created a new discount code
    *
    * @param code   The textual representation of the discount code
    * @param discount   The percentage (with 2 decimals) that should be deducted from the price (500 = 5%)
    * @param tickets    How many times the discount code can be used, if set to zero the code is considered invalid
    */
    function addDiscountCode(string memory code, uint256 discount, uint256 tickets) public onlyOwner {
        require(tickets > 0, "CommissionReceiver: Trying to add zero tickets");
        require(discount > 0, "CommissionReceiver: Trying to add zero discount");
        require(discount <= 10 ** 4, "CommissionReceiver: Discount cannot exceed 100%");
        Discount storage _discount = _discounts[_toBytes32(code)];
        _discount.discount = discount;
        _discount.tickets = tickets;
    }

    // By just setting tickets to zero, we've effectively removed the discount code
    function removeDiscountCode(string memory code) public onlyOwner {
        _discounts[_toBytes32(code)].tickets = 0;
    }

    // Exclude address from commission fees
    function addExclusion(address _address) public onlyOwner {
        _excluded[_address] = true;
    }

    // Remove exclusion of address for commission fees
    function removeExclusion(address _address) public onlyOwner {
        _excluded[_address] = false;
    }

    function isAddressExcluded(address _address) public view returns (bool){
        return _excluded[_address];
    }

    /**
    * @dev Adds a new affiliate code to the system
    *
    * @param _address   The address which the commission should be sent to
    * @param initialSales   Instantiate the affiliate with initial sales, can be used to skip ranks
    * @param code   The textual representation of the affiliate code used
    * @param customCommission   If the commission should be permanently above the ranks cap, use this (minimum is 25%)
    * @param customDiscount     If the discount should be permanently above the ranks cap, use this (minimum 15%)
    */
    function addAffiliate(address _address, uint256 initialSales, string memory code, uint256 customCommission, uint256 customDiscount) public onlyOwner {
        require(address(_address) == _address, "CommissionReceiver: Address is not payable");
        require(bytes(code).length != 0, "CommissionReceiver: Code cannot be empty");
        Affiliate storage aff = _affiliateCodes[_toBytes32(code)];
        aff.sales = initialSales;
        aff.affiliateAddress = _address;
        aff.commission = customCommission == 0 ? getNewCommissionValueForAffiliate(aff) : customCommission;
        aff.discount = customDiscount == 0 ? getNewDiscountValueForAffiliate(aff) : customDiscount;
        aff.isValid = true;
    }

    /**
    * @dev removes an affiliate code from the system
    */
    function removeAffiliate(string memory code) public onlyOwner {
        _affiliateCodes[_toBytes32(code)].isValid = false;
        _affiliateCodes[_toBytes32(code)].sales = 0;
    }

    /**
    * @dev adds another balance drainer, make sure to fix the other drainers percentages before calling this.
    */
    function addBalanceDrainer(address payable _address, uint256 splitPercentage) public onlyMainOwner {
        uint256 percentSum;
        for (uint256 i = 0; i < _balanceDrainers.length; i++) {
            percentSum += _balanceDrainers[i].percentages;
        }
        require(percentSum + splitPercentage <= 10000, "CommissionReceiver: Drainer percentages needs to sum to, or below 100%");
        Drainer memory _drainer;
        _drainer.drainerAddress = _address;
        _drainer.percentages = splitPercentage;
        _balanceDrainers.push(_drainer);
    }

    /**
    * @dev sets the percentage to drain for each address in the {_balanceDrainers} array
    */
    function setBalanceDrainerPercentage(address _address, uint256 newPercentage) public onlyMainOwner {
        require(isDrainer(_address), "CommissionReceiver: Address is not a drainer.");
        uint256 percentageSum = 0;
        uint256 index;
        for (uint256 i = 0; i < _balanceDrainers.length; i++) {
            if (_balanceDrainers[i].drainerAddress == _address) {
                index = i;
                percentageSum += newPercentage;
            } else {
                percentageSum += _balanceDrainers[i].percentages;
            }
        }
        require(percentageSum <= 10000, "CommissionReceiver: Percentages cannot exceed 100%");
        _balanceDrainers[index].percentages = newPercentage;
    }

    /**
    * @dev removes a drainer from {_balanceDrainers}
    */
    function removeBalanceDrainer(address _address) public onlyMainOwner {
        uint256 index;
        bool found;
        for (uint256 i = 0; i < _balanceDrainers.length; i++) {
            if (_balanceDrainers[i].drainerAddress == _address) {
                index = i;
                found = true;
                break;
            }
        }
        require(found, "CommissionReceiver: Tried to remove non-existing balance drainer");

        for (uint i = index; i < _balanceDrainers.length - 1; i++) {
            _balanceDrainers[i] = _balanceDrainers[i + 1];
        }
        _balanceDrainers.pop();
    }

    /**
    * @dev checks whether an address is a balance drainer
    */
    function isDrainer(address _address) public view returns (bool){
        for (uint256 i = 0; i < _balanceDrainers.length; i++) {
            if (_balanceDrainers[i].drainerAddress == _address) {
                return true;
            }
        }
        return false;
    }

    function _toBytes32(string memory _string) private pure returns (bytes32) {
        return keccak256(abi.encode(_string));
    }

    function totalDeployments() public view returns (uint256){
        return _totalDeployments;
    }

    function totalPaidToAffiliates() public view returns (uint256){
        return _totalPaid;
    }
}