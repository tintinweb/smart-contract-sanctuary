// "SPDX-License-Identifier: MIT"
pragma solidity >=0.6.6;
pragma experimental ABIEncoderV2;

import "./vendors/interfaces/IUniswapOracle.sol";
import "./vendors/interfaces/IERC20.sol";
import "./vendors/libraries/SafeMath.sol";
import "./vendors/libraries/SafeERC20.sol";
import "./vendors/libraries/Whitelist.sol";
import "./vendors/libraries/TxStorage.sol";



// helper methods for interacting with sending ETH that do not consistently return true/false
library TransferHelper {
    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }

}

contract BasePool is Whitelist, TxStorage {
    
    using SafeMath for uint;
    using SafeERC20 for IERC20;

    address public _oracleAddress;
    address public _PACT;

    uint public _minBuy;
    uint public _price;

    event Deposit(uint amount, uint price);
    event Withdraw(uint tokensAmount, uint price);
    
 constructor (
        address governanceAddress,
        address oracleAddress,
        address PACT,
        uint minBuy,
        uint price
    ) {
        require (oracleAddress != address(0), "ORACLE ADDRESS SHOULD BE NOT NULL");
        require (PACT != address(0), "PACT ADDRESS SHOULD BE NOT NULL");

        _oracleAddress = oracleAddress;
        _PACT = PACT;
        
        _minBuy = minBuy == 0 ? 10000e18 : minBuy;
        _price = price == 0 ? 100000 : price; //USDT 

        SetGovernance(governanceAddress == address(0) ? msg.sender : governanceAddress);
        IUniswapOracle(_oracleAddress).update();
    }
    
    
    function buylimitsUpdate( uint minLimit) public onlyGovernance {
        _minBuy = minLimit;
    }
    

    function changeOracleAddress (address oracleAddress) 
      public 
      onlyGovernance {
        require (oracleAddress != address(0), "NEW ORACLE ADDRESS SHOULD BE NOT NULL");

        _oracleAddress = oracleAddress;
    }


	function calcPriceEthUdtPact(uint amountIn) public view returns (uint amountOut) {
        uint WETHPrice = IUniswapOracle(_oracleAddress).consultAB(amountIn);
        amountOut = WETHPrice.div(_price).mul(1e18);
	}


    function depositEthToToken() public onlyWhitelisted payable {
        uint amountIn = msg.value;
        IUniswapOracle(_oracleAddress).update();
        uint tokensAmount = calcPriceEthUdtPact(amountIn);
        IERC20 PACT = IERC20(_PACT);

        require(tokensAmount >= _minBuy);
        require(tokensAmount <= PACT.balanceOf(address(this)), "NOT ENOUGH PACT TOKENS ON BASEPOOl CONTRACT BALANCE");

        PACT.safeTransfer(msg.sender, tokensAmount);
        transactionAdd(tokensAmount,amountIn);

        emit Deposit(tokensAmount, amountIn);
    }
    

    function withdrawEthFromToken(uint index) external onlyWhitelisted {
        IERC20 PACT = IERC20(_PACT);
        checkTrransaction(msg.sender , index);
        (uint amount, uint price,,,) = getTransaction(msg.sender , index);
        
        require(address(this).balance >= price, "NOT ENOUGH ETH ON BASEPOOl CONTRACT BALANCE");
        require(PACT.allowance(msg.sender, address(this)) >= amount, "NOT ENOUGH DELEGATED PACT TOKENS ON DESTINATION BALANCE");

        closedTransaction(msg.sender, index);
        PACT.safeTransferFrom(msg.sender, amount);
        TransferHelper.safeTransferETH(msg.sender, price);

        emit Withdraw(amount, price);
    }





}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.6;

interface IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    
    function balanceOf(address tokenOwner) external view returns (uint balance);
    function allowance(address tokenOwner, address spender) external view returns (uint remaining);
    function approve(address spender, uint tokens) external returns (bool success);
    function transfer(address to, uint tokens) external returns (bool success);
    function transferFrom(address from, address to, uint tokens) external returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

// "SPDX-License-Identifier: MIT"
pragma solidity >=0.6.6;

interface IUniswapOracle {
	function getPair() external view returns (
     address
	);
	function update() external;
	function getTimeElapsed(address tokenIn, address tokenOut) external view returns (uint) ;
    function consultWETHUSDT(uint amountIn) external view returns (uint amountOut);
    function consultAB(uint amountIn) external view  returns (uint amountOut);
    function consultBA(uint amountIn) external view  returns (uint amountOut);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.6;


contract GovernanceOwnable {
    address private _governanceAddress;

    event GovernanceSetTransferred(address indexed previousGovernance, address indexed newGovernance);

    /**
     * @dev Initializes the contract setting the deployer as the initial governance.
     */
    constructor () {
        _governanceAddress = msg.sender;
        emit GovernanceSetTransferred(address(0), msg.sender);
    }

    /**
     * @dev Returns the address of the current governanceAddress.
     */
    function governance() public view returns (address) {
        return _governanceAddress;
    }

    /**
     * @dev Throws if called by any account other than the governanceAddress.
     */
    modifier onlyGovernance() {
        require(_governanceAddress == msg.sender, "Governance: caller is not the governance");
        _;
    }

    /**
     * @dev SetGovernance of the contract to a new account (`newGovernance`).
     * Can only be called by the current onlyGovernance.
     */
    function SetGovernance(address newGovernance) public virtual onlyGovernance {
        require(newGovernance != address(0), "GovernanceOwnable: new governance is the zero address");
        emit GovernanceSetTransferred(_governanceAddress, newGovernance);
        _governanceAddress = newGovernance;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.6;

import "../interfaces/IERC20.sol";

library SafeERC20 {
    function safeSymbol(IERC20 token) internal view returns(string memory) {
        (bool success, bytes memory data) = address(token).staticcall(abi.encodeWithSelector(0x95d89b41));
        return success && data.length > 0 ? abi.decode(data, (string)) : "???";
    }

    function safeName(IERC20 token) internal view returns(string memory) {
        (bool success, bytes memory data) = address(token).staticcall(abi.encodeWithSelector(0x06fdde03));
        return success && data.length > 0 ? abi.decode(data, (string)) : "???";
    }

    function safeDecimals(IERC20 token) public view returns (uint8) {
        (bool success, bytes memory data) = address(token).staticcall(abi.encodeWithSelector(0x313ce567));
        return success && data.length == 32 ? abi.decode(data, (uint8)) : 18;
    }

    function safeTransfer(IERC20 token, address to, uint256 amount) internal {
        (bool success, bytes memory data) = address(token).call(abi.encodeWithSelector(0xa9059cbb, to, amount));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "SafeERC20: Transfer failed");
    }

    function safeApprove(IERC20 token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = address(token).call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransferFrom(IERC20 token, address from, uint256 amount) internal {
        (bool success, bytes memory data) = address(token).call(abi.encodeWithSelector(0x23b872dd, from, address(this), amount));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "SafeERC20: TransferFrom failed");
    }
}

pragma solidity >=0.5.16;
// "SPDX-License-Identifier: Apache License 2.0"


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
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// "SPDX-License-Identifier: MIT"
pragma solidity >=0.6.6;
pragma experimental ABIEncoderV2;

import "./SafeMath.sol";
import "./GovernanceOwnable.sol";

contract TxStorage is GovernanceOwnable{	
	using SafeMath for uint;

    uint private expirePeriod = 7776000;

    struct Transaction {
		uint ammount;		
		uint price;	
        uint timestamp;
        uint expireTimeStamp;
        bool closed;
	}


    mapping(address => mapping (uint => Transaction)) internal transactionsHistory;
    mapping(address => uint) internal index;

    function setExparePeriud(uint _epirePeriod) external onlyGovernance payable{
        expirePeriod = _epirePeriod;
    }

    function transactionAdd(uint ammount, uint price) internal{
       uint timestamp = block.timestamp;
       _transactionAdd(msg.sender, ammount, price, timestamp, timestamp.add(expirePeriod));
    }

    function closedTransaction(address to, uint _index) internal {
         transactionsHistory[to][_index].closed = true;
    }

    function _transactionAdd(address to, uint ammount, uint price, uint timestamp, uint expireTimeStamp) internal {
        index[to] +=1;
        transactionsHistory[to][index[to]] = Transaction(ammount, price, timestamp, expireTimeStamp, false);
    }

    function getTransaction(address to, uint _index) public view returns (uint ammount, uint price, uint timestamp, uint expireTimeStamp, bool closed) {
       require(transactionsHistory[to][_index].timestamp != 0 , "INDEX OUT OF RANGE");
       ammount = transactionsHistory[to][_index].ammount;
       price =transactionsHistory[to][_index].price;
       timestamp = transactionsHistory[to][_index].timestamp;
       expireTimeStamp = transactionsHistory[to][_index].expireTimeStamp;
       closed = transactionsHistory[to][_index].closed;
    }


    function checkTrransaction(address to, uint _index) internal view{
       Transaction memory transaction = transactionsHistory[to][_index];
       require(transaction.timestamp != 0 , "INDEX OUT OF RANGE");
       require(!transaction.closed , "THE TRANSACTION IS CLOSED");
       require(block.timestamp <= transaction.expireTimeStamp, "TRANSACTION TIME EXPIRED");
    }


    function getTransactionlastIndex(address to) external view returns (uint ) {
        return index[to];
    }

}

// "SPDX-License-Identifier: MIT"
pragma solidity >=0.6.6;


import "./GovernanceOwnable.sol";

contract Whitelist is GovernanceOwnable {
    mapping(address => bool) whitelist;
    event AddedToWhitelist(address indexed account);
    event RemovedFromWhitelist(address indexed account);

    modifier onlyWhitelisted() {
        require(isWhitelisted(msg.sender));
        _;
    }

    function whitelistAdd(address _address) public onlyGovernance {
        whitelist[_address] = true;
        emit AddedToWhitelist(_address);
    }

    function whitelistRemove(address _address) public onlyGovernance {
        whitelist[_address] = false;
        emit RemovedFromWhitelist(_address);
    }

    function isWhitelisted(address _address) public view returns(bool) {
        return whitelist[_address];
    }
}