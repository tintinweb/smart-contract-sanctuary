/**
 *Submitted for verification at BscScan.com on 2021-07-24
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


// 
interface IBasisAsset {
    function mint(address recipient, uint256 amount) external returns (bool);

    function burn(uint256 amount) external;

    function burnFrom(address from, uint256 amount) external;

    function isOperator() external returns (bool);

    function operator() external view returns (address);

    function balanceOf(address addr) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external;
}

contract TokenMigration {

    IBasisAsset public oldChip = IBasisAsset(0x8d5728fe016A07743e18B54fBbE07E853BCa491c);
    IBasisAsset public oldFish = IBasisAsset(0x4FAB296f67fBaC741D4A1b884a5cAb96974C7cd8);
    IBasisAsset public oldMpea = IBasisAsset(0x117cC1e6C64C0830C587990b975612E2fcb9Ed22);

    IBasisAsset public newChip;
    IBasisAsset public newFish;
    IBasisAsset public newMpea;

    uint256 endTime;

    modifier canMigrate() {
        require(endTime > block.timestamp, "TokenMigration: Migration is finished");
        _;
    }

    constructor(IBasisAsset _newChip, IBasisAsset _newFish, IBasisAsset _newMpea, uint256 _endTime) {
        require(_endTime > block.timestamp, "TokenMigration: Invalid end time");
        newChip = _newChip;
        newFish = _newFish;
        newMpea = _newMpea;

        endTime = _endTime;
    }

    function migrateChip() external canMigrate {
        uint256 oldBalance = oldChip.balanceOf(msg.sender);
        oldChip.burnFrom(msg.sender, oldBalance);
        newChip.transfer(msg.sender, oldBalance);
    }

    function migrateFish() external canMigrate {
        uint256 oldBalance = oldFish.balanceOf(msg.sender);
        oldFish.burnFrom(msg.sender, oldBalance);
        newFish.transfer(msg.sender, oldBalance);
    }

    function migrateMpea() external canMigrate {
        uint256 oldBalance = oldMpea.balanceOf(msg.sender);
        oldMpea.burnFrom(msg.sender, oldBalance);
        newChip.transfer(msg.sender, oldBalance);
    }
}