/**
 *Submitted for verification at Etherscan.io on 2021-04-27
*/

// Proof of concept using Tornado.cash with flashbots

//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

interface ITornadoProxy {
    function withdraw(
        address _tornado,
        bytes calldata _proof,
        bytes32 _root,
        bytes32 _nullifierHash,
        address payable _recipient,
        address payable _relayer,
        uint256 _fee,
        uint256 _refund
    ) external payable;
}

contract TornadoMEV {
    ITornadoProxy public immutable tornadoProxy = ITornadoProxy(0x722122dF12D4e14e13Ac3b6895a86e84145b6967);
    
    fallback() external payable {}
    receive() external payable {}

    function withdraw(
        address _tornado,
        bytes calldata _proof,
        bytes32 _root,
        bytes32 _nullifierHash,
        address payable _recipient,
        address payable _relayer,
        uint256 _fee,
        uint256 _refund
    ) external {
        require(_relayer == address(this), "Incorrect relayer address");
        uint balance = address(this).balance;
        
        tornadoProxy.withdraw(_tornado, _proof, _root, _nullifierHash, _recipient, _relayer, _fee, _refund);
        require(address(this).balance - balance == _fee, "Fee is invalid");
        
        block.coinbase.transfer(_fee);
    }
}