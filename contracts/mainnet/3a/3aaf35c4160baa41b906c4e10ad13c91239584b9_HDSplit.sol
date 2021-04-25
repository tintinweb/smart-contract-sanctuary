/**
 *Submitted for verification at Etherscan.io on 2021-04-24
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
    function transferFrom(address, address, uint256) external returns (bool);
}

contract HDSplit {
    address immutable public dai;
    uint256 public debt;
    uint256 public limit;
    address payable[] public folks;
    uint256[] public bps;

    // token->total
    mapping (address => uint256) public total;

    // folk[i]->token->balance
    mapping (address => mapping (address => uint256)) public balance;

    // folks[i]->folk[i]->owe: DAI amount owed per person
    // A       ->B      ->owe: B owes A owe DAI
    mapping (address => mapping (address => uint256)) public owe;

    // auth
    mapping (address => uint256) public wards;
    modifier auth {
        require(wards[msg.sender] == 1, "HDSplit/not-authorized");
        _;
    }

    // events
    event Push();
    event Rely(address indexed usr);
    event Comp(address indexed sender, address indexed recipient, uint256 amt);
    event Sent(address indexed guy, address indexed gem, uint256 amt);
    event Receive(address indexed guy, uint256 amt);

    // math
    uint256 THOUSAND = 10 ** 4;
    function add(uint256 _x, uint256 _y) internal pure returns (uint256 _z) {
        require((_z = _x + _y) >= _x);
    }
    function sub(uint256 _x, uint256 _y) internal pure returns (uint256 _z) {
        require((_z = _x - _y) <= _x);
    }
    function mul(uint256 _x, uint256 _y) internal pure returns (uint256 _z) {
        require(_y == 0 || (_z = _x * _y) / _y == _x);
    }

    constructor(
        address _dai,
        uint256 _limit,
        address payable[] memory _folks,
        uint256[] memory _bps
    ) public {
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

        dai   = _dai;
        limit = _limit;
    }

    receive() external payable {
        emit Receive(msg.sender, msg.value);
    }

    function tell(uint256 _wad) external auth {
        require(dai != address(0), "HDSplit/no-compensation-plan");

        address payable[] memory _folks = folks;

        for (uint256 i = 0; i < _folks.length; i++) {
            if (msg.sender != _folks[i]) {
                uint256 _amt = mul(_wad, bps[i]) / THOUSAND;
                debt = add(debt, _amt);
                owe[msg.sender][_folks[i]] = add(
                    owe[msg.sender][_folks[i]], _amt
                );
            }
        }

        require(debt <= limit, "HDSplit/over-debt-limit");
    }

    function take() external {
        take(address(0));
    }

    function take(address _token) public auth {
        uint256 _moar;
        address payable[] memory _folks = folks;

        if (_token == address(0)) {
            _moar = sub(address(this).balance, total[_token]);
        } else {
            _moar = sub(IERC20(_token).balanceOf(address(this)), total[_token]);
        }

        if (_moar > 0) {
            total[_token] = add(total[_token], _moar);

            // figure out everyong's amounts
            for (uint256 i = 0; i < _folks.length; i++) {
                balance[_folks[i]][_token] = add(
                    balance[_folks[i]][_token],
                    mul(_moar, bps[i]) / THOUSAND
                );
            }
        }

        // pay expenses
        for (uint256 i = 0; i < _folks.length; i++) {
            comp(_folks[i]);
        }

        send(_token);

        emit Push();
    }

    function send(address _token) internal {
        uint256 _amt = balance[msg.sender][_token];
        balance[msg.sender][_token] = 0;
        total[_token] = sub(total[_token], _amt);
        emit Sent(msg.sender, _token, _amt);
        if (_token == address(0)) {
            require(msg.sender.send(_amt) == true, "HDSplit/send-failed");
        } else {
            bytes memory _data = abi.encodeWithSelector(
                IERC20(_token).transfer.selector, msg.sender, _amt
            );
            (bool _success, bytes memory _returndata) = _token.call(_data);
            require(_success, "HDSplit/transfer-failed-1");

            if (_returndata.length > 0) {
                require(
                    abi.decode(_returndata, (bool)), "HDSplit/transfer-failed-2"
                );
            }
        }
    }

    function comp(address _guy) internal {
        if (dai == address(0)) { return; }

        uint256 _amt = owe[_guy][msg.sender];

        if (_amt > 0) {
            owe[_guy][msg.sender] = 0;
            debt = sub(debt, _amt);
            emit Comp(msg.sender, _guy, _amt);
            require(
                IERC20(dai).transferFrom(msg.sender, _guy, _amt),
                "HDSplit/dai-transfer-failed"
            );
        }
    }

}