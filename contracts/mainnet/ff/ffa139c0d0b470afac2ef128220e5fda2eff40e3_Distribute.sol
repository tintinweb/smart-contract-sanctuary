pragma solidity ^0.4.25;

interface token {
    function transfer(address receiver, uint amount) external;
    function burn(uint256 _value) external returns (bool);
    function balanceOf(address _address) external returns (uint256);
}
contract owned {
    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
    }
}


contract Distribute is owned {

    token public tokenReward;

    /**
     * Constructor function
     *
     * Setup the owner
     */
    constructor() public {
        tokenReward = token(0x5fA34CE3D7D05e858b50bB38afa91C8b1a045688); //Token address. Modify by the current token address
    }

    function changeTokenAddress(address newAddress) onlyOwner public{
        tokenReward = token(newAddress);
    }


    function airdrop(address[] participants, uint totalAmount) onlyOwner public{ //amount with decimals
        require(totalAmount<=tokenReward.balanceOf(this));
        uint amount;
        for(uint i=0;i<participants.length;i++){
            amount = totalAmount/participants.length;
            tokenReward.transfer(participants[i], amount);
        }
    }

    function bounty(address[] participants, uint[] amounts) onlyOwner public{ //Array of amounts with decimals
        require(participants.length==amounts.length);
        for(uint i=0; i<participants.length; i++){
            tokenReward.transfer(participants[i], amounts[i]);
        }

    }
}