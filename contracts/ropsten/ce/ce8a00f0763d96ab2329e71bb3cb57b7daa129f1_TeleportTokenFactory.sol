pragma solidity ^0.8.6;
/*
 * SPDX-License-Identifier: MIT
 */
pragma experimental ABIEncoderV2;

// import "hardhat/console.sol";
import "./TeleportToken.sol";

contract TeleportTokenFactory is Owned, Oracled {
    TeleportToken[] public teleporttokens;
    uint256 public creationFee = 0.01 ether;

    // Payable constructor can receive Ether
    constructor() payable {
    }

    // Function to deposit Ether into this contract.
    // Call this function along with some Ether.
    // The balance of this contract will be automatically updated.
    function deposit() public payable {}

    // Call this function along with some Ether.
    // The function will throw an error since this function is not payable.
    function notPayable() public {}

    // Function to withdraw all Ether from this contract.
    function withdraw() onlyOwner public {
        // get the amount of Ether stored in this contract
        uint amount = address(this).balance;

        // send all Ether to owner
        // Owner can receive Ether since the address of owner is payable
        (bool success, ) = owner.call{value: amount}("");
        require(success, "Failed to send Ether");
    }

    // Function to receive Ether. msg.data must be empty
    receive() external payable {}

    // Fallback function is called when msg.data is not empty
    fallback() external payable {}

    function getBalance() public view returns (uint) {
        return address(this).balance;
    }

    function create(
        string memory _symbol,
        string memory _name,
        uint8 _decimals,
        uint256 __totalSupply,
        uint8 _threshold,
        uint8 _thisChainId
    ) public payable {
        // correct fee
        require(msg.value == creationFee, "Wrong fee");
        TeleportToken tt = new TeleportToken(
            _symbol,
            _name,
            _decimals,
            __totalSupply,
            _threshold,
            _thisChainId
        );

        uint oraclesLength = oraclesArr.length;
        for (uint i = 0; i < oraclesLength; i++) {
            tt.regOracle(oraclesArr[i]);
        }
        tt.transferOwnership(msg.sender);

        teleporttokens.push(tt);
    }

    function getTokenAddress(uint256 _index)
        public
        view
        returns (
            address ttAddress
        )
    {
        TeleportToken tt = teleporttokens[_index];

        return (
            address(tt)
        );
    }

    function setFee(uint256 _fee) public onlyOwner {
        creationFee = _fee;
    }

}