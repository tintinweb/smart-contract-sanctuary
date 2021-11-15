pragma solidity  >=0.7.3;
contract BatchCaller {
    function batchMint(address payable [] memory proxies) public payable {
        for(uint i = 0; i < proxies.length; i++) {
            proxies[i].call("");
        }
    }   
}

