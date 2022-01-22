/**
 *Submitted for verification at BscScan.com on 2022-01-22
*/

pragma solidity ^0.8.11;
contract SBSLottoTest {
function random(uint256 _totalPlayers) public view returns (uint256) {
        uint256 w_rnd_c_1 = uint(blockhash(block.number - 1));
        uint256 w_rnd_c_2 = 345691561789097689434450699;
        uint256 _rnd = 0;
        _rnd = uint(keccak256(abi.encodePacked(blockhash(block.number), w_rnd_c_1, blockhash(block.number), w_rnd_c_2)));
        _rnd = _rnd % _totalPlayers;
        return _rnd;
}
}