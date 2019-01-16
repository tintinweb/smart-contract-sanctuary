pragma solidity ^0.4.25;
contract Owned {
    address public owner;
    constructor() public {
        owner = msg.sender;
    }
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    function setOwner(address _newOwner) public onlyOwner {
        owner = _newOwner;
    }
}

contract HackingLabTools{
    //Welcome To HackingLab.cn
    //TXkgV2VjaGF0IGlzIENwbHVzSHVhLCBubyBuZWVkIHRvIGhlc2l0YXRlLCBhZGQgbWUgbm93IQ==
    function hash(string data) public constant returns (string hashret){
        return bytes32ToString(keccak256(abi.encodePacked(data)));
        
    }
    function bytes32ToString(bytes32 x) public constant returns (string stringret) {
        bytes memory bytesString = new bytes(32);
        uint charCount = 0;
        for (uint j = 0; j < 32; j++) {
            byte char = byte(bytes32(uint(x) * 2 ** (8 * j)));
            if (char != 0) {
                bytesString[charCount] = char;
                charCount++;
            }
        }
        bytes memory bytesStringTrimmed = new bytes(charCount);
        for (j = 0; j < charCount; j++) {
            bytesStringTrimmed[j] = bytesString[j];
        }
        return string(bytesStringTrimmed);
    }
    function AddresstoString(address x) returns (string) {
        bytes memory b = new bytes(20);
        for (uint i = 0; i < 20; i++)
            b[i] = byte(uint8(uint(x) / (2**(8*(19 - i)))));
        return string(b);
    }
    function strConcat(string _a, string _b) internal returns (string){
        bytes memory _ba = bytes(_a);
        bytes memory _bb = bytes(_b);
        string memory ret = new string(_ba.length + _bb.length);
        bytes memory bret = bytes(ret);
        uint k = 0;
        for (uint i = 0; i < _ba.length; i++)bret[k++] = _ba[i];
        for (i = 0; i < _bb.length; i++) bret[k++] = _bb[i];
        return string(ret);
   } 
    function answerCompare(bytes32 _answer, bytes32 _user_answer) public constant returns (bool){
        bytes32 system_answer = keccak256(keccak256(_answer), abi.encodePacked(msg.sender));
        if(system_answer == _user_answer){
            return true;
        }
        return false;
    }
    function getKeccak256(uint256 _answer)public constant returns (bytes32){
        return keccak256(bytes32(_answer));
    }
    function getAddressAnserKeccak256(uint256 _answer)public constant returns (bytes32){
        return keccak256(keccak256(_answer), abi.encodePacked(msg.sender));
    }
}

contract AnswerToWin is Owned,HackingLabTools {
    uint256 private answer;

    function setAnswer(uint256 _answer) public onlyOwner{
        answer = _answer;
    }
    
    function guessAnswer(bytes32 _user_answer) public payable returns (bool){
        require(msg.value <= 5000000000 wei);
        if(answerCompare(bytes32(answer),_user_answer)){
            uint256 bonus = msg.value * 2;
            msg.sender.transfer(bonus);
            return true;
        }
        return false;
    }
    function transfer(address _to, uint256 _value) public  onlyOwner{
        _to.transfer(_value);
    }
  
}