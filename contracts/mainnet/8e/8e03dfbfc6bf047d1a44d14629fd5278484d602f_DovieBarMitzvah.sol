pragma solidity ^0.4.13;

contract DovieBarMitzvah {

  address private owner;
  string private messagefromdovie;  

  function DovieBarMitzvah () public {
    owner = msg.sender;    
  }

  /* Modifiers */
  modifier onlyOwner() {
    require(owner == msg.sender);
    _;
  }

function parsha() public pure returns (string _name) {
    return "Bereshit";
  }

  function thedate() public pure returns (string _name) {
    return "Sunday, October 7th";
  }

  function thelocation() public pure returns (string _name) {
    return "Miami, Florida";
  }

  function messagetodovie() public pure returns (string _name) {
    return "Mazol Tov on your bar mitzvah...13 years in the making.  All the best to you and your family. Feel free to share a message to everyone using the private keys I share with you.";
  }


  /* Set Message From Dovie */
  function setMessagefromdovie (string _messagefromdovie) onlyOwner() public {
    messagefromdovie = _messagefromdovie;
  }

  function getmessagefromdovie() public view returns (string _name) {
    return messagefromdovie;
  }
}