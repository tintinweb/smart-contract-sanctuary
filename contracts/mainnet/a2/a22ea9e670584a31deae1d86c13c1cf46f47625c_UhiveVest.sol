// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./UhiveToken.sol";

contract UhiveVest {

    // The token being sold
    UhiveToken internal _token;

    // Owner of this contract
    address _owner;

    uint256 internal _releaseDate;

    function releaseDate() public view virtual returns (uint256) {
        return _releaseDate;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function token() public view virtual returns (UhiveToken) {
        return _token;
    }

    // Functions with this modifier can only be executed when the vesting period elapses
    modifier onlyWhenReleased {
        require(block.timestamp >= _releaseDate, "UhiveVest: Not ready for release...");
        _;
    }

    // Functions with this modifier can only be executed by the owner
    modifier onlyOwner() {
        require(msg.sender == _owner, "UhiveVest: Method only allowed for contract owner..");
        _;
    }

    constructor(address token_address_, uint256 releaseDate_){
        _token = UhiveToken(token_address_);
        _owner = msg.sender;
        _releaseDate = releaseDate_;
    }

    function extendVestingPeriod(uint256 newReleaseDate_) onlyOwner public {
        require(_releaseDate < newReleaseDate_, "UhiveVest: New date is before current release date...");
        _releaseDate = newReleaseDate_;
    }

    /**
    * Event for token transfer logging
    * @param purchaser who paid for the tokens
    * @param beneficiary who got the tokens
    * @param value weis paid for purchase
    * @param amount amount of tokens purchased
    */
    event TokenTransfer(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);


    //Transfer tokens to a specified address, works only after vesting period elapses
    function forwardTokens(address _beneficiary, uint256 amount) onlyOwner onlyWhenReleased public {
        _preValidateTokenTransfer(_beneficiary, amount);
        _deliverTokens(_beneficiary, amount);
    }

    //Withdraw tokens to owner wallet, works only after vesting period elapses
    function withdrawTokens() onlyOwner onlyWhenReleased public {
        uint256 vested = _token.balanceOf(address(this));
        require(vested > 0, "UhiveVest: Vested amount = 0...");
        _deliverTokens(_owner, vested);
    }

    //Change the owner wallet address
    function changeOwner(address _newOwner) onlyOwner public {
        require(_newOwner != address(0), "UhiveVest: Invalid owner address..");
        _owner = _newOwner;
    }

    // -----------------------------------------
    // Internal interface (extensible)
    // -----------------------------------------

    //Assertain the validity of the transfer
    function _preValidateTokenTransfer(address _beneficiary, uint256 _tokenAmount) internal pure {
        require(_beneficiary != address(0), "UhiveVest: Invalid beneficiary address...");
        require(_tokenAmount > 0, "UhiveVest: Amount = 0...");
    }

    //Forward the tokens from the contract to the beneficiary
    function _deliverTokens(address _beneficiary, uint256 _tokenAmount) internal {
        require(_token.transfer(_beneficiary, _tokenAmount) == true, "UhiveVest: Failed forwarding tokens");
        emit TokenTransfer(msg.sender, _beneficiary, 0, _tokenAmount);
    }

}