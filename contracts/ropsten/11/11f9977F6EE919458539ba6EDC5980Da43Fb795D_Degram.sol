/**
 *Submitted for verification at Etherscan.io on 2021-11-24
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract Degram {
    string public name = "Degram";

    // store images
    uint public imageCount = 0;
    mapping(uint => Image) public images;

    struct Image {
        uint id;
        string hash;
        string description;
        uint tipAmount;
        address payable author;
    }

    // event for image created
    event ImageCreated(
        uint id,
        string hash,
        string description,
        uint tipAmount,
        address payable author
    );

    // event for tip image
    event ImageTipped(
        uint id,
        string hash,
        string description,
        uint tipAmount,
        address payable author
    );

    // create image 
    function uploadImage(string memory _imgHash, string memory _description) public {
        // require
        require(bytes(_description).length > 0, "Description cannot be empty");
        require(bytes(_imgHash).length > 0, "Image hash cannot be empty");
        require(msg.sender != address(0x0), "sender is 0x0 not applicable");

        // increment image count
        imageCount++;
        images[imageCount] = Image(imageCount, _imgHash, _description, 0, payable(msg.sender));

        // trigger an event
        emit ImageCreated(imageCount, _imgHash, _description, 0, payable(msg.sender));
    }

    // tip image
    function tipImageOwner(uint _id) public payable {
        // check if id is valid
        require(_id > 0 && _id <= imageCount);
        
        // fetch image
        Image memory _image = images[_id];
        // fetch the author of the image
        address payable _author = _image.author;

        // transfer tip to author
        payable(address(_author)).transfer(msg.value);

        // update tip amount of the image
        _image.tipAmount = _image.tipAmount + msg.value;

        // update image obj in images mapping
        images[_id] = _image;

        // trigger an event
        emit ImageCreated(_id, _image.hash, _image.description, _image.tipAmount, payable(_author));  
    }
    
}