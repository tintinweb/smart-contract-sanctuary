pragma solidity ^0.4.21;

library SafeMath {
    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
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
        // assert(b &gt; 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return c;
    }

    /**
    * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b &lt;= a);
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c &gt;= a);
        return c;
    }
}

contract ERC721 {
  // Required methods
  function approve(address _to, uint256 _tokenId) public;
  function balanceOf(address _owner) public view returns (uint256 balance);
  function implementsERC721() public pure returns (bool);
  function ownerOf(uint256 _tokenId) public view returns (address addr);
  function takeOwnership(uint256 _tokenId) public;
  function totalSupply() public view returns (uint256 total);
  function transferFrom(address _from, address _to, uint256 _tokenId) public;
  function transfer(address _to, uint256 _tokenId) public;

  event Transfer(address indexed from, address indexed to, uint256 tokenId);
  event Approval(address indexed owner, address indexed approved, uint256 tokenId);
}

contract CryptoCupToken is ERC721 {

    // evsoftware.co.uk
    // cryptocup.online

    /*****------ EVENTS -----*****/
    event TeamSold(uint256 indexed team, address indexed from, uint256 oldPrice, address indexed to, uint256 newPrice, uint256 tradingTime, uint256 balance, uint256 lastSixteenPrize, uint256 quarterFinalPrize, uint256 semiFinalPrize, uint256 winnerPrize);
    event PrizePaid(string tournamentStage, uint256 indexed team, address indexed to, uint256 prize, uint256 time);
    event Transfer(address from, address to, uint256 tokenId);

    /*****------- CONSTANTS -------******/
    uint256 private startingPrice = 0.001 ether;
	uint256 private doublePriceUntil = 0.1 ether;
	uint256 private lastSixteenWinnerPayments = 0;
	uint256 private quarterFinalWinnerPayments = 0;
	uint256 private semiFinalWinnerPayments = 0;
	bool private tournamentComplete = false;
    
    /*****------- STORAGE -------******/
    mapping (uint256 =&gt; address) public teamOwners;
    mapping (address =&gt; uint256) private ownerTeamCount;
    mapping (uint256 =&gt; address) public teamToApproved;
    mapping (uint256 =&gt; uint256) private teamPrices;
    address public contractModifierAddress;
    address public developerAddress;
    
    /*****------- DATATYPES -------******/
    struct Team {
        string name;
        string code;
        uint256 cost;
        uint256 price;
        address owner;
        uint256 numPayouts;
        mapping (uint256 =&gt; Payout) payouts;
    }

    struct Payout {
        string stage;
        uint256 amount;
        address to;
        uint256 when;
    }

    Team[] private teams;
    
    struct PayoutPrizes {
        uint256 LastSixteenWinner;
        bool LastSixteenTotalFixed;
        uint256 QuarterFinalWinner;
        bool QuarterFinalTotalFixed;
        uint256 SemiFinalWinner;
        bool SemiFinalTotalFixed;
        uint256 TournamentWinner;
    }
    
    PayoutPrizes private prizes;

    /*****------- MODIFIERS -------******/
    modifier onlyContractModifier() {
        require(msg.sender == contractModifierAddress);
        _;
    }
    
    /*****------- CONSTRUCTOR -------******/
    constructor() public {
        contractModifierAddress = msg.sender;
        developerAddress = msg.sender;

        // Initialse Prize Totals
        prizes.LastSixteenTotalFixed = false;
        prizes.QuarterFinalTotalFixed = false;
        prizes.SemiFinalTotalFixed = false;
    }
    
    /*****------- PUBLIC FUNCTIONS -------******/
    function name() public pure returns (string) {
        return &quot;CryptoCup&quot;;
    }
  
    function symbol() public pure returns (string) {
        return &quot;CryptoCupToken&quot;;
    }
    
    function implementsERC721() public pure returns (bool) {
        return true;
    }

    function ownerOf(uint256 _tokenId) public view returns (address owner) {
        owner = teamOwners[_tokenId];
        require(owner != address(0));
        return owner;
    }
    
    function takeOwnership(uint256 _tokenId) public {
        address to = msg.sender;
        address from = teamOwners[_tokenId];
    
        require(_addressNotNull(to));
        require(_approved(to, _tokenId));
    
        _transfer(from, to, _tokenId);
    }
    
    function approve(address _to, uint256 _tokenId) public {
        require(_owns(msg.sender, _tokenId));
        teamToApproved[_tokenId] = _to;
        emit Approval(msg.sender, _to, _tokenId);
    }
    
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return ownerTeamCount[_owner];
    }
    
    function totalSupply() public view returns (uint256 total) {
        return teams.length;
    }
    
    function transfer(address _to, uint256 _tokenId) public {
        require(_owns(msg.sender, _tokenId));
        require(_addressNotNull(_to));
        _transfer(msg.sender, _to, _tokenId);
    }
    
    function transferFrom(address _from, address _to, uint256 _tokenId) public {
        require(_owns(_from, _tokenId));
        require(_approved(_to, _tokenId));
        require(_addressNotNull(_to));
        _transfer(_from, _to, _tokenId);
    }

	function destroy() public onlyContractModifier {
		selfdestruct(contractModifierAddress);
    }

    function setDeveloper(address _newDeveloperAddress) public onlyContractModifier {
        require(_newDeveloperAddress != address(0));
        developerAddress = _newDeveloperAddress;
    }
    
    function createTeams() public onlyContractModifier {
        _createTeam(&quot;Russia&quot;, &quot;RUS&quot;, startingPrice, developerAddress);
        _createTeam(&quot;Saudi Arabia&quot;, &quot;KSA&quot;, startingPrice, developerAddress);
        _createTeam(&quot;Egypt&quot;, &quot;EGY&quot;, startingPrice, developerAddress);
        _createTeam(&quot;Uruguay&quot;, &quot;URU&quot;, startingPrice, developerAddress);
        _createTeam(&quot;Portugal&quot;, &quot;POR&quot;, startingPrice, developerAddress);
        _createTeam(&quot;Spain&quot;, &quot;SPA&quot;, startingPrice, developerAddress);
        _createTeam(&quot;Morocco&quot;, &quot;MOR&quot;, startingPrice, developerAddress);
        _createTeam(&quot;Iran&quot;, &quot;IRN&quot;, startingPrice, developerAddress);
        _createTeam(&quot;France&quot;, &quot;FRA&quot;, startingPrice, developerAddress);
        _createTeam(&quot;Australia&quot;, &quot;AUS&quot;, startingPrice, developerAddress);
        _createTeam(&quot;Peru&quot;, &quot;PER&quot;, startingPrice, developerAddress);
        _createTeam(&quot;Denmark&quot;, &quot;DEN&quot;, startingPrice, developerAddress);
        _createTeam(&quot;Argentina&quot;, &quot;ARG&quot;, startingPrice, developerAddress);
        _createTeam(&quot;Iceland&quot;, &quot;ICE&quot;, startingPrice, developerAddress);
        _createTeam(&quot;Croatia&quot;, &quot;CRO&quot;, startingPrice, developerAddress);
        _createTeam(&quot;Nigeria&quot;, &quot;NGA&quot;, startingPrice, developerAddress);
        _createTeam(&quot;Brazil&quot;, &quot;BRZ&quot;, startingPrice, developerAddress);
        _createTeam(&quot;Switzerland&quot;, &quot;SWI&quot;, startingPrice, developerAddress);
        _createTeam(&quot;Costa Rica&quot;, &quot;CRC&quot;, startingPrice, developerAddress);
        _createTeam(&quot;Serbia&quot;, &quot;SER&quot;, startingPrice, developerAddress);
        _createTeam(&quot;Germany&quot;, &quot;GER&quot;, startingPrice, developerAddress);
        _createTeam(&quot;Mexico&quot;, &quot;MEX&quot;, startingPrice, developerAddress);
        _createTeam(&quot;Sweden&quot;, &quot;SWE&quot;, startingPrice, developerAddress);
        _createTeam(&quot;South Korea&quot;, &quot;KOR&quot;, startingPrice, developerAddress);
        _createTeam(&quot;Belgium&quot;, &quot;BEL&quot;, startingPrice, developerAddress);
        _createTeam(&quot;Panama&quot;, &quot;PAN&quot;, startingPrice, developerAddress);
        _createTeam(&quot;Tunisia&quot;, &quot;TUN&quot;, startingPrice, developerAddress);
        _createTeam(&quot;England&quot;, &quot;ENG&quot;, startingPrice, developerAddress);
        _createTeam(&quot;Poland&quot;, &quot;POL&quot;, startingPrice, developerAddress);
        _createTeam(&quot;Senegal&quot;, &quot;SEN&quot;, startingPrice, developerAddress);
        _createTeam(&quot;Colombia&quot;, &quot;COL&quot;, startingPrice, developerAddress);
        _createTeam(&quot;Japan&quot;, &quot;JPN&quot;, startingPrice, developerAddress);
    }
    
    function createTeam(string name, string code) public onlyContractModifier {
        _createTeam(name, code, startingPrice, developerAddress);
    }
    
    function lockInLastSixteenPrize() public onlyContractModifier {
        prizes.LastSixteenTotalFixed = true;
    }
    
    function payLastSixteenWinner(uint256 _tokenId) public onlyContractModifier {
        require(prizes.LastSixteenTotalFixed != false);
        require(lastSixteenWinnerPayments &lt; 8);
        require(tournamentComplete != true);
        
        Team storage team = teams[_tokenId];
        require(team.numPayouts == 0);
        
        team.owner.transfer(prizes.LastSixteenWinner);
        emit PrizePaid(&quot;Last Sixteen&quot;, _tokenId, team.owner, prizes.LastSixteenWinner, uint256(now));

        team.payouts[team.numPayouts++] = Payout({
            stage: &quot;Last Sixteen&quot;,
            amount: prizes.LastSixteenWinner,
            to: team.owner,
            when: uint256(now)
        });
        
        lastSixteenWinnerPayments++;
    }
    
    function lockInQuarterFinalPrize() public onlyContractModifier {
        require(prizes.LastSixteenTotalFixed != false);
        prizes.QuarterFinalTotalFixed = true;
    }
    
    function payQuarterFinalWinner(uint256 _tokenId) public onlyContractModifier {
        require(prizes.QuarterFinalTotalFixed != false);
        require(quarterFinalWinnerPayments &lt; 4);
        require(tournamentComplete != true);
        Team storage team = teams[_tokenId];
        require(team.numPayouts == 1);
        Payout storage payout = team.payouts[0];
        require(_compareStrings(payout.stage, &quot;Last Sixteen&quot;));

        team.owner.transfer(prizes.QuarterFinalWinner);
        emit PrizePaid(&quot;Quarter Final&quot;, _tokenId, team.owner, prizes.QuarterFinalWinner, uint256(now));
        team.payouts[team.numPayouts++] = Payout({
            stage: &quot;Quarter Final&quot;,
            amount: prizes.QuarterFinalWinner,
            to: team.owner,
            when: uint256(now)
        });
        
        quarterFinalWinnerPayments++;
    }
    
    function lockInSemiFinalPrize() public onlyContractModifier {
        require(prizes.QuarterFinalTotalFixed != false);
        prizes.SemiFinalTotalFixed = true;
    }
        
    function paySemiFinalWinner(uint256 _tokenId) public onlyContractModifier {
        require(prizes.SemiFinalTotalFixed != false);
        require(semiFinalWinnerPayments &lt; 2);
        require(tournamentComplete != true);
        Team storage team = teams[_tokenId];
        require(team.numPayouts == 2);
        Payout storage payout = team.payouts[1];
        require(_compareStrings(payout.stage, &quot;Quarter Final&quot;));
        
        team.owner.transfer(prizes.SemiFinalWinner);
        emit PrizePaid(&quot;Semi Final&quot;, _tokenId, team.owner, prizes.SemiFinalWinner, uint256(now));
        team.payouts[team.numPayouts++] = Payout({
            stage: &quot;Semi Final&quot;,
            amount: prizes.SemiFinalWinner,
            to: team.owner,
            when: uint256(now)
        });
        
        semiFinalWinnerPayments++;
    }
    
    function payTournamentWinner(uint256 _tokenId) public onlyContractModifier {
        require (tournamentComplete != true);
        Team storage team = teams[_tokenId];
        require(team.numPayouts == 3);
        Payout storage payout = team.payouts[2];
        require(_compareStrings(payout.stage, &quot;Semi Final&quot;));

        team.owner.transfer(prizes.TournamentWinner);
        emit PrizePaid(&quot;Final&quot;, _tokenId, team.owner, prizes.TournamentWinner, uint256(now));
        team.payouts[team.numPayouts++] = Payout({
            stage: &quot;Final&quot;,
            amount: prizes.TournamentWinner,
            to: team.owner,
            when: uint256(now)
        });
        
        tournamentComplete = true;
    }

    function payExcess() public onlyContractModifier {
        /* ONLY IF TOURNAMENT FINISHED AND THERE&#39;S EXCESS - THERE SHOULDN&#39;T BE */
        /* ONLY IF TRADES OCCUR AFTER TOURNAMENT FINISHED */
        require (tournamentComplete != false);
        developerAddress.transfer(address(this).balance);
    }

    function getTeam(uint256 _tokenId) public view returns (uint256 id, string name, string code, uint256 cost, uint256 price, address owner, uint256 numPayouts) {
        Team storage team = teams[_tokenId];
        id = _tokenId;
        name = team.name;
        code = team.code;
        cost = team.cost;
        price = team.price;
        owner = team.owner;
        numPayouts = team.numPayouts;
    }
        
    function getTeamPayouts(uint256 _tokenId, uint256 _payoutId) public view returns (uint256 id, string stage, uint256 amount, address to, uint256 when) {
        Team storage team = teams[_tokenId];
        Payout storage payout = team.payouts[_payoutId];
        id = _payoutId;
        stage = payout.stage;
        amount = payout.amount;
        to = payout.to;
        when = payout.when;
    }

    // Allows someone to send ether and obtain the token
    function buyTeam(uint256 _tokenId) public payable {
        address from = teamOwners[_tokenId];
        address to = msg.sender;
        uint256 price = teamPrices[_tokenId];
        
	    require(_addressNotNull(to));
        require(from != to);
        require(msg.value &gt;= price);
        
        Team storage team = teams[_tokenId];
	    
        uint256 purchaseExcess = SafeMath.sub(msg.value, price);
        uint256 profit = SafeMath.sub(price, team.cost);
        
	    // get 15% - 5 goes to dev and 10 stays in prize fund that is split during knockout stages
	    uint256 onePercent = SafeMath.div(profit, 100);
	    uint256 developerAllocation = SafeMath.mul(onePercent, 5);
	    uint256 saleProceeds = SafeMath.add(SafeMath.mul(onePercent, 85), team.cost);
	    uint256 fundProceeds = SafeMath.mul(onePercent, 10);
	    
	    _transfer(from, to, _tokenId);
	    
	    // Pay previous owner if owner is not contract
        if (from != address(this)) {
	        from.transfer(saleProceeds);
        }

        // Pay developer
        if (developerAddress != address(this)) {
	        developerAddress.transfer(developerAllocation);
        }
        
        uint256 slice = 0;
        
        // Increase prize fund totals
        if (!prizes.LastSixteenTotalFixed) {
            slice = SafeMath.div(fundProceeds, 4);
            prizes.LastSixteenWinner += SafeMath.div(slice, 8);    
            prizes.QuarterFinalWinner += SafeMath.div(slice, 4);    
            prizes.SemiFinalWinner += SafeMath.div(slice, 2);    
            prizes.TournamentWinner += slice;    
        } else if (!prizes.QuarterFinalTotalFixed) {
            slice = SafeMath.div(fundProceeds, 3);
            prizes.QuarterFinalWinner += SafeMath.div(slice, 4);    
            prizes.SemiFinalWinner += SafeMath.div(slice, 2);    
            prizes.TournamentWinner += slice;   
        } else if (!prizes.SemiFinalTotalFixed) {
            slice = SafeMath.div(fundProceeds, 2);
            prizes.SemiFinalWinner += SafeMath.div(slice, 2);
            prizes.TournamentWinner += slice;   
        } else {
            prizes.TournamentWinner += fundProceeds;   
        }
	    
		// Set new price for team
	    uint256 newPrice = 0;
        if (price &lt; doublePriceUntil) {
            newPrice = SafeMath.div(SafeMath.mul(price, 200), 100);
        } else {
            newPrice = SafeMath.div(SafeMath.mul(price, 115), 100);
        }
		
	    teamPrices[_tokenId] = newPrice;
	    team.cost = price;
	    team.price = newPrice;
	    
	    emit TeamSold(_tokenId, from, price, to, newPrice, uint256(now), address(this).balance, prizes.LastSixteenWinner, prizes.QuarterFinalWinner, prizes.SemiFinalWinner, prizes.TournamentWinner);
	    
	    msg.sender.transfer(purchaseExcess);
	}
	
    function getPrizeFund() public view returns (bool lastSixteenTotalFixed, uint256 lastSixteenWinner, bool quarterFinalTotalFixed, uint256 quarterFinalWinner, bool semiFinalTotalFixed, uint256 semiFinalWinner, uint256 tournamentWinner, uint256 total) {
        lastSixteenTotalFixed = prizes.LastSixteenTotalFixed;
        lastSixteenWinner = prizes.LastSixteenWinner;   
        quarterFinalTotalFixed = prizes.QuarterFinalTotalFixed;
        quarterFinalWinner = prizes.QuarterFinalWinner;
        semiFinalTotalFixed = prizes.SemiFinalTotalFixed;
        semiFinalWinner = prizes.SemiFinalWinner;
        tournamentWinner = prizes.TournamentWinner;
        total = address(this).balance;
    }

    /********----------- PRIVATE FUNCTIONS ------------********/
    function _addressNotNull(address _to) private pure returns (bool) {
        return _to != address(0);
    }   
    
    function _createTeam(string _name, string _code, uint256 _price, address _owner) private {
        Team memory team = Team({
            name: _name,
            code: _code,
            cost: 0 ether,
            price: _price,
            owner: _owner,
            numPayouts: 0
        });

        uint256 newTeamId = teams.push(team) - 1;
        teamPrices[newTeamId] = _price;
        
        _transfer(address(0), _owner, newTeamId);
    }
    
    function _approved(address _to, uint256 _tokenId) private view returns (bool) {
        return teamToApproved[_tokenId] == _to;
    }
    
    function _transfer(address _from, address _to, uint256 _tokenId) private {
        ownerTeamCount[_to]++;
        teamOwners[_tokenId] = _to;
        
        Team storage team = teams[_tokenId];
        team.owner = _to;
        
        if (_from != address(0)) {
          ownerTeamCount[_from]--;
          delete teamToApproved[_tokenId];
        }
        
        emit Transfer(_from, _to, _tokenId);
    }
    
    function _owns(address _claimant, uint256 _tokenId) private view returns (bool) {
        return _claimant == teamOwners[_tokenId];
    }    
    
    function _compareStrings (string a, string b) private pure returns (bool){
        return keccak256(a) == keccak256(b);
    }
}