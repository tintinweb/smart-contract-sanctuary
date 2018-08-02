pragma solidity ^0.4.24;

contract IERC20Token {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;

    function balanceOf(address _owner) public constant returns (uint256 balance);
    function transfer(address _to, uint256 _value)  public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value)  public returns (bool success);
    function approve(address _spender, uint256 _value)  public returns (bool success);
    function allowance(address _owner, address _spender)  public constant returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}


contract Ownable {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address previousOwner, address newOwner);

    constructor(address _owner) public {
        owner = _owner == address(0) ? msg.sender : _owner;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != owner);
        newOwner = _newOwner;
    }

    function confirmOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = 0x0;
    }
}


contract AbyssBatchTransfer is Ownable {
    IERC20Token public token;

    constructor(address tokenAddress, address ownerAddress) public Ownable(ownerAddress) {
        token = IERC20Token(tokenAddress);
    }

    function batchTransfer(address[] recipients, uint256[] amounts) public onlyOwner {
        require(recipients.length == amounts.length);

        for(uint i = 0; i < recipients.length; i++) {
            require(token.transfer(recipients[i], amounts[i]));
        }
    }
}