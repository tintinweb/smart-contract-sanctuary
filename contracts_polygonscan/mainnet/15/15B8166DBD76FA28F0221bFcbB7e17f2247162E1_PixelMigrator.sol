/**
 *Submitted for verification at polygonscan.com on 2021-07-25
*/

//SPDX-License-Identifier: MIT
//  _____ _          _   _____            
// |  __ (_)        | | |_   _|           
// | |__) |__  _____| |   | |  _ __   ___ 
// |  ___/ \ \/ / _ \ |   | | | '_ \ / __|
// | |   | |>  <  __/ |  _| |_| | | | (__ 
// |_|   |_/_/\_\___|_| |_____|_| |_|\___| Migrator
//
// Flung together by BoringCrypto during COVID-19 lockdown in 2021
// Stay safe! 

// Alpha here https://bit.ly/3icxSru

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

interface IERC20 {
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
}

contract PixelMigrator {
    IERC20 pixel = IERC20(0x61E9c2F3501889f6167921087Bd6EA306002904a);

    struct MigrateEvent {
        uint256 blockNumber;
        address owner;
        uint256 amount;
    }

    MigrateEvent[] public events;
    mapping(address => uint256) public deposited;

    function Migrate(uint256 amount) public {
        // Is there something to burn?
        require(amount > 0, "PixelMigrator: Amount is 0");

        events.push(MigrateEvent({
            blockNumber: block.number,
            owner: msg.sender,
            amount: amount
        }));
        
        deposited[msg.sender] = deposited[msg.sender] + amount;

        // Transfer the PIXEL tokens from the user to this contract, where they will be locked forever
        require(pixel.transferFrom(msg.sender, address(this), amount), "PixelMigrator: Transfer failed");
    }
    
    function EventCount() public view returns (uint256 count) {
        count = events.length;
    }

    function MigratedSince(uint256 startBlock) public view returns (MigrateEvent[] memory result) {
        uint256 count = 0;
        for (uint256 i = 0; i < events.length; i++) {
            if (events[i].blockNumber >= startBlock) {
                count += 1;
            }
        }
        result = new MigrateEvent[](events.length);
        count = 0;
        for (uint256 i = 0; i < events.length; i++) {
            if (events[i].blockNumber >= startBlock) {
                result[count] = events[i];
                count += 1;
            }
        }
    }
}