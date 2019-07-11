/**
 *Submitted for verification at Etherscan.io on 2019-07-10
*/

// File: openzeppelin-solidity/contracts/token/ERC20/IERC20.sol

pragma solidity ^0.5.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see `ERC20Detailed`.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller&#39;s account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a `Transfer` event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through `transferFrom`. This is
     * zero by default.
     *
     * This value changes when `approve` or `transferFrom` are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller&#39;s tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * > Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender&#39;s allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an `Approval` event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller&#39;s
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a `Transfer` event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to `approve`. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: contracts/Fundraiser.sol

pragma solidity ^0.5.1;


contract Fundable {
    
    function() external payable {
        require(msg.data.length == 0); // only allow plain transfers
    }
    
    function tokenBalance(address token) public view returns (uint) {
        if (token == address(0x0)) {
            return address(this).balance;
        } else {
            return IERC20(token).balanceOf(address(this));
        }
    }
   
    function send(address payable to, address token, uint amount) internal {
        if (token == address(0x0)) {
            to.transfer(amount);
        } else {
            IERC20(token).transfer(to, amount);
        }
    }
}

contract Fundraiser is Fundable {
    address payable public recipient;
    uint public expiration;
    Grant public grant;
    mapping (address => uint) disbursed;

    constructor(address payable _recipient, address payable _sponsor, uint _expiration) public {
        require(_expiration > now);
        require(_expiration < now + 365 days);
        recipient = _recipient;
        expiration = _expiration;
        grant = new Grant(this, _sponsor);
    }

    function hasExpired() public view returns (bool) {
        return now >= expiration;
    }
    
    function raised(address token) external view returns (uint) {
        return tokenBalance(token) + disbursed[token] + grant.tokenBalance(token) - grant.refundable(token);
    }

    function disburse(address token) external {
        grant.tally(token);
        uint amount = tokenBalance(token);
        disbursed[token] += amount;
        send(recipient, token, amount);
    }

}

contract Grant is Fundable {
    struct Tally {
        uint sponsored;
        uint matched;
    }

    Fundraiser public fundraiser;
    address payable public sponsor; 
    mapping (address => Tally) tallied;
    
    constructor(Fundraiser _fundraiser, address payable _sponsor) public {
        fundraiser = _fundraiser;
        sponsor = _sponsor;
    }
    
    function refund(address token) external {
        tally(token);
        send(sponsor, token, tokenBalance(token));
    }

    function refundable(address token) external view returns (uint) {
        uint balance = tokenBalance(token);
        Tally storage t = tallied[token];
        return isTallied(t) ? balance : balance - matchable(token);
    }
    
    function sponsored(address token) external view returns (uint) {
        Tally storage t = tallied[token];
        return isTallied(t) ? t.sponsored : tokenBalance(token);
    }

    function matched(address token) external view returns (uint) {
        Tally storage t = tallied[token];
        return isTallied(t) ? t.matched : matchable(token);
    }
    
    function tally(address token) public {
        require(fundraiser.hasExpired());
        Tally storage t = tallied[token];
        if (!isTallied(t)) {
            t.sponsored = tokenBalance(token);
            t.matched = matchable(token);
            send(address(fundraiser), token, t.matched);
        }
    }
    
    // only valid before tally
    function matchable(address token) private view returns (uint) {
        uint donations = fundraiser.tokenBalance(token);
        uint granted = tokenBalance(token);
        return donations > granted ? granted : donations;
    }

    function isTallied(Tally storage t) private view returns (bool) {
        return t.sponsored != 0;
    }

}

// File: contracts/FundraiserFactory.sol

pragma solidity ^0.5.1;


contract FundraiserFactory {

	event NewFundraiser(
		address indexed deployer,
		address indexed recipient,
		address indexed sponsor,
		Fundraiser fundraiser,
		Grant grant,
		uint expiration);
    
    function newFundraiser(address payable _recipient, address payable _sponsor, uint _expiration) public returns (Fundraiser fundraiser, Grant grant) {
        fundraiser = new Fundraiser(_recipient, _sponsor, _expiration);
        grant = fundraiser.grant();
        emit NewFundraiser(msg.sender, _recipient, _sponsor, fundraiser, grant, _expiration);
    }

}