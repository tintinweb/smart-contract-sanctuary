// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;
import "./ERC20.sol";

contract PolkaDex is ERC20 {
    address payable Owner;
    uint256 InitialBlockNumber;

    constructor() ERC20("PolkaDex", "PDEX") {
        MainHolder();
        Owner = msg.sender;
        InitialBlockNumber = block.number;
    }

    function ClaimAfterVesting() public {
        //change 25 to require blocknumber from launching block for example if u deploy contract on 100 block number and you want to excute function after 175 you have to write InitialBlockNumber+75
        
        /** 
        // ! NOTE: CHANGE 25 BEFORE DEPLOYMENT
        //
        */
        
        require(block.number > InitialBlockNumber + 25, "Time to claim vested tokens has not reached"); 
        require(VestedTokens[msg.sender] > 0, "You are not eligible for claim");
        _mint(msg.sender, VestedTokens[msg.sender]);
        VestedTokens[msg.sender] = 0;
    }

    modifier OnlyOwner {
        require(msg.sender == Owner, "unautorized access");
        _;
    }

    function DestructToken() public OnlyOwner {
        selfdestruct(msg.sender);
    }

    function TransferOwnerShip(address payable NewAddress) public OnlyOwner {
        Owner = NewAddress;
    }

    function ShowOwner() public view returns (address) {
        return Owner;
    }

    function disable() public OnlyOwner {
        IsEnd = true;
    }
}