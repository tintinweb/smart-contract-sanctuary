/**
 *Submitted for verification at Etherscan.io on 2022-01-16
*/

//SPDX-License-Identifier: Unlicense

//Ardi

pragma solidity 0.8.11;
interface IERC165 {

    function supportsInterface(bytes4 interfaceId) external view returns (bool);

}
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
interface IERC721Receiver {

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);

}
interface IERC721Metadata is IERC721 {

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function tokenURI(uint256 tokenId) external view returns (string memory);

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
abstract contract ERC165 is IERC165 {

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
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
    }

    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
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

/*
░█████╗░██████╗░██╗░░░██╗██████╗░████████╗░█████╗░██████╗░██╗░█████╗░██╗░░██╗██╗███████╗
██╔══██╗██╔══██╗╚██╗░██╔╝██╔══██╗╚══██╔══╝██╔══██╗██╔══██╗██║██╔══██╗██║░██╔╝██║██╔════╝
██║░░╚═╝██████╔╝░╚████╔╝░██████╔╝░░░██║░░░██║░░██║██║░░██║██║██║░░╚═╝█████═╝░██║█████╗░░
██║░░██╗██╔══██╗░░╚██╔╝░░██╔═══╝░░░░██║░░░██║░░██║██║░░██║██║██║░░██╗██╔═██╗░██║██╔══╝░░
╚█████╔╝██║░░██║░░░██║░░░██║░░░░░░░░██║░░░╚█████╔╝██████╔╝██║╚█████╔╝██║░╚██╗██║███████╗
░╚════╝░╚═╝░░╚═╝░░░╚═╝░░░╚═╝░░░░░░░░╚═╝░░░░╚════╝░╚═════╝░╚═╝░╚════╝░╚═╝░░╚═╝╚═╝╚══════╝
*/
contract cryptoDickies is ERC721, Ownable {

    uint256 public constant maxSupply = 9999;
    uint256 public constant maxMint = 10;
    uint256 public numTokensMinted = 0;
    uint256 public price = 0.01 ether;
    
    string private PT = '<path stroke="#';
    string private End = '" />';
    string[3] private Type = ['Zombie', 'Ape', 'Alien'];
    string[11] private baseColors = ['#7DA269', '#61503D', '#C8FBFB', '#C9CCAF', '#E8AA96','#F2B8B8', '#DBB181', '#EAD9D9', '#AE8B61', '#EECFA0', '#D5C6E1'];
    string[11] private baseShades = ['#4B613F', '#3A3025', '#9BE0E0', '#797B69', '#8C665A','#997574', '#846A4E', '#8D8383', '#69543A', '8F7D60', '#807787'];
    string[3] private abnormaltypefaces = ['4b613f" d="M12 16h2M17 16h2M12 18h1M17 18h1" /><path stroke="#fd3232" d="M12 17h1M17 17h1" /><path stroke="#000000" d="M13 17h1M18 17h1M14 23h3" /><path stroke="#48613f" d="M14 24h1', 
            '958a7d" d="M13 13h5M12 14h7M11 15h8M11 16h1M14 16h3M11 17h1M14 17h3M11 18h8M12 19h2M15 19h1M17 19h2M13 20h5M12 21h7M12 22h7M12 23h2M17 23h2M13 24h5" /><path stroke="#000000" d="M14 19h1M16 19h1" /><path stroke="#61503d" d="M18 20h1', 
            '75bdbd" d="M12 16h1M17 16h1" /><path stroke="#000000" d="M13 16h1M18 16h1M12 17h1M17 17h1M13 23h5" /><path stroke="#9be0e0" d="M13 17h1M18 17h1M15 18h1M15 19h1M15 20h1M15 21h1" /><path stroke="#c8fbfb" d="M16 20h1'];
    
    string[4] private attribute_1_mouth = ['Straight', 'Frown', 'Smile', 'Mustahce'];
    string[4] private attribute_1 = ['', 
            '000000" d="M13 24h1', 
            '000000" d="M13 22h1', 
            'c28846" d="M13 22h1M17 22h1" /><path stroke="#a66d2c" d="M14 22h3M13 23h1M17 23h1M13 24h1M17 24h1'];
    
    string[4] private attribute_2_cigars = ['None', 'E-Sig', 'Cigarette', 'Pipe'];
    string[4] private attribute_2 = ['', 
            '000000" d="M17 22h5M22 23h1M17 24h5" /><path stroke="#595959" d="M17 23h4" /><path stroke="#304ffe" d="M21 23h1', 
            '97a9b3" d="M22 17h1M22 18h1M22 19h1M22 20h1" /><path stroke="#000000" d="M17 22h5M22 23h1M17 24h5" /><path stroke="#d1d7d7" d="M17 23h4" /><path stroke="#d79a00" d="M21 23h1', 
            'b4b4b4" d="M23 22h1" /><path stroke="#000000" d="M16 23h1M18 23h1M17 24h1M19 24h1M21 24h1M25 24h1M18 25h1M20 25h2M25 25h1M19 26h1M24 26h1M20 27h4" /><path stroke="#794b12" d="M17 23h1M18 24h1M22 24h3M19 25h1M22 25h3M20 26h4'];
    
    string[4] private attribute_3_accessory = ['None', 'Piercing', 'Rash', 'Pubes'];
    string[4] private attribute_3 = ['', 
            '9e9e9e" d="M9 20h1', 
            '000000" d="M8 22h1M7 23h1M8 24h1" /><path stroke="#d50000" d="M9 22h1M8 23h2M9 24h1', 
            '000000" d="M4 21h1M1 22h1M4 22h2M1 23h6M2 24h6M26 24h2M3 25h6M22 25h1M24 25h1M26 25h1M1 26h7M21 26h7M2 27h5M22 27h4M1 28h5M22 28h5M2 29h5M23 29h3'];
    
    string[9] private attribute_4_glasses = ['None', 'VR', 'Classic', 'Sleep Mask', 'Shades', '3D', 'Patch', 'Big Shades', 'Small Shades'];
    string[9] private attribute_4 = ['', 
            '000000" d="M11 14h8M10 15h1M20 15h1M12 16h7M20 16h1M12 17h7M20 17h1M10 18h1M20 18h1M11 19h8" /><path stroke="#8d8d8d" d="M11 15h1M19 15h1M10 16h1M10 17h1M11 18h1M19 18h1" /><path stroke="#b4b4b4" d="M12 15h7M11 16h1M19 16h1M11 17h1M19 17h1M12 18h7', 
            '000000" d="M10 15h9M11 16h1M15 16h1" /><path stroke="#eeeeee" d="M12 16h1M16 16h1M12 17h1M16 17h1M12 18h3M16 18h3" /><path stroke="#bdbdbd" d="M13 16h2M17 16h2" /><path stroke="#757575" d="M13 17h1M17 17h1" /><path stroke="#e0e0e0" d="M14 17h1M18 17h1', 
            '000000" d="M10 16h9M10 17h10', 
            '000000" d="M10 15h10M11 16h1M14 16h1M16 16h1M11 17h1M14 17h1M16 17h1M12 18h2M17 18h2" /><path stroke="#5c390c" d="M12 16h2M17 16h2" /><path stroke="#c77613" d="M12 17h2M17 17h2', 
            'ffffff" d="M9 15h12M11 16h1M15 16h1M19 16h1M11 17h1M15 17h1M19 17h1M11 18h9" /><path stroke="#2196f3" d="M12 16h3M12 17h3" /><path stroke="#ff1744" d="M16 16h1M16 17h3" /><path stroke="#fd3232" d="M17 16h2', 
            '000000" d="M10 15h9M12 16h3M12 17h3M13 18h1', 
            '000000" d="M10 16h9M20 16h1M11 17h4M16 17h3M20 17h1M12 18h2M17 18h2', 
            '000000" d="M10 16h9M12 17h2M17 17h2'];

    string[12] private attribute_5_Hats = ['None', 'Condom', 'Knitted', 'Top', 'Fedora', 'Cap', 'Durag', 'Cowboy', 'Forward', 'Blood!', 'Pee!', 'Cum!'];
    //'<path stroke="#'
    string[12] private attribute_5 = ['',
    'abc7bf" d="M12 3h5M11 4h1M17 4h1M10 5h1M18 5h1M9 6h1M19 6h1M8 7h1M20 7h1M7 8h1M21 8h1M6 9h1M22 9h1M6 10h1M22 10h1M6 11h1M22 11h1M7 12h1M21 12h1M8 13h1M20 13h1', 
    '000000" d="M10 4h9M9 5h1M19 5h1M8 6h1M20 6h1M7 7h1M21 7h1M7 8h1M21 8h1" /><path stroke="#ca4f12" d="M10 5h9M9 6h11M8 7h13M8 8h13', 
    '000000" d="M8 1h13M7 2h15M7 3h15M7 4h15M7 5h15M6 7h17M5 8h19" /><path stroke="#dc1d1d" d="M7 6h15', 
    '3d2f1e" d="M11 1h7M10 2h9M9 3h11M9 4h11M8 5h13M5 7h19M4 8h21" /><path stroke="#000000" d="M7 6h15', 
    '8019b7" d="M9 4h11M8 5h10M19 5h2M7 6h12M20 6h1M7 7h17M7 8h18" /><path stroke="#b361dc" d="M18 5h1M19 6h1', 
    '000000" d="M9 4h11M8 5h1M20 5h1M7 6h1M21 6h1M7 7h1M21 7h1M7 8h1M21 8h1" /><path stroke="#515151" d="M9 5h11M8 6h13M8 7h13M8 8h13', 
    '794b12" d="M10 2h2M17 2h2M9 3h11M9 4h11M9 5h11M4 6h1M24 6h1M4 7h21M5 8h19" /><path stroke="#503005" d="M8 6h13', 
    '000000" d="M9 3h11M8 4h1M20 4h1M7 5h1M21 5h1M7 6h1M13 6h10M7 7h1M12 7h12M7 8h17" /><path stroke="#515151" d="M9 4h11M8 5h13M8 6h5M8 7h4', 
    'ff0000" d="M12 1h1M11 2h1M13 2h1M10 3h1M14 3h1M9 4h1M8 5h1M8 6h1M7 7h1', 
    'f1df39" d="M12 1h1M11 2h1M13 2h1M10 3h1M14 3h1M9 4h1M8 5h1M8 6h1M7 7h1', 
    'ffffff" d="M12 1h1M11 2h1M13 2h1M10 3h1M14 3h1M9 4h1M8 5h1M8 6h1M7 7h1'];
  
    struct DickObject {
        uint256 attribute_0;
        uint256 attribute_1;
        uint256 attribute_2;
        uint256 attribute_3;
        uint256 attribute_4;
        uint256 attribute_5;
    }

    function randomDick(uint256 tokenId) internal pure returns (DickObject memory) {
        
        DickObject memory Dick;

        uint256 rn = (220911037794467/tokenId) % 70;
        uint256 a = 0;
        if (rn >= 1 && rn < 2) { a = 1; }
        if (rn >= 2 && rn < 3) { a = 2; }
        if (rn >= 3 && rn < 16) { a = 3; }
        if (rn >= 16 && rn < 26) { a = 4; }
        if (rn >= 26 && rn < 36) { a = 5; }
        if (rn >= 36 && rn < 46) { a = 6; }
        if (rn >= 46 && rn < 56) { a = 7; }
        if (rn >= 56) { a = 8; }
        Dick.attribute_0 = a;

        rn = (811742552641903/tokenId) % 6;
        if (rn < 3) { Dick.attribute_1 = 0; } else {
            Dick.attribute_1 = rn - 2;
        }        

        rn = (334288938190873/tokenId) % 20;
        if (rn < 17) { Dick.attribute_2 = 0; } else {
            Dick.attribute_2 = rn - 16;
        }

        rn = (707824864766807/tokenId) % 20;
        if (rn < 17) { Dick.attribute_3 = 0; } else {
            Dick.attribute_3 = rn - 16;
        }

        rn = (367999528793983/tokenId) % 50;
        if (rn < 42) { Dick.attribute_4 = 0; } else {
            Dick.attribute_4 = rn - 41;
        }

        rn = (228193987164089/tokenId) % 40;
        if (rn < 29) { Dick.attribute_5 = 0; } else {
            Dick.attribute_5 = rn - 28;
        }

        return Dick;
    }

    function getattributes(DickObject memory Dick) internal view returns (string memory) {
        
        string[2] memory parts;

        if (Dick.attribute_0 <= 2) {parts[0] = Type[Dick.attribute_0];}
        if (Dick.attribute_0 > 2) {parts[0] = 'Normal';}
        
        if (Dick.attribute_0 <= 2) {parts[1] = Type[Dick.attribute_0];}
        if (Dick.attribute_0 > 2) {parts[1] = attribute_1_mouth[Dick.attribute_1];}
        
        string memory output = string(abi.encodePacked(', "attributes": [{"trait_type": "Type","value": "', parts[0], '"}, {"trait_type": "Mouth","value": "', parts[1], '"}, {"trait_type": "Cigar","value": "', attribute_2_cigars[Dick.attribute_2], '"}, {"trait_type": "Accessory","value": "')); 
                      output = string(abi.encodePacked(output, attribute_3_accessory[Dick.attribute_3], '"}, {"trait_type": "Glasses","value": "', attribute_4_glasses[Dick.attribute_4], '"}, {"trait_type": "Dick Head","value": "', attribute_5_Hats[Dick.attribute_5], '"}], '));
        return output;
    }

    function getSVG(DickObject memory Dick) internal view returns (string memory) {
        string[1] memory parts;
        
        if (Dick.attribute_0 <= 2) {
            parts[0] = abnormaltypefaces[Dick.attribute_0];}
            else {
                parts[0] = attribute_1[Dick.attribute_1];
            }
        
        string memory output = string(abi.encodePacked('<svg id="x" xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 30 30"><rect width="29.5" height="29.5" style="fill:#638596" /><path stroke="#000000" d="M12 4h5M11 5h1M17 5h1M10 6h1M18 6h1M9 7h1M19 7h1M8 8h1M20 8h1M7 9h1M21 9h1M7 10h1M21 10h1M7 11h1M21 11h1M8 12h1M10 12h1M18 12h1M20 12h1M15 20h2M14 23h3M8 26h1M20 26h1M7 27h1M13 27h1M15 27h1M21 27h1M6 28h1M14 28h1M22 28h1M6 29h1M14 29h1M22 29h1" /><rect x="9.5" y="11" width="10" height="15" style="stroke:#000000;stroke-width:1;fill:none"/><path stroke="', baseColors[Dick.attribute_0], '" d="M12 5h2M15 5h2M11 6h7M10 7h9M9 8h11M9 9h12M9 10h12M10 11h1M18 11h3M11 12h7M19 12h1M11 13h8M11 14h8M11 15h8M11 16h8M11 17h8M11 18h8M11 19h8M11 20h4M17 20h2M11 21h8M11 22h8M11 23h3M17 23h2M11 24h8M11 25h8M13 26h3M8 27h5M14 27h1M16 27h5M8 28h6M16 28h6M9 29h5M17 29h5" /><path stroke="', baseShades[Dick.attribute_0], '" d="M14 5h1M8 9h1M8 10h1M8 11h2M9 12h1M10 13h1M10 14h1M10 15h1M10 16h1M10 17h1M10 18h1M10 19h1M10 20h1M10 21h1M10 22h1M10 23h1M10 24h1M10 25h1M7 28h1M15 28h1M7 29h2M15 29h2" />', '<path stroke="#000000" stroke-opacity="0.4" d="M12 16h2M17 16h2" /><path stroke="#000000" d="M12 17h1M17 17h1" /><path stroke="#000000" stroke-opacity="0.2" d="M13 17h1M18 17h1" />', PT, parts[0]));
                      output = string(abi.encodePacked(output, End, PT, attribute_2[Dick.attribute_2], End, PT, attribute_3[Dick.attribute_3]));
                      output = string(abi.encodePacked(output, End, PT, attribute_4[Dick.attribute_4], End));
                      output = string(abi.encodePacked(output, PT, attribute_5[Dick.attribute_5], End,  '<style>#x{shape-rendering: crispedges;}</style></svg>'));

        return output;
    }

    function tokenURI(uint256 tokenId) override public view returns (string memory) {
        DickObject memory Dick = randomDick(tokenId);
        string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "CryptoDickies NFT #', toString(tokenId), '", "description": "On-chain random NFT"', getattributes(Dick), '"image": "data:image/svg+xml;base64,', Base64.encode(bytes(getSVG(Dick))), '"}'))));
        json = string(abi.encodePacked('data:application/json;base64,', json));
        return json;
    }

    function mintDick(address destination, uint256 amountOfTokens) private {
        require(numTokensMinted < maxSupply, "All minted");
        require(numTokensMinted + amountOfTokens <= maxSupply, "Sold Out!");
        require(amountOfTokens <= maxMint, "Too many mints");
        require(amountOfTokens > 0, "Zero mint?");
        require(price * amountOfTokens == msg.value, "Paid amount is incorrect");

        for (uint256 i = 0; i < amountOfTokens; i++) {
            uint256 tokenId = numTokensMinted + 1;
            _safeMint(destination, tokenId);
            numTokensMinted += 1;
        }
    }

    function mint(uint256 amountOfTokens) public payable virtual {
        mintDick(_msgSender(),amountOfTokens);
    }

    function setPrice(uint256 newPrice) public onlyOwner {
        price = newPrice;
    }

    function withdrawAll() public payable onlyOwner {
        require(payable(_msgSender()).send(address(this).balance));
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
    
    constructor() ERC721("Crypto Dickies", "DICK") Ownable() {}
}

library Base64 {
    bytes internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";

        uint256 encodedLen = 4 * ((len + 2) / 3);

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