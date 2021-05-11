/**
 *Submitted for verification at Etherscan.io on 2021-05-11
*/

/**
 *Submitted for verification at Etherscan.io on 2021-02-04
*/

// SPDX-License-Identifier: (c) Otsea.fi, 2021

pragma solidity ^0.6.12;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
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
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * @title SafeMath
 * @dev Unsigned math operations with safety checks that revert on error
 * 
 * @dev Default OpenZeppelin
 */
library SafeMath {
    /**
     * @dev Multiplies two unsigned integers, reverts on overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    /**
     * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Adds two unsigned integers, reverts on overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    /**
     * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
     * reverts when dividing by zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

contract Vesting {

    using SafeMath for uint256;

    IERC20 public token;

    uint256 public totalTokens;
    uint256 public releaseStart;
    uint256 public releaseEnd;

    mapping (address => uint256) public starts;
    mapping (address => uint256) public grantedToken;

    // this means, released but unclaimed amounts
    mapping (address => uint256) public released;

    event Claimed(address indexed _user, uint256 _amount, uint256 _timestamp);
    event Transfer(address indexed _from, address indexed _to, uint256 _amount, uint256 _timestamp);

    // do not input same recipient in the _recipients, it will lead to locked token in this contract
    function initialize(
        address _token,
        uint256 _totalTokens,
        uint256 _start,
        uint256 _period,
        address[] calldata _recipients,
        uint256[] calldata _grantedToken
    )
      public
    {
        require(releaseEnd == 0, "Contract is already initialized.");
        require(_recipients.length == _grantedToken.length, "Array lengths do not match.");

        releaseEnd = _start.add(_period);
        releaseStart = _start;

        token = IERC20(_token);
        token.transferFrom(msg.sender, address(this), _totalTokens);
        totalTokens = _totalTokens;
        uint256 sum = 0;

        for(uint256 i = 0; i<_recipients.length; i++) {
            starts[_recipients[i]] = releaseStart;
            grantedToken[_recipients[i]] = _grantedToken[i];
            sum = sum.add(_grantedToken[i]);
        }

        // We're gonna just set the weight as full tokens. Ensures grantedToken were entered correctly as well.
        require(sum == totalTokens, "Weight does not match tokens being distributed.");
    }

    /**
     * @dev User may claim tokens that have vested.
    **/
    function claim()
      public
    {
        address user = msg.sender;

        require(releaseStart <= block.timestamp, "Release has not started");
        require(grantedToken[user] > 0 || released[user] > 0, "This contract may only be called by users with a stake.");

        uint256 releasing = releasable(user);
        // updates the grantedToken
        grantedToken[user] = grantedToken[user].sub(releasing);

        // claim will claim both released and releasing
        uint256 claimAmount = released[user].add(releasing);

        // flush the released since released means "unclaimed" amount
        released[user] = 0;
        
        // and update the starts
        starts[user] = block.timestamp;
        token.transfer(user, claimAmount);
        emit Claimed(user, claimAmount, block.timestamp);
    }

    /**
     * @dev returns claimable token. buffered(released) token + token released from last update
     * @param _user user to check the claimable token
    **/
    function claimableAmount(address _user) external view returns(uint256) {
        return released[_user].add(releasable(_user));
    }

    /**
     * @dev returns the token that can be released from last user update
     * @param _user user to check the releasable token
    **/
    function releasable(address _user) public view returns(uint256) {
        if (block.timestamp < releaseStart) return 0;
        uint256 applicableTimeStamp = block.timestamp >= releaseEnd ? releaseEnd : block.timestamp;
        return grantedToken[_user].mul(applicableTimeStamp.sub(starts[_user])).div(releaseEnd.sub(starts[_user]));
    }

    /**
     * @dev Transfers a sender's weight to another address starting from now.
     * @param _to The address to transfer weight to.
     * @param _amountInFullTokens The amount of tokens (in 0 decimal format). We will not have fractions of tokens.
    **/
    function transfer(address _to, uint256 _amountInFullTokens)
      external
    {
        // first, update the released
        released[msg.sender] = released[msg.sender].add(releasable(msg.sender));
        released[_to] = released[_to].add(releasable(_to));

        // then update the grantedToken;
        grantedToken[msg.sender] = grantedToken[msg.sender].sub(releasable(msg.sender));
        grantedToken[_to] = grantedToken[_to].sub(releasable(_to));

        // then update the starts of user
        starts[msg.sender] = block.timestamp;
        starts[_to] = block.timestamp;

        // If trying to transfer too much, transfer full amount.
        uint256 amount = _amountInFullTokens.mul(1e18) > grantedToken[msg.sender] ? grantedToken[msg.sender] : _amountInFullTokens.mul(1e18);

        // then move _amount
        grantedToken[msg.sender] = grantedToken[msg.sender].sub(amount);
        grantedToken[_to] = grantedToken[_to].add(amount);

        emit Transfer(msg.sender, _to, amount, block.timestamp);
    }

}