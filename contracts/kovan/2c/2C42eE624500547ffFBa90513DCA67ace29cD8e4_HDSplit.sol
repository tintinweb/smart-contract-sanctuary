/**
 *Submitted for verification at Etherscan.io on 2021-04-07
*/

// SPDX-License-Identifier: GPL-3.0-or-later

/// split.sol -- splits funds sent to this contract

// Copyright (C) 2021 HDSplit

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.6.12;

interface IERC20 {
    function balanceOf(address) external view returns (uint256);
    function transfer(address, uint256) external returns (bool);
}

contract HDSplit {
    address payable[] public folks;
    uint256[] public bps;

    // auth
    mapping (address => uint256) public wards;
    modifier auth {
        require(wards[msg.sender] == 1, "HDSplit/not-authorized");
        _;
    }

    // events
    event Push();
    event Rely(address indexed usr);
    event Sent(address indexed guy, address indexed gem, uint256 amt);
    event Receive(address indexed guy, uint256 amt);

    // math
    uint256 THOUSAND = 10 ** 4;
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x);
    }
    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x);
    }

    constructor(address payable[] memory _folks, uint256[] memory _bps) public {
        require(_folks.length == _bps.length, "HDSplit/length-must-match");

        uint256 _total;

        for (uint256 i = 0; i < _folks.length; i++) {
            _total = add(_total, _bps[i]);
            folks.push(_folks[i]);
            bps.push(_bps[i]);
            wards[_folks[i]] = 1;
            emit Rely(_folks[i]);
        }

        require(_total == 10000, "HDSplit/basis-points-must-total-10000");
    }

    receive() external payable {
        emit Receive(msg.sender, msg.value);
    }

    function push() external {
        push(address(0));
    }

    function push(address _token) public auth {
        address payable _addr;
        uint256[] memory _amts = new uint256[](folks.length);

        if (_token == address(0)) {
            // figure out ETH amounts first
            for (uint256 i = 0; i < folks.length; i++) {
                _amts[i] = mul(address(this).balance, bps[i]) / THOUSAND;
            }

            // send ETH to folks
            for (uint256 i = 0; i < folks.length; i++) {
                _addr = folks[i];
                emit Sent(_addr, _token, _amts[i]);
                require(_addr.send(_amts[i]) == true, "HDSplit/send-failed");
            }
        } else {
            // figure out token amounts first
            for (uint256 i = 0; i < folks.length; i++) {
                _amts[i] = mul(IERC20(_token).balanceOf(address(this)), bps[i])
                    / THOUSAND;
            }

            // send token to folks
            for (uint256 i = 0; i < folks.length; i++) {
                _addr = folks[i];
                emit Sent(_addr, _token, _amts[i]);
                IERC20(_token).transfer(_addr, _amts[i]);
            }
        }

        emit Push();
    }
}