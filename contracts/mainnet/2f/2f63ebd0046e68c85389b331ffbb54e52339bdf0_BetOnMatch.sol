pragma solidity ^0.4.21;


/// @title A base contract to control ownership
/// @author cuilichen
contract OwnerBase {

    // The addresses of the accounts that can execute actions within each roles.
    address public ceoAddress;
    address public cfoAddress;
    address public cooAddress;

    // @dev Keeps track whether the contract is paused. When that is true, most actions are blocked
    bool public paused = false;
    
    /// constructor
    function OwnerBase() public {
       ceoAddress = msg.sender;
       cfoAddress = msg.sender;
       cooAddress = msg.sender;
    }

    /// @dev Access modifier for CEO-only functionality
    modifier onlyCEO() {
        require(msg.sender == ceoAddress);
        _;
    }

    /// @dev Access modifier for CFO-only functionality
    modifier onlyCFO() {
        require(msg.sender == cfoAddress);
        _;
    }
    
    /// @dev Access modifier for COO-only functionality
    modifier onlyCOO() {
        require(msg.sender == cooAddress);
        _;
    }

    /// @dev Assigns a new address to act as the CEO. Only available to the current CEO.
    /// @param _newCEO The address of the new CEO
    function setCEO(address _newCEO) external onlyCEO {
        require(_newCEO != address(0));

        ceoAddress = _newCEO;
    }


    /// @dev Assigns a new address to act as the COO. Only available to the current CEO.
    /// @param _newCFO The address of the new COO
    function setCFO(address _newCFO) external onlyCEO {
        require(_newCFO != address(0));

        cfoAddress = _newCFO;
    }
    
    /// @dev Assigns a new address to act as the COO. Only available to the current CEO.
    /// @param _newCOO The address of the new COO
    function setCOO(address _newCOO) external onlyCEO {
        require(_newCOO != address(0));

        cooAddress = _newCOO;
    }

    /// @dev Modifier to allow actions only when the contract IS NOT paused
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    /// @dev Modifier to allow actions only when the contract IS paused
    modifier whenPaused {
        require(paused);
        _;
    }

    /// @dev Called by any "C-level" role to pause the contract. Used only when
    ///  a bug or exploit is detected and we need to limit damage.
    function pause() external onlyCOO whenNotPaused {
        paused = true;
    }

    /// @dev Unpauses the smart contract. Can only be called by the CEO, since
    ///  one reason we may pause the contract is when CFO or COO accounts are
    ///  compromised.
    /// @notice This is public rather than external so it can be called by
    ///  derived contracts.
    function unpause() public onlyCOO whenPaused {
        // can&#39;t unpause if contract was upgraded
        paused = false;
    }
    
    
    /// @dev check wether target address is a contract or not
    function isNormalUser(address addr) internal view returns (bool) {
        if (addr == address(0)) {
            return false;
        }
        uint size = 0;
        assembly { 
            size := extcodesize(addr) 
        } 
        return size == 0;
    }
}



/// @title Base contract for Chaotic. Holds all common structs, events and base variables.
/// @author cuilichen
contract BaseFight is OwnerBase {

    event FighterReady(uint32 season);
    
    // data of fighter
    struct Fighter {
        uint tokenID;
        address hometown;
        address owner;
        uint16 power;
    }
    
    
    mapping (uint => Fighter) public soldiers; // key is (season * 1000 + index)
    
    // time for matches
    mapping (uint32 => uint64 ) public matchTime;// key is season
    
    
    mapping (uint32 => uint64 ) public seedFromCOO; // key is season
    
    
    mapping (uint32 => uint8 ) public finished; // key is season
    
    //
    uint32[] seasonIDs;
    
    
    
    /// @dev get base infomation of the seasons
    function getSeasonInfo(uint32[99] _seasons) view public returns (uint length,uint[99] matchTimes, uint[99] results) {
        for (uint i = 0; i < _seasons.length; i++) {    
            uint32 _season = _seasons[i];
            if(_season >0){
                matchTimes[i] = matchTime[_season];
                results[i] = finished[_season];
            }else{
                length = i;
                break;
            }
        }
    }
    
    
    
    
    /// @dev check seed form coo
    function checkCooSeed(uint32 _season) public view returns (uint64) {
        require(finished[_season] > 0);
        return seedFromCOO[_season];
    }

    
    /// @dev set a fighter for a season, prepare for combat.
    function createSeason(uint32 _season, uint64 fightTime, uint64 _seedFromCOO, address[8] _home, uint[8] _tokenID, uint16[8] _power, address[8] _owner) external onlyCOO {
        require(matchTime[_season] <= 0);
        require(fightTime > 0);
        require(_seedFromCOO > 0);
        seasonIDs.push(_season);// a new season
        matchTime[_season] = fightTime;
        seedFromCOO[_season] = _seedFromCOO;
        
        for (uint i = 0; i < 8; i++) {        
            Fighter memory soldier = Fighter({
                hometown:_home[i],
                owner:_owner[i],
                tokenID:_tokenID[i],
                power: _power[i]
            });
                
            uint key = _season * 1000 + i;
            soldiers[key] = soldier;
            
        }
        
        //fire the event
        emit FighterReady(_season);
    }
    
    
    
    /// @dev process a fight
    function _localFight(uint32 _season, uint32 _seed) internal returns (uint8 winner)
    {
        require(finished[_season] == 0);//make sure a season just match once.
        
        uint[] memory powers = new uint[](8);
        
        uint sumPower = 0;
        uint8 i = 0;
        uint key = 0;
        Fighter storage soldier = soldiers[0];
        for (i = 0; i < 8; i++) {
            key = _season * 1000 + i;
            soldier = soldiers[key];
            powers[i] = soldier.power;
            sumPower = sumPower + soldier.power;
        }
        
        uint sumValue = 0;
        uint tmpPower = 0;
        for (i = 0; i < 8; i++) {
            tmpPower = powers[i] ** 5;//
            sumValue += tmpPower;
            powers[i] = sumValue;
        }
        uint singleDeno = sumPower ** 5;
        uint randomVal = _getRandom(_seed);
        
        winner = 0;
        uint shoot = sumValue * randomVal * 10000000000 / singleDeno / 0xffffffff;
        for (i = 0; i < 8; i++) {
            tmpPower = powers[i];
            if (shoot <= tmpPower * 10000000000 / singleDeno) {
                winner = i;
                break;
            }
        }
        
        finished[_season] = uint8(100 + winner);
        return winner;
    }
    
    
    /// @dev give a seed and get a random value between 0 and 0xffffffff.
    /// @param _seed an uint32 value from users
    function _getRandom(uint32 _seed) pure internal returns(uint32) {
        return uint32(keccak256(_seed));
    }
}



/**
 * Math operations with safety checks
 */
contract SafeMath {
    function safeMul(uint a, uint b) internal pure returns (uint) {
        uint c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function safeDiv(uint a, uint b) internal pure returns (uint) {
        assert(b > 0);
        uint c = a / b;
        assert(a == b * c + a % b);
        return c;
    }

    function safeSub(uint a, uint b) internal pure returns (uint) {
        assert(b <= a);
        return a - b;
    }

    function safeAdd(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        assert(c>=a && c>=b);
        return c;
    }

    function max64(uint64 a, uint64 b) internal pure returns (uint64) {
        return a >= b ? a : b;
    }

    function min64(uint64 a, uint64 b) internal pure returns (uint64) {
        return a < b ? a : b;
    }

    function max256(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    function min256(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
 
}


 

/**
 * 
 * @title Interface of contract for partner
 * @author cuilichen
 */
contract PartnerHolder {
    //
    function isHolder() public pure returns (bool);
    
    // Required methods
    function bonusAll() payable public ;
    
    
    function bonusOne(uint id) payable public ;
    
}



contract BetOnMatch is BaseFight, SafeMath {

    event Betted( uint32 indexed season, uint32 indexed index, address indexed account, uint amount);
    event SeasonNone( uint32 season);
    event SeasonWinner( uint32 indexed season, uint winnerID);
    event LogFighter( uint32 indexed season, address indexed fighterOwner, uint fighterKey, uint fund, address fighterContract, uint fighterTokenID, uint power, uint8 isWin,uint reward, uint64 fightTime);
    event LogMatch( uint32 indexed season, uint sumFund, uint64 fightTime, uint sumSeed, uint fighterKey, address fighterContract, uint fighterTokenID ,bool isRefound);
    event LogBet( uint32 indexed season, address indexed sender, uint fund, uint seed, uint fighterKey, address fighterContract, uint fighterTokenID );
    
    struct Betting {
        // user 
        address account;
        
        uint32 season;
        
        uint32 index;
        
        address invitor;
        
        uint seed;
        //
        uint amount;
    }
    
    // contract of partners
    PartnerHolder public partners;
    
    // all betting data
    mapping (uint => Betting[]) public allBittings; // key is season * 1000 + index
    
    // bet on the fighter,
    mapping (uint => uint) public betOnFighter; // key is season * 1000 + index
    
    // address to balance.
    mapping( address => uint) public balances;
    
    
    /// @dev constructor of contract, set partners
    function BetOnMatch(address _partners) public {
        ceoAddress = msg.sender;
        cooAddress = msg.sender;
        cfoAddress = msg.sender;
        
        partners = PartnerHolder(_partners);
    }
        
    
    
    /// @dev bet to the match
    function betOn(
        uint32 _season, 
        uint32 _index, 
        uint _seed, 
        address _invitor) 
    payable external returns (bool){
        require(isNormalUser(msg.sender));
        require(matchTime[_season] > 0);
        require(now < matchTime[_season] - 300); // 5 minites before match.
        require(msg.value >= 1 finney && msg.value < 99999 ether );
        
        
        Betting memory tmp = Betting({
            account:msg.sender,
            season:_season,
            index:_index,
            seed:_seed,
            invitor:_invitor,
            amount:msg.value
        });
        
        
        uint key = _season * 1000 + _index;
        betOnFighter[key] = safeAdd(betOnFighter[key], msg.value);
        Betting[] storage items = allBittings[key];
        items.push(tmp);
        
        Fighter storage soldier = soldiers[key];
        
        emit Betted( _season, _index, msg.sender, msg.value);
        emit LogBet( _season, msg.sender, msg.value, _seed, key, soldier.hometown, soldier.tokenID );
    }
    
    
    /// @dev set a fighter for a season, prepare for combat.
    function getFighters( uint32 _season) public view returns (address[8] outHome, uint[8] outTokenID, uint[8] power,  address[8] owner, uint[8] funds) {
        for (uint i = 0; i < 8; i++) {  
            uint key = _season * 1000 + i;
            funds[i] = betOnFighter[key];
            
            Fighter storage soldier = soldiers[key];
            outHome[i] = soldier.hometown;
            outTokenID[i] = soldier.tokenID;
            power[i] = soldier.power;
            owner[i] = soldier.owner;
        }
    }
    
    
    
    /// @notice process a combat, it is expencive, so provide enough gas
    function processSeason(uint32 _season) public onlyCOO
    {
        uint64 fightTime = matchTime[_season];
        require(now >= fightTime && fightTime > 0);
        
        uint sumFund = 0;
        uint sumSeed = 0;
        (sumFund, sumSeed) = _getFightData(_season);
        if (sumFund == 0) {
            finished[_season] = 110;
            doLogFighter(_season,0,0);
            emit SeasonNone(_season);
            emit LogMatch( _season, sumFund, fightTime, sumSeed, 0, 0, 0, false );
        } else {
            uint8 champion = _localFight(_season, uint32(sumSeed));
        
            uint percentile = safeDiv(sumFund, 100);
            uint devCut = percentile * 4; // for developer
            uint partnerCut = percentile * 5; // for partners
            uint fighterCut = percentile * 1; // for fighters
            uint bonusWinner = percentile * 80; // for winner
            // for salesman percentile * 10
            
            _bonusToPartners(partnerCut);
            _bonusToFighters(_season, champion, fighterCut);
            bool isRefound = _bonusToBettor(_season, champion, bonusWinner);
            _addMoney(cfoAddress, devCut);
            
            uint key = _season * 1000 + champion;
            Fighter storage soldier = soldiers[key];
            doLogFighter(_season,key,fighterCut);
            emit SeasonWinner(_season, champion);        
            emit LogMatch( _season, sumFund, fightTime, sumSeed, key, soldier.hometown, soldier.tokenID, isRefound );
        }
        clearTheSeason(_season);
    }
    
    
    
    function clearTheSeason( uint32 _season) internal {
        for (uint i = 0; i < 8; i++){
            uint key = _season * 1000 + i;
            delete soldiers[key];
            delete allBittings[key];
        }
    }
    
    
    
    /// @dev write log about 8 fighters
    function doLogFighter( uint32 _season, uint _winnerKey, uint fighterReward) internal {
        for (uint i = 0; i < 8; i++){
            uint key = _season * 1000 + i;
            uint8 isWin = 0;
            uint64 fightTime = matchTime[_season];
            uint winMoney = safeDiv(fighterReward, 10);
            if(key == _winnerKey){
                isWin = 1;
                winMoney = safeMul(winMoney, 3);
            }
            Fighter storage soldier = soldiers[key];
            emit LogFighter( _season, soldier.owner, key, betOnFighter[key], soldier.hometown, soldier.tokenID, soldier.power, isWin,winMoney,fightTime);
        }
    }
    
    
    
    /// @dev caculate fund and seed value
    function _getFightData(uint32 _season) internal returns (uint outFund, uint outSeed){
        outSeed = seedFromCOO[_season];
        for (uint i = 0; i < 8; i++){
            uint key = _season * 1000 + i;
            uint fund = 0;
            Betting[] storage items = allBittings[key]; 
            for (uint j = 0; j < items.length; j++) {
                Betting storage item = items[j];
                outSeed += item.seed;
                fund += item.amount;
                
                uint forSaler = safeDiv(item.amount, 10); // 0.1 for salesman
                if (item.invitor == address(0)){
                    _addMoney(cfoAddress, forSaler);
                } else {
                    _addMoney(item.invitor, forSaler);
                }
            }
            outFund += fund;
        }
    }
    
    /// @dev add fund to the address.
    function _addMoney( address user, uint val) internal {
        uint oldValue = balances[user];
        balances[user] = safeAdd(oldValue, val);
    }
    
    
    
    
    /// @dev bonus to partners.
    function _bonusToPartners(uint _amount) internal {
        if (partners == address(0)) {
            _addMoney(cfoAddress, _amount);
        } else {
            partners.bonusAll.value(_amount)();
        }
    }
    
    
    /// @dev bonus to the fighters in the season.
    function _bonusToFighters(uint32 _season, uint8 _winner, uint _reward) internal {
        for (uint i = 0; i < 8; i++) {
            uint key = _season * 1000 + i;
            Fighter storage item = soldiers[key];
            address owner = item.owner;
            uint fund = safeDiv(_reward, 10);
            if (i == _winner) {
                fund = safeMul(fund, 3);
            }
            if (owner == address(0)) {
                _addMoney(cfoAddress, fund);
            } else {
                _addMoney(owner, fund);
            }
        }
    }
    
    
    /// @dev bonus to bettors who won.
    function _bonusToBettor(uint32 _season, uint8 _winner, uint bonusWinner) internal returns (bool) {
        uint winnerBet = _getWinnerBetted(_season, _winner);
        uint key = _season * 1000 + _winner;
        Betting[] storage items = allBittings[key];
        if (items.length == 0) {
            backToAll(_season);
            return true;
        } else {
            for (uint j = 0; j < items.length; j++) {
                Betting storage item = items[j];
                address account = item.account;
                uint newFund = safeDiv(safeMul(bonusWinner, item.amount), winnerBet); 
                _addMoney(account, newFund);
            }
            return false;
        }
    }
    
    /// @dev nobody win, return fund back to all bettors.
    function backToAll(uint32 _season) internal {
        for (uint i = 0; i < 8; i++) {
            uint key = _season * 1000 + i;
            Betting[] storage items = allBittings[key];
            for (uint j = 0; j < items.length; j++) {
                Betting storage item = items[j];
                address account = item.account;
                uint backVal = safeDiv(safeMul(item.amount, 8), 10); // amount * 0.8
                _addMoney(account, backVal);
            }
        }
    }
    
    
    
    /// @dev caculate total amount betted on winner
    function _getWinnerBetted(uint32 _season, uint32 _winner) internal view returns (uint){
        uint sum = 0;
        uint key = _season * 1000 + _winner;
        Betting[] storage items = allBittings[key];
        for (uint j = 0; j < items.length; j++) {
            Betting storage item = items[j];
            sum += item.amount;
        }
        return sum;
    }
    
    
    
    /// @dev partner withdraw, 
    function userWithdraw() public {
        uint fund = balances[msg.sender];
        require (fund > 0);
        delete balances[msg.sender];
        msg.sender.transfer(fund);
    }
    
    
    /// @dev cfo withdraw dead ether. 
    function withdrawDeadFund( address addr) external onlyCFO {
        uint fund = balances[addr];
        require (fund > 0);
        delete balances[addr];
        cfoAddress.transfer(fund);
    }

}