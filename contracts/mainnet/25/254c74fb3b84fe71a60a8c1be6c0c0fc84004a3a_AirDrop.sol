pragma solidity ^0.4.17;


contract Ownable {
    
    address public owner;

    function Ownable() public {
        owner = 0x969c3EdB43b7b191E248B3E65400Cd9dd079Ed80;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    event OwnershipTransferred(address indexed from, address indexed to);
    

    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != 0x0);
        OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }
}


contract TokenTransferInterface {
    function transfer(address _to, uint256 _value) public;
}


contract AirDrop is Ownable {

    TokenTransferInterface public constant token = TokenTransferInterface(0x9D1784746A161a3252D61D0A1e254944ec357B63);

    function multiValueAirDrop(address[] _addrs, uint256[] _values) public onlyOwner {
	    require(_addrs.length == _values.length && _addrs.length <= 100);
        for (uint i = 0; i < _addrs.length; i++) {
            if (_addrs[i] != 0x0 && _values[i] > 0) {
                token.transfer(_addrs[i], _values[i] * (10 ** 18));  
            }
        }
    }

    function singleValueAirDrop(address[] _addrs, uint256 _value) public onlyOwner {
	    require(_addrs.length <= 100 && _value > 0);
        for (uint i = 0; i < _addrs.length; i++) {
            if (_addrs[i] != 0x0) {
                token.transfer(_addrs[i], _value * (10 ** 18));
            }
        }
    }
}