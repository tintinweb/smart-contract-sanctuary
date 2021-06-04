/**
 *Submitted for verification at Etherscan.io on 2021-06-04
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Lottery {
    address public owner;
    address[] public players;
    address private _cryptol_address = 0xB0DD74bc7Dc6278ed1CFf32bd76A9FcBc2EDA67d;

    constructor() {
        owner = msg.sender;
    }
    
    function contractBalance() external view returns(uint) {
        return IERC20(_cryptol_address).balanceOf(address(this));
    }
    
    function contractEthBalance() external view returns(uint) {
        return address(this).balance;
    }

    function random(uint256 difficulty) private view returns (uint) {
        if(difficulty == 0) return 0;
        uint randomHash = uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp)));
        return randomHash % difficulty;
    }
    
    function play(uint256 difficulty) public payable {

        uint256 amount = 10000000000000000000000; //10 000 CRYPTOL
        //uint256 amount = 1000000000000000000; //1 CRYPTOL
        
        address payable caller = payable(msg.sender);
        //caller.transfer(address(this).balance/2);
        
        require(
            IERC20(_cryptol_address).transferFrom(msg.sender, address(this), amount),
            "You need to send 10 000 CRYPTOL to play"
        );
        
        players.push(msg.sender);
        
        IERC20 cryptol_token = IERC20(_cryptol_address);
        if(random(difficulty-1) == 0)
        {
            //100% Always Win шанс за 1x
            if(difficulty == 1)
            {
                cryptol_token.transfer(caller, amount-1);   
            }
            //25% шанс за 2х
            else if(difficulty == 4)
            {
                cryptol_token.transfer(caller, amount*2);   
            }
            //10% шанс за 5х
            else if(difficulty == 10)
            {
                cryptol_token.transfer(caller, amount*5);   
            }
            //5% шанс за 10х
            else if(difficulty == 20)
            {
                cryptol_token.transfer(caller, amount*10);   
            }
            //1% шанс за 77х
            else if(difficulty == 100)
            {
                cryptol_token.transfer(caller, amount*77);   
            }
            //1/10 000 000 шанс за 100 000х = 1 милиард
            //todo
        }
    }
        
    function clearPlayers() public onlyOwner {
        players = new address[](0);
    }
    
    function getPlayers() public view returns (address[] memory) {
        return players;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    function withdraw(uint256 amount) external {
        require(
            msg.sender == owner,
            "Only the Owner can call this function"
        );
        require(
            IERC20(_cryptol_address).balanceOf(address(this)) >= amount,
            "Insufficient funds. Deposit balance is not enough. Withdraw lower amount"
        );
        
        address caller = msg.sender;
        IERC20 cryptol_token = IERC20(_cryptol_address);
        cryptol_token.transfer(caller, amount);
    }
}