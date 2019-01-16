pragma solidity ^0.5.0;


contract DebtEngine {
}


contract LoanManager {
    function debtEngine() external view returns (DebtEngine);
    
    function requestLoan(uint128 _amount, address _model, address _oracle, address _borrower, uint256 _salt, uint64 _expiration, bytes calldata _loanData) external returns (bytes32 id);
}


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


interface IERC721Base {
    function assetsOf(address _owner) external view returns (uint256[] memory);
    function totalSupply() external view returns (uint256);
    function tokenByIndex(uint256 _index) external view returns (uint256);
    function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256);
    function ownerOf(uint256 _assetId) external view returns (address);
    function balanceOf(address _owner) external view returns (uint256);
    function isApprovedForAll(address _operator, address _assetHolder) external view returns (bool);
    function isAuthorized(address _operator, uint256 _assetId) external view returns (bool);

    function setApprovalForAll(address _operator, bool _authorized) external;
    function approve(address _operator, uint256 _assetId) external;
    function safeTransferFrom(address _from, address _to, uint256 _assetId) external;
    function safeTransferFrom(address _from, address _to, uint256 _assetId, bytes calldata _userData) external;
    function transferFrom(address _from, address _to, uint256 _assetId) external;
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


contract BatchRequester is ERC165, LoanApprover{
    LoanManager public loanManager;
    uint256 public salt;

    uint128 public amount;
    address public model;
    address public oracle;
    uint64 public expiration;
    bytes public loanData;

    constructor() public {
        _registerInterface(0x76ba6009);
        _registerInterface(0xcd40239e);
        _registerInterface(0xbbfa4397);
    }

    function setLoanManager(LoanManager _loanManager) external {
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

    function requestBatchLoans(uint256 _length) public {
        for(; _length > 0;) {
            loanManager.requestLoan(
                amount,
                model,
                oracle,
                address(this),
                salt,
                expiration,
                loanData
            );
            salt++;
            _length -= _length;
        }
    }

    function approveRequest(bytes32 _futureDebt) external returns (bytes32) {
        return _futureDebt ^ 0xdfcb15a077f54a681c23131eacdfd6e12b5e099685b492d382c3fd8bfc1e9a2a;
    }

    function settleApproveRequest(bytes calldata, bytes calldata, bool, uint256) external returns (bytes32) { }
}