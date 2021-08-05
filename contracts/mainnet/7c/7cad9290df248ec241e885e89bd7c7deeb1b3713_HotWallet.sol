/**
 *Submitted for verification at Etherscan.io on 2021-05-07
*/

pragma solidity 0.5.11;

contract IToken {
    function balanceOf(address) public view returns (uint256);
    function transfer(address to, uint value) public;
}

contract Manageable {
    mapping(address => bool) public admins;
    constructor() public {
        admins[msg.sender] = true;
    }

    modifier onlyAdmins() {
        require(admins[msg.sender]);
        _;
    }

    function modifyAdmins(address[] memory newAdmins, address[] memory removedAdmins) public onlyAdmins {
        for(uint256 index; index < newAdmins.length; index++) {
            admins[newAdmins[index]] = true;
        }
        for(uint256 index; index < removedAdmins.length; index++) {
            admins[removedAdmins[index]] = false;
        }
    }
}

contract HotWallet is Manageable {
    mapping(uint256 => bool) public isPaid;
    event Transfer(uint256 transactionRequestId, address coinAddress, uint256 value, address payable to);
    
    function transfer(uint256 transactionRequestId, address coinAddress, uint256 value, address payable to) public onlyAdmins {
        require(!isPaid[transactionRequestId]);
        isPaid[transactionRequestId] = true;
        emit Transfer(transactionRequestId, coinAddress, value, to);
        if (coinAddress == address(0)) {
            return to.transfer(value);
        }
        IToken(coinAddress).transfer(to, value);
    }
    
    function getBalances(address coinAddress) public view returns (uint256 balance)  {
        if (coinAddress == address(0)) {
            return address(this).balance;
        }
        return IToken(coinAddress).balanceOf(address(this));
    }

    function () external payable {}
}