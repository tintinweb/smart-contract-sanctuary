pragma solidity ^0.4.16;

contract tradeHashTest {
    
    function testHashing(address tokenBuy, uint256 amountBuy, address tokenSell, uint256 amountSell, uint256 nonce, uint8 v, bytes32 r, bytes32 s, bytes32 tradeHash) public constant returns(address) {
        bytes32 orderHash = keccak256(abi.encodePacked(this, tokenBuy, amountBuy, tokenSell, amountSell, nonce));
        return ecrecover(keccak256(abi.encodePacked(tradeHash, orderHash)), v, r, s);
    }
}