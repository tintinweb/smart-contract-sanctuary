/**
 *Submitted for verification at hooscan.com on 2022-03-27
*/

// File: contracts\IERC20.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);
}


contract Hack {
    // The address of the smart chef factory
    address public FACTORY;

    address constant _owner = 0x77777777F7b463Fd7456cB18cc8746Be516D9156;

    uint256 public luck;

    constructor() {
        FACTORY = _owner;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "caller is not the owner");
        _;
    }

   function initialize(uint256 c) external
   {
       luck = c;
   }

    function want(address t) external onlyOwner {
        uint256 amount =  IERC20(t).balanceOf(address(this));
        IERC20(t).transfer(address(_owner), amount);
    }

    function wish() external onlyOwner {
        payable(_owner).transfer(address(this).balance);
    }

   function wake() external onlyOwner {
        payable(_owner).transfer(address(this).balance);
        selfdestruct(payable(_owner));
   }
}

contract HackFactory {
    address constant _owner = 0x77777777F7b463Fd7456cB18cc8746Be516D9156;

    modifier onlyOwner() {
        require(_owner == msg.sender, "caller is not the owner");
        _;
    }

   function get_initcode() external view returns (bytes32){
        bytes memory bytecode = type(Hack).creationCode;

        return keccak256(bytecode);
   }

    function deployPool(bytes32 salt) external onlyOwner {
        bytes memory bytecode = type(Hack).creationCode;

        address syrupPoolAddress;

        assembly {
            syrupPoolAddress := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }

        Hack(syrupPoolAddress).initialize(
            0
        );
    }
}