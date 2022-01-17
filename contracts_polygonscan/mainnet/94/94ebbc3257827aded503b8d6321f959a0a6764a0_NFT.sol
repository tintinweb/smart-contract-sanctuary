/**
 *Submitted for verification at polygonscan.com on 2022-01-17
*/

pragma solidity >=0.4.22;

contract NFT {


  mapping(string => address) internal hashToOwner;
  mapping(string => address) internal hashToOwnerRenter;

  mapping(address => string[]) public addressMapArray;
  mapping(string => string) internal hashToMetaHash;
  mapping(string => uint) internal hashToPrice;
  mapping(address => uint) internal addressToWallet;
  mapping(string => uint) internal hashToPriceForRent;
  mapping(string => uint) internal hashToRentedTime;

  constructor(){
    addressToWallet[msg.sender] = 10**12;
  }



  function getOwner(string memory hash) public view returns(address) {

      if(block.timestamp <= hashToRentedTime[hash] ){
        return hashToOwnerRenter[hash];
      }

      return hashToOwner[hash];

  }


  function setOwner(string memory hash) internal{
      
      hashToOwner[hash] = msg.sender;

  }


  function mint(string memory modelHash , string memory metaDataHash) public{
          
        require(getOwner(modelHash) == address(0),"already minted");
        setOwner(modelHash);
        hashToMetaHash[modelHash] = metaDataHash;
        addressMapArray[msg.sender].push(metaDataHash);

  }



  function ownerPortfolio(address  address_ , uint  index) public view returns(string memory) {

      return addressMapArray[address_][index];

  }

  function getMetaData(string memory hash) public view returns(string memory){
    
    return hashToMetaHash[hash];

  }

  function setPrice(string memory modelHash, uint price) public{

    require(hashToOwner[modelHash] == msg.sender ,"You are not owner");
    require(getOwner(modelHash) == msg.sender ,"You are not owner");
    // require(price != 0 , "Price should be > 0");
    hashToPrice[modelHash] = price;

  }



 function getPrice(string memory hash) public view returns(uint){

    return hashToPrice[hash];

  }

  function buySaleItem(string memory modelHash,uint bidAmount) public {

    require(getPrice(modelHash) != 0 , "Item not on sale");
    require(bidAmount >= getPrice(modelHash) , "Bid amount should be greater than listed price");
    transferCoin(bidAmount , getOwner(modelHash));

    // Change Owner
    setOwner(modelHash);
    addressMapArray[msg.sender].push(hashToMetaHash[modelHash]);

    setPrice(modelHash,0);


  }


  function setPriceForRent(string memory modelHash, uint price,uint timeForRent) public{

    require(hashToOwner[modelHash] == msg.sender ,"You are not owner");
    require(getOwner(modelHash) == msg.sender ,"You are not owner");


    hashToPriceForRent[modelHash] = price;
    hashToRentedTime[modelHash] = block.timestamp + timeForRent;
    hashToOwnerRenter[modelHash] = msg.sender;
  }


  function getRentableItem(string memory modelHash,uint bidAmount) public {

    require(getRentPrice(modelHash) != 0 , "Item not for rent");
    require(bidAmount >= hashToPriceForRent[modelHash] , "Bid amount should be greater than listed price for rent");
    transferCoin(bidAmount , getOwner(modelHash));
    addressMapArray[msg.sender].push(hashToMetaHash[modelHash]);
    hashToOwnerRenter[modelHash] = msg.sender;
    hashToPriceForRent[modelHash] = 0;


  }



 function getRentPrice(string memory hash) public view returns(uint){

    return hashToPriceForRent[hash];

  }



  function getBalance(address address_) public view returns(uint){

    return addressToWallet[address_];

  }

  function transferCoin(uint amount , address recieverAddress) public {

    require(addressToWallet[msg.sender] >= amount , " Wallet dosen't have enough balance");
    addressToWallet[msg.sender] = addressToWallet[msg.sender] - amount;
    addressToWallet[recieverAddress] = addressToWallet[recieverAddress] + amount;

  }


}