/**
 *Submitted for verification at testnet.snowtrace.io on 2021-12-06
*/

// File: utils/Context.sol

//SPDX-License-Identifier:None
pragma solidity 0.8.0;

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
abstract contract Context {

    /// Empty constructor, to prevent people from mistakenly deploying
    /// an instance of this contract, which should be used via inheritance.

    constructor () { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {

        return payable(msg.sender);
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}
// File: utils/Ownable.sol


pragma solidity 0.8.0;


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;
    address private _nominatedOwner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event OwnershipNominated(address indexed previousOwner, address indexed newOwner);
    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor (address multisig) {
        _owner = multisig;
        emit OwnershipTransferred(address(0), multisig);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() external view returns (address) {
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
    function renounceOwnership() external onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Nominate new Owner of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function nominateNewOwner(address newOwner) external onlyOwner {
        _nominatedOwner = newOwner;
        emit OwnershipNominated(_owner,newOwner);
    }

    /**
     * @dev Nominated Owner can accept the Ownership of the contract.
     * Can only be called by the nominated owner.
     */
    function acceptOwnership() external {
        require(msg.sender == _nominatedOwner, "Ownable: You must be nominated before you can accept ownership");
        emit OwnershipTransferred(_owner, _nominatedOwner);
        _owner = _nominatedOwner;
        _nominatedOwner = address(0);
    }
}
// File: utils/Address.sol


pragma solidity 0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
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
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    /**
     * @dev Converts an `address` into `address payable`. Note that this is
     * simply a type cast: the actual underlying value is not changed.
     *
     * _Available since v2.4.0._
     */
    function toPayable(address account) internal pure returns (address payable) {
        return payable(address(uint160(account)));
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
     *
     * _Available since v2.4.0._
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-call-value
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}
// File: NFTs/CommonConstants.sol


pragma solidity 0.8.0;

contract CommonConstants {
    // bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))
    bytes4 constant internal ERC1155_ACCEPTED = 0xf23a6e61; 

    // bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))
    bytes4 constant internal ERC1155_BATCH_ACCEPTED = 0xbc197c81; 
}
// File: interfaces/ERC1155TokenReceiver.sol


pragma solidity 0.8.0;


/**
    Note: The ERC-165 identifier for this interface is 0x4e2312e0.
*/
interface ERC1155TokenReceiver {
    /**
        @notice Handle the receipt of a single ERC1155 token type.
        @dev An ERC1155-compliant smart contract MUST call this function on the token recipient contract, at the end of a `safeTransferFrom` after the balance has been updated.
        This function MUST return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` (i.e. 0xf23a6e61) if it accepts the transfer.
        This function MUST revert if it rejects the transfer.
        Return of any other value than the prescribed keccak256 generated value MUST result in the transaction being reverted by the caller.
        @param operator  The address which initiated the transfer (i.e. msg.sender)
        @param sender    The address which previously owned the token
        @param id        The ID of the token being transferred
        @param value     The amount of tokens being transferred
        @param data      Additional data with no specified format
        @return         `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
    */
    function onERC1155Received(address operator, address sender, uint256 id, uint256 value, bytes calldata data) external returns(bytes4);

    /**
        @notice Handle the receipt of multiple ERC1155 token types.
        @dev An ERC1155-compliant smart contract MUST call this function on the token recipient contract, at the end of a `safeBatchTransferFrom` after the balances have been updated.
        This function MUST return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` (i.e. 0xbc197c81) if it accepts the transfer(s).
        This function MUST revert if it rejects the transfer(s).
        Return of any other value than the prescribed keccak256 generated value MUST result in the transaction being reverted by the caller.
        @param operator  The address which initiated the batch transfer (i.e. msg.sender)
        @param sender    The address which previously owned the token
        @param ids       An array containing ids of each token being transferred (order and length must match _values array)
        @param values    An array containing amounts of each token being transferred (order and length must match _ids array)
        @param data      Additional data with no specified format
        @return          `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
    */
    function onERC1155BatchReceived(address operator, address sender, uint256[] calldata ids, uint256[] calldata values, bytes calldata data) external returns(bytes4);
}
// File: interfaces/IERC165.sol


pragma solidity 0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}
// File: interfaces/IERC1155.sol


pragma solidity 0.8.0;


/**
 * @title ERC-1155 Multi Token Standard
 * @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-1155.md
 * Note: The ERC-165 identifier for this interface is 0xd9b67a26.
 */
abstract contract IERC1155 is IERC165 {
    /**
     * @dev Either `TransferSingle` or `TransferBatch` MUST emit when tokens are transferred, 
     *      including zero value transfers as well as minting or burning (see "Safe Transfer Rules" section of the standard).
     * The `operator` argument MUST be msg.sender.
     * The `_from` argument MUST be the address of the holder whose balance is decreased.
     * The `to` argument MUST be the address of the recipient whose balance is increased.
     * The `id` argument MUST be the token type being transferred.
     * The `value` argument MUST be the number of tokens the holder balance is decreased by and match what the recipient 
     *      balance is increased by.
     * 
     * When minting/creating tokens, the `_from` argument MUST be set to `0x0` (i.e. zero address).
     * When burning/destroying tokens, the `to` argument MUST be set to `0x0` (i.e. zero address).
    */
    event TransferSingle(address indexed operator, address indexed _from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Either `TransferSingle` or `TransferBatch` MUST emit when tokens are transferred, including zero value transfers 
     *      as well as minting or burning (see "Safe Transfer Rules" section of the standard).
     * The `operator` argument MUST be msg.sender.
     * The `_from` argument MUST be the address of the holder whose balance is decreased.
     * The `to` argument MUST be the address of the recipient whose balance is increased.
     * The `ids` argument MUST be the list of tokens being transferred.
     * The `values` argument MUST be the list of number of tokens (matching the list and order of tokens specified in _ids) 
     *      the holder balance is decreased by and match what the recipient balance is increased by.
     * When minting/creating tokens, the `_from` argument MUST be set to `0x0` (i.e. zero address).
     * When burning/destroying tokens, the `to` argument MUST be set to `0x0` (i.e. zero address).
    */
    event TransferBatch(address indexed operator, address indexed _from, address indexed to, uint256[] ids, uint256[] values);

    /**
     * @dev MUST emit when the URI is updated for a token ID.
     * URIs are defined in RFC 3986.
     * The URI MUST point a JSON file that conforms to the "ERC-1155 Metadata URI JSON Schema".
    */
    event URI(string value, uint256 indexed id);

    /**
     * @notice Transfers `value` amount of an `id` from the `_from` address to the `to` address specified (with safety call).
     * @dev Caller must be approved to manage the tokens being transferred out of the `_from` account 
     *      (see "Approval" section of the standard).
     * MUST revert if `to` is the zero address.
     * MUST revert if balance of holder for token `id` is lower than the `value` sent.
     * MUST revert on any other error.
     * MUST emit the `TransferSingle` event to reflect the balance change (see "Safe Transfer Rules" section of the standard).
     * After the above conditions are met, this function MUST check if `to` is a smart contract (e.g. code size > 0). 
     *      If so, it MUST call `onERC1155Received` on `to` and act appropriately (see "Safe Transfer Rules" section of the standard).
     * @param _from    Source address
     * @param to      Target address
     * @param id      ID of the token type
     * @param value   Transfer amount
     * @param data    Additional data with no specified format, MUST be sent unaltered in call to `onERC1155Received` on `to`
    */
    function safeTransferFrom(address _from, address to, uint256 id, uint256 value, bytes memory data) internal virtual;

    /**
     * @notice Transfers `_values` amount(s) of `_ids` from the `_from` address to the `to` address specified 
     *      (with safety call).
     * @dev Caller must be approved to manage the tokens being transferred out of the `_from` account 
     *      (see "Approval" section of the standard).
     * MUST revert if `to` is the zero address.
     * MUST revert if length of `_ids` is not the same as length of `_values`.
     * UST revert if any of the balance(s) of the holder(s) for token(s) in `_ids` is lower than the respective amount(s) 
     *      in `_values` sent to the recipient.
     * MUST revert on any other error.
     * MUST emit `TransferSingle` or `TransferBatch` event(s) such that all the balance changes are reflected 
     *      (see "Safe Transfer Rules" section of the standard).
     * Balance changes and events MUST follow the ordering of the arrays (_ids[0]/_values[0] before _ids[1]/_values[1], etc).
     * After the above conditions for the transfer(s) in the batch are met, this function MUST check if `to` is a smart contract 
     *      (e.g. code size > 0). If so, it MUST call the relevant `ERC1155TokenReceiver` hook(s) on `to` and act appropriately 
     *      (see "Safe Transfer Rules" section of the standard).
     * 
     * @param _from   Source address
     * @param to      Target address
     * @param ids     IDs of each token type (order and length must match _values array)
     * @param values  Transfer amounts per token type (order and length must match _ids array)
     * @param data    Additional data with no specified format, MUST be sent unaltered in call to the `ERC1155TokenReceiver` hook(s) on `to`
    */
    function safeBatchTransferFrom(address _from, address to, uint256[] memory ids, uint256[] memory values, bytes memory data) internal virtual;

    /**
     * @notice Get the balance of an account's Tokens.
     * @param owner  The address of the token holder
     * @param id     ID of the Token
     * @return       The _owner's balance of the Token type requested
     */
    function balanceOf(address owner, uint256 id) external virtual view returns (uint256);

    /**
     * @notice Get the balance of multiple account/token pairs
     * @param owners The addresses of the token holders
     * @param ids    ID of the Tokens
     * @return       The _owner's balance of the Token types requested (i.e. balance for each (owner, id) pair)
     */
    function balanceOfBatch(address[] calldata owners, uint256[] calldata ids) external virtual view returns (uint256[] memory);

}
// File: NFTs/ERC165.sol


pragma solidity 0.8.0;


/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts may inherit from this and call {_registerInterface} to declare
 * their support of an interface.
 */
contract ERC165 is IERC165 {
    /*
     * bytes4(keccak256('supportsInterface(bytes4)')) == 0x01ffc9a7
     */
    bytes4 private constant interfaceIdERC165 = 0x01ffc9a7;

    /**
     * @dev Mapping of interface ids to whether or not it's supported.
     */
    mapping(bytes4 => bool) private supportedInterfaces;

    constructor () {
        // Derived contracts need only register support for their own interfaces,
        // we register support for ERC165 itself here
        _registerInterface(interfaceIdERC165);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     *
     * Time complexity O(1), guaranteed to always use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external override view returns (bool) {
        return supportedInterfaces[interfaceId];
    }

    /**
     * @dev Registers the contract as an implementer of the interface defined by
     * `interfaceId`. Support of the actual ERC165 interface is automatic and
     * registering its interface id is not required.
     *
     * See {IERC165-supportsInterface}.
     *
     * Requirements:
     *
     * - `interfaceId` cannot be the ERC165 invalid interface (`0xffffffff`).
     */
    function _registerInterface(bytes4 interfaceId) internal {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        supportedInterfaces[interfaceId] = true;
    }
}
// File: NFTs/ERC1155AttentionSeeker.sol


pragma solidity 0.8.0;







// A sample implementation of core ERC1155 function.
contract ERC1155AttentionSeeker is Ownable, IERC1155, ERC165, CommonConstants {
    
    using Address for address;

    /// @dev mapping from tokenId => (tokenOwner => amount of tokenId at tokenOwner address)
    mapping(uint256 => mapping(address => uint256)) internal balances;

    /// @dev mapping from ownerAddress => tokenId
    mapping(address => uint256) internal attentionSeekerIDs;

    /////////////////////////////////////////// ERC165 //////////////////////////////////////////////

    /*
        bytes4(keccak256("safeTransferFrom(address,address,uint256,uint256,bytes)")) ^
        bytes4(keccak256("safeBatchTransferFrom(address,address,uint256[],uint256[],bytes)")) ^
        bytes4(keccak256("balanceOf(address,uint256)")) ^
        bytes4(keccak256("balanceOfBatch(address[],uint256[])")) ^
        bytes4(keccak256("setApprovalForAll(address,bool)")) ^
        bytes4(keccak256("isApprovedForAll(address,address)"));
    */
    bytes4 constant private INTERFACE_SIGNATURE_ERC1155 = 0xd9b67a26;

    /////////////////////////////////////////// CONSTRUCTOR //////////////////////////////////////////

    constructor(address multisigAddress) Ownable(multisigAddress) {
        _registerInterface(INTERFACE_SIGNATURE_ERC1155);
    }

    /////////////////////////////////////////// ERC1155 //////////////////////////////////////////////

    /**
     * @notice Transfers `value` amount of an `id` from the `_from` address to the `to` address specified (with safety call).
     * @dev Caller must be approved to manage the tokens being transferred out of the `_from` account (see "Approval" section
     * of the standard).
     * 
     * MUST revert if `to` is the zero address.
     * MUST revert if balance of holder for token `id` is lower than the `value` sent.
     * MUST revert on any other error.
     * MUST emit the `TransferSingle` event to reflect the balance change (see "Safe Transfer Rules" section of the standard).
     * After the above conditions are met, this function MUST check if `to` is a smart contract (e.g. code size > 0). If so,
     * it MUST call `onERC1155Received` on `to` and act appropriately (see "Safe Transfer Rules" section of the standard).
     * 
     * @param from    Source address
     * @param to      Target address
     * @param id      ID of the token type
     * @param value   Transfer amount
     * @param data    Additional data with no specified format, MUST be sent unaltered in call to `onERC1155Received` on `to`
    */
    function safeTransferFrom(address      from,
                              address      to,
                              uint256      id,
                              uint256      value,
                              bytes memory data) internal override {

        require(to != address(0), "to must be non-zero.");
        require(from == _msgSender(), "Need operator approval for 3rd party transfers.");

        // SafeMath will throw with insuficient funds _from
        // or if id is not valid (balance will be 0)
        balances[id][from] = balances[id][from] - value;
        balances[id][to]   = value + balances[id][to];

        // MUST emit event
        emit TransferSingle(_msgSender(), from, to, id, value);

        // Now that the balance is updated and the event was emitted,
        // call onERC1155Received if the destination is a contract.
        if (to.isContract()) {
            _doSafeTransferAcceptanceCheck(_msgSender(), from, to, id, value, data);
        }
    }

    /**
     * @notice Transfers `values` amount(s) of `ids` from the `_from` address to the `to` address specified
     *      (with safety call).
     * @dev Caller must be approved to manage the tokens being transferred out of the `_from` account 
     *      (see "Approval" section of the standard).
     * 
     * MUST revert if `to` is the zero address.
     * MUST revert if length of `ids` is not the same as length of `values`.
     * MUST revert if any of the balance(s) of the holder(s) for token(s) in `ids` is lower than the respective amount(s) in `values` sent to the recipient.
     * MUST revert on any other error.
     * MUST emit `TransferSingle` or `TransferBatch` event(s) such that all the balance changes are reflected (see "Safe Transfer Rules" section of the standard).
     * 
     * Balance changes and events MUST follow the ordering of the arrays (ids[0]/values[0] before ids[1]/values[1], etc).
     * 
     * After the above conditions for the transfer(s) in the batch are met, 
     *      this function MUST check if `to` is a smart contract (e.g. code size > 0).
     * If so, it MUST call the relevant `ERC1155TokenReceiver` hook(s) on `to` and act appropriately (see "Safe Transfer Rules" section of the standard).
     * 
     * @param from    Source address
     * @param to      Target address
     * @param ids     IDs of each token type (order and length must match values array)
     * @param values  Transfer amounts per token type (order and length must match ids array)
     * @param data    Additional data with no specified format, MUST be sent unaltered in call to the `ERC1155TokenReceiver` hook(s) on `to`
    */
    function safeBatchTransferFrom(address          from,
                                   address          to,
                                   uint256[] memory ids, 
                                   uint256[] memory values, 
                                   bytes     memory data) internal override {

        // MUST Throw on errors
        require(to != address(0), "destination address must be non-zero.");
        require(ids.length == values.length, "_ids and values array lenght must match.");
        require(from == _msgSender(), "No 3rd party transfers.");

        for (uint256 idx = 0; idx < ids.length; ++idx) {
            uint256 id = ids[idx];
            uint256 value = values[idx];

            // SafeMath will throw with insuficient funds _from
            // or if _id is not valid (balance will be 0)
            balances[id][from] = balances[id][from] - value;
            balances[id][to]    = value + balances[id][to];
        }

        // Note: instead of the below batch versions of event and acceptance check you MAY have emitted a TransferSingle
        // event and a subsequent call to _doSafeTransferAcceptanceCheck in above loop for each balance change instead.
        // Or emitted a TransferSingle event for each in the loop and then the single _doSafeBatchTransferAcceptanceCheck below.
        // However it is implemented the balance changes and events MUST match when a check (i.e. calling an external contract) is done.

        // MUST emit event
        emit TransferBatch(_msgSender(), from, to, ids, values);

        // Now that the balances are updated and the events are emitted,
        // call onERC1155BatchReceived if the destination is a contract.
        if (to.isContract()) {
            _doSafeBatchTransferAcceptanceCheck(_msgSender(), from, to, ids, values, data);
        }
    }

    /**
     * @notice Get the balance of an account's Tokens.
     * @param owner  The address of the token holder.
     * @param id     ID of the Token.
     * @return       The owner's balance of the Token type requested.
     */
    function balanceOf(address owner, uint256 id) external override view returns (uint256) {
        // The balance of any account can be calculated from the Transfer events history.
        // However, since we need to keep the balances to validate transfer request,
        // there is no extra cost to also privide a querry function.
        return balances[id][owner];
    }

    /**
     * @notice Get the Member ID of an account.
     * 
     * @param owner  The address of the token holder.
     * @return       The owner's balance of the Token type requested.
     */
    function attentionSeekerIdOf(address owner) external view returns (uint256) {
        
        uint256 id = _attentionSeekerIdOf(owner);
        return id;
    }

    function _attentionSeekerIdOf(address owner) internal view returns (uint256) {
        // The balance of any account can be calculated from the Transfer events history.
        // However, since we need to keep the balances to validate transfer request,
        // there is no extra cost to also privide a querry function.
        return attentionSeekerIDs[owner];
    }


    /**
     * @notice Get the balance of multiple account/token pairs
     * @param owners The addresses of the token holders
     * @param ids  ID of the Tokens
     * @return     The owner's balance of the Token types requested (i.e. balance for each (owner, id) pair)
     */
    function balanceOfBatch(address[] calldata owners, uint256[] calldata ids)
             external override view returns (uint256[] memory) {

        require(owners.length == ids.length);

        uint256[] memory balancesBatch = new uint256[](owners.length);

        for (uint256 idx = 0; idx < owners.length; ++idx) {
            balancesBatch[idx] = balances[ids[idx]][owners[idx]];
        }

        return balancesBatch;
    }

    /////////////////////////////////////////// Internal //////////////////////////////////////////////

    function _doSafeTransferAcceptanceCheck(address      operator,
                                            address      from,
                                            address      to,
                                            uint256      id,
                                            uint256      value,
                                            bytes memory data) internal {

        // If this was a hybrid standards solution you would have to check ERC165(to).supportsInterface(0x4e2312e0) here,
        //     but as this is a pure implementation of an ERC-1155 token set as recommended by
        // the standard, it is not necessary. The below should revert in all failure cases i.e. to isn't a receiver, 
        //     or it is and either returns an unknown value or it reverts in the call to indicate non-acceptance.


        // Note: if the below reverts in the onERC1155Received function of the to address you will have an undefined revert 
        //     reason returned rather than the one in the require test.
        // If you want predictable revert reasons consider using low level to.call() style instead so
        //     the revert does not bubble up and you can revert yourself on the ERC1155_ACCEPTED test.
        require(ERC1155TokenReceiver(to).onERC1155Received(operator, from, id, value, data) == ERC1155_ACCEPTED, "contract returned an unknown value from onERC1155Received");
    }

    function _doSafeBatchTransferAcceptanceCheck(address          operator,
                                                 address          from,
                                                 address          to,
                                                 uint256[] memory ids, 
                                                 uint256[] memory values, 
                                                 bytes     memory data) internal {

        // If this was a hybrid standards solution you would have to check ERC165(to).supportsInterface(0x4e2312e0) here,
        //     but as this is a pure implementation of an ERC-1155 token set as recommended by
        // the standard, it is not necessary. The below should revert in all failure cases i.e. to isn't a receiver, 
        //     or it is and either returns an unknown value or it reverts in the call to indicate non-acceptance.

        // Note: if the below reverts in the onERC1155BatchReceived function of the to address you will have an undefined 
        //     revert reason returned rather than the one in the require test.
        // If you want predictable revert reasons consider using low level to.call() style instead,
        //     so the revert does not bubble up and you can revert yourself on the ERC1155_BATCH_ACCEPTED test.
        require(ERC1155TokenReceiver(to).onERC1155BatchReceived(operator, from, ids, values, data) == ERC1155_BATCH_ACCEPTED, "contract returned an unknown value from onERC1155BatchReceived");
    }
}
// File: NFTs/HasContractURI.sol


pragma solidity 0.8.0;


contract HasContractURI is ERC165 {

    string private _contractURI;

    /*
     * bytes4(keccak256('contractURI()')) == 0xe8a3d485
     */
    bytes4 private constant interfaceIdContractUri = 0xe8a3d485;

    constructor(string memory contractUri) {
        _contractURI = contractUri;
        _registerInterface(interfaceIdContractUri);
    }

    function contractURI() public view returns(string memory) {
        return _contractURI;
    }

    /**
     * @dev Internal function to set the contract URI
     * @param contractUri string URI prefix to assign
     */
    function _setContractURI(string memory contractUri) internal {
        _contractURI = contractUri;
    }
}
// File: utils/UintLibrary.sol


pragma solidity 0.8.0;

library UintLibrary {
    function toString(uint256 _i) internal pure returns (string memory) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len - 1;
        while (_i != 0) {
            bstr[k--] = bytes1(uint8(48 + _i % 10));
            _i /= 10;
        }
        return string(bstr);
    }
}
// File: utils/StringLibrary.sol


pragma solidity 0.8.0;


library StringLibrary {
    using UintLibrary for uint256;

    function append(string memory _a, string memory _b) internal pure returns (string memory) {
        bytes memory _ba = bytes(_a);
        bytes memory _bb = bytes(_b);
        bytes memory bab = new bytes(_ba.length + _bb.length);
        uint k = 0;
        for (uint i = 0; i < _ba.length; i++) bab[k++] = _ba[i];
        for (uint i = 0; i < _bb.length; i++) bab[k++] = _bb[i];
        return string(bab);
    }

    function append(string memory _a, string memory _b, string memory _c) internal pure returns (string memory) {
        bytes memory _ba = bytes(_a);
        bytes memory _bb = bytes(_b);
        bytes memory _bc = bytes(_c);
        bytes memory bbb = new bytes(_ba.length + _bb.length + _bc.length);
        uint k = 0;
        for (uint i = 0; i < _ba.length; i++) bbb[k++] = _ba[i];
        for (uint i = 0; i < _bb.length; i++) bbb[k++] = _bb[i];
        for (uint i = 0; i < _bc.length; i++) bbb[k++] = _bc[i];
        return string(bbb);
    }

    function recover(string memory message, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
        bytes memory msgBytes = bytes(message);
        bytes memory fullMessage = concat(
            bytes("\x19Ethereum Signed Message:\n"),
            bytes(msgBytes.length.toString()),
            msgBytes,
            new bytes(0), new bytes(0), new bytes(0), new bytes(0)
        );
        return ecrecover(keccak256(fullMessage), v, r, s);
    }

    function concat(bytes memory _ba, bytes memory _bb, bytes memory _bc, bytes memory _bd, bytes memory _be, bytes memory _bf, bytes memory _bg) internal pure returns (bytes memory) {
        bytes memory resultBytes = new bytes(_ba.length + _bb.length + _bc.length + _bd.length + _be.length + _bf.length + _bg.length);
        uint k = 0;
        for (uint i = 0; i < _ba.length; i++) resultBytes[k++] = _ba[i];
        for (uint i = 0; i < _bb.length; i++) resultBytes[k++] = _bb[i];
        for (uint i = 0; i < _bc.length; i++) resultBytes[k++] = _bc[i];
        for (uint i = 0; i < _bd.length; i++) resultBytes[k++] = _bd[i];
        for (uint i = 0; i < _be.length; i++) resultBytes[k++] = _be[i];
        for (uint i = 0; i < _bf.length; i++) resultBytes[k++] = _bf[i];
        for (uint i = 0; i < _bg.length; i++) resultBytes[k++] = _bg[i];
        return resultBytes;
    }
}
// File: NFTs/HasTokenURI.sol


pragma solidity 0.8.0;


contract HasTokenURI {

    using StringLibrary for string;

    //Token URI prefix
    string private _tokenURIPrefix;

    // Optional mapping for token URIs
    mapping(uint256 => string) private tokenURIs;

    constructor(string memory tokenUriPrefix) {
        _tokenURIPrefix = tokenUriPrefix;
    }

    function tokenURIPrefix() public view returns(string memory) {
        return _tokenURIPrefix;
    }

    /**
     * @dev Returns an URI for a given token ID.
     * Throws if the token ID does not exist. May return an empty string.
     * @param tokenId uint256 ID of the token to query
     */
    function _tokenURI(uint256 tokenId) internal view returns (string memory) {
        return _tokenURIPrefix.append(tokenURIs[tokenId]);
    }

    /**
     * @dev Internal function to set the token URI for a given token.
     * Reverts if the token ID does not exist.
     * @param tokenId uint256 ID of the token to set its URI
     * @param uri string URI to assign
     */
    function _setTokenURI(uint256 tokenId, string memory uri) internal virtual {
        tokenURIs[tokenId] = uri;
    }

    /**
     * @dev Internal function to set the token URI prefix.
     * @param tokenUriPrefix string URI prefix to assign
     */
    function _setTokenURIPrefix(string memory tokenUriPrefix) internal {
        _tokenURIPrefix = tokenUriPrefix;
    }

    function _clearTokenURI(uint256 tokenId) internal {
        if (bytes(tokenURIs[tokenId]).length != 0) {
            delete tokenURIs[tokenId];
        }
    }
}
// File: interfaces/IERC1155Metadata_URI.sol


pragma solidity 0.8.0;

/**
    Note: The ERC-165 identifier for this interface is 0x0e89341c.
*/
interface IERC1155Metadata_URI {
    /**
        @notice A distinct Uniform Resource Identifier (URI) for a given token.
        @dev URIs are defined in RFC 3986.
        The URI may point to a JSON file that conforms to the "ERC-1155 Metadata URI JSON Schema".
        @return URI string
    */
    function uri(uint256 id) external view returns (string memory);
}
// File: NFTs/ERC1155Metadata_URI.sol


pragma solidity 0.8.0;



/**
    Note: The ERC-165 identifier for this interface is 0x0e89341c.
*/
contract ERC1155Metadata_URI is IERC1155Metadata_URI, HasTokenURI {

    constructor(string memory tokenURIPrefix) HasTokenURI(tokenURIPrefix) {

    }

    function uri(uint256 id) external override view returns (string memory) {
        return _tokenURI(id);
    }
}
// File: NFTs/ERC1155BaseAttentionSeeker.sol


pragma solidity 0.8.0;




contract ERC1155BaseAttentionSeeker is ERC1155Metadata_URI, HasContractURI, ERC1155AttentionSeeker {

    /// @dev Contains the mapping from TokenId => user who created that token.
    mapping (uint256 => address) private creators;

    constructor(string memory contractURI, 
                string memory tokenURIPrefix,
                address multisigAddress) 
                HasContractURI(contractURI) 
                ERC1155Metadata_URI(tokenURIPrefix)
                ERC1155AttentionSeeker(multisigAddress) {
    }

    /**
    *  @dev Transfer the token from address(0) to the caller address.
    *
    *  @param id      Id of the token that is to be generated.
    *  @param supply  The amount of token to be minted.
    *  @param uri     Uri of the token to store its metadata
    *
    * It Emits {TransferSingle} and {URI} after successful minting
    */
    function _mint(uint256 id, uint256 supply, string memory uri) internal {

        require(id     != 0, "Invalid token ID");
        require(supply != 0, "Supply should be positive");
        require(bytes(uri).length > 0, "Uri should be set");
        require(creators[id] == address(0), "Token is already minted");
        require(attentionSeekerIDs[_msgSender()] == 0, "AttentionSeekerID is already minted for this user");

        creators[id] = _msgSender();
        balances[id][_msgSender()] = supply;
        attentionSeekerIDs[_msgSender()] = id;

        _setTokenURI(id, uri);

        // Transfer event with mint semantic
        emit TransferSingle(_msgSender(), address(0x0), _msgSender(), id, supply);
        emit URI(uri, id);
    }

    /**
     * @dev Transfer the NFT of the caller at address(0).
     * The caller will no longer hold the NFT this particular NFT.
     *
     * @param owner Owner of the NFT that is to be burned.
     * @param value Amount of NFT to be burned.
     *
     * Emits {TransferSingle} after the token is burned.
     */
    function _burn(address owner, uint256 value) internal {

        uint256 id =  _attentionSeekerIdOf(owner);
        require(balances[id][owner] > 0, "You don't posses attention seeker token");
        require(value == 1, "Only 1 Token can be burned");
        
        balances[id][owner]       = 0;
        attentionSeekerIDs[owner] = 0;
        creators[id]              = address(0);

        emit TransferSingle(_msgSender(), owner, address(0), id, value);
    }

    /**
     * @dev Internal function to set the token URI for a given token.
     * Reverts if the token ID does not exist.

     * @param tokenId uint256 ID of the token to set its URI
     * @param uri     string URI to assign
     */
    function _setTokenURI(uint256 tokenId, string memory uri) internal override {
        require(creators[tokenId] != address(0), "_setTokenURI: Token should exist");
        super._setTokenURI(tokenId, uri);
    }

    function setTokenURIPrefix(string memory tokenURIPrefix) public onlyOwner {
        _setTokenURIPrefix(tokenURIPrefix);
    }

    function setContractURI(string memory contractURI) public onlyOwner {
        _setContractURI(contractURI);
    }

    function creator(uint256 id) public view returns(address) {
        return creators[id];
    }
}
// File: NFTs/AttentionSeekerToken.sol


pragma solidity 0.8.0;


contract AttentionSeekerToken is ERC1155BaseAttentionSeeker {
    string public name;
    string public symbol;

    constructor(string memory tokenName,
                string memory tokenSymbol,
                string memory contractURI,
                string memory tokenURIPrefix,
                address       multisigAddress) ERC1155BaseAttentionSeeker(contractURI, tokenURIPrefix, multisigAddress) {

        name   = tokenName;
        symbol = tokenSymbol;

        _registerInterface(bytes4(keccak256('MINT_WITH_ADDRESS')));
    }

    /**
     *  @dev see {ERC1155BaseAttentionSeeker - _mint}
     */
    function mint(uint256 id, uint256 supply, string memory uri) internal {
        _mint(id, supply, uri);
    }
}
// File: interfaces/IArkiusMembershipToken.sol


pragma solidity 0.8.0;

interface IArkiusMembershipToken {
    function memberIdOf(address owner) external view returns (uint256);
}
// File: AttentionSeekerNFT.sol

//Arkius Public Benefit Corporation Privileged & Confidential

pragma solidity 0.8.0;



contract ArkiusAttentionSeekerToken is AttentionSeekerToken {

    event CreateERC1155_v1(address indexed creator, string name, string symbol);

    event UpdateMembership(address membershipAddress);

    IArkiusMembershipToken private membershipToken;

    uint256 constant INVALID = 0;

    /// @dev Contains Id of all seekers.
    uint256[] private allSeekers;

    /// @dev mapping from seekerId => index of allSeekers.
    mapping(uint256 => uint256) private indexAllSeekers;

    constructor(string memory name,
                string memory symbol,
                string memory contractURI,
                string memory tokenURIPrefix,
                IArkiusMembershipToken membership_token,
                address multisigAddress
            ) AttentionSeekerToken(name, symbol, contractURI, tokenURIPrefix, multisigAddress) {

        emit CreateERC1155_v1(msg.sender, name, symbol);

        membershipToken = membership_token;
    }

    function mint(string memory uri) public {

        uint id = membershipToken.memberIdOf(_msgSender());
        require(id != INVALID, "Not an Arkius Member");

        allSeekers.push(id);
        indexAllSeekers[id] = allSeekers.length;

        super.mint(id, 1, uri);
    }

    function burn(address owner, uint256 value) external {

        require(_msgSender() == owner || _msgSender() == address(membershipToken), "Not Authorised to burn");

        uint256 seekerId = _attentionSeekerIdOf(owner);

        if (seekerId > 0) {
            allSeekers[indexAllSeekers[seekerId] - 1] = allSeekers[allSeekers.length - 1];
            indexAllSeekers[allSeekers[allSeekers.length - 1]] = indexAllSeekers[seekerId];
            indexAllSeekers[seekerId] = 0;
            allSeekers.pop();
        }

        _burn(owner, value);
    }

    function updateMembership(IArkiusMembershipToken membershipTokenAddress) public onlyOwner {
        membershipToken = membershipTokenAddress;
        emit UpdateMembership(address(membershipTokenAddress));
    }

    function membershipAddress() public view returns(IArkiusMembershipToken) {
        return membershipToken;
    }

    function getAllSeekers() public view returns(uint256[] memory) {
        return allSeekers;
    }
}