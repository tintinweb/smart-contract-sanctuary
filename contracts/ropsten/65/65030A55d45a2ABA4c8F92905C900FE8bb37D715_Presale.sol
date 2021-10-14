// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./SafeMath.sol";
import "./Address.sol";
import "./Ownable.sol";

contract Presale is ERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    uint256 ETHER_DECIMALS = 1000000000000000000;

    uint256 public _price;
    uint256 public _purchaseLimit;
    bool public _isOpen = false;
    mapping(address => bool) public _whitelisted;
    mapping(address => uint256) public _mintCount;

    event Whitelisted(address account);
    event Delisted(address account);
    event Price(uint256 price);
    event PurchaseLimit(uint256 limit);
    event Open(bool isOpen);
    event Create(uint256 amount);
    event Destroy(uint256 amount);

    constructor(
        string memory name,
        string memory symbol,
        uint256 price,
        uint256 purchaseLimit
    ) ERC20(name, symbol) {
        _price = price;
        _purchaseLimit = purchaseLimit;
    }

    modifier onlyOpened() {
        require(_isOpen, "sale not open");
        _;
    }

    modifier onlyWhitelisted() {
        require(_whitelisted[msg.sender], "only whitelisted");
        _;
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
            emit Delisted(accounts[i]);
        }
    }

    function changePrice(uint256 price) external onlyOwner {
        _price = price;
        emit Price(price);
    }

    function changePurchaseLimit(uint256 purchaseLimit) external onlyOwner {
        _purchaseLimit = purchaseLimit;
        emit PurchaseLimit(purchaseLimit);
    }

    function emptyETHBalance() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function open() external onlyOwner {
        _isOpen = !_isOpen;
        emit Open(_isOpen);
    }

    function create(uint256 amount) external payable onlyOpened onlyWhitelisted {
        require(msg.value == _price.mul(amount), 'incorrect amount sent');
        require(_purchaseLimit >= _mintCount[msg.sender] + amount,
            'account already has created the maximum amount of allowed tokens');

        // mint new token
        _mint(msg.sender, amount.mul(ETHER_DECIMALS));
        _mintCount[msg.sender] = _mintCount[msg.sender] + amount;
        emit Create(amount);

        // forward ETH to owner
        payable(owner()).transfer(address(this).balance);
    }

    function destroy(uint256 amount) external onlyOwner {
        _burn(msg.sender, amount);
        emit Destroy(amount);
    }
}