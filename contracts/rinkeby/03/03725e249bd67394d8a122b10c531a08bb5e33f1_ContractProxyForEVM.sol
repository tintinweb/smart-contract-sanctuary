/**
 *Submitted for verification at Etherscan.io on 2021-08-22
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

contract ContractProxyForEVM{
    address public admin;
    address public reciver;
    address public owner;

    function setAdmin (address _admin) public {
        require(admin == address(0), "Set admin only time");
        admin = _admin;
    }
    
    receive() external payable {}
    
    modifier OnlyAdmin{
        require(msg.sender == admin);
        _;
    }
    
    function setInfo(address _reciver, address _owner) public OnlyAdmin {
        require(getBalance() == 0);
        owner = _owner;
        reciver = _reciver;
    }

    function Consensus() public OnlyAdmin{
        withdrawMoneyTo(reciver);
    }
    
    function Refund() public OnlyAdmin{
        withdrawMoneyTo(owner);
    }

    function withdrawMoneyTo(address _to) private{
        (bool success, ) = payable(_to).call{value:getBalance()}("");
        require(success, "Transfer failed.");
    }
    
    function getBalance() public view returns(uint){
        return address(this).balance;
    }
}