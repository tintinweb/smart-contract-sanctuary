/**
 *Submitted for verification at BscScan.com on 2021-08-16
*/

/**
 *Submitted for verification at BscScan.com on 2021-06-04
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IBEP20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function getOwner() external view returns (address);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Lottery {
    address public owner;
    //address[] private players;
    //address private token_address = 0xeD24FC36d5Ee211Ea25A80239Fb8C4Cfd80f12Ee; // BUSD Testnet
    address private token_address = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56; // BUSD

    constructor() {
        owner = msg.sender;
    }
    
    function contractTokenBalance() external view returns(uint) {
        return IBEP20(token_address).balanceOf(address(this));
    }
    
    function contractBalance() external view returns(uint) {
        return address(this).balance;
    }

    function random(uint256 difficulty) private view returns (uint) {
        if(difficulty == 0) return 0;
        uint randomHash = uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp)));
        return randomHash % difficulty;
    }
    
    function play(uint256 difficulty) public payable {

        uint256 amount = 10000000000000000000; //10 tokens
        //uint256 amount = 1000000000000000000; //1 tokens
        
        //address payable caller = payable(msg.sender);
        //caller.transfer(address(this).balance/2);
        
        require(
            IBEP20(token_address).transferFrom(msg.sender, address(this), amount),
            "You need to send tokens to play"
        );
        
        //players.push(msg.sender);
        
        IBEP20 token = IBEP20(token_address);
        if(random(difficulty-1) == 0)
        {
            //100% Always Win chance for 1x
            if(difficulty == 1)
            {
                token.transfer(msg.sender, amount-1);   
            }
            //25% chance for 2х
            else if(difficulty == 4)
            {
                token.transfer(msg.sender, amount*2);   
            }
            //10% chance for 5х
            else if(difficulty == 10)
            {
                token.transfer(msg.sender, amount*5);   
            }
            //5% chance for 10х
            else if(difficulty == 20)
            {
                token.transfer(msg.sender, amount*10);   
            }
            //1% chance for 77х
            else if(difficulty == 100)
            {
                token.transfer(msg.sender, amount*77);   
            }
            // //1/10 000 000 chance for 100 000x
            // //todo
        }
    }
        
    // function clearPlayers() public {
    //     require(
    //         msg.sender == owner,
    //         "clearPlayers: Only the Owner can call this function"
    //     );
    //     players = new address[](0);
    // }
    
    // function getPlayers() public view returns (address[] memory) {
    //     return players;
    // }
    
    function withdrawTokens(uint256 amount) external {
        require(
            msg.sender == owner,
            "withdrawTokens: Only the Owner can call this function"
        );
        require(
            IBEP20(token_address).balanceOf(address(this)) >= amount,
            "withdrawTokens: Insufficient funds. Deposit balance is not enough. Withdraw lower amount"
        );
        
        IBEP20 token = IBEP20(token_address);
        token.transfer(msg.sender, amount);
    }
    
    function withdraw(uint256 amount) external {
        require(
            msg.sender == owner,
            "withdraw: Only the Owner can call this function"
        );
        require(
            address(this).balance >= amount,
            "withdraw: Insufficient funds. Deposit balance is not enough. Withdraw lower amount"
        );

        payable(msg.sender).transfer(amount);
    }
}