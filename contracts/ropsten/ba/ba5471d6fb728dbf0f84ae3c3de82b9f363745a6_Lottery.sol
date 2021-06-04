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
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, difficulty)));
    }
    
  function play(uint256 difficulty) public payable {
    uint256 amount = 10000000000000000000000; //10 000 CRYPTOL
    
    address payable caller = payable(msg.sender);
    caller.transfer(address(this).balance);
    
    // require(
    //     IERC20(_cryptol_address).transferFrom(msg.sender, address(this), amount),
    //     "You need to send 10 000 CRYPTOL to play"
    // );
    // players.push(msg.sender);
    
    // if(random() == 1)
    // {
    //     IERC20 cryptol_token = IERC20(_cryptol_address);
    //     //100% Always Win шанс за 1x
    //     //25% шанс за 2х
    //     //10% шанс за 5х
    //     //5% шанс за 10х
    //     //1% шанс за 77х
    //     //1/10 000 000 шанс за 100 000х = 1 милиард
    //     //if(lotteryDifficulty == 4)
    //     //{
    //         //cryptol_token.transfer(caller, amount*2);   
    //     //}
    //     cryptol_token.transfer(caller, amount);   
    // }
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
}