pragma solidity 0.6.5;

import "./Ownable.sol";

contract Freezable is Ownable {
    mapping(address => bool) private _frozen;

    event Freeze(address indexed target);
    event Unfreeze(address indexed target);

    modifier whenNotFrozen(address target) {
        require(!_frozen[target], "Freezable : target is frozen");
        _;
    }

    function freeze(address target) external onlyOwner returns (bool success) {
        _frozen[target] = true;
        emit Freeze(target);
        success = true;
    }

    function unFreeze(address target)
        external
        onlyOwner
        returns (bool success)
    {
        _frozen[target] = false;
        emit Unfreeze(target);
        success = true;
    }

    function isFrozen(address target)
        external
        view
        returns (bool frozen)
    {
        return _frozen[target];
    }
}
