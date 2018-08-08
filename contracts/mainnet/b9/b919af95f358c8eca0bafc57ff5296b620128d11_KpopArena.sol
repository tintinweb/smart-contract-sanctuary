// KpopArena lets users play with their Kpop cards against other
// players on Kpop.io

pragma solidity ^0.4.18;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
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

contract ERC721 {
  function approve(address _to, uint _itemId) public;
  function balanceOf(address _owner) public view returns (uint balance);
  function implementsERC721() public pure returns (bool);
  function ownerOf(uint _itemId) public view returns (address addr);
  function takeOwnership(uint _itemId) public;
  function totalSupply() public view returns (uint total);
  function transferFrom(address _from, address _to, uint _itemId) public;
  function transfer(address _to, uint _itemId) public;

  event Transfer(address indexed from, address indexed to, uint itemId);
  event Approval(address indexed owner, address indexed approved, uint itemId);
}

contract KpopCeleb is ERC721 {
  function ownerOf(uint _celebId) public view returns (address addr);
  function getCeleb(uint _celebId) public view returns (
    string name,
    uint price,
    address owner,
    uint[6] traitValues,
    uint[6] traitBoosters
  );
  function updateTraits(uint _celebId) public;
}

contract KpopItem is ERC721 {
  function ownerOf(uint _itemId) public view returns (address addr);
  function getItem(uint _itemId) public view returns (
    string name,
    uint price,
    address owner,
    uint[6] traitValues,
    uint celebId
  );
  function transferToWinner(address _winner, address _loser, uint _itemId) public;
}

contract KpopArena {
  using SafeMath for uint;

  address public author;
  address public coauthor;

  string public constant NAME = "KpopArena";
  string public constant SYMBOL = "KpopArena";

  address public KPOP_CELEB_CONTRACT_ADDRESS = 0x0;
  address public KPOP_ITEM_CONTRACT_ADDRESS = 0x0;

  mapping(address => bool) public userToIsAcceptingChallenge;
  mapping(address => uint) private userToActiveCelebId;
  mapping(address => uint) private userToActiveItemId;
  mapping(address => uint) public userToScore;

  event Enroll(address indexed user, uint celebId, uint itemId);
  event Expel(address indexed user);
  event Rescind(address indexed user);
  event FightOver(
    address indexed host,
    address indexed challenger,
    address indexed winner,
    uint challengerCelebId,
    uint challengerItemId,
    string selectedTrait
  );

  function KpopArena() public {
    author = msg.sender;
    coauthor = msg.sender;
  }

  function enroll(uint _celebId, uint _itemId) public {
    // User can only enroll once at a time
    require(!userToIsAcceptingChallenge[msg.sender]);

    // Use must own the celeb and items
    require(doesUserOwnItem(msg.sender, _itemId));
    require(doesUserOwnCeleb(msg.sender, _celebId));

    userToIsAcceptingChallenge[msg.sender] = true;
    userToActiveCelebId[msg.sender] = _celebId;
    userToActiveItemId[msg.sender] = _itemId;

    Enroll(msg.sender, _celebId, _itemId);
  }

  function rescind(address _user) public {
    require(_user == msg.sender || _user == author || _user == coauthor);

    userToIsAcceptingChallenge[_user] = false;
    Rescind(_user);
  }

  function challenge(address _host, uint _celebId, uint _itemId) public {
    address _challenger = msg.sender;

    require(!isNullAddress(_host) && !isNullAddress(_challenger));
    require(_host != _challenger);
    require(userToIsAcceptingChallenge[_host]);
    require(doesUserOwnCeleb(_challenger, _celebId));
    require(doesUserOwnItem(_challenger, _itemId));

    uint _hostCelebId = userToActiveCelebId[_host];
    uint _hostItemId = userToActiveItemId[_host];

    // Expel user who doesn&#39;t own their celeb or items anymore
    if (!(doesUserOwnCeleb(_host, _hostCelebId) && doesUserOwnItem(_host, _hostItemId))) {
      userToIsAcceptingChallenge[_host] = false;
      Expel(_host);
      return;
    }

    // Get winner
    uint selectedTraitIdx = selectRandomTrait();
    address winner = computeWinner(
      _host, _hostCelebId, _hostItemId,
      _challenger, _celebId, _itemId,
      selectedTraitIdx
    );

    // Assign scores
    if (winner != 0x0) {
      userToScore[winner] = userToScore[winner].add(3);

      // Level up celeb and give winner the item card
      KpopCeleb KPOP_CELEB = KpopCeleb(KPOP_CELEB_CONTRACT_ADDRESS);
      KpopItem KPOP_ITEM = KpopItem(KPOP_ITEM_CONTRACT_ADDRESS);

      if (winner == _host) {
        KPOP_CELEB.updateTraits(_hostCelebId);
        KPOP_ITEM.transferToWinner(_host, _challenger, _itemId);
      } else {
        KPOP_CELEB.updateTraits(_celebId);
        KPOP_ITEM.transferToWinner(_challenger, _host, _hostItemId);
      }
    } else {
      userToScore[_host] = userToScore[_host].add(1);
      userToScore[_challenger] = userToScore[_challenger].add(1);
    }

    // Duel is over. Host must opt into the arena again if they wish to get more challenges
    userToIsAcceptingChallenge[_host] = false;
    delete userToActiveCelebId[_host];
    delete userToActiveItemId[_host];

    FightOver(
      _host,
      _challenger,
      winner,
      _celebId,
      _itemId,
      traitIdxToName(selectedTraitIdx)
    );
  }

  // _a wins if score > 0 and _b wins if score < 0. Otherwise, draw.
  function computeWinner(
    address _host, uint _hostCelebId, uint _hostItemId,
    address _challenger, uint _challengerCelebId, uint _challengerItemId,
    uint _selectedTraitIdx
  ) private view returns(address winner)
  {
    uint hostTraitScore = computeTraitScore(_hostCelebId, _hostItemId, _selectedTraitIdx);
    uint challengerTraitScore = computeTraitScore(_challengerCelebId, _challengerItemId, _selectedTraitIdx);

    if (hostTraitScore > challengerTraitScore) {
      return _host;
    }

    if (hostTraitScore < challengerTraitScore) {
      return _challenger;
    }

    return 0x0;
  }

  function computeTraitScore(uint _celebId, uint _itemId, uint _selectedTraitIdx) private view returns (uint) {
    KpopCeleb KPOP_CELEB = KpopCeleb(KPOP_CELEB_CONTRACT_ADDRESS);
    KpopItem KPOP_ITEM = KpopItem(KPOP_ITEM_CONTRACT_ADDRESS);

    var ( , , ,celebTraits, ) = KPOP_CELEB.getCeleb(_celebId);
    var ( , , ,itemTraits, ) = KPOP_ITEM.getItem(_itemId);

    return celebTraits[_selectedTraitIdx] + itemTraits[_selectedTraitIdx];
  }

  function selectRandomTrait() private view returns (uint) {
    return uint(block.blockhash(block.number - 1)) % 6;
  }

  function withdraw(uint _amount, address _to) public onlyAuthors {
    require(!isNullAddress(_to));
    require(_amount <= this.balance);

    _to.transfer(_amount);
  }

  function withdrawAll() public onlyAuthors {
    require(author != 0x0);
    require(coauthor != 0x0);

    uint halfBalance = uint(SafeMath.div(this.balance, 2));

    author.transfer(halfBalance);
    coauthor.transfer(halfBalance);
  }

  function doesUserOwnCeleb(address _user, uint _celebId) private view returns (bool) {
    KpopCeleb KPOP_CELEB = KpopCeleb(KPOP_CELEB_CONTRACT_ADDRESS);

    return KPOP_CELEB.ownerOf(_celebId) == _user;
  }

  function doesUserOwnItem(address _user, uint _itemId) private view returns (bool) {
    KpopItem KPOP_ITEM = KpopItem(KPOP_ITEM_CONTRACT_ADDRESS);

    return KPOP_ITEM.ownerOf(_itemId) == _user;
  }

  function setCoAuthor(address _coauthor) public onlyAuthor {
    require(!isNullAddress(_coauthor));

    coauthor = _coauthor;
  }

  function setKpopItemContractAddress(address _address) public onlyAuthors {
    KPOP_ITEM_CONTRACT_ADDRESS = _address;
  }

  function setKpopCelebContractAddress(address _address) public onlyAuthors {
    KPOP_CELEB_CONTRACT_ADDRESS = _address;
  }

  function traitIdxToName(uint _idx) public pure returns (string) {
    if (_idx == 0) {
      return "rap";
    }
    if (_idx == 1) {
      return "vocal";
    }
    if (_idx == 2) {
      return "dance";
    }
    if (_idx == 3) {
      return "charm";
    }
    if (_idx == 4) {
      return "acting";
    }
    if (_idx == 5) {
      return "producing";
    }
  }

  /** MODIFIERS **/

  modifier onlyAuthor() {
    require(msg.sender == author);
    _;
  }

  modifier onlyAuthors() {
    require(msg.sender == author || msg.sender == coauthor);
    _;
  }

  function isNullAddress(address _addr) private pure returns (bool) {
    return _addr == 0x0;
  }
}