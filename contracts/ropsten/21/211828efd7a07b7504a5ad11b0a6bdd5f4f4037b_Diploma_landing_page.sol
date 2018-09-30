pragma solidity ^0.4.11;

contract Diploma_landing_page {
 address public owner;
 string htmlhash;
 string LandingPageHash;
 
 modifier onlyOwner() {
  require(msg.sender == owner);
  _;
 }
 
 function Diploma_landing_page() public {
  owner = msg.sender;
 }
 
 function setHTML(string _htmlhash) payable public onlyOwner {
  htmlhash = _htmlhash;
 }
  function setLandingPage(string _LandingPageHash) payable public onlyOwner {
  LandingPageHash = _LandingPageHash;
 }
  function renderLandingHash() public view returns (string) {
   return LandingPageHash;
 }
 
 function renderWeb() public view returns (string) {
   return htmlhash;
 }
}