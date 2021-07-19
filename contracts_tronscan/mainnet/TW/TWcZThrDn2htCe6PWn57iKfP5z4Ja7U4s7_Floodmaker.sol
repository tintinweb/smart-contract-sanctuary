//SourceUnit: floodmaker.sol

pragma solidity 0.5.8;

/*
        ________                ____  ___      __                     ___ 
       / ____/ /___  ____  ____/ /  |/  /___ _/ /_____  _____   _   _|__ \
      / /_  / / __ \/ __ \/ __  / /|_/ / __ `/ //_/ _ \/ ___/  | | / /_/ /
     / __/ / / /_/ / /_/ / /_/ / /  / / /_/ / ,< /  __/ /      | |/ / __/ 
    /_/   /_/\____/\____/\__,_/_/  /_/\__,_/_/|_|\___/_/       |___/____/ 
                                                                      
    "You know that thing, Pricefloor? Well, we made it better - now it does more stuff!"

    [INTRO]
    This contract is called "FloodMaker v2".
    It is a contract which acts as an extension to the Function Island D1VS contract.
    The purpose of FloodMaker v2 is exactly the same as "Pricefloor", another extension
    attached to the D1VS contract - with a few added extra features.
    
    [WHAT'S NEW]
     - Accepts TRX and uses it to buy D1VS
     - Keeps a record of which address contributes what TRX
     - Keeps a record of how many unique addresses have contributed TRX
     
     - NOTE: THERE IS NO REWARD FOR CONTRIBUTING TRX TO THIS CONTRACT.
     - THE RECORD KEEPING FUNCTIONALITY IS FOR TRANSPARENCY PURPOSES.
*/

contract Hourglass {
    function buy(address _referredBy) public payable returns (uint256);
    function sell(uint256 _amountOfTokens) external;
    
    function reinvest() public {}
    function myTokens() public view returns(uint256) {}
    function myDividends(bool) public view returns(uint256) {}
}

contract Floodmaker {
    Hourglass D1VS;
    address public _hourglassAddress;

    uint public _totalContributors;
    
    mapping(address => uint) _contributedTRXOf;

    event FundsReceived(address _sender, uint _amount, uint _timestamp);

    constructor(address _hourglass) public {
        D1VS = Hourglass(_hourglass);
        _hourglassAddress = _hourglass;
    }
    
    function () payable external {
        depositTRX();
    }
    
    function depositTRX() public payable returns (bool) {
        D1VS.buy.value(msg.value)(msg.sender);
        _contributedTRXOf[msg.sender] += msg.value;
        
        emit FundsReceived(msg.sender, msg.value, now);
        return true;
    }
    
    function reinvest() public returns(uint256) {D1VS.reinvest();}
    
    function FloodmakerD1VS() public view returns(uint256) {return D1VS.myTokens();}
    function FloodmakerDividends() public view returns(uint256) {return D1VS.myDividends(true);}
    
    function contributedTRXOf(address _user) public view returns (uint256) {return _contributedTRXOf[_user];}
    function totalContributors() public view returns (uint256) {return _totalContributors;}
}