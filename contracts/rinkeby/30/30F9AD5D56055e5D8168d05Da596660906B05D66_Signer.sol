/**
 *Submitted for verification at Etherscan.io on 2021-03-30
*/

pragma solidity ^0.7.6;



contract  Signer {

    event MetaData(address indexed _signer, bytes indexed _data);

    function Sign(bytes memory _data) external {
       emit MetaData(msg.sender, _data);
    }

}