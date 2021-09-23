/**
 *Submitted for verification at Etherscan.io on 2021-09-22
*/

// SPDX-License-Identifier: MIT 
pragma solidity 0.8.7;

/*
WARNING: This is a trap. It is designed for the dev to make money from overconfident searchers.
However, It *is* possible for sophisticated searchers to drain all the money from this contract 
at a rate of about 2.75 ETH per hour.

Play at your own risk, and know that you probably don't understand all the risks.
No refunds. I drink your tears. That's the whole point.

HOW IT WORKS
1. Register your upcoming attempt by calling register()
    - Registering costs 1 ETH. You get this back, plus 0.02 ETH profit, only if you succeed in stealing the cheese.
    - EOA's only.
    - Must not register if your address is already registered.
2. Steal the cheese by calling stealTheCheese() while passing in the target block number.
    - You must wait at least 1 block after registering before trying to steal the cheese.
    - You must use a priority fee of at least 20 gwei.
    - You must pass in the correct block number.
    - You must not try to steal the cheese for a block in which it's already been stolen.

Break any rule and you lose your 1 ETH. Otherwise, you get it back + another 0.02 ETH.

My hope is that I'll earn at least 1 ETH in failures before someone figures it out and drains the contract.

This contract has not been audited and is probably broken. Go nuts.
*/
contract MouseTrap {
    
    mapping(address => uint256) public registeredBlock;
    uint256 private lastBlockCheeseWasStolen;
    address payable public immutable dev;
    
    constructor() {
        require(msg.sender == tx.origin, 'dev must be EOA');
        dev = payable(msg.sender);
    }
    
    receive() external payable {}
    
    function register() external payable {
        // no risk, no reward
        if (msg.value < 1 ether) return;
        
        // EOA only
        if (msg.sender != tx.origin) {
            _lose();
            return;
        }
        
        // already registered
        if (registeredBlock[msg.sender] != 0) {
            _lose();
            return;
        }
        
        // successfully registered!
        registeredBlock[msg.sender] = block.number;
    }
    
    function stealTheCheese(uint256 _targetBlock) external {
        // must register before trying to steal cheese
        if (registeredBlock[msg.sender] == 0) return;
        
        // must wait at least 1 block after registering before trying to steal cheese
        if (block.number == registeredBlock[msg.sender]) {
            _lose();
            return;
        }
        
        // must have priority fee of at least 20 gwei
        if (tx.gasprice - block.basefee < 20 gwei) {
            _lose();
            return;
        }
        
        // must pass in the correct block number
        if (_targetBlock != block.number) {
            _lose();
            return;
        }
        
        // cheese can be stolen only once per block
        if (lastBlockCheeseWasStolen == block.number) {
            _lose();
            return;
        }
        
        lastBlockCheeseWasStolen = block.number;

        // winner!!
        sendValue(payable(msg.sender), 1.02 ether);
    }
    
    function _lose() private {
        registeredBlock[msg.sender] = 0;
        sendValue(dev, 1 ether);
    }

    // OpenZeppelin's sendValue function
	function sendValue(address payable recipient, uint256 amount) private {
		require(address(this).balance >= amount, "Address: insufficient balance");
		// solhint-disable-next-line avoid-low-level-calls, avoid-call-value
		(bool success, ) = recipient.call{ value: amount }("");
		require(success, "Address: unable to send value, recipient may have reverted");
	}

}