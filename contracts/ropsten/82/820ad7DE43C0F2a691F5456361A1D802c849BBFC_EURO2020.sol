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
    uint256 constant private MAX_AVALIABLE = 10;
    uint256 constant private NUM_TEAMS = 16;
    uint256 public time_start_playoff;
    uint256 public time_end_tournament;
    address private owner;
    mapping (string => uint256) private TEAM_MAP;
    mapping (uint8 => uint256) private LEVELS;
    mapping (string => uint256) private PAYBACK;
    
    uint public last_offer_id;
    uint256 constant private our_fee = 0.005 ether;
    bool locked;
    mapping (uint => OfferInfo) private offers_map;
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
        TEAM_MAP['WAL'] = MAX_AVALIABLE;
        TEAM_MAP['SWI'] = MAX_AVALIABLE;
        TEAM_MAP['BEL'] = MAX_AVALIABLE;
        TEAM_MAP['DEN'] = MAX_AVALIABLE;
        TEAM_MAP['NED'] = MAX_AVALIABLE;
        TEAM_MAP['AUS'] = MAX_AVALIABLE;
        TEAM_MAP['UKR'] = MAX_AVALIABLE;
        TEAM_MAP['CRO'] = MAX_AVALIABLE;
        TEAM_MAP['RCZ'] = MAX_AVALIABLE;
        TEAM_MAP['SWE'] = MAX_AVALIABLE;
        TEAM_MAP['SPA'] = MAX_AVALIABLE;
        TEAM_MAP['POR'] = MAX_AVALIABLE;
        TEAM_MAP['FRA'] = MAX_AVALIABLE;
        TEAM_MAP['GER'] = MAX_AVALIABLE;
        TEAM_MAP['ENG'] = MAX_AVALIABLE;
        
        LEVELS[0] = 1;
        LEVELS[1] = 2;
        LEVELS[2] = 4;
        LEVELS[3] = 16;
        LEVELS[4] = 50;
        
        time_end_tournament =  now + 18 days; 
        time_start_playoff = now + 3 days;
        owner = msg.sender;
        balances[owner] = totalSupply;
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
    function place_bet(string _team, uint256 _amount) public payable returns (bool success) {
        require(now <= time_start_playoff);
        require(msg.value >= _amount * PRICE_PER_UNIT);
        require(TEAM_MAP[_team] >= _amount);
        TEAM_MAP[_team] -= _amount;
        bets[msg.sender][_team] += _amount;
        balances[msg.sender] += _amount;
        balances[owner] -= _amount;
        return true;
    }
    
    function collect_dust() public returns(bool success) {
        // instead of checking if the owner has totalSupply number of coins, it is possible to put a time condition
        require(msg.sender == owner);
        require(balances[msg.sender] == totalSupply);
        owner.transfer(address(this).balance);
        return true;
    }
    
    function oracle(string _team, uint8 _level) public returns (bool success) {
        require(msg.sender == owner);
        if (TEAM_MAP[_team] == MAX_AVALIABLE){
            PAYBACK[_team] = 0;
        } else {
            PAYBACK[_team] = (address(this).balance * LEVELS[_level] / 100) / (MAX_AVALIABLE - TEAM_MAP[_team]);
        }
        return true;
    }
    
    function collect_bet(string _team) public returns (bool success) {
        //require(now >= time_end_tournament );
        require(bets[msg.sender][_team] >= 1);
        uint256 amount = bets[msg.sender][_team];
        bets[msg.sender][_team] = 0 ;
        balances[owner] += amount;
        balances[msg.sender] -= amount;
        msg.sender.transfer(PAYBACK[_team] * amount);
        return true;
        
    }
    
    
    
    /*
    * DEX FUNCTIONs
    */
    modifier can_buy(uint id) {
        require(offer_isActive(id));
        _;
    }

    modifier can_cancel(uint id) {
        require(offer_isActive(id));
        require(offer_getOwner(id) == msg.sender);
        _;
    }
    modifier synchronized {
        require(!locked);
        locked = true;
        _;
        locked = false;
    }
    
    function offer_isActive(uint id) public view returns (bool active) {
        return offers_map[id].timestamp > 0;
    }
    function offer_getOwner(uint id) public view returns (address own) {
        return offers_map[id].owner;
    }
    
    function getOfferInfo(uint id) public view returns (string, uint256, uint256) {
      OfferInfo memory offer = offers_map[id];
      return (offer.pair, offer.price, offer.amount);
    }
    
    function _next_id() internal returns (uint) {
        last_offer_id++;
        return last_offer_id;
    }
    
    function buy(uint256 id, uint8 quantity) public payable can_buy(id) synchronized returns (bool) {
        
        OfferInfo memory offer = offers_map[id];
        uint256 to_spend = quantity * offer.price;
        require(bets[offer.owner][offer.pair] >= quantity);
        require(to_spend <= address(this).balance);
        require(to_spend <= msg.value);
        require(quantity > 0);
        require(to_spend > 0);
        require(offer.amount >= quantity);

        bets[offer.owner][offer.pair] -= quantity;
        bets[msg.sender][offer.pair] += quantity;
        balances[offer.owner] -= quantity;
        balances[msg.sender] += quantity;
        offers_map[id].amount -= quantity;
        address(offer.owner).transfer(to_spend - our_fee * quantity);
        
        if (offers_map[id].amount == 0) {
          delete offers_map[id];
        }

        return true;
    }
    
    // Cancel an offer. Refunds offer maker.
    function cancel_offer(uint id) public can_cancel(id) synchronized returns (bool success) {
        // read-only offer. Modify an offer by directly accessing offers[id]
        delete offers_map[id];
        return true;
    }

    // Make a new offer. Takes funds from the caller into market escrow.
    function sell(string pair, uint256 price, uint256 amount) public synchronized returns (uint256 id) {
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
        offers_map[id] = info;

        return id;
    }
    
    function getNumberTokensOnTeam(address _address, string _team) public view returns (uint256){
        return bets[_address][_team];
    }
    
    function getTeamNames() public pure returns (string){
        return "Teams: ENG, ITA, FRA, GER, WAL, SWI, BEL, DEN, NED, AUS, UKR, CRO, RCZ, SWE, SPA, HUN";
    }
    
    function getAvailableTokensOnTeam(string _team) public view returns (uint256){
        return TEAM_MAP[_team];
    }
    
    /*function getPayback(string _team) public view returns (uint256){
        return PAYBACK[_team];
    }*/
    
    /*function getTeamMap(string _team) public view returns (uint256){
        return TEAM_MAP[_team];
    }*/
    
    function getPricePerUnit() public pure returns (uint256){
        return PRICE_PER_UNIT;
    }
    
}