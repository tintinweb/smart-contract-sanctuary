// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../0. base.sol";

// 學生成績表
// 1. 輸入學生名字、與成績
// 2. 可以使用名字來查詢成績
// 3. 能夠清除所有已經輸入過的成績
contract Student_Score is Base("\xe5\xad\xb8\xe7\x94\x9f\xe6\x88\x90\xe7\xb8\xbe\xe8\xa1\xa8") {

    // 成績表 map
    mapping(string => uint) _scores;
    // 姓名 array
    // 因為 mapping 只表明學生和其成績的關係, 故需要此陣列來記錄所有輸入的姓名
    string[] _names;

    // 新增學生成績
    function add(string memory name, uint score) public {
        _scores[name] = score;
        _names.push(name);
    }

    // 查詢學生成績
    function get(string memory name) public view returns (uint) {
        return _scores[name];
    }

    // 清除此成績表
    function reset() public {
        while (_names.length > 0) {
            // 上一個加入的學生明
            string memory last_one = _names[_names.length - 1];
            // 刪除 map
            delete _scores[last_one];
            // 刪除 array
            _names.pop();
        }
    }
}