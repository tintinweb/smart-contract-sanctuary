// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "./ERC20.sol";
import "./AccessControl.sol";
import "./SafeMath.sol";

contract Theseus is ERC20, AccessControl{
    using SafeMath for uint256;
    
    bytes32 private constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 private constant TAXER_ROLE = keccak256("TAXER_ROLE");
    
    modifier onlyTaxer() {
        require(hasRole(TAXER_ROLE, msg.sender), "Only for taxer.");
        _;
    }
    
    address private _taxDestination;
    uint private _taxRate = 0;
    mapping (address => bool) private _taxWhitelist;
    function setTaxRate(uint256 rate) public onlyTaxer {
        require(rate >= 0 && rate <= 500, "Tax rate is too high!"); //
        _taxRate = rate;
    }

    function setTaxDestination(address account) public onlyTaxer {
        // destination can be adress(0), to burn
        _taxDestination = account;
    }

    function addToWhitelist(address account) public onlyTaxer {
        _taxWhitelist[account] = true;
    }

    function removeFromWhitelist(address account) public onlyTaxer {
        _taxWhitelist[account] = false;
    }

    function taxDestination() public view returns(address) {
        return _taxDestination;
    }

    function taxRate() public view returns(uint256) {
        return _taxRate;
    }

    function isInWhitelist(address account) public view returns(bool) {
        return _taxWhitelist[account];
    }
    
    //****************END OF TAX AREA*******************************//
    
    //*****************MINT AREA***********************************//
    modifier onlyMinter() {
        require(hasRole(MINTER_ROLE, msg.sender), "Restricted to minters.");
        _;
    }

    function mint(address to, uint amount) public onlyMinter {
        require(to != address(0), "Mint to zero address");
        _mint(to, amount);
    }

    //*****************END OF MINT AREA******************************//
    
    constructor(string memory _name, string memory _symbol, uint8 _decimals, uint256 _supply) ERC20(_name, _symbol) {
        _setupDecimals(_decimals);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _taxRate = 0;
        _taxDestination = msg.sender;
        
        uint256 init_supply = _supply.mul(10**_decimals);
        _mint(msg.sender, init_supply);
    }
    
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        address _sender = msg.sender;
        uint256 taxAmount = calcTaxAmount(_sender, recipient, amount);
        uint256 transferAmount = amount.sub(taxAmount);
        require(balanceOf(_sender) >= amount, "insufficient balance.");
        super.transfer(recipient, transferAmount);

        if (taxAmount != 0) {
            super.transfer(_taxDestination, taxAmount);
        }
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        uint256 taxAmount = calcTaxAmount(sender, recipient, amount);
        uint256 transferAmount = amount.sub(taxAmount);
        require(balanceOf(sender) >= amount, "insufficient balance.");
        super.transferFrom(sender, recipient, transferAmount);
        if (taxAmount != 0) {
            super.transferFrom(sender, _taxDestination, taxAmount);
        }
        return true;
    }
    
    function calcTaxAmount(address sender, address recipient, uint256 amount) private view returns (uint256){
        uint256 taxAmount = amount.mul(_taxRate).div(10000);
        if (_taxWhitelist[sender] == true || _taxWhitelist[recipient] == true) {
            taxAmount = 0;
        }
        return taxAmount;
    }
    
    function burn(uint amount) public {
        require(amount > 0);
        address _sender = msg.sender;
        require(balanceOf(_sender) >= amount);
        _burn(_sender, amount);
    }
}
