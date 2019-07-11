/**
 *Submitted for verification at Etherscan.io on 2019-07-09
*/

pragma solidity >=0.5.10;


interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract KNCLock {
    
    IERC20 public KNC = IERC20(0xdd974D5C2e2928deA5F71b9825b8b646686BD200);
    
    uint public lockId;
    mapping (address=>uint) lockedKNC;
    
    constructor(IERC20 knc) public {
        
        KNC = knc;
    }
    
    event Lock (
        uint indexed qty, 
        uint64 indexed eosRecipientName, 
        uint indexed lockId
    );
    
    function lock(uint qty, string memory eosAddr, uint64 eosRecipientName) public {
        
        eosAddr;
        
        //Transfer the KNC
        require(KNC.transferFrom(msg.sender, address(this), qty));
        
        lockedKNC[msg.sender] += qty;
        
        emit Lock(qty, eosRecipientName, lockId);
        
        ++lockId;
    }
    
    function unLock(uint qty) public {
        require(lockedKNC[msg.sender] >= qty);
        
        lockedKNC[msg.sender] -= qty;
        
        require(KNC.transfer(msg.sender, qty));
    }
}