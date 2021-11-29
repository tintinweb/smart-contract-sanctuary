/**
 *Submitted for verification at polygonscan.com on 2021-11-28
*/

pragma solidity ^0.5.0;

contract Decentragram {
  string public name;
  uint public imageCount = 0;
  mapping(uint => Image) public images;

  struct Image {
    uint id;
    string hash;
    string description;
    uint tipAmount;
    address payable author;
  }

  event ImageCreated(
    uint id,
    string hash,
    string description,
    uint tipAmount,
    address payable author
  );

  event ImageTipped(
    uint id,
    string hash,
    string description,
    uint tipAmount,
    address payable author
  );

  constructor() public {
    name = "Decentragram";
  }

  function uploadImage(string memory _imgHash, string memory _description) public {
    //+-Make sure the image hash exists:_
    require(bytes(_imgHash).length > 0);
    
    //+-Make sure image description exists:_
    require(bytes(_description).length > 0);

    //+-Make sure uploader address exists:_
    require(msg.sender!=address(0));

    //+-Increment image id:_
    imageCount ++;

    //+-Add Image to the contract:_
    images[imageCount] = Image(imageCount, _imgHash, _description, 0, msg.sender);

    //+-Trigger an event:_
    emit ImageCreated(imageCount, _imgHash, _description, 0, msg.sender);
  }

  function tipImageOwner(uint _id) public payable {
    //+-Make sure the id is valid:_
    require(_id > 0 && _id <= imageCount);

    //+-Fetch the image:_
    Image memory _image = images[_id];

    //+-Fetch the author:_
    address payable _author = _image.author;

    //+-Pay the author by sending them Ether:_
    address(_author).transfer(msg.value);

    //+-Increment the tip amount:_
    _image.tipAmount = _image.tipAmount + msg.value;

    //+-Update the image:_
    images[_id] = _image;

    //+-Trigger an event:_
    emit ImageTipped(_id, _image.hash, _image.description, _image.tipAmount, _author);
  }
}