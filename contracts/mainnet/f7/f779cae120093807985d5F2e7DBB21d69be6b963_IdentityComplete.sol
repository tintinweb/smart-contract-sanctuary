// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.7.4;

import "./SafeMathLib.sol";


/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}



/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

// ERC 721
contract Identity {
    using SafeMathLib for uint;

    mapping (uint => address) public owners;
    mapping (address => uint) public balances;

    // Mapping from owner to operator approvals
    mapping (address => mapping (address => bool)) public operatorApprovals;
    mapping (uint => address) public tokenApprovals;

    // Equals to `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
    // which can be also obtained as `IERC721Receiver(0).onERC721Received.selector`
    bytes4 private constant ERC721_RECEIVED = 0x150b7a02;

    /*
     *     bytes4(keccak256('balanceOf(address)')) == 0x70a08231
     *     bytes4(keccak256('ownerOf(uint256)')) == 0x6352211e
     *     bytes4(keccak256('approve(address,uint256)')) == 0x095ea7b3
     *     bytes4(keccak256('getApproved(uint256)')) == 0x081812fc
     *     bytes4(keccak256('setApprovalForAll(address,bool)')) == 0xa22cb465
     *     bytes4(keccak256('isApprovedForAll(address,address)')) == 0xe985e9c5
     *     bytes4(keccak256('transferFrom(address,address,uint256)')) == 0x23b872dd
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256)')) == 0x42842e0e
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256,bytes)')) == 0xb88d4fde
     *
     *     => 0x70a08231 ^ 0x6352211e ^ 0x095ea7b3 ^ 0x081812fc ^
     *        0xa22cb465 ^ 0xe985e9c5 ^ 0x23b872dd ^ 0x42842e0e ^ 0xb88d4fde == 0x80ac58cd
     */
    bytes4 private constant INTERFACE_ID_ERC721 = 0x80ac58cd;

    /*
     * bytes4(keccak256('supportsInterface(bytes4)')) == 0x01ffc9a7
     */
    bytes4 private constant INTERFACE_ID_ERC165 = 0x01ffc9a7;

    uint public identityIncreaseFactor = 2;
    uint public identityIncreaseDenominator = 1;
    uint public lastIdentityPrice = 100 * 1 ether; // burn cost of making an identity, in IERC20
    uint public identityDecayFactor = 1 ether / 100;
    uint public identityPriceFloor = 100 * 1 ether;
    uint public numIdentities = 0;
    uint public lastPurchaseBlock;

    address public management;

    IERC20 public token;

    event ManagementUpdated(address oldManagement, address newManagement);
    event TokenSet(address token);
    event IdentityIncreaseFactorUpdated(uint oldIdIncreaseFactor, uint newIdIncreaseFactor);
    event IdentityIncreaseDenominatorUpdated(uint oldIdIncreaseDenominator, uint newIdIncreaseDenominator);
    event IdentityDecayFactorUpdated(uint oldIdDecayFactor, uint newIdDecayFactor);
    event IdentityPriceFloorUpdated(uint oldIdPriceFloor, uint newIdPriceFloor);
    event IdentityCreated(address indexed owner, uint indexed token);


    /// @dev This emits when ownership of any NFT changes by any mechanism.
    ///  This event emits when NFTs are created (`from` == 0) and destroyed
    ///  (`to` == 0). Exception: during contract creation, any number of NFTs
    ///  may be created and assigned without emitting Transfer. At the time of
    ///  any transfer, the approved address for that NFT (if any) is reset to none.
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /// @dev This emits when the approved address for an NFT is changed or
    ///  reaffirmed. The zero address indicates there is no approved address.
    ///  When a Transfer event emits, this also indicates that the approved
    ///  address for that NFT (if any) is reset to none.
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /// @dev This emits when an operator is enabled or disabled for an owner.
    ///  The operator can manage all NFTs of the owner.
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    modifier managementOnly() {
        require (msg.sender == management, 'Identity: Only management may call this');
        _;
    }

    constructor(address mgmt) {
        management = mgmt;
        lastPurchaseBlock = block.number;
    }

    function setToken(address tokenAddr) public managementOnly {
        token = IERC20(tokenAddr);
        emit TokenSet(tokenAddr);
    }

    // this function creates an identity by burning the IERC20. Anyone can call it.
    function createMyIdentity(uint maxPrice) public {
        uint identityPrice = getIdentityPrice();
        require(maxPrice >= identityPrice || maxPrice == 0, "Identity: current price exceeds user maximum");
        token.transferFrom(msg.sender, address(0), identityPrice);
        createIdentity(msg.sender);
        lastIdentityPrice = identityPrice.times(identityIncreaseFactor) / identityIncreaseDenominator;
        lastPurchaseBlock = block.number;
    }

    // this function creates an identity for free. Only management can call it.
    function createIdentityFor(address newId) public managementOnly {
        createIdentity(newId);
    }

    function createIdentity(address owner) internal {
        numIdentities = numIdentities.plus(1);
        owners[numIdentities] = owner;
        balances[owner] = balances[owner].plus(1);
        emit Transfer(address(0), owner, numIdentities);
        emit IdentityCreated(owner, numIdentities);
    }

    function getIdentityPrice() public view returns (uint) {
        uint decay = identityDecayFactor.times(block.number.minus(lastPurchaseBlock));
        if (lastIdentityPrice < decay.plus(identityPriceFloor)) {
            return identityPriceFloor;
        } else {
            return lastIdentityPrice.minus(decay);
        }
    }

    /// ================= SETTERS =======================================

    // change the management key
    function setManagement(address newMgmt) public managementOnly {
        address oldMgmt =  management;
        management = newMgmt;
        emit ManagementUpdated(oldMgmt, newMgmt);
    }

    function setIdentityIncreaseFactor(uint newIncreaseFactor) public managementOnly {
        uint oldIncreaseFactor = identityIncreaseFactor;
        identityIncreaseFactor = newIncreaseFactor;
        emit IdentityIncreaseFactorUpdated(oldIncreaseFactor, newIncreaseFactor);
    }

    function setIdentityIncreaseDenominator(uint newIncreaseDenominator) public managementOnly {
        uint oldIncreaseDenominator = identityIncreaseDenominator;
        identityIncreaseDenominator = newIncreaseDenominator;
        emit IdentityIncreaseDenominatorUpdated(oldIncreaseDenominator, newIncreaseDenominator);
    }

    function setIdentityDecayFactor(uint newDecayFactor) public managementOnly {
        uint oldDecayFactor = identityDecayFactor;
        identityDecayFactor = newDecayFactor;
        emit IdentityDecayFactorUpdated(oldDecayFactor, newDecayFactor);
    }

    function setIdentityPriceFloor(uint newPriceFloor) public managementOnly {
        uint oldFloor = identityPriceFloor;
        identityPriceFloor = newPriceFloor;
        emit IdentityPriceFloorUpdated(oldFloor, newPriceFloor);
    }

    /// ================= ERC 721 FUNCTIONS =============================================

    /// @notice Count all NFTs assigned to an owner
    /// @dev NFTs assigned to the zero address are considered invalid, and this
    ///  function throws for queries about the zero address.
    /// @param owner An address for whom to query the balance
    /// @return The number of NFTs owned by `owner`, possibly zero
    function balanceOf(address owner) external view returns (uint256) {
        return balances[owner];
    }

    /// @notice Find the owner of an NFT
    /// @dev NFTs assigned to zero address are considered invalid, and queries
    ///  about them do throw.
    /// @param tokenId The identifier for an NFT
    /// @return The address of the owner of the NFT
    function ownerOf(uint256 tokenId) external view returns (address)  {
        address owner = owners[tokenId];
        require(owner != address(0), 'No such token');
        return owner;
    }

    /// @notice Transfer ownership of an NFT -- THE CALLER IS RESPONSIBLE
    ///  TO CONFIRM THAT `to` IS CAPABLE OF RECEIVING NFTS OR ELSE
    ///  THEY MAY BE PERMANENTLY LOST
    /// @dev Throws unless `msg.sender` is the current owner, an authorized
    ///  operator, or the approved address for this NFT. Throws if `from` is
    ///  not the current owner. Throws if `to` is the zero address. Throws if
    ///  `tokenId` is not a valid NFT.
    /// @param from The current owner of the NFT
    /// @param to The new owner
    /// @param tokenId The NFT to transfer
    function transferFrom(address from, address to, uint256 tokenId) public {
        require(isApproved(msg.sender, tokenId), 'Identity: Unapproved transfer');
        transfer(from, to, tokenId);
    }

    /// @notice Transfers the ownership of an NFT from one address to another address
    /// @dev Throws unless `msg.sender` is the current owner, an authorized
    ///  operator, or the approved address for this NFT. Throws if `from` is
    ///  not the current owner. Throws if `to` is the zero address. Throws if
    ///  `tokenId` is not a valid NFT. When transfer is complete, this function
    ///  checks if `to` is a smart contract (code size > 0). If so, it calls
    ///  `onERC721Received` on `to` and throws if the return value is not
    ///  `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.
    /// @param from The current owner of the NFT
    /// @param to The new owner
    /// @param tokenId The NFT to transfer
    /// @param data Additional data with no specified format, sent in call to `to`
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public {
        transferFrom(from, to, tokenId);
        require(checkOnERC721Received(from, to, tokenId, data), "Identity: transfer to non ERC721Receiver implementer");
    }

    /// @notice Transfers the ownership of an NFT from one address to another address
    /// @dev This works identically to the other function with an extra data parameter,
    ///  except this function just sets data to "".
    /// @param from The current owner of the NFT
    /// @param to The new owner
    /// @param tokenId The NFT to transfer
    function safeTransferFrom(address from, address to, uint256 tokenId) public {
        safeTransferFrom(from, to, tokenId, '');
    }


    /// @notice Change or reaffirm the approved address for an NFT
    /// @dev The zero address indicates there is no approved address.
    ///  Throws unless `msg.sender` is the current NFT owner, or an authorized
    ///  operator of the current owner.
    /// @param approved The new approved NFT controller
    /// @param tokenId The NFT to approve
    function approve(address approved, uint256 tokenId) public {
        address owner = owners[tokenId];
        require(isApproved(msg.sender, tokenId), 'Identity: Not authorized to approve');
        require(owner != approved, 'Identity: Approving self not allowed');
        tokenApprovals[tokenId] = approved;
        emit Approval(owner, approved, tokenId);
    }

    /// @notice Enable or disable approval for a third party ("operator") to manage
    ///  all of `msg.sender`'s assets
    /// @dev Emits the ApprovalForAll event. The contract MUST allow
    ///  multiple operators per owner.
    /// @param operator Address to add to the set of authorized operators
    /// @param approved True if the operator is approved, false to revoke approval
    function setApprovalForAll(address operator, bool approved) external {
        operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    /// @notice Get the approved address for a single NFT
    /// @dev Throws if `tokenId` is not a valid NFT.
    /// @param tokenId The NFT to find the approved address for
    /// @return The approved address for this NFT, or the zero address if there is none
    function getApproved(uint256 tokenId) external view returns (address) {
        address owner = owners[tokenId];
        require(owner != address(0), 'Identity: Invalid tokenId');
        return tokenApprovals[tokenId];
    }

    /// @notice Query if an address is an authorized operator for another address
    /// @param owner The address that owns the NFTs
    /// @param operator The address that acts on behalf of the owner
    /// @return True if `operator` is an approved operator for `owner`, false otherwise
    function isApprovedForAll(address owner, address operator) public view returns (bool) {
        return operatorApprovals[owner][operator];
    }

    /// ================ UTILS =========================
    function isApproved(address operator, uint tokenId) public view returns (bool) {
        address owner = owners[tokenId];
        return (
            operator == owner ||
            operatorApprovals[owner][operator] ||
            tokenApprovals[tokenId] == operator
        );
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address from, address to, uint256 tokenId) internal {
        require(owners[tokenId] == from, "Identity: Transfer of token that is not own");
        require(to != address(0), "Identity: transfer to the zero address");

        // Clear approvals from the previous owner
        approve(address(0), tokenId);

        owners[tokenId] = to;
        balances[from] = balances[from].minus(1);
        balances[to] = balances[to].plus(1);

        emit Transfer(from, to, tokenId);
    }

    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for non-contract addresses

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory data)
        private returns (bool)
    {
        if (!isContract(to)) {
            return true;
        }
        IERC721Receiver target = IERC721Receiver(to);
        bytes4 retval = target.onERC721Received(from, to, tokenId, data);
        return ERC721_RECEIVED == retval;
    }

    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external pure returns (bool) {
        return (
            interfaceId == INTERFACE_ID_ERC721 ||
            interfaceId == INTERFACE_ID_ERC165
        );
    }

}
