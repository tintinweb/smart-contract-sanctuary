/**
 *Submitted for verification at BscScan.com on 2021-09-03
*/

// NFT合约, 代币和领取代币收益; BSC链;
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


// Owner
contract Ownable {
    // 一级管理者
    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "NFTToken: You are not owner");
        _;
    }

    function updateOwner(address newOwner) onlyOwner public {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }

}


contract NFT is ERC20, Ownable {
    string public name = "NFT Token";
    string public symbol = "NFT";
    uint8 public decimals = 18;
    uint256 public totalSupply;
    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) public allowed;

    // mining合约可以造币, 设置0地址则没有人可以造币
    address public mintAddress;

    constructor() public {}

    // 铸造事件;
    event Mint(address owner, uint256 value);

    function _transfer(address _from, address _to, uint256 _value) internal {
        balances[_from] = SafeMath.sub(balances[_from], _value);
        balances[_to] = SafeMath.add(balances[_to], _value);
        emit Transfer(_from, _to, _value);
    }

    function balanceOf(address _address) public view returns (uint256) {
        return balances[_address];
    }

    function transfer(address _to, uint256 _value) public {
        require(balances[msg.sender] >= _value, "NFTToken: Insufficient balance");
        _transfer(msg.sender, _to, _value);
    }

    function approve(address _spender, uint256 _amount) public {
        require(_spender != address(0), "Zero address error");
        require((allowed[msg.sender][_spender] == 0) || (_amount == 0), "NFTToken: Approve amount error");
        allowed[msg.sender][_spender] = _amount;
        emit Approval(msg.sender, _spender, _amount);
    }

    function transferFrom(address _from, address _to, uint256 _value) public {
        require(balances[_from] >= _value && allowed[_from][msg.sender] >= _value, "NFTToken: Insufficient balance");
        allowed[_from][msg.sender] = SafeMath.sub(allowed[_from][msg.sender], _value);
        _transfer(_from, _to, _value);
    }

    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }

    // 造币
    function _mint(address _owner, uint256 _value) private {
        totalSupply = SafeMath.add(totalSupply, _value);
        balances[_owner] = SafeMath.add(balances[_owner], _value);
        emit Mint(_owner, _value);
    }

    // 设置可造币的地址;
    function setMintAddress(address _mintAddress) public onlyOwner {
        mintAddress = _mintAddress;
    }

    // 造币接口
    function mint(address _owner, uint256 _value) public {
        require(msg.sender == mintAddress, "NFTToken: You are not mint address");
        _mint(_owner, _value);
    }

}