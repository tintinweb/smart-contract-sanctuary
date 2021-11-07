// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

  function createGravatar(string memory _displayName, string memory _imageUrl)
    public
  {
    // solhint-disable-next-line reason-string
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
    // solhint-disable-next-line reason-string
    require(ownerToGravatar[msg.sender] != 0);
    // solhint-disable-next-line reason-string
    require(msg.sender == gravatars[ownerToGravatar[msg.sender]].owner);

    uint256 id = ownerToGravatar[msg.sender];

    gravatars[id].displayName = _displayName;
    emit UpdatedGravatar(id, msg.sender, _displayName, gravatars[id].imageUrl);
  }

  function updateGravatarImage(string memory _imageUrl) public {
    // solhint-disable-next-line reason-string
    require(ownerToGravatar[msg.sender] != 0);
    // solhint-disable-next-line reason-string
    require(msg.sender == gravatars[ownerToGravatar[msg.sender]].owner);

    uint256 id = ownerToGravatar[msg.sender];

    gravatars[id].imageUrl = _imageUrl;
    emit UpdatedGravatar(id, msg.sender, gravatars[id].displayName, _imageUrl);
  }

  function setMythicalGravatar() public {
    // solhint-disable-next-line reason-string
    require(msg.sender == 0x8d3e809Fbd258083a5Ba004a527159Da535c8abA);
    gravatars.push(Gravatar(address(0), " ", " "));
  }
}