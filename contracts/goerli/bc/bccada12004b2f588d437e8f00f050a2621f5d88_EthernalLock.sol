/**
 *Submitted for verification at Etherscan.io on 2021-03-04
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.4.22 <0.9.0;
pragma experimental ABIEncoderV2;

contract EthernalLock {
    event LockCreated(address indexed _from, address indexed _lovee, string _txt);

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

        address Lovee;
    }
    
    uint public defaultLockPrice;
    Lock[] public locks;
    
    mapping(address => bool) owners;
    mapping(address => bool) freeLockCreators;

    mapping(uint => uint) customLockPrices;
    uint public highestValidLockType;
    
    
    modifier onlyowner() {
        require(owners[msg.sender] == true, "Caller is not owner");
        _;
    }    
    
    constructor() {
        defaultLockPrice = 0.01 ether;
        owners[msg.sender] = true;
    }    
    
    function setOwner(address adr, bool isOwner) public onlyowner {
        owners[adr] = isOwner;
    }
    
    function setFreeLockCreator(address adr, bool isFreeLockCreator) public onlyowner {
        freeLockCreators[adr] = isFreeLockCreator;
    }

    function setHighestValidLockType(uint count) public onlyowner {
        highestValidLockType = count;
    }

    function setDefaultLockPrice(uint lockPrice) public onlyowner {
        defaultLockPrice = lockPrice;
    }

    function setLockTypePrice(uint lockType, uint lockPrice) public onlyowner {
        customLockPrices[lockType] = lockPrice;
    }
    
    function cashOut() public onlyowner {
        payable(msg.sender).transfer(address(this).balance);
    }



    function getLockPrice(uint lockType) public view returns (uint lockPrice) {
        uint thisLockPrice = customLockPrices[lockType];
        if (thisLockPrice == 0) {
            return defaultLockPrice;
        }
        return thisLockPrice;
    }
    
    function createLock(Color calldata backgroundColor, Color calldata lockColor, Color calldata labelColor, Color calldata textColor, uint lockType, string calldata text, bool encrypted, address lovee) public payable returns (uint pos) {
        if (freeLockCreators[msg.sender] == false) {
            uint curPrice = getLockPrice(lockType);
            require(msg.value >= curPrice, "Payment is not enough");
        }

        require(bytes(text).length > 0, "Text length should be at least 1");
        require(lockType <= highestValidLockType, "You can only created a lock with a type that's allowed");
        
        locks.push(Lock(
            {
                BackgroundColor: backgroundColor, 
                LockColor: lockColor,
                LabelColor: labelColor,
                TextColor: textColor,
                LockType: lockType,
                Text: text,
                Encrypted: encrypted,
                Lovee: lovee
            }
        ));
        
        emit LockCreated(msg.sender, lovee, text);

        return locks.length - 1;
    }
    
    function getLockCount() public view returns (uint count) {
        return locks.length;
    }

    function getLocks() public view returns (Lock[] memory allLocks) {
        return locks;
    }

    function getLocksSet(uint start, uint count) public view returns (Lock[] memory lockSet) {
        Lock[] memory b = new Lock[](count);
        for (uint i=0; i < b.length; i++) {
            if (i + start < locks.length) {
                b[i] = locks[i + start];
            }
        }
        return b;
    }
}