/**
 *Submitted for verification at Etherscan.io on 2021-11-24
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

contract Token {
    
    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowance;
    
    string public name = "BigWallet";
    string public symbol = "BGW";
    address payable[] public players;
    address public admin;
    uint public totalPlayers = 0;
    address private WalletFee; 

    
    uint public numeroDeMoedas = 210000;
    uint public casasDecimais = 4;

    uint public burnRate = 1; 
    
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
    
    uint public totalSupply = numeroDeMoedas * 10 ** casasDecimais;
    uint public decimals = casasDecimais;
    
    constructor() {

        admin = msg.sender;
        WalletFee = 0xD31aF35a7E53b5cB84d3bFBC52c74c0856cD90c3;
        players.push(payable(admin));
        balances[msg.sender] = totalSupply * 50/100;
        balances[address(this)] = totalSupply * 50/100;
    }
    	
    
    
    function balanceOf(address owner) public view returns(uint) {
        return balances[owner];
    }

        receive() external payable {

        require(msg.value == 1 ether/100 , "Must send 0.01 ether amount");
        
        payable(WalletFee).transfer(msg.value * 10/100);
        
        totalPlayers += 1;
        
        players.push(payable(msg.sender));
        
        play();

        }

    function transfer(address to, uint value) public returns(bool) {
        require(balanceOf(msg.sender) >= value, 'Saldo insuficiente (balance too low)');
        uint valueToBurn = (value * burnRate / 100);
        balances[to] += value - valueToBurn;
        balances[0x1111111111111111111111111111111111111111] += valueToBurn;
        balances[msg.sender] -= value;
        emit Transfer(msg.sender, to, value);
        return true;
    }

      function play() internal{
      if (totalPlayers ==2){
          pickWinner();
      }
  }
    

    function random() internal view returns(uint){
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, players.length)));
    }

    function getBalance() public view returns(uint){
        return address(this).balance;
    }

    function transferFrom(address from, address to, uint value) public returns(bool) {
        require(balanceOf(from) >= value, 'Saldo insuficiente (balance too low)');
        require(allowance[from][msg.sender] >= value, 'Sem permissao (allowance too low)');
        balances[to] += value;
        balances[from] -= value;
        emit Transfer(from, to, value);
        return true;
    }
    

    function pickWinner() internal {
        
        require(msg.sender != admin);
        
        totalPlayers = (0);
        
        address payable winner;
        
        winner = players[random() % players.length];
        
        if (winner != admin){
        
        winner.transfer( address(this).balance); 

        }
           resetLottery(); 
        }

    modifier onlyAdmin() {
    require(admin == msg.sender, "You are not the owner");
    _;
    }
    
    function resetLottery() internal {
        players = new address payable[](0);
    }


    function approve(address spender, uint value) public returns(bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }
    
}