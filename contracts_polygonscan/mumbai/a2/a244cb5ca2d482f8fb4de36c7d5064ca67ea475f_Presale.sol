/**
 *Submitted for verification at polygonscan.com on 2021-07-12
*/

pragma solidity ^0.4.23;

pragma solidity ^0.4.23;

interface BlockchainCutiesERC1155Interface
{
    function mintNonFungibleSingleShort(uint128 _type, address _to) external;
    function mintNonFungibleSingle(uint256 _type, address _to) external;
    function mintNonFungibleShort(uint128 _type, address[] _to) external;
    function mintNonFungible(uint256 _type, address[] _to) external;
    function mintFungibleSingle(uint256 _id, address _to, uint256 _quantity) external;
    function mintFungible(uint256 _id, address[] _to, uint256[] _quantities) external;
    function isNonFungible(uint256 _id) external pure returns(bool);
    function ownerOf(uint256 _id) external view returns (address);
    function totalSupplyNonFungible(uint256 _type) view external returns (uint256);
    function totalSupplyNonFungibleShort(uint128 _type) view external returns (uint256);

    /**
        @notice A distinct Uniform Resource Identifier (URI) for a given token.
        @dev URIs are defined in RFC 3986.
        The URI may point to a JSON file that conforms to the "ERC-1155 Metadata URI JSON Schema".
        @return URI string
    */
    function uri(uint256 _id) external view returns (string memory);
    function proxyTransfer721(address _from, address _to, uint256 _tokenId, bytes _data) external;
    function proxyTransfer20(address _from, address _to, uint256 _tokenId, uint256 _value) external;
    /**
        @notice Get the balance of an account's Tokens.
        @param _owner  The address of the token holder
        @param _id     ID of the Token
        @return        The _owner's balance of the Token type requested
     */
    function balanceOf(address _owner, uint256 _id) external view returns (uint256);
    /**
        @notice Transfers `_value` amount of an `_id` from the `_from` address to the `_to` address specified (with safety call).
        @dev Caller must be approved to manage the tokens being transferred out of the `_from` account (see "Approval" section of the standard).
        MUST revert if `_to` is the zero address.
        MUST revert if balance of holder for token `_id` is lower than the `_value` sent.
        MUST revert on any other error.
        MUST emit the `TransferSingle` event to reflect the balance change (see "Safe Transfer Rules" section of the standard).
        After the above conditions are met, this function MUST check if `_to` is a smart contract (e.g. code size > 0). If so, it MUST call `onERC1155Received` on `_to` and act appropriately (see "Safe Transfer Rules" section of the standard).
        @param _from    Source address
        @param _to      Target address
        @param _id      ID of the token type
        @param _value   Transfer amount
        @param _data    Additional data with no specified format, MUST be sent unaltered in call to `onERC1155Received` on `_to`
    */
    function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _value, bytes _data) external;
}

pragma solidity ^0.4.23;


pragma solidity ^0.4.23;

pragma solidity ^0.4.23;

// ----------------------------------------------------------------------------
contract ERC20 {

    // ERC Token Standard #223 Interface
    // https://github.com/ethereum/EIPs/issues/223

    string public symbol;
    string public  name;
    uint8 public decimals;

    function transfer(address _to, uint _value, bytes _data) external returns (bool success);

    // approveAndCall
    function approveAndCall(address spender, uint tokens, bytes data) external returns (bool success);

    // ERC Token Standard #20 Interface
    // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md


    function totalSupply() public view returns (uint);
    function balanceOf(address tokenOwner) public view returns (uint balance);
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);

    // bulk operations
    function transferBulk(address[] to, uint[] tokens) public;
    function approveBulk(address[] spender, uint[] tokens) public;
}

pragma solidity ^0.4.23;

/// @title ERC-721 Non-Fungible Token Standard
/// @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
///  Note: the ERC-165 identifier for this interface is 0x6466353c
interface ERC721 /*is ERC165*/ {

    /// @notice Query if a contract implements an interface
    /// @param interfaceID The interface identifier, as specified in ERC-165
    /// @dev Interface identification is specified in ERC-165. This function
    ///  uses less than 30,000 gas.
    /// @return `true` if the contract implements `interfaceID` and
    ///  `interfaceID` is not 0xffffffff, `false` otherwise
    function supportsInterface(bytes4 interfaceID) external view returns (bool);

    /// @dev This emits when ownership of any NFT changes by any mechanism.
    ///  This event emits when NFTs are created (`from` == 0) and destroyed
    ///  (`to` == 0). Exception: during contract creation, any number of NFTs
    ///  may be created and assigned without emitting Transfer. At the time of
    ///  any transfer, the approved address for that NFT (if any) is reset to none.
    event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);

    /// @dev This emits when the approved address for an NFT is changed or
    ///  reaffirmed. The zero address indicates there is no approved address.
    ///  When a Transfer event emits, this also indicates that the approved
    ///  address for that NFT (if any) is reset to none.
    event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);

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
    /// @param _tokenId The identifier for an NFT
    /// @dev NFTs assigned to zero address are considered invalid, and queries
    ///  about them do throw.
    /// @return The address of the owner of the NFT
    function ownerOf(uint256 _tokenId) external view returns (address);

    /// @notice Transfers the ownership of an NFT from one address to another address
    /// @dev Throws unless `msg.sender` is the current owner, an authorized
    ///  operator, or the approved address for this NFT. Throws if `_from` is
    ///  not the current owner. Throws if `_to` is the zero address. Throws if
    ///  `_tokenId` is not a valid NFT. When transfer is complete, this function
    ///  checks if `_to` is a smart contract (code size > 0). If so, it calls
    ///  `onERC721Received` on `_to` and throws if the return value is not
    ///  `bytes4(keccak256("onERC721Received(address,uint256,bytes)"))`.
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    /// @param data Additional data with no specified format, sent in call to `_to`
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes data) external;
    
    /// @notice Transfers the ownership of an NFT from one address to another address
    /// @dev This works identically to the other function with an extra data parameter,
    ///  except this function just sets data to ""
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

    /// @notice Set or reaffirm the approved address for an NFT
    /// @dev The zero address indicates there is no approved address.
    /// @dev Throws unless `msg.sender` is the current NFT owner, or an authorized
    ///  operator of the current owner.
    /// @param _approved The new approved NFT controller
    /// @param _tokenId The NFT to approve
    function approve(address _approved, uint256 _tokenId) external;

    /// @notice Enable or disable approval for a third party ("operator") to manage
    ///  all your asset.
    /// @dev Emits the ApprovalForAll event
    /// @param _operator Address to add to the set of authorized operators.
    /// @param _approved True if the operators is approved, false to revoke approval
    function setApprovalForAll(address _operator, bool _approved) external;

    /// @notice Get the approved address for a single NFT
    /// @dev Throws if `_tokenId` is not a valid NFT
    /// @param _tokenId The NFT to find the approved address for
    /// @return The approved address for this NFT, or the zero address if there is none
    function getApproved(uint256 _tokenId) external view returns (address);

    /// @notice Query if an address is an authorized operator for another address
    /// @param _owner The address that owns the NFTs
    /// @param _operator The address that acts on behalf of the owner
    /// @return True if `_operator` is an approved operator for `_owner`, false otherwise
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);


   /// @notice A descriptive name for a collection of NFTs in this contract
    function name() external pure returns (string _name);

    /// @notice An abbreviated name for NFTs in this contract
    function symbol() external pure returns (string _symbol);

    
    /// @notice A distinct Uniform Resource Identifier (URI) for a given asset.
    /// @dev Throws if `_tokenId` is not a valid NFT. URIs are defined in RFC
    ///  3986. The URI may point to a JSON file that conforms to the "ERC721
    ///  Metadata JSON Schema".
    function tokenURI(uint256 _tokenId) external view returns (string);

     /// @notice Count NFTs tracked by this contract
    /// @return A count of valid NFTs tracked by this contract, where each one of
    ///  them has an assigned and queryable owner not equal to the zero address
    function totalSupply() external view returns (uint256);

    /// @notice Enumerate valid NFTs
    /// @dev Throws if `_index` >= `totalSupply()`.
    /// @param _index A counter less than `totalSupply()`
    /// @return The token identifier for the `_index`th NFT,
    ///  (sort order not specified)
    function tokenByIndex(uint256 _index) external view returns (uint256);

    /// @notice Enumerate NFTs assigned to an owner
    /// @dev Throws if `_index` >= `balanceOf(_owner)` or if
    ///  `_owner` is the zero address, representing invalid NFTs.
    /// @param _owner An address where we are interested in NFTs owned by them
    /// @param _index A counter less than `balanceOf(_owner)`
    /// @return The token identifier for the `_index`th NFT assigned to `_owner`,
    ///   (sort order not specified)
    function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256);

    /// @notice Transfers a Cutie to another address. When transferring to a smart
    ///  contract, ensure that it is aware of ERC-721 (or
    ///  BlockchainCuties specifically), otherwise the Cutie may be lost forever.
    /// @param _to The address of the recipient, can be a user or contract.
    /// @param _cutieId The ID of the Cutie to transfer.
    function transfer(address _to, uint256 _cutieId) external;
}

pragma solidity ^0.4.23;

pragma solidity ^0.4.23;


/**
 * @title ERC165
 * @dev https://github.com/ethereum/EIPs/blob/master/EIPS/eip-165.md
 */
interface ERC165 {

    /**
     * @notice Query if a contract implements an interface
     * @param _interfaceId The interface identifier, as specified in ERC-165
     * @dev Interface identification is specified in ERC-165. This function
     * uses less than 30,000 gas.
     */
    function supportsInterface(bytes4 _interfaceId)
    external
    view
    returns (bool);
}


/**
    @title ERC-1155 Multi Token Standard
    @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-1155.md
    Note: The ERC-165 identifier for this interface is 0xd9b67a26.
 */
interface IERC1155 /* is ERC165 */ {
    /**
        @dev Either `TransferSingle` or `TransferBatch` MUST emit when tokens are transferred, including zero value transfers as well as minting or burning (see "Safe Transfer Rules" section of the standard).
        The `_operator` argument MUST be msg.sender.
        The `_from` argument MUST be the address of the holder whose balance is decreased.
        The `_to` argument MUST be the address of the recipient whose balance is increased.
        The `_id` argument MUST be the token type being transferred.
        The `_value` argument MUST be the number of tokens the holder balance is decreased by and match what the recipient balance is increased by.
        When minting/creating tokens, the `_from` argument MUST be set to `0x0` (i.e. zero address).
        When burning/destroying tokens, the `_to` argument MUST be set to `0x0` (i.e. zero address).
    */
    event TransferSingle(address indexed _operator, address indexed _from, address indexed _to, uint256 _id, uint256 _value);

    /**
        @dev Either `TransferSingle` or `TransferBatch` MUST emit when tokens are transferred, including zero value transfers as well as minting or burning (see "Safe Transfer Rules" section of the standard).
        The `_operator` argument MUST be msg.sender.
        The `_from` argument MUST be the address of the holder whose balance is decreased.
        The `_to` argument MUST be the address of the recipient whose balance is increased.
        The `_ids` argument MUST be the list of tokens being transferred.
        The `_values` argument MUST be the list of number of tokens (matching the list and order of tokens specified in _ids) the holder balance is decreased by and match what the recipient balance is increased by.
        When minting/creating tokens, the `_from` argument MUST be set to `0x0` (i.e. zero address).
        When burning/destroying tokens, the `_to` argument MUST be set to `0x0` (i.e. zero address).
    */
    event TransferBatch(address indexed _operator, address indexed _from, address indexed _to, uint256[] _ids, uint256[] _values);

    /**
        @dev MUST emit when approval for a second party/operator address to manage all tokens for an owner address is enabled or disabled (absense of an event assumes disabled).
    */
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    /**
        @dev MUST emit when the URI is updated for a token ID.
        URIs are defined in RFC 3986.
        The URI MUST point a JSON file that conforms to the "ERC-1155 Metadata URI JSON Schema".

        The URI value allows for ID substitution by clients. If the string {id} exists in any URI,
        clients MUST replace this with the actual token ID in hexadecimal form.
    */
    event URI(string _value, uint256 indexed _id);

    /**
        @notice Transfers `_value` amount of an `_id` from the `_from` address to the `_to` address specified (with safety call).
        @dev Caller must be approved to manage the tokens being transferred out of the `_from` account (see "Approval" section of the standard).
        MUST revert if `_to` is the zero address.
        MUST revert if balance of holder for token `_id` is lower than the `_value` sent.
        MUST revert on any other error.
        MUST emit the `TransferSingle` event to reflect the balance change (see "Safe Transfer Rules" section of the standard).
        After the above conditions are met, this function MUST check if `_to` is a smart contract (e.g. code size > 0). If so, it MUST call `onERC1155Received` on `_to` and act appropriately (see "Safe Transfer Rules" section of the standard).
        @param _from    Source address
        @param _to      Target address
        @param _id      ID of the token type
        @param _value   Transfer amount
        @param _data    Additional data with no specified format, MUST be sent unaltered in call to `onERC1155Received` on `_to`
    */
    function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _value, bytes _data) external;

    /**
        @notice Transfers `_values` amount(s) of `_ids` from the `_from` address to the `_to` address specified (with safety call).
        @dev Caller must be approved to manage the tokens being transferred out of the `_from` account (see "Approval" section of the standard).
        MUST revert if `_to` is the zero address.
        MUST revert if length of `_ids` is not the same as length of `_values`.
        MUST revert if any of the balance(s) of the holder(s) for token(s) in `_ids` is lower than the respective amount(s) in `_values` sent to the recipient.
        MUST revert on any other error.
        MUST emit `TransferSingle` or `TransferBatch` event(s) such that all the balance changes are reflected (see "Safe Transfer Rules" section of the standard).
        Balance changes and events MUST follow the ordering of the arrays (_ids[0]/_values[0] before _ids[1]/_values[1], etc).
        After the above conditions for the transfer(s) in the batch are met, this function MUST check if `_to` is a smart contract (e.g. code size > 0). If so, it MUST call the relevant `ERC1155TokenReceiver` hook(s) on `_to` and act appropriately (see "Safe Transfer Rules" section of the standard).
        @param _from    Source address
        @param _to      Target address
        @param _ids     IDs of each token type (order and length must match _values array)
        @param _values  Transfer amounts per token type (order and length must match _ids array)
        @param _data    Additional data with no specified format, MUST be sent unaltered in call to the `ERC1155TokenReceiver` hook(s) on `_to`
    */
    function safeBatchTransferFrom(address _from, address _to, uint256[] _ids, uint256[] _values, bytes _data) external;

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
        @return        The _owner's balance of the Token types requested (i.e. balance for each (owner, id) pair)
     */
    function balanceOfBatch(address[] _owners, uint256[] _ids) external view returns (uint256[] memory);

    /**
        @notice Enable or disable approval for a third party ("operator") to manage all of the caller's tokens.
        @dev MUST emit the ApprovalForAll event on success.
        @param _operator  Address to add to the set of authorized operators
        @param _approved  True if the operator is approved, false to revoke approval
    */
    function setApprovalForAll(address _operator, bool _approved) external;

    /**
        @notice Queries the approval status of an operator for a given owner.
        @param _owner     The owner of the Tokens
        @param _operator  Address of authorized operator
        @return           True if the operator is approved, false if not
    */
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}


contract Operators
{
    mapping (address=>bool) ownerAddress;
    mapping (address=>bool) operatorAddress;

    constructor() public
    {
        ownerAddress[msg.sender] = true;
    }

    modifier onlyOwner()
    {
        require(ownerAddress[msg.sender], "Access denied");
        _;
    }

    function isOwner(address _addr) public view returns (bool) {
        return ownerAddress[_addr];
    }

    function addOwner(address _newOwner) external onlyOwner {
        require(_newOwner != address(0), "New owner is empty");

        ownerAddress[_newOwner] = true;
    }

    function setOwner(address _newOwner) external onlyOwner {
        require(_newOwner != address(0), "New owner is empty");

        ownerAddress[_newOwner] = true;
        delete(ownerAddress[msg.sender]);
    }

    function removeOwner(address _oldOwner) external onlyOwner {
        delete(ownerAddress[_oldOwner]);
    }

    modifier onlyOperator() {
        require(isOperator(msg.sender), "Access denied");
        _;
    }

    function isOperator(address _addr) public view returns (bool) {
        return operatorAddress[_addr] || ownerAddress[_addr];
    }

    function addOperator(address _newOperator) external onlyOwner {
        require(_newOperator != address(0), "New operator is empty");

        operatorAddress[_newOperator] = true;
    }

    function removeOperator(address _oldOperator) external onlyOwner {
        delete(operatorAddress[_oldOperator]);
    }

    function withdrawERC20(ERC20 _tokenContract) external onlyOwner
    {
        uint256 balance = _tokenContract.balanceOf(address(this));
        _tokenContract.transfer(msg.sender, balance);
    }

    function approveERC721(ERC721 _tokenContract) external onlyOwner
    {
        _tokenContract.setApprovalForAll(msg.sender, true);
    }

    function approveERC1155(IERC1155 _tokenContract) external onlyOwner
    {
        _tokenContract.setApprovalForAll(msg.sender, true);
    }

    function withdrawEth() external onlyOwner
    {
        if (address(this).balance > 0)
        {
            msg.sender.transfer(address(this).balance);
        }
    }
}



/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract PausableOperators is Operators {
    event Pause();
    event Unpause();

    bool public paused = false;


    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     */
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     */
    modifier whenPaused() {
        require(paused);
        _;
    }

    /**
     * @dev called by the owner to pause, triggers stopped state
     */
    function pause() onlyOwner whenNotPaused public {
        paused = true;
        emit Pause();
    }

    /**
     * @dev called by the owner to unpause, returns to normal state
     */
    function unpause() onlyOwner whenPaused public {
        paused = false;
        emit Unpause();
    }
}

pragma solidity ^0.4.23;

interface CutieGeneratorInterface
{
    function generate(uint _genome, uint16 _generation, address[] _target) external;
    function generateSingle(uint _genome, uint16 _generation, address _target) external returns (uint40 babyId);
}

pragma solidity ^0.4.23;

/**
    Note: The ERC-165 identifier for this interface is 0x43b236a2.
*/
interface IERC1155TokenReceiver {

    /**
        @notice Handle the receipt of a single ERC1155 token type.
        @dev An ERC1155-compliant smart contract MUST call this function on the token recipient contract, at the end of a `safeTransferFrom` after the balance has been updated.
        This function MUST return `bytes4(keccak256("accept_erc1155_tokens()"))` (i.e. 0x4dc21a2f) if it accepts the transfer.
        This function MUST revert if it rejects the transfer.
        Return of any other value than the prescribed keccak256 generated value MUST result in the transaction being reverted by the caller.
        @param _operator  The address which initiated the transfer (i.e. msg.sender)
        @param _from      The address which previously owned the token
        @param _id        The id of the token being transferred
        @param _value     The amount of tokens being transferred
        @param _data      Additional data with no specified format
        @return           `bytes4(keccak256("accept_erc1155_tokens()"))`
    */
    function onERC1155Received(address _operator, address _from, uint256 _id, uint256 _value, bytes _data) external returns(bytes4);

    /**
        @notice Handle the receipt of multiple ERC1155 token types.
        @dev An ERC1155-compliant smart contract MUST call this function on the token recipient contract, at the end of a `safeBatchTransferFrom` after the balances have been updated.
        This function MUST return `bytes4(keccak256("accept_batch_erc1155_tokens()"))` (i.e. 0xac007889) if it accepts the transfer(s).
        This function MUST revert if it rejects the transfer(s).
        Return of any other value than the prescribed keccak256 generated value MUST result in the transaction being reverted by the caller.
        @param _operator  The address which initiated the batch transfer (i.e. msg.sender)
        @param _from      The address which previously owned the token
        @param _ids       An array containing ids of each token being transferred (order and length must match _values array)
        @param _values    An array containing amounts of each token being transferred (order and length must match _ids array)
        @param _data      Additional data with no specified format
        @return           `bytes4(keccak256("accept_batch_erc1155_tokens()"))`
    */
    function onERC1155BatchReceived(address _operator, address _from, uint256[] _ids, uint256[] _values, bytes _data) external returns(bytes4);

    /**
        @notice Indicates whether a contract implements the `ERC1155TokenReceiver` functions and so can accept ERC1155 token types.
        @dev This function MUST return `bytes4(keccak256("isERC1155TokenReceiver()"))` (i.e. 0x0d912442).
        This function MUST NOT consume more than 5,000 gas.
        @return           `bytes4(keccak256("isERC1155TokenReceiver()"))`
    */
    function isERC1155TokenReceiver() external view returns (bytes4);
}

pragma solidity ^0.4.23;



/// @title BlockchainCuties Presale Contract
/// @author https://BlockChainArchitect.io
interface PresaleInterface
{
    function bidWithPlugin(uint32 lotId, address purchaser, uint valueForEvent, address tokenForEvent) external payable;
    function bidWithPluginReferrer(uint32 lotId, address purchaser, uint valueForEvent, address tokenForEvent, address referrer) external payable;

    function getLotNftFixedRewards(uint32 lotId) external view returns (
        uint256 rewardsNFTFixedKind,
        uint256 rewardsNFTFixedIndex
    );
    function getLotToken1155Rewards(uint32 lotId) external view returns (
        uint256[10] memory rewardsToken1155tokenId,
        uint256[10] memory rewardsToken1155count
    );
    function getLotCutieRewards(uint32 lotId) external view returns (
        uint256[10] memory rewardsCutieGenome,
        uint256[10] memory rewardsCutieGeneration
    );
    function getLotNftMintRewards(uint32 lotId) external view returns (
        uint256[10] memory rewardsNFTMintNftKind
    );

    function getLotToken1155RewardByIndex(uint32 lotId, uint index) external view returns (
        uint256 rewardsToken1155tokenId,
        uint256 rewardsToken1155count
    );
    function getLotCutieRewardByIndex(uint32 lotId, uint index) external view returns (
        uint256 rewardsCutieGenome,
        uint256 rewardsCutieGeneration
    );
    function getLotNftMintRewardByIndex(uint32 lotId, uint index) external view returns (
        uint256 rewardsNFTMintNftKind
    );

    function getLotToken1155RewardCount(uint32 lotId) external view returns (uint);
    function getLotCutieRewardCount(uint32 lotId) external view returns (uint);
    function getLotNftMintRewardCount(uint32 lotId) external view returns (uint);

    function getLotRewards(uint32 lotId) external view returns (
        uint256[5] memory rewardsToken1155tokenId,
        uint256[5] memory rewardsToken1155count,
        uint256[5] memory rewardsNFTMintNftKind,
        uint256[5] memory rewardsNFTFixedKind,
        uint256[5] memory rewardsNFTFixedIndex,
        uint256[5] memory rewardsCutieGenome,
        uint256[5] memory rewardsCutieGeneration
    );

    function bidWithToken(uint32 lotId, uint rate, uint expireAt, ERC20 paymentToken, uint8 _v, bytes32 _r, bytes32 _s, address referrer) external;
    function bidNativeWithToken(uint32 lotId, address referrer, ERC20 paymentToken) external;
}

pragma solidity ^0.4.23;



interface TokenRegistryInterface
{
    function getPriceInToken(ERC20 tokenContract, uint128 priceWei) external view returns (uint128);
    function convertPriceFromTokensToWei(ERC20 tokenContract, uint priceTokens) external view returns (uint);
    function areAllTokensAllowed(address[] tokens) external view returns (bool);
    function isTokenInList(address[] allowedTokens, address currentToken) external pure returns (bool);
    function getDefaultTokens() external view returns (address[]);
    function getDefaultCreatorTokens() external view returns (address[]);
    function onTokensReceived(ERC20 tokenContract, uint tokenCount) external;
    function withdrawEthFromBalance() external;
    function canConvertToEth(ERC20 tokenContract) external view returns (bool);
    function convertTokensToEth(ERC20 tokenContract, address seller, uint sellerValue, uint fee) external;
}


/// @title BlockchainCuties Presale
/// @author https://BlockChainArchitect.io
contract Presale is PresaleInterface, PausableOperators, IERC1155TokenReceiver
{
    struct RewardToken1155
    {
        uint tokenId;
        uint count;
    }

    struct RewardNFT
    {
        uint128 nftKind;
        uint128 tokenIndex;
    }

    struct RewardCutie
    {
        uint genome;
        uint16 generation;
    }

    uint32 constant RATE_SIGN = 0;
    uint32 constant NATIVE = 1;

    struct Lot
    {
        RewardToken1155[] rewardsToken1155; // stackable
        uint128[] rewardsNftMint; // stackable
        RewardNFT[] rewardsNftFixed; // non stackable - one element per lot
        RewardCutie[] rewardsCutie; // stackable
        uint128 price;
        uint128 leftCount;
        uint128 priceMul;
        uint128 priceAdd;
        uint32 expireTime;
        uint32 lotKind;
        address priceInToken;
    }

    mapping (uint32 => Lot) public lots;

    mapping (address => uint) public referrers;

    BlockchainCutiesERC1155Interface public token1155;
    CutieGeneratorInterface public cutieGenerator;
    TokenRegistryInterface public tokenRegistry;
    address public signerAddress;

    event Bid(address indexed purchaser, uint32 indexed lotId, uint value, address indexed token);
    event BidReferrer(address indexed purchaser, uint32 indexed lotId, uint value, address token, address indexed referrer);
    event LotChange(uint32 indexed lotId);

    function setToken1155(BlockchainCutiesERC1155Interface _token1155) onlyOwner public
    {
        token1155 = _token1155;
    }

    function setCutieGenerator(CutieGeneratorInterface _cutieGenerator) onlyOwner public
    {
        cutieGenerator = _cutieGenerator;
    }

    function setTokenRegistry(TokenRegistryInterface _tokenRegistry) onlyOwner public
    {
        tokenRegistry = _tokenRegistry;
    }

    function setup(
        BlockchainCutiesERC1155Interface _token1155,
        CutieGeneratorInterface _cutieGenerator,
        TokenRegistryInterface _tokenRegistry) onlyOwner external
    {
        setToken1155(_token1155);
        setCutieGenerator(_cutieGenerator);
        setTokenRegistry(_tokenRegistry);
    }

    function setLot(uint32 lotId, uint128 price, uint128 count, uint32 expireTime, uint128 priceMul, uint128 priceAdd, uint32 lotKind) external onlyOperator
    {
        delete lots[lotId];
        Lot storage lot = lots[lotId];
        lot.price = price;
        lot.leftCount = count;
        lot.expireTime = expireTime;
        lot.priceMul = priceMul;
        lot.priceAdd = priceAdd;
        lot.lotKind = lotKind;
        lot.priceInToken = address(0x0);
        emit LotChange(lotId);
    }

    function setLotWithToken(uint32 lotId, uint128 price, uint128 count, uint32 expireTime, uint128 priceMul, uint128 priceAdd, uint32 lotKind, address priceInToken) external onlyOperator
    {
        delete lots[lotId];
        Lot storage lot = lots[lotId];
        lot.price = price;
        lot.leftCount = count;
        lot.expireTime = expireTime;
        lot.priceMul = priceMul;
        lot.priceAdd = priceAdd;
        lot.lotKind = lotKind;
        lot.priceInToken = priceInToken;
        emit LotChange(lotId);
    }

    function setLotLeftCount(uint32 lotId, uint128 count) external onlyOperator
    {
        Lot storage lot = lots[lotId];
        lot.leftCount = count;
        emit LotChange(lotId);
    }

    function setExpireTime(uint32 lotId, uint32 expireTime) external onlyOperator
    {
        Lot storage lot = lots[lotId];
        lot.expireTime = expireTime;
        emit LotChange(lotId);
    }

    function setPrice(uint32 lotId, uint128 price) external onlyOperator
    {
        lots[lotId].price = price;
        emit LotChange(lotId);
    }

    function deleteLot(uint32 lotId) external onlyOperator
    {
        delete lots[lotId];
        emit LotChange(lotId);
    }

    function addRewardToken1155(uint32 lotId, uint tokenId, uint count) external onlyOperator
    {
        lots[lotId].rewardsToken1155.push(RewardToken1155(tokenId, count));
        emit LotChange(lotId);
    }

    function setRewardToken1155(uint32 lotId, uint tokenId, uint count) external onlyOperator
    {
        delete lots[lotId].rewardsToken1155;
        lots[lotId].rewardsToken1155.push(RewardToken1155(tokenId, count));
        emit LotChange(lotId);
    }

    function setRewardNftFixed(uint32 lotId, uint128 nftType, uint128 tokenIndex) external onlyOperator
    {
        delete lots[lotId].rewardsNftFixed;
        lots[lotId].rewardsNftFixed.push(RewardNFT(nftType, tokenIndex));
        emit LotChange(lotId);
    }

    function addRewardNftFixed(uint32 lotId, uint128 nftType, uint128 tokenIndex) external onlyOperator
    {
        lots[lotId].rewardsNftFixed.push(RewardNFT(nftType, tokenIndex));
        emit LotChange(lotId);
    }

    function addRewardNftFixedBulk(uint32 lotId, uint128 nftType, uint128[] tokenIndex) external onlyOperator
    {
        for (uint i = 0; i < tokenIndex.length; i++)
        {
            lots[lotId].rewardsNftFixed.push(RewardNFT(nftType, tokenIndex[i]));
        }
        emit LotChange(lotId);
    }

    function addRewardNftMint(uint32 lotId, uint128 nftType) external onlyOperator
    {
        lots[lotId].rewardsNftMint.push(nftType);
        emit LotChange(lotId);
    }

    function setRewardNftMint(uint32 lotId, uint128 nftType) external onlyOperator
    {
        delete lots[lotId].rewardsNftMint;
        lots[lotId].rewardsNftMint.push(nftType);
        emit LotChange(lotId);
    }

    function addRewardCutie(uint32 lotId, uint genome, uint16 generation) external onlyOperator
    {
        lots[lotId].rewardsCutie.push(RewardCutie(genome, generation));
        emit LotChange(lotId);
    }

    function setRewardCutie(uint32 lotId, uint genome, uint16 generation) external onlyOperator
    {
        delete lots[lotId].rewardsCutie;
        lots[lotId].rewardsCutie.push(RewardCutie(genome, generation));
        emit LotChange(lotId);
    }

    function isAvailable(uint32 lotId) public view returns (bool)
    {
        Lot storage lot = lots[lotId];
        return
            lot.leftCount > 0 && lot.expireTime >= now;
    }

    function getLot(uint32 lotId) external view returns (
        uint256 price,
        uint256 left,
        uint256 expireTime,
        uint256 lotKind
    )
    {
        Lot storage p = lots[lotId];
        price = p.price;
        left = p.leftCount;
        expireTime = p.expireTime;
        lotKind = p.lotKind;
    }

    function getLot2(uint32 lotId) external view returns (
        uint256 price,
        uint256 left,
        uint256 expireTime,
        uint256 lotKind,
        address priceInToken
    )
    {
        Lot storage p = lots[lotId];
        price = p.price;
        left = p.leftCount;
        expireTime = p.expireTime;
        lotKind = p.lotKind;
        priceInToken = p.priceInToken;
    }

    function getLotRewards(uint32 lotId) external view returns (
            uint256[5] memory rewardsToken1155tokenId,
            uint256[5] memory rewardsToken1155count,
            uint256[5] memory rewardsNFTMintNftKind,
            uint256[5] memory rewardsNFTFixedKind,
            uint256[5] memory rewardsNFTFixedIndex,
            uint256[5] memory rewardsCutieGenome,
            uint256[5] memory rewardsCutieGeneration
        )
    {
        Lot storage p = lots[lotId];
        uint i;
        for (i = 0; i < p.rewardsToken1155.length; i++)
        {
            if (i >= 5) break;
            rewardsToken1155tokenId[i] = p.rewardsToken1155[i].tokenId;
            rewardsToken1155count[i] = p.rewardsToken1155[i].count;
        }
        for (i = 0; i < p.rewardsNftMint.length; i++)
        {
            if (i >= 5) break;
            rewardsNFTMintNftKind[i] = p.rewardsNftMint[i];
        }
        for (i = 0; i < p.rewardsNftFixed.length; i++)
        {
            if (i >= 5) break;
            rewardsNFTFixedKind[i] = p.rewardsNftFixed[i].nftKind;
            rewardsNFTFixedIndex[i] = p.rewardsNftFixed[i].tokenIndex;
        }
        for (i = 0; i < p.rewardsCutie.length; i++)
        {
            if (i >= 5) break;
            rewardsCutieGenome[i] = p.rewardsCutie[i].genome;
            rewardsCutieGeneration[i] = p.rewardsCutie[i].generation;
        }
    }

    function getLotNftFixedRewards(uint32 lotId) external view returns (
        uint256 rewardsNFTFixedKind,
        uint256 rewardsNFTFixedIndex
    )
    {
        Lot storage p = lots[lotId];

        if (p.rewardsNftFixed.length > 0)
        {
            rewardsNFTFixedKind = p.rewardsNftFixed[p.rewardsNftFixed.length-1].nftKind;
            rewardsNFTFixedIndex = p.rewardsNftFixed[p.rewardsNftFixed.length-1].tokenIndex;
        }
    }

    function getLotToken1155Rewards(uint32 lotId) external view returns (
        uint256[10] memory rewardsToken1155tokenId,
        uint256[10] memory rewardsToken1155count
    )
    {
        Lot storage p = lots[lotId];
        for (uint i = 0; i < p.rewardsToken1155.length; i++)
        {
            if (i >= 10) break;
            rewardsToken1155tokenId[i] = p.rewardsToken1155[i].tokenId;
            rewardsToken1155count[i] = p.rewardsToken1155[i].count;
        }
    }

    function getLotCutieRewards(uint32 lotId) external view returns (
        uint256[10] memory rewardsCutieGenome,
        uint256[10] memory rewardsCutieGeneration
    )
    {
        Lot storage p = lots[lotId];
        for (uint i = 0; i < p.rewardsCutie.length; i++)
        {
            if (i >= 10) break;
            rewardsCutieGenome[i] = p.rewardsCutie[i].genome;
            rewardsCutieGeneration[i] = p.rewardsCutie[i].generation;
        }
    }

    function getLotNftMintRewards(uint32 lotId) external view returns (
        uint256[10] memory rewardsNFTMintNftKind
    )
    {
        Lot storage p = lots[lotId];
        for (uint i = 0; i < p.rewardsNftMint.length; i++)
        {
            if (i >= 10) break;
            rewardsNFTMintNftKind[i] = p.rewardsNftMint[i];
        }
    }

    function getLotToken1155RewardByIndex(uint32 lotId, uint index) external view returns (
        uint256 rewardsToken1155tokenId,
        uint256 rewardsToken1155count
    )
    {
        Lot storage p = lots[lotId];
        rewardsToken1155tokenId = p.rewardsToken1155[index].tokenId;
        rewardsToken1155count = p.rewardsToken1155[index].count;
    }

    function getLotCutieRewardByIndex(uint32 lotId, uint index) external view returns (
        uint256 rewardsCutieGenome,
        uint256 rewardsCutieGeneration
    )
    {
        Lot storage p = lots[lotId];
        rewardsCutieGenome = p.rewardsCutie[index].genome;
        rewardsCutieGeneration = p.rewardsCutie[index].generation;
    }

    function getLotNftMintRewardByIndex(uint32 lotId, uint index) external view returns (
        uint256 rewardsNFTMintNftKind
    )
    {
        Lot storage p = lots[lotId];
        rewardsNFTMintNftKind = p.rewardsNftMint[index];
    }

    function getLotToken1155RewardCount(uint32 lotId) external view returns (uint)
    {
        return lots[lotId].rewardsToken1155.length;
    }
    function getLotCutieRewardCount(uint32 lotId) external view returns (uint)
    {
        return lots[lotId].rewardsCutie.length;
    }
    function getLotNftMintRewardCount(uint32 lotId) external view returns (uint)
    {
        return lots[lotId].rewardsNftMint.length;
    }

    function deleteRewards(uint32 lotId) external onlyOwner
    {
        delete lots[lotId].rewardsToken1155;
        delete lots[lotId].rewardsNftMint;
        delete lots[lotId].rewardsNftFixed;
        delete lots[lotId].rewardsCutie;
        emit LotChange(lotId);
    }

    function bidWithPlugin(uint32 lotId, address purchaser, uint valueForEvent, address tokenForEvent) external payable onlyOperator
    {
        _bid(lotId, purchaser, valueForEvent, tokenForEvent, address(0x0));
    }

    function bidWithPluginReferrer(uint32 lotId, address purchaser, uint valueForEvent, address tokenForEvent, address referrer) external payable onlyOperator
    {
        _bid(lotId, purchaser, valueForEvent, tokenForEvent, referrer);
    }

    function _bid(uint32 lotId, address purchaser, uint valueForEvent, address tokenForEvent, address referrer) internal whenNotPaused
    {
        Lot storage p = lots[lotId];
        require(isAvailable(lotId), "Lot is not available");

        if (referrer == address(0x0))
        {
            emit BidReferrer(purchaser, lotId, valueForEvent, tokenForEvent, referrer);
        }
        else
        {
            emit Bid(purchaser, lotId, valueForEvent, tokenForEvent);
        }

        p.leftCount--;
        p.price += uint128(uint256(p.price)*p.priceMul / 1000000);
        p.price += p.priceAdd;

        issueRewards(p, purchaser);

        if (referrers[referrer] > 0)
        {
            uint referrerValue = valueForEvent * referrers[referrer] / 100;
            referrer.transfer(referrerValue);
        }
    }

    function issueRewards(Lot storage p, address purchaser) internal
    {
        uint i;
        for (i = 0; i < p.rewardsToken1155.length; i++)
        {
            mintToken1155(purchaser, p.rewardsToken1155[i]);
        }
        if (p.rewardsNftFixed.length > 0)
        {
            transferNFT(purchaser, p.rewardsNftFixed[p.rewardsNftFixed.length-1]);
            p.rewardsNftFixed.length--;
        }
        for (i = 0; i < p.rewardsNftMint.length; i++)
        {
            mintNFT(purchaser, p.rewardsNftMint[i]);
        }
        for (i = 0; i < p.rewardsCutie.length; i++)
        {
            mintCutie(purchaser, p.rewardsCutie[i]);
        }
    }

    function mintToken1155(address purchaser, RewardToken1155 storage reward) internal
    {
        token1155.mintFungibleSingle(reward.tokenId, purchaser, reward.count);
    }

    function mintNFT(address purchaser, uint128 nftKind) internal
    {
        token1155.mintNonFungibleSingleShort(nftKind, purchaser);
    }

    function transferNFT(address purchaser, RewardNFT storage reward) internal
    {
        uint tokenId = (uint256(reward.nftKind) << 128) | (1 << 255) | reward.tokenIndex;
        token1155.safeTransferFrom(address(this), purchaser, tokenId, 1, "");
    }

    function mintCutie(address purchaser, RewardCutie storage reward) internal
    {
        cutieGenerator.generateSingle(reward.genome, reward.generation, purchaser);
    }

    function destroyContract() external onlyOwner {
        require(address(this).balance == 0);
        selfdestruct(msg.sender);
    }

    /// @dev Reject all Ether
    function() external payable {
        revert();
    }

    /// @dev The balance transfer to project owners
    function withdrawEthFromBalance(uint value) external onlyOwner
    {
        uint256 total = address(this).balance;
        if (total > value)
        {
            total = value;
        }

        msg.sender.transfer(total);
    }

    function bidNative(uint32 lotId, address referrer) external payable
    {
        Lot storage lot = lots[lotId];
        require(lot.price <= msg.value, "Not enough value provided");
        require(lot.lotKind == NATIVE, "Lot kind should be NATIVE");
        require(lot.priceInToken == address(0x0), "Price in token is not supported");

        _bid(lotId, msg.sender, msg.value, address(0x0), referrer);
    }

    // https://github.com/BitGuildPlatform/Documentation/blob/master/README.md#2-required-game-smart-contract-changes
    // Function that is called when trying to use Token for payments from approveAndCall
    function receiveApproval(address _sender, uint256, address _tokenContract, bytes _extraData) external
    {
        uint32 lotId = getLotId(_extraData);
        _bidNativeWithToken(lotId, address(0x0), ERC20(_tokenContract), _sender);
    }

    function getLotId(bytes _extraData) pure internal returns (uint32)
    {
        require(_extraData.length == 4); // 32 bits

        return
            uint32(_extraData[0]) +
            uint32(_extraData[1]) * 0x100 +
            uint32(_extraData[2]) * 0x10000 +
            uint32(_extraData[3]) * 0x100000;
    }

    function bidNativeWithToken(uint32 lotId, address referrer, ERC20 paymentToken) external
    {
        _bidNativeWithToken(lotId, referrer, paymentToken, msg.sender);
    }

    function _bidNativeWithToken(uint32 lotId, address referrer, ERC20 paymentToken, address sender) internal
    {
        Lot storage lot = lots[lotId];
        require(lot.lotKind == NATIVE, "Lot kind should be NATIVE");
        require(isTokenAllowed(paymentToken), "Token is not allowed");

        uint priceInTokens;

        // do not convert if price is specified in same token as payment token
        if (lot.priceInToken == address(paymentToken))
        {
            priceInTokens = lot.price;
        }
        // convert from one token to another
        else if (lot.priceInToken != address(0x0))
        {
            uint priceInWei = convertPriceFromTokensToWei(ERC20(lot.priceInToken), lot.price);
            priceInTokens = convertPriceFromWeiToTokens(paymentToken, priceInWei);
        }
        else // price in ETH
        {
            uint priceInWei2 = lot.price;
            priceInTokens = convertPriceFromWeiToTokens(paymentToken, priceInWei2);
        }
        require(paymentToken.transferFrom(sender, address(tokenRegistry), priceInTokens), "Can't request tokens");
        tokenRegistry.onTokensReceived(paymentToken, priceInTokens);

        _bid(lotId, sender, priceInTokens, address(paymentToken), referrer);
    }

    function bid(uint32 lotId, uint rate, uint expireAt, uint8 _v, bytes32 _r, bytes32 _s) external payable
    {
        bidReferrer(lotId, rate, expireAt, _v, _r, _s, address(0x0));
    }

    function bidWithToken(uint32 lotId, uint rate, uint expireAt, ERC20 paymentToken, uint8 _v, bytes32 _r, bytes32 _s, address referrer) external
    {
        Lot storage lot = lots[lotId];
        require(lot.lotKind == RATE_SIGN, "Lot kind should be RATE_SIGN");

        require(isValidSignature(rate, expireAt, _v, _r, _s), "Signature is not valid");
        require(expireAt >= now, "Rate sign is expired");
        require(isTokenAllowed(paymentToken), "Token is not allowed");

        uint priceInTokens;
        // do not convert if price is specified in same token as payment token
        if (lot.priceInToken == address(paymentToken))
        {
            priceInTokens = lot.price;
        }
        // convert from one token to another
        else if (lot.priceInToken != address(0x0))
        {
            uint priceInWei = rate * lot.price;
            priceInTokens = convertPriceFromWeiToTokens(paymentToken, priceInWei);
        }
        else // price in ETH
        {
            uint priceInWei2 = rate * lot.price;
            priceInTokens = convertPriceFromWeiToTokens(paymentToken, priceInWei2);
        }

        require(paymentToken.transferFrom(msg.sender, address(tokenRegistry), priceInTokens), "Can't request tokens");
        tokenRegistry.onTokensReceived(paymentToken, priceInTokens);

        _bid(lotId, msg.sender, priceInTokens, address(paymentToken), referrer);
    }

    function bidReferrer(uint32 lotId, uint rate, uint expireAt, uint8 _v, bytes32 _r, bytes32 _s, address referrer) public payable
    {
        Lot storage lot = lots[lotId];
        require(lot.lotKind == RATE_SIGN, "Lot kind should be RATE_SIGN");

        require(isValidSignature(rate, expireAt, _v, _r, _s));
        require(expireAt >= now, "Rate sign is expired");

        uint priceInWei = rate * lot.price;
        require(priceInWei <= msg.value, "Not enough value provided");

        _bid(lotId, msg.sender, priceInWei, address(0x0), referrer);
    }

    function setSigner(address _newSigner) public onlyOwner {
        signerAddress = _newSigner;
    }

    function isValidSignature(uint rate, uint expireAt, uint8 _v, bytes32 _r, bytes32 _s) public view returns (bool)
    {
        return getSigner(rate, expireAt, _v, _r, _s) == signerAddress;
    }

    function getSigner(uint rate, uint expireAt, uint8 _v, bytes32 _r, bytes32 _s) public pure returns (address)
    {
        bytes32 msgHash = hashArguments(rate, expireAt);
        return ecrecover(msgHash, _v, _r, _s);
    }

    /// @dev Common function to be used also in backend
    function hashArguments(uint rate, uint expireAt) public pure returns (bytes32 msgHash)
    {
        msgHash = keccak256(abi.encode(rate, expireAt));
    }

    function isERC1155TokenReceiver() external view returns (bytes4) {
        return bytes4(keccak256("isERC1155TokenReceiver()"));
    }

    function onERC1155BatchReceived(address, address, uint256[], uint256[], bytes) external returns(bytes4)
    {
        return bytes4(keccak256("acrequcept_batch_erc1155_tokens()"));
    }

    function onERC1155Received(address, address, uint256, uint256, bytes) external returns(bytes4)
    {
        return bytes4(keccak256("accept_erc1155_tokens()"));
    }

    // 100 means 100%
    function setReferrer(address _address, uint _percent) external onlyOwner
    {
        require(_percent < 100);
        referrers[_address] = _percent;
    }

    function removeReferrer(address _address) external onlyOwner
    {
        delete referrers[_address];
    }

    function decreaseCount(uint32 lotId) external onlyOperator
    {
        Lot storage p = lots[lotId];
        if (p.leftCount > 0)
        {
            p.leftCount--;
        }

        emit LotChange(lotId);
    }

    function isTokenAllowed(ERC20 token) view public returns (bool)
    {
        address[] memory arg = new address[](1);
        arg[0] = address(token);
        return tokenRegistry.areAllTokensAllowed(arg);
    }

    function convertPriceFromWeiToTokens(ERC20 token, uint valueInWei) view public returns (uint)
    {
        return uint(tokenRegistry.getPriceInToken(token, uint128(valueInWei)));
    }

    function convertPriceFromTokensToWei(ERC20 token, uint valueInTokens) view public returns (uint)
    {
        return tokenRegistry.convertPriceFromTokensToWei(token, valueInTokens);
    }
}