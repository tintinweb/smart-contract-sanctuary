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
    address payable _seller;
    uint256 public _purchaseLimit;
    mapping(address => bool) public _whitelisted;
    mapping(address => uint256) public _mintCount;

    event Whitelisted(address account);
    event Delisted(address account);
    event Price(uint256 price);
    event PurchaseLimit(uint256 limit);
    event Seller(address seller);
    event Create(uint256 amount);
    event Destroy(uint256 amount);

    constructor(
        string memory name,
        string memory symbol,
        uint256 price,
        uint256 purchaseLimit
    ) ERC20(name, symbol) {
        _price = price;
        _seller = payable(msg.sender);
        _purchaseLimit = purchaseLimit;
    }

    modifier onlyWhitelisted() {
        require(_whitelisted[msg.sender], "only whitelisted");
        _;
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

    function changeSeller(address account) external onlyOwner {
        _seller = payable (account);
        emit Seller(account);
    }

    function emptyETHBalance() external onlyOwner {
        _seller.transfer(address(this).balance);
    }

    function create(uint256 amount) external payable onlyWhitelisted {
        require(msg.value == _price.mul(amount), 'incorrect amount sent');
        require(_purchaseLimit > _mintCount[msg.sender],
            'account already has created the maximum amount of allowed tokens');

        // mint new token
        _mint(msg.sender, amount.mul(ETHER_DECIMALS));
        _mintCount[msg.sender] = _mintCount[msg.sender] + 1;
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