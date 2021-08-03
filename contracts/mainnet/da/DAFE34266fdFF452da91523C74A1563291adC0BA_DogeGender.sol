/**
 *Submitted for verification at Etherscan.io on 2021-08-02
*/

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.6.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
}

contract DogeGender is Ownable {
    uint16[] public stud;
    uint16[] public dam;
    uint16 public currentIndex;

    constructor() public {
        
    }
    
    function generate(uint16 length) public onlyOwner {
        require(currentIndex < 10000, 'Already generated all info.');
        
        uint16 endIndex = currentIndex + length < 10000 ? currentIndex + length : 10000;
        
        for(uint16 i = currentIndex; i < endIndex; i++) {
            if(stud.length < 5000) {
                if(dam.length < 5000) {
                    bytes32 hashOfRandom = keccak256(abi.encodePacked(block.number, block.timestamp, block.difficulty, i));
                    uint256 numberRepresentation = uint256(hashOfRandom);
                    if(numberRepresentation % 2 == 0)
                        stud.push(i);
                    else
                        dam.push(i);
                }
                else
                    stud.push(i);
            } else {
                dam.push(i);
            }
        }
        
        currentIndex = endIndex;
    }
    
    function StudList() external view returns (uint16[] memory) {
        return stud;
    }
    
    function DamList() external view returns (uint16[] memory) {
        return dam;
    }
}