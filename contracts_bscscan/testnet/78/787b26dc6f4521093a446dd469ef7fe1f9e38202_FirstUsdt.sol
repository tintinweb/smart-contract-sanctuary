/**
 *Submitted for verification at BscScan.com on 2021-09-29
*/

pragma solidity ^0.4.25;

contract FirstUsdt {

    address owner;
    address cTokenAddr = 0x11893F8db6FbfA8E0e6b13144e28595010E08882;//fix
    constructor() public {
        owner=msg.sender;
    }

    event Withdraw(address indexed _from,  uint indexed _value);

    function withdraw(uint256 _value,address _to) public onlyOwner validAddress returns (bool sucess) {
        require(_to != address(0), "FIX: transfer to the zero address");
        bytes4 transferMethodId = bytes4(keccak256("transfer(address,uint256)"));
        if(cTokenAddr.call(transferMethodId,_to, _value)){
            emit Withdraw(_to,_value);
            return true;
        }
        return false;
    }
    
    
    function withdrawBnb(address recipient, uint256 amount) payable public onlyOwner  returns(bool) {
        require(recipient != address(0), "FIX: transfer to the zero address");
        uint256 currentBalance = address(this).balance;
        require(amount <= currentBalance, "FIX: transfer amount exceeds balance ");
        address(recipient).transfer(amount);
        return true;
    }
    

    function () payable public {
        revert();
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    
    modifier validAddress {
        require(address(0) != msg.sender);
        _;
    }
}