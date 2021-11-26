/**
 *Submitted for verification at polygonscan.com on 2021-11-25
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.9.0;

contract GravatarRegistry {
  event NewGravatar(
    uint256 id,
    address owner,
    string displayName,
    string imageUrl
  );
  event UpdatedGravatar(
    uint256 id,
    address owner,
    string displayName,
    string imageUrl
  );

  struct Gravatar {
    address owner;
    string displayName;
    string imageUrl;
  }

  Gravatar[] public gravatars;

  mapping(uint256 => address) public gravatarToOwner;
  mapping(address => uint256) public ownerToGravatar;

  constructor() public {
    gravatars.push(
      Gravatar(0x8494e4dBF47c732CE5a236c58974bB942C50FEe9, " ", " ")
    );
  }

  function createGravatar(string memory _displayName, string memory _imageUrl)
    public
  {
    require(ownerToGravatar[msg.sender] == 0);
    gravatars.push(Gravatar(msg.sender, _displayName, _imageUrl));
    uint256 id = gravatars.length - 1;

    gravatarToOwner[id] = msg.sender;
    ownerToGravatar[msg.sender] = id;

    emit NewGravatar(id, msg.sender, _displayName, _imageUrl);
  }

  function getGravatar(address owner)
    public
    view
    returns (string memory, string memory)
  {
    uint256 id = ownerToGravatar[owner];
    return (gravatars[id].displayName, gravatars[id].imageUrl);
  }

  function updateGravatarName(string memory _displayName) public {
    require(
      ownerToGravatar[msg.sender] != 0,
      "gravatar for sender not created yet"
    );
    require(msg.sender == gravatars[ownerToGravatar[msg.sender]].owner);

    uint256 id = ownerToGravatar[msg.sender];

    gravatars[id].displayName = _displayName;
    emit UpdatedGravatar(id, msg.sender, _displayName, gravatars[id].imageUrl);
  }

  function updateGravatarImage(string memory _imageUrl) public {
    require(ownerToGravatar[msg.sender] != 0);
    require(msg.sender == gravatars[ownerToGravatar[msg.sender]].owner);

    uint256 id = ownerToGravatar[msg.sender];

    gravatars[id].imageUrl = _imageUrl;
    emit UpdatedGravatar(id, msg.sender, gravatars[id].displayName, _imageUrl);
  }
}