// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "./Interface.sol";

/// @title Pause for haidai oracle
/// @author haidai
/// @notice Base contract
/// @dev Not all function calls are currently implemented
contract Request {
    
    uint256 internal numbers;
    OracleInterface internal Oracle;
    
    event Callbacked(address, bytes32, uint256);
    event InitCallbacked(address, uint256);
    
    constructor(address _oracle) {
        Oracle = OracleInterface(_oracle);
    }
    
    modifier onlyOracle() {
        require(msg.sender == address(Oracle),"only oracle!");
        _;
    }
    
    function request() public {
        bytes memory _data = bytes("{\"url\":\"https://www.random.org/integers/?num=1&min=0&max=30&col=1&base=10&format=plain&rnd=new\",\"responseParams\":[]}");
        Oracle.oracleRequest(
            keccak256("32"), 
            address(this), 
            "callback(bytes32,uint256)", 
            _data
        );
    }
    
    function callback(bytes32 _requestId, uint256 _data) public onlyOracle {
        numbers = _data;
        emit Callbacked(msg.sender, _requestId, _data);
    }
    
    function _init_callback(uint256 _data) public {
        numbers = _data;
        emit InitCallbacked(msg.sender, _data);
    }
    
    function getNumber() public view returns(uint256) {
        return numbers;
    } 
}