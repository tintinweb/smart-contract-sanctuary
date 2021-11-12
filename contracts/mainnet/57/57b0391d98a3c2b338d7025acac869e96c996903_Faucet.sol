// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./IERC20.sol";

contract Faucet {
    //once an address has claimed, it cannot claim anymore
    mapping(address => bool) private _used;
    //the ERC20 to be spent
    IERC20 private _contractAddress;
    //the owner of the generous token provider for this faucet
    address private _tokenOwner;
    //how much tokens we want to spend per claim
    uint256 private _tokensPerClaim;

    event Claim(address claimer, uint256 amount);

    constructor(address contractAddress, address tokenOwner, uint256 tokensPerClaim) {
        _contractAddress = IERC20(contractAddress);
        _tokenOwner = tokenOwner;
        _tokensPerClaim = tokensPerClaim;
    }

    function claim() external {
        require(!_used[msg.sender], "Same address cannot claim twice");
        //send tokens to the one who called this contract
        _contractAddress.transferFrom(_tokenOwner, msg.sender, _tokensPerClaim);
        //mark the address of the one who called this contract,
        //so this address cannot claim again
        _used[msg.sender] = true;
        emit Claim(msg.sender, _tokensPerClaim);
    }
}