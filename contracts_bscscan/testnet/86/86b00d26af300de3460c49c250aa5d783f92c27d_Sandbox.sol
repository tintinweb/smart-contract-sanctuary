/**
 *Submitted for verification at BscScan.com on 2021-11-11
*/

pragma solidity 0.8.0;

contract Sandbox {
    
    mapping(uint256 => address) public isSales;
    mapping(uint256 => string) public playerBox;
    
    function deposit(uint256 amount) payable public {
        require(msg.value == amount);
        // TODO do something then
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
    
    function getTimestamp() public view returns (uint256) {
        return block.timestamp;
    }
    
    function withdraw(uint256 amount) public {
        payable(msg.sender).transfer(amount);
    }
    
    function setSale(string[] memory _box) public {
        for(uint256 i = 0; i < _box.length; i++) {
            playerBox[i] = _box[i];
        }
    }
    
    function getBalance2() pure public returns (uint256) {
        return type(uint256).max;
    }
    
    uint public mod1;
    uint public mod2;
    uint public mod3;
    
    modifier modA() {
        mod1 = mod1 + 1;
        _;
    }
    
    modifier modB() {
        mod2 = mod2 + 1;
        _;
        mod2 = mod2 + 1;
        _;
    }
    
    function func() public modA modB {
        mod3 = mod3 + 1;
    }
    
    function get1Min() pure public returns(uint256) {
        return  1 days;
    }
}