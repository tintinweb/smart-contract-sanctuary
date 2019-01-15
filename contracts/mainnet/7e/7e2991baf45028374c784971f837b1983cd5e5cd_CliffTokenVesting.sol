pragma solidity ^0.5.2;

contract ERC20TokenInterface {

    function totalSupply () external view returns (uint);
    function balanceOf (address tokenOwner) external view returns (uint balance);
    function transfer (address to, uint tokens) external returns (bool success);
    function transferFrom (address from, address to, uint tokens) external returns (bool success);

}

library SafeMath {

    function mul (uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        require(c / a == b);
        return c;
    }
    
    function div (uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }
    
    function sub (uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        return a - b;
    }

    function add (uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        require(c >= a);
        return c;
    }

}

/**
 * @title Permanent, linearly-distributed vesting with cliff for specified token.
 * Vested accounts can check how many tokens they can withdraw from this smart contract by calling
 * `releasableAmount` function. If they want to withdraw these tokens, they create a transaction
 * to a `release` function, specifying the account to release tokens from as an argument.
 */
contract CliffTokenVesting {

    using SafeMath for uint256;

    event Released(address beneficiary, uint256 amount);

    /**
     * Vesting records.
     */
    struct Beneficiary {
        uint256 start;
        uint256 duration;
        uint256 cliff;
        uint256 totalAmount;
        uint256 releasedAmount;
    }
    mapping (address => Beneficiary) public beneficiary;

    /**
     * Token address.
     */
    ERC20TokenInterface public token;

    uint256 public nonce = 696523;

    /**
     * Whether an account was vested.
     */
    modifier isVestedAccount (address account) { require(beneficiary[account].start != 0); _; }

    /**
    * Cliff vesting for specific token.
    */
    constructor (ERC20TokenInterface tokenAddress) public {
        require(tokenAddress != ERC20TokenInterface(0x0));
        token = tokenAddress;
    }

    /**
    * Calculates the releaseable amount of tokens at the current time.
    * @param account Vested account.
    * @return Withdrawable amount in decimals.
    */
    function releasableAmount (address account) public view returns (uint256) {
        return vestedAmount(account).sub(beneficiary[account].releasedAmount);
    }

    /**
    * Transfers available vested tokens to the beneficiary.
    * @notice The transaction fails if releasable amount = 0, or tokens for `account` are not vested.
    * @param account Beneficiary account.
    */
    function release (address account) public isVestedAccount(account) {
        uint256 unreleased = releasableAmount(account);
        require(unreleased > 0);
        beneficiary[account].releasedAmount = beneficiary[account].releasedAmount.add(unreleased);
        token.transfer(account, unreleased);
        emit Released(account, unreleased);
        if (beneficiary[account].releasedAmount == beneficiary[account].totalAmount) { // When done, clean beneficiary info
            delete beneficiary[account];
        }
    }

    /**
     * Allows to vest tokens for beneficiary.
     * @notice Tokens for vesting will be withdrawn from `msg.sender`&#39;s account. Sender must first approve this amount
     * for the smart contract.
     * @param account Account to vest tokens for.
     * @param start The absolute date of vesting start in unix seconds.
     * @param duration Duration of vesting in seconds.
     * @param cliff Cliff duration in seconds.
     * @param amount How much tokens in decimals to withdraw.
     */
    function addBeneficiary (
        address account,
        uint256 start,
        uint256 duration,
        uint256 cliff,
        uint256 amount
    ) public {
        require(amount != 0 && start != 0 && account != address(0x0) && cliff < duration && beneficiary[account].start == 0);
        require(token.transferFrom(msg.sender, address(this), amount));
        beneficiary[account] = Beneficiary({
            start: start,
            duration: duration,
            cliff: start.add(cliff),
            totalAmount: amount,
            releasedAmount: 0
        });
    }

    /**
    * Calculates the amount that is vested.
    * @param account Vested account.
    * @return Amount in decimals.
    */
    function vestedAmount (address account) private view returns (uint256) {
        if (block.timestamp < beneficiary[account].cliff) {
            return 0;
        } else if (block.timestamp >= beneficiary[account].start.add(beneficiary[account].duration)) {
            return beneficiary[account].totalAmount;
        } else {
            return beneficiary[account].totalAmount.mul(
                block.timestamp.sub(beneficiary[account].start)
            ).div(beneficiary[account].duration);
        }
    }

}