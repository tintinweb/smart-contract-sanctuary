/**
 *Submitted for verification at Etherscan.io on 2021-11-06
*/

// File: contracts/ERC20Wallet2out3.sol

pragma solidity >=0.8 <0.9.0;


interface IERC20 {
    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);
}

contract ERC20Wallet2out3{

   
   enum State {
       pending,
       complete
   }
   // Declaring a structure
   struct Payout { 
      uint256 qtyAlice;
      uint256 qtyBob;
      uint256 qtyDave;
      address initiatedBy;
      address cosignedBy;
      State state;
   }
   
    event TransferInitiated(address, uint);
    event TransferConfirmed(address, uint);
    
    address alice;
    address bob;
    address dave;
    IERC20 public token;

    uint public nonce = 0; //the index of next payment  
    Payout [] public payouts;  
    
    constructor(address _alice, address _bob, address _dave, address erc20){
        require (_alice != address(0));
        require (_bob   != address(0));
        require (_dave  != address(0));
        require (erc20  != address(0));
        
        alice = _alice;
        bob   = _bob;
        dave  = _dave;
        token = IERC20(erc20);
    }
    

    function initTransfer(uint256 qtyAlice, uint256 qtyBob, uint256 qtyDave) external{
        require(msg.sender == alice || msg.sender == bob || msg.sender == dave, "not an owner");
        payouts.push (Payout(qtyAlice, qtyBob, qtyDave, msg.sender, address(0), State.pending));
        emit TransferInitiated(msg.sender, nonce);
        nonce ++;
    }
    
    function confirmTransfer(uint _nonce) external virtual{
        require(msg.sender == alice || msg.sender == bob || msg.sender == dave, "not an owner");
        require(payouts[_nonce].initiatedBy != msg.sender, "the initiator cannot confirm");
        require(payouts[_nonce].state == State.pending, "incorrect state for payout");
        token.transfer(alice, payouts[_nonce].qtyAlice);
        token.transfer(bob, payouts[_nonce].qtyBob);
        token.transfer(dave, payouts[_nonce].qtyDave);
        payouts[_nonce].state = State.complete;
        payouts[_nonce].cosignedBy = msg.sender;
        emit TransferConfirmed(msg.sender, _nonce);
    }
    
}
// File: contracts/ERC20Wallet2out3Backup.sol

pragma solidity >=0.8 <0.9.0;



contract ERC20Wallet2out3Backup is ERC20Wallet2out3{
    
    //the backup address is a special owner which can co-sign but cannot
    //receive funds
    address public backup;
    
    constructor(address _alice, address _bob, address _dave, address _backup, address erc20)
    ERC20Wallet2out3(_alice, _bob, _dave, erc20){
        require (_backup != address(0));
        backup = _backup;
    }
    
    
    function confirmTransfer(uint _nonce) external override{
        require(msg.sender == alice || msg.sender == bob || msg.sender == dave || msg.sender == backup, "not an owner");
        require(payouts[_nonce].initiatedBy != msg.sender, "the initiator cannot confirm");
        require(payouts[_nonce].state == State.pending, "incorrect state for payout");
        token.transfer(alice, payouts[_nonce].qtyAlice);
        token.transfer(bob, payouts[_nonce].qtyBob);
        token.transfer(dave, payouts[_nonce].qtyDave);
        payouts[_nonce].state = State.complete;
        payouts[_nonce].cosignedBy = msg.sender;
    }
    
}
// File: contracts/Factory.sol

pragma solidity >=0.8 <0.9.0;


contract Factory{
    event NewWallet(address);
    function create2out3Backup(
                            address [3] memory owners, 
                            address backup, 
                            address erc20)  
                            external{
        
        ERC20Wallet2out3Backup wallet =
        new ERC20Wallet2out3Backup( owners[0], 
                                    owners[1], 
                                    owners[2],
                                    backup,
                                    erc20);
        emit NewWallet(address(wallet));

    }
}