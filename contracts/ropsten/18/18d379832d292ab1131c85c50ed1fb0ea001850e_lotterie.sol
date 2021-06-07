pragma solidity ^0.5.0;

import "./erc20.sol";

contract lotterie{
    uint256 public WithdrawTime;
    string public name = "Lotterie";
    GagaToken public gagaToken;
    mapping(address => uint) public commitment;
    mapping(address => uint) public loose_amount;
    mapping(uint => address) public loose_number;
    address[] public players;
    address owner;
    
    
    constructor(GagaToken _gagaToken) public{
        gagaToken = _gagaToken;
        owner = address(this);
    }
    
    
    function deposite (uint _amount) public {
        _amount /= 5;
        _amount *= 5;
        require (_amount >= 5, "Minimum bet isn't reached: min _amount is 5 Coins!");
        gagaToken.transferFrom(msg.sender, address(this), _amount);
        players.push(msg.sender);
        commitment[msg.sender] += _amount;
    }
    
    function declareWinner(uint _seed) private returns(address){
        uint loosenumber = 0;
        for(uint i = 0; i<players.length;i++){
            loose_amount[players[i]] = commitment[players[i]] / 5 ;
            for (uint x = 0; x < loose_amount[players[i]]; x++){
                loose_number[loosenumber] = players[i];
                loosenumber++;
            }
        }
        
        uint256 winnerloose = uint256(_seed * (uint256(keccak256(abi.encode(block.timestamp))))%loosenumber);
        
        return(loose_number[winnerloose]);
    }
    
    function PayoutWinner(address _winneradress, uint _winamount) public{
        gagaToken.transfer(_winneradress,_winamount);
    }
    
    function RunLotterie(uint _seed) public{
        require (msg.sender == owner, "Only Owner can run the Lotterie");
        uint _winamount = gagaToken.balanceOf(address(this));
        require (players.length > 5, "There aren't enough players yet");
        address _winneradress = declareWinner(_seed);
        PayoutWinner(_winneradress, _winamount);
    }
}