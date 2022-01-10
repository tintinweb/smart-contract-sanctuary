/**
 *Submitted for verification at Etherscan.io on 2022-01-10
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
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
library ECDSA {
  function recover(bytes32 hash, bytes memory signature)
    internal
    pure
    returns (address)
  {
    bytes32 r;
    bytes32 s;
    uint8 v;
    if (signature.length != 65) {
      return (address(0));
    }
    assembly {
      r := mload(add(signature, 0x20))
      s := mload(add(signature, 0x40))
      v := byte(0, mload(add(signature, 0x60)))
    }
    if (v < 27) {
      v += 27;
    }
    if (v != 27 && v != 28) {
      return (address(0));
    } else {
      // solium-disable-next-line arg-overflow
      return ecrecover(hash, v, r, s);
    }
  }

  /**
    * toEthSignedMessageHash
    * @dev prefix a bytes32 value with "\x19Ethereum Signed Message:"
    * and hash the result
    */
  function toEthSignedMessageHash(bytes32 hash)
    internal
    pure
    returns (bytes32)
  {
    return keccak256(
      abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
    );
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
        require( address(this).balance >= amount, "Address: insufficient balance");
        (bool success, ) = recipient.call{value: amount}("");
        require( success, "Address: unable to send value, recipient may have reverted");
    }
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }
    function functionCall( address target, bytes memory data, string memory errorMessage ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }
    function functionCallWithValue( address target, bytes memory data, uint256 value ) internal returns (bytes memory) {
        return functionCallWithValue( target, data, value, "Address: low-level call with value failed" );
    }
    function functionCallWithValue( address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require( address(this).balance >= value, "Address: insufficient balance for call" );
        require(isContract(target), "Address: call to non-contract");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall( target, data, "Address: low-level static call failed");
    }
    function functionStaticCall( address target, bytes memory data, string memory errorMessage ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall( target, data, "Address: low-level delegate call failed");
    }
    function functionDelegateCall( address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }
    function verifyCallResult( bool success, bytes memory returndata, string memory errorMessage) internal pure returns (bytes memory) {
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
library Counters {
    struct Counter {
        uint256 _value; // default: 0
    }
    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }
    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }
    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }
    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}
interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}
interface IERC721 is IERC165 {
    event Transfer( address indexed from, address indexed to, uint256 indexed tokenId );
    event Approval( address indexed owner, address indexed approved, uint256 indexed tokenId );
    event ApprovalForAll( address indexed owner, address indexed operator, bool approved );
    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function approve(address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function setApprovalForAll(address operator, bool _approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}
interface IERC721Receiver {
    function onERC721Received( address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}
interface IERC721Metadata is IERC721 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function tokenURI(uint256 tokenId) external view returns (string memory);
}
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
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
        require( owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require( owner != address(0), "ERC721: owner query for nonexistent token" );
        return owner;
    }
    function name() public view virtual override returns (string memory) {
        return _name;
    }
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require( _exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, tokenId.toString()))
                : "";
    }
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");
        require(_msgSender() == owner || isApprovedForAll(owner, _msgSender()), "ERC721: approve caller is not owner nor approved for all");
        _approve(to, tokenId);
    }
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId),"ERC721: approved query for nonexistent token");
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
    function transferFrom( address from, address to, uint256 tokenId) internal virtual {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId),"ERC721: transfer caller is not owner nor approved");
        _transfer(from, to, tokenId);
    }
    function safeTransferFrom(address from, address to, uint256 tokenId) internal virtual {
        safeTransferFrom(from, to, tokenId, "");
    }
    function safeTransferFrom( address from, address to, uint256 tokenId, bytes memory _data) internal virtual {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }
    function _safeTransfer( address from, address to, uint256 tokenId, bytes memory _data) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data),"ERC721: transfer to non ERC721Receiver implementer");
    }
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner ||
            getApproved(tokenId) == spender ||
            isApprovedForAll(owner, spender));
    }
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }
    function _safeMint( address to, uint256 tokenId,bytes memory _data) internal virtual {
        _mint(to, tokenId);
        require(_checkOnERC721Received(address(0), to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");
        _beforeTokenTransfer(address(0), to, tokenId);
        _balances[to] += 1;
        _owners[tokenId] = to;
        emit Transfer(address(0), to, tokenId);
    }
    function _transfer( address from, address to, uint256 tokenId) internal virtual {
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
    function _checkOnERC721Received( address from, address to, uint256 tokenId, bytes memory _data) private returns (bool) {
        if (to.isContract()) {
            try
                IERC721Receiver(to).onERC721Received(
                    _msgSender(),
                    from,
                    tokenId,
                    _data
                )
            returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert(
                        "ERC721: transfer to non ERC721Receiver implementer"
                    );
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
    function _beforeTokenTransfer( address from, address to, uint256 tokenId ) internal virtual {}
}
abstract contract ERC721URIStorage is ERC721 {
    using Strings for uint256;
    mapping(uint256 => string) private _tokenURIs;
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");
        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }
        return super.tokenURI(tokenId);
    }
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require( _exists(tokenId), "ERC721URIStorage: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }
}
abstract contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
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
        require( newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }
    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}
// check balance and withdraw WETH
interface WETH{
    function transferFrom(address _from,address _to, uint _value) external returns (bool success);
    function balanceOf(address _owner) external returns (uint balance);
}
contract MusicLabs is ERC721, ERC721URIStorage, Ownable {
    address wethAddress;
    constructor(string memory tokenName, string memory tokenSymbol, address _weth) ERC721(tokenName, tokenSymbol) {
        wethAddress = _weth;
    }
    using ECDSA for bytes32;
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    uint256 NFT_PERCENT = 2;
    uint256 public newItemId;
    Counters.Counter private _tokenIds;
    Counters.Counter private _projectIds;
    struct tokenInfo {
        uint256 tokenId;
        address payable creator;
        address payable currentOwner;
        uint256 price;
        bool selling;
        address signer;
    }
    struct projectInfo {
        uint256 projectId;
        address payable creator;
        string metadata;
        string name;
        uint256 budget;
        uint256 startTime;
        uint256 endTime;
        uint256 fundsCollected;
    }
    struct createProjectData {
        string metadata;
        string name;
        uint256 budget;
        uint256 startTime;
        uint256 endTime;
    }
    struct Royalty {
        uint percent;
        string partnerType;
        address wallet;
    }
    struct createNftData {
        string metaData;
        address creator;
        uint quantity;
        uint freeCopies;
        uint secondaryRoyalty;
    }
    struct mintNftData {
        string metaData;
        address creator;
        uint freeTypes;
        uint paidTypes;
        uint256 tokenId;
    }
    mapping(uint256 => tokenInfo) public allTokensInfo;
    mapping(uint256 => projectInfo) public allProjectsInfo;
    mapping(uint256 => uint) public nftPaidAllowed;
    mapping(uint256 => uint) public nftPaidMinted;
    mapping(uint256 => uint) public nftFreeCopiesAllowed;
    mapping(uint256 => uint) public nftFreeCopiesMinted;
    mapping(uint256 => uint) public nftRoyaltiesNumber;
    mapping(uint256 => Royalty[]) public nftRoyalties;
    mapping(uint256 => uint) public nftSecondaryRoyalties;

    event NewNFT(uint256 indexed tokenId);
    event NewProject(uint256 indexed projectId);
    event mintedNFTs(uint[] freeTypesIds, uint[] paidTypesIds);
    event OfferAccepted(uint256 indexed tokenId,uint256 indexed price,address from,address to);
    modifier onlyNftOwner(uint256 tokenId) {
        require(ownerOf(tokenId) == msg.sender,"Not the owner");
        _;
    }
    modifier onlyProjectOwner(uint256 projectId) {
        projectInfo memory projectInfoById = allProjectsInfo[projectId];
        address creator = projectInfoById.creator;
        require(creator == msg.sender, "Not the project owner");
        _;
    }
    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }
    function getTokenOwner(uint256 _tokenId) public view returns (address) {
        return ownerOf(_tokenId);
    }
    function createNFT(createNftData memory _nftData, Royalty[] memory royalties, bytes32 hash, bytes memory signature) public {
        address signer = hash.recover(signature);
        // require(signer == msg.sender && _nftData.creator == msg.sender, "Invalid creator signature");
        _tokenIds.increment();
        uint256 newTokenId = _tokenIds.current();
        _mint(msg.sender, newTokenId);
        _setTokenURI(newTokenId, _nftData.metaData);
        tokenInfo memory newTokenInfo = tokenInfo(
            newTokenId,
            payable(msg.sender),
            payable(msg.sender),
            0,
            true,
            signer
        );
        nftPaidAllowed[newTokenId] = _nftData.quantity;
        nftFreeCopiesAllowed[newTokenId] = _nftData.freeCopies;
        nftRoyaltiesNumber[newTokenId] = royalties.length;
        for(uint x = 0; x < royalties.length; x++) {
            nftRoyalties[newTokenId].push(royalties[x]);
        }
        nftSecondaryRoyalties[newTokenId] = _nftData.secondaryRoyalty;
        allTokensInfo[newTokenId] = newTokenInfo;
        emit NewNFT(newTokenId);
    }
    function mintNFTs(mintNftData memory _nftData, bytes32 hash, bytes memory signature) public payable {
        address signer = hash.recover(signature);
        // require(signer == msg.sender && _nftData.creator == msg.sender, "Invalid creator signature");
        uint freeTypes = _nftData.freeTypes;
        uint paidTypes = _nftData.paidTypes;
        uint[] memory freeTypesIds = new uint[](freeTypes);
        uint[] memory paidTypesIds = new uint[](paidTypes);
        tokenInfo memory tokenInfoById = allTokensInfo[_nftData.tokenId];
        uint256 tokenPrice = tokenInfoById.price;
        uint256 tokensFees = tokenPrice.mul(paidTypes);
        if(paidTypes > 0 ) {
            require(msg.value >= tokensFees, "Amount sent is not suffecient");
            require(nftPaidAllowed[_nftData.tokenId] > nftPaidMinted[_nftData.tokenId] && nftPaidAllowed[_nftData.tokenId] >= nftPaidMinted[_nftData.tokenId]+paidTypes, "Paid copies not available");
        }
        if(freeTypes > 0 ) {
            require(nftFreeCopiesAllowed[_nftData.tokenId] > nftFreeCopiesMinted[_nftData.tokenId] && nftFreeCopiesAllowed[_nftData.tokenId] >= nftFreeCopiesMinted[_nftData.tokenId]+freeTypes, "Free copies not available");
        }
        
        for(uint x = 0; x < freeTypes; x++) {
            _tokenIds.increment();
            uint256 newTokenId = _tokenIds.current();
            _mint(_nftData.creator, newTokenId);
            _setTokenURI(newTokenId, _nftData.metaData);
            _transfer(_nftData.creator, msg.sender, newTokenId);
            tokenInfo memory newTokenInfo = tokenInfo(
                newTokenId,
                payable(_nftData.creator),
                payable(msg.sender),
                0,
                false,
                signer
            );
            freeTypesIds[x] = newTokenId;
            nftRoyaltiesNumber[newTokenId] = nftRoyaltiesNumber[_nftData.tokenId];
            nftRoyalties[newTokenId] = nftRoyalties[_nftData.tokenId];
            nftSecondaryRoyalties[newTokenId] = nftSecondaryRoyalties[_nftData.tokenId];
            allTokensInfo[newTokenId] = newTokenInfo;
        }
        for(uint x = 0; x < paidTypes; x++) {
            _tokenIds.increment();
            uint256 newTokenId = _tokenIds.current();
            _mint(_nftData.creator, newTokenId);
            _setTokenURI(newTokenId, _nftData.metaData);
            _transfer(_nftData.creator, msg.sender, newTokenId);
            tokenInfo memory newTokenInfo = tokenInfo(
                newTokenId,
                payable(_nftData.creator),
                payable(msg.sender),
                0,
                false,
                signer
            );
            paidTypesIds[x] = newTokenId;
            nftRoyaltiesNumber[newTokenId] = nftRoyaltiesNumber[_nftData.tokenId];
            nftRoyalties[newTokenId] = nftRoyalties[_nftData.tokenId];
            nftSecondaryRoyalties[newTokenId] = nftSecondaryRoyalties[_nftData.tokenId];
            allTokensInfo[newTokenId] = newTokenInfo;
        }
        emit mintedNFTs(freeTypesIds, paidTypesIds);
    }
    function transferRoyalties(uint256 tokensFees, Royalty[] memory nftRoyalty) internal {
        
    }
    function changeTokenPriceAndSelling(uint256 _tokenId, bool status, uint256 _newPrice) external onlyNftOwner(_tokenId) {
        tokenInfo memory tokenInfoById = allTokensInfo[_tokenId];
        tokenInfoById.selling = status;
        tokenInfoById.price = _newPrice;
        allTokensInfo[_tokenId] = tokenInfoById;
    }
    function buyNFT(uint256 tokenId, address owner, bytes32 hash, bytes memory signature) external payable {
        address signer = hash.recover(signature);
        // require(signer == msg.sender, "Invalid User signature");
        tokenInfo memory tokenInfoById = allTokensInfo[tokenId];
        require(tokenInfoById.selling, "NFT not available for sale");
        _transfer(owner, msg.sender, tokenId);
        tokenInfoById.currentOwner = payable(msg.sender);
        allTokensInfo[tokenId] = tokenInfoById;
        uint256 twoPoint5P = calculatePercentValue(msg.value, NFT_PERCENT);
        uint256 amountToTransfer = msg.value-twoPoint5P;
        transferwethToOwner(msg.sender, amountToTransfer, owner);
    }
    function createProject(createProjectData memory _projectData, bytes32 hash, bytes memory signature ) public {
        _projectIds.increment();
        uint256 newProjectId = _projectIds.current();
        allProjectsInfo[newProjectId] = projectInfo(
            newProjectId,
            payable(msg.sender),
            _projectData.metadata,
            _projectData.name,
            _projectData.budget,
            _projectData.startTime,
            _projectData.endTime,
            0
        );
        emit NewProject(newProjectId);
    }
    function fundProject(uint256 _projectId, bytes32 hash, bytes memory signature ) public payable {
        require(msg.value > 0, "No payment sent");
        uint256 amount = msg.value;
        projectInfo memory projectInfoById = allProjectsInfo[_projectId];
        uint256 fundsCollected = projectInfoById.fundsCollected + amount;
        projectInfoById.fundsCollected = fundsCollected;
        allProjectsInfo[_projectId] = projectInfoById;
    }
    function withdrawProjectFunds(uint256 _projectId, bytes32 hash, bytes memory signature ) public payable onlyProjectOwner(_projectId) {
        
    }
    receive () payable external {}
    function updateNFTPercent(uint256 percent) external onlyOwner {
        NFT_PERCENT = percent;
    }
    function checkNFTPercent() public view returns (uint256) {
        return NFT_PERCENT;
    }
    function calculatePercentValue(uint256 total, uint256 percent) pure private returns(uint256) {
        uint256 division = total.mul(percent);
        uint256 percentValue = division.div(100);
        return percentValue;
    }
    function transferwethToOwner(address buyer, uint256 amount, address ownerOfNFT) private {
        WETH weth = WETH(wethAddress);
        uint256 balance = weth.balanceOf(buyer);
        require(balance >= amount, "insufficient balance" );
        weth.transferFrom(buyer, ownerOfNFT, amount);
    }
}