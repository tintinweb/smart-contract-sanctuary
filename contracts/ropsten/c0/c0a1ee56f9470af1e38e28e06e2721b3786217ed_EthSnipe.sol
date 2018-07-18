pragma solidity ^0.4.24;

// 

contract EthSnipe{ 
    using SafeMath for *;
    
    uint BasicKeyPrice = (1 finney);
    uint DeltaKeyPrice = (1 finney);//..(100 szabo);
    uint JackpotSplit = 50;
    //uint DivSplit = 50;
    uint JackpotPay = 50;
    
    uint MaxRoundTime = (10 minutes);//(2 minutes);// (12 hours);
    uint StartTime = (5 minutes);// hours);
    uint KeyAddTime = (30 seconds); //(2 minutes);
    
    uint Magnitude = (10 ** 18);
    
    address owner;
    
    uint public refKeyPrice = (0.01 ether);
    uint refKeyDelta = (0.01 ether);
    uint RefPCT = 10;
    
    mapping(address => bool) public refs;
    mapping(address => address) public refsof;
    mapping(uint => uint) ProfitPerKey;
    
    event UserInvest(address who, uint value, uint Keys);
    event UserReinvest(address who, uint value, uint Keys);
    event UserWithdraw(address who, uint value);
    event UserWon(address who, uint payment);
    event UserRef(address who, address ref);

    
    constructor() public {
        owner=msg.sender;
        refs[owner] = true;
    }
    
    // struct size: 3 storage slots [80k new; 20k update max]
    struct RoundData{
        uint TotalPot; // 256 
        uint KeysSold; // 256
        uint CloseTime; // 96 
        address Winner; // 160
    }
    
    uint public RoundNum;
    
    RoundData public currentRound;
    
    // struct size: 1 storage slot [40k new; 10k update]
    struct Keyring{
        uint Keys; // max 2^70 &quot;real&quot; keys 
        uint Payment;     
    }
    
    modifier maxVal(uint what, uint bits){
        require(chkBSize(what, bits)); // 
        _;
    }
    
    function getRemainingTime() public view returns (uint){
        if (currentRound.CloseTime < now){
            return 0;
        }
        return currentRound.CloseTime - now;
    }
    
    function chkBSize(uint what, uint bits) internal pure returns (bool){ 
        return (what < (2 ** bits));
    }
    
    
    //      user               round
    mapping(address => mapping(uint => Keyring)) public vault;
    
    function() public payable{
        buy(address(owner));
    }
    
    function finishGame() public{
        RoundData memory rd = currentRound;
        require(now > rd.CloseTime);
        rd.KeysSold = 0;
        uint Pay = (rd.TotalPot.mul(JackpotPay)) / 100;
        if (rd.Winner.send(Pay)){
            rd.TotalPot = rd.TotalPot.sub(Pay);
        }
        else{
            // nice try poorfag 
        }
        rd.CloseTime = (now + StartTime);
        //ProfitPerKey[RoundNum] = 0;
        
        currentRound = rd;
        
        RoundNum++;
        
        emit UserWon(rd.Winner, Pay);
    }
    
    function buy(address ref) public payable{
        uint keys = _buy(ref, msg.value);
        emit UserInvest(msg.sender, msg.value, keys);
    }
    
    function _buy(address ref, uint value) internal returns (uint){
        require(value > 0);
        uint ogvalue=value;
        if (now > currentRound.CloseTime){
            finishGame();
        }
        
        address refchk = refsof[msg.sender];
        if (refchk != address(0x0)){
            ref = refchk;
        }
        if (ref != address(0x0) && refs[ref]){
            //value -= value/10; // cannot underflow 
            refsof[msg.sender] = ref;
            if (!ref.send(value/10)){
                value = msg.value; // poorfags   
            } 
            else{
                emit UserRef(msg.sender, ref);
                 value -= value/10; // cannot underflow 
            }
           
        }
        
        // calculate number of keys;
        
        uint Price = ((currentRound.KeysSold + Magnitude) * (DeltaKeyPrice) + BasicKeyPrice) / Magnitude;
        require(value <= (Price.mul(10))); // antiwhale max buy 10 keys 
        
        uint Keys = (ogvalue * Magnitude) / Price;
        require(Keys > 1);
        
        RoundData memory cr = currentRound;
        
        if (Keys >= Magnitude){
            // get jp 
            uint addTime = cr.CloseTime.add( (Keys / Magnitude).mul( KeyAddTime )); // only full keys
            if (addTime > (now + MaxRoundTime)){
                cr.CloseTime = (now + MaxRoundTime);
            }
            else{
                cr.CloseTime = addTime;
            }
            cr.Winner = msg.sender;
        }
        
       // require(chkBSize(cr.KeysSold + Keys, 56));
        cr.KeysSold = (cr.KeysSold.add(Keys));
        uint ToPot = (value.mul(JackpotSplit)/100);
        cr.TotalPot = cr.TotalPot.add(ToPot);
        uint update = (((value.sub(ToPot)).mul(Magnitude)) / Keys);
        //cr.ProfitPerKey = cr.ProfitPerKey.add(update);
        ProfitPerKey[RoundNum] = ProfitPerKey[RoundNum].add(update);

        currentRound = cr;
        
        Keyring memory PD = vault[msg.sender][RoundNum];
        PD.Keys = (PD.Keys + Keys);
        PD.Payment += ((ProfitPerKey[RoundNum] - update) * Keys);
        
        vault[msg.sender][RoundNum] = PD;
        
        return Keys;
    }
    
    
    function buyRef() public payable{
        require(msg.value >= refKeyPrice);
        uint diff = msg.value - refKeyPrice;
        if (diff > 0){
            // safe transfer 
            msg.sender.transfer(diff);
        }
        // safe transfer [2300 gas]
        owner.transfer(refKeyPrice);
        refs[msg.sender] = true;
        refKeyPrice += refKeyDelta;
    }
    
    function getUserDivs(address who, uint Round) public view returns (uint){
        Keyring memory PD = vault[who][Round];
        uint PPS = ProfitPerKey[Round];
        uint profit = (PD.Keys.mul(PPS).sub(PD.Payment)) / Magnitude;
        return profit;
    }
    
    function getKeyPrice() public view returns (uint){
        return ((currentRound.KeysSold + Magnitude) * (DeltaKeyPrice) + BasicKeyPrice) / Magnitude;
    }
    
    function withdraw(uint Round) public {
        Keyring memory PD = vault[msg.sender][Round];
        uint PPS = ProfitPerKey[Round];
        uint profit = (PD.Keys.mul(PPS).sub(PD.Payment)) / Magnitude;

        PD.Payment = (PD.Payment.add(profit.mul(Magnitude)));
        vault[msg.sender][Round] = PD;
        msg.sender.transfer(profit);
        emit UserWithdraw(msg.sender, profit);
    }
    
    function reinvest() public {
        Keyring memory PD = vault[msg.sender][RoundNum];
        uint PPS = ProfitPerKey[RoundNum];
        uint profit = (PD.Keys.mul(PPS).sub(PD.Payment)) / Magnitude;

        PD.Payment = (PD.Payment.add(profit.mul(Magnitude)));
        vault[msg.sender][RoundNum] = PD;
        uint Keys = _buy(address(0x0), profit);
        emit UserReinvest(msg.sender, profit, Keys);
    }
}


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