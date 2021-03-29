/**
 *Submitted for verification at Etherscan.io on 2021-03-29
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.10;

contract IaunToken721{
    address private ownerContract = msg.sender;
    modifier onlyOwner {
        require(ownerContract == msg.sender);
        _;
    }

    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);

    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);

    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);


    function mint(uint256 _tokenId, string memory _uri, address _to) onlyOwner external {}
    
    function getTokenURI(uint256 _tokenId) external view returns (string memory){}
    
    function balanceOf(address _owner) external view returns (uint256){}
    
    function ownerOf(uint256 _tokenId) public view returns (address){}
    
    function isApprovedForAll(address _owner, address _operator) public view returns (bool){}
    
    function approve(address to, uint256 tokenId) external {}
    
    function transferFrom(address _from, address _to, uint256 _tokenId) public{}
    
    function setApprovalForAll(address _operator, bool _approved) external{}
     
    function getApproved(uint256 _tokenId) external view returns (address){}
     
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory data) external{}
     
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external {}
}

contract IaunToken {
    
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    
    function totalSupply() public pure returns (uint256){}
    
    function balanceOf(address account) public view returns (uint256){}
    
    function transfer(address recipient, uint256 amount) public returns (bool){}
    
    function allowance(address _owner, address spender) public view returns (uint256){}
    
    function approve(address spender, uint256 amount) public returns (bool){}
    
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool){}

}

contract exchangeNFT {
    address private erc20 = 0x015467ca3Bd9560DC5856f9e161155194a6404af;
    address private erc721 = 0x0a7841973341578087FC115B8E1f699c6f25ed2A;
    
    IaunToken contractERC20 = IaunToken(erc20);
    IaunToken721 contractERC721 = IaunToken721(erc721);
    
    event Exchange(address indexed _from, address indexed _to, uint256 _tokenId);
    
    mapping(uint256 => uint256) price;
    
    function getPrice(uint256 _tokenId) external view returns (uint256){
        return price[_tokenId];
    }
    
    function setPrice(uint256 _tokenId, uint256 tokenPrice) external {
        require ( msg.sender == contractERC721.ownerOf(_tokenId) );
        price[_tokenId] = tokenPrice;
    }
    
    function buyNFT(uint256 _tokenId) external {
        uint256 tokenPrice = price[_tokenId];
        address recipient = msg.sender;
        require( tokenPrice <= contractERC20.balanceOf(recipient) );
        address owner = contractERC721.ownerOf(_tokenId);
        
        contractERC20.transferFrom(recipient, owner, tokenPrice);
        contractERC721.transferFrom(owner, recipient, _tokenId);
        
        emit Exchange(owner, recipient, _tokenId);
    }
}