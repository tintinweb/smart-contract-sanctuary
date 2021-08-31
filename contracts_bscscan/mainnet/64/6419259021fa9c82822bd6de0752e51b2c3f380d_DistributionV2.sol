/**
 *Submitted for verification at BscScan.com on 2021-08-31
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

interface IBEP20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the token name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view returns (address);

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
    function allowance(address _owner, address spender) external view returns (uint256);

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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


abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Pausable is Context {
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
    constructor () internal {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view returns (bool) {
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
        require(!_paused, "Pausable: paused");
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
        require(_paused, "Pausable: not paused");
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


contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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


contract ReentrancyGuard {
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

    constructor () internal {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
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


library SafeMath {
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
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
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
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
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
        require(b != 0, errorMessage);
        return a % b;
    }
}

contract DistributionV2 is Ownable, Pausable, ReentrancyGuard {
    using SafeMath for uint256;

    IBEP20 public tokenFundIn;
    IBEP20 public tokenFundOut;
    
    bool public sale1Status = false;
    bool public sale2Status = false;
    bool public sale3Status = false;
    bool public sale4Status = true;
    bool public sale5Status = false;
    bool public sale6Status = false;
    bool public sale7Status = false;
    bool public saleLeftOverStatus = false;


    uint256 public salesLimit1 = 200000e18;
    uint256 public currentSalesLimit1 = 0;

    uint256 public salesLimit2 = 200000e18;
    uint256 public currentSalesLimit2 = 0;

    uint256 public salesLimit3 = 200000e18;
    uint256 public currentSalesLimit3 = 0;

    uint256 public salesLimit4 = 117600e18;
    uint256 public currentSalesLimit4 = 0;

    uint256 public salesLimit5 = 200000e18;
    uint256 public currentSalesLimit5 = 0;

    uint256 public salesLimit6 = 200000e18;
    uint256 public currentSalesLimit6 = 0;

    uint256 public salesLimit7 = 200000e18;
    uint256 public currentSalesLimit7 = 0;

    uint256 public LeftOverLimit = 317600e18;
    uint256 public remainingLeftOver = 0;

    uint256 public price1 = 10;
    uint256 public price2 = 20;
    uint256 public price3 = 30;
    uint256 public price4 = 40;
    uint256 public price5 = 50;
    uint256 public price6 = 60;
    uint256 public price7 = 70;


    address public treasury;

    
    constructor(
        address _tokenFundIn,
        address _tokenFundOut,
        address _treasury
    ) public {
        tokenFundIn = IBEP20(_tokenFundIn);
        tokenFundOut = IBEP20(_tokenFundOut);
        treasury = _treasury;
    }


    function exchangeSale1(uint256 _amountFundIn) public nonReentrant{
        require(_amountFundIn%100e18 == 0, "should be denomination of 100");
        require(_amountFundIn > 100e18, "must be more than 100");
        require(sale1Status == true, "Distribution: Sales1 is Closed");

        
        uint256 tokenPurchased = _amountFundIn.mul(100).div(price1);

        require(currentSalesLimit1.add(_amountFundIn) <= salesLimit1, "Distribution: Exceed Private sale Allocation Limit");
        currentSalesLimit1 = currentSalesLimit1.add(_amountFundIn);
        LeftOverLimit = LeftOverLimit.sub(_amountFundIn);
        uint256 totalTokensToSend = tokenPurchased;

        tokenFundIn.transferFrom(msg.sender,treasury, (_amountFundIn));
        tokenFundOut.transfer(msg.sender, totalTokensToSend);

        if(currentSalesLimit1 == salesLimit1){
            sale1Status = false;
            sale2Status = true;
        }
    }

    function exchangeSale2(uint256 _amountFundIn) public nonReentrant{
        
        require(sale2Status == true, "Distribution: Sales2 is Closed");
        require(_amountFundIn%100e18 == 0, "Distribution: must be denomination of 100");
        require(_amountFundIn > 100e18, "Distribution must be more than 100");

        
        uint256 tokenPurchased = _amountFundIn.mul(100).div(price2);

        require(currentSalesLimit2.add(_amountFundIn) <= salesLimit2, "Distribution: Exceed Private sale Allocation Limit");
        currentSalesLimit2 = currentSalesLimit2.add(_amountFundIn);
        LeftOverLimit = LeftOverLimit.sub(_amountFundIn);
        uint256 totalTokensToSend = tokenPurchased;

        tokenFundIn.transferFrom(msg.sender,treasury, (_amountFundIn));
        tokenFundOut.transfer(msg.sender, totalTokensToSend);

        if(currentSalesLimit2 == salesLimit2){
            sale2Status = false;
            sale3Status = true;
        }
    }
    function exchangeSale3(uint256 _amountFundIn) public nonReentrant{
        require(sale3Status == true, "Distribution: Sales3 is Closed");
        require(_amountFundIn%100e18 == 0, "Distribution: must be denomination of 100");
        require(_amountFundIn > 100e18, "Distribution must be more than 100");

        
        uint256 tokenPurchased = _amountFundIn.mul(100).div(price3);

        require(currentSalesLimit3.add(_amountFundIn) <= salesLimit3, "Distribution: Exceed Private sale Allocation Limit");
        currentSalesLimit3 = currentSalesLimit3.add(_amountFundIn);
        LeftOverLimit = LeftOverLimit.sub(_amountFundIn);
        uint256 totalTokensToSend = tokenPurchased;

        tokenFundIn.transferFrom(msg.sender,treasury, (_amountFundIn));
        tokenFundOut.transfer(msg.sender, totalTokensToSend);

        if(currentSalesLimit3 == salesLimit3){
            sale3Status = false;
            sale4Status = true;
        }
    }
    function exchangeSale4(uint256 _amountFundIn) public nonReentrant{
        require(sale4Status == true, "Distribution: Sales4 is Closed");
        require(_amountFundIn%100e18 == 0, "Distribution: must be denomination of 100");
        require(_amountFundIn > 100e18, "Distribution must be more than 100");

        
        uint256 tokenPurchased = _amountFundIn.mul(100).div(price4);

        require(currentSalesLimit4.add(_amountFundIn) <= salesLimit4, "Distribution: Exceed Private sale Allocation Limit");
        currentSalesLimit4 = currentSalesLimit4.add(_amountFundIn);
        LeftOverLimit = LeftOverLimit.sub(_amountFundIn);
        uint256 totalTokensToSend = tokenPurchased;

        tokenFundIn.transferFrom(msg.sender,treasury, (_amountFundIn));
        tokenFundOut.transfer(msg.sender, totalTokensToSend);

        if(currentSalesLimit4 == salesLimit4){
            sale4Status = false;
            sale5Status = true;
        }
    }
    function exchangeSale5(uint256 _amountFundIn) public nonReentrant{
        require(sale5Status == true, "Distribution: Sales5 is Closed");
        require(_amountFundIn%100e18 == 0, "Distribution: must be denomination of 100");
        require(_amountFundIn > 100e18, "Distribution must be more than 100");

        
        uint256 tokenPurchased = _amountFundIn.mul(100).div(price5);

        require(currentSalesLimit5.add(_amountFundIn) <= salesLimit5, "Distribution: Exceed Private sale Allocation Limit");
        currentSalesLimit5 = currentSalesLimit5.add(_amountFundIn);
        LeftOverLimit = LeftOverLimit.sub(_amountFundIn);
        uint256 totalTokensToSend = tokenPurchased;

        tokenFundIn.transferFrom(msg.sender,treasury, (_amountFundIn));
        tokenFundOut.transfer(msg.sender, totalTokensToSend);

        if(currentSalesLimit5 == salesLimit5){
            sale5Status = false;
            sale6Status = true;
        }
    }

    function exchangeSale6(uint256 _amountFundIn) public nonReentrant{
        require(sale6Status == true, "Distribution: Sales6 is Closed");
        require(_amountFundIn%100e18 == 0, "Distribution: must be denomination of 100");
        require(_amountFundIn > 100e18, "Distribution must be more than 100");

        
        uint256 tokenPurchased = _amountFundIn.mul(100).div(price6);

        require(currentSalesLimit6.add(_amountFundIn) <= salesLimit6, "Distribution: Exceed Private sale Allocation Limit");
        currentSalesLimit6 = currentSalesLimit6.add(_amountFundIn);
        LeftOverLimit = LeftOverLimit.sub(_amountFundIn);
        uint256 totalTokensToSend = tokenPurchased;

        tokenFundIn.transferFrom(msg.sender,treasury, (_amountFundIn));
        tokenFundOut.transfer(msg.sender, totalTokensToSend);

        if(currentSalesLimit6 == salesLimit6){
            sale6Status = false;
            sale7Status = true;
        }
    }

    function exchangeSale7(uint256 _amountFundIn) public nonReentrant{
        require(sale7Status == true, "Distribution: Sales7 is Closed");
        require(_amountFundIn%100e18 == 0, "Distribution: must be denomination of 100");
        require(_amountFundIn > 100e18, "Distribution must be more than 100");

        
        uint256 tokenPurchased = _amountFundIn.mul(100).div(price7);

        require(currentSalesLimit7.add(_amountFundIn) <= salesLimit7, "Distribution: Exceed Private sale Allocation Limit");
        currentSalesLimit7 = currentSalesLimit7.add(_amountFundIn);
        LeftOverLimit = LeftOverLimit.sub(_amountFundIn);
        uint256 totalTokensToSend = tokenPurchased;

        tokenFundIn.transferFrom(msg.sender,treasury, (_amountFundIn));
        tokenFundOut.transfer(msg.sender, totalTokensToSend);

        if(currentSalesLimit7 == salesLimit7){
            sale7Status = false;
            saleLeftOverStatus = true;
        }
    }


    function exchangeSaleLeftOver(uint256 _amountFundIn) public nonReentrant{
        require(saleLeftOverStatus == true, "Distribution: Leftover Sales is Closed");
        require(_amountFundIn%100e18 == 0, "Distribution: must be denomination of 100");
        require(_amountFundIn > 100e18, "Distribution must be more than 100");
        
        uint256 tokenPurchased = _amountFundIn.mul(100).div(price7);

        require(remainingLeftOver.add(_amountFundIn) <= LeftOverLimit, "Distribution: Exceed Leftover Allocation Limit");
        remainingLeftOver = remainingLeftOver.add(_amountFundIn);

        uint256 totalTokensToSend = tokenPurchased;

        tokenFundIn.transferFrom(msg.sender,treasury, _amountFundIn);
        tokenFundOut.transfer(msg.sender, totalTokensToSend);
    
        if(remainingLeftOver == LeftOverLimit){
            saleLeftOverStatus = false;
        }
    }

    function openSale1() public nonReentrant onlyOwner{
        require(_checkOnly1Open(), "Distribution: Only 1 Sales can be open at a time");
        sale1Status = true;
        
    }

    function openSale2() public nonReentrant onlyOwner{
        require(_checkOnly1Open(), "Distribution: Only 1 Sales can be open at a time");
        sale2Status = true;
        
    }

    function openSale3() public nonReentrant onlyOwner{
        require(_checkOnly1Open(), "Distribution: Only 1 Sales can be open at a time");
        sale3Status = true;
        
    }

    function openSale4() public nonReentrant onlyOwner{
        require(_checkOnly1Open(), "Distribution: Only 1 Sales can be open at a time");
        sale4Status = true;
        
    }

    function openSale5() public nonReentrant onlyOwner{
        require(_checkOnly1Open(), "Distribution: Only 1 Sales can be open at a time");
        sale5Status = true;
        
    }
    function openSale6() public nonReentrant onlyOwner{
        require(_checkOnly1Open(), "Distribution: Only 1 Sales can be open at a time");
        sale6Status = true;
        
    }
    function openSale7() public nonReentrant onlyOwner{
        require(_checkOnly1Open(), "Distribution: Only 1 Sales can be open at a time");
        sale7Status = true;
        
    }

    function openLeftOverSale() public nonReentrant onlyOwner{
        require(_checkOnly1Open(), "Distribution: Only 1 Sales can be open at a time");
        saleLeftOverStatus = true;
        
    }

    function closeSale1() public nonReentrant onlyOwner{
        require(_checkOnly1Open(), "Distribution: Only 1 Sales can be open at a time");
        sale1Status = false;
        
    }

    function closeSale2() public nonReentrant onlyOwner{
        require(_checkOnly1Open(), "Distribution: Only 1 Sales can be open at a time");
        sale2Status = false;
        
    }

    function closeSale3() public nonReentrant onlyOwner{
        require(_checkOnly1Open(), "Distribution: Only 1 Sales can be open at a time");
        sale3Status = false;
        
    }

    function closeSale4() public nonReentrant onlyOwner{
        require(_checkOnly1Open(), "Distribution: Only 1 Sales can be open at a time");
        sale4Status = false;
        
    }

    function closeale5() public nonReentrant onlyOwner{
        require(_checkOnly1Open(), "Distribution: Only 1 Sales can be open at a time");
        sale5Status = false;
        
    }
    function closeSale6() public nonReentrant onlyOwner{
        require(_checkOnly1Open(), "Distribution: Only 1 Sales can be open at a time");
        sale6Status = false;
        
    }
    function closeSale7() public nonReentrant onlyOwner{
        require(_checkOnly1Open(), "Distribution: Only 1 Sales can be open at a time");
        sale7Status = false;
        
    }

    function closeLeftOverSale() public nonReentrant onlyOwner{
        require(_checkOnly1Open(), "Distribution: Only 1 Sales can be open at a time");
        saleLeftOverStatus = false;
        
    }

    function closeAllSale() public nonReentrant  onlyOwner{
        sale1Status = false;
        sale2Status = false;
        sale3Status = false;
        sale4Status = false;
        sale5Status = false;
        sale6Status = false;
        sale7Status = false;
        saleLeftOverStatus = false;
    }



    function changeTreasury(address _treasury) public onlyOwner{
        treasury = _treasury;

    }

    function returnStatusArray() public view returns(bool[] memory){
        bool[] memory listOfStatus;
        listOfStatus[0] = (sale1Status);
        listOfStatus[1] = (sale2Status);
        listOfStatus[2] = (sale3Status);
        listOfStatus[3] = (sale4Status);
        listOfStatus[4] = (sale5Status);
        listOfStatus[5] = (sale6Status);
        listOfStatus[6] = (sale7Status);
        listOfStatus[7] = (saleLeftOverStatus);

        return listOfStatus;
    }

    function returnBalanceArray() public view returns(uint256[] memory) {
        uint256[] memory listOfBalance;
        listOfBalance[0] = salesLimit1.sub(currentSalesLimit1);
        listOfBalance[1] = salesLimit2.sub(currentSalesLimit2);
        listOfBalance[2] = salesLimit3.sub(currentSalesLimit3);
        listOfBalance[3] = salesLimit4.sub(currentSalesLimit4);
        listOfBalance[4] = salesLimit5.sub(currentSalesLimit5);
        listOfBalance[5] = salesLimit6.sub(currentSalesLimit6);
        listOfBalance[6] = salesLimit7.sub(currentSalesLimit7);
        listOfBalance[7] = LeftOverLimit.sub(remainingLeftOver);

        return listOfBalance;
    }


    function _checkOnly1Open() internal view returns(bool) {
        uint256 count = 0;
        if(sale1Status == true){
            count++;
        }
        if(sale2Status == true){
            count++;
        }
        if(sale3Status == true){
            count++;
        }
        if(sale4Status == true){
            count++;
        }
        if(sale5Status == true){
            count++;
        }
        if(sale6Status == true){
            count++;
        }
        if(sale7Status == true){
            count++;
        }
        if(saleLeftOverStatus == true){
            count++;
        }

        if(count > 1 ){
            return false;
        } else{
            return true;
        }
    }
}