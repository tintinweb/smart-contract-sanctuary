/**
 *Submitted for verification at Etherscan.io on 2021-03-30
*/

pragma solidity ^0.7.6;



contract  Signer {

    event MetaData(address indexed _signer, string _data);

    function Sign(string memory _data) external {
       emit MetaData(msg.sender, _data);
    }

}