pragma solidity ^0.4.19;

contract DummyDaoContract {
  string public description1 = &quot;This is just a dummy contract to be assigned the role of `dao` in the DGD token contract&quot;;
  string public description2 = &quot;The purpose is to seal off the minting function of the DGD token contract forever&quot;;
  string public description3 = &quot;Since only the `dao` role can create a sales address, which can mint more DGDs&quot;;
  string public description4 = &quot;And when registerDao() is called on the DGD token contract to register this dummy contract as `dao`, this dummy contract will remain the role of `dao` forever&quot;;
}