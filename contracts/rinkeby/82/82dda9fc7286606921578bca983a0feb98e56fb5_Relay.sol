/**
 *Submitted for verification at Etherscan.io on 2021-06-16
*/

contract Relay {
    address public currentVersion;
    address public owner;

    function Relay(address initAddr){
        currentVersion = initAddr;
        owner = msg.sender;
    }

    function update(address newAddress){
        if(msg.sender != owner) throw;
        currentVersion = newAddress;
    }

    function(){
        if(!currentVersion.delegatecall(msg.data)) throw;
    }
}