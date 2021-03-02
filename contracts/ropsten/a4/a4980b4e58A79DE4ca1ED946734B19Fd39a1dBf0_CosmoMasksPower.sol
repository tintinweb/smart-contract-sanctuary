// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "./utils/Ownable.sol";
import "./CosmoMasksPowerERC20.sol";

interface ICosmoMasksShort {
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function totalSupply() external view returns (uint256);
    function isMintedBeforeReveal(uint256 index) external view returns (bool);
}


/**
 * CosmoMasksPower Contract (The native token of CosmoMasks)
 * https://TheCosmoMasks.com/
 * @dev Extends standard ERC20 contract
 */
contract CosmoMasksPower is Ownable, CosmoMasksPowerERC20 {
    using SafeMath for uint256;

    // Constants
    uint256 public constant SECONDS_IN_A_DAY = 86400;
    uint256 public constant INITIAL_ALLOTMENT = 1830e18;
    uint256 public constant PRE_REVEAL_MULTIPLIER = 2;

    // Public variables
    uint256 public emissionStart;
    uint256 public emissionEnd;
    uint256 public emissionPerDay = 10e18;
    mapping(uint256 => uint256) private _lastClaim;


    constructor(uint256 emissionStartTimestamp) public CosmoMasksPowerERC20("CosmoMasks Power", "CMP") {
        emissionStart = emissionStartTimestamp;
        emissionEnd = emissionStartTimestamp + (SECONDS_IN_A_DAY * 365 * 10);
        _setURL("https://TheCosmoMasks.com/");
    }

    /**
     * @dev When accumulated CMPs have last been claimed for a CosmoMask index
     */
    function lastClaim(uint256 tokenIndex) public view returns (uint256) {
        require(ICosmoMasksShort(cosmoMasksAddress).ownerOf(tokenIndex) != address(0), "CosmoMasksPower: owner cannot be 0 address");
        require(tokenIndex < ICosmoMasksShort(cosmoMasksAddress).totalSupply(), "CosmoMasksPower: CosmoMasks at index has not been minted yet");

        uint256 lastClaimed = uint256(_lastClaim[tokenIndex]) != 0
            ? uint256(_lastClaim[tokenIndex])
            : emissionStart;
        return lastClaimed;
    }

    /**
     * @dev Accumulated CMP tokens for a CosmoMask token index.
     */
    function accumulated(uint256 tokenIndex) public view returns (uint256) {
        require(block.timestamp > emissionStart, "CosmoMasksPower: emission has not started yet");
        require(ICosmoMasksShort(cosmoMasksAddress).ownerOf(tokenIndex) != address(0), "CosmoMasksPower: owner cannot be 0 address");
        require(tokenIndex < ICosmoMasksShort(cosmoMasksAddress).totalSupply(), "CosmoMasksPower: CosmoMasks at index has not been minted yet");

        uint256 lastClaimed = lastClaim(tokenIndex);

        // Sanity check if last claim was on or after emission end
        if (lastClaimed >= emissionEnd)
            return 0;

        // Getting the min value of both
        uint256 accumulationPeriod = block.timestamp < emissionEnd ? block.timestamp : emissionEnd;
        uint256 totalAccumulated = accumulationPeriod.sub(lastClaimed).mul(emissionPerDay).div(SECONDS_IN_A_DAY);

        // If claim hasn't been done before for the index, add initial allotment (plus prereveal multiplier if applicable)
        if (lastClaimed == emissionStart) {
            uint256 initialAllotment = ICosmoMasksShort(cosmoMasksAddress).isMintedBeforeReveal(tokenIndex) == true
                ? INITIAL_ALLOTMENT.mul(PRE_REVEAL_MULTIPLIER)
                : INITIAL_ALLOTMENT;
            totalAccumulated = totalAccumulated.add(initialAllotment);
        }

        return totalAccumulated;
    }

    /**
     * @dev Permissioning not added because it is only callable once. It is set right after deployment and verified.
     */
    function setCosmoMasksAddress(address masksAddress) public onlyOwner {
        require(cosmoMasksAddress == address(0), "CosmoMasks: CosmoMasks has already setted");
        require(masksAddress != address(0), "CosmoMasks: CosmoMasks is the zero address");
        cosmoMasksAddress = masksAddress;
    }

    /**
     * @dev Claim mints CMPs and supports multiple CosmoMask token indices at once.
     */
    function claim(uint256[] memory tokenIndices) public returns (uint256) {
        require(block.timestamp > emissionStart, "CosmoMasksPower: Emission has not started yet");

        uint256 totalClaimQty = 0;
        for (uint256 i = 0; i < tokenIndices.length; i++) {
            // Sanity check for non-minted index
            require(tokenIndices[i] < ICosmoMasksShort(cosmoMasksAddress).totalSupply(), "CosmoMasksPower: CosmoMasks at index has not been minted yet");
            // Duplicate token index check
            for (uint256 j = i + 1; j < tokenIndices.length; j++)
                require(tokenIndices[i] != tokenIndices[j], "CosmoMasksPower: duplicate token index" );

            uint256 tokenIndex = tokenIndices[i];
            require(ICosmoMasksShort(cosmoMasksAddress).ownerOf(tokenIndex) == msg.sender, "CosmoMasksPower: sender is not the owner");

            uint256 claimQty = accumulated(tokenIndex);
            if (claimQty != 0) {
                totalClaimQty = totalClaimQty.add(claimQty);
                _lastClaim[tokenIndex] = block.timestamp;
            }
        }

        require(totalClaimQty != 0, "CosmoMasksPower: no accumulated tokens");
        _mint(msg.sender, totalClaimQty);
        return totalClaimQty;
    }

    function setURL(string memory newUrl) public onlyOwner {
        _setURL(newUrl);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

import "./libraries/SafeMath.sol";
import "./utils/Context.sol";

interface IERC20Burnable {
    function burn(uint256 amount) external returns (bool);
    function burnFrom(address account, uint256 amount) external returns (bool);
    // ERC20
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


/**
 * @dev Implementation of the {IERC20} interface.
 */
abstract contract CosmoMasksPowerERC20 is Context, IERC20Burnable {
    using SafeMath for uint256;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    uint256 private _totalSupply;
    string private _name;
    string private _symbol;
    uint8 private _decimals;
    string private _url;
    address public cosmoMasksAddress;


    constructor(string memory name_, string memory symbol_) internal {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    function url() public view returns (string memory) {
        return _url;
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

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
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
        // Approval check is skipped if the caller of transferFrom is the CosmoMasks contract. For better UX.
        if (msg.sender != cosmoMasksAddress)
            _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "CosmoMasksPower: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "CosmoMasksPower: decreased allowance below zero"));
        return true;
    }

    function burn(uint256 amount) public override returns (bool) {
        _burn(_msgSender(), amount);
        return true;
    }

    function burnFrom(address account, uint256 amount) public override returns (bool) {
        uint256 decreasedAllowance = allowance(account, _msgSender()).sub(amount, "CosmoMasksPower:  burn amount exceeds allowance");
        _approve(account, _msgSender(), decreasedAllowance);
        _burn(account, amount);
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "CosmoMasksPower: transfer from the zero address");
        require(recipient != address(0), "CosmoMasksPower: transfer to the zero address");
        _balances[sender] = _balances[sender].sub(amount, "CosmoMasksPower: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "CosmoMasksPower: mint to the zero address");
        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "CosmoMasksPower: burn from the zero address");
        _balances[account] = _balances[account].sub(amount, "CosmoMasksPower: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "CosmoMasksPower: approve from the zero address");
        require(spender != address(0),"CosmoMasksPower: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _setURL(string memory newUrl) internal {
        _url = newUrl;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 */
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction.
 */
abstract contract Context {
    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

import "./Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 */
abstract contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}