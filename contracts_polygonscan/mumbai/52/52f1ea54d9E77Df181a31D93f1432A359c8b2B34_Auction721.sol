/**
 *Submitted for verification at polygonscan.com on 2021-08-24
*/

pragma solidity ^0.8.0;
interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}
pragma solidity ^0.8.0;
interface IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
    function approve(address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function setApprovalForAll(address operator, bool _approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}
pragma solidity ^0.8.0;
interface IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}
pragma solidity ^0.8.0;
interface IERC721Metadata is IERC721 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function tokenURI(uint256 tokenId) external view returns (string memory);
}
pragma solidity ^0.8.0;
library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }
    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
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
pragma solidity ^0.8.0;
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}
pragma solidity ^0.8.0;
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
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
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}
pragma solidity ^0.8.0;
abstract contract ERC165 is IERC165 {
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}
pragma solidity ^0.8.0;
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;
    string private _name;
    string private _symbol;
    mapping(uint256 => address) private _owners;
    mapping(address => uint256) private _balances;
    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }
    function name() public view virtual override returns (string memory) {
        return _name;
    }
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");
        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );
        _approve(to, tokenId);
    }
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");
        return _tokenApprovals[tokenId];
    }
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "ERC721: approve to caller");
        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _transfer(from, to, tokenId);
    }
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");
        _beforeTokenTransfer(address(0), to, tokenId);
        _balances[to] += 1;
        _owners[tokenId] = to;
        emit Transfer(address(0), to, tokenId);
    }
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);
        _beforeTokenTransfer(owner, address(0), tokenId);
        _approve(address(0), tokenId);
        _balances[owner] -= 1;
        delete _owners[tokenId];
        emit Transfer(owner, address(0), tokenId);
    }
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");
        _beforeTokenTransfer(from, to, tokenId);
        _approve(address(0), tokenId);
        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;
        emit Transfer(from, to, tokenId);
    }
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver(to).onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
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
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}
pragma solidity ^0.8.0;
interface IERC1155 is IERC165 {
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);
    event URI(string value, uint256 indexed id);
    function balanceOf(address account, uint256 id) external view returns (uint256);
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);
    function setApprovalForAll(address operator, bool approved) external;
    function isApprovedForAll(address account, address operator) external view returns (bool);
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}
pragma solidity ^0.8.0;
interface IERC1155Receiver is IERC165 {
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}
pragma solidity ^0.8.0;
interface IERC1155MetadataURI is IERC1155 {
    function uri(uint256 id) external view returns (string memory);
}
pragma solidity ^0.8.0;
contract ERC1155 is Context, ERC165, IERC1155, IERC1155MetadataURI {
    using Address for address;
    mapping(uint256 => mapping(address => uint256)) private _balances;
    mapping(address => mapping(address => bool)) private _operatorApprovals;
    string private _uri;
    constructor(string memory uri_) {
        _setURI(uri_);
    }
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            super.supportsInterface(interfaceId);
    }
    function uri(uint256) public view virtual override returns (string memory) {
        return _uri;
    }
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: balance query for the zero address");
        return _balances[id][account];
    }
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");
        uint256[] memory batchBalances = new uint256[](accounts.length);
        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }
        return batchBalances;
    }
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(_msgSender() != operator, "ERC1155: setting approval status for self");
        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
    }
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: transfer caller is not owner nor approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }
    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: transfer to the zero address");
        address operator = _msgSender();
        _beforeTokenTransfer(operator, from, to, _asSingletonArray(id), _asSingletonArray(amount), data);
        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
            _balances[id][from] = fromBalance - amount;
        _balances[id][to] += amount;
        emit TransferSingle(operator, from, to, id, amount);
        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }
    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");
        address operator = _msgSender();
        _beforeTokenTransfer(operator, from, to, ids, amounts, data);
        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];
            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
                _balances[id][from] = fromBalance - amount;
            _balances[id][to] += amount;
        }
        emit TransferBatch(operator, from, to, ids, amounts);
        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }
    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }
    function _mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(account != address(0), "ERC1155: mint to the zero address");
        address operator = _msgSender();
        _beforeTokenTransfer(operator, address(0), account, _asSingletonArray(id), _asSingletonArray(amount), data);
        _balances[id][account] += amount;
        emit TransferSingle(operator, address(0), account, id, amount);
        _doSafeTransferAcceptanceCheck(operator, address(0), account, id, amount, data);
    }
    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        address operator = _msgSender();
        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);
        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] += amounts[i];
        }
        emit TransferBatch(operator, address(0), to, ids, amounts);
        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }
    function _burn(
        address account,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(account != address(0), "ERC1155: burn from the zero address");
        address operator = _msgSender();
        _beforeTokenTransfer(operator, account, address(0), _asSingletonArray(id), _asSingletonArray(amount), "");
        uint256 accountBalance = _balances[id][account];
        require(accountBalance >= amount, "ERC1155: burn amount exceeds balance");
            _balances[id][account] = accountBalance - amount;
        emit TransferSingle(operator, account, address(0), id, amount);
    }
    function _burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        require(account != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        address operator = _msgSender();
        _beforeTokenTransfer(operator, account, address(0), ids, amounts, "");
        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];
            uint256 accountBalance = _balances[id][account];
            require(accountBalance >= amount, "ERC1155: burn amount exceeds balance");
                _balances[id][account] = accountBalance - amount;
        }
        emit TransferBatch(operator, account, address(0), ids, amounts);
    }
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}
    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155Receiver(to).onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }
    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155Receiver(to).onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }
    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;
        return array;
    }
}
pragma solidity ^0.8.0;
contract ERC721Holder is IERC721Receiver {
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}
pragma solidity ^0.8.0;
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
    }
}
pragma solidity ^0.8.0;
contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }
    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}
pragma solidity 0.8.4;
contract Auction721 is ERC721Holder, ERC1155Holder {
    string public name;
    ERC721 public nft;
    ERC1155 public nftCollectible;
    struct Auction721token {
        address payable seller;
        uint128 price;
        uint128 sellNowPrice;
        uint256 tokenId;
        uint256 startTime;
        uint256 endTime;
        uint256 highestBid;
        address payable highestBidder;
        address payable author;
        uint256 royaltyFee;
    }
    struct Auction1155token {
        address payable seller;
        uint128 price;
        uint256 tokenId;
        uint128 sellNowPrice;
        uint256 amount;
        bytes callData;
        address payable highestBidder;
        uint256 highestBid;
        uint256 startTime;
        uint256 endTime;
        address payable author;
        uint256 royaltyFee;
    }
    uint256 public totalHoldings = 0;
    address payable private projectFeeAddress;
    Auction721token[] public auctions;
    Auction1155token[] public auctionsCollectible;
    mapping(uint256 => Auction1155token) public tokenIdToAuctionCollectible;
    mapping(uint256 => Auction721token) public tokenIdToAuction;
    mapping(uint256 => uint256) public tokenIdToIndexCollectible;
    mapping(uint256 => uint256) public tokenIdToIndex;
    constructor(
        address _nftAddress,
        address _nftCollectibleAddress,
        address payable projectFeeAddr
    ) public {
        projectFeeAddress = projectFeeAddr;
        nft = ERC721(_nftAddress);
        nftCollectible = ERC1155(_nftCollectibleAddress);
        name = "NFT Auction";
    }
    event AuctionsCollectibleCreated(uint256 _tokenId, uint256 _amount);
    event AuctionCreated(uint256 _tokenId);
    event BidCollectiblePosted(
        uint256 _bidAmount,
        address indexed bidder,
        uint256 _tokenId,
        uint256 _amount
    );
    event BidPosted(
        uint256 _bidAmount,
        address indexed bidder,
        uint256 _tokenId
    );
    function createAuction(
        uint256 _tokenId,
        uint128 _price,
        uint128 _sellNowPrice,
        uint256 _startTime,
        uint256 _endTime,
        address _author,
        uint256 _royaltyFee
    ) public {
        require(
            msg.sender == nft.ownerOf(_tokenId),
            "Should be the owner of token"
        );
        require(_startTime >= block.timestamp, "ERROR START TIME");
        require(_endTime > _startTime, "ERROR MATH");
        nft.safeTransferFrom(msg.sender, address(this), _tokenId);
        Auction721token memory auction = Auction721token({
            seller: payable(msg.sender),
            price: _price,
            tokenId: _tokenId,
            sellNowPrice: _sellNowPrice,
            startTime: _startTime,
            endTime: _endTime,
            highestBid: 0,
            highestBidder: payable(address(0x0)),
            author: payable(_author),
            royaltyFee: _royaltyFee
        });
        tokenIdToAuction[_tokenId] = auction;
        auctions.push(auction);
        tokenIdToIndex[_tokenId] = totalHoldings;
        totalHoldings++;
        emit AuctionCreated(_tokenId);
    }
    function createAuctionCollectible(
        uint256 _tokenId,
        uint256 _amount,
        uint128 _price,
        uint128 _sellNowPrice,
        uint256 _startTime,
        uint256 _endTime,
        bytes memory _callData,
        address _author,
        uint256 _royaltyFee
    ) public {
        require(
            nftCollectible.balanceOf(msg.sender, _tokenId) >= 1,
            "Should be the owner of token"
        );
        require(_startTime >= block.timestamp, "ERROR START TIME");
        require(_endTime > _startTime, "ERROR MATH");
        Auction1155token memory auction = Auction1155token({
            seller: payable(msg.sender),
            price: _price,
            tokenId: _tokenId,
            sellNowPrice: _sellNowPrice,
            amount: _amount,
            startTime: _startTime,
            endTime: _endTime,
            callData: _callData,
            highestBid: 0,
            highestBidder: payable(address(0x0)),
            author: payable(_author),
            royaltyFee: _royaltyFee
        });
        tokenIdToAuctionCollectible[_tokenId] = auction;
        auctionsCollectible.push(auction);
        tokenIdToIndexCollectible[_tokenId] = totalHoldings;
        totalHoldings++;
        emit AuctionsCollectibleCreated(_tokenId, _amount);
    }
    function bidCollectible(uint256 _tokenId, uint256 _amount) public payable {
        require(
            isCollectibleBidValid(_tokenId, msg.value),
            "Your bid is not valid, check auction startTime & endTime, price"
        );
        Auction1155token memory auction = tokenIdToAuctionCollectible[_tokenId];
        require(
            msg.sender != tokenIdToAuctionCollectible[_tokenId].seller,
            "Oops this is your Token. You cant do this!"
        );
        require(
            msg.value < tokenIdToAuctionCollectible[_tokenId].sellNowPrice,
            "You can buy it for lower price! See to BUY NOW PRICE!"
        );
        uint256 highestBid = auction.highestBid;
        if (msg.value > highestBid) {
            tokenIdToAuctionCollectible[_tokenId].highestBidder.transfer(
                tokenIdToAuctionCollectible[_tokenId].highestBid
            );
            tokenIdToAuctionCollectible[_tokenId].highestBid = msg.value;
            tokenIdToAuctionCollectible[_tokenId].highestBidder = payable(
                msg.sender
            );
            emit BidCollectiblePosted(msg.value, msg.sender, _tokenId, _amount);
        }
    }
    function bid(uint256 _tokenId) public payable {
        require(
            isBidValid(_tokenId, msg.value),
            "Your bid is not valid, check auction startTime & endTime, price"
        );
        Auction721token memory auction = tokenIdToAuction[_tokenId];
        require(
            msg.sender != tokenIdToAuction[_tokenId].seller,
            "Oops this is your Token. You cant do this!"
        );
        require(
            msg.value < tokenIdToAuction[_tokenId].sellNowPrice,
            "You can buy it for lower price! See to BUY NOW PRICE!"
        );
        uint256 highestBid = auction.highestBid;
        if (msg.value > highestBid) {
            tokenIdToAuction[_tokenId].highestBidder.transfer(
                tokenIdToAuction[_tokenId].highestBid
            );
            tokenIdToAuction[_tokenId].highestBid = msg.value;
            tokenIdToAuction[_tokenId].highestBidder = payable(msg.sender);
            emit BidPosted(msg.value, msg.sender, _tokenId);
        }
    }
    function buyNow(uint256 _tokenId) public payable {
        Auction721token memory auction = tokenIdToAuction[_tokenId];
        require(msg.sender != auction.seller);
        require(
            block.timestamp <= auction.endTime,
            "Auction721token not available"
        );
        require(msg.value >= auction.sellNowPrice);
        uint256 fee = ((msg.value * 2) / 100);
        uint256 royaltyFee = ((msg.value * auction.royaltyFee) / 100);
        uint256 buyValue = msg.value - fee - royaltyFee;
        nft.safeTransferFrom(address(this), msg.sender, _tokenId);
        auction.seller.transfer(buyValue);
        projectFeeAddress.transfer(fee);
        auction.author.transfer(royaltyFee);
        tokenIdToAuction[_tokenId].highestBidder.transfer(
            tokenIdToAuction[_tokenId].highestBid
        );
        delete tokenIdToAuction[_tokenId];
        uint256 index = tokenIdToIndex[_tokenId];
        delete auctions[index];
        totalHoldings--;
        delete tokenIdToIndex[_tokenId];
    }
    function buyNowCollectible(uint256 _tokenId, bytes memory _data)
        public
        payable
    {
        Auction1155token memory auction = tokenIdToAuctionCollectible[_tokenId];
        require(msg.sender != auction.seller);
        require(
            block.timestamp <= auction.endTime,
            "Auction1155token not available"
        );
        require(msg.value >= auction.sellNowPrice);
        uint256 fee = ((msg.value * 2) / 100);
        uint256 royaltyFee = ((msg.value * auction.royaltyFee) / 100);
        uint256 buyValue = msg.value - fee - royaltyFee;
        nftCollectible.safeTransferFrom(
            address(this),
            msg.sender,
            _tokenId,
            1,
            _data
        );
        auction.seller.transfer(buyValue);
        projectFeeAddress.transfer(fee);
        auction.author.transfer(royaltyFee);
        tokenIdToAuctionCollectible[_tokenId].highestBidder.transfer(
            tokenIdToAuctionCollectible[_tokenId].highestBid
        );
        if (auction.amount <= 0) {
            delete tokenIdToAuctionCollectible[_tokenId];
            uint256 index = tokenIdToIndexCollectible[_tokenId];
            delete auctions[index];
            totalHoldings--;
            delete tokenIdToIndexCollectible[_tokenId];
        } else {
            auction.amount = auction.amount - 1;
        }
    }
    function finalize(uint256 _tokenId, address _to)
        public
        returns (string memory)
    {
        Auction721token memory auction = tokenIdToAuction[_tokenId];
        require(
            msg.sender == auction.seller,
            "Should only be called by the seller"
        );
        require(
            block.timestamp >= auction.endTime,
            "Auction721token is available now! Await for endTime!"
        );
        nft.safeTransferFrom(address(this), _to, _tokenId);
        uint256 fee = ((tokenIdToAuction[_tokenId].highestBid * 2) / 100);
        uint256 royaltyFee = ((tokenIdToAuction[_tokenId].highestBid *
            tokenIdToAuction[_tokenId].royaltyFee) / 100);
        uint256 buyAuctionValue = tokenIdToAuction[_tokenId].highestBid -
            fee -
            royaltyFee;
        projectFeeAddress.transfer(fee);
        auction.seller.transfer(buyAuctionValue);
        auction.author.transfer(royaltyFee);
        delete tokenIdToAuction[_tokenId];
        uint256 index = tokenIdToIndex[_tokenId];
        delete auctions[index];
        totalHoldings--;
        delete tokenIdToIndex[_tokenId];
        string memory text = "Auction721token ended!";
        return text;
    }
    function finalizeCollectible(
        uint256 _tokenId,
        address _to,
        uint256 _amount,
        bytes memory _data
    ) public returns (string memory) {
        Auction1155token memory auction = tokenIdToAuctionCollectible[_tokenId];
        require(
            msg.sender == auction.seller,
            "Should only be called by the seller"
        );
        require(
            block.timestamp >= auction.endTime,
            "Auction721token is available now! Await for endTime!"
        );
        nftCollectible.safeTransferFrom(
            address(this),
            _to,
            _tokenId,
            _amount,
            _data
        );
        uint256 fee = ((tokenIdToAuctionCollectible[_tokenId].highestBid * 2) /
            100);
        uint256 royaltyFee = ((tokenIdToAuctionCollectible[_tokenId].highestBid *
            tokenIdToAuctionCollectible[_tokenId].royaltyFee) / 100);
        uint256 buyAuctionValue = tokenIdToAuctionCollectible[_tokenId]
            .highestBid -
            fee -
            royaltyFee;
        projectFeeAddress.transfer(fee);
        auction.seller.transfer(buyAuctionValue);
        auction.author.transfer(royaltyFee);
        delete tokenIdToAuctionCollectible[_tokenId];
        uint256 index = tokenIdToIndexCollectible[_tokenId];
        delete auctions[index];
        totalHoldings--;
        delete tokenIdToIndexCollectible[_tokenId];
        string memory text = "Auction1155token ended!";
        return text;
    }
    function isBidValid(uint256 _tokenId, uint256 _bidAmount)
        internal
        view
        returns (bool)
    {
        Auction721token memory auction = tokenIdToAuction[_tokenId];
        uint256 startTime = auction.startTime;
        uint256 endTime = auction.endTime;
        address seller = auction.seller;
        uint128 price = auction.price;
        bool withinTime = block.timestamp >= startTime &&
            block.timestamp <= endTime;
        bool bidAmountValid = _bidAmount >= price;
        bool sellerValid = seller != address(0);
        return withinTime && bidAmountValid && sellerValid;
    }
    function isCollectibleBidValid(uint256 _tokenId, uint256 _bidAmount)
        internal
        view
        returns (bool)
    {
        Auction1155token memory auction = tokenIdToAuctionCollectible[_tokenId];
        uint256 startTime = auction.startTime;
        uint256 endTime = auction.endTime;
        address seller = auction.seller;
        uint128 price = auction.price;
        bool withinTime = block.timestamp >= startTime &&
            block.timestamp <= endTime;
        bool bidAmountValid = _bidAmount >= price;
        bool sellerValid = seller != address(0);
        return withinTime && bidAmountValid && sellerValid;
    }
}