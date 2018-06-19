pragma solidity ^0.4.21;

// Dev fee payout contract + dividend options 
// EtherGuy DApp fee will be stored here 
// Buying any token gives right to claim 
// UI: etherguy.surge.sh/dividend.html
// Made by EtherGuy, <a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="8de8f9e5e8ffeaf8f4cde0ece4e1a3eee2e0">[email&#160;protected]</a> 

// IF THERE IS ANY BUG the data will be rerolled from here. See the discord https://discord.gg/R84hD6f if anything happens or mail me 


contract Dividends{
    // 10 million token supply 
    uint256 constant TokenSupply = 10000000;
    
    uint256 public TotalPaid = 0;
    
    uint16 public Tax = 1250; 
    
    address dev;
    
    mapping (address => uint256) public MyTokens;
    mapping (address => uint256) public DividendCollectSince;
    
    // TKNS / PRICE 
    mapping(address => uint256[2]) public SellOrder;
    
    // web 
    // returns tokens + price (in wei)
    function GetSellOrderDetails(address who) public view returns (uint256, uint256){
        return (SellOrder[who][0], SellOrder[who][1]);
    }
    
    function ViewMyTokens(address who) public view returns (uint256){
        return MyTokens[who];
    }
    
    function ViewMyDivs(address who) public view returns (uint256){
        uint256 tkns = MyTokens[who];
        if (tkns==0){
            return 0;
        }
        return (GetDividends(who, tkns));
    }
    
    function Bal() public view returns (uint256){
        return (address(this).balance);
    }
    
    // >MINT IT
    function Dividends() public {
        dev = msg.sender;
        // EG
        MyTokens[msg.sender] = TokenSupply - 400000;
        // HE
        MyTokens[address(0x83c0Efc6d8B16D87BFe1335AB6BcAb3Ed3960285)] = 200000;
        // PG
        MyTokens[address(0x26581d1983ced8955C170eB4d3222DCd3845a092)] = 200000;
        //MyTokens[address(0x0)] = 400000;
        PlaceSellOrder(1600000, (0.5 szabo)); // 1 token per 0.5 szabo / 500 gwei or 1000 tokens per 0.5 finney / 0.0005 ether or 1M tokens per 0.5 ETH 
    }
    
    function GetDividends(address who, uint256 TokenAmount) internal view  returns(uint256){
        if (TokenAmount == 0){
            return 0;
        }
        uint256 TotalContractIn = address(this).balance + TotalPaid;
        // division rounds DOWN so we never pay too much
        // no revert errors due to this. 
        
        uint256 MyBalance = sub(TotalContractIn, DividendCollectSince[who]);
        
        return  ((MyBalance * TokenAmount) / (TokenSupply));
    }
    

    event Sold(address Buyer, address Seller, uint256 price, uint256 tokens);
    function Buy(address who) public payable {
       // require(msg.value >= (1 szabo)); // normal amounts pls 
        // lookup order by addr 
        uint256[2] memory order = SellOrder[who];
        uint256 amt_available = order[0];
        uint256 price = order[1];
        
        uint256 excess = 0;
        
        // nothing to sell 
        if (amt_available == 0){
            revert();
        }
        
        uint256 max = amt_available * price; 
        uint256 currval = msg.value;
        // more than max buy value 
        if (currval > max){
            excess = (currval-max);
            currval = max;
        }
        



        uint256 take = currval / price;
        
        if (take == 0){
            revert(); // very high price apparently 
        }
        excess = excess + sub(currval, take * price); 

        
        if (excess > 0){
            msg.sender.transfer(excess);
        }
        
        currval = sub(currval,excess);
        
        // pay fees 

        uint256 fee = (Tax * currval)/10000;
        dev.transfer(fee);
        who.transfer(currval-fee);
        
        // the person with these tokens will also receive dividend over this buy order (this.balance)
        // however the excess is removed, see the excess transfer above 
     //   if (msg.value > (excess+currval+fee)){
      //      msg.sender.transfer(msg.value-excess-currval-fee);
     //   }
        _withdraw(who, MyTokens[who]);
        if (MyTokens[msg.sender] > 0){
            
            _withdraw(msg.sender, MyTokens[msg.sender]);
        }
        MyTokens[who] = MyTokens[who] - take; 
        SellOrder[who][0] = SellOrder[who][0]-take; 
        MyTokens[msg.sender] = MyTokens[msg.sender] + take;
    //    MyPayouts[msg.sender] = MyPayouts[msg.sender] + GetDividends(msg.sender, take);
        DividendCollectSince[msg.sender] = (address(this).balance) + TotalPaid;
        
        emit Sold(msg.sender, who, price, take);
       // push((excess + currval)/(1 finney), (msg.value)/(1 finney));
    }
    
    function Withdraw() public {
        _withdraw(msg.sender, MyTokens[msg.sender]);
    }
    
    function _withdraw(address who, uint256 amt) internal{
        // withdraws from amt. 
        // (amt not used in current code, always same value)
        if (MyTokens[who] < amt){
            revert(); // ??? security check 
        }
        
        uint256 divs = GetDividends(who, amt);
        
        who.transfer(divs);
        TotalPaid = TotalPaid + divs;
        
        DividendCollectSince[who] = TotalPaid + address(this).balance;
    }
    
    event SellOrderPlaced(address who, uint256 amt, uint256 price);
    function PlaceSellOrder(uint256 amt, uint256 price) public {
        // replaces old order 
        if (amt > MyTokens[msg.sender]){
            revert(); // ?? more sell than you got 
        }
        SellOrder[msg.sender] = [amt,price];
        emit SellOrderPlaced(msg.sender, amt, price);
    }
    
    function ChangeTax(uint16 amt) public {
        require (amt <= 2500);
        require(msg.sender == dev);
        Tax=amt;
    }
    
    
    // dump divs in contract 
    function() public payable {
        
    }
    
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    } 
    
}