/**
 *Submitted for verification at Etherscan.io on 2021-12-16
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

interface IBEP20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the token name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view returns (address);

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
    function allowance(address _owner, address spender) external view returns (uint256);

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




library SafeMath {
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

contract Ownable {

  address public owner;

  modifier onlyOwner {
    require(msg.sender == owner, "Ownable: You are not the owner, Bye.");
    _;
  }

  constructor () public {
    owner = msg.sender;
  }
}

contract VENDER is Ownable{

    event Bought(uint256 amount);
    event Sold(uint256 amount);


    IBEP20 public token;
    uint256 public buyRate;
    uint256 public sellRate;

    constructor() public {
        
    }
    

    function buy() payable public {
        uint256 decimals = 18 - token.decimals();
        uint256 amountTobuy = msg.value * buyRate / (10 ** decimals);
        uint256 dexBalance = token.balanceOf(address(this));
        require(amountTobuy > 0, "You need to send some ether");
        require(amountTobuy <= dexBalance, "Not enough tokens in the reserve");
        token.transfer(msg.sender, amountTobuy);
        emit Bought(amountTobuy);
    }


    function sell(uint256 amount) public {
        require(amount > 0, "You need to sell at least some tokens");
        uint256 allowance = token.allowance(msg.sender, address(this));
        require(allowance >= amount, "Check the token allowance");
        token.transferFrom(msg.sender, address(this), amount);
        uint256 decimals = uint8(18) - token.decimals();
        uint256 bnbamount = (amount  * 10 ** decimals)/ sellRate;
        msg.sender.transfer(bnbamount);
        emit Sold(amount);
    }

    function setAsset(address assetAddr) onlyOwner public {
        token = IBEP20(assetAddr);
    }

    function setRate(uint256 _buyRate, uint256 _sellRate) onlyOwner public{
        buyRate =  _buyRate;
        sellRate = _sellRate;
    }

    function ownerTokenWithdrawWithAddress(address tokenAddress, uint256 amount) onlyOwner public {
        IBEP20 _token = IBEP20(tokenAddress);
        require(amount <= _token.balanceOf(address(this)),"The Token withdraw amount exceeds the balance.");
        _token.transfer(owner,amount);
    }
    
    function ownerTokenWithdraw(uint256 amount) onlyOwner public {
        require(amount <= token.balanceOf(address(this)),"The Token withdraw amount exceeds the balance.");
        token.transfer(owner,amount);
    }

    function ownerBNBwithdraw(uint256 amount) onlyOwner public {
        require(amount <= address(this).balance,"The BNB withdraw amount exceeds the balance.");
        msg.sender.transfer(amount);
    }
    function ownerBNBDeposit() public payable {
        // require(amount <= address(this).balance,"The BNB withdraw amount exceeds the balance.");
        // msg.sender.transfer(amount);
    }

}