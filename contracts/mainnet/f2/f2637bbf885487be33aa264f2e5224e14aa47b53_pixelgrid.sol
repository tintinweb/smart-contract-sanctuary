pragma solidity 0.4.21;

contract pixelgrid {
    uint8[1000000] public pixels;
    address public manager;
    address public owner = 0x668d7b1a47b3a981CbdE581bc973B047e1989390;
    event Updated();
    function pixelgrid() public {
        manager = msg.sender;
    }

    function setColors(uint32[] pixelIndex, uint8[] color) public payable  {
      require(pixelIndex.length < 256);
      require(msg.value >= pixelIndex.length * 0.0001 ether || msg.sender == manager);
      require(color.length == pixelIndex.length);
    for (uint8 i=0; i<pixelIndex.length; i++) {
    pixels[pixelIndex[i]] = color[i];
    }
    emit Updated();

    }


    function getColors(uint32 start) public view returns (uint8[50000] ) {
      require(start < 1000000);
        uint8[50000] memory partialPixels;
           for (uint32 i=0; i<50000; i++) {
               partialPixels[i]=pixels[start+i];
           }

      return partialPixels;
    }

    function collectFunds() public {
         require(msg.sender == manager || msg.sender == owner);
         address contractAddress = this;
         owner.transfer(contractAddress .balance);
    }

    function () public payable {
      // dont receive ether via fallback
  }
}