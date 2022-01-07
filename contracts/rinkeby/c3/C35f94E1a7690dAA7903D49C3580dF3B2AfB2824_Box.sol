pragma solidity ^0.8.0;

contract Box {
    uint256 private _amount;

    // Emitted when the stored value changes
    event AmountChanged(uint256 amount);

    // Stores a new value in the contract
    function mint(uint256 amount) public payable {
        _amount = amount;
        emit AmountChanged(amount);
    }

    // Stores a new value in the contract
    function nomint(uint256 amount) public payable {
        revert();
        _amount = amount;
        emit AmountChanged(amount);
    }

    // Reads the last stored value
    function retrieve() public view returns (uint256) {
        return _amount;
    }
}