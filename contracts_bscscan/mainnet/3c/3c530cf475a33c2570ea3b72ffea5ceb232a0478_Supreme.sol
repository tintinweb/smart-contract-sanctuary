// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "./ERC20.sol";
import "./SafeMath.sol";

contract Supreme is ERC20 
{
    using SafeMath for uint256;
    uint TAX_FEE = 3;
    uint BURN_FEE = 2;
    address public owner;
    mapping (address => bool) public excludedFromTax;
    
    constructor() ERC20("Supreme Fintech", "SFT") 
    {
        _mint(msg.sender, 1000000000000 * 10 ** 18);
        owner = msg.sender;
        excludedFromTax[msg.sender] = true;
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) 
    {
        if (excludedFromTax[msg.sender] == true) 
        {
            _transfer(_msgSender(), recipient, amount);
        }
        else
        {
            uint burnt = amount.mul(BURN_FEE)/100;
            uint admamt = amount.mul(TAX_FEE)/100;
            _burn(_msgSender(), burnt);
            _transfer(_msgSender(),owner,admamt);
            _transfer(_msgSender(),recipient, amount.sub(burnt).sub(admamt));
        }
        return true;
    }
}