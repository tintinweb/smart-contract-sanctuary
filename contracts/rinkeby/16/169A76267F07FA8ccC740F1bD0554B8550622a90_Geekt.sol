/**
 *Submitted for verification at Etherscan.io on 2022-01-10
*/

pragma solidity ^0.4.4;

// Simple Solidity intro/demo contract for BlockGeeks Article
contract Geekt {

  address GeektAdmin;

  mapping ( bytes32 => notarizedImage) notarizedImages; // this allows to look up notarizedImages by their SHA256notaryHash
  bytes32[] imagesByNotaryHash; // this is like a whitepages of all images, by SHA256notaryHash

  mapping ( address => User ) Users;   // this allows to look up Users by their ethereum address
  address[] usersByAddress;  // this is like a whitepages of all users, by ethereum address

  struct notarizedImage {
    string imageURL;
    uint timeStamp;
  }

  struct User {
    string handle;
    bytes32 city;
    bytes32 state;
    bytes32 country;
    bytes32[] myImages;
  }

  function Geekt() payable {  // this is the CONSTRUCTOR (same name as contract) it gets called ONCE only when contract is first deployed
    GeektAdmin = msg.sender;  // just set the admin, so they can remove bad users or images if needed, but nobody else can
  }

  modifier onlyAdmin() {
      if (msg.sender != GeektAdmin)
        throw;
      // Do not forget the "_;"! It will be replaced by the actual function body when the modifier is used.
      _;
  }

  function removeUser(address badUser) onlyAdmin returns (bool success) {
    delete Users[badUser];
    return true;
  }

  function removeImage(bytes32 badImage) onlyAdmin returns (bool success) {
    delete notarizedImages[badImage];
    return true;
  }

  function registerNewUser(string handle, bytes32 city, bytes32 state, bytes32 country) returns (bool success) {
    address thisNewAddress = msg.sender;
    // don't overwrite existing entries, and make sure handle isn't null
    if(bytes(Users[msg.sender].handle).length == 0 && bytes(handle).length != 0){
      Users[thisNewAddress].handle = handle;
      Users[thisNewAddress].city = city;
      Users[thisNewAddress].state = state;
      Users[thisNewAddress].country = country;
      usersByAddress.push(thisNewAddress);  // adds an entry for this user to the user 'whitepages'
      return true;
    } else {
      return false; // either handle was null, or a user with this handle already existed
    }
  }

  function addImageToUser(string imageURL, bytes32 SHA256notaryHash) returns (bool success) {
    address thisNewAddress = msg.sender;
    if(bytes(Users[thisNewAddress].handle).length != 0){ // make sure this user has created an account first
      if(bytes(imageURL).length != 0){   // ) {  // couldn't get bytes32 null check to work, oh well!
        // prevent users from fighting over sha->image listings in the whitepages, but still allow them to add a personal ref to any sha
        if(bytes(notarizedImages[SHA256notaryHash].imageURL).length == 0) {
          imagesByNotaryHash.push(SHA256notaryHash); // adds entry for this image to our image whitepages
        }
        notarizedImages[SHA256notaryHash].imageURL = imageURL;
        notarizedImages[SHA256notaryHash].timeStamp = block.timestamp; // note that updating an image also updates the timestamp
        Users[thisNewAddress].myImages.push(SHA256notaryHash); // add the image hash to this users .myImages array
        return true;
      } else {
        return false; // either imageURL or SHA256notaryHash was null, couldn't store image
      }
      return true;
    } else {
      return false; // user didn't have an account yet, couldn't store image
    }
  }

  function getUsers() constant returns (address[]) { return usersByAddress; }

  function getUser(address userAddress) constant returns (string,bytes32,bytes32,bytes32,bytes32[]) {
    return (Users[userAddress].handle,Users[userAddress].city,Users[userAddress].state,Users[userAddress].country,Users[userAddress].myImages);
  }

  function getAllImages() constant returns (bytes32[]) { return imagesByNotaryHash; }

  function getUserImages(address userAddress) constant returns (bytes32[]) { return Users[userAddress].myImages; }

  function getImage(bytes32 SHA256notaryHash) constant returns (string,uint) {
    return (notarizedImages[SHA256notaryHash].imageURL,notarizedImages[SHA256notaryHash].timeStamp);
  }

}