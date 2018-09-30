pragma solidity ^0.4.24;

contract ERC20 {

  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract DocumentStore{
    
    ERC20 kareTestToken;
    mapping(address => string) public docs;
    uint256 storeFee = 1000000000000000;
    
    constructor(address tokenContract) public {
        kareTestToken = ERC20(tokenContract);
    }
    
    function updateStoreFee(uint256 newStoreFee) public {
        storeFee = newStoreFee;
    }

    function storeDoc(string docHash) public {
        require(kareTestToken.transferFrom(msg.sender, address(this), storeFee));
        docs[msg.sender] = docHash;
    }
    
    function getDoc(address owner) public view returns (string){
        return docs[owner];
    }
    
}