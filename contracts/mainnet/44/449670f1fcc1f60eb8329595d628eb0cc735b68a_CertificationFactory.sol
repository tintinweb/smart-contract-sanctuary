/**
 *Submitted for verification at Etherscan.io on 2021-05-24
*/

/// SPDX-License-Identifier: MIT
/// Presented by LexDAO LLC
/// @notice Minimal Certification NFT.
pragma solidity 0.8.4;

contract Certification {
    address public governance;
    uint256 public totalSupply;
    string  public baseURI;
    string  public details;
    string  public name;
    string  public symbol;
    
    mapping(address => uint256) public balanceOf;
    mapping(uint256 => address) public ownerOf;
    mapping(uint256 => string) public tokenURI;
    mapping(bytes4 => bool) public supportsInterface; // ERC-165 
    
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event GovTokenURI(uint256 indexed tokenId, string tokenURI);
    event TransferGovernance(address indexed governance);
    event UpdateBaseURI(string baseURI);
    
    constructor(
        address _governance,
        string memory _baseURI, 
        string memory _details, 
        string memory _name, 
        string memory _symbol
    ) {
        governance = _governance;
        baseURI = _baseURI;
        details = _details; 
        name = _name; 
        symbol = _symbol;  
        supportsInterface[0x80ac58cd] = true; // ERC-721 
        supportsInterface[0x5b5e139f] = true; // METADATA
    }

    modifier onlyGovernance {
        require(msg.sender == governance, '!governance');
        _;
    }
    
    function burn(address from, uint256 tokenId) external {
        require(from == ownerOf[tokenId] || from == governance, '!owner||!governance');
        balanceOf[from]--; 
        ownerOf[tokenId] = address(0);
        tokenURI[tokenId] = "";
        emit Transfer(from, address(0), tokenId); 
    }
    
    function mint(address to, string calldata customURI) external onlyGovernance { 
        string memory _tokenURI; 
        bytes(customURI).length > 0 ? _tokenURI = customURI : _tokenURI = baseURI;
        totalSupply++;
        uint256 tokenId = totalSupply;
        balanceOf[to]++;
        ownerOf[tokenId] = to;
        tokenURI[tokenId] = _tokenURI;
        emit Transfer(address(0), to, tokenId);
    }

    function govTokenURI(uint256 tokenId, string calldata _tokenURI) external onlyGovernance {
        require(tokenId <= totalSupply, '!exist');
        tokenURI[tokenId] = _tokenURI;
        emit GovTokenURI(tokenId, _tokenURI);
    }
    
    function govTransferFrom(address from, address to, uint256 tokenId) external onlyGovernance {
        require(from == ownerOf[tokenId], 'from!=owner');
        balanceOf[from]--; 
        balanceOf[to]++; 
        ownerOf[tokenId] = to;
        emit Transfer(from, to, tokenId); 
    }

    function transferGovernance(address _governance) external onlyGovernance {
        governance = _governance;
        emit TransferGovernance(_governance);
    }
    
    function updateBaseURI(string calldata _baseURI) external onlyGovernance {
        baseURI = _baseURI;
        emit UpdateBaseURI(_baseURI);
    }
}

contract CertificationFactory {
    event DeployCertification(Certification indexed certification, address indexed governance);
    
    function deployCertification(
        address _governance, 
        string calldata _baseURI, 
        string calldata _details, 
        string calldata _name, 
        string calldata _symbol
    ) external returns (Certification certification) {
        certification = new Certification(
            _governance, 
            _baseURI, 
            _details, 
            _name, 
            _symbol);
        emit DeployCertification(certification, _governance);
    }
}