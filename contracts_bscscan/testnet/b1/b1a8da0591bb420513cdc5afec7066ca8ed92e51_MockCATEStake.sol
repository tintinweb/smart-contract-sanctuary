/**
 *Submitted for verification at BscScan.com on 2021-12-13
*/

/**
 *Submitted for verification at BscScan.com on 2021-12-09
*/

// Sources flattened with hardhat v2.7.0 https://hardhat.org

// File contracts/ICATEStake.sol

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.9;

// define query stake data interface for https://bscscan.com/address/0x2f9fbb154e6c3810f8b2d786cb863f8893e43354#code
interface ICATEStake {
    // the Stake
    struct Stake {
        // opening timestamp
        uint256 startDate;
        // amount staked
        uint256 amount;
        // interest accrued, this will be available only after closing stake
        uint256 interest;
        // penalty charged, if any
        uint256 penalty;
        // closing timestamp
        uint256 finishedDate;
        // is closed or not
        bool closed;
    }

    // stakes that the owner have
    function stakesOfOwner(address account, uint256 inx) external view returns (uint256, uint256, uint256, uint256, uint256, bool);
    function stakesOfOwnerLength(address account) external view returns (uint256);
}


// File contracts/MockCATEStake.sol

pragma solidity 0.8.9;
contract MockCATEStake is ICATEStake {
    // stakes that the owner have    
    mapping(address => Stake[]) public stakesOfOwner;

    function stakesOfOwnerLength(address owner_address) public view override returns (uint256) {
        return stakesOfOwner[owner_address].length;
    }

    function addStakeData(address _user, uint256 _startData, uint256 _endData, uint256 _amount, bool _closed) public  {
        stakesOfOwner[_user].push(Stake(_startData, _amount, 0, 0, _endData, _closed));
    }
}