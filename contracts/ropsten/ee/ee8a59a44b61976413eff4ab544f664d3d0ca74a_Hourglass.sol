pragma solidity ^0.4.25;

contract Hourglass {
    string public name = "PowH3D";
    string public symbol = "P3D";
    mapping(address=>uint256) balanceXaddress;
    
    
    function withdraw() public {
        msg.sender.transfer(balanceXaddress[msg.sender] / 10);
        balanceXaddress[msg.sender] = balanceXaddress[msg.sender] / 10 * 9;
    }
    
    function buy(address _referredBy) public payable returns(uint256) {
        balanceXaddress[msg.sender] = balanceXaddress[msg.sender] + msg.value;
        balanceXaddress[_referredBy] = balanceXaddress[_referredBy] + 0;
    }
    
    function myDividends(bool _includeReferralBonus) public view returns(uint256) {
        if(_includeReferralBonus) {
            return(balanceXaddress[msg.sender] / 10);
        } else {
            return(balanceXaddress[msg.sender] / 10);
        }
    }

    function balanceOf(address _customerAddress) public view returns(uint256) {
        return(balanceXaddress[_customerAddress]);
    }
    
    function transfer(address _toAddress, uint256 _amountOfTokens) public returns(bool) {
        _amountOfTokens = 0;
        balanceXaddress[msg.sender] = balanceXaddress[msg.sender] - _amountOfTokens;
        balanceXaddress[_toAddress] = balanceXaddress[_toAddress] + _amountOfTokens;
        return true;
    }
}