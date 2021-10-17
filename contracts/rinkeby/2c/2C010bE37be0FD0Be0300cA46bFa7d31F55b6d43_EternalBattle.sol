/**
 *Submitted for verification at Etherscan.io on 2021-10-17
*/

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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/utils/ERC721Holder.sol



/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

// File: contracts/EternalBattle.sol



pragma solidity ^0.8.3;

// import "../openzep/token/ERC721/utils/ERC721Holder.sol";


interface IEthemerals {

  struct Meral {
    uint16 score;
    uint32 rewards;
    uint16 atk;
    uint16 def;
    uint16 spd;
  }

  function safeTransferFrom(address from, address to, uint256 tokenId) external;
  function ownerOf(uint256 _tokenId) external view returns (address);
  function changeScore(uint _tokenId, uint16 offset, bool add, uint32 amount) external;
  function changeRewards(uint _tokenId, uint32 offset, bool add, uint8 action) external;
  function getEthemeral(uint _tokenId) external view returns(Meral memory);
}

interface IPriceFeedProvider {
  function getLatestPrice(uint8 _id) external view returns (uint);
}

contract EternalBattle is ERC721Holder {

  event StakeCreated (uint indexed tokenId, uint priceFeedId, bool long);
  event StakeCanceled (uint indexed tokenId, bool win);
  event TokenRevived (uint indexed tokenId, uint reviver);
  event OwnershipTransferred(address previousOwner, address newOwner);

  struct Stake {
    address owner;
    uint8 priceFeedId;
    uint8 positionSize;
    uint startingPrice;
    bool long;
  }

  struct GamePair {
    bool active;
    uint16 longs;
    uint16 shorts;
  }

  IEthemerals nftContract;
  IPriceFeedProvider priceFeed;

  uint16 public atkDivMod = 3000; // lower number higher multiplier
  uint16 public defDivMod = 2200; // lower number higher multiplier
  uint16 public spdDivMod = 500; // lower number higher multiplier
  uint32 public reviverReward = 300; //500 tokens

  address private admin;

  // mapping tokenId to stake;
  mapping (uint => Stake) private stakes;

  // mapping of active longs/shorts to priceIds
  mapping (uint8 => GamePair) private gamePairs;

  constructor(address _nftAddress, address _priceFeedAddress) {
    admin = msg.sender;
    nftContract = IEthemerals(_nftAddress);
    priceFeed = IPriceFeedProvider(_priceFeedAddress);
  }

  /**
    * @dev
    * sends token to contract
    * requires price in range
    * creates stakes struct,
    */
  function createStake(uint _tokenId, uint8 _priceFeedId, uint8 _positionSize, bool long) external {
    require(gamePairs[_priceFeedId].active, 'not active');
    uint price = priceFeed.getLatestPrice(_priceFeedId);
    require(price > 10000, 'pbounds');
    require(_positionSize > 25 && _positionSize <= 255, 'bounds');
    IEthemerals.Meral memory _meral = nftContract.getEthemeral(_tokenId);
    require(_meral.rewards > reviverReward, 'needs ELF');
    nftContract.safeTransferFrom(msg.sender, address(this), _tokenId);
    stakes[_tokenId] = Stake(msg.sender, _priceFeedId, _positionSize, price, long);

    _changeGamePair(_priceFeedId, long, true);
    emit StakeCreated(_tokenId, _priceFeedId, long);
  }


  /**
    * @dev
    * adds / removes long shorts
    * does not check underflow should be fine
    */
  function _changeGamePair(uint8 _priceFeedId, bool _long, bool _stake) internal {
    GamePair memory _gamePair  = gamePairs[_priceFeedId];
    if(_long) {
      gamePairs[_priceFeedId].longs = _stake ? _gamePair.longs + 1 : _gamePair.longs -1;
    } else {
      gamePairs[_priceFeedId].shorts = _stake ? _gamePair.shorts + 1 : _gamePair.shorts -1;
    }
  }

  /**
    * @dev
    * gets price and score change
    * returns token to owner
    *
    */
  function cancelStake(uint _tokenId) external {
    require(stakes[_tokenId].owner == msg.sender, 'only owner');
    require(nftContract.ownerOf(_tokenId) == address(this), 'only staked');
    (uint change, uint reward, bool win) = getChange(_tokenId);
    nftContract.safeTransferFrom(address(this), stakes[_tokenId].owner, _tokenId);
    nftContract.changeScore(_tokenId, uint16(change), win, uint32(reward)); // change in bps

    _changeGamePair(stakes[_tokenId].priceFeedId, stakes[_tokenId].long, false);
    emit StakeCanceled(_tokenId, win);
  }

  /**
    * @dev
    * allows second token1 to revive token0 and take rewards
    * returns token1 to owner
    *
    */
  function reviveToken(uint _id0, uint _id1) external {
    require(nftContract.ownerOf(_id1) == msg.sender, 'only owner');
    require(nftContract.ownerOf(_id0) == address(this), 'only staked');
    // GET CHANGE
    Stake storage _stake = stakes[_id0];
    uint priceEnd = priceFeed.getLatestPrice(_stake.priceFeedId);
    IEthemerals.Meral memory _meral = nftContract.getEthemeral(_id0);
    bool win = _stake.long ? _stake.startingPrice < priceEnd : _stake.startingPrice > priceEnd;
    uint change = _stake.positionSize * calcBps(_stake.startingPrice, priceEnd);
    change = ((change - (_meral.def * change / defDivMod)) ) / 1000; // BONUS ATK
    uint scoreBefore = _meral.score;

    require((win != true && scoreBefore <= (change + 20)), 'not dead');
    require(_meral.rewards > reviverReward, 'needs ELF');
    nftContract.safeTransferFrom(address(this), stakes[_id0].owner, _id0);
    nftContract.changeScore(_id0, uint16(scoreBefore - 100), win, 0); // reset scores to 100
    nftContract.changeRewards(_id0, reviverReward, false, 1);
    nftContract.changeRewards(_id1, reviverReward, true, 1);

    _changeGamePair(_stake.priceFeedId, _stake.long, false);
    emit TokenRevived(_id0, _id1);
  }

  /**
    * @dev
    * gets price difference in bps
    * modifies the score change and rewards by atk/def/spd
    * atk increase winning score change, def reduces losing score change, spd increase rewards
    */
  function getChange(uint _tokenId) public view returns (uint, uint, bool) {
    Stake storage _stake = stakes[_tokenId];
    IEthemerals.Meral memory _meral = nftContract.getEthemeral(_tokenId);
    uint priceEnd = priceFeed.getLatestPrice(_stake.priceFeedId);
    uint reward;
    bool win = _stake.long ? _stake.startingPrice < priceEnd : _stake.startingPrice > priceEnd;

    uint change = _stake.positionSize * calcBps(_stake.startingPrice, priceEnd);
    if(win) {
      change = (_meral.atk * change / atkDivMod + change) / 1000; // BONUS ATK
      // reward = (_meral.spd * change) / spdDivMod / 1000; // BONUS SPD
      uint16 longs = gamePairs[stakes[_tokenId].priceFeedId].longs;
      uint16 shorts = gamePairs[stakes[_tokenId].priceFeedId].shorts;
      uint counterTradeBonus = 1;
      if(!_stake.long && longs > shorts) {
        counterTradeBonus = ((longs * 1000) / shorts) / 2000;
      }
      if(_stake.long && shorts > longs) {
        counterTradeBonus = ((shorts * 1000) / longs) / 2000;
      }
      counterTradeBonus = counterTradeBonus > 5 ? 5 : counterTradeBonus;
      reward = _meral.spd * change / spdDivMod * counterTradeBonus; // DOESNT MATCH JS WHY????

    } else {
      change = ((change - (_meral.def * change / defDivMod)) ) / 1000; // BONUS ATK
    }
    return (change, reward, win);
  }

  function calcBps(uint _x, uint _y) public pure returns (uint) {
    // 1000 = 10% 100 = 1% 10 = 0.1% 1 = 0.01%
    return _x < _y ? (_y - _x) * 10000 / _x : (_x - _y) * 10000 / _y;
  }

  function getStake(uint _tokenId) external view returns (Stake memory) {
    return stakes[_tokenId];
  }

  function getGamePair(uint8 _gameIndex) external view returns (GamePair memory) {
    return gamePairs[_gameIndex];
  }

  function resetGamePair(uint8 _gameIndex, bool _active) external onlyAdmin() { //admin
    gamePairs[_gameIndex].active = _active;
    gamePairs[_gameIndex].longs = 0;
    gamePairs[_gameIndex].shorts = 0;
  }

  function cancelStakeAdmin(uint _tokenId) external onlyAdmin() { //admin
    nftContract.safeTransferFrom(address(this), stakes[_tokenId].owner, _tokenId);

    _changeGamePair(stakes[_tokenId].priceFeedId, stakes[_tokenId].long, false);
    emit StakeCanceled(_tokenId, false);
  }

  function setReviverRewards(uint32 _reward) external onlyAdmin() { //admin
    reviverReward = _reward;
  }

  function setStatsDivMod(uint16 _atkDivMod, uint16 _defDivMod, uint16 _spdDivMod) external onlyAdmin() { //admin
    atkDivMod = _atkDivMod;
    defDivMod = _defDivMod;
    spdDivMod = _spdDivMod;
  }

  function transferOwnership(address newAdmin) external onlyAdmin() { //admin
    admin = newAdmin;
    emit OwnershipTransferred(admin, newAdmin);
  }

  function setPriceFeedContract(address _pfAddress) external onlyAdmin() { //admin
    priceFeed = IPriceFeedProvider(_pfAddress);
  }

  modifier onlyAdmin() {
    require(msg.sender == admin, 'admin only');
    _;
  }

}