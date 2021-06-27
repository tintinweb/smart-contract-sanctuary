/**
 *Submitted for verification at Etherscan.io on 2021-06-27
*/

pragma solidity =0.6.6;

contract ViewTest {
    address private owner;
    uint private _seed;
    mapping(address => uint) private luckyNum;

    modifier onlyOwner() {
        require(msg.sender == owner, "no access");
        _;
    }

    constructor() public {
        owner = msg.sender;
        _seed = block.number;
        luckyNum[msg.sender] = uint(msg.sender) % 1000;
        luckyNum[address(0)] = 666;
    }

    function getLuckyNum() external view onlyOwner returns(uint) {
        return luckyNum[msg.sender];
    }

    function getSeed() external view onlyOwner returns(uint) {
        return _seed;
    }

    function setSeed(uint seed) external onlyOwner returns(bool) {
        _seed = seed;
        return true;
    }
}