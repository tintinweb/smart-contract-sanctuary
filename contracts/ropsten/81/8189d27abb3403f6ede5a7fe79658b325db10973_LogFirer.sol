/**
 *Submitted for verification at Etherscan.io on 2021-05-21
*/

contract LogFirer {
    event RandomB(bytes32 indexed a, uint256 b, uint256 c) anonymous;
    event RandomA(bytes32 a, uint256 b, uint256 c) anonymous;

    uint256 counter;
    bytes32 rand;

    fallback() external {
        bytes32 _rand = rand;
        uint256 _counter = counter;

        for (uint256 i = 0; i < 20; i++) {
            _rand = keccak256(abi.encodePacked(_rand, msg.sender, block.number));
            emit RandomA(_rand, i, _counter + i);
            emit RandomB(_rand, i, _counter + i);
        }

        rand = _rand;
        counter = _counter + 20;
    }
}