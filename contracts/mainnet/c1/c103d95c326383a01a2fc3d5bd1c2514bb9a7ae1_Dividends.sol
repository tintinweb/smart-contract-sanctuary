pragma solidity ^0.4.21;

// Dev fee payout contract + dividend options 
// EtherGuy DApp fee will be stored here 
// Buying any token gives right to claim part of development dividends.
// It is suggested you do withdraw once in a while. If someone still finds an attack after this fixed contrat 
// they are unable the steal any of your withdrawn eth. Withdrawing does not sell your tokens!
// UI: etherguy.surge.sh/dividend.html
// Made by EtherGuy, <a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="adc8d9c5c8dfcad8d4edc0ccc4c183cec2c0">[email&#160;protected]</a> 
// Version 2 of contract. Exploit(s) found by ccashwell in v1, thanks for reporting them!


// IF THERE IS ANY BUG the data will be rerolled from here. See the discord https://discord.gg/R84hD6f if anything happens or mail me 


contract Dividends{
    // 10 million token supply 
    uint256 constant TokenSupply = 10000000;
    
    uint256 public TotalPaid = 0;
    
    uint16 public Tax = 1250; 
    
    address dev;
    
    bool public StopSell=false; // in case aonther bug is found, stop selling so it is easier to give everyone their tokens back. 
    
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
        MyTokens[msg.sender] =  8000000;// was: TokenSupply - 400000;
        // HE
        MyTokens[address(0x83c0Efc6d8B16D87BFe1335AB6BcAb3Ed3960285)] = 200000;
        // PG
        MyTokens[address(0x26581d1983ced8955C170eB4d3222DCd3845a092)] = 200000;
        //MyTokens[address(0x0)] = 400000;
        
        // Since not a lot of addresses bought, we can instantly restore this 
        // If this happens in the future, we will need users to do a single transaction to retrieve their tokens from 
        // previous contract and withdraw all amount immediately 
        // Below tokens are paid for - 0.5 szabo per token (cheap right? blame the develo --- oh wait :D )
        
        MyTokens[address(0x3130259deEdb3052E24FAD9d5E1f490CB8CCcaa0)] = 100000;
        MyTokens[address(0x4f0d861281161f39c62B790995fb1e7a0B81B07b)] = 200000;
        MyTokens[address(0x36E058332aE39efaD2315776B9c844E30d07388B)] =  20000;
        MyTokens[address(0x1f2672E17fD7Ec4b52B7F40D41eC5C477fe85c0c)] =  40000;
        MyTokens[address(0xedDaD54E9e1F8dd01e815d84b255998a0a901BbF)] =  20000;
        MyTokens[address(0x0a3239799518E7F7F339867A4739282014b97Dcf)] = 500000;
        MyTokens[address(0x29A9c76aD091c015C12081A1B201c3ea56884579)] = 600000;
        MyTokens[address(0x0668deA6B5ec94D7Ce3C43Fe477888eee2FC1b2C)] = 100000;
        MyTokens[address(0x0982a0bf061f3cec2a004b4d2c802F479099C971)] =  20000;
        //                                                              ------+
        //                                                             1600000 = 1.6M which corresponds to the sell volume. Nice.     +400k + 8M = 10M, which corresponds to token supply                                                          
        
        //PlaceSellOrder(1600000, (0.5 szabo)); // 1 token per 0.5 szabo / 500 gwei or 1000 tokens per 0.5 finney / 0.0005 ether or 1M tokens per 0.5 ETH 
    }
    
    function GetDividends(address who, uint256 TokenAmount ) internal view  returns(uint256){
        if (TokenAmount == 0){
            return 0;
        }
        uint256 TotalContractIn = address(this).balance + TotalPaid;
        // division rounds DOWN so we never pay too much
        // no revert errors due to this. 
        
        uint256 MyBalance = sub(TotalContractIn, DividendCollectSince[who]);
        
        return  ((MyBalance * TokenAmount) / (TokenSupply));
    }
    
    // dev can stop selling 
    // this does NOT DISABLE withdrawing 
    function EmergencyStopSell(bool setting) public {
        require(msg.sender==dev);
        StopSell=setting;
    }
    

    event Sold(address Buyer, address Seller, uint256 price, uint256 tokens);
    // price_max anti-scam arg 
    function Buy(address who, uint256 price_max) public payable {
       // require(msg.value >= (1 szabo)); // normal amounts pls 
        // lookup order by addr 
        require(!StopSell);
        require(who!=msg.sender && who!=tx.origin);
        uint256[2] storage order = SellOrder[who];
        uint256 amt_available = order[0];
        uint256 price = order[1];
        
        // only buy for certain price 
        require(price <= price_max);
        
        uint256 excess = 0;
        
        // nothing to sell 
        if (amt_available == 0){
            revert();
        }
        
        // high price overflow prevent (ccashwell)
        uint256 max = mul(amt_available, price); 
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
        excess = excess + sub(currval, mul(take, price)); 
        // do not take max value off .
        currval = sub(currval,sub(currval, mul(take, price)));
        
        // pay fees 

        uint256 fee = (mul(Tax, currval))/10000;

        
        // the person with these tokens will also receive dividend over this buy order (this.balance)
        // however the excess is removed, see the excess transfer above 
     //   if (msg.value > (excess+currval+fee)){
      //      msg.sender.transfer(msg.value-excess-currval-fee);
     //   }


        MyTokens[who] = MyTokens[who] - take; 
        SellOrder[who][0] = SellOrder[who][0]-take; 
        MyTokens[msg.sender] = MyTokens[msg.sender] + take;
    //    MyPayouts[msg.sender] = MyPayouts[msg.sender] + GetDividends(msg.sender, take);
        //DividendCollectSince[msg.sender] = (address(this).balance) + TotalPaid;
        
        emit Sold(msg.sender, who, price, take);
       // push((excess + currval)/(1 finney), (msg.value)/(1 finney));
       
       // all transfers at end 
       
       
        dev.transfer(fee);
        who.transfer(currval-fee);
        if ((excess) > 0){
            msg.sender.transfer(excess);
        }
        // call withdraw with tokens before data change 
        _withdraw(who, MyTokens[who]+take);
        //DividendCollectSince[msg.sender] = (address(this).balance) + TotalPaid;
        if (sub(MyTokens[msg.sender],take) > 0){
            _withdraw(msg.sender,MyTokens[msg.sender]-take);    
        }
        else{
            // withdraw zero tokens to set DividendCollectSince to the right place. 
            // updates before this break the withdraw if user has any tokens .
            _withdraw(msg.sender, 0);
        }
        
        
        
    }
    
    function Withdraw() public {
        _withdraw(msg.sender, MyTokens[msg.sender]);
    }
    
    
    event GiveETH(address who, uint256 yummy_eth);
    function _withdraw(address who, uint256 amt) internal{
        // withdraws from amt. 
        // (amt not used in current code, always same value)
       // if (MyTokens[who] < amt){
        //    revert(); // ??? security check 
       // }
        
        uint256 divs = GetDividends(who, amt);
        TotalPaid = TotalPaid + divs;
        DividendCollectSince[who] = sub(TotalPaid + address(this).balance, divs);
        
        // muh logs 
        emit GiveETH(who, divs);
        
        who.transfer(divs);

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
    
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }
    
}