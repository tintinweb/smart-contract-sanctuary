/**
 *Submitted for verification at Etherscan.io on 2022-01-25
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

contract HodlBank {
    struct SingleHodl {
        uint256 amount;
        uint256 createdAt;
        bool isWidrawn;
        uint256 widrawalTime;
        uint256 dateOfWidrawal;
    }

    mapping(address => SingleHodl[]) HodlRecords;

    function CreateHodl(uint256 _widrawlTime) external payable {
        require(msg.value > 0, "No value passed");
        require(_widrawlTime > block.timestamp, "Time has to be in future");

        // Create a new struct in the array of mapping
        HodlRecords[msg.sender].push(
            SingleHodl(
                msg.value,
                block.timestamp,
                false,
                _widrawlTime,
                block.timestamp
            )
        );
    }

    function WidrawHodl(uint256 _index) external payable {
        // check if the array has the record
        require(_index < HodlRecords[msg.sender].length, "No record was found");

        require(
            HodlRecords[msg.sender][_index].isWidrawn == false,
            "ETH has been widrawn"
        );
        require(
            block.timestamp > HodlRecords[msg.sender][_index].widrawalTime,
            "Time has not yet passed"
        );

        address payable current = payable(msg.sender);

        HodlRecords[msg.sender][_index].isWidrawn = true;
        HodlRecords[msg.sender][_index].dateOfWidrawal = block.timestamp;
        // current.transfer(HodlRecords[msg.sender][_index].amount);

        uint256 totalAmount = HodlRecords[msg.sender][_index].amount;
        current.transfer(totalAmount);
    }

    function getTime() public view returns (uint256) {
        return block.timestamp;
    }

    function getTransactions(address account)
        public
        view
        returns (SingleHodl[] memory)
    {
        return HodlRecords[account];
    }
}