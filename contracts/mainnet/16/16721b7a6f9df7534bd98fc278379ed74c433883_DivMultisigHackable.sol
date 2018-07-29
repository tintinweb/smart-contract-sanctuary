pragma solidity ^0.4.24;

contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = 0x0B0eFad4aE088a88fFDC50BCe5Fb63c6936b9220;
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
contract DivMultisigHackable is Owned {
HourglassInterface constant P3Dcontract_ = HourglassInterface(0xB3775fB83F7D12A36E0475aBdD1FCA35c091efBe);

function buyp3d(uint256 amt) internal{
P3Dcontract_.buy.value(amt)(this);
}
function claimdivs() internal{
P3Dcontract_.withdraw();
}
// amount of divs available

struct HackableSignature {
    address owner;
    uint256 hackingcost;
    uint256 encryption;
}
uint256 private ethtosend;
uint256 private nexId;
uint256 public totalsigs;
mapping(uint256 => HackableSignature) public Multisigs;  
mapping(address => uint256) public lasthack;

address public contrp3d = 0xB3775fB83F7D12A36E0475aBdD1FCA35c091efBe;
uint256 private div;
uint256 private count;
constructor(uint256 amtsigs) public{
    for(nexId = 0; nexId < amtsigs;nexId++){
    Multisigs[nexId].owner = msg.sender;
    Multisigs[nexId].hackingcost = 1;
    Multisigs[nexId].encryption = 1;
}
totalsigs = amtsigs;
}
event onHarvest(
        address customerAddress,
        uint256 amount
    );
function harvestabledivs()
        view
        public
        returns(uint256)
    {
        return ( P3Dcontract_.dividendsOf(address(this)))  ;
    }
function amountofp3d() external view returns(uint256){
    return ( P3Dcontract_.balanceOf(address(this)))  ;
}
function Hacksig(uint256 nmbr) public payable{
    require(lasthack[msg.sender] < block.number);
    require(nmbr < totalsigs);
    require(Multisigs[nmbr].owner != msg.sender);
    require(msg.value >= Multisigs[nmbr].hackingcost + Multisigs[nmbr].encryption);
    Multisigs[nmbr].owner = msg.sender;
    Multisigs[nmbr].hackingcost ++;
    Multisigs[nmbr].encryption = 0;
    lasthack[msg.sender] = block.number;
}
function Encrypt(uint256 nmbr) public payable{
    require(Multisigs[nmbr].owner == msg.sender);//prevent encryption of hacked sig
    Multisigs[nmbr].encryption += msg.value;
    }

function HackDivs() public payable{
    div = harvestabledivs();
    require(msg.value >= 1 finney);
    require(div > 0);
    count = 0;
    for(nexId = 0; nexId < totalsigs;nexId++){
    if(Multisigs[nexId].owner == msg.sender){
        count++;
    }
}
require(count > totalsigs/2);
    claimdivs();
    //1% to owner
    ethtosend = div /100;
    owner.transfer(ethtosend);
    ethtosend = ethtosend * 99;
    msg.sender.transfer(ethtosend);
    emit onHarvest(msg.sender,ethtosend);
}

function Expand() public {
    //1% to owner
    ethtosend = this.balance /100;
    owner.transfer(ethtosend);
    //99% buy p3d
    buyp3d(this.balance);
}

function () external payable{}
}