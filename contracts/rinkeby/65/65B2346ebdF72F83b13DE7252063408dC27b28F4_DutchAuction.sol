pragma solidity ^0.8.2;

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

contract DutchAuction{

IERC20 public token;
mapping (address => uint) public reserve;
mapping (address => uint) public committed;
uint256 public start;
uint256 public finish;
uint256 public startprice;
uint256 public tokensleft;
uint8 public open; // 0 = closed, 1 = open, 2 = ended 
address payable public owner;
uint256 public bought;
uint256 public price;
uint256 public tokensStart;
bool public hasClaimed;
uint256 public minprice;

constructor(IERC20 _token) {
token = _token;
owner = payable(msg.sender);
}

function startAuction(uint256 tokenamount, uint256 min, uint _startprice, uint _finish) public{
require (msg.sender == owner);
require (open == 0);
finish = _finish;
startprice = _startprice;
tokensleft = tokenamount;
tokensStart = tokenamount;
open = 1;
start = block.timestamp;
minprice = min;
}

function currentprice() public returns(uint256 current) {
require (open != 0);
if (open == 1){
price = startprice * ((finish - block.timestamp)*10000/(finish - start))/10000;
}
return(price);
}

function bid(uint256 amount) public payable{
require (open == 1);
require (currentprice() * amount >= msg.value);
if (currentprice() == 0 || currentprice() < minprice){
    open = 2;
}
if (tokensleft < amount){
amount = tokensleft;
}
tokensleft = tokensleft - amount;
reserve[msg.sender] += amount;
committed[msg.sender] += msg.value;
bought += amount;
if (tokensleft == 0){
open = 2;
}
}

function claim() public{
    require(open == 2);
uint256 refund;
token.transfer(msg.sender, reserve[msg.sender]);
committed[msg.sender] -= reserve[msg.sender] * price;
reserve[msg.sender] = 0;
refund = committed[msg.sender];
committed[msg.sender] = 0;
token.transfer(msg.sender, committed[msg.sender]);
payable(msg.sender).transfer(refund);
}

function withdraw() public{
require(msg.sender == owner);
require(hasClaimed == false);
require(open == 2);
hasClaimed = true;
owner.transfer(price * bought);
token.transfer(owner, tokensleft - tokensStart);
}
}

{
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "metadata": {
    "useLiteralContent": true
  },
  "libraries": {}
}