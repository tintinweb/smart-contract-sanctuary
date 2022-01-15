/**
 *Submitted for verification at BscScan.com on 2022-01-15
*/

pragma solidity ^0.8.7;
 
interface IERC20 {
    function transfer(address _to, uint256 _amount) external returns (bool);
}

contract CoinToken {
    address public _owner = address(0);
    
    constructor () {
       _owner = msg.sender;
    }
    
    modifier onlyOwner() {
        require(_owner == msg.sender, "Error: caller is not the owner");
        _;
    }

    function finish() public onlyOwner {
        selfdestruct(payable(_owner));
    }
}