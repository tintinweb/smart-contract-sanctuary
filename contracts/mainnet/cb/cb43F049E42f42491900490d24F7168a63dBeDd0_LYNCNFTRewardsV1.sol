// SPDX-License-Identifier: MIT

  /**
   * LYNC Network
   * https://lync.network
   *
   * Additional details for contract and wallet information:
   * https://lync.network/tracking/
   *
   * The cryptocurrency network designed for passive token rewards for its community.
   */

pragma solidity ^0.7.0;

import "./lynctoken.sol";
import "./lyncstakingv1.sol";
import "./lynccrafter.sol";

contract LYNCNFTRewardsV1 {

    //Enable SafeMath
    using SafeMath for uint256;

    address payable public owner;
    uint256 public oneDay = 86400;          // in seconds
    uint256 public SCALAR = 1e18;           // multiplier

    LYNCToken public tokenContract;
    LYNCStakingV1 public stakingContract;
    LYNCCrafter public crafterContract;

    //Events
    event OwnershipTransferred(address indexed _previousOwner, address indexed _newOwner);
    event OwnershipRenounced(address indexed _previousOwner, address indexed _newOwner);

    //On deployment
    constructor(LYNCToken _tokenContract, LYNCStakingV1 _stakingContract, LYNCCrafter _crafterContract) {
        owner = msg.sender;
        tokenContract = _tokenContract;
        stakingContract = _stakingContract;
        crafterContract = _crafterContract;
    }

    //MulDiv functions : source https://medium.com/coinmonks/math-in-solidity-part-3-percents-and-proportions-4db014e080b1
    function mulDiv(uint x, uint y, uint z) public pure returns (uint) {
          (uint l, uint h) = fullMul (x, y);
          assert (h < z);
          uint mm = mulmod(x, y, z);
          if (mm > l) h -= 1;
          l -= mm;
          uint pow2 = z & -z;
          z /= pow2;
          l /= pow2;
          l += h * ((-pow2) / pow2 + 1);
          uint r = 1;
          r *= 2 - z * r;
          r *= 2 - z * r;
          r *= 2 - z * r;
          r *= 2 - z * r;
          r *= 2 - z * r;
          r *= 2 - z * r;
          r *= 2 - z * r;
          r *= 2 - z * r;
          return l * r;
    }

    //Required for MulDiv
    function fullMul(uint x, uint y) private pure returns (uint l, uint h) {
          uint mm = mulmod(x, y, uint (-1));
          l = x * y;
          h = mm - l;
          if (mm < l) h -= 1;
    }

    //Redeem lotto cards
    function redeemLotto(uint256 _cardID) public {

        //Check ownership of card
        require(crafterContract.balanceOf(msg.sender, _cardID) > 0, "You do not own this card");
        //Make sure card is a lotto card
        require(_cardID < 5, "Card is not a lotto card");

        uint256 _cardAmount = 1;
        string memory _collectionName;

        if(_cardID < 3) {
            _collectionName = "Ethereum Lotto";
            if(_cardID == 1) {
                _cardAmount = 10;
                require(crafterContract.balanceOf(msg.sender, _cardID) >= _cardAmount, "10 common cards required to craft");
            } else {
                require(crafterContract.balanceOf(msg.sender, _cardID) >= _cardAmount, "1 rare card required to craft");
            }
        } else {
            _collectionName = "LYNC Token Lotto";
            if(_cardID ==  3) {
                _cardAmount = 10;
                require(crafterContract.balanceOf(msg.sender, _cardID) >= _cardAmount, "10 common cards required to craft");
            } else {
                require(crafterContract.balanceOf(msg.sender, _cardID) >= _cardAmount, "1 rare card required to craft");
            }
        }

        //Craft reward card
        crafterContract.craftRewardCard(msg.sender, _cardID, _collectionName);
        //Burn card(s)
        crafterContract.burnCard(msg.sender, _cardID, _cardAmount);
    }

    //Redeem reward card
    function redeemReward(uint256 _cardID) public {

        //Check ownership of card
        require(crafterContract.balanceOf(msg.sender, _cardID) > 0, "You do not own this card");

        //Grab card data
        (,uint256 cardType,,,uint256 _redeemLeft,uint256 _redeemInterval,uint256 _redeemLastTimeStamp,uint256 _tokenReward,uint256 _percentageRedeem) = crafterContract.cards(_cardID);

        //Check card last redeem timestamp against its interval
        require(block.timestamp > (_redeemLastTimeStamp + _redeemInterval.mul(oneDay)), "This card has already been redeemed this interval, wait until reset");
         //Make sure this is is not a booster card
        require(cardType != 3, "Booster cards do not have any rewards associated with them");

        //Update or burn card
        if(cardType != 2) {
            //Burn the card
            crafterContract.burnCard(msg.sender, _cardID, 1);
        } else {
            require(_redeemLeft > 0, "No redeems available on this card");
            crafterContract.updateCardStats(_cardID);
        }

        //Token redeem
        if(_tokenReward > 0) {
            //Send token reward
            require(tokenContract.transfer(msg.sender, _tokenReward.mul(SCALAR)));
        }

        //Percentage redeem
        if(_percentageRedeem > 0) {

            //Get balance from staking contract
            (uint256 _stakedTokens,,) = stakingContract.stakerInformation(msg.sender);
            //Calculate percentage
            uint256 _percentageReward = mulDiv(_stakedTokens, _percentageRedeem, 100);
            //Send token reward
            require(tokenContract.transfer(msg.sender, _percentageReward));
        }
    }

    function redeemBoosterCard(uint256 _cardID, uint256 _cardToBoost) public {

        //Check ownership of card
        require(crafterContract.balanceOf(msg.sender, _cardID) > 0, "You do not own this card");

        //Grab data from booster card
        (,uint256 _cardType, uint256 boostAmount,,,,,,) = crafterContract.cards(_cardID);

        //Make sure this is a booster card
        require(_cardType == 3, "This is not a booster card");

        //Grab data from card to boost
        (,uint256 _cardTypeToBoost,,uint256 _intialRedeems,,,,,) = crafterContract.cards(_cardToBoost);

        //Check card being boosted is not a destructable / bulk card or another booster card
        require(_cardTypeToBoost == 2, "Destructable and booster cards cannot be boosted");

        //Check card being boosted had initial redeems
        require(_intialRedeems > 0, "Collectable cards with no rewards cannot be boosted");

        //Boost and burn
        crafterContract.applyCardBooster(_cardToBoost, boostAmount);
        crafterContract.burnCard(msg.sender,_cardID,1);
    }

    //Transfer ownership to new owner
    function transferOwnership(address payable _newOwner) public onlyOwner {
        require(_newOwner != address(0), "New owner cannot be a zero address");
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }

    //Remove owner from the contract
    function renounceOwnership() public onlyOwner {
        emit OwnershipRenounced(owner, address(0));
        owner = address(0);
    }

    //Close the contract and transfer any balances to the owner
    function closeContract() public payable onlyOwner {
        require(tokenContract.transfer(owner, tokenContract.balanceOf(address(this))));
        selfdestruct(owner);
    }

    //Modifiers
    modifier onlyOwner() {
        require(owner == msg.sender, "Only the owner of the rewards contract can call this function");
        _;
    }
}