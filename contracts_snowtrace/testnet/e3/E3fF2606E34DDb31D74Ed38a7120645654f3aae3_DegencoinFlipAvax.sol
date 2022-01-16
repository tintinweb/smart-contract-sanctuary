/**
 *Submitted for verification at testnet.snowtrace.io on 2022-01-15
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;


contract DegencoinFlipAvax {
    address onwer = 0xa7ee51B02240F92817606675030246ab774cE6c6;
    address feeAddress = 0x6308336Df3A68e2D405eaf3A59380786433987aE;
    // constructor() {
    //     /*
    //         owner: Change to be owner of project (Able to withdraw all money)
    //         feeAddress: Where 0.03 VAX will allocate to as fee of each bet (3%)
    //     */
    //     onwer = 0xa7ee51B02240F92817606675030246ab774cE6c6;
    //     feeAddress = 0x6308336Df3A68e2D405eaf3A59380786433987aE;
    // }
    
    /*Amount of each bet 0.103 AVAX:
        - 0.1 bidding
        - 0.03 fee
    */
    event LogData(uint chance);
    uint exactAmount = 103000000 gwei; 

    function bet() public payable{
        require(msg.value == exactAmount, "insufficient amount, must be 0.103 AVAX");
        
        uint chance = createRandom(10);
        emit LogData(chance);
        if (chance % 2 == 1) {
            payable(msg.sender).transfer(200000000 gwei);
        }
        payable(feeAddress).transfer(3000000 gwei);
    }

    function getBalanced() public view returns (uint) {
        return address(this).balance;
    }

    function deposit() public payable {

    }

    function withDrawAllTheFun(address payable _to) public {
        require(msg.sender == onwer, "You are not the owner");
        _to.transfer(address(this).balance);
    }

    // Initializing the state variable
    uint randNonce = 0;
    
    // Defining a function to generate
    // a random number
    function createRandom(uint _modulus) internal returns(uint)
    {
    // increase nonce
    randNonce++; 
    return uint(keccak256(abi.encodePacked(block.timestamp,
                                            msg.sender,
                                            randNonce))) % _modulus;
    }
}