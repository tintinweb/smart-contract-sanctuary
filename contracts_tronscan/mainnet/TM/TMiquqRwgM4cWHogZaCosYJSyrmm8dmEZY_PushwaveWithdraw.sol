//SourceUnit: PushwaveWithdraw.sol.sol

pragma solidity ^0.4.25;


contract PushwaveWithdraw   {
    
    
    address private owner;
    
    constructor() public {
        owner = msg.sender;
    }
    
    function ownerAddress() public view returns(address)   {
        return owner;
    }
    
    function Balance() public view returns(uint)  {
        return owner.balance;
    }
    
     function sendTrx(address recipient, uint256 amount) external {
        recipient.transfer(amount);
    }
}