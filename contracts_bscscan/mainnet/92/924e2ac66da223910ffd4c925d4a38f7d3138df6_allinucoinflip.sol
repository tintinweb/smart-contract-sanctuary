/**
 *Submitted for verification at BscScan.com on 2021-11-08
*/

pragma solidity >=0.6.8;
contract allinucoinflip {
    struct Bet {
        address creator;
        address referrer;
        uint256 time;
        uint256 value;
        uint256 betFor; //tails or heads
    }
    
    address private _chef;
    mapping(address => Bet) public Bets;
    address[] public BetLUT;
    uint256 private _chefTips;
    uint256 public _tipsRate;
    uint256 public _refRate;
    uint256 public _cancelFee;
    
    event NewBet (address creator, uint256 betFor, uint256 value, uint256 time);
    event CancelBet (address creator, uint256 betFor, uint256 value);
    event WinBet (address indexed creator, address indexed joiner, address indexed ref, uint256 betFor, uint256 win, uint256 value, uint256 time);
    
    constructor () public {
        _chef = msg.sender;
        _tipsRate=500; _cancelFee=100; _refRate=100;// rate/10000 => 500 <=> 5%
    }
    
    function toss() internal view returns(uint256) { return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, block.gaslimit, block.coinbase, block.number)))%2; }
    
    function send(address to, uint256 amt, uint256 tips, address ref) private returns (bool){
        (bool sentTo,) = address(to).call{value : amt-tips}("");
        if(tips>0) {
            if(ref != 0x0000000000000000000000000000000000000000) {
                uint256 refEarn = amt/2*_refRate/10000;//sharing tips with referral
                (bool sentRef,) = address(ref).call{value : refEarn}("");
                if(sentRef) tips -= refEarn;
            }
            
            (bool sentFee,) = address(_chef).call{value : tips}("");
            _chefTips += tips;
            return sentTo&&sentFee;
        }
        return sentTo;
    }
    
    function removeBet(address addr) private {
        for (uint256 i = 0; i < BetLUT.length; i++) {
            if (BetLUT[i] == addr) {
                delete Bets[addr];
                BetLUT[i] = BetLUT[BetLUT.length - 1];
                BetLUT.pop();
                break;
            }
        }
    }
    
    function createBet (uint256 betFor, address ref) public payable {
        require(msg.value > 0, "Cant bet for zero"); require(betFor < 2, "BetFor 1 or 0");
        require(msg.sender != ref, "!self ref");require(Bets[msg.sender].value == 0, "You have a pending bet");
        Bets[msg.sender] = Bet({ creator: msg.sender, referrer: ref, value: msg.value, betFor: betFor, time: block.timestamp });
        BetLUT.push(msg.sender);
        emit NewBet(msg.sender, betFor, msg.value, block.timestamp);
    }
    
    function cancelBet () public payable {
        require(Bets[msg.sender].value > 0, "You have no pending bet");
        uint256 fee = Bets[msg.sender].value * _cancelFee/10000;
        require(send(msg.sender, Bets[msg.sender].value, fee, 0x0000000000000000000000000000000000000000), 'Cancel bet failed');
        removeBet(msg.sender);
        emit CancelBet (msg.sender, Bets[msg.sender].betFor, Bets[msg.sender].value);
    }
    
    function takeBet (address with) public payable {
        require(tx.origin == msg.sender, "Humans only");
        Bet memory bet = Bets[with];
        require(bet.value > 0, "Bet is unavailable");
        require(msg.value > 0 && msg.value == bet.value, "Unfair bet");
        uint256 tips = bet.value * _tipsRate/10000;
        uint256 win = bet.value + msg.value;
        uint256 winNum = toss();
        if(winNum==bet.betFor) require(send(with, win, tips, bet.referrer), 'Reward failed');//creator win
        else require(send(msg.sender, win, tips, bet.referrer), 'Reward failed');//joiner win
        
        removeBet(with);
        emit WinBet (with, msg.sender, bet.referrer, bet.betFor, winNum, msg.value, block.timestamp);
    }
    
    function countBets() public view returns (uint256) { return BetLUT.length; }
    
    function chefTips() public view returns (uint256) { require(msg.sender==_chef, "!chef"); return _chefTips; }
    function setTipRate(uint256 rate) public { require(msg.sender==_chef, "!chef");require(rate <= 1500, "hey chef! don't be greedy");_tipsRate = rate; }
    function setRefRate(uint256 rate) public { require(msg.sender==_chef, "!chef");require(rate <= 1500, "nax 15%");_refRate = rate; }
    function setCancelRate(uint256 rate) public { require(msg.sender==_chef, "!chef");require(rate <= 300, "max 3%");_cancelFee = rate; }
}