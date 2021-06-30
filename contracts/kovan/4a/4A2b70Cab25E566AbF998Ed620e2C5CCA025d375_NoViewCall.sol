/**
 *Submitted for verification at Etherscan.io on 2021-06-30
*/

pragma solidity =0.6.6;

contract NoViewTest {
    uint private _seed = 66;

    function getSeed() external returns(uint) {
        if (false) {
            _seed = _seed;
        }
        return _seed;
    }
}

interface INoViewTest {
    function getSeed() external view returns(uint);
}

contract NoViewCall {
    INoViewTest public test = INoViewTest(0xE00D0BC01F11Dc5C5F66611A6cf37c3F3847fE1A);

    function getSeed() external view returns(uint) {
        return test.getSeed();
    }

}