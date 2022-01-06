//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// SafeMath {{{
// -----------------------------------------------------------------------------
/**
 * Standard SafeMath, stripped down to just add/sub/mul/div
 */
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }
}
// }}}

// IBEP20 {{{
// -----------------------------------------------------------------------------
/**
 * BEP20 standard interface.
 */
interface IBEP20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function getOwner() external view returns (address);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// }}}

// BOGAuth {{{
// -----------------------------------------------------------------------------
/**
 * Provides ownable & authorized contexts
 */
abstract contract BOGAuth {
    address owner;
    mapping (address => bool) private authorizations;

    constructor(address _owner) {
        owner = _owner;
        authorizations[_owner] = true;
    }

    /**
     * Function modifier to require caller to be contract owner
     */
    modifier onlyOwner() {
        require(isOwner(msg.sender)); _;
    }

    /**
     * Function modifier to require caller to be authorized
     */
    modifier authorized() {
        require(isAuthorized(msg.sender)); _;
    }

    /**
     * Authorize address. Any authorized address
     */
    function authorize(address adr) public authorized {
        authorizations[adr] = true;
        emit Authorized(adr);
    }

    /**
     * Remove address' authorization. Owner only
     */
    function unauthorize(address adr) public onlyOwner {
        authorizations[adr] = false;
        emit Unauthorized(adr);
    }

    /**
     * Check if address is owner
     */
    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }

    /**
     * Return address' authorization status
     */
    function isAuthorized(address adr) public view returns (bool) {
        return authorizations[adr];
    }

    /**
     * Transfer ownership to new address. Caller must be owner.
     */
    function transferOwnership(address payable adr) public onlyOwner {
        owner = adr;
        authorizations[adr] = true;
        emit OwnershipTransferred(adr);
    }

    event OwnershipTransferred(address owner);
    event Authorized(address adr);
    event Unauthorized(address adr);
}

// }}}

// IBOGWhitelister {{{
// -----------------------------------------------------------------------------
interface IBOGWhitelister {
    function isWhitelisted(address adr) external view returns (bool);
}
// }}}

// BOGBlacklist {{{
// -----------------------------------------------------------------------------
contract BOGBlacklist is BOGAuth, IBOGWhitelister {
    constructor() BOGAuth(msg.sender) {}
    
    function isWhitelisted(address adr) external view override returns (bool) {
        return false;
    }
}
// }}}

// BOGWhitelist {{{
// -----------------------------------------------------------------------------
contract BOGWhitelist is BOGAuth, IBOGWhitelister {
    mapping (address => bool) public whitelist;
    
    constructor() BOGAuth(msg.sender) {}
    
    function isWhitelisted(address adr) external view override returns (bool) {
        return whitelist[adr];
    }
    
    function addMany(address[] calldata holders) external authorized {
        for(uint256 i; i<holders.length; i++){
            whitelist[holders[i]] = true;
        }
    }
    
    function setWhitelisted(address holder, bool state) external authorized {
        whitelist[holder] = state;
    }
}

// }}}