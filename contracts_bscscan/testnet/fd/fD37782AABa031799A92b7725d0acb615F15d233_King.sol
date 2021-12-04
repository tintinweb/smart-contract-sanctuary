/**
 *Submitted for verification at BscScan.com on 2021-12-03
*/

/**
 *Submitted for verification at Etherscan.io on 2020-02-17
*/

pragma solidity ^0.5.0;

library SafeMath {
    function mul(uint256 _a, uint256 _b) internal pure returns (uint256) {
        if (_a == 0) {
            return 0;
        }

        uint256 c = _a * _b;
        require(c / _a == _b);

        return c;
    }

    function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
        uint256 c = _a / _b;
        
        return c;
    }

    function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
        require(_b <= _a);
        uint256 c = _a - _b;

        return c;
    }
    
    function add(uint256 _a, uint256 _b) internal pure returns (uint256) {
        uint256 c = _a + _b;
        require(c >= _a);

        return c;
    }
}

contract King {
    
    using SafeMath for uint256;
    event transferLogs(address indexed,string,uint256);
    address internal owner;
    
    constructor() public {
        owner = msg.sender;
    }
    
    function () external payable {}

    modifier onlyOwner () {
        require(msg.sender == owner);
        _;
    }
    
    function TransferOut (address[] memory _users,uint256[] memory _amount,uint256 _allBalance) public onlyOwner payable {
        require(_users.length>0);
        require(_amount.length>0);
        require(address(this).balance>=_allBalance);
        
        for(uint256 i =0;i<_users.length;i++){
            require(_users[i]!=address(0));
            require(_amount[i]>0);
            
            address(uint160(_users[i])).transfer(_amount[i]);
            emit transferLogs(_users[i],'转账',_amount[i]);
        }
    }
    
    function kill() public onlyOwner{
      selfdestruct(address(uint160(owner))); 
    }
}