/**
 *Submitted for verification at Etherscan.io on 2021-07-03
*/

pragma solidity ^0.4.25;

contract DepositFee {
    
    address private _owner;

    constructor() public {
        _owner = msg.sender;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, 'Ownable: caller is not the owner');
        _;
    }

    function deposit() public payable {
        
    }

    function withdraw(uint256 amount) public onlyOwner {
        _owner.transfer(amount);
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
    
    function getOwner() public view returns (address) {
        return _owner;
    }
    
    function transferOwner(address newOwner) public onlyOwner {
        require(newOwner != address(0), 'Ownable: new owner is the zero address');
        _owner = newOwner;
    }
}