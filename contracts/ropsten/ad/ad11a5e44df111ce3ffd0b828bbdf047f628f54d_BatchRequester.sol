pragma solidity ^0.5.0;


interface ILoanManager {
    function requestLoan(uint128, address, address, address, uint256, uint64, bytes calldata) external returns (bytes32 id);
}


contract InstallmentsModel{
    function encodeData(uint128, uint256, uint24, uint40, uint32) external pure returns (bytes memory);
}


/**
 * @title ERC165
 * @author Matt Condon (@shrugs)
 * @dev Implements ERC165 using a lookup table.
 */
contract ERC165 {
    bytes4 private constant _InterfaceId_ERC165 = 0x01ffc9a7;
    /**
    * 0x01ffc9a7 ===
    *   bytes4(keccak256(&#39;supportsInterface(bytes4)&#39;))
    */

    /**
    * @dev a mapping of interface id to whether or not it&#39;s supported
    */
    mapping(bytes4 => bool) private _supportedInterfaces;

    /**
    * @dev A contract implementing SupportsInterfaceWithLookup
    * implement ERC165 itself
    */
    constructor()
        internal
    {
        _registerInterface(_InterfaceId_ERC165);
    }

    /**
    * @dev implement supportsInterface(bytes4) using a lookup table
    */
    function supportsInterface(bytes4 interfaceId)
        external
        view
        returns (bool)
    {
        return _supportedInterfaces[interfaceId];
    }

    /**
    * @dev internal method for registering an interface
    */
    function _registerInterface(bytes4 interfaceId)
        internal
    {
        require(interfaceId != 0xffffffff, "Can&#39;t register 0xffffffff");
        _supportedInterfaces[interfaceId] = true;
    }
}


/**
    A contract implementing LoanApprover is able to approve loan requests using callbacks,
    to approve a loan the contract should respond the callbacks the result of
    one designated value XOR keccak256("approve-loan-request")

    keccak256("approve-loan-request"): 0xdfcb15a077f54a681c23131eacdfd6e12b5e099685b492d382c3fd8bfc1e9a2a

    To receive calls on the callbacks, the contract should also implement the following ERC165 interfaces:

    approveRequest: 0x76ba6009
    settleApproveRequest: 0xcd40239e
    LoanApprover: 0xbbfa4397
*/
contract LoanApprover {
    /**
        Request the approve of a loan created using requestLoan, if the borrower is this contract,
        to approve the request the contract should return:

        _futureDebt XOR 0xdfcb15a077f54a681c23131eacdfd6e12b5e099685b492d382c3fd8bfc1e9a2a

        @param _futureDebt ID of the loan to approve

        @return _futureDebt XOR keccak256("approve-loan-request"), if the approve is accepted
    */
    function approveRequest(bytes32 _futureDebt) external returns (bytes32);

    /**
        Request the approve of a loan being settled, the contract can be called as borrower or creator.
        To approve the request the contract should return:

        _id XOR 0xdfcb15a077f54a681c23131eacdfd6e12b5e099685b492d382c3fd8bfc1e9a2a

        @param _requestData All the parameters of the loan request
        @param _loanData Data to feed to the Model
        @param _isBorrower True if this contract is the borrower, False if the contract is the creator
        @param _id loanManager.requestSignature(_requestDatam _loanData)

        @return _id XOR keccak256("approve-loan-request"), if the approve is accepted
    */
    function settleApproveRequest(
        bytes calldata _requestData,
        bytes calldata _loanData,
        bool _isBorrower,
        uint256 _id
    )
        external returns (bytes32);
}


contract BatchRequester is ERC165, LoanApprover {
    address public loanManager;
    uint256 public salt;

    uint128 public amount;
    address public model;
    address public oracle;
    uint64 public expiration;
    bytes public loanData;

    function setLoanManager(address _loanManager) external {
        loanManager = _loanManager;
    }

    function setAmount(uint128 _amount) external {
        amount = _amount;
    }

    function setModel(address _model) external {
        model = _model;
    }

    function setOracle(address _oracle) external {
        oracle = _oracle;
    }

    function setExpiration(uint64 _expiration) external {
        expiration = _expiration;
    }

    function setLoanData(bytes calldata _loanData) external {
        loanData = _loanData;
    }

    function setInstallmentsLoanData(uint128 _cuota, uint256 _interestRate, uint24 _installments, uint40 _duration, uint32 _timeUnit) external {
        loanData = InstallmentsModel(model).encodeData(
            _cuota,
            _interestRate,
            _installments,
            _duration,
            _timeUnit
        );
    }

    function requestBatchLoans(uint256 _length) public {
        for(; _length > 0;) {
            ILoanManager(loanManager).requestLoan(
                amount,
                model,
                oracle,
                address(this),
                salt,
                expiration,
                loanData
            );
            salt++;
            _length--;
        }
    }

    function approveRequest(bytes32 _futureDebt) external returns (bytes32) {
        return _futureDebt ^ 0xdfcb15a077f54a681c23131eacdfd6e12b5e099685b492d382c3fd8bfc1e9a2a;
    }

    function settleApproveRequest(bytes calldata, bytes calldata, bool, uint256) external returns (bytes32) { }
}