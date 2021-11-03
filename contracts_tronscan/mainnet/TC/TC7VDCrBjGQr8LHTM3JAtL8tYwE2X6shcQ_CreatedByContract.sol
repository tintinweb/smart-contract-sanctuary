//SourceUnit: test.sol

pragma solidity ^0.6.0;

interface ITRC20 {
    function balanceOf(address who) external view returns (uint256);
}

contract Market{

  string private name;
  ITRC20 private NftInstance;

  mapping(uint256 => address) private owners;

  event NewOwner(address indexed owner,uint256 indexed tokenId);


  constructor (string memory _name, address _NftAddress) public {
    name = _name;
    NftInstance = ITRC20(_NftAddress);
   }

   function getNftContract() public view returns(address){
     return address(NftInstance);
   }
   function getName() public view returns(string memory){
     return name;
   }
   function getOwner(uint256 tokenId) public view returns(address){
     return owners[tokenId];
   }
   function setOwner(uint256 tokenId,address owner) public{
    owners[tokenId] = owner;
    emit NewOwner(owner,tokenId);
   }


}

contract factory{

  event AddToken(address indexed owner,string name,address indexed marketAddress);
  mapping(address => address) public tokens;


  constructor () public {

   }

   function getMarketName(address token) public view returns(string memory){
     return Market(tokens[token]).getName();
   }

   function addToken (string memory _name, address token) public {

     Market marketAddress = new Market(_name,token);

     tokens[token] = address(marketAddress);

     emit AddToken(token,_name,address(marketAddress));
   }



   fallback () external payable { }

   receive() external payable { }

   function kill() public {
     selfdestruct(msg.sender);
   }

}