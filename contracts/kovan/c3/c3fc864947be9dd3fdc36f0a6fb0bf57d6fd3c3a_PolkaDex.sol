// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;
import "./ERC20.sol";

contract PolkaDex is ERC20 {
    address payable Owner;
    uint256  immutable InitialBlockNumber ;

    constructor() ERC20("Polkadex", "PDEX") {
        mainHolder();
        Owner = msg.sender;
        InitialBlockNumber = block.number;
    }

    function ClaimAfterVesting() public {
        // The second tranch of vesting happens after 3 months (1 quarter = (3*30*24*60*60)/13.14 blocks) from TGE
        require(block.number > InitialBlockNumber + 591781, "Time to claim vested tokens has not reached");
        require(VestedTokens[msg.sender] > 0, "You are not eligible for claim");
        _mint(msg.sender, VestedTokens[msg.sender]);
        VestedTokens[msg.sender] = 0;
    }

    modifier OnlyOwner {
        require(msg.sender == Owner, "unauthorized access");
        _;
    }
    function TransferOwnerShip(address payable NewAddress) public OnlyOwner {
        require(NewAddress!=address(0),"TransferOwnerShip Denied");
        Owner = NewAddress;
    }

    function ShowOwner() public view returns (address) {
        return Owner;
    }
}