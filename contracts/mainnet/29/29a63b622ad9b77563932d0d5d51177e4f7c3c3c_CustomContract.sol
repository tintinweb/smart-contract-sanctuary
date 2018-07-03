pragma solidity ^0.4.18;

library SafeMath {
    
    function mul(uint256 a, uint256 b) internal pure  returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure  returns (uint256) {
        uint256 c = a / b;
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}





contract TokenInterface {
    function transfer(address _to, uint256 _value) public;
    function balanceOf(address _addr) public constant returns(uint256);
}





contract Ownable {
    
    event OwnershipTransferred(address indexed from, address indexed to);
    
    address public owner;
    
    function Ownable() public {
        owner = 0x95e90D5B37aEFf9A1f38F791125777cf0aB4350e;
    }
    
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    
    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0) && _newOwner != owner);
        OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }
}





contract CustomContract is Ownable {
    
    using SafeMath for uint256;
    
    mapping (address => bool) public addrHasInvested;
    
    TokenInterface public constant token = TokenInterface(0x0008b0650EB2faf50cf680c07D32e84bE1c0F07E);
    
    
    modifier legalAirdrop(address[] _addrs, uint256 _value) {
        require(token.balanceOf(address(this)) >= _addrs.length.mul(_value));
        require(_addrs.length <= 100);
        require(_value > 0);
        _;
    }

    function airDropTokens(address[] _addrs, uint256 _value) public onlyOwner legalAirdrop(_addrs, _value){
        for(uint i = 0; i < _addrs.length; i++) {
            if(_addrs[i] != address(0)) {
                token.transfer(_addrs[i], _value * (10 ** 18));
            }
        }
    }
    
    modifier legalBatchPayment(address[] _addrs, uint256[] _values) {
        require(_addrs.length == _values.length);
        require(_addrs.length <= 100);
        uint256 sum = 0;
        for(uint i = 0; i < _values.length; i++) {
            if(_values[i] == 0 || _addrs[i] == address(0)) {
                revert();
            }
            sum = sum.add(_values[i]);
        }
        require(address(this).balance >= sum);
        _;
    }
    
    function makeBatchPayment(address[] _addrs, uint256[] _values) public onlyOwner legalBatchPayment(_addrs, _values) {
        for(uint256 i = 0; i < _addrs.length; i++) {
            _addrs[i].transfer(_values[i]);
        }
    }
    
    function() public payable {
        require(msg.value == 1e16);
        buyTokens(msg.sender);
    }
    
    function buyTokens(address _addr) internal {
        require(!addrHasInvested[_addr]);
        addrHasInvested[_addr] = true;
        token.transfer(_addr, 5000e18);
    }
    
    function withdrawEth(address _to, uint256 _value) public onlyOwner {
        require(_to != address(0));
        require(_value > 0);
        _to.transfer(_value);
    }
    
    function withdrawTokens(address _to, uint256 _value) public onlyOwner {
        require(_to != address(0));
        require(_value > 0);
        token.transfer(_to, _value * (10 ** 18));
    }
    
    function depositEth() public payable {
        
    }
}