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





/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}




/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}





/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
  function safeTransfer(ERC20Basic token, address to, uint256 value) internal {
    assert(token.transfer(to, value));
  }

  function safeTransferFrom(
    ERC20 token,
    address from,
    address to,
    uint256 value
  )
    internal
  {
    assert(token.transferFrom(from, to, value));
  }

  function safeApprove(ERC20 token, address spender, uint256 value) internal {
    assert(token.approve(spender, value));
  }
}






/**
 * @title Smart contract Osliki Classifieds
 *
 * @dev This is part of the Decentralized Osliki Platform (DOP).
 */
contract OslikiClassifieds {
  using SafeMath for uint;
  using SafeERC20 for ERC20;

  ERC20 public oslikToken; // OSLIK Token (OT) address (ERC20 compatible token)
  address public oslikiFoundation; // Osliki Foundation (OF) address

  uint public upPrice = 1 ether; // same decimals for OSLIK tokens
  uint public reward = 20 ether; // same decimals for OSLIK tokens

  string[] public catsRegister;
  Ad[] public ads;
  Comment[] public comments;

  mapping (address => uint[]) internal adsByUser;
  mapping (string => uint[]) internal adsByCat;

  event EventNewCategory(uint catId, string catName);
  event EventNewAd(address indexed from, uint indexed catId, uint adId);
  event EventEditAd(address indexed from, uint indexed catId, uint indexed adId);
  event EventNewComment(address indexed from, uint indexed catId, uint indexed adId, uint cmntId);
  event EventUpAd(address indexed from, uint indexed catId, uint indexed adId);
  event EventReward(address indexed to, uint reward);

  struct Ad {
    address user;
    uint catId;
    string text;
    uint[] comments;
    uint createdAt;
    uint updatedAt;
  }

  struct Comment {
    address user;
    uint adId;
    string text;
    uint createdAt;
  }

  constructor(
    ERC20 _oslikToken,
    address _oslikiFoundation
  ) public {
    require(address(_oslikToken) != address(0), "_oslikToken is not assigned.");
    require(_oslikiFoundation != address(0), "_oslikiFoundation is not assigned.");

    oslikToken = _oslikToken;
    oslikiFoundation = _oslikiFoundation;
  }

  function _newAd(
    uint catId,
    string text // format &#39;ipfs hash,ipfs hash...&#39;
  ) private returns (bool) {
    require(bytes(text).length != 0, "Text is empty");

    ads.push(Ad({
      user: msg.sender,
      catId: catId,
      text: text,
      comments: new uint[](0),
      createdAt: now,
      updatedAt: now
    }));

    uint adId = ads.length - 1;

    adsByCat[catsRegister[catId]].push(adId);
    adsByUser[msg.sender].push(adId);

    if (adsByUser[msg.sender].length == 1 && reward > 0 && oslikToken.allowance(oslikiFoundation, address(this)) >= reward) {
      uint balanceOfBefore = oslikToken.balanceOf(oslikiFoundation);

      if (balanceOfBefore >= reward) {
        oslikToken.safeTransferFrom(oslikiFoundation, msg.sender, reward);

        uint balanceOfAfter = oslikToken.balanceOf(oslikiFoundation);
        assert(balanceOfAfter == balanceOfBefore.sub(reward));

        emit EventReward(msg.sender, reward);
      }
    }

    emit EventNewAd(msg.sender, catId, adId);

    return true;
  }

  function newAd(
    uint catId,
    string text // format &#39;ipfs hash,ipfs hash...&#39;
  ) public {
    require(catId < catsRegister.length, "Category not found");

    assert(_newAd(catId, text));
  }

  function newCatWithAd(
    string catName,
    string text // format &#39;ipfs hash,ipfs hash...&#39;
  ) public {
    require(bytes(catName).length != 0, "Category is empty");
    require(adsByCat[catName].length == 0, "Category already exists");

    catsRegister.push(catName);
    uint catId = catsRegister.length - 1;

    emit EventNewCategory(catId, catName);

    assert(_newAd(catId, text));
  }

  function editAd(
    uint adId,
    string text // format &#39;ipfs hash,ipfs hash...&#39;
  ) public {
    require(adId < ads.length, "Ad id not found");
    require(bytes(text).length != 0, "Text is empty");

    Ad storage ad = ads[adId];

    require(msg.sender == ad.user, "Sender not authorized.");
    //require(!_stringsEqual(ad.text, text), "New text is the same");

    ad.text = text;
    ad.updatedAt = now;

    emit EventEditAd(msg.sender, ad.catId, adId);
  }

  function newComment(
    uint adId,
    string text
  ) public {
    require(adId < ads.length, "Ad id not found");
    require(bytes(text).length != 0, "Text is empty");

    Ad storage ad = ads[adId];

    comments.push(Comment({
      user: msg.sender,
      adId: adId,
      text: text,
      createdAt: now
    }));

    uint cmntId = comments.length - 1;

    ad.comments.push(cmntId);

    emit EventNewComment(msg.sender, ad.catId, adId, cmntId);
  }

  function upAd(
    uint adId
  ) public {
    require(adId < ads.length, "Ad id not found");

    Ad memory ad = ads[adId];

    require(msg.sender == ad.user, "Sender not authorized.");

    adsByCat[catsRegister[ad.catId]].push(adId);

    uint balanceOfBefore = oslikToken.balanceOf(oslikiFoundation);

    oslikToken.safeTransferFrom(msg.sender, oslikiFoundation, upPrice);

    uint balanceOfAfter = oslikToken.balanceOf(oslikiFoundation);
    assert(balanceOfAfter == balanceOfBefore.add(upPrice));

    emit EventUpAd(msg.sender, ad.catId, adId);
  }

  /*function _stringsEqual(string a, string b) private pure returns (bool) {
   return keccak256(a) == keccak256(b);
  }*/

  modifier onlyFoundation {
    require(msg.sender == oslikiFoundation, "Sender not authorized.");
    _;
  }

  function _changeUpPrice(uint newUpPrice) public onlyFoundation {
    upPrice = newUpPrice;
  }

  function _changeReward(uint newReward) public onlyFoundation {
    reward = newReward;
  }

  function _changeOslikiFoundation(address newAddress) public onlyFoundation {
    require(newAddress != address(0));
    oslikiFoundation = newAddress;
  }


  function getCatsCount() public view returns (uint) {
    return catsRegister.length;
  }

  function getCommentsCount() public view returns (uint) {
    return comments.length;
  }

  function getCommentsCountByAd(uint adId) public view returns (uint) {
    return ads[adId].comments.length;
  }

  function getAllCommentIdsByAd(uint adId) public view returns (uint[]) {
    return ads[adId].comments;
  }

  function getCommentIdByAd(uint adId, uint index) public view returns (uint) {
    return ads[adId].comments[index];
  }


  function getAdsCount() public view returns (uint) {
    return ads.length;
  }


  function getAdsCountByUser(address user) public view returns (uint) {
    return adsByUser[user].length;
  }

  function getAdIdByUser(address user, uint index) public view returns (uint) {
    return adsByUser[user][index];
  }

  function getAllAdIdsByUser(address user) public view returns (uint[]) {
    return adsByUser[user];
  }


  function getAdsCountByCat(uint catId) public view returns (uint) {
    return adsByCat[catsRegister[catId]].length;
  }

  function getAdIdByCat(uint catId, uint index) public view returns (uint) {
    return adsByCat[catsRegister[catId]][index];
  }

  function getAllAdIdsByCat(uint catId) public view returns (uint[]) {
    return adsByCat[catsRegister[catId]];
  }

}