/**
 *Submitted for verification at Etherscan.io on 2021-03-03
*/

/**
 *Submitted for verification at Etherscan.io on 2021-03-02
*/

// Copyright (C) 2020, 2021 Lev Livnev <[email protected]>
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

pragma solidity 0.5.12;

// https://github.com/dapphub/ds-token/blob/master/src/token.sol
interface DSTokenAbstract {
    function name() external view returns (bytes32);
    function symbol() external view returns (bytes32);
    function decimals() external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function balanceOf(address) external view returns (uint256);
    function transfer(address, uint256) external returns (bool);
    function allowance(address, address) external view returns (uint256);
    function approve(address, uint256) external returns (bool);
    function approve(address) external returns (bool);
    function transferFrom(address, address, uint256) external returns (bool);
    function push(address, uint256) external;
    function pull(address, uint256) external;
    function move(address, address, uint256) external;
    function mint(uint256) external;
    function mint(address,uint) external;
    function burn(uint256) external;
    function burn(address,uint) external;
    function setName(bytes32) external;
    function authority() external view returns (address);
    function owner() external view returns (address);
    function setOwner(address) external;
    function setAuthority(address) external;
}

contract RwaInputConduit {
    DSTokenAbstract public gov;
    DSTokenAbstract public dai;
    address public to;

    event Push(address indexed to, uint256 wad);

    constructor(address _gov, address _dai, address _to) public {
        gov = DSTokenAbstract(_gov);
        dai = DSTokenAbstract(_dai);
        to = _to;
    }

    function push() external {
        require(gov.balanceOf(msg.sender) > 0);
        uint256 balance = dai.balanceOf(address(this));
        emit Push(to, balance);
        dai.transfer(to, balance);
    }
}

contract RwaOutputConduit {
    // --- auth ---
    mapping (address => uint256) public wards;
    mapping (address => uint256) public can;
    function rely(address usr) external auth {
        wards[usr] = 1;
        emit Rely(usr);
    }
    function deny(address usr) external auth {
        wards[usr] = 0;
        emit Deny(usr);
    }
    modifier auth {
        require(wards[msg.sender] == 1, "RwaConduit/not-authorized");
        _;
    }
    function hope(address usr) external auth {
        can[usr] = 1;
        emit Hope(usr);
    }
    function nope(address usr) external auth {
        can[usr] = 0;
        emit Nope(usr);
    }
    modifier operator {
        require(can[msg.sender] == 1, "RwaConduit/not-operator");
        _;
    }

    DSTokenAbstract public gov;
    DSTokenAbstract public dai;

    address public to;
    mapping (address => uint256) public bud;

    // Events
    event Rely(address indexed usr);
    event Deny(address indexed usr);
    event Hope(address indexed usr);
    event Nope(address indexed usr);
    event Kiss(address indexed who);
    event Diss(address indexed who);
    event Pick(address indexed who);
    event Push(address indexed to, uint256 wad);

    constructor(address _gov, address _dai) public {
        wards[msg.sender] = 1;
        gov = DSTokenAbstract(_gov);
        dai = DSTokenAbstract(_dai);
        emit Rely(msg.sender);
    }

    // --- administration ---
    function kiss(address who) public auth {
        bud[who] = 1;
        emit Kiss(who);
    }
    function diss(address who) public auth {
        if (to == who) to = address(0);
        bud[who] = 0;
        emit Diss(who);
    }

    // --- routing ---
    function pick(address who) public operator {
        require(bud[who] == 1 || who == address(0), "RwaConduit/not-bud");
        to = who;
        emit Pick(who);
    }
    function push() external {
        require(to != address(0), "RwaConduit/to-not-set");
        require(gov.balanceOf(msg.sender) > 0, "RwaConduit/no-gov");
        uint256 balance = dai.balanceOf(address(this));
        emit Push(to, balance);
        dai.transfer(to, balance);
        to = address(0);
    }
}