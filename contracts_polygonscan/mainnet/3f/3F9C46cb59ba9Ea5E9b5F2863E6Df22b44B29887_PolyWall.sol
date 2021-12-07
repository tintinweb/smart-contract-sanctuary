// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


contract PolyWall {

    struct Line {
        string str;
        uint edits;
        address lastEditor;
    }

    struct ExportLine {
        int uid;
        string str;
        uint edits;
    }

    mapping(int => Line) lines;
    mapping(address => uint) _pendingMatic;

    uint public LINE_LENGTH;
    uint public LINE_PRICE;

    event LineUpdated(int indexed uid, string str, uint edits);

    address public devAddress;

    constructor (uint lineLength, uint linePrice)
    {
        LINE_LENGTH = lineLength;
        LINE_PRICE = linePrice;
        devAddress = msg.sender;
    }

    function uploadLines(string[] calldata strings, int[] calldata uids) public payable {
        require(strings.length == uids.length, "Arrays lengths do not match");
        uint value = msg.value;

        for (uint i = 0; i < strings.length; i++) {
            require(bytes(strings[i]).length <= LINE_LENGTH, "Unexpected line length");

            uint thisPrice = lines[uids[i]].edits * LINE_PRICE;

            require(value >= thisPrice, "Not enough funds");

            value -= thisPrice;

            if (thisPrice > 0) {
                uint devReward = thisPrice / 10;
                uint lastEditorReward = thisPrice - devReward;
                _pendingMatic[devAddress] += devReward;
                _pendingMatic[lines[uids[i]].lastEditor] += lastEditorReward;
            }

            lines[uids[i]].str = strings[i];
            lines[uids[i]].edits++;


            lines[uids[i]].lastEditor = msg.sender;

            emit LineUpdated(uids[i], lines[uids[i]].str, lines[uids[i]].edits);
        }
    }

    function getLines(int startIndex, int amount) public view returns (ExportLine[] memory out){
        require(amount > 0, "Negative or null amount");

        out = new ExportLine[](uint(amount));

        for (int i = startIndex; i < startIndex + amount; i++) {
            Line memory _line = lines[i];
            out[uint(i - startIndex)].uid = i;
            out[uint(i - startIndex)].str = _line.str;
            out[uint(i - startIndex)].edits = _line.edits;
        }

        return out;
    }

    function getLinesUnordered(int[] calldata uids) public view returns (ExportLine[] memory out){
        out = new ExportLine[](uids.length);

        for (uint i = 0; i < uids.length; i++) {
            int uid = uids[i];
            Line memory _line = lines[uid];
            out[i].uid = uid;
            out[i].str = _line.str;
            out[i].edits = _line.edits;
        }

        return out;
    }

    function abs(int x) private pure returns (int) {
        return x >= 0 ? x : - x;
    }

    function pendingMatic(address addr) public view returns (uint) {
        return _pendingMatic[addr];
    }

    function withdraw() public {
        require(_pendingMatic[msg.sender] > 0, "Nothing to withdraw");
        uint amount = _pendingMatic[msg.sender];
        _pendingMatic[msg.sender] = 0;
        (bool success,) = payable(msg.sender).call{value : amount}("");
        require(success, "Transfer failed.");
    }
}