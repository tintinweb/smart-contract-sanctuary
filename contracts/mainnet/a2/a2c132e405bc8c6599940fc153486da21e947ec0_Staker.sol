/**
 *Submitted for verification at Etherscan.io on 2021-05-04
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;
/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath{
    function mul(uint256 a, uint256 b) internal pure returns (uint256) 
    {
        if (a == 0) {
        return 0;}
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) 
    {
        uint256 c = a / b;
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) 
    {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) 
    {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }

}
/**
 * @dev Interface of the ERC standard.
 */
pragma solidity ^0.8.0;
/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
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

contract Staker {
    using SafeMath for uint;
    
    IERC20 public xDNA;
    uint[] timespans = [2592000, 7776000, 15552000, 31536000];
    uint[] rates = [103, 110, 123, 149];
    mapping(uint => address) public ownerOf;
    struct Stake {
        uint amount;
        uint reward;
        uint start;
        uint8 timespan;
        bool withdrawn;
        uint256 stakedAt;
    }
    Stake[] public stakes;

    function stake(uint _amount, uint8 _timespan) public returns (uint _tokenId) {
        require(block.timestamp < 1656547200,'Cannot Stake Amount After 30th June,2022');
        require(_amount >= 1000000000000000000,'Minimum of 1 token can be staked');
        require(_timespan < 4);
        require(xDNA.transferFrom(msg.sender, address(this), _amount));
        Stake memory _stake = Stake({
            amount: _amount,
            reward:_amount.mul(rates[_timespan]).div(100),
            start: block.timestamp,
            timespan: _timespan,
            withdrawn: false,
            stakedAt:block.timestamp
        });
        _tokenId = stakes.length;
        stakes.push(_stake);
        ownerOf[_tokenId] = msg.sender;
    }
    
    function unstake(uint _id) public {
        require(msg.sender == ownerOf[_id]);
        Stake storage _s = stakes[_id];
        uint8 _t = _s.timespan;
        require(_s.withdrawn == false);
        require(block.timestamp >= _s.start + timespans[_t]);
        require(xDNA.transfer(msg.sender, _s.amount.mul(rates[_t]).div(100)));
        _s.withdrawn = true;
    }
    
   
    function tokenUsed() public view returns (IERC20 t) {
        return xDNA;
    }
    function tokensOf(address _owner) public view returns (Stake[] memory ownerTokens) {
        uint _count = 0;
        for (uint i = 0; i < stakes.length; i++) {
            if (ownerOf[i] == _owner) _count++;
        }
        if (_count == 0) return new Stake[](0);
        ownerTokens = new Stake[](_count);
        uint _index = 0;        
        for (uint i = 0; i < stakes.length; i++) {

            if (ownerOf[i] == _owner) ownerTokens[_index++] = stakes[i];
        }
    }
    
    constructor (IERC20 _token) {
        xDNA = IERC20(_token);
    }
}