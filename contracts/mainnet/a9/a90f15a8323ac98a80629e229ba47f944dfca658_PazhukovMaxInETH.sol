pragma solidity ^0.4.18;

contract PazhukovMaxInETH {
    
    bytes32 info = &quot;I&#39;m smart contract from p5m.ru!&quot;;
    
    function getInfo() view public returns (bytes32) {
        return (info);
    }
    
}