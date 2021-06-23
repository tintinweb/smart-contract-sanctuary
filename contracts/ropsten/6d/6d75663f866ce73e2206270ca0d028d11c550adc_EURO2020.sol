/**
 *Submitted for verification at Etherscan.io on 2021-06-23
*/

/*
Implements EIP20 token standard: https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
.*/


pragma solidity ^0.4.21;


contract EURO2020 {

    uint256 constant private MAX_UINT256 = 2**256 - 1;
    
    uint256 constant private PRICE_PER_UNIT = 0.03 ether;
    uint256 constant private MAX_AVALIABLE = 1;
    uint256 constant private NUM_TEAMS = 4;
    uint256 private token_left = 4;
    uint256 public stop_selling;
    uint256 public start_release;
    address public owner;
    mapping (string => uint256) private TEAM_MAP;
    mapping (uint8 => uint256) private LEVELS;
    mapping (string => uint256) private PAYBACK;
    
    
    
    uint public last_offer_id;
    uint256 constant private our_fee = 0.005 ether;
    bool locked;
    mapping (uint => OfferInfo) public offers;
    struct OfferInfo {
        uint256  price;
        uint256  amount;
        string   pair;
        address  owner;
        uint64   timestamp;
    }

    
    
    mapping (address => uint256) public balances;
    
    mapping (address => mapping (string => uint256)) private bets;
    /*
    NOTE:
    The following variables are OPTIONAL vanities. One does not have to include them.
    They allow one to customise the token contract & in no way influences the core functionality.
    Some wallets/interfaces might not even bother to look at this information.
    */
    string public name = "Project Blockchain Polimi";                   //fancy name: eg Simon Bucks
    uint8 public decimals = 0;                //How many decimals to show.
    string public symbol = "EURO2020";                 //An identifier: eg SBX
    uint256 public totalSupply;

    constructor() public { 
        totalSupply = MAX_AVALIABLE*NUM_TEAMS;
        TEAM_MAP['ITA'] = MAX_AVALIABLE;
        TEAM_MAP['FRA'] = MAX_AVALIABLE;
        TEAM_MAP['GER'] = MAX_AVALIABLE;
        TEAM_MAP['ENG'] = MAX_AVALIABLE;
        
        
        LEVELS[0] = 5;
        LEVELS[1] = 20;
        LEVELS[2] = 60;
        
        start_release =  now + 18 days; 
        stop_selling = now + 12 days;
        owner = msg.sender;
    }
    
    /*
    * FUNCTIONs FOR ERC-20 COMPATIBILITY
    */
    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balances[msg.sender] >= _value);
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        return true;
    }
    
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }
    
    
    /*
    * BOOKMAKER FUNCTIONs
    */
    function bet(string _team, uint256 _amount) public payable returns (bool success) {
        require(now <= stop_selling);
        require(msg.value >= _amount*PRICE_PER_UNIT);
        require(TEAM_MAP[_team] >= _amount);
        TEAM_MAP[_team] -= _amount;
        bets[msg.sender][_team] += _amount;
        balances[msg.sender] += _amount;
        return true;
    }
    
    function collect_dust() public returns(bool success) {
        // instead of checking if the owner has totalSupply number of coins, it is possible to put a time condition
        require(msg.sender == owner);
        require(balances[msg.sender] == totalSupply);
        owner.transfer(address(this).balance);
        return true;
    }
    
    function update_rw_results(string _team, uint8 _level) public returns (bool success) {
        require(msg.sender == owner);
        if (TEAM_MAP[_team] == MAX_AVALIABLE){
            PAYBACK[_team] = 0;
        } else {
            PAYBACK[_team] = (LEVELS[_level] / 100) * address(this).balance / (MAX_AVALIABLE - TEAM_MAP[_team]);
        }
        return true;
    }
    
    function retrive(string _team) public returns (bool success) {
        //require(now >= start_release );
        require(bets[msg.sender][_team] >= 1);
        uint256 amount = bets[msg.sender][_team];
        uint256 paybak_total = 0;
        paybak_total = PAYBACK[_team]*amount;
        bets[msg.sender][_team] = 0 ;
        balances[owner] += amount;
        balances[msg.sender] -= amount;
        msg.sender.transfer(paybak_total);
        return true;
        
    }
    
    
    
    /*
    * DEX FUNCTIONs
    */
    modifier can_buy(uint id) {
        require(isActive(id));
        _;
    }

    modifier can_cancel(uint id) {
        require(isActive(id));
        require(getOwner(id) == msg.sender);
        _;
    }
    modifier synchronized {
        require(!locked);
        locked = true;
        _;
        locked = false;
    }
    
    function isActive(uint id) public view returns (bool active) {
        return offers[id].timestamp > 0;
    }
    function getOwner(uint id) public view returns (address own) {
        return offers[id].owner;
    }
    
    function getOffer(uint id) public view returns (string, uint256, uint256) {
      OfferInfo memory offer = offers[id];
      return (offer.pair, offer.price, offer.amount);
    }
    
    function _next_id() internal returns (uint) {
        last_offer_id++;
        return last_offer_id;
    }
    
    function buy(uint256 id, uint8 quantity) public payable can_buy(id) synchronized returns (bool) {
        
        OfferInfo memory offer = offers[id];
        uint256 to_spend = quantity * offer.price;
        require(bets[offer.owner][offer.pair] >= quantity);
        require(to_spend <= address(this).balance);

        // For backwards semantic compatibility.
        if (quantity == 0 || to_spend == 0 || quantity > offer.amount || to_spend <= msg.value) {
            return false;
        }

        
        bets[offer.owner][offer.pair] -= quantity;
        bets[msg.sender][offer.pair] += quantity;
        balances[offer.owner] -= quantity;
        balances[msg.sender] += quantity;
        offers[id].amount -= quantity;
        offer.owner.transfer(to_spend - our_fee * quantity);
        
        if (offers[id].amount == 0) {
          delete offers[id];
        }

        return true;
    }
    
    // Cancel an offer. Refunds offer maker.
    function cancel(uint id) public can_cancel(id) synchronized returns (bool success) {
        // read-only offer. Modify an offer by directly accessing offers[id]
        delete offers[id];
        return true;
    }

    // Make a new offer. Takes funds from the caller into market escrow.
    function offer(string pair, uint256 price, uint256 amount) public synchronized returns (uint256 id) {
        require(price > 0);
        require(amount > 0);
        require(bets[msg.sender][pair] >= amount);

        OfferInfo memory info;
        info.pair = pair;
        info.price = price + our_fee;
        info.amount = amount;
        info.owner = msg.sender;
        info.timestamp = uint64(now);
        id = _next_id();
        offers[id] = info;

        return id;
    }

    
}