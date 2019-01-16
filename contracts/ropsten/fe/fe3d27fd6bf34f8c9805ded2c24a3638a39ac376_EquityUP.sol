pragma solidity ^0.4.24;


library SafeMath {
    
    // methods for mathematical operations
    
    function add(uint256 _a, uint256 _b) internal pure returns (uint256 _sum) {
        _sum = _a + _b;
        assert (_sum >= _a);
        return _sum;
    }
    
    function substract(uint256 _a, uint256 _b) internal pure returns (uint256 _diff) {
        _diff = _a - _b;
        assert (_a >= _b);
        return _diff;
    }
    
    function multiply(uint256 _a, uint256 _b) internal pure returns (uint256 _product) {
        if (_a==0 || _b==0){
            return 0;
        }
        _product = _a * _b;
        assert ( _product/_a == _b);
        return _product;
    }
    
    function exponential(uint256 _a, uint256 _b) internal pure returns (uint256 _exponent) {
        _exponent = _a ** _b;
        
        if ((_a >= 1) && (_b >= 1)) {
            assert (_exponent >= _a);
        }
        else if ((_a < 1) && (_b >=1)) {
            assert ((_exponent < _a) && (_exponent > 0));
        }
        else if ((_a < 1) && (_b < 1)) {
            assert ((_exponent > _a) && ( _exponent < 1));
        }
        else {
            assert (( _exponent <= _a) && (_exponent > 1));
        }
        
        return _exponent;
    }
}


// define ABI fingerprints of every token to be integrated
contract Token_1 {
    // ABI fingerprints of every method that we require
    function balanceOf (address) public pure returns (uint256) {}
    function transferFrom (address, address, uint256) public pure returns (bool) {}
    function decimals() public pure returns (uint256);
}


// our EquityUP contract
contract EquityUP{
    
    using SafeMath for uint256;
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    
    Token_1 token1;
    
    constructor (address[1] memory deployed_token_address) public {
        // instantiate token instances here
        token1 = Token_1(deployed_token_address[0]);
    }
    
    // get Token1 balance
    function Token_1_Balance (address _address) public view returns (uint256) {
        return token1.balanceOf(_address);
    }
    
    // transfer Token1
    function Token1_Transfer (address _from, address _to, uint _amount) public returns(bool){
        //require (_to != address(0));
        uint256 _base = 10;
        uint256 _amount_to_transfer = _amount.multiply(_base.exponential(token1.decimals()));
        
        token1.transferFrom(_from ,_to, _amount_to_transfer);
        emit Transfer(msg.sender, _to, _amount_to_transfer);
    }
}