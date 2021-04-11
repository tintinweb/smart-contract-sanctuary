/**
 *Submitted for verification at Etherscan.io on 2021-04-11
*/

/// VoteProxy.sol

// Copyright (C) 2018-2020 Maker Ecosystem Growth Holdings, INC.

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

// vote w/ a hot or cold wallet using a proxy identity
pragma solidity >=0.4.24;

interface TokenLike {
    function balanceOf(address) external view returns (uint256);
    function approve(address, uint256) external;
    function pull(address, uint256) external;
    function push(address, uint256) external;
}

interface ChiefLike {
    function GOV() external view returns (TokenLike);
    function IOU() external view returns (TokenLike);
    function deposits(address) external view returns (uint256);
    function lock(uint256) external;
    function free(uint256) external;
    function vote(address[] calldata) external returns (bytes32);
    function vote(bytes32) external;
}

contract VoteDelegate {
    address   public delegate;
    TokenLike public gov;
    TokenLike public iou;
    ChiefLike public chief;
    mapping (address => uint256) public balance;


    constructor(address _chief) public {
        chief = ChiefLike(_chief);
        delegate = msg.sender;
        gov = chief.GOV();
        iou = chief.IOU();
        gov.approve(address(chief), uint256(-1));
        iou.approve(address(chief), uint256(-1));
    }

    modifier auth() {
        require(msg.sender == delegate, "Sender must be the delegate");
        _;
    }

    function setDelegate(address _delegate) public auth returns (bool) {
        delegate = _delegate;
    }

    function lock(uint256 wad) public {
        gov.pull(msg.sender, wad);   // mkr from cold
        uint256 newBalance = balance[msg.sender]+wad;
        balance[msg.sender] = newBalance;
        chief.lock(wad);       // mkr out, ious in
        iou.push(msg.sender, wad);
    }

    function free(uint256 wad) public {
        require(balance[msg.sender] >= wad, "Not enough MKR locked");
        iou.pull(msg.sender, wad);
        uint256 newBalance = balance[msg.sender]-wad;
        balance[msg.sender] = newBalance;        
        chief.free(wad);       // ious out, mkr in
        gov.push(msg.sender, wad);   // mkr to cold
    }
    
    function freeAll() public {
        iou.pull(msg.sender, balance[msg.sender]);
        chief.free(balance[msg.sender]);
        gov.push(msg.sender, balance[msg.sender]);
    }

    function vote(address[] memory yays) public auth returns (bytes32) {
        return chief.vote(yays);
    }

    function vote(bytes32 slate) public auth {
        chief.vote(slate);
    }
}