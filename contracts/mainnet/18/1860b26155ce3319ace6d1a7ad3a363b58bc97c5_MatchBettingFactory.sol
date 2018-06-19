pragma solidity ^0.4.21;

contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    function Ownable() public {
        owner = msg.sender;
    }


    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }


    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

}


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
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return c;
    }

    /**
    * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
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

/// @title Contract to bet Ether for on a match of two teams
contract MatchBetting {
    using SafeMath for uint256;

    //Represents a team, along with betting information
    struct Team {
        string name;
        mapping(address => uint) bettingContribution;
        mapping(address => uint) ledgerBettingContribution;
        uint totalAmount;
        uint totalParticipants;
    }
    //Represents two teams
    Team[2] public teams;
    // Flag to show if the match is completed
    bool public matchCompleted = false;
    // Flag to show if the contract will stop taking bets.
    bool public stopMatchBetting = false;
    // The minimum amount of ether to bet for the match
    uint public minimumBetAmount;
    // WinIndex represents the state of the match. 4 shows match not started.
    // 4 - Match has not started
    // 0 - team[0] has won
    // 1 - team[1] has won
    // 2 - match is draw
    uint public winIndex = 4;
    // A helper variable to track match easily on the backend web server
    uint matchNumber;
    // Owner of the contract
    address public owner;
    // The jackpot address, to which some of the proceeds goto from the match
    address public jackpotAddress;

    address[] public betters;

    // Only the owner will be allowed to excute the function.
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    //@notice Contructor that is used configure team names, the minimum bet amount, owner, jackpot address
    // and match Number
    function MatchBetting(string teamA, string teamB, uint _minimumBetAmount, address sender, address _jackpotAddress, uint _matchNumber) public {
        Team memory newTeamA = Team({
            totalAmount : 0,
            name : teamA,
            totalParticipants : 0
            });

        Team memory newTeamB = Team({
            totalAmount : 0,
            name : teamB,
            totalParticipants : 0
            });

        teams[0] = newTeamA;
        teams[1] = newTeamB;
        minimumBetAmount = _minimumBetAmount;
        owner = sender;
        jackpotAddress = _jackpotAddress;
        matchNumber = _matchNumber;
    }

    //@notice Allows a user to place Bet on the match
    function placeBet(uint index) public payable {
        require(msg.value >= minimumBetAmount);
        require(!stopMatchBetting);
        require(!matchCompleted);

        if(teams[0].bettingContribution[msg.sender] == 0 && teams[1].bettingContribution[msg.sender] == 0) {
            betters.push(msg.sender);
        }

        if (teams[index].bettingContribution[msg.sender] == 0) {
            teams[index].totalParticipants = teams[index].totalParticipants.add(1);
        }
        teams[index].bettingContribution[msg.sender] = teams[index].bettingContribution[msg.sender].add(msg.value);
        teams[index].ledgerBettingContribution[msg.sender] = teams[index].ledgerBettingContribution[msg.sender].add(msg.value);
        teams[index].totalAmount = teams[index].totalAmount.add(msg.value);
    }

    //@notice Set the outcome of the match
    function setMatchOutcome(uint winnerIndex, string teamName) public onlyOwner {
        if (winnerIndex == 0 || winnerIndex == 1) {
            //Match is not draw, double check on name and index so that no mistake is made
            require(compareStrings(teams[winnerIndex].name, teamName));
            uint loosingIndex = (winnerIndex == 0) ? 1 : 0;
            // Send Share to jackpot only when Ether are placed on both the teams
            if (teams[winnerIndex].totalAmount != 0 && teams[loosingIndex].totalAmount != 0) {
                uint jackpotShare = (teams[loosingIndex].totalAmount).div(5);
                jackpotAddress.transfer(jackpotShare);
            }
        }
        winIndex = winnerIndex;
        matchCompleted = true;
    }

    //@notice Sets the flag stopMatchBetting to true
    function setStopMatchBetting() public onlyOwner{
        stopMatchBetting = true;
    }

    //@notice Allows the user to get ether he placed on his team, if his team won or draw.
    function getEther() public {
        require(matchCompleted);

        if (winIndex == 2) {
            uint betOnTeamA = teams[0].bettingContribution[msg.sender];
            uint betOnTeamB = teams[1].bettingContribution[msg.sender];

            teams[0].bettingContribution[msg.sender] = 0;
            teams[1].bettingContribution[msg.sender] = 0;

            uint totalBetContribution = betOnTeamA.add(betOnTeamB);
            require(totalBetContribution != 0);

            msg.sender.transfer(totalBetContribution);
        } else {
            uint loosingIndex = (winIndex == 0) ? 1 : 0;
            // If No Ether were placed on winning Team - Allow claim Ether placed on loosing side.

            uint betValue;
            if (teams[winIndex].totalAmount == 0) {
                betValue = teams[loosingIndex].bettingContribution[msg.sender];
                require(betValue != 0);

                teams[loosingIndex].bettingContribution[msg.sender] = 0;
                msg.sender.transfer(betValue);
            } else {
                betValue = teams[winIndex].bettingContribution[msg.sender];
                require(betValue != 0);

                teams[winIndex].bettingContribution[msg.sender] = 0;

                uint winTotalAmount = teams[winIndex].totalAmount;
                uint loosingTotalAmount = teams[loosingIndex].totalAmount;

                if (loosingTotalAmount == 0) {
                    msg.sender.transfer(betValue);
                } else {
                    //original Bet + (original bet * 80 % of bet on losing side)/bet on winning side
                    uint userTotalShare = betValue;
                    uint bettingShare = betValue.mul(80).div(100).mul(loosingTotalAmount).div(winTotalAmount);
                    userTotalShare = userTotalShare.add(bettingShare);

                    msg.sender.transfer(userTotalShare);
                }
            }
        }
    }

    function getBetters() public view returns (address[]) {
        return betters;
    }

    //@notice get various information about the match and its current state.
    function getMatchInfo() public view returns (string, uint, uint, string, uint, uint, uint, bool, uint, uint, bool) {
        return (teams[0].name, teams[0].totalAmount, teams[0].totalParticipants, teams[1].name,
        teams[1].totalAmount, teams[1].totalParticipants, winIndex, matchCompleted, minimumBetAmount, matchNumber, stopMatchBetting);
    }

    //@notice Returns users current amount of bet on the match
    function userBetContribution(address userAddress) public view returns (uint, uint) {
        return (teams[0].bettingContribution[userAddress], teams[1].bettingContribution[userAddress]);
    }

    //@notice Returns how much a user has bet on the match.
    function ledgerUserBetContribution(address userAddress) public view returns (uint, uint) {
        return (teams[0].ledgerBettingContribution[userAddress], teams[1].ledgerBettingContribution[userAddress]);
    }

    //@notice Private function the helps in comparing strings.
    function compareStrings(string a, string b) private pure returns (bool){
        return keccak256(a) == keccak256(b);
    }
}

contract MatchBettingFactory is Ownable {
    // Array of all the matches deployed
    address[] deployedMatches;
    // The address to which some ether is to be transferred
    address public jackpotAddress;

    //@notice Constructor thats sets up the jackpot address
    function MatchBettingFactory(address _jackpotAddress) public{
        jackpotAddress = _jackpotAddress;
    }

    //@notice Creates a match with given team names, minimum bet amount and a match number
    function createMatch(string teamA, string teamB, uint _minimumBetAmount, uint _matchNumber) public onlyOwner{
        address matchBetting = new MatchBetting(teamA, teamB, _minimumBetAmount, msg.sender, jackpotAddress, _matchNumber);
        deployedMatches.push(matchBetting);
    }

    //@notice get a address of all deployed matches
    function getDeployedMatches() public view returns (address[]) {
        return deployedMatches;
    }
}