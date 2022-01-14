pragma solidity ^0.8.1;

// This already includes ERC721 and the ownable files
import './721Meta.sol';
// file structure
// 721 -> Meta
// Ownable -> Meta
// Meta -> NFT

contract NFT is ERC721Metadata {
    uint fee =             30000000000000;
    uint weiToEther = 1000000000000000000;
    uint paidBalance = 0;
    // wei
    mapping (address => uint) ethBalances;
    mapping (address => mapping (address => mapping (uint => mapping(uint => uint)))) sales;

    function mintNFT(address _owner, uint tokenId) public onlyOwner {
        require(nftToOwner[tokenId] == address(0), "Id already used");
        nftToOwner[tokenId] = _owner;
        ownerToBalance[_owner]++;
        emit Transfer(address(0), _owner, tokenId);
    }

    function burnNFT(uint _tokenId) public onlyOwner {
        address oldOwner = nftToOwner[_tokenId];
        ownerToBalance[oldOwner]--;
        nftToOwner[_tokenId] = address(0);
        emit Transfer(oldOwner, address(0), _tokenId);
    }

    function withdraw(address _owner) public onlyOwner returns (bytes memory) {
        (bool sent, bytes memory data) = _owner.call{value: address(this).balance}("");
        require(sent);
        return data;
    }

    function updateFee(uint _fee) onlyOwner public {
        fee = _fee;
    }

    // Copy paste - add commision
    function _transfer(address _from, address _to, uint _tokenId) internal override {
        require(_from == nftToOwner[_tokenId]);
        require(_to != address(0));
        require(msg.value >= fee, "Tranaction fee not paid");
        // from is the owner, as of two lines ago
        require(msg.sender == _from || msg.sender == tokenApprovedAddress[_tokenId] || authorizedOperators[_from][msg.sender]);
        emit Transfer(_from, _to, _tokenId);
        emit Approval(_from, address(0), _tokenId);
        ownerToBalance[_from]--;
        ownerToBalance[_to]++;
        nftToOwner[_tokenId] = _to;
        tokenApprovedAddress[_tokenId] = address(0);
    }

    function sellNFT(address _from, address _to, uint _tokenId, uint _price) public {
        require(_from == nftToOwner[_tokenId]);
        require(_to != address(0));
        // from is the owner, as of two lines ago
        require(msg.sender == _from || msg.sender == tokenApprovedAddress[_tokenId] || authorizedOperators[_from][msg.sender]);
        sales[_from][_to][_tokenId][_price] = 1;
    }

    function buyNFT(address _from, address _to, uint _tokenId, uint _price) public {
        require(ethBalances[_to] >= _price * weiToEther, "Insufficient funds");
        require(msg.sender == _to);
        sales[_from][_to][_tokenId][_price] = 2;
    }

    function finishSale(address _from, address _to, uint _tokenId, uint _price) public {
        require(ethBalances[_to] >= _price * weiToEther, "Insufficient funds");
        require(_from == nftToOwner[_tokenId]);
        require(_to != address(0));
        uint s = sales[_from][_to][_tokenId][_price];
        require(s == 1 || s == 2, "No existing request");
        s == 1 ? 
        require(msg.sender == _to)
        : 
        require(msg.sender == _from || msg.sender == tokenApprovedAddress[_tokenId] || authorizedOperators[_from][msg.sender], "No access");
        (bool sent, bytes memory data) = _from.call{value: _price}("");
        require(sent, "Failed to send Ether");
        safeTransferFrom(_from, _to, _tokenId);
    }

    function deposit() public payable {
        ethBalances[msg.sender] += msg.value;
    }

    function withdraw() public returns (bytes memory) {
        uint val = ethBalances[msg.sender];
        ethBalances[msg.sender] = 0;
        (bool sent, bytes memory data) = msg.sender.call{value: val}("");
        require(sent);
        return data;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import './721.sol';
import './access.sol';

contract ERC721Metadata is ERC721, Ownable {
    string private _name = 'Contract';
    string private _symbol = 'NFT';
    mapping (uint => string) metadata;

    function name() external view returns (string memory) {
        return _name;
    }

    function symbol() external view returns (string memory) {
        return _symbol;
    }

    function tokenURI (uint _tokenId) external view returns (string memory) {
        return metadata[_tokenId];
    }

    function setName(string memory _newName) external onlyOwner {
        _name = _newName;
    }

    function setSymbol(string memory _newSymbol) external onlyOwner {
        _symbol = _newSymbol;
    }

    function setTokenURI(string memory _URI, uint _tokenId) external {
        require(msg.sender == nftToOwner[_tokenId] || msg.sender == tokenApprovedAddress[_tokenId] || authorizedOperators[nftToOwner[_tokenId]][msg.sender]);
        metadata[_tokenId] = _URI;
    }

    // ERC165
    function supportsInterface(bytes4 interfaceID) public override pure returns (bool) {
        return super.supportsInterface(interfaceID) || interfaceID == 0x5b5e139f;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import './165.sol';
import '../interfaces/I721Wallet.sol';
// import '../interfaces/I721.sol';

contract ERC721 is ERC165 {
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    mapping (address => uint) ownerToBalance;
    mapping (uint => address) nftToOwner;
    mapping (uint => address) tokenApprovedAddress;
    // like a array, but easier to code
    // authorizedOperators[owner][operator]
    mapping (address => mapping(address => bool)) authorizedOperators;

    function supportsInterface(bytes4 interfaceID) public virtual override pure returns (bool) {
        return interfaceID == 0x80ac58cd || super.supportsInterface(interfaceID);
    }
    
    function balanceOf(address _owner) external view returns (uint256) {
        require(_owner != address(0), "ERC721: 0 address is invalid");
        return ownerToBalance[_owner];
    }

    function ownerOf(uint _tokenId) external view returns (address) {
        require(_tokenId != 0, "ERC721: 0 is invalid");
        require(_tokenId != 0, "ERC721: 0 address is invalid");
        return nftToOwner[_tokenId];
    }

    function safeTransferFrom(address _from, address _to, uint _tokenId, bytes memory _data) public payable {
        _transfer(_from, _to, _tokenId);
        _ERC721Recieved(_from, _to, _tokenId, _data);
    }

    function safeTransferFrom(address _from, address _to, uint _tokenId) public payable {
        // less repitive
        safeTransferFrom(_from, _to, _tokenId, "");
    }

    function transferFrom(address _from, address _to, uint256 _tokenId) external payable {
        _transfer(_from, _to, _tokenId);
        // one line function to transfer nfts
    }

    function approve(address _approved, uint256 _tokenId) external {
        require(msg.sender == nftToOwner[_tokenId] || authorizedOperators[nftToOwner[_tokenId]][msg.sender]);
        tokenApprovedAddress[_tokenId] = _approved;
        emit Approval(msg.sender, _approved, _tokenId);
    }

    function setApprovalForAll(address _operator, bool _approved) external {
        authorizedOperators[msg.sender][_operator] = true;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    function getApproved(uint256 _tokenId) external view returns (address) {
        require(nftToOwner[_tokenId] == address(0));
        return tokenApprovedAddress[_tokenId];
    }

    function isApprovedForAll(address _owner, address _operator) external view returns (bool) {
        return authorizedOperators[_owner][_operator];
    }

    function _transfer(address _from, address _to, uint _tokenId) virtual internal {
        require(_from == nftToOwner[_tokenId]);
        require(_to != address(0));
        // from is the owner, as of two lines ago
        require(msg.sender == _from || msg.sender == tokenApprovedAddress[_tokenId] || authorizedOperators[_from][msg.sender]);
        emit Transfer(_from, _to, _tokenId);
        emit Approval(_from, address(0), _tokenId);
        ownerToBalance[_from]--;
        ownerToBalance[_to]++;
        nftToOwner[_tokenId] = _to;
        tokenApprovedAddress[_tokenId] = address(0);
    }

    function _ERC721Recieved(address _from, address _to, uint _tokenId, bytes memory _data) private returns (bool) {
        if (_to.code.length > 0){
            // call the interface
            bytes4 cfunc = ERC721TokenReceiver(_to).onERC721Received(msg.sender, _from, _tokenId, _data);
            require(cfunc == bytes4(keccak256("onERC721Received(address,address,uint256,bytes)")),
                "ERC721: Invalid contract receiving NFT.");
            return true;
        } else {
            return true;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _owner = msg.sender;
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
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '../interfaces/I165.sol';

contract ERC165 {
    function supportsInterface(bytes4 interfaceID) public virtual pure returns (bool) {
        return
          interfaceID == type(IERC165).interfaceId;
    }
}

pragma solidity ^0.8.1;
/// @dev Note: the ERC-165 identifier for this interface is 0x150b7a02.
interface ERC721TokenReceiver {
    /// @notice Handle the receipt of an NFT
    /// @dev The ERC721 smart contract calls this function on the recipient
    ///  after a `transfer`. This function MAY throw to revert and reject the
    ///  transfer. Return of other than the magic value MUST result in the
    ///  transaction being reverted.
    ///  Note: the contract address is always the message sender.
    /// @param _operator The address which called `safeTransferFrom` function
    /// @param _from The address which previously owned the token
    /// @param _tokenId The NFT identifier which is being transferred
    /// @param _data Additional data with no specified format
    /// @return `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
    ///  unless throwing
    function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes memory _data) external returns(bytes4);
}

pragma solidity ^0.8.0;

interface IERC165 {
    /// @notice Query if a contract implements an interface
    /// @param interfaceID The interface identifier, as specified in ERC-165
    /// @dev Interface identification is specified in ERC-165. This function
    ///  uses less than 30,000 gas.
    /// @return `true` if the contract implements `interfaceID` and
    ///  `interfaceID` is not 0xffffffff, `false` otherwise
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}