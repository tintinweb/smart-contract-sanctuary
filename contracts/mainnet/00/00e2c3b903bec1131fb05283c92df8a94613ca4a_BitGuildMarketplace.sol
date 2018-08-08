pragma solidity ^0.4.22;


contract tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public; }

contract BitGuildToken {
    // Public variables of the token
    string public name = "BitGuild PLAT";
    string public symbol = "PLAT";
    uint8 public decimals = 18;
    uint256 public totalSupply = 10000000000 * 10 ** uint256(decimals); // 10 billion tokens;

    // This creates an array with all balances
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    // This generates a public event on the blockchain that will notify clients
    event Transfer(address indexed from, address indexed to, uint256 value);

    // This notifies clients about the amount burnt
    event Burn(address indexed from, uint256 value);

    /**
     * Constructor function
     * Initializes contract with initial supply tokens to the creator of the contract
     */
    function BitGuildToken() public {
        balanceOf[msg.sender] = totalSupply;
    }

    /**
     * Internal transfer, only can be called by this contract
     */
    function _transfer(address _from, address _to, uint _value) internal {
        // Prevent transfer to 0x0 address. Use burn() instead
        require(_to != 0x0);
        // Check if the sender has enough
        require(balanceOf[_from] >= _value);
        // Check for overflows
        require(balanceOf[_to] + _value > balanceOf[_to]);
        // Save this for an assertion in the future
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
        // Subtract from the sender
        balanceOf[_from] -= _value;
        // Add the same to the recipient
        balanceOf[_to] += _value;
        Transfer(_from, _to, _value);
        // Asserts are used to use static analysis to find bugs in your code. They should never fail
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

    /**
     * Transfer tokens
     *
     * Send `_value` tokens to `_to` from your account
     *
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transfer(address _to, uint256 _value) public {
        _transfer(msg.sender, _to, _value);
    }

    /**
     * Transfer tokens from other address
     *
     * Send `_value` tokens to `_to` on behalf of `_from`
     *
     * @param _from The address of the sender
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);     // Check allowance
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    /**
     * Set allowance for other address
     *
     * Allows `_spender` to spend no more than `_value` tokens on your behalf
     *
     * @param _spender The address authorized to spend
     * @param _value the max amount they can spend
     */
    function approve(address _spender, uint256 _value) public
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }

    /**
     * Set allowance for other address and notify
     *
     * Allows `_spender` to spend no more than `_value` tokens on your behalf, and then ping the contract about it
     *
     * @param _spender The address authorized to spend
     * @param _value the max amount they can spend
     * @param _extraData some extra information to send to the approved contract
     */
    function approveAndCall(address _spender, uint256 _value, bytes _extraData)
        public
        returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }

    /**
     * Destroy tokens
     *
     * Remove `_value` tokens from the system irreversibly
     *
     * @param _value the amount of money to burn
     */
    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);   // Check if the sender has enough
        balanceOf[msg.sender] -= _value;            // Subtract from the sender
        totalSupply -= _value;                      // Updates totalSupply
        Burn(msg.sender, _value);
        return true;
    }

    /**
     * Destroy tokens from other account
     *
     * Remove `_value` tokens from the system irreversibly on behalf of `_from`.
     *
     * @param _from the address of the sender
     * @param _value the amount of money to burn
     */
    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balanceOf[_from] >= _value);                // Check if the targeted balance is enough
        require(_value <= allowance[_from][msg.sender]);    // Check allowance
        balanceOf[_from] -= _value;                         // Subtract from the targeted balance
        allowance[_from][msg.sender] -= _value;             // Subtract from the sender&#39;s allowance
        totalSupply -= _value;                              // Update totalSupply
        Burn(_from, _value);
        return true;
    }
}


/**
 * @title BitGuildAccessAdmin
 * @dev Allow two roles: &#39;owner&#39; or &#39;operator&#39;
 *      - owner: admin/superuser (e.g. with financial rights)
 *      - operator: can update configurations
 */
contract BitGuildAccessAdmin {
    address public owner;
    address[] public operators;

    uint public MAX_OPS = 20; // Default maximum number of operators allowed

    mapping(address => bool) public isOperator;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
    event OperatorAdded(address operator);
    event OperatorRemoved(address operator);

    // @dev The BitGuildAccessAdmin constructor: sets owner to the sender account
    constructor() public {
        owner = msg.sender;
    }

    // @dev Throws if called by any account other than the owner.
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    // @dev Throws if called by any non-operator account. Owner has all ops rights.
    modifier onlyOperator() {
        require(
            isOperator[msg.sender] || msg.sender == owner,
            "Permission denied. Must be an operator or the owner."
        );
        _;
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param _newOwner The address to transfer ownership to.
     */
    function transferOwnership(address _newOwner) public onlyOwner {
        require(
            _newOwner != address(0),
            "Invalid new owner address."
        );
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }

    /**
     * @dev Allows the current owner or operators to add operators
     * @param _newOperator New operator address
     */
    function addOperator(address _newOperator) public onlyOwner {
        require(
            _newOperator != address(0),
            "Invalid new operator address."
        );

        // Make sure no dups
        require(
            !isOperator[_newOperator],
            "New operator exists."
        );

        // Only allow so many ops
        require(
            operators.length < MAX_OPS,
            "Overflow."
        );

        operators.push(_newOperator);
        isOperator[_newOperator] = true;

        emit OperatorAdded(_newOperator);
    }

    /**
     * @dev Allows the current owner or operators to remove operator
     * @param _operator Address of the operator to be removed
     */
    function removeOperator(address _operator) public onlyOwner {
        // Make sure operators array is not empty
        require(
            operators.length > 0,
            "No operator."
        );

        // Make sure the operator exists
        require(
            isOperator[_operator],
            "Not an operator."
        );

        // Manual array manipulation:
        // - replace the _operator with last operator in array
        // - remove the last item from array
        address lastOperator = operators[operators.length - 1];
        for (uint i = 0; i < operators.length; i++) {
            if (operators[i] == _operator) {
                operators[i] = lastOperator;
            }
        }
        operators.length -= 1; // remove the last element

        isOperator[_operator] = false;
        emit OperatorRemoved(_operator);
    }

    // @dev Remove ALL operators
    function removeAllOps() public onlyOwner {
        for (uint i = 0; i < operators.length; i++) {
            isOperator[operators[i]] = false;
        }
        operators.length = 0;
    }
}


/**
 * @title BitGuildWhitelist
 * @dev A small smart contract to provide whitelist functionality and storage
 */
contract BitGuildWhitelist is BitGuildAccessAdmin {
    uint public total = 0;
    mapping (address => bool) public isWhitelisted;

    event AddressWhitelisted(address indexed addr, address operator);
    event AddressRemovedFromWhitelist(address indexed addr, address operator);

    // @dev Throws if _address is not in whitelist.
    modifier onlyWhitelisted(address _address) {
        require(
            isWhitelisted[_address],
            "Address is not on the whitelist."
        );
        _;
    }

    // Doesn&#39;t accept eth
    function () external payable {
        revert();
    }

    /**
     * @dev Allow operators to add whitelisted contracts
     * @param _newAddr New whitelisted contract address
     */
    function addToWhitelist(address _newAddr) public onlyOperator {
        require(
            _newAddr != address(0),
            "Invalid new address."
        );

        // Make sure no dups
        require(
            !isWhitelisted[_newAddr],
            "Address is already whitelisted."
        );

        isWhitelisted[_newAddr] = true;
        total++;
        emit AddressWhitelisted(_newAddr, msg.sender);
    }

    /**
     * @dev Allow operators to remove a contract from the whitelist
     * @param _addr Contract address to be removed
     */
    function removeFromWhitelist(address _addr) public onlyOperator {
        require(
            _addr != address(0),
            "Invalid address."
        );

        // Make sure the address is in whitelist
        require(
            isWhitelisted[_addr],
            "Address not in whitelist."
        );

        isWhitelisted[_addr] = false;
        if (total > 0) {
            total--;
        }
        emit AddressRemovedFromWhitelist(_addr, msg.sender);
    }

    /**
     * @dev Allow operators to update whitelist contracts in bulk
     * @param _addresses Array of addresses to be processed
     * @param _whitelisted Boolean value -- to add or remove from whitelist
     */
    function whitelistAddresses(address[] _addresses, bool _whitelisted) public onlyOperator {
        for (uint i = 0; i < _addresses.length; i++) {
            address addr = _addresses[i];
            if (isWhitelisted[addr] == _whitelisted) continue;
            if (_whitelisted) {
                addToWhitelist(addr);
            } else {
                removeFromWhitelist(addr);
            }
        }
    }
}

/**
 * @title BitGuildFeeProvider
 * @dev Fee definition, supports custom fees by seller or buyer or token combinations
 */
contract BitGuildFeeProvider is BitGuildAccessAdmin {
    // @dev Since default uint value is zero, need to distinguish Default vs No Fee
    uint constant NO_FEE = 10000;

    // @dev default % fee. Fixed is not supported. use percent * 100 to include 2 decimals
    uint defaultPercentFee = 500; // default fee: 5%

    mapping(bytes32 => uint) public customFee;  // Allow buyer or seller or game discounts

    event LogFeeChanged(uint newPercentFee, uint oldPercentFee, address operator);
    event LogCustomFeeChanged(uint newPercentFee, uint oldPercentFee, address buyer, address seller, address token, address operator);

    // Default
    function () external payable {
        revert();
    }

    /**
     * @dev Allow operators to update the fee for a custom combo
     * @param _newFee New fee in percent x 100 (to support decimals)
     */
    function updateFee(uint _newFee) public onlyOperator {
        require(_newFee >= 0 && _newFee <= 10000, "Invalid percent fee.");

        uint oldPercentFee = defaultPercentFee;
        defaultPercentFee = _newFee;

        emit LogFeeChanged(_newFee, oldPercentFee, msg.sender);
    }

    /**
     * @dev Allow operators to update the fee for a custom combo
     * @param _newFee New fee in percent x 100 (to support decimals)
     *                enter zero for default, 10000 for No Fee
     */
    function updateCustomFee(uint _newFee, address _currency, address _buyer, address _seller, address _token) public onlyOperator {
        require(_newFee >= 0 && _newFee <= 10000, "Invalid percent fee.");

        bytes32 key = _getHash(_currency, _buyer, _seller, _token);
        uint oldPercentFee = customFee[key];
        customFee[key] = _newFee;

        emit LogCustomFeeChanged(_newFee, oldPercentFee, _buyer, _seller, _token, msg.sender);
    }

    /**
     * @dev Calculate the custom fee based on buyer, seller, game token or combo of these
     */
    function getFee(uint _price, address _currency, address _buyer, address _seller, address _token) public view returns(uint percent, uint fee) {
        bytes32 key = _getHash(_currency, _buyer, _seller, _token);
        uint customPercentFee = customFee[key];
        (percent, fee) = _getFee(_price, customPercentFee);
    }

    function _getFee(uint _price, uint _percentFee) internal view returns(uint percent, uint fee) {
        require(_price >= 0, "Invalid price.");

        percent = _percentFee;

        // No data, set it to default
        if (_percentFee == 0) {
            percent = defaultPercentFee;
        }

        // Special value to set it to zero
        if (_percentFee == NO_FEE) {
            percent = 0;
            fee = 0;
        } else {
            fee = _safeMul(_price, percent) / 10000; // adjust for percent and decimal. division always truncate
        }
    }

    // get custom fee hash
    function _getHash(address _currency, address _buyer, address _seller, address _token) internal pure returns(bytes32 key) {
        key = keccak256(abi.encodePacked(_currency, _buyer, _seller, _token));
    }

    // safe multiplication
    function _safeMul(uint a, uint b) internal pure returns (uint) {
        if (a == 0) {
            return 0;
        }
        uint c = a * b;
        assert(c / a == b);
        return c;
    }
}

pragma solidity ^0.4.24;

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
    ///  `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    /// @param data Additional data with no specified format, sent in call to `_to`
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes data) external;

    /// @notice Transfers the ownership of an NFT from one address to another address
    /// @dev This works identically to the other function with an extra data parameter,
    ///  except this function just sets data to "".
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external;

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
    function transferFrom(address _from, address _to, uint256 _tokenId) external;

    /// @notice Change or reaffirm the approved address for an NFT
    /// @dev The zero address indicates there is no approved address.
    ///  Throws unless `msg.sender` is the current NFT owner, or an authorized
    ///  operator of the current owner.
    /// @param _approved The new approved NFT controller
    /// @param _tokenId The NFT to approve
    function approve(address _approved, uint256 _tokenId) external;

    /// @notice Enable or disable approval for a third party ("operator") to manage
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

// @title ERC-721 Non-Fungible Token Standard
// @dev Include interface for both new and old functions
interface ERC721TokenReceiver {
	function onERC721Received(address _from, uint256 _tokenId, bytes data) external returns(bytes4);
	function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes data) external returns(bytes4);
}

/*
 * @title BitGuildMarketplace
 * @dev: Marketplace smart contract for BitGuild.com
 */
contract BitGuildMarketplace is BitGuildAccessAdmin {
    // Callback values from zepellin ERC721Receiver.sol
    // Old ver: bytes4(keccak256("onERC721Received(address,uint256,bytes)")) = 0xf0b9e5ba;
    bytes4 constant ERC721_RECEIVED_OLD = 0xf0b9e5ba;
    // New ver w/ operator: bytes4(keccak256("onERC721Received(address,address,uint256,bytes)")) = 0xf0b9e5ba;
    bytes4 constant ERC721_RECEIVED = 0x150b7a02;

    // BitGuild Contracts
    BitGuildToken public PLAT = BitGuildToken(0x7E43581b19ab509BCF9397a2eFd1ab10233f27dE); // Main Net
    BitGuildWhitelist public Whitelist = BitGuildWhitelist(0xA8CedD578fed14f07C3737bF42AD6f04FAAE3978); // Main Net
    BitGuildFeeProvider public FeeProvider = BitGuildFeeProvider(0x58D36571250D91eF5CE90869E66Cd553785364a2); // Main Net
    // BitGuildToken public PLAT = BitGuildToken(0x0F2698b7605fE937933538387b3d6Fec9211477d); // Rinkeby
    // BitGuildWhitelist public Whitelist = BitGuildWhitelist(0x72b93A4943eF4f658648e27D64e9e3B8cDF520a6); // Rinkeby
    // BitGuildFeeProvider public FeeProvider = BitGuildFeeProvider(0xf7AB04A47AA9F3c8Cb7FDD701CF6DC6F2eB330E2); // Rinkeby

    uint public defaultExpiry = 7 days;  // default expiry is 7 days

    enum Currency { PLAT, ETH }
    struct Listing {
        Currency currency;      // ETH or PLAT
        address seller;         // seller address
        address token;          // token contract
        uint tokenId;           // token id
        uint price;             // Big number in ETH or PLAT
        uint createdAt;         // timestamp
        uint expiry;            // createdAt + defaultExpiry
    }

    mapping(bytes32 => Listing) public listings;

    event LogListingCreated(address _seller, address _contract, uint _tokenId, uint _createdAt, uint _expiry);
    event LogListingExtended(address _seller, address _contract, uint _tokenId, uint _createdAt, uint _expiry);
    event LogItemSold(address _buyer, address _seller, address _contract, uint _tokenId, uint _price, Currency _currency, uint _soldAt);
    event LogItemWithdrawn(address _seller, address _contract, uint _tokenId, uint _withdrawnAt);
    event LogItemExtended(address _contract, uint _tokenId, uint _modifiedAt, uint _expiry);

    modifier onlyWhitelisted(address _contract) {
        require(Whitelist.isWhitelisted(_contract), "Contract not in whitelist.");
        _;
    }

    // @dev fall back function
    function () external payable {
        revert();
    }

    // @dev Retrieve hashkey to view listing
    function getHashKey(address _contract, uint _tokenId) public pure returns(bytes32 key) {
        key = _getHashKey(_contract, _tokenId);
    }

    // ===========================================
    // Fee functions (from fee provider contract)
    // ===========================================
    // @dev get fees
    function getFee(uint _price, address _currency, address _buyer, address _seller, address _token) public view returns(uint percent, uint fee) {
        (percent, fee) = FeeProvider.getFee(_price, _currency, _buyer, _seller, _token);
    }

    // ===========================================
    // Seller Functions
    // ===========================================
    // Deposit Item
    // @dev deprecated callback (did not handle operator). added to support older contracts
    function onERC721Received(address _from, uint _tokenId, bytes _extraData) external returns(bytes4) {
        _deposit(_from, msg.sender, _tokenId, _extraData);
        return ERC721_RECEIVED_OLD;
    }

    // @dev expected callback (include operator)
    function onERC721Received(address _operator, address _from, uint _tokenId, bytes _extraData) external returns(bytes4) {
        _deposit(_from, msg.sender, _tokenId, _extraData);
        return ERC721_RECEIVED;
    }

    // @dev Extend item listing: new expiry = current expiry + defaultExpiry
    // @param _contract whitelisted contract
    // @param _tokenId  tokenId
    function extendItem(address _contract, uint _tokenId) public onlyWhitelisted(_contract) returns(bool) {
        bytes32 key = _getHashKey(_contract, _tokenId);
        address seller = listings[key].seller;

        require(seller == msg.sender, "Only seller can extend listing.");
        require(listings[key].expiry > 0, "Item not listed.");

        listings[key].expiry = now + defaultExpiry;

        emit LogListingExtended(seller, _contract, _tokenId, listings[key].createdAt, listings[key].expiry);

        return true;
    }

    // @dev Withdraw item from marketplace back to seller
    // @param _contract whitelisted contract
    // @param _tokenId  tokenId
    function withdrawItem(address _contract, uint _tokenId) public onlyWhitelisted(_contract) {
        bytes32 key = _getHashKey(_contract, _tokenId);
        address seller = listings[key].seller;

        require(seller == msg.sender, "Only seller can withdraw listing.");

        // Transfer item back to the seller
        ERC721 gameToken = ERC721(_contract);
        gameToken.safeTransferFrom(this, seller, _tokenId);

        emit LogItemWithdrawn(seller, _contract, _tokenId, now);

        // remove listing
        delete(listings[key]);
    }

    // ===========================================
    // Purchase Item
    // ===========================================
    // @dev Buy item with ETH. Take ETH from buyer, transfer token, transfer payment minus fee to seller
    // @param _token  Token contract
    // @param _tokenId   Token Id
    function buyWithETH(address _token, uint _tokenId) public onlyWhitelisted(_token) payable {
        _buy(_token, _tokenId, Currency.ETH, msg.value, msg.sender);
    }

    // Buy with PLAT requires calling BitGuildToken contract, this is the callback
    // call to approve already verified the token ownership, no checks required
    // @param _buyer     buyer
    // @param _value     PLAT amount (big number)
    // @param _PLAT      BitGuild token address
    // @param _extraData address _gameContract, uint _tokenId
    function receiveApproval(address _buyer, uint _value, BitGuildToken _PLAT, bytes _extraData) public {
        require(_extraData.length > 0, "No extraData provided.");
        // We check msg.sender with our known PLAT address instead of the _PLAT param
        require(msg.sender == address(PLAT), "Unauthorized PLAT contract address.");

        address token;
        uint tokenId;
        (token, tokenId) = _decodeBuyData(_extraData);

        _buy(token, tokenId, Currency.PLAT, _value, _buyer);
    }

    // ===========================================
    // Admin Functions
    // ===========================================
    // @dev Update fee provider contract
    function updateFeeProvider(address _newAddr) public onlyOperator {
        require(_newAddr != address(0), "Invalid contract address.");
        FeeProvider = BitGuildFeeProvider(_newAddr);
    }

    // @dev Update whitelist contract
    function updateWhitelist(address _newAddr) public onlyOperator {
        require(_newAddr != address(0), "Invalid contract address.");
        Whitelist = BitGuildWhitelist(_newAddr);
    }

    // @dev Update expiry date
    function updateExpiry(uint _days) public onlyOperator {
        require(_days > 0, "Invalid number of days.");
        defaultExpiry = _days * 1 days;
    }

    // @dev Admin function: withdraw ETH balance
    function withdrawETH() public onlyOwner payable {
        msg.sender.transfer(msg.value);
    }

    // @dev Admin function: withdraw PLAT balance
    function withdrawPLAT() public onlyOwner payable {
        uint balance = PLAT.balanceOf(this);
        PLAT.transfer(msg.sender, balance);
    }

    // ===========================================
    // Internal Functions
    // ===========================================
    function _getHashKey(address _contract, uint _tokenId) internal pure returns(bytes32 key) {
        key = keccak256(abi.encodePacked(_contract, _tokenId));
    }

    // @dev create new listing data
    function _newListing(address _seller, address _contract, uint _tokenId, uint _price, Currency _currency) internal {
        bytes32 key = _getHashKey(_contract, _tokenId);
        uint createdAt = now;
        uint expiry = now + defaultExpiry;
        listings[key].currency = _currency;
        listings[key].seller = _seller;
        listings[key].token = _contract;
        listings[key].tokenId = _tokenId;
        listings[key].price = _price;
        listings[key].createdAt = createdAt;
        listings[key].expiry = expiry;

        emit LogListingCreated(_seller, _contract, _tokenId, createdAt, expiry);
    }

    // @dev deposit unpacks _extraData and log listing info
    // @param _extraData packed bytes of (uint _price, uint _currency)
    function _deposit(address _seller, address _contract, uint _tokenId, bytes _extraData) internal onlyWhitelisted(_contract) {
        uint price;
        uint currencyUint;
        (currencyUint, price) = _decodePriceData(_extraData);
        Currency currency = Currency(currencyUint);

        require(price > 0, "Invalid price.");

        _newListing(_seller, _contract, _tokenId, price, currency);
    }

    // @dev handles purchase logic for both PLAT and ETH
    function _buy(address _token, uint _tokenId, Currency _currency, uint _price, address _buyer) internal {
        bytes32 key = _getHashKey(_token, _tokenId);
        Currency currency = listings[key].currency;
        address seller = listings[key].seller;

        address currencyAddress = _currency == Currency.PLAT ? address(PLAT) : address(0);

        require(currency == _currency, "Wrong currency.");
        require(_price > 0 && _price == listings[key].price, "Invalid price.");
        require(listings[key].expiry > now, "Item expired.");

        ERC721 gameToken = ERC721(_token);
        require(gameToken.ownerOf(_tokenId) == address(this), "Item is not available.");

        if (_currency == Currency.PLAT) {
            // Transfer PLAT to marketplace contract
            require(PLAT.transferFrom(_buyer, address(this), _price), "PLAT payment transfer failed.");
        }

        // Transfer item token to buyer
        gameToken.safeTransferFrom(this, _buyer, _tokenId);

        uint fee;
        (,fee) = getFee(_price, currencyAddress, _buyer, seller, _token); // getFee returns percentFee and fee, we only need fee

        if (_currency == Currency.PLAT) {
            PLAT.transfer(seller, _price - fee);
        } else {
            require(seller.send(_price - fee) == true, "Transfer to seller failed.");
        }

        // Emit event
        emit LogItemSold(_buyer, seller, _token, _tokenId, _price, currency, now);

        // delist item
        delete(listings[key]);
    }

    function _decodePriceData(bytes _extraData) internal pure returns(uint _currency, uint _price) {
        // Deserialize _extraData
        uint256 offset = 64;
        _price = _bytesToUint256(offset, _extraData);
        offset -= 32;
        _currency = _bytesToUint256(offset, _extraData);
    }

    function _decodeBuyData(bytes _extraData) internal pure returns(address _contract, uint _tokenId) {
        // Deserialize _extraData
        uint256 offset = 64;
        _tokenId = _bytesToUint256(offset, _extraData);
        offset -= 32;
        _contract = _bytesToAddress(offset, _extraData);
    }

    // @dev Decoding helper function from Seriality
    function _bytesToUint256(uint _offst, bytes memory _input) internal pure returns (uint256 _output) {
        assembly {
            _output := mload(add(_input, _offst))
        }
    }

    // @dev Decoding helper functions from Seriality
    function _bytesToAddress(uint _offst, bytes memory _input) internal pure returns (address _output) {
        assembly {
            _output := mload(add(_input, _offst))
        }
    }
}