pragma solidity 0.4.24;

contract Code {
    struct CodeFile {
        uint256 id;
        string fileName;
        string code;
        address owner;
    }

    mapping(address => CodeFile[]) public userCode;

    function addCode(string _fileName, string _code) public {
        require(bytes(_fileName)[0] != 0);
        require(bytes(_code)[0] != 0);

        uint256 myId = userCode[msg.sender].length;
        CodeFile memory myCodeFile = CodeFile(myId, _fileName, _code, msg.sender);
        userCode[msg.sender].push(myCodeFile);
    }

    function getLength() public view returns(uint256) {
        return userCode[msg.sender].length;
    }
}