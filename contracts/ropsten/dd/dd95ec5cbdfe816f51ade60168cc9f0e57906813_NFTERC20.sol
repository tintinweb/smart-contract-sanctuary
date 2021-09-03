/**
 *Submitted for verification at Etherscan.io on 2021-09-03
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract NFTERC20{
    
    address public owner; 
    string public name;
    string public symbol;
    uint8 public decimals = 18;
    // 18 decimals is the strongly suggested default, avoid changing it
    uint256 public totalSupply;
    uint256 public lotteryRate; 
    uint8 public lotteryCount; 
    uint256 public faucetValue; 
    
    string[] public prizePool;  // save all hashs to lottery
    mapping (address => uint256) public balanceOf; // balanceOf 
    mapping (address => uint) public faucetTime; // balanceOf 
    mapping(address => string[]) public prizeOwn;
        
    // This generates a public event on the blockchain that will notify clients
    event LotteryCall(address indexed from, address indexed to, uint256 value,string[] prize);
    
    event BalanceChange(address indexed oner, uint256 value);
    
       /**
     * Constructor function
     *
     * Initializes contract with initial supply tokens to the creator of the contract
     */
    constructor(
        string memory tokenName,
        string memory tokenSymbol
    )  {
        totalSupply = 1000 * 10 ** uint256(decimals);  // Update total supply with the decimal amount
        balanceOf[msg.sender] = totalSupply;                // Give the creator all initial tokens
        name = tokenName;                                   // Set the name for display purposes
        symbol = tokenSymbol;                               // Set the symbol for display purposes
        owner = msg.sender;
        lotteryRate = 10* 10 ** uint256(decimals);
    }
    

    function lottery(uint256 _times) public returns (bool success) {
         // Check if the sender has enough
        require(_times >0x0);
        uint256 _cost =  _times *lotteryRate;
        require(balanceOf[msg.sender] >= _cost);
        balanceOf[msg.sender] -= _cost;
        
        // 
        for(uint256 i=0;i<_times*uint256(lotteryCount);i++){
            uint256 random = uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp)));
            uint256 index= random%prizePool.length;
            prizeOwn[msg.sender].push(prizePool[index]);
        } 
        return true;
    }
    
    function setLotteryCount(uint8 count) public returns (bool success){
        require(msg.sender==owner,
          "Only owner can setLotteryCount.");
        require(count>0);
        lotteryCount= count;
       return true;
    }
    
    function setLotteryRate(uint256 count) public returns (bool success){
        require(msg.sender==owner,
          "Only owner can setLotteryRate.");
        require(count>0);
        lotteryRate= count;
       return true;
    }
    
    function setFaucetValue(uint256 count) public returns (bool success){
        require(msg.sender==owner,
          "Only owner can setFaucetValue.");
        require(count>0);
        faucetValue= count;
       return true;
    }
    
    function faucet(address to) public returns (bool success){
        require(block.timestamp-faucetTime[to] > uint(10*60));
        faucetTime[to] = block.timestamp;
    	balanceOf[to] +=faucetValue;
    	return true;
    }


}