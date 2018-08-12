pragma solidity ^0.4.24;

/*
  @author Yumerium Ltd
*/
contract Yumo {
    using SafeMath for uint256;
    YumeriumManager public manager;
    YDistribution public yDistribution; // distribution contract for Yumerium holders
    address public teamWallet;
    address public creator;
    mapping(uint256 => Round) public rounds;
    uint256 public currentRound;
    uint256 public ethReserverForToken;
    uint256 public ethReserverForWithdraw;

    uint256 airdropChance = 0; // percentage to get airdrop 0 - 100%
    uint256 airdropChanceRate = 100; // percentage increased by 0.8% per transaction

    // fee for each transaction
    uint256[] public mainGameFee; // ether distributed for the main game
    uint256[] public feeHolders; // ether distributed for the main game
    uint256 public communityFee = 1;
    uint256 public airdropFee = 10; // ether distributed for the airdrop
    uint256 public referralFee = 10; // ether referrer receive in percentage
    uint256 public referrerBonus = 10; // bonus token referrer receive in percentage
    uint256 public maxTimeInHours = 5 minutes;
    uint256 public timePerETH = 30 seconds;

    uint256 public winnerReward = 25; // ether distributed for the main game
    uint256 public forNextRound = 25; // ether distributed for the main game
    uint256[] public pDistributionRatio; // ether distributed for the main game

    mapping(uint256 => mapping(address => Player)) public players; // map for the player information
    mapping(uint256 => address[]) public participantAddresses; // map for the player information
    mapping(address => Renowned) public renownedPlayers; // map for the player information
    mapping(address => uint256) public balanceOf; // amount ETH for players
    mapping(address => uint256) public tokenBalanceOf; // amount ETH for players
    mapping(bytes32 => bool) public nameList; // map for the player information

    constructor(address _wallet, address _manager_address, address _yDistribution) public {
        teamWallet = _wallet;
        creator = msg.sender;
        manager = YumeriumManager(_manager_address);
        yDistribution = YDistribution(_yDistribution);
        currentRound = 0;

        rounds[currentRound].lastPersonParticipated = creator;
        rounds[currentRound].checkpoint = now;

        mainGameFee.push(20);
        mainGameFee.push(50);
        feeHolders.push(10);
        feeHolders.push(6);

        pDistributionRatio.push(15);
        pDistributionRatio.push(20);
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
        return calc(val.add(1)).sub(val);
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

    function becomeRenown(bytes32 name) public isHuman() payable {
        require(msg.value >= 1 * 10 ** 16, "Not enough ETH to be renowned!");
        require(!renownedPlayers[msg.sender].isRenowned, "You already registered as renowned!");
        require(name.length != 0, "Name can&#39;t be empty!");
        require(!nameList[name], "Following name already exists");
        renownedPlayers[msg.sender].addr = msg.sender;
        renownedPlayers[msg.sender].name = name;
        renownedPlayers[msg.sender].referralCode = keccak256(abi.encodePacked(msg.sender));
        nameList[name] = true;
        renownedPlayers[msg.sender].isRenowned = true;
    }

    function participate(uint team, address referredAddress) public isHuman() payable {
        uint256 price = getPrice(rounds[currentRound].totalAlbums);
        require(msg.value >= price, "the amount of ETH invested is less than minimum participating fee");
        require(!rounds[currentRound].hasGameOver, "The game has already been over");
        uint256 albums = msg.value.div(price);
        uint256 timeLeft = now.sub(rounds[currentRound].checkpoint);
        // game will be over when time out or event sale ended
        if (timeLeft >= maxTimeInHours)
        {
            gameOver();
            currentRound = currentRound.add(1);
            rounds[currentRound].lastPersonParticipated = creator;
            rounds[currentRound].checkpoint = now;
        }
        distribute(albums, team, referredAddress);
    }
    function useVaults(uint team, uint256 numAlbums) external isHuman() {
        uint256 price = getPrice(rounds[currentRound].totalAlbums).mul(numAlbums);
        require(balanceOf[msg.sender] >= price, "the amount of ETH you have is less than you are trying to pay");
        require(!rounds[currentRound].hasGameOver, "The game has already been over");
        uint256 timeLeft = now.sub(rounds[currentRound].checkpoint);
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(price);
        // game will be over when time out or event sale ended
        if (timeLeft >= maxTimeInHours)
        {
            gameOver();
            currentRound = currentRound.add(1);
            rounds[currentRound].lastPersonParticipated = creator;
            rounds[currentRound].checkpoint = now;
        }
        distribute(numAlbums, team, address(0));
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
    // change ydist address
    function changeYDistAddress(address _yDistribution) external {
        require(msg.sender==creator, "Changed the creator");
        yDistribution = YDistribution(_yDistribution);
    }

    event Contribution(address from, uint256 amount);
    event ParticipateGame(address from, uint256 ethForMainGame);
    event Referral(address referrer, address referredAddress, uint256 rewardGiven);
    event Airdrop(address sender, uint256 chanceToGet, uint256 randomValue, uint256 valueToGet, uint256 totalAirdropPot);
    event GameOver(address winner, uint256 rewardGained);

    function gameOver() public {
        require(!rounds[currentRound].hasGameOver, "The game has already been over");
        uint256 timePassed = now.sub(rounds[currentRound].checkpoint);
        require(timePassed >= maxTimeInHours, "game must have triggered the following conditions");

        Player memory lastPlayer = players[currentRound][rounds[currentRound].lastPersonParticipated];

        uint256 amountForWinner = rounds[currentRound].mainGamePot.mul(winnerReward).div(100);
        uint256 amountForParticipants = rounds[currentRound].mainGamePot;
        amountForParticipants = amountForParticipants.mul(pDistributionRatio[lastPlayer.lastChosenTeam]).div(100);
        uint256 amountForNextRound = rounds[currentRound].mainGamePot.mul(forNextRound).div(100);
        uint256 remainETH = rounds[currentRound].mainGamePot.sub(amountForWinner)
            .sub(amountForParticipants).sub(amountForNextRound);

        ethReserverForToken = ethReserverForToken.add(amountForParticipants);
        ethReserverForWithdraw = ethReserverForWithdraw.add(rounds[currentRound].participantsPot);
        // start distribution
        balanceOf[lastPlayer.addr] = balanceOf[lastPlayer.addr].add(amountForWinner);
        rounds[currentRound + 1].mainGamePot = amountForNextRound;
        for (uint256 i = 0; i < participantAddresses[currentRound].length; i++)
        {
            address participantAddress = participantAddresses[currentRound][i];
            uint256 tokenToGive = amountForParticipants.mul(players[currentRound][participantAddress].albums)
                .div(rounds[currentRound].totalAlbums);
            uint256 ethToGive = rounds[currentRound].participantsPot.mul(players[currentRound][participantAddress].albums)
                .div(rounds[currentRound].totalAlbums);
            tokenBalanceOf[participantAddress] = tokenBalanceOf[participantAddress].add(tokenToGive);
            balanceOf[participantAddress] = balanceOf[participantAddress].add(ethToGive);
        }
        if (remainETH > 0)
        {
            address(yDistribution).transfer(remainETH);
            yDistribution.gameOver();
        }

        // rest
        if (address(this).balance > ethReserverForToken.add(ethReserverForWithdraw))
        {
            address(this).transfer(address(this).balance.sub(ethReserverForToken).sub(ethReserverForWithdraw));
        }

        rounds[currentRound].hasGameOver = true;
        emit GameOver(rounds[currentRound].lastPersonParticipated, amountForWinner);
    }
    function withdraw(uint256 ethValue, uint256 tokenValue) public {
        require(balanceOf[msg.sender] >= ethValue && tokenBalanceOf[msg.sender] >= tokenValue, "You are trying to withdraw more than you have!");
        msg.sender.transfer(ethValue);
        manager.getYumerium.value(ethValue)(msg.sender);
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(ethValue);
        tokenBalanceOf[msg.sender] = tokenBalanceOf[msg.sender].sub(tokenValue);
    }
    function distribute(uint256 albums, uint team, address referredAddress) private {
        if (!players[currentRound][msg.sender].notFirstTime) {
            players[currentRound][msg.sender].addr = msg.sender;
            players[currentRound][msg.sender].notFirstTime = true;
            participantAddresses[currentRound].push(msg.sender);
            yDistribution.addHolder(msg.sender);
        }
        players[currentRound][msg.sender].albums = players[currentRound][msg.sender].albums.add(albums);
        players[currentRound][msg.sender].lastChosenTeam = team;
        rounds[currentRound].lastPersonParticipated = msg.sender;

        // calculate distribution for the game
        uint256 distributionForMainGame = msg.value.mul(mainGameFee[team]).div(100);
        uint256 distributionForAirdrop = msg.value.mul(airdropFee).div(100);
        uint256 feeYDist = msg.value.mul(feeHolders[team]).div(100);
        uint256 comFee = msg.value.mul(communityFee).div(100);

        uint256 remainingEther = msg.value.sub(distributionForMainGame).
            sub(feeYDist).sub(comFee).sub(distributionForAirdrop);
        // distribution for referral
        if (referredAddress != address(0) && referredAddress != msg.sender && renownedPlayers[referredAddress].referralCode > 0)
        {
            uint256 ethForReferral = msg.value.mul(referralFee).div(100);
            remainingEther = remainingEther.sub(ethForReferral);
            referredAddress.transfer(ethForReferral);
            emit Referral(msg.sender, referredAddress, ethForReferral);
        }
        // transfer distributions
        teamWallet.transfer(comFee);
        address(yDistribution).transfer(feeYDist);
        rounds[currentRound].participantsPot = rounds[currentRound].participantsPot.add(remainingEther);

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
        uint256 participantsPot;
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
    function getYumerium(address sender) public payable returns (uint256);
}

contract YDistribution {
    function addHolder(address holder) external;
    function gameOver() external;
}