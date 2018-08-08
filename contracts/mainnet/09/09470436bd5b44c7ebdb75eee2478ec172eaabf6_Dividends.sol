pragma solidity ^0.4.21;

// ERC20 contract which has the dividend shares of Ethopolis in it 
// The old contract had a bug in it, thanks to ccashwell for notifying.
// Contact: <a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="3f5a4b575a4d584a467f525e5653115c5052">[email&#160;protected]</a> 
// ethopolis.io 
// etherguy.surge.sh [if the .io site is up this might be outdated, one of those sites will be up-to-date]
// Selling tokens (and buying them) will be online at etherguy.surge.sh/dividends.html and might be moved to the ethopolis site.

contract Dividends {

    string public name = "Ethopolis Shares";      //  token name
    string public symbol = "EPS";           //  token symbol
    uint256 public decimals = 18;            //  token digit

    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    uint256 public totalSupply = 10000000* (10 ** uint256(decimals));
    
    uint256 SellFee = 1250; // max is 10 000


    address owner = 0x0;

    modifier isOwner {
        assert(owner == msg.sender);
        _;
    }



    modifier validAddress {
        assert(0x0 != msg.sender);
        _;
    }

    function Dividends() public {
        owner = msg.sender;


        // PREMINED TOKENS 
        
        // EG
        balanceOf[msg.sender] =  8000000* (10 ** uint256(decimals));// was: TokenSupply - 400000;
        // HE
        balanceOf[address(0x83c0Efc6d8B16D87BFe1335AB6BcAb3Ed3960285)] = 200000* (10 ** uint256(decimals));
        // PG
        balanceOf[address(0x26581d1983ced8955C170eB4d3222DCd3845a092)] = 200000* (10 ** uint256(decimals));

        // BOUGHT tokens in the OLD contract         
        balanceOf[address(0x3130259deEdb3052E24FAD9d5E1f490CB8CCcaa0)] = 100000* (10 ** uint256(decimals));
        balanceOf[address(0x4f0d861281161f39c62B790995fb1e7a0B81B07b)] = 200000* (10 ** uint256(decimals));
        balanceOf[address(0x36E058332aE39efaD2315776B9c844E30d07388B)] =  20000* (10 ** uint256(decimals));
        balanceOf[address(0x1f2672E17fD7Ec4b52B7F40D41eC5C477fe85c0c)] =  40000* (10 ** uint256(decimals));
        balanceOf[address(0xedDaD54E9e1F8dd01e815d84b255998a0a901BbF)] =  20000* (10 ** uint256(decimals));
        balanceOf[address(0x0a3239799518E7F7F339867A4739282014b97Dcf)] = 500000* (10 ** uint256(decimals));
        balanceOf[address(0x29A9c76aD091c015C12081A1B201c3ea56884579)] = 600000* (10 ** uint256(decimals));
        balanceOf[address(0x0668deA6B5ec94D7Ce3C43Fe477888eee2FC1b2C)] = 100000* (10 ** uint256(decimals));
        balanceOf[address(0x0982a0bf061f3cec2a004b4d2c802F479099C971)] =  20000* (10 ** uint256(decimals));

        // Etherscan likes it very much if we emit these events 
        emit Transfer(0x0, msg.sender, 8000000* (10 ** uint256(decimals)));
        emit Transfer(0x0, 0x83c0Efc6d8B16D87BFe1335AB6BcAb3Ed3960285, 200000* (10 ** uint256(decimals)));
        emit Transfer(0x0, 0x26581d1983ced8955C170eB4d3222DCd3845a092, 200000* (10 ** uint256(decimals)));
        emit Transfer(0x0, 0x3130259deEdb3052E24FAD9d5E1f490CB8CCcaa0, 100000* (10 ** uint256(decimals)));
        emit Transfer(0x0, 0x4f0d861281161f39c62B790995fb1e7a0B81B07b, 200000* (10 ** uint256(decimals)));
        emit Transfer(0x0, 0x36E058332aE39efaD2315776B9c844E30d07388B, 20000* (10 ** uint256(decimals)));
        emit Transfer(0x0, 0x1f2672E17fD7Ec4b52B7F40D41eC5C477fe85c0c, 40000* (10 ** uint256(decimals)));
        emit Transfer(0x0, 0xedDaD54E9e1F8dd01e815d84b255998a0a901BbF, 20000* (10 ** uint256(decimals)));
        emit Transfer(0x0, 0x0a3239799518E7F7F339867A4739282014b97Dcf, 500000* (10 ** uint256(decimals)));
        emit Transfer(0x0, 0x29A9c76aD091c015C12081A1B201c3ea56884579, 600000* (10 ** uint256(decimals)));
        emit Transfer(0x0, 0x0668deA6B5ec94D7Ce3C43Fe477888eee2FC1b2C, 100000* (10 ** uint256(decimals)));
        emit Transfer(0x0, 0x0982a0bf061f3cec2a004b4d2c802F479099C971, 20000* (10 ** uint256(decimals)));
       
    }

    function transfer(address _to, uint256 _value)  public validAddress returns (bool success) {
        require(balanceOf[msg.sender] >= _value);
        require(balanceOf[_to] + _value >= balanceOf[_to]);
        // after transfer have enough to pay sell order 
        require(sub(balanceOf[msg.sender], SellOrders[msg.sender][0]) >= _value);
        require(msg.sender != _to);

        uint256 _toBal = balanceOf[_to];
        uint256 _fromBal = balanceOf[msg.sender];
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        
        uint256 _sendFrom = _withdraw(msg.sender, _fromBal, false);
        uint256 _sendTo = _withdraw(_to, _toBal, false);
        
        msg.sender.transfer(_sendFrom);
        _to.transfer(_sendTo);
        
        return true;
    }
    
    // forcetransfer does not do any withdrawals
    function _forceTransfer(address _from, address _to, uint256  _value) internal validAddress {
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to] + _value >= balanceOf[_to]);
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
        
    }

    function transferFrom(address _from, address _to, uint256 _value) public validAddress returns (bool success) {
                // after transfer have enough to pay sell order 
        require(_from != _to);
        require(sub(balanceOf[_from], SellOrders[_from][0]) >= _value);
        require(balanceOf[_to] + _value >= balanceOf[_to]);
        require(allowance[_from][msg.sender] >= _value);
        uint256 _toBal = balanceOf[_to];
        uint256 _fromBal = balanceOf[_from];
        balanceOf[_to] += _value;
        balanceOf[_from] -= _value;
        allowance[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        
        // Call withdrawal of old amounts 
        CancelOrder();
        uint256 _sendFrom = _withdraw(_from, _fromBal,false);
        uint256 _sendTo = _withdraw(_to, _toBal,false);
        
        _from.transfer(_sendFrom);
        _to.transfer(_sendTo);
        
        return true;
    }

    function approve(address _spender, uint256 _value) public validAddress returns (bool success) {
        require(_value == 0 || allowance[msg.sender][_spender] == 0);
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function setSymbol(string _symb) public isOwner {
        symbol = _symb;
    }

    function setName(string _name) public isOwner {
        name = _name;
    }
    
    function newOwner(address who) public isOwner validAddress {
        owner = who;
    }
    
    function setFee(uint256 fee) public isOwner {
        require (fee <= 2500);
        SellFee = fee;
    }


// Market stuff start 
    
    mapping(address => uint256[2]) public SellOrders;
    mapping(address => uint256) public LastBalanceWithdrawn;
    uint256 TotalOut;
    
    function Withdraw() public{
        _withdraw(msg.sender, balanceOf[msg.sender], true);
    }
    
    function ViewSellOrder(address who) public view returns (uint256, uint256){
        return (SellOrders[who][0], SellOrders[who][1]);
    }
    
    // if dosend is set to false then the calling function MUST send the fees 
    function _withdraw(address to, uint256 tkns, bool dosend) internal returns (uint256){
        // calculate how much wei you get 
        if (tkns == 0){
            // ok we just reset the timer then 
            LastBalanceWithdrawn[msg.sender] = sub(add(address(this).balance, TotalOut),msg.value);
            return;
        }
        // remove msg.value is exists. if it is nonzero then the call came from Buy, do not include this in balance. 
        uint256 total_volume_in = address(this).balance + TotalOut - msg.value;
        // get volume in since last withdrawal; 
        uint256 Delta = sub(total_volume_in, LastBalanceWithdrawn[to]);
        
        uint256 Get = (tkns * Delta) / totalSupply;
        
        TotalOut = TotalOut + Get;
        
        LastBalanceWithdrawn[to] = sub(sub(add(address(this).balance, TotalOut), Get),msg.value);
        
        emit WithdrawalComplete(to, Get);
        if (dosend){
            to.transfer(Get);
            return 0;
        }
        else{
            return Get;
        }
        
    }
    
    function GetDivs(address who) public view returns (uint256){
         uint256 total_volume_in = address(this).balance + TotalOut;
         uint256 Delta = sub(total_volume_in, LastBalanceWithdrawn[who]);
         uint256 Get = (balanceOf[who] * Delta) / totalSupply;
         return (Get);
    }
    
    function CancelOrder() public {
        _cancelOrder(msg.sender);
    }
    
    function _cancelOrder(address target) internal{
         SellOrders[target][0] = 0;
         emit SellOrderCancelled(target);
    }
    
    
    // the price is per 10^decimals tokens 
    function PlaceSellOrder(uint256 amount, uint256 price) public {
        require(price > 0);
        require(balanceOf[msg.sender] >= amount);
        SellOrders[msg.sender] = [amount, price];
        emit SellOrderPlaced(msg.sender, amount, price);
    }

    // Safe buy order where user specifies the max amount to buy and the max price; prevents snipers changing their price 
    function Buy(address target, uint256 maxamount, uint256 maxprice) public payable {
        require(SellOrders[target][0] > 0);
        require(SellOrders[target][1] <= maxprice);
        uint256 price = SellOrders[target][1];
        uint256 amount_buyable = (mul(msg.value, uint256(10**decimals))) / price; 
        
        // decide how much we buy 
        
        if (amount_buyable > SellOrders[target][0]){
            amount_buyable = SellOrders[target][0];
        }
        if (amount_buyable > maxamount){
            amount_buyable = maxamount;
        }
        //10000000000000000000,1000
        //"0xca35b7d915458ef540ade6068dfe2f44e8fa733c",10000000000000000000,1000
        uint256 total_payment = mul(amount_buyable, price) / (uint256(10 ** decimals));
        
        // Let&#39;s buy tokens and actually pay, okay?
        require(amount_buyable > 0 && total_payment > 0); 
        
        // From the amount we actually pay, we take exchange fee from it 
        
        uint256 Fee = mul(total_payment, SellFee) / 10000;
        uint256 Left = total_payment - Fee; 
        
        uint256 Excess = msg.value - total_payment;
        
        uint256 OldTokensSeller = balanceOf[target];
        uint256 OldTokensBuyer = balanceOf[msg.sender];

        // Change it in memory 
        _forceTransfer(target, msg.sender, amount_buyable);
        
        // Pay out withdrawals and reset timer
        // Prevents double withdrawals in same tx
        
        // Change sell order 
        SellOrders[target][0] = sub(SellOrders[target][0],amount_buyable);
        
        
        // start all transfer stuff 

        uint256 _sendTarget = _withdraw(target, OldTokensSeller, false);
        uint256 _sendBuyer = _withdraw(msg.sender, OldTokensBuyer, false );
        
        // in one transfer saves gas, but its not nice in the etherscan logs 
        target.transfer(add(Left, _sendTarget));
        
        if (add(Excess, _sendBuyer) > 0){
            msg.sender.transfer(add(Excess,_sendBuyer));
        }
        
        if (Fee > 0){
            owner.transfer(Fee);
        }
     
        emit SellOrderFilled(msg.sender, target, amount_buyable,  price, Left);
    }


    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event SellOrderPlaced(address who, uint256 available, uint256 price);
    event SellOrderFilled(address buyer, address seller, uint256 tokens, uint256 price, uint256 payment);
    event SellOrderCancelled(address who);
    event WithdrawalComplete(address who, uint256 got);
    
    
    // thanks for divs 
    function() public payable{
        
    }
    
    // safemath 
    
      function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return a / b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}