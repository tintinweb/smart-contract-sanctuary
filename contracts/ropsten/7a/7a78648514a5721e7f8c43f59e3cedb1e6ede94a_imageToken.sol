/**
 *Submitted for verification at Etherscan.io on 2021-04-09
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.0 <0.5.0;
// import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/9b3710465583284b8c4c5d2245749246bb2e0094/contracts/token/ERC20/ERC20.sol";

/* SalmanToken : ST 
  developed by Salman Haider 
 */
 
interface ERC721 {
    function balanceOf(address _owner) external view returns (uint256);
    function ownerOf(uint256 _tokenId) external view returns (address);
}

contract imageToken is ERC721 {
    
    // Mapping from token ID to owner address
    mapping (uint256 => address) private _owners;
    // Mapping token count to owner address
    mapping (address => uint256) balances;
    
    mapping (uint256 => string) idToUri;
    uint256 _totalSupply;
    string private _name;
    string private _symbol; 
    
    
    // To assign the No. of tokens to the contract deploying address
    constructor(uint256 _tokenId, string memory uri) public {
        
        _totalSupply = 2 ** 256 - 1;
        _name = "miniCrypto";
        _symbol = "mC";
        balances[msg.sender] = _totalSupply;
        
        mint(msg.sender, _tokenId, uri);
        mint(msg.sender, _tokenId+1, uri);
        mint(msg.sender, _tokenId+2, uri);
        mint(msg.sender, _tokenId+3, uri);
        mint(msg.sender, _tokenId+4, uri);
        mint(msg.sender, _tokenId+5, uri);
        mint(msg.sender, _tokenId+6, uri);
        mint(msg.sender, _tokenId+7, uri);
        mint(msg.sender, _tokenId+8, uri);
        mint(msg.sender, _tokenId+9, uri);
        mint(msg.sender, _tokenId+10, uri);
        mint(msg.sender, _tokenId+11, uri);
        mint(msg.sender, _tokenId+12, uri);
        mint(msg.sender, _tokenId+13, uri);
        mint(msg.sender, _tokenId+14, uri);
        mint(msg.sender, _tokenId+15, uri);
        mint(msg.sender, _tokenId+16, uri);
        mint(msg.sender, _tokenId+17, uri);
        mint(msg.sender, _tokenId+18, uri);
        mint(msg.sender, _tokenId+19, uri);
        mint(msg.sender, _tokenId+20, uri);
    }
    // To get the name of the token
    function name() public view returns (string) {
        return _name;
    }
    // To get the symbol of the token
    function symbol() public view returns (string) {
        return _symbol;
    }
    
    // To get the total tokens regardless of the owner
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }
    
     // To get the token balance of a specific account using the address 
    function balanceOf(address _tokenOwner) public view returns (uint256 balance){
        return balances[_tokenOwner];
    }

    function ownerOf(uint256 _tokenId) external view returns (address){
        require(_owners[_tokenId] != address(0), "No Token/Owner found");
        return _owners[_tokenId];
    }
    
    function _mint(address _receipient, uint256 _tokenId, string memory _uri) internal {
        require( _receipient != address(0), "_receipient Address is Zero" );
       // require(_owners[_tokenId] != address(0), "Owner Address is Zero") ;

         balances[_receipient] += 1;
        _owners[_tokenId] = _receipient;
        _setTokenUri(_tokenId, _uri);
    }
    function mint(address _receipient, uint256 _tokenId, string memory _uri) public {
        _mint(_receipient, _tokenId, _uri);
    }
    
    function _setTokenUri(uint256 _tokenId, string memory _uri) internal {
        idToUri[_tokenId] = _uri;
    }
    
    function getTokenURI(uint256 _tokenId) external view returns (string memory){
        return idToUri[_tokenId];
    }

    
    
}