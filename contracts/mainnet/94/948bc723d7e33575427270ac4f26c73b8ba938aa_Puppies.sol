// SPDX-License-Identifier: MIT  

pragma solidity >=0.6.0 <0.8.0;

import "./Ownable.sol";
import "./ERC721.sol";

contract Puppies is 
  Ownable, 
  ERC721
{
  using SafeMath for uint256;

  mapping(uint256 => uint256) public eligibility;

  // address of Dog contract
  ERC721 public dogs;
  
  constructor(
    string memory _uri,
    address _dogsAddress
  ) ERC721("Puppies", "PUPPY") public {
    _setBaseURI(_uri);
    dogs = ERC721(_dogsAddress);
  }

  /** INTERACTIONS **/

  /**
    * @notice claims a Puppy for the relevant Dog
    * @param dogId the ID of the Dog to claim against
    */
  function claim(uint256 dogId) external {
    require(getDogEligible(dogId), "Dog not eligible for claim");
    require(dogs.ownerOf(dogId) == _msgSender(), "Must own dog to claim");
    _mint(_msgSender(), dogId);
    setDogEligible(dogId, false);
  }

  /** ADMIN **/

  /**
    * @notice updates the base URI to update metadata if needed
    * @param _baseURI URI of new metadata base ofolder
    */
  function setBaseURI(string calldata _baseURI) external onlyOwner {
    _setBaseURI(_baseURI);
  }

  /**
    * @notice enables the claim of Puppies for specific Dogs
    * @param dogIds the IDs of the Dogs to enable claims for
    */
  function setEligibility(uint16[] calldata dogIds, bool eligible) external onlyOwner {
    for (uint i = 0; i < dogIds.length; i++) {
      setDogEligible(dogIds[i], eligible);
    }
  }
  
  function getDogEligible(uint256 dogId) public view returns (bool) {
      uint256 dogMask = eligibility[getBucket(dogId)];
      return (dogMask >> (dogId % 256)) & 1 == 1;
  }
  
  function setDogEligible(uint256 dogId, bool eligible) internal {
    uint256 dogMask = eligibility[getBucket(dogId)];
    if (eligible)
        dogMask |= 1 << (dogId % 256);
    else
        dogMask &= ~(1 << (dogId % 256));
    eligibility[getBucket(dogId)] = dogMask;
  }

  function getBucket(uint256 dogId) internal pure returns (uint256){
      return dogId / 256;
  }

  /**
    * @notice force claims a Puppy for a Dog
    * @param puppyId the ID of the Puppy to force claim
    * @param to the address to mint the Puppy to
    */
  function devRescue(uint256 puppyId, address to) external onlyOwner {
    _mint(to, puppyId);
  }
}