pragma solidity ^0.8.5;

import "./IERC20.sol";

contract PolkaWarGame {

     string private _name="PolkaWar Game";
     string private _symbol="PWARG";

     IERC20 public PolkaWarTest;

    address public tokenAdress; // This is the token address

    address public owner;
    uint256[] _entry= [10,50,100,200,500,1000];
    struct Game{
        uint256 id;
        GameState state;
        address[] players;
    }

    uint256 public rewardMultiplier;
    mapping(uint256=>Game) public _games;

    enum GameState {Open, Waiting, Running}
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);


    constructor(address _TokenAddress) {
        PolkaWarTest = IERC20(_TokenAddress);
        owner = msg.sender;
        rewardMultiplier=90;
        startAllPools();
    }
  
    modifier onlyOwner(){
        require(msg.sender == owner);
        _;
    }

    function startAllPools() internal{
        for(uint256 i=0;i<_entry.length;i++){
            _games[i]= Game(i,GameState.Open,new address[](0));
        }
    }

     function stake(uint256 _amount) external  returns (bool) {
        PolkaWarTest.transferFrom(msg.sender, address(this), _amount);
        return true;
    }


    function senderBalance() public view returns (uint){
        return PolkaWarTest.balanceOf(msg.sender);
    }

    function enterInGame(uint256 _poolId) public returns(bool){
        // Check desired conditions
        require(PolkaWarTest.balanceOf(msg.sender)>=_entry[_poolId],"Insufficient balance");
        require(_games[_poolId].state!=GameState.Running,"Battle is running, you can not participate.");
        
        // Add user and deposit PWAR
        if(_games[_poolId].state==GameState.Open){
            address[] storage tempArr1=_games[_poolId].players;
            tempArr1.push(msg.sender);
           _games[_poolId]= Game(_poolId,GameState.Waiting,tempArr1);
           
        }
        if(_games[_poolId].state==GameState.Waiting){
            address[] storage tempArr2=_games[_poolId].players;
            tempArr2.push(msg.sender);
            Game memory _updatedGame= Game(_poolId,GameState.Running,tempArr2);
           _games[_poolId]=_updatedGame;
        }

        // Deposit funds to battle
        address from = msg.sender;
        address to = address(this);
        PolkaWarTest.transferFrom(from, to, _entry[_poolId]*10**18);
        emit Transfer(msg.sender, address(this), _entry[_poolId]*10**18);
        return true;
    }
    
     function claimWinnerReward(uint256 _poolId) public returns(bool){
        // Check desired conditions
        require(_games[_poolId].state==GameState.Running,"Battle is not finished yet.");
        require(_games[_poolId].players[0]==msg.sender || _games[_poolId].players[1]==msg.sender,"Player not found.");
        
        // update variables
        Game memory _initializeGame= Game(_poolId,GameState.Open,new address[](0));
        _games[_poolId]=_initializeGame;

        // Transfer funds to winner address
        address from =address(this);
        address to = msg.sender;
        uint256 winningAmount= _entry[_poolId]*10**18*rewardMultiplier/100;
        PolkaWarTest.transferFrom(from, to, winningAmount);

        emit Transfer(from, to, winningAmount);
        return true;
    }
}