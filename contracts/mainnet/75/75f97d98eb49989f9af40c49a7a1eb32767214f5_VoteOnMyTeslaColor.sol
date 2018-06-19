pragma solidity ^0.4.0;

/// @title PonzICO
/// @author acityinohio
contract PonzICO {
    address public owner;
    uint public total;
    mapping (address => uint) public invested;
    mapping (address => uint) public balances;

    //function signatures
    function PonzICO() { }
    function withdraw() { }
    function reinvest() { }
    function invest() payable { }
    
}

/// @title VoteOnMyTeslaColor EXCLUSIVELY FOR SUPER-ACCREDITED PONZICO INVESTORS
/// @author acityinohio
contract VoteOnMyTeslaColor {
    address public owner;
    enum Color { SolidBlack, MidnightSilverMetallic, DeepBlueMetallic, SilverMetallic, RedMultiCoat }
    mapping (uint8 => uint32) public votes;
    mapping (address => bool) public voted;

    //log vote
    event LogVotes(Color color, uint num);
    //log winner
    event LogWinner(Color color);

    //hardcode production PonzICO address
    PonzICO ponzico = PonzICO(0x1ce7986760ADe2BF0F322f5EF39Ce0DE3bd0C82B);

    //just for me
    modifier ownerOnly() {require(msg.sender == owner); _; }
    //only valid colors, as specified by the Model3 production details
    modifier isValidColor(uint8 color) {require(color < uint8(5)); _; }
    //Only super-accredited ponzICO investors (0.1 ETH per vote) can vote
    //Can only vote once! Unless you want to pay to play...
    modifier superAccreditedInvestor() { require(ponzico.invested(msg.sender) >= 0.1 ether && !voted[msg.sender]); _;}

    //constructor for initializing VoteOnMyTeslaColor
    //the owner is the genius who made the revolutionary smart contract PonzICO
    //obviously blue starts with 10 votes because it is objectively the BEST color
    function VoteOnMyTeslaColor() {
        owner = msg.sender;
        //YOURE MY BOY BLUE
        votes[uint8(2)] = 10;
    }

    //SUPER ACCREDITED INVESTORS ONLY, YOU CAN ONLY VOTE ONCE
    function vote(uint8 color)
    superAccreditedInvestor()
    isValidColor(color)
    {
        //0.1 ETH invested in PonzICO per vote, truncated
        uint32 num = uint32(ponzico.invested(msg.sender) / (0.1 ether));
        votes[color] += num;
        voted[msg.sender] = true;
        LogVotes(Color(color), num);
    }
    
    //pay to vote again! I don&#39;t care!
    //...but it&#39;ll cost you 1 ether for me to look the other way, wink wink
    function itsLikeChicago() payable {
        require(voted[msg.sender] && msg.value >= 1 ether);
        voted[msg.sender] = false;
    }

    function winnovate()
    ownerOnly()
    {
        Color winner = Color.SolidBlack;
        for (uint8 choice = 1; choice < 5; choice++) {
            if (votes[choice] > votes[choice-1]) {
                winner = Color(choice);
            }
        }
        LogWinner(winner);
        //keeping dat blockchain bloat on check
        selfdestruct(owner);
    }
}