pragma solidity 0.4.24;

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

contract WorldCupTeam {

    EtherWorldCup etherWorldCup;
    string public teamName;
    address public parentAddr;
    uint256 public endTime = 1528988400; // 1528988400 - 2018-6-14 15:00 GMT

    function WorldCupTeam(address _parent, string _name) public {
        parentAddr = _parent;
        etherWorldCup = EtherWorldCup(parentAddr);
        teamName = _name;
    }

    // deposit will be transfered to the main pool in the parent contract
    function () 
        public
        payable 
    {
        require(now <= endTime, "Betting period has ended");

        parentAddr.transfer(msg.value);
        etherWorldCup.UpdateBetOnTeams(teamName, msg.sender, msg.value);
    }
}

contract EtherWorldCup is Ownable {
    using SafeMath for uint256;

    mapping(address=>bool) public isWorldCupTeam;
    uint public numOfTeam;

    mapping(string=>mapping(address=>uint256)) playersBetOnTeams; // address that bet on each team
    mapping(string=>address[]) playersPick; // player addresses on each team
    mapping(string=>uint256) PlayersBet; // bets on each team
    uint public commission = 90; // number in percent

    uint256 public sharingPool;
    uint256 totalShare = 50; 

    // EVENTS
    event UpdatedBetOnTeams(string team, address whom, uint256 betAmt);

    // FUNCTIONS

    function EtherWorldCup() public {}

    function permitChildContract(address[] _teams)
        public
        onlyOwner
    {
        for (uint i = 0; i < _teams.length; i++) {
            if (!isWorldCupTeam[_teams[i]]) numOfTeam++;
            isWorldCupTeam[_teams[i]] = true;
        }
    }

    function () payable {}
	
    // update the bets by child contract only
    function UpdateBetOnTeams(string _team, address _addr, uint256 _betAmt) 
    {   
        require(isWorldCupTeam[msg.sender]);

        if (playersBetOnTeams[_team][_addr] == 0) playersPick[_team].push(_addr); // prevent duplicate address
        playersBetOnTeams[_team][_addr] = playersBetOnTeams[_team][_addr].add(_betAmt);
        PlayersBet[_team] = PlayersBet[_team].add(_betAmt);
        sharingPool = sharingPool.add(_betAmt);
        UpdatedBetOnTeams(_team, _addr, _betAmt);
    }

    uint256 public numOfWinner;
    address[] public winners;
    uint256 public distributeAmount;

    // distribute fund to winners
    function distributeWinnerPool(string _winTeam, uint256 _share) 
        public 
        onlyOwner
    {
        distributeAmount = sharingPool.mul(commission).div(100).mul(_share).div(totalShare);
        winners = playersPick[_winTeam]; // number of ppl bet on the winning team
        numOfWinner = winners.length;

        // for each address, to distribute the prize according to the ratio
        for (uint i = 0; i < winners.length; i++) {
            uint256 sendAmt = distributeAmount.mul(playersBetOnTeams[_winTeam][winners[i]]).div(PlayersBet[_winTeam]);
            winners[i].transfer(sendAmt);
        }
    }

    function getPlayerBet(string _team, address _addr) 
        public
        returns (uint256)
    {
        return playersBetOnTeams[_team][_addr];
    }

    function getPlayersPick(string _team) 
        public
        returns (address[])
    {
        return playersPick[_team];
    }

    function getTeamBet(string _team) 
        public 
        returns (uint256)
    {
        return PlayersBet[_team];
    }

    function updateCommission(uint _newPercent) 
        public 
        onlyOwner
    {
        commission = _newPercent;
    }

    function safeDrain() 
        public 
        onlyOwner 
    {
        owner.transfer(this.balance);
    }
}