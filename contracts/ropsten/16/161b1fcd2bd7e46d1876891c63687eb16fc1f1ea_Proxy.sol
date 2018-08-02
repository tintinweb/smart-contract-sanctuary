pragma solidity ^0.4.24;

contract Proxy {
    
    function () payable public {
        if (!address(0x710613A64648A466fBE00d8224B4EF19CbF1CF91).delegatecall())
            revert(&quot;DelegateCall failed.&quot;);
    }
}