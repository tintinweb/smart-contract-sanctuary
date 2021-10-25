/**
 *Submitted for verification at Etherscan.io on 2021-10-24
*/

pragma solidity =0.6.12;
pragma experimental ABIEncoderV2;


contract StructParamTest {

    uint x;

    struct ParamsOne {
        address router;
        uint amountIn;
        bool isSF;  
    }

    struct ParamsTwo {
        address router;
        address[] path;
        uint amountIn;
        bool isSF;  
    }

    struct ParamsTree {
        ParamsOne paramsOne;
        address[] path;
    }

    modifier removeView() {
        if(false) {
            x = 0;
        }
        _;
    }

    function testParamsOne(ParamsOne calldata one) external removeView returns (bool) {
        one;
        return true;
    }

    function testParamsTwo(ParamsTwo calldata two) external removeView returns (bool) {
        two;
        return true;
    }

    function testParamsThree(ParamsTwo calldata three) external removeView returns (bool) {
        three;
        return true;
    }
}