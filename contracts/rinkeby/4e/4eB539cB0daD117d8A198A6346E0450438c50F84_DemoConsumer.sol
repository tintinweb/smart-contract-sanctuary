// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

// must import this in order for it to connect to the system and network.
import "@unification-com/xfund-router/contracts/lib/ConsumerBase.sol";

/**
 * @title Data Consumer Demo
 *
 * @dev Note the "is ConsumerBase", to extend
 * https://github.com/unification-com/xfund-router/blob/main/contracts/lib/ConsumerBase.sol
 * ConsumerBase.sol interacts with the deployed Router.sol smart contract
 * which will route data requests and fee payment to the selected provider
 * and handle data fulfilment.
 *
 * The selected provider will listen to the Router for requests, then send the data
 * back to the Router, which will in turn forward the data to your smart contract
 * after verifying the source of the data.
 */
contract DemoConsumer is ConsumerBase, Ownable {

    // This variable will effectively be modified by the data provider.
    // Must be a uint256
    uint256 private price;

    // provider to use for data requests. Must be registered on Router
    address private provider;

    // default fee to use for data requests
    uint256 public fee;

    mapping(bytes32 => uint8) private activeRequests;

    // Will be called when data provider has sent data to the recieveData function
    event PriceDiff(bytes32 requestId, uint256 oldPrice, uint256 newPrice, int256 diff);

    /**
     * @dev constructor must pass the address of the Router and xFUND smart
     * contracts to the constructor of your contract! Without it, this contract
     * cannot interact with the system, nor request/receive any data.
     * The constructor calls the parent ConsumerBase constructor to set these.
     *
     * @param _router address of the Router smart contract
     * @param _xfund address of the xFUND smart contract
     * @param _provider address of the default provider
     * @param _fee uint256 default fee
     */
    constructor(address _router, address _xfund, address _provider, uint256 _fee)
    ConsumerBase(_router, _xfund) {
        price = 0;
        provider = _provider;
        fee = _fee;
    }

    /**
     * @dev setProvider change default provider. Uses OpenZeppelin's
     * onlyOwner modifier to secure the function.
     *
     * @param _provider address of the default provider
     */
    function setProvider(address _provider) external onlyOwner {
        provider = _provider;
    }

    /**
     * @dev setFee change default fee. Uses OpenZeppelin's
     * onlyOwner modifier to secure the function.
     *
     * @param _fee uint256 default fee
     */
    function setFee(uint256 _fee) external onlyOwner {
        fee = _fee;
    }

    /**
     * @dev getData the actual function to request data.
     *
     * NOTE: Calls ConsumerBase.sol's requestData function.
     *
     * Uses OpenZeppelin's onlyOwner modifier to secure the function.
     * The data format can be found at
     * https://docs.finchains.io/guide/ooo_api.html
     * Endpoints should be Hex encoded using, for example
     * the web3.utils.asciiToHex function.
     *
     * @param _data bytes32 data being requested.
     */
    function requestData(bytes32 _data) external onlyOwner returns (bytes32) {
        bytes32 requestId = _requestData(provider, fee, _data);
        activeRequests[requestId] = 1;
        return requestId;
    }

    /**
     * @dev getPrice returns the current price
     * @return price uint256
     */
    function getPrice() external view returns (uint256) {
        return price;
    }

    /**
     * @dev increaseRouterAllowance allows the Router to spend xFUND on behalf of this
     * smart contract.
     *
     * NOTE: Calls the internal _increaseRouterAllowance function in ConsumerBase.sol.
     *
     * Required so that xFUND fees can be paid. Uses OpenZeppelin's onlyOwner modifier
     * to secure the function.
     *
     * @param _amount uint256 amount to increase
     */
    function increaseRouterAllowance(uint256 _amount) external onlyOwner {
        require(_increaseRouterAllowance(_amount));
    }

    /**
     * @dev setRouter allows updating the Router contract address
     *
     * NOTE: Calls the internal setRouter function in ConsumerBase.sol.
     *
     * Can be used if network upgrades require new Router deployments.
     * Uses OpenZeppelin's onlyOwner modifier to secure the function.
     *
     * @param _router address new Router address
     */
    function setRouter(address _router) external onlyOwner {
        require(_setRouter(_router));
    }

    /**
     * @dev increaseRouterAllowance allows contract owner to withdraw
     * any xFUND held in this contract.
     * Uses OpenZeppelin's onlyOwner modifier to secure the function.
     *
     * @param _to address recipient
     * @param _value uint256 amount to withdraw
     */
    function withdrawxFund(address _to, uint256 _value) external onlyOwner {
        require(xFUND.transfer(_to, _value), "Not enough xFUND");
    }

    /**
     * @dev recieveData - example end user function to receive data. This will be called
     * by the data provider, via the Router's fulfillRequest, and through the ConsumerBase's
     * rawReceiveData function.
     *
     * Note: validation of the data and data provider sending the data is handled
     * by the Router smart contract prior to it forwarding the data to your contract, allowing
     * devs to focus on pure functionality. ConsumerBase.sol's rawReceiveData
     * function can only be called by the Router smart contract.
     *
     * @param _price uint256 result being sent
     * @param _requestId bytes32 request ID of the request being fulfilled
     */
    function receiveData(
        uint256 _price,
        bytes32 _requestId
    )
    internal override {
        require(activeRequests[_requestId] == 1, "request not active");
        delete activeRequests[_requestId];
        // optionally, do something and emit an event to the logs
        int256 diff = int256(_price) - int256(price);
        emit PriceDiff(_requestId, price, _price, diff);

        // set the new price as sent by the provider
        price = _price;
    }
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20_Ex {
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
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IRouter {
    function initialiseRequest(address, uint256, bytes32) external returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../vendor/OOOSafeMath.sol";
import "../interfaces/IERC20_Ex.sol";
import "../interfaces/IRouter.sol";
import "./RequestIdBase.sol";

/**
 * @title ConsumerBase smart contract
 *
 * @dev This contract can be imported by any smart contract wishing to include
 * off-chain data or data from a different network within it.
 *
 * The consumer initiates a data request by forwarding the request to the Router
 * smart contract, from where the data provider(s) pick up and process the
 * data request, and forward it back to the specified callback function.
 *
 */
abstract contract ConsumerBase is RequestIdBase {
    using OOOSafeMath for uint256;

    /*
     * STATE VARIABLES
     */

    // nonces for generating requestIds. Must be in sync with the
    // nonces defined in Router.sol.
    mapping(address => uint256) private nonces;

    IERC20_Ex internal immutable xFUND;
    IRouter internal router;

    /*
     * WRITE FUNCTIONS
     */

    /**
     * @dev Contract constructor. Accepts the address for the router smart contract,
     * and a token allowance for the Router to spend on the consumer's behalf (to pay fees).
     *
     * The Consumer contract should have enough tokens allocated to it to pay fees
     * and the Router should be able to use the Tokens to forward fees.
     *
     * @param _router address of the deployed Router smart contract
     * @param _xfund address of the deployed xFUND smart contract
     */
    constructor(address _router, address _xfund) {
        require(_router != address(0), "router cannot be the zero address");
        require(_xfund != address(0), "xfund cannot be the zero address");
        router = IRouter(_router);
        xFUND = IERC20_Ex(_xfund);
    }

    /**
     * @notice _setRouter is a helper function to allow changing the router contract address
     * Allows updating the router address. Future proofing for potential Router upgrades
     * NOTE: it is advisable to wrap this around a function that uses, for example, OpenZeppelin's
     * onlyOwner modifier
     *
     * @param _router address of the deployed Router smart contract
     */
    function _setRouter(address _router) internal returns (bool) {
        require(_router != address(0), "router cannot be the zero address");
        router = IRouter(_router);
        return true;
    }

    /**
     * @notice _increaseRouterAllowance is a helper function to increase token allowance for
     * the xFUND Router
     * Allows this contract to increase the xFUND allowance for the Router contract
     * enabling it to pay request fees on behalf of this contract.
     * NOTE: it is advisable to wrap this around a function that uses, for example, OpenZeppelin's
     * onlyOwner modifier
     *
     * @param _amount uint256 amount to increase allowance by
     */
    function _increaseRouterAllowance(uint256 _amount) internal returns (bool) {
        // The context of msg.sender is this contract's address
        require(xFUND.increaseAllowance(address(router), _amount), "failed to increase allowance");
        return true;
    }

    /**
     * @dev _requestData - initialises a data request. forwards the request to the deployed
     * Router smart contract.
     *
     * @param _dataProvider payable address of the data provider
     * @param _fee uint256 fee to be paid
     * @param _data bytes32 value of data being requested, e.g. PRICE.BTC.USD.AVG requests
     * average price for BTC/USD pair
     * @return requestId bytes32 request ID which can be used to track or cancel the request
     */
    function _requestData(address _dataProvider, uint256 _fee, bytes32 _data)
    internal returns (bytes32) {
        bytes32 requestId = makeRequestId(address(this), _dataProvider, address(router), nonces[_dataProvider], _data);
        // call the underlying ConsumerLib.sol lib's submitDataRequest function
        require(router.initialiseRequest(_dataProvider, _fee, _data));
        nonces[_dataProvider] = nonces[_dataProvider].safeAdd(1);
        return requestId;
    }

    /**
     * @dev rawReceiveData - Called by the Router's fulfillRequest function
     * in order to fulfil a data request. Data providers call the Router's fulfillRequest function
     * The request is validated to ensure it has indeed been sent via the Router.
     *
     * The Router will only call rawReceiveData once it has validated the origin of the data fulfillment.
     * rawReceiveData then calls the user defined receiveData function to finalise the fulfilment.
     * Contract developers will need to override the abstract receiveData function defined below.
     *
     * @param _price uint256 result being sent
     * @param _requestId bytes32 request ID of the request being fulfilled
     * has sent the data
     */
    function rawReceiveData(
        uint256 _price,
        bytes32 _requestId) external
    {
        // validate it came from the router
        require(msg.sender == address(router), "only Router can call");

        // call override function in end-user's contract
        receiveData(_price, _requestId);
    }

    /**
    * @dev receiveData - should be overridden by contract developers to process the
    * data fulfilment in their own contract.
    *
    * @param _price uint256 result being sent
    * @param _requestId bytes32 request ID of the request being fulfilled
    */
    function receiveData(
        uint256 _price,
        bytes32 _requestId
    ) internal virtual;

    /*
     * READ FUNCTIONS
     */

    /**
     * @dev getRouterAddress returns the address of the Router smart contract being used
     *
     * @return address
     */
    function getRouterAddress() external view returns (address) {
        return address(router);
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title RequestIdBase
 *
 * @dev A contract used by ConsumerBase and Router to generate requestIds
 *
 */
contract RequestIdBase {

    /**
    * @dev makeRequestId generates a requestId
    *
    * @param _dataConsumer address of consumer contract
    * @param _dataProvider address of provider
    * @param _router address of Router contract
    * @param _requestNonce uint256 request nonce
    * @param _data bytes32 hex encoded data endpoint
    *
    * @return bytes32 requestId
    */
    function makeRequestId(
        address _dataConsumer,
        address _dataProvider,
        address _router,
        uint256 _requestNonce,
        bytes32 _data) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_dataConsumer, _dataProvider, _router, _requestNonce, _data));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
library OOOSafeMath {
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
    function safeAdd(uint256 a, uint256 b) internal pure returns (uint256) {
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
    function safeSub(uint256 a, uint256 b) internal pure returns (uint256) {
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
    function safeMul(uint256 a, uint256 b) internal pure returns (uint256) {
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
    function saveDiv(uint256 a, uint256 b) internal pure returns (uint256) {
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
    function safeMod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

{
  "remappings": [],
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "evmVersion": "istanbul",
  "libraries": {
    "@unification-com/xfund-router/contracts/lib/ConsumerLib.sol": {
      "ConsumerLib": "0xD69582b569C5616D46f277b97d1fd49EcB9df418"
    }
  },
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