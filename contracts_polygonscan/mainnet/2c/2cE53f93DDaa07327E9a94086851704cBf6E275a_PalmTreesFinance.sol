/**
 *Submitted for verification at polygonscan.com on 2022-01-13
*/

/*
                                     ```....................```                                     
                               ```..```                      ``...```                               
                           ``..``                                  ``..``                           
                        `..``                                          ``..`                        
                     `.``                                                  `..`                     
                  `..`                                              ```       `..`                  
                `.``                                            `.-::/:         `..`                
              `.`                     ````                   `-://////-           `..`              
            `.`                  `.:+oossoo/-`             .:///////:-               ..`            
           ..`                 .+syhhhyhhyyyys:`         `:////////-.`                `..           
         `.`                 -sddddhyhhhyyyyyhhs-       -///////////`                   `.`         
        `.                  +dhso/:--oysyyyhyyyyy:    `:///////////-                     `.`        
       ..                   -`        `/+shhyyyyhy:  `:///////////.                        ..       
      .`                                +yyyyyyyhyy- :////////:-.                           ..      
     -`                   ``..-----...`` `/syhyyhyhs://///////:-`                            ..     
    .`               `.-:////////////////::osyhyyyhs/////////:.  ````....``                   ..    
   ..             `.:////////////////////////++osyy+////////-.-::///////////::-.`              .`   
  `:::::::::::::-:///////////////////////////////++//////////////////////////////:-:::::::::::::-`  
  -///////////////////////////////////+++oossssyy+///////////////////://////////////////////////:.  
 `://////////////://:////:////////++syyyyyyhhyyhy+/////+ooooooooo+////:/:////////////////////////:` 
 -///////////////://:///////://+ssyhhhyhhhyyyyhhy///////+sssshhhhyo+////:////////////////////////:. 
`:///////////////////////////oyyyyyyyyhhyhhyyyhhy////////+osshhhhhhyo//////////////://////////////-`
.://///////////////////////oyhyhyyhyyoyhssyssyyys////////++oshhhhyhhhs+///////////////////////////:`
-/////////////////////////shhhsyhyyyyo+sssyyyssss///////++//ohhhhhyhyyy+//////////////////::://///:.
:////////////////////////yhyyys+yso+///+shhysssss+++////////oo+osyyyyhyy//////////////////////////:-
:///////////////////////shhyy+s////////////+sssss+/+/////////////+oohyyhs//////////////////////////-
://////////////////////+yhyso///////////////ssssys+////////////////+shyyh+/////////////////////////-
-//////////////////////sso//////////////////osyhhho////////////////////hhy////////////////////////:-
.//////////////////////+///////////////////ssoss++/////////////////////oyh+///////////////////////:.
.:////////////////////////////////////////+ooss+////////////////////////+ys///////////////////////:`
`:///////////////////////////////////////+oooss//////////////////////////+s///////////////////////-`
 -/+/////////////////////////////////////oooss+///////////////////////////+//////////////////////:. 
 `:+++//////////////////+/////+/////+///ooooss/+///++////////////+/+////+++/////////++++//////++/-` 
  -/++++++++++++++++++++++++++++++++++++ooosso/++++++++//:///////+++++++++++++++++++++++//++++++:.  
  `:++++++++++++++++++++++++++++++++++/ooosss++++++++++++////////++++++++++++++++++++++++++++++/-`  
   .://::::::::::::::::///////+++++++++ooosss++++++++++++++//////+++++++++++++++++++++++++++++/-`   
    ..`                   ````...--://+ooosso+++++++++++++++++///+++++++++++++++++++++++///:---.    
     ..```````                      `/ooossso++++++++++++++++++++++++++++++++++//::--..```  `..     
      ..````````````````````````````.oooosss/``..---:::////////////::::---..````````````````..      
       .-```````````````````````````:ossssss:``````````````````````````````````````````````..       
        `-.`````````````````````````ooosssss-````````````````````````````````````````````.-`        
         `..```````````````````````-ooosssss-```````````````````````````````````````````..`         
           .-.`````````````````````/ooosssss-`````````````````````````````````````````.-.           
            `.-.``````````````````.+ooosssss-``...```````````````.``````````````````.-.`            
              `...````````````````.oooosssss:-ossso+:..```````````````````````````...`              
                `...``````````````-oooosssss/shhhyyyyso-````````````````````````...`                
                  `.....``````````:ooossssssohhhhhhhhyyy:```````````````````.....`                  
                     `.....```````/ooossssssshhhhhhhhhhhy.```````````````.....`                     
                        `.......``:ooossssssshhhhhhhdhdhs.``````...``......`                        
                           ``.....:++oossssssoyhhhhhhdhs-.`.`.`......-..`                           
                               ``..-::/+oooss+-+syyys+:.........-..``                               
                                     ```....-----------.....```                                     
                         
*/

pragma solidity 0.4.18;

library SafeMath {
    function mul(uint256 a, uint256 b) internal constant returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal constant returns (uint256) {
        uint256 c = a / b;
        return c;
    }

    function sub(uint256 a, uint256 b) internal constant returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal constant returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

contract Ownable {
    address public owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function Ownable() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        require(newOwner != address(0));
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

contract ERC20 {
    uint256 public totalSupply;
    function balanceOf(address who) public constant returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function allowance(address owner, address spender) public constant returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract StandardToken is ERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;

    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value > 0);

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_from != address(0));
        require(_to != address(0));

        uint256 _allowance = allowed[_from][msg.sender];

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = _allowance.sub(_value);
        Transfer(_from, _to, _value);
        return true;
    }

    function balanceOf(address _owner) public constant returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
}

contract PalmTreesFinance is StandardToken, Ownable {

    string public name = "PalmTreesFinance";
    string public symbol = "PTF";
    uint public decimals = 18;

    // The token allocation
    uint public constant TOTAL_SUPPLY       = 11000000e18;
    uint public constant ALLOC_AIRDROP      = 550000e18; // 5%
    uint public constant ALLOC_LIQUIDITY    = 1650000e18; // 15%
    uint public constant ALLOC_FARM         = 2970000e18; // 27%
    uint public constant ALLOC_LOCK         = 3080000e18; // 28%
    uint public constant ALLOC_SALE         = 2750000e18; // 25%

    // wallets
    address public constant WALLET_AIRDROP      = 0x00E293D0A88043741163021E1B3452402aC361f2;
    address public constant WALLET_LIQUIDITY    = 0x0243e3Ea715399134482B0EeB73E12fAFe0A51a8;
    address public constant WALLET_FARM         = 0x1E986d0Beb6d5d33356cd409Da7bC6BCE7b547e3;
    address public constant WALLET_LOCK         = 0x9574B89837A8615F1fABBaaF47a51a9e9691A82e;
    address public constant WALLET_SALE         = 0x776DA3D636Ee156132421168d5e7d42f4d94b89d;

    // 2 groups of lockup
    mapping(address => uint256) public contributors_locked;
    mapping(address => uint256) public investors_locked;

    // 2 types of releasing
    mapping(address => uint256) public contributors_countdownDate;
    mapping(address => uint256) public investors_deliveryDate;

    // MODIFIER

    // checks if the address can transfer certain amount of tokens
    modifier canTransfer(address _sender, uint256 _value) {
        require(_sender != address(0));

        uint256 remaining = balances[_sender].sub(_value);
        uint256 totalLockAmt = 0;

        if (contributors_locked[_sender] > 0) {
            totalLockAmt = totalLockAmt.add(getLockedAmount_contributors(_sender));
        }

        if (investors_locked[_sender] > 0) {
            totalLockAmt = totalLockAmt.add(getLockedAmount_investors(_sender));
        }

        require(remaining >= totalLockAmt);

        _;
    }

    // EVENTS
    event UpdatedLockingState(string whom, address indexed to, uint256 value, uint256 date);

    // FUNCTIONS

    function PTFToken() public {
        balances[msg.sender] = TOTAL_SUPPLY;
        totalSupply = TOTAL_SUPPLY;

        // do the distribution of the token, in token transfer
        transfer(WALLET_AIRDROP, ALLOC_AIRDROP);
        transfer(WALLET_LIQUIDITY, ALLOC_LIQUIDITY);
        transfer(WALLET_FARM, ALLOC_FARM);
        transfer(WALLET_LOCK, ALLOC_LOCK);
        transfer(WALLET_SALE, ALLOC_SALE);
    }

    // get contributors' locked amount of token
    // this lockup will be released in 8 batches which take place every 180 days
    function getLockedAmount_contributors(address _contributor)
        public
		constant
		returns (uint256)
	{
        uint256 countdownDate = contributors_countdownDate[_contributor];
        uint256 lockedAmt = contributors_locked[_contributor];

        if (now <= countdownDate + (180 * 1 days)) {return lockedAmt;}
        if (now <= countdownDate + (180 * 2 days)) {return lockedAmt.mul(7).div(8);}
        if (now <= countdownDate + (180 * 3 days)) {return lockedAmt.mul(6).div(8);}
        if (now <= countdownDate + (180 * 4 days)) {return lockedAmt.mul(5).div(8);}
        if (now <= countdownDate + (180 * 5 days)) {return lockedAmt.mul(4).div(8);}
        if (now <= countdownDate + (180 * 6 days)) {return lockedAmt.mul(3).div(8);}
        if (now <= countdownDate + (180 * 7 days)) {return lockedAmt.mul(2).div(8);}
        if (now <= countdownDate + (180 * 8 days)) {return lockedAmt.mul(1).div(8);}

        return 0;
    }

    // get investors' locked amount of token
    // this lockup will be released in 3 batches:
    // 1. on delievery date
    // 2. three months after the delivery date
    // 3. six months after the delivery date
    function getLockedAmount_investors(address _investor)
        public
		constant
		returns (uint256)
	{
        uint256 delieveryDate = investors_deliveryDate[_investor];
        uint256 lockedAmt = investors_locked[_investor];

        if (now <= delieveryDate) {return lockedAmt;}
        if (now <= delieveryDate + 90 days) {return lockedAmt.mul(2).div(3);}
        if (now <= delieveryDate + 180 days) {return lockedAmt.mul(1).div(3);}

        return 0;
    }

    // set lockup for contributors
    function setLockup_contributors(address _contributor, uint256 _value, uint256 _countdownDate)
        public
        onlyOwner
    {
        require(_contributor != address(0));

        contributors_locked[_contributor] = _value;
        contributors_countdownDate[_contributor] = _countdownDate;
        UpdatedLockingState("contributor", _contributor, _value, _countdownDate);
    }

    // set lockup for strategic investor
    function setLockup_investors(address _investor, uint256 _value, uint256 _delieveryDate)
        public
        onlyOwner
    {
        require(_investor != address(0));

        investors_locked[_investor] = _value;
        investors_deliveryDate[_investor] = _delieveryDate;
        UpdatedLockingState("investor", _investor, _value, _delieveryDate);
    }

	// Transfer amount of tokens from sender account to recipient.
    function transfer(address _to, uint _value)
        public
        canTransfer(msg.sender, _value)
		returns (bool success)
	{
        return super.transfer(_to, _value);
    }

	// Transfer amount of tokens from a specified address to a recipient.
    function transferFrom(address _from, address _to, uint _value)
        public
        canTransfer(_from, _value)
		returns (bool success)
	{
        return super.transferFrom(_from, _to, _value);
    }
}