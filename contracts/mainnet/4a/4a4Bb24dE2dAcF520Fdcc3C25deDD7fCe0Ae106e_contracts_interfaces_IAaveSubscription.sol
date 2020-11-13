pragma solidity ^0.6.0;

abstract contract IAaveSubscription {
    function subscribe(uint128 _minRatio, uint128 _maxRatio, uint128 _optimalBoost, uint128 _optimalRepay, bool _boostEnabled) public virtual;
    function unsubscribe() public virtual;
}
