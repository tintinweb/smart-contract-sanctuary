pragma solidity ^0.8.0;

contract DemoContract {
    uint256 private _amount;
    uint8 _state = 0; //0 = mint disabled

    event AmountChanged(uint256 amount);
    event StateChanged(uint8 state);

    // Stores a new value in the contract
    function mint(uint256 amount) public payable {
        require(_state > 0, "Mint closed!!");
        _amount = amount;
        emit AmountChanged(amount);
    }

    function setState(uint8 state) public{
        _state = state;
        emit StateChanged(state);
    }

    // Reads the last stored value
    function retrieve() public view returns (uint256) {
        return _amount;
    }

    // Reads the last stored value
    function retrieveState() public view returns (uint8) {
        return _state;
    }
}