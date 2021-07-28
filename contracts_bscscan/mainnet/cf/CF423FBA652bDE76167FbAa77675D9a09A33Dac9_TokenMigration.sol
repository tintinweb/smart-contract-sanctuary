/**
 *Submitted for verification at BscScan.com on 2021-07-28
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

    IBasisAsset public oldChip = IBasisAsset(0x7a4Feb21b86281F7D345dEDE500c9C51881b948B);
    IBasisAsset public oldFish = IBasisAsset(0xD47c524ae4Cf0f941D0Dd03b44CD9C80dd4238d6);
    IBasisAsset public oldMpea = IBasisAsset(0x23A47619f784F109582f07C01D8a72512ba9D0E1);

    IBasisAsset public newChip;
    IBasisAsset public newFish;

    uint256 public endTime;

    modifier canMigrate() {
        require(block.timestamp <= endTime, "TokenMigration: Migration is finished");
        _;
    }

    constructor(IBasisAsset _newChip, IBasisAsset _newFish, uint256 _endTime) {
        require(_endTime > block.timestamp, "TokenMigration: Invalid end time");
        newChip = _newChip;
        newFish = _newFish;

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

    function burn() external {
        require(block.timestamp > endTime, "TokenMigration: not finished");
        newChip.burn(newChip.balanceOf(address(this)));
        newFish.burn(newFish.balanceOf(address(this)));
    }
}