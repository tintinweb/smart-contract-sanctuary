/**
 *Submitted for verification at Etherscan.io on 2021-06-27
*/

pragma solidity =0.6.6;

contract ViewTest {
    address private owner;
    uint private _seed;
    mapping(address => uint) private luckyNum;
    mapping(address => uint) private luckyNumTwo;

    modifier onlyOwner() {
        require(msg.sender == owner, "no access");
        _;
    }

    constructor() public {
        owner = msg.sender;
        _seed = block.number;
        luckyNum[msg.sender] = uint(msg.sender) % 1000;
        luckyNum[address(0)] = 666;
        luckyNumTwo[msg.sender] = uint(msg.sender) % 10000;
        luckyNumTwo[address(0)] = 6666;
    }

    function getMyAddress() external view returns(address) {
        return msg.sender;
    }

    function getLuckyNum() external view returns(uint) {
        return luckyNum[msg.sender];
    }

    function getLuckyNumTwo(address user) external view onlyOwner returns(uint) {
        return luckyNumTwo[user];
    }

    function getSeed() external view onlyOwner returns(uint) {
        return _seed;
    }

    function setSeed(uint seed) external onlyOwner returns(bool) {
        _seed = seed;
        return true;
    }
}