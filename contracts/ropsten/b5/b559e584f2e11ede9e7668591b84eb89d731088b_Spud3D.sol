pragma solidity ^0.4.25;
// First Spielley and Dav collab on creating a Hot potato take for P3D
// insert more info here about gameplay

contract Spud3D {
    using SafeMath for uint;
    
    HourglassInterface constant p3dContract = HourglassInterface(0x0E62d6a4E8354EFC62b1eA7fDFfff2eff0FE5712);//0xB3775fB83F7D12A36E0475aBdD1FCA35c091efBe);
    SPASMInterface constant SPASM_ = SPASMInterface(0xdc827558062AA1cc0e2AB28146DA9eeAC38A06D1);//0xfaAe60F2CE6491886C9f7C9356bd92F688cA66a1);//spielley&#39;s profit sharing payout
    
    struct State {
        
        uint256 blocknumber;
        address player;
        uint256 Result;
        
    }
    
    mapping(uint256 => mapping(uint256 => State)) public Spudgame;
    mapping(address => uint256) public playerVault;
    mapping(address => uint256) public SpudCoin;
    mapping(uint256 => address) public Rotator;
    
    uint256 public totalsupply;//spud totalsupply
    uint256 public Pot; // pot that get&#39;s filled from entry mainly
    uint256 public SpudPot; // divpot spucoins can be traded for
    uint256 public round; //roundnumber
    uint256 public inroundindex;// in round index
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
        Spudgame[0][0].player = 0x0B0eFad4aE088a88fFDC50BCe5Fb63c6936b9220;
        Spudgame[0][0].blocknumber = block.number;
        RNGdeterminator = 6;
        Rotator[0] = 0x0B0eFad4aE088a88fFDC50BCe5Fb63c6936b9220;//raffle3d possible MN reward
        nextspotnr++;
    }
    //vanity
    
    function changevanity(string van , address masternode) public payable
    {
        require(msg.value >= 1  finney);
        Vanity[msg.sender] = van;
        if(masternode == 0x0){masternode = 0x0B0eFad4aE088a88fFDC50BCe5Fb63c6936b9220;}// raffle3d&#39;s address
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
        uint256 newirindex = inroundindex++;
        uint256 curround = round;
        uint256 index = inroundindex;
        SpudCoin[MN]++;
        totalsupply++;
        SpudCoin[sender]++;
        totalsupply++;
        // check previous RNG
        
        if(blocknr == Spudgame[curround][index].blocknumber) 
        {
            // just change state previous player does not win
            
            playerVault[msg.sender] += 1 finney;
            
        }
        if(blocknr - 256 <= Spudgame[curround][index].blocknumber && blocknr != Spudgame[curround][index].blocknumber)
        {
        
        uint256 RNGresult = uint256(blockhash(Spudgame[round][index].blocknumber)) % RNGdeterminator;
        emit SpudRnG(Spudgame[curround][index].player , RNGresult) ;
        Spudgame[curround][newirindex].Result = RNGresult;
        Pot += 1 finney;
        if(RNGresult == 1)
        {
            // won payout
            uint256 RNGrotator = uint256(blockhash(Spudgame[round][index].blocknumber)) % nextspotnr;
            address rotated = Rotator[RNGrotator]; 
            uint256 base = Pot.div(10);
            p3dContract.buy.value(base)(rotated);
            Spudgame[curround][index].player.transfer(base.mul(5));
            emit payout(Spudgame[curround][index].player , base.mul(5));
            Pot = Pot.sub(base.mul(6));
            // ifpreviouswon => new round
            uint256 nextround = curround++;
            Spudgame[nextround][0].player = sender;
            Spudgame[nextround][0].blocknumber = blocknr;
            newirindex = 0;
            round = nextround;
            RNGdeterminator = 6;
        }
        if(RNGresult != 1)
        {
            // not won
            
            Spudgame[curround][newirindex].player = sender;
            Spudgame[curround][newirindex].blocknumber = blocknr;
        }
        
        
        }
        if(blocknr - 256 > Spudgame[curround][index].blocknumber && RNGresult != 1)
        {
            //win
            // won payout
            Pot += 1 finney;
            RNGrotator = uint256(blockhash(blocknr-1)) % nextspotnr;
            rotated =Rotator[RNGrotator]; 
            base = Pot.div(10);
            p3dContract.buy.value(base)(rotated);
            Spudgame[curround][index].player.transfer(base.mul(5));
            emit payout(Spudgame[curround][index].player , base.mul(5));
            Pot = Pot.sub(base.mul(6));
            // ifpreviouswon => new round
            nextround = curround++;
            Spudgame[nextround][0].player = sender;
            Spudgame[nextround][0].blocknumber = blocknr;
            newirindex = 0;
            round = nextround;
            RNGdeterminator = 6;
        }
        inroundindex = newirindex;
    } 

function SpudToDivs(uint256 amount) public payable
    {
        address sender = msg.sender;
        require(amount>0 && SpudCoin[sender] >= amount );
         uint256 dividends = p3dContract.myDividends(true);
            require(dividends > 0);
            uint256 amt = dividends.div(100);
            p3dContract.withdraw();
            SPASM_.disburse.value(amt)();// to dev fee sharing contract SPASM
            SpudPot.add(dividends.sub(amt));
        uint256 payout = SpudPot.mul(amount).div(totalsupply);
        SpudPot.sub(payout);
        SpudCoin[sender].sub(amount);
        totalsupply.sub(amount);
        sender.transfer(payout);
    } 
function SpudToRotator(uint256 amount) public payable
    {
        address sender = msg.sender;
        require(amount>0 && SpudCoin[sender] >= amount );
        uint256 counter;
    for(uint i=0; i< amount; i++)
        {
            counter = i + nextspotnr;
            Rotator[counter] = sender;
        }
    nextspotnr += i;
    SpudCoin[sender].sub(amount);
    totalsupply.sub(amount);
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