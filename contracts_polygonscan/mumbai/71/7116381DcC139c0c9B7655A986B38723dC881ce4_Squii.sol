/**
 *Submitted for verification at polygonscan.com on 2021-10-19
*/

pragma solidity 0.8.9;

contract Squii {
    
    address owner;
    bool public paused;
    bool private exists;
    
       modifier onlyOwner() {
        require(msg.sender == owner, "Ownable: requires owner.");
        _;
    }
    
    
    function setPaused(bool _paused) public onlyOwner{
        paused = _paused;
    }
    
    struct Player {
        address userAddress;
        bool exists;
    }
    
    
    Player[] public players;
    
    mapping(address => bool) private _unlocked;

    function unlock(address _address) public onlyOwner {
        _unlocked[_address] = true;
    }
    
    function createPlayer(address _address) public onlyOwner {
        require(paused == false, "Contract Paused");
        require(_unlocked[_address], "User has not paid, cannot make profile");
        Player memory player = Player(_address, true);

        player.userAddress = _address;
        player.exists = true;
        
        players.push(player);
        players.length -1;
    }
    
    function getPlayers() view public onlyOwner returns(Player[] memory) {
        require(paused == false, "Contract Paused");
        return players;
    }
    
    function getPlayer(uint id) view public onlyOwner returns (address) {
        require(paused == false, "Contract Paused");
        return (players[id].userAddress);
    }
    
    function countPlayers() view public onlyOwner returns (uint) {
        require(paused == false, "Contract Paused");
        return players.length;
    }
}