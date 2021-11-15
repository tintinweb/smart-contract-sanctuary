// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Trade {

  event askEvent(
    uint256 askId,
    address tokenA,
    address tokenB,
    uint256 amountA,
    uint256 amountB
  );
  event bidEvent(
    uint256 askId,
    address tokenA,
    address tokenB,
    uint256 amountA,
    uint256 amountB
  );

  struct Ask {
    uint256 _askId;
    address tokenA;
    address tokenB;
    uint256 amountA;
    uint256 amountB;
  }

  Ask[] public asks;
  mapping(uint256 => address) public askToOwner;
  mapping(address => uint256) public ownerAskCount;

  mapping(address => mapping(address => Ask[])) public typeOfTokenAsk;

/* Ask:  A user (asker) create a request to trade one asset to another, 
         sending the amount of asset they one to trade into the contract. 
         Input: types of asset one to trade, amount of the asset one to trade. */
  function askToken20_Token20(
    address _tokenA,
    address _tokenB,
    uint256 _amountA,
    uint256 _amountB)
  external 
  returns(uint256) {
    uint256 id = asks.length;
    asks.push(Ask(id, _tokenA, _tokenB, _amountA, _amountB));
    IERC20(_tokenA).transferFrom(msg.sender, address(this), _amountA);
    askToOwner[id] = msg.sender;
    ownerAskCount[msg.sender]++;
    typeOfTokenAsk[_tokenA][_tokenB].push(Ask(id, _tokenA, _tokenB, _amountA, _amountB));

    emit askEvent(id, _tokenA, _tokenB, _amountA, _amountB);
    return id;
  }

  function askToken20_ETH(
    address _tokenA,
    uint256 _amountA,
    uint256 _amountB)
  external
  returns(uint256) {
    require(_amountB > 0);
    uint256 id = asks.length;
    asks.push(Ask(id, _tokenA, address(0x0), _amountA, _amountB));
    IERC20(_tokenA).transferFrom(msg.sender, address(this), _amountA);
    askToOwner[id] = msg.sender;
    ownerAskCount[msg.sender]++;
    typeOfTokenAsk[_tokenA][address(0x0)].push(Ask(id, _tokenA, address(0x0), _amountA, _amountB));

    emit askEvent(id, _tokenA, address(0x0), _amountA, _amountB);
    return id;
  }

  function askETH_Token20(
    address _tokenB,
    uint256 _amountB)
  external
  payable
  returns(uint256) {
    require(msg.value > 0);
    uint256 id = asks.length;
    asks.push(Ask(id, address(0x0), _tokenB, msg.value, _amountB));
    askToOwner[id] = msg.sender;
    ownerAskCount[msg.sender]++;
    typeOfTokenAsk[address(0x0)][_tokenB].push(Ask(id, address(0x0), _tokenB, msg.value, _amountB));

    emit askEvent(id, address(0x0), _tokenB, msg.value, _amountB);
    return id;
  }

  function askETH_Token721(
    address _tokenB,
    uint256 _IdTokenB)
  external
  payable
  returns(uint256) {
    require(msg.value > 0);
    uint256 id = asks.length;
    asks.push(Ask(id, address(0x0), _tokenB, msg.value, _IdTokenB));
    askToOwner[id] = msg.sender;
    ownerAskCount[msg.sender]++;

    emit askEvent(id, address(0x0), _tokenB, msg.value, _IdTokenB);
    return id;
  }

/* Bid: A user (bidder) create a request to accept the ask request of other user and execute the trade. 
        Input: Ask request id, amount of asset the bidder want to trade. */
       
  function bidToken20_Token20(
    uint256 _askId,
    uint256 amountB_ToTrade)
    external  
    returns (bool) {
      require ( amountB_ToTrade > 0,"Token amounts aren't enough to trade!!!" );
      Ask storage askRequest = asks[_askId];
      address recipient = askToOwner[_askId];
      uint256 amountA_ToTrade = (amountB_ToTrade * askRequest.amountA) / askRequest.amountB;

      IERC20(askRequest.tokenB).transferFrom(msg.sender, recipient, amountB_ToTrade);
      if ( amountB_ToTrade <= askRequest.amountB){
        askRequest.amountB = askRequest.amountB - amountB_ToTrade;
      } else {
        askRequest.amountB = 0;
      }

      IERC20(askRequest.tokenA).transfer(msg.sender, amountA_ToTrade);
      if ( amountA_ToTrade <= askRequest.amountA ){
        askRequest.amountA = askRequest.amountA - amountA_ToTrade;
      } else {
        askRequest.amountA = 0;
      }

      emit bidEvent(_askId, askRequest.tokenA, askRequest.tokenB, amountA_ToTrade, amountB_ToTrade);
      return true;
  }

  function bidETH_Token20(
    uint256 _askId,
    uint256 amountB_ToTrade)
    external  
    returns (bool) {
      require ( amountB_ToTrade > 0,"Token amounts aren't enough to trade!!!" );
      Ask storage askRequest = asks[_askId];
      address recipient = askToOwner[_askId];
      uint256 amountA_ToTrade = (amountB_ToTrade * askRequest.amountA) / askRequest.amountB;

      IERC20(askRequest.tokenB).transferFrom(msg.sender, recipient, amountB_ToTrade);
      if ( amountB_ToTrade <= askRequest.amountB){
        askRequest.amountB = askRequest.amountB - amountB_ToTrade;
      } else {
        askRequest.amountB = 0;
      }

      payable(msg.sender).transfer( amountA_ToTrade);
      if ( amountA_ToTrade <= askRequest.amountA ){
        askRequest.amountA = askRequest.amountA - amountA_ToTrade;
      } else {
        askRequest.amountA = 0;
      }

      emit bidEvent(_askId, askRequest.tokenA, askRequest.tokenB, amountA_ToTrade, amountB_ToTrade);
      return true;
  }

  function bidToken20_ETH(
    uint256 _askId)
    external
    payable
    returns (bool) {
      require ( msg.value > 0,"Token amounts aren't enough to trade!!!" );
      Ask storage askRequest = asks[_askId];
      address recipient = askToOwner[_askId];
      uint256 amountA_ToTrade = (msg.value * askRequest.amountA) / askRequest.amountB;

      payable(recipient).transfer(msg.value);
      if ( msg.value <= askRequest.amountB){
        askRequest.amountB = askRequest.amountB - msg.value;
      } else {
        askRequest.amountB = 0;
      }

      IERC20(askRequest.tokenA).transfer(msg.sender, amountA_ToTrade);
      if ( amountA_ToTrade <= askRequest.amountA ){
        askRequest.amountA = askRequest.amountA - amountA_ToTrade;
      } else {
        askRequest.amountA = 0;
      }

      emit bidEvent(_askId, askRequest.tokenA, askRequest.tokenB, amountA_ToTrade, msg.value);
      return true;
  }

/* getAsk: Get all list of Asks */
  function getAsk() 
  external
  view 
  returns (Ask[] memory) {
    return asks;
  }

/* getAskCount: Get amount of Asks */
  function getAskCount()
  external
  view
  returns(uint256) {
    return asks.length;
  }

/* getAskInfor: Get information of one ask (  ) */
  function getAskInfor(
    uint256 index
  )
  external
  view
  returns(uint256, address, address, uint256, uint256) {
    return (asks[index]._askId, asks[index].tokenA, asks[index].tokenB, asks[index].amountA, asks[index].amountB);
  }

/* getTypeOfTokenAsk: return type of ask base on asset pair */
  function getTypeOfTokenAsk(
    address _tokenA,
    address _tokenB
  )
  external
  view
  returns (Ask[] memory){
    return typeOfTokenAsk[_tokenA][_tokenB];
  }

/* Calculate: calculate amout of token A to trade base on asset pair and amount of token B to trade. 
        Input: Ask request id, amount of asset the bidder want to trade. */
  function calculateTokenA_ReciveToken20_Token20(
    uint256 _askId,
    uint256 amountB_ToTrade)
    external
    view
    returns (uint256) {
      Ask memory askRequest = asks[_askId];
      uint256 amountA_ToTrade = (amountB_ToTrade * askRequest.amountA) / askRequest.amountB;
      return amountA_ToTrade;
    }

/* bestPrice: Get the best price of an asset pair. */
  function bestPrice(address _tokenA, address _tokenB)
  external
  view
  returns (uint256)
  {
    uint256 askBestPrice = asks[0].amountA / asks[0].amountB;
    uint256 counter = 0;
    for (uint256 i = 0; i < asks.length; i++) {
      if ( asks[i].tokenA == _tokenA && 
           asks[i].tokenB == _tokenB && 
           asks[i].amountA / asks[i].amountB >= askBestPrice ){
        counter = i;
      }
    }
    return counter;
  }

/* bestPrice_1: Get the best price of an asset pair Using multi-dimensional array. */
  function bestPrice_1(address _tokenA, address _tokenB)
  external
  view
  returns (uint256)
  {
    Ask[] memory askBestPrice = typeOfTokenAsk[_tokenA][_tokenB];
    uint256 max =0;
    uint256 counter = 0;
    for (uint256 i = 0; i < askBestPrice.length; i++) {
      if ( (askBestPrice[i].amountA / askBestPrice[i].amountB) >= max ){
        max = askBestPrice[i].amountA / askBestPrice[i].amountB;
        counter = i;
      }
    }
    return counter;
  }

}

// SPDX-License-Identifier: MIT

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

