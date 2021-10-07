// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./SafeMath.sol";
import "./Address.sol";
import "./Ownable.sol";

contract PreSale is ERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    uint256 public _price;
    address payable _seller;
    mapping(address => bool) public _whitelisted;

    event Whitelisted(address account);
    event Create(uint256 amount);
    event Destroy(uint256 amount);

    constructor(
        string memory name,
        string memory symbol,
        uint256 price
    ) ERC20(name, symbol) {
        _price = price;
        _seller = payable(msg.sender);
    }

    function getSeller() public view returns(address) {
        return _seller;
    }

    function addWhitelist(address[] memory accounts) external onlyOwner {
        for (uint i = 0; i < accounts.length; i++) {
            _whitelisted[accounts[i]] = true;
            emit Whitelisted(accounts[i]);
        }
    }

    function removeWhitelist(address[] memory accounts) external onlyOwner {
        for (uint i = 0; i < accounts.length; i++) {
            _whitelisted[accounts[i]] = false;
            emit Whitelisted(accounts[i]);
        }
    }

    function create(uint256 amount) external payable {
        require(msg.value == _price.mul(amount), 'incorrect amount sent');

        // mint new token
        _mint(msg.sender, amount);
        emit Create(amount);

        // forward ETH to seller
        _seller.transfer(address(this).balance);
    }

    function destroy(uint256 amount) external  {
        require(msg.sender == _seller, 'Only seller can burn tokens');
        _burn(msg.sender, amount);
        emit Destroy(amount);
    }
}