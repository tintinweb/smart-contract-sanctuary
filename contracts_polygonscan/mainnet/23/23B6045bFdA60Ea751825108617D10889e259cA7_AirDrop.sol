// contracts/AirDrop.sol
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract AirDrop{
    mapping(address => bool) airdropLog;

    address _owner;
    uint256 amount;

    event AirDropped (
        address[] _recipients, 
        uint256 _amount);

    event AirdropFunded(
        uint256 _value
    );

    constructor(){
        amount = 200000000000000000;
        _owner = msg.sender;
    }

    function airDrop(address[] memory _recipients) external onlyOwner {
        require(address(this).balance > amount * _recipients.length);
        uint256 airdropped = 0;

        for (uint256 index = 0; index < _recipients.length; index++) {
            if (!airdropLog[_recipients[index]]) {
                airdropLog[_recipients[index]] = true;
                 (bool success, ) = payable(_recipients[index]).call{
                    value: amount
                }("");
                require(success, "Failed to send MATIC");
                airdropped = airdropped + amount;
            }
        }
        
        emit AirDropped(_recipients, amount);
    }

    /**
     * @dev Modifier to only allow owner to call functions
     */
    modifier onlyOwner() {
        require(_owner == msg.sender);
        _;
    }

    function fundAirdrop() public payable{
        emit AirdropFunded(msg.value);
    }
}