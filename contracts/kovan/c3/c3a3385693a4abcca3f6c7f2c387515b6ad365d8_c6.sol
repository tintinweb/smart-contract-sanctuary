/**
*          (•̪●)
*        ███████]▄▄▄▄▄▄▄▄▃              ██████▅▅▅▅▅▅▅▅▅
*   .▂▄▅█████████▅▄▃▂         ..▂▄▅█████████▅▄▃▂
*  [███████████████████]          [███████████████████]
*_\◥⊙▲⊙▲⊙▲⊙▲⊙▲⊙▲⊙◤/_________\[email protected][email protected][email protected][email protected][email protected][email protected][email protected][email protected]_/___
*
*  
*         ███████]▄▄▄▄▄▄▄▄█            ████]▄▄▄▄▄▃
*  .▂▄▅█████████▅▄▃▂          ▄▅ ██████▅▄▃▂       
*  [██████████████████].          [████████████████]
* _\[email protected][email protected][email protected][email protected][email protected][email protected][email protected][email protected]_/_________\◥⊙▲⊙▲⊙▲⊙▲⊙▲⊙◤/_____   
*
*
*/

// SPDX-License-Identifier: MIT

pragma solidity =0.8.6;

import "./Interfaces.sol";

contract c6 is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcluded;
    address[] private _excluded;
    
    // AntiBot declarations:
    mapping (address => bool) private _antiBotDump;
    event botBanned (address botAddress, bool isBanned);

    // Token detalis.
    string private _name = 'c6';
    string private _symbol = 'c6';
    uint8 private _decimals = 9;
    
    // Total Supply.
    uint256 private constant _tTotal = 10000000 * 10**9;
    uint256 private constant MAX = ~uint256(0);
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    
    // Percentage of Fee tokens to burn for stacking/airdrops.
    uint256 private _tFeeTotal;
    string public feeBurnRate = "0.2%";
    
    // Socials links strings.
    string telegram = "https://t.me/xxx                ";
    string twitter = "https://twitter.com/xxx          ";
    string website  = "https://website.com/xxx         ";
    
    // Game items database.
    string[] private weapon = [
        "Small Cannon",
        "Large Cannon",
        "Double Cannon",
        "Slow Machine Gun",
        "Fast Machine Gun",
        "Rocket Launcher",
        "Ground Missile",
        "Air Missile",
        "Tracking Missile",
        "Nuclear Missile"
    ];
    string[] private armor = [
        "Metal Helm",
        "War Belt",
        "Anit-Fire Shield",
        "Anti-Missile Shield",
        "Additional Steel Body",
        "Caterpillars Shield",
        "Bulletproof Vest",
        "Engine Protection",
        "Shock Absorbers",
        "Titanium Hatch"
    ];
    string[] private health = [
        "First Aid Kit",
        "Bandages",
        "Painkillers",
        "Food",
        "Water",
        "Repair Kit",
        "Engine Oil",
        "New Battery",
        "New Caterpillars",
        "New Suspension"
    ];
    string[] private upgrade = [
        "Large Caterpillars",
        "Climb Improvement",
        "Engine Booster",
        "Special Fuel",
        "Large Exhaust",
        "Bigger Fuel Tank",
        "Double Fire",
        "Auto Tracking",
        "Wide Radar View",
        "Artifacts Scanner"
    ];
    string[] private artifact = [
        "Gold Ring",
        "Human Bone",
        "Garrison Flag",
        "Rusty Knife",
        "Binoculars",
        "Eagle Plate",
        "Purple Heart Medal",
        "Soldier Dog Tag",
        "Silver Bullet",
        "Lucky Medallion"
    ];
    
    address public uniswapV2router;
    
    constructor (address router) {
        uniswapV2router = router;

        // Generate Total Supply.
        _rOwned[_msgSender()] = _rTotal;
        emit Transfer(address(0), _msgSender(), _tTotal);
    
        // Exclude the contact Owner from stacking/airdrops.
        _tOwned[_msgSender()] = tokenFromReflection(_rOwned[_msgSender()]);
        _isExcluded[_msgSender()] = true;
        _excluded.push(_msgSender());
    }

    /**
     * @dev Anti-Bot-dump function. 
     * -add bot to banned address database,
     * -in case of mistake: repeated will reverse ban.
     * -emits botBanned event.
     *
     * Requirements:
     * -only contract Owner is allowed to call this function,
     * -when renouceOwnership is done (the Owner is zero address),
     * this function will be locked (cannot be called anymore).
     */
    function antiBotDump(address botAddress) external onlyOwner {
        if (_antiBotDump[botAddress] == true) {
            _antiBotDump[botAddress] = false;
        } else {_antiBotDump[botAddress] = true;
            emit botBanned (botAddress, _antiBotDump[botAddress]);
          }
    }
    
    /**
     * @dev Returns Bot address ban status:
     * -true: means Bot is banned.
     * -false: means Bot is free.
     */
    function checkAntiBot(address botAddress) public view returns (bool) {
        return _antiBotDump[botAddress];
    }
    
    /**
     * @dev Functions to operate game items database.
     */
    function random(string memory input) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }
    
    function gameItemWeapon(uint256 tokenNumber) public view returns (string memory) {
        return itemName(tokenNumber, "WEAPON", weapon);
    }
    
    function gameItemArmor(uint256 tokenNumber) public view returns (string memory) {
        return itemName(tokenNumber, "ARMOR", armor);
    }
    
    function gameItemHealth(uint256 tokenNumber) public view returns (string memory) {
        return itemName(tokenNumber, "HEALTH", health);
    }

    function gameItemUpgrade(uint256 tokenNumber) public view returns (string memory) {
        return itemName(tokenNumber, "UPGRADE", upgrade);
    }
    
    function gameItemArtifact(uint256 tokenNumber) public view returns (string memory) {
        return itemName(tokenNumber, "ARTIFACT", artifact);
    }
    
    function itemName(uint256 tokenId, string memory keyPrefix, string[] memory sourceArray) internal pure returns (string memory) {
        uint256 rand = random(string(abi.encodePacked(keyPrefix, toString(tokenId))));
        string memory output = sourceArray[rand % sourceArray.length];
        return output;
    }
     
    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
    
    function Telegram() public view returns (string memory) {
        return telegram;
    }
    
    function Twitter() public view returns (string memory) {
        return twitter;
    }
    
    function Website() public view returns (string memory) {
        return website;
    }
    
    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public pure override returns (uint256) {
        return _tTotal;
    }
    
    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcluded[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function alreadyBurnedFees() public view returns (uint256) {
        return _tFeeTotal;
    }
    
    function reflect(uint256 tAmount) public {
        address sender = _msgSender();
        require(!_isExcluded[sender], "Excluded addresses cannot call this function");
        (uint256 rAmount,,,,) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rTotal = _rTotal.sub(rAmount);
        _tFeeTotal = _tFeeTotal.add(tAmount);
    }

    function reflectionFromToken(uint256 tAmount, bool deductTransferFee) public view returns(uint256) {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        if (!deductTransferFee) {
            (uint256 rAmount,,,,) = _getValues(tAmount);
            return rAmount;
        } else {
            (,uint256 rTransferAmount,,,) = _getValues(tAmount);
            return rTransferAmount;
        }
    }

    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return rAmount.div(currentRate);
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    
    function _transfer(address sender, address recipient, uint256 amount) private {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        // anti-Bot-dump. Works only on the beginning. When renouceOwnership is done
        // (when the contract Owner is zero address) new Bots cannot be caught anymore.
        if (_antiBotDump[sender] || _antiBotDump[recipient])
        require (amount == 0, "Are you the cheating BOT? Hi, you are banned :)");
        // disable burn fee tokens when the Owner sends tokens and adds liquidity.
        if (sender == owner() || recipient == owner()) {
        _ownerTransfer(sender, recipient, amount);
        // enable burn fee tokens and airdrops for everyone else.
        } else if (_isExcluded[sender] && !_isExcluded[recipient]) {
        _transferFromExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && _isExcluded[recipient]) {
        _transferToExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && !_isExcluded[recipient]) {
        _transferStandard(sender, recipient, amount);
        } else if (_isExcluded[sender] && _isExcluded[recipient]) {
        _transferBothExcluded(sender, recipient, amount);
        } else {_transferStandard(sender, recipient, amount);}
    }
    
    /**
     * @dev Special transfer to disable burn fee tokens and airdrops
     * for the contract Owner, during each transaction like
     * tokens transfer and liquidity add.
     */
    function _ownerTransfer(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, , , , ) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        if (_isExcluded[sender]) {
            _tOwned[sender] = _tOwned[sender].sub(tAmount);
        }
        _rOwned[recipient] = _rOwned[recipient].add(rAmount);
        if (_isExcluded[recipient]) {
            _tOwned[recipient] = _tOwned[recipient].add(tAmount);
        }
        emit Transfer(sender, recipient, tAmount);
    }
    
    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);       
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferToExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);           
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);   
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);        
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }

    function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 tFee) = _getTValues(tAmount);
        uint256 currentRate =  _getRate();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, currentRate);
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee);
    }

    function _getTValues(uint256 tAmount) private pure returns (uint256, uint256) {
        // tokens burn rate 0.2% for stacking/airdrops.
        uint256 tFee = tAmount.div(1000).mul(2);
        uint256 tTransferAmount = tAmount.sub(tFee);
        return (tTransferAmount, tFee);
    }

    function _getRValues(uint256 tAmount, uint256 tFee, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee);
        return (rAmount, rTransferAmount, rFee);
    }

    function _getRate() private view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function _getCurrentSupply() private view returns(uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;      
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_rOwned[_excluded[i]] > rSupply || _tOwned[_excluded[i]] > tSupply) return (_rTotal, _tTotal);
            rSupply = rSupply.sub(_rOwned[_excluded[i]]);
            tSupply = tSupply.sub(_tOwned[_excluded[i]]);
        }
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }
}