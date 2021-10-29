/**
 *Submitted for verification at BscScan.com on 2021-10-29
*/

pragma solidity ^0.4.24;


interface ERC20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address tokenOwner) external view returns (uint balance);
    function allowance(address tokenOwner, address spender) external view returns (uint remaining);
    function transfer(address to, uint tokens) external returns (bool success);
    function approve(address spender, uint tokens) external returns (bool success);
    function transferFrom(address from, address to, uint tokens) external returns (bool success);
}


library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a, "Addition overflow");
    }
    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a, "Subtraction overflow");
        c = a - b;
    }
    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b, "Multiplication overflow");
    }
    function div(uint a, uint b) internal pure returns (uint c) {
        require(b > 0, "The denominator is 0");
        c = a / b;
    }
}


contract ValixOrgBulk
{
    using SafeMath for uint;
    address owner;
    
    event MultiTransfer(
        address indexed _from,
        uint indexed _value,
        address _to,
        uint _amount
    );

    event MultiERC20Transfer(
        address indexed _from,
        address _to,
        uint _amount,
        ERC20 _token
    );
    
    constructor () public payable {
        owner = msg.sender;
    }
    
    function multiTransfer(address[] _addresses, uint[] _amounts) public payable returns(bool) {
        uint toReturn = msg.value;
        for (uint i = 0; i < _addresses.length; i++) {
            _safeTransfer(_addresses[i], _amounts[i]);
            toReturn = SafeMath.sub(toReturn, _amounts[i]);
            emit MultiTransfer(msg.sender, msg.value, _addresses[i], _amounts[i]);
        }
        _safeTransfer(msg.sender, toReturn);
        return true;
    }

    function multiERC20Transfer(ERC20 _token, address[] _addresses, uint[] _amounts) public payable {
        for (uint i = 0; i < _addresses.length; i++) {
            _safeERC20Transfer(_token, _addresses[i], _amounts[i]);
            emit MultiERC20Transfer(
                msg.sender,
                _addresses[i],
                _amounts[i],
                _token
            );
        }
    }

    function _safeTransfer(address _to, uint _amount) internal {
        require(_to != 0, "Receipt address can't be 0");
        _to.transfer(_amount);
    }

    function _safeERC20Transfer(ERC20 _token, address _to, uint _amount) internal {
        require(_to != 0, "Receipt address can't be 0");
        require(_token.transferFrom(msg.sender, _to, _amount), "Sending a token failed");
    }

    function () public payable {
        revert("Contract prohibits receiving funds");
    }

    function forwardTransaction( address destination, uint amount, uint gasLimit, bytes data) internal {
        require(msg.sender == owner, "Not an administrator");
        require(
            destination.call.gas(
                (gasLimit > 0) ? gasLimit : gasleft()
            ).value(amount)(data), 
            "operation failed"
        );
    }
}