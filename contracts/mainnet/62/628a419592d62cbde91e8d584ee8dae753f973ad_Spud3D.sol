pragma solidity ^0.4.25;
// First Spielley and Dav collab on creating a Hot potato take for P3D
// pass the spud, 
// each time you have the spud you can win the jackpot, 
// first player has most chance of hitting jackpot and slowly the chances of winning decrease. 
// if someone doesn&#39;t take over the spud within 256 blocks you auto win
// each time you play you get a spudcoin
// spudcoin reward for UI devs
// spudcoins can be traded in for a part of the contracts divs
// dependant on totalsupply and how many coins you trade in
// you can also trade in spudcoin for spots in the MN rotator when the contract buys P3D
// 

contract Spud3D {
    using SafeMath for uint;
    
    HourglassInterface constant p3dContract = HourglassInterface(0xB3775fB83F7D12A36E0475aBdD1FCA35c091efBe);
    SPASMInterface constant SPASM_ = SPASMInterface(0xfaAe60F2CE6491886C9f7C9356bd92F688cA66a1);//spielley&#39;s profit sharing payout
    
    struct State {
        
        uint256 blocknumber;
        address player;
        
        
    }
    
    mapping(uint256 =>  State) public Spudgame;
    mapping(address => uint256) public playerVault;
    mapping(address => uint256) public SpudCoin;
    mapping(uint256 => address) public Rotator;
    
    uint256 public totalsupply;//spud totalsupply
    uint256 public Pot; // pot that get&#39;s filled from entry mainly
    uint256 public SpudPot; // divpot spucoins can be traded for
    uint256 public round; //roundnumber
    
    uint256 public RNGdeterminator; // variable upon gameprogress
    uint256 public nextspotnr; // next spot in rotator
    
    mapping(address => string) public Vanity;
    
    event Withdrawn(address indexed player, uint256 indexed amount);
    event SpudRnG(address indexed player, uint256 indexed outcome);
    event payout(address indexed player, uint256 indexed amount);
    
    function harvestabledivs()
        view
        public
        returns(uint256)
    {
        return ( p3dContract.myDividends(true))  ;
    }
    function contractownsthismanyP3D()
        public
        view
        returns(uint256)
    {
        
        return (p3dContract.balanceOf(address(this)));
    }
    function getthismuchethforyourspud(uint256 amount)
        public
        view
        returns(uint256)
    {
        uint256 dividends = p3dContract.myDividends(true);
            
            uint256 amt = dividends.div(100);
            
            uint256 thepot = SpudPot.add(dividends.sub(amt));
            
        uint256 payouts = thepot.mul(amount).div(totalsupply);
        return (payouts);
    }
    function thismanyblockstillthspudholderwins()
        public
        view
        returns(uint256)
    {
        uint256 value;
        if(265-( block.number - Spudgame[round].blocknumber) >0){value = 265- (block.number - Spudgame[round].blocknumber);}
        return (value);
    }
    function currentspudinfo()
        public
        view
        returns(uint256, address)
    {
        
        return (Spudgame[round].blocknumber, Spudgame[round].player);
    }
    function returntrueifcurrentplayerwinsround()
        public
        view
        returns(bool)
    {
        uint256 refblocknr = Spudgame[round].blocknumber;
        uint256 RNGresult = uint256(blockhash(refblocknr)) % RNGdeterminator;
        
        bool result;
        if(RNGresult == 1){result = true;}
        if(refblocknr < block.number - 256){result = true;}
        return (result);
    }
    //mods
    modifier hasEarnings()
    {
        require(playerVault[msg.sender] > 0);
        _;
    }
    
    function() external payable {} // needed for P3D myDividends
    //constructor
    constructor()
        public
    {
        Spudgame[0].player = 0x0B0eFad4aE088a88fFDC50BCe5Fb63c6936b9220;
        Spudgame[0].blocknumber = block.number;
        RNGdeterminator = 6;
        Rotator[0] = 0x989eB9629225B8C06997eF0577CC08535fD789F9;//raffle3d possible MN reward
        nextspotnr++;
    }
    //vanity
    
    function changevanity(string van , address masternode) public payable
    {
        require(msg.value >= 1  finney);
        Vanity[msg.sender] = van;
        if(masternode == 0x0){masternode = 0x989eB9629225B8C06997eF0577CC08535fD789F9;}// raffle3d&#39;s address
        p3dContract.buy.value(msg.value)(masternode);
    } 
    //
     function withdraw()
        external
        hasEarnings
    {
       
        
        uint256 amount = playerVault[msg.sender];
        playerVault[msg.sender] = 0;
        
        emit Withdrawn(msg.sender, amount); 
        
        msg.sender.transfer(amount);
    }
    // main function
    function GetSpud(address MN) public payable
    {
        require(msg.value >= 1  finney);
        address sender = msg.sender;
        uint256 blocknr = block.number;
        uint256 curround = round;
        uint256 refblocknr = Spudgame[curround].blocknumber;
        
        SpudCoin[MN]++;
        totalsupply +=2;
        SpudCoin[sender]++;
        
        // check previous RNG
        
        if(blocknr == refblocknr) 
        {
            // just change state previous player does not win
            
            playerVault[msg.sender] += msg.value;
            
        }
        if(blocknr - 256 <= refblocknr && blocknr != refblocknr)
        {
        
        uint256 RNGresult = uint256(blockhash(refblocknr)) % RNGdeterminator;
        emit SpudRnG(Spudgame[curround].player , RNGresult) ;
        
        Pot += msg.value;
        if(RNGresult == 1)
        {
            // won payout
            uint256 RNGrotator = uint256(blockhash(refblocknr)) % nextspotnr;
            address rotated = Rotator[RNGrotator]; 
            uint256 base = Pot.div(10);
            p3dContract.buy.value(base)(rotated);
            Spudgame[curround].player.transfer(base.mul(5));
            emit payout(Spudgame[curround].player , base.mul(5));
            Pot = Pot.sub(base.mul(6));
            // ifpreviouswon => new round
            uint256 nextround = curround+1;
            Spudgame[nextround].player = sender;
            Spudgame[nextround].blocknumber = blocknr;
            
            round++;
            RNGdeterminator = 6;
        }
        if(RNGresult != 1)
        {
            // not won
            
            Spudgame[curround].player = sender;
            Spudgame[curround].blocknumber = blocknr;
        }
        
        
        }
        if(blocknr - 256 > refblocknr)
        {
            //win
            // won payout
            Pot += msg.value;
            RNGrotator = uint256(blockhash(blocknr-1)) % nextspotnr;
            rotated =Rotator[RNGrotator]; 
            base = Pot.div(10);
            p3dContract.buy.value(base)(rotated);
            Spudgame[round].player.transfer(base.mul(5));
            emit payout(Spudgame[round].player , base.mul(5));
            Pot = Pot.sub(base.mul(6));
            // ifpreviouswon => new round
            nextround = curround+1;
            Spudgame[nextround].player = sender;
            Spudgame[nextround].blocknumber = blocknr;
            
            round++;
            RNGdeterminator = 6;
        }
        
    } 

function SpudToDivs(uint256 amount) public 
    {
        address sender = msg.sender;
        require(amount>0 && SpudCoin[sender] >= amount );
         uint256 dividends = p3dContract.myDividends(true);
            require(dividends > 0);
            uint256 amt = dividends.div(100);
            p3dContract.withdraw();
            SPASM_.disburse.value(amt)();// to dev fee sharing contract SPASM
            SpudPot = SpudPot.add(dividends.sub(amt));
        uint256 payouts = SpudPot.mul(amount).div(totalsupply);
        SpudPot = SpudPot.sub(payouts);
        SpudCoin[sender] = SpudCoin[sender].sub(amount);
        totalsupply = totalsupply.sub(amount);
        sender.transfer(payouts);
    } 
function SpudToRotator(uint256 amount, address MN) public
    {
        address sender = msg.sender;
        require(amount>0 && SpudCoin[sender] >= amount );
        uint256 counter;
    for(uint i=0; i< amount; i++)
        {
            counter = i + nextspotnr;
            Rotator[counter] = MN;
        }
    nextspotnr += i;
    SpudCoin[sender] = SpudCoin[sender].sub(amount);
    totalsupply = totalsupply.sub(amount);
    }
}

interface HourglassInterface {
    function buy(address _playerAddress) payable external returns(uint256);
    function withdraw() external;
    function myDividends(bool _includeReferralBonus) external view returns(uint256);
    function balanceOf(address _playerAddress) external view returns(uint256);
}
interface SPASMInterface  {
    function() payable external;
    function disburse() external  payable;
}
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