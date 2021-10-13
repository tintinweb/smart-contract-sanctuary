// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0 <0.7.0;
import "./ERC721Contract.sol";


contract Monster is ERC721Contract {
    
    address ben;
    uint256 monsterId;

    struct EachMonster {
        uint256 id;
        string name;
        uint level;
        uint256 attackPower;
        uint256 defencePower;
    }
    uint256[] Id;
    mapping(uint256 => EachMonster) public monster;
    mapping(uint256 => address) public idToOwner;

    constructor () public {
        ben = msg.sender;
        EachMonster memory monst = EachMonster(monsterId, "Mugiwara", 1, 100, 100);
        monster[monsterId] = monst;
        Id.push(monsterId);
        mint(ben, monsterId);
        idToOwner[monsterId] = ben;
        monsterId++;
    }

    function newMonster(string calldata _name, uint256 _level, uint256 _attackPower, uint256 _defencePower) external {
        monster[monsterId] = EachMonster(monsterId, _name, _level, _attackPower, _defencePower);
        Id.push(monsterId);
        mint(msg.sender, monsterId);
        idToOwner[monsterId] = msg.sender;
        monsterId++;
    }

    function sendMonster(uint256 _tokenId, address _to) external {
        //check user is sending his own token
        address oldOwner = idToOwner[_tokenId];
        require(msg.sender == oldOwner, "Monster: Not Authorized to send.");
        _safeTransfer(oldOwner, _to, _tokenId, "");
        idToOwner[_tokenId] = _to;
    }

    function getBeastsId() public view returns (uint256[] memory) {
        return Id;
    }

    function getSingleBeast(uint256 _monsterId)
        public view returns (string memory, uint256, uint256, uint256)
    {
        return (monster[_monsterId].name, monster[_monsterId].level, monster[_monsterId].attackPower, monster[_monsterId].defencePower);
    }

    function battleMonsters(uint _monsterId, uint _targetId)  public {
        address player1 = idToOwner[_monsterId];
        address player2 = idToOwner[_targetId];
    
       require(player1 == msg.sender || player2 == msg.sender, "You are not the owner of this monster");

        EachMonster storage monster1 =  monster[_monsterId];
        EachMonster storage monster2 =  monster[_targetId];

        if(monster1.attackPower >= monster2.defencePower) {
            monster1.level += 1;
            monster1.attackPower += 10;
        } else {
            monster2.level += 1;
            monster2.defencePower += 10;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.7.0;


library Address {
    
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {

        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;


            bytes32 accountHash
         = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            codehash := extcodehash(account)
        }
        return (codehash != accountHash && codehash != 0x0);
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    // function sendValue(address payable recipient, uint256 amount) internal {
    //     require(address(this).balance >= amount, "Address: insufficient balance");

    //     // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
    //     (bool success, ) = recipient.call({ value: amount }).("");
    //     require(success, "Address: unable to send value, recipient may have reverted");
    // }
}


/// @dev Note: the ERC-165 identifier for this interface is 0x150b7a02.
interface IERC721TokenReceiver {

    /// @notice Handle the receipt of an NFT
    /// @dev The ERC721 smart contract calls this function on the recipient
    ///  after a `transfer`. This function MAY throw to revert and reject the
    ///  transfer. Return of other than the magic value MUST result in the
    ///  transaction being reverted.
    ///  Note: the contract address is always the message sender.
    /// @param _operator The address which called `safeTransferFrom` function
    /// @param _from The address which previously owned the token
    /// @param _tokenId The NFT identifier which is being transferred
    /// @param _data Additional data with no specified format
    /// @return `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
    ///  unless throwing

    function onERC721Received(
        address _operator,
        address _from,
        uint256 _tokenId,
        bytes calldata _data
    ) external returns (bytes4);
}


/// @title ERC-721 Non-Fungible Token Standard
/// @dev See https://eips.ethereum.org/EIPS/eip-721
///  Note: the ERC-165 identifier for this interface is 0x80ac58cd.
/* is ERC165 */

interface ERC721 {
    /// @dev This emits when ownership of any NFT changes by any mechanism.
    ///  This event emits when NFTs are created (`from` == 0) and destroyed
    ///  (`to` == 0). Exception: during contract creation, any number of NFTs
    ///  may be created and assigned without emitting Transfer. At the time of
    ///  any transfer, the approved address for that NFT (if any) is reset to none.

    event Transfer(
        address indexed _from,
        address indexed _to,
        uint256 indexed _tokenId
    );

    /// @dev This emits when the approved address for an NFT is changed or
    ///  reaffirmed. The zero address indicates there is no approved address.
    ///  When a Transfer event emits, this also indicates that the approved
    ///  address for that NFT (if any) is reset to none.

    event Approval(
        address indexed _owner,
        address indexed _approved,
        uint256 indexed _tokenId
    );

    /// @dev This emits when an operator is enabled or disabled for an owner.
    ///  The operator can manage all NFTs of the owner.

    event ApprovalForAll(
        address indexed _owner,
        address indexed _operator,
        bool _approved
    );

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

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes calldata data
    ) external payable;

    /// @notice Transfers the ownership of an NFT from one address to another address
    /// @dev This works identically to the other function with an extra data parameter,
    ///  except this function just sets data to "".
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) external payable;

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

    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) external payable;

    /// @notice Change or reaffirm the approved address for an NFT
    /// @dev The zero address indicates there is no approved address.
    ///  Throws unless `msg.sender` is the current NFT owner, or an authorized
    ///  operator of the current owner.
    /// @param _approved The new approved NFT controller
    /// @param _tokenId The NFT to approve

    function approve(
        address _approved, 
        uint256 _tokenId
        ) external payable;

    /// @notice Enable or disable approval for a third party ("operator") to manage
    ///  all of `msg.sender`'s assets
    /// @dev Emits the ApprovalForAll event. The contract MUST allow
    ///  multiple operators per owner.
    /// @param _operator Address to add to the set of authorized operators
    /// @param _approved True if the operator is approved, false to revoke approval

    function setApprovalForAll(
        address _operator, 
        bool _approved
        ) external;

    /// @notice Get the approved address for a single NFT
    /// @dev Throws if `_tokenId` is not a valid NFT.
    /// @param _tokenId The NFT to find the approved address for
    /// @return The approved address for this NFT, or the zero address if there is none

    function getApproved(
        uint256 _tokenId
        ) external 
        view 
        returns (address);

    /// @notice Query if an address is an authorized operator for another address
    /// @param _owner The address that owns the NFTs
    /// @param _operator The address that acts on behalf of the owner
    /// @return True if `_operator` is an approved operator for `_owner`, false otherwise

    function isApprovedForAll(
        address _owner, 
        address _operator
        )
        external
        view
        returns (bool);
}


contract ERC721Contract is ERC721 {

    using Address for address;
    mapping(address => uint256) private tokenBalanceOfOwner;
    mapping(uint256 => address) private tokenOwner;
    mapping(uint256 => address) private tokenIDApprover;
    mapping(address => mapping(address => bool)) private operators;

    bytes4 internal constant MAGIC_ON_ERC721_RECEIVED = 0x150b7a02;
    uint256 private nextTokenId;

    address me;

    constructor() public {
        me = msg.sender;
    }

    function mint(address _owner, uint256 _tokenId) public {
        tokenBalanceOfOwner[_owner]++;
        tokenOwner[_tokenId] = _owner;
        emit Transfer(address(0), _owner, _tokenId);
        nextTokenId++;
    }

    function balanceOf(address _owner) override external view returns (uint256) {
        return tokenBalanceOfOwner[_owner];
    }

    function ownerOf(uint256 _tokenId) override external view returns (address) {
        return tokenOwner[_tokenId];
    }

    function getApproved(uint256 _tokenId) override external view returns (address) {
        return tokenIDApprover[_tokenId];
    }

    function isApprovedForAll(address _owner, address _operator) override external view returns (bool) {
        return operators[_owner][_operator];
    }

    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes calldata data) override external payable {
        _safeTransfer(_from, _to, _tokenId, data);
    }

    function safeTransferFrom(address _from, address _to, uint256 _tokenId) override external payable {
        _safeTransfer(_from, _to, _tokenId, "");
    }

    function transferFrom(address _from, address _to, uint256 _tokenId) override external payable {
        _transfer(_from, _to, _tokenId);
    }

    function approve(address _approved, uint256 _tokenId) override external payable {
        //ensure only I can approve if I own the token
        address owner = tokenOwner[_tokenId];
        require(msg.sender == owner, "ERC721Contract: Are you sure you own this token?");
        tokenIDApprover[_tokenId] = _approved;
        emit Approval(owner, _approved, _tokenId);
    }

    function setApprovalForAll(address _operator, bool _approved) override external {
        //Allowing everyone to approve
        operators[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    function _transfer(address _from, address _to, uint256 _tokenId) internal allowTransfer(_tokenId) {
        tokenBalanceOfOwner[_from] -= 1;
        tokenBalanceOfOwner[_to] += 1;
        tokenOwner[_tokenId] = _to;
        emit Transfer(_from, _to, _tokenId);
    }

    function _safeTransfer(address _from, address _to, uint256 _tokenId, bytes memory data) internal {
        _transfer(_from, _to, _tokenId);
        if (_to.isContract()) {
            bytes4 retval = IERC721TokenReceiver(_to).onERC721Received(msg.sender, _to, _tokenId, data);
            require(retval == MAGIC_ON_ERC721_RECEIVED, "receiver cant take ERC721 tokens");
        }
    }

    modifier allowTransfer(uint256 _tokenId) {
        //retrieve the owners adress from his ID
        address owner = tokenOwner[_tokenId];
        require(owner == msg.sender || tokenIDApprover[_tokenId] == msg.sender || operators[owner][msg.sender] == true, "ERC721Contract: You are not authorized to allow a transfer");
        _;
    }
}