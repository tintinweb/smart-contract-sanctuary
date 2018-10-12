pragma solidity ^0.4.25;

contract Ownable {
    address public owner;
    address public Publisher;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    /**
    * @dev The Ownable constructor sets the original `owner` of the contract to the sender
    * account.
    */
    constructor() public{
        owner = msg.sender;
        Publisher = msg.sender;
    }

    /**
    * @dev Throws if called by any account other than the owner.
    */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /**
    * @dev Allows the current owner to transfer control of the contract to a newOwner.
    * @param newOwner The address to transfer ownership to.
    */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    /**
    * @dev return Owner address.
    */

    function OwnerAddress() public view returns(address){
        return owner;
    }
}

contract notice_gogoto1 is Ownable{
    string notice;
    string games_dice;
    string games_stic;

    event changed_notice(string _notice);
    event changed_game_dice(string _games_dice);
    event changed_game_stic(string _games_stic);    
    
    constructor(string _notice, string _games_dice, string _games_stic) public {
        notice = _notice;
        games_dice = _games_dice;
        games_stic = _games_stic;
    }
    function change_notice(string _notice) public onlyOwner {        
        notice = _notice;
        emit changed_notice(notice);
    }
    function change_game_dice(string _games_dice) public onlyOwner {        
        games_dice = _games_dice;
        emit changed_game_dice(games_dice);
    }
    function change_game_stic(string _games_stic) public onlyOwner {        
        games_stic = _games_stic;
        emit changed_game_stic(games_stic);
    }
}