/**
 *Submitted for verification at Etherscan.io on 2021-03-15
*/

pragma solidity ^0.5.16;

contract PriceOracle {
    address constant ADMIN = address(0xc783df8a850f42e7F7e57013759C285caa701eB6);
    address oracle = address(0xbBdE93962Ca9fe39537eeA7380550ca6845F8db7);
    
    bool public constant isPriceOracle = true;

    function setOracle(address _oracle) external {
        require(msg.sender == ADMIN, "not-admin");
        
        oracle = _oracle;
    }

    function getUnderlyingPrice(address cToken) external view returns (uint) {
        return PriceOracle(oracle).getUnderlyingPrice(cToken);
    }
}


contract FakePriceOracle {
    address constant ADMIN = address(0xc783df8a850f42e7F7e57013759C285caa701eB6);
    address oracle = address(0xbBdE93962Ca9fe39537eeA7380550ca6845F8db7);
    
    mapping(address => uint) prices;
    mapping(address => bool) operators;
    
    function addOperator(address a) external {
        require(msg.sender == ADMIN, "!admin");
        operators[a] = true;
    }
    
    function setPrice(address ctoken, uint price) external {
        require(operators[msg.sender], "!operator");
        
        prices[ctoken] = price;
    }
    
    function getUnderlyingPrice(address cToken) external view returns(uint) {
        if(prices[cToken] != 0) return prices[cToken];
        
        return PriceOracle(oracle).getUnderlyingPrice(cToken);
    }
}