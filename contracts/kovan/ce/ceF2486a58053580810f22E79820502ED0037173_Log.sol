/**
 *Submitted for verification at Etherscan.io on 2021-12-05
*/

pragma solidity ^0.8.0;

contract Log {
    struct Log {
        string ActionTo;
        string UserName;
        uint256 Id;
        string ActionFor;
        address TxOrigin;
        uint256 Timestamp;
        uint256 blockNum;
        address MsgSender;
        bool ifSuccess;
    }

    Log[] logs;

    function addLog(string memory _actionTo, string memory _actionFor, address _msgSender, uint256 _id, bool _ifSuccess) external {
        Log memory log = Log(_actionTo, "", _id, _actionFor, tx.origin, block.timestamp, block.number, _msgSender, _ifSuccess);
        logs.push(log);
    }

    function addLog_User(string memory _actionTo, string memory _actionFor, address _msgSender, string memory _name, bool _ifSuccess) external {
        Log memory log = Log(_actionTo, _name, 0, _actionFor, tx.origin, block.timestamp, block.number, _msgSender, _ifSuccess);
        logs.push(log);
    }

    //TODO:合约交互：管理员可以获取日志信息
    function getMyLog() public returns (Log[] memory){

        uint j = 0;
        uint sum = 0;
        for (uint i = 0; i < logs.length; i++) {
            if (logs[i].MsgSender == msg.sender) {
                sum++;
            }
        }
        Log[] memory retLogs = new Log[](sum);
        for (uint i = 0; i < logs.length; i++) {
            if (logs[i].MsgSender == msg.sender) {
                retLogs[j] = logs[i];
                j++;
            }
        }
        return retLogs;
    }

    function getCourseLog(uint256 _courseId) public returns (Log[] memory){
        uint j = 0;
        uint sum = 0;
        for (uint i = 0; i < logs.length; i++) {
            if (hashCompareInternal(logs[i].ActionTo, "Course") && logs[i].Id == _courseId) {
                sum++;
            }
        }
        Log[] memory retLogs = new Log[](sum);
        for (uint i = 0; i < logs.length; i++) {
            if (hashCompareInternal(logs[i].ActionTo, "Course") && logs[i].Id == _courseId) {
                retLogs[j] = logs[i];
                j++;
            }
        }
        return retLogs;

    }

    function getExperimentLog(uint256 _experimentId) public returns (Log[] memory){
        uint j = 0;
        uint sum = 0;
        for (uint i = 0; i < logs.length; i++) {
            if (hashCompareInternal(logs[i].ActionTo, "Experiment") && logs[i].Id == _experimentId) {
                sum++;
            }
        }
        Log[] memory retLogs = new Log[](sum);
        for (uint i = 0; i < logs.length; i++) {
            if (hashCompareInternal(logs[i].ActionTo, "Experiment") && logs[i].Id == _experimentId) {
                retLogs[j] = logs[i];
                j++;
            }
        }
        return retLogs;
    }

    function hashCompareInternal(string memory a, string memory b) internal pure returns (bool) {
        return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
    }

    function getUserLog(address _userAddress) public returns (Log[] memory){
        uint j = 0;
        uint sum = 0;
        for (uint i = 0; i < logs.length; i++) {
            if (hashCompareInternal(logs[i].ActionTo, "User") && logs[i].MsgSender == _userAddress) {
                sum++;
            }
        }
        Log[] memory retLogs = new Log[](sum);
        for (uint i = 0; i < logs.length; i++) {
            if (hashCompareInternal(logs[i].ActionTo, "User") && logs[i].MsgSender == _userAddress) {
                retLogs[j] = logs[i];
                j++;
            }
        }
        return retLogs;

    }
}