pragma solidity ^0.4.24;

/// @title New Child Kydy&#39;s Genes
contract GeneSynthesisInterface {
    /// @dev boolean to check this is the contract we expect to be
    function isGeneSynthesis() public pure returns (bool);

    /**
     * @dev Synthesizes the genes of yin and yang Kydy, and returns the result as the child&#39;s genes. 
     * @param gene1 genes of yin Kydy
     * @param gene2 genes of yang Kydy
     * @return the genes of the child
     */
    function synthGenes(uint256 gene1, uint256 gene2) public returns (uint256);
}

/**
 * @title Part of KydyCore that manages special access controls.
 * @author VREX Lab Co., Ltd
 * @dev See the KydyCore contract documentation to understand how the various contracts are arranged.
 */
contract KydyAccessControl {
    /**
     * This contract defines access control for the following important roles of the Dyverse:
     *
     *     - The CEO: The CEO can assign roles and change the addresses of the smart contracts. 
     *         It can also solely unpause the smart contract. 
     *
     *     - The CFO: The CFO can withdraw funds from the KydyCore and the auction contracts.
     *
     *     - The COO: The COO can release Generation 0 Kydys and create promotional-type Kydys.
     *
     */

    /// @dev Used when contract is upgraded. 
    event ContractUpgrade(address newContract);

    // The assigned addresses of each role, as defined in this contract. 
    address public ceoAddress;
    address public cfoAddress;
    address public cooAddress;

    /// @dev Checks if the contract is paused. When paused, most of the functions of this contract will also be stopped.
    bool public paused = false;

    /// @dev Access modifier for CEO-only
    modifier onlyCEO() {
        require(msg.sender == ceoAddress);
        _;
    }

    /// @dev Access modifier for CFO-only
    modifier onlyCFO() {
        require(msg.sender == cfoAddress);
        _;
    }

    /// @dev Access modifier for COO-only
    modifier onlyCOO() {
        require(msg.sender == cooAddress);
        _;
    }

    /// @dev Access modifier for CEO, CFO, COO
    modifier onlyCLevel() {
        require(
            msg.sender == ceoAddress ||
            msg.sender == cfoAddress ||
            msg.sender == cooAddress
        );
        _;
    }

    /**
     * @dev Assigns a new address to the CEO. Only the current CEO has the authority.
     * @param _newCEO The address of the new CEO
     */
    function setCEO(address _newCEO) external onlyCEO {
        require(_newCEO != address(0));

        ceoAddress = _newCEO;
    }

    /**
     * @dev Assigns a new address to the CFO. Only the current CEO has the authority.
     * @param _newCFO The address of the new CFO
     */
    function setCFO(address _newCFO) external onlyCEO {
        require(_newCFO != address(0));

        cfoAddress = _newCFO;
    }

    /**
     * @dev Assigns a new address to the COO. Only the current CEO has the authority.
     * @param _newCOO The address of the new COO
     */
    function setCOO(address _newCOO) external onlyCEO {
        require(_newCOO != address(0));

        cooAddress = _newCOO;
    }

    /*** Pausable functionality adapted from OpenZeppelin ***/

    /// @dev Modifier to allow actions only when the contract IS NOT paused
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    /// @dev Modifier to allow actions only when the contract IS paused
    modifier whenPaused {
        require(paused);
        _;
    }

    /**
     * @dev Called by any "C-level" role to pause the contract. Used only when
     *  a bug or exploit is detected to limit the damage.
     */
    function pause() external onlyCLevel whenNotPaused {
        paused = true;
    }

    /**
     * @dev Unpauses the smart contract. Can only be called by the CEO, since
     *  one reason we may pause the contract is when CFO or COO accounts are
     *  compromised.
     * @notice This is public rather than external so it can be called by
     *  derived contracts.
     */
    function unpause() public onlyCEO whenPaused {
        // can&#39;t unpause if contract was upgraded
        paused = false;
    }
}

contract ERC165Interface {
    /**
     * @notice Query if a contract implements an interface
     * @param interfaceID The interface identifier, as specified in ERC-165
     * @dev Interface identification is specified in ERC-165. This function
     *  uses less than 30,000 gas.
     * @return `true` if the contract implements `interfaceID` and
     *  `interfaceID` is not 0xffffffff, `false` otherwise
     */
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}

contract ERC165 is ERC165Interface {
    /**
     * @dev a mapping of interface id to whether or not it&#39;s supported
     */
    mapping(bytes4 => bool) private _supportedInterfaces;

    /**
     * @dev implement supportsInterface(bytes4) using a lookup table
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool) {
        return _supportedInterfaces[interfaceId];
    }

    /**
     * @dev internal method for registering an interface
     */
    function _registerInterface(bytes4 interfaceId) internal {
        require(interfaceId != 0xffffffff);
        _supportedInterfaces[interfaceId] = true;
    }
}

// Every ERC-721 compliant contract must implement the ERC721 and ERC165 interfaces.
/** 
 * @title ERC-721 Non-Fungible Token Standard
 * @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 * Note: the ERC-165 identifier for this interface is 0x80ac58cd.
 */
contract ERC721Basic is ERC165 {
    // Below is MUST

    /**
     * @dev This emits when ownership of any NFT changes by any mechanism.
     *  This event emits when NFTs are created (`from` == 0) and destroyed
     *  (`to` == 0). Exception: during contract creation, any number of NFTs
     *  may be created and assigned without emitting Transfer. At the time of
     *  any transfer, the approved address for that NFT (if any) is reset to none.
     */
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);

    /**
     * @dev This emits when the approved address for an NFT is changed or
     *  reaffirmed. The zero address indicates there is no approved address.
     *  When a Transfer event emits, this also indicates that the approved
     *  address for that NFT (if any) is reset to none.
     */
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);

    /**
     * @dev This emits when an operator is enabled or disabled for an owner.
     *  The operator can manage all NFTs of the owner.
     */
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    /**
     * @notice Count all NFTs assigned to an owner
     * @dev NFTs assigned to the zero address are considered invalid, and this
     *  function throws for queries about the zero address.
     * @param _owner An address for whom to query the balance
     * @return The number of NFTs owned by `_owner`, possibly zero
     */
    function balanceOf(address _owner) public view returns (uint256);

    /**
     * @notice Find the owner of an NFT
     * @dev NFTs assigned to zero address are considered invalid, and queries
     *  about them do throw.
     * @param _tokenId The identifier for an NFT
     * @return The address of the owner of the NFT
     */
    function ownerOf(uint256 _tokenId) public view returns (address);

    /**
     * @notice Transfers the ownership of an NFT from one address to another address
     * @dev Throws unless `msg.sender` is the current owner, an authorized
     *  operator, or the approved address for this NFT. Throws if `_from` is
     *  not the current owner. Throws if `_to` is the zero address. Throws if
     *  `_tokenId` is not a valid NFT. When transfer is complete, this function
     *  checks if `_to` is a smart contract (code size > 0). If so, it calls
     *  `onERC721Received` on `_to` and throws if the return value is not
     *  `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.
     * @param _from The current owner of the NFT
     * @param _to The new owner
     * @param _tokenId The NFT to transfer
     * @param data Additional data with no specified format, sent in call to `_to`
     */
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes data) public;

    /**
     * @notice Transfers the ownership of an NFT from one address to another address
     * @dev This works identically to the other function with an extra data parameter,
     *  except this function just sets data to "".
     * @param _from The current owner of the NFT
     * @param _to The new owner
     * @param _tokenId The NFT to transfer
     */
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) public;

    /**
     * @notice Transfer ownership of an NFT -- THE CALLER IS RESPONSIBLE
     *  TO CONFIRM THAT `_to` IS CAPABLE OF RECEIVING NFTS OR ELSE
     *  THEY MAY BE PERMANENTLY LOST
     * @dev Throws unless `msg.sender` is the current owner, an authorized
     *  operator, or the approved address for this NFT. Throws if `_from` is
     *  not the current owner. Throws if `_to` is the zero address. Throws if
     *  `_tokenId` is not a valid NFT.
     * @param _from The current owner of the NFT
     * @param _to The new owner
     * @param _tokenId The NFT to transfer
     */
    function transferFrom(address _from, address _to, uint256 _tokenId) public;

    /**
     * @notice Change or reaffirm the approved address for an NFT
     * @dev The zero address indicates there is no approved address.
     *  Throws unless `msg.sender` is the current NFT owner, or an authorized
     *  operator of the current owner.
     * @param _approved The new approved NFT controller
     * @param _tokenId The NFT to approve
     */
    function approve(address _approved, uint256 _tokenId) external;

    /**
     * @notice Enable or disable approval for a third party ("operator") to manage
     *  all of `msg.sender`&#39;s assets
     * @dev Emits the ApprovalForAll event. The contract MUST allow
     *  multiple operators per owner.
     * @param _operator Address to add to the set of authorized operators
     * @param _approved True if the operator is approved, false to revoke approval
     */
    function setApprovalForAll(address _operator, bool _approved) external;

    /**
     * @notice Get the approved address for a single NFT
     * @dev Throws if `_tokenId` is not a valid NFT.
     * @param _tokenId The NFT to find the approved address for
     * @return The approved address for this NFT, or the zero address if there is none
     */
    function getApproved(uint256 _tokenId) public view returns (address);

    /**
     * @notice Query if an address is an authorized operator for another address
     * @param _owner The address that owns the NFTs
     * @param _operator The address that acts on behalf of the owner
     * @return True if `_operator` is an approved operator for `_owner`, false otherwise
     */
    function isApprovedForAll(address _owner, address _operator) public view returns (bool);

    // Below is OPTIONAL

    // ERC721Metadata
    // The metadata extension is OPTIONAL for ERC-721 smart contracts (see "caveats", below). This allows your smart contract to be interrogated for its name and for details about the assets which your NFTs represent.
    
    /**
     * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
     * @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
     *  Note: the ERC-165 identifier for this interface is 0x5b5e139f.
     */

    /// @notice A descriptive name for a collection of NFTs in this contract
    function name() external view returns (string _name);

    /// @notice An abbreviated name for NFTs in this contract
    function symbol() external view returns (string _symbol);

    /**
     * @notice A distinct Uniform Resource Identifier (URI) for a given asset.
     * @dev Throws if `_tokenId` is not a valid NFT. URIs are defined in RFC
     *  3986. The URI may point to a JSON file that conforms to the "ERC721
     *  Metadata JSON Schema".
     */
    function tokenURI(uint256 _tokenId) external view returns (string);

    // ERC721Enumerable
    // The enumeration extension is OPTIONAL for ERC-721 smart contracts (see "caveats", below). This allows your contract to publish its full list of NFTs and make them discoverable.

    /**
     * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
     * @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
     *  Note: the ERC-165 identifier for this interface is 0x780e9d63.
     */

    /**
     * @notice Count NFTs tracked by this contract
     * @return A count of valid NFTs tracked by this contract, where each one of
     *  them has an assigned and queryable owner not equal to the zero address
     */
    function totalSupply() public view returns (uint256);
}

/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 */
library SafeMath {
    /**
    * @dev Multiplies two numbers, reverts on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring &#39;a&#39; not being zero, but the
        // benefit is lost if &#39;b&#39; is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    /**
    * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold

        return c;
    }

    /**
    * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    /**
    * @dev Adds two numbers, reverts on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    /**
    * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
    * reverts when dividing by zero.
    */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

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
        // solium-disable-next-line security/no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}

/**
 * @title The base contract of Dyverse. ERC-721 compliant.
 * @author VREX Lab Co., Ltd
 * @dev See the KydyCore contract for more info on details. 
 */
contract KydyBase is KydyAccessControl, ERC721Basic {
    using SafeMath for uint256;
    using Address for address;

    /*** EVENT ***/

    /**
     * @dev The Creation event takes place whenever a new Kydy is created via Synthesis or minted by the COO.  
     */
    event Created(address indexed owner, uint256 kydyId, uint256 yinId, uint256 yangId, uint256 genes);

    /*** DATA TYPES ***/

    /**
     * @dev Every Kydy in the Dyverse is a copy of this structure. 
     */
    struct Kydy {
        // The Kydy&#39;s genetic code is stored into 256-bits and never changes.
        uint256 genes;

        // The timestamp of the block when this Kydy was created
        uint64 createdTime;

        // The timestamp of when this Kydy can synthesize again.
        uint64 rechargeEndBlock;

        // The ID of the parents (Yin, female, and Yang, male). It is 0 for Generation 0 Kydys.
        uint32 yinId;
        uint32 yangId;

        // The ID of the yang Kydy that the yin Kydy is creating with. 
        uint32 synthesizingWithId;

        // The recharge index that represents the duration of the recharge for this Kydy. 
        // After each synthesis, this increases by one for both yin and yang Kydys of the synthesis. 
        uint16 rechargeIndex;

        // The generation index of this Kydy. The newly created Kydy takes the generation index of the parent 
        // with a larger generation index. 
        uint16 generation;
    }

    /*** CONSTANTS ***/

    /**
     * @dev An array table of the recharge duration. Referred to as "creation time" for yin 
     *  and "synthesis recharge" for yang Kydys. Maximum duration is 4 days. 
     */
    uint32[14] public recharges = [
        uint32(1 minutes),
        uint32(2 minutes),
        uint32(5 minutes),
        uint32(10 minutes),
        uint32(30 minutes),
        uint32(1 hours),
        uint32(2 hours),
        uint32(4 hours),
        uint32(8 hours),
        uint32(16 hours),
        uint32(1 days),
        uint32(2 days),
        uint32(4 days)
    ];

    // An approximation of seconds between blocks.
    uint256 public secondsPerBlock = 15;

    /*** STORAGE ***/

    /**
     * @dev This array contains the ID of every Kydy as an index. 
     */
    Kydy[] kydys;

    /**
     * @dev This maps each Kydy ID to the address of the owner. Every Kydy must have an owner, even Gen 0 Kydys.
     *  You can view this mapping via `ownerOf()`.
     */
    mapping (uint256 => address) internal kydyIndexToOwner;

    /**
     * @dev This maps the owner&#39;s address to the number of Kydys that the address owns.
     *  You can view this mapping via `balanceOf()`.
     */
    mapping (address => uint256) internal ownershipTokenCount;

    /**
     * @dev This maps transferring Kydy IDs to the the approved address to call safeTransferFrom().
     *  You can view this mapping via `getApproved()`.
     */
    mapping (uint256 => address) internal kydyIndexToApproved;

    /**
     * @dev This maps KydyIDs to the address approved to synthesize via synthesizeWithAuto().
     *  You can view this mapping via `getSynthesizeApproved()`.
     */
    mapping (uint256 => address) internal synthesizeAllowedToAddress;

    /**
     * @dev This maps the owner to operator approvals, for the usage of setApprovalForAll().
     */
    mapping (address => mapping (address => bool)) private _operatorApprovals;

    /**
     * @dev Returns the owner of the given Kydy ID. Required for ERC-721 compliance.
     * @param _tokenId uint256 ID of the Kydy in query
     * @return the address of the owner of the given Kydy ID
     */
    function ownerOf(uint256 _tokenId) public view returns (address) {
        address owner = kydyIndexToOwner[_tokenId];
        require(owner != address(0));
        return owner;
    }

    /**
     * @dev Returns the approved address of the receiving owner for a Kydy ID. Required for ERC-721 compliance.
     * @param tokenId uint256 ID of the Kydy in query
     * @return the address of the approved, receiving owner for the given Kydy ID
     */
    function getApproved(uint256 tokenId) public view returns (address) {
        require(_exists(tokenId));
        return kydyIndexToApproved[tokenId];
    }

    /**
     * @dev Returns the synthesize approved address of the Kydy ID.
     * @param tokenId uint256 ID of the Kydy in query
     * @return the address of the synthesizing approved of the given Kydy ID
     */
    function getSynthesizeApproved(uint256 tokenId) external view returns (address) {
        require(_exists(tokenId));
        return synthesizeAllowedToAddress[tokenId];
    }

    /**
     * @dev Returns whether an operator is approved by the owner. Required for ERC-721 compliance.
     * @param owner owner address to check whether it is approved
     * @param operator operator address to check whether it is approved
     * @return bool whether the operator is approved or not
     */
    function isApprovedForAll(address owner, address operator) public view returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev Sets or unsets the approval of the operator. Required for ERC-721 compliance.
     * @param to operator address to set the approval
     * @param approved the status to be set
     */
    function setApprovalForAll(address to, bool approved) external {
        require(to != msg.sender);
        _operatorApprovals[msg.sender][to] = approved;
        emit ApprovalForAll(msg.sender, to, approved);
    }

    /// @dev Assigns ownership of this Kydy to an address.
    function _transfer(address _from, address _to, uint256 _tokenId) internal {
        ownershipTokenCount[_to] = ownershipTokenCount[_to].add(1);
        // Transfers the ownership of this Kydy.
        kydyIndexToOwner[_tokenId] = _to;

        ownershipTokenCount[_from] = ownershipTokenCount[_from].sub(1);
        // After a transfer, synthesis allowance is also reset.
        delete synthesizeAllowedToAddress[_tokenId];
        // Clears any previously approved transfer.
        delete kydyIndexToApproved[_tokenId];

        // Emit the transfer event.
        emit Transfer(_from, _to, _tokenId);
    }

    /**
     * @dev Returns whether the given Kydy ID exists
     * @param _tokenId uint256 ID of the Kydy in query
     * @return whether the Kydy exists
     */
    function _exists(uint256 _tokenId) internal view returns (bool) {
        address owner = kydyIndexToOwner[_tokenId];
        return owner != address(0);
    }

    /**
     * @dev Returns whether the given spender can transfer the Kydy ID
     * @param _spender address of the spender to query
     * @param _tokenId uint256 ID of the Kydy to be transferred
     * @return bool whether the msg.sender is approved
     */
    function _isApprovedOrOwner(address _spender, uint256 _tokenId) internal view returns (bool) {
        address owner = ownerOf(_tokenId);
        // Disable solium check because of
        // https://github.com/duaraghav8/Solium/issues/175
        // solium-disable-next-line operator-whitespace
        return (_spender == owner || getApproved(_tokenId) == _spender || isApprovedForAll(owner, _spender));
    }

    /**
     * @dev Internal function to add a Kydy ID to the new owner&#39;s list.
     * @param _to address the new owner&#39;s address
     * @param _tokenId uint256 ID of the transferred Kydy 
     */
    function _addTokenTo(address _to, uint256 _tokenId) internal {
        // Checks if the owner of the Kydy is 0x0 before the transfer.
        require(kydyIndexToOwner[_tokenId] == address(0));
        // Transfers the ownership to the new owner.
        kydyIndexToOwner[_tokenId] = _to;
        // Increases the total Kydy count of the new owner.
        ownershipTokenCount[_to] = ownershipTokenCount[_to].add(1);
    }

    /**
     * @dev Internal function to remove a Kydy ID from the previous owner&#39;s list.
     * @param _from address the previous owner&#39;s address
     * @param _tokenId uint256 ID of the transferred Kydy 
     */
    function _removeTokenFrom(address _from, uint256 _tokenId) internal {
        // Checks the current owner of the Kydy is &#39;_from&#39;.
        require(ownerOf(_tokenId) == _from);
        // Reduces the total Kydy count of the previous owner.
        ownershipTokenCount[_from] = ownershipTokenCount[_from].sub(1);
        // Deletes the transferred Kydy from the current owner&#39;s list.
        kydyIndexToOwner[_tokenId] = address(0);
    }

    /**
     * @dev Internal function to mint a new Kydy.
     * @param _to The address that owns the newly minted Kydy
     * @param _tokenId uint256 ID of the newly minted Kydy
     */
    function _mint(address _to, uint256 _tokenId) internal {
        require(!_exists(_tokenId));
        _addTokenTo(_to, _tokenId);
        emit Transfer(address(0), _to, _tokenId);
    }

    /**
     * @dev Internal function to clear current approvals of a given Kydy ID.
     * @param _owner owner of the Kydy
     * @param _tokenId uint256 ID of the Kydy to be transferred
     */
    function _clearApproval(address _owner, uint256 _tokenId) internal {
        require(ownerOf(_tokenId) == _owner);
        if (kydyIndexToApproved[_tokenId] != address(0)) {
            kydyIndexToApproved[_tokenId] = address(0);
        }
        if (synthesizeAllowedToAddress[_tokenId] != address(0)) {
            synthesizeAllowedToAddress[_tokenId] = address(0);
        }
    }

    /**
     * @dev Internal function that creates a new Kydy and stores it. 
     * @param _yinId The ID of the yin Kydy (zero for Generation 0 Kydy)
     * @param _yangId The ID of the yang Kydy (zero for Generation 0 Kydy)
     * @param _generation The generation number of the new Kydy.
     * @param _genes The Kydy&#39;s gene code
     * @param _owner The owner of this Kydy, must be non-zero (except for the ID 0)
     */
    function _createKydy(
        uint256 _yinId,
        uint256 _yangId,
        uint256 _generation,
        uint256 _genes,
        address _owner
    )
        internal
        returns (uint)
    {
        require(_yinId == uint256(uint32(_yinId)));
        require(_yangId == uint256(uint32(_yangId)));
        require(_generation == uint256(uint16(_generation)));

        // New Kydy&#39;s recharge index is its generation / 2.
        uint16 rechargeIndex = uint16(_generation / 2);
        if (rechargeIndex > 13) {
            rechargeIndex = 13;
        }

        Kydy memory _kyd = Kydy({
            genes: _genes,
            createdTime: uint64(now),
            rechargeEndBlock: 0,
            yinId: uint32(_yinId),
            yangId: uint32(_yangId),
            synthesizingWithId: 0,
            rechargeIndex: rechargeIndex,
            generation: uint16(_generation)
        });
        uint256 newbabyKydyId = kydys.push(_kyd) - 1;

        // Just in case.
        require(newbabyKydyId == uint256(uint32(newbabyKydyId)));

        // Emits the Created event.
        emit Created(
            _owner,
            newbabyKydyId,
            uint256(_kyd.yinId),
            uint256(_kyd.yangId),
            _kyd.genes
        );

        // Here grants ownership, and also emits the Transfer event.
        _mint(_owner, newbabyKydyId);

        return newbabyKydyId;
    }

    // Any C-level roles can change the seconds per block
    function setSecondsPerBlock(uint256 secs) external onlyCLevel {
        require(secs < recharges[0]);
        secondsPerBlock = secs;
    }
}

/**
 * @notice This is MUST to be implemented.
 *  A wallet/broker/auction application MUST implement the wallet interface if it will accept safe transfers.
 * @dev Note: the ERC-165 identifier for this interface is 0x150b7a02.
 */
contract ERC721TokenReceiver {
    /**
     * @notice Handle the receipt of an NFT
     * @dev The ERC721 smart contract calls this function on the recipient
     *  after a `transfer`. This function MAY throw to revert and reject the
     *  transfer. Return of other than the magic value MUST result in the
     *  transaction being reverted.
     *  Note: the contract address is always the message sender.
     * @param _operator The address which called `safeTransferFrom` function
     * @param _from The address which previously owned the token
     * @param _tokenId The NFT identifier which is being transferred
     * @param _data Additional data with no specified format
     * @return `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
     *  unless throwing
     */
    function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes _data) public returns (bytes4);
}

// File: contracts/lib/Strings.sol

library Strings {
    // via https://github.com/oraclize/ethereum-api/blob/master/oraclizeAPI_0.5.sol
    function strConcat(string _a, string _b, string _c, string _d, string _e) internal pure returns (string) {
        bytes memory _ba = bytes(_a);
        bytes memory _bb = bytes(_b);
        bytes memory _bc = bytes(_c);
        bytes memory _bd = bytes(_d);
        bytes memory _be = bytes(_e);
        string memory abcde = new string(_ba.length + _bb.length + _bc.length + _bd.length + _be.length);
        bytes memory babcde = bytes(abcde);
        uint k = 0;
        for (uint i = 0; i < _ba.length; i++) babcde[k++] = _ba[i];
        for (i = 0; i < _bb.length; i++) babcde[k++] = _bb[i];
        for (i = 0; i < _bc.length; i++) babcde[k++] = _bc[i];
        for (i = 0; i < _bd.length; i++) babcde[k++] = _bd[i];
        for (i = 0; i < _be.length; i++) babcde[k++] = _be[i];
        return string(babcde);
    }

    function strConcat(string _a, string _b, string _c, string _d) internal pure returns (string) {
        return strConcat(_a, _b, _c, _d, "");
    }

    function strConcat(string _a, string _b, string _c) internal pure returns (string) {
        return strConcat(_a, _b, _c, "", "");
    }

    function strConcat(string _a, string _b) internal pure returns (string) {
        return strConcat(_a, _b, "", "", "");
    }

    function uint2str(uint i) internal pure returns (string) {
        if (i == 0) return "0";
        uint j = i;
        uint len;
        while (j != 0){
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len - 1;
        while (i != 0){
            bstr[k--] = byte(48 + i % 10);
            i /= 10;
        }
        return string(bstr);
    }
}

/**
 * @title Part of the KydyCore contract that manages ownership, ERC-721 compliant.
 * @author VREX Lab Co., Ltd
 * @dev Ref: https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 *  See the KydyCore contract documentation to understand how the various contracts are arranged.
 */
contract KydyOwnership is KydyBase {
    using Strings for string;

    /// @notice Name and symbol of the non fungible token, as defined in ERC721.
    string public constant _name = "Dyverse";
    string public constant _symbol = "KYDY";

    // Base Server Address for Token MetaData URI
    string internal tokenURIBase = "http://testapi.dyver.se/api/KydyMetadata/";

    // Equals to `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
    // which can be also obtained as `ERC721TokenReceiver(0).onERC721Received.selector`
    bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;

    bytes4 private constant _InterfaceId_ERC165 = 0x01ffc9a7;
    /**
     * 0x01ffc9a7 ===
     *     bytes4(keccak256(&#39;supportsInterface(bytes4)&#39;))
     */

    bytes4 private constant _InterfaceId_ERC721 = 0x80ac58cd;
    /*
     * 0x80ac58cd ===
     *     bytes4(keccak256(&#39;balanceOf(address)&#39;)) ^
     *     bytes4(keccak256(&#39;ownerOf(uint256)&#39;)) ^
     *     bytes4(keccak256(&#39;approve(address,uint256)&#39;)) ^
     *     bytes4(keccak256(&#39;getApproved(uint256)&#39;)) ^
     *     bytes4(keccak256(&#39;setApprovalForAll(address,bool)&#39;)) ^
     *     bytes4(keccak256(&#39;isApprovedForAll(address,address)&#39;)) ^
     *     bytes4(keccak256(&#39;transferFrom(address,address,uint256)&#39;)) ^
     *     bytes4(keccak256(&#39;safeTransferFrom(address,address,uint256)&#39;)) ^
     *     bytes4(keccak256(&#39;safeTransferFrom(address,address,uint256,bytes)&#39;))
     */

    bytes4 private constant _InterfaceId_ERC721Metadata = 0x5b5e139f;
    /**
     * 0x5b5e139f ===
     *     bytes4(keccak256(&#39;name()&#39;)) ^
     *     bytes4(keccak256(&#39;symbol()&#39;)) ^
     *     bytes4(keccak256(&#39;tokenURI(uint256)&#39;))
     */

    constructor() public {
        _registerInterface(_InterfaceId_ERC165);
        // register the supported interfaces to conform to ERC721 via ERC165
        _registerInterface(_InterfaceId_ERC721);
        // register the supported interfaces to conform to ERC721 via ERC165
        _registerInterface(_InterfaceId_ERC721Metadata);
    }

    /**
     * @dev Checks if a given address is the current owner of this Kydy.
     * @param _claimant the address which we want to query the ownership of the Kydy ID.
     * @param _tokenId Kydy id, only valid when > 0
     */
    function _owns(address _claimant, uint256 _tokenId) internal view returns (bool) {
        return kydyIndexToOwner[_tokenId] == _claimant;
    }

    /**
     * @dev Grants an approval to the given address for safeTransferFrom(), overwriting any
     *  previous approval. Setting _approved to address(0) clears all transfer approval.
     *  Note that _approve() does NOT emit the Approval event. This is intentional because
     *  _approve() and safeTransferFrom() are used together when putting Kydys to the auction,
     *  and there is no need to spam the log with Approval events in that case.
     */
    function _approve(uint256 _tokenId, address _approved) internal {
        kydyIndexToApproved[_tokenId] = _approved;
    }

    /**
     * @dev Transfers a Kydy owned by this contract to the specified address.
     *  Used to rescue lost Kydys. (There is no "proper" flow where this contract
     *  should be the owner of any Kydy. This function exists for us to reassign
     *  the ownership of Kydys that users may have accidentally sent to our address.)
     * @param _kydyId ID of the lost Kydy
     * @param _recipient address to send the Kydy to
     */
    function rescueLostKydy(uint256 _kydyId, address _recipient) external onlyCOO whenNotPaused {
        require(_owns(this, _kydyId));
        _transfer(this, _recipient, _kydyId);
    }

    /**
     * @dev Gets the number of Kydys owned by the given address.
     *  Required for ERC-721 compliance.
     * @param _owner address to query the balance of
     * @return uint256 representing the amount owned by the passed address
     */
    function balanceOf(address _owner) public view returns (uint256) {
        require(_owner != address(0));
        return ownershipTokenCount[_owner];
    }

    /**
     * @dev Approves another address to transfer the given Kydy ID.
     *  The zero address indicates that there is no approved address.
     *  There can only be one approved address per Kydy at a given time.
     *  Can only be called by the Kydy owner or an approved operator.
     *  Required for ERC-721 compliance.
     * @param to address to be approved for the given Kydy ID
     * @param tokenId uint256 ID of the Kydy to be approved
     */
    function approve(address to, uint256 tokenId) external whenNotPaused {
        address owner = ownerOf(tokenId);
        require(to != owner);
        // Owner or approved operator by owner can approve the another address
        // to transfer the Kydy.
        require(msg.sender == owner || isApprovedForAll(owner, msg.sender));

        // Approves the given address.
        _approve(tokenId, to);

        // Emits the Approval event.
        emit Approval(owner, to, tokenId);
    }

    /**
     * @dev Transfers the ownership of the Kydy to another address.
     *  Usage of this function is discouraged, use `safeTransferFrom` whenever possible.
     *  Requires the msg sender to be the owner, approved, or operator.
     *  Required for ERC-721 compliance.
     * @param from current owner of the Kydy
     * @param to address to receive the ownership of the given Kydy ID
     * @param tokenId uint256 ID of the Kydy to be transferred
     */
    function transferFrom(address from, address to, uint256 tokenId) public whenNotPaused {
        // Checks the caller is the owner or approved one or an operator.
        require(_isApprovedOrOwner(msg.sender, tokenId));
        // Safety check to prevent from transferring Kydy to 0x0 address.
        require(to != address(0));

        // Clears approval from current owner.
        _clearApproval(from, tokenId);
        // Resets the ownership of this Kydy from current owner and sets it to 0x0.
        _removeTokenFrom(from, tokenId);
        // Grants the ownership of this Kydy to new owner.
        _addTokenTo(to, tokenId);

        // Emits the Transfer event.
        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Safely transfers the ownership of a given Kydy to another address.
     *  If the target address is a contract, it must implement `onERC721Received`,
     *  which is called upon a safe transfer, and return the magic value
     *  `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`;
     *  Otherwise, the transfer is reverted.
     *  Requires the msg sender to be the owner, approved, or operator.
     *  Required for ERC-721 compliance.
     * @param from current owner of the Kydy
     * @param to address to receive the ownership of the given Kydy ID
     * @param tokenId uint256 ID of the Kydy to be transferred
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public {
        // solium-disable-next-line arg-overflow
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev Safely transfers the ownership of a given Kydy to another address.
     *  If the target address is a contract, it must implement `onERC721Received`,
     *  which is called upon a safe transfer, and return the magic value
     *  `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`;
     *  Otherwise, the transfer is reverted.
     *  Requires the msg sender to be the owner, approved, or operator.
     *  Required for ERC-721 compliance.
     * @param from current owner of the Kydy
     * @param to address to receive the ownership of the given Kydy ID
     * @param tokenId uint256 ID of the Kydy to be transferred
     * @param _data bytes data to send along with a safe transfer check
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes _data) public {
        transferFrom(from, to, tokenId);
        // solium-disable-next-line arg-overflow
        require(_checkOnERC721Received(from, to, tokenId, _data));
    }

    /**
     * @dev Internal function to invoke `onERC721Received` on a target address.
     *  This function is not executed if the target address is not a contract.
     * @param _from address representing the previous owner of the given Kydy ID
     * @param _to target address that will receive the Kydys
     * @param _tokenId uint256 ID of the Kydy to be transferred
     * @param _data bytes optional data to send along with the call
     * @return whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(address _from, address _to, uint256 _tokenId, bytes _data) internal returns (bool) {
        if (!_to.isContract()) {
            return true;
        }

        bytes4 retval = ERC721TokenReceiver(_to).onERC721Received(msg.sender, _from, _tokenId, _data);
        return (retval == _ERC721_RECEIVED);
    }
    
    /**
     * @dev Gets the token name.
     *  Required for ERC721Metadata compliance.
     * @return string representing the token name
     */
    function name() external view returns (string) {
        return _name;
    }

    /**
     * @dev Gets the token symbol.
     *  Required for ERC721Metadata compliance.
     * @return string representing the token symbol
     */
    function symbol() external view returns (string) {
        return _symbol;
    }

    /**
     * @dev Returns an URI for a given Kydy ID.
     *  Throws if the token ID does not exist. May return an empty string.
     *  Required for ERC721Metadata compliance.
     * @param tokenId uint256 ID of the token to query
     */
    function tokenURI(uint256 tokenId) external view returns (string) {
        require(_exists(tokenId));
        return Strings.strConcat(
            tokenURIBase,
            Strings.uint2str(tokenId)
        );
    }

    /**
     * @dev Gets the total amount of Kydys stored in the contract
     * @return uint256 representing the total amount of Kydys
     */
    function totalSupply() public view returns (uint256) {
        return kydys.length - 1;
    }

    /**
     * @notice Returns a list of all Kydy IDs assigned to an address.
     * @param _owner The owner whose Kydys we are interested in.
     * @dev This function MUST NEVER be called by smart contract code. It&#39;s pretty
     *  expensive (it looks into the entire Kydy array looking for Kydys belonging to owner),
     *  and it also returns a dynamic array, which is only supported for web3 calls, and
     *  not contract-to-contract calls.
     */
    function tokensOfOwner(address _owner) external view returns(uint256[] ownerTokens) {
        uint256 tokenCount = balanceOf(_owner);

        if (tokenCount == 0) {
            // Return an empty array
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 totalKydys = totalSupply();
            uint256 resultIndex = 0;

            // All Kydys have IDs starting at 1 and increasing sequentially up to the totalKydy count.
            uint256 kydyId;

            for (kydyId = 1; kydyId <= totalKydys; kydyId++) {
                if (kydyIndexToOwner[kydyId] == _owner) {
                    result[resultIndex] = kydyId;
                    resultIndex++;
                }
            }

            return result;
        }
    }
}

/**
 * @title This manages synthesis and creation of Kydys.
 * @author VREX Lab Co., Ltd
 * @dev Please reference the KydyCore contract for details. 
 */
contract KydySynthesis is KydyOwnership {

    /**
     * @dev The Creating event is emitted when two Kydys synthesize and the creation
     *  timer begins by the yin.
     */
    event Creating(address owner, uint256 yinId, uint256 yangId, uint256 rechargeEndBlock);

    /**
     * @notice The minimum payment required for synthesizeWithAuto(). This fee is for
     *  the gas cost paid by whoever calls bringKydyHome(), and can be updated by the COO address.
     */
    uint256 public autoCreationFee = 14 finney;

    // Number of the Kydys that are creating a new Kydy.
    uint256 public creatingKydys;

    /**
     * @dev The address of the sibling contract that mixes and combines genes of the two parent Kydys. 
     */
    GeneSynthesisInterface public geneSynthesis;

    /**
     * @dev Updates the address of the genetic contract. Only CEO may call this function.
     * @param _address An address of the new GeneSynthesis contract instance.
     */
    function setGeneSynthesisAddress(address _address) external onlyCEO {
        GeneSynthesisInterface candidateContract = GeneSynthesisInterface(_address);

        // Verifies that the contract is valid.
        require(candidateContract.isGeneSynthesis());

        // Sets the new GeneSynthesis contract address.
        geneSynthesis = candidateContract;
    }

    /**
     * @dev Checks that the Kydy is able to synthesize. 
     */
    function _isReadyToSynthesize(Kydy _kyd) internal view returns (bool) {
        // Double-checking if there is any pending creation event. 
        return (_kyd.synthesizingWithId == 0) && (_kyd.rechargeEndBlock <= uint64(block.number));
    }

    /**
     * @dev Checks if a yang Kydy has been approved to synthesize with this yin Kydy.
     */
    function _isSynthesizingAllowed(uint256 _yangId, uint256 _yinId) internal view returns (bool) {
        address yinOwner = kydyIndexToOwner[_yinId];
        address yangOwner = kydyIndexToOwner[_yangId];

        return (yinOwner == yangOwner || synthesizeAllowedToAddress[_yangId] == yinOwner);
    }

    /**
     * @dev Sets the rechargeEndTime for the given Kydy, based on its current rechargeIndex.
     *  The rechargeIndex increases until it hits the cap.
     * @param _kyd A reference to the Kydy that needs its timer to be started.
     */
    function _triggerRecharge(Kydy storage _kyd) internal {
        // Computes the approximation of the end of recharge time in blocks (based on current rechargeIndex).
        _kyd.rechargeEndBlock = uint64((recharges[_kyd.rechargeIndex] / secondsPerBlock) + block.number);

        // Increases this Kydy&#39;s synthesizing count, and the cap is fixed at 12.
        if (_kyd.rechargeIndex < 12) {
            _kyd.rechargeIndex += 1;
        }
    }

    /**
     * @notice Grants approval to another user to synthesize with one of your Kydys.
     * @param _address The approved address of the yin Kydy that can synthesize with your yang Kydy. 
     * @param _yangId Your kydy that _address can now synthesize with.
     */
    function approveSynthesizing(address _address, uint256 _yangId)
        external
        whenNotPaused
    {
        require(_owns(msg.sender, _yangId));
        synthesizeAllowedToAddress[_yangId] = _address;
    }

    /**
     * @dev Updates the minimum payment required for calling bringKydyHome(). Only COO
     *  can call this function. 
     */
    function setAutoCreationFee(uint256 value) external onlyCOO {
        autoCreationFee = value;
    }

    /// @dev Checks if this Kydy is creating and if the creation period is complete. 
    function _isReadyToBringKydyHome(Kydy _yin) private view returns (bool) {
        return (_yin.synthesizingWithId != 0) && (_yin.rechargeEndBlock <= uint64(block.number));
    }

    /**
     * @notice Checks if this Kydy is able to synthesize 
     * @param _kydyId reference the ID of the Kydy
     */
    function isReadyToSynthesize(uint256 _kydyId)
        public
        view
        returns (bool)
    {
        require(_kydyId > 0);
        Kydy storage kyd = kydys[_kydyId];
        return _isReadyToSynthesize(kyd);
    }

    /**
     * @dev Checks if the Kydy is currently creating.
     * @param _kydyId reference the ID of the Kydy
     */
    function isCreating(uint256 _kydyId)
        public
        view
        returns (bool)
    {
        require(_kydyId > 0);

        return kydys[_kydyId].synthesizingWithId != 0;
    }

    /**
     * @dev Internal check to see if these yang and yin are a valid couple. 
     * @param _yin A reference to the Kydy struct of the potential yin.
     * @param _yinId The yin&#39;s ID.
     * @param _yang A reference to the Kydy struct of the potential yang.
     * @param _yangId The yang&#39;s ID
     */
    function _isValidCouple(
        Kydy storage _yin,
        uint256 _yinId,
        Kydy storage _yang,
        uint256 _yangId
    )
        private
        view
        returns(bool)
    {
        // Kydy can&#39;t synthesize with itself.
        if (_yinId == _yangId) {
            return false;
        }

        // Kydys can&#39;t synthesize with their parents.
        if (_yin.yinId == _yangId || _yin.yangId == _yangId) {
            return false;
        }
        if (_yang.yinId == _yinId || _yang.yangId == _yinId) {
            return false;
        }

        // Skip sibling check for Gen 0
        if (_yang.yinId == 0 || _yin.yinId == 0) {
            return true;
        }

        // Kydys can&#39;t synthesize with full or half siblings.
        if (_yang.yinId == _yin.yinId || _yang.yinId == _yin.yangId) {
            return false;
        }
        if (_yang.yangId == _yin.yinId || _yang.yangId == _yin.yangId) {
            return false;
        }
        return true;
    }

    /**
     * @dev Internal check to see if these yang and yin Kydys, connected via market, are a valid couple for synthesis. 
     */
    function _canSynthesizeWithViaAuction(uint256 _yinId, uint256 _yangId)
        internal
        view
        returns (bool)
    {
        Kydy storage yin = kydys[_yinId];
        Kydy storage yang = kydys[_yangId];
        return _isValidCouple(yin, _yinId, yang, _yangId);
    }

    /**
     * @dev Checks if the two Kydys can synthesize together, including checks for ownership and synthesizing approvals. 
     * @param _yinId ID of the yin Kydy
     * @param _yangId ID of the yang Kydy
     */
    function canSynthesizeWith(uint256 _yinId, uint256 _yangId)
        external
        view
        returns(bool)
    {
        require(_yinId > 0);
        require(_yangId > 0);
        Kydy storage yin = kydys[_yinId];
        Kydy storage yang = kydys[_yangId];
        return _isValidCouple(yin, _yinId, yang, _yangId) &&
            _isSynthesizingAllowed(_yangId, _yinId);
    }

    /**
     * @dev Internal function to start synthesizing, when all the conditions are met
     */
    function _synthesizeWith(uint256 _yinId, uint256 _yangId) internal {
        Kydy storage yang = kydys[_yangId];
        Kydy storage yin = kydys[_yinId];

        // Marks this yin as creating, and make note of who the yang Kydy is.
        yin.synthesizingWithId = uint32(_yangId);

        // Triggers the recharge for both parents.
        _triggerRecharge(yang);
        _triggerRecharge(yin);

        // Clears synthesizing permission for both parents, just in case.
        delete synthesizeAllowedToAddress[_yinId];
        delete synthesizeAllowedToAddress[_yangId];

        // When a Kydy starts creating, this number is increased. 
        creatingKydys++;

        // Emits the Creating event.
        emit Creating(kydyIndexToOwner[_yinId], _yinId, _yangId, yin.rechargeEndBlock);
    }

    /**
     * @dev Synthesis between two approved Kydys. Requires a pre-payment of the fee to the first caller of bringKydyHome().
     * @param _yinId ID of the Kydy which will be a yin (will start creation if successful)
     * @param _yangId ID of the Kydy which will be a yang (will begin its synthesizing cooldown if successful)
     */
    function synthesizeWithAuto(uint256 _yinId, uint256 _yangId)
        external
        payable
        whenNotPaused
    {
        // Checks for pre-payment.
        require(msg.value >= autoCreationFee);

        // Caller must be the yin&#39;s owner.
        require(_owns(msg.sender, _yinId));

        // Checks if the caller has valid authority for this synthesis
        require(_isSynthesizingAllowed(_yangId, _yinId));

        // Gets a reference of the potential yin.
        Kydy storage yin = kydys[_yinId];

        // Checks that the potential yin is ready to synthesize
        require(_isReadyToSynthesize(yin));

        // Gets a reference of the potential yang.
        Kydy storage yang = kydys[_yangId];

        // Checks that the potential yang is ready to synthesize
        require(_isReadyToSynthesize(yang));

        // Checks that these Kydys are a valid couple.
        require(_isValidCouple(
            yin,
            _yinId,
            yang,
            _yangId
        ));

        // All checks passed! Yin Kydy starts creating.
        _synthesizeWith(_yinId, _yangId);

    }

    /**
     * @notice Let&#39;s bring the new Kydy to it&#39;s home!
     * @param _yinId A Kydy which is ready to bring the newly created Kydy to home.
     * @return The Kydy ID of the newly created Kydy.
     * @dev The newly created Kydy is transferred to the owner of the yin Kydy. Anyone is welcome to call this function.
     */
    function bringKydyHome(uint256 _yinId)
        external
        whenNotPaused
        returns(uint256)
    {
        // Gets a reference of the yin from storage.
        Kydy storage yin = kydys[_yinId];

        // Checks that the yin is a valid Kydy.
        require(yin.createdTime != 0);

        // Checks that the yin is in creation mode, and the creating period is over.
        require(_isReadyToBringKydyHome(yin));

        // Gets a reference of the yang from storage.
        uint256 yangId = yin.synthesizingWithId;
        Kydy storage yang = kydys[yangId];

        // Ascertains which has the higher generation number between the two parents.
        uint16 parentGen = yin.generation;
        if (yang.generation > yin.generation) {
            parentGen = yang.generation;
        }

        // The baby Kydy receives its genes 
        uint256 childGenes = geneSynthesis.synthGenes(yin.genes, yang.genes);

        // The baby Kydy is now on blockchain
        address owner = kydyIndexToOwner[_yinId];
        uint256 kydyId = _createKydy(_yinId, yin.synthesizingWithId, parentGen + 1, childGenes, owner);

        // Clears the synthesis status of the parents
        delete yin.synthesizingWithId;

        // When a baby Kydy is created, this number is decreased back. 
        creatingKydys--;

        // Sends the fee to the person who called this. 
        msg.sender.transfer(autoCreationFee);

        // Returns the new Kydy&#39;s ID.
        return kydyId;
    }
}

contract ERC721Holder is ERC721TokenReceiver {
    function onERC721Received(address, address, uint256, bytes) public returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

/**
 * @title Base auction contract of the Dyverse
 * @author VREX Lab Co., Ltd
 * @dev Contains necessary functions and variables for the auction.
 *  Inherits `ERC721Holder` contract which is the implementation of the `ERC721TokenReceiver`.
 *  This is to accept safe transfers.
 */
contract AuctionBase is ERC721Holder {
    using SafeMath for uint256;

    // Represents an auction on an NFT
    struct Auction {
        // Current owner of NFT
        address seller;
        // Price (in wei) of NFT
        uint128 price;
        // Time when the auction started
        // NOTE: 0 if this auction has been concluded
        uint64 startedAt;
    }

    // Reference to contract tracking NFT ownership
    ERC721Basic public nonFungibleContract;

    // The amount owner takes from the sale, (in basis points, which are 1/100 of a percent).
    uint256 public ownerCut;

    // Maps token ID to it&#39;s corresponding auction.
    mapping (uint256 => Auction) tokenIdToAuction;

    event AuctionCreated(uint256 tokenId, uint256 price);
    event AuctionSuccessful(uint256 tokenId, uint256 totalPrice, address bidder);
    event AuctionCanceled(uint256 tokenId);

    /// @dev Disables sending funds to this contract.
    function() external {}

    /// @dev A modifier to check if the given value can fit in 64-bits.
    modifier canBeStoredWith64Bits(uint256 _value) {
        require(_value <= (2**64 - 1));
        _;
    }

    /// @dev A modifier to check if the given value can fit in 128-bits.
    modifier canBeStoredWith128Bits(uint256 _value) {
        require(_value <= (2**128 - 1));
        _;
    }

    /**
     * @dev Returns true if the claimant owns the token.
     * @param _claimant An address which to query the ownership of the token.
     * @param _tokenId ID of the token to query the owner of.
     */
    function _owns(address _claimant, uint256 _tokenId) internal view returns (bool) {
        return (nonFungibleContract.ownerOf(_tokenId) == _claimant);
    }

    /**
     * @dev Escrows the NFT. Grants the ownership of the NFT to this contract safely.
     *  Throws if the escrow fails.
     * @param _owner Current owner of the token.
     * @param _tokenId ID of the token to escrow.
     */
    function _escrow(address _owner, uint256 _tokenId) internal {
        nonFungibleContract.safeTransferFrom(_owner, this, _tokenId);
    }

    /**
     * @dev Transfers an NFT owned by this contract to another address safely.
     * @param _receiver The receiving address of NFT.
     * @param _tokenId ID of the token to transfer.
     */
    function _transfer(address _receiver, uint256 _tokenId) internal {
        nonFungibleContract.safeTransferFrom(this, _receiver, _tokenId);
    }

    /**
     * @dev Adds an auction to the list of open auctions. 
     * @param _tokenId ID of the token to be put on auction.
     * @param _auction Auction information of this token to open.
     */
    function _addAuction(uint256 _tokenId, Auction _auction) internal {
        tokenIdToAuction[_tokenId] = _auction;

        emit AuctionCreated(
            uint256(_tokenId),
            uint256(_auction.price)
        );
    }

    /// @dev Cancels the auction which the _seller wants.
    function _cancelAuction(uint256 _tokenId, address _seller) internal {
        _removeAuction(_tokenId);
        _transfer(_seller, _tokenId);
        emit AuctionCanceled(_tokenId);
    }

    /**
     * @dev Computes the price and sends it to the seller.
     *  Note that this does NOT transfer the ownership of the token.
     */
    function _bid(uint256 _tokenId, uint256 _bidAmount)
        internal
        returns (uint256)
    {
        // Gets a reference of the token from auction storage.
        Auction storage auction = tokenIdToAuction[_tokenId];

        // Checks that this auction is currently open
        require(_isOnAuction(auction));

        // Checks that the bid is greater than or equal to the current token price.
        uint256 price = _currentPrice(auction);
        require(_bidAmount >= price);

        // Gets a reference of the seller before the auction gets deleted.
        address seller = auction.seller;

        // Removes the auction before sending the proceeds to the sender
        _removeAuction(_tokenId);

        // Transfers proceeds to the seller.
        if (price > 0) {
            uint256 auctioneerCut = _computeCut(price);
            uint256 sellerProceeds = price.sub(auctioneerCut);

            seller.transfer(sellerProceeds);
        }

        // Computes the excess funds included with the bid and transfers it back to bidder. 
        uint256 bidExcess = _bidAmount - price;

        // Returns the exceeded funds.
        msg.sender.transfer(bidExcess);

        // Emits the AuctionSuccessful event.
        emit AuctionSuccessful(_tokenId, price, msg.sender);

        return price;
    }

    /**
     * @dev Removes an auction from the list of open auctions.
     * @param _tokenId ID of the NFT on auction to be removed.
     */
    function _removeAuction(uint256 _tokenId) internal {
        delete tokenIdToAuction[_tokenId];
    }

    /**
     * @dev Returns true if the NFT is on auction.
     * @param _auction An auction to check if it exists.
     */
    function _isOnAuction(Auction storage _auction) internal view returns (bool) {
        return (_auction.startedAt > 0);
    }

    /// @dev Returns the current price of an NFT on auction.
    function _currentPrice(Auction storage _auction)
        internal
        view
        returns (uint256)
    {
        return _auction.price;
    }

    /**
     * @dev Computes the owner&#39;s receiving amount from the sale.
     * @param _price Sale price of the NFT.
     */
    function _computeCut(uint256 _price) internal view returns (uint256) {
        return _price * ownerCut / 10000;
    }
}

contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  constructor() public {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
}

contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;

  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  modifier whenPaused() {
    require(paused);
    _;
  }

  function pause() onlyOwner whenNotPaused public {
    paused = true;
    emit Pause();
  }

  function unpause() onlyOwner whenPaused public {
    paused = false;
    emit Unpause();
  }
}

/**
 * @title Auction for NFT.
 * @author VREX Lab Co., Ltd
 */
contract Auction is Pausable, AuctionBase {

    /**
     * @dev Removes all Ether from the contract to the NFT contract.
     */
    function withdrawBalance() external {
        address nftAddress = address(nonFungibleContract);

        require(
            msg.sender == owner ||
            msg.sender == nftAddress
        );
        nftAddress.transfer(address(this).balance);
    }

    /**
     * @dev Creates and begins a new auction.
     * @param _tokenId ID of the token to creat an auction, caller must be it&#39;s owner.
     * @param _price Price of the token (in wei).
     * @param _seller Seller of this token.
     */
    function createAuction(
        uint256 _tokenId,
        uint256 _price,
        address _seller
    )
        external
        whenNotPaused
        canBeStoredWith128Bits(_price)
    {
        require(_owns(msg.sender, _tokenId));
        _escrow(msg.sender, _tokenId);
        Auction memory auction = Auction(
            _seller,
            uint128(_price),
            uint64(now)
        );
        _addAuction(_tokenId, auction);
    }

    /**
     * @dev Bids on an open auction, completing the auction and transferring
     *  ownership of the NFT if enough Ether is supplied.
     * @param _tokenId - ID of token to bid on.
     */
    function bid(uint256 _tokenId)
        external
        payable
        whenNotPaused
    {
        _bid(_tokenId, msg.value);
        _transfer(msg.sender, _tokenId);
    }

    /**
     * @dev Cancels an auction and returns the NFT to the current owner.
     * @param _tokenId ID of the token on auction to cancel.
     * @param _seller The seller&#39;s address.
     */
    function cancelAuction(uint256 _tokenId, address _seller)
        external
    {
        // Requires that this function should only be called from the
        // `cancelSaleAuction()` of NFT ownership contract. This function gets
        // the _seller directly from it&#39;s arguments, so if this check doesn&#39;t
        // exist, then anyone can cancel the auction! OMG!
        require(msg.sender == address(nonFungibleContract));
        Auction storage auction = tokenIdToAuction[_tokenId];
        require(_isOnAuction(auction));
        address seller = auction.seller;
        require(_seller == seller);
        _cancelAuction(_tokenId, seller);
    }

    /**
     * @dev Cancels an auction when the contract is paused.
     * Only the owner may do this, and NFTs are returned to the seller. 
     * @param _tokenId ID of the token on auction to cancel.
     */
    function cancelAuctionWhenPaused(uint256 _tokenId)
        external
        whenPaused
        onlyOwner
    {
        Auction storage auction = tokenIdToAuction[_tokenId];
        require(_isOnAuction(auction));
        _cancelAuction(_tokenId, auction.seller);
    }

    /**
     * @dev Returns the auction information for an NFT
     * @param _tokenId ID of the NFT on auction
     */
    function getAuction(uint256 _tokenId)
        external
        view
        returns
    (
        address seller,
        uint256 price,
        uint256 startedAt
    ) {
        Auction storage auction = tokenIdToAuction[_tokenId];
        require(_isOnAuction(auction));
        return (
            auction.seller,
            auction.price,
            auction.startedAt
        );
    }

    /**
     * @dev Returns the current price of the token on auction.
     * @param _tokenId ID of the token
     */
    function getCurrentPrice(uint256 _tokenId)
        external
        view
        returns (uint256)
    {
        Auction storage auction = tokenIdToAuction[_tokenId];
        require(_isOnAuction(auction));
        return _currentPrice(auction);
    }
}

/**
 * @title  Auction for synthesizing
 * @author VREX Lab Co., Ltd
 * @notice Reset fallback function to prevent accidental fund sending to this contract.
 */
contract SynthesizingAuction is Auction {

    /**
     * @dev Sanity check that allows us to ensure that we are pointing to the
     *  right auction in our `setSynthesizingAuctionAddress()` call.
     */
    bool public isSynthesizingAuction = true;

    /**
     * @dev Creates a reference to the NFT ownership contract and checks the owner cut is valid
     * @param _nftAddress Address of a deployed NFT interface contract
     * @param _cut Percent cut which the owner takes on each auction, between 0-10,000.
     */
    constructor(address _nftAddress, uint256 _cut) public {
        require(_cut <= 10000);
        ownerCut = _cut;

        ERC721Basic candidateContract = ERC721Basic(_nftAddress);
        nonFungibleContract = candidateContract;
    }

    /**
     * @dev Creates and begins a new auction. Since this function is wrapped,
     *  requires the caller to be KydyCore contract.
     * @param _tokenId ID of token to auction, sender must be it&#39;s owner.
     * @param _price Price of the token (in wei).
     * @param _seller Seller of this token.
     */
    function createAuction(
        uint256 _tokenId,
        uint256 _price,
        address _seller
    )
        external
        canBeStoredWith128Bits(_price)
    {
        require(msg.sender == address(nonFungibleContract));
        _escrow(_seller, _tokenId);
        Auction memory auction = Auction(
            _seller,
            uint128(_price),
            uint64(now)
        );
        _addAuction(_tokenId, auction);
    }

    /**
     * @dev Places a bid for synthesizing. Requires the caller
     *  is the KydyCore contract because all bid functions
     *  should be wrapped. Also returns the Kydy to the
     *  seller rather than the bidder.
     */
    function bid(uint256 _tokenId)
        external
        payable
    {
        require(msg.sender == address(nonFungibleContract));
        address seller = tokenIdToAuction[_tokenId].seller;
        // _bid() checks that the token ID is valid and will throw if bid fails
        _bid(_tokenId, msg.value);
        // Transfers the Kydy back to the seller, and the bidder will get
        // the baby Kydy.
        _transfer(seller, _tokenId);
    }
}

/**
 * @title Auction for sale of Kydys.
 * @author VREX Lab Co., Ltd
 */
contract SaleAuction is Auction {

    /**
     * @dev To make sure we are addressing to the right auction. 
     */
    bool public isSaleAuction = true;

    // Last 5 sale price of Generation 0 Kydys.
    uint256[5] public lastGen0SalePrices;
    
    // Total number of Generation 0 Kydys sold.
    uint256 public gen0SaleCount;

    /**
     * @dev Creates a reference to the NFT ownership contract and checks the owner cut is valid
     * @param _nftAddress Address of a deployed NFT interface contract
     * @param _cut Percent cut which the owner takes on each auction, between 0-10,000.
     */
    constructor(address _nftAddress, uint256 _cut) public {
        require(_cut <= 10000);
        ownerCut = _cut;

        ERC721Basic candidateContract = ERC721Basic(_nftAddress);
        nonFungibleContract = candidateContract;
    }

    /**
     * @dev Creates and begins a new auction.
     * @param _tokenId ID of token to auction, sender must be it&#39;s owner.
     * @param _price Price of the token (in wei).
     * @param _seller Seller of this token.
     */
    function createAuction(
        uint256 _tokenId,
        uint256 _price,
        address _seller
    )
        external
        canBeStoredWith128Bits(_price)
    {
        require(msg.sender == address(nonFungibleContract));
        _escrow(_seller, _tokenId);
        Auction memory auction = Auction(
            _seller,
            uint128(_price),
            uint64(now)
        );
        _addAuction(_tokenId, auction);
    }

    /**
     * @dev Updates lastSalePrice only if the seller is nonFungibleContract. 
     */
    function bid(uint256 _tokenId)
        external
        payable
    {
        // _bid verifies token ID
        address seller = tokenIdToAuction[_tokenId].seller;
        uint256 price = _bid(_tokenId, msg.value);
        _transfer(msg.sender, _tokenId);

        // If the last sale was not Generation 0 Kydy&#39;s, the lastSalePrice doesn&#39;t change.
        if (seller == address(nonFungibleContract)) {
            // Tracks gen0&#39;s latest sale prices.
            lastGen0SalePrices[gen0SaleCount % 5] = price;
            gen0SaleCount++;
        }
    }

    /// @dev Gives the new average Generation 0 sale price after each Generation 0 Kydy sale.
    function averageGen0SalePrice() external view returns (uint256) {
        uint256 sum = 0;
        for (uint256 i = 0; i < 5; i++) {
            sum = sum.add(lastGen0SalePrices[i]);
        }
        return sum / 5;
    }
}

/**
 * @title This contract defines how sales and synthesis auctions for Kydys are created. 
 * @author VREX Lab Co., Ltd
 */
contract KydyAuction is KydySynthesis {

    /**
     * @dev The address of the Auction contract which handles ALL sales of Kydys, both user-generated and Generation 0. 
     */
    SaleAuction public saleAuction;

    /**
     * @dev The address of another Auction contract which handles synthesis auctions. 
     */
    SynthesizingAuction public synthesizingAuction;

    /**
     * @dev Sets the address for the sales auction. Only CEO may call this function. 
     * @param _address The address of the sale contract.
     */
    function setSaleAuctionAddress(address _address) external onlyCEO {
        SaleAuction candidateContract = SaleAuction(_address);

        // Verifies that the contract is correct
        require(candidateContract.isSaleAuction());

        // Sets the new sale auction contract address.
        saleAuction = candidateContract;
    }

    /**
     * @dev Sets the address to the synthesis auction. Only CEO may call this function.
     * @param _address The address of the synthesis contract.
     */
    function setSynthesizingAuctionAddress(address _address) external onlyCEO {
        SynthesizingAuction candidateContract = SynthesizingAuction(_address);

        require(candidateContract.isSynthesizingAuction());

        synthesizingAuction = candidateContract;
    }

    /**
     * @dev Creates a Kydy sale.
     */
    function createSaleAuction(
        uint256 _kydyId,
        uint256 _price
    )
        external
        whenNotPaused
    {
        require(_owns(msg.sender, _kydyId));
        require(!isCreating(_kydyId));
        _approve(_kydyId, saleAuction);
 
        saleAuction.createAuction(
            _kydyId,
            _price,
            msg.sender
        );
    }

    /**
     * @dev Creates a synthesis auction. 
     */
    function createSynthesizingAuction(
        uint256 _kydyId,
        uint256 _price
    )
        external
        whenNotPaused
    {
        require(_owns(msg.sender, _kydyId));
        require(isReadyToSynthesize(_kydyId));
        _approve(_kydyId, synthesizingAuction);

        synthesizingAuction.createAuction(
            _kydyId,
            _price,
            msg.sender
        );
    }

    /**
     * @dev After bidding for a synthesis auction is accepted, this starts the actual synthesis process.
     * @param _yangId ID of the yang Kydy on the synthesis auction.
     * @param _yinId ID of the yin Kydy owned by the bidder.
     */
    function bidOnSynthesizingAuction(
        uint256 _yangId,
        uint256 _yinId
    )
        external
        payable
        whenNotPaused
    {
        require(_owns(msg.sender, _yinId));
        require(isReadyToSynthesize(_yinId));
        require(_canSynthesizeWithViaAuction(_yinId, _yangId));

        uint256 currentPrice = synthesizingAuction.getCurrentPrice(_yangId);

        require (msg.value >= currentPrice + autoCreationFee);

        synthesizingAuction.bid.value(msg.value - autoCreationFee)(_yangId);

        _synthesizeWith(uint32(_yinId), uint32(_yangId));
    }

    /**
     * @dev Cancels a sale and returns the Kydy back to the owner.
     * @param _kydyId ID of the Kydy on sale that the owner wishes to cancel.
     */
    function cancelSaleAuction(
        uint256 _kydyId
    )
        external
        whenNotPaused
    {
        // Checks if the Kydy is in auction. 
        require(_owns(saleAuction, _kydyId));
        // Gets the seller of the Kydy.
        (address seller,,) = saleAuction.getAuction(_kydyId);
        // Checks that the caller is the real seller.
        require(msg.sender == seller);
        // Cancels the sale auction of this kydy by it&#39;s seller&#39;s request.
        saleAuction.cancelAuction(_kydyId, msg.sender);
    }

    /**
     * @dev Cancels an synthesis auction. 
     * @param _kydyId ID of the Kydy on the synthesis auction. 
     */
    function cancelSynthesizingAuction(
        uint256 _kydyId
    )
        external
        whenNotPaused
    {
        require(_owns(synthesizingAuction, _kydyId));
        (address seller,,) = synthesizingAuction.getAuction(_kydyId);
        require(msg.sender == seller);
        synthesizingAuction.cancelAuction(_kydyId, msg.sender);
    }

    /**
     * @dev Transfers the balance. 
     */
    function withdrawAuctionBalances() external onlyCLevel {
        saleAuction.withdrawBalance();
        synthesizingAuction.withdrawBalance();
    }
}

/**
 * @title All functions related to creating Kydys
 * @author VREX Lab Co., Ltd
 */
contract KydyMinting is KydyAuction {

    // Limits of the number of Kydys that COO can create.
    uint256 public constant promoCreationLimit = 888;
    uint256 public constant gen0CreationLimit = 8888;

    uint256 public constant gen0StartingPrice = 10 finney;

    // Counts the number of Kydys that COO has created.
    uint256 public promoCreatedCount;
    uint256 public gen0CreatedCount;

    /**
     * @dev Creates promo Kydys, up to a limit. Only COO can call this function.
     * @param _genes Encoded genes of the Kydy to be created.
     * @param _owner Future owner of the created Kydys. COO is the default owner.
     */
    function createPromoKydy(uint256 _genes, address _owner) external onlyCOO {
        address kydyOwner = _owner;
        if (kydyOwner == address(0)) {
            kydyOwner = cooAddress;
        }
        require(promoCreatedCount < promoCreationLimit);

        promoCreatedCount++;
        _createKydy(0, 0, 0, _genes, kydyOwner);
    }

    /**
     * @dev Creates a new gen0 Kydy with the given genes and
     *  creates an sale auction of it.
     */
    function createGen0Auction(uint256 _genes) external onlyCOO {
        require(gen0CreatedCount < gen0CreationLimit);

        uint256 kydyId = _createKydy(0, 0, 0, _genes, address(this));
        _approve(kydyId, saleAuction);

        saleAuction.createAuction(
            kydyId,
            _computeNextGen0Price(),
            address(this)
        );

        gen0CreatedCount++;
    }

    /**
     * @dev Computes the next gen0 auction price. It will be
     *  the average of the past 5 prices + 50%.
     */
    function _computeNextGen0Price() internal view returns (uint256) {
        uint256 averagePrice = saleAuction.averageGen0SalePrice();

        // Sanity check to ensure not to overflow arithmetic.
        require(averagePrice == uint256(uint128(averagePrice)));

        uint256 nextPrice = averagePrice.add(averagePrice / 2);

        // New gen0 auction price will not be less than the
        // starting price always.
        if (nextPrice < gen0StartingPrice) {
            nextPrice = gen0StartingPrice;
        }

        return nextPrice;
    }
}

contract KydyTravelInterface {
    function balanceOfUnclaimedTT(address _user) public view returns(uint256);
    function transferTTProduction(address _from, address _to, uint256 _kydyId) public;
    function getProductionOf(address _user) public view returns (uint256);
}

/**
 * @title The Dyverse : A decentralized universe of Kydys, the unique 3D characters and avatars on the Blockchain.
 * @author VREX Lab Co., Ltd
 * @dev This is the main KydyCore contract. It keeps track of the kydys over the blockchain, and manages
 *  general operation of the contracts, metadata and important addresses, including defining who can withdraw 
 *  the balance from the contract.
 */
contract KydyCore is KydyMinting {

    // This is the main Kydy contract. To keep the code upgradable and secure, we broke up the code in two different ways.  
    // First, we separated auction and gene combination functions into several sibling contracts. This allows us to securely 
    // fix bugs and upgrade contracts, if necessary. Please note that while we try to make most code open source, 
    // some code regarding gene combination is not open-source to make it more intriguing for users. 
    // However, as always, advanced users will be able to figure out how it works. 
    //
    // We also break the core function into a few files, having one contract for each of the major functionalities of the Dyverse. 
    // The breakdown is as follows:
    //
    //      - KydyBase: This contract defines the most fundamental core functionalities, including data storage and management.
    //
    //      - KydyAccessControl: This contract manages the roles, addresses and constraints for CEO, CFO and COO.
    //
    //      - KydyOwnership: This contract provides the methods required for basic non-fungible token transactions.
    //
    //      - KydySynthesis: This contract contains how new baby Kydy is created via a process called the Synthesis. 
    //
    //      - KydyAuction: This contract manages auction creation and bidding. 
    //
    //      - KydyMinting: This contract defines how we create new Generation 0 Kydys. There is a limit of 8,888 Gen 0 Kydys. 

    // Upgraded version of the core contract.
    // Should be used when the core contract is broken and an upgrade is required.
    address public newContractAddress;

    /// @notice Creates the main Kydy smart contract instance.
    constructor() public {
        // Starts with the contract is paused.
        paused = true;

        // The creator of the contract is the initial CEO
        ceoAddress = msg.sender;

        // Starts with the Kydy ID 0 which is invalid one.
        // So we don&#39;t have generation-0 parent issues.
        _createKydy(0, 0, 0, uint256(-1), address(0));
    }

    /**
     * @dev Used to mark the smart contract as upgraded when an upgrade happens. 
     * @param _v2Address Upgraded version of the core contract.
     */
    function setNewAddress(address _v2Address) external onlyCEO whenPaused {
        // We&#39;ll announce if the upgrade is needed.
        newContractAddress = _v2Address;
        emit ContractUpgrade(_v2Address);
    }

    /**
     * @dev Rejects all Ether being sent from unregistered addresses, so that users don&#39;t accidentally end us Ether.
     */
    function() external payable {
        require(
            msg.sender == address(saleAuction) ||
            msg.sender == address(synthesizingAuction)
        );
    }

    /**
     * @notice Returns all info about a given Kydy. 
     * @param _id ID of the Kydy you are enquiring about. 
     */
    function getKydy(uint256 _id)
        external
        view
        returns (
        bool isCreating,
        bool isReady,
        uint256 rechargeIndex,
        uint256 nextActionAt,
        uint256 synthesizingWithId,
        uint256 createdTime,
        uint256 yinId,
        uint256 yangId,
        uint256 generation,
        uint256 genes
    ) {
        Kydy storage kyd = kydys[_id];

        // If this is setted to 0 then it&#39;s not at creating mode.
        isCreating = (kyd.synthesizingWithId != 0);
        isReady = (kyd.rechargeEndBlock <= block.number);
        rechargeIndex = uint256(kyd.rechargeIndex);
        nextActionAt = uint256(kyd.rechargeEndBlock);
        synthesizingWithId = uint256(kyd.synthesizingWithId);
        createdTime = uint256(kyd.createdTime);
        yinId = uint256(kyd.yinId);
        yangId = uint256(kyd.yangId);
        generation = uint256(kyd.generation);
        genes = kyd.genes;
    }

    /**
     * @dev Overrides unpause() to make sure that all external contract addresses are set before unpause. 
     * @notice This should be public rather than external.
     */
    function unpause() public onlyCEO whenPaused {
        require(saleAuction != address(0));
        require(synthesizingAuction != address(0));
        require(geneSynthesis != address(0));
        require(newContractAddress == address(0));

        // Now the contract actually unpauses.
        super.unpause();
    }

    /// @dev CFO can withdraw the balance available from the contract.
    function withdrawBalance() external onlyCFO {
        uint256 balance = address(this).balance;

        // Subtracts all creation fees needed to be given to the bringKydyHome() callers,
        // and plus 1 of margin.
        uint256 subtractFees = (creatingKydys + 1) * autoCreationFee;

        if (balance > subtractFees) {
            cfoAddress.transfer(balance - subtractFees);
        }
    }

    /// @dev Sets new tokenURI API for token metadata.
    function setNewTokenURI(string _newTokenURI) external onlyCLevel {
        tokenURIBase = _newTokenURI;
    }

    // An address of Kydy Travel Plugin.
    KydyTravelInterface public travelCore;

    /**
     * @dev Adds the Kydy Travel Plugin contract to the Kydy Core contract.
     * @notice We have a plan to add some fun features to the Dyverse. 
     *  Your Kydy will travel all over our world while you carry on with your life.
     *  During their travel, they will earn some valuable coins which will then be given to you.
     *  Please stay tuned!
     */
    function setTravelCore(address _newTravelCore) external onlyCEO whenPaused {
        travelCore = KydyTravelInterface(_newTravelCore);
    }
}