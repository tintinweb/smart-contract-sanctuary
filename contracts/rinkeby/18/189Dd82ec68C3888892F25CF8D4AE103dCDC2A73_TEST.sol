/**
 *Submitted for verification at Etherscan.io on 2021-05-26
*/

pragma solidity ^0.5.16;


// Math operations with safety checks that throw on error
library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "Math error");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "Math error");
        return a - b;
    }

}


// Abstract contract for the full ERC 20 Token standard
contract ERC20 {

    function balanceOf(address _address) public view returns (uint256 balance);

    function transfer(address _to, uint256 _value) public returns (bool success);

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

    function approve(address _spender, uint256 _value) public returns (bool success);

    function allowance(address _owner, address _spender) public view returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

}


// Token contract
contract TEST {
    address public owner;
    bytes4 private constant TRANSFER = bytes4(
        keccak256(bytes("transfer(address,uint256)"))
    );

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner, "You are not owner");
        _;
    }
    
    // 修改管理员
    function setOwner(address _owner) public onlyOwner returns (bool success) {
        require(_owner != address(0), "zero address");
        owner = _owner;
        success = true;
    }
    
    // 管理员取出里面的Token
    function fetchToken(ERC20 _erc20Address) public onlyOwner returns (bool success2) {
        uint256 _value = _erc20Address.balanceOf(address(this));
        (bool success, ) = address(_erc20Address).call(
            abi.encodeWithSelector(TRANSFER, msg.sender, _value)
        );
        if(!success) {
            revert("transfer fail");
        }
        success2 = true;
    }
    
    // 管理员取出里面的ETH
    function fetchETH() public onlyOwner returns (bool success) {
        msg.sender.transfer(address(this).balance);
        success = true;
    }
    
    // 合约接受ETH
    function receiveETH() public payable returns (bool success) {
        (address(uint160(address(this)))).transfer(msg.value);
        success = true;
    }
    
    // 合约接受一半的ETH
    // 提示: 实际转入的值依然是msg.value, 并没有除以2
    function receiveHalfETH() public payable returns (bool success) {
        (address(uint160(address(this)))).transfer(msg.value / 2);
        success = true;
    }
    
    // 合约接受一部分的ETH
    function receiveLittleETH() public payable returns (bool success) {
        (address(uint160(address(this)))).transfer(3);
        success = true;
    }
    
    // 查询ETH余额
    function getETHBalance(address _address) public view returns (uint256 b) {
        b = (address(uint160(_address))).balance;
    }
    
    function() payable external {}

}