pragma solidity ^0.8.0;

import "./Ownable.sol";

interface ILiquidityToken {
    function transfer(address to, uint amount) external returns (bool);
    function transferFrom(address from, address to, uint amount) external returns (bool);
}

contract LiquidityLock is Ownable {
    
    address public liquidityToken;
    uint public lockedLiquidity;
    uint public lockedUntil;
    bool public locked;
    
    event LiquidityLocked(uint amount, uint until);
    event LiquidityUnlocked(uint amount, address to);
    
    constructor(address _token) {
        liquidityToken = _token;
    }
    
    modifier whenNotLocked() {
        require(!locked, "Liquidity is already locked");
        locked = true;
        _;
    }
    
    function lockLiquidity(uint amount, uint time) external onlyOwner whenNotLocked {
        lockedLiquidity = amount;
        lockedUntil = block.timestamp + time;
        ILiquidityToken(liquidityToken).transferFrom(msg.sender, address(this), amount);
        emit LiquidityLocked(amount, lockedUntil);
    }
    
    function unlockLiquidty() external onlyOwner {
        require(locked, "Liquidity not locked");
        require(block.timestamp >= lockedUntil, "Can't unlock yet");
        ILiquidityToken(liquidityToken).transfer(owner(), lockedLiquidity);
        emit LiquidityUnlocked(lockedLiquidity, owner());
    }
    
}