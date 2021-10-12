// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract VariousBooks is ERC721Enumerable, ReentrancyGuard, Ownable {
  using Counters for Counters.Counter;

  uint256 public constant mintPrice = 25000000000000000;
  bool public saleIsActive = true;
  Counters.Counter private _tokenIdCounter;

  string[] private nouns = [ 
    "Spends hours drooling over old books in the library","Under the influence of pink magic","Frequently turns invisible in crowds","Loves things made out of plastic",
    "Has a permanent stiff back","Recently lost her calculator","Throws out hay for chickens who refuses to work","Separates recyclables for extra weekend gold pieces","Gets unusually excited when it rains fish","Trains fish to handstand",
    "Sings Eurodance during defecation","Favors pancakes over waffles",
    "Hates humidity","Sticks to freshly washed glasses",
    "Sticks to all sorts of pets","Bookworm girl with glasses that totter","Starts to sleep if talk longer than 1 minute","Got asthma after eating spicy seaweed",
    "Blatant tomboy","Secretly obsessed with motorbikes","Illiterate cousin who knows computers",
    "Houses your room like a kendo space","Your high school classmate","Lives in fast forward","Tries running to lose weight","Has a secret job","Looks the same regardless of sex","Fails to create a happy family","Soggy pants every mon-thursday","Obsessed with dried up & dead creatures","Left eye is slightly bigger than right eye","Believes all stories can be traced back to aliens","Wonderfully twitchy the whole day","Makes up weird fairy-tales","Tries to catch snowflakes on her tongue","Heavily depends on drugs to succeed","Known for greeting everyone","$1 left in the accounts for this week","Always salutes to cops","Employed at a chocolate factory","Draws unicorns with leaky pens","Gets coffee for everyone in the morning","Committed to destroy all video surveillance","Artist for international tobacco","Believes thunder is the voice of an angry God","Always looks at opposite direction","Rarely reads poetry to his grand children","Always hesitates before speaking","Thinks each rabbit has its reasons","Surprisingly good at bowling","Expects the worst","Extremely sleep-able","Believes pigeons are twice as smart as humans","Closet japanophile","Punctual for all the wrong reasons","He is who he says he is","No stranger to physical violence","Trained as a flea circus performer","Performs spontaneous stunts","Secretly hearts sliced bread","Keeps a bottle of Bloody Mary in her backpack","Keen interest in charmed and enchanted objects","Names every trash bag","Wears a handmade Furby Fur Hat","Loves cereal with foot jam syrup","Expert selfie stylist","Can tame any animal with a bag","Star pupil of the embroidery class","Lost 22 umbrellas","Talks slowly with her hands for emphasis","Really into sun cookies","Never starts unnecessary conversations","Weird monk likes cucumbers","Always texts his contract partner","Tends to be aggressive to noobs","Collects various rocks","She can't be worn out by travelling","Always has a pair of scissors","Serious but loves cat jokes","Abstract artist who loves optical toys","Automatically changes usernames whenever online","Actually a hired assistant of a maid from some JRPG","Has been jumped into some cult","Good at teaching babies how to say their first words","Captivating conversation skills","Hates the sound of voices","Attracted to insects","Enjoys carrying scissors on her person at all times","Enjoys telling ghost stories","Might suffer from delusions","Only eats food if she's holding the silverware","Obsessed with making Christmas ornaments","Hears voices inside her head on the regular","Enjoys crying in the wilderness","Tremendous memorization skills","Foul smelling man's man","Enjoys cooking exotic dishes","Friend of nature","Can't live another day without pine cones","Has strong bladders","Sort-of owns a car","Seems to be constantly taking stock","Easily (and constantly) intimidated","Not even a little bit evil","Deadly with switchblades","Bedazzled by shiny gemstones","Has a glass eye","We rolled a dice and here she is","Doesn't remember his name","Could never learn how to do her hair right","Did not win the ugliest baby contest","Had an imaginary turtle","Owns an unspecific museum","Screams his onw name","Stops by construction sites just for fun","Loves to be eaten away","Mispronounces his own name at job interviews","Listens to annoying songs on his walkman","Four eyes three feet ten inches","Thinks idioms are a glitch","The only person who's visited the ancient gator farm","Teleported but he can't tell anyone","Old computer","Child genius","Collects left over makeup","Talks to animals","Is obsessed with lizzard maths","Always wears tights","Owns a waltzing doll","Has a closet full of tangled neck ties","He is a belly dancer","Very knowledgable in tonic herbs","Actually loves cockroaches","Makes complex plans for silly trolls","Is much, much older than everybody thinks","Enjoys sermons about the merits of patience","Turned a pumpkin into a guillotine","Spends a lot of time collecting words","Everybody thinks of him as a colorful groupie","Has slowed down speech","Made an artifical housefly","Talks to his bubble-encased worm-skeleton","Thinks bubbles are bubbles","Has a bucket labeled 'liquid' next to his bed","Sick from sniffing insect cuticle oil","Always dresses in a Santa suit on the 21st","Needs a romantic partner who perceives sizes correctly","Talks to a bottle of soda","Personal assistant for a close friend","Has more than twelve yoga mats","Immortally curious","Composed of mercury vapor","Doesn't mirror","Feels each breeze","Smells like vanilla","Promotes eating nuts","Rainbow butt chin & palm","Heated anemometer","No gym membership","Spinning water bed","Solves bath toy squabbles","Hugs nude","Forgot Macarena","Ice cream scenter","Touched a heated towel rail","Composed of joy","No hair on body, not a dolphin","Wean heavy foods",
    "Tells stories to potted plants","Names spices & sauces","Acutally inspired",
    "Reverse leg stand","Sugary citrus","Assuming everything is a telephone","A regular at the recycling trade","Experienced in making mud pies","Walks into rooms backwards","Pretends to go deaf when drunk","Explodes in a ball of rocks when weapons come too near","A feline at house party","Viewer's guide to summer canoe canoeing",
    "Two-headed aardvark","Tries to order every Spanish pintxo","Amazingly good at moving shadows on walls with hands","I am an artist, please take my banner","Gripped by an insane fear of moths","Notorious for using 900-feet zip lines to travel","Usually invites herself","Tells jokes nobody understands","Boasts how easy it is to get stiches","Enjoys making chainmail of sticky mittens","Notorious for throwing soup spoon parties","Strange scars that can't be explained","A psychedelic cyclist trying to upset the speed limit","There are a lot of chemicals in him","Basically one big eyeball","Will spend his life as a jar on a shelf","Cactus with a face","Very good listener","Lives her life as a broken elevator","Was dumped by a portal to a land with a lot of snow","From a planet with no sound at all, so she whispers","Has a strangely warm hat","Had her heart ripped out by a treacherous villain","Smells like a clean public bathroom","Smells like a new car","Is really cuddly and soft on the inside","Cannot move because of paint","An old currency","Actual moonlight","Attended Woodstock","Can trap thoughts and keep them as pets","Can't cook, can't dance, can't relate","Makes deals with everyone, deals no one could keep","Stereotype of a Vampire","Portable sausage factory","Cartoon shoe that speaks foreign languages","Dead Orcs lay at her dark will but her dark will does not speak","Seeks elephant remains to identify their former owner","He will likely lose","Calm dervish","Suggests to others he is good at measuring water","Interim god of taxes","Considers smelling like pure heaven","Was rear-ended but blames Earth","Carried to orgasm","Suggests monsters should share every feeling","Enormous screw used to lock many doors during demon prince Orin's reign","Discuss their love of soup","Carries all readers to magical realm where everyone is great at bread making","Reduces distance between all events","Has everything she wants rolled into one body","Every living thing that sees her faints","His deprivation grows everyday","Drinks the pulp out of oranges","Eats boogers when dreaming","Only cries in Radioland","Draws brand logos in tortoise shells","Gets agitated when told to go to bed","Howls in the night when the wind breathes through her teeth","When dreaming, eats paper","Keeps his baby teeth under his pillow","Attends mayonnaise festival","Drinks lemon water","A child of two villages","Threatens people with a dead hamster","Howls in cellophane, while showering","Decorates rooms with people's toenails","Thinks everything is screaming","Sits on the fridge to dream","Crossroads demon","Writes secret messages in lipstick, and eats it","Fears the gym's showers, and avoids them","She's just a disembodied eyeball","Named after a gas pedal","Inaudible dog barking","Shepherds a large flock of cuddly rat babies","The most adorable monster you've ever seen","Daughter of Brutus","Curates his collection entirely online","Finds any meal disgusting","Hates flavored anything","Good at normal if you don't let him think about it","Born without a knee cap","Joy of others is poison to her","Carry an easel everywhere she goes","Thought of as a non-moron by a few","Draw a heart around or inside everything he sees","Angry at a flower","Fire chases her everywhere","Finds everything more adorable after she colors it pink","red-green monster","Asks tiny sticks to fight tiny trolls","Mothers tiny men with tiny forks","Mommy always liked her best","Thinks outside the shoe box","His childhood ended a long time ago","Bad luck stains his package","A tiny bowler hat sits on her head","Dead, but can't remember to stay that way","Loves every single little seed","Hates being hired because he can't remember anything","Has a button on his head, hasn't pressed it yet","Auto-destructive","Is addicted to fingering people","Mountainous","Experienced french tickler","Possesses a jet-pack, or was that a grocery pack?","Was last seen at the Gliese 581 system","Seeks darkness, not at night, not in caves","Uses 'oo' sound for most words","Can split into two people","Espionage Cowboy","Just took a very long singing lesson","Lacks big feet","Drinking milk through a drinking straw","Wears a top hat, has no head","Is a bad handshaker, doesn't let go","Is good with plants","Has a drinking problem","Knows how to turn lead into gold","Doesn't need credit cards to shop","Birth rates will drop by 40% if he ever becomes a politician","Politically incorrect Instagram influencer","She doesn't shake hands, she just hugs","The other reality is not nice to her","She appears small to the aliens","He wishes he had a little smaller eyes","Has no idea how to pronounce 'bete noire'","Only exists when completely ignored by anyone","Weights exactly the same with a Colombian llama","How have you been, ice block?","Head was replaced with a cabbage","She has a very good sense of smell","Artwork of an important subject","Has anger issues- very loud when angry","Facepalms when seeing double glass doors","Knows how good he smells","Cyclops with hexagon head","Sexy only occasionally","Water baby who gets furious if he sees soap","You don't want to ride this terrifying horse","Capable of juggling two full-sized humans","Archer without memory","Most beautiful widow in the world",
    "Mostly blind superstar","A shameful secret","Healed by negativity","Self-fertilising monster","Saw a self-fertilising monster once","Wants a girlfriend already","Hates castles","The kitchen is his bedroom","Can explode when aggravated","Catch fire when hungry","Teleports when friends show up","Whimsical thug who hides a dapper duds in his bag","A mysterious tiny head that speaks with cryptic voice","A mad looking wizard who carries an iron-hard recipe book","Looks like dog poop","A man who drinks chicken ghost seedport rum","Craves human hair for his hot-pink hair helmet","Always has a spare box of air for her breathing","Wears half-lenses in an iron disfiguration","Pulls his horns in when he tries to act cool","Can't escape ...love","Cries in the dark when she thinks of what she could have done","Accidentally eats a silver spoon","Warlock in love with the texture of his beard","Infamously confused w/ another character by players","Shepherds the meaning of words","Loves to be slapped","Ghost who can not fit into the dark","Calls rats to his defence","She loves it when little humans try to stand up to her","Has not quite mastered orange squeezing","Undefined human who goes through walls","Halloween costume nightmare","Clearly not the right avatar","Made someone's stomach burst with pride","Why does everyone like her pillow collection?","Haunted electronic synthesizer","Immediately evaporate in the sun","Cactus wizard","Her husband is gigantic","Beer god slowly turning into lava","Always lying but simultaneously telling the truth","Fiery trap expert","Friendly Rabies","An irradiated little god who believes he's another god","Believes everything must be destroyed","Immune to plasma cannons","The cubes she throws are delicious"
  ];

  string[] private adjectives = [
    "Academic", "Ancient", "Basic", "Big", "Burning", "Bright", "Broken", "Bronze", 
    "Cold", "Complete", "Concise", "Consolidated", "Contemporary", "Continuous", "Cursed", "Cyber", 
    "Eastern", "Elemental", "Emerald", "Experimental", "Fallen", "First", "Forgotten", "Frozen", 
    "Fundamental", "Golden", "Greater", "Hardcore", "Hidden", "High", "Historic", "Holistic", 
    "Haunted", "Illustrated", "Informational", "Instant", "Little", "Living", "Lonely", "Lost", 
    "Lunar", "Magnetic", "Misty", "Modern", "New", "Northern", "Phantom", "Polar", 
    "Psychological", "Pure", "Quantum", "Romantic", "Rough", "Sacred", "Secret", "Silent", 
    "Simple", "Solar", "Southern", "Strange", "Supernatural", "Theoretical", "Third", "Total", 
    "Traditional", "Trailing", "Trembling", "Unknown", "Vacant", "Wandering", "Western", "Wild"
  ];

  string[] private prepositions = [
    "or",
    "from",
    "through",
    "with",
    "without",
    "beneath",
    "beyond",
    "before",
    "against",
    "amongst"
  ];

  string[] private formats = [
    "Softcover",
    "Oversized",
    "Mass-Market",
    "Hardcover",
    "Booklet"
  ];

  string[] private conditions = [
    "Fair",
    "Poor",
    "Perfect",
    "Fine",
    "Very Good",
    "Good"
  ];

  string[] private colors = [
    "#B08699",
    "#EBD999",
    "#FA2B00",
    "#0D75FF",
    "#66AB56",
    "#FFAB00",
    "#FFFFFF"
  ];

  uint256[] private formatWeights = [ 25, 38, 65, 85, 100 ];
  uint256[] private conditionWeights = [ 22, 36, 48, 63, 80, 100 ];
  uint256[] private colorWeights = [ 1, 2, 3, 4, 5, 6, 9 ];

  function random(uint256 tokenId, string memory seed) internal pure returns (uint256) {
    return uint256(keccak256(abi.encodePacked(seed, Strings.toString(tokenId))));
  }

  function getFormat(uint256 tokenId) public view returns (string memory) {
    return select(tokenId, "FORMAT", formats, formatWeights);
  }

  function getCondition(uint256 tokenId) public view returns (string memory) {
    return select(tokenId, "CONDITION", conditions, conditionWeights);
  }

  function getCoverColor(uint256 tokenId) public view returns (string memory) {
    return select(tokenId, "COLOR", colors, colorWeights);
  }

  function getSpineColor(uint256 tokenId) public view returns (string memory) {
    if ((random(tokenId, "SPINERARITY") % 15) < 3) {
      return select(tokenId, "SPINECOLOR", colors, colorWeights);
    } else {
      return select(tokenId, "COLOR", colors, colorWeights);
    }
  }

  function getPublisher(uint256 tokenId) public pure returns (uint256) {
    uint256 rand = random(tokenId, "PUBLISHER") % 100;
    return 15 > rand ? 1 : (51 > rand ? 2 : 3);
  }

  function getPages(uint256 tokenId) public pure returns (uint256) {
    return random(tokenId, "PAGES") % 501;
  }

  function getTitle(uint256 tokenId) public view returns (string memory) {
    uint256 rand = random(tokenId, "TITLE");
    uint256 format = rand % 4;
    string memory a1 = adjectives[(rand / 3) % adjectives.length];
    string memory n1 = nouns[(rand / 5) % nouns.length];
    string memory t1 = (rand / 7) % 2 != 0 ? 'The ' : '';
    string memory a2 = adjectives[(rand / 9) % adjectives.length];
    string memory n2 = nouns[(rand / 11) % nouns.length];
    string memory t2 = (rand / 13) % 2 != 0 ? 'the ' : '';
    string memory p = prepositions[(rand / 15) % prepositions.length];
    string memory j = (rand / 17) % 2 != 0 ? 'and' : 'of';

    if (format < 2) {
      return string(abi.encodePacked(
        (format == 1 ? t1 : ''), a1, ' ', n1
      ));
    } else {
      a1 = (rand / 26) % 2 != 0 ? string(abi.encodePacked(a1, ' ')) : '';
      a2 = (rand / 6) % 2 != 0 ? string(abi.encodePacked(a2, ' ')) : '';
      return string(abi.encodePacked(
        t1, a1, n1, ' ', (format == 2 ? p : j), ' ', t2, a2, n2
      ));
    }
  }

  function getTitleOutput(uint256 tokenId) internal view returns (string memory) {
    string memory output;
    bytes memory b = bytes(getTitle(tokenId));
    
    uint256 y = 78;
    uint256 i = 0;
    uint256 e = 0;    
    uint256 ll = 13;
    
    while (true) {
      e = i + ll;
      if (e >= b.length) {
        e = b.length;
      } else {
        while (b[e] != ' ' && e > i) { e--; }
      }

      bytes memory line = new bytes(e-i);
      for (uint k = i; k < e; k++) {
        line[k-i] = _upper(b[k]);
      }

      output = string(abi.encodePacked(output,'<text x="275" y="',Strings.toString(y),'">',line,'</text>'));
      if (y > 300) break;
      
      y += 38;
      if (e >= b.length) break;
      i = e + 1;
    }

    return output;
  }

  function getPublisherOutput(uint256 tokenId) internal pure returns (string memory) {
    uint256 publisher = getPublisher(tokenId);
    return publisher == 1 
      ? '<polygon points="50,430 60,450 40,450" />'
      : (publisher == 2 
      ? '<rect width="20" height="20" x="40" y="430" />' 
      : '<circle r="10" cx="50" cy="440" />');
  }

  function select(uint256 tokenId, string memory key, string[] memory sourceArray, uint256[] memory sourceWeights) internal pure returns (string memory) {
    uint256 val = random(tokenId, key) % sourceWeights[sourceWeights.length - 1];
    for(uint256 i = 0; i < sourceWeights.length; i++) {
      if (sourceWeights[i] > val) {
        return sourceArray[i];
      }
    } 
  }

  function tokenURI(uint256 tokenId) override public view returns (string memory) {
    string memory output = string(abi.encodePacked(
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 500 500"><rect width="500" height="500" />',
      '<rect width="450" height="450" x="25" y="25" rx="25" fill="', getCoverColor(tokenId), '" stroke="#000" />',
      '<rect width="50" height="450" x="25" y="25" fill="', getSpineColor(tokenId), '" stroke="#000" />',
      '<g font-family="serif" font-size="38px" text-anchor="middle">', getTitleOutput(tokenId),
      '<text x="275" y="450">', Strings.toString(tokenId), '</text></g>',
      '<text transform="rotate(90) translate(50 -45)" font-family="serif" font-size="16px">', getFormat(tokenId), ', ', Strings.toString(getPages(tokenId)), ', ', getCondition(tokenId), '</text>',
      getPublisherOutput(tokenId),
      '</svg>'
    ));

    string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "Book #', Strings.toString(tokenId), '", "description": "Various Books is a collection of speculative books generated and stored on chain.", "image": "data:image/svg+xml;base64,', Base64.encode(bytes(output)), '"}'))));
    output = string(abi.encodePacked('data:application/json;base64,', json));

    return output;
  }

  function claim() public payable {
    require(saleIsActive, "Sale is not active");
    uint256 nextId = _tokenIdCounter.current();
    require(mintPrice <= msg.value, "Ether value sent is not correct");
    require(nextId <= 4500, "Token limit reached");
    _safeMint(_msgSender(), nextId);
    _tokenIdCounter.increment();
  }

  function ownerClaim(uint256 tokenId) public nonReentrant onlyOwner {
    require(tokenId > 4500 && tokenId <= 4600, "Token ID invalid");
    _safeMint(owner(), tokenId);
  }

  function flipSaleState() public onlyOwner {
    saleIsActive = !saleIsActive;
  }

  function withdraw(address to, uint256 amount) public nonReentrant onlyOwner {
    require(amount <= address(this).balance, "Amount too high");
    payable(to).transfer(amount);
  }

  function _upper(bytes1 _b1) private pure returns (bytes1) {
    if (_b1 >= 0x61 && _b1 <= 0x7A) {
      return bytes1(uint8(_b1) - 32);
    }
    return _b1;
  }

  constructor() ERC721("VariousBooks", "VAB") Ownable() {
    _tokenIdCounter.increment();
  }
}

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