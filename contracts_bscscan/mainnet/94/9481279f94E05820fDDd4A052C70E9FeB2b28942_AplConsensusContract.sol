/**
 *Submitted for verification at BscScan.com on 2021-12-19
*/

// File: contract-6627c3a6ea.sol


// File: contract-6627c3a6ea.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
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
    constructor() {
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

contract AplConsensusContract is Pausable, Ownable {
    using SafeMath for uint256;

    uint256 OneDayInSeconds = 24 * 60 * 60;
    // uint256 OneDayInSeconds = 60;
    uint256 public maxUsdtLimit = 0;

    uint256 public aplPriceInUsdt;
    address public receiveAddress;

    address public adminAddress;
    address public adminReceiveAddress;

    struct Presale { 
        uint256 investedUsdt;
        uint256 aplAmount;
        uint256 withdrawedApl;
        uint256 lastWithdrawTime;
        uint256 withdrawTimes;
        bool isAllive;
    }

    uint256 public systemTotalAplAmount;
    uint256 public systemTotalWithdrawedAplAmount;
    mapping(address => uint256) public ownerOfTotalUsdt;
    mapping(address => uint256) public ownerOfAplAmount;
    mapping(address => Presale[]) public ownerOfPresales;

    IERC20 usdt; 
    IERC20 apl;

    function setAplPriceInUsdt(uint256 _aplPriceInUsdt) public {
        require(_aplPriceInUsdt != 0, "Invalid Apl Price");
        require(msg.sender == adminAddress, "Unauthorized Account");
        aplPriceInUsdt = _aplPriceInUsdt;
    }

    function setReceiveAddress(address _receiveAddress) public {
        require(_receiveAddress != address(0), "Invalid Receive Address");
        require(msg.sender == adminReceiveAddress, "Unauthorized Account");
        receiveAddress = _receiveAddress;
    }

    function setAplAddress(address _address) public onlyOwner {
        apl = IERC20(address(_address));
    }

    function setUsdtAddress(address _address) public onlyOwner {
        usdt = IERC20(address(_address));
    }

    function setMaxUsdtAmount(uint256 _max) public {
        require(msg.sender == adminAddress, "Unauthorized Account");
        maxUsdtLimit = _max;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function buyAplWithUsdt(uint256 _usdtAmount) public {
        uint256 totalUsdtAmount = ownerOfTotalUsdt[msg.sender];
        totalUsdtAmount = totalUsdtAmount.add(_usdtAmount);
        require(totalUsdtAmount <= maxUsdtLimit, "Exceed maximum usdt amount");
        ownerOfTotalUsdt[msg.sender] = totalUsdtAmount;
        // user has approve this contract
        usdt.transferFrom(msg.sender, receiveAddress, _usdtAmount);

        uint256 aplAmount = _usdtAmount.div(aplPriceInUsdt).mul(10**18);
        Presale memory presale = Presale(_usdtAmount, aplAmount, 0, block.timestamp, 0, true);
        ownerOfPresales[msg.sender].push(presale);

        uint256 totalAplAmount = ownerOfAplAmount[msg.sender];
        totalAplAmount = totalAplAmount.add(aplAmount);
        ownerOfAplAmount[msg.sender] = totalAplAmount;
        systemTotalAplAmount = systemTotalAplAmount.add(totalAplAmount);

        uint256 cunrrentAplBalance = apl.balanceOf(address(this));
        uint256 leftBalance = systemTotalAplAmount.sub(systemTotalWithdrawedAplAmount).add(_usdtAmount);
        require(cunrrentAplBalance >= leftBalance, "Not enough apl in this contract");
    }

    function withdrawApl() public {
        uint256 withdrawAmount = 0;
        uint256 nowTime = block.timestamp;
        for(uint8 i=0; i < ownerOfPresales[msg.sender].length; i++){
            if(ownerOfPresales[msg.sender][i].isAllive && ownerOfPresales[msg.sender][i].lastWithdrawTime!=0){
                uint256 lastWithdrawTime = ownerOfPresales[msg.sender][i].lastWithdrawTime;
                uint256 withdrawTimes = ownerOfPresales[msg.sender][i].withdrawTimes;
                uint256 timespan = nowTime.sub(lastWithdrawTime);
                uint256 mod = timespan.mod(OneDayInSeconds);
                uint256 numOfDays = timespan.sub(mod).div(OneDayInSeconds);
                if(numOfDays > 0){
                    ownerOfPresales[msg.sender][i].lastWithdrawTime = nowTime;
                    if(withdrawTimes.add(numOfDays) >= 1000){
                        ownerOfPresales[msg.sender][i].withdrawTimes = 1000; 
                        withdrawAmount = withdrawAmount.add(ownerOfPresales[msg.sender][i].aplAmount.sub(ownerOfPresales[msg.sender][i].withdrawedApl));
                        ownerOfPresales[msg.sender][i].withdrawedApl = ownerOfPresales[msg.sender][i].aplAmount;
                        ownerOfPresales[msg.sender][i].isAllive = false;
                    }else{
                        ownerOfPresales[msg.sender][i].withdrawTimes = withdrawTimes.add(numOfDays); 
                        uint256 amount = ownerOfPresales[msg.sender][i].aplAmount.mul(numOfDays.mul(1)).div(1000);
                        withdrawAmount = withdrawAmount.add(amount);
                        ownerOfPresales[msg.sender][i].withdrawedApl = ownerOfPresales[msg.sender][i].withdrawedApl.add(amount);
                    }
                }
            }
        }
        apl.transfer(msg.sender, withdrawAmount);
        systemTotalWithdrawedAplAmount = systemTotalWithdrawedAplAmount.add(withdrawAmount);
    }

    function getAplBalance(address _address) public view returns(uint256) {
        require(_address != address(0), "Invalid address");
        uint256 withdrawAmount = 0;
        uint256 nowTime = block.timestamp;
        for(uint8 i=0; i < ownerOfPresales[_address].length; i++){
            if(ownerOfPresales[_address][i].isAllive && ownerOfPresales[_address][i].lastWithdrawTime!=0){
                uint256 lastWithdrawTime = ownerOfPresales[_address][i].lastWithdrawTime;
                uint256 withdrawTimes = ownerOfPresales[_address][i].withdrawTimes;
                uint256 timespan = nowTime.sub(lastWithdrawTime);
                uint256 mod = timespan.mod(OneDayInSeconds);
                uint256 numOfDays = timespan.sub(mod).div(OneDayInSeconds);
                if(numOfDays > 0){
                    if(withdrawTimes.add(numOfDays) >= 1000){ 
                        withdrawAmount = withdrawAmount.add(ownerOfPresales[_address][i].aplAmount.sub(ownerOfPresales[_address][i].withdrawedApl));
                    }else{
                        uint256 aplAmount = ownerOfPresales[_address][i].aplAmount;
                        uint256 amount = aplAmount.mul(numOfDays.mul(1)).div(1000);
                        withdrawAmount = withdrawAmount.add(amount);
                    }
                }
            }
        }
        return withdrawAmount;
    }

    function setAdminAddress(address _address) public onlyOwner {
        require(_address != address(0), "Invalid address");
        adminAddress = _address;
    }

    function setAdminReceiveAddress(address _address) public onlyOwner {
        require(_address != address(0), "Invalid address");
        adminReceiveAddress = _address;
    }
}