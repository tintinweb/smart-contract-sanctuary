// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// arguments
// "0xf8e81D47203A594245E36C48e151709F0C19fBe8",["0x5146a08baf902532d0ee2f909971144f12ca32651cd70cbee1117cddfb3b3b33", "0x9c1ca198f61ac1647c38f20b6678649f8e87b7e06309094d812edd1e9119d309","0x33ed200cce320c90b0f5226969f1f198e39ade4221f23425218e256d5152f765", "0x39a8b3e6e97619937505a2ae24f70fc909c329e7595f016056def5c61ec407f4","0x5351739d55170cfb22a4ca0ed7c81953f896619e021ad6df97d197953d00ffd2", "0xdd7f4dc9b35ac72d649723b085bbc7dd3f5d3da1af9751c1605dc4aa94a94866","0xa08aacfe27eee176d3a98646161bdd8127a631f5d126a7366caa91d0f6ac9fde", "0x3a2f235c9daaf33349d300aadff2f15078a89df81bcfdd45ba11c8f816bddc6f","0x175d7b85ff1bc91c4b0c406862c9875f787d29798bfc84e43d7eda7bb7543a31"],["0x4d23c8E0e601C5e37b062832427b2D62777fAEF9","0x4d23c8E0e601C5e37b062832427b2D62777fAEF9","0x4d23c8E0e601C5e37b062832427b2D62777fAEF9","0x4d23c8E0e601C5e37b062832427b2D62777fAEF9","0x4d23c8E0e601C5e37b062832427b2D62777fAEF9","0x4d23c8E0e601C5e37b062832427b2D62777fAEF9","0x4d23c8E0e601C5e37b062832427b2D62777fAEF9","0x4d23c8E0e601C5e37b062832427b2D62777fAEF9","0x4d23c8E0e601C5e37b062832427b2D62777fAEF9"],[10,"5",8,"8",10,"20",30,"3",6],[10,"10",5,"1",5,"5",1,"2",5]
// abi encoded arguments
// 000000000000000000000000f8e81d47203a594245e36c48e151709f0c19fbe800000000000000000000000000000000000000000000000000000000000000a000000000000000000000000000000000000000000000000000000000000001e00000000000000000000000000000000000000000000000000000000000000320000000000000000000000000000000000000000000000000000000000000046000000000000000000000000000000000000000000000000000000000000000095146a08baf902532d0ee2f909971144f12ca32651cd70cbee1117cddfb3b3b339c1ca198f61ac1647c38f20b6678649f8e87b7e06309094d812edd1e9119d30933ed200cce320c90b0f5226969f1f198e39ade4221f23425218e256d5152f76539a8b3e6e97619937505a2ae24f70fc909c329e7595f016056def5c61ec407f45351739d55170cfb22a4ca0ed7c81953f896619e021ad6df97d197953d00ffd2dd7f4dc9b35ac72d649723b085bbc7dd3f5d3da1af9751c1605dc4aa94a94866a08aacfe27eee176d3a98646161bdd8127a631f5d126a7366caa91d0f6ac9fde3a2f235c9daaf33349d300aadff2f15078a89df81bcfdd45ba11c8f816bddc6f175d7b85ff1bc91c4b0c406862c9875f787d29798bfc84e43d7eda7bb7543a3100000000000000000000000000000000000000000000000000000000000000090000000000000000000000004d23c8e0e601c5e37b062832427b2d62777faef90000000000000000000000004d23c8e0e601c5e37b062832427b2d62777faef90000000000000000000000004d23c8e0e601c5e37b062832427b2d62777faef90000000000000000000000004d23c8e0e601c5e37b062832427b2d62777faef90000000000000000000000004d23c8e0e601c5e37b062832427b2d62777faef90000000000000000000000004d23c8e0e601c5e37b062832427b2d62777faef90000000000000000000000004d23c8e0e601c5e37b062832427b2d62777faef90000000000000000000000004d23c8e0e601c5e37b062832427b2d62777faef90000000000000000000000004d23c8e0e601c5e37b062832427b2d62777faef90000000000000000000000000000000000000000000000000000000000000009000000000000000000000000000000000000000000000000000000000000000a000000000000000000000000000000000000000000000000000000000000000500000000000000000000000000000000000000000000000000000000000000080000000000000000000000000000000000000000000000000000000000000008000000000000000000000000000000000000000000000000000000000000000a0000000000000000000000000000000000000000000000000000000000000014000000000000000000000000000000000000000000000000000000000000001e000000000000000000000000000000000000000000000000000000000000000300000000000000000000000000000000000000000000000000000000000000060000000000000000000000000000000000000000000000000000000000000009000000000000000000000000000000000000000000000000000000000000000a000000000000000000000000000000000000000000000000000000000000000a0000000000000000000000000000000000000000000000000000000000000005000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000050000000000000000000000000000000000000000000000000000000000000005000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000005

import "./SafeMath.sol";
import "./IERC20.sol";
import "./Ownable.sol";

contract FloyxTokenomics is Ownable{

    using SafeMath for uint256;

    bytes32 public constant TEAM_ROLE = keccak256('TEAM_ROLE');
    bytes32 public constant ADVISOR_ROLE =keccak256('ADVISOR_ROLE');
    bytes32 public constant MARKETING_ROLE =keccak256('MARKETING_ROLE');
    bytes32 public constant LIQUIDITY_ROLE =keccak256('LIQUIDITY_ROLE');
    bytes32 public constant DEVELOPMENT_ROLE =keccak256('DEVELOPMENT_ROLE');
    bytes32 public constant ECOSYSTEM_ROLE =keccak256('ECOSYSTEM_ROLE');
    bytes32 public constant TOKENSALE_ROLE =keccak256('TOKENSALE_ROLE');
    bytes32 public constant AIRDROP_ROLE =keccak256('AIRDROP_ROLE');
    bytes32 public constant GRANTS_ROLE =keccak256('GRANTS_ROLE');


    string private paymentErr = "Floyx Tokenomics : No due Payments";
    uint256 public constant unixtimeOneMonth = 60*60*3;//2592000; //60*60*24*30
    bool public lockClaim = false;
    uint256 public deployedTime;

    IERC20 internal floyx;

    mapping(bytes32 => address)public roles;
    mapping(address => uint256)public tokenAllowance;
    mapping(address => uint256) public paymentPerMonth;
    mapping(address => uint) public remainingInstallments;
    mapping(address => uint) public completedInstallments;

    event FundsReleased(address indexed recepient, uint256 amount);

    constructor() {
        deployedTime = block.timestamp;
        
    }

    function init(address floyxAddress, bytes32[] memory roles_, address[] memory addresses_, uint256[] memory allowancePercentage_, 
        uint256[] memory installmentPercentage_)public onlyOwner{
        require(addresses_.length == roles_.length);
        floyx = IERC20(floyxAddress);
        uint256 totalSupply = floyx.totalSupply();

        for (uint8 i=0; i< addresses_.length; i++){

            roles[roles_[i]] = addresses_[i];
            tokenAllowance[addresses_[i]] = _percentage(totalSupply, allowancePercentage_[i]) ; // total supply percentage
            paymentPerMonth[addresses_[i]] = _percentage(tokenAllowance[addresses_[i]], installmentPercentage_[i]); // installments of supply
            remainingInstallments[addresses_[i]] =  tokenAllowance[addresses_[i]].div(paymentPerMonth[addresses_[i]]);
        }
    }

    function lockClaims() public onlyOwner {
        lockClaim = true;
    }

    function unlockClaims() public onlyOwner {
        lockClaim = false;
    }

    function distributeInstallment(address recepient, uint256 monthsToPay) private{
        uint256 amountDue=0;
        monthsToPay = monthsToPay.sub(completedInstallments[recepient]);

        for(uint256 len=monthsToPay; len>0; len--){
            if(remainingInstallments[recepient] == 0){
                break;
            }

            amountDue = amountDue.add(paymentPerMonth[recepient]);
            remainingInstallments[recepient] = remainingInstallments[recepient].sub(1);
            completedInstallments[recepient] = completedInstallments[recepient].add(1);
        }

        if (amountDue > 0) {
            _floxyTransfer(amountDue,recepient);
        }
    }

    function teamClaim()public{
        _verifyClaim(TEAM_ROLE, msg.sender);
        uint256 monthsToPay = _elapsedMonths(0);
        require (monthsToPay > 0, paymentErr);
        distributeInstallment(msg.sender,monthsToPay);
    }

    function advisorClaim()public{
        _verifyClaim(ADVISOR_ROLE, msg.sender);
        uint256 monthsToPay = _elapsedMonths(0);
        monthsToPay = monthsToPay.div(3);
        require (monthsToPay > 0,  paymentErr);

        distributeInstallment(msg.sender,monthsToPay);
    }

    function marketingClaim()public{
        _verifyClaim(MARKETING_ROLE, msg.sender);
        uint256 monthsToPay = _elapsedMonths(0);
        require (monthsToPay > 0,  paymentErr);

        distributeInstallment(msg.sender,monthsToPay);
    }

    function liquidityClaim()public{
        _verifyClaim(LIQUIDITY_ROLE, msg.sender);

        distributeInstallment(msg.sender,remainingInstallments[msg.sender]);
    }

    function developmentClaim()public{
        _verifyClaim(DEVELOPMENT_ROLE, msg.sender);
        uint256 monthsToPay = _elapsedMonths(0);
        require (monthsToPay > 0,  paymentErr);

        distributeInstallment(msg.sender,monthsToPay);
    }

    function ecosystemClaim()public{
        _verifyClaim(ECOSYSTEM_ROLE, msg.sender);
        uint256 monthsToPay = _elapsedMonths(0);
        require (monthsToPay > 0,  paymentErr);

        distributeInstallment(msg.sender,monthsToPay);
    }


    function tokenSaleClaim()public{
        _verifyClaim(TOKENSALE_ROLE, msg.sender);

        distributeInstallment(msg.sender,remainingInstallments[msg.sender]);
    }

    function airDropClaim()public{
        _verifyClaim(AIRDROP_ROLE, msg.sender);
        uint256 monthsToPay = _elapsedMonths(0);
        require (monthsToPay > 0,  paymentErr);

        distributeInstallment(msg.sender,monthsToPay);
    }

    function grantsClaim()public{
        _verifyClaim(GRANTS_ROLE, msg.sender);
        uint256 monthsToPay = _elapsedMonths(3); // 3 months lockout period
        require (monthsToPay > 0,  paymentErr);

        distributeInstallment(msg.sender,monthsToPay);
    }

    function _verifyClaim(bytes32 role_,address user_)internal view {
        require(lockClaim == false,"Floyx Tokenomics : Claim is locked now. Please try again later");
        require(roles[role_] == user_, "Floyx Tokenomics : Invalid caller");
        require(tokenAllowance[user_] > 0, "Floyx Tokenomics : All token payments already completed");
        require(remainingInstallments[user_] > 0, "Floyx Tokenomics : Installments completed");
    }

    function updateAddress(bytes32[]memory roles_, address[] memory addresses_)public onlyOwner{
        require(addresses_.length == roles_.length);
        
        for(uint8 i = 0; i< roles_.length; i++){
            require(roles[roles_[i]] != address(0), "Floyx Tokenomics : Role does not exists");
            roles[roles_[i]] = addresses_[i];
        }
    }

    function _floxyTransfer(uint256 amountDue,address recepient) internal{
            tokenAllowance[recepient] = tokenAllowance[recepient].sub(amountDue);
            floyx.transfer(recepient,amountDue);
            emit FundsReleased(recepient, amountDue);
    }
  
    function _percentage(uint256 totalAmount_,uint256 percentage_) internal pure returns(uint256) {
        return (totalAmount_.mul(percentage_).div(100));
    }

    function _elapsedMonths(uint256 _lockPeriod) internal view returns(uint256) {
        uint256 presentTime = block.timestamp;
        uint256 elapsedTime = presentTime.sub(deployedTime);
     
        uint256 unixlocktime = _lockPeriod.mul(unixtimeOneMonth);
        require(elapsedTime > unixlocktime,"Floyx Tokenomics : Lock period is active");
        elapsedTime = elapsedTime.sub(unixlocktime);
        require(elapsedTime > 0, "Floyx Tokenomics : Lock period is active");      
        uint256 elapsedMonth = elapsedTime.div(unixtimeOneMonth);
        return elapsedMonth;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
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
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

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

import "./Context.sol";
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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