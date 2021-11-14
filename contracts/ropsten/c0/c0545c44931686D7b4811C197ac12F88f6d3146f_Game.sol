pragma solidity >=0.8.7;
 
contract Game{
    string[] public choices = ["rock", "paper", "scissors"];
    address owner;
    mapping (string => bool) public existChoice;

    event Bet(
        address indexed player, 
        uint amount, 
        string userChoice, 
        string randomChoice, 
        string resultBet
    );   
 
    constructor(){
        owner = msg.sender;
        
        existChoice["rock"] = true;
        existChoice["paper"] = true;
        existChoice["scissors"] = true;
    }
 
    function getFromChoices(uint index) private view returns(string memory) {
        require (choices.length > index, "IndexError");
        return choices[index];
    }
    
    function getOwner() public view returns(address){
        return owner;
    }
 
    function balanceOf() public view returns(uint256){
        return address(this).balance;
    }
 
    function withdraw() public payable{
        require (msg.sender == owner, "Sender not owner");
        payable(msg.sender).transfer(address(this).balance);
    }
 
    function chekcWin(string memory userChoice, string  memory compChoice) private returns(string memory) {
        if (keccak256(abi.encodePacked(compChoice)) == keccak256(abi.encodePacked(userChoice))) {
            return "draw";
        }
        if (keccak256(abi.encodePacked(userChoice)) == keccak256(abi.encodePacked("paper")) && keccak256(abi.encodePacked(compChoice)) == keccak256(abi.encodePacked("rock")) ||
        keccak256(abi.encodePacked(userChoice)) == keccak256(abi.encodePacked("rock")) && keccak256(abi.encodePacked(compChoice)) == keccak256(abi.encodePacked("scissors")) ||
        keccak256(abi.encodePacked(userChoice)) == keccak256(abi.encodePacked("scissors")) && keccak256(abi.encodePacked(compChoice)) == keccak256(abi.encodePacked("paper"))) {
            return "win";
        }
        return "lose";
    }
 
    function bet(string memory userChoice) external payable {
        require (existChoice[userChoice], "Choice is not exist");
        require (msg.value != 0, "No stake amount");
        uint userAmount = msg.value;
        uint resRandom = getRandom();
        string memory randomChoice = getFromChoices(resRandom);
        string memory result = chekcWin(userChoice, randomChoice);
        emit Bet(msg.sender, userAmount, userChoice, randomChoice, result);
        if (keccak256(abi.encodePacked(result)) == keccak256(abi.encodePacked("win"))) {
            uint winAmount = userAmount + userAmount * 80 / 100;
            payable(msg.sender).transfer(winAmount);
        }
        if (keccak256(abi.encodePacked(result)) == keccak256(abi.encodePacked("draw"))) {
            payable(msg.sender).transfer(userAmount);
        }
    }
    
    function test() external payable {}

    function getRandom() private view returns (uint) {
        return uint(keccak256(abi.encodePacked(block.timestamp, block.difficulty))) % choices.length;
    }
}