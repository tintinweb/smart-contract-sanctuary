/**
 *Submitted for verification at polygonscan.com on 2021-11-17
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
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

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
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

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
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


abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

pragma solidity ^0.8.0;

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

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
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
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


interface IERC721Receiver {
  
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}


pragma solidity ^0.8.0;

interface IERC165 {
   
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

pragma solidity ^0.8.0;



abstract contract ERC165 is IERC165 {
    
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
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


interface IERC721Enumerable is IERC721 {

    function totalSupply() external view returns (uint256);

    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

  
    function tokenByIndex(uint256 index) external view returns (uint256);
}


pragma solidity ^0.8.0;


interface IERC721Metadata is IERC721 {
  
    function name() external view returns (string memory);

  
    function symbol() external view returns (string memory);

   
    function tokenURI(uint256 tokenId) external view returns (string memory);
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

        // Clear approvals from the previous owner
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
}




pragma solidity ^0.8.0;



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
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
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

   
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

   
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}


pragma solidity ^0.8.0;

contract DwarfSpaceForce is ERC721Enumerable, Ownable {
    using Strings for uint256;
    address ipfs = 0xfc2D40ad08f176f728A63DAdd22abC6929f544b6;
    string public baseTokenURI = "ipfs://QmNuePv9SkygvresjSYctnTg59xM1yNoacKputTEb3jdZj/";
    
    uint256 public maxSupply = 10000;
    uint256 public reserve = 250;
    uint256 public maxPreSaleMint = 3;
    uint256 public maxPublicSaleMint = 10;
    bool public isPreSaleActive = false;
    bool public isPublicSaleActive = true;

    uint256 public price = 136 ether;
    uint256 public rewardFirstLevel = 33;
    uint256 public rewardSecondLevel = 14;
    uint256 public rewardThirdLevel = 5;
    uint256 public invitedDiscount = 20;

    mapping(address => bool) public whitelist;

    struct codeInvitee {
        address invitor;
        string  acode;
        uint256 amt;    
        string  pcode;
    }
    mapping(address => codeInvitee ) userInviteInfo;
    mapping( string => address ) addressOfCode;
    mapping(address => address[]) invitedUsersList;

    struct InviteeInfo {
        address invitor;
        address invitee;
        uint inviteeMintCount;
        uint level;
    }

    uint256 public totalWhitelist;
    

    modifier onlyWhitelisted() {
        require(whitelist[msg.sender], 'Sorry, this address is not on the whitelist. Please message us on Discord.');
        _;
    }

    
    constructor() ERC721("Dwarf Space Force", "DSF") {
        setBaseURI(baseTokenURI);
    }


    function mintReserve(uint256 _mintCount) public onlyOwner {
        uint256 supply = totalSupply();
        uint256 tokenCount = balanceOf(msg.sender);

        require(_mintCount > 0,                          'Dwarf count can not be 0');
        require(tokenCount + _mintCount <= reserve,      'This transaction would exceed reserve supply of dwarf.');
        require(supply + _mintCount <= maxSupply,        'This transaction would exceed max supply of dwarf');
        
        for (uint256 i = 0; i < _mintCount; i++) {
            if (totalSupply() < maxSupply) {
               _safeMint(msg.sender, supply + i);
            }
        }
    }


    function multipleAddressesToWhiteList(address[] memory addresses) public onlyOwner {
        for(uint256 i =0; i < addresses.length; i++) {
            singleAddressToWhiteList(addresses[i]);
        }
    }

    function singleAddressToWhiteList(address userAddress) public onlyOwner {
        require(userAddress != address(0), "Address can not be zero");
        whitelist[userAddress] = true;
        totalWhitelist++;
    }


    function removeAddressesFromWhiteList(address[] memory addresses) public onlyOwner {
        for(uint i =0; i<addresses.length; i++) {
            removeAddressFromWhiteList(addresses[i]);
        }
    }

  
    function removeAddressFromWhiteList(address userAddress) public onlyOwner {
        require(userAddress != address(0), "Address can not be zero");
        whitelist[userAddress] = false;
        totalWhitelist--;
    }


    function mint(uint256 _mintCount, string memory code) public payable {
        
        uint256 supply = totalSupply();
        bytes memory byteCode = bytes(code);
        uint256 realPrice = price;
        if ( byteCode.length>0 )  realPrice = price * (100-invitedDiscount) / 100;
        
        require(isPublicSaleActive,                   'Public sale is not active');
        require(_mintCount > 0,                       'Dwarf count can not be 0');
        require(_mintCount <= maxPublicSaleMint,      string(abi.encodePacked('You can only mint ', maxPublicSaleMint.toString(), ' dwarfs in one transaction')));
        require(supply + _mintCount <= maxSupply,     'This transaction would exceed max supply of dwarf');
        require(msg.value >= realPrice * _mintCount,      'Ether value is too low');
        
        address owners;
        codeInvitee memory invitor = userInviteInfo[msg.sender];
        if ( invitor.invitor != address(0) ) {
            //require(keccak256(abi.encodePacked(invitor.acode)) == keccak256(abi.encodePacked(code)), "InvalidInviteCode");
            require(invitor.invitor == addressOfCode[code], "InvlideInviteCode");
            invitor.amt += _mintCount;
        } else {
            
            if (byteCode.length == 0) {
                                
            } else {
                require(addressOfCode[code] != address(0), "Invalid Invite Code");
                require(addressOfCode[code] != msg.sender, "Invalid Invite Code");
                invitor.invitor = addressOfCode[code];
                invitor.acode = code;
                invitor.amt = _mintCount;
                userInviteInfo[msg.sender] = invitor;
                invitedUsersList[addressOfCode[code]].push(msg.sender);
            }   
        }
        
        for (uint256 i = 0; i < _mintCount; i++) {
            if (totalSupply() < maxSupply) {
                _safeMint(msg.sender, supply + i);
            }
        }
        
        address[] memory topLevelUsers = getTop3Account(msg.sender);
        if ( supply < reserve + 100 ) {
            if (topLevelUsers[0] == address(0)) {
                require(payable(owner()).send(realPrice * _mintCount));
            } else if (topLevelUsers[1] == address(0)) {
                require(payable(topLevelUsers[0]).send(realPrice * rewardFirstLevel * _mintCount / 100));
                require(payable(owner()).send(realPrice * (100 - rewardFirstLevel) * _mintCount / 100));
            } else if (topLevelUsers[2] == address(0)) {
                require(payable(topLevelUsers[0]).send(realPrice * rewardFirstLevel * _mintCount / 100));
                require(payable(topLevelUsers[1]).send(realPrice * rewardSecondLevel * _mintCount / 100));
                require(payable(owner()).send(realPrice * (100 - rewardFirstLevel - rewardSecondLevel) * _mintCount / 100));
            } else {
                require(payable(topLevelUsers[0]).send(realPrice * rewardFirstLevel * _mintCount / 100));
                require(payable(topLevelUsers[1]).send(realPrice * rewardSecondLevel * _mintCount / 100));
                require(payable(topLevelUsers[2]).send(realPrice * rewardThirdLevel * _mintCount / 100));
                require(payable(owner()).send(realPrice * (100 - rewardFirstLevel - rewardSecondLevel - rewardThirdLevel) * _mintCount / 100));
            }
        } else {
            if (topLevelUsers[0] == address(0)) {
                require(payable(owner()).send(realPrice * _mintCount/2));
                require(payable(owners).send(realPrice * _mintCount/2));
            } else if (topLevelUsers[1] == address(0)) {
                require(payable(topLevelUsers[0]).send(realPrice * rewardFirstLevel * _mintCount / 100));
                require(payable(owner()).send(realPrice * (100 - rewardFirstLevel) * _mintCount / 200));
                require(payable(owners).send(realPrice * (100 - rewardFirstLevel) * _mintCount / 200));
            } else if (topLevelUsers[2] == address(0)) {
                require(payable(topLevelUsers[0]).send(realPrice * rewardFirstLevel * _mintCount / 100));
                require(payable(topLevelUsers[1]).send(realPrice * rewardSecondLevel * _mintCount / 100));
                require(payable(owner()).send(realPrice * (100 - rewardFirstLevel - rewardSecondLevel) * _mintCount / 200));
                require(payable(owners).send(realPrice * (100 - rewardFirstLevel - rewardSecondLevel) * _mintCount / 200));
            } else {
                require(payable(topLevelUsers[0]).send(realPrice * rewardFirstLevel * _mintCount / 100));
                require(payable(topLevelUsers[1]).send(realPrice * rewardSecondLevel * _mintCount / 100));
                require(payable(topLevelUsers[2]).send(realPrice * rewardThirdLevel * _mintCount / 100));
                require(payable(owner()).send(realPrice * (100 - rewardFirstLevel - rewardSecondLevel - rewardThirdLevel) * _mintCount / 200));
                require(payable(owners).send(realPrice * (100 - rewardFirstLevel - rewardSecondLevel - rewardThirdLevel) * _mintCount / 200));
            }
        }
        
       
    }
    
    function getTop3Account(address account) internal view returns(address[] memory) {
        address[] memory top_users = new address[](3);
        top_users[0] = address(0);
        top_users[1] = address(0);
        top_users[2] = address(0);
        
        top_users[0] = userInviteInfo[account].invitor;
        if (top_users[0] == address(0)) return top_users;
        
        top_users[1] = userInviteInfo[top_users[0]].invitor;
        if (top_users[1] == address(0)) return top_users;
        
        top_users[2] = userInviteInfo[top_users[1]].invitor;
        return top_users;
    }

    function get3LevelInvitedLists(address inviteeL0) public view returns(InviteeInfo[] memory) {
        uint totalCount = 0;
        for (uint i = 0; i < invitedUsersList[inviteeL0].length; i++) {
            address inviteeL1 = invitedUsersList[inviteeL0][i];
            totalCount++;
            for (uint j = 0; j < invitedUsersList[inviteeL1].length; j++) {
                address inviteeL2 = invitedUsersList[inviteeL1][j];
                totalCount++;
                totalCount += invitedUsersList[inviteeL2].length;
            }
        }

        InviteeInfo[] memory invitees = new InviteeInfo[](totalCount);
        uint idx = 0;
        for (uint i = 0; i < invitedUsersList[inviteeL0].length; i++) {
            address inviteeL1 = invitedUsersList[inviteeL0][i];
            InviteeInfo memory infoL1;
            infoL1.invitor = inviteeL0;
            infoL1.invitee = inviteeL1;
            infoL1.inviteeMintCount = userInviteInfo[inviteeL1].amt;
            infoL1.level = 1;
            invitees[idx] = infoL1; idx++;
            
            for (uint j = 0; j < invitedUsersList[inviteeL1].length; j++) {
                address inviteeL2 = invitedUsersList[inviteeL1][j];
                InviteeInfo memory infoL2;
                infoL2.invitor = inviteeL1;
                infoL2.invitee = inviteeL2;
                infoL2.inviteeMintCount = userInviteInfo[inviteeL2].amt;
                infoL2.level = 2;
                invitees[idx] = infoL2; idx++;
                
                for (uint k = 0; k < invitedUsersList[inviteeL2].length; k++) {
                    address inviteeL3 = invitedUsersList[inviteeL2][k];
                    InviteeInfo memory infoL3;
                    infoL3.invitor = inviteeL2;
                    infoL3.invitee = inviteeL3;
                    infoL3.inviteeMintCount = userInviteInfo[inviteeL3].amt;
                    infoL3.level = 3;
                    invitees[idx] = infoL3; idx++;
                }
            }
        }
        return invitees;
    }
   
    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
    }

     function setPrice(uint256 _price, uint256 first, uint256 second, uint256 third, uint256 discount) public onlyOwner {
        require(_price>60 ether, "Invalid price");
        
        require(first>0 && first<=50, "Invalid First Level Input");
        require(second>0 && second<=50, "Invalid Second Level Input");
        require(third>0 && third<=50, "Invalid Third Level Input");
        require( discount>=0 && discount<50, "Invalid Discount");
        require(first+second+third+discount<=100, "Invalid Levels Input");
    
        rewardFirstLevel = first;
        rewardSecondLevel = second;
        rewardThirdLevel = third;
        invitedDiscount = discount;
        price = _price;
    }

    function setRewardLevelPercent( uint256 first, uint256 second, uint256 third, uint256 discount ) public onlyOwner{
        require(first>0 && first<=50, "Invalid First Level Input");
        require(second>0 && second<=50, "Invalid Second Level Input");
        require(third>0 && third<=50, "Invalid Third Level Input");
        require( discount>=0 && discount<50, "Invalid Discount");
        require(first+second+third+discount<=100, "Invalid Levels Input");
    
        rewardFirstLevel = first;
        rewardSecondLevel = second;
        rewardThirdLevel = third;
        invitedDiscount = discount;
    }
    
    
    function setMaxPreSale(uint256 _number) public onlyOwner {
        require(_number>1, "Invalid value");
        maxPreSaleMint = _number;
    }

    function flipPreSale() public onlyOwner {
        require(isPublicSaleActive == false, "Can't Change to presale");
        isPublicSaleActive = false;
        isPreSaleActive = true;
    }

    function flipPublicSale() public onlyOwner {
        isPreSaleActive = false;
        isPublicSaleActive = true;
    }

    function tokensOfOwner(address owner) public view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(owner);
        uint256[] memory tokenIds = new uint256[](tokenCount);
        for (uint256 i = 0; i < tokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(owner, i);
        }
        return tokenIds;
    }

    function info() public view returns (uint256, uint256, uint256, bool, bool, uint256, uint256, uint256, uint256) {
        return (price, maxPreSaleMint, maxPublicSaleMint, isPreSaleActive, isPublicSaleActive, rewardFirstLevel, rewardSecondLevel, rewardThirdLevel, invitedDiscount);
    }
    
    function saveCode(address account, string memory code) public {
        bytes memory byteCode = bytes(code); // Uses memory
        require(byteCode.length > 0, "InvlideCode");
        
        userInviteInfo[account].pcode = code;
        addressOfCode[code] = account;
    }

    function getCode(address account) public view returns(string memory ) {
        return userInviteInfo[account].pcode;
    }
    
    function getInvitedCode( address account) public view returns(string memory){
        return userInviteInfo[account].acode;
    }
    
    function burn( uint256 tokenId) public onlyOwner {
        _burn(tokenId);
    }
    
    function withdraw() public onlyOwner {
        require(address(this).balance > 0, "Balance must be positive");

        uint256 _balance = address(this).balance;
        payable(owner()).transfer(_balance);
    }
}