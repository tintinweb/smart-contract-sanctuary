// "SPDX-License-Identifier: MIT"
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "../vendors/contracts/access/Whitelist.sol";
import "../vendors/contracts/TxStorage.sol";
import "../vendors/interfaces/IUniswapOracle.sol";
import "../vendors/interfaces/IERC20.sol";
import "../vendors/libraries/SafeMath.sol";
import "../vendors/libraries/SafeERC20.sol";
import "../vendors/libraries/TransferHelper.sol";


contract PactBasePool is Whitelist, TxStorage {
    
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
        uint minBuy

    ) public GovernanceOwnable(governanceAddress) {
        require (oracleAddress != address(0), "ORACLE ADDRESS SHOULD BE NOT NULL");
        require (PACT != address(0), "PACT ADDRESS SHOULD BE NOT NULL");

        _oracleAddress = oracleAddress;
        _PACT = PACT;
        
        _minBuy = minBuy == 0 ? 10000e18 : minBuy;
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


	function calcPriceEthPact(uint amountInEth) public view returns (uint) {
        uint price = IUniswapOracle(_oracleAddress).consultAB(1e18);
        if (price > 1e18){
            return amountInEth.mul(price.div(1e18));
        }
        return amountInEth.mul(uint(1e18).div(price));
	}

	function calcPricePactEth(uint amountInPact) public view returns (uint) {
        uint price = IUniswapOracle(_oracleAddress).consultAB(1e18);
        if (price > 1e18){
            return amountInPact.div(price.div(1e18));
        }
        return amountInPact.div(uint(1e18).div(price));
	}


    function changeEthToToken() public onlyWhitelisted payable {
        uint amountIn = msg.value;
        IUniswapOracle(_oracleAddress).update();
        uint tokensAmount = calcPriceEthPact(amountIn);
        IERC20 PACT = IERC20(_PACT);

        require(tokensAmount >= _minBuy, "BUY LIMIT");
        require(tokensAmount <= PACT.balanceOf(address(this)), "NOT ENOUGH PACT TOKENS ON BASEPOOl CONTRACT BALANCE");

        PACT.safeTransfer(msg.sender, tokensAmount);
        transactionAdd(tokensAmount,amountIn);

        emit Deposit(tokensAmount, amountIn);
    }
    

    function returnToken(uint index) external onlyWhitelisted {
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


    function withdrawEthForExpiredTransaction(address to) public onlyGovernance{
        uint actualBalanceOfTransactions = amountOfActualTransactions();
        uint balance = address(this).balance;
        require(balance > actualBalanceOfTransactions,"");
        TransferHelper.safeTransferETH(to,balance.sub(actualBalanceOfTransactions));   
    }
    
}

// "SPDX-License-Identifier: MIT"
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "../libraries/SafeMath.sol";
import "./access/GovernanceOwnable.sol";

abstract contract TxStorage is GovernanceOwnable{
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
    address [] public userList;

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
        if (index[to]==0){
            userList.push(to);
        }
        index[to] +=1;
        transactionsHistory[to][index[to]] = Transaction(ammount, price, timestamp, expireTimeStamp, false);
    }


    function amountOfActualTransactions() public view returns (uint result) {
        for (uint i = 0; i < userList.length; i++) {
            for (uint a = 0; a <= index[userList[i]]; a++) {
               if (transactionsHistory[userList[i]][a].expireTimeStamp > block.timestamp){
                   result += transactionsHistory[userList[i]][a].price;
               }
            }           
        }
        return result;
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

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "../../interfaces/IGovernanceOwnable.sol";

abstract contract GovernanceOwnable is IGovernanceOwnable {
    address private _governanceAddress;

    event GovernanceSetTransferred(address indexed previousGovernance, address indexed newGovernance);

    constructor (address governance_) public {
        require(governance_ != address(0), "Governance address should be not null");
        _governanceAddress = governance_;
        emit GovernanceSetTransferred(address(0), governance_);
    }

    /**
     * @dev Returns the address of the current governanceAddress.
     */
    function governance() public view override returns (address) {
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
    function setGovernance(address newGovernance) public virtual override onlyGovernance {
        require(newGovernance != address(0), "GovernanceOwnable: new governance is the zero address");
        emit GovernanceSetTransferred(_governanceAddress, newGovernance);
        _governanceAddress = newGovernance;
    }

}

// "SPDX-License-Identifier: MIT"
pragma solidity 0.6.12;


import "./GovernanceOwnable.sol";

abstract contract Whitelist is GovernanceOwnable {
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

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

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

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;


interface IGovernanceOwnable {
    event GovernanceSetTransferred(address indexed previousGovernance, address indexed newGovernance);

    function governance() external view returns (address);
    function setGovernance(address newGovernance) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IUniswapOracle {
	function getPair() external view returns (address);
	function update() external;
	function getTimeElapsed(address tokenIn, address tokenOut) external view returns (uint);
    function consultAB(uint amountIn) external view  returns (uint amountOut);
    function consultBA(uint amountIn) external view  returns (uint amountOut);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

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

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return add(a, b, "SafeMath: Add Overflow");
    }
    function add(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, errorMessage);// "SafeMath: Add Overflow"

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: Underflow");
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;// "SafeMath: Underflow"

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return mul(a, b, "SafeMath: Mul Overflow");
    }
    function mul(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, errorMessage);// "SafeMath: Mul Overflow"

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: division by zero");
        uint256 c = a / b;

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
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
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}

{
  "remappings": [],
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "evmVersion": "istanbul",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}