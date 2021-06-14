/**
 *Submitted for verification at Etherscan.io on 2021-06-13
*/

pragma solidity >=0.7.0 <0.9.0;

contract DummyGRTProxy{
    
    
    event LogSender(address sender);
    
    function delegate(address _indexer, uint256 _tokens)
        external
        returns (uint256  shares_) {
            emit LogSender(msg.sender);
            shares_ = 1;
        }
}