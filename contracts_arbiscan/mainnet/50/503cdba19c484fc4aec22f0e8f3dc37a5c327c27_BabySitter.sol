/**
 *Submitted for verification at arbiscan.io on 2022-01-14
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

// Interface for our erc20 token
interface IERC20 {
    function allowance(address tokenOwner, address spender)
        external
        view
        returns (uint256 remaining);
    function approve(address spender, uint256 tokens)
        external
        returns (bool success);
    function balanceOf(address tokenOwner)
        external
        view
    returns (uint256 balance);
    function transfer(address to, uint256 tokens)
        external
        returns (bool success);
    function transferFrom(
        address from,
        address to,
        uint256 tokens
    ) external returns (bool success);
}
interface ICudlFinance {
  function buyAccesory ( uint256 nftId, uint256 itemId ) external;
  function claimMiningRewards ( uint256 nftId ) external;
  function getPetInfo ( uint256 _nftId ) external view returns ( uint256 _pet, bool _isStarving, uint256 _score, uint256 _level, uint256 _expectedReward, uint256 _timeUntilStarving, uint256 _lastTimeMined, uint256 _timepetBorn, address _owner, address _token, uint256 _tokenId, bool _isAlive );
  function itemPrice ( uint256 ) external view returns ( uint256 );
  function setCareTaker ( uint256 _tokenId, address _careTaker, bool clearCareTaker ) external;

}

contract BabySitter {
    address public owner;
    uint256 public percentage = 2000;
    mapping (address => uint) public pendingRewards;
    IERC20 Cudl = IERC20(0x0f4676178b5c53Ae0a655f1B19A96387E4b8B5f2);
    ICudlFinance CudlFinance = ICudlFinance(0x58b1422b21d58Ae6073ba7B28feE62F704Fc2539);
    uint256 maxUint256 = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
    constructor() {
        owner = msg.sender;
    }
    modifier onlyOwner(){
        require(msg.sender == owner);
        _;
    }
    // Only current owner can set a new owner to the contract. 
    function newOwner(address _owner) public onlyOwner {
        owner = _owner;
    }
    // Sets the owner's cut of cudl rewards in basis points.
    // Only owner can set 
    // Owners cut goes towards gas costs, server costs, and profits
    function newPercentage(uint256 _percentage) public onlyOwner {
        percentage = _percentage;
    }
    // Feeds and claims cudl from multiple pets
    function FeedMultiple(uint256[] calldata ids, uint256[] calldata food) external {
        for(uint256 i = 0; i < ids.length; i++){
            Feed(ids[i], food[i]);
        }
    }
    // Feeds and claims a singe pet for internal use
    function Feed(uint256 id, uint256 food) internal {
        (, , , , , , , , address _parent, , ,) = CudlFinance.getPetInfo(id);
        uint256 price = CudlFinance.itemPrice(food);
        // Give maximum approval to the game contract so that we can always buy food. 
        if(Cudl.allowance(address(this), 0x58b1422b21d58Ae6073ba7B28feE62F704Fc2539) < price){
            Cudl.approve(0x58b1422b21d58Ae6073ba7B28feE62F704Fc2539, maxUint256);
        }
        CudlFinance.buyAccesory(id,food);
        uint256 before = Cudl.balanceOf(address(this));
        CudlFinance.claimMiningRewards(id);
        uint256 reward = Cudl.balanceOf(address(this)) - before;
        if(reward > price){
            Distribute(_parent, reward-price);
            return;
        }
        Cudl.transferFrom(_parent, address(this), price-reward);
    }
    // Distributes the cudl reward among parties to claim later
    function Distribute(address _parent, uint256 reward) private {
        //Keep 20%
        uint256 shareForX = reward * percentage / 10000;
        pendingRewards[_parent] += reward-shareForX;
        pendingRewards[address(this)] += shareForX;
    }
    // Allows the parent to claim their accumulated share of cudl
    function Claim(address _parent) external {
        require(_parent != address(this));
        require(_parent == msg.sender);
        uint256 amount = pendingRewards[_parent];
        pendingRewards[_parent] = 0;
        Cudl.transfer(_parent, amount);
    }
    // Allows the owner to claim their accumulated share of cudl
    function OwnerClaim() onlyOwner external {
        uint256 amount = pendingRewards[address(this)];
        pendingRewards[address(this)] = 0;
        Cudl.transfer(owner, amount);
    }   
    // Sets the caretakers of all current pets to a new address
    function Upgrade(uint256[] calldata ids, address caretaker) onlyOwner external {
        for(uint256 i = 0; i < ids.length; i++){
            CudlFinance.setCareTaker(ids[i], caretaker, false);
        }
    }
}