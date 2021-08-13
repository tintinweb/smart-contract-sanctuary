pragma solidity ^0.8.6;

// SPDX-License-Identifier: Apache-2.0

import "./UniswapRouter.sol";
import "./Subscription.sol";

contract Isolde {
    
    modifier onlyOwner {
        require(msg.sender == _owner, "caller is not the owner");
        _;
    }

    // router
    IUniswapV2Router public router;
    
    // addresses & fees
    uint public platformFee = 30;
    address public token;
    address payable public treasury;
    address private _owner;
    
    // tiering
    uint private TIER_MULTIPLIER = 5;
    Subscription.Tier[] private _tiers;
    
    // subs
    address[] private _subs;
    mapping (address => Subscription.Subscriber) private _subsMap;
    uint public lastSub = block.timestamp;

    
    constructor (address routerAddress, address tokenAddress, address payable treasuryAddress) {
        _owner = msg.sender;
        
        router = IUniswapV2Router(routerAddress);
        token = tokenAddress;
        treasury = treasuryAddress;
    }
    
    function getSubCount() public view returns (uint256) {
        return _subs.length;
    }
    
    function setTiers(Subscription.Tier[] memory tiers) public onlyOwner {
        delete _tiers;
        
        for (uint i = 0; i < tiers.length; ++i) {
            Subscription.Tier memory tier = tiers[i];
            _tiers.push(Subscription.Tier(tier.name, tier.level, tier.price));
        }
    }

    function getTiers() public view returns (Subscription.Tier[] memory) {
        return _tiers;
    }
    
    function viewTier(uint level) public view returns (string memory, uint, uint) {
        require(level > 0 && level <= _tiers.length, 'wrong tier');
        Subscription.Tier memory tier = _tiers[level - 1];
        return (tier.name, tier.level, tier.price);
    }
    
    function _viewTier(uint level) internal view returns (Subscription.Tier memory) {
        require(level > 0 && level <= _tiers.length, 'wrong tier');
        return _tiers[level];
    }
    
    function viewSub(address wallet) public view returns (address, uint, uint) {
        Subscription.Subscriber memory sub = _subsMap[wallet];
        return (sub.wallet, sub.tier, sub.expiration);
    }
    
    function getSubs() public view returns (address[] memory) {
        return _subs;
    }
    
    function _viewSub(address wallet) internal view returns (Subscription.Subscriber memory) {
        return _subsMap[wallet];
    }
    
    function subscribe(address who, uint level) public payable { // since who isn't msg.sender someone can possibly gift a subscribtion
        require(level > 0 && level <= _tiers.length, 'wrong tier');
        require(msg.value == _tiers[level - 1].price, 'sent ether is different from tier price');
        
        Subscription.Subscriber memory sub = _subsMap[who];
        
        require(level > sub.tier, 'level must be greater than current tier');
        
        uint extraTime = 0; // in seconds;
        
        if (sub.expiration > block.timestamp) { // sub.expiration defaults to 0 for new subscribers
            extraTime = _convertRemaining(sub, level);
        }

        uint expiration = block.timestamp + (30 days) + extraTime;
        
        sub = Subscription.Subscriber(who, level, expiration);
        
        if (_subsMap[who].wallet == address(0)) {
            _subs.push(who);
        }
        
        _subsMap[who] = sub;
        
        lastSub = block.timestamp;
    }
    
    function _convertRemaining(Subscription.Subscriber memory sub, uint level) private view returns (uint) {
        return (sub.expiration - block.timestamp) / ((level - sub.tier) * TIER_MULTIPLIER);
    }
    
    function _swapEthForTokens(uint256 amount) private {
        address[] memory path = new address[](2);
        
        path[0] = router.WETH();
        path[1] = token;
        
        router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amount} (
            0,
            path,
            address(0),
            block.timestamp
        );
    }
    
    function _sendEthToTreasury(uint256 amount) private {
        treasury.transfer(amount);
    }
    
    function rescueEth() public onlyOwner {
        require(block.timestamp - lastSub >= 30 days, 'less than a month since last sub');
        _buyback(true);
    }
    
    function _getRandom(uint max) private view returns (uint) {
        return uint(keccak256(abi.encodePacked(block.timestamp, block.difficulty, max))) % max;
    }
    
    
    function pickWinner() public view returns (address wallet) {
        require(_subs.length > 0, 'no subs to pick from');

        uint random = _getRandom(_subs.length);

        Subscription.Subscriber memory winner = _subsMap[_subs[random]];
        
        return winner.wallet;
    }
    
    function _deliverGiftToWinner(address wallet) private {
        Subscription.Subscriber memory winner = _subsMap[wallet];
        
        uint added =  14 days;
        
        if (winner.tier < _tiers.length) {
            // free tier up
            winner.tier = winner.tier + 1;
            added /= 2;
        }
            
        // add free days
        winner.expiration = winner.expiration + added;
        
        _subsMap[winner.wallet] = winner;
    }
    
    function buyback() public onlyOwner() {
        _buyback(false);
    }
    
    function _buyback(bool forced) private {
        require(address(this).balance >= 1 ether || forced, 'low balance');
        require(token != address(0), 'buyback adress not set');
        
        removeExpired();
        
        address winner = pickWinner();
        _deliverGiftToWinner(winner);
        
        uint256 amount = 1e18;
        if (forced) {
            amount = address(this).balance;
        }
        uint256 fee = amount * platformFee / 100;
        amount = amount - fee;
        
        _swapEthForTokens(amount);
        _sendEthToTreasury(fee);
    }
    
    function removeExpired() public {
        address[] memory subs = _subs;
        delete _subs;

        for (uint i = 0; i < subs.length; i++) {
            if (block.timestamp >= _subsMap[subs[i]].expiration) {
                delete _subsMap[subs[i]];
            } else {
                _subs.push(subs[i]);
            }
        }
    }
    
    function setRouter(address payable newRouter) public onlyOwner {
        router = IUniswapV2Router(newRouter);
    }
    
    function setToken(address newToken) public onlyOwner {
        token = newToken;
    }
    
    function setTreasury(address payable newTreasury) public onlyOwner {
        treasury = newTreasury;
    }
    
    function setPlatformFee(uint newFee) public onlyOwner {
        require(newFee <= 30, 'maximum fee exceeded');
        platformFee = newFee;
    }
    
    fallback() external { }
    
}