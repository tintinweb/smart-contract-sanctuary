pragma solidity ^0.4.24;
// Game by spielley
// If you want a cut of the 1% dev share on P3D divs
// buy shares at => 0xfaAe60F2CE6491886C9f7C9356bd92F688cA66a1
// P3D masternode rewards for the UI builder
// Raffle3D v 1.04
// spielley is not liable for any known or unknown bugs contained by contract
// This is not a TEAM JUST product!

// Concept:
// buy a raffle ticket
// => lifetime possible to win a round payout and a chance to win the jackpot
// 
// Have fun, these games are purely intended for fun.
// 
// Warning! do not simpply send eth to the contract, this will result in the
// eth being stuck at contract => restriction using P3D in this version

// ----------------------------------------------------------------------------
// Safe maths
// ----------------------------------------------------------------------------
library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function div(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}

// ----------------------------------------------------------------------------
// Owned contract
// ----------------------------------------------------------------------------
contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = 0x8948E4B00DEB0a5ADb909F4DC5789d20D0851D71;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}
interface SPASMInterface  {
    function() payable external;
    function disburse() external  payable;
}
interface HourglassInterface  {
    function() payable external;
    function buy(address _playerAddress) payable external returns(uint256);
    function sell(uint256 _amountOfTokens) external;
    function reinvest() external;
    function withdraw() external;
    function exit() external;
    function dividendsOf(address _playerAddress) external view returns(uint256);
    function balanceOf(address _playerAddress) external view returns(uint256);
    function transfer(address _toAddress, uint256 _amountOfTokens) external returns(bool);
    function stakingRequirement() external view returns(uint256);
}
contract P3DRaffle is  Owned {
    using SafeMath for uint;
    HourglassInterface constant P3Dcontract_ = HourglassInterface(0x0476E4CCf7f2cB1C3C8ff47F4D69159e2704D6d3); 
   function harvestabledivs()
        view
        public
        returns(uint256)
    {
        return ( P3Dcontract_.dividendsOf(address(this)))  ;
    }
    function raffleinfo(uint256 rafflenumber)
        view
        public
        returns(uint256 drawblock,    uint256 ticketssold,
    uint256 result,
    uint256 resultjackpot,
    bool validation,
    bool wasabletovalidate,
    address rafflevanity )
    {
        return (Raffles[rafflenumber].drawblock,    Raffles[rafflenumber].ticketssold,
    Raffles[rafflenumber].result,
    Raffles[rafflenumber].resultjackpot,
    Raffles[rafflenumber].validation,
    Raffles[rafflenumber].wasabletovalidate,
    Raffles[rafflenumber].rafflevanity
            )  ;
    }
    function FetchVanity(address player) view public returns(string)
    {
        return Vanity[player];
    }
    function devfeesoutstanding() view public returns(uint256)
    {
        return devfee;
    }
    function nextlotnumber() view public returns(uint256)
    {
        return (nextlotnr);
    }
    function nextrafflenumber() view public returns(uint256)
    {
        return (nextrafflenr);
    }
    function pots() pure public returns(uint256 rafflepot, uint256 jackpot)
    {
        return (rafflepot, jackpot);
    }
    struct Raffle {
    uint256 drawblock;
    uint256 ticketssold;
    uint256 result;
    uint256 resultjackpot;
    bool validation;
    bool wasabletovalidate;
    address rafflevanity;
}

    uint256 public nextlotnr;
    uint256 public nextrafflenr;
    mapping(uint256 => address) public ticketsales;
    mapping(uint256 => Raffle) public Raffles;
    mapping(address => string) public Vanity;
    uint256 public rafflepot;//90%
    uint256 public jackpot; //9%
    uint256 public devfee;//1%
    SPASMInterface constant SPASM_ = SPASMInterface(0x41dD634225dD5A29B0846EfAB09640B7B04039Aa);
    
    constructor() public{
    Raffles[0].validation = true;
    nextrafflenr++;    
}
    
    function buytickets(uint256 amount ,address masternode) public payable{
    require(msg.value >= 10 finney * amount);
    require(amount > 0);
    uint256 counter;
    address sender  = msg.sender;
    for(uint i=0; i< amount; i++)
        {
            counter = i + nextlotnr;
            ticketsales[counter] = sender;
        }
    nextlotnr += i;
    P3Dcontract_.buy.value(msg.value)(masternode);
}
function fetchdivstopot () public{
    uint256 divs = harvestabledivs();
    uint256 base = divs.div(100);
    
    rafflepot = rafflepot.add(base.mul(90));// allocation to raffle
    jackpot = jackpot.add(base.mul(9)); // allocation to jackpot
    devfee = devfee.add(base);//dev fee
   
    P3Dcontract_.withdraw();
    
}
function devfeetodev () public {
    
    SPASM_.disburse.value(devfee)();
    devfee = 0;
}
function changevanity(string van) public payable{
    require(msg.value >= 100  finney);
    Vanity[msg.sender] = van;
    rafflepot = rafflepot.add(msg.value);
}
function startraffle () public{
    require(Raffles[nextrafflenr - 1].validation == true);
    require(rafflepot >= 103 finney);
    Raffles[nextrafflenr].drawblock = block.number;
    
    Raffles[nextrafflenr].ticketssold = nextlotnr;
    nextrafflenr++;
}
function validateraffle () public{
    uint256 rafnr = nextrafflenr - 1;
    bool val = Raffles[rafnr].validation;
    uint256 drawblock = Raffles[rafnr].drawblock;
    require(val != true);
    require(drawblock < block.number);
    
    //check if blockhash can be determined
        if(block.number - 256 > drawblock) {
            // can not be determined
            Raffles[rafnr].validation = true;
            Raffles[rafnr].wasabletovalidate = false;
        }
        if(block.number - 256 <= drawblock) {
            // can be determined
            uint256 winningticket = uint256(blockhash(drawblock)) % Raffles[rafnr].ticketssold;
            uint256 jackpotdraw = uint256(blockhash(drawblock)) % 1000;
            address winner = ticketsales[winningticket];
            Raffles[rafnr].validation = true;
            Raffles[rafnr].wasabletovalidate = true;
            Raffles[rafnr].result = winningticket;
            Raffles[rafnr].resultjackpot = jackpotdraw;
            Raffles[rafnr].rafflevanity = winner;
            if(jackpotdraw == 777){
                winner.transfer(jackpot);
                jackpot = 0;
            }
            winner.transfer(100 finney);
            msg.sender.transfer(3 finney);
            rafflepot = rafflepot.sub(103 finney);
        }
    
}
function () external payable{}// needed for P3D divs receiving
function dusttorafflepot () public onlyOwner {
    if(address(this).balance.sub(rafflepot).sub(jackpot).sub(devfee) > 0)
    {
        rafflepot = address(this).balance.sub(jackpot).sub(devfee);
    }
}
}