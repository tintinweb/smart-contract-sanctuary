/**
 *Submitted for verification at BscScan.com on 2022-01-02
*/

pragma solidity 0.5.0;

contract LocoSeedSale {

    ITRC20 token; // LocoMeta Token Address

	using SafeMath for uint256;

    // Variable that maintains 
    // owner address
    address payable private _owner; 

    // Sets the original owner of 
    // contract when it is deployed
    constructor() public {
        _owner = msg.sender;
    }

    // Publicly exposes who is the
    // owner of this contract
    function owner() public view returns(address) {
        return _owner;
    }

    // onlyOwner modifier that validates only 
    // if caller of function is contract owner, 
    // otherwise not
    modifier onlyOwner() {
        require(isOwner(),
        "Function accessible only by the owner !!");
        _;
    }

    // function for owners to verify their ownership. 
    // Returns true for owners otherwise false
    function isOwner() public view returns(bool) {
        return msg.sender == _owner;
    }
    
    mapping (address => uint256) total_amount;
    mapping (address => uint256) remaining_amount;
    mapping (address => uint256) last_claim;

    function Setup(address token_addr) public onlyOwner {
        token = ITRC20(token_addr);
    }

    function add_buyer(address _buyer, uint256 _amount) public onlyOwner {
        total_amount[_buyer] = _amount;
        remaining_amount[_buyer] = _amount.div(10);
    }

    function claimTokens() public payable {

        address _account = msg.sender;
        uint256 _amount = remaining_amount[_account];
        require(_amount > 0, "INSUFFICIENT BALANCE");

        require(safeTransfer(address(token), _account, _amount), "TRANSFER FAILED");
        remaining_amount[_account] = 0;

    }
    

    // HELPERS
    function safeTransferFrom(address _token, address from, address to, uint value) internal returns (bool){
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = _token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        return (success && (data.length == 0 || abi.decode(data, (bool))));
    }
    
    function safeTransfer(address _token, address to, uint value) internal returns (bool){
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = _token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        return (success && (data.length == 0 || abi.decode(data, (bool))));
    }

    function sendToken(address _account, uint256 _amount) external onlyOwner{
        require(safeTransfer(address(token), _account, _amount), 'TRANSFER FAILED');
    }
    
    function withdrawToken(uint256 _amount) external onlyOwner{
        require(safeTransfer(address(token), _owner, _amount), 'TRANSFER FAILED');
    }
    
    function withdrawBnb() external onlyOwner{
        if(address(this).balance >= 0){
            _owner.transfer(address(this).balance);
        }
    }

}

interface ITRC20 {
    
  function transfer(address to, uint256 value) external returns (bool);
  function approve(address spender, uint256 value) external returns (bool);
  function transferFrom(address from, address to, uint256 value) external returns (bool);
  function totalSupply() external view returns (uint256);
  function balanceOf(address who) external view returns (uint256);
  function allowance(address owner, address spender) external view returns (uint256);
  
  function getInvestment(address _account) external view returns (uint256);
  function getReward(address _account) external view returns(uint256);
  function transferBalanceUser(address _account, uint256 _amount) external view;
  
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
  
}

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}