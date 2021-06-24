/**
 *Submitted for verification at Etherscan.io on 2021-06-24
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.1;

// import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
// import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
// import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
// import "./others/Helper.sol";


interface IERC721Receiver {
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

interface IERC721 is IERC165 {

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) external view returns (uint256 balance);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    function transferFrom(address from, address to, uint256 tokenId) external;

    function approve(address to, uint256 tokenId) external;

    function getApproved(uint256 tokenId) external view returns (address operator);

    function setApprovalForAll(address operator, bool _approved) external;
    
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}


contract Token721 is IERC721 {
    
    string private _symbol;
    string private  _name;
    
    mapping(address => uint) private tokenCount;
    mapping(uint => address) private tokenOwner;
    mapping(uint => address) private tokenApproved;
    mapping(address => mapping(address => bool)) private ownerOperator;
    
    constructor() {
        mint(msg.sender, 1);
        mint(msg.sender, 2);
        
        // _name = "ERC721Token";
        // _symbol = "ERC721T";
        // for(uint i=0; i<ids.length; i++) {
        //     mint(creator, ids[i]);   
        // }
    }
    
    // constructor(address creator, uint[] memory ids) {
    //     _name = "ERC721Token";
    //     _symbol = "ERC721T";
    //     for(uint i=0; i<ids.length; i++) {
    //         mint(creator, ids[i]);   
    //     }
    // }
    
    function mint(address to, uint tokenId) public {
        require(to != address(0), "Token721: mint to the zero address");
        require(!tokenExists(tokenId), "Token721: token already minted");

        tokenCount[to] += 1;
        tokenOwner[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }
    
    function name() external view returns (string memory) {
        return _name;   
    }
    
    function symbol() external view returns (string memory) {
        return _symbol;
    }
    
    function balanceOf(address _owner) external view override returns (uint256) {
        require(_owner != address(0), "Token721: Cant calculate balance of address(0)");
        return tokenCount[_owner];
    }

    function ownerOf(uint256 _tokenId) public view override returns (address) {
        address owner = tokenOwner[_tokenId];
        require(owner != address(0), "Token721: Token not minted yet!");
        return owner;
    }

    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory data) public override {
        checkIfImplemented(_from, _to, _tokenId, data);
        transfer(_from, _to, _tokenId);
    }

    function safeTransferFrom(address _from, address _to, uint256 _tokenId) public override {
        checkIfImplemented(_from, _to, _tokenId, "");
        transfer(_from, _to, _tokenId);
    }

    function transferFrom(address _from, address _to, uint256 _tokenId) public override {
        transfer(_from, _to, _tokenId);
    }

    function approve(address _approved, uint256 _tokenId) public override {
        address owner = tokenOwner[_tokenId];
        require(msg.sender == owner || ownerOperator[owner][msg.sender], "Token721: Dont have permission to approve this token");
        require(tokenExists(_tokenId), "Token721: Token does not exist!");
        tokenApproved[_tokenId] = _approved;
        emit Approval(owner, _approved, _tokenId);
        
    }

    function setApprovalForAll(address _operator, bool _approved) public override {
        require(msg.sender != _operator, "Operator cannot set approval for all.");
        ownerOperator[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    function getApproved(uint256 _tokenId) public view override returns (address) {
        require(tokenExists(_tokenId), "Token does not exist!");
        return tokenApproved[_tokenId];
    }

    function isApprovedForAll(address _owner, address _operator) external view override returns (bool) {
        return ownerOperator[_owner][_operator];
    }
    
    function supportsInterface(bytes4 interfaceId) external view override returns (bool) {
        
    }

    function tokenExists(uint _tokenId) private view returns (bool) {
        return tokenOwner[_tokenId] != address(0);
    }    
    
    function transfer(address _from, address _to, uint256 _tokenId) private {
        require(_from != address(0), "Cannot send a token from address(0)");
        require(_to != address(0), "Cannot send a token to address(0)");
        require(validSender(_tokenId, _from), "Token721: Dont have permission to send this token.");
        
        tokenApproved[_tokenId] = address(0);
        emit Approval(_to, address(0), _tokenId);
        
        tokenOwner[_tokenId] = _to;
        tokenCount[_from] -= 1;
        tokenCount[_to] += 1;
        emit Transfer(_from, _to, _tokenId);
    }
    
    function validSender(uint _tokenId, address _owner) public view returns (bool) {
        return msg.sender == _owner || msg.sender == tokenApproved[_tokenId] || ownerOperator[_owner][msg.sender];
    }
    
    function checkIfImplemented(address _from, address _to, uint256 _tokenId, bytes memory _data) private {
        if (isContract(_to)) {
            IERC721Receiver receiver = IERC721Receiver(_to);
            receiver.onERC721Received(_from, _to, _tokenId, _data);
        }
    
    }
    
    function isContract(address _addr) private view returns (bool) {
        uint32 size;
        assembly {
            size := extcodesize(_addr)
        }
        return (size > 0);
    }    
    
}