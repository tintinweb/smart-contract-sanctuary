pragma solidity ^0.4.24;

// File: contracts/interfaces/Token.sol

contract Token {
    function transfer(address _to, uint _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function allowance(address _owner, address _spender) public view returns (uint256 remaining);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function increaseApproval (address _spender, uint _addedValue) public returns (bool success);
    function balanceOf(address _owner) public view returns (uint256 balance);
}

// File: contracts/utils/Ownable.sol

contract Ownable {
    address public owner;

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function Ownable() public {
        owner = msg.sender; 
    }

    /**
        @dev Transfers the ownership of the contract.

        @param _to Address of the new owner
    */
    function transferTo(address _to) public onlyOwner returns (bool) {
        require(_to != address(0));
        owner = _to;
        return true;
    } 
}

// File: contracts/interfaces/Oracle.sol

/**
    @dev Defines the interface of a standard RCN oracle.

    The oracle is an agent in the RCN network that supplies a convertion rate between RCN and any other currency,
    it&#39;s primarily used by the exchange but could be used by any other agent.
*/
contract Oracle is Ownable {
    uint256 public constant VERSION = 4;

    event NewSymbol(bytes32 _currency);

    mapping(bytes32 => bool) public supported;
    bytes32[] public currencies;

    /**
        @dev Returns the url where the oracle exposes a valid "oracleData" if needed
    */
    function url() public view returns (string);

    /**
        @dev Returns a valid convertion rate from the currency given to RCN

        @param symbol Symbol of the currency
        @param data Generic data field, could be used for off-chain signing
    */
    function getRate(bytes32 symbol, bytes data) public returns (uint256 rate, uint256 decimals);

    /**
        @dev Adds a currency to the oracle, once added it cannot be removed

        @param ticker Symbol of the currency

        @return if the creation was done successfully
    */
    function addCurrency(string ticker) public onlyOwner returns (bool) {
        bytes32 currency = encodeCurrency(ticker);
        NewSymbol(currency);
        supported[currency] = true;
        currencies.push(currency);
        return true;
    }

    /**
        @return the currency encoded as a bytes32
    */
    function encodeCurrency(string currency) public pure returns (bytes32 o) {
        require(bytes(currency).length <= 32);
        assembly {
            o := mload(add(currency, 32))
        }
    }
    
    /**
        @return the currency string from a encoded bytes32
    */
    function decodeCurrency(bytes32 b) public pure returns (string o) {
        uint256 ns = 256;
        while (true) { if (ns == 0 || (b<<ns-8) != 0) break; ns -= 8; }
        assembly {
            ns := div(ns, 8)
            o := mload(0x40)
            mstore(0x40, add(o, and(add(add(ns, 0x20), 0x1f), not(0x1f))))
            mstore(o, ns)
            mstore(add(o, 32), b)
        }
    }
    
}

// File: contracts/basalt/interfaces/Engine.sol

contract Engine {
    uint256 public VERSION;
    string public VERSION_NAME;

    enum Status { initial, lent, paid, destroyed }
    struct Approbation {
        bool approved;
        bytes data;
        bytes32 checksum;
    }

    function getTotalLoans() public view returns (uint256);
    function getOracle(uint index) public view returns (Oracle);
    function getBorrower(uint index) public view returns (address);
    function getCosigner(uint index) public view returns (address);
    function ownerOf(uint256) public view returns (address owner);
    function getCreator(uint index) public view returns (address);
    function getAmount(uint index) public view returns (uint256);
    function getPaid(uint index) public view returns (uint256);
    function getDueTime(uint index) public view returns (uint256);
    function getApprobation(uint index, address _address) public view returns (bool);
    function getStatus(uint index) public view returns (Status);
    function isApproved(uint index) public view returns (bool);
    function getPendingAmount(uint index) public returns (uint256);
    function getCurrency(uint index) public view returns (bytes32);
    function cosign(uint index, uint256 cost) external returns (bool);
    function approveLoan(uint index) public returns (bool);
    function transfer(address to, uint256 index) public returns (bool);
    function takeOwnership(uint256 index) public returns (bool);
    function withdrawal(uint index, address to, uint256 amount) public returns (bool);
}

// File: contracts/interfaces/Cosigner.sol

/**
    @dev Defines the interface of a standard RCN cosigner.

    The cosigner is an agent that gives an insurance to the lender in the event of a defaulted loan, the confitions
    of the insurance and the cost of the given are defined by the cosigner.

    The lender will decide what cosigner to use, if any; the address of the cosigner and the valid data provided by the
    agent should be passed as params when the lender calls the "lend" method on the engine.

    When the default conditions defined by the cosigner aligns with the status of the loan, the lender of the engine
    should be able to call the "claim" method to receive the benefit; the cosigner can define aditional requirements to
    call this method, like the transfer of the ownership of the loan.
*/
contract Cosigner {
    uint256 public constant VERSION = 2;

    /**
        @return the url of the endpoint that exposes the insurance offers.
    */
    function url() public view returns (string);

    /**
        @dev Retrieves the cost of a given insurance, this amount should be exact.

        @return the cost of the cosign, in RCN wei
    */
    function cost(address engine, uint256 index, bytes data, bytes oracleData) public view returns (uint256);

    /**
        @dev The engine calls this method for confirmation of the conditions, if the cosigner accepts the liability of
        the insurance it must call the method "cosign" of the engine. If the cosigner does not call that method, or
        does not return true to this method, the operation fails.

        @return true if the cosigner accepts the liability
    */
    function requestCosign(Engine engine, uint256 index, bytes data, bytes oracleData) public returns (bool);

    /**
        @dev Claims the benefit of the insurance if the loan is defaulted, this method should be only calleable by the
        current lender of the loan.

        @return true if the claim was done correctly.
    */
    function claim(address engine, uint256 index, bytes oracleData) public returns (bool);
}

// File: contracts/utils/SafeMath.sol

library SafeMath {
    function add(uint256 x, uint256 y) internal pure returns (uint256) {
        uint256 z = x + y;
        require((z >= x) && (z >= y), "Add overflow");
        return z;
    }

    function sub(uint256 x, uint256 y) internal pure returns (uint256) {
        require(x >= y, "Sub underflow");
        uint256 z = x - y;
        return z;
    }

    function mult(uint256 x, uint256 y) internal pure returns (uint256) {
        uint256 z = x * y;
        require((x == 0)||(z/x == y), "Mult overflow");
        return z;
    }
}

// File: contracts/utils/ERC721Base.sol

contract ERC721Base {
    using SafeMath for uint256;

    uint256 private _count;

    mapping(uint256 => address) private _holderOf;
    mapping(address => uint256[]) private _assetsOf;
    mapping(address => mapping(address => bool)) private _operators;
    mapping(uint256 => address) private _approval;
    mapping(uint256 => uint256) private _indexOfAsset;

    bytes4 private constant ERC721_RECEIVED = 0x150b7a02;
    bytes4 private constant ERC721_RECEIVED_LEGACY = 0xf0b9e5ba;

    event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    //
    // Global Getters
    //

    /**
     * @dev Gets the total amount of assets stored by the contract
     * @return uint256 representing the total amount of assets
     */
    function totalSupply() external view returns (uint256) {
        return _totalSupply();
    }
    function _totalSupply() internal view returns (uint256) {
        return _count;
    }

    //
    // Asset-centric getter functions
    //

    /**
     * @dev Queries what address owns an asset. This method does not throw.
     * In order to check if the asset exists, use the `exists` function or check if the
     * return value of this call is `0`.
     * @return uint256 the assetId
     */
    function ownerOf(uint256 assetId) external view returns (address) {
        return _ownerOf(assetId);
    }
    function _ownerOf(uint256 assetId) internal view returns (address) {
        return _holderOf[assetId];
    }

    //
    // Holder-centric getter functions
    //
    /**
     * @dev Gets the balance of the specified address
     * @param owner address to query the balance of
     * @return uint256 representing the amount owned by the passed address
     */
    function balanceOf(address owner) external view returns (uint256) {
        return _balanceOf(owner);
    }
    function _balanceOf(address owner) internal view returns (uint256) {
        return _assetsOf[owner].length;
    }

    //
    // Authorization getters
    //

    /**
     * @dev Query whether an address has been authorized to move any assets on behalf of someone else
     * @param operator the address that might be authorized
     * @param assetHolder the address that provided the authorization
     * @return bool true if the operator has been authorized to move any assets
     */
    function isApprovedForAll(address operator, address assetHolder)
        external view returns (bool)
    {
        return _isApprovedForAll(operator, assetHolder);
    }
    function _isApprovedForAll(address operator, address assetHolder)
        internal view returns (bool)
    {
        return _operators[assetHolder][operator];
    }

    /**
     * @dev Query what address has been particularly authorized to move an asset
     * @param assetId the asset to be queried for
     * @return bool true if the asset has been approved by the holder
     */
    function getApprovedAddress(uint256 assetId) external view returns (address) {
        return _getApprovedAddress(assetId);
    }
    function _getApprovedAddress(uint256 assetId) internal view returns (address) {
        return _approval[assetId];
    }

    /**
     * @dev Query if an operator can move an asset.
     * @param operator the address that might be authorized
     * @param assetId the asset that has been `approved` for transfer
     * @return bool true if the asset has been approved by the holder
     */
    function isAuthorized(address operator, uint256 assetId) external view returns (bool) {
        return _isAuthorized(operator, assetId);
    }
    function _isAuthorized(address operator, uint256 assetId) internal view returns (bool)
    {
        require(operator != 0);
        address owner = _ownerOf(assetId);
        if (operator == owner) {
            return true;
        }
        return _isApprovedForAll(operator, owner) || _getApprovedAddress(assetId) == operator;
    }

    //
    // Authorization
    //

    /**
     * @dev Authorize a third party operator to manage (send) msg.sender&#39;s asset
     * @param operator address to be approved
     * @param authorized bool set to true to authorize, false to withdraw authorization
     */
    function setApprovalForAll(address operator, bool authorized) external {
        return _setApprovalForAll(operator, authorized);
    }
    function _setApprovalForAll(address operator, bool authorized) internal {
        if (authorized) {
            require(!_isApprovedForAll(operator, msg.sender));
            _addAuthorization(operator, msg.sender);
        } else {
            require(_isApprovedForAll(operator, msg.sender));
            _clearAuthorization(operator, msg.sender);
        }
        emit ApprovalForAll(operator, msg.sender, authorized);
    }

    /**
     * @dev Authorize a third party operator to manage one particular asset
     * @param operator address to be approved
     * @param assetId asset to approve
     */
    function approve(address operator, uint256 assetId) external {
        address holder = _ownerOf(assetId);
        require(msg.sender == holder || _isApprovedForAll(msg.sender, holder));
        require(operator != holder);
        if (_getApprovedAddress(assetId) != operator) {
            _approval[assetId] = operator;
            emit Approval(holder, operator, assetId);
        }
    }

    function _addAuthorization(address operator, address holder) private {
        _operators[holder][operator] = true;
    }

    function _clearAuthorization(address operator, address holder) private {
        _operators[holder][operator] = false;
    }

    //
    // Internal Operations
    //

    function _addAssetTo(address to, uint256 assetId) internal {
        _holderOf[assetId] = to;

        uint256 length = _balanceOf(to);

        _assetsOf[to].push(assetId);

        _indexOfAsset[assetId] = length;

        _count = _count.add(1);
    }

    function _removeAssetFrom(address from, uint256 assetId) internal {
        uint256 assetIndex = _indexOfAsset[assetId];
        uint256 lastAssetIndex = _balanceOf(from).sub(1);
        uint256 lastAssetId = _assetsOf[from][lastAssetIndex];

        _holderOf[assetId] = 0;

        // Insert the last asset into the position previously occupied by the asset to be removed
        _assetsOf[from][assetIndex] = lastAssetId;

        // Resize the array
        _assetsOf[from][lastAssetIndex] = 0;
        _assetsOf[from].length--;

        // Remove the array if no more assets are owned to prevent pollution
        if (_assetsOf[from].length == 0) {
            delete _assetsOf[from];
        }

        // Update the index of positions for the asset
        _indexOfAsset[assetId] = 0;
        _indexOfAsset[lastAssetId] = assetIndex;

        _count = _count.sub(1);
    }

    function _clearApproval(address holder, uint256 assetId) internal {
        if (_ownerOf(assetId) == holder && _approval[assetId] != 0) {
            _approval[assetId] = 0;
            emit Approval(holder, 0, assetId);
        }
    }

    //
    // Supply-altering functions
    //

    function _generate(uint256 assetId, address beneficiary) internal {
        require(_holderOf[assetId] == 0, "Asset already exists");

        _addAssetTo(beneficiary, assetId);

        emit Transfer(0x0, beneficiary, assetId);
    }

    function _destroy(uint256 assetId) internal {
        address holder = _holderOf[assetId];
        require(holder != 0);

        _removeAssetFrom(holder, assetId);

        emit Transfer(holder, 0x0, assetId);
    }

    //
    // Transaction related operations
    //

    modifier onlyHolder(uint256 assetId) {
        require(_ownerOf(assetId) == msg.sender);
        _;
    }

    modifier onlyAuthorized(uint256 assetId) {
        require(_isAuthorized(msg.sender, assetId));
        _;
    }

    modifier isCurrentOwner(address from, uint256 assetId) {
        require(_ownerOf(assetId) == from);
        _;
    }

    /**
     * @dev Alias of `safeTransferFrom(from, to, assetId, &#39;&#39;)`
     *
     * @param from address that currently owns an asset
     * @param to address to receive the ownership of the asset
     * @param assetId uint256 ID of the asset to be transferred
     */
    function safeTransferFrom(address from, address to, uint256 assetId) external {
        return _doTransferFrom(from, to, assetId, "", true);
    }

    /**
     * @dev Securely transfers the ownership of a given asset from one address to
     * another address, calling the method `onNFTReceived` on the target address if
     * there&#39;s code associated with it
     *
     * @param from address that currently owns an asset
     * @param to address to receive the ownership of the asset
     * @param assetId uint256 ID of the asset to be transferred
     * @param userData bytes arbitrary user information to attach to this transfer
     */
    function safeTransferFrom(address from, address to, uint256 assetId, bytes userData) external {
        return _doTransferFrom(from, to, assetId, userData, true);
    }

    /**
     * @dev Transfers the ownership of a given asset from one address to another address
     * Warning! This function does not attempt to verify that the target address can send
     * tokens.
     *
     * @param from address sending the asset
     * @param to address to receive the ownership of the asset
     * @param assetId uint256 ID of the asset to be transferred
     */
    function transferFrom(address from, address to, uint256 assetId) external {
        return _doTransferFrom(from, to, assetId, "", false);
    }

    function _doTransferFrom(
        address from,
        address to,
        uint256 assetId,
        bytes userData,
        bool doCheck
    )
        onlyAuthorized(assetId)
        internal
    {
        _moveToken(from, to, assetId, userData, doCheck);
    }

    function _moveToken(
        address from,
        address to,
        uint256 assetId,
        bytes userData,
        bool doCheck
    )
        internal
        isCurrentOwner(from, assetId)
    {
        address holder = _holderOf[assetId];
        _removeAssetFrom(holder, assetId);
        _clearApproval(holder, assetId);
        _addAssetTo(to, assetId);

        if (doCheck && _isContract(to)) {
            // Call dest contract
            uint256 success;
            bytes32 result;
            // Perform check with the new safe call
            // onERC721Received(address,address,uint256,bytes)
            (success, result) = _noThrowCall(
                to,
                abi.encodeWithSelector(
                    ERC721_RECEIVED,
                    msg.sender,
                    holder,
                    assetId,
                    userData
                )
            );

            if (success != 1 || result != ERC721_RECEIVED) {
                // Try legacy safe call
                // onERC721Received(address,uint256,bytes)
                (success, result) = _noThrowCall(
                    to,
                    abi.encodeWithSelector(
                        ERC721_RECEIVED_LEGACY,
                        holder,
                        assetId,
                        userData
                    )
                );

                require(success == 1 && result == ERC721_RECEIVED_LEGACY);
            }
        }

        emit Transfer(holder, to, assetId);
    }

    /**
     * Internal function that moves an asset from one holder to another
     */

    /**
     * @dev Returns `true` if the contract implements `interfaceID` and `interfaceID` is not 0xffffffff, `false` otherwise
     * @param    _interfaceID The interface identifier, as specified in ERC-165
     */
    function supportsInterface(bytes4 _interfaceID) external view returns (bool) {

        if (_interfaceID == 0xffffffff) {
            return false;
        }
        return _interfaceID == 0x01ffc9a7 || _interfaceID == 0x80ac58cd;
    }

    //
    // Utilities
    //

    function _isContract(address addr) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }

    function _noThrowCall(
        address _contract,
        bytes _data
    ) internal returns (uint256 success, bytes32 result) {
        assembly {
            let x := mload(0x40)

            success := call(
                            gas,                  // Send all gas
                            _contract,            // To addr
                            0,                    // Send ETH
                            add(0x20, _data),     // Input is data past the first 32 bytes
                            mload(_data),         // Input size is the lenght of data
                            x,                    // Store the ouput on x
                            0x20                  // Output is a single bytes32, has 32 bytes
                        )

            result := mload(x)
        }
    }
}

// File: contracts/interfaces/ERC165.sol

interface ERC165 {
    /// @notice Query if a contract implements an interface
    /// @param interfaceID The interface identifier, as specified in ERC-165
    /// @dev Interface identification is specified in ERC-165. This function
    ///  uses less than 30,000 gas.
    /// @return `true` if the contract implements `interfaceID` and
    ///  `interfaceID` is not 0xffffffff, `false` otherwise
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}

// File: contracts/diaspore/interfaces/Model.sol

/**
    The abstract contract Model defines the whole lifecycle of a debt on the DebtEngine.

    Models can be used without previous approbation, this is meant
    to avoid centralization on the development of RCN; this implies that not all models are secure.
    Models can have back-doors, bugs and they have not guarantee of being autonomous.

    The DebtEngine is meant to be the User of this model,
    so all the methods with the ability to perform state changes should only be callable by the DebtEngine.

    @author Agustin Aguilar
*/
contract Model is ERC165 {
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

    // Model interface selector
    bytes4 internal debtModelInterface =
    this.isOperator.selector
    ^ this.validate.selector
    ^ this.getStatus.selector
    ^ this.getPaid.selector
    ^ this.getObligation.selector
    ^ this.getClosingObligation.selector
    ^ this.getDueTime.selector
    ^ this.getFinalTime.selector
    ^ this.getFrequency.selector
    ^ this.getEstimateObligation.selector
    ^ this.create.selector
    ^ this.addPaid.selector
    ^ this.addDebt.selector
    ^ this.run.selector;

    uint256 public constant STATUS_ONGOING = 1;
    uint256 public constant STATUS_PAID = 2;
    uint256 public constant STATUS_ERROR = 4;

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

        @return True if operator is able to modify the state of the model
    */
    function isOperator(address operator) external view returns (bool canOperate);

    /**
        Validates the data for the creation of a new registry, if returns True the
            same data should be compatible with the create method.

        @dev This method can revert the call or return false, and both meant an invalid data.

        @param data Data to validate

        @return True if the data can be used to create a new registry
    */
    function validate(bytes data) external view returns (bool isValid);

    // ///
    // Getters
    // ///

    /**
        Exposes the current status of the registry. The possible values are:

        1: Ongoing - The debt is still ongoing and waiting to be paid
        2: Paid - The debt is already paid and
        5: Error - There was an Error with the registry

        @dev This method should always be called by the DebtEngine

        @param id Id of the registry

        @return The current status value
    */
    function getStatus(bytes32 id) external view returns (uint256 status);

    /**
        Returns the total paid amount on the registry.

        @dev it should equal to the sum of all real addPaid

        @param id Id of the registry

        @return Total paid amount
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
        @return defined True If the amount returned is fixed and can&#39;t change
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

        This is the estimated final payment date of the debt if it&#39;s always paid on each exact dueTime.

        @param id Id of the registry

        @return timestamp Timestamp of the final due time
    */
    function getFinalTime(bytes32 id) external view returns (uint256 timestamp);

    /**
        Similar to getFinalTime returns the expected payment remaining if paid always on the exact dueTime.

        If the model has no interest discounts for early payments,
            this method should return the same value as getClosignObligation.

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
    function create(bytes32 id, bytes data) external returns (bool success);

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
            multiple calls to run shouldn&#39;t affect the internal calculations of the model.

        @dev If the call had no effect the method would return False,
            that is no sign of things going wrong, and the call shouldn&#39;t be wrapped on a require

        @param id If of the registry

        @return effect True if the run performed a change on the state
    */
    function run(bytes32 id) external returns (bool effect);
}

// File: contracts/diaspore/DebtEngine.sol

interface IOracle {
    function getRate(bytes32 symbol, bytes data) external returns (uint256 rate, uint256 decimals);
}

contract DebtEngine is ERC721Base {
    event Created(bytes32 indexed _id, uint256 _nonce, bytes _data);
    event Created2(bytes32 indexed _id, uint256 _nonce, bytes _data);
    event Paid(bytes32 indexed _id, address _sender, address _origin, uint256 _requested, uint256 _requestedTokens, uint256 _paid, uint256 _tokens);
    event ReadedOracle(bytes32 indexed _id, uint256 _amount, uint256 _decimals);
    event Withdrawn(bytes32 indexed _id, address _sender, address _to, uint256 _amount);
    event Error(bytes32 indexed _id, address _sender, uint256 _value, uint256 _gasLeft, uint256 _gasLimit, bytes _callData);

    Token public token;

    mapping(bytes32 => Debt) public debts;
    mapping(address => uint256) public nonces;

    struct Debt {
        bool error;
        bytes8 currency;
        uint128 balance;
        Model model;
        address creator;
        address oracle;
    }

    constructor(Token _token) public {
        token = _token;
    }

    function name() external pure returns (string _name) {
        _name = "RCN Debt Record";
    }

    function symbol() external pure returns (string _symbol) {
        _symbol = "RDR";
    }

    function create(
        Model _model,
        address _owner,
        address _oracle,
        bytes8 _currency,
        bytes _data
    ) external returns (bytes32 id) {
        uint256 nonce = nonces[msg.sender]++;
        id = _buildId(msg.sender, nonce, false);

        debts[id] = Debt({
            error: false,
            currency: _currency,
            balance: 0,
            creator: msg.sender,
            model: _model,
            oracle: _oracle
        });

        _generate(uint256(id), _owner);
        require(_model.create(id, _data), "Error creating debt in model");

        emit Created({
            _id: id,
            _nonce: nonce,
            _data: _data
        });
    }

    function create2(
        Model _model,
        address _owner,
        address _oracle,
        bytes8 _currency,
        uint256 _nonce,
        bytes _data
    ) external returns (bytes32 id) {
        id = _buildId(msg.sender, _nonce, true);

        debts[id] = Debt({
            error: false,
            currency: _currency,
            balance: 0,
            creator: msg.sender,
            model: _model,
            oracle: _oracle
        });

        _generate(uint256(id), _owner);
        require(_model.create(id, _data), "Error creating debt in model");

        emit Created2({
            _id: id,
            _nonce: _nonce,
            _data: _data
        });
    }

    function buildId(
        address _creator,
        uint256 _nonce,
        bool _method2
    ) external pure returns (bytes32) {
        return keccak256(abi.encodePacked(_creator, _nonce, _method2));
    }

    function _buildId(
        address _creator,
        uint256 _nonce,
        bool _method2
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_creator, _nonce, _method2));
    }

    function pay(
        bytes32 _id,
        uint256 _amount,
        address _origin,
        bytes _oracleData
    ) external returns (uint256 paid, uint256 paidToken) {
        Debt storage debt = debts[_id];
        if (debt.error) delete debt.error;

        // Paid only required amount
        paid = _safePay(_id, debt.model, _amount);
        require(paid <= _amount, "Paid can&#39;t be more than requested");

        IOracle oracle = IOracle(debt.oracle);
        if (oracle != address(0)) {
            // Convert
            (uint256 rate, uint256 decimals) = oracle.getRate(debt.currency, _oracleData);
            emit ReadedOracle(_id, rate, decimals);
            paidToken = toToken(paid, rate, decimals);
        } else {
            paidToken = paid;
        }

        // Pull tokens from payer
        require(token.transferFrom(msg.sender, address(this), paidToken), "Error pulling payment tokens");

        // Add balance to the debt
        uint256 newBalance = paidToken.add(debt.balance);
        require(newBalance < 340282366920938463463374607431768211456, "uint128 Overflow");
        debt.balance = uint128(newBalance);

        // Emit pay event
        emit Paid({
            _id: _id,
            _sender: msg.sender,
            _origin: _origin,
            _requested: _amount,
            _requestedTokens: 0,
            _paid: paid,
            _tokens: paidToken
        });
    }
    
    function payToken(
        bytes32 id,
        uint256 amount,
        address origin,
        bytes oracleData
    ) external returns (uint256 paid, uint256 paidToken) {
        Debt storage debt = debts[id];
        if (debt.error) delete debt.error;

        // Read storage
        IOracle oracle = IOracle(debt.oracle);

        uint256 rate;
        uint256 decimals;
        uint256 available;

        // Get available <currency> amount
        if (oracle != address(0)) {
            (rate, decimals) = oracle.getRate(debt.currency, oracleData);
            emit ReadedOracle(id, rate, decimals);
            available = fromToken(amount, rate, decimals);
        } else {
            available = amount;
        }

        // Call addPaid on model
        paid = _safePay(id, debt.model, available);
        require(paid <= available, "Paid can&#39;t exceed available");

        // Convert back to required pull amount
        if (oracle != address(0)) {
            paidToken = toToken(paid, rate, decimals);
            require(paidToken <= amount, "Paid can&#39;t exceed requested");
        } else {
            paidToken = paid;
        }

        // Pull tokens from payer
        require(token.transferFrom(msg.sender, address(this), paidToken), "Error pulling tokens");

        // Add balance to the debt
        // WARNING: Reusing variable **available**
        available = paidToken.add(debt.balance);
        require(available < 340282366920938463463374607431768211456, "uint128 Overflow");
        debt.balance = uint128(available);

        // Emit pay event
        emit Paid({
            _id: id,
            _sender: msg.sender,
            _origin: origin,
            _requested: 0,
            _requestedTokens: amount,
            _paid: paid,
            _tokens: paidToken
        });
    }

    function _safePay(
        bytes32 _id,
        Model _model,
        uint256 _available
    ) internal returns (uint256) {
        (uint256 success, bytes32 paid) = _safeGasCall(
            _model,
            abi.encodeWithSelector(
                _model.addPaid.selector,
                _id,
                _available
            )
        );

        if (success != 0) {
            return uint256(paid);
        } else {
            emit Error({
                _id: _id,
                _sender: msg.sender,
                _value: msg.value,
                _gasLeft: gasleft(),
                _gasLimit: block.gaslimit,
                _callData: msg.data
            });
            debts[_id].error = true;
        }
    }

    /**
        Converts an amount in the rate currency to an amount in token

        @param _amount Amount to convert in rate currency
        @param _rate Rate to use in the convertion
        @param _decimals Base difference between rate and tokens

        @return Amount in tokens
    */
    function toToken(uint256 _amount, uint256 _rate, uint256 _decimals) internal pure returns (uint256) {
        require(_decimals <= 18, "Decimals limit reached");
        return _rate.mult(_amount).mult((10 ** (18 - _decimals))) / 1000000000000000000;
    }

    /**
        Converts an amount in token to the rate currency

        @param _amount Amount to convert in token
        @param _rate Rate to use in the convertion
        @param _decimals Base difference between rate and tokens

        @return Amount in rate currency
    */
    function fromToken(uint256 _amount, uint256 _rate, uint256 _decimals) internal pure returns (uint256) {
        require(_decimals <= 18, "Decimals limit reached");
        return (_amount.mult(1000000000000000000) / _rate) / 10 ** (18 - _decimals);
    }

    function run(bytes32 _id) external returns (bool) {
        Debt storage debt = debts[_id];
        if (debt.error) delete debt.error;

        (uint256 success, bytes32 result) = _safeGasCall(
            debt.model,
            abi.encodeWithSelector(
                debt.model.run.selector,
                _id
            )
        );

        if (success != 0) {
            return result == bytes32(1);
        } else {
            emit Error({
                _id: _id,
                _sender: msg.sender,
                _value: 0,
                _gasLeft: gasleft(),
                _gasLimit: block.gaslimit,
                _callData: msg.data
            });
            debt.error = true;
        }
    }

    function withdrawal(bytes32 _id, address _to) external returns (uint256 amount) {
        require(_isAuthorized(msg.sender, uint256(_id)), "Sender not authorized");
        Debt storage debt = debts[_id];
        amount = debt.balance;
        debt.balance = 0;
        require(token.transfer(_to, amount), "Error sending tokens");
        emit Withdrawn({
            _id: _id,
            _sender: msg.sender,
            _to: _to,
            _amount: amount
        });
    }

    function withdrawalList(bytes32[] _ids, address _to) external returns (uint256 amount) {
        bytes32 target;
        uint256 balance;
        for (uint256 i = 0; i < _ids.length; i++) {
            target = _ids[i];
            if(_isAuthorized(msg.sender, uint256(target))) {
                balance = debts[target].balance;
                debts[target].balance = 0;
                amount += balance;
                emit Withdrawn({
                    _id: target,
                    _sender: msg.sender,
                    _to: _to,
                    _amount: balance
                });
            }
        }
        require(token.transfer(_to, amount), "Error sending tokens");
    }

    function getStatus(bytes32 _id) external view returns (uint256) {
        Debt storage debt = debts[_id];
        if (debt.error) {
            return 4;
        } else {
            (uint256 success, bytes32 result) = _safeGasStaticCall(
                debt.model,
                abi.encodeWithSelector(
                    debt.model.getStatus.selector,
                    _id
                )
            );
            return success == 1 ? uint256(result) : 4;
        }
    }

    function _safeGasStaticCall(
        address _contract,
        bytes _data
    ) internal view returns (uint256 success, bytes32 result) {
        uint256 _gas = (block.gaslimit * 80) / 100;
        _gas = gasleft() < _gas ? gasleft() : _gas;
        assembly {
            let x := mload(0x40)
            success := staticcall(
                            _gas,                 // Send almost all gas
                            _contract,            // To addr
                            add(0x20, _data),     // Input is data past the first 32 bytes
                            mload(_data),         // Input size is the lenght of data
                            x,                    // Store the ouput on x
                            0x20                  // Output is a single bytes32, has 32 bytes
                        )

            result := mload(x)
        }
    }

    function _safeGasCall(
        address _contract,
        bytes _data
    ) internal returns (uint256 success, bytes32 result) {
        uint256 _gas = (block.gaslimit * 80) / 100;
        _gas = gasleft() < _gas ? gasleft() : _gas;
        assembly {
            let x := mload(0x40)
            success := call(
                            _gas,                 // Send almost all gas
                            _contract,            // To addr
                            0,                    // Send ETH
                            add(0x20, _data),     // Input is data past the first 32 bytes
                            mload(_data),         // Input size is the lenght of data
                            x,                    // Store the ouput on x
                            0x20                  // Output is a single bytes32, has 32 bytes
                        )

            result := mload(x)
        }
    }
}

// File: contracts/diaspore/interfaces/LoanRequester.sol

interface LoanRequester {
    function loanRequested(bytes32[8] requestData, bytes loanData, bool isBorrower, uint256 returnFlag) external returns (uint256);
}

// File: contracts/diaspore/LoanManager.sol

contract LoanManager {
    DebtEngine public debtEngine;
    Token public token;

    bytes32[] public directory;
    mapping(bytes32 => Request) public requests;
    mapping(bytes32 => bool) public canceledSettles;

    event Requested(bytes32 indexed _id, uint256 _nonce);
    event Approved(bytes32 indexed _id);
    event Lent(bytes32 indexed _id, address _lender, uint256 _tokens);
    event Cosigned(bytes32 indexed _id, address _cosigner, uint256 _cost);
    event Canceled(bytes32 indexed _id, address _canceler);
    event ReadedOracle(bytes32 indexed _id, uint256 _amount, uint256 _decimals);

    event SettledLend(bytes32 indexed _id, bytes32 _sig, address _lender, uint256 _tokens);
    event SettledCancel(bytes32 _sig, address _canceler);

    constructor(DebtEngine _debtEngine) public {
        debtEngine = _debtEngine;
        token = debtEngine.token();
        require(token != address(0), "Error loading token");
    }
    
    function getDirectory() external view returns (bytes32[]) { return directory; }

    function getDirectoryLength() external view returns (uint256) { return directory.length; }

    function getBorrower(uint256 id) external view returns (address) { 
        return requests[bytes32(id)].borrower;
    }

    function getCreator(uint256 id) external view returns (address) { return requests[bytes32(id)].creator; }
    function getOracle(uint256 id) external view returns (address) { return requests[bytes32(id)].oracle; }
    function getCosigner(uint256 id) external view returns (address) { return requests[bytes32(id)].cosigner; }
    function getCurrency(uint256 id) external view returns (bytes32) { return requests[bytes32(id)].currency; }
    function getAmount(uint256 id) external view returns (uint256) { return requests[bytes32(id)].amount; }

    function getExpirationRequest(uint256 id) external view returns (uint256) { return requests[bytes32(id)].expiration; }
    function getApproved(uint256 id) external view returns (bool) { return requests[bytes32(id)].approved; }
    function getDueTime(uint256 id) external view returns (uint256) { return Model(requests[bytes32(id)].model).getDueTime(bytes32(id)); }
    function getLoanData(uint256 id) external view returns (bytes) { return requests[bytes32(id)].loanData; }

    function getStatus(uint256 id) external view returns (uint256) {
        Request storage request = requests[bytes32(id)];
        return request.open ? 0 : Model(request.model).getStatus(bytes32(id));
    }

    struct Request {
        bool open;
        bool approved;
        bytes8 currency;
        uint64 position;
        uint64 expiration;
        uint128 amount;
        address cosigner;
        address model;
        address creator;
        address oracle;
        address borrower;
        uint256 nonce;
        bytes loanData;
    }

    function calcFutureDebt(
        address creator,
        uint256 nonce
    ) external view returns (bytes32) {
        return debtEngine.buildId(
            address(this),
            uint256(keccak256(abi.encodePacked(creator, nonce))),
            true
        );
    }

    function requestLoan(
        bytes8 currency,
        uint128 amount,
        address model,
        address oracle,
        address borrower,
        uint256 nonce,
        uint64 expiration,
        bytes loanData
    ) external returns (bytes32 futureDebt) {
        require(borrower != address(0), "The request should have a borrower");
        require(Model(model).validate(loanData), "The loan data is not valid");

        uint256 internalNonce = uint256(keccak256(abi.encodePacked(msg.sender, nonce)));
        futureDebt = debtEngine.buildId(
            address(this),
            internalNonce,
            true
        );

        require(requests[futureDebt].borrower == address(0), "Request already exist");
        bool approved = msg.sender == borrower;
        uint64 pos;
        if (approved) {
            pos = uint64(directory.push(futureDebt) - 1);
        }

        requests[futureDebt] = Request({
            open: true,
            approved: approved,
            position: pos,
            cosigner: address(0),
            currency: currency,
            amount: amount,
            model: model,
            creator: msg.sender,
            oracle: oracle,
            borrower: borrower,
            nonce: internalNonce,
            loanData: loanData,
            expiration: expiration
        });

        emit Requested(futureDebt, nonce);
    }

    function approveRequest(
        bytes32 futureDebt
    ) external returns (bool) {
        Request storage request = requests[futureDebt];
        require(msg.sender == request.borrower, "Only borrower can approve");
        if (!request.approved) {
            request.position = uint64(directory.push(futureDebt) - 1);
            request.approved = true;
            emit Approved(futureDebt);
        }
        return true;
    }

    function lend(
        bytes32 futureDebt,
        bytes oracleData,
        address cosigner,
        uint256 cosignerLimit,
        bytes cosignerData
    ) public returns (bool) {
        Request storage request = requests[futureDebt];
        require(request.open, "Request is no longer open");
        require(request.approved, "The request is not approved by the borrower");
        require(request.expiration > now, "The request is expired");

        request.open = false;

        uint256 tokens = currencyToToken(request.oracle, request.currency, request.amount, oracleData);
        require(
            token.transferFrom(
                msg.sender,
                request.borrower,
                tokens
            ),
            "Error sending tokens to borrower"
        );

        emit Lent(futureDebt, msg.sender, tokens);

        // Generate the debt
        require(
            debtEngine.create2(
                Model(request.model),
                msg.sender,
                request.oracle,
                request.currency,
                request.nonce,
                request.loanData
            ) == futureDebt,
            "Error creating the debt"
        );

        // Purge request
        delete request.loanData;

        // Remove directory entry
        bytes32 last = directory[directory.length - 1];
        requests[last].position = request.position;
        directory[request.position] = last;
        request.position = 0;
        directory.length--;

        // Call the cosigner
        if (cosigner != address(0)) {
            uint256 auxNonce = request.nonce;
            request.cosigner = address(uint256(cosigner) + 2);
            request.nonce = cosignerLimit; // Risky ?
            require(Cosigner(cosigner).requestCosign(Engine(address(this)), uint256(futureDebt), cosignerData, oracleData), "Cosign method returned false");
            require(request.cosigner == cosigner, "Cosigner didn&#39;t callback");
            request.nonce = auxNonce;
        }

        return true;
    }

    function requestSignature(
        bytes32[8] requestData,
        bytes loanData
    ) external view returns (bytes32) {
        return keccak256(abi.encodePacked(this, requestData, loanData));
    }

    function _requestSignature(
        bytes32[8] requestData,
        bytes loanData
    ) internal view returns (bytes32) {
        return keccak256(abi.encodePacked(this, requestData, loanData));
    }

    uint256 public constant R_CURRENCY = 0;
    uint256 public constant R_AMOUNT = 1;
    uint256 public constant R_MODEL = 2;
    uint256 public constant R_ORACLE = 3;
    uint256 public constant R_BORROWER = 4;
    uint256 public constant R_NONCE = 5;
    uint256 public constant R_EXPIRATION = 6;
    uint256 public constant R_CREATOR = 7;

    function settleLend(
        bytes32[8] requestData,
        bytes loanData,
        address cosigner,
        uint256 maxCosignerCost,
        bytes cosignerData,
        bytes oracleData,
        bytes creatorSig,
        bytes borrowerSig
    ) public returns (bytes32 futureDebt) {
        require(uint64(requestData[R_EXPIRATION]) > now, "Loan request is expired");
        require(address(requestData[R_BORROWER]) != address(0), "Borrower can&#39;t be 0x0");
        require(address(requestData[R_CREATOR]) != address(0), "Creator can&#39;t be 0x0");

        uint256 internalNonce = uint256(
            keccak256(
                abi.encodePacked(
                    address(requestData[R_CREATOR]),
                    uint256(requestData[R_NONCE]))
                )
            );
        
        futureDebt = debtEngine.buildId(
            address(this),
            internalNonce,
            true
        );
        
        require(requests[futureDebt].borrower == address(0), "Request already exist");

        bytes32 sig = _requestSignature(requestData, loanData);
        validateRequest(sig, requestData, loanData, borrowerSig, creatorSig);

        uint256 tokens = currencyToToken(requestData, oracleData);
        require(
            token.transferFrom(
                msg.sender,
                address(requestData[R_BORROWER]),
                tokens
            ),
            "Error sending tokens to borrower"
        );

        // Generate the debt
        require(createDebt(requestData, loanData, internalNonce) == futureDebt, "Error creating debt registry");

        emit SettledLend(futureDebt, sig, msg.sender, tokens);

        requests[futureDebt] = Request({
            open: false,
            approved: true,
            cosigner: cosigner,
            currency: bytes8(requestData[R_CURRENCY]),
            amount: uint128(requestData[R_AMOUNT]),
            model: address(requestData[R_MODEL]),
            creator: address(requestData[R_CREATOR]),
            oracle: address(requestData[R_ORACLE]),
            borrower: address(requestData[R_BORROWER]),
            nonce: cosigner != address(0) ? maxCosignerCost : internalNonce,
            loanData: "",
            position: 0,
            expiration: uint64(requestData[R_EXPIRATION])
        });
        
        Request storage request = requests[futureDebt];

        // Call the cosigner
        if (cosigner != address(0)) {
            request.cosigner = address(uint256(cosigner) + 2);
            require(Cosigner(cosigner).requestCosign(Engine(address(this)), uint256(futureDebt), cosignerData, oracleData), "Cosign method returned false");
            require(request.cosigner == cosigner, "Cosigner didn&#39;t callback");
            request.nonce = internalNonce;
        }
    }

    function cancel(bytes32 futureDebt) external returns (bool) {
        Request storage request = requests[futureDebt];

        require(
            request.creator == msg.sender || request.borrower == msg.sender,
            "Only borrower or creator can cancel a request"
        );

        // Remove directory entry
        bytes32 last = directory[directory.length - 1];
        requests[last].position = request.position;
        directory[request.position] = last;
        request.position = 0;
        directory.length--;

        delete request.loanData;
        delete requests[futureDebt];

        emit Canceled(futureDebt, msg.sender);

        return true;
    }

    function settleCancel(
        bytes32[8] requestData,
        bytes loanData
    ) external returns (bool) {
        bytes32 sig = _requestSignature(requestData, loanData);
        require(
            msg.sender == address(requestData[R_BORROWER]) ||
            msg.sender == address(requestData[R_CREATOR]),
            "Only borrower or creator can cancel a settle"
        );
        canceledSettles[sig] = true;
        emit SettledCancel(sig, msg.sender);

        return true;
    }

    function ecrecovery(bytes32 _hash, bytes _sig) internal pure returns (address) {
        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
            r := mload(add(_sig, 32))
            s := mload(add(_sig, 64))
            v := and(mload(add(_sig, 65)), 255)
        }

        if (v < 27) {
            v += 27;
        }

        return ecrecover(_hash, v, r, s);
    }

    function validateRequest(
        bytes32 sig,
        bytes32[8] requestData,
        bytes loanData,
        bytes borrowerSig,
        bytes creatorSig
    ) internal {
        require(!canceledSettles[sig], "Settle was canceled");
        
        uint256 expected = uint256(sig) / 2;
        address borrower = address(requestData[R_BORROWER]);
        address creator = address(requestData[R_CREATOR]);

        if (_isContract(borrower)) {
            require(
                LoanRequester(borrower).loanRequested(requestData, loanData, true, uint256(sig)) == expected,
                "Borrower contract rejected the loan"
            );
        } else {
            require(
                borrower == ecrecovery(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", sig)), borrowerSig),
                "Invalid borrower signature"
            );
        }

        if (borrower != creator) {
            if (_isContract(creator)) {
                require(
                    LoanRequester(creator).loanRequested(requestData, loanData, true, uint256(sig)) == expected,
                    "Creator contract rejected the loan"
                );
            } else {
                require(
                    creator == ecrecovery(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", sig)), creatorSig),
                    "Invalid creator signature"
                );
            }
        }
    }

    function createDebt(
        bytes32[8] requestData,
        bytes loanData,
        uint256 internalNonce
    ) internal returns (bytes32) {
        return debtEngine.create2(
            Model(address(requestData[R_MODEL])),
            msg.sender,
            address(requestData[R_ORACLE]),
            bytes8(requestData[R_CURRENCY]),
            internalNonce,
            loanData
        );
    }

    function cosign(uint256 futureDebt, uint256 cost) external returns (bool) {
        Request storage request = requests[bytes32(futureDebt)];
        require(request.position == 0, "Request cosigned is invalid");
        require(request.cosigner != address(0), "Cosigner not valid");
        require(request.expiration > now, "Request is expired");
        require(request.cosigner == address(uint256(msg.sender) + 2), "Cosigner not valid");
        request.cosigner = msg.sender;
        require(request.nonce >= cost || request.nonce == 0, "Cosigner cost exceeded");
        require(token.transferFrom(debtEngine.ownerOf(futureDebt), msg.sender, cost), "Error paying cosigner");
        emit Cosigned(bytes32(futureDebt), msg.sender, cost);
        return true;
    }

    function currencyToToken(
        bytes32[8] requestData,
        bytes oracleData
    ) internal returns (uint256) {
        return currencyToToken(
            address(requestData[R_ORACLE]),
            bytes16(requestData[R_CURRENCY]),
            uint256(requestData[R_AMOUNT]),
            oracleData
        );
    }

    function currencyToToken(
        address oracle,
        bytes16 currency,
        uint256 amount,
        bytes oracleData
    ) internal returns (uint256) {
        if (oracle != 0x0) {
            (uint256 rate, uint256 decimals) = Oracle(oracle).getRate(currency, oracleData);
            return (rate * amount * 10 ** (18 - decimals)) / 10 ** 18;
        } else {
            return amount;
        }
    }

    function _isContract(address addr) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }
}