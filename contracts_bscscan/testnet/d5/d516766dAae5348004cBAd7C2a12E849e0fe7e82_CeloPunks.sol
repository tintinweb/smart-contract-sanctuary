/**
 *Submitted for verification at BscScan.com on 2021-10-10
*/

/**
 *Submitted for verification at arbiscan.io on 2021-09-13
*/

// Sources flattened with hardhat v2.6.0 https://hardhat.org

// File contracts/erc721.sol

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

/**
 * @dev ERC-721 non-fungible token standard.
 * See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md.
 */
interface ERC721 {
	/**
	 * @dev Emits when ownership of any NFT changes by any mechanism. This event emits when NFTs are
	 * created (`from` == 0) and destroyed (`to` == 0). Exception: during contract creation, any
	 * number of NFTs may be created and assigned without emitting Transfer. At the time of any
	 * transfer, the approved address for that NFT (if any) is reset to none.
	 */
	event Transfer(
		address indexed _from,
		address indexed _to,
		uint256 indexed _tokenId
	);

	/**
	 * @dev This emits when the approved address for an NFT is changed or reaffirmed. The zero
	 * address indicates there is no approved address. When a Transfer event emits, this also
	 * indicates that the approved address for that NFT (if any) is reset to none.
	 */
	event Approval(
		address indexed _owner,
		address indexed _approved,
		uint256 indexed _tokenId
	);

	/**
	 * @dev This emits when an operator is enabled or disabled for an owner. The operator can manage
	 * all NFTs of the owner.
	 */
	event ApprovalForAll(
		address indexed _owner,
		address indexed _operator,
		bool _approved
	);

	/**
	 * @notice Throws unless `msg.sender` is the current owner, an authorized operator, or the
	 * approved address for this NFT. Throws if `_from` is not the current owner. Throws if `_to` is
	 * the zero address. Throws if `_tokenId` is not a valid NFT. When transfer is complete, this
	 * function checks if `_to` is a smart contract (code size > 0). If so, it calls
	 * `onERC721Received` on `_to` and throws if the return value is not
	 * `bytes4(keccak256("onERC721Received(address,uint256,bytes)"))`.
	 * @dev Transfers the ownership of an NFT from one address to another address. This function can
	 * be changed to payable.
	 * @param _from The current owner of the NFT.
	 * @param _to The new owner.
	 * @param _tokenId The NFT to transfer.
	 * @param _data Additional data with no specified format, sent in call to `_to`.
	 */
	function safeTransferFrom(
		address _from,
		address _to,
		uint256 _tokenId,
		bytes calldata _data
	) external;

	/**
	 * @notice This works identically to the other function with an extra data parameter, except this
	 * function just sets data to ""
	 * @dev Transfers the ownership of an NFT from one address to another address. This function can
	 * be changed to payable.
	 * @param _from The current owner of the NFT.
	 * @param _to The new owner.
	 * @param _tokenId The NFT to transfer.
	 */
	function safeTransferFrom(
		address _from,
		address _to,
		uint256 _tokenId
	) external;

	/**
	 * @notice The caller is responsible to confirm that `_to` is capable of receiving NFTs or else
	 * they may be permanently lost.
	 * @dev Throws unless `msg.sender` is the current owner, an authorized operator, or the approved
	 * address for this NFT. Throws if `_from` is not the current owner. Throws if `_to` is the zero
	 * address. Throws if `_tokenId` is not a valid NFT.  This function can be changed to payable.
	 * @param _from The current owner of the NFT.
	 * @param _to The new owner.
	 * @param _tokenId The NFT to transfer.
	 */
	function transferFrom(
		address _from,
		address _to,
		uint256 _tokenId
	) external;

	/**
	 * @notice The zero address indicates there is no approved address. Throws unless `msg.sender` is
	 * the current NFT owner, or an authorized operator of the current owner.
	 * @param _approved The new approved NFT controller.
	 * @dev Set or reaffirm the approved address for an NFT. This function can be changed to payable.
	 * @param _tokenId The NFT to approve.
	 */
	function approve(address _approved, uint256 _tokenId) external;

	/**
	 * @notice The contract MUST allow multiple operators per owner.
	 * @dev Enables or disables approval for a third party ("operator") to manage all of
	 * `msg.sender`'s assets. It also emits the ApprovalForAll event.
	 * @param _operator Address to add to the set of authorized operators.
	 * @param _approved True if the operators is approved, false to revoke approval.
	 */
	function setApprovalForAll(address _operator, bool _approved) external;

	/**
	 * @dev Returns the number of NFTs owned by `_owner`. NFTs assigned to the zero address are
	 * considered invalid, and this function throws for queries about the zero address.
	 * @notice Count all NFTs assigned to an owner.
	 * @param _owner Address for whom to query the balance.
	 * @return Balance of _owner.
	 */
	function balanceOf(address _owner) external view returns (uint256);

	/**
	 * @notice Find the owner of an NFT.
	 * @dev Returns the address of the owner of the NFT. NFTs assigned to the zero address are
	 * considered invalid, and queries about them do throw.
	 * @param _tokenId The identifier for an NFT.
	 * @return Address of _tokenId owner.
	 */
	function ownerOf(uint256 _tokenId) external view returns (address);

	/**
	 * @notice Throws if `_tokenId` is not a valid NFT.
	 * @dev Get the approved address for a single NFT.
	 * @param _tokenId The NFT to find the approved address for.
	 * @return Address that _tokenId is approved for.
	 */
	function getApproved(uint256 _tokenId) external view returns (address);

	/**
	 * @notice Query if an address is an authorized operator for another address.
	 * @dev Returns true if `_operator` is an approved operator for `_owner`, false otherwise.
	 * @param _owner The address that owns the NFTs.
	 * @param _operator The address that acts on behalf of the owner.
	 * @return True if approved for all, false otherwise.
	 */
	function isApprovedForAll(address _owner, address _operator)
		external
		view
		returns (bool);
}

// File contracts/erc721-token-receiver.solpragma solidity 0.8.4;

/**
 * @dev ERC-721 interface for accepting safe transfers.
 * See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md.
 */
interface ERC721TokenReceiver {
	/**
	 * @notice The contract address is always the message sender. A wallet/broker/auction application
	 * MUST implement the wallet interface if it will accept safe transfers.
	 * @dev Handle the receipt of a NFT. The ERC721 smart contract calls this function on the
	 * recipient after a `transfer`. This function MAY throw to revert and reject the transfer. Return
	 * of other than the magic value MUST result in the transaction being reverted.
	 * Returns `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))` unless throwing.
	 * @param _operator The address which called `safeTransferFrom` function.
	 * @param _from The address which previously owned the token.
	 * @param _tokenId The NFT identifier which is being transferred.
	 * @param _data Additional data with no specified format.
	 * @return Returns `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.
	 */
	function onERC721Received(
		address _operator,
		address _from,
		uint256 _tokenId,
		bytes calldata _data
	) external returns (bytes4);
}

// File contracts/erc165.solpragma solidity 0.8.4;

/**
 * @dev A standard for detecting smart contract interfaces.
 * See: https://eips.ethereum.org/EIPS/eip-165.
 */
interface ERC165 {
	/**
	 * @dev Checks if the smart contract includes a specific interface.
	 * This function uses less than 30,000 gas.
	 * @param _interfaceID The interface identifier, as specified in ERC-165.
	 * @return True if _interfaceID is supported, false otherwise.
	 */
	function supportsInterface(bytes4 _interfaceID)
		external
		view
		returns (bool);
}

// File contracts/supports-interface.sol

pragma solidity 0.8.4;
/**
 * @dev Implementation of standard for detect smart contract interfaces.
 */

contract SupportsInterface is ERC165 {
	/**
	 * @dev Mapping of supported intefraces. You must not set element 0xffffffff to true.
	 */
	mapping(bytes4 => bool) internal supportedInterfaces;

	/**
	 * @dev Contract constructor.
	 */
	constructor() {
		supportedInterfaces[0x01ffc9a7] = true; // ERC165
	}

	/**
	 * @dev Function to check which interfaces are suported by this contract.
	 * @param _interfaceID Id of the interface.
	 * @return True if _interfaceID is supported, false otherwise.
	 */
	function supportsInterface(bytes4 _interfaceID)
		external
		view
		override
		returns (bool)
	{
		return supportedInterfaces[_interfaceID];
	}
}

// File contracts/address-utils.sol
pragma solidity 0.8.4;

/**
 * @notice Based on:
 * https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Address.sol
 * Requires EIP-1052.
 * @dev Utility library of inline functions on addresses.
 */
library AddressUtils {
	/**
	 * @dev Returns whether the target address is a contract.
	 * @param _addr Address to check.
	 * @return addressCheck True if _addr is a contract, false if not.
	 */
	function isContract(address _addr)
		internal
		view
		returns (bool addressCheck)
	{
		// This method relies in extcodesize, which returns 0 for contracts in
		// construction, since the code is only stored at the end of the
		// constructor execution.

		// According to EIP-1052, 0x0 is the value returned for not-yet created accounts
		// and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
		// for accounts without code, i.e. `keccak256('')`
		bytes32 codehash;
		bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
		assembly {
			codehash := extcodehash(_addr)
		} // solhint-disable-line
		addressCheck = (codehash != 0x0 && codehash != accountHash);
	}
}

// File contracts/nf-token.sol
pragma solidity 0.8.4;

/**
 * @dev Implementation of ERC-721 non-fungible token standard.
 */
contract NFToken is ERC721, SupportsInterface {
	using AddressUtils for address;

	/**
	 * @dev List of revert message codes. Implementing dApp should handle showing the correct message.
	 * Based on 0xcert framework error codes.
	 */
	string constant ZERO_ADDRESS = '003001';
	string constant NOT_VALID_NFT = '003002';
	string constant NOT_OWNER_OR_OPERATOR = '003003';
	string constant NOT_OWNER_APPROVED_OR_OPERATOR = '003004';
	string constant NOT_ABLE_TO_RECEIVE_NFT = '003005';
	string constant NFT_ALREADY_EXISTS = '003006';
	string constant NOT_OWNER = '003007';
	string constant IS_OWNER = '003008';

	/**
	 * @dev Magic value of a smart contract that can receive NFT.
	 * Equal to: bytes4(keccak256("onERC721Received(address,address,uint256,bytes)")).
	 */
	bytes4 internal constant MAGIC_ON_ERC721_RECEIVED = 0x150b7a02;

	/**
	 * @dev A mapping from NFT ID to the address that owns it.
	 */
	mapping(uint256 => address) internal idToOwner;

	/**
	 * @dev Mapping from NFT ID to approved address.
	 */
	mapping(uint256 => address) internal idToApproval;

	/**
	 * @dev Mapping from owner address to count of their tokens.
	 */
	mapping(address => uint256) private ownerToNFTokenCount;

	/**
	 * @dev Mapping from owner address to mapping of operator addresses.
	 */
	mapping(address => mapping(address => bool)) internal ownerToOperators;

	/**
	 * @dev Guarantees that the msg.sender is an owner or operator of the given NFT.
	 * @param _tokenId ID of the NFT to validate.
	 */
	modifier canOperate(uint256 _tokenId) {
		address tokenOwner = idToOwner[_tokenId];
		require(
			tokenOwner == msg.sender ||
				ownerToOperators[tokenOwner][msg.sender],
			NOT_OWNER_OR_OPERATOR
		);
		_;
	}

	/**
	 * @dev Guarantees that the msg.sender is allowed to transfer NFT.
	 * @param _tokenId ID of the NFT to transfer.
	 */
	modifier canTransfer(uint256 _tokenId) {
		address tokenOwner = idToOwner[_tokenId];
		require(
			tokenOwner == msg.sender ||
				idToApproval[_tokenId] == msg.sender ||
				ownerToOperators[tokenOwner][msg.sender],
			NOT_OWNER_APPROVED_OR_OPERATOR
		);
		_;
	}

	/**
	 * @dev Guarantees that _tokenId is a valid Token.
	 * @param _tokenId ID of the NFT to validate.
	 */
	modifier validNFToken(uint256 _tokenId) {
		require(idToOwner[_tokenId] != address(0), NOT_VALID_NFT);
		_;
	}

	/**
	 * @dev Contract constructor.
	 */
	constructor() {
		supportedInterfaces[0x80ac58cd] = true; // ERC721
	}

	/**
	 * @notice Throws unless `msg.sender` is the current owner, an authorized operator, or the
	 * approved address for this NFT. Throws if `_from` is not the current owner. Throws if `_to` is
	 * the zero address. Throws if `_tokenId` is not a valid NFT. When transfer is complete, this
	 * function checks if `_to` is a smart contract (code size > 0). If so, it calls
	 * `onERC721Received` on `_to` and throws if the return value is not
	 * `bytes4(keccak256("onERC721Received(address,uint256,bytes)"))`.
	 * @dev Transfers the ownership of an NFT from one address to another address. This function can
	 * be changed to payable.
	 * @param _from The current owner of the NFT.
	 * @param _to The new owner.
	 * @param _tokenId The NFT to transfer.
	 * @param _data Additional data with no specified format, sent in call to `_to`.
	 */
	function safeTransferFrom(
		address _from,
		address _to,
		uint256 _tokenId,
		bytes calldata _data
	) external override {
		_safeTransferFrom(_from, _to, _tokenId, _data);
	}

	/**
	 * @notice This works identically to the other function with an extra data parameter, except this
	 * function just sets data to "".
	 * @dev Transfers the ownership of an NFT from one address to another address. This function can
	 * be changed to payable.
	 * @param _from The current owner of the NFT.
	 * @param _to The new owner.
	 * @param _tokenId The NFT to transfer.
	 */
	function safeTransferFrom(
		address _from,
		address _to,
		uint256 _tokenId
	) external override {
		_safeTransferFrom(_from, _to, _tokenId, '');
	}

	/**
	 * @notice The caller is responsible to confirm that `_to` is capable of receiving NFTs or else
	 * they may be permanently lost.
	 * @dev Throws unless `msg.sender` is the current owner, an authorized operator, or the approved
	 * address for this NFT. Throws if `_from` is not the current owner. Throws if `_to` is the zero
	 * address. Throws if `_tokenId` is not a valid NFT. This function can be changed to payable.
	 * @param _from The current owner of the NFT.
	 * @param _to The new owner.
	 * @param _tokenId The NFT to transfer.
	 */
	function transferFrom(
		address _from,
		address _to,
		uint256 _tokenId
	) external override canTransfer(_tokenId) validNFToken(_tokenId) {
		address tokenOwner = idToOwner[_tokenId];
		require(tokenOwner == _from, NOT_OWNER);
		require(_to != address(0), ZERO_ADDRESS);

		_transfer(_to, _tokenId);
	}

	/**
	 * @notice The zero address indicates there is no approved address. Throws unless `msg.sender` is
	 * the current NFT owner, or an authorized operator of the current owner.
	 * @dev Set or reaffirm the approved address for an NFT. This function can be changed to payable.
	 * @param _approved Address to be approved for the given NFT ID.
	 * @param _tokenId ID of the token to be approved.
	 */
	function approve(address _approved, uint256 _tokenId)
		external
		override
		canOperate(_tokenId)
		validNFToken(_tokenId)
	{
		address tokenOwner = idToOwner[_tokenId];
		require(_approved != tokenOwner, IS_OWNER);

		idToApproval[_tokenId] = _approved;
		emit Approval(tokenOwner, _approved, _tokenId);
	}

	/**
	 * @notice This works even if sender doesn't own any tokens at the time.
	 * @dev Enables or disables approval for a third party ("operator") to manage all of
	 * `msg.sender`'s assets. It also emits the ApprovalForAll event.
	 * @param _operator Address to add to the set of authorized operators.
	 * @param _approved True if the operators is approved, false to revoke approval.
	 */
	function setApprovalForAll(address _operator, bool _approved)
		external
		override
	{
		ownerToOperators[msg.sender][_operator] = _approved;
		emit ApprovalForAll(msg.sender, _operator, _approved);
	}

	/**
	 * @dev Returns the number of NFTs owned by `_owner`. NFTs assigned to the zero address are
	 * considered invalid, and this function throws for queries about the zero address.
	 * @param _owner Address for whom to query the balance.
	 * @return Balance of _owner.
	 */
	function balanceOf(address _owner)
		external
		view
		override
		returns (uint256)
	{
		require(_owner != address(0), ZERO_ADDRESS);
		return _getOwnerNFTCount(_owner);
	}

	/**
	 * @dev Returns the address of the owner of the NFT. NFTs assigned to the zero address are
	 * considered invalid, and queries about them do throw.
	 * @param _tokenId The identifier for an NFT.
	 * @return _owner Address of _tokenId owner.
	 */
	function ownerOf(uint256 _tokenId)
		external
		view
		override
		returns (address _owner)
	{
		_owner = idToOwner[_tokenId];
		require(_owner != address(0), NOT_VALID_NFT);
	}

	/**
	 * @notice Throws if `_tokenId` is not a valid NFT.
	 * @dev Get the approved address for a single NFT.
	 * @param _tokenId ID of the NFT to query the approval of.
	 * @return Address that _tokenId is approved for.
	 */
	function getApproved(uint256 _tokenId)
		external
		view
		override
		validNFToken(_tokenId)
		returns (address)
	{
		return idToApproval[_tokenId];
	}

	/**
	 * @dev Checks if `_operator` is an approved operator for `_owner`.
	 * @param _owner The address that owns the NFTs.
	 * @param _operator The address that acts on behalf of the owner.
	 * @return True if approved for all, false otherwise.
	 */
	function isApprovedForAll(address _owner, address _operator)
		external
		view
		override
		returns (bool)
	{
		return ownerToOperators[_owner][_operator];
	}

	/**
	 * @notice Does NO checks.
	 * @dev Actually performs the transfer.
	 * @param _to Address of a new owner.
	 * @param _tokenId The NFT that is being transferred.
	 */
	function _transfer(address _to, uint256 _tokenId) internal {
		address from = idToOwner[_tokenId];
		_clearApproval(_tokenId);

		_removeNFToken(from, _tokenId);
		_addNFToken(_to, _tokenId);

		emit Transfer(from, _to, _tokenId);
	}

	/**
	 * @notice This is an internal function which should be called from user-implemented external
	 * mint function. Its purpose is to show and properly initialize data structures when using this
	 * implementation.
	 * @dev Mints a new NFT.
	 * @param _to The address that will own the minted NFT.
	 * @param _tokenId of the NFT to be minted by the msg.sender.
	 */
	function _mint(address _to, uint256 _tokenId) internal virtual {
		require(_to != address(0), ZERO_ADDRESS);
		require(idToOwner[_tokenId] == address(0), NFT_ALREADY_EXISTS);

		_addNFToken(_to, _tokenId);

		emit Transfer(address(0), _to, _tokenId);
	}

	/**
	 * @notice This is an internal function which should be called from user-implemented external burn
	 * function. Its purpose is to show and properly initialize data structures when using this
	 * implementation. Also, note that this burn implementation allows the minter to re-mint a burned
	 * NFT.
	 * @dev Burns a NFT.
	 * @param _tokenId ID of the NFT to be burned.
	 */
	function _burn(uint256 _tokenId) internal virtual validNFToken(_tokenId) {
		address tokenOwner = idToOwner[_tokenId];
		_clearApproval(_tokenId);
		_removeNFToken(tokenOwner, _tokenId);
		emit Transfer(tokenOwner, address(0), _tokenId);
	}

	/**
	 * @notice Use and override this function with caution. Wrong usage can have serious consequences.
	 * @dev Removes a NFT from owner.
	 * @param _from Address from which we want to remove the NFT.
	 * @param _tokenId Which NFT we want to remove.
	 */
	function _removeNFToken(address _from, uint256 _tokenId) internal virtual {
		require(idToOwner[_tokenId] == _from, NOT_OWNER);
		ownerToNFTokenCount[_from] -= 1;
		delete idToOwner[_tokenId];
	}

	/**
	 * @notice Use and override this function with caution. Wrong usage can have serious consequences.
	 * @dev Assigns a new NFT to owner.
	 * @param _to Address to which we want to add the NFT.
	 * @param _tokenId Which NFT we want to add.
	 */
	function _addNFToken(address _to, uint256 _tokenId) internal virtual {
		require(idToOwner[_tokenId] == address(0), NFT_ALREADY_EXISTS);

		idToOwner[_tokenId] = _to;
		ownerToNFTokenCount[_to] += 1;
	}

	/**
	 * @dev Helper function that gets NFT count of owner. This is needed for overriding in enumerable
	 * extension to remove double storage (gas optimization) of owner NFT count.
	 * @param _owner Address for whom to query the count.
	 * @return Number of _owner NFTs.
	 */
	function _getOwnerNFTCount(address _owner)
		internal
		view
		virtual
		returns (uint256)
	{
		return ownerToNFTokenCount[_owner];
	}

	/**
	 * @dev Actually perform the safeTransferFrom.
	 * @param _from The current owner of the NFT.
	 * @param _to The new owner.
	 * @param _tokenId The NFT to transfer.
	 * @param _data Additional data with no specified format, sent in call to `_to`.
	 */
	function _safeTransferFrom(
		address _from,
		address _to,
		uint256 _tokenId,
		bytes memory _data
	) private canTransfer(_tokenId) validNFToken(_tokenId) {
		address tokenOwner = idToOwner[_tokenId];
		require(tokenOwner == _from, NOT_OWNER);
		require(_to != address(0), ZERO_ADDRESS);

		_transfer(_to, _tokenId);

		if (_to.isContract()) {
			bytes4 retval = ERC721TokenReceiver(_to).onERC721Received(
				msg.sender,
				_from,
				_tokenId,
				_data
			);
			require(
				retval == MAGIC_ON_ERC721_RECEIVED,
				NOT_ABLE_TO_RECEIVE_NFT
			);
		}
	}

	/**
	 * @dev Clears the current approval of a given NFT ID.
	 * @param _tokenId ID of the NFT to be transferred.
	 */
	function _clearApproval(uint256 _tokenId) private {
		delete idToApproval[_tokenId];
	}
}

// File contracts/erc721-enumerable.solpragma solidity 0.8.4;

/**
 * @dev Optional enumeration extension for ERC-721 non-fungible token standard.
 * See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md.
 */
interface ERC721Enumerable {
	/**
	 * @dev Returns a count of valid NFTs tracked by this contract, where each one of them has an
	 * assigned and queryable owner not equal to the zero address.
	 * @return Total supply of NFTs.
	 */
	function totalSupply() external view returns (uint256);

	/**
	 * @dev Returns the token identifier for the `_index`th NFT. Sort order is not specified.
	 * @param _index A counter less than `totalSupply()`.
	 * @return Token id.
	 */
	function tokenByIndex(uint256 _index) external view returns (uint256);

	/**
	 * @dev Returns the token identifier for the `_index`th NFT assigned to `_owner`. Sort order is
	 * not specified. It throws if `_index` >= `balanceOf(_owner)` or if `_owner` is the zero address,
	 * representing invalid NFTs.
	 * @param _owner An address where we are interested in NFTs owned by them.
	 * @param _index A counter less than `balanceOf(_owner)`.
	 * @return Token id.
	 */
	function tokenOfOwnerByIndex(address _owner, uint256 _index)
		external
		view
		returns (uint256);
}

// File contracts/nf-token-enumerable.solpragma solidity 0.8.4;

/**
 * @dev Optional enumeration implementation for ERC-721 non-fungible token standard.
 */
contract NFTokenEnumerable is NFToken, ERC721Enumerable {
	/**
	 * @dev List of revert message codes. Implementing dApp should handle showing the correct message.
	 * Based on 0xcert framework error codes.
	 */
	string constant INVALID_INDEX = '005007';

	/**
	 * @dev Array of all NFT IDs.
	 */
	uint256[] internal tokens;

	/**
	 * @dev Mapping from token ID to its index in global tokens array.
	 */
	mapping(uint256 => uint256) internal idToIndex;

	/**
	 * @dev Mapping from owner to list of owned NFT IDs.
	 */
	mapping(address => uint256[]) internal ownerToIds;

	/**
	 * @dev Mapping from NFT ID to its index in the owner tokens list.
	 */
	mapping(uint256 => uint256) internal idToOwnerIndex;

	/**
	 * @dev Contract constructor.
	 */
	constructor() {
		supportedInterfaces[0x780e9d63] = true; // ERC721Enumerable
	}

	/**
	 * @dev Returns the count of all existing NFTokens.
	 * @return Total supply of NFTs.
	 */
	function totalSupply() external view override returns (uint256) {
		return tokens.length;
	}

	/**
	 * @dev Returns NFT ID by its index.
	 * @param _index A counter less than `totalSupply()`.
	 * @return Token id.
	 */
	function tokenByIndex(uint256 _index)
		external
		view
		override
		returns (uint256)
	{
		require(_index < tokens.length, INVALID_INDEX);
		return tokens[_index];
	}

	/**
	 * @dev returns the n-th NFT ID from a list of owner's tokens.
	 * @param _owner Token owner's address.
	 * @param _index Index number representing n-th token in owner's list of tokens.
	 * @return Token id.
	 */
	function tokenOfOwnerByIndex(address _owner, uint256 _index)
		external
		view
		override
		returns (uint256)
	{
		require(_index < ownerToIds[_owner].length, INVALID_INDEX);
		return ownerToIds[_owner][_index];
	}

	/**
	 * @notice This is an internal function which should be called from user-implemented external
	 * mint function. Its purpose is to show and properly initialize data structures when using this
	 * implementation.
	 * @dev Mints a new NFT.
	 * @param _to The address that will own the minted NFT.
	 * @param _tokenId of the NFT to be minted by the msg.sender.
	 */
	function _mint(address _to, uint256 _tokenId) internal virtual override {
		super._mint(_to, _tokenId);
		tokens.push(_tokenId);
		idToIndex[_tokenId] = tokens.length - 1;
	}

	/**
	 * @notice This is an internal function which should be called from user-implemented external
	 * burn function. Its purpose is to show and properly initialize data structures when using this
	 * implementation. Also, note that this burn implementation allows the minter to re-mint a burned
	 * NFT.
	 * @dev Burns a NFT.
	 * @param _tokenId ID of the NFT to be burned.
	 */
	function _burn(uint256 _tokenId) internal virtual override {
		super._burn(_tokenId);

		uint256 tokenIndex = idToIndex[_tokenId];
		uint256 lastTokenIndex = tokens.length - 1;
		uint256 lastToken = tokens[lastTokenIndex];

		tokens[tokenIndex] = lastToken;

		tokens.pop();
		// This wastes gas if you are burning the last token but saves a little gas if you are not.
		idToIndex[lastToken] = tokenIndex;
		idToIndex[_tokenId] = 0;
	}

	/**
	 * @notice Use and override this function with caution. Wrong usage can have serious consequences.
	 * @dev Removes a NFT from an address.
	 * @param _from Address from wich we want to remove the NFT.
	 * @param _tokenId Which NFT we want to remove.
	 */
	function _removeNFToken(address _from, uint256 _tokenId)
		internal
		virtual
		override
	{
		require(idToOwner[_tokenId] == _from, NOT_OWNER);
		delete idToOwner[_tokenId];

		uint256 tokenToRemoveIndex = idToOwnerIndex[_tokenId];
		uint256 lastTokenIndex = ownerToIds[_from].length - 1;

		if (lastTokenIndex != tokenToRemoveIndex) {
			uint256 lastToken = ownerToIds[_from][lastTokenIndex];
			ownerToIds[_from][tokenToRemoveIndex] = lastToken;
			idToOwnerIndex[lastToken] = tokenToRemoveIndex;
		}

		ownerToIds[_from].pop();
	}

	/**
	 * @notice Use and override this function with caution. Wrong usage can have serious consequences.
	 * @dev Assigns a new NFT to an address.
	 * @param _to Address to wich we want to add the NFT.
	 * @param _tokenId Which NFT we want to add.
	 */
	function _addNFToken(address _to, uint256 _tokenId)
		internal
		virtual
		override
	{
		require(idToOwner[_tokenId] == address(0), NFT_ALREADY_EXISTS);
		idToOwner[_tokenId] = _to;

		ownerToIds[_to].push(_tokenId);
		idToOwnerIndex[_tokenId] = ownerToIds[_to].length - 1;
	}

	/**
	 * @dev Helper function that gets NFT count of owner. This is needed for overriding in enumerable
	 * extension to remove double storage(gas optimization) of owner NFT count.
	 * @param _owner Address for whom to query the count.
	 * @return Number of _owner NFTs.
	 */
	function _getOwnerNFTCount(address _owner)
		internal
		view
		virtual
		override
		returns (uint256)
	{
		return ownerToIds[_owner].length;
	}
}

// File contracts/erc721-metadata.sol

pragma solidity 0.8.4;
/**
 * @dev Optional metadata extension for ERC-721 non-fungible token standard.
 * See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md.
 */

interface ERC721Metadata {
	/**
	 * @dev Returns a descriptive name for a collection of NFTs in this contract.
	 * @return _name Representing name.
	 */
	function name() external view returns (string memory _name);

	/**
	 * @dev Returns a abbreviated name for a collection of NFTs in this contract.
	 * @return _symbol Representing symbol.
	 */
	function symbol() external view returns (string memory _symbol);

	/**
	 * @dev Returns a distinct Uniform Resource Identifier (URI) for a given asset. It Throws if
	 * `_tokenId` is not a valid NFT. URIs are defined in RFC3986. The URI may point to a JSON file
	 * that conforms to the "ERC721 Metadata JSON Schema".
	 * @return URI of _tokenId.
	 */
	function tokenURI(uint256 _tokenId) external view returns (string memory);
}

// File contracts/nf-token-metadata.sol
pragma solidity 0.8.4;

/**
 * @dev Optional metadata implementation for ERC-721 non-fungible token standard.
 */
contract NFTokenMetadata is NFToken, ERC721Metadata {
	/**
	 * @dev A descriptive name for a collection of NFTs.
	 */
	string internal nftName;

	/**
	 * @dev An abbreviated name for NFTokens.
	 */
	string internal nftSymbol;

	/**
	 * @dev Mapping from NFT ID to metadata uri.
	 */
	mapping(uint256 => string) internal idToUri;

	/**
	 * @notice When implementing this contract don't forget to set nftName and nftSymbol.
	 * @dev Contract constructor.
	 */
	constructor() {
		supportedInterfaces[0x5b5e139f] = true; // ERC721Metadata
	}

	/**
	 * @dev Returns a descriptive name for a collection of NFTokens.
	 * @return _name Representing name.
	 */
	function name() external view override returns (string memory _name) {
		_name = nftName;
	}

	/**
	 * @dev Returns an abbreviated name for NFTokens.
	 * @return _symbol Representing symbol.
	 */
	function symbol() external view override returns (string memory _symbol) {
		_symbol = nftSymbol;
	}

	/**
	 * @dev A distinct URI (RFC 3986) for a given NFT.
	 * @param _tokenId Id for which we want uri.
	 * @return URI of _tokenId.
	 */
	function tokenURI(uint256 _tokenId)
		external
		view
		override
		validNFToken(_tokenId)
		returns (string memory)
	{
		return idToUri[_tokenId];
	}

	/**
	 * @notice This is an internal function which should be called from user-implemented external
	 * burn function. Its purpose is to show and properly initialize data structures when using this
	 * implementation. Also, note that this burn implementation allows the minter to re-mint a burned
	 * NFT.
	 * @dev Burns a NFT.
	 * @param _tokenId ID of the NFT to be burned.
	 */
	function _burn(uint256 _tokenId) internal virtual override {
		super._burn(_tokenId);

		delete idToUri[_tokenId];
	}

	/**
	 * @notice This is an internal function which should be called from user-implemented external
	 * function. Its purpose is to show and properly initialize data structures when using this
	 * implementation.
	 * @dev Set a distinct URI (RFC 3986) for a given NFT ID.
	 * @param _tokenId Id for which we want URI.
	 * @param _uri String representing RFC 3986 URI.
	 */
	function _setTokenUri(uint256 _tokenId, string memory _uri)
		internal
		validNFToken(_tokenId)
	{
		idToUri[_tokenId] = _uri;
	}
}

// File contracts/NFTokenMetadataEnumerable.sol
pragma solidity 0.8.4;

/**
 * @dev Optional metadata implementation for ERC-721 non-fungible token standard.
 */
abstract contract NFTokenEnumerableMetadata is
	NFToken,
	ERC721Metadata,
	ERC721Enumerable
{
	/**
	 * @dev A descriptive name for a collection of NFTs.
	 */
	string internal nftName;

	/**
	 * @dev An abbreviated name for NFTokens.
	 */
	string internal nftSymbol;

	/**
	 * @dev Mapping from NFT ID to metadata uri.
	 */
	mapping(uint256 => string) internal idToUri;

	/**
	 * @dev List of revert message codes. Implementing dApp should handle showing the correct message.
	 * Based on 0xcert framework error codes.
	 */
	string constant INVALID_INDEX = '005007';

	/**
	 * @dev Array of all NFT IDs.
	 */
	uint256[] internal tokens;

	/**
	 * @dev Mapping from token ID to its index in global tokens array.
	 */
	mapping(uint256 => uint256) internal idToIndex;

	/**
	 * @dev Mapping from owner to list of owned NFT IDs.
	 */
	mapping(address => uint256[]) internal ownerToIds;

	/**
	 * @dev Mapping from NFT ID to its index in the owner tokens list.
	 */
	mapping(uint256 => uint256) internal idToOwnerIndex;

	/**
	 * @notice When implementing this contract don't forget to set nftName and nftSymbol.
	 * @dev Contract constructor.
	 */
	constructor() {
		supportedInterfaces[0x780e9d63] = true; // ERC721Enumerable
		supportedInterfaces[0x5b5e139f] = true; // ERC721Metadata
	}

	/**
	 * @dev Returns a descriptive name for a collection of NFTokens.
	 * @return _name Representing name.
	 */
	function name() external view override returns (string memory _name) {
		_name = nftName;
	}

	/**
	 * @dev Returns an abbreviated name for NFTokens.
	 * @return _symbol Representing symbol.
	 */
	function symbol() external view override returns (string memory _symbol) {
		_symbol = nftSymbol;
	}

	/**
	 * @dev A distinct URI (RFC 3986) for a given NFT.
	 * @param _tokenId Id for which we want uri.
	 * @return URI of _tokenId.
	 */
	function tokenURI(uint256 _tokenId)
		external
		view
		override
		validNFToken(_tokenId)
		returns (string memory)
	{
		return idToUri[_tokenId];
	}

	/**
	 * @notice This is an internal function which should be called from user-implemented external
	 * function. Its purpose is to show and properly initialize data structures when using this
	 * implementation.
	 * @dev Set a distinct URI (RFC 3986) for a given NFT ID.
	 * @param _tokenId Id for which we want URI.
	 * @param _uri String representing RFC 3986 URI.
	 */
	function _setTokenUri(uint256 _tokenId, string memory _uri)
		internal
		validNFToken(_tokenId)
	{
		idToUri[_tokenId] = _uri;
	}

	/**
	 * @dev Returns the count of all existing NFTokens.
	 * @return Total supply of NFTs.
	 */
	function totalSupply() external view override returns (uint256) {
		return tokens.length;
	}

	/**
	 * @dev Returns NFT ID by its index.
	 * @param _index A counter less than `totalSupply()`.
	 * @return Token id.
	 */
	function tokenByIndex(uint256 _index)
		external
		view
		override
		returns (uint256)
	{
		require(_index < tokens.length, INVALID_INDEX);
		return tokens[_index];
	}

	/**
	 * @dev returns the n-th NFT ID from a list of owner's tokens.
	 * @param _owner Token owner's address.
	 * @param _index Index number representing n-th token in owner's list of tokens.
	 * @return Token id.
	 */
	function tokenOfOwnerByIndex(address _owner, uint256 _index)
		external
		view
		override
		returns (uint256)
	{
		require(_index < ownerToIds[_owner].length, INVALID_INDEX);
		return ownerToIds[_owner][_index];
	}

	/**
	 * @notice This is an internal function which should be called from user-implemented external
	 * mint function. Its purpose is to show and properly initialize data structures when using this
	 * implementation.
	 * @dev Mints a new NFT.
	 * @param _to The address that will own the minted NFT.
	 * @param _tokenId of the NFT to be minted by the msg.sender.
	 */
	function _mint(address _to, uint256 _tokenId) internal virtual override {
		super._mint(_to, _tokenId);
		tokens.push(_tokenId);
		idToIndex[_tokenId] = tokens.length - 1;
	}

	/**
	 * @notice This is an internal function which should be called from user-implemented external
	 * burn function. Its purpose is to show and properly initialize data structures when using this
	 * implementation. Also, note that this burn implementation allows the minter to re-mint a burned
	 * NFT.
	 * @dev Burns a NFT.
	 * @param _tokenId ID of the NFT to be burned.
	 */
	function _burn(uint256 _tokenId) internal virtual override {
		super._burn(_tokenId);

		uint256 tokenIndex = idToIndex[_tokenId];
		uint256 lastTokenIndex = tokens.length - 1;
		uint256 lastToken = tokens[lastTokenIndex];

		tokens[tokenIndex] = lastToken;

		tokens.pop();
		delete idToUri[_tokenId];
		// This wastes gas if you are burning the last token but saves a little gas if you are not.
		idToIndex[lastToken] = tokenIndex;
		idToIndex[_tokenId] = 0;
	}

	/**
	 * @notice Use and override this function with caution. Wrong usage can have serious consequences.
	 * @dev Removes a NFT from an address.
	 * @param _from Address from wich we want to remove the NFT.
	 * @param _tokenId Which NFT we want to remove.
	 */
	function _removeNFToken(address _from, uint256 _tokenId)
		internal
		virtual
		override
	{
		require(idToOwner[_tokenId] == _from, NOT_OWNER);
		delete idToOwner[_tokenId];

		uint256 tokenToRemoveIndex = idToOwnerIndex[_tokenId];
		uint256 lastTokenIndex = ownerToIds[_from].length - 1;

		if (lastTokenIndex != tokenToRemoveIndex) {
			uint256 lastToken = ownerToIds[_from][lastTokenIndex];
			ownerToIds[_from][tokenToRemoveIndex] = lastToken;
			idToOwnerIndex[lastToken] = tokenToRemoveIndex;
		}

		ownerToIds[_from].pop();
	}

	/**
	 * @notice Use and override this function with caution. Wrong usage can have serious consequences.
	 * @dev Assigns a new NFT to an address.
	 * @param _to Address to wich we want to add the NFT.
	 * @param _tokenId Which NFT we want to add.
	 */
	function _addNFToken(address _to, uint256 _tokenId)
		internal
		virtual
		override
	{
		require(idToOwner[_tokenId] == address(0), NFT_ALREADY_EXISTS);
		idToOwner[_tokenId] = _to;

		ownerToIds[_to].push(_tokenId);
		idToOwnerIndex[_tokenId] = ownerToIds[_to].length - 1;
	}

	/**
	 * @dev Helper function that gets NFT count of owner. This is needed for overriding in enumerable
	 * extension to remove double storage(gas optimization) of owner NFT count.
	 * @param _owner Address for whom to query the count.
	 * @return Number of _owner NFTs.
	 */
	function _getOwnerNFTs(address _owner)
		internal
		view
		virtual
		returns (uint256[] memory)
	{
		return ownerToIds[_owner];
	}

	/**
	 * @dev Helper function that gets NFT count of owner. This is needed for overriding in enumerable
	 * extension to remove double storage(gas optimization) of owner NFT count.
	 * @param _owner Address for whom to query the count.
	 * @return Number of _owner NFTs.
	 */
	function _getOwnerNFTCount(address _owner)
		internal
		view
		virtual
		override
		returns (uint256)
	{
		return ownerToIds[_owner].length;
	}
}

// File @openzeppelin/contracts/utils/[email protected] solidity 0.8.4;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
	function _msgSender() internal view virtual returns (address) {
		return msg.sender;
	}

	function _msgData() internal view virtual returns (bytes calldata) {
		return msg.data;
	}
}

// File @openzeppelin/contracts/access/[email protected] solidity 0.8.4;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
	address private _owner;

	event OwnershipTransferred(
		address indexed previousOwner,
		address indexed newOwner
	);

	/**
	 * @dev Initializes the contract setting the deployer as the initial owner.
	 */
	constructor() {
		_setOwner(_msgSender());
	}

	/**
	 * @dev Returns the address of the current owner.
	 */
	function owner() public view virtual returns (address) {
		return _owner;
	}

	/**
	 * @dev Throws if called by any account other than the owner.
	 */
	modifier onlyOwner() {
		require(owner() == _msgSender(), 'Ownable: caller is not the owner');
		_;
	}

	/**
	 * @dev Leaves the contract without owner. It will not be possible to call
	 * `onlyOwner` functions anymore. Can only be called by the current owner.
	 *
	 * NOTE: Renouncing ownership will leave the contract without an owner,
	 * thereby removing any functionality that is only available to the owner.
	 */
	function renounceOwnership() public virtual onlyOwner {
		_setOwner(address(0));
	}

	/**
	 * @dev Transfers ownership of the contract to a new account (`newOwner`).
	 * Can only be called by the current owner.
	 */
	function transferOwnership(address newOwner) public virtual onlyOwner {
		require(
			newOwner != address(0),
			'Ownable: new owner is the zero address'
		);
		_setOwner(newOwner);
	}

	function _setOwner(address newOwner) private {
		address oldOwner = _owner;
		_owner = newOwner;
		emit OwnershipTransferred(oldOwner, newOwner);
	}
}

// File @openzeppelin/contracts/utils/math/[email protected]

pragma solidity 0.8.4; // CAUTION

// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
	/**
	 * @dev Returns the addition of two unsigned integers, with an overflow flag.
	 *
	 * _Available since v3.4._
	 */
	function tryAdd(uint256 a, uint256 b)
		internal
		pure
		returns (bool, uint256)
	{
		unchecked {
			uint256 c = a + b;
			if (c < a) return (false, 0);
			return (true, c);
		}
	}

	/**
	 * @dev Returns the substraction of two unsigned integers, with an overflow flag.
	 *
	 * _Available since v3.4._
	 */
	function trySub(uint256 a, uint256 b)
		internal
		pure
		returns (bool, uint256)
	{
		unchecked {
			if (b > a) return (false, 0);
			return (true, a - b);
		}
	}

	/**
	 * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
	 *
	 * _Available since v3.4._
	 */
	function tryMul(uint256 a, uint256 b)
		internal
		pure
		returns (bool, uint256)
	{
		unchecked {
			// Gas optimization: this is cheaper than requiring 'a' not being zero, but the
			// benefit is lost if 'b' is also tested.
			// See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
			if (a == 0) return (true, 0);
			uint256 c = a * b;
			if (c / a != b) return (false, 0);
			return (true, c);
		}
	}

	/**
	 * @dev Returns the division of two unsigned integers, with a division by zero flag.
	 *
	 * _Available since v3.4._
	 */
	function tryDiv(uint256 a, uint256 b)
		internal
		pure
		returns (bool, uint256)
	{
		unchecked {
			if (b == 0) return (false, 0);
			return (true, a / b);
		}
	}

	/**
	 * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
	 *
	 * _Available since v3.4._
	 */
	function tryMod(uint256 a, uint256 b)
		internal
		pure
		returns (bool, uint256)
	{
		unchecked {
			if (b == 0) return (false, 0);
			return (true, a % b);
		}
	}

	/**
	 * @dev Returns the addition of two unsigned integers, reverting on
	 * overflow.
	 *
	 * Counterpart to Solidity's `+` operator.
	 *
	 * Requirements:
	 *
	 * - Addition cannot overflow.
	 */
	function add(uint256 a, uint256 b) internal pure returns (uint256) {
		return a + b;
	}

	/**
	 * @dev Returns the subtraction of two unsigned integers, reverting on
	 * overflow (when the result is negative).
	 *
	 * Counterpart to Solidity's `-` operator.
	 *
	 * Requirements:
	 *
	 * - Subtraction cannot overflow.
	 */
	function sub(uint256 a, uint256 b) internal pure returns (uint256) {
		return a - b;
	}

	/**
	 * @dev Returns the multiplication of two unsigned integers, reverting on
	 * overflow.
	 *
	 * Counterpart to Solidity's `*` operator.
	 *
	 * Requirements:
	 *
	 * - Multiplication cannot overflow.
	 */
	function mul(uint256 a, uint256 b) internal pure returns (uint256) {
		return a * b;
	}

	/**
	 * @dev Returns the integer division of two unsigned integers, reverting on
	 * division by zero. The result is rounded towards zero.
	 *
	 * Counterpart to Solidity's `/` operator.
	 *
	 * Requirements:
	 *
	 * - The divisor cannot be zero.
	 */
	function div(uint256 a, uint256 b) internal pure returns (uint256) {
		return a / b;
	}

	/**
	 * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
	 * reverting when dividing by zero.
	 *
	 * Counterpart to Solidity's `%` operator. This function uses a `revert`
	 * opcode (which leaves remaining gas untouched) while Solidity uses an
	 * invalid opcode to revert (consuming all remaining gas).
	 *
	 * Requirements:
	 *
	 * - The divisor cannot be zero.
	 */
	function mod(uint256 a, uint256 b) internal pure returns (uint256) {
		return a % b;
	}

	/**
	 * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
	 * overflow (when the result is negative).
	 *
	 * CAUTION: This function is deprecated because it requires allocating memory for the error
	 * message unnecessarily. For custom revert reasons use {trySub}.
	 *
	 * Counterpart to Solidity's `-` operator.
	 *
	 * Requirements:
	 *
	 * - Subtraction cannot overflow.
	 */
	function sub(
		uint256 a,
		uint256 b,
		string memory errorMessage
	) internal pure returns (uint256) {
		unchecked {
			require(b <= a, errorMessage);
			return a - b;
		}
	}

	/**
	 * @dev Returns the integer division of two unsigned integers, reverting with custom message on
	 * division by zero. The result is rounded towards zero.
	 *
	 * Counterpart to Solidity's `/` operator. Note: this function uses a
	 * `revert` opcode (which leaves remaining gas untouched) while Solidity
	 * uses an invalid opcode to revert (consuming all remaining gas).
	 *
	 * Requirements:
	 *
	 * - The divisor cannot be zero.
	 */
	function div(
		uint256 a,
		uint256 b,
		string memory errorMessage
	) internal pure returns (uint256) {
		unchecked {
			require(b > 0, errorMessage);
			return a / b;
		}
	}

	/**
	 * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
	 * reverting with custom message when dividing by zero.
	 *
	 * CAUTION: This function is deprecated because it requires allocating memory for the error
	 * message unnecessarily. For custom revert reasons use {tryMod}.
	 *
	 * Counterpart to Solidity's `%` operator. This function uses a `revert`
	 * opcode (which leaves remaining gas untouched) while Solidity uses an
	 * invalid opcode to revert (consuming all remaining gas).
	 *
	 * Requirements:
	 *
	 * - The divisor cannot be zero.
	 */
	function mod(
		uint256 a,
		uint256 b,
		string memory errorMessage
	) internal pure returns (uint256) {
		unchecked {
			require(b > 0, errorMessage);
			return a % b;
		}
	}
}


 
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
	function transfer(address recipient, uint256 amount)
		external
		returns (bool);

	/**
	 * @dev Returns the remaining number of tokens that `spender` will be
	 * allowed to spend on behalf of `owner` through {transferFrom}. This is
	 * zero by default.
	 *
	 * This value changes when {approve} or {transferFrom} are called.
	 */
	function allowance(address owner, address spender)
		external
		view
		returns (uint256);

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
	function transferFrom(
		address sender,
		address recipient,
		uint256 amount
	) external returns (bool);

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
	event Approval(
		address indexed owner,
		address indexed spender,
		uint256 value
	);
}

// File @openzeppelin/contracts/utils/[email protected] solidity 0.8.4;

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
		// This method relies on extcodesize, which returns 0 for contracts in
		// construction, since the code is only stored at the end of the
		// constructor execution.

		uint256 size;
		assembly {
			size := extcodesize(account)
		}
		return size > 0;
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
	function sendValue(address payable recipient, uint256 amount) internal {
		require(
			address(this).balance >= amount,
			'Address: insufficient balance'
		);

		(bool success, ) = recipient.call{value: amount}('');
		require(
			success,
			'Address: unable to send value, recipient may have reverted'
		);
	}

	/**
	 * @dev Performs a Solidity function call using a low level `call`. A
	 * plain `call` is an unsafe replacement for a function call: use this
	 * function instead.
	 *
	 * If `target` reverts with a revert reason, it is bubbled up by this
	 * function (like regular Solidity function calls).
	 *
	 * Returns the raw returned data. To convert to the expected return value,
	 * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
	 *
	 * Requirements:
	 *
	 * - `target` must be a contract.
	 * - calling `target` with `data` must not revert.
	 *
	 * _Available since v3.1._
	 */
	function functionCall(address target, bytes memory data)
		internal
		returns (bytes memory)
	{
		return functionCall(target, data, 'Address: low-level call failed');
	}

	/**
	 * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
	 * `errorMessage` as a fallback revert reason when `target` reverts.
	 *
	 * _Available since v3.1._
	 */
	function functionCall(
		address target,
		bytes memory data,
		string memory errorMessage
	) internal returns (bytes memory) {
		return functionCallWithValue(target, data, 0, errorMessage);
	}

	/**
	 * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
	 * but also transferring `value` wei to `target`.
	 *
	 * Requirements:
	 *
	 * - the calling contract must have an ETH balance of at least `value`.
	 * - the called Solidity function must be `payable`.
	 *
	 * _Available since v3.1._
	 */
	function functionCallWithValue(
		address target,
		bytes memory data,
		uint256 value
	) internal returns (bytes memory) {
		return
			functionCallWithValue(
				target,
				data,
				value,
				'Address: low-level call with value failed'
			);
	}

	/**
	 * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
	 * with `errorMessage` as a fallback revert reason when `target` reverts.
	 *
	 * _Available since v3.1._
	 */
	function functionCallWithValue(
		address target,
		bytes memory data,
		uint256 value,
		string memory errorMessage
	) internal returns (bytes memory) {
		require(
			address(this).balance >= value,
			'Address: insufficient balance for call'
		);
		require(isContract(target), 'Address: call to non-contract');

		(bool success, bytes memory returndata) = target.call{value: value}(
			data
		);
		return verifyCallResult(success, returndata, errorMessage);
	}

	/**
	 * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
	 * but performing a static call.
	 *
	 * _Available since v3.3._
	 */
	function functionStaticCall(address target, bytes memory data)
		internal
		view
		returns (bytes memory)
	{
		return
			functionStaticCall(
				target,
				data,
				'Address: low-level static call failed'
			);
	}

	/**
	 * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
	 * but performing a static call.
	 *
	 * _Available since v3.3._
	 */
	function functionStaticCall(
		address target,
		bytes memory data,
		string memory errorMessage
	) internal view returns (bytes memory) {
		require(isContract(target), 'Address: static call to non-contract');

		(bool success, bytes memory returndata) = target.staticcall(data);
		return verifyCallResult(success, returndata, errorMessage);
	}

	/**
	 * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
	 * but performing a delegate call.
	 *
	 * _Available since v3.4._
	 */
	function functionDelegateCall(address target, bytes memory data)
		internal
		returns (bytes memory)
	{
		return
			functionDelegateCall(
				target,
				data,
				'Address: low-level delegate call failed'
			);
	}

	/**
	 * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
	 * but performing a delegate call.
	 *
	 * _Available since v3.4._
	 */
	function functionDelegateCall(
		address target,
		bytes memory data,
		string memory errorMessage
	) internal returns (bytes memory) {
		require(isContract(target), 'Address: delegate call to non-contract');

		(bool success, bytes memory returndata) = target.delegatecall(data);
		return verifyCallResult(success, returndata, errorMessage);
	}

	/**
	 * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
	 * revert reason using the provided one.
	 *
	 * _Available since v4.3._
	 */
	function verifyCallResult(
		bool success,
		bytes memory returndata,
		string memory errorMessage
	) internal pure returns (bytes memory) {
		if (success) {
			return returndata;
		} else {
			// Look for revert reason and bubble it up if present
			if (returndata.length > 0) {
				// The easiest way to bubble the revert reason is using memory via assembly

				assembly {
					let returndata_size := mload(returndata)
					revert(add(32, returndata), returndata_size)
				}
			} else {
				revert(errorMessage);
			}
		}
	}
}

// File @openzeppelin/contracts/token/ERC20/utils/[email protected]

pragma solidity 0.8.4;
/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */

library SafeERC20 {
	using Address for address;

	function safeTransfer(
		IERC20 token,
		address to,
		uint256 value
	) internal {
		_callOptionalReturn(
			token,
			abi.encodeWithSelector(token.transfer.selector, to, value)
		);
	}

	function safeTransferFrom(
		IERC20 token,
		address from,
		address to,
		uint256 value
	) internal {
		_callOptionalReturn(
			token,
			abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
		);
	}

	/**
	 * @dev Deprecated. This function has issues similar to the ones found in
	 * {IERC20-approve}, and its usage is discouraged.
	 *
	 * Whenever possible, use {safeIncreaseAllowance} and
	 * {safeDecreaseAllowance} instead.
	 */
	function safeApprove(
		IERC20 token,
		address spender,
		uint256 value
	) internal {
		// safeApprove should only be called when setting an initial allowance,
		// or when resetting it to zero. To increase and decrease it, use
		// 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
		require(
			(value == 0) || (token.allowance(address(this), spender) == 0),
			'SafeERC20: approve from non-zero to non-zero allowance'
		);
		_callOptionalReturn(
			token,
			abi.encodeWithSelector(token.approve.selector, spender, value)
		);
	}

	function safeIncreaseAllowance(
		IERC20 token,
		address spender,
		uint256 value
	) internal {
		uint256 newAllowance = token.allowance(address(this), spender) + value;
		_callOptionalReturn(
			token,
			abi.encodeWithSelector(
				token.approve.selector,
				spender,
				newAllowance
			)
		);
	}

	function safeDecreaseAllowance(
		IERC20 token,
		address spender,
		uint256 value
	) internal {
		unchecked {
			uint256 oldAllowance = token.allowance(address(this), spender);
			require(
				oldAllowance >= value,
				'SafeERC20: decreased allowance below zero'
			);
			uint256 newAllowance = oldAllowance - value;
			_callOptionalReturn(
				token,
				abi.encodeWithSelector(
					token.approve.selector,
					spender,
					newAllowance
				)
			);
		}
	}

	/**
	 * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
	 * on the return value: the return value is optional (but if data is returned, it must not be false).
	 * @param token The token targeted by the call.
	 * @param data The call data (encoded using abi.encode or one of its variants).
	 */
	function _callOptionalReturn(IERC20 token, bytes memory data) private {
		// We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
		// we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
		// the target address contains contract code and also asserts for success in the low-level call.

		bytes memory returndata = address(token).functionCall(
			data,
			'SafeERC20: low-level call failed'
		);
		if (returndata.length > 0) {
			// Return data is optional
			require(
				abi.decode(returndata, (bool)),
				'SafeERC20: ERC20 operation did not succeed'
			);
		}
	}
}

// File contracts/CeloPunks.sol
pragma solidity 0.8.4;

contract CeloPunks is NFTokenEnumerableMetadata, Ownable {
	using SafeMath for uint256;

    // TODO: Change the price
	uint256 public price = 15 ether;
	uint256 public maxSupply = 10_000;
	uint256 public maxMintNFT = 15;
	uint256 public royaltyFee = 20;
	string public baseUri = 'https://ipfs.io/ipfs/QmV9ixmfGpsZib9v3r2LFDuAcUSyzfTpnK2d3JyjaqfGYm/';
	mapping (uint256 => address) public originalMinter;
	mapping (address => uint256) public amountMintedPerAddress;
	mapping (address => bool) public didPremint;
	mapping (address => uint256) public marketingWallets;

	event PriceUpdated(uint256 newPrice);
	event MaxSupplyUpdated(uint256 newMaxSupply);
	event BaseUriUpdated(string newBaseUri);
	event royaltyFeeUpdated(uint256 royaltyFee);

	constructor() {
		nftName = 'IoTeXPunks';
		nftSymbol = 'GenXPunks';


		marketingWallets[msg.sender] = 100;
	}

	function premint(address preMinter) external {
		require(marketingWallets[preMinter] > 0, 'No premint for this address');
		require(!didPremint[preMinter], 'Already did premint');
		require(maxSupply > this.totalSupply(), 'Sold out');

		// Premint for influencers
			didPremint[preMinter] = true;
			for (uint256 j=0; j < marketingWallets[preMinter]; j++) {
				uint256 currentSupply = this.totalSupply();

				uint256 tokenId = currentSupply;
				address to = preMinter;

				super._mint(to, tokenId);
				super._setTokenUri(
					tokenId,
					string(abi.encodePacked(baseUri, toString(tokenId), '.json'))
				);
				originalMinter[tokenId] = preMinter;
				}
			
	}

	function mint() external payable {
		// TODO: Uncomment this
		require(block.timestamp > 1633377600, 'Please wait until minting starts');
		require(msg.value >= price, 'Amount is less than price');
		require(maxSupply > this.totalSupply(), 'Sold out');

		uint256 count = msg.value / price;
		require(count <= maxMintNFT, 'Mint less NFTs please');
		require(maxSupply > (this.totalSupply() + count), 'Almost sold out, please mint less punks');

		for (uint256 i = 0; i < count; i++) {
			uint256 currentSupply = this.totalSupply();

			uint256 tokenId = currentSupply;
			address to = msg.sender;

			super._mint(to, tokenId);

			super._setTokenUri(
				tokenId,
				string(abi.encodePacked(baseUri, toString(tokenId), '.json'))
			);

			originalMinter[tokenId] = msg.sender;
		}
	}

	function getOwnerNFTs(address _owner)
		public
		view
		returns (uint256[] memory)
	{
		return super._getOwnerNFTs(_owner);
	}

	function withdraw() external onlyOwner {
		payable(msg.sender).transfer(address(this).balance);
	}

	function updatePrice(uint256 _newPrice) public onlyOwner {
		price = _newPrice;
		emit PriceUpdated(_newPrice);
	}

	function updateMaxSupply(uint256 _maxSupply) public onlyOwner {
		maxSupply = _maxSupply;
		emit MaxSupplyUpdated(_maxSupply);
	}

	function updateroyaltyFee(uint _royaltyFee) public onlyOwner {
		require(_royaltyFee < 100);
		royaltyFee = _royaltyFee;
		emit royaltyFeeUpdated(_royaltyFee);
	}

	function updateBaseUri(string memory _baseUri) public onlyOwner {
		baseUri = _baseUri;
		emit BaseUriUpdated(_baseUri);
	}

	// EIP-2981
	function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view 
		returns (address receiver, uint256 royaltyRate) {

			address _receiver = originalMinter[_tokenId];
			uint256 _royaltyFee = _salePrice - ((_salePrice * royaltyFee) / 1000);
			return(_receiver, _royaltyFee);
		}


	function toString(uint256 value) internal pure returns (string memory) {
		// Inspired by OraclizeAPI's implementation - MIT license
		// https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol
		if (value == 0) {
			return '0';
		}
		uint256 temp = value;
		uint256 digits;
		while (temp != 0) {
			digits++;
			temp /= 10;
		}
		bytes memory buffer = new bytes(digits);
		while (value != 0) {
			digits -= 1;
			buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
			value /= 10;
		}
		return string(buffer);
	}
}

// File @openzeppelin/contracts/token/ERC20/[email protected] solidity 0.8.4;