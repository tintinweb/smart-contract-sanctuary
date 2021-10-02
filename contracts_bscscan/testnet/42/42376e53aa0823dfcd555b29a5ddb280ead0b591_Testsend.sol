/**
 *Submitted for verification at BscScan.com on 2021-10-01
*/

pragma solidity ^0.8.0;
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}
struct account_data {
    mapping(address => bool) referrals;
    address[] referrals_list;
    bool client;
    address refer1;
    address refer2;
    address refer3;
}
abstract contract Context {
   function _msgSender() internal view virtual returns (address) {
    return msg.sender;
}

function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}
contract PuzzleTokenV2 {
   function transfer(address recipient, uint256 amount) external returns (bool) {}
   function transferFrom(address sender, address recipient, uint256 amount) external returns (bool) {}
   function approve(address spender, uint256 amount) external returns (bool){}
   function balanceOf(address account) external view returns (uint256){}

}
contract Testsend is Context {
    mapping (address => account_data) private accountProfile;
    PuzzleTokenV2 c =  PuzzleTokenV2(0xf6a3eBeB5Bc4a38D4F160F56114ddD76A429c7a1);
    address pegasus;
    address perseus;
    constructor(address host, address _pegasus, address _perseus) payable{
        accountProfile[host].client = true;
        accountProfile[host].refer1 = host;
        accountProfile[host].refer2 = host;
        accountProfile[host].refer3 = host;
        pegasus = _pegasus;
        perseus = _perseus;
    }
    function setRefer(address referral, address referrer) internal {
        accountProfile[referral].refer1 = referrer;
        accountProfile[referral].refer2 = accountProfile[referrer].refer1;
        accountProfile[referral].refer3 = accountProfile[referrer].refer2;
        accountProfile[referrer].referrals_list.push(referral);
        accountProfile[referrer].referrals[referral] = true;
    }
    function getRefer(address referral) public view returns (address){
        return accountProfile[referral].refer1;
    }
    function getCountReferrals(address referrer) public view returns (uint){
        return accountProfile[referrer].referrals_list.length;
    }
    function getReferral(address referrer, uint index) public view returns(address){
        return accountProfile[referrer].referrals_list[index];
    }
    function getReferrals(address referrer) public view returns(address[] memory){
        return accountProfile[referrer].referrals_list;
    }
    function addRefer(address refer) public returns (bool){
        require (accountProfile[_msgSender()].refer1 != _msgSender(), "ERC20: You can't be a referrer of yourself");
        require (accountProfile[_msgSender()].client == false, "PZl: You already have a referrer");
        require (accountProfile[refer].client == true, "PZL: Invalid referrer address");
        setRefer(_msgSender(), refer);
        accountProfile[_msgSender()].client = true;
        return accountProfile[_msgSender()].client;
        
    }
    function approveSend(address spender,address spender2, uint256 amount) public returns(bool){
        c.approve(spender2,amount);
        return c.approve(spender,amount);
    }
    function sendAction(address addr,address addr2, uint count) public returns(bool) {
        c.transfer(addr2, count);
        return c.transfer(addr, count);
    }
    function callTransferFrom(address sender, address recipient, uint256 amount) private returns (bool) {
        return c.transferFrom(sender ,recipient ,amount);
    }
    function contractTax(address sender, uint256 amount) private returns (uint256) {
        uint256 temp3918 = SafeMath.mul(15, amount);
        callTransferFrom(sender, pegasus, temp3918);
        callTransferFrom(sender, perseus, temp3918);
        return SafeMath.mul(temp3918, 2);
    }
    function referrerPay(address sender, address mentor, uint256 amount) private returns (uint256){
        uint256 referTax1 = SafeMath.mul(5, amount);
        uint256 referTax2 = SafeMath.mul(3, amount);
        uint256 referTax3 = SafeMath.mul(2, amount);
        callTransferFrom(sender, accountProfile[sender].refer1, referTax1);
        callTransferFrom(sender, accountProfile[sender].refer2, referTax2);
        callTransferFrom(sender, accountProfile[sender].refer3, referTax3);
        callTransferFrom(sender, accountProfile[mentor].refer1, referTax1);
        callTransferFrom(sender, accountProfile[mentor].refer2, referTax2);
        callTransferFrom(sender, accountProfile[mentor].refer3, referTax3);
        return SafeMath.mul(amount, 20);
    }
    function buyMentoring(address mentor, uint256 amount) public returns (bool){
        address sender = _msgSender();
        require (c.balanceOf(sender) >= amount);
        uint256 percent = SafeMath.div(amount, 100);
        uint256 mentorPay = amount - contractTax(sender, percent) - referrerPay(sender, mentor, percent);
        return callTransferFrom(sender, mentor, mentorPay);

    }
}
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