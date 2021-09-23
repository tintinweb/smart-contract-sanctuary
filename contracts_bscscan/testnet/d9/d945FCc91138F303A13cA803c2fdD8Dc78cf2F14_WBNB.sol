/**
 *Submitted for verification at BscScan.com on 2021-09-23
*/

// NFT ERC20合约
pragma solidity ^0.5.16;


// a library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math)
library SafeMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, 'ds-math-add-overflow');
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, 'ds-math-sub-underflow');
    }
}


// ERC20
contract ERC20 {
    function balanceOf(address _address) public view returns (uint256);
    function transfer(address _to, uint256 _value) public;
    function transferFrom(address _from, address _to, uint256 _value) public;
    function approve(address _spender, uint256 _value) public;
    function allowance(address _owner, address _spender) public view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract WBNB is ERC20 {
    string public name = "WBNB Token";
    string public symbol = "WBNB";
    uint8 public decimals = 18;
    uint256 public totalSupply = 365000000000 * 10**18;
    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) public allowed;

    constructor() public {
        balances[msg.sender] = totalSupply;
    }

    function _transfer(address _from, address _to, uint256 _value) internal {
        balances[_from] = SafeMath.sub(balances[_from], _value);
        balances[_to] = SafeMath.add(balances[_to], _value);
        emit Transfer(_from, _to, _value);
    }

    function balanceOf(address _address) public view returns (uint256) {
        return balances[_address];
    }

    function transfer(address _to, uint256 _value) public {
        require(balances[msg.sender] >= _value, "NFTS: Insufficient balance");
        _transfer(msg.sender, _to, _value);
    }

    function approve(address _spender, uint256 _amount) public {
        require(_spender != address(0), "Zero address error");
        require((allowed[msg.sender][_spender] == 0) || (_amount == 0), "NFTS: Approve amount error");
        allowed[msg.sender][_spender] = _amount;
        emit Approval(msg.sender, _spender, _amount);
    }

    function transferFrom(address _from, address _to, uint256 _value) public {
        require(balances[_from] >= _value && allowed[_from][msg.sender] >= _value, "NFTS: Insufficient balance");
        allowed[_from][msg.sender] = SafeMath.sub(allowed[_from][msg.sender], _value);
        _transfer(_from, _to, _value);
    }

    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }

}