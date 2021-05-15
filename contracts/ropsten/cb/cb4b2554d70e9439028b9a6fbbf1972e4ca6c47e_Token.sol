/**
 *Submitted for verification at Etherscan.io on 2021-05-15
*/

pragma solidity >=0.8.0;

contract Token {
    uint256 private totalTokens_;
    mapping (address => uint256) private balance_;
    mapping (address => mapping (address => uint256)) approval_;
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    constructor() {
        balance_[msg.sender] = 25;
    }

    function name() public pure returns (string memory) {
        return "605111090";
    }

    function symbol() public pure returns (string memory) {
        return "CS188";
    }

    function decimals() public pure returns (uint8) {
        return 18;
    }

    function totalSupply() public view returns (uint256) {
        return totalTokens_;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balance_[_owner];
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balance_[msg.sender] >= _value);
        balance_[msg.sender] -= _value;
        balance_[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(balance_[_from] >= _value);
        require(approval_[_from][_to] >= _value);
        balance_[_from] -= _value;
        balance_[_to] += _value;
        emit Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        approval_[msg.sender][_spender] = 0;
        approval_[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return approval_[_owner][_spender];
    }
}