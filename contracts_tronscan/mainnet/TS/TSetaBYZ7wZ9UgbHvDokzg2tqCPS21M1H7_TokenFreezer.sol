//SourceUnit: _TokenFreezer.sol

pragma solidity ^0.4.25;

contract TokenFreezer {
    uint public totalFrozen;
    uint public tokenId = 1003049;

    event Freeze(address user);
    
    // frozen tokens
    mapping (address => uint) public frozen;

    function freeze() external payable {
        require(msg.tokenid == tokenId);
        require(msg.tokenvalue > 0);

        frozen[msg.sender] += msg.tokenvalue;
        totalFrozen += msg.tokenvalue;
        
        emit Freeze(msg.sender);
    }

    function unfreeze() external {
        totalFrozen -= frozen[msg.sender];
        msg.sender.transferToken(frozen[msg.sender], tokenId);
        frozen[msg.sender] = 0;
    }
}