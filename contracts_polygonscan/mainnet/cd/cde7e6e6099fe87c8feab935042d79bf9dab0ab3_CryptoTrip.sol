/**
 *Submitted for verification at polygonscan.com on 2021-09-29
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}
abstract contract ERC165 is IERC165 {
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

interface IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom(address from,address to,uint256 tokenId) external;
    function transferFrom(address from,address to,uint256 tokenId) external;
    function approve(address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function setApprovalForAll(address operator, bool _approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function safeTransferFrom(address from,address to,uint256 tokenId,bytes calldata data) external;
}


interface IERC721Receiver {
    function onERC721Received(address operator,address from,uint256 tokenId,bytes calldata data ) external returns (bytes4);
}

interface IERC721Metadata is IERC721 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

interface IERC721Enumerable is IERC721 {
    function totalSupply() external view returns (uint256);
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);
    function tokenByIndex(uint256 index) external view returns (uint256);
}

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

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _setOwner(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}
abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        _status = _ENTERED;

        _;

        _status = _NOT_ENTERED;
    }
}


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

    function functionCallWithValue( address target,bytes memory data,uint256 value ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue( address target,bytes memory data,uint256 value,string memory errorMessage ) internal returns (bytes memory) {
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

library Base64 {
    bytes internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((len + 2) / 3);

        // Add some extra buffer at the end
        bytes memory result = new bytes(encodedLen + 32);

        bytes memory table = TABLE;

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)

            for {
                let i := 0
            } lt(i, len) {

            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)

                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(input, 0x3F))), 0xFF))
                out := shl(224, out)

                mstore(resultPtr, out)

                resultPtr := add(resultPtr, 4)
            }

            switch mod(len, 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }

            mstore(result, encodedLen)
        }

        return string(result);
    }
}
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


abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    mapping(uint256 => uint256) private _ownedTokensIndex;

    uint256[] private _allTokens;

    mapping(uint256 => uint256) private _allTokensIndex;


    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }


    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }


    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }


    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _reIntelligenceTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _reIntelligenceTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }


    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }


    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }


    function _reIntelligenceTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Intelligence the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the Intelligenced token's index
        }

        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }
    function _reIntelligenceTokenFromAllTokensEnumeration(uint256 tokenId) private {
        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Intelligence the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the Intelligenced token's index

        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}



contract CryptoTrip is ERC721Enumerable, ReentrancyGuard, Ownable {

    mapping(string => string[][]) public cityCards; // cityName to cityImages

    mapping(uint256 => string[]) private tokenURIs; // tokenId to tokenURI

    mapping(string => uint256) public cityMinted; // cityName to minted

    mapping(uint256 => string) public tokenCity; // cityName to minted

    string[] public allCities = [
        "Argentina",
        "Brazil",
        "Canada",
        "Chile",
        "China",
        "Dubai",
        "Finland",
        "France",
        "Germany",
        "Greece",
        "Holland",
        "Iceland",
        "India",
        "Italy",
        "Japan",
        "Mexican",
        "Philippines",
        "Russian",
        "Singapore",
        "Sonora",
        "South_Korea",
        "Sri_Lanka",
        "Swiss",
        "Thailand",
        "Ukraine",
        "United_Kingdom",
        "United_States"
    ]; // all imported cities

    string public baseURI = "https://gateway.pinata.cloud/ipfs/"; // IPFS baseURI

    uint256 private tokenId; // Auto increment tokenId

    uint256 public mintFee = 0.01 ether; // mint fee to owner

    uint256 tokenLimit = 2021;

    constructor() ERC721("CryptoTrip", "TRIP") Ownable() {
        cityCards["America"]=[["QmZbEtbqPYUiB6QRPKx5rQnC2Zpn4rf7Bae7ATaeRb5NG9","QmNbKFVj2NfQAmZMEani7Zk3zACLpPzqnYcUzQW1RXbv36"], ["QmeBe6SFgZ1e7gpG17geoiQuST3kczYzP8q23xpxPEJCga","QmY364eceJidTjQfJGMvV85Vs9B6NtDuCoGtTmfoPTGykJ"]];
        cityCards["Argentina"]=[["QmRe85EmLT58Es8s21PSiznWNjvV9AniuEtBid5BivJQzZ","QmRe85EmLT58Es8s21PSiznWNjvV9AniuEtBid5BivJQzZ"]];
        cityCards["Brazil"]=[["QmYwVNd75Cd1aEnvJXH5r95QT9meUwzyNG9Y9zHhTBL1M4","QmYwVNd75Cd1aEnvJXH5r95QT9meUwzyNG9Y9zHhTBL1M4"]];
        cityCards["Canada"]=[["QmXQa5db6W74qBktYGYeAHvvBF7C5QYubespjTZEfYDDvx","QmXQa5db6W74qBktYGYeAHvvBF7C5QYubespjTZEfYDDvx"]];
        cityCards["Chile"]=[["QmaTuzPFw8aiRSw5Kb3AgWFRKsS1fSMonZsc4FsPijSJmh","QmaTuzPFw8aiRSw5Kb3AgWFRKsS1fSMonZsc4FsPijSJmh"]];
        cityCards["China"]=[["QmQEF6e1U1rn1uMb7b1tTXqfLkdKrKB4FsucsWod7sfMQQ","QmQEF6e1U1rn1uMb7b1tTXqfLkdKrKB4FsucsWod7sfMQQ"],["QmP4DmAiJRwMPitoU5pSFQRCawzpXU6bs6pTvXbaSYiGkc","QmP4DmAiJRwMPitoU5pSFQRCawzpXU6bs6pTvXbaSYiGkc"],["QmdxpgDaS8awCBPYFZKqGNHQQiPevRoVPnLLX3XJDBB3hx","QmdxpgDaS8awCBPYFZKqGNHQQiPevRoVPnLLX3XJDBB3hx"],["QmQuPtL8FbpNk7LKrFJSPsSAB7MWDekLDG56v7RSySWvo9","QmQuPtL8FbpNk7LKrFJSPsSAB7MWDekLDG56v7RSySWvo9"],["QmPReMvrUjSHiLHQmt5bL4wpWMZ7rwbi9xZzUbyzzyY5tR","QmPReMvrUjSHiLHQmt5bL4wpWMZ7rwbi9xZzUbyzzyY5tR"]];
        cityCards["Dubai"]=[["QmWdxMrkKd8g6UCXTKA3gdjW9L7fca8GUCwaXjBADgDDPu","QmWdxMrkKd8g6UCXTKA3gdjW9L7fca8GUCwaXjBADgDDPu"]];
        cityCards["Finland"]=[["Qmbh6VDQ8VSuqxLxvBaUqvYWXmh8qt61bZQbuob2qEPzAE","Qmbh6VDQ8VSuqxLxvBaUqvYWXmh8qt61bZQbuob2qEPzAE"]];
        cityCards["France"]=[["QmfKSCczuv8xpkDagqpu2jsNSKgSqQJZrgbtEiSkwa8iEv","QmfKSCczuv8xpkDagqpu2jsNSKgSqQJZrgbtEiSkwa8iEv"],["QmTmoiWKuRQe6wfkvXktCcvuvBR3k3ive4x7XyY59smsjP","QmTmoiWKuRQe6wfkvXktCcvuvBR3k3ive4x7XyY59smsjP"],["QmbkPDu5sqwM5neFivF57rMuvzbE1qQWoHUvtirTdVUoCK","QmbkPDu5sqwM5neFivF57rMuvzbE1qQWoHUvtirTdVUoCK"]];
        cityCards["Germany"]=[["QmZrgRtXXje6zPr7YQkb2V4T5vhAfLHy8M9st82PLrzS5i","QmZrgRtXXje6zPr7YQkb2V4T5vhAfLHy8M9st82PLrzS5i"]];
        cityCards["Greece"]=[["QmNVdemSzBqxmzifLJszPqCyHVpk2onrxYwFbs87WjAS3R","QmNVdemSzBqxmzifLJszPqCyHVpk2onrxYwFbs87WjAS3R"],["QmV3P6sygASkBpVdP2nmkCq23uTfkgCiuEm7mKfPUYxcXC","QmV3P6sygASkBpVdP2nmkCq23uTfkgCiuEm7mKfPUYxcXC"]];
        cityCards["Holland"]=[["QmNsTUbFqREQTWsSrVoAwdPAHEPgQLBdPHjuK3gUHVS2jj","QmNsTUbFqREQTWsSrVoAwdPAHEPgQLBdPHjuK3gUHVS2jj"]];
        cityCards["Iceland"]=[["QmWNsPQBwKmQZZ9aXZsUa1bAMuujSSbZk71mgMGLY7CYwL","QmWNsPQBwKmQZZ9aXZsUa1bAMuujSSbZk71mgMGLY7CYwL"]];
        cityCards["India"]=[["QmXaJFqMWg5NmdVkQypxNak2smgftnXoLkLQLup9dorDa2","QmXaJFqMWg5NmdVkQypxNak2smgftnXoLkLQLup9dorDa2"]];
        cityCards["Italy"]=[["QmSU86avWo1DpPXyWXWB3Yu3ACAmmzrSLJqyJwWNTjj2ps","QmSU86avWo1DpPXyWXWB3Yu3ACAmmzrSLJqyJwWNTjj2ps"]];
        cityCards["Japan"]=[["QmbKE5v3crzKZ522Tp5nfPak4i5JPu8aBZtZZzcJG8ZhmZ","QmbKE5v3crzKZ522Tp5nfPak4i5JPu8aBZtZZzcJG8ZhmZ"],["Qma4oEZv7XYWn6JUHGCtpLqJdkaGMm2ba8KehTxr86LLcZ","Qma4oEZv7XYWn6JUHGCtpLqJdkaGMm2ba8KehTxr86LLcZ"],["QmXj2szaH1223ko1LKd4dcJmboD2iZPHiiw6Z1bkeUjTmu","QmXj2szaH1223ko1LKd4dcJmboD2iZPHiiw6Z1bkeUjTmu"]];
        cityCards["Mexican"]=[["QmZCF92RWie5Xkyt63QwzArUEY2vRFSAaJicjMjG9CAFxv","QmZCF92RWie5Xkyt63QwzArUEY2vRFSAaJicjMjG9CAFxv"]];
        cityCards["Philippines"]=[["QmUXfZCi7feyRNZqYo4u1pKWmYksDNdCJGaMw3qYnzQjvQ","QmUXfZCi7feyRNZqYo4u1pKWmYksDNdCJGaMw3qYnzQjvQ"]];
        cityCards["Russian"]=[["QmZN9pTU5qDsBA3bpRNM6MFppf1h6LCK5G87cghup3iZSg","QmZN9pTU5qDsBA3bpRNM6MFppf1h6LCK5G87cghup3iZSg"],["QmU4MB8vDMBoUGVSTYtXWyeFRdaGMGeZq8E1rZA37U2Cy4","QmU4MB8vDMBoUGVSTYtXWyeFRdaGMGeZq8E1rZA37U2Cy4"]];
        cityCards["Singapore"]=[["QmPTKo1AfL2FHcJDFKhCGph7y8cqMQXveEF2As1kG6snGM","QmPTKo1AfL2FHcJDFKhCGph7y8cqMQXveEF2As1kG6snGM"]];
        cityCards["Sonora"]=[["QmXsLWKEtuSwP3rzKFwPnpEZgN9cMHBdeg4d7zGv5dyS92","QmXsLWKEtuSwP3rzKFwPnpEZgN9cMHBdeg4d7zGv5dyS92"]];
        cityCards["South_Korea"]=[["QmZ2L6A57HJqtnpNGXtTn56513HUgktnfV88DXF8wnY5qA","QmZ2L6A57HJqtnpNGXtTn56513HUgktnfV88DXF8wnY5qA"]];
        cityCards["Sri_Lanka"]=[["QmSNXHFy9uBSLnRdGiRu9QUam9AAqEAmMMqioKvz4ceFkJ","QmSNXHFy9uBSLnRdGiRu9QUam9AAqEAmMMqioKvz4ceFkJ"]];
        cityCards["Swiss"]=[["QmXqLPXTumzAb3aExK5PaZVBCbzgC3oFd8xk2x8CYuwfk4","QmXqLPXTumzAb3aExK5PaZVBCbzgC3oFd8xk2x8CYuwfk4"]];
        cityCards["Thailand"]=[["QmcxjVXjPYhBfvREWWsv7rsmGmvkebWungnXst4i9ckXhS","QmcxjVXjPYhBfvREWWsv7rsmGmvkebWungnXst4i9ckXhS"],["QmPWkZGkSgYanqp6GFGWhBw6vGnzENvoyuMxGCXoJWTXGx","QmPWkZGkSgYanqp6GFGWhBw6vGnzENvoyuMxGCXoJWTXGx"]];
        cityCards["Ukraine"]=[["QmVR9H9WaNFdENspGKGU2GY2TMBPv3nv3qmUoNqmyUKhDa","QmVR9H9WaNFdENspGKGU2GY2TMBPv3nv3qmUoNqmyUKhDa"]];
        cityCards["United_Kingdom"]=[["QmTAGiNod8tZ7ABbp2v6F5JZtfiCzpKWjr8Ks9QupNYxt9","QmTAGiNod8tZ7ABbp2v6F5JZtfiCzpKWjr8Ks9QupNYxt9"],["QmSj2uCb3Aixnp1ykQ5UGCgC6CmKSQfQb5zR7mdfjyusWy","QmSj2uCb3Aixnp1ykQ5UGCgC6CmKSQfQb5zR7mdfjyusWy"],["QmU6ixeDpLpsrzpgpHexf6ptTqFoiRVamouHQ4o1XsE2Hc","QmU6ixeDpLpsrzpgpHexf6ptTqFoiRVamouHQ4o1XsE2Hc"],["QmPTy6cosLDtFGrUVPhLUbQL8x5k94bkCX8nFJXeg1aLZB","QmPTy6cosLDtFGrUVPhLUbQL8x5k94bkCX8nFJXeg1aLZB"]];
        cityCards["United_States"]=[["QmUEvy5Ei36QPchcEnMRWAfaATKki8MJkmuiezPaXNXeSW","QmUEvy5Ei36QPchcEnMRWAfaATKki8MJkmuiezPaXNXeSW"],["QmQxfFmzdWMqX8fYKPLq2xTSFwp6XAp2HHSgefpr19MBTt","QmQxfFmzdWMqX8fYKPLq2xTSFwp6XAp2HHSgefpr19MBTt"],["QmcwX9aPXbfa2MTiocDNNFWVFrmW9Qt8411DeyeVx2s82q","QmcwX9aPXbfa2MTiocDNNFWVFrmW9Qt8411DeyeVx2s82q"],["Qmaa6iXmx2Aubp3qdB6gCeyvmtsV6WBFg9dccmjme1sRSo","Qmaa6iXmx2Aubp3qdB6gCeyvmtsV6WBFg9dccmjme1sRSo"],["QmU4E4GtmS7hJoPo5Fpy7cPy1PCSNmTXG2ejLU1YuCoEbT","QmU4E4GtmS7hJoPo5Fpy7cPy1PCSNmTXG2ejLU1YuCoEbT"],["QmXePz7aTueCHVNPSijs1ThHYiFwSddNeguTGDasg9fT9s","QmXePz7aTueCHVNPSijs1ThHYiFwSddNeguTGDasg9fT9s"]];
    }

    function newCity(string memory cityName,string[] memory imageBlob) public onlyOwner returns(bool){
        require(bytes(cityName).length > 0,'City Name is invalid');
        require(imageBlob.length == 2,'Image Blob is empty');
        string[][] storage cityImages = cityCards[cityName];
        if (cityImages.length == 0) {
            allCities.push(cityName);
        }
        cityImages.push(imageBlob);

        return false;
    }

    function addMultiCity(string[] memory cityNames, string[][] memory images) external nonReentrant onlyOwner {
        uint256 cityCount = cityNames.length;
        uint256 imageCount = images.length;
        require(cityCount == imageCount, 'Wrong count');
        for (uint256 i; i < cityCount; i++) {
            string memory cityName = cityNames[i];
            string[] memory image = images[i];
            newCity(cityName, image);
        }
    }

    function getCityJson() external view returns(string memory) {
        string memory cityJson = '{';
        for (uint256 i; i < allCities.length; i++) {
            cityJson = string(abi.encodePacked(cityJson, '"', allCities[i], '":', toString(cityMinted[allCities[i]])));
            if (i != allCities.length - 1) {
                cityJson = string(abi.encodePacked(cityJson, ","));
            }
        }
        cityJson = string(abi.encodePacked(cityJson, "}"));

        return cityJson;
    }

    function setBaseURI(string memory _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }

    function withdrawFee() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function claim(string memory cityName) public payable nonReentrant {
        // charge fee
        require(msg.value >= mintFee, 'Not enough fee');
        // check token limit
        require(tokenId <= tokenLimit, 'No token left');
        // check city images
        string[][] memory cityImages = cityCards[cityName];
        require(cityImages.length > 0, 'Not supported city');
        // cityMinted count
        cityMinted[cityName]++;
        // get random image for city
        tokenId++;
        uint256 randInt = uint256(keccak256(abi.encodePacked(cityName, msg.sender, blockhash(block.number), tokenId)));
        string[] memory _tokenURI = cityImages[randInt % cityImages.length];
        // mint token and set tokenURI
        tokenURIs[tokenId] = _tokenURI;
        tokenCity[tokenId] = cityName;
        _safeMint(_msgSender(), tokenId);
    }

    function tokenURI(uint256 _tokenId) override public view returns (string memory) {
        string[] memory _tokenURI = tokenURIs[_tokenId];
        require(_tokenURI.length > 0, 'Not minted');

        //TODO: get city name of #tokenId
        string memory city = tokenCity[_tokenId];

        string memory json = string(abi.encodePacked(
                '{"token_id" : ' , toString(tokenId) ,
                ', "name": "', city ,' #', toString(tokenId), '"' ,
                ', "description": "We, born to freedom.To smash the blockade of COVID-19,Cryptotrip is generated.It is stored on chain,for the ones who born to freedom."',
                ', "image": "', baseURI , _tokenURI[0] , '"'
            ));
        json = string(abi.encodePacked(json,
            ', "external_url": "', baseURI , _tokenURI[1] , '"',
            ', "youtube_url": "', baseURI , _tokenURI[1] , '"',
            ', "attributes" : [{"trait_type" : "City","value" : "' , city , '"}]}'
            ));

        string memory base64 = Base64.encode(bytes(json));

        return string(abi.encodePacked('data:application/json;base64,', base64));
    }

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
}