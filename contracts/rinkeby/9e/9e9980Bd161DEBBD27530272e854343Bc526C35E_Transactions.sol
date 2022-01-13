//SPDX-License-Identifer: MIT
pragma solidity ^0.8.6;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

contract Transactions {

  uint public instrumentId;
  address public tokenAddress;

  constructor(address token){
     tokenAddress = token;
  }

  struct Instruments {
    address merchant;
    address token;
    uint amount;
    string name;
    
  }
  struct Purchases {
    address buyer;
    uint date;
  }
  mapping(uint => Instruments) public instruments;
  mapping(address => mapping(uint => Purchases)) public purchases;
  

  event InstrumentsCreated(
    address merchant,
    uint instrumentId,
    uint amount,
    uint date,
    string name
  );
  event PurchaseCreated(
    address buyer,
    address seller,
    uint amount,
    uint instrumentsId,
    uint date
  );
  event PaymentSent(
    address from,
    address to,
    uint amount,
    uint instrumentId,
    uint date
  );

  event FundsTransfer(
      address from,
      address to,
      uint256 amount,
      uint256 date,
      string _type
  );

  function createInstrument(address token, uint amount, string memory name) external {
    require(token != address(0), 'address cannot be null address');
    require(amount > 0, 'amount needs to be > 0');
    bytes memory testName = bytes(name);
    require(testName.length != 0, 'Name is required');
    instruments[instrumentId] = Instruments(
      msg.sender, 
      token,
      amount, 
      name
    );
    instrumentId++;
    emit InstrumentsCreated(
        msg.sender,
        instrumentId,
        amount,
        block.timestamp,
        name
    );
  }

  function purchase(uint instId) external payable {
    // pointer to token
    IERC20 token = IERC20(instruments[instId].token);
    // pointer to instruments
    Instruments storage instruts = instruments[instId];
    require(instruts.merchant != address(0), 'this instrument does not exist');

    // transfer coin from buyer to merchant
    token.transferFrom(msg.sender, instruts.merchant, instruts.amount);  
    emit PaymentSent(
      msg.sender, 
      instruts.merchant, 
      instruts.amount, 
      instId, 
      block.timestamp
    );

    purchases[msg.sender][instId] = Purchases(
      msg.sender, 
      block.timestamp
    );
    emit PurchaseCreated(
        msg.sender, 
        instruts.merchant, 
        instruts.amount, 
        instId, 
        block.timestamp);
  }


  function sendFunds(address payable receiver, uint256 amount) external payable
  {
  
    IERC20 token = IERC20(tokenAddress);
    require(
      receiver != address(0), 
      'this receivers address does not exist'
    );
   

    token.transferFrom(msg.sender, receiver, amount);  
    emit FundsTransfer(
      msg.sender,
      receiver, 
      amount, 
      block.timestamp,
      'lending/borrowing'
    );
    
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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