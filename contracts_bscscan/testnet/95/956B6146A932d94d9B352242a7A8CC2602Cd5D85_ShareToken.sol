// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./ReentrancyGuard.sol";
import "./Operatable.sol";
import "./ERC20.sol";
import "./SafeMath.sol";
contract ShareToken is Operatable, ERC20
{
    using SafeMath for uint256;
    uint256 public ShareVal;
    uint256 public ProductId;
    
    constructor(uint256 productId) ERC20("Asset Management-Product Token", "AMPT" ) {
        ProductId = productId;
    }
    
    function mint(address account, uint256 amount) public onlyOwner{
        uint256 tokenAmount = amount.mul(10 ** decimals()).div(ShareVal);
        _mint(account, tokenAmount);
    }
    function burn(address account, uint256 amount) public onlyOwner{
        uint256 tokenAmount = amount.mul(10 ** decimals()).div(ShareVal);
        _burn(account, tokenAmount);
    }
    function updateShareVal(uint val) public onlyOwner{
        ShareVal = val;
    }
}