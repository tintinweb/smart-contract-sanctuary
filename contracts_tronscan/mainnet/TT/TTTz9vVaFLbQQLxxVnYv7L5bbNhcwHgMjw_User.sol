//SourceUnit: Temp.sol

// File: contracts/interface/IUser.sol

pragma solidity >=0.5.15  <=0.5.17;

interface IUser{
    function totalSupply(address token) external view returns (uint256);
    function balance(address token, address owner) external view returns (uint256);

    function deposit(uint8 coinType, address token, uint256 value) external payable;
    function withdraw(uint8 coinType, address token, uint256 value) external;

    function transfer(address token, address fromUser, uint256 value) external returns (bool);
    function receiveToken(address token, address toUser, uint256 value) external returns (bool);
}

// File: contracts/interface/IERC20.sol

pragma solidity >=0.5.15  <=0.5.17;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
 */
interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint);

    function balanceOf(address owner) external view returns (uint);

    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);

    function transfer(address to, uint value) external returns (bool);

    function transferFrom(address from, address to, uint value) external returns (bool);
}

// File: contracts/interface/IWrappedCoin.sol

pragma solidity >=0.5.15  <=0.5.17;

interface IWrappedCoin {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

// File: contracts/interface/IManager.sol

pragma solidity >=0.5.15  <=0.5.17;

interface IManager{
    function feeOwner() external view returns (address);
    function riskFundingOwner() external view returns (address);
    function poolFeeOwner() external view returns (address);
    function taker() external view returns (address);
    function checkSigner(address _signer)  external view returns(bool);
    function checkController(address _controller)  view external returns(bool);
    function checkRouter(address _router) external view returns(bool);
    function checkMarket(address _market) external view returns(bool);
    function checkMaker(address _maker) external view returns(bool);

    function cancelBlockElapse() external returns (uint256);
    function openLongBlockElapse() external returns (uint256);

    function paused() external returns (bool);

}

// File: contracts/library/SafeMath.sol

pragma solidity >=0.5.15  <=0.5.17;

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
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
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
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
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
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
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: contracts/library/Address.sol

pragma solidity >=0.5.15  <=0.5.17;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * This test is non-exhaustive, and there may be false-negatives: during the
     * execution of a contract's constructor, its address will be reported as
     * not containing a contract.
     *
     * IMPORTANT: It is unsafe to assume that an address for which this
     * function returns false is an externally-owned account (EOA) and not a
     * contract.
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != 0x0 && codehash != accountHash);
    }

    /**
     * @dev Converts an `address` into `address payable`. Note that this is
     * simply a type cast: the actual underlying value is not changed.
     *
     * _Available since v2.4.0._
     */
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     *
     * _Available since v2.4.0._
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-call-value
        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

// File: contracts/library/TransferHelper.sol

pragma solidity >=0.5.15  <=0.5.17;


library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // usdt of tron mainnet TR7NHqjeKQxGTCi8q8ZY4pL8otSzgjLj6t: 0x41a614f803b6fd780986a42c78ec9c7f77e6ded13c
        if (token == address(0x41a614f803b6fd780986a42c78ec9c7f77e6ded13c)){
            IERC20(token).transfer(to, value);
            return;
        }

        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call.value(value)(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}

// File: contracts/library/ReentrancyGuard.sol

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.15  <=0.5.17;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
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

// File: contracts/User.sol

pragma solidity >=0.5.15  <=0.5.17;









contract User is IUser, ReentrancyGuard {
    using SafeMath for uint256;

    address public wCoin;                                           // wrapped contract
    address public manager;                                         // manager contract
    mapping(address => bool) public tokenList;                      // tokens supported
    mapping(address => uint256) public totalSupply;                 // token:totalSupply
    mapping(address => mapping(address => uint256)) public balance; // token:owner:balance
    bool public depositPaused = true;
    bool public withdrawPaused = true;

    event Transfer(address token, address from, address to, uint256 value);
    event ReceiveToken(address token, address from, address to, uint256 value);
    event Deposit(address token, address user, uint256 value);
    event Withdraw(address token, address user, uint256 value);
    event AddToken(address token);

    constructor(address _m, address _wCoin) public {
        require(_m != address(0), "invalid manager");
        require(_wCoin != address(0), "invalid wrapped contract");
        manager = _m;
        wCoin = _wCoin;
    }

    function() external payable {
        require(msg.sender == wCoin, "invalid recharge method, please use deposit function");
    }

    modifier onlyController(){
        require(IManager(manager).checkController(msg.sender), "not controller");
        _;
    }

    modifier whenDepositNotPaused() {
        require(!depositPaused, "paused");
        _;
    }

    modifier whenWithdrawNotPaused() {
        require(!withdrawPaused, "paused");
        _;
    }

    modifier onlyMakerOrMarket() {
        require(IManager(manager).checkMarket(msg.sender) || IManager(manager).checkMaker(msg.sender), "insufficient permissions!");
        _;
    }

    function setPaused(bool _depositPaused, bool _withdrawPaused) external onlyController {
       depositPaused = _depositPaused;
       withdrawPaused = _withdrawPaused;
    }

    function addToken(address _token) external onlyController returns (bool){
        require(msg.sender != address(0), "invalid sender address");
        require(_token != address(0), "invalid token address");
        tokenList[_token] = true;

        emit AddToken(_token);
        return true;
    }

/*
    address(0) for tron: 0x410000000000000000000000000000000000000000 or T9yD14Nj9j7xAB4dbGeiX9h8unkKHxuWwb

    deposit coin or token
    coinType: 0 for coin like eth or trx, 1 for token

    example:
    deposit trx:    deposit(0, T9yD14Nj9j7xAB4dbGeiX9h8unkKHxuWwb, 0).send({callValue: 99999})
    deposit token:  deposit(1, token, 99999).send();
*/
    function deposit(uint8 coinType, address token, uint256 value) external nonReentrant whenDepositNotPaused payable {
         require(coinType == 0 || coinType == 1, "invalid coin type!");

        if (coinType == 0) {
             require(token == address(0), "token address must be address(0)!");
             require(tokenList[wCoin], "not in token list");
             require(value == 0, "token value must be 0!");
             require(msg.value > 0, "invalid value!");

            // trx -> WTrx
            IWrappedCoin(wCoin).deposit.value(msg.value)();
            totalSupply[wCoin] = totalSupply[wCoin].add(msg.value);
            balance[wCoin][msg.sender] = balance[wCoin][msg.sender].add(msg.value);

            emit Deposit(wCoin, msg.sender, msg.value);
        }else{
            require(token != address(0), "token address can not be address 0!");
            require(Address.isContract(token), "token must be a contract address!");
            require(tokenList[token], "not in token list");
            require(value > 0, "invalid value!");

            TransferHelper.safeTransferFrom(token, msg.sender, address(this), value);
            totalSupply[token] = totalSupply[token].add(value);
            balance[token][msg.sender]=balance[token][msg.sender].add(value);

            emit Deposit(token, msg.sender, value);
         }
    }

/*
    withdraw coin or token
    coinType: 0 fro coin like eth or trx, 1 for token

    example:
    withdraw trx:   withdraw(0, T9yD14Nj9j7xAB4dbGeiX9h8unkKHxuWwb, 99999).send();
    withdraw token: withdraw(1, token, 99999).send();
*/
    function withdraw(uint8 coinType, address token, uint256 value) external nonReentrant whenWithdrawNotPaused {
        require(coinType == 0 || coinType == 1, "invalid coin type!");
        require(value > 0, "invalid value!");

        if (coinType == 0) {
            require(token == address(0), "token address must be address 0!");
            require(balance[wCoin][msg.sender] >= value);

            totalSupply[wCoin] = totalSupply[wCoin].sub(value);
            balance[wCoin][msg.sender] = balance[wCoin][msg.sender].sub(value);
            IWrappedCoin(wCoin).withdraw(value);
            TransferHelper.safeTransferETH(msg.sender, value);

            emit Withdraw(wCoin, msg.sender, value);
         }else{
            require(token != address(0), "token address can not be address 0!");
            require(Address.isContract(token), "token must be a contract address!");
            require(balance[token][msg.sender] >= value, "insufficient balance");

            totalSupply[token] = totalSupply[token].sub(value);
            balance[token][msg.sender] = balance[token][msg.sender].sub(value);
            TransferHelper.safeTransfer(token, msg.sender, value);

            emit Withdraw(token, msg.sender, value);
        }
    }

    function transfer(address token, address fromUser, uint256 value) external nonReentrant onlyMakerOrMarket returns (bool){
        require(token != address(0), "token address can not be address 0");
        require(fromUser != address(0), "fromUser address can not be address 0");
        require(value > 0, "invalid value");
        require(balance[token][fromUser] >= value, "insufficient balance");

        totalSupply[token] = totalSupply[token].sub(value);
        balance[token][fromUser] = balance[token][fromUser].sub(value);
        TransferHelper.safeTransfer(token, msg.sender, value);

        emit Transfer(token, fromUser, msg.sender, value);
        return true;
    }

    function receiveToken(address token, address toUser, uint256 value) external nonReentrant onlyMakerOrMarket returns (bool){
        require(token != address(0), "token address can not be address 0");
        require(toUser != address(0), "toUser address can not be address 0");
        require(value > 0, "invalid value");
        totalSupply[token] = totalSupply[token].add(value);
        balance[token][toUser] = balance[token][toUser].add(value);

        emit ReceiveToken(token, msg.sender, toUser, value);
        return true;
    }
}