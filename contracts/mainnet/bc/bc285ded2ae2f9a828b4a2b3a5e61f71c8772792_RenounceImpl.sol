/**
 *Submitted for verification at Etherscan.io on 2021-04-14
*/

pragma solidity >=0.7.0 <0.9.0;

interface IMinter {
  function renounceMinter() external;
}


contract RenounceImpl {

    function renounceMinter(address addr) public {
        IMinter(addr).renounceMinter();
    }

}