/**
 *Submitted for verification at Etherscan.io on 2021-01-31
*/

pragma solidity >=0.6.2;
// SPDX-License-Identifier: MIT

contract Payment {
    address deployer;
    uint256 releaseTime;
    
    modifier deployerOnly {
        require(msg.sender == deployer, 'Restricted to deployer');
        _;
    }
    
    constructor(uint256 _releaseBlocks) {
        deployer = msg.sender;
        //100000 blocks = 30 days
        releaseTime = block.number + _releaseBlocks;
    }
    
    function withdraw(address _tokenContract, uint256 _amount) public deployerOnly {
        require(block.number > releaseTime, 'Wait unil release time');
        ERC20 token = ERC20(_tokenContract);
        token.transfer(msg.sender, _amount);
    }
    
    receive() external payable {
        //Do nothing
    }
}

interface ERC20 {
    function balanceOf(address _owner) external;
    function transfer(address _to, uint _value) external;
    function transferFrom(address _from, address _to, uint _value) external;
    function approve(address _spender, uint _value) external;
    function allowance(address _owner, address _spender) external;
}