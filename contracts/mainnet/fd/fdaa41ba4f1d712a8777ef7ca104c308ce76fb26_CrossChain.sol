/**
 *Submitted for verification at Etherscan.io on 2021-04-02
*/

// File: @openzeppelin/contracts/math/SafeMath.sol



pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
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
        return a / b;
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
        require(b > 0, errorMessage);
        return a % b;
    }
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol



pragma solidity >=0.6.0 <0.8.0;

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

// File: contracts/IERC20CrossChain.sol

pragma solidity ^0.6.12;


interface IERC20CrossChain is IERC20 {
    function mint(address account, uint256 amount) external;
    function burn(uint256 amount) external;
}

// File: @openzeppelin/contracts/utils/Context.sol



pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol



pragma solidity >=0.6.0 <0.8.0;

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
    constructor () internal {
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

// File: contracts/CrossChainAdminStorage.sol

pragma solidity ^0.6.12;


contract CrossChainAdminStorage is Ownable{

    address public admin;

    address public implementation;
}

// File: contracts/CrossChainStorage.sol

pragma solidity ^0.6.12;


contract CrossChainStorage is CrossChainAdminStorage{

    enum Chain {
        ETH, /// Ethereum
        BSC, /// Binance Smart Chain
        HECO /// Huobi ECO Chain
    }

    mapping (address => bool) public relayer;
    mapping (address => bool) public acceptToken;
    mapping (Chain => bool) public acceptChain;
    mapping (bytes32 => address[]) public relayInfo;
    uint256 public confirmRequireNum;
    mapping (Chain => uint256) public fee;
    mapping (address => uint256) public maxAmountPerDay;
    mapping (address => uint256) public maxAmount;
    mapping (address => uint256) public minAmount;
    mapping (address => uint256) public sendTotalAmount;
    mapping (address => uint256) public receiveTotalAmount;
    uint256 public timestamp;
    bool public paused;
}

// File: contracts/ICrossChain.sol

pragma solidity ^0.6.12;

interface ICrossChain {
    function setAcceptToken(address token, bool isAccepted) external;
    function setAcceptChain(uint8 chain, bool isAccepted) external;
    function addRelayer(address relayerAddress) external;
    function removeRelayer(address relayerAddress) external;
    function setConfirmRequireNum(uint256 requireNum) external;
    function setMaxAmountPerDay(address token, uint256 amount) external;
    function setFee(uint8 chain, uint256 amount) external;
    function crossChainTransfer(address token, uint256 amount, address to, uint8 chain) external payable;
    function receiveToken(address token, uint256 amount, address receiveAddress, string memory info) external;
    function transferToken(address token, uint256 amount, address to) external;
    function transfer(uint256 amount, address payable to) external;
    function pause() external;
    function unpause() external;
}

// File: contracts/CrossChain.sol

pragma solidity ^0.6.12;





contract CrossChain is CrossChainStorage {
    using SafeMath for uint256;

    enum Error {
        NO_ERROR,
        ALREADY_RELAYED,
        OVER_MAX_AMOUNT_PER_DAY
    }

    event Failure(uint256 error);

    uint256 constant secondsPerDay = 86400;

    event CrossChainTransfer(address indexed from, uint256 amount, address indexed token, address targetAddress, Chain chain, uint256 fee);
    event ReceivingToken(address indexed receiveAddress, address indexed token, uint256 amount, string info);
    event ReceiveTokenDone(address indexed receiveAddress, address indexed token, uint256 amount, string info);
    event Paused(address account);
    event Unpaused(address account);
    event AcceptToken(address token, bool isAccepted);
    event AcceptChain(Chain chain, bool isAccepted);
    event RelayerAdded(address relayer);
    event RelayerRemoved(address relayer);
    event ConfirmRequireNumChanged(uint256 oldNum,uint256 newNum);
    event MaxAmountChanged(address token, uint256 oldAmount, uint256 newAmount);
    event MinAmountChanged(address token, uint256 oldAmount, uint256 newAmount);
    event MaxAmountPerDayChanged(address token, uint256 oldMaxAmount, uint256 newMaxAmount);
    event FeeChanged(Chain chain, uint256 oldFee, uint256 newFee);

    modifier onlyRelayer() {
        require(relayer[msg.sender], "Caller is not the relayer");
        _;
    }

    modifier onlyAdmin() {
        require(admin == msg.sender, "Caller is not the admin");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "Pausable: paused");
        _;
    }

    modifier whenPaused() {
        require(paused, "Pausable: not paused");
        _;
    }

    function initialize(
        address _acceptToken,
        uint256 _confirmRequireNum,
        Chain[] memory _acceptChains,
        uint256 _timestamp
    ) external  {
        require(admin == msg.sender, "UNAUTHORIZED");
        require(timestamp == 0, "ALREADY INITIALIZED");
        timestamp = _timestamp;
        confirmRequireNum = _confirmRequireNum;
        acceptToken[_acceptToken] = true;
        for(uint8 i = 0; i < _acceptChains.length; i++){
            acceptChain[_acceptChains[i]] = true;
        }
        paused = false;
    }

    function setAcceptToken(address token, bool isAccepted) external onlyOwner{
        acceptToken[token] = isAccepted;
        emit AcceptToken(token, isAccepted);
    }

    function setAcceptChain(Chain chain, bool isAccepted) external onlyOwner{
        acceptChain[chain] = isAccepted;
        emit AcceptChain(chain, isAccepted);
    }

    function addRelayer(address relayerAddress) external onlyAdmin{
        relayer[relayerAddress] = true;
        emit RelayerAdded(relayerAddress);
    }

    function removeRelayer(address relayerAddress) external onlyOwner{
        relayer[relayerAddress] = false;
        emit RelayerRemoved(relayerAddress);
    }

    function setConfirmRequireNum(uint256 requireNum) external onlyOwner{
        uint256 oldNum = confirmRequireNum;
        confirmRequireNum = requireNum;
        emit ConfirmRequireNumChanged(oldNum, requireNum);
    }

    function setMaxAmount(address token, uint256 amount) external onlyOwner{
        require(amount >= minAmount[token], "Invalid amount");
        uint256 oldAmount = maxAmount[token];
        maxAmount[token] = amount;
        emit MaxAmountChanged(token, oldAmount, amount);
    }

    function setMinAmount(address token, uint256 amount) external onlyOwner{
        require(amount <= maxAmount[token], "Invalid amount");
        uint256 oldAmount = minAmount[token];
        minAmount[token] = amount;
        emit MinAmountChanged(token, oldAmount, amount);
    }

    function setMaxAmountPerDay(address token, uint256 amount) external onlyOwner{
        uint256 oldMaxAmount = maxAmountPerDay[token];
        maxAmountPerDay[token] = amount;
        emit MaxAmountPerDayChanged(token, oldMaxAmount, amount);
    }

    function setFee(Chain chain, uint256 amount) external onlyOwner{
        uint256 oldFee = fee[chain];
        fee[chain] = amount;
        emit FeeChanged(chain, oldFee, amount);
    }
    
    function crossChainTransfer(address token, uint256 amount, address to, Chain chain) external payable whenNotPaused {
        require(acceptToken[token],"Invalid token");
        require(acceptChain[chain],"Invalid chain");
        require(msg.value >= fee[chain], "Fee is not enough");
        checkTransferAmount(token, amount);
        (Error error,uint256 totalAmount)= addTotalAmount(token, sendTotalAmount[token], amount);
        require(uint256(error) == 0, "Total amount is greater than max amount per day");
        sendTotalAmount[token] = totalAmount;
        IERC20CrossChain(token).transferFrom(msg.sender, address(this), amount);
        emit CrossChainTransfer(msg.sender, amount, token, to, chain, msg.value);
    }

    function receiveToken(address token, uint256 amount, address receiveAddress, string memory info) external onlyRelayer whenNotPaused returns (uint256){
        bytes32 relayInfoHash = keccak256((abi.encodePacked(token,receiveAddress,amount,info)));
        if(hasRelay(relayInfoHash)) return fail(Error.ALREADY_RELAYED);
        uint256 confirmNum = relayInfo[relayInfoHash].length;
        if(confirmNum == 0){
            (Error error, uint256 totalAmount) = addTotalAmount(token, receiveTotalAmount[token], amount);
            if(uint256(error) != 0) return fail(error);
            receiveTotalAmount[token] = totalAmount;
        }
        relayInfo[relayInfoHash].push(msg.sender);
        confirmNum = confirmNum + 1;
        if(confirmNum < confirmRequireNum){
            emit ReceivingToken(receiveAddress, token, amount, info);
        }else if(relayInfo[relayInfoHash].length == confirmRequireNum){
            IERC20CrossChain(token).transfer(receiveAddress, amount);
            emit ReceivingToken(receiveAddress, token, amount, info);
            emit ReceiveTokenDone(receiveAddress, token, amount, info);
        }
        return uint256(Error.NO_ERROR);
    }

    function transferToken(address token, uint256 amount, address to) external onlyAdmin {
        IERC20CrossChain(token).transfer(to, amount);
    }

    function transfer(uint256 amount, address payable to) external onlyOwner {
        to.transfer(amount);
    }

    function pause() external whenNotPaused onlyOwner {
         paused = true;
        emit Paused(msg.sender);
    }

    function unpause() external whenPaused onlyOwner {
        paused = false;
        emit Unpaused(msg.sender);
    }

    function checkTransferAmount(address token, uint256 amount) internal view returns (uint256){
        require(amount <= maxAmount[token],"Amount is greater than max amount");
        require(amount >= minAmount[token],"Amount is less than min amount");
    }

    function addTotalAmount(address token, uint256 totalAmount, uint256 amount) internal returns (Error,uint256){
        if(block.timestamp > timestamp.add(secondsPerDay)){
            uint256 offset = block.timestamp.sub(timestamp).div(secondsPerDay).mul(secondsPerDay);
            timestamp = timestamp.add(offset);
            totalAmount = 0;
        }
        totalAmount = totalAmount.add(amount);
        if(totalAmount > maxAmountPerDay[token]) return (Error.OVER_MAX_AMOUNT_PER_DAY, totalAmount);
        return (Error.NO_ERROR ,totalAmount);
    }

    function hasRelay(bytes32 relayInfoHash) internal view returns (bool){
        address[] memory relayers = relayInfo[relayInfoHash];
        for(uint256 i = 0; i < relayers.length; i++){
            if(relayers[i] == msg.sender)
                return true;
        }
        return false;
    }

    function fail(Error err) private returns (uint) {
        emit Failure(uint256(err));
        return uint256(err);
    }
}