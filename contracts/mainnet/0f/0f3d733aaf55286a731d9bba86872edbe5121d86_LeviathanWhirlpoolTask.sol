/**
 *Submitted for verification at Etherscan.io on 2020-12-30
*/

pragma solidity <=0.6.2;

interface IRelease {
    function release() external;
}

interface IWhirlpool {
    function getAllInfoFor(address _user) external view returns (bool isActive, uint256[12] memory info);
}

contract LeviathanWhirlpoolTask {
    address private constant _leviathanWhirlpool = 0x4f2CCc35F791e763779f711168424b766Ba3468F;
    address private constant _whirlpool = 0x999b1e6EDCb412b59ECF0C5e14c20948Ce81F40b;

    function check(uint _requirement)
    external view returns (uint256) {
        (, uint256[12] memory userData) = IWhirlpool(_whirlpool).getAllInfoFor(_leviathanWhirlpool);

        if(userData[10] >= _requirement)
            return 0;
        else
            return _requirement - userData[10];
    }

    function execute()
    external {
        IRelease(_leviathanWhirlpool).release();
    }
}