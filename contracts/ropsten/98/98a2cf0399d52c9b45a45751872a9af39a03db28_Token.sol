pragma solidity ^0.4.23;

contract Token {
    
    uint256 public counter = 0;

    function signVer(address _buyerAddress, bytes32 _buyerId, uint256 _maxAmount, uint8 v, bytes32 r, bytes32 s) public returns(address) {
        bytes memory data = abi.encodePacked(&quot;Atomax authorization:&quot;, this, _buyerAddress, _buyerId, _maxAmount);
        bytes32 prefixedHash = keccak256(data);
        counter += 1;
        return ecrecover(prefixedHash, v, r, s);
    }
}