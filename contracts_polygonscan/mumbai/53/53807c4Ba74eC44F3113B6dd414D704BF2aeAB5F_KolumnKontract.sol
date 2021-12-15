/**
 *Submitted for verification at polygonscan.com on 2021-12-14
*/

// SPDX-License-Identifier: GPL
pragma solidity ^0.8.0;

contract KolumnKontract {
    //Kolumn Structure
    struct Kolumn {
        uint256 id;
        string title;
        string content;
        string timestamp;
        uint256 tips;
        address payable author;
    }

    uint256 public kolumnKount = 0;
    mapping(uint256 => Kolumn) public kolumns;

    //Add a new Kolumn
    function createKolumn(
        string memory _title,
        string memory _content,
        string memory _timestamp
    ) public {
        require(msg.sender != address(0x0));
        require(bytes(_title).length * bytes(_content).length > 0);
        kolumnKount++;
        kolumns[kolumnKount] = Kolumn(
            kolumnKount,
            _title,
            _content,
            _timestamp,
            0,
            payable(msg.sender)
        );
    }

    //View Kolumn by ID
    function viewKolumn(uint256 _id)
        public
        view
        returns (Kolumn memory kolumn)
    {
        kolumn = kolumns[_id];
    }

    //View Latest Columns
    function viewLatestKolumns(uint256 _flag)
        public
        view
        returns (Kolumn[] memory)
    {
        //Kolumns browsed
        uint256 _localLatest = (_flag - 1) * 10;
        require(kolumnKount > _localLatest);
        //Start Sending Kolumns from
        _localLatest = kolumnKount - _localLatest;
        uint256 _counter = 0;
        if (_localLatest > 10) {
            Kolumn[] memory _latestKolumns = new Kolumn[](10);
            for (uint256 i = _localLatest; i > (_localLatest - 10); i--) {
                _latestKolumns[_counter] = kolumns[i];
                _counter++;
            }
            return _latestKolumns;
        } else {
            Kolumn[] memory _latestKolumns = new Kolumn[](_localLatest);
            for (uint256 i = _localLatest; i > 0; i--) {
                _latestKolumns[_counter] = kolumns[i];
                _counter++;
            }
            return _latestKolumns;
        }
    }
}