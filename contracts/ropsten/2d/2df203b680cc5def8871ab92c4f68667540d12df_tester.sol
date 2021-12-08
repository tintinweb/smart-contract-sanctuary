/**
 *Submitted for verification at Etherscan.io on 2021-12-08
*/

pragma solidity ^0.8;

contract tester {
    uint256 public totalSupply = 1;

    event Minted(uint256 _amount, address indexed _address);

    constructor () payable {
        require(msg.value == 0.0 ether, "Ether needed.");
    }

    receive() external payable {
        require(totalSupply < 10, "All minted.");

        if(msg.value == 0.005 ether) {
            emit Minted(1, msg.sender);
            totalSupply += 1;   
        }
        else if(msg.value == 0.01 ether) {
            emit Minted(2, msg.sender);
            totalSupply += 2;   
        }
        else if(msg.value == 0.015 ether) {
            emit Minted(3, msg.sender);
            totalSupply += 3;          
        }
    }

    fallback(bytes calldata) external payable returns(bytes memory){
        return msg.data;
    }

    function pay() public payable {
        require(totalSupply < 10, "All minted.");

        emit Minted(msg.value, msg.sender);

        totalSupply += 1;   
    }   
}