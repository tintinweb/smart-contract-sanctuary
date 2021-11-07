/**
 *Submitted for verification at BscScan.com on 2021-11-07
*/

/**
 *Submitted for verification at BscScan.com on 2021-11-03
*/

// SPDX-License-Identifier: PRIVATE

pragma solidity ^0.6.12;


abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
} 

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

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }


    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    uint256 private _lockTime;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }   
    
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


contract ShibaPupRewards is Context, Ownable {
    
    IERC20 shibapup = IERC20(0x5c2C6d86EA28DE95fdf57a23f1E6CbCBb940Ae09);

    uint256 public players; //Counts the players amount
    mapping(address => uint256) public userScore; //Contains the scores of the players & their wallet address
    mapping(address => bool) public participating; //Returns a boolean about the participation of the player, used into the server side

    address payable [] public registered_players; //Players who are defined to win
    address payable [] public playersArray; //Is used to clear the userScore mapping when the contract reset's itself

    uint256 public winners_amount; //Amount of players who will get rewards
    uint256 public minimal_participation;    //Minimal participation to the game.
    uint256 public balance = shibapup.balanceOf(address(this));
    

    constructor(uint256 _winners_amount, uint256 _minimal_participation) public {
        winners_amount = _winners_amount;
        minimal_participation = _minimal_participation;
    }

    
    
    /*
        function participate : 
                - Adds +1 to the players count
                - Registers the players into the users array. 
    */
    function participate() public payable { 
        
        require(shibapup.balanceOf(msg.sender) >= minimal_participation, "Insufficent balance to participate");
        require(shibapup.transferFrom(msg.sender, address(this), minimal_participation), "Impossible to proceed to the payment");
        require(participating[msg.sender] == false, "Player is already participating");
        
        userScore[msg.sender] = 0;
        participating[msg.sender] = true;
        playersArray.push(msg.sender);
        players = players + 1; 
        balance = shibapup.balanceOf(address(this));

    }
    
     /*
        function releaseRewards : 
                - Distribute the rewards to X amount of players that got the best score
    */
    function releaseRewards() public onlyOwner{  // throw error on release rewards cause of require function
    
    require(registered_players.length > winners_amount, "There is not enough winners.");
        
        uint256 currentBalance = shibapup.balanceOf(address(this));
        uint256 share = currentBalance / winners_amount;

       for(uint i = 0; i <= winners_amount; i++){
           if(registered_players[i] != address(0)){
            shibapup.transfer(registered_players[i], share);
           }
        }

    }

     /*
        function resetContract : 
                - Clears the userIndex mapping 
                - Clears the players amount
                - Clears the  winners array;
                - Clears the registered_players array
                - Calls emergencyWithdraw() to remove any leftover funds;
    */
    function resetContract() public onlyOwner{
        
        for(uint i =0; i < playersArray.length; i++){
          participating[playersArray[i]] = false; 
          userScore[playersArray[i]] = 0;
        }
        players = 0; 
        delete registered_players;
        delete playersArray;
        emergencyWithdraw();
    }
    
    /*
        function setUserScore : 
                - Sets the score of a player to the defined value. Uses userScore array to store it. 
    */
       function setUserScore(uint256 _score, address payable wallet) public onlyOwner {
        userScore[wallet] = _score;

    }
    
     /*
        function addWinner : 
                - Adds a player to the registered_players array.
    */
    function addWinner(address payable user) public onlyOwner {
        for(uint i = 0; i < registered_players.length; i++){
            if(registered_players[i] == user){
                return;
            }
        }
        registered_players.push(user);
    }
    
     /*
        function removeWinner : 
                - Removes a player from the registered_players array.
    */
    function removeWinner(address payable user) public onlyOwner {
        for(uint256 i = 0; i < registered_players.length; i++){
            if(registered_players[i] == user){
                delete registered_players[i];
            }
        }
    }
    
     /*
        function setWinnersAmount : 
                - Sets the variable winners_amount to the defined value.
    */
     function setWinnersAmount(uint256 value) public onlyOwner {
                winners_amount = value;
    }
    
    /*
        function endParticipation : 
                - Sets the variable participating to the defined value.
    */
    function endParticipation(address player) public onlyOwner{
                participating[player] = false;
    }
     /*
        function setMinimalParticipation : 
                - Sets the variable minimal_participation to the defined value.
    */
    function setMinimalParticipation(uint256 value) public onlyOwner {
                minimal_participation = value;
    }
     
    /*
        function emergencyWithdraw : 
                -  Sends the contract balance to the owner, called in case of a failure of the contract & on the reset of the contract
    */
    function emergencyWithdraw() public onlyOwner{
        msg.sender.transfer(address(this).balance);
    }
    
     /*
        function withdrawERC20 : 
                -  Sends the balance of any ERC20 token to the owner, used in case of a transfer by mistake to the contract
    */
    function withdrawERC20(IERC20 token) public onlyOwner{ 
        require(token.transfer(msg.sender, token.balanceOf(address(this))), "ERC20 Withdraw : Transfer failed");
    }
    
    
}