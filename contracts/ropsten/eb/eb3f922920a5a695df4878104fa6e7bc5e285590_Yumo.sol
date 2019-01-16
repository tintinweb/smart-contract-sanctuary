pragma solidity ^0.4.24;

/*
  @author Yumerium Ltd
*/
contract Yumo {
    using SafeMath for uint256;
    YumeriumManager public manager;
    address public teamWallet;
    address public creator;
    mapping(uint256 => Round) public rounds;
    uint256 public currentRound;

    uint256 airdropChance = 0; // percentage to get airdrop 0 - 100%
    uint256 airdropChanceRate = 10; // percentage increased by 1% per transaction

    // fee for each transaction
    uint256 public mainGameFee = 50; // ether distributed for the main game
    uint256 public feeParticipants = 18; // ether distributed for the main game
    uint256 public communityFee = 20;
    uint256 public gameoverFee = 2;
    uint256 public airdropFee = 20; // ether distributed for the airdrop
    uint256 public referralFee = 10; // ether referrer receive in percentage
    uint256 public referrerBonus = 10; // bonus token referrer receive in percentage
    uint256 public maxTimeInHours = 5 minutes;
    uint256 public timePerETH = 30 seconds;

    uint256 public winnerReward = 48; // ether distributed for the main game
    uint256[] public forNextRound; // ether distributed for the main game
    uint256[] public pDistributionRatio; // ether distributed for the main game
    uint256 public ethReserverForWithdrawl;
    
    mapping(uint256 => mapping(uint => uint256)) public totalInvestForEachTeam;
    mapping(uint256 => mapping(address => Player)) public players; // map for the player information
    mapping(uint256 => address[]) public participantAddresses; // map for the player information
    mapping(address => Renowned) public renownedPlayers; // map for the player information
    mapping(address => uint256) public balanceOf; // amount ETH for players
    mapping(address => uint256) public winningRewards; // amount ETH for players
    mapping(address => uint256) public gainedByReferrals; // amount ETH for players
    mapping(bytes32 => bool) public nameList; // map for the player information
    mapping(bytes32 => address) public referral; // map for the player information

    constructor(address _wallet, address _manager_address) public {
        teamWallet = _wallet;
        creator = msg.sender;
        manager = YumeriumManager(_manager_address);
        currentRound = 0;

        rounds[currentRound].lastPersonParticipated = creator;
        rounds[currentRound].checkpoint = now;

        forNextRound.push(35);
        forNextRound.push(25);
        pDistributionRatio.push(15);
        pDistributionRatio.push(25);
    }

    modifier isHuman() {
        address _addr = msg.sender;
        uint256 _codeLength;
        
        assembly {_codeLength := extcodesize(_addr)}
        require(_codeLength == 0, "sorry humans only");
        _;
    }

    function() external isHuman() payable {
        participate(0, address(0));
    }

    function getPrice(uint256 val) public pure returns (uint256) {
        return calc(val.add(1000000000000000000)).sub(calc(val)).add(10 ** 9);
    }
    function calc(uint256 val) private pure returns (uint256) {
        uint256 a = 781 * 10 * 5;
        uint256 b = 149 * 10 ** 13;
        b = b.mul(10 ** 18).div(2);
        return a.mul(val).mul(val).add(b).div(10 ** 32);
    }
    function getTimeLeft() public view returns(uint256) {
        uint256 timeLeft = now.sub(rounds[currentRound].checkpoint);
        if (timeLeft >= maxTimeInHours) {
            return 0;
        }
        return maxTimeInHours.sub(timeLeft);
    }
    function estimateDistribution() public view returns (uint256)
    {
        address participantAddress = msg.sender;
        Player memory lastPlayer = players[currentRound][rounds[currentRound].lastPersonParticipated];
        uint256 amountForParticipants = rounds[currentRound].mainGamePot;

        amountForParticipants = amountForParticipants.mul(pDistributionRatio[lastPlayer.lastChosenTeam]).div(100);
        uint256 ethToGive = amountForParticipants.mul(players[currentRound][participantAddress].albums)
            .div(rounds[currentRound].totalAlbums);
        return ethToGive;
    }

    function becomeRenown(bytes32 name) public isHuman() payable {
        require(msg.value >= 1 * 10 ** 16, "Not enough ETH to be renowned!");
        require(!renownedPlayers[msg.sender].isRenowned, "You already registered as renowned!");
        require(name.length != 0, "Name can&#39;t be empty!");
        require(!nameList[name], "Following name already exists");
        renownedPlayers[msg.sender].addr = msg.sender;
        renownedPlayers[msg.sender].name = name;
        renownedPlayers[msg.sender].referralCode = keccak256(abi.encodePacked(msg.sender));
        referral[renownedPlayers[msg.sender].referralCode] = msg.sender;
        nameList[name] = true;
        renownedPlayers[msg.sender].isRenowned = true;
        teamWallet.transfer(msg.value);
    }

    function participate(uint team, address referredAddress) public isHuman() payable {
        require(currentRound < (2 ** 256 - 1), "Can&#39;t play the game anymore");
        require(!rounds[currentRound].hasGameOver, "The game has already been over");
        uint256 timeLeft = now.sub(rounds[currentRound].checkpoint);
        // game will be over when time out or event sale ended
        if (timeLeft >= maxTimeInHours)
        {
            if (rounds[currentRound].totalAlbums > 0)
            {
                gameOver();
            }
        }
        uint256 price = getPrice(rounds[currentRound].totalAlbums);
        require(msg.value >= price, "the amount of ETH invested is less than minimum participating fee");
        uint256 albums = msg.value.div(price);
        distribute(albums, team, referredAddress);
    }
    function useVaults(uint team, uint256 numAlbums) external isHuman() {
        require(currentRound < (2 ** 256 - 1), "Can&#39;t play the game anymore");
        require(!rounds[currentRound].hasGameOver, "The game has already been over");
        uint256 timeLeft = now.sub(rounds[currentRound].checkpoint);
        // game will be over when time out or event sale ended
        if (timeLeft >= maxTimeInHours)
        {
            if (rounds[currentRound].totalAlbums > 0)
            {
                gameOver();
            }
        }
        uint256 price = getPrice(rounds[currentRound].totalAlbums).mul(numAlbums);
        require(balanceOf[msg.sender] >= price, "the amount of ETH you have is less than you are trying to pay");
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(price);
        distributeUsingVaults(numAlbums, price, team, address(0));
    }

    // change creator address
    function changeCreator(address _creator) external {
        require(msg.sender==creator, "Changed the creator");
        creator = _creator;
    }
    // change wallet address
    function changeTeamWallet(address _wallet) external {
        require(msg.sender==creator, "Changed the creator");
        teamWallet = _wallet;
    }
    // change sale address
    function changeManagerAddress(address _manager_address) external {
        require(msg.sender==creator, "Changed the creator");
        manager = YumeriumManager(_manager_address);
    }

    event Contribution(address from, uint256 amount);
    event ParticipateGame(address from, uint256 ethForMainGame);
    event Referral(address referrer, address referredAddress, uint256 rewardGiven);
    event Airdrop(address sender, uint256 chanceToGet, uint256 randomValue, uint256 valueToGet, uint256 totalAirdropPot);
    event GameOver(address winner, uint256 rewardGained);

    function gameOver() public {
        require(currentRound < (2 ** 256 - 1), "Can&#39;t play the game anymore");
        require(!rounds[currentRound].hasGameOver, "The game has already been over");
        uint256 timePassed = now.sub(rounds[currentRound].checkpoint);
        require(timePassed >= maxTimeInHours, "game must have triggered the following conditions");

        Player memory lastPlayer = players[currentRound][rounds[currentRound].lastPersonParticipated];

        uint256 amountForWinner = rounds[currentRound].mainGamePot.mul(winnerReward).div(100);
        uint256 amountForParticipants = rounds[currentRound].mainGamePot;
        amountForParticipants = amountForParticipants.mul(pDistributionRatio[lastPlayer.lastChosenTeam]).div(100);
        uint256 amountForNextRound = rounds[currentRound].mainGamePot.mul(forNextRound[lastPlayer.lastChosenTeam]).div(100);

        // start distribution
        winningRewards[lastPlayer.addr] = winningRewards[lastPlayer.addr].add(amountForWinner);
        if (currentRound < (2 ** 256 - 2)) {
            rounds[currentRound + 1].mainGamePot = amountForNextRound;
        }
        else {
            teamWallet.transfer(amountForNextRound);
        }
        
        for (uint256 i = 0; i < participantAddresses[currentRound].length; i++)
        {
            address participantAddress = participantAddresses[currentRound][i];
            uint256 ethToGive = amountForParticipants.mul(players[currentRound][participantAddress].albums)
                .div(rounds[currentRound].totalAlbums);
            ethReserverForWithdrawl = ethReserverForWithdrawl.add(ethToGive);
            balanceOf[participantAddress] = balanceOf[participantAddress].add(ethToGive);
        }

        teamWallet.transfer(rounds[currentRound].airdropPot);
        teamWallet.transfer(rounds[currentRound].mainGamePot.mul(gameoverFee).div(100));

        rounds[currentRound].hasGameOver = true;
        currentRound = currentRound.add(1);
        rounds[currentRound].lastPersonParticipated = creator;
        rounds[currentRound].checkpoint = now;

        emit GameOver(rounds[currentRound].lastPersonParticipated, amountForWinner);
    }
    function withdraw() public {
        require(!rounds[currentRound].hasGameOver, "The game has already been over");
        uint256 timeLeft = now.sub(rounds[currentRound].checkpoint);
        // game will be over when time out or event sale ended
        if (timeLeft >= maxTimeInHours)
        {
            if (rounds[currentRound].totalAlbums > 0)
            {
                gameOver();
            }
        }
        msg.sender.transfer(balanceOf[msg.sender]);
        msg.sender.transfer(winningRewards[msg.sender]);
        msg.sender.transfer(gainedByReferrals[msg.sender]);
        ethReserverForWithdrawl = ethReserverForWithdrawl.sub(balanceOf[msg.sender]);
        balanceOf[msg.sender] = 0;
        winningRewards[msg.sender] = 0;
        gainedByReferrals[msg.sender] = 0;
    }
    function distribute(uint256 albums, uint team, address referredAddress) private {
        if (!players[currentRound][msg.sender].notFirstTime) {
            players[currentRound][msg.sender].addr = msg.sender;
            players[currentRound][msg.sender].notFirstTime = true;
            participantAddresses[currentRound].push(msg.sender);
        }
        players[currentRound][msg.sender].albums = players[currentRound][msg.sender].albums.add(albums);
        players[currentRound][msg.sender].lastChosenTeam = team;
        rounds[currentRound].lastPersonParticipated = msg.sender;
        totalInvestForEachTeam[currentRound][team] = totalInvestForEachTeam[currentRound][team].add(msg.value);

        // calculate distribution for the game
        uint256 distributionForMainGame = msg.value.mul(mainGameFee).div(100);
        uint256 distributionForAirdrop = msg.value.mul(airdropFee).div(100);
        uint256 comFee = msg.value.mul(communityFee).div(100);

        uint256 remainingEther = msg.value.sub(distributionForMainGame).sub(comFee).sub(distributionForAirdrop);
        // distribution for referral
        if (referredAddress != address(0) && referredAddress != msg.sender && renownedPlayers[referredAddress].referralCode > 0)
        {
            uint256 ethForReferral = msg.value.mul(referralFee).div(100);
            remainingEther = remainingEther.sub(ethForReferral);
            gainedByReferrals[msg.sender] = gainedByReferrals[msg.sender].add(ethForReferral);
            emit Referral(msg.sender, referredAddress, ethForReferral);
        }

        // distribute yum token to the participant here
        manager.getYumerium(remainingEther, msg.sender);

        // transfer distributions
        teamWallet.transfer(comFee);

        // distribution for main game
        rounds[currentRound].totalAlbums = rounds[currentRound].totalAlbums.add(albums);
        rounds[currentRound].mainGamePot = rounds[currentRound].mainGamePot.add(distributionForMainGame);
        
        // distribution for airdrop
        rounds[currentRound].airdropPot = rounds[currentRound].airdropPot.add(distributionForAirdrop);
        airdropChance = airdropChance.add(airdropChanceRate);
        airdrop(msg.sender, msg.value);

        uint256 timeAdded = albums.mul(timePerETH);
        rounds[currentRound].checkpoint = rounds[currentRound].checkpoint.add(timeAdded);
        if (now < rounds[currentRound].checkpoint)
        {
            rounds[currentRound].checkpoint = now;
        }
        emit ParticipateGame(msg.sender, distributionForMainGame);
    }
    function distributeUsingVaults(uint256 albums, uint256 price, uint team, address referredAddress) private {
        if (!players[currentRound][msg.sender].notFirstTime) {
            players[currentRound][msg.sender].addr = msg.sender;
            players[currentRound][msg.sender].notFirstTime = true;
            participantAddresses[currentRound].push(msg.sender);
        }
        players[currentRound][msg.sender].albums = players[currentRound][msg.sender].albums.add(albums);
        players[currentRound][msg.sender].lastChosenTeam = team;
        rounds[currentRound].lastPersonParticipated = msg.sender;
        totalInvestForEachTeam[currentRound][team] = totalInvestForEachTeam[currentRound][team].add(price);

        // calculate distribution for the game
        uint256 distributionForMainGame = price.mul(mainGameFee).div(100);
        uint256 distributionForAirdrop = price.mul(airdropFee).div(100);

        uint256 remainingEther = price.sub(distributionForMainGame).sub(price.mul(communityFee).div(100)).sub(distributionForAirdrop);
        // distribution for referral
        if (referredAddress != address(0) && referredAddress != msg.sender && renownedPlayers[referredAddress].referralCode > 0)
        {
            uint256 ethForReferral = price.mul(referralFee).div(100);
            remainingEther = remainingEther.sub(ethForReferral);
            gainedByReferrals[msg.sender] = gainedByReferrals[msg.sender].add(ethForReferral);
            emit Referral(msg.sender, referredAddress, ethForReferral);
        }
        
        // distribute yum token to the participant here
        manager.getYumerium(remainingEther, msg.sender);

        // transfer distributions
        teamWallet.transfer(price.mul(communityFee).div(100));

        // distribution for main game
        rounds[currentRound].totalAlbums = rounds[currentRound].totalAlbums.add(albums);
        rounds[currentRound].mainGamePot = rounds[currentRound].mainGamePot.add(distributionForMainGame);
        
        // distribution for airdrop
        rounds[currentRound].airdropPot = rounds[currentRound].airdropPot.add(distributionForAirdrop);
        airdropChance = airdropChance.add(airdropChanceRate);
        airdrop(msg.sender, price);

        rounds[currentRound].checkpoint = rounds[currentRound].checkpoint.add(albums.mul(timePerETH));
        if (now < rounds[currentRound].checkpoint)
        {
            rounds[currentRound].checkpoint = now;
        }
        emit ParticipateGame(msg.sender, distributionForMainGame);
    }
    function airdrop(address sender, uint256 amountInvested) private {
        uint256 seed = uint256(keccak256(abi.encodePacked((block.timestamp)
        .add(block.difficulty)
        .add((uint256(keccak256(abi.encodePacked(
            block.coinbase)))) / 
            (now))
            .add(block.gaslimit)
            .add((uint256(keccak256(abi.encodePacked(msg.sender)))) / (now)).add(block.number)
        )));

        uint256 p = (seed - ((seed / 1000) * 1000));
        if(p < airdropChance)
        {
            uint256 amountReceive = 0;
            // more than 10 eth invested
            if (amountInvested >= 10 * 10 ** 18) {
                amountReceive = rounds[currentRound].airdropPot;
            }
            // more than 1 eth invested
            else if (amountInvested >= 1 * 10 ** 18) {
                amountReceive = rounds[currentRound].airdropPot.mul(75).div(100);
            }
             // more than 0.1 eth invested
            else if (amountInvested >= 1 * 10 ** 17) {
                amountReceive = rounds[currentRound].airdropPot.mul(50).div(100);
            }
             // more than 0.01 eth invested
            else if (amountInvested >= 1 * 10 ** 16) {
                amountReceive = rounds[currentRound].airdropPot.mul(25).div(100);
            }
            // less than 0.01 eth invested
            else {
                amountReceive = rounds[currentRound].airdropPot.mul(10).div(100);
            }

            emit Airdrop(sender, airdropChance, p, amountReceive, rounds[currentRound].airdropPot);
            rounds[currentRound].airdropPot = rounds[currentRound].airdropPot.sub(amountReceive);
            sender.transfer(amountReceive);
            airdropChance = 0;
        }
        else {
            emit Airdrop(sender, airdropChance, p, 0, rounds[currentRound].airdropPot);
        }
    }
    struct Player {
        address addr;
        uint256 albums;
        uint lastChosenTeam;
        bool notFirstTime;
    }
    struct Renowned {
        bytes32 referralCode;
        bytes32 name;
        address addr;
        bool isRenowned;
    }
    struct Round {
        address lastPersonParticipated; // if no one participate the game, initial ether will be given back to the creator
        uint256 checkpoint;
        bool hasGameOver;
        uint256 totalAlbums;
        uint256 mainGamePot; // ether gathered for main game
        uint256 airdropPot; // ether gathered for airdrop
    }
}


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
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
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}

contract YumeriumManager {
    function getYumerium(uint256 value, address sender) public returns (uint256);
}