pragma solidity ^0.4.15;


contract Ownable {
    address public owner;

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    constructor() public {
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

/**
    @dev Defines the interface of a standard RCN cosigner.

    The cosigner is an agent that gives an insurance to the lender in the event of a defaulted loan, the confitions
    of the insurance and the cost of the given are defined by the cosigner. 

    The lender will decide what cosigner to use, if any; the address of the cosigner and the valid data provided by the
    agent should be passed as params when the lender calls the &quot;lend&quot; method on the engine.
    
    When the default conditions defined by the cosigner aligns with the status of the loan, the lender of the engine
    should be able to call the &quot;claim&quot; method to receive the benefit; the cosigner can define aditional requirements to
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
        the insurance it must call the method &quot;cosign&quot; of the engine. If the cosigner does not call that method, or
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
        @dev Returns the url where the oracle exposes a valid &quot;oracleData&quot; if needed
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
        emit NewSymbol(currency);
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

contract Token {
    function transfer(address _to, uint _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function allowance(address _owner, address _spender) public view returns (uint256 remaining);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function increaseApproval (address _spender, uint _addedValue) public returns (bool success);
    function balanceOf(address _owner) public view returns (uint256 balance);
}

contract BytesUtils {
    function readBytes32(bytes data, uint256 index) internal pure returns (bytes32 o) {
        require(data.length / 32 > index);
        assembly {
            o := mload(add(data, add(32, mul(32, index))))
        }
    }
}

/// @title ERC-721 Non-Fungible Token Standard
/// @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
///  Note: the ERC-165 identifier for this interface is 0x80ac58cd.
interface ERC721 /* is ERC165 */ {
    /// @dev This emits when ownership of any NFT changes by any mechanism.
    ///  This event emits when NFTs are created (`from` == 0) and destroyed
    ///  (`to` == 0). Exception: during contract creation, any number of NFTs
    ///  may be created and assigned without emitting Transfer. At the time of
    ///  any transfer, the approved address for that NFT (if any) is reset to none.
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);

    /// @dev This emits when the approved address for an NFT is changed or
    ///  reaffirmed. The zero address indicates there is no approved address.
    ///  When a Transfer event emits, this also indicates that the approved
    ///  address for that NFT (if any) is reset to none.
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);

    /// @dev This emits when an operator is enabled or disabled for an owner.
    ///  The operator can manage all NFTs of the owner.
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    /// @notice Count all NFTs assigned to an owner
    /// @dev NFTs assigned to the zero address are considered invalid, and this
    ///  function throws for queries about the zero address.
    /// @param _owner An address for whom to query the balance
    /// @return The number of NFTs owned by `_owner`, possibly zero
    function balanceOf(address _owner) external view returns (uint256);

    /// @notice Find the owner of an NFT
    /// @dev NFTs assigned to zero address are considered invalid, and queries
    ///  about them do throw.
    /// @param _tokenId The identifier for an NFT
    /// @return The address of the owner of the NFT
    function ownerOf(uint256 _tokenId) external view returns (address);

    /// @notice Transfers the ownership of an NFT from one address to another address
    /// @dev Throws unless `msg.sender` is the current owner, an authorized
    ///  operator, or the approved address for this NFT. Throws if `_from` is
    ///  not the current owner. Throws if `_to` is the zero address. Throws if
    ///  `_tokenId` is not a valid NFT. When transfer is complete, this function
    ///  checks if `_to` is a smart contract (code size > 0). If so, it calls
    ///  `onERC721Received` on `_to` and throws if the return value is not
    ///  `bytes4(keccak256(&quot;onERC721Received(address,address,uint256,bytes)&quot;))`.
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    /// @param data Additional data with no specified format, sent in call to `_to`
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes data) external payable;

    /// @notice Transfers the ownership of an NFT from one address to another address
    /// @dev This works identically to the other function with an extra data parameter,
    ///  except this function just sets data to &quot;&quot;.
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external payable;

    /// @notice Transfer ownership of an NFT -- THE CALLER IS RESPONSIBLE
    ///  TO CONFIRM THAT `_to` IS CAPABLE OF RECEIVING NFTS OR ELSE
    ///  THEY MAY BE PERMANENTLY LOST
    /// @dev Throws unless `msg.sender` is the current owner, an authorized
    ///  operator, or the approved address for this NFT. Throws if `_from` is
    ///  not the current owner. Throws if `_to` is the zero address. Throws if
    ///  `_tokenId` is not a valid NFT.
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    function transferFrom(address _from, address _to, uint256 _tokenId) external payable returns(bool);

    /// @notice Change or reaffirm the approved address for an NFT
    /// @dev The zero address indicates there is no approved address.
    ///  Throws unless `msg.sender` is the current NFT owner, or an authorized
    ///  operator of the current owner.
    /// @param _approved The new approved NFT controller
    /// @param _tokenId The NFT to approve
    function approve(address _approved, uint256 _tokenId) external payable returns(bool);

    /// @notice Enable or disable approval for a third party (&quot;operator&quot;) to manage
    ///  all of `msg.sender`&#39;s assets
    /// @dev Emits the ApprovalForAll event. The contract MUST allow
    ///  multiple operators per owner.
    /// @param _operator Address to add to the set of authorized operators
    /// @param _approved True if the operator is approved, false to revoke approval
    function setApprovalForAll(address _operator, bool _approved) external;

    /// @notice Get the approved address for a single NFT
    /// @dev Throws if `_tokenId` is not a valid NFT.
    /// @param _tokenId The NFT to find the approved address for
    /// @return The approved address for this NFT, or the zero address if there is none
    function getApproved(uint256 _tokenId) external view returns (address);

    /// @notice Query if an address is an authorized operator for another address
    /// @param _owner The address that owns the NFTs
    /// @param _operator The address that acts on behalf of the owner
    /// @return True if `_operator` is an approved operator for `_owner`, false otherwise
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}

interface IERC721Receiver {
    function onERC721Received(
        address _oldOwner,
        uint256 _tokenId,
        bytes   _userData
    ) external returns (bytes4);
}

library SafeMath {
    function add(uint256 x, uint256 y) internal pure returns(uint256) {
        uint256 z = x + y;
        require((z >= x) && (z >= y));
        return z;
    }

    function sub(uint256 x, uint256 y) internal pure returns(uint256) {
        require(x >= y);
        uint256 z = x - y;
        return z;
    }

    function mult(uint256 x, uint256 y) internal pure returns(uint256) {
        uint256 z = x * y;
        require((x == 0)||(z/x == y));
        return z;
    }
}

contract ERC721Base {
    using SafeMath for uint256;

    uint256 private _count;

    mapping(uint256 => address) private _holderOf;
    mapping(address => uint256[]) private _assetsOf;
    mapping(address => mapping(address => bool)) private _operators;
    mapping(uint256 => address) private _approval;
    mapping(uint256 => uint256) private _indexOfAsset;

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

    function assetsOf(address owner) external view returns (uint256[]) {
        return _assetsOf[owner];
    }

    /// @notice Enumerate NFTs assigned to an owner
    /// @dev Throws if `_index` >= `balanceOf(_owner)` or if
    ///  `_owner` is the zero address, representing invalid NFTs.
    /// @param _owner An address where we are interested in NFTs owned by them
    /// @param _index A counter less than `balanceOf(_owner)`
    /// @return The token identifier for the `_index`th NFT assigned to `_owner`,
    ///   (sort order not specified)
    function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256) {
        return _assetsOf[_owner][_index];
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
    function _isAuthorized(address operator, uint256 assetId) internal view returns (bool){
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
    function setApprovalForAll(address operator, bool authorized) external returns (bool) {
        return _setApprovalForAll(operator, authorized);
    }

    function _setApprovalForAll(address operator, bool authorized) internal returns (bool) {
        if (authorized) {
            require(!_isApprovedForAll(operator, msg.sender));
            _addAuthorization(operator, msg.sender);
        } else {
            require(_isApprovedForAll(operator, msg.sender));
            _clearAuthorization(operator, msg.sender);
        }
        emit ApprovalForAll(operator, msg.sender, authorized);
        return true;
    }

    function _addAuthorization(address operator, address holder) private {
        _operators[holder][operator] = true;
    }

    function _clearAuthorization(address operator, address holder) private {
        _operators[holder][operator] = false;
    }

    /**
     * @dev Authorize a third party operator to manage one particular asset
     * @param operator address to be approved
     * @param assetId asset to approve
     */
    function approve(address operator, uint256 assetId) external returns (bool) {
        address holder = _ownerOf(assetId);
        require(msg.sender == holder || _isApprovedForAll(msg.sender, holder));
        if (_getApprovedAddress(assetId) != operator) {
            _approval[assetId] = operator;
            emit Approval(holder, operator, assetId);
        }
        return true;
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
        require(_holderOf[assetId] == 0);

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
    function safeTransferFrom(address from, address to, uint256 assetId) external returns (bool) {
        return _doTransferFrom(from, to, assetId, &quot;&quot;, true);
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
    function safeTransferFrom(address from, address to, uint256 assetId, bytes userData) external returns (bool) {
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
    function transferFrom(address from, address to, uint256 assetId) external returns (bool) {
        return _doTransferFrom(from, to, assetId, &quot;&quot;, false);
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
        returns (bool)
    {
        _moveToken(from, to, assetId, userData, doCheck);
        return true;
    }

    function _moveToken(
        address from,
        address to,
        uint256 assetId,
        bytes userData,
        bool doCheck
    )
        isCurrentOwner(from, assetId)
        internal
    {
        address holder = _holderOf[assetId];
        _removeAssetFrom(holder, assetId);
        _clearApproval(holder, assetId);
        _addAssetTo(to, assetId);

        if (doCheck && _isContract(to)) {
            // Equals to bytes4(keccak256(&quot;onERC721Received(address,uint256,bytes)&quot;))
            bytes4 ERC721_RECEIVED = bytes4(0xf0b9e5ba);
            require(
                IERC721Receiver(to).onERC721Received(
                    holder, assetId, userData
                ) == ERC721_RECEIVED
            );
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
}


contract IBundle is ERC721Base {
    function content(uint256 id) external view returns (address[] tokens, uint256[] ids);
    function create() public returns (uint256 id);
    function depositBatch(uint256 _packageId, ERC721[] tokens, uint256[] ids) external returns (bool);
    function depositTokenBatch(uint256 _packageId, ERC721 token, uint256[] ids) external returns (bool);
    function deposit(uint256 _packageId, ERC721 token, uint256 tokenId) external returns (bool);
    function withdraw(uint256 packageId, ERC721 token, uint256 tokenId, address to) public returns (bool);
}

contract IPoach is ERC721Base {
    function getPair(uint poachId) public view returns(address, uint, bool);
    function create(Token token, uint256 amount) public payable returns (uint256 id);
    function destroy(uint256 id) public returns (bool);
}

contract NanoLoanEngine is Engine {
    function createLoan(address _oracleContract, address _borrower, bytes32 _currency, uint256 _amount, uint256 _interestRate,
        uint256 _interestRatePunitory, uint256 _duesIn, uint256 _cancelableAt, uint256 _expirationRequest, string _metadata) public returns (uint256);
    function registerApprove(bytes32 identifier, uint8 v, bytes32 r, bytes32 s) public returns (bool);
    function getAmount(uint index) public view returns (uint256);
    function getIdentifier(uint index) public view returns (bytes32);
    function identifierToIndex(bytes32 signature) public view returns (uint256);
}

/**
    @notice The contract is used to handle all the lifetime of a pawn. The borrower can

    Implements the Cosigner interface of RCN, and when is tied to a loan it creates a new ERC721
      to handle the ownership of the pawn.

    When the loan is resolved (paid, pardoned or defaulted), the pawn with his tokens can be recovered.
*/
contract PawnManager is Cosigner, ERC721Base, BytesUtils, Ownable {
    using SafeMath for uint256;

    address constant internal ETH = 0x00eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee;
    NanoLoanEngine nanoLoanEngine;
    IBundle bundle;
    IPoach poach;

    event NewPawn(address borrower, uint256 loanId, uint256 packageId, uint256 pawnId);
    event RequestedPawn(uint256 pawnId, address borrower, address engine, uint256 loanId, uint256 packageId);
    event StartedPawn(uint256 pawnId);
    event CanceledPawn(address from, address to, uint256 pawnId);
    event PaidPawn(address from, uint256 pawnId);
    event DefaultedPawn(uint256 pawnId);

    mapping(uint256 => uint256) pawnByPackageId; // Relates packageIds to pawnIds
    mapping(address => mapping(uint256 => uint256)) loanToLiability; // Relates engine address to loanId to pawnIds

    Pawn[] pawns;
    struct Pawn {
        address owner;
        Engine engine;
        uint256 loanId;
        uint256 packageId;
        Status status;
    }

    enum Status { Pending, Ongoing, Canceled, Paid, Defaulted }

    constructor(NanoLoanEngine _nanoLoanEngine, IBundle _bundle, IPoach _poach) public {
        nanoLoanEngine = _nanoLoanEngine;
        bundle = _bundle;
        poach = _poach;
        pawns.length++;
    }
    // Getters
    function getLiability(Engine engine, uint256 loanId) view public returns(uint256) { return loanToLiability[engine][loanId]; }
    function getPawnId(uint256 packageId) view public returns(uint256) { return pawnByPackageId[packageId]; }
    // Struct pawn getters
    function getPawnOwner(uint256 pawnId) view public returns(address) { return pawns[pawnId].owner; }
    function getPawnEngine(uint256 pawnId) view public returns(address) { return pawns[pawnId].engine; }
    function getPawnLoanId(uint256 pawnId) view public returns(uint256) { return pawns[pawnId].loanId; }
    function getPawnPackageId(uint256 pawnId) view public returns(uint256) { return pawns[pawnId].packageId; }
    function getPawnStatus(uint256 pawnId) view public returns(Status) { return pawns[pawnId].status; }

    /**
        @dev Creates a loan using an array of parameters

        @param _oracle  Oracle of loan
        @param _currency Currency of loan
        @param params 0 - Ammount
                      1 - Interest rate
                      2 - Interest rate punitory
                      3 - Dues in
                      4 - Cancelable at
                      5 - Expiration of request

        @param metadata Loan metadata

        @return Id of the loan

    */
    function createLoan(Oracle _oracle, bytes32 _currency, uint256[6] memory params, string metadata) internal returns (uint256) {
        return nanoLoanEngine.createLoan(
            _oracle,
            msg.sender,
            _currency,
            params[0],
            params[1],
            params[2],
            params[3],
            params[4],
            params[5],
            metadata
        );
    }

    /**
        @notice Request a loan and attachs a pawn request

        @dev Requires the loan signed by the borrower
            The length of _tokens and _amounts should be equal
             also length of _erc721s and _ids

        @param _oracle  Oracle of loan
        @param _currency Currency of loan
        @param loanParams   0 - Ammount
                            1 - Interest rate
                            2 - Interest rate punitory
                            3 - Dues in
                            4 - Cancelable at
                            5 - Expiration of request
        @param metadata Loan metadata
        @param v Loan signature by the borrower
        @param r Loan signature by the borrower
        @param s Loan signature by the borrower

        @param _tokens Array of ERC20 contract addresses
        @param _amounts Array of tokens amounts
        @param _erc721s Array of ERC721 contract addresses
        @param _ids Array of non fungible token ids

        @return pawnId The id of the pawn
        @return packageId The id of the package
    */
    function requestPawn(
        Oracle _oracle,
        bytes32 _currency,
        uint256[6] loanParams,
        string metadata,
        uint8 v,
        bytes32 r,
        bytes32 s,
        //ERC20
        Token[] _tokens,
        uint256[] _amounts,
        //ERC721
        ERC721[] _erc721s,
        uint256[] _ids
    ) public payable returns (uint256 pawnId, uint256 packageId) {
        uint256 loanId = createLoan(_oracle, _currency, loanParams, metadata);
        require(nanoLoanEngine.registerApprove(nanoLoanEngine.getIdentifier(loanId), v, r, s));

        (pawnId, packageId) = requestPawnId(nanoLoanEngine, loanId, _tokens, _amounts, _erc721s, _ids);

        emit NewPawn(msg.sender, loanId, packageId, pawnId);
    }
    /**
        @notice Requests a pawn with a loan identifier

        @dev The loan should exist in the designated engine
             The length of _tokens and _amounts should be equal
              also length of _erc721s and _ids

        @param engine RCN Engine
        @param loanIdentifier Identifier of the loan asociated with the pawn

        @param _tokens Array of ERC20 contract addresses
        @param _amounts Array of tokens amounts
        @param _erc721s Array of ERC721 contract addresses
        @param _ids Array of non fungible token ids

        @return pawnId The id of the pawn
        @return packageId The id of the package
    */
    function requestPawnWithLoanIdentifier(
        NanoLoanEngine engine,
        bytes32 loanIdentifier,
        Token[] _tokens,
        uint256[] _amounts,
        ERC721[] _erc721s,
        uint256[] _ids
    ) public payable returns (uint256 pawnId, uint256 packageId) {
        return requestPawnId(engine, engine.identifierToIndex(loanIdentifier), _tokens, _amounts, _erc721s, _ids);
    }
    /**
        @notice Request a pawn to buy a new loan

        @dev The loan should exist in the designated engine
             The length of _tokens and _amounts should be equal
              also length of _erc721s and _ids

        @param engine RCN Engine
        @param loanId Id of the loan asociated with the pawn

        @param _tokens Array of ERC20 contract addresses
        @param _amounts Array of tokens amounts
        @param _erc721s Array of ERC721 contract addresses
        @param _ids Array of non fungible token ids

        @return pawnId The id of the pawn
        @return packageId The id of the package
    */
    function requestPawnId(
        Engine engine,
        uint256 loanId,
        Token[] _tokens,
        uint256[] _amounts,
        ERC721[] _erc721s,
        uint256[] _ids
    ) public payable returns (uint256 pawnId, uint256 packageId) {
        // Validate the associated loan
        address borrower = engine.getBorrower(loanId);
        require(engine.getStatus(loanId) == Engine.Status.initial);
        require(msg.sender == borrower || msg.sender == engine.getCreator(loanId));
        require(engine.isApproved(loanId));
        require(loanToLiability[engine][loanId] == 0);

        packageId = createPackage(_tokens, _amounts, _erc721s, _ids);

        // Create the liability
        pawnId = pawns.push(Pawn({
            owner:     borrower,
            engine:    engine,
            loanId:    loanId,
            packageId: packageId,
            status:    Status.Pending
        })) - 1;

        loanToLiability[engine][loanId] = pawnId;

        emit RequestedPawn({
            pawnId:    pawnId,
            borrower:  borrower,
            engine:    engine,
            loanId:    loanId,
            packageId: packageId
        });
    }
    /**
        @notice Create a package
        @dev The length of _tokens and _amounts should be equal also
              length of _erc721s and _ids
              The sum of the all amounts of ether should be send

        @param _tokens Array of ERC20 contract addresses
        @param _amounts Array of tokens amounts
        @param _erc721s Array of ERC721 contract addresses
        @param _ids Array of non fungible token ids

        @return the index of package on array of bundle contract
    */
    function createPackage(
        Token[] _tokens,
        uint256[] _amounts,
        ERC721[] _erc721s,
        uint256[] _ids
    ) internal returns(uint256 packageId){
        uint256 tokensLength = _tokens.length;
        uint256 erc721sLength = _erc721s.length;
        require(tokensLength == _amounts.length && erc721sLength == _ids.length);

        packageId = bundle.create();
        uint256 i = 0;
        uint256 poachId;
        uint256 totEth;

        for(; i < tokensLength; i++){
            if (address(_tokens[i]) != ETH) {
                require(_tokens[i].transferFrom(msg.sender, this, _amounts[i]));
                require(_tokens[i].approve(poach, _amounts[i]));
                poachId = poach.create(_tokens[i], _amounts[i]);
            } else {
                poachId = poach.create.value(_amounts[i])(_tokens[i], _amounts[i]);
                totEth = totEth.add(_amounts[i]);
            }

            require(poach.approve(bundle, poachId));
            bundle.deposit(packageId, ERC721(poach), poachId);
        }
        require(totEth == msg.value);

        for(i = 0; i < erc721sLength; i++){
            require(_erc721s[i].transferFrom(msg.sender, this, _ids[i]));
            require(_erc721s[i].approve(bundle, _ids[i]));
        }
        bundle.depositBatch(packageId, _erc721s, _ids);
    }
    /**
        @notice Cancels an existing pawn and withdraw all tokens
        @dev The pawn status should be pending

        @param _pawnId Id of the pawn
        @param _to The new owner
        @param _asBundle If true only transfer the package, if false transfer all tokens

        @return true If the operation was executed
    */
    function cancelPawn(uint256 _pawnId, address _to, bool _asBundle) public returns (bool) {
        Pawn storage pawn = pawns[_pawnId];

        // Only the owner of the pawn and if the pawn is pending
        require(msg.sender == pawn.owner, &quot;Only the owner can cancel the pawn&quot;);
        require(pawn.status == Status.Pending, &quot;The pawn is not pending&quot;);

        pawn.status = Status.Canceled;

        _transferAsset(pawn.packageId, _to, _asBundle);

        emit CanceledPawn(msg.sender, _to, _pawnId);
        return true;
    }

    /**
        @dev Use to claim eth to the poach
    */
    function () external payable {
        require(msg.sender == address(poach));
    }

    //
    // Implements cosigner
    //
    uint256 private constant I_PAWN_ID = 0;

    /**
        @notice Returns the cost of the cosigner

        This cosigner does not have any risk or maintenance cost, so its free.

        @return 0, because it&#39;s free
    */
    function cost(address , uint256 , bytes , bytes ) public view returns (uint256) {
        return 0;
    }
    /**
        @notice Request the cosign of a loan

        Emits an ERC721 to manage the ownership of the pawn property.

        @param _engine Engine of the loan
        @param _index Index of the loan
        @param _data Data with the pawn id

        @return True if the cosign was performed
    */
    function requestCosign(Engine _engine, uint256 _index, bytes _data, bytes ) public returns (bool) {
        require(msg.sender == address(_engine), &quot;the sender its not the Engine&quot;);
        uint256 pawnId = uint256(readBytes32(_data, I_PAWN_ID));
        Pawn storage pawn = pawns[pawnId];

        // Validate that the loan matches with the pawn
        // and the pawn is still pending
        require(pawn.engine == _engine, &quot;Engine does not match&quot;);
        require(pawn.loanId == _index, &quot;Loan id does not match&quot;);
        require(pawn.status == Status.Pending, &quot;Pawn is not pending&quot;);

        pawn.status = Status.Ongoing;

        // Mint pawn ERC721 Token
        _generate(pawnId, pawn.owner);

        // Cosign contract
        require(_engine.cosign(_index, 0), &quot;Error performing cosign&quot;);

        // Save pawn id registry
        pawnByPackageId[pawn.packageId] = pawnId;

        // Emit pawn event
        emit StartedPawn(pawnId);

        return true;
    }

    function url() public view returns (string) {
        return &quot;&quot;;
    }

    /**
        @notice Defines a custom logic that determines if a loan is defaulted or not.

        @param _engine RCN Engines
        @param _index Index of the loan

        @return true if the loan is considered defaulted
    */
    function isDefaulted(Engine _engine, uint256 _index) public view returns (bool) {
        return _engine.getStatus(_index) == Engine.Status.lent && _engine.getDueTime(_index) <= now;
    }

    /**
        @notice Claims the pawn when the loan status is resolved and transfers the ownership of the package to which corresponds.

        @dev Deletes the pawn ERC721

        @param _engine RCN Engine
        @param _loanId Loan ID

        @return true If the claim succeded
    */
    function claim(address _engine, uint256 _loanId, bytes ) public returns (bool) {
        return _claim(_engine, _loanId, true);
    }

    /**
        @notice Claims the pawn when the loan status is resolved and transfer all tokens to which corresponds.

        @dev Deletes the pawn ERC721

        @param _engine RCN Engine
        @param _loanId Loan ID

        @return true If the claim succeded
    */
    function claimWithdraw(address _engine, uint256 _loanId) public returns (bool) {
        return _claim(_engine, _loanId, false);
    }

    /**
        @notice Claims the pawn when the loan status is resolved and transfer all tokens to which corresponds.

        @dev Deletes the pawn ERC721

        @param _engine RCN Engine
        @param _loanId Loan ID
        @param _asBundle If true only transfer the package, if false transfer all tokens

        @return true If the claim succeded
    */
    function _claim(address _engine, uint256 _loanId, bool _asBundle) internal returns(bool){
        uint256 pawnId = loanToLiability[_engine][_loanId];
        Pawn storage pawn = pawns[pawnId];
        // Validate that the pawn wasn&#39;t claimed
        require(pawn.status == Status.Ongoing, &quot;Pawn not ongoing&quot;);
        require(pawn.loanId == _loanId, &quot;Pawn don&#39;t match loan id&quot;);

        if (pawn.engine.getStatus(_loanId) == Engine.Status.paid || pawn.engine.getStatus(_loanId) == Engine.Status.destroyed) {
            // The pawn is paid
            require(_isAuthorized(msg.sender, pawnId), &quot;Sender not authorized&quot;);

            pawn.status = Status.Paid;

            _transferAsset(pawn.packageId, msg.sender, _asBundle);

            emit PaidPawn(msg.sender, pawnId);
        } else {
            if (isDefaulted(pawn.engine, _loanId)) {
                // The pawn is defaulted
                require(msg.sender == pawn.engine.ownerOf(_loanId), &quot;Sender not lender&quot;);

                pawn.status = Status.Defaulted;

                _transferAsset(pawn.packageId, msg.sender, _asBundle);

                emit DefaultedPawn(pawnId);
            } else {
                revert(&quot;Pawn not defaulted/paid&quot;);
            }
        }

        // ERC721 Delete asset
        _destroy(pawnId);

        // Delete pawn id registry
        delete pawnByPackageId[pawn.packageId];

        return true;
    }

    function _transferAsset(uint _packageId, address _to, bool _asBundle) internal returns(bool){
        if (_asBundle) {
            // Transfer the package back to the _to
            require(bundle.safeTransferFrom(this, _to, _packageId));
        } else {
            // Transfer all tokens to the _to
            require(_withdrawAll(_packageId, _to));
        }

        return true;
    }

    /**
        @notice Transfer all the ERC721 and ERC20 of an package back to the beneficiary

        @dev If the currency its ether and the destiny its a contract, execute the payable deposit()

        @param _packageId Id of the pawn
        @param _beneficiary Beneficiary of tokens

        @return true If the operation was executed
    */
    function _withdrawAll(uint256 _packageId, address _beneficiary) internal returns(bool){
        address[] memory tokens;
        uint256[] memory ids;
        (tokens, ids) = bundle.content(_packageId);
        uint256 tokensLength = tokens.length;
        // for ERC20 tokens
        address addr;
        uint256 amount;

        for (uint i = 0; i < tokensLength; i++) {
            if (tokens[i] != address(poach)){
                // for a ERC721 token
                bundle.withdraw(_packageId, ERC721(tokens[i]), ids[i], _beneficiary);
            } else { // for a ERC20 token
                bundle.withdraw(_packageId, ERC721(tokens[i]), ids[i], address(this));
                (addr, amount,) = poach.getPair(ids[i]);
                require(poach.destroy(ids[i]), &quot;Fail destroy&quot;);
                if (addr != ETH)
                    require(Token(addr).transfer(_beneficiary, amount));
                else
                    _beneficiary.transfer(amount);
            }
        }
        return true;
    }
}