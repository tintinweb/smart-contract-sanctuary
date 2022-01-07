/**
 *Submitted for verification at Etherscan.io on 2022-01-07
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;
// Creates a standard method to publish and detect what interfaces a smart contract implements.
interface IERC165 {
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
// IERC165 implementation.
abstract contract ERC165 is IERC165 {

        function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
                return interfaceId == type(IERC165).interfaceId;
        }
}
// A standard interface for non-fungible tokens, also known as deeds.
interface IERC721 is IERC165 {
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
    function balanceOf(address _owner) external view returns (uint256);
        /**
      * @notice Find the owner of an NFT
      * @dev NFTs assigned to zero address are considered invalid, and queries
      *  about them do throw.
      * @param _tokenId The identifier for an NFT
      * @return The address of the owner of the NFT
          */
    function ownerOf(uint256 _tokenId) external view returns (address);
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
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory data) external;
        /**
      * @notice Transfers the ownership of an NFT from one address to another address
      * @dev This works identically to the other function with an extra data parameter,
      *  except this function just sets data to "".
      * @param _from The current owner of the NFT
      * @param _to The new owner
      * @param _tokenId The NFT to transfer
          */
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external;
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
    function transferFrom(address _from, address _to, uint256 _tokenId) external;
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
      *  all of `msg.sender`'s assets
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
    function getApproved(uint256 _tokenId) external view returns (address);
        /**
      * @notice Query if an address is an authorized operator for another address
      * @param _owner The address that owns the NFTs
      * @param _operator The address that acts on behalf of the owner
      * @return True if `_operator` is an approved operator for `_owner`, false otherwise
          */
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}
/**
  * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
  * @dev See https://eips.ethereum.org/EIPS/eip-721
  *  Note: the ERC-165 identifier for this interface is 0x5b5e139f.
  */
interface IERC721Metadata {
        /**
          * @notice A descriptive name for a collection of NFTs in this contract
          */
    function name() external view returns (string memory);
        /**
      * @notice An abbreviated name for NFTs in this contract
          */
    function symbol() external view returns (string memory);
        /**
      * @notice A distinct Uniform Resource Identifier (URI) for a given asset.
      * @dev Throws if `_tokenId` is not a valid NFT. URIs are defined in RFC
      *  3986. The URI may point to a JSON file that conforms to the "ERC721
      *  Metadata JSON Schema".
          */
    function tokenURI(uint256 _tokenId) external view returns (string memory);
}
interface IERC721Receiver {
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
        function onERC721Received(
                address _operator,
                address _from,
                uint256 _tokenId,
                bytes memory _data
        ) external returns (bytes4);
}
// @dev uint256 type conversion and counter library.
library UINT256 {
        /**
          * @dev Converts uint256 to string.
          */
        function toString(uint256 _value) internal pure returns (string memory) {
                // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol
                if (_value == 0) {
                        return "0";
                }
                uint256 temp = _value;
                uint256 digits;

                while (temp != 0) {
                        digits++;
                        temp /= 10;
                }
                bytes memory buffer = new bytes(digits);
                while (_value != 0) {
                        digits -= 1;
                        buffer[digits] = bytes1(uint8(48 + uint256(_value % 10)));
                        _value /= 10;
                }
                return string(buffer);
        }
}
// implementation of IERC721.
contract ERC721 is IERC721, IERC721Metadata, ERC165 {
        using UINT256 for uint256;
        // Token name.
        string private _name;
        // Token symbol.
        string private _symbol;
        // mapping from token ID to owner address
        mapping(uint256 => address) private _ownerOf;
        // mapping owner address to token count
        mapping(address => uint256) private _balanceOf;
        // mapping from token ID to approved address
        mapping(uint256 => address) private _tokenApprovals;

        // mapping from owner to operator approvals
        mapping(address => mapping(address => bool)) private _operatorApprovals;
        // initialize contract by setting `name` and `symbol` of the token.
        constructor(string memory name_, string memory symbol_) {
                _name = name_;
                _symbol = symbol_;
        }
        // @dev see {IERC165 - supportsInterface}
        function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
                return
                        interfaceId == type(IERC721).interfaceId
                        ||
                        interfaceId == type(IERC721Metadata).interfaceId
                        ||
                        super.supportsInterface(interfaceId);
        }
        // @dev see{IERC721Metadata - name}
        function name() public view virtual override returns (string memory) {
                return _name;
        }
        // @dev see{IERC721Metadata - symbol}
        function symbol() public view virtual override returns (string memory) {
                return _symbol;
        }
        // @dev see{IERC721Metadata - tokenURI}
        function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
                require(_ownerOf[_tokenId] != address(0), "Error: query for non exist token.");
                string memory baseURI = _baseURI();
                return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, _tokenId.toString())) : "";
        }
        // @dev see{IERC721 - balanceOf}
        function balanceOf(address _owner) public view virtual override returns (uint256) {
                require(_owner != address(0), "Error: query for zero address.");
                return _balanceOf[_owner];
        }
        // @dev see{IERC721 - ownerOf}
        function ownerOf(uint256 _tokenId) public view virtual override returns (address) {
                address owner = _ownerOf[_tokenId];
                require(isExist(_tokenId), "Error: query for non exist token.");

                return owner;
        }
        // @dev see{IERC721 - transferFrom}
        function transferFrom(address _from, address _to, uint256 _tokenId) public virtual {
                address owner = _ownerOf[_tokenId];
                require(isExist(_tokenId), "Error: query for non exist token.");
                require(msg.sender == owner || getApproved(_tokenId) == msg.sender || isApprovedForAll(owner, msg.sender), "Error: transactor is not owner or approved.");
                _transfer(_from, _to, _tokenId);
        }
        // @dev see{IERC721 - safeTransferFrom}
        function safeTransferFrom(address _from, address _to, uint256 _tokenId) public virtual override {

                safeTransferFrom(_from, _to, _tokenId, "");
        }
        // @dev see{IERC721 - safeTransferFrom}
        function safeTransferFrom(
                address _from,
                address _to,
                uint256 _tokenId,
                bytes memory data
        ) public virtual override {
                address owner = _ownerOf[_tokenId];
                require(isExist(_tokenId), "Error: query for non exist token.");
                require(msg.sender == owner || getApproved(_tokenId) == msg.sender || isApprovedForAll(owner, msg.sender), "Error: transactor is not owner or approved.");

                _transfer(_from, _to, _tokenId);
                require(_checkOnERC721Received(_from, _to, _tokenId, data), "Error: transfer to non ERC721Receiver implementer");
        }
        // @dev see{IERC721 - approve}
        function approve(address _approved, uint256 _tokenId) public virtual override {
                address owner = ownerOf(_tokenId);
                require(owner == msg.sender || isApprovedForAll(owner, msg.sender), "Error: transactor is not owner or approved for all.");
                require(_approved != address(0), "Error: approval to zero address");
                _tokenApprovals[_tokenId] = _approved;
                emit Approval(owner, _approved, _tokenId);
        }
        // @dev see{IERC721 - setApprovalForAll}
        function setApprovalForAll(address _operator, bool _approved) public virtual override {
                require(msg.sender != _operator, "Error: approval to transactor.");
                _operatorApprovals[msg.sender][_operator] = _approved;
                emit ApprovalForAll(msg.sender, _operator, _approved);
        }
        // @dev see{IERC721 - getApproved}
        function getApproved(uint256 _tokenId) public view virtual override returns (address) {
                require(isExist(_tokenId), "Error: query for non exist token.");
                return _tokenApprovals[_tokenId];
        }
        // @dev see{IERC721 - isApprovedForAll}
        function isApprovedForAll(address _owner, address _operator) public view virtual override returns (bool) {
                return _operatorApprovals[_owner][_operator];
        }
        /**
      * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
      * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
      * by default, can be overriden in child contracts.
      */
        function _baseURI() internal view virtual returns (string memory) {
                return "";
        }
        /**
          * @dev Transfers `_tokenId` from `_from` to `_to`.
          * Requirements:
          *
          * - `_to` cannot be zero address.
          * - `_tokenId` must  by `_from`
          *
          * Emits a {Transfer} event.
          */
        function _transfer(address _from, address _to, uint256 _tokenId) internal virtual {
                require(ownerOf(_tokenId) == _from, "Error: transfer from incorrect owner.");
                require(_to != address(0), "Error: transfer to zero address");
                // clear approvals
                _tokenApprovals[_tokenId] = address(0);
                _balanceOf[_from] -= 1;
                _balanceOf[_to] += 1;
                _ownerOf[_tokenId] = _to;
                emit Transfer(_from, _to, _tokenId);
        }
        /**
      * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
      * The call is not executed if the target address is not a contract.
      *
      * @param _from address representing the previous owner of the given token ID
      * @param _to target address that will receive the tokens
      * @param _tokenId uint256 ID of the token to be transferred
      * @param _data bytes optional data to send along with the call
      * @return bool whether the call correctly returned the expected magic value
      */
        function _checkOnERC721Received(
                address _from,
                address _to,
                uint256 _tokenId,
                bytes memory _data
        ) private returns (bool) {
                if (_to.code.length > 0) {

                        try IERC721Receiver(_to).onERC721Received(msg.sender, _from, _tokenId, _data) returns (bytes4 retval) {
                                return retval == IERC721Receiver.onERC721Received.selector;
                        } catch (bytes memory reason) {
                                if (reason.length == 0) {
                                        revert("Error: transfer to non ERC721Receiver implementer.");
                                } else {
                                        assembly {
                                                revert(add(32, reason), mload(reason))
                                        }
                                }
                        }
                } else {
                        return true;
                }
        }
        /**
          * @dev Mint `_tokenId` to `_to`.
          *
          * Requirements:
          *
          * - `_tokenId` must not exist.
          * - `_to` cannot be zero address.
          * - if `_to` is contract address must be ERC721Receiver implementer.
          *
          * Emits {Transfer} event.
          */
        function _mint(address _to, uint256 _tokenId) internal virtual {
                require(_to != address(0), "Error: minting to zero address.");
                require(!isExist(_tokenId), "Error: token already minted.");
                require(_checkOnERC721Received(address(0), _to, _tokenId, ""), "Error: mint to non ERC721Receiver implementer.");
                _balanceOf[_to] += 1;
                _ownerOf[_tokenId] = _to;
                emit Transfer(address(0), _to, _tokenId);
        }
        /**
          * @dev Burn `_tokenId` and clear Approval.
          *
          * Requirements:
          *
          * - `_tokenId` must exist.
          *
          * Emits {Transfer} event.
          */
        function _burn(uint256 _tokenId) internal virtual {
                address owner = ownerOf(_tokenId);
                require(msg.sender == owner || getApproved(_tokenId) == msg.sender || isApprovedForAll(owner, msg.sender), "Error: transactor is not owner or approved.");
                _tokenApprovals[_tokenId] = address(0);
                delete _ownerOf[_tokenId];
                emit Transfer(owner, address(0), _tokenId);
        }
        /**
          * @dev Check if `_tokenId` exist or not owned by zero address
          *
          * @param _tokenId is id for the NFT token.
          */
        function isExist(uint256 _tokenId) internal view virtual returns (bool) {
                return _ownerOf[_tokenId] != address(0);
        }
}
/**
  * @dev ERC721 URI storage management
  */
abstract contract ERC721URIStorage is ERC721 {
        using UINT256 for uint256;
        // mapping for token uri.
        mapping(uint256 => string) private _URIs;
        // @dev see{IERC721Metadata - tokenURI}
        function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
                require(isExist(_tokenId), "Error: query for non exist token.");
                string memory tokenURI_ = _URIs[_tokenId];
                string memory base_ = _baseURI();
                if (bytes(base_).length == 0) {
                        return tokenURI_;
                }
                if (bytes(tokenURI_).length > 0) {
                        return string(abi.encodePacked(base_, tokenURI_));
                }
                return super.tokenURI(_tokenId);
        }
        /**
          * @dev Set _uri for _tokenId
          *
          * @param _uri string of the URI
          * @param _tokenId id of the token
          *
          * Requirements:
          *
          * - `_tokenId` must exist
          */
        function _setURI(uint256 _tokenId, string memory _uri) internal virtual {
                require(isExist(_tokenId), "Error: query for non exist token.");
                _URIs[_tokenId] = _uri;
        }
        // @dev Override {ERC721 - _burn}
        function _burn(uint256 _tokenId) internal virtual override {
                super._burn(_tokenId);
                if (bytes(_URIs[_tokenId]).length != 0) {
                        delete _URIs[_tokenId];
                }

        }
}
// @dev Group of granted address.
abstract contract AdminGroup {
        using UINT256 for uint256;
        mapping(address => uint256) private _admin;
        uint256 private _baseAdmin = 1;
        uint256 private _superAdmin = 2;
        bytes32 private _secret;
        event AddAdmin(address indexed _user, uint256 _role);
        event RemoveAdmin(address indexed _user, uint256 _role);
        event TransferAdmin(address indexed _from, address indexed _to, uint256 _role);

        /**
          * @dev Set super admin for the group.
          *
          * @param _user is address of the user will be asigned to roles group.
          *
          * Requirements:
          *
          * - `_user` must be `false` or never be granted.
          */
        function superAdmin(address _user) internal {
                require(!isAdmin(_user), "Error: this address already granted.");
                _admin[_user] = _superAdmin;
                emit AddAdmin(_user, _superAdmin);
        }
        // @dev Check if given address was granted.
        function isAdmin(address _user) internal view returns (bool) {
                uint256 role = getRole(_user);
                return role == _baseAdmin || role == _superAdmin;
        }
        // @dev Get current roles of the user.
        function getRole(address _user) internal view returns (uint256) {
                return _admin[_user];
        }
        /**
          * @dev Modifier that check if transactor has required roles.
          * @param _role is the level ove required roles.
          *
          * Requirements:
          *
          * - `_role` should be available.
          * - if `role` is base admin, super admin should be granted.
          */
        modifier roleGroup(uint256 _role) {
                if(_role != _baseAdmin || _role != _superAdmin) {
                        revert(
                                string(
                                        abi.encodePacked(
                                                "Error: unsupported roles, use ",
                                                _baseAdmin.toString(),
                                                " for base admin or ",
                                                _superAdmin.toString(),
                                                " for super admin instead."
                                        )
                                )
                        );
                }
                if (_role == _baseAdmin) {
                        require(isAdmin(msg.sender), "Error: min base admin roles needed.");
                } else {
                        require(getRole(msg.sender) == _role, "Error: super admin roles needed.");
                }
                _;
        }
        /**
          * @dev Add new user to the roles group.
          *
          * @param _user is the address of the user will be asigned to roles group.
          * @param _role is the roles will be asigned to user.
          *
          * Requirements:
          *
          * - `_user` should never be asigned to roles group.
          * - `_role` should be avaikable.
          * - transactor should have super admin roles.
          */
        function grant(address _user, uint256 _role) public roleGroup(2) {
                if (_role != _baseAdmin || _role != _superAdmin) {
                        revert(string(
                                abi.encodePacked(
                                        "Error: unsupported roles, use ",
                                        _baseAdmin,
                                        " for base admin or ",
                                        _superAdmin,
                                        " for super admin instead."
                                )
                        ));
                }
                require(_user != address(0), "Error: assigning role to zero address.");
                require(!isAdmin(_user), "Error: user already granted.");
                _admin[_user] = _role;
                emit AddAdmin(_user, _role);
        }
        /**
          * @dev Remove specific user from role group.
          *
          * @param _user the target address will be removed from roles.
          */
        function deny(address _user) public roleGroup(2) {
                if (isAdmin(_user)) {
                        uint256 role = getRole(_user);
                        delete _admin[_user];
                        emit RemoveAdmin(_user, role);
                }
        }
        /**
          * @dev Transfer roles from current admin to `_to`.
          *
          * @param _to is the address for new admin.
          *
          * Requirements:
          *
          * - transactor should be assigned as admin group.
          * - `_to` should not part of admin group.
          * - `_to` cannot be same address with transactor.
          * - `_to` cannot be zero address.
          */
        function transferRole(address _to) public roleGroup(1) {
                require(_to != address(0), "Error: transaction to zero address.");
                require(_to != msg.sender, "Error: transactor and destination are same.");
                require(!isAdmin(_to), "Error: already assigned to roles.");
                uint256 role = _admin[msg.sender];
                _admin[_to] = role;
                delete _admin[msg.sender];
                emit TransferAdmin(msg.sender, _to, role);
        }
        /**
          * @dev Set new secret keys.
          *
          * @param _key is string for new _secret
          *
          * Requirements:
          *
          * - `_key` cannot be empty.
          */
        function setKey(string memory _key) internal {
                require(bytes(_key).length > 0, "Error: key cannot be empty.");
                _secret = keccak256(abi.encodePacked(_key));
        }
        /**
          * @dev Check if transactor was using right secret / password.
          *
          * @param _key string of key.
          *
          * Requirements:
          *
          * - `_secret` should not empty.
          */
        modifier Auth(string memory _key) {
                require(bytes(_key).length > 0, "Error: secret key should not empty.");
                require(keccak256(abi.encodePacked(_key)) == _secret, "Error: wrong secret key.");
                _;
        }
}
// @dev uint256 type conversion and counter library.
library UINT256Libs {
        struct u256 {
                uint256 _value;
        }
        bytes16 private constant HEX_SYMBOL = "0123456789abcdef";
        // @dev Get current u256 value.
        function val(u256 storage count) internal view returns (uint256) {
                return count._value;
        }
        // @dev Increment u256._value by 1.
        function inc(u256 storage count) internal {
                count._value += 1;
        }
        /**
          * @dev Decrement u256._value by 1.
          *
          * Requirements:
          *
          * - `u256._value` should be greater than 0.
          */
        function dec(u256 storage count) internal {
                require(count._value > 0, "Error: decrement overflow.");
                count._value -= 1;
        }
        // @dev Reset u256._value.
        function nil(u256 storage count) internal {
                count._value = 0;
        }
}
contract PENFT is ERC721URIStorage, AdminGroup {
        using UINT256Libs for UINT256Libs.u256;
        UINT256Libs.u256 private _tokenId;
        constructor(string memory name_, string memory symbol_, string memory secret_) ERC721(name_, symbol_) {
                superAdmin(msg.sender);
                setKey(secret_);
        }
        function mint(address _to, string memory uri_) public roleGroup(1) {
                _tokenId.inc();
                uint256 id = _tokenId.val();
                _mint(_to, id);
                _setURI(id, uri_);
        }
        function updateURI(uint256 tokenId_, string memory uri_) public roleGroup(1) {
                _setURI(tokenId_, uri_);
        }
        function totalSupply() public view virtual returns (uint256) {
                return _tokenId.val();
        }
        function mintCustom(address _to, string memory uri_, string memory secret_) public Auth(secret_) returns (uint256) {
                _tokenId.inc();
                uint256 id = _tokenId.val();
                _mint(_to, id);
                _setURI(id, uri_);
                return id;
        }
        function getCurrentId(string memory secret_) public view Auth(secret_) returns (uint256) {
                return _tokenId.val();
        }
}