interface ILottery {

}

interface IOracle {
    function getRandomNumber() external returns (uint256);
}

contract Attacker {
    IOracle oracle;

    constructor() public {
        oracle = IOracle(0x90649B117656e54aB4F2592c1E83e7145Eae1290);
    }

    event LogRandomNumber(uint256 n);

    function getRandomNumber() external returns (uint256) {
        uint256 n = oracle.getRandomNumber();
        emit LogRandomNumber(n);
        return n;
    }
}