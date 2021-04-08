/**
 *Submitted for verification at Etherscan.io on 2021-04-08
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
    constructor(string memory name, string memory symbol, uint256 total) public {
        
        _totalSupply = total;
        _name = name;
        _symbol = symbol;
        balances[msg.sender] = _totalSupply;
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
        require(_owners[_tokenId] != address(0));
        return _owners[_tokenId];
    }
    
    function _mint(address _receipient, uint256 _tokenId) internal {
        // require( (_receipient != address(0)) && (_owners[_tokenId] != address(0)) );

         balances[_receipient] += 1;
        _owners[_tokenId] = _receipient;
    }
    function mint(address _receipient, uint256 _tokenId) public {
        _mint(_receipient, _tokenId);
    }
    
    function _setTokenUri(uint256 _tokenId, string memory _uri) public {
        idToUri[_tokenId] = _uri;
    }
    
    function getTokenURI(uint256 _tokenId) external view returns (string memory){
        return idToUri[_tokenId];
    }

    
    
}