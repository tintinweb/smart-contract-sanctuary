/**
 *Submitted for verification at Etherscan.io on 2020-07-17
*/

/**
 *Submitted for verification at Etherscan.io on 2020-06-11
*/

// File: contracts/interfaces/IERC20.sol

pragma solidity ^0.6.6;


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

// File: contracts/utils/SafeMath.sol

pragma solidity ^0.6.6;


library SafeMath {
    using SafeMath for uint256;

    function add(uint256 x, uint256 y) internal pure returns (uint256) {
        uint256 z = x + y;
        require(z >= x, "Add overflow");
        return z;
    }

    function sub(uint256 x, uint256 y) internal pure returns (uint256) {
        require(x >= y, "Sub overflow");
        return x - y;
    }

    function mul(uint256 x, uint256 y) internal pure returns (uint256) {
        if (x == 0) {
            return 0;
        }

        uint256 z = x * y;
        require(z/x == y, "Mult overflow");
        return z;
    }

    function div(uint256 x, uint256 y) internal pure returns (uint256) {
        require(y != 0, "Div by zero");
        return x / y;
    }

    function multdiv(uint256 x, uint256 y, uint256 z) internal pure returns (uint256) {
        require(z != 0, "div by zero");
        return x.mul(y) / z;
    }
}

// File: contracts/interfaces/IERC173.sol

pragma solidity ^0.6.6;


/// @title ERC-173 Contract Ownership Standard
/// @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-173.md
///  Note: the ERC-165 identifier for this interface is 0x7f5828d0
interface IERC173 {
    /// @dev This emits when ownership of a contract changes.
    event OwnershipTransferred(address indexed _previousOwner, address indexed _newOwner);

    /// @notice Get the address of the owner
    /// @return The address of the owner.
    function owner() external view returns (address);

    /// @notice Set the address of the new owner of the contract
    /// @param _newOwner The address of the new owner of the contract
    function transferOwnership(address _newOwner) external;
}

// File: contracts/utils/Ownable.sol

pragma solidity ^0.6.6;



contract Ownable is IERC173 {
    address internal _owner;

    modifier onlyOwner() {
        require(msg.sender == _owner, "The owner should be the sender");
        _;
    }

    constructor() public {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0x0), msg.sender);
    }

    function owner() external override view returns (address) {
        return _owner;
    }

    /**
        @dev Transfers the ownership of the contract.

        @param _newOwner Address of the new owner
    */
    function transferOwnership(address _newOwner) external override onlyOwner {
        require(_newOwner != address(0), "0x0 Is not a valid owner");
        emit OwnershipTransferred(_owner, _newOwner);
        _owner = _newOwner;
    }
}

// File: contracts/interfaces/rcn/ICosigner.sol

pragma solidity ^0.6.6;


interface ICosigner {
    function cost(
        address engine,
        uint256 index,
        bytes calldata data,
        bytes calldata oracleData
    ) external view returns (uint256);
}

// File: contracts/interfaces/rcn/IModel.sol

pragma solidity ^0.6.6;


/**
    The abstract contract Model defines the whole lifecycle of a debt on the DebtEngine.

    Models can be used without previous approbation, this is meant
    to avoid centralization on the development of RCN; this implies that not all models are secure.
    Models can have back-doors, bugs and they have not guarantee of being autonomous.

    The DebtEngine is meant to be the User of this model,
    so all the methods with the ability to perform state changes should only be callable by the DebtEngine.

    All models should implement the 0xaf498c35 interface.

    @author Agustin Aguilar
*/
interface IModel {
    // ///
    // Events
    // ///

    /**
        @dev This emits when create a new debt.
    */
    event Created(bytes32 indexed _id);

    /**
        @dev This emits when the status of debt change.

        @param _timestamp Timestamp of the registry
        @param _status New status of the registry
    */
    event ChangedStatus(bytes32 indexed _id, uint256 _timestamp, uint256 _status);

    /**
        @dev This emits when the obligation of debt change.

        @param _timestamp Timestamp of the registry
        @param _debt New debt of the registry
    */
    event ChangedObligation(bytes32 indexed _id, uint256 _timestamp, uint256 _debt);

    /**
        @dev This emits when the frequency of debt change.

        @param _timestamp Timestamp of the registry
        @param _frequency New frequency of each installment
    */
    event ChangedFrequency(bytes32 indexed _id, uint256 _timestamp, uint256 _frequency);

    /**
        @param _timestamp Timestamp of the registry
    */
    event ChangedDueTime(bytes32 indexed _id, uint256 _timestamp, uint256 _status);

    /**
        @param _timestamp Timestamp of the registry
        @param _dueTime New dueTime of each installment
    */
    event ChangedFinalTime(bytes32 indexed _id, uint256 _timestamp, uint64 _dueTime);

    /**
        @dev This emits when the call addDebt function.

        @param _amount New amount of the debt, old amount plus added
    */
    event AddedDebt(bytes32 indexed _id, uint256 _amount);

    /**
        @dev This emits when the call addPaid function.

        If the registry is fully paid on the call and the amount parameter exceeds the required
            payment amount, the event emits the real amount paid on the payment.

        @param _paid Real amount paid
    */
    event AddedPaid(bytes32 indexed _id, uint256 _paid);

    // ///
    // Meta
    // ///

    /**
        @return Identifier of the model
    */
    function modelId() external view returns (bytes32);

    /**
        Returns the address of the contract used as Descriptor of the model

        @dev The descriptor contract should follow the ModelDescriptor.sol scheme

        @return Address of the descriptor
    */
    function descriptor() external view returns (address);

    /**
        If called for any address with the ability to modify the state of the model registries,
            this method should return True.

        @dev Some contracts may check if the DebtEngine is
            an operator to know if the model is operative or not.

        @param operator Address of the target request operator

        @return canOperate True if operator is able to modify the state of the model
    */
    function isOperator(address operator) external view returns (bool canOperate);

    /**
        Validates the data for the creation of a new registry, if returns True the
            same data should be compatible with the create method.

        @dev This method can revert the call or return false, and both meant an invalid data.

        @param data Data to validate

        @return isValid True if the data can be used to create a new registry
    */
    function validate(bytes calldata data) external view returns (bool isValid);

    // ///
    // Getters
    // ///

    /**
        Exposes the current status of the registry. The possible values are:

        1: Ongoing - The debt is still ongoing and waiting to be paid
        2: Paid - The debt is already paid and
        4: Error - There was an Error with the registry

        @dev This method should always be called by the DebtEngine

        @param id Id of the registry

        @return status The current status value
    */
    function getStatus(bytes32 id) external view returns (uint256 status);

    /**
        Returns the total paid amount on the registry.

        @dev it should equal to the sum of all real addPaid

        @param id Id of the registry

        @return paid Total paid amount
    */
    function getPaid(bytes32 id) external view returns (uint256 paid);

    /**
        If the returned amount does not depend on any interactions and only on the model logic,
            the defined flag will be True; if the amount is an estimation of the future debt,
            the flag will be set to False.

        If timestamp equals the current moment, the defined flag should always be True.

        @dev This can be a gas-intensive method to call, consider calling the run method before.

        @param id Id of the registry
        @param timestamp Timestamp of the obligation query

        @return amount Amount pending to pay on the given timestamp
        @return defined True If the amount returned is fixed and can't change
    */
    function getObligation(bytes32 id, uint64 timestamp) external view returns (uint256 amount, bool defined);

    /**
        The amount required to fully paid a registry.

        All registries should be payable in a single time, even when it has multiple installments.

        If the registry discounts interest for early payment, those discounts should be
            taken into account in the returned amount.

        @dev This can be a gas-intensive method to call, consider calling the run method before.

        @param id Id of the registry

        @return amount Amount required to fully paid the loan on the current timestamp
    */
    function getClosingObligation(bytes32 id) external view returns (uint256 amount);

    /**
        The timestamp of the next required payment.

        After this moment, if the payment goal is not met the debt will be considered overdue.

            The getObligation method can be used to know the required payment on the future timestamp.

        @param id Id of the registry

        @return timestamp The timestamp of the next due time
    */
    function getDueTime(bytes32 id) external view returns (uint256 timestamp);

    // ///
    // Metadata
    // ///

    /**
        If the loan has multiple installments returns the duration of each installment in seconds,
            if the loan has not installments it should return 1.

        @param id Id of the registry

        @return frequency Frequency of each installment
    */
    function getFrequency(bytes32 id) external view returns (uint256 frequency);

    /**
        If the loan has multiple installments returns the total of installments,
            if the loan has not installments it should return 1.

        @param id Id of the registry

        @return installments Total of installments
    */
    function getInstallments(bytes32 id) external view returns (uint256 installments);

    /**
        The registry could be paid before or after the date, but the debt will always be
            considered overdue if paid after this timestamp.

        This is the estimated final payment date of the debt if it is always paid on each exact dueTime.

        @param id Id of the registry

        @return timestamp Timestamp of the final due time
    */
    function getFinalTime(bytes32 id) external view returns (uint256 timestamp);

    /**
        Similar to getFinalTime returns the expected payment remaining if paid always on the exact dueTime.

        If the model has no interest discounts for early payments,
            this method should return the same value as getClosingObligation.

        @param id Id of the registry

        @return amount Expected payment amount
    */
    function getEstimateObligation(bytes32 id) external view returns (uint256 amount);

    // ///
    // State interface
    // ///

    /**
        Creates a new registry using the provided data and id, it should fail if the id already exists
            or if calling validate(data) returns false or throws.

        @dev This method should only be callable by an operator

        @param id Id of the registry to create
        @param data Data to construct the new registry

        @return success True if the registry was created
    */
    function create(bytes32 id, bytes calldata data) external returns (bool success);

    /**
        If the registry is fully paid on the call and the amount parameter exceeds the required
            payment amount, the method returns the real amount used on the payment.

        The payment taken should always be the same as the requested unless the registry
            is fully paid on the process.

        @dev This method should only be callable by an operator

        @param id If of the registry
        @param amount Amount to pay

        @return real Real amount paid
    */
    function addPaid(bytes32 id, uint256 amount) external returns (uint256 real);

    /**
        Adds a new amount to be paid on the debt model,
            each model can handle the addition of more debt freely.

        @dev This method should only be callable by an operator

        @param id Id of the registry
        @param amount Debt amount to add to the registry

        @return added True if the debt was added
    */
    function addDebt(bytes32 id, uint256 amount) external returns (bool added);

    // ///
    // Utils
    // ///

    /**
        Runs the internal clock of a registry, this is used to compute the last changes on the state.
            It can make transactions cheaper by avoiding multiple calculations when calling views.

        Not all models have internal clocks, a model without an internal clock should always return false.

        Calls to this method should be possible from any address,
            multiple calls to run shouldn"t affect the internal calculations of the model.

        @dev If the call had no effect the method would return False,
            that is no sign of things going wrong, and the call shouldn"t be wrapped on a require

        @param id If of the registry

        @return effect True if the run performed a change on the state
    */
    function run(bytes32 id) external returns (bool effect);
}

// File: contracts/interfaces/rcn/IRateOracle.sol

pragma solidity ^0.6.6;


/// @dev Defines the interface of a standard Diaspore RCN Oracle,
/// The contract should also implement it is ERC165 interface: 0xa265d8e0
/// @notice Each oracle can only support one currency
/// @author Agustin Aguilar
interface IRateOracle {
    function readSample(bytes calldata _data) external returns (uint256 _tokens, uint256 _equivalent);
}

// File: contracts/interfaces/rcn/IDebtEngine.sol

pragma solidity ^0.6.6;




interface IDebtEngine {
    function debts(
        bytes32 _id
    ) external view returns(
        bool error,
        uint128 balance,
        IModel model,
        address creator,
        IRateOracle oracle
    );

    function create(
        IModel _model,
        address _owner,
        address _oracle,
        bytes calldata _data
    ) external returns (bytes32 id);

    function create2(
        IModel _model,
        address _owner,
        address _oracle,
        uint256 _salt,
        bytes calldata _data
    ) external returns (bytes32 id);

    function create3(
        IModel _model,
        address _owner,
        address _oracle,
        uint256 _salt,
        bytes calldata _data
    ) external returns (bytes32 id);

    function buildId(
        address _creator,
        uint256 _nonce
    ) external view returns (bytes32);

    function buildId2(
        address _creator,
        address _model,
        address _oracle,
        uint256 _salt,
        bytes calldata _data
    ) external view returns (bytes32);

    function buildId3(
        address _creator,
        uint256 _salt
    ) external view returns (bytes32);

    function pay(
        bytes32 _id,
        uint256 _amount,
        address _origin,
        bytes calldata _oracleData
    ) external returns (uint256 paid, uint256 paidToken);

    function payToken(
        bytes32 id,
        uint256 amount,
        address origin,
        bytes calldata oracleData
    ) external returns (uint256 paid, uint256 paidToken);

    function payBatch(
        bytes32[] calldata _ids,
        uint256[] calldata _amounts,
        address _origin,
        address _oracle,
        bytes calldata _oracleData
    ) external returns (uint256[] memory paid, uint256[] memory paidTokens);

    function payTokenBatch(
        bytes32[] calldata _ids,
        uint256[] calldata _tokenAmounts,
        address _origin,
        address _oracle,
        bytes calldata _oracleData
    ) external returns (uint256[] memory paid, uint256[] memory paidTokens);

    function withdraw(
        bytes32 _id,
        address _to
    ) external returns (uint256 amount);

    function withdrawPartial(
        bytes32 _id,
        address _to,
        uint256 _amount
    ) external returns (bool success);

    function withdrawBatch(
        bytes32[] calldata _ids,
        address _to
    ) external returns (uint256 total);

    function transferFrom(address _from, address _to, uint256 _assetId) external;

    function getStatus(bytes32 _id) external view returns (uint256);
}

// File: contracts/interfaces/rcn/ILoanManager.sol

pragma solidity ^0.6.6;




interface ILoanManager {
    function token() external view returns (IERC20);

    function debtEngine() external view returns (IDebtEngine);
    function getCurrency(uint256 _id) external view returns (bytes32);
    function getAmount(uint256 _id) external view returns (uint256);
    function getAmount(bytes32 _id) external view returns (uint256);
    function getOracle(uint256 _id) external view returns (address);

    function settleLend(
        bytes calldata _requestData,
        bytes calldata _loanData,
        address _cosigner,
        uint256 _maxCosignerCost,
        bytes calldata _cosignerData,
        bytes calldata _oracleData,
        bytes calldata _creatorSig,
        bytes calldata _borrowerSig
    ) external returns (bytes32 id);

    function lend(
        bytes32 _id,
        bytes calldata _oracleData,
        address _cosigner,
        uint256 _cosignerLimit,
        bytes calldata _cosignerData,
        bytes calldata _callbackData
    ) external returns (bool);

}

// File: contracts/interfaces/ITokenConverter.sol

pragma solidity ^0.6.6;



interface ITokenConverter {
    function convertFrom(
        IERC20 _fromToken,
        IERC20 _toToken,
        uint256 _fromAmount,
        uint256 _minReceive
    ) external payable returns (uint256 _received);

    function convertTo(
        IERC20 _fromToken,
        IERC20 _toToken,
        uint256 _toAmount,
        uint256 _maxSpend
    ) external payable returns (uint256 _spend);

    function getPriceConvertFrom(
        IERC20 _fromToken,
        IERC20 _toToken,
        uint256 _fromAmount
    ) external view returns (uint256 _receive);

    function getPriceConvertTo(
        IERC20 _fromToken,
        IERC20 _toToken,
        uint256 _toAmount
    ) external view returns (uint256 _spend);
}

// File: contracts/utils/SafeERC20.sol

pragma solidity ^0.6.6;



/**
* @dev Library to perform safe calls to standard method for ERC20 tokens.
*
* Why Transfers: transfer methods could have a return value (bool), throw or revert for insufficient funds or
* unathorized value.
*
* Why Approve: approve method could has a return value (bool) or does not accept 0 as a valid value (BNB token).
* The common strategy used to clean approvals.
*
* We use the Solidity call instead of interface methods because in the case of transfer, it will fail
* for tokens with an implementation without returning a value.
* Since versions of Solidity 0.4.22 the EVM has a new opcode, called RETURNDATASIZE.
* This opcode stores the size of the returned data of an external call. The code checks the size of the return value
* after an external call and reverts the transaction in case the return data is shorter than expected
* https://github.com/nachomazzara/SafeERC20/blob/master/contracts/libs/SafeERC20.sol
*/
library SafeERC20 {
    /**
    * @dev Transfer token for a specified address
    * @param _token erc20 The address of the ERC20 contract
    * @param _to address The address which you want to transfer to
    * @param _value uint256 the _value of tokens to be transferred
    * @return bool whether the transfer was successful or not
    */
    function safeTransfer(IERC20 _token, address _to, uint256 _value) internal returns (bool) {
        uint256 prevBalance = _token.balanceOf(address(this));

        if (prevBalance < _value) {
            // Insufficient funds
            return false;
        }

        (bool success,) = address(_token).call(
            abi.encodeWithSignature("transfer(address,uint256)", _to, _value)
        );

        if (!success || prevBalance - _value != _token.balanceOf(address(this))) {
            // Transfer failed
            return false;
        }

        return true;
    }

    /**
    * @dev Transfer tokens from one address to another
    * @param _token erc20 The address of the ERC20 contract
    * @param _from address The address which you want to send tokens from
    * @param _to address The address which you want to transfer to
    * @param _value uint256 the _value of tokens to be transferred
    * @return bool whether the transfer was successful or not
    */
    function safeTransferFrom(
        IERC20 _token,
        address _from,
        address _to,
        uint256 _value
    ) internal returns (bool)
    {
        uint256 prevBalance = _token.balanceOf(_from);

        if (prevBalance < _value) {
            // Insufficient funds
            return false;
        }

        if (_token.allowance(_from, address(this)) < _value) {
            // Insufficient allowance
            return false;
        }

        (bool success,) = address(_token).call(
            abi.encodeWithSignature("transferFrom(address,address,uint256)", _from, _to, _value)
        );

        if (!success || prevBalance - _value != _token.balanceOf(_from)) {
            // Transfer failed
            return false;
        }

        return true;
    }

   /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   *
   * Beware that changing an allowance with this method brings the risk that someone may use both the old
   * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
   * race condition is to first reduce the spender"s allowance to 0 and set the desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   *
   * @param _token erc20 The address of the ERC20 contract
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   * @return bool whether the approve was successful or not
   */
    function safeApprove(IERC20 _token, address _spender, uint256 _value) internal returns (bool) {
        (bool success,) = address(_token).call(
            abi.encodeWithSignature("approve(address,uint256)",_spender, _value)
        );

        if (!success && _token.allowance(address(this), _spender) != _value) {
            // Approve failed
            return false;
        }

        return true;
    }

   /**
   * @dev Clear approval
   * Note that if 0 is not a valid value it will be set to 1.
   * @param _token erc20 The address of the ERC20 contract
   * @param _spender The address which will spend the funds.
   */
    function clearApprove(IERC20 _token, address _spender) internal returns (bool) {
        bool success = safeApprove(_token, _spender, 0);

        if (!success) {
            success = safeApprove(_token, _spender, 1);
        }

        return success;
    }
}

// File: contracts/utils/SafeTokenConverter.sol

pragma solidity ^0.6.6;






library SafeTokenConverter {
    IERC20 constant private ETH_TOKEN_ADDRESS = IERC20(0x00eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee);
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    function safeConvertFrom(
        ITokenConverter _converter,
        IERC20 _fromToken,
        IERC20 _toToken,
        uint256 _fromAmount,
        uint256 _minReceive
    ) internal returns (uint256 _received) {
        uint256 prevBalance = _selfBalance(_toToken);

        if (_fromToken == ETH_TOKEN_ADDRESS) {
            _converter.convertFrom{
                value: _fromAmount
            }(
                _fromToken,
                _toToken,
                _fromAmount,
                _minReceive
            );
        } else {
            require(_fromToken.safeApprove(address(_converter), _fromAmount), "error approving converter");
            _converter.convertFrom(
                _fromToken,
                _toToken,
                _fromAmount,
                _minReceive
            );

            require(_fromToken.clearApprove(address(_converter)), "error clearing approve");
        }

        _received = _selfBalance(_toToken).sub(prevBalance);
        require(_received >= _minReceive, "_minReceived not reached");
    }

    function safeConvertTo(
        ITokenConverter _converter,
        IERC20 _fromToken,
        IERC20 _toToken,
        uint256 _toAmount,
        uint256 _maxSpend
    ) internal returns (uint256 _spend) {
        uint256 prevFromBalance = _selfBalance(_fromToken);
        uint256 prevToBalance = _selfBalance(_toToken);

        if (_fromToken == ETH_TOKEN_ADDRESS) {
            _converter.convertTo{
                value: _maxSpend
            }(
                _fromToken,
                _toToken,
                _toAmount,
                _maxSpend
            );
        } else {
            require(_fromToken.safeApprove(address(_converter), _maxSpend), "error approving converter");
            _converter.convertTo(
                _fromToken,
                _toToken,
                _toAmount,
                _maxSpend
            );

            require(_fromToken.clearApprove(address(_converter)), "error clearing approve");
        }

        _spend = prevFromBalance.sub(_selfBalance(_fromToken));
        require(_spend <= _maxSpend, "_maxSpend exceeded");
        require(_selfBalance(_toToken).sub(prevToBalance) >= _toAmount, "_toAmount not received");
    }

    function _selfBalance(IERC20 _token) private view returns (uint256) {
        if (_token == ETH_TOKEN_ADDRESS) {
            return address(this).balance;
        } else {
            return _token.balanceOf(address(this));
        }
    }
}

// File: contracts/utils/Math.sol

pragma solidity ^0.6.6;


library Math {
    function min(uint256 _a, uint256 _b) internal pure returns (uint256) {
        if (_a < _b) {
            return _a;
        } else {
            return _b;
        }
    }

    function divCeil(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
        require(_b != 0, "div by zero");
        c = _a / _b;
        if (_a % _b != 0) {
            c = c + 1;
        }
    }
}

// File: contracts/ConverterRamp.sol

pragma solidity ^0.6.6;













/// @title  Converter Ramp
/// @notice for conversion between different assets, use ITokenConverter
///         contract as abstract layer for convert different assets.
/// @dev All function calls are currently implemented without side effects
contract ConverterRamp is Ownable {
    using SafeTokenConverter for ITokenConverter;
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using Math for uint256;

    /// @notice address to identify operations with ETH
    address public constant ETH_ADDRESS = address(0x00eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee);

    event Return(address _token, address _to, uint256 _amount);
    event ReadedOracle(address _oracle, uint256 _tokens, uint256 _equivalent);

    IDebtEngine public debtEngine;
    ILoanManager public loanManager;
    IERC20 public token;

    constructor(ILoanManager _loanManager) public {
        loanManager = _loanManager;
        token = _loanManager.token();
        debtEngine = _loanManager.debtEngine();
    }

    function pay(
        ITokenConverter _converter,
        IERC20 _fromToken,
        uint256 _payAmount,
        uint256 _maxSpend,
        bytes32 _requestId,
        bytes calldata _oracleData
    ) external payable {
        IDebtEngine _debtEngine = debtEngine;

        // Get amount required, in RCN, for payment
        uint256 amount = getRequiredRcnPay(
            _debtEngine,
            _requestId,
            _payAmount,
            _oracleData
        );

        // Pull funds from sender
        IERC20 _token = token;
        _pullConvertAndReturnExtra(
            _converter,
            _fromToken,
            _token,
            amount,
            _maxSpend
        );

        // Pay the loan the debtEngine is trusted so we can approve it only once
        _approveOnlyOnce(_token, address(_debtEngine), amount);

        // Execute the payment
        (, uint256 paidToken) = _debtEngine.payToken(_requestId, amount, msg.sender, _oracleData);

        // Convert any extra RCN and send it back it should not be reachable
        if (paidToken < amount) {
            _convertAndReturn(
                _converter,
                _token,
                _fromToken,
                amount - paidToken
            );
        }
    }

    function lend(
        ITokenConverter _converter,
        IERC20 _fromToken,
        uint256 _maxSpend,
        ICosigner _cosigner,
        uint256 _cosignerLimitCost,
        bytes32 _requestId,
        bytes memory _oracleData,
        bytes memory _cosignerData,
        bytes memory _callbackData
    ) public payable {
        ILoanManager _loanManager = loanManager;

        // Get required RCN for lending the loan
        uint256 amount = getRequiredRcnLend(
            _loanManager,
            _cosigner,
            _requestId,
            _oracleData,
            _cosignerData
        );

        IERC20 _token = token;
        _pullConvertAndReturnExtra(
            _converter,
            _fromToken,
            _token,
            amount,
            _maxSpend
        );

        // Approve token to loan manager only once the loan manager is trusted
        _approveOnlyOnce(_token, address(_loanManager), amount);

        _loanManager.lend(
            _requestId,
            _oracleData,
            address(_cosigner),
            _cosignerLimitCost,
            _cosignerData,
            _callbackData
        );

        // Transfer loan to the msg.sender
        debtEngine.transferFrom(address(this), msg.sender, uint256(_requestId));
    }

    function getLendCost(
        ITokenConverter _converter,
        IERC20 _fromToken,
        ICosigner _cosigner,
        bytes32 _requestId,
        bytes calldata _oracleData,
        bytes calldata _cosignerData
    ) external returns (uint256) {
        uint256 amountRcn = getRequiredRcnLend(
            loanManager,
            _cosigner,
            _requestId,
            _oracleData,
            _cosignerData
        );

        return _converter.getPriceConvertTo(
            _fromToken,
            token,
            amountRcn
        );
    }

    /// @notice returns how much RCN is required for a given pay
    function getPayCost(
        ITokenConverter _converter,
        IERC20 _fromToken,
        bytes32 _requestId,
        uint256 _amount,
        bytes calldata _oracleData
    ) external returns (uint256) {
        uint256 amountRcn = getRequiredRcnPay(
            debtEngine,
            _requestId,
            _amount,
            _oracleData
        );

        return _converter.getPriceConvertTo(
            _fromToken,
            token,
            amountRcn
        );
    }

    /// @notice returns how much RCN is required for a given lend
    function getRequiredRcnLend(
        ILoanManager _loanManager,
        ICosigner _lenderCosignerAddress,
        bytes32 _requestId,
        bytes memory _oracleData,
        bytes memory _cosignerData
    ) internal returns (uint256) {
        // Load request amount
        uint256 amount = loanManager.getAmount(_requestId);

        // If loan has a cosigner, sum the cost
        if (_lenderCosignerAddress != ICosigner(0)) {
            amount = amount.add(
                _lenderCosignerAddress.cost(
                    address(_loanManager),
                    uint256(_requestId),
                    _cosignerData,
                    _oracleData
                )
            );
        }

        // Load the  Oracle rate and convert required
        address oracle = loanManager.getOracle(uint256(_requestId));

        return getCurrencyToToken(oracle, amount, _oracleData);
    }

    /// @notice returns how much RCN is required for a given pay
    function getRequiredRcnPay(
        IDebtEngine _debtEngine,
        bytes32 _requestId,
        uint256 _amount,
        bytes memory _oracleData
    ) internal returns (uint256 _result) {
        (,,IModel model,, IRateOracle oracle) = _debtEngine.debts(_requestId);

        // Load amount to pay
        uint256 amount = Math.min(
            model.getClosingObligation(_requestId),
            _amount
        );

        // Read loan oracle
        return getCurrencyToToken(address(oracle), amount, _oracleData);
    }

    /// @notice returns how much tokens for _amount currency
    /// @dev tokens and equivalents get oracle data
    function getCurrencyToToken(
        address _oracle,
        uint256 _amount,
        bytes memory _oracleData
    ) internal returns (uint256) {
        if (_oracle == address(0)) {
            return _amount;
        }

        (uint256 tokens, uint256 equivalent) = IRateOracle(_oracle).readSample(_oracleData);

        emit ReadedOracle(_oracle, tokens, equivalent);
        return tokens.mul(_amount).divCeil(equivalent);
    }

    function getPriceConvertTo(
        ITokenConverter _converter,
        IERC20 _fromToken,
        uint256 _amount
    ) external view returns (uint256) {
        return _converter.getPriceConvertTo(
            _fromToken,
            token,
            _amount
        );
    }

    function _convertAndReturn(
        ITokenConverter _converter,
        IERC20 _fromToken,
        IERC20 _toToken,
        uint256 _amount
    ) private {
        uint256 buyBack = _converter.safeConvertFrom(
            _fromToken,
            _toToken,
            _amount,
            1
        );

        require(_toToken.safeTransfer(msg.sender, buyBack), "error sending extra");
    }

    function _pullConvertAndReturnExtra(
        ITokenConverter _converter,
        IERC20 _fromToken,
        IERC20 _toToken,
        uint256 _amount,
        uint256 _maxSpend
    ) private {
        // Pull limit amount from sender
        _pull(_fromToken, _maxSpend);

        uint256 spent = _converter.safeConvertTo(_fromToken, _toToken, _amount, _maxSpend);

        if (spent < _maxSpend) {
            _transfer(_fromToken, msg.sender, _maxSpend - spent);
        }
    }

    function _pull(
        IERC20 _token,
        uint256 _amount
    ) private {
        if (address(_token) == ETH_ADDRESS) {
            require(msg.value == _amount, "sent eth is not enought");
        } else {
            require(msg.value == 0, "method is not payable");
            require(_token.safeTransferFrom(msg.sender, address(this), _amount), "error pulling tokens");
        }
    }

    function _transfer(
        IERC20 _token,
        address payable _to,
        uint256 _amount
    ) private {
        if (address(_token) == ETH_ADDRESS) {
            _to.transfer(_amount);
        } else {
            require(_token.safeTransfer(_to, _amount), "error sending tokens");
        }
    }

    function _approveOnlyOnce(
        IERC20 _token,
        address _spender,
        uint256 _amount
    ) private {
        uint256 allowance = _token.allowance(address(this), _spender);
        if (allowance < _amount) {
            if (allowance != 0) {
                _token.clearApprove(_spender);
            }

            _token.approve(_spender, uint(-1));
        }
    }

    function emergencyWithdraw(
        IERC20 _token,
        address _to,
        uint256 _amount
    ) external onlyOwner {
        _token.transfer(_to, _amount);
    }

    receive() external payable {
        // solhint-disable-next-line
        require(tx.origin != msg.sender, "ramp: send eth rejected");
    }
}