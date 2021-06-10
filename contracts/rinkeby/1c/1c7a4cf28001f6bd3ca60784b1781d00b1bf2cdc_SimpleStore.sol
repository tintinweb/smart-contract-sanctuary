/**
 *Submitted for verification at Etherscan.io on 2021-06-10
*/

//Write your own contracts here. Currently compiles using solc v0.4.15+commit.bbb8e64f.
pragma solidity ^0.4.18;
contract SimpleStore {

CC[] public eos;
      struct CC {
        string logo;
        string site;
        string paper;
       
        uint256 start;

      }

function setCC() public {
    CC memory cc = CC({
      logo : '1',
      site : '1',
      paper : '1',
      start : 100
    });
    eos.push(cc);
  }

  function getCc() public view returns (CC) {
    CC memory cc = eos[0];
    return cc;
  }

  function set(uint _value) public {
    value = _value;
  }

  function get() public constant returns (uint) {
    return value;
  }

  uint value;
}