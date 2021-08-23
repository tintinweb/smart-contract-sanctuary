//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import 'BEP20.sol';

contract TestToken is BEP20('Test Token', 'TST', 18) {

    uint256 private immutable _tokensPerDay;
    uint private _lastDate;
    
    constructor(uint256 total, uint256 perday) {
        _mint(_msgSender(), total * (10 ** uint256(decimals())));
        _lastDate = block.timestamp;
        _tokensPerDay = perday * (10 ** uint256(decimals()));
    }

    function createTokens() public onlyOwner {
        require(block.timestamp > _lastDate && block.timestamp - _lastDate > 10 seconds, "Once per minute");
        uint256 tokens = (block.timestamp - _lastDate) * (_tokensPerDay / 1 days);
        require(tokens > 0, 'Empty earn');
        
        _mint(_msgSender(), tokens);
        _lastDate = block.timestamp;
    }
}