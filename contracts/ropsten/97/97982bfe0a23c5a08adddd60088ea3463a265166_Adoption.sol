pragma solidity ^0.4.19;
contract Adoption {
  address ceoAddress = 0x1AEA2d3709bB7CFf5326a4Abc44c45Aa2629C626;
  struct Pepe {
    address owner;
    uint256 price;
   
  }

  Pepe[16] data;

  function Adoption() public {
    for (uint i = 0; i < 16; i++) {
     
      data[i].price = 10000000000000000;
      data[i].owner = msg.sender;
    }
  }

  function returnEth(address oldOwner, uint256 price) public payable {
    oldOwner.transfer(price);
  }

  function gimmeTendies(address, uint256 price) public payable {
    ceoAddress.transfer(price);
  }
  // Adopting a pet
  function adopt(uint pepeId) public payable returns (uint, uint) {
    require(pepeId >= 0 && pepeId <= 15);
    if ( data[pepeId].price == 10000000000000000 ) {
      data[pepeId].price = 20000000000000000;
    } else {
      data[pepeId].price = data[pepeId].price * 2;
    }
    
    require(msg.value >= data[pepeId].price * uint256(1));
    returnEth(data[pepeId].owner,  (data[pepeId].price / 10) * (9)); 
    gimmeTendies(ceoAddress, (data[pepeId].price / 10) * (1));
    data[pepeId].owner = msg.sender;
    return (pepeId, data[pepeId].price);
    //return value;
  }

  function getAdopters() external view returns (address[], uint256[]) {
    address[] memory owners = new address[](16);
    uint256[] memory prices =  new uint256[](16);
    for (uint i=0; i<16; i++) {
      owners[i] = (data[i].owner);
      prices[i] = (data[i].price);
    }
    return (owners,prices);
  }
  
}