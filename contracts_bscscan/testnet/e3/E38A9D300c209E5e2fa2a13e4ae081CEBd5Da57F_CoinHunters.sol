/**
 *Submitted for verification at BscScan.com on 2021-09-10
*/

/**
 *Submitted for verification at BscScan.com on 2021-09-10
*/

/**
 *Submitted for verification at BscScan.com on 2021-09-09
*/

pragma solidity 0.5.10;

interface IBEP20 {
    
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeMath {
    
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {

        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;

        require(c / a == b);

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {

        require(b > 0);

        uint256 c = a / b;

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);

        uint256 c = a - b;

        return c;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;

        require(c >= a);

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);

        return a % b;
    }
}

contract Ownable   {
    address public _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() public {
        _owner = msg.sender;

        emit OwnershipTransferred(address(0), _owner);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");

        _;
    }


    function transferOwnership(address newOwner) public onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );

        emit OwnershipTransferred(_owner, newOwner);

        _owner = newOwner;
    }
}

contract CoinHunters is Ownable {
    
    IBEP20 public v1;
    IBEP20 public v2;
    
    event swap( address indexed spender, uint256 value);
    
    constructor(IBEP20 _v1, IBEP20 _v2) public{
        v1=_v1;
        v2=_v2;
    }
    
    function swapTokens(uint256 _numberOfV1Tokens) public  { 
        
        require(v1.balanceOf(msg.sender)>=_numberOfV1Tokens,"You don't have enough tokens!");
     
        v1.transferFrom(msg.sender,0xAF6c52aE51a7F4CE61D28bE9F6b5cf34d670424F, _numberOfV1Tokens);
        v2.transfer(msg.sender,_numberOfV1Tokens);
        
        emit swap(msg.sender ,_numberOfV1Tokens);
    }
    
}