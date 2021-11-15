pragma solidity 0.5.16;

import "../interface/IOracle.sol";
import "../interface/IOraiToken.sol";
import "../library/SafeMath.sol";


contract OraiTokenReceiver {

    uint256 constant private SELECTOR_LENGTH = 4;
    uint256 constant private EXPECTED_REQUEST_WORDS = 2;

    function onTokenTransfer(
        address _sender,
        uint256 _amount,
        bytes memory _data
    )
    public
    onlyOrai
    permittedFunctionsForCallData(_data)
    {
        assembly {
            mstore(add(_data, 36), _sender) // ensure correct sender is passed
            mstore(add(_data, 68), _amount)    // ensure correct amount is passed
        }
        (bool success,) = address(this).delegatecall(_data);
        require(success, "O0");
    }

    function getOraichainToken() public view returns (address);


    modifier onlyOrai() {
        require(msg.sender == getOraichainToken(), "01");
        _;
    }

    modifier permittedFunctionsForCallData(bytes memory _data) {
        bytes4 funcSelector;
        assembly {
            funcSelector := mload(add(_data, 32))
        }
        require(funcSelector == 0x320aecd3, "02");
        _;
    }
}

contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }


    function owner() public view returns (address) {
        return _owner;
    }


    modifier onlyOwner() {
        require(isOwner(), "03");
        _;
    }


    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }


    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "04");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}




contract Oracle is IOracle, Ownable, OraiTokenReceiver {
    using SafeMath for uint256;

    uint256 constant private MINIMUM_CONSUMER_GAS_LIMIT = 400000;
    mapping(bytes32 => uint256) public paymentFee;
    mapping(address => uint256) public rewardClaim;

    IOraiToken internal oraiToken;
    mapping(bytes32 => bytes32) public commitments;
    mapping(address => bool) private authorizedNodes;

    event OracleRequest(
        address requester,
        bytes32 requestId,
        bytes32 jobId,
        uint256 payment,
        address callbackAddr,
        bytes4 callbackFunction,
        bytes data
    );


    constructor(address _token)
    public
    Ownable()
    {
        oraiToken = IOraiToken(_token);
    }


    /**
     * @notice Creates the request
     * @dev Stores the hash of the params as the on-chain commitment for the request.
     * Emits OracleRequest event for the validator to detect.
     * @param _sender The sender of the request
     * @param _payment The amount of payment given (specified in wei)
     * @param _specId The Job Specification ID
     * @param _callbackAddress The callback address for the response
     * @param _callbackFunction The callback function ID for the response
     * @param _nonce The nonce sent by the requester
     * @param data The data of the request
     */
    function oracleRequest(
        address _sender,
        uint256 _payment,
        bytes32 _specId,
        address _callbackAddress,
        bytes4 _callbackFunction,
        uint256 _nonce,
        bytes calldata data
    )
    external
    onlyOrai()
    checkCallbackAddress(_callbackAddress)
    {
        bytes32 requestId = keccak256(abi.encodePacked(_sender, _nonce));
        require(commitments[requestId] == 0, "O5");
        commitments[requestId] = keccak256(
            abi.encodePacked(
                _callbackAddress,
                _callbackFunction
            )
        );
        paymentFee[requestId] = _payment;
        emit OracleRequest(
            _sender,
            requestId,
            _specId,
            _payment,
            _callbackAddress,
            _callbackFunction,
            data
        );
    }

    /**
    * @notice Allows validator fulfill data to callbackAddress contract and in function callbackFunctionId
    * Remove commitments requestId
    * Add reward claim to validator
    * @param _requestId The request ID
    * @param _callbackAddress The address contract to fulfill data
    * @param _callbackFunctionId The function to call in callbackAddress
    * @param _data The encoded data to fill in function in _callbackAddress
    */
    function fulfillOracleRequest(
        bytes32 _requestId,
        address _callbackAddress,
        bytes4 _callbackFunctionId,
        bytes32 hashCheck,
        bytes calldata _data
    )
    external
    onlyAuthorizedNode
    isValidRequest(_requestId)
    returns (bool)
    {
        bytes32 id = _requestId;
        bytes32 paramsHash = keccak256(
            abi.encodePacked(
                _callbackAddress,
                _callbackFunctionId
            )
        );
        require(commitments[_requestId] == paramsHash, "O6");
        require(gasleft() >= MINIMUM_CONSUMER_GAS_LIMIT, "O7");
        delete commitments[_requestId];
        rewardClaim[msg.sender] += paymentFee[_requestId];
        (bool success,) = _callbackAddress.call(abi.encodeWithSelector(_callbackFunctionId, _data, hashCheck,id));

        return success;
    }


    function getAuthorizationStatus(address _node) external view returns (bool)
    {
        return authorizedNodes[_node];
    }


    /**
    * @notice Set permission for node
    * Only nodes in authorizedNodes is allowance call fulfillOracleRequest
    * @param _node The node address
    * @param _allowed The permission
    */
    function setFulfillmentPermission(address _node, bool _allowed) external onlyOwner()
    {
        authorizedNodes[_node] = _allowed;
    }


    /**
    * @notice Withdraw request fee for validator
    * @dev Only when msg.sender == owner or msg.sender = validator and token fee of this address > _amount
    * @param _amount The amount to withdraw
    */
    function withdraw(uint256 _amount) external hasAvailableFunds(_amount)
    {
        assert(oraiToken.transfer(msg.sender, _amount));
    }

    function getOraichainToken() public view returns (address)
    {
        return address(oraiToken);
    }


    modifier hasAvailableFunds(uint256 _amount) {
        require(oraiToken.balanceOf(address(this)) >= _amount, "O8");
        if (!isOwner()) {
            require(rewardClaim[msg.sender] >= _amount, "O9");
        }
        _;
    }


    modifier isValidRequest(bytes32 _requestId) {
        require(commitments[_requestId] != 0, "O10");
        _;
    }

    modifier onlyAuthorizedNode() {
        require(authorizedNodes[msg.sender] || msg.sender == owner(), "O11");
        _;
    }


    modifier checkCallbackAddress(address _to) {
        require(_to != address(oraiToken), "O12");
        _;
    }

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
        bytes32 hashCheck,
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

