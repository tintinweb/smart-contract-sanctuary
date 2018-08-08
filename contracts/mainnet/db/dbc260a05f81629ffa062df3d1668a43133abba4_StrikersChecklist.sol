pragma solidity ^0.4.21;


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
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
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}






/// @title The contract that manages all the players that appear in our game.
/// @author The CryptoStrikers Team
contract StrikersPlayerList is Ownable {
  // We only use playerIds in StrikersChecklist.sol (to
  // indicate which player features on instances of a
  // given ChecklistItem), and nowhere else in the app.
  // While it&#39;s not explictly necessary for any of our
  // contracts to know that playerId 0 corresponds to
  // Lionel Messi, we think that it&#39;s nice to have
  // a canonical source of truth for who the playerIds
  // actually refer to. Storing strings (player names)
  // is expensive, so we just use Events to prove that,
  // at some point, we said a playerId represents a given person.

  /// @dev The event we fire when we add a player.
  event PlayerAdded(uint8 indexed id, string name);

  /// @dev How many players we&#39;ve added so far
  ///   (max 255, though we don&#39;t plan on getting close)
  uint8 public playerCount;

  /// @dev Here we add the players we are launching with on Day 1.
  ///   Players are loosely ranked by things like FIFA ratings,
  ///   number of Instagram followers, and opinions of CryptoStrikers
  ///   team members. Feel free to yell at us on Twitter.
  constructor() public {
    addPlayer("Lionel Messi"); // 0
    addPlayer("Cristiano Ronaldo"); // 1
    addPlayer("Neymar"); // 2
    addPlayer("Mohamed Salah"); // 3
    addPlayer("Robert Lewandowski"); // 4
    addPlayer("Kevin De Bruyne"); // 5
    addPlayer("Luka Modrić"); // 6
    addPlayer("Eden Hazard"); // 7
    addPlayer("Sergio Ramos"); // 8
    addPlayer("Toni Kroos"); // 9
    addPlayer("Luis Su&#225;rez"); // 10
    addPlayer("Harry Kane"); // 11
    addPlayer("Sergio Ag&#252;ero"); // 12
    addPlayer("Kylian Mbapp&#233;"); // 13
    addPlayer("Gonzalo Higua&#237;n"); // 14
    addPlayer("David de Gea"); // 15
    addPlayer("Antoine Griezmann"); // 16
    addPlayer("N&#39;Golo Kant&#233;"); // 17
    addPlayer("Edinson Cavani"); // 18
    addPlayer("Paul Pogba"); // 19
    addPlayer("Isco"); // 20
    addPlayer("Marcelo"); // 21
    addPlayer("Manuel Neuer"); // 22
    addPlayer("Dries Mertens"); // 23
    addPlayer("James Rodr&#237;guez"); // 24
    addPlayer("Paulo Dybala"); // 25
    addPlayer("Christian Eriksen"); // 26
    addPlayer("David Silva"); // 27
    addPlayer("Gabriel Jesus"); // 28
    addPlayer("Thiago"); // 29
    addPlayer("Thibaut Courtois"); // 30
    addPlayer("Philippe Coutinho"); // 31
    addPlayer("Andr&#233;s Iniesta"); // 32
    addPlayer("Casemiro"); // 33
    addPlayer("Romelu Lukaku"); // 34
    addPlayer("Gerard Piqu&#233;"); // 35
    addPlayer("Mats Hummels"); // 36
    addPlayer("Diego God&#237;n"); // 37
    addPlayer("Mesut &#214;zil"); // 38
    addPlayer("Son Heung-min"); // 39
    addPlayer("Raheem Sterling"); // 40
    addPlayer("Hugo Lloris"); // 41
    addPlayer("Radamel Falcao"); // 42
    addPlayer("Ivan Rakitić"); // 43
    addPlayer("Leroy San&#233;"); // 44
    addPlayer("Roberto Firmino"); // 45
    addPlayer("Sadio Man&#233;"); // 46
    addPlayer("Thomas M&#252;ller"); // 47
    addPlayer("Dele Alli"); // 48
    addPlayer("Keylor Navas"); // 49
    addPlayer("Thiago Silva"); // 50
    addPlayer("Rapha&#235;l Varane"); // 51
    addPlayer("&#193;ngel Di Mar&#237;a"); // 52
    addPlayer("Jordi Alba"); // 53
    addPlayer("Medhi Benatia"); // 54
    addPlayer("Timo Werner"); // 55
    addPlayer("Gylfi Sigur&#240;sson"); // 56
    addPlayer("Nemanja Matić"); // 57
    addPlayer("Kalidou Koulibaly"); // 58
    addPlayer("Bernardo Silva"); // 59
    addPlayer("Vincent Kompany"); // 60
    addPlayer("Jo&#227;o Moutinho"); // 61
    addPlayer("Toby Alderweireld"); // 62
    addPlayer("Emil Forsberg"); // 63
    addPlayer("Mario Mandžukić"); // 64
    addPlayer("Sergej Milinković-Savić"); // 65
    addPlayer("Shinji Kagawa"); // 66
    addPlayer("Granit Xhaka"); // 67
    addPlayer("Andreas Christensen"); // 68
    addPlayer("Piotr Zieliński"); // 69
    addPlayer("Fyodor Smolov"); // 70
    addPlayer("Xherdan Shaqiri"); // 71
    addPlayer("Marcus Rashford"); // 72
    addPlayer("Javier Hern&#225;ndez"); // 73
    addPlayer("Hirving Lozano"); // 74
    addPlayer("Hakim Ziyech"); // 75
    addPlayer("Victor Moses"); // 76
    addPlayer("Jefferson Farf&#225;n"); // 77
    addPlayer("Mohamed Elneny"); // 78
    addPlayer("Marcus Berg"); // 79
    addPlayer("Guillermo Ochoa"); // 80
    addPlayer("Igor Akinfeev"); // 81
    addPlayer("Sardar Azmoun"); // 82
    addPlayer("Christian Cueva"); // 83
    addPlayer("Wahbi Khazri"); // 84
    addPlayer("Keisuke Honda"); // 85
    addPlayer("Tim Cahill"); // 86
    addPlayer("John Obi Mikel"); // 87
    addPlayer("Ki Sung-yueng"); // 88
    addPlayer("Bryan Ruiz"); // 89
    addPlayer("Maya Yoshida"); // 90
    addPlayer("Nawaf Al Abed"); // 91
    addPlayer("Lee Chung-yong"); // 92
    addPlayer("Gabriel G&#243;mez"); // 93
    addPlayer("Na&#239;m Sliti"); // 94
    addPlayer("Reza Ghoochannejhad"); // 95
    addPlayer("Mile Jedinak"); // 96
    addPlayer("Mohammad Al-Sahlawi"); // 97
    addPlayer("Aron Gunnarsson"); // 98
    addPlayer("Blas P&#233;rez"); // 99
    addPlayer("Dani Alves"); // 100
    addPlayer("Zlatan Ibrahimović"); // 101
  }

  /// @dev Fires an event, proving that we said a player corresponds to a given ID.
  /// @param _name The name of the player we are adding.
  function addPlayer(string _name) public onlyOwner {
    require(playerCount < 255, "You&#39;ve already added the maximum amount of players.");
    emit PlayerAdded(playerCount, _name);
    playerCount++;
  }
}


/// @title The contract that manages checklist items, sets, and rarity tiers.
/// @author The CryptoStrikers Team
contract StrikersChecklist is StrikersPlayerList {
  // High level overview of everything going on in this contract:
  //
  // ChecklistItem is the parent class to Card and has 3 properties:
  //  - uint8 checklistId (000 to 255)
  //  - uint8 playerId (see StrikersPlayerList.sol)
  //  - RarityTier tier (more info below)
  //
  // Two things to note: the checklistId is not explicitly stored
  // on the checklistItem struct, and it&#39;s composed of two parts.
  // (For the following, assume it is left padded with zeros to reach
  // three digits, such that checklistId 0 becomes 000)
  //  - the first digit represents the setId
  //      * 0 = Originals Set
  //      * 1 = Iconics Set
  //      * 2 = Unreleased Set
  //  - the last two digits represent its index in the appropriate set arary
  //
  //  For example, checklist ID 100 would represent fhe first checklist item
  //  in the iconicChecklistItems array (first digit = 1 = Iconics Set, last two
  //  digits = 00 = first index of array)
  //
  // Because checklistId is represented as a uint8 throughout the app, the highest
  // value it can take is 255, which means we can&#39;t add more than 56 items to our
  // Unreleased Set&#39;s unreleasedChecklistItems array (setId 2). Also, once we&#39;ve initialized
  // this contract, it&#39;s impossible for us to add more checklist items to the Originals
  // and Iconics set -- what you see here is what you get.
  //
  // Simple enough right?

  /// @dev We initialize this contract with so much data that we have
  ///   to stage it in 4 different steps, ~33 checklist items at a time.
  enum DeployStep {
    WaitingForStepOne,
    WaitingForStepTwo,
    WaitingForStepThree,
    WaitingForStepFour,
    DoneInitialDeploy
  }

  /// @dev Enum containing all our rarity tiers, just because
  ///   it&#39;s cleaner dealing with these values than with uint8s.
  enum RarityTier {
    IconicReferral,
    IconicInsert,
    Diamond,
    Gold,
    Silver,
    Bronze
  }

  /// @dev A lookup table indicating how limited the cards
  ///   in each tier are. If this value is 0, it means
  ///   that cards of this rarity tier are unlimited,
  ///   which is only the case for the 8 Iconics cards
  ///   we give away as part of our referral program.
  uint16[] public tierLimits = [
    0,    // Iconic - Referral Bonus (uncapped)
    100,  // Iconic Inserts ("Card of the Day")
    1000, // Diamond
    1664, // Gold
    3328, // Silver
    4352  // Bronze
  ];

  /// @dev ChecklistItem is essentially the parent class to Card.
  ///   It represents a given superclass of cards (eg Originals Messi),
  ///   and then each Card is an instance of this ChecklistItem, with
  ///   its own serial number, mint date, etc.
  struct ChecklistItem {
    uint8 playerId;
    RarityTier tier;
  }

  /// @dev The deploy step we&#39;re at. Defaults to WaitingForStepOne.
  DeployStep public deployStep;

  /// @dev Array containing all the Originals checklist items (000 - 099)
  ChecklistItem[] public originalChecklistItems;

  /// @dev Array containing all the Iconics checklist items (100 - 131)
  ChecklistItem[] public iconicChecklistItems;

  /// @dev Array containing all the unreleased checklist items (200 - 255 max)
  ChecklistItem[] public unreleasedChecklistItems;

  /// @dev Internal function to add a checklist item to the Originals set.
  /// @param _playerId The player represented by this checklist item. (see StrikersPlayerList.sol)
  /// @param _tier This checklist item&#39;s rarity tier. (see Rarity Tier enum and corresponding tierLimits)
  function _addOriginalChecklistItem(uint8 _playerId, RarityTier _tier) internal {
    originalChecklistItems.push(ChecklistItem({
      playerId: _playerId,
      tier: _tier
    }));
  }

  /// @dev Internal function to add a checklist item to the Iconics set.
  /// @param _playerId The player represented by this checklist item. (see StrikersPlayerList.sol)
  /// @param _tier This checklist item&#39;s rarity tier. (see Rarity Tier enum and corresponding tierLimits)
  function _addIconicChecklistItem(uint8 _playerId, RarityTier _tier) internal {
    iconicChecklistItems.push(ChecklistItem({
      playerId: _playerId,
      tier: _tier
    }));
  }

  /// @dev External function to add a checklist item to our mystery set.
  ///   Must have completed initial deploy, and can&#39;t add more than 56 items (because checklistId is a uint8).
  /// @param _playerId The player represented by this checklist item. (see StrikersPlayerList.sol)
  /// @param _tier This checklist item&#39;s rarity tier. (see Rarity Tier enum and corresponding tierLimits)
  function addUnreleasedChecklistItem(uint8 _playerId, RarityTier _tier) external onlyOwner {
    require(deployStep == DeployStep.DoneInitialDeploy, "Finish deploying the Originals and Iconics sets first.");
    require(unreleasedCount() < 56, "You can&#39;t add any more checklist items.");
    require(_playerId < playerCount, "This player doesn&#39;t exist in our player list.");
    unreleasedChecklistItems.push(ChecklistItem({
      playerId: _playerId,
      tier: _tier
    }));
  }

  /// @dev Returns how many Original checklist items we&#39;ve added.
  function originalsCount() external view returns (uint256) {
    return originalChecklistItems.length;
  }

  /// @dev Returns how many Iconic checklist items we&#39;ve added.
  function iconicsCount() public view returns (uint256) {
    return iconicChecklistItems.length;
  }

  /// @dev Returns how many Unreleased checklist items we&#39;ve added.
  function unreleasedCount() public view returns (uint256) {
    return unreleasedChecklistItems.length;
  }

  // In the next four functions, we initialize this contract with our
  // 132 initial checklist items (100 Originals, 32 Iconics). Because
  // of how much data we need to store, it has to be broken up into
  // four different function calls, which need to be called in sequence.
  // The ordering of the checklist items we add determines their
  // checklist ID, which is left-padded in our frontend to be a
  // 3-digit identifier where the first digit is the setId and the last
  // 2 digits represents the checklist items index in the appropriate ___ChecklistItems array.
  // For example, Originals Messi is the first item for set ID 0, and this
  // is displayed as #000 throughout the app. Our Card struct declare its
  // checklistId property as uint8, so we have
  // to be mindful that we can only have 256 total checklist items.

  /// @dev Deploys Originals #000 through #032.
  function deployStepOne() external onlyOwner {
    require(deployStep == DeployStep.WaitingForStepOne, "You&#39;re not following the steps in order...");

    /* ORIGINALS - DIAMOND */
    _addOriginalChecklistItem(0, RarityTier.Diamond); // 000 Messi
    _addOriginalChecklistItem(1, RarityTier.Diamond); // 001 Ronaldo
    _addOriginalChecklistItem(2, RarityTier.Diamond); // 002 Neymar
    _addOriginalChecklistItem(3, RarityTier.Diamond); // 003 Salah

    /* ORIGINALS - GOLD */
    _addOriginalChecklistItem(4, RarityTier.Gold); // 004 Lewandowski
    _addOriginalChecklistItem(5, RarityTier.Gold); // 005 De Bruyne
    _addOriginalChecklistItem(6, RarityTier.Gold); // 006 Modrić
    _addOriginalChecklistItem(7, RarityTier.Gold); // 007 Hazard
    _addOriginalChecklistItem(8, RarityTier.Gold); // 008 Ramos
    _addOriginalChecklistItem(9, RarityTier.Gold); // 009 Kroos
    _addOriginalChecklistItem(10, RarityTier.Gold); // 010 Su&#225;rez
    _addOriginalChecklistItem(11, RarityTier.Gold); // 011 Kane
    _addOriginalChecklistItem(12, RarityTier.Gold); // 012 Ag&#252;ero
    _addOriginalChecklistItem(13, RarityTier.Gold); // 013 Mbapp&#233;
    _addOriginalChecklistItem(14, RarityTier.Gold); // 014 Higua&#237;n
    _addOriginalChecklistItem(15, RarityTier.Gold); // 015 de Gea
    _addOriginalChecklistItem(16, RarityTier.Gold); // 016 Griezmann
    _addOriginalChecklistItem(17, RarityTier.Gold); // 017 Kant&#233;
    _addOriginalChecklistItem(18, RarityTier.Gold); // 018 Cavani
    _addOriginalChecklistItem(19, RarityTier.Gold); // 019 Pogba

    /* ORIGINALS - SILVER (020 to 032) */
    _addOriginalChecklistItem(20, RarityTier.Silver); // 020 Isco
    _addOriginalChecklistItem(21, RarityTier.Silver); // 021 Marcelo
    _addOriginalChecklistItem(22, RarityTier.Silver); // 022 Neuer
    _addOriginalChecklistItem(23, RarityTier.Silver); // 023 Mertens
    _addOriginalChecklistItem(24, RarityTier.Silver); // 024 James
    _addOriginalChecklistItem(25, RarityTier.Silver); // 025 Dybala
    _addOriginalChecklistItem(26, RarityTier.Silver); // 026 Eriksen
    _addOriginalChecklistItem(27, RarityTier.Silver); // 027 David Silva
    _addOriginalChecklistItem(28, RarityTier.Silver); // 028 Gabriel Jesus
    _addOriginalChecklistItem(29, RarityTier.Silver); // 029 Thiago
    _addOriginalChecklistItem(30, RarityTier.Silver); // 030 Courtois
    _addOriginalChecklistItem(31, RarityTier.Silver); // 031 Coutinho
    _addOriginalChecklistItem(32, RarityTier.Silver); // 032 Iniesta

    // Move to the next deploy step.
    deployStep = DeployStep.WaitingForStepTwo;
  }

  /// @dev Deploys Originals #033 through #065.
  function deployStepTwo() external onlyOwner {
    require(deployStep == DeployStep.WaitingForStepTwo, "You&#39;re not following the steps in order...");

    /* ORIGINALS - SILVER (033 to 049) */
    _addOriginalChecklistItem(33, RarityTier.Silver); // 033 Casemiro
    _addOriginalChecklistItem(34, RarityTier.Silver); // 034 Lukaku
    _addOriginalChecklistItem(35, RarityTier.Silver); // 035 Piqu&#233;
    _addOriginalChecklistItem(36, RarityTier.Silver); // 036 Hummels
    _addOriginalChecklistItem(37, RarityTier.Silver); // 037 God&#237;n
    _addOriginalChecklistItem(38, RarityTier.Silver); // 038 &#214;zil
    _addOriginalChecklistItem(39, RarityTier.Silver); // 039 Son
    _addOriginalChecklistItem(40, RarityTier.Silver); // 040 Sterling
    _addOriginalChecklistItem(41, RarityTier.Silver); // 041 Lloris
    _addOriginalChecklistItem(42, RarityTier.Silver); // 042 Falcao
    _addOriginalChecklistItem(43, RarityTier.Silver); // 043 Rakitić
    _addOriginalChecklistItem(44, RarityTier.Silver); // 044 San&#233;
    _addOriginalChecklistItem(45, RarityTier.Silver); // 045 Firmino
    _addOriginalChecklistItem(46, RarityTier.Silver); // 046 Man&#233;
    _addOriginalChecklistItem(47, RarityTier.Silver); // 047 M&#252;ller
    _addOriginalChecklistItem(48, RarityTier.Silver); // 048 Alli
    _addOriginalChecklistItem(49, RarityTier.Silver); // 049 Navas

    /* ORIGINALS - BRONZE (050 to 065) */
    _addOriginalChecklistItem(50, RarityTier.Bronze); // 050 Thiago Silva
    _addOriginalChecklistItem(51, RarityTier.Bronze); // 051 Varane
    _addOriginalChecklistItem(52, RarityTier.Bronze); // 052 Di Mar&#237;a
    _addOriginalChecklistItem(53, RarityTier.Bronze); // 053 Alba
    _addOriginalChecklistItem(54, RarityTier.Bronze); // 054 Benatia
    _addOriginalChecklistItem(55, RarityTier.Bronze); // 055 Werner
    _addOriginalChecklistItem(56, RarityTier.Bronze); // 056 Sigur&#240;sson
    _addOriginalChecklistItem(57, RarityTier.Bronze); // 057 Matić
    _addOriginalChecklistItem(58, RarityTier.Bronze); // 058 Koulibaly
    _addOriginalChecklistItem(59, RarityTier.Bronze); // 059 Bernardo Silva
    _addOriginalChecklistItem(60, RarityTier.Bronze); // 060 Kompany
    _addOriginalChecklistItem(61, RarityTier.Bronze); // 061 Moutinho
    _addOriginalChecklistItem(62, RarityTier.Bronze); // 062 Alderweireld
    _addOriginalChecklistItem(63, RarityTier.Bronze); // 063 Forsberg
    _addOriginalChecklistItem(64, RarityTier.Bronze); // 064 Mandžukić
    _addOriginalChecklistItem(65, RarityTier.Bronze); // 065 Milinković-Savić

    // Move to the next deploy step.
    deployStep = DeployStep.WaitingForStepThree;
  }

  /// @dev Deploys Originals #066 through #099.
  function deployStepThree() external onlyOwner {
    require(deployStep == DeployStep.WaitingForStepThree, "You&#39;re not following the steps in order...");

    /* ORIGINALS - BRONZE (066 to 099) */
    _addOriginalChecklistItem(66, RarityTier.Bronze); // 066 Kagawa
    _addOriginalChecklistItem(67, RarityTier.Bronze); // 067 Xhaka
    _addOriginalChecklistItem(68, RarityTier.Bronze); // 068 Christensen
    _addOriginalChecklistItem(69, RarityTier.Bronze); // 069 Zieliński
    _addOriginalChecklistItem(70, RarityTier.Bronze); // 070 Smolov
    _addOriginalChecklistItem(71, RarityTier.Bronze); // 071 Shaqiri
    _addOriginalChecklistItem(72, RarityTier.Bronze); // 072 Rashford
    _addOriginalChecklistItem(73, RarityTier.Bronze); // 073 Hern&#225;ndez
    _addOriginalChecklistItem(74, RarityTier.Bronze); // 074 Lozano
    _addOriginalChecklistItem(75, RarityTier.Bronze); // 075 Ziyech
    _addOriginalChecklistItem(76, RarityTier.Bronze); // 076 Moses
    _addOriginalChecklistItem(77, RarityTier.Bronze); // 077 Farf&#225;n
    _addOriginalChecklistItem(78, RarityTier.Bronze); // 078 Elneny
    _addOriginalChecklistItem(79, RarityTier.Bronze); // 079 Berg
    _addOriginalChecklistItem(80, RarityTier.Bronze); // 080 Ochoa
    _addOriginalChecklistItem(81, RarityTier.Bronze); // 081 Akinfeev
    _addOriginalChecklistItem(82, RarityTier.Bronze); // 082 Azmoun
    _addOriginalChecklistItem(83, RarityTier.Bronze); // 083 Cueva
    _addOriginalChecklistItem(84, RarityTier.Bronze); // 084 Khazri
    _addOriginalChecklistItem(85, RarityTier.Bronze); // 085 Honda
    _addOriginalChecklistItem(86, RarityTier.Bronze); // 086 Cahill
    _addOriginalChecklistItem(87, RarityTier.Bronze); // 087 Mikel
    _addOriginalChecklistItem(88, RarityTier.Bronze); // 088 Sung-yueng
    _addOriginalChecklistItem(89, RarityTier.Bronze); // 089 Ruiz
    _addOriginalChecklistItem(90, RarityTier.Bronze); // 090 Yoshida
    _addOriginalChecklistItem(91, RarityTier.Bronze); // 091 Al Abed
    _addOriginalChecklistItem(92, RarityTier.Bronze); // 092 Chung-yong
    _addOriginalChecklistItem(93, RarityTier.Bronze); // 093 G&#243;mez
    _addOriginalChecklistItem(94, RarityTier.Bronze); // 094 Sliti
    _addOriginalChecklistItem(95, RarityTier.Bronze); // 095 Ghoochannejhad
    _addOriginalChecklistItem(96, RarityTier.Bronze); // 096 Jedinak
    _addOriginalChecklistItem(97, RarityTier.Bronze); // 097 Al-Sahlawi
    _addOriginalChecklistItem(98, RarityTier.Bronze); // 098 Gunnarsson
    _addOriginalChecklistItem(99, RarityTier.Bronze); // 099 P&#233;rez

    // Move to the next deploy step.
    deployStep = DeployStep.WaitingForStepFour;
  }

  /// @dev Deploys all Iconics and marks the deploy as complete!
  function deployStepFour() external onlyOwner {
    require(deployStep == DeployStep.WaitingForStepFour, "You&#39;re not following the steps in order...");

    /* ICONICS */
    _addIconicChecklistItem(0, RarityTier.IconicInsert); // 100 Messi
    _addIconicChecklistItem(1, RarityTier.IconicInsert); // 101 Ronaldo
    _addIconicChecklistItem(2, RarityTier.IconicInsert); // 102 Neymar
    _addIconicChecklistItem(3, RarityTier.IconicInsert); // 103 Salah
    _addIconicChecklistItem(4, RarityTier.IconicInsert); // 104 Lewandowski
    _addIconicChecklistItem(5, RarityTier.IconicInsert); // 105 De Bruyne
    _addIconicChecklistItem(6, RarityTier.IconicInsert); // 106 Modrić
    _addIconicChecklistItem(7, RarityTier.IconicInsert); // 107 Hazard
    _addIconicChecklistItem(8, RarityTier.IconicInsert); // 108 Ramos
    _addIconicChecklistItem(9, RarityTier.IconicInsert); // 109 Kroos
    _addIconicChecklistItem(10, RarityTier.IconicInsert); // 110 Su&#225;rez
    _addIconicChecklistItem(11, RarityTier.IconicInsert); // 111 Kane
    _addIconicChecklistItem(12, RarityTier.IconicInsert); // 112 Ag&#252;ero
    _addIconicChecklistItem(15, RarityTier.IconicInsert); // 113 de Gea
    _addIconicChecklistItem(16, RarityTier.IconicInsert); // 114 Griezmann
    _addIconicChecklistItem(17, RarityTier.IconicReferral); // 115 Kant&#233;
    _addIconicChecklistItem(18, RarityTier.IconicReferral); // 116 Cavani
    _addIconicChecklistItem(19, RarityTier.IconicInsert); // 117 Pogba
    _addIconicChecklistItem(21, RarityTier.IconicInsert); // 118 Marcelo
    _addIconicChecklistItem(24, RarityTier.IconicInsert); // 119 James
    _addIconicChecklistItem(26, RarityTier.IconicInsert); // 120 Eriksen
    _addIconicChecklistItem(29, RarityTier.IconicReferral); // 121 Thiago
    _addIconicChecklistItem(36, RarityTier.IconicReferral); // 122 Hummels
    _addIconicChecklistItem(38, RarityTier.IconicReferral); // 123 &#214;zil
    _addIconicChecklistItem(39, RarityTier.IconicInsert); // 124 Son
    _addIconicChecklistItem(46, RarityTier.IconicInsert); // 125 Man&#233;
    _addIconicChecklistItem(48, RarityTier.IconicInsert); // 126 Alli
    _addIconicChecklistItem(49, RarityTier.IconicReferral); // 127 Navas
    _addIconicChecklistItem(73, RarityTier.IconicInsert); // 128 Hern&#225;ndez
    _addIconicChecklistItem(85, RarityTier.IconicInsert); // 129 Honda
    _addIconicChecklistItem(100, RarityTier.IconicReferral); // 130 Alves
    _addIconicChecklistItem(101, RarityTier.IconicReferral); // 131 Zlatan

    // Mark the initial deploy as complete.
    deployStep = DeployStep.DoneInitialDeploy;
  }

  /// @dev Returns the mint limit for a given checklist item, based on its tier.
  /// @param _checklistId Which checklist item we need to get the limit for.
  /// @return How much of this checklist item we are allowed to mint.
  function limitForChecklistId(uint8 _checklistId) external view returns (uint16) {
    RarityTier rarityTier;
    uint8 index;
    if (_checklistId < 100) { // Originals = #000 to #099
      rarityTier = originalChecklistItems[_checklistId].tier;
    } else if (_checklistId < 200) { // Iconics = #100 to #131
      index = _checklistId - 100;
      require(index < iconicsCount(), "This Iconics checklist item doesn&#39;t exist.");
      rarityTier = iconicChecklistItems[index].tier;
    } else { // Unreleased = #200 to max #255
      index = _checklistId - 200;
      require(index < unreleasedCount(), "This Unreleased checklist item doesn&#39;t exist.");
      rarityTier = unreleasedChecklistItems[index].tier;
    }
    return tierLimits[uint8(rarityTier)];
  }
}