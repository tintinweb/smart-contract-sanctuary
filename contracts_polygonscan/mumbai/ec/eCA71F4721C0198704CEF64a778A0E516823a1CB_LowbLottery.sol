// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC721LOWB {

    function holderOf(uint256 tokenId) external view returns (address holder);
    function totalSupply() external view returns (uint n);

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IWallet {

    function balanceOf(address user) external view returns (uint balance);
    function isApprovededAddress(address user, address contractAddress) external view returns (bool b);
    function award(address user, uint amount) external;
    function use(address user, uint amount) external;

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC721LOWB.sol";
import "./IWallet.sol";

contract LowbLottery {

  struct Round {
    uint id;
    uint block;
    uint pool;
    uint cheatFee;
    uint[10] luckyNumbers;
  }
  
  uint private randNonce;
  address public walletAddress;
  address public nftAddress;
  address public owner;
  bool public isPause;
  Round[] public rounds;
  mapping (address => bool) public whitelist;
  
  constructor(address wallet_, address nft_) {
    walletAddress = wallet_;
    nftAddress = nft_;
    owner = msg.sender;
    Round memory round;
    round.id = 0;
    round.block = block.number;
    round.pool = 1000000e18;
    rounds.push(round);
    _setLuckyNumber();
  }
  
  function setPause(bool b) public {
    require(msg.sender == owner, "You are not admin");
    isPause = b;
  }
  
  function getLuckyNumbers(uint id) public view returns (uint[10] memory) {
    return rounds[id].luckyNumbers;
  }
  
  function totalRounds() public view returns (uint) {
    return rounds.length;
  }
  
  function cheat() public {
    uint _cheatFee = rounds[rounds.length-1].cheatFee + 1000e18;
    IWallet wallet = IWallet(walletAddress);
    require(wallet.balanceOf(msg.sender) >= _cheatFee, "Please deposit enough lowb to cheat!");
    require(wallet.isApprovededAddress(msg.sender, address(this)), "You should approve the contract to use your wallet.");
    wallet.use(msg.sender, _cheatFee);
    rounds[rounds.length-1].cheatFee = _cheatFee;
    rounds[rounds.length-1].pool = rounds[rounds.length-1].pool + _cheatFee/2;
    _setLuckyNumber();
  }
  
  function setWhitelist() public {
    whitelist[msg.sender] = true;
  }
  
  function _setLuckyNumber() private {
    IERC721LOWB token = IERC721LOWB(nftAddress);
    uint n = token.totalSupply();
    for (uint i=0; i<10; i++) {
      rounds[rounds.length-1].luckyNumbers[i] = uint(keccak256(abi.encode(block.timestamp, msg.sender, randNonce))) % n;
      randNonce ++;
    }
  }

  function moveToNextRound() public {
    require(isPause == false, "The lottery paused.");
    IWallet wallet = IWallet(walletAddress);
    
    Round memory nextRound;
    Round memory currentRound = rounds[rounds.length - 1];
    nextRound.id = currentRound.id + 1;
    nextRound.block = block.number;
    require(block.number >= currentRound.block + 2400, "One round per 4 hours!");
    nextRound.pool = currentRound.pool + 100000e18;
    uint rewards = currentRound.pool / 10;
    IERC721LOWB token = IERC721LOWB(nftAddress);
    for (uint i=0; i<10; i++) {
      address holder = token.holderOf(currentRound.luckyNumbers[i]);
      if (whitelist[holder]) {
        nextRound.pool = nextRound.pool - rewards;
        wallet.award(holder, rewards);
        whitelist[holder] = false;
      }
    }
    rounds.push(nextRound);
    _setLuckyNumber();
    
    wallet.award(msg.sender, 1000e18);
  }
  
  
  
}