// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./SafeMath.sol";
import "./Ownable.sol";

contract OctoCashier is Ownable {
    using SafeMath for uint256;

    ERC20[] public tokenInfo;
    mapping(ERC20 => bool) private tokenExistence;
    address public devAddress;
    address public costAddress;


    constructor(address _devAddress, address _costAddress) {
        devAddress = _devAddress;
        costAddress = _costAddress;
    }

    modifier nonDuplicated(ERC20 _token) {
        require(tokenExistence[_token] == false, "nonDuplicated: duplicated");
        _;
    }

    function addToken(ERC20 _token) public onlyOwner nonDuplicated(_token) {
        tokenExistence[_token] = true;
        tokenInfo.push(_token);
    }

    function tokenLength() external view returns (uint256) {
        return tokenInfo.length;
    }

    event Checkout(address indexed customer, uint256 tokenId, uint256 amount);
    function checkout(uint256 _tokenId, uint256 _amount, uint256 _devShare, uint256 _costShare) public {
        require(_devShare.add(_costShare) == 10000, "devShare and costShare must have a summary as 10000");
        require(_tokenId < tokenInfo.length, "unavailable token id");
        ERC20 token = tokenInfo[_tokenId];
        uint256 devAmount = _amount.mul(_devShare).div(10000);
        uint256 costAmount = _amount.mul(_costShare).div(10000);
        token.transferFrom(msg.sender, devAddress, devAmount);
        token.transferFrom(msg.sender, costAddress, costAmount);

        emit Checkout(msg.sender, _tokenId, _amount);
    }
}