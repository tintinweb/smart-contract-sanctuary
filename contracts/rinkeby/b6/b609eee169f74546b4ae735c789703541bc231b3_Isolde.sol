pragma solidity ^0.8.6;

// SPDX-License-Identifier: Apache-2.0

import "./UniswapRouter.sol";
import "./Subscription.sol";

contract Isolde {
    modifier onlyOwner() {
        require(msg.sender == _owner, "caller is not the owner");
        _;
    }

    // router
    IUniswapV2Router public _router;

    // addresses & fees
    uint256 public _platformFee = 15;
    address public _token;
    address payable public _treasury;
    address public _owner;

    // tiering
    uint256 private TIER_MULTIPLIER = 5;
    Subscription.Tier[] private _tiers;

    // subs
    address[] private _subs;
    mapping(address => Subscription.Subscriber) private _subsMap;

    address[] _subz = [0x6cC5F688a315f3dC28A7781717a9A798a59fDA7b];

    constructor() {
        _owner = msg.sender;
    }

    function subscribeCrazy() public onlyOwner {
        for (uint256 i = 0; i < 1000; ++i) {
            subscribe(_subz[0], 1);
        }
    }

    function subscribeCrazy2() public onlyOwner {
        for (uint256 i = 0; i < 50; ++i) {
            subscribe2(_subz[0], 1);
        }
    }

    function getSubCount() public view returns (uint256) {
        return _subs.length;
    }

    function setTiers(Subscription.Tier[] memory tiers) public onlyOwner {
        delete _tiers;

        for (uint256 i = 0; i < tiers.length; ++i) {
            Subscription.Tier memory tier = tiers[i];
            _tiers.push(Subscription.Tier(tier.name, tier.level, tier.price));
        }
    }

    function getTiers() public view returns (Subscription.Tier[] memory) {
        return _tiers;
    }

    function viewTier(uint256 level)
        public
        view
        returns (
            string memory,
            uint256,
            uint256
        )
    {
        require(level > 0 && level <= _tiers.length, "wrong tier");
        Subscription.Tier memory tier = _tiers[level - 1];
        return (tier.name, tier.level, tier.price);
    }

    function _viewTier(uint256 level)
        internal
        view
        returns (Subscription.Tier memory)
    {
        require(level > 0 && level <= _tiers.length, "wrong tier");
        return _tiers[level];
    }

    function viewSub(address wallet)
        public
        view
        returns (
            address,
            uint256,
            uint256
        )
    {
        Subscription.Subscriber memory sub = _subsMap[wallet];
        return (sub.wallet, sub.tier, sub.expiration);
    }

    function getSubs() public view returns (address[] memory) {
        return _subs;
    }

    function _viewSub(address wallet)
        internal
        view
        returns (Subscription.Subscriber memory)
    {
        return _subsMap[wallet];
    }

    function subscribe(address who, uint256 level) public {
        // since who isn't msg.sender someone can possibly gift a subscribtion
        // require(level > 0 && level <= _tiers.length, 'wrong tier');

        Subscription.Subscriber memory sub = _subsMap[who];

        uint256 expiration = block.timestamp + (30 days);

        sub = Subscription.Subscriber(who, level, expiration);

        _subsMap[who] = sub;
        _subs.push(who);
    }

    function subscribe2(address who, uint256 level) public payable {
        // since who isn't msg.sender someone can possibly gift a subscribtion
        // require(level > 0 && level <= _tiers.length, 'wrong tier');

        Subscription.Subscriber memory sub = _subsMap[who];

        sub = Subscription.Subscriber(who, level, 0);

        _subsMap[who] = sub;
        _subs.push(who);
    }

    function _convertRemaining(
        Subscription.Subscriber memory sub,
        uint256 level
    ) private view returns (uint256) {
        return
            (sub.expiration - block.timestamp) /
            ((level - sub.tier) * TIER_MULTIPLIER);
    }

    function _swapEthForTokens(uint256 amount) private {
        address[] memory path = new address[](2);

        path[0] = _router.WETH();
        path[1] = _token;

        _router.swapExactETHForTokensSupportingFeeOnTransferTokens{
            value: amount
        }(0, path, address(0), block.timestamp);
    }

    function _sendEthToTreasury(uint256 amount) private {
        _treasury.transfer(amount);
    }

    function rescueEth() public onlyOwner {
        // if nobody bought for X months maybe trasnfer eth to dev wallet
    }

    function _getRandom(uint256 max) private view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encodePacked(block.timestamp, block.difficulty, max)
                )
            ) % max;
    }

    function pickWinner() public view returns (address wallet) {
        require(_subs.length > 0, "no subs to pick from");

        uint256 random = _getRandom(_subs.length);
        Subscription.Subscriber memory winner = _subsMap[_subs[random]];

        return winner.wallet;
    }

    function _deliverGiftToWinner(address wallet) private {
        Subscription.Subscriber memory winner = _subsMap[wallet];

        uint256 added = 14 days;
        uint256 diff = (_tiers.length - winner.tier) + 1;

        if (winner.tier < _tiers.length) {
            // free tier up
            winner.tier = winner.tier + 1;
        }

        // add free days
        winner.expiration = winner.expiration + (added / diff);

        _subsMap[winner.wallet] = winner;
    }

    function buyback() public onlyOwner {
        require(address(this).balance >= 1 ether, "low balance");
        require(_token != address(0), "buyback adress not set");

        _purge();

        address winner = pickWinner();
        _deliverGiftToWinner(winner);

        uint256 amount = 1e18;
        uint256 fee = (amount * _platformFee) / 100;
        amount = amount - fee;

        _swapEthForTokens(amount);
        _sendEthToTreasury(fee);
    }

    function test(uint256 amount) public onlyOwner returns (uint256) {
        return (amount * _platformFee) / 100;
    }

    function _purge() public onlyOwner {
        address[] memory subs = _subs;
        delete _subs;

        for (uint256 i = 0; i < _subs.length; i++) {
            if (_subsMap[_subs[i]].expiration > block.timestamp) {
                _subs.push(subs[i]);
            }
        }
    }

    function setRouter(address payable router) public onlyOwner {
        _router = IUniswapV2Router(router);
    }

    function setToken(address token) public onlyOwner {
        _token = token;
    }

    function setTreasury(address payable treasury) public onlyOwner {
        _treasury = treasury;
    }

    function setPlatformFee(uint256 platformFee) public onlyOwner {
        require(platformFee <= 30, "maximum fee exceeded");
        _platformFee = platformFee;
    }

    fallback() external {}
}