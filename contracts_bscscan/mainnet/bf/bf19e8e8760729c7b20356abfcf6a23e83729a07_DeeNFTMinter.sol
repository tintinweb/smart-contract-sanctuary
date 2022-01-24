/**
 *Submitted for verification at BscScan.com on 2022-01-24
*/

/**
 *Submitted for verification at BscScan.com on 2021-10-14
*/

pragma solidity ^0.5.10;

interface ERC721Interface {
  function transferFrom(address _from, address _to, uint256 _tokenId) external ;
  function ownerOf(uint256 _tokenId) external view returns (address);
  function approve(address _to, uint256 _tokenId) external;
  function mint(address player,uint256 tokenId) external returns (uint256);
}

contract Ownable {
  address payable public owner;

  constructor () public{
    owner = msg.sender;
  }

  modifier onlyOwner()  {
    require(msg.sender == owner);
    _;
  }

  function transferOwnership(address payable newOwner) public onlyOwner {

    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }
}

contract DeeNFTMinter is Ownable {
    
    // dee nft contract
    address public nftContract;

    //This pool stores the amount of NFTs generated for each role and level
    mapping (uint => uint) public pool;

    mapping (uint256=>address) public tokenIdHolders;

    event CreateNFT(
        uint indexed _character,
        uint indexed _level,
        uint _amount,
        address _toAddress
    );

    constructor(address _nftContract) public{
        nftContract = _nftContract;
    }

    function initPoolStartIndex(uint character, uint level, uint amount) public onlyOwner{
        uint key = 10000 + character * 100 + level;
        pool[key] = amount;
    }

    function mintNFT(uint character, uint level, uint amount,address toAddress) public onlyOwner {

        for(uint i=0;i<amount;i++){

            uint key = 10000 + character * 100 + level;
            uint amountIdx = pool[key];

            // 30102090100000004 
            uint256 nftId = 30100000000000000 + 1000000000000 * character + 10000000000 * level + amountIdx;
            ERC721Interface(nftContract).mint(toAddress,nftId);

            //modify storage
            pool[key] = amountIdx + 1;

            emit CreateNFT(character,level,amount,toAddress);
        }
    }
}