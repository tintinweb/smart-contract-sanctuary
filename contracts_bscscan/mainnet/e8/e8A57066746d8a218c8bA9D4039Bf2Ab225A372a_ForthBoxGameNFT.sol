/**
 *Submitted for verification at BscScan.com on 2021-12-13
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;


interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
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
    function onERC721Received(address operator,address from,uint256 tokenId,bytes calldata data) view external returns (bytes4);
}

interface IERC721Metadata is IERC721 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {size := extcodesize(account)}
        return size > 0;
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
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
}
abstract contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }
    function owner() public view returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

library Counters {
    struct Counter {
        uint256 _value;
    }
    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }
    function increment(Counter storage counter) internal {
        unchecked {counter._value += 1;}
    }
}

interface IERC721Enumerable is IERC721 {
    function totalSupply() external view returns (uint256);
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);
    function tokenByIndex(uint256 index) external view returns (uint256);
}

contract ReentrancyGuard {
    uint256 private _guardCounter;
    constructor () {
        _guardCounter = 1;
    }
    modifier nonReentrant() {
        _guardCounter += 1;
        uint256 localCounter = _guardCounter;
        _;
        require(localCounter == _guardCounter, "ReentrancyGuard: reentrant call");
    }
}

abstract contract ERC165 is IERC165 {
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

abstract contract ERC721 is Context,ERC165, IERC721, IERC721Metadata,IERC721Receiver,Ownable {
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
        require(_exists(tokenId), "FBXNFT: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");
        require(_msgSender() == owner || isApprovedForAll(owner, _msgSender()),"ERC721: approve caller is not owner nor approved for all");
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
    function transferFrom(address from,address to,uint256 tokenId) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _transfer(from, to, tokenId);
    }
    function safeTransferFrom(address from,address to,uint256 tokenId) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }
    function safeTransferFrom(address from,address to,uint256 tokenId,bytes memory _data) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }
    function _safeTransfer(address from,address to,uint256 tokenId,bytes memory _data) internal virtual {
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
    function _safeMint(address to,uint256 tokenId,bytes memory _data) internal virtual {
        _mint(to, tokenId);
        require(_checkOnERC721Received(address(0), to, tokenId, _data),"ERC721: transfer to non ERC721Receiver implementer");
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
    function _transfer(address from,address to,uint256 tokenId) internal virtual {
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

    function _checkOnERC721Received(address from,address to,uint256 tokenId,bytes memory _data) private view returns (bool) {
        if (to.isContract()){
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval){
              return retval == IERC721Receiver.onERC721Received.selector;
            }
            catch (bytes memory reason){
                if (reason.length == 0){
                  revert("ERC721: transfer to non ERC721Receiver implementer");
                }
                else{
                  assembly {revert(add(32, reason), mload(reason))}
                }
            }
        } else {
            return true;
        }
    }
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }
    function _beforeTokenTransfer(address from,address to,uint256 tokenId) internal virtual {}
}

abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;
    mapping(uint256 => uint256) private _ownedTokensIndex;
    uint256[] private _allTokens;
    mapping(uint256 => uint256) private _allTokensIndex;

    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }
    function tokenOfOwner(address owner) public view returns (uint256[] memory) {
        uint256 num = ERC721.balanceOf(owner);
        uint256[] memory Token_list = new uint256[](uint256(num));
        for(uint256 i=0; i<num; ++i) {
            Token_list[i] =_ownedTokens[owner][i];
        }
        return Token_list;
    }
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }
    function _beforeTokenTransfer(address from,address to,uint256 tokenId) internal virtual override {
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
    function onERC721Received(address,address,uint256,bytes memory) public view virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
         return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }
}

contract ForthBoxGameNFT is ERC721Enumerable,ReentrancyGuard  {
    using Strings for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIds;
    string private _baseURIextended="https://www.forthbox.io/";
    string[4] private _imageAdress = ["","","",""];
    string[4] private _degreeName = ["N","R","SR","SSR"];
    uint256[4] public maxTokenNum =[5000,3000,1500,500];
    uint256[4] public mintTokenNum =[0,0,0,0];
    uint256 public maxTotalSupply = 10000;

    struct sNftPropertys {
        uint256 value;
    }
    mapping(uint256 => sNftPropertys) private _NftPropertys;

    constructor () ERC721("ForthBox Fighter NFT", "Fighter NFT") {
    }

    //---view---//
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseURIextended;
    }
    function bExistsID(uint256 tokenId) public view returns (bool) {
        return _exists(tokenId);
    }
    function getDegreeByTokenId(uint256 tokenId) external view returns(uint256){
        require(_exists(tokenId), "ERC721: Existent ID");
        return _NftPropertys[tokenId].value;
    }
    function getDegreeNameByTokenId(uint256 tokenId) external view returns(string memory){
        require(_exists(tokenId), "ERC721: Existent ID");
        return _degreeName[_NftPropertys[tokenId].value-1];
    }
    function getPropertiesByTokenIds(uint256[] calldata tokenIdArr) external view returns(uint256[] memory){
        for(uint256 i=0; i<tokenIdArr.length; ++i) {
            require(_exists(tokenIdArr[i]), "ERC721: Existent ID");
        }
        uint256[] memory tPropertyArr = new uint256[](uint256(2*tokenIdArr.length));
        uint256 ith=0;
        for(uint256 i=0; i<tokenIdArr.length; ++i) {
            tPropertyArr[ith] = tokenIdArr[i]; ith++;
            tPropertyArr[ith] =_NftPropertys[tokenIdArr[i]].value; ith++;
        }
        return tPropertyArr;
    }

    function tokenURI(uint256 tokenId) public view virtual override(ERC721) returns (string memory){
        require(_exists(tokenId), "FBXNFT: URI query for nonexistent token");
        string memory base = _baseURI();
        string memory imageAdress = _imageAdress[_NftPropertys[tokenId].value-1];
        string memory degreeName = _degreeName[_NftPropertys[tokenId].value-1];
        string memory json = string(abi.encodePacked(
                '{"name":"ForthBox Fighter NFT",',
                '"description":"Fighter NFT",',
                '"image":"',imageAdress, '",',
                '"base":"',base, '",',
                '"id":',Strings.toString(tokenId), ',',
                '"degree":',Strings.toString(_NftPropertys[tokenId].value), ','
                '"degreeName":"',degreeName, '"}'
                ));       
        return json;
    }

    //---write---//
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);
    }
    function _burn(uint256 tokenId) internal override(ERC721) {
        super._burn(tokenId);
        delete _NftPropertys[tokenId];
        return;
    }
    function burnNFT(uint256 tokenId) public returns (uint256) {
        require(_msgSender() == ownerOf(tokenId),"ForthBoxNFT: Only the owner of this Token could Burn It!");
        _burn(tokenId);
        return tokenId;
    }

    function transNFT(address _to,uint256 tokenId) public returns (uint256) {
        require(_msgSender() == ownerOf(tokenId),"ForthBoxNFT: Only the owner of this Token could transfer It!");
        _safeTransfer(_msgSender(),_to,tokenId,"");
        return tokenId;
    }
    function TransferNFTs(address[] calldata _tos, uint256[] calldata tokenIds) external returns (bool){
        require(_tos.length > 0);
        for(uint256 i=0; i < _tos.length ; i++){
            transNFT(_tos[i], tokenIds[i]);
        }
        return true;
    }

    //---write onlyOwner---//
    function mintNFTsTo(uint256 num,uint256 degree,address to) public onlyOwner {
        require(num>0, "ForthBoxNFT: num zero!");
        require(num<=1000, "ForthBoxNFT: num exceed 1000!");
        require(degree<=4, "ForthBoxNFT: degree exceed 4!");
        require(degree>=1, "ForthBoxNFT: degree less than 1!");
        require(mintTokenNum[degree-1]+num<=maxTokenNum[degree-1], "ForthBoxNFT: mintTokenNum exceed maxTokenNum!");
        mintTokenNum[degree-1] = mintTokenNum[degree-1]+num;

        for(uint256 i=0; i<num; ++i) {
            _mintNFT(degree,to);
        }
        return;
    }
    function mintNFTsToAddrs(address[] calldata _tos,uint256 degree) public onlyOwner {
        require(_tos.length > 0, "ForthBoxNFT: num zero!");
        require(_tos.length <= 1000, "ForthBoxNFT: num exceed 1000!");
        require(degree<=4, "ForthBoxNFT: degree exceed 4!");
        require(degree>=1, "ForthBoxNFT: degree less than 1!");
        require(mintTokenNum[degree-1]+_tos.length<=maxTokenNum[degree-1], "ForthBoxNFT: mintTokenNum exceed maxTokenNum!");
        mintTokenNum[degree-1] = mintTokenNum[degree-1]+_tos.length;

        for(uint256 i=0; i < _tos.length ; i++) {
            _mintNFT(degree,_tos[i]);
        }
        return;
    }
    function _mintNFT(uint256 degree,address to) internal returns (uint256) {
        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();
        _mint(to, newItemId);
        _NftPropertys[newItemId].value=degree;
        return newItemId;
    }
    function setImageAdress(string[] memory imageAdresses) external onlyOwner {
        require(imageAdresses.length == _imageAdress.length, "ERC721: length not equal");
        for(uint256 i=0; i<imageAdresses.length; ++i) {
            _imageAdress[i] = imageAdresses[i];
        }

    }

}