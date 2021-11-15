pragma solidity ^0.5.4;

import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "openzeppelin-solidity/contracts/utils/Address.sol";
import "openzeppelin-solidity/contracts/introspection/IERC165.sol";
import "@openzeppelin/contracts/GSN/GSNRecipient.sol";
import "./IERC1155TokenReceiver.sol";
import "./IERC1155.sol";

// A sample implementation of core ERC1155 function.
contract ERC1155 is IERC1155, IERC165, GSNRecipient
{
    using SafeMath for uint256;
    using Address for address;

    bytes4 constant public ERC1155_RECEIVED = 0xf23a6e61;
    bytes4 constant public ERC1155_BATCH_RECEIVED = 0xbc197c81;

    // id => (owner => balance)
    mapping (uint256 => mapping(address => uint256)) internal balances;

    // owner => (operator => approved)
    mapping (address => mapping(address => bool)) internal operatorApproval;

/////////////////////////////////////////// ERC1155 //////////////////////////////////////////////
    /**
        @notice Transfers value amount of an _id from the _from address to the _to addresses specified. Each parameter array should be the same length, with each index correlating.
        @dev MUST emit TransferSingle event on success.
        Caller must be approved to manage the _from account's tokens (see isApprovedForAll).
        MUST Throw if `_to` is the zero address.
        MUST Throw if `_id` is not a valid token ID.
        MUST Throw on any other error.
        When transfer is complete, this function MUST check if `_to` is a smart contract (code size > 0). If so, it MUST call `onERC1155Received` on `_to`
        and revert if the return value is not `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`.
        @param _from    Source addresses
        @param _to      Target addresses
        @param _id      ID of the token type
        @param _value   Transfer amount
        @param _data    Additional data with no specified format, sent in call to `_to`
    */
    function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _value, bytes calldata _data) external {
        require(_to != address(0x0), "_to must be non-zero.");

        address sender = _msgSender();
        require(_from == sender || operatorApproval[_from][sender] == true, "Need operator approval for 3rd party transfers.");

        // SafeMath will throw with insuficient funds _from
        // or if _id is not valid (balance will be 0)
        balances[_id][_from] = balances[_id][_from].sub(_value);
        balances[_id][_to] = _value.add(balances[_id][_to]);

        emit TransferSingle(sender, _from, _to, _id, _value);

        if (_to.isContract()) {
            require(IERC1155TokenReceiver(_to).onERC1155Received(sender, _from, _id, _value, _data) == ERC1155_RECEIVED, "Receiver contract did not accept the transfer.");
        }
    }

    /**
        @notice Send multiple types of Tokens from a 3rd party in one transfer (with safety call).
        @dev MUST emit TransferBatch event on success.
        Caller must be approved to manage the _from account's tokens (see isApprovedForAll).
        MUST Throw if `_to` is the zero address.
        MUST Throw if any of the `_ids` is not a valid token ID.
        MUST Throw on any other error.
        When transfer is complete, this function MUST check if `_to` is a smart contract (code size > 0). If so, it MUST call `onERC1155BatchReceived` on `_to` 
        and revert if the return value is not `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`.
        @param _from    Source address
        @param _to      Target address
        @param _ids     IDs of each token type
        @param _values  Transfer amounts per token type
        @param _data    Additional data with no specified format, sent in call to `_to`
    */
    function safeBatchTransferFrom(address _from, address _to, uint256[] calldata _ids, uint256[] calldata _values, bytes calldata _data) external {
        // MUST Throw on errors
        require(_to != address(0x0), "destination address must be non-zero.");
        require(_ids.length == _values.length, "_ids and _values array lenght must match.");

        address sender = _msgSender();
        require(_from == sender || operatorApproval[_from][sender] == true, "Need operator approval for 3rd party transfers.");

        for (uint256 i = 0; i < _ids.length; ++i) {
            uint256 id = _ids[i];
            uint256 value = _values[i];

            // SafeMath will throw with insuficient funds _from
            // or if _id is not valid (balance will be 0)
            balances[id][_from] = balances[id][_from].sub(value);
            balances[id][_to] = value.add(balances[id][_to]);
        }

        // MUST emit event
        emit TransferBatch(sender, _from, _to, _ids, _values);

        // Now that the balances are updated,
        // call onERC1155BatchReceived if the destination is a contract
        if (_to.isContract()) {
            require(IERC1155TokenReceiver(_to).onERC1155BatchReceived(sender, _from, _ids, _values, _data) == ERC1155_BATCH_RECEIVED, "Receiver contract did not accept the transfer.");
        }
    }

    /**
        @notice Enable or disable approval for a third party ("operator") to manage all of the caller's tokens.
        @dev MUST emit the ApprovalForAll event on success.
        @param _operator  Address to add to the set of authorized operators
        @param _approved  True if the operator is approved, false to revoke approval
    */
    function setApprovalForAll(address _operator, bool _approved) external {
        address sender = _msgSender();
        operatorApproval[sender][_operator] = _approved;
        emit ApprovalForAll(sender, _operator, _approved);
    }

    /**
        @notice Get the balance of an account's Tokens.
        @param _owner  The address of the token holder
        @param _id     ID of the Token
        @return        The _owner's balance of the Token type requested
     */
    function balanceOf(address _owner, uint256 _id) external view returns (uint256) {
        // The balance of any account can be calculated from the Transfer events history.
        // However, since we need to keep the balances to validate transfer request,
        // there is no extra cost to also privide a querry function.
        return balances[_id][_owner];
    }

    /**
        @notice Get the balance of multiple account/token pairs
        @param _owners The addresses of the token holders
        @param _ids    ID of the Tokens
        @return        The _owner's balance of the Token types requested
     */
    function balanceOfBatch(address[] calldata _owners, uint256[] calldata _ids) external view returns (uint256[] memory) {
        require(_owners.length == _ids.length);

        uint256[] memory balances_ = new uint256[](_owners.length);

        for (uint256 i = 0; i < _owners.length; ++i) {
            balances_[i] = balances[_ids[i]][_owners[i]];
        }

        return balances_;
    }

    /**
        @notice Queries the approval status of an operator for a given owner.
        @param _owner     The owner of the Tokens
        @param _operator  Address of authorized operator
        @return           True if the operator is approved, false if not
    */
    function isApprovedForAll(address _owner, address _operator) external view returns (bool) {
        return operatorApproval[_owner][_operator];
    }

    function acceptRelayedCall(
        address,
        address from,
        bytes calldata,
        uint256 transactionFee,
        uint256 gasPrice,
        uint256,
        uint256,
        bytes calldata,
        uint256 maxPossibleCharge
    ) external view returns (uint256, bytes memory) {
        return _approveRelayedCall(abi.encode(from, maxPossibleCharge, transactionFee, gasPrice));
    }

/////////////////////////////////////////// ERC165 //////////////////////////////////////////////
    /*
        bytes4(keccak256('supportsInterface(bytes4)'));
    */
    bytes4 constant private INTERFACE_SIGNATURE_ERC165 = 0x01ffc9a7;

    /*
        bytes4(keccak256("safeTransferFrom(address,address,uint256,uint256,bytes)")) ^
        bytes4(keccak256("safeBatchTransferFrom(address,address,uint256[],uint256[],bytes)")) ^
        bytes4(keccak256("balanceOf(address,uint256)")) ^
        bytes4(keccak256("balanceOfBatch(address[],uint256[])")) ^
        bytes4(keccak256("setApprovalForAll(address,bool)")) ^
        bytes4(keccak256("isApprovedForAll(address,address)"));
    */
    bytes4 constant private INTERFACE_SIGNATURE_ERC1155 = 0xd9b67a26;

    function supportsInterface(bytes4 _interfaceId) public view returns (bool) {
        if (_interfaceId == INTERFACE_SIGNATURE_ERC165 ||
            _interfaceId == INTERFACE_SIGNATURE_ERC1155) {
            return true;
        }

        return false;
    }

    function _preRelayedCall(bytes memory) internal returns (bytes32) {
        return 0;
    }

    function _postRelayedCall(bytes memory, bool, uint256, bytes32) internal {
        // solhint-disable-previous-line no-empty-blocks
    }
}

pragma solidity ^0.5.4;

import "./ERC1155.sol";
import "@openzeppelin/contracts/access/roles/WhitelistedRole.sol";

/**
    @dev Extension to ERC1155 for Mixed Fungible and Non-Fungible Items support
    The main benefit is sharing of common type information, just like you do when
    creating a fungible id.
*/
contract ERC1155MixedFungible is ERC1155, WhitelistedRole {

    // Use a split bit implementation.
    // Store the type in the upper 128 bits..
    uint256 constant internal TYPE_MASK = uint256(uint128(~0)) << 128;

    // ..and the non-fungible index in the lower 128
    uint256 constant internal NF_INDEX_MASK = uint128(~0);

    // The top bit is a flag to tell if this is a NFI.
    uint256 constant internal TYPE_NF_BIT = 1 << 255;

    mapping (uint256 => address) internal nfOwners;

    // override
    function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _value, bytes calldata _data) external {
        require(isWhitelisted(_to), "_to should have Whitelisted role");

        address sender = _msgSender();
        require(_from == sender || operatorApproval[_from][sender] == true, "Need operator approval for 3rd party transfers.");

        _safeTransferFrom(_from, _to, _id, _value);
        emit TransferSingle(sender, _from, _to, _id, _value);

        if (_to.isContract()) {
            require(IERC1155TokenReceiver(_to).onERC1155Received(sender, _from, _id, _value, _data) == ERC1155_RECEIVED);
        }
    }

    // override
    function safeBatchTransferFrom(address _from, address _to, uint256[] calldata _ids, uint256[] calldata _values, bytes calldata _data) external {
        require(isWhitelisted(_to), "_to should have Whitelisted role");
        require(_ids.length == _values.length, "Array length must match");

        address sender = _msgSender();
        // Only supporting a global operator approval allows us to do only 1 check and not to touch storage to handle allowances.
        require(_from == sender || operatorApproval[_from][sender] == true, "Need operator approval for 3rd party transfers.");

        for (uint256 i = 0; i < _ids.length; ++i) {
            // Cache value to local variable to reduce read costs.
            uint256 id = _ids[i];
            uint256 value = _values[i];

            _safeTransferFrom(_from, _to, id, value);
        }

        emit TransferBatch(sender, _from, _to, _ids, _values);

        if (_to.isContract()) {
            require(IERC1155TokenReceiver(_to).onERC1155BatchReceived(sender, _from, _ids, _values, _data) == ERC1155_BATCH_RECEIVED);
        }
    }

    function balanceOf(address _owner, uint256 _id) external view returns (uint256) {
        if (isNonFungibleItem(_id))
            return nfOwners[_id] == _owner ? 1 : 0;
        return balances[_id][_owner];
    }

    function balanceOfBatch(address[] calldata _owners, uint256[] calldata _ids) external view returns (uint256[] memory) {
        require(_owners.length == _ids.length);

        uint256[] memory balances_ = new uint256[](_owners.length);

        for (uint256 i = 0; i < _owners.length; ++i) {
            uint256 id = _ids[i];
            if (isNonFungibleItem(id)) {
                balances_[i] = nfOwners[id] == _owners[i] ? 1 : 0;
            }
            balances_[i] = balances[id][_owners[i]];
        }

        return balances_;
    }

    // Only to make code clearer. Should not be functions
    function isNonFungible(uint256 _id) public pure returns(bool) {
        return _id & TYPE_NF_BIT == TYPE_NF_BIT;
    }

    function isFungible(uint256 _id) public pure returns(bool) {
        return _id & TYPE_NF_BIT == 0;
    }

    function getNonFungibleIndex(uint256 _id) public pure returns(uint256) {
        return _id & NF_INDEX_MASK;
    }

    function getNonFungibleBaseType(uint256 _id) public pure returns(uint256) {
        return _id & TYPE_MASK;
    }

    function isNonFungibleBaseType(uint256 _id) public pure returns(bool) {
        // A base type has the NF bit but does not have an index.
        return (_id & TYPE_NF_BIT == TYPE_NF_BIT) && (_id & NF_INDEX_MASK == 0);
    }

    function isNonFungibleItem(uint256 _id) public pure returns(bool) {
        // A base type has the NF bit but does has an index.
        return (_id & TYPE_NF_BIT == TYPE_NF_BIT) && (_id & NF_INDEX_MASK != 0);
    }

    function ownerOf(uint256 _id) public view returns (address) {
        return nfOwners[_id];
    }

    function _safeTransferFrom(address _from, address _to, uint256 _id, uint256 _value) private {
        if (isNonFungible(_id)) {
            // require(nfOwners[id] == _from);
            // nfOwners[id] = _to;

            uint256 baseType = getNonFungibleBaseType(_id);
            balances[baseType][_from] = balances[baseType][_from].sub(_value);
            balances[baseType][_to] = balances[baseType][_to].add(_value);
        } else {
            balances[_id][_from] = balances[_id][_from].sub(_value);
            balances[_id][_to] = balances[_id][_to].add(_value);
        }
    }
}

pragma solidity ^0.5.4;

import "@openzeppelin/contracts/ownership/Ownable.sol";
import "./ERC1155MixedFungible.sol";
import "./LinearCurve.sol";

contract FT is ERC1155MixedFungible, Ownable {
    enum State {Init, Active, Financed}

    struct Invoice {
        address owner;
        bytes32 digest;
        uint256 totalSupply;
        uint256 value;
        uint256 interest;
        uint256 publish;
        uint256 payoutInDays;
        address curve;
        State state;
        uint256 fee;
    }

    event LogFeeCollectorChanged(address indexed sender, address newCollector);
    event LogInvoiceFinanced(address indexed sender, address indexed owner, uint256 id, uint256 value, uint256 fee);
    event LogInvoicePaidOut(address indexed sender, address indexed receiver, uint256 id, uint256 value, uint256 day);
    event LogFinancierReplaced(address indexed sender, address indexed from, address indexed to, uint256 id, uint256 amount, uint256 value);
    event LogCredited(address indexed financier, address indexed receiver, uint256 amount, uint256 receivable, address collector, uint256 fee);
    event LogWithdrawal(address indexed from, uint256 indexed amount);

    // /* Contract name */
    // string public constant name = "Finturi";

    // /* Contract symbol */
    // string public constant symbol = "FNT";

    /* Default token id */
    uint256 public constant DEFAULT_TOKEN_ID = 1;

    /* Inverse basis point */
    uint256 public constant INVERSE_BASIS_POINT = 10000;

    uint256 private nonce;

    /* Mapping from owner to list of owned token IDs */
    mapping(address => uint256[]) private _ownedTokens;

    /* Array with all token ids, used for enumeration */
    uint256[] private _allTokens;

    mapping(uint256 => Invoice) private _invoices;

    address private _feeCollector;

    modifier onlyNonFungible(uint256 _id) {
        require(isNonFungible(_id), "Type must be non-fungible");
        _;
    }

    modifier onlyPermitted(address _address) {
        require(isWhitelisted(_address), "Address should be permitted");
        _;
    }

    constructor(address feeCollector) public {
        changeFeeCollector(feeCollector);
    }

    function mint(
        address to,
        uint256 quantity,
        bytes32 digest,
        uint256 value,
        uint256 interest,
        uint256 publish,
        uint256 payoutInDays,
        address curve,
        uint256 fee
    )
        external
        onlyOwner
        onlyPermitted(to)
        returns (uint256 id)
    {
        require(quantity > 0, "Quantity should more than zero");
        require(value > interest, "Value should greater interest");
        require(payoutInDays > 0, "PayoutInDays must be non-zero");
        require(curve != address(0x0), "Curve must be non-zero");
        require(fee <= 10000, "Fee must not be greater 10000");

        id = (++nonce << 128) | TYPE_NF_BIT;

        _ownedTokens[to].push(id);
        _allTokens.push(id);

        Invoice storage invoice = _invoices[id];
        invoice.owner = to;
        invoice.digest = digest;
        invoice.totalSupply = quantity;
        invoice.value = value;
        invoice.interest = interest;
        invoice.publish = publish;
        invoice.payoutInDays = payoutInDays;
        invoice.curve = curve;
        invoice.state = State.Active;
        invoice.fee = fee;

        balances[id][to] = balances[id][to].add(quantity);

        emit TransferSingle(_msgSender(), address(0x0), to, id, quantity);
    }

    function mint(address to, uint256 quantity)
        external
        onlyOwner
        onlyPermitted(to)
        returns (uint256 id)
    {
        id = DEFAULT_TOKEN_ID;

        balances[id][to] = balances[id][to].add(quantity);

        emit TransferSingle(_msgSender(), address(0x0), to, id, quantity);
    }

    function burn(address from, uint256 quantity)
        external
        onlyOwner
        returns (uint256 id)
    {
        id = DEFAULT_TOKEN_ID;

        balances[id][from] = balances[id][from].sub(quantity);

        emit TransferSingle(_msgSender(), from, address(0x0), id, quantity);
    }

    function finance(uint256 id, uint256 amount) external {
        _financeFrom(_msgSender(), id, amount);
    }

    function financeFrom(address from, uint256 id, uint256 amount)
        external
        onlyOwner
    {
        _financeFrom(from, id, amount);
    }

    function payout(address to, uint256 id, uint256 amount, uint256 day)
        external
    {
        _payoutFrom(_msgSender(), to, id, amount, day);
    }

    function payoutFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        uint256 day
    ) external onlyOwner {
        _payoutFrom(from, to, id, amount, day);
    }

    function replaceFinancier(address from, address to, uint256 id)
        external
        onlyOwner
        onlyNonFungible(id)
    {
        require(to != address(0x0));

        require(_invoices[id].state == State.Financed, "State must be Financed");
        require(balances[id][from] > 0, "Balance should greater than zero");

        uint256 amount = balances[id][from];
        uint256 value = getPrice(id, amount, 0);

        balances[DEFAULT_TOKEN_ID][to] = balances[DEFAULT_TOKEN_ID][to].sub(value);
        balances[DEFAULT_TOKEN_ID][from] = balances[DEFAULT_TOKEN_ID][from].add(value);

        balances[id][from] = balances[id][from].sub(amount);
        balances[id][to] = balances[id][to].add(amount);

        emit LogFinancierReplaced(_msgSender(), from, to, id, amount, value);
    }

    function creditWithdraw(
        address financier,
        uint256 amount,
        address receiver,
        uint256 receivableAmount,
        address collector,
        uint256 feeAmount
    ) external onlyOwner {
        require(receivableAmount.add(feeAmount) == amount);

        balances[DEFAULT_TOKEN_ID][financier] = balances[DEFAULT_TOKEN_ID][financier].sub(amount);

        emit LogCredited(financier, receiver, amount, receivableAmount, collector, feeAmount);
        emit LogWithdrawal(receiver, receivableAmount);
        emit LogWithdrawal(collector, feeAmount);
    }

    function getNow() external view returns (uint256) {
        return now;
    }

    function getInvoice(uint256 id)
        external
        view
        onlyNonFungible(id)
        returns (
            address invoiceOwner,
            bytes32 digest,
            uint256 totalSupply,
            uint256 value,
            uint256 interest,
            uint256 publish,
            uint256 payoutInDays,
            address curve,
            State state,
            uint256 fee
        )
    {
        Invoice storage invoice = _invoices[id];
        invoiceOwner = invoice.owner;
        digest = invoice.digest;
        totalSupply = invoice.totalSupply;
        value = invoice.value;
        interest = invoice.interest;
        publish = invoice.publish;
        payoutInDays = invoice.payoutInDays;
        curve = invoice.curve;
        state = invoice.state;
        fee = invoice.fee;
    }

    function changeFeeCollector(address feeCollector) public onlyOwner {
        _feeCollector = feeCollector;

        emit LogFeeCollectorChanged(_msgSender(), _feeCollector);
    }

    function getPrice(uint256 id, uint256 amount, uint256 day)
        public
        view
        returns (uint256)
    {
        uint256 price = getUnitPrice(id, day);
        return price.mul(amount);
    }

    function getUnitPrice(uint256 id, uint256 day)
        public
        view
        returns (uint256)
    {
        Invoice storage invoice = _invoices[id];
        uint256 y1 = invoice.value.div(invoice.totalSupply);
        uint256 y2 = invoice.value.add(invoice.interest).div(invoice.totalSupply);

        return LinearCurve(invoice.curve).getPrice(0, y1, invoice.payoutInDays, y2, day);
    }

    function _financeFrom(address from, uint256 id, uint256 amount)
        private
        onlyNonFungible(id)
    {
        Invoice storage invoice = _invoices[id];
        require(invoice.owner != from, "Invoice owner cannot execute");
        require(invoice.state == State.Active, "State must be Active");
        require(
            invoice.totalSupply == amount,
            "Amount is bigger then totalSupply"
        );

        invoice.state = State.Financed;

        uint256 fee;
        uint256 value = getPrice(id, amount, 0);
        uint256 receiveAmount = value;
        if (invoice.fee > 0) {
            fee = invoice.fee.mul(value).div(INVERSE_BASIS_POINT);
            receiveAmount = receiveAmount.sub(fee);
            balances[DEFAULT_TOKEN_ID][_feeCollector] = balances[DEFAULT_TOKEN_ID][_feeCollector].add(fee);
        }

        balances[DEFAULT_TOKEN_ID][from] = balances[DEFAULT_TOKEN_ID][from].sub(value);
        balances[DEFAULT_TOKEN_ID][invoice.owner] = balances[DEFAULT_TOKEN_ID][invoice.owner].add(receiveAmount);

        balances[id][invoice.owner] = balances[id][invoice.owner].sub(amount);
        balances[id][from] = balances[id][from].add(amount);

        emit LogInvoiceFinanced(from, invoice.owner, id, receiveAmount, fee);
    }

    function _payoutFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        uint256 day
    )
        private
        onlyNonFungible(id)
    {
        Invoice storage invoice = _invoices[id];
        require(invoice.owner == from, "Only invoice owner can execute");
        require(invoice.state == State.Financed, "State must be Financed");

        uint256 value = getPrice(id, amount, day);
        balances[DEFAULT_TOKEN_ID][invoice.owner] = balances[DEFAULT_TOKEN_ID][invoice.owner].sub(value);
        balances[DEFAULT_TOKEN_ID][to] = balances[DEFAULT_TOKEN_ID][to].add(value);

        balances[id][to] = balances[id][to].sub(amount);
        balances[id][invoice.owner] = balances[id][invoice.owner].add(amount);

        emit LogInvoicePaidOut(invoice.owner, to, id, value, day);
    }
}

pragma solidity ^0.5.4;

/**
    @title ERC-1155 Multi Token Standard
    @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-1155.md
    Note: The ERC-165 identifier for this interface is 0xd9b67a26.
 */
interface IERC1155 {
    /**
        @dev Either TransferSingle or TransferBatch MUST emit when tokens are transferred, including zero value transfers as well as minting or burning.
        Operator will always be msg.sender.
        Either event from address `0x0` signifies a minting operation.
        An event to address `0x0` signifies a burning or melting operation.
        The total value transferred from address 0x0 minus the total value transferred to 0x0 may be used by clients and exchanges to be added to the "circulating supply" for a given token ID.
        To define a token ID with no initial balance, the contract SHOULD emit the TransferSingle event from `0x0` to `0x0`, with the token creator as `_operator`.
    */
    event TransferSingle(address indexed _operator, address indexed _from, address indexed _to, uint256 _id, uint256 _value);

    /**
        @dev Either TransferSingle or TransferBatch MUST emit when tokens are transferred, including zero value transfers as well as minting or burning.
        Operator will always be msg.sender.
        Either event from address `0x0` signifies a minting operation.
        An event to address `0x0` signifies a burning or melting operation.
        The total value transferred from address 0x0 minus the total value transferred to 0x0 may be used by clients and exchanges to be added to the "circulating supply" for a given token ID.
        To define multiple token IDs with no initial balance, this SHOULD emit the TransferBatch event from `0x0` to `0x0`, with the token creator as `_operator`.
    */
    event TransferBatch(address indexed _operator, address indexed _from, address indexed _to, uint256[] _ids, uint256[] _values);

    /**
        @dev MUST emit when an approval is updated.
    */
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    /**
        @dev MUST emit when the URI is updated for a token ID.
        URIs are defined in RFC 3986.
        The URI MUST point a JSON file that conforms to the "ERC-1155 Metadata JSON Schema".
    */
    event URI(string _value, uint256 indexed _id);

    /**
        @notice Transfers value amount of an _id from the _from address to the _to address specified.
        @dev MUST emit TransferSingle event on success.
        Caller must be approved to manage the _from account's tokens (see isApprovedForAll).
        MUST throw if `_to` is the zero address.
        MUST throw if balance of sender for token `_id` is lower than the `_value` sent.
        MUST throw on any other error.
        When transfer is complete, this function MUST check if `_to` is a smart contract (code size > 0). If so, it MUST call `onERC1155Received` on `_to`
        and revert if the return value is not `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`.
        @param _from    Source address
        @param _to      Target address
        @param _id      ID of the token type
        @param _value   Transfer amount
        @param _data    Additional data with no specified format, sent in call to `_to`
    */
    function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _value, bytes calldata _data) external;

    /**
        @notice Send multiple types of Tokens from a 3rd party in one transfer (with safety call).
        @dev MUST emit TransferBatch event on success.
        Caller must be approved to manage the _from account's tokens (see isApprovedForAll).
        MUST throw if `_to` is the zero address.
        MUST throw if length of `_ids` is not the same as length of `_values`.
        MUST throw if any of the balance of sender for token `_ids` is lower than the respective `_values` sent.
        MUST throw on any other error.
        When transfer is complete, this function MUST check if `_to` is a smart contract (code size > 0). If so, it MUST call `onERC1155BatchReceived` on `_to`
        and revert if the return value is not `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`.
        @param _from    Source addresses
        @param _to      Target addresses
        @param _ids     IDs of each token type
        @param _values  Transfer amounts per token type
        @param _data    Additional data with no specified format, sent in call to `_to`
    */
    function safeBatchTransferFrom(address _from, address _to, uint256[] calldata _ids, uint256[] calldata _values, bytes calldata _data) external;

    /**
        @notice Enable or disable approval for a third party ("operator") to manage all of the caller's tokens.
        @dev MUST emit the ApprovalForAll event on success.
        @param _operator  Address to add to the set of authorized operators
        @param _approved  True if the operator is approved, false to revoke approval
    */
    function setApprovalForAll(address _operator, bool _approved) external;

    /**
        @notice Get the balance of an account's Tokens.
        @param _owner  The address of the token holder
        @param _id     ID of the Token
        @return        The _owner's balance of the Token type requested
     */
    function balanceOf(address _owner, uint256 _id) external view returns (uint256);

    /**
        @notice Get the balance of multiple account/token pairs
        @param _owners The addresses of the token holders
        @param _ids    ID of the Tokens
        @return        The _owner's balance of the Token types requested
     */
    function balanceOfBatch(address[] calldata _owners, uint256[] calldata _ids) external view returns (uint256[] memory);

    /**
        @notice Queries the approval status of an operator for a given owner.
        @param _owner     The owner of the Tokens
        @param _operator  Address of authorized operator
        @return           True if the operator is approved, false if not
    */
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}

pragma solidity ^0.5.4;

interface IERC1155TokenReceiver {
    /**
        @notice Handle the receipt of a single ERC1155 token type
        @dev The smart contract calls this function on the recipient
        after a `safeTransferFrom`. This function MAY throw to revert and reject the
        transfer. Return of other than the magic value MUST result in the
        transaction being reverted
        Note: the contract address is always the message sender
        @param _operator  The address which called `safeTransferFrom` function
        @param _from      The address which previously owned the token
        @param _id        An array containing the ids of the token being transferred
        @param _value     An array containing the amount of tokens being transferred
        @param _data      Additional data with no specified format
        @return           `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
    */
    function onERC1155Received(address _operator, address _from, uint256 _id, uint256 _value, bytes calldata _data) external returns(bytes4);

    /**
        @notice Handle the receipt of multiple ERC1155 token types
        @dev The smart contract calls this function on the recipient
        after a `safeTransferFrom`. This function MAY throw to revert and reject the
        transfer. Return of other than the magic value MUST result in the
        transaction being reverted
        Note: the contract address is always the message sender
        @param _operator  The address which called `safeTransferFrom` function
        @param _from      The address which previously owned the token
        @param _ids       An array containing ids of each token being transferred
        @param _values    An array containing amounts of each token being transferred
        @param _data      Additional data with no specified format
        @return           `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
    */
    function onERC1155BatchReceived(address _operator, address _from, uint256[] calldata _ids, uint256[] calldata _values, bytes calldata _data) external returns(bytes4);
}

pragma solidity ^0.5.4;

contract LinearCurve {
    function getPrice(uint x1, uint y1, uint x2, uint y2, uint x) public pure returns(uint) {
        return -((y1 - y2) * x + (x1 * y2 - x2 * y1)) / (x2 - x1);
    }
}

pragma solidity ^0.5.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

pragma solidity ^0.5.0;

import "./IRelayRecipient.sol";
import "./IRelayHub.sol";
import "./Context.sol";

/**
 * @dev Base GSN recipient contract: includes the {IRelayRecipient} interface
 * and enables GSN support on all contracts in the inheritance tree.
 *
 * TIP: This contract is abstract. The functions {acceptRelayedCall},
 *  {_preRelayedCall}, and {_postRelayedCall} are not implemented and must be
 * provided by derived contracts. See the
 * xref:ROOT:gsn-strategies.adoc#gsn-strategies[GSN strategies] for more
 * information on how to use the pre-built {GSNRecipientSignature} and
 * {GSNRecipientERC20Fee}, or how to write your own.
 */
contract GSNRecipient is IRelayRecipient, Context {
    // Default RelayHub address, deployed on mainnet and all testnets at the same address
    address private _relayHub = 0xD216153c06E857cD7f72665E0aF1d7D82172F494;

    uint256 constant private RELAYED_CALL_ACCEPTED = 0;
    uint256 constant private RELAYED_CALL_REJECTED = 11;

    // How much gas is forwarded to postRelayedCall
    uint256 constant internal POST_RELAYED_CALL_MAX_GAS = 100000;

    /**
     * @dev Emitted when a contract changes its {IRelayHub} contract to a new one.
     */
    event RelayHubChanged(address indexed oldRelayHub, address indexed newRelayHub);

    /**
     * @dev Returns the address of the {IRelayHub} contract for this recipient.
     */
    function getHubAddr() public view returns (address) {
        return _relayHub;
    }

    /**
     * @dev Switches to a new {IRelayHub} instance. This method is added for future-proofing: there's no reason to not
     * use the default instance.
     *
     * IMPORTANT: After upgrading, the {GSNRecipient} will no longer be able to receive relayed calls from the old
     * {IRelayHub} instance. Additionally, all funds should be previously withdrawn via {_withdrawDeposits}.
     */
    function _upgradeRelayHub(address newRelayHub) internal {
        address currentRelayHub = _relayHub;
        require(newRelayHub != address(0), "GSNRecipient: new RelayHub is the zero address");
        require(newRelayHub != currentRelayHub, "GSNRecipient: new RelayHub is the current one");

        emit RelayHubChanged(currentRelayHub, newRelayHub);

        _relayHub = newRelayHub;
    }

    /**
     * @dev Returns the version string of the {IRelayHub} for which this recipient implementation was built. If
     * {_upgradeRelayHub} is used, the new {IRelayHub} instance should be compatible with this version.
     */
    // This function is view for future-proofing, it may require reading from
    // storage in the future.
    function relayHubVersion() public view returns (string memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return "1.0.0";
    }

    /**
     * @dev Withdraws the recipient's deposits in `RelayHub`.
     *
     * Derived contracts should expose this in an external interface with proper access control.
     */
    function _withdrawDeposits(uint256 amount, address payable payee) internal {
        IRelayHub(_relayHub).withdraw(amount, payee);
    }

    // Overrides for Context's functions: when called from RelayHub, sender and
    // data require some pre-processing: the actual sender is stored at the end
    // of the call data, which in turns means it needs to be removed from it
    // when handling said data.

    /**
     * @dev Replacement for msg.sender. Returns the actual sender of a transaction: msg.sender for regular transactions,
     * and the end-user for GSN relayed calls (where msg.sender is actually `RelayHub`).
     *
     * IMPORTANT: Contracts derived from {GSNRecipient} should never use `msg.sender`, and use {_msgSender} instead.
     */
    function _msgSender() internal view returns (address payable) {
        if (msg.sender != _relayHub) {
            return msg.sender;
        } else {
            return _getRelayedCallSender();
        }
    }

    /**
     * @dev Replacement for msg.data. Returns the actual calldata of a transaction: msg.data for regular transactions,
     * and a reduced version for GSN relayed calls (where msg.data contains additional information).
     *
     * IMPORTANT: Contracts derived from {GSNRecipient} should never use `msg.data`, and use {_msgData} instead.
     */
    function _msgData() internal view returns (bytes memory) {
        if (msg.sender != _relayHub) {
            return msg.data;
        } else {
            return _getRelayedCallData();
        }
    }

    // Base implementations for pre and post relayedCall: only RelayHub can invoke them, and data is forwarded to the
    // internal hook.

    /**
     * @dev See `IRelayRecipient.preRelayedCall`.
     *
     * This function should not be overriden directly, use `_preRelayedCall` instead.
     *
     * * Requirements:
     *
     * - the caller must be the `RelayHub` contract.
     */
    function preRelayedCall(bytes calldata context) external returns (bytes32) {
        require(msg.sender == getHubAddr(), "GSNRecipient: caller is not RelayHub");
        return _preRelayedCall(context);
    }

    /**
     * @dev See `IRelayRecipient.preRelayedCall`.
     *
     * Called by `GSNRecipient.preRelayedCall`, which asserts the caller is the `RelayHub` contract. Derived contracts
     * must implement this function with any relayed-call preprocessing they may wish to do.
     *
     */
    function _preRelayedCall(bytes memory context) internal returns (bytes32);

    /**
     * @dev See `IRelayRecipient.postRelayedCall`.
     *
     * This function should not be overriden directly, use `_postRelayedCall` instead.
     *
     * * Requirements:
     *
     * - the caller must be the `RelayHub` contract.
     */
    function postRelayedCall(bytes calldata context, bool success, uint256 actualCharge, bytes32 preRetVal) external {
        require(msg.sender == getHubAddr(), "GSNRecipient: caller is not RelayHub");
        _postRelayedCall(context, success, actualCharge, preRetVal);
    }

    /**
     * @dev See `IRelayRecipient.postRelayedCall`.
     *
     * Called by `GSNRecipient.postRelayedCall`, which asserts the caller is the `RelayHub` contract. Derived contracts
     * must implement this function with any relayed-call postprocessing they may wish to do.
     *
     */
    function _postRelayedCall(bytes memory context, bool success, uint256 actualCharge, bytes32 preRetVal) internal;

    /**
     * @dev Return this in acceptRelayedCall to proceed with the execution of a relayed call. Note that this contract
     * will be charged a fee by RelayHub
     */
    function _approveRelayedCall() internal pure returns (uint256, bytes memory) {
        return _approveRelayedCall("");
    }

    /**
     * @dev See `GSNRecipient._approveRelayedCall`.
     *
     * This overload forwards `context` to _preRelayedCall and _postRelayedCall.
     */
    function _approveRelayedCall(bytes memory context) internal pure returns (uint256, bytes memory) {
        return (RELAYED_CALL_ACCEPTED, context);
    }

    /**
     * @dev Return this in acceptRelayedCall to impede execution of a relayed call. No fees will be charged.
     */
    function _rejectRelayedCall(uint256 errorCode) internal pure returns (uint256, bytes memory) {
        return (RELAYED_CALL_REJECTED + errorCode, "");
    }

    /*
     * @dev Calculates how much RelayHub will charge a recipient for using `gas` at a `gasPrice`, given a relayer's
     * `serviceFee`.
     */
    function _computeCharge(uint256 gas, uint256 gasPrice, uint256 serviceFee) internal pure returns (uint256) {
        // The fee is expressed as a percentage. E.g. a value of 40 stands for a 40% fee, so the recipient will be
        // charged for 1.4 times the spent amount.
        return (gas * gasPrice * (100 + serviceFee)) / 100;
    }

    function _getRelayedCallSender() private pure returns (address payable result) {
        // We need to read 20 bytes (an address) located at array index msg.data.length - 20. In memory, the array
        // is prefixed with a 32-byte length value, so we first add 32 to get the memory read index. However, doing
        // so would leave the address in the upper 20 bytes of the 32-byte word, which is inconvenient and would
        // require bit shifting. We therefore subtract 12 from the read index so the address lands on the lower 20
        // bytes. This can always be done due to the 32-byte prefix.

        // The final memory read index is msg.data.length - 20 + 32 - 12 = msg.data.length. Using inline assembly is the
        // easiest/most-efficient way to perform this operation.

        // These fields are not accessible from assembly
        bytes memory array = msg.data;
        uint256 index = msg.data.length;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            // Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
            result := and(mload(add(array, index)), 0xffffffffffffffffffffffffffffffffffffffff)
        }
        return result;
    }

    function _getRelayedCallData() private pure returns (bytes memory) {
        // RelayHub appends the sender address at the end of the calldata, so in order to retrieve the actual msg.data,
        // we must strip the last 20 bytes (length of an address type) from it.

        uint256 actualDataLength = msg.data.length - 20;
        bytes memory actualData = new bytes(actualDataLength);

        for (uint256 i = 0; i < actualDataLength; ++i) {
            actualData[i] = msg.data[i];
        }

        return actualData;
    }
}

pragma solidity ^0.5.0;

/**
 * @dev Interface for `RelayHub`, the core contract of the GSN. Users should not need to interact with this contract
 * directly.
 *
 * See the https://github.com/OpenZeppelin/openzeppelin-gsn-helpers[OpenZeppelin GSN helpers] for more information on
 * how to deploy an instance of `RelayHub` on your local test network.
 */
contract IRelayHub {
    // Relay management

    /**
     * @dev Adds stake to a relay and sets its `unstakeDelay`. If the relay does not exist, it is created, and the caller
     * of this function becomes its owner. If the relay already exists, only the owner can call this function. A relay
     * cannot be its own owner.
     *
     * All Ether in this function call will be added to the relay's stake.
     * Its unstake delay will be assigned to `unstakeDelay`, but the new value must be greater or equal to the current one.
     *
     * Emits a {Staked} event.
     */
    function stake(address relayaddr, uint256 unstakeDelay) external payable;

    /**
     * @dev Emitted when a relay's stake or unstakeDelay are increased
     */
    event Staked(address indexed relay, uint256 stake, uint256 unstakeDelay);

    /**
     * @dev Registers the caller as a relay.
     * The relay must be staked for, and not be a contract (i.e. this function must be called directly from an EOA).
     *
     * This function can be called multiple times, emitting new {RelayAdded} events. Note that the received
     * `transactionFee` is not enforced by {relayCall}.
     *
     * Emits a {RelayAdded} event.
     */
    function registerRelay(uint256 transactionFee, string memory url) public;

    /**
     * @dev Emitted when a relay is registered or re-registerd. Looking at these events (and filtering out
     * {RelayRemoved} events) lets a client discover the list of available relays.
     */
    event RelayAdded(address indexed relay, address indexed owner, uint256 transactionFee, uint256 stake, uint256 unstakeDelay, string url);

    /**
     * @dev Removes (deregisters) a relay. Unregistered (but staked for) relays can also be removed.
     *
     * Can only be called by the owner of the relay. After the relay's `unstakeDelay` has elapsed, {unstake} will be
     * callable.
     *
     * Emits a {RelayRemoved} event.
     */
    function removeRelayByOwner(address relay) public;

    /**
     * @dev Emitted when a relay is removed (deregistered). `unstakeTime` is the time when unstake will be callable.
     */
    event RelayRemoved(address indexed relay, uint256 unstakeTime);

    /** Deletes the relay from the system, and gives back its stake to the owner.
     *
     * Can only be called by the relay owner, after `unstakeDelay` has elapsed since {removeRelayByOwner} was called.
     *
     * Emits an {Unstaked} event.
     */
    function unstake(address relay) public;

    /**
     * @dev Emitted when a relay is unstaked for, including the returned stake.
     */
    event Unstaked(address indexed relay, uint256 stake);

    // States a relay can be in
    enum RelayState {
        Unknown, // The relay is unknown to the system: it has never been staked for
        Staked, // The relay has been staked for, but it is not yet active
        Registered, // The relay has registered itself, and is active (can relay calls)
        Removed    // The relay has been removed by its owner and can no longer relay calls. It must wait for its unstakeDelay to elapse before it can unstake
    }

    /**
     * @dev Returns a relay's status. Note that relays can be deleted when unstaked or penalized, causing this function
     * to return an empty entry.
     */
    function getRelay(address relay) external view returns (uint256 totalStake, uint256 unstakeDelay, uint256 unstakeTime, address payable owner, RelayState state);

    // Balance management

    /**
     * @dev Deposits Ether for a contract, so that it can receive (and pay for) relayed transactions.
     *
     * Unused balance can only be withdrawn by the contract itself, by calling {withdraw}.
     *
     * Emits a {Deposited} event.
     */
    function depositFor(address target) public payable;

    /**
     * @dev Emitted when {depositFor} is called, including the amount and account that was funded.
     */
    event Deposited(address indexed recipient, address indexed from, uint256 amount);

    /**
     * @dev Returns an account's deposits. These can be either a contracts's funds, or a relay owner's revenue.
     */
    function balanceOf(address target) external view returns (uint256);

    /**
     * Withdraws from an account's balance, sending it back to it. Relay owners call this to retrieve their revenue, and
     * contracts can use it to reduce their funding.
     *
     * Emits a {Withdrawn} event.
     */
    function withdraw(uint256 amount, address payable dest) public;

    /**
     * @dev Emitted when an account withdraws funds from `RelayHub`.
     */
    event Withdrawn(address indexed account, address indexed dest, uint256 amount);

    // Relaying

    /**
     * @dev Checks if the `RelayHub` will accept a relayed operation.
     * Multiple things must be true for this to happen:
     *  - all arguments must be signed for by the sender (`from`)
     *  - the sender's nonce must be the current one
     *  - the recipient must accept this transaction (via {acceptRelayedCall})
     *
     * Returns a `PreconditionCheck` value (`OK` when the transaction can be relayed), or a recipient-specific error
     * code if it returns one in {acceptRelayedCall}.
     */
    function canRelay(
        address relay,
        address from,
        address to,
        bytes memory encodedFunction,
        uint256 transactionFee,
        uint256 gasPrice,
        uint256 gasLimit,
        uint256 nonce,
        bytes memory signature,
        bytes memory approvalData
    ) public view returns (uint256 status, bytes memory recipientContext);

    // Preconditions for relaying, checked by canRelay and returned as the corresponding numeric values.
    enum PreconditionCheck {
        OK,                         // All checks passed, the call can be relayed
        WrongSignature,             // The transaction to relay is not signed by requested sender
        WrongNonce,                 // The provided nonce has already been used by the sender
        AcceptRelayedCallReverted,  // The recipient rejected this call via acceptRelayedCall
        InvalidRecipientStatusCode  // The recipient returned an invalid (reserved) status code
    }

    /**
     * @dev Relays a transaction.
     *
     * For this to succeed, multiple conditions must be met:
     *  - {canRelay} must `return PreconditionCheck.OK`
     *  - the sender must be a registered relay
     *  - the transaction's gas price must be larger or equal to the one that was requested by the sender
     *  - the transaction must have enough gas to not run out of gas if all internal transactions (calls to the
     * recipient) use all gas available to them
     *  - the recipient must have enough balance to pay the relay for the worst-case scenario (i.e. when all gas is
     * spent)
     *
     * If all conditions are met, the call will be relayed and the recipient charged. {preRelayedCall}, the encoded
     * function and {postRelayedCall} will be called in that order.
     *
     * Parameters:
     *  - `from`: the client originating the request
     *  - `to`: the target {IRelayRecipient} contract
     *  - `encodedFunction`: the function call to relay, including data
     *  - `transactionFee`: fee (%) the relay takes over actual gas cost
     *  - `gasPrice`: gas price the client is willing to pay
     *  - `gasLimit`: gas to forward when calling the encoded function
     *  - `nonce`: client's nonce
     *  - `signature`: client's signature over all previous params, plus the relay and RelayHub addresses
     *  - `approvalData`: dapp-specific data forwared to {acceptRelayedCall}. This value is *not* verified by the
     * `RelayHub`, but it still can be used for e.g. a signature.
     *
     * Emits a {TransactionRelayed} event.
     */
    function relayCall(
        address from,
        address to,
        bytes memory encodedFunction,
        uint256 transactionFee,
        uint256 gasPrice,
        uint256 gasLimit,
        uint256 nonce,
        bytes memory signature,
        bytes memory approvalData
    ) public;

    /**
     * @dev Emitted when an attempt to relay a call failed.
     *
     * This can happen due to incorrect {relayCall} arguments, or the recipient not accepting the relayed call. The
     * actual relayed call was not executed, and the recipient not charged.
     *
     * The `reason` parameter contains an error code: values 1-10 correspond to `PreconditionCheck` entries, and values
     * over 10 are custom recipient error codes returned from {acceptRelayedCall}.
     */
    event CanRelayFailed(address indexed relay, address indexed from, address indexed to, bytes4 selector, uint256 reason);

    /**
     * @dev Emitted when a transaction is relayed. 
     * Useful when monitoring a relay's operation and relayed calls to a contract
     *
     * Note that the actual encoded function might be reverted: this is indicated in the `status` parameter.
     *
     * `charge` is the Ether value deducted from the recipient's balance, paid to the relay's owner.
     */
    event TransactionRelayed(address indexed relay, address indexed from, address indexed to, bytes4 selector, RelayCallStatus status, uint256 charge);

    // Reason error codes for the TransactionRelayed event
    enum RelayCallStatus {
        OK,                      // The transaction was successfully relayed and execution successful - never included in the event
        RelayedCallFailed,       // The transaction was relayed, but the relayed call failed
        PreRelayedFailed,        // The transaction was not relayed due to preRelatedCall reverting
        PostRelayedFailed,       // The transaction was relayed and reverted due to postRelatedCall reverting
        RecipientBalanceChanged  // The transaction was relayed and reverted due to the recipient's balance changing
    }

    /**
     * @dev Returns how much gas should be forwarded to a call to {relayCall}, in order to relay a transaction that will
     * spend up to `relayedCallStipend` gas.
     */
    function requiredGas(uint256 relayedCallStipend) public view returns (uint256);

    /**
     * @dev Returns the maximum recipient charge, given the amount of gas forwarded, gas price and relay fee.
     */
    function maxPossibleCharge(uint256 relayedCallStipend, uint256 gasPrice, uint256 transactionFee) public view returns (uint256);

     // Relay penalization. 
     // Any account can penalize relays, removing them from the system immediately, and rewarding the
    // reporter with half of the relay's stake. The other half is burned so that, even if the relay penalizes itself, it
    // still loses half of its stake.

    /**
     * @dev Penalize a relay that signed two transactions using the same nonce (making only the first one valid) and
     * different data (gas price, gas limit, etc. may be different).
     *
     * The (unsigned) transaction data and signature for both transactions must be provided.
     */
    function penalizeRepeatedNonce(bytes memory unsignedTx1, bytes memory signature1, bytes memory unsignedTx2, bytes memory signature2) public;

    /**
     * @dev Penalize a relay that sent a transaction that didn't target `RelayHub`'s {registerRelay} or {relayCall}.
     */
    function penalizeIllegalTransaction(bytes memory unsignedTx, bytes memory signature) public;

    /**
     * @dev Emitted when a relay is penalized.
     */
    event Penalized(address indexed relay, address sender, uint256 amount);

    /**
     * @dev Returns an account's nonce in `RelayHub`.
     */
    function getNonce(address from) external view returns (uint256);
}

pragma solidity ^0.5.0;

/**
 * @dev Base interface for a contract that will be called via the GSN from {IRelayHub}.
 *
 * TIP: You don't need to write an implementation yourself! Inherit from {GSNRecipient} instead.
 */
contract IRelayRecipient {
    /**
     * @dev Returns the address of the {IRelayHub} instance this recipient interacts with.
     */
    function getHubAddr() public view returns (address);

    /**
     * @dev Called by {IRelayHub} to validate if this recipient accepts being charged for a relayed call. Note that the
     * recipient will be charged regardless of the execution result of the relayed call (i.e. if it reverts or not).
     *
     * The relay request was originated by `from` and will be served by `relay`. `encodedFunction` is the relayed call
     * calldata, so its first four bytes are the function selector. The relayed call will be forwarded `gasLimit` gas,
     * and the transaction executed with a gas price of at least `gasPrice`. `relay`'s fee is `transactionFee`, and the
     * recipient will be charged at most `maxPossibleCharge` (in wei). `nonce` is the sender's (`from`) nonce for
     * replay attack protection in {IRelayHub}, and `approvalData` is a optional parameter that can be used to hold a signature
     * over all or some of the previous values.
     *
     * Returns a tuple, where the first value is used to indicate approval (0) or rejection (custom non-zero error code,
     * values 1 to 10 are reserved) and the second one is data to be passed to the other {IRelayRecipient} functions.
     *
     * {acceptRelayedCall} is called with 50k gas: if it runs out during execution, the request will be considered
     * rejected. A regular revert will also trigger a rejection.
     */
    function acceptRelayedCall(
        address relay,
        address from,
        bytes calldata encodedFunction,
        uint256 transactionFee,
        uint256 gasPrice,
        uint256 gasLimit,
        uint256 nonce,
        bytes calldata approvalData,
        uint256 maxPossibleCharge
    )
        external
        view
        returns (uint256, bytes memory);

    /**
     * @dev Called by {IRelayHub} on approved relay call requests, before the relayed call is executed. This allows to e.g.
     * pre-charge the sender of the transaction.
     *
     * `context` is the second value returned in the tuple by {acceptRelayedCall}.
     *
     * Returns a value to be passed to {postRelayedCall}.
     *
     * {preRelayedCall} is called with 100k gas: if it runs out during exection or otherwise reverts, the relayed call
     * will not be executed, but the recipient will still be charged for the transaction's cost.
     */
    function preRelayedCall(bytes calldata context) external returns (bytes32);

    /**
     * @dev Called by {IRelayHub} on approved relay call requests, after the relayed call is executed. This allows to e.g.
     * charge the user for the relayed call costs, return any overcharges from {preRelayedCall}, or perform
     * contract-specific bookkeeping.
     *
     * `context` is the second value returned in the tuple by {acceptRelayedCall}. `success` is the execution status of
     * the relayed call. `actualCharge` is an estimate of how much the recipient will be charged for the transaction,
     * not including any gas used by {postRelayedCall} itself. `preRetVal` is {preRelayedCall}'s return value.
     *
     *
     * {postRelayedCall} is called with 100k gas: if it runs out during execution or otherwise reverts, the relayed call
     * and the call to {preRelayedCall} will be reverted retroactively, but the recipient will still be charged for the
     * transaction's cost.
     */
    function postRelayedCall(bytes calldata context, bool success, uint256 actualCharge, bytes32 preRetVal) external;
}

pragma solidity ^0.5.0;

/**
 * @title Roles
 * @dev Library for managing addresses assigned to a Role.
 */
library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

    /**
     * @dev Give an account access to this role.
     */
    function add(Role storage role, address account) internal {
        require(!has(role, account), "Roles: account already has role");
        role.bearer[account] = true;
    }

    /**
     * @dev Remove an account's access to this role.
     */
    function remove(Role storage role, address account) internal {
        require(has(role, account), "Roles: account does not have role");
        role.bearer[account] = false;
    }

    /**
     * @dev Check if an account has this role.
     * @return bool
     */
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0), "Roles: account is the zero address");
        return role.bearer[account];
    }
}

pragma solidity ^0.5.0;

import "../../GSN/Context.sol";
import "../Roles.sol";

/**
 * @title WhitelistAdminRole
 * @dev WhitelistAdmins are responsible for assigning and removing Whitelisted accounts.
 */
contract WhitelistAdminRole is Context {
    using Roles for Roles.Role;

    event WhitelistAdminAdded(address indexed account);
    event WhitelistAdminRemoved(address indexed account);

    Roles.Role private _whitelistAdmins;

    constructor () internal {
        _addWhitelistAdmin(_msgSender());
    }

    modifier onlyWhitelistAdmin() {
        require(isWhitelistAdmin(_msgSender()), "WhitelistAdminRole: caller does not have the WhitelistAdmin role");
        _;
    }

    function isWhitelistAdmin(address account) public view returns (bool) {
        return _whitelistAdmins.has(account);
    }

    function addWhitelistAdmin(address account) public onlyWhitelistAdmin {
        _addWhitelistAdmin(account);
    }

    function renounceWhitelistAdmin() public {
        _removeWhitelistAdmin(_msgSender());
    }

    function _addWhitelistAdmin(address account) internal {
        _whitelistAdmins.add(account);
        emit WhitelistAdminAdded(account);
    }

    function _removeWhitelistAdmin(address account) internal {
        _whitelistAdmins.remove(account);
        emit WhitelistAdminRemoved(account);
    }
}

pragma solidity ^0.5.0;

import "../../GSN/Context.sol";
import "../Roles.sol";
import "./WhitelistAdminRole.sol";

/**
 * @title WhitelistedRole
 * @dev Whitelisted accounts have been approved by a WhitelistAdmin to perform certain actions (e.g. participate in a
 * crowdsale). This role is special in that the only accounts that can add it are WhitelistAdmins (who can also remove
 * it), and not Whitelisteds themselves.
 */
contract WhitelistedRole is Context, WhitelistAdminRole {
    using Roles for Roles.Role;

    event WhitelistedAdded(address indexed account);
    event WhitelistedRemoved(address indexed account);

    Roles.Role private _whitelisteds;

    modifier onlyWhitelisted() {
        require(isWhitelisted(_msgSender()), "WhitelistedRole: caller does not have the Whitelisted role");
        _;
    }

    function isWhitelisted(address account) public view returns (bool) {
        return _whitelisteds.has(account);
    }

    function addWhitelisted(address account) public onlyWhitelistAdmin {
        _addWhitelisted(account);
    }

    function removeWhitelisted(address account) public onlyWhitelistAdmin {
        _removeWhitelisted(account);
    }

    function renounceWhitelisted() public {
        _removeWhitelisted(_msgSender());
    }

    function _addWhitelisted(address account) internal {
        _whitelisteds.add(account);
        emit WhitelistedAdded(account);
    }

    function _removeWhitelisted(address account) internal {
        _whitelisteds.remove(account);
        emit WhitelistedRemoved(account);
    }
}

pragma solidity ^0.5.0;

import "../GSN/Context.sol";
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        _owner = _msgSender();
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

pragma solidity ^0.5.0;

/**
 * @title IERC165
 * @dev https://github.com/ethereum/EIPs/blob/master/EIPS/eip-165.md
 */
interface IERC165 {
    /**
     * @notice Query if a contract implements an interface
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @dev Interface identification is specified in ERC-165. This function
     * uses less than 30,000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

pragma solidity ^0.5.0;

/**
 * @title SafeMath
 * @dev Unsigned math operations with safety checks that revert on error
 */
library SafeMath {
    /**
    * @dev Multiplies two unsigned integers, reverts on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    /**
    * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
    * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    /**
    * @dev Adds two unsigned integers, reverts on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    /**
    * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
    * reverts when dividing by zero.
    */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

pragma solidity ^0.5.0;

/**
 * Utility library of inline functions on addresses
 */
library Address {
    /**
     * Returns whether the target address is a contract
     * @dev This function will return false if invoked during the constructor of a contract,
     * as the code is not actually created until after the constructor finishes.
     * @param account address of the account to check
     * @return whether the target address is a contract
     */
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        // XXX Currently there is no better way to check if there is a contract in an address
        // than to check the size of the code at that address.
        // See https://ethereum.stackexchange.com/a/14016/36603
        // for more details about how this works.
        // TODO Check this again before the Serenity release, because all addresses will be
        // contracts then.
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}

