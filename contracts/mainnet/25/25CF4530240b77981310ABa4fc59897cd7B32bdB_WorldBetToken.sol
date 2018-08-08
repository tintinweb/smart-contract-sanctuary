pragma solidity ^0.4.18;

contract WorldBetToken {
    /* Token name */
    string public name = "World Bet Lottery Tickets";

    /* Token Symbol */
    string public symbol = "WBT";

    /* Token digit*/
    uint public decimals = 0;

    mapping(uint => uint) private userBalanceOf;                // user total amount of tickets
    bool public stopped = false;

    /* User*/
    struct Country {
        uint user; // country sequence id
        uint balance; // total amount of bought tickets for this country
    }

    // installed when one country has won
    uint public WINNER_COUNTRY_CODE = 0;

    mapping(uint => bool) private countryIsPlaying;

    /* Countries->Users*/
    mapping(uint => Country[]) public users;       // countries


    /* Countries->Users*/
    mapping(uint => uint[]) public countries;       // countries

    /* Jackpot Users*/
    uint[] public jackpotUsers;

    /* Jackpot Users*/
    uint[] activeCountries;

    /* Jackpot Eligibility*/
    mapping(uint => bool) isJackpotEligible;

    /* Jackpot Location*/
    mapping(uint => uint) jackpotLocation;

    // JACKPOT WINNER
    uint public JACKPOT_WINNER = 0;

    uint jackpotMaxCap = 100;

    uint public totalSupply = 0;

    address owner = 0x0;

    modifier isOwner {
        assert(owner == msg.sender);
        _;
    }

    modifier isRunning {
        assert(!stopped);
        _;
    }

    modifier valAddress {
        assert(0x0 != msg.sender);
        _;
    }

    function WorldBetToken() public {
        owner = msg.sender;
        countryIsPlaying[1] = true;
        // Argentina
        countryIsPlaying[2] = true;
        // Australia
        countryIsPlaying[3] = true;
        // Belgium
        countryIsPlaying[4] = true;
        // Brazil
        countryIsPlaying[5] = true;
        // Colombia
        countryIsPlaying[6] = true;
        // Costa Rica
        countryIsPlaying[7] = true;
        // Croatia
        countryIsPlaying[8] = true;
        // Denmark
        countryIsPlaying[9] = true;
        // Egypt
        countryIsPlaying[10] = true;
        // England
        countryIsPlaying[11] = true;
        // France
        countryIsPlaying[12] = true;
        // Germany
        countryIsPlaying[13] = true;
        // Iceland
        countryIsPlaying[14] = true;
        // Iran
        countryIsPlaying[15] = true;
        // Japan
        countryIsPlaying[16] = true;
        // Mexico
        countryIsPlaying[17] = true;
        // Morocco
        countryIsPlaying[18] = true;
        // Nigeria
        countryIsPlaying[19] = true;
        // Panama
        countryIsPlaying[20] = true;
        // Peru
        countryIsPlaying[21] = true;
        // Poland
        countryIsPlaying[22] = true;
        // Portugal
        countryIsPlaying[23] = true;
        // Russia
        countryIsPlaying[24] = true;
        // Saudi Arabia
        countryIsPlaying[25] = true;
        // Senegal
        countryIsPlaying[26] = true;
        // Serbia
        countryIsPlaying[27] = true;
        // South Korea
        countryIsPlaying[28] = true;
        // Spain
        countryIsPlaying[29] = true;
        // Sweden
        countryIsPlaying[30] = true;
        // Switzerland
        countryIsPlaying[31] = true;
        // Tunisia
        countryIsPlaying[32] = true;
        // Uruguay
    }

    function giveBalance(uint country, uint user, uint value) public isRunning returns (bool success) {
        require(countryIsPlaying[country]);
        require(WINNER_COUNTRY_CODE == 0);


        // add user total amount of tickets
        userBalanceOf[user] += value;


        countries[country].push(user);

        users[user].push(Country(user, value));

        if (userBalanceOf[user] >= jackpotMaxCap && !isJackpotEligible[user]) {
            jackpotUsers.push(user);
            jackpotLocation[user] = jackpotUsers.length - 1;
        }

        // increase totalSupply
        totalSupply += value;

        // fire transfer event
        Transfer(0x0, user, value);
        return true;
    }

    function installWinner(uint country) public {
        require(WINNER_COUNTRY_CODE == 0);
        require(countryIsPlaying[country]);
        WINNER_COUNTRY_CODE = country;
        WinnerInstalled(WINNER_COUNTRY_CODE);
    }

    function removeCountry(uint country) public {
        countryIsPlaying[country] = false;
        CountryRemoved(country);
    }

    function playJackpot() public {
        require(JACKPOT_WINNER == 0);
        if (jackpotUsers.length >= 2) {
            uint nonce = jackpotUsers.length;
            uint max = jackpotUsers.length - 1;
            uint randomNumber = uint(keccak256(nonce)) % max;
            JACKPOT_WINNER = jackpotUsers[randomNumber];
        } else {
            JACKPOT_WINNER = jackpotUsers[0];
        }
    }

    function winnerList() view public returns (uint[]){
        return countries[WINNER_COUNTRY_CODE];
    }

    event Transfer(address indexed _from, uint indexed _to, uint _value);
    event CountryRemoved(uint indexed country);
    event WinnerInstalled(uint indexed country);
}