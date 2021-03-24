pragma solidity 0.5.16;

import "../library/SafeMath.sol";
import "../interface/IApiConsumer.sol";
import "../interface/IOraiToken.sol";
import "../interface/IOracle.sol";
import "../interface/IHash.sol";

library Oraichain {
    struct Request {
        bytes32 id;
        address callbackAddress;
        bytes4 callbackFunction;
        uint256 nonce;
        bytes data;
    }
    struct callbackController {
        address callbackAddress;
        bytes4 callbackFunction;
    }


    function initialize(
        Request memory self,
        bytes32 _id,
        address _callbackAddress,
        bytes4 callbackFunction
    ) internal pure returns (Request memory) {
        self.id = _id;
        self.callbackAddress = _callbackAddress;
        self.callbackFunction = callbackFunction;
        return self;
    }

    function addData(Request memory self, bytes  memory _data) internal pure
    {
        self.data = _data;
    }
}

contract OraichainClient {
    using Oraichain for Oraichain.Request;
    using SafeMath for uint256;

    uint256 constant internal ORAI = 10 ** 18;
    uint256 constant private AMOUNT_OVERRIDE = 0;
    address constant private SENDER_OVERRIDE = address(0);

    IOraiToken private orai;
    IOracle private oracle;
    uint256 private requestCount = 1;
    mapping(bytes32 => address) private pendingRequests;

    event Requested(bytes32 indexed id);
    event Fulfilled(bytes32 indexed id);


    function buildOraichainRequest(
        bytes32 _specId,
        address _callbackAddress,
        bytes4 _callbackFunction
    ) internal pure returns (Oraichain.Request memory) {
        Oraichain.Request memory req;
        return req.initialize(_specId, _callbackAddress, _callbackFunction);
    }

    function sendOraichainRequest(Oraichain.Request memory _req, uint256 _payment)
    internal
    returns (bytes32)
    {
        return sendOraichainRequestTo(address(oracle), _req, _payment);
    }



    function sendOraichainRequestTo(address _oracle, Oraichain.Request memory _req, uint256 _payment)
    internal
    returns (bytes32 requestId)
    {
        requestId = keccak256(abi.encodePacked(this, requestCount));
        _req.nonce = requestCount;
        pendingRequests[requestId] = _oracle;
        emit Requested(requestId);
        require(orai.transferAndCall(_oracle, _payment, encodeRequest(_req)), "A0");
        requestCount += 1;
        return requestId;
    }

    function setOraichainOracle(address _oracle) internal {
        oracle = IOracle(_oracle);
    }

    function setPublicOraichainToken(address _token) internal {
        orai = IOraiToken(_token);
    }


    function oraichainTokenAddress() internal view returns (address)
    {
        return address(orai);
    }


    function oraichainOracleAddress() internal view returns (address)
    {
        return address(oracle);
    }


    function encodeRequest(Oraichain.Request memory _req)
    private
    view
    returns (bytes memory)
    {
        return abi.encodeWithSelector(
            oracle.oracleRequest.selector,
            SENDER_OVERRIDE, // Sender value - overridden by onTokenTransfer by the requesting contract's address
            AMOUNT_OVERRIDE, // Amount value - overridden by onTokenTransfer by the actual amount of LINK sent
            _req.id,
            _req.callbackAddress,
            _req.callbackFunction,
            _req.nonce,
            _req.data
        );
    }


    function validateOraichainCallback(bytes32 _requestId)
    internal
    recordOraichainFulfillment(_requestId)
        // solhint-disable-next-line no-empty-blocks
    {}


    modifier recordOraichainFulfillment(bytes32 _requestId) {
        require(msg.sender == pendingRequests[_requestId],
            "A1");
        delete pendingRequests[_requestId];
        emit Fulfilled(_requestId);
        _;
    }


    modifier notPendingRequest(bytes32 _requestId) {
        require(pendingRequests[_requestId] == address(0), "A2");
        _;
    }
}

pragma solidity 0.5.16;


contract APIConsumer is OraichainClient {

    uint256 public volume;
    address private _owner;
    address private oracle;
    bytes32 private jobId;
    uint256 private fee;
    address private libHash;
    mapping(address => bool) requesterPermission;
    mapping(bytes32 => Oraichain.callbackController) public callbackControllers;

    constructor(address _oracle, address _token) public {
        _owner = msg.sender;
        setPublicOraichainToken(_token);
        oracle = _oracle;
        jobId = "29fa9aa13bf1468788b7cc4a500a45b8";
        fee = 0.001 * 10 ** 18;

    }
    modifier requireOwner()  {
        require(msg.sender == _owner, "A3");
        _;
    }


    modifier requireOwnerOrRequester()  {
        require(msg.sender == _owner || requesterPermission[msg.sender], "A4");
        _;
    }

    function changeOwner(address _newOwner) public requireOwner {
        _owner = _newOwner;
    }

    function owner() public view returns (address) {
        return _owner;
    }

    function setRequesterPermission(address requester, bool allowed) public requireOwner {
        requesterPermission[requester] = allowed;
    }

    function setLibHash(address _libAddress) public requireOwner{
        libHash = _libAddress;
    }
    function requestData(bytes memory data, bytes4 callbackFunctionId, address callbackAddress) public requireOwnerOrRequester returns (bytes32 requestId)
    {
        require(callbackAddress != address(0), "A5");
        Oraichain.Request memory request = buildOraichainRequest(jobId,  address(this), this.checkResultRequestFutureWeights.selector);
        request.addData(data);
        bytes32 requestId = sendOraichainRequestTo(oracle, request, fee);
        callbackControllers[requestId] = Oraichain.callbackController(callbackAddress,callbackFunctionId);
        return requestId;
    }

    function checkResultRequestFutureWeights(bytes calldata data,bytes32  hashCheck ,bytes32 _requestId) external returns(bool) {
        (address vault, address[] memory strategy, uint256[] memory weight) = abi.decode(data, (address, address[],uint256[]));
        require(libHash != address(0),"Address lib hash 0x");
        require(IHash(libHash).hash(IHash(libHash).encode(weight)) == hashCheck,"check hash failed");
        require( callbackControllers[_requestId].callbackAddress != address(0),"callbackAddress 0x");
        require( callbackControllers[_requestId].callbackFunction != bytes4(0),"callbackFunction 0x");
        (bool success,) =  callbackControllers[_requestId].callbackAddress.call(abi.encodeWithSelector( callbackControllers[_requestId].callbackFunction, data));
        return success;
    }

    function inCaseTokenStuck() external requireOwner {
        IOraiToken oraiToken = IOraiToken(oraichainTokenAddress());
        require(oraiToken.transfer(msg.sender, oraiToken.balanceOf(address(this))), "A6");
    }
}

pragma solidity 0.5.16;

interface IApiConsumer {
    function requestData(bytes calldata data, bytes4 callbackFunctionId, address callbackAddress) external returns (bytes32 requestId);

    function changeOwner(address _newOwner) external;

    function owner() external view returns (address);

    function setRequesterPermission(address requester, bool allowed) external;

    function fulfill(bytes32 _requestId, bytes calldata data) external;

    function inCaseTokenStuck() external;
}

pragma solidity 0.5.16;

interface IHash {

    function hash(bytes calldata data) external view returns (bytes32);

    function encode(uint256[] calldata data) external view returns(bytes memory);

}

pragma solidity 0.5.16;

interface IOracle {
    function oracleRequest(
        address sender,
        uint256 requestPrice,
        bytes32 serviceAgreementID,
        address callbackAddress,
        bytes4 callbackFunction,
        uint256 nonce,
        bytes calldata data
    ) external;

    function fulfillOracleRequest(
        bytes32 requestId,
        address callbackAddress,
        bytes4 callbackFunctionId,
        bytes calldata hashCheck,
        bytes calldata data
    ) external returns (bool);

    function getAuthorizationStatus(address node) external view returns (bool);

    function setFulfillmentPermission(address node, bool allowed) external;

    function withdraw(uint256 amount) external;

    event OracleRequest(
        address requester,
        bytes32 requestId,
        bytes32 jobId,
        uint256 payment,
        address callbackAddr,
        bytes4 callbackFunction,
        bytes data
    );
}

pragma solidity 0.5.16;

interface IOraiToken{
    function allowance(address owner, address spender) external view returns (uint256 remaining);

    function approve(address spender, uint256 value) external returns (bool success);

    function balanceOf(address owner) external view returns (uint256 balance);

    function decimals() external view returns (uint8 decimalPlaces);

    function decreaseApproval(address spender, uint256 addedValue) external returns (bool success);

    function increaseApproval(address spender, uint256 subtractedValue) external;

    function name() external view returns (string memory tokenName);

    function symbol() external view returns (string memory tokenSymbol);

    function totalSupply() external view returns (uint256 totalTokensIssued);

    function transfer(address to, uint256 value) external returns (bool success);

    function transferAndCall(address to, uint256 value, bytes calldata data) external returns (bool success);

    function transferFrom(address from, address to, uint256 value) external returns (bool success);
}

pragma solidity 0.5.16;
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