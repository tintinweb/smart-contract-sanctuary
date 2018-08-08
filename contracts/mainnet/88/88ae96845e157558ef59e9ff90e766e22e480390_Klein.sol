//      IKB TOKEN
//      By Mitchell F. Chan


/*
OVERVIEW:
    This contract manages the purchase and transferral of Digital Zones of Immaterial Pictorial Sensibility.
    It reproduces the rules originally created by Yves Klein which governed the transferral of his original Zones of Immaterial Pictorial Sensibility.

    The project is described in full in the Blue Paper included in this repository.
*/

pragma solidity ^0.4.15;

// interface for ERC20 standard token
contract ERC20 {
    function totalSupply() constant returns (uint256 currentSupply);
    function balanceOf(address _owner) public constant returns (uint256 balance);
    function transfer(address _to, uint256 _value) returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);
    function approve(address _spender, uint256 _value) returns (bool success);
    function allowance(address _owner, address _spender) constant returns (uint256 remaining);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

//  token boilerplate
contract owned {
    address public owner;

    function owned() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner {
        owner = newOwner;
    }
}

// library for math to prevent underflows and overflows
contract SafeMath {

  function safeAdd(uint256 x, uint256 y) internal returns(uint256) {
      uint256 z = x + y;
      assert((z >= x) && (z >= y));
      return z;
  }

  function safeSubtract(uint256 x, uint256 y) internal returns(uint256) {
      assert(x >= y);
      uint256 z = x - y;
      return z;
  }

  function safeMult(uint256 x, uint256 y) internal returns(uint256) {
      uint256 z = x * y;
      assert((x == 0) || (z / x == y));
      return z;
  }
}

contract Klein is ERC20, owned, SafeMath {
    
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    mapping (address => mapping (address => mapping (uint256 => bool))) specificAllowed;
    
                                                                    // The Swarm address of the artwork is saved here for reference and posterity
    string public constant zonesSwarmAddress = "0a52f265d8d60a89de41a65069fa472ac3b130c269b4788811220b6546784920";
    address public constant theRiver = 0x8aDE9bCdA847852DE70badA69BBc9358C1c7B747;                      // ROPSTEN REVIVAL address
    string public constant name = "Digital Zone of Immaterial Pictorial Sensibility";
    string public constant symbol = "IKB";
    uint256 public constant decimals = 0;
    uint256 public maxSupplyPossible;
    uint256 public initialPrice = 10**17;                              // should equal 0.1 ETH
    uint256 public currentSeries;    
    uint256 public issuedToDate;
    uint256 public totalSold;
    uint256 public burnedToDate;
    bool first = true;
                                                                    // IKB are issued in tranches, or series of editions. There will be 8 total
                                                                    // Each IBKSeries represents one of Klein&#39;s receipt books, or a series of issued tokens.
    struct IKBSeries {
        uint256 price;
        uint256 seriesSupply;
    }

    IKBSeries[8] public series;                                     // An array of all 8 series

    struct record {
        address addr;
        uint256 price;
        bool burned;
    }

    record[101] public records;                                     // An array of all 101 records
    
    event UpdateRecord(uint indexed IKBedition, address holderAddress, uint256 price, bool burned);
    event SeriesCreated(uint indexed seriesNum);
    event SpecificApproval(address indexed owner, address indexed spender, uint256 indexed edition);
    
    function Klein() {
        currentSeries = 0;
        series[0] = IKBSeries(initialPrice, 31);                    // the first series has unique values...
    
        for(uint256 i = 1; i < series.length; i++){                    // ...while the next 7 can be defined in a for loop
            series[i] = IKBSeries(series[i-1].price*2, 10);
        }     
        
        maxSupplyPossible = 101;
    }
    
    function() payable {
        buy();
    }

    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }
    
    function specificApprove(address _spender, uint256 _edition) returns (bool success) {
        specificAllowed[msg.sender][_spender][_edition] = true;
        SpecificApproval(msg.sender, _spender, _edition);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }

    // NEW: I thought it was more in keeping with what totalSupply() is supposed to be about to return how many tokens are currently in circulation
    function totalSupply() constant returns (uint _currentSupply) {
      return (issuedToDate - burnedToDate);
    }

    function issueNewSeries() onlyOwner returns (bool success){
        require(balances[this] <= 0);                            //can only issue a new series if you&#39;ve sold all the old ones
        require(currentSeries < 7);
        
        if(!first){
            currentSeries++;                                        // the first time we run this function, don&#39;t run up the currentSeries counter. Keep it at 0
        } else if (first){
            first=false;                                            // ...but only let this work once.
        } 
         
        balances[this] = safeAdd(balances[this], series[currentSeries].seriesSupply);
        issuedToDate = safeAdd(issuedToDate, series[currentSeries].seriesSupply);
        SeriesCreated(currentSeries);
        return true;
    }
    
    function buy() payable returns (bool success){
        require(balances[this] > 0);
        require(msg.value >= series[currentSeries].price);
        uint256 amount = msg.value / series[currentSeries].price;      // calculates the number of tokens the sender will buy
        uint256 receivable = msg.value;
        if (balances[this] < amount) {                              // this section handles what happens if someone tries to buy more than the currently available supply
            receivable = safeMult(balances[this], series[currentSeries].price);
            uint256 returnable = safeSubtract(msg.value, receivable);
            amount = balances[this];
            msg.sender.transfer(returnable);             
        }
        
        if (receivable % series[currentSeries].price > 0) assert(returnChange(receivable));
        
        balances[msg.sender] = safeAdd(balances[msg.sender], amount);                             // adds the amount to buyer&#39;s balance
        balances[this] = safeSubtract(balances[this], amount);      // subtracts amount from seller&#39;s balance
        Transfer(this, msg.sender, amount);                         // execute an event reflecting the change

        for(uint k = 0; k < amount; k++){                           // now let&#39;s make a record of every sale
            records[totalSold] = record(msg.sender, series[currentSeries].price, false);
            totalSold++;
        }
        
        return true;                                   // ends function and returns
    }

    function returnChange(uint256 _receivable) internal returns (bool success){
        uint256 change = _receivable % series[currentSeries].price;
        msg.sender.transfer(change);
        return true;
    }
                                                                    // when this function is called, the caller is transferring any number of tokens. The function automatically chooses the tokens with the LOWEST index to transfer.
    function transfer(address _to, uint _value) returns (bool success) {
        require(balances[msg.sender] >= _value);
        require(_value > 0); 
        uint256 recordsChanged = 0;

        for(uint k = 0; k < records.length; k++){                 // go through every record
            if(records[k].addr == msg.sender && recordsChanged < _value) {
                records[k].addr = _to;                            // change the address associated with this record
                recordsChanged++;                                 // keep track of how many records you&#39;ve changed in this transfer. After you&#39;ve changed as many records as there are tokens being transferred, conditions of this loop will cease to be true.
                UpdateRecord(k, _to, records[k].price, records[k].burned);
            }
        }

        balances[msg.sender] = safeSubtract(balances[msg.sender], _value);
        balances[_to] = safeAdd(balances[_to], _value);
        Transfer(msg.sender, _to, _value);
        return true;
    }
    
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        require(balances[_from] >= _value); 
        require(allowed[_from][msg.sender] >= _value); 
        require(_value > 0);
        uint256 recordsChanged = 0;
        
        for(uint256 k = 0; k < records.length; k++){                 // go through every record
            if(records[k].addr == _from && recordsChanged < _value) {
                records[k].addr = _to;                            // change the address associated with this record
                recordsChanged++;                                 // keep track of how many records you&#39;ve changed in this transfer. After you&#39;ve changed as many records as there are tokens being transferred, conditions of this loop will cease to be true.
                UpdateRecord(k, _to, records[k].price, records[k].burned);
            }
        }
        
        balances[_from] = safeSubtract(balances[_from], _value);
        allowed[_from][msg.sender] = safeSubtract(allowed[_from][msg.sender], _value);
        balances[_to] = safeAdd(balances[_to], _value); 
        Transfer(_from, _to, _value);
        return true;     
    }   
                                                                    // when this function is called, the caller is transferring only 1 IKB to another account, and specifying exactly which token they would like to transfer.
    function specificTransfer(address _to, uint _edition) returns (bool success) {
        require(balances[msg.sender] > 0);
        require(records[_edition].addr == msg.sender); 
        balances[msg.sender] = safeSubtract(balances[msg.sender], 1);
        balances[_to] = safeAdd(balances[_to], 1);
        records[_edition].addr = _to;                           // update the records so that the record shows this person owns the 
        
        Transfer(msg.sender, _to, 1);
        UpdateRecord(_edition, _to, records[_edition].price, records[_edition].burned);
        return true;
    }
    
    function specificTransferFrom(address _from, address _to, uint _edition) returns (bool success){
        require(balances[_from] > 0);
        require(records[_edition].addr == _from);
        require(specificAllowed[_from][msg.sender][_edition]);
        balances[_from] = safeSubtract(balances[_from], 1);
        balances[_to] = safeAdd(balances[_to], 1);
        specificAllowed[_from][msg.sender][_edition] = false;
        records[_edition].addr = _to;                           // update the records so that the record shows this person owns the 
        
        Transfer(msg.sender, _to, 1);
        UpdateRecord(_edition, _to, records[_edition].price, records[_edition].burned);
        return true;
    }
                                                                    // a quick way to figure out who holds a specific token without querying the whole record. This might actually be redundant.
    function getTokenHolder(uint searchedRecord) public constant returns(address){
        return records[searchedRecord].addr;
    }
    
    function getHolderEditions(address _holder) public constant returns (uint256[] _editions) {
        uint256[] memory editionsOwned = new uint256[](balances[_holder]);
        uint256 index;
        for(uint256 k = 0; k < records.length; k++) {
            if(records[k].addr == _holder) {
                editionsOwned[index] = k;
                index++;
            }
        }
        return editionsOwned;
    }
                                                                    // allows the artist to withdraw ether from the contract
    function redeemEther() onlyOwner returns (bool success) {
        owner.transfer(this.balance);  
        return true;
    }
                                                                    // allows the artist to put ether back in the contract so that holders can execute the ritual function
    function fund() payable onlyOwner returns (bool success) {
        return true;
    }
    
    function ritual(uint256 _edition) returns (bool success){
        require(records[_edition].addr == msg.sender); 
        require(!records[_edition].burned);
        uint256 halfTheGold = records[_edition].price / 2;
        require(this.balance >= halfTheGold);
        
        records[_edition].addr = 0xdead;
        records[_edition].burned = true;
        burnedToDate++;
        balances[msg.sender] = safeSubtract(balances[msg.sender], 1);
        theRiver.transfer(halfTheGold);                             // call should fail if this contract isn&#39;t holding enough ETH
        return true;
    }
}