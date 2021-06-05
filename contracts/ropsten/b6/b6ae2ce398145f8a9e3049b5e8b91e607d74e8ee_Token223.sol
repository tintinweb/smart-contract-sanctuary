/**
 *Submitted for verification at Etherscan.io on 2021-06-05
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.1;

// import "./others/IERC223.sol";
// import "./others/Helper.sol";
// import "./others/IERC223Recipient.sol";

interface IERC223 {

    
    function balanceOf(address who) external view returns (uint);
    function transfer(address to, uint value) external returns (bool success);
    function transfer(address to, uint value, bytes memory data) external returns (bool success);
     
    event Transfer(address indexed from, address indexed to, uint value, bytes data);
}

interface IERC223Recipient { 
    function tokenFallback(address _from, uint _value, bytes memory _data) external;
}

contract Token223 is IERC223 {
    
     
    string private _symbol;
    string private  _name;
    uint8 private _decimals;
    uint private _totalSupply;
    mapping(address => uint) private userBalance;
    
    
    constructor(address creator) {
        _symbol = "LT223";
        _name = "LakhoToken223";
        _decimals = 3;
        _totalSupply = 10**5;
        userBalance[creator] = _totalSupply;
        emit Transfer(address(0), creator, _totalSupply, "");
        
    }
    
    function name() external view returns (string memory) {
        return _name;   
    }
    
    function symbol() external view returns (string memory) {
        return _symbol;
    }
  

    function totalSupply() public view returns (uint) {
        return _totalSupply;
    }
    
    function balanceOf(address who) public view override returns (uint) {
        return userBalance[who];
    }   
        
    function transfer(address to, uint value) public override returns (bool) {
        return _transfer(to, value, "");
    }
        
    function transfer(address to, uint value, bytes memory data) public override returns (bool) {
        return _transfer(to, value, data);
    }
    
    function _transfer(address to, uint value, bytes memory data) private returns (bool) {
        require(userBalance[msg.sender] >= value, "Insufficient balance");
        checkIfImplemented(to, value, data);
        
        userBalance[msg.sender] -= value;
        userBalance[to] += value;
        emit Transfer(msg.sender, to, value, data);
        return true;
    }
    
    function checkIfImplemented(address to, uint value, bytes memory data) private {
        if(isContract(to)) {
            IERC223Recipient receiver = IERC223Recipient(to);
            receiver.tokenFallback(to, value, data);
        } 
    }
    
    function isContract(address _addr) private view returns (bool) {
        uint32 size;
        assembly {
            size := extcodesize(_addr)
        }
        return (size > 0);
    }    
}