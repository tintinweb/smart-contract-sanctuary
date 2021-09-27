/**
 *Submitted for verification at polygonscan.com on 2021-09-27
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

    mapping(string => string[]) public cityCards; // cityName to cityImages

    mapping(uint256 => string) private tokenURIs; // tokenId to tokenURI

    mapping(string => uint256) public cityMinted; // cityName to minted

    mapping(uint256 => string) public tokenCity; // cityName to minted

    string[] public allCities = [
        "America",
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
        "South Korea",
        "Sri Lanka",
        "Swiss",
        "Thailand",
        "Ukraine",
        "United Kingdom",
        "Vietnam"
    ]; // all imported cities

    string public baseURI; // IPFS baseURI

    uint256 private tokenId; // Auto increment tokenId

    uint256 public mintFee = 0.01 ether; // mint fee to owner

    uint256 tokenLimit = 2021;

    constructor() ERC721("CryptoTrip", "TRIP") Ownable() {
        cityCards["America"]=["QmZbEtbqPYUiB6QRPKx5rQnC2Zpn4rf7Bae7ATaeRb5NG9","QmNbKFVj2NfQAmZMEani7Zk3zACLpPzqnYcUzQW1RXbv36","QmeBe6SFgZ1e7gpG17geoiQuST3kczYzP8q23xpxPEJCga","QmY364eceJidTjQfJGMvV85Vs9B6NtDuCoGtTmfoPTGykJ","QmexoULwBkf4A4RDjKQeVPGSZZAgmYDtKPYr3BAPu82ga4"];
        cityCards["Argentina"]=["QmVxz826U2cixkbkjFxuTd7KFa8m4YpLNngwvrFQrybV2k"];
        cityCards["Brazil"]=["QmdKGVXmmYKL4GC2JJhVBRe81GLowQF62aBatsD1Z4NHwc"];
        cityCards["Canada"]=["QmNRp3oGS9feNjPkZdKThQH5WHjPopbn4U55XrZGN9R47M"];
        cityCards["Chile"]=["QmUTVSHhDQgFd5rX2rhUPR7chjZECx9Xyjvo7AKgf9WDT3"];
        cityCards["China"]=["Qmd3xtkrCnDzHDHF7NBctQwSvokF8qQpAy3keo98soWrkg","QmRLBGpKPE5etDnNdqRksRyEf7H1yUc624M7iy7JmGXE7f","Qmcuhyr8gpRhcZmwXWwGvikEh21t3kU72Nk3Y6gBgLEuFU","QmSAymX89DmUDgG7psp7WtK5Ss5KqrzmikgjoTgpaj9Fbm","QmWahAjpLadn6F4xtV7maJg5mEFowRLPJve6N77pXNSLkE"];
        cityCards["Dubai"]=["QmTvEe2MMKTeg5eL8pJYBg4jJDNQB3zyJgMgcgs7kUyznw"];
        cityCards["Finland"]=["QmQJiPDvaWUvf32D264HzBkzXrmA6faDFh6hYmfDHb4feq"];
        cityCards["France"]=["QmaauXi6o28bbX13Ms2jofF74z5TBUYihKnu357j1iipcS","QmSScZn5jcRHVpuENxHXLcyRp86dj6V7BZ5ch8EV4JhnWM","QmeLjesWrVq4cXjvRSDCcur4WNSTRKAUS16s3V6HTsdFZd"];
        cityCards["Germany"]=["QmeUShaksNQXtVDZt5Y21X4vBEaUoJdNzCrFSN8c2AEVjQ"];
        cityCards["Greece"]=["QmRRVusc7VMo8X5dyms1XDcpA2z7uTuRniy6iF3dqDuhZh","QmbMoHTrxepf9uZyArKwcp5nWJM9XcSQ5Hkg72YL95CZCM"];
        cityCards["Holland"]=["QmXHbYVajst84hirEKM5MdTVN5CP84tDV3AA2sYTyurGSE"];
        cityCards["Iceland"]=["QmcxzoCUudBZexuuLBC61jiWHWGuaQtn1F6QDVL8aDrgkD"];
        cityCards["India"]=["QmNp68hwGkh9rxMDoTkbL235Xj8SPP53gnbJ7MbifGNcR8"];
        cityCards["Italy"]=["QmbWiPo4n76h2UUvxgagrbyUPyVsfpsmjTJBV25QxW9yKG"];
        cityCards["Japan"]=["QmbS9fKpGt49phKfqgVifXMhhd2Qm4VDFVSWC2KFwXrB69","QmZJXWXpWmnNCzzUJV55ZLK8YWNYQYtqUbyKYX5RqmZhkE","QmZCfUwfeszieHk2CXaxH7JauchuczeiTen78rRubeBCYK"];
        cityCards["Mexican"]=["QmZhk5qtj1KFigrpd4jG2cr827Jt8g6AnzkZ7c7mwieL3G"];
        cityCards["Philippines"]=["QmQ3oT3VzHAQTFYYSF46McY2PzF86ErnELXY8qhByDVVFz"];
        cityCards["Russian"]=["QmSEuAiMtKmZ5n9eKARkmejz5bud6LvnZXBKzcfJ3hMHyM","Qmc6DCarFoPExb7rSnQfBTFNKVjjSVBXbYEYmTRateuRfy"];
        cityCards["Singapore"]=["QmYnpnVy7qoezSYq98mFnXxG886tWg8ypvzRRCu2Auqcc9"];
        cityCards["Sonora"]=["QmcQa7oBofPVD86RtbJJSSY6k4mmYCA2cwjm7qm5AiVkEv"];
        cityCards["South Korea"]=["QmVN5NgqaakMqNDHWZUJCmnU68G3tdP6HGscWhcDayWvC9"];
        cityCards["Sri Lanka"]=["QmRoTwvtwnhPacUuhWFuUzBwxj1kunSzCTPCcAxcRZomh8"];
        cityCards["Swiss"]=["QmcSopdLBX7NbS6Z3C7TpeBwoM8z8WomMhiHcWuWd3Ctbr"];
        cityCards["Thailand"]=["QmNcMN6xRgUqVsaFUSnHFbhyDs57o2WFXsXxZnQRDqdRLJ","QmeLGrVVX1WcHubVTdzJFufUDgRXmp5zee91LJs8NK66iX"];
        cityCards["Ukraine"]=["QmfXn2uVLSvSSy47cFFjzWL5sxCc7sbtmbtSpQ8tVPCtwS"];
        cityCards["United Kingdom"]=["QmdWjWSkhuqGy2pFXBihhXuvpJ1RB9M67dhBUzW466SdBV","QmR6DT78NZHz1PYwJUyE3mfTwGKpdG4zTg26EZ2LGV1MdT","QmPsWqQqEasgwQ9wcD3J6BaoHsv2XA9xdZj6F4oWLB8cRs","QmewhJXHg3BnQotpdXYH8hayVPiE93JE9g3oUTCBZdb15b"];
        cityCards["Vietnam"]=["QmbWM4op7PWMDrZS8ocxRuVy4EzTsdyw5f4WbmpU5Y9oci"];
    }

    function newCity(string memory cityName,string memory imageBlob) public onlyOwner returns(bool){
        require(bytes(cityName).length > 0,'City Name is invalid');
        require(bytes(imageBlob).length > 0,'Image Blob is empty');
        string[] storage cityImages = cityCards[cityName];
        if (cityImages.length == 0) {
            allCities.push(cityName);
        }
        cityImages.push(imageBlob);

        return false;
    }

    function addMultiCity(string[] memory cityNames, string[] memory images) external nonReentrant onlyOwner {
        uint256 cityCount = cityNames.length;
        uint256 imageCount = images.length;
        require(cityCount == imageCount, 'Wrong count');
        for (uint256 i; i < cityCount; i++) {
            string memory cityName = cityNames[i];
            string memory image = images[i];
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

    /**
     * user mint
     */
    function claim(string memory cityName) public payable nonReentrant {
        // charge fee
        require(msg.value >= mintFee, 'Not enough fee');
        // check token limit
        require(tokenId <= tokenLimit, 'No token left');
        // check city images
        string[] memory cityImages = cityCards[cityName];
        require(cityImages.length > 0, 'Not supported city');
        // cityMinted count
        cityMinted[cityName]++;
        // get random image for city
        tokenId++;
        uint256 randInt = uint256(keccak256(abi.encodePacked(cityName, tokenId)));
        string memory _tokenURI = cityImages[randInt % cityImages.length];
        // mint token and set tokenURI
        tokenURIs[tokenId] = _tokenURI;
        tokenCity[tokenId] = cityName;
        _safeMint(_msgSender(), tokenId);
    }

    function tokenURI(uint256 tokenId) override public view returns (string memory) {
        string memory _tokenURI = tokenURIs[tokenId];
        require(bytes(_tokenURI).length > 0, 'Not minted');

        //TODO: get city name of #tokenId
        string memory city = tokenCity[tokenId];

        string memory json = Base64.encode(bytes(string(abi.encodePacked(
                '{"token_id" : ' , toString(tokenId) ,
                ', "name": "', city ,' #', toString(tokenId), '"' ,
                ', "description": "We, born to freedom.To smash the blockade of COVID-19,Cryptotrip is generated.It is stored on chain,for the ones who born to freedom."',
                ', "image": "', baseURI , _tokenURI , '"',
                ', "attributes" : [{"trait_type" : "City","value" : "' , city , '"}]}'
            ))));
        return string(abi.encodePacked('data:application/json;base64,', json));

        return string(abi.encodePacked(baseURI, _tokenURI));
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