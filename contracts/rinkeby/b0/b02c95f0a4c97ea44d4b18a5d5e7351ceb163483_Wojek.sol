/**
 *Submitted for verification at Etherscan.io on 2022-01-25
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

library Address 
{
    function isContract(address account) internal view returns (bool) {
        return account.code.length > 0;
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
        return verifyCallResult(success, returndata, errorMessage);
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
        return verifyCallResult(success, returndata, errorMessage);
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
        return verifyCallResult(success, returndata, errorMessage);
    }

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

library Strings 
{
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

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

abstract contract Context 
{
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context 
{
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IERC165 
{
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

interface IERC721 is IERC165 
{
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

interface IERC721Metadata is IERC721 
{
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function tokenURI(uint256 tokenId) external view returns (string memory);
}

interface IERC721Receiver 
{
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

abstract contract ERC165 is IERC165 
{
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
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
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
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

        _afterTokenTransfer(address(0), to, tokenId);
    }

    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
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

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

library WojekHelper
{
    string internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    function attributeIndexToString(uint256 index) internal pure returns (string memory result)
    {
        if(index == 0)
        {
            result = "Background";
        }
        else if(index == 1)
        {
            result = "Character";
        }
        else if(index == 2)
        {
            result = "Beard";
        }
        else if(index == 3)
        {
            result = "Forehead";
        }
        else if(index == 4)
        {
            result = "Mouth";
        }
        else if(index == 5)
        {
            result = "Eyes";
        }
        else if(index == 6)
        {
            result = "Nose";
        }
        else if(index == 7)
        {
            result = "Hat";
        }
        else if(index == 8)
        {
            result = "Accessory";
        }

        return result;
    }

    function dirtyRandom(uint256 seed, address sender) internal view returns (uint256)
    {
        return uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp, sender, seed)));
    }

    function subString(string memory str, uint startIndex, uint endIndex) internal pure returns (bytes memory) 
    {
        bytes memory strBytes = bytes(str);
        bytes memory result = new bytes(endIndex-startIndex);
        for(uint i = startIndex; i < endIndex; i++) {
            result[i-startIndex] = strBytes[i];
        }
        return result;
    }

    function splitHash(uint256 hash, uint256 hashLength, uint256 attributeIndex) internal pure returns (uint256)
    {
        return ((hash - 10 ** hashLength) / (10 ** (hashLength - (attributeIndex * 3) - 3))) % 1000;
    }

    function stringLength(string memory str) internal pure returns(uint256) {
        return bytes(str).length;
    }

    function toString(uint256 value) internal pure returns (string memory) 
    {
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

    function encode(bytes memory data) internal pure returns (string memory) 
    {
        if (data.length == 0) return "";

        // load the table into memory
        string memory table = TABLE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 3 bytes at a time
            for {

            } lt(dataPtr, endPtr) {

            } {
                dataPtr := add(dataPtr, 3)

                // read 3 bytes
                let input := mload(dataPtr)

                // write 4 characters
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(input, 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }
        }

        return result;
    }
}

contract Wojek is ERC721, Ownable
{
    struct Attribute 
    {
        string value;
        string svg;
    }

    string private constant _svgHeader = "<svg id='wojek-svg' xmlns='http://www.w3.org/2000/svg' preserveAspectRatio='xMinYMin meet' viewBox='0 0 50 50' transform='scale(";
    string private constant _svgStyles = "<style>#wojek-svg{shape-rendering: crispedges;}.w10{fill:#000000}.w11{fill:#ffffff}.w12{fill:#00aaff}.w13{fill:#ff0000}.w14{fill:#ff7777}.w15{fill:#ff89b9}.w16{fill:#fff9e5}.w17{fill:#fff9d5}.w18{fill:#93c63b}.w19{fill:#ff6a00}.w20{fill:#808080}.w21{fill:#a94d00}.w22{fill:#00ffff}.w23{fill:#00ff00}.w24{fill:#B2B2B2}.w25{fill:#267F00}.w26{fill:#5B7F00}.w27{fill:#7F3300}.w28{fill:#A3A3A3}.w29{fill:#B78049}.w30{fill:#B5872B}.w31{fill:#565756}.w32{fill:#282828}.w33{fill:#8F7941}.w34{fill:#E3E5E4}.w35{fill:#6BBDD3}.w36{fill:#FFFF00}.w37{fill:#6A6257}";
        
    string private _background = "<rect class='w00' x='00' y='00' width='50' height='50'/>";
    string private _wojakFill = "<rect class='w01' x='15' y='05' width='19' height='45'/><rect class='w01' x='17' y='03' width='18' height='02'/><rect class='w01' x='34' y='05' width='04' height='37'/><rect class='w01' x='38' y='07' width='02' height='33'/><rect class='w01' x='40' y='09' width='02' height='29'/><rect class='w01' x='42' y='14' width='02' height='20'/><rect class='w01' x='44' y='25' width='01' height='05'/><rect class='w01' x='13' y='07' width='02' height='24'/><rect class='w01' x='11' y='11' width='02' height='15'/><rect class='w01' x='34' y='46' width='12' height='04'/><rect class='w01' x='46' y='49' width='03' height='01'/><rect class='w01' x='34' y='45' width='01' height='01'/><rect class='w01' x='46' y='48' width='01' height='01'/><rect class='w01' x='00' y='47' width='15' height='03'/><rect class='w01' x='05' y='45' width='10' height='02'/><rect class='w01' x='11' y='43' width='04' height='02'/><rect class='w01' x='13' y='39' width='02' height='04'/>";
    string private _wojakOutline = "<rect class='w10' x='00' y='47' width='01' height='01'/><rect class='w10' x='01' y='46' width='04' height='01'/><rect class='w10' x='05' y='45' width='03' height='01'/><rect class='w10' x='08' y='44' width='03' height='01'/><rect class='w10' x='11' y='43' width='01' height='01'/><rect class='w10' x='12' y='42' width='01' height='01'/><rect class='w10' x='13' y='39' width='01' height='03'/><rect class='w10' x='14' y='37' width='01' height='02'/><rect class='w10' x='15' y='32' width='01' height='05'/><rect class='w10' x='14' y='31' width='01' height='01'/><rect class='w10' x='13' y='29' width='01' height='02'/><rect class='w10' x='12' y='26' width='01' height='03'/><rect class='w10' x='11' y='24' width='01' height='02'/><rect class='w10' x='10' y='14' width='01' height='10'/><rect class='w10' x='11' y='11' width='01' height='03'/><rect class='w10' x='12' y='08' width='01' height='03'/><rect class='w10' x='13' y='07' width='01' height='01'/><rect class='w10' x='14' y='06' width='01' height='01'/><rect class='w10' x='15' y='05' width='01' height='01'/><rect class='w10' x='16' y='04' width='01' height='01'/><rect class='w10' x='17' y='03' width='03' height='01'/><rect class='w10' x='20' y='02' width='11' height='01'/><rect class='w10' x='31' y='03' width='04' height='01'/><rect class='w10' x='35' y='04' width='02' height='01'/><rect class='w10' x='37' y='05' width='01' height='01'/><rect class='w10' x='38' y='06' width='01' height='01'/><rect class='w10' x='39' y='07' width='01' height='01'/><rect class='w10' x='40' y='08' width='01' height='01'/><rect class='w10' x='41' y='09' width='01' height='02'/><rect class='w10' x='42' y='11' width='01' height='03'/><rect class='w10' x='43' y='14' width='01' height='03'/><rect class='w10' x='44' y='17' width='01' height='08'/><rect class='w10' x='45' y='25' width='01' height='05'/><rect class='w10' x='44' y='30' width='01' height='02'/><rect class='w10' x='43' y='32' width='01' height='02'/><rect class='w10' x='42' y='34' width='01' height='01'/><rect class='w10' x='41' y='35' width='01' height='03'/><rect class='w10' x='40' y='38' width='01' height='01'/><rect class='w10' x='39' y='39' width='01' height='01'/><rect class='w10' x='38' y='40' width='01' height='01'/><rect class='w10' x='36' y='41' width='02' height='01'/><rect class='w10' x='30' y='42' width='06' height='01'/><rect class='w10' x='28' y='41' width='02' height='01'/><rect class='w10' x='27' y='40' width='01' height='01'/><rect class='w10' x='25' y='39' width='02' height='01'/><rect class='w10' x='24' y='38' width='01' height='01'/><rect class='w10' x='23' y='37' width='01' height='01'/><rect class='w10' x='22' y='36' width='01' height='01'/><rect class='w10' x='21' y='35' width='01' height='01'/><rect class='w10' x='20' y='34' width='01' height='01'/><rect class='w10' x='19' y='31' width='01' height='03'/><rect class='w10' x='18' y='28' width='01' height='03'/><rect class='w10' x='33' y='43' width='01' height='01'/><rect class='w10' x='34' y='44' width='01' height='01'/><rect class='w10' x='35' y='45' width='08' height='01'/><rect class='w10' x='43' y='46' width='03' height='01'/><rect class='w10' x='46' y='47' width='01' height='01'/><rect class='w10' x='47' y='48' width='02' height='01'/><rect class='w10' x='49' y='49' width='01' height='01'/><rect class='w10' x='18' y='36' width='01' height='01'/><rect class='w10' x='19' y='37' width='01' height='02'/><rect class='w10' x='14' y='45' width='02' height='01'/><rect class='w10' x='16' y='44' width='01' height='01'/><rect class='w10' x='17' y='43' width='02' height='01'/><rect class='w10' x='23' y='47' width='02' height='01'/><rect class='w10' x='25' y='48' width='04' height='01'/><rect class='w10' x='29' y='47' width='02' height='01'/>";

    uint256 private constant _traitCount = 9;

    uint256 private constant _hashLength = 30;

    Attribute[][] private _attributes;
    mapping(uint256 => bool) private _mintedTokens; //Hash => Is minted
    mapping(uint256 => uint256) private _tokenHashes; //Id => Hash

    uint256 private _totalSupply;
    uint256 private constant _maxSupply = 10000;

    uint256 private _mintCost;
    uint256 private _mintsLeft;

    uint256[] _seriesRanges;

    constructor() ERC721("Wojek", "WOJEK")
    {
        //Initialize the _attributes array
        for(uint256 i = 0; i < _traitCount; i++)
        {
            _attributes.push();
        }
    }

    receive() external payable
    {
        mint();
    }

    function withdraw() public onlyOwner
    {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }

    function totalSupply() public view returns (uint256)
    {
        return _totalSupply;
    }

    function maxSupply() public pure returns (uint256)
    {
        return _maxSupply;
    }

    function mintsLeft() public view returns (uint256)
    {
        return _mintsLeft;
    }

    function mintCost() public view returns (uint256)
    {
        return _mintCost;
    }

    function finishSeries() public onlyOwner returns (bool)
    {
        _seriesRanges.push(_totalSupply);

        return true;
    }

    function startMint(uint256 amount, uint256 cost) public onlyOwner returns (bool)
    {
        require(_totalSupply < _maxSupply);

        _mintCost = cost;
        _mintsLeft = amount;

        return true;
    }

    function endMint() public onlyOwner returns (bool)
    {
        require(_mintsLeft > 0);
        
        _mintsLeft = 0;

        return true;
    }

    function mint() public payable returns (bool)
    {
        uint256 value = msg.value;
        require(value >= _mintCost);

        uint256 mintAmount = value / _mintCost;
        require(_totalSupply + mintAmount <= _maxSupply);
        require(_mintsLeft - mintAmount >= 0);

        address sender = _msgSender();

        for(uint256 i = 0; i < mintAmount; i++)
        {
            uint256 id = _totalSupply + i;

            uint256 randomNumber = WojekHelper.dirtyRandom(id, sender);

            uint256 hash = 10 ** _hashLength;

            for(uint256 a = 0; a < _traitCount; a++)
            {
                hash += (10 ** (_hashLength - (a * 3) - 3)) * (randomNumber % _attributes[a].length);

                randomNumber >>= 8;
            }

            if(randomNumber % 100 < 10)
            {
                hash += 1; 
            }

            require(_mintedTokens[hash] == false);

            _mintedTokens[hash] = true;
            _tokenHashes[id] = hash;

            _safeMint(sender, id);
        }

        _mintsLeft -= mintAmount;
        _totalSupply += mintAmount;

        return true;
    }

    function mintHashes(uint256[] memory hashes) public onlyOwner returns (bool)
    {
        uint256 mintAmount = hashes.length;
        require(_totalSupply + mintAmount <= _maxSupply);

        address sender = _msgSender();

        for(uint256 i = 0; i < hashes.length; i++)
        {
            uint256 id = _totalSupply + i;

            _mintedTokens[hashes[i]] = true;
            _tokenHashes[id] = hashes[i];

            _safeMint(sender, id);
        }

        _totalSupply += mintAmount;

        return true;
    }

    function addAttributes(uint256 attributeType, Attribute[] memory newAttributes) public onlyOwner returns(bool)
    {
        for(uint256 i = 0; i < newAttributes.length; i++)
        {
            _attributes[attributeType].push(Attribute
            (
                newAttributes[i].value,
                newAttributes[i].svg
            ));
        }

        return true;
    }

    function tokenURI(uint256 id) public view override returns (string memory)
    {
        require(_exists(id));

        uint256 hash = _tokenHashes[id];

        require(_mintedTokens[hash] == true);

        return string(abi.encodePacked(
            "data:application/json;base64,",
            WojekHelper.encode(bytes(string(
                abi.encodePacked(
                    '{"name": "Wojek #',
                    WojekHelper.toString(id),
                    '", "description": "',
                    "Wojeks are a completely onchain collection of images that display a wide variety of emotions, even the feelsbad ones.", 
                    '", "image": "data:image/svg+xml;base64,',
                    WojekHelper.encode(bytes(_generateSvg(hash))),
                    '", "attributes":',
                    _hashMetadata(hash, id),
                    "}"
                )
            )))
        ));
    }

    function _generateSvg(uint256 hash) private view returns(string memory result) 
    {
        string memory xScale = "1";

        if(WojekHelper.splitHash(hash, _hashLength, 9) > 0)
        {
            //Phunked
            xScale = "-1";
        }

        result = string(abi.encodePacked(
            _svgHeader, xScale, ",1)'>", _svgStyles, 
            _attributes[0][WojekHelper.splitHash(hash, _hashLength, 0)].svg, 
            _attributes[1][WojekHelper.splitHash(hash, _hashLength, 1)].svg, 
            "</style>",
            _background,
            _wojakFill,
            _wojakOutline
        ));

        for(uint256 i = 2; i < _traitCount; i++) 
        {
            uint256 attributeIndex = WojekHelper.splitHash(hash, _hashLength, i);

            uint256 svgLength = WojekHelper.stringLength(_attributes[i][attributeIndex].svg) / 10;

            for(uint256 a = 0; a < svgLength; a++)
            {
                uint256 svgIndex = a * 10;

                result = string(abi.encodePacked(
                    result, 
                    "<rect class='w", WojekHelper.subString(_attributes[i][attributeIndex].svg, svgIndex, svgIndex + 2), 
                    "' x='", WojekHelper.subString(_attributes[i][attributeIndex].svg, svgIndex + 2, svgIndex + 4), 
                    "' y='", WojekHelper.subString(_attributes[i][attributeIndex].svg, svgIndex + 4, svgIndex + 6), 
                    "' width='", WojekHelper.subString(_attributes[i][attributeIndex].svg, svgIndex + 6, svgIndex + 8), 
                    "' height='", WojekHelper.subString(_attributes[i][attributeIndex].svg, svgIndex + 8, svgIndex + 10), 
                    "'/>"
                ));
            }
        }

        return string(abi.encodePacked(result, "</svg>"));
    }

    function _hashMetadata(uint256 hash, uint256 id) private view returns(string memory)
    {
        string memory metadata;

        for(uint256 i = 0; i < _traitCount; i++) 
        {
            uint256 attributeIndex = WojekHelper.splitHash(hash, _hashLength, i);

            if(WojekHelper.stringLength(_attributes[i][attributeIndex].svg) > 0)
            {
                metadata = string(abi.encodePacked
                (
                    metadata,
                    '{"trait_type":"',
                    WojekHelper.attributeIndexToString(i),
                    '","value":"',
                    _attributes[i][attributeIndex].value,
                    '"},'
                ));
            }
        }

        if(WojekHelper.splitHash(hash, _hashLength, 9) > 0)
        {
            //Phunked
            metadata = string(abi.encodePacked
            (
                metadata,
                '{"trait_type":"',
                "Phunk",
                '","value":"',
                "Phunked",
                '"},'
            ));
        }

        for(uint256 i = 0; i < _seriesRanges.length + 1; i++) 
        {
            if(i == _seriesRanges.length || id < _seriesRanges[i])
            {
                //Series
                metadata = string(abi.encodePacked
                (
                    metadata,
                    '{"trait_type":"',
                    "Series",
                    '","value":"',
                    WojekHelper.toString(i),
                    '"}'
                ));
            }
        }

        return string(abi.encodePacked("[", metadata, "]"));
    }
}