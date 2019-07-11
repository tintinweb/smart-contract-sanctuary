/**
 *Submitted for verification at Etherscan.io on 2019-07-09
*/

pragma solidity >=0.5.10;


interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

interface KNCLock {
    function lock(uint qty, string calldata eosAddr, uint64 eosRecipientName) external;
}

contract TriggerKNCLock {
    
    KNCLock public KNCLockContract = KNCLock(0x980358360409b1cc913A916bC0Bf6f52F775242A);
    IERC20 public KNC = IERC20(0xdd974D5C2e2928deA5F71b9825b8b646686BD200);
    
    constructor(IERC20 knc) public {
        
        KNC = knc;
    }
    
    function triggerLock(string memory eosAddr, uint64 eosRecipientName) public {
        
        uint qty = KNC.balanceOf(address(this)); 
        
        KNCLockContract.lock(qty, eosAddr, eosRecipientName);
    }
    
    function setKNCLockAddress(KNCLock lockContract) public {
        KNCLockContract = lockContract;
    }
}