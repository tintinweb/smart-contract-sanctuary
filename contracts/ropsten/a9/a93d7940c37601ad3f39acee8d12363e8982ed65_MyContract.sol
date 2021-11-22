/**
 *Submitted for verification at Etherscan.io on 2021-11-22
*/

pragma solidity ^0.5.17;

interface IERC20 {
    function totalSupply() external view returns (uint supply);
    function balanceOf(address _owner) external view returns (uint balance);
    function transfer(address _to, uint _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint _value) external returns (bool success);
    function approve(address _spender, uint _value) external returns (bool success);
    function allowance(address _owner, address _spender) external view returns (uint remaining);
    function decimals() external view returns(uint digits);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}

contract owned {
    IERC20 daitoken;
    address owner;

    constructor(address addr) public{
        owner = msg.sender;
        daitoken = IERC20(addr);
    }

    modifier onlyOwner {
        require(msg.sender == owner,
                "Only the contract owner can call this function");
        _;
    }
}

contract MyContract is owned{

    address owner;

    constructor(address _daiToken)
    public 
    owned(_daiToken)
    {}

    function approves(uint256 _value) public {
        daitoken.approve(address(this), _value);
    }

    function allowance(address _owner, address _spender) public view returns(uint256) {
        return daitoken.allowance(_owner, _spender);
    }

    function transferFroms(address _to, uint256 _value) public {
        daitoken.transferFrom(address(this), _to, _value);
    }

    function transfers(address _addr, uint256 _value) external {
        require(daitoken.transfer(_addr, _value));
    }

    function balanceOf(address _addr) public view returns(uint256){
        return daitoken.balanceOf(_addr);
    }
}