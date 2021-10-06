// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./SafeMath.sol";
import "./Address.sol";

contract PreSale is ERC20 {
    using SafeMath for uint256;
    using Address for address;

    uint256 public _price;
    uint256 public _maxSupply;
    uint256 public _currentSupply;
    address payable _seller;

    event Create(uint256 amount);
    event Destroy(uint256 amount);

    constructor(
        string memory name,
        string memory symbol,
        uint256 maxSupply,
        uint256 price
    ) ERC20(name, symbol) {
        _price = price;
        _seller = payable(msg.sender);
        _currentSupply = 0;
        _maxSupply = maxSupply;
    }

    function decimals() public view virtual override returns (uint8) {
        return 1;
    }

    function getSeller() public view returns(address) {
        return _seller;
    }

    function create(uint256 amount) external payable {
        require(msg.value == _price.mul(amount), 'incorrect amount sent');
        require(_currentSupply.add(amount) <= _maxSupply, 'tokens sold out');

        _currentSupply = _currentSupply.add(amount);

        // mint new token
        _mint(msg.sender, amount);
        emit Create(amount);

        // forward ETH to seller
        _seller.transfer(address(this).balance);
    }

    function destroy(uint256 amount) external  {
        require(msg.sender == _seller, 'Only seller can burn tokens');
        _burn(msg.sender, amount);
    }
}