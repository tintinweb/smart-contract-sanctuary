/**
 *Submitted for verification at polygonscan.com on 2021-12-27
*/

// Verified using https://dapp.tools

// hevm: flattened sources of /nix/store/lqfvmi1l4qw2x0zz33hxkj4icxkn6fx5-geb-polling-emitter/dapp/geb-polling-emitter/src/GebPollingEmitter.sol

pragma solidity >=0.6.7 <0.7.0;

////// /nix/store/lqfvmi1l4qw2x0zz33hxkj4icxkn6fx5-geb-polling-emitter/dapp/geb-polling-emitter/src/GebPollingEmitter.sol
// Copyright (C) 2016-2020 Maker Ecosystem Growth Holdings, INC

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

/* pragma solidity ^0.6.7; */

contract GebPollingEvents {
    event PollCreated(
        address indexed creator,
        uint256 blockCreated,
        uint256 indexed pollId,
        uint256 startDate,
        uint256 endDate,
        string multiHash,
        string url
    );

    event PollWithdrawn(
        address indexed creator,
        uint256 blockWithdrawn,
        uint256 pollId
    );

    event Voted(
        address indexed voter,
        uint256 indexed pollId,
        uint256 indexed optionId
    );
}

contract GebPollingEmitter is GebPollingEvents {
    uint256 public npoll;

    function createPoll(uint256 startDate, uint256 endDate, string calldata multiHash, string calldata url)
        external
    {
        uint256 startDate_ = startDate > now ? startDate : now;
        require(endDate > startDate_, "GebPollingEmitter/polling-invalid-poll-window");
        emit PollCreated(
            msg.sender,
            block.number,
            npoll,
            startDate_,
            endDate,
            multiHash,
            url
        );
        require(npoll < uint(-1), "GebPollingEmitter/polling-too-many-polls");
        npoll++;
    }

    function withdrawPoll(uint256 pollId)
        external
    {
        emit PollWithdrawn(msg.sender, block.number, pollId);
    }

    function vote(uint256 pollId, uint256 optionId)
        external
    {
        emit Voted(msg.sender, pollId, optionId);
    }

    function withdrawPoll(uint256[] calldata pollIds)
        external
    {
        for (uint i = 0; i < pollIds.length; i++) {
            emit PollWithdrawn(msg.sender, pollIds[i], block.number);
        }
    }

    function vote(uint256[] calldata pollIds, uint256[] calldata optionIds)
        external
    {
        require(pollIds.length == optionIds.length, "GebPollingEmitter/non-matching-length");
        for (uint i = 0; i < pollIds.length; i++) {
            emit Voted(msg.sender, pollIds[i], optionIds[i]);
        }
    }
}