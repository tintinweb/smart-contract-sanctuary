/**
 *Submitted for verification at Etherscan.io on 2021-03-04
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.4.22 <0.9.0;
pragma experimental ABIEncoderV2;

contract EthernalLock {
    struct Color {
        uint8 R;
        uint8 G;
        uint8 B;
    }
    
    struct Lock {
        Color BackgroundColor;
        Color LockColor;
        Color LabelColor;
        Color TextColor;
        uint LockType;
        
        string Text;
        bool Encrypted;
    }
    
    uint price;
    Lock[] public locks;
    
    mapping(address => bool) owners;
    mapping(address => bool) freeLockCreators;
    
    
    modifier onlyowner() {
        require(owners[msg.sender] == true, "Caller is not owner");
        _;
    }
    
    
    constructor() {
        price = 0.01 ether;
        owners[msg.sender] = true;
        freeLockCreators[msg.sender] = true;
    }
    
    
    function setOwner(address adr, bool isOwner) public onlyowner {
        owners[adr] = isOwner;
    }
    
    function setFreeLockCreator(address adr, bool isFreeLockCreator) public onlyowner {
        freeLockCreators[adr] = isFreeLockCreator;
    }
    
    function cashOut() public onlyowner {
        payable(msg.sender).transfer(address(this).balance);
    }
    
    function createLock(Color calldata backgroundColor, Color calldata lockColor, Color calldata labelColor, Color calldata textColor, uint lockType, string calldata text, bool encrypted) public payable returns (uint pos) {
        if (freeLockCreators[msg.sender] == false) {
            require(msg.value >= price, "Payment is not enough");
        }
        
        locks.push(Lock(
            {
                BackgroundColor: backgroundColor, 
                LockColor: lockColor,
                LabelColor: labelColor,
                TextColor: textColor,
                LockType: lockType,
                Text: text,
                Encrypted: encrypted
            }
        ));
        
        return locks.length - 1;
    }
    
    function getLockCount() public view returns (uint count) {
        return locks.length;
    }

    function getLocks() public view returns (Lock[] memory allLocks) {
        return locks;
    }
}