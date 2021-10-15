// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./ContextMixin.sol";
import "./Base64.sol";

contract CryptoFootball2021 is ERC721Enumerable, ContextMixin, ReentrancyGuard, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    address payable public daoAddress;
    address payable public potAddress;

    /// Specifically whitelist an OpenSea proxy registry address.
    address public proxyRegistryAddress;

    struct PlayerMeta {
        uint256 tier;
        uint256 score;
    }

    mapping(string => PlayerMeta) private playerMeta;

    uint256 public teamPrice;
    uint256 public bulkBuyLimit;
    uint256 public maxSupply;
    uint256 public reserveTeams;

    string[] private quarterbacks = [
    "Kyler Murray", "Josh Allen", "Patrick Mahomes II", "Lamar Jackson", "Dak Prescott", "Tom Brady", "Justin Herbert", "Jalen Hurts", "Matthew Stafford", "Aaron Rodgers", "Joe Burrow", "Sam Darnold", "Kirk Cousins", "Derek Carr", "Ryan Tannehill", "Trey Lance", "Trevor Lawrence", "Daniel Jones", "Matt Ryan", "Justin Fields", "Baker Mayfield", "Russell Wilson", "Jameis Winston", "Teddy Bridgewater", "Carson Wentz", "Taylor Heinicke", "Mac Jones", "Ben Roethlisberger", "Tua Tagovailoa", "Jared Goff", "Zach Wilson", "Jimmy Garoppolo", "Geno Smith", "Davis Mills", "Tyrod Taylor"
    ];

    string[] private runningBacks = [
    "Derrick Henry", "Christian McCaffrey", "Alvin Kamara", "Aaron Jones", "Austin Ekeler", "Ezekiel Elliott", "Nick Chubb", "Dalvin Cook", "Najee Harris", "Jonathan Taylor", "Antonio Gibson", "Joe Mixon", "Saquon Barkley", "D'Andre Swift", "Darrell Henderson Jr.", "James Robinson", "Kareem Hunt", "Chris Carson", "Chase Edmonds", "Josh Jacobs", "Damien Harris", "Javonte Williams", "Cordarrelle Patterson", "Leonard Fournette", "Miles Sanders", "Clyde Edwards-Helaire", "Melvin Gordon III", "Tony Pollard", "Elijah Mitchell", "David Montgomery", "Zack Moss", "Myles Gaskin", "Mike Davis", "Jamaal Williams", "Damien Williams", "James Conner", "Latavius Murray", "Alexander Mattison", "Michael Carter", "Trey Sermon", "Kenneth Gainwell", "AJ Dillon", "Chuba Hubbard", "Nyheim Hines", "Darrel Williams", "Devin Singletary", "J.D. McKissic", "Sony Michel", "Ronald Jones II", "Alex Collins", "Devontae Booker", "Samaje Perine", "Ty'Son Williams", "Giovani Bernard", "David Johnson", "Mark Ingram II"
    ];

    string[] private tightEnds = [
    "Travis Kelce", "Darren Waller", "Kyle Pitts", "T.J. Hockenson", "Mark Andrews", "Dawson Knox", "George Kittle", "Tyler Higbee", "Dalton Schultz", "Noah Fant", "Mike Gesicki", "Rob Gronkowski", "Hunter Henry", "Jared Cook", "Dallas Goedert", "Robert Tonyan", "Logan Thomas", "Jonnu Smith", "Zach Ertz", "Evan Engram", "Gerald Everett", "Austin Hooper", "Tyler Conklin", "Cole Kmet", "Dan Arnold", "Pat Freiermuth", "Hayden Hurst", "Adam Trautman", "Blake Jarwin", "Anthony Firkser", "Jack Doyle", "David Njoku", "Mo Alie-Cox", "C.J. Uzomah", "Donald Parham Jr.", "Tommy Tremble", "Eric Ebron", "Cameron Brate", "O.J. Howard", "Juwan Johnson", "Ricky Seals-Jones", "Ian Thomas", "Will Dissly", "Jimmy Graham", "Kyle Rudolph"
    ];

    string[] private wideReceivers = [
    "Davante Adams", "Tyreek Hill", "Stefon Diggs", "Cooper Kupp", "Justin Jefferson", "DeAndre Hopkins", "D.J. Moore", "Mike Williams", "CeeDee Lamb", "D.K. Metcalf", "Terry McLaurin", "Ja'Marr Chase", "Deebo Samuel", "Keenan Allen", "Calvin Ridley", "Amari Cooper", "Chris Godwin", "Mike Evans", "Diontae Johnson", "A.J. Brown", "Tyler Lockett", "Antonio Brown", "Robert Woods", "Adam Thielen", "Tee Higgins", "Marquise Brown", "Courtland Sutton", "Chase Claypool", "DeVonta Smith", "Brandin Cooks", "Julio Jones", "Michael Pittman Jr.", "Tyler Boyd", "Allen Robinson II", "Odell Beckham Jr.", "Marvin Jones Jr.", "Corey Davis", "Kadarius Toney", "Jaylen Waddle", "Emmanuel Sanders", "Laviska Shenault Jr.", "Jakobi Meyers", "Rondale Moore", "Sterling Shepard", "Jerry Jeudy", "Michael Thomas", "Henry Ruggs III", "Darnell Mooney", "Kenny Golladay", "Tim Patrick", "Christian Kirk", "Cole Beasley", "Robby Anderson", "Hunter Renfrow", "DeVante Parker", "Brandon Aiyuk", "Will Fuller V", "Michael Gallup", "A.J. Green", "Jarvis Landry", "Mecole Hardman", "Rashod Bateman", "Curtis Samuel", "Van Jefferson", "Marquez Callaway", "Terrace Marshall Jr.", "Zach Pascal", "Nelson Agholor", "Bryan Edwards", "K.J. Osborn", "Jalen Reagor", "Elijah Moore", "Darius Slayton", "Gabriel Davis", "Jamison Crowder", "DeSean Jackson", "Marquez Valdes-Scantling", "James Washington", "Sammy Watkins", "Randall Cobb", "Kalif Raymond", "Anthony Miller", "Kendrick Bourne", "Tyrell Williams", "Amon-Ra St. Brown", "Quintez Cephus", "Allen Lazard", "Parris Campbell", "Quez Watkins", "Donovan Peoples-Jones", "T.Y. Hilton", "Deonte Harris", "Dyami Brown", "Russell Gage", "Tre'Quan Smith", "Josh Reynolds", "N'Keal Harry", "John Ross", "Rashard Higgins", "Freddie Swain", "Byron Pringle", "Chris Moore", "Josh Gordon", "D.J. Chark Jr."
    ];

    uint256 private flexLength = wideReceivers.length + runningBacks.length + tightEnds.length;

    constructor(address payable _daoAddress, address payable _potAddress, address _proxyRegistryAddress, uint256 _teamPrice, uint256 _bulkBuyLimit, uint256 _maxSupply, uint256 _reserveTeams) ERC721("CryptoFootball2021", "FOOT") {
        daoAddress = _daoAddress;
        potAddress = _potAddress;
        proxyRegistryAddress = _proxyRegistryAddress;
        teamPrice = _teamPrice;
        bulkBuyLimit = _bulkBuyLimit;
        maxSupply = _maxSupply;
        reserveTeams = _reserveTeams;

        playerMeta["Kyler Murray"] = PlayerMeta(1, 246);
        playerMeta["Josh Allen"] = PlayerMeta(1, 241);
        playerMeta["Patrick Mahomes II"] = PlayerMeta(1, 233);
        playerMeta["Lamar Jackson"] = PlayerMeta(1, 229);
        playerMeta["Dak Prescott"] = PlayerMeta(1, 222);
        playerMeta["Tom Brady"] = PlayerMeta(1, 218);
        playerMeta["Justin Herbert"] = PlayerMeta(2, 213);
        playerMeta["Jalen Hurts"] = PlayerMeta(2, 212);
        playerMeta["Matthew Stafford"] = PlayerMeta(2, 210);
        playerMeta["Aaron Rodgers"] = PlayerMeta(2, 200);
        playerMeta["Joe Burrow"] = PlayerMeta(2, 196);
        playerMeta["Sam Darnold"] = PlayerMeta(2, 187);
        playerMeta["Kirk Cousins"] = PlayerMeta(2, 185);
        playerMeta["Derek Carr"] = PlayerMeta(2, 183);
        playerMeta["Ryan Tannehill"] = PlayerMeta(3, 180);
        playerMeta["Trey Lance"] = PlayerMeta(3, 178);
        playerMeta["Trevor Lawrence"] = PlayerMeta(3, 178);
        playerMeta["Daniel Jones"] = PlayerMeta(3, 176);
        playerMeta["Matt Ryan"] = PlayerMeta(3, 174);
        playerMeta["Justin Fields"] = PlayerMeta(3, 174);
        playerMeta["Baker Mayfield"] = PlayerMeta(3, 174);
        playerMeta["Russell Wilson"] = PlayerMeta(3, 173);
        playerMeta["Jameis Winston"] = PlayerMeta(3, 168);
        playerMeta["Teddy Bridgewater"] = PlayerMeta(3, 168);
        playerMeta["Carson Wentz"] = PlayerMeta(3, 166);
        playerMeta["Taylor Heinicke"] = PlayerMeta(3, 165);
        playerMeta["Mac Jones"] = PlayerMeta(3, 162);
        playerMeta["Ben Roethlisberger"] = PlayerMeta(3, 161);
        playerMeta["Tua Tagovailoa"] = PlayerMeta(3, 160);
        playerMeta["Jared Goff"] = PlayerMeta(3, 158);
        playerMeta["Zach Wilson"] = PlayerMeta(3, 151);
        playerMeta["Jimmy Garoppolo"] = PlayerMeta(3, 142);
        playerMeta["Geno Smith"] = PlayerMeta(3, 52);
        playerMeta["Davis Mills"] = PlayerMeta(3, 47);
        playerMeta["Tyrod Taylor"] = PlayerMeta(3, 42);
        playerMeta["Derrick Henry"] = PlayerMeta(1, 216);
        playerMeta["Christian McCaffrey"] = PlayerMeta(1, 192);
        playerMeta["Alvin Kamara"] = PlayerMeta(1, 180);
        playerMeta["Aaron Jones"] = PlayerMeta(1, 176);
        playerMeta["Austin Ekeler"] = PlayerMeta(1, 158);
        playerMeta["Ezekiel Elliott"] = PlayerMeta(1, 157);
        playerMeta["Nick Chubb"] = PlayerMeta(1, 156);
        playerMeta["Dalvin Cook"] = PlayerMeta(1, 156);
        playerMeta["Najee Harris"] = PlayerMeta(2, 152);
        playerMeta["Jonathan Taylor"] = PlayerMeta(2, 151);
        playerMeta["Antonio Gibson"] = PlayerMeta(2, 149);
        playerMeta["Joe Mixon"] = PlayerMeta(2, 148);
        playerMeta["Saquon Barkley"] = PlayerMeta(2, 143);
        playerMeta["D'Andre Swift"] = PlayerMeta(2, 136);
        playerMeta["Darrell Henderson Jr."] = PlayerMeta(2, 134);
        playerMeta["James Robinson"] = PlayerMeta(2, 133);
        playerMeta["Kareem Hunt"] = PlayerMeta(2, 132);
        playerMeta["Chris Carson"] = PlayerMeta(2, 130);
        playerMeta["Chase Edmonds"] = PlayerMeta(2, 130);
        playerMeta["Josh Jacobs"] = PlayerMeta(2, 122);
        playerMeta["Damien Harris"] = PlayerMeta(2, 118);
        playerMeta["Javonte Williams"] = PlayerMeta(2, 115);
        playerMeta["Cordarrelle Patterson"] = PlayerMeta(2, 114);
        playerMeta["Leonard Fournette"] = PlayerMeta(3, 110);
        playerMeta["Miles Sanders"] = PlayerMeta(3, 108);
        playerMeta["Clyde Edwards-Helaire"] = PlayerMeta(3, 104);
        playerMeta["Melvin Gordon III"] = PlayerMeta(3, 100);
        playerMeta["Tony Pollard"] = PlayerMeta(3, 97);
        playerMeta["Elijah Mitchell"] = PlayerMeta(3, 95);
        playerMeta["David Montgomery"] = PlayerMeta(3, 86);
        playerMeta["Zack Moss"] = PlayerMeta(3, 84);
        playerMeta["Myles Gaskin"] = PlayerMeta(3, 84);
        playerMeta["Mike Davis"] = PlayerMeta(3, 83);
        playerMeta["Jamaal Williams"] = PlayerMeta(3, 82);
        playerMeta["Damien Williams"] = PlayerMeta(3, 80);
        playerMeta["James Conner"] = PlayerMeta(3, 79);
        playerMeta["Latavius Murray"] = PlayerMeta(3, 79);
        playerMeta["Alexander Mattison"] = PlayerMeta(3, 78);
        playerMeta["Michael Carter"] = PlayerMeta(3, 75);
        playerMeta["Trey Sermon"] = PlayerMeta(3, 74);
        playerMeta["Kenneth Gainwell"] = PlayerMeta(3, 73);
        playerMeta["AJ Dillon"] = PlayerMeta(3, 73);
        playerMeta["Chuba Hubbard"] = PlayerMeta(3, 71);
        playerMeta["Nyheim Hines"] = PlayerMeta(3, 71);
        playerMeta["Darrel Williams"] = PlayerMeta(3, 71);
        playerMeta["Devin Singletary"] = PlayerMeta(3, 70);
        playerMeta["J.D. McKissic"] = PlayerMeta(3, 66);
        playerMeta["Sony Michel"] = PlayerMeta(3, 63);
        playerMeta["Ronald Jones II"] = PlayerMeta(3, 62);
        playerMeta["Alex Collins"] = PlayerMeta(3, 59);
        playerMeta["Devontae Booker"] = PlayerMeta(3, 58);
        playerMeta["Samaje Perine"] = PlayerMeta(3, 55);
        playerMeta["Ty'Son Williams"] = PlayerMeta(3, 54);
        playerMeta["Giovani Bernard"] = PlayerMeta(3, 53);
        playerMeta["David Johnson"] = PlayerMeta(3, 52);
        playerMeta["Mark Ingram II"] = PlayerMeta(3, 50);
        playerMeta["Davante Adams"] = PlayerMeta(1, 177);
        playerMeta["Tyreek Hill"] = PlayerMeta(1, 174);
        playerMeta["Stefon Diggs"] = PlayerMeta(1, 162);
        playerMeta["Cooper Kupp"] = PlayerMeta(1, 157);
        playerMeta["Justin Jefferson"] = PlayerMeta(1, 154);
        playerMeta["DeAndre Hopkins"] = PlayerMeta(1, 145);
        playerMeta["D.J. Moore"] = PlayerMeta(1, 145);
        playerMeta["Mike Williams"] = PlayerMeta(1, 142);
        playerMeta["CeeDee Lamb"] = PlayerMeta(1, 140);
        playerMeta["D.K. Metcalf"] = PlayerMeta(1, 133);
        playerMeta["Terry McLaurin"] = PlayerMeta(1, 130);
        playerMeta["Ja'Marr Chase"] = PlayerMeta(1, 129);
        playerMeta["Deebo Samuel"] = PlayerMeta(1, 129);
        playerMeta["Keenan Allen"] = PlayerMeta(1, 128);
        playerMeta["Calvin Ridley"] = PlayerMeta(1, 127);
        playerMeta["Amari Cooper"] = PlayerMeta(1, 125);
        playerMeta["Chris Godwin"] = PlayerMeta(1, 124);
        playerMeta["Mike Evans"] = PlayerMeta(1, 123);
        playerMeta["Diontae Johnson"] = PlayerMeta(1, 121);
        playerMeta["A.J. Brown"] = PlayerMeta(1, 120);
        playerMeta["Tyler Lockett"] = PlayerMeta(2, 119);
        playerMeta["Antonio Brown"] = PlayerMeta(2, 115);
        playerMeta["Robert Woods"] = PlayerMeta(2, 115);
        playerMeta["Adam Thielen"] = PlayerMeta(2, 112);
        playerMeta["Tee Higgins"] = PlayerMeta(2, 112);
        playerMeta["Marquise Brown"] = PlayerMeta(2, 109);
        playerMeta["Courtland Sutton"] = PlayerMeta(2, 109);
        playerMeta["Chase Claypool"] = PlayerMeta(2, 108);
        playerMeta["DeVonta Smith"] = PlayerMeta(2, 107);
        playerMeta["Brandin Cooks"] = PlayerMeta(2, 107);
        playerMeta["Julio Jones"] = PlayerMeta(2, 107);
        playerMeta["Michael Pittman Jr."] = PlayerMeta(2, 107);
        playerMeta["Tyler Boyd"] = PlayerMeta(2, 105);
        playerMeta["Allen Robinson II"] = PlayerMeta(2, 104);
        playerMeta["Odell Beckham Jr."] = PlayerMeta(2, 102);
        playerMeta["Marvin Jones Jr."] = PlayerMeta(2, 101);
        playerMeta["Corey Davis"] = PlayerMeta(2, 100);
        playerMeta["Kadarius Toney"] = PlayerMeta(2, 99);
        playerMeta["Jaylen Waddle"] = PlayerMeta(2, 98);
        playerMeta["Emmanuel Sanders"] = PlayerMeta(2, 97);
        playerMeta["Laviska Shenault Jr."] = PlayerMeta(2, 96);
        playerMeta["Jakobi Meyers"] = PlayerMeta(2, 95);
        playerMeta["Rondale Moore"] = PlayerMeta(2, 94);
        playerMeta["Sterling Shepard"] = PlayerMeta(2, 93);
        playerMeta["Jerry Jeudy"] = PlayerMeta(2, 93);
        playerMeta["Michael Thomas"] = PlayerMeta(2, 92);
        playerMeta["Henry Ruggs III"] = PlayerMeta(2, 91);
        playerMeta["Darnell Mooney"] = PlayerMeta(2, 90);
        playerMeta["Kenny Golladay"] = PlayerMeta(2, 87);
        playerMeta["Tim Patrick"] = PlayerMeta(3, 86);
        playerMeta["Christian Kirk"] = PlayerMeta(3, 84);
        playerMeta["Cole Beasley"] = PlayerMeta(3, 84);
        playerMeta["Robby Anderson"] = PlayerMeta(3, 83);
        playerMeta["Hunter Renfrow"] = PlayerMeta(3, 82);
        playerMeta["DeVante Parker"] = PlayerMeta(3, 82);
        playerMeta["Brandon Aiyuk"] = PlayerMeta(3, 81);
        playerMeta["Will Fuller V"] = PlayerMeta(3, 80);
        playerMeta["Michael Gallup"] = PlayerMeta(3, 78);
        playerMeta["A.J. Green"] = PlayerMeta(3, 77);
        playerMeta["Jarvis Landry"] = PlayerMeta(3, 76);
        playerMeta["Mecole Hardman"] = PlayerMeta(3, 76);
        playerMeta["Rashod Bateman"] = PlayerMeta(3, 75);
        playerMeta["Curtis Samuel"] = PlayerMeta(3, 74);
        playerMeta["Van Jefferson"] = PlayerMeta(3, 71);
        playerMeta["Marquez Callaway"] = PlayerMeta(3, 71);
        playerMeta["Terrace Marshall Jr."] = PlayerMeta(3, 71);
        playerMeta["Zach Pascal"] = PlayerMeta(3, 71);
        playerMeta["Nelson Agholor"] = PlayerMeta(3, 71);
        playerMeta["Bryan Edwards"] = PlayerMeta(3, 69);
        playerMeta["K.J. Osborn"] = PlayerMeta(3, 69);
        playerMeta["Jalen Reagor"] = PlayerMeta(3, 68);
        playerMeta["Elijah Moore"] = PlayerMeta(3, 66);
        playerMeta["Darius Slayton"] = PlayerMeta(3, 64);
        playerMeta["Gabriel Davis"] = PlayerMeta(3, 64);
        playerMeta["Jamison Crowder"] = PlayerMeta(3, 62);
        playerMeta["DeSean Jackson"] = PlayerMeta(3, 61);
        playerMeta["Marquez Valdes-Scantling"] = PlayerMeta(3, 61);
        playerMeta["James Washington"] = PlayerMeta(3, 60);
        playerMeta["Sammy Watkins"] = PlayerMeta(3, 60);
        playerMeta["Randall Cobb"] = PlayerMeta(3, 59);
        playerMeta["Kalif Raymond"] = PlayerMeta(3, 58);
        playerMeta["Anthony Miller"] = PlayerMeta(3, 58);
        playerMeta["Kendrick Bourne"] = PlayerMeta(3, 57);
        playerMeta["Tyrell Williams"] = PlayerMeta(3, 57);
        playerMeta["Amon-Ra St. Brown"] = PlayerMeta(3, 55);
        playerMeta["Quintez Cephus"] = PlayerMeta(3, 54);
        playerMeta["Allen Lazard"] = PlayerMeta(3, 53);
        playerMeta["Parris Campbell"] = PlayerMeta(3, 52);
        playerMeta["Quez Watkins"] = PlayerMeta(3, 50);
        playerMeta["Donovan Peoples-Jones"] = PlayerMeta(3, 50);
        playerMeta["T.Y. Hilton"] = PlayerMeta(3, 49);
        playerMeta["Deonte Harris"] = PlayerMeta(3, 49);
        playerMeta["Dyami Brown"] = PlayerMeta(3, 49);
        playerMeta["Russell Gage"] = PlayerMeta(3, 47);
        playerMeta["Tre'Quan Smith"] = PlayerMeta(3, 46);
        playerMeta["Josh Reynolds"] = PlayerMeta(3, 46);
        playerMeta["N'Keal Harry"] = PlayerMeta(3, 46);
        playerMeta["John Ross"] = PlayerMeta(3, 44);
        playerMeta["Rashard Higgins"] = PlayerMeta(3, 42);
        playerMeta["Freddie Swain"] = PlayerMeta(3, 42);
        playerMeta["Byron Pringle"] = PlayerMeta(3, 41);
        playerMeta["Chris Moore"] = PlayerMeta(3, 41);
        playerMeta["Josh Gordon"] = PlayerMeta(3, 41);
        playerMeta["D.J. Chark Jr."] = PlayerMeta(3, 40);
        playerMeta["Travis Kelce"] = PlayerMeta(1, 160);
        playerMeta["Darren Waller"] = PlayerMeta(1, 130);
        playerMeta["Kyle Pitts"] = PlayerMeta(1, 128);
        playerMeta["T.J. Hockenson"] = PlayerMeta(2, 107);
        playerMeta["Mark Andrews"] = PlayerMeta(2, 97);
        playerMeta["Dawson Knox"] = PlayerMeta(2, 95);
        playerMeta["George Kittle"] = PlayerMeta(2, 81);
        playerMeta["Tyler Higbee"] = PlayerMeta(2, 81);
        playerMeta["Dalton Schultz"] = PlayerMeta(2, 80);
        playerMeta["Noah Fant"] = PlayerMeta(2, 78);
        playerMeta["Mike Gesicki"] = PlayerMeta(2, 78);
        playerMeta["Rob Gronkowski"] = PlayerMeta(2, 74);
        playerMeta["Hunter Henry"] = PlayerMeta(2, 72);
        playerMeta["Jared Cook"] = PlayerMeta(2, 69);
        playerMeta["Dallas Goedert"] = PlayerMeta(2, 67);
        playerMeta["Robert Tonyan"] = PlayerMeta(2, 66);
        playerMeta["Logan Thomas"] = PlayerMeta(2, 65);
        playerMeta["Jonnu Smith"] = PlayerMeta(2, 65);
        playerMeta["Zach Ertz"] = PlayerMeta(2, 63);
        playerMeta["Evan Engram"] = PlayerMeta(2, 63);
        playerMeta["Gerald Everett"] = PlayerMeta(3, 61);
        playerMeta["Austin Hooper"] = PlayerMeta(3, 60);
        playerMeta["Tyler Conklin"] = PlayerMeta(3, 58);
        playerMeta["Cole Kmet"] = PlayerMeta(3, 57);
        playerMeta["Dan Arnold"] = PlayerMeta(3, 54);
        playerMeta["Pat Freiermuth"] = PlayerMeta(3, 52);
        playerMeta["Hayden Hurst"] = PlayerMeta(3, 51);
        playerMeta["Adam Trautman"] = PlayerMeta(3, 49);
        playerMeta["Blake Jarwin"] = PlayerMeta(3, 46);
        playerMeta["Anthony Firkser"] = PlayerMeta(3, 46);
        playerMeta["Jack Doyle"] = PlayerMeta(3, 43);
        playerMeta["David Njoku"] = PlayerMeta(3, 41);
        playerMeta["Mo Alie-Cox"] = PlayerMeta(3, 41);
        playerMeta["C.J. Uzomah"] = PlayerMeta(3, 40);
        playerMeta["Donald Parham Jr."] = PlayerMeta(3, 39);
        playerMeta["Tommy Tremble"] = PlayerMeta(3, 38);
        playerMeta["Eric Ebron"] = PlayerMeta(3, 38);
        playerMeta["Cameron Brate"] = PlayerMeta(3, 37);
        playerMeta["O.J. Howard"] = PlayerMeta(3, 36);
        playerMeta["Juwan Johnson"] = PlayerMeta(3, 35);
        playerMeta["Ricky Seals-Jones"] = PlayerMeta(3, 35);
        playerMeta["Ian Thomas"] = PlayerMeta(3, 34);
        playerMeta["Will Dissly"] = PlayerMeta(3, 32);
        playerMeta["Jimmy Graham"] = PlayerMeta(3, 32);
        playerMeta["Kyle Rudolph"] = PlayerMeta(3, 31);

        _mintReserveTeams();
    }

    // Mint reserve teams with tokenIds after the publicly available tokenIds
    function _mintReserveTeams() internal {
        for (uint256 i = maxSupply + 1; i < maxSupply + reserveTeams + 1; i++) {
            _safeMint(potAddress, i);
        }
    }

    function mintTeam(uint256 numberOfTeams) external payable nonReentrant {
        require(numberOfTeams <= bulkBuyLimit, "Cannot buy more than the preset limit at a time");
        require((_tokenIds.current() + numberOfTeams) <= maxSupply, "Sold out!");

        uint256 purchasePrice = teamPrice * numberOfTeams;
        require(purchasePrice <= msg.value, "Not enough funds sent for this purchase");

        uint256 daoAmount = purchasePrice / 5;
        uint256 potAmount = daoAmount * 4;

        (bool transferStatus, ) = daoAddress.call{value: daoAmount}("");
        require(transferStatus, "Unable to send dao amount, recipient may have reverted");

        (transferStatus, ) = potAddress.call{value: potAmount}("");
        require(transferStatus, "Unable to send pot amount, recipient may have reverted");

        uint256 excessAmount = msg.value - purchasePrice;
        if (excessAmount > 0) {
            (bool returnExcessStatus, ) = _msgSender().call{value: excessAmount}("");
            require(returnExcessStatus, "Failed to return excess.");
        }

        for (uint256 i = 0; i < numberOfTeams; i++) {
            _tokenIds.increment();
            _safeMint(_msgSender(), _tokenIds.current());
        }
    }

    function random(string memory input) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }

    function getQuarterback(uint256 tokenId) internal view returns (uint256) {
        return pluckPlayer(tokenId, "QUARTERBACK", quarterbacks.length);
    }

    function getWideReceiver(uint256 tokenId, uint256 position) internal view returns (uint256) {
        return pluckPlayer(tokenId, string(abi.encodePacked("WIDERECEIVER", toString(position))), wideReceivers.length);
    }

    function getRunningBack(uint256 tokenId, uint256 position) internal view returns (uint256) {
        return pluckPlayer(tokenId, string(abi.encodePacked("RUNNINGBACK", toString(position))), runningBacks.length);
    }

    function getTightEnd(uint256 tokenId, uint256 position) internal view returns (uint256) {
        return pluckPlayer(tokenId, string(abi.encodePacked("TIGHTEND", toString(position))), tightEnds.length);
    }

    function getFlex(uint256 tokenId, uint256 position) internal view returns (uint256) {
        return pluckPlayer(tokenId, string(abi.encodePacked("FLEX", toString(position))), flexLength);
    }

    function pluckPlayer(uint256 tokenId, string memory keyPrefix, uint256 numPlayers) internal pure returns (uint256) {
        uint256 rand = random(string(abi.encodePacked(keyPrefix, toString(tokenId))));
        return rand % numPlayers;
    }

    function tokenURI(uint256 tokenId) override public view returns (string memory) {
        string memory token = toString(tokenId);

        uint256[8] memory players;
        players[0] = getQuarterback(tokenId);
        players[1] = getWideReceiver(tokenId, 0);
        players[2] = getWideReceiver(tokenId, 1);
        for (uint256 i = 2; players[2] == players[1]; i++) {
            players[2] = getWideReceiver(tokenId, i);
        }
        players[3] = getRunningBack(tokenId, 0);
        players[4] = getRunningBack(tokenId, 1);
        for (uint256 i = 2; players[4] == players[3]; i++) {
            players[4] = getRunningBack(tokenId, i);
        }
        players[5] = getTightEnd(tokenId, 0);

        // 2nd WR needs to not be the same as the first
        // 2nd RB needs to not be the same as the first
        // first flex needs to not be the same as 2 WRs, 2 RBs, 1 TE
        // second flex needs to not be the same as the prior

        uint256 score = 0;
        uint256[3] memory tiers; // = [uint256(0), uint256(0), uint256(0)];
        string[13] memory attParts;
        string[19] memory parts;
        parts[0] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style>.base { fill: white; font-family: monospace; font-size: 14px; }</style><rect width="100%" height="100%" fill="black" /><text x="10" y="20" class="base" font-size="larger" font-weight="bold">';
        parts[1] = string(abi.encodePacked('Team #', token));
        parts[2] = '</text><text x="10" y="40" class="base">';
        parts[3] = quarterbacks[players[0]];
        score = score + playerMeta[parts[3]].score;
        tiers[playerMeta[parts[3]].tier - 1] = tiers[playerMeta[parts[3]].tier - 1] + 1;
        attParts[4] = string(abi.encodePacked('{"trait_type": "QB", "value": "', parts[3], '"}, '));

        parts[4] = '</text><text x="10" y="60" class="base">';
        parts[5] = wideReceivers[players[1]];
        score = score + playerMeta[parts[5]].score;
        tiers[playerMeta[parts[5]].tier - 1] = tiers[playerMeta[parts[5]].tier - 1] + 1;
        attParts[5] = string(abi.encodePacked('{"trait_type": "WR", "value": "', parts[5], '"}, '));

        parts[6] = '</text><text x="10" y="80" class="base">';
        parts[7] = wideReceivers[players[2]];
        score = score + playerMeta[parts[7]].score;
        tiers[playerMeta[parts[7]].tier - 1] = tiers[playerMeta[parts[7]].tier - 1] + 1;
        attParts[6] = string(abi.encodePacked('{"trait_type": "WR", "value": "', parts[7], '"}, '));

        parts[8] = '</text><text x="10" y="100" class="base">';
        parts[9] = runningBacks[players[3]];
        score = score + playerMeta[parts[9]].score;
        tiers[playerMeta[parts[9]].tier - 1] = tiers[playerMeta[parts[9]].tier - 1] + 1;
        attParts[7] = string(abi.encodePacked('{"trait_type": "RB", "value": "', parts[9], '"}, '));

        parts[10] = '</text><text x="10" y="120" class="base">';
        parts[11] = runningBacks[players[4]];
        score = score + playerMeta[parts[11]].score;
        tiers[playerMeta[parts[11]].tier - 1] = tiers[playerMeta[parts[11]].tier - 1] + 1;
        attParts[8] = string(abi.encodePacked('{"trait_type": "RB", "value": "', parts[11], '"}, '));

        parts[12] = '</text><text x="10" y="140" class="base">';
        parts[13] = tightEnds[players[5]];
        score = score + playerMeta[parts[13]].score;
        tiers[playerMeta[parts[13]].tier - 1] = tiers[playerMeta[parts[13]].tier - 1] + 1;
        attParts[9] = string(abi.encodePacked('{"trait_type": "TE", "value": "', parts[13], '"}, '));
        parts[14] = '</text><text x="10" y="160" class="base">';

        uint256 flex1 = getFlex(tokenId, 0);
        string memory traitType1;
        if (0 <= flex1 && flex1 < wideReceivers.length) {
            traitType1 = "WR";
            for (uint256 i = 2; flex1 == players[1] || flex1 == players[2]; i++) {
                flex1 = getWideReceiver(tokenId, i);
            }
            parts[15] = wideReceivers[flex1];
        } else if (wideReceivers.length <= flex1 && flex1 < wideReceivers.length + runningBacks.length) {
            traitType1 = "RB";
            flex1 = flex1 - wideReceivers.length;
            for (uint256 i = 2; flex1 == players[3] || flex1 == players[4]; i++) {
                flex1 = getRunningBack(tokenId, i);
            }
            parts[15] = runningBacks[flex1];
        } else {
            traitType1 = "TE";
            flex1 = flex1 - (wideReceivers.length + runningBacks.length);
            for (uint256 i = 2; flex1 == players[5]; i++) {
                flex1 = getTightEnd(tokenId, i);
            }
            parts[15] = tightEnds[flex1];
        }
        score = score + playerMeta[parts[15]].score;
        tiers[playerMeta[parts[15]].tier - 1] = tiers[playerMeta[parts[15]].tier - 1] + 1;
        attParts[10] = string(abi.encodePacked('{"trait_type": "', traitType1, '", "value": "', parts[15], '"}, '));

        parts[16] = '</text><text x="10" y="180" class="base">';
        uint256 flex2 = getFlex(tokenId, 0);
        string memory traitType2;
        if (0 <= flex2 && flex2 < wideReceivers.length) {
            traitType2 = "WR";
            for (uint256 i = 2; flex2 == players[1] || flex2 == players[2] || flex2 == flex1; i++) {
                flex2 = getWideReceiver(tokenId, i);
            }
            parts[17] = wideReceivers[flex2];
        } else if (wideReceivers.length <= flex2 && flex2 < wideReceivers.length + runningBacks.length) {
            flex2 = flex2 - wideReceivers.length;
            traitType2 = "RB";
            for (uint256 i = 2; flex2 == players[3] || flex2 == players[4] || flex2 == flex1; i++) {
                flex2 = getRunningBack(tokenId, i);
            }
            parts[17] = runningBacks[flex2];
        } else {
            traitType2 = "TE";
            flex2 = flex2 - (wideReceivers.length + runningBacks.length);
            for (uint256 i = 2; flex2 == players[5] || flex2 == flex1; i++) {
                flex2 = getTightEnd(tokenId, i);
            }
            parts[17] = tightEnds[flex2];
        }
        score = score + playerMeta[parts[17]].score;
        tiers[playerMeta[parts[17]].tier - 1] = tiers[playerMeta[parts[17]].tier - 1] + 1;
        attParts[11] = string(abi.encodePacked('{"trait_type": "', traitType2, '", "value": "', parts[17], '"}, '));
        parts[18] = '</text></svg>';

        string memory output = string(abi.encodePacked(parts[0], parts[1],parts[2], parts[3], parts[4]));
        output = string(abi.encodePacked(output, parts[5], parts[6], parts[7], parts[8], parts[9]));
        output = string(abi.encodePacked(output, parts[10], parts[11], parts[12], parts[13], parts[14]));
        output = string(abi.encodePacked(output, parts[15], parts[16], parts[17], parts[18]));

        // We are disregarding Draft Grade for this release
        attParts[0] = string(abi.encodePacked('{"display_type": "boost_percentage", "trait_type": "Draft Grade: B", "value": ', toString(players[1] * 7 % 101), '}, '));
        attParts[12] = string(abi.encodePacked('{"trait_type": "score", "value": ', toString(score), '}'));

        attParts[1] = string(abi.encodePacked('{"trait_type": "T1", "value": ', toString(tiers[0]), '}, '));
        attParts[2] = string(abi.encodePacked('{"trait_type": "T2", "value": ', toString(tiers[1]), '}, '));
        attParts[3] = string(abi.encodePacked('{"trait_type": "T3", "value": ', toString(tiers[2]), '}, '));

        string memory attributes = string(abi.encodePacked(attParts[1], attParts[2], attParts[3], attParts[4]));
        attributes = string(abi.encodePacked(attributes, attParts[5], attParts[6], attParts[7], attParts[8], attParts[9]));
        attributes = string(abi.encodePacked(attributes, attParts[10], attParts[11], attParts[12]));

        string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "Team #', token, '", "attributes": [', attributes, '], "description": "Fantasy Football meets NFTs. By minting a Team you get an NFT that will have a random collection of 1 QB, 3 RBs, 3 WRs and 1 TE. Every week the top 5 and bottom 5 scorers (no losers in this league!) will be airdropped a prize.", "image": "data:image/svg+xml;base64,', Base64.encode(bytes(output)), '"}'))));
        output = string(abi.encodePacked('data:application/json;base64,', json));

        return output;
    }

    /**
     * Override isApprovedForAll to auto-approve OpenSea's proxy contract
     */
    function isApprovedForAll(address _owner, address _operator) public override view returns (bool isOperator) {
        // Whitelist OpenSea proxy contract for easy trading.
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(_owner)) == _operator) {
            return true;
        }

        // Otherwise, use the default ERC721.isApprovedForAll()
        return ERC721.isApprovedForAll(_owner, _operator);
    }

    /**
     * This is used instead of msg.sender as transactions won't be sent by the original token owner, but by OpenSea.
     * https://docs.opensea.io/docs/polygon-basic-integration
     */
    function _msgSender() internal override view returns (address sender) {
        return ContextMixin.msgSender();
    }

    /**
     * https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Strings.sol
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT license
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "./IERC721Enumerable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

/**
 * For gasless transactions on OpenSea
 * https://github.com/ProjectOpenSea/opensea-creatures/blob/master/contracts/common/meta-transactions/ContentMixin.sol
 */
abstract contract ContextMixin {
    function msgSender() internal view returns (address payable sender) {
        if (msg.sender == address(this)) {
            bytes memory array = msg.data;
            uint256 index = msg.data.length;
            assembly {
                // Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
                sender := and(
                mload(add(array, index)),
                0xffffffffffffffffffffffffffffffffffffffff
                )
            }
        } else {
            sender = payable(msg.sender);
        }
        return sender;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// [MIT License]
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <[email protected]>
library Base64 {
    bytes internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /// @notice Encodes some bytes to the base64 representation
    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((len + 2) / 3);

        // Add some extra buffer at the end
        bytes memory result = new bytes(encodedLen + 32);

        bytes memory table = TABLE;

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)

            for {
                let i := 0
            } lt(i, len) {

            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)

                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(input, 0x3F))), 0xFF))
                out := shl(224, out)

                mstore(resultPtr, out)

                resultPtr := add(resultPtr, 4)
            }

            switch mod(len, 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }

            mstore(result, encodedLen)
        }

        return string(result);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}