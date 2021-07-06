/**
 *Submitted for verification at BscScan.com on 2021-07-06
*/

/**
 *Submitted for verification at BscScan.com on 2021-06-23
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.6;

interface IVBEP20 {
    function mint(uint mintAmount) external returns(uint);
    function redeem(uint redeemTokens) external returns (uint);
    function redeemUnderlying(uint redeemAmount) external returns (uint);
    function borrow(uint borrowAmount) external returns (uint);
    function repayBorrow(uint repayAmount) external returns (uint);
    function repayBorrowBehalf(address borrower, uint repayAmount) external returns (uint);
}

interface IVBNB {
    function mint() external payable;
    function redeem(uint redeemTokens) external returns (uint);
    function redeemUnderlying(uint redeemAmount) external returns (uint);
    function borrow(uint borrowAmount) external returns (uint);
    function repayBorrow() external payable;
    function balanceOfUnderlying(address owner) external returns (uint);
    function borrowBalanceCurrent(address account) external returns (uint);
}

interface IERC20 {
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

contract BSCVenus {


    receive() external payable {
    }

    function supplyToken(address _underlying, address _vToken, uint256 amount) external {
        require(_underlying != address(0), "BSCVenus.supplyToken: underlying address should not be zero address");
        require(_vToken != address(0), "BSCVenus.supplyToken: vtoken address should not be zero address");

        IERC20 underlying = IERC20(_underlying);
        IVBEP20 vToken = IVBEP20(_vToken);
        underlying.approve(address(vToken), amount);

        require(vToken.mint(amount) == 0, "BSCVenus.supplyToken: Error mint vtoken");
    }

    function withdrawToken(address _vToken, uint256 amount) external {
        require(_vToken != address(0), "BSCVenus.withdrawToken: vtoken address should not be zero address");

        IVBEP20 vToken = IVBEP20(_vToken);

        require(vToken.redeemUnderlying(amount) == 0, "BSCVenus.withdrawToken: Error reedem token");
    }

    function supplyBnb(address _vBnb) external payable {
        require(_vBnb != address(0), "BSCVenus.supplyBnb: vbnb address should not be zero address");

        IVBNB vBnb = IVBNB(_vBnb);
        vBnb.mint{value: msg.value}();
    }

    function withdrawBnb(address _vBnb, uint256 amount) external {
        require(_vBnb != address(0), "BSCVenus.withdrawToken: vBnb address should not be zero address");

        IVBNB vBnb = IVBNB(_vBnb);

        require(vBnb.redeemUnderlying(amount) == 0, "BSCVenus.withdrawToken: Error reedem token");
    }

    function borrowToken(address _vToken, uint256 amount) external {
        require(_vToken != address(0), "BSCVenus.borrowToken: vtoken address should not be zero address");

        IVBEP20 vToken = IVBEP20(_vToken);

        require(vToken.borrow(amount) == 0, "BSCVenus.borrowToken: Error borrow token");
    }

    function repayBorrowToken(address _underlying, address _vToken, uint256 amount) external {
        require(_underlying != address(0), "BSCVenus.repayBorrowToken: underlying address should not be zero address");
        require(_vToken != address(0), "BSCVenus.repayBorrowToken: vtoken address should not be zero address");

        IERC20 underlying = IERC20(_underlying);
        IVBEP20 vToken = IVBEP20(_vToken);
        underlying.approve(address(vToken), amount);

        require(vToken.repayBorrow(amount) == 0, "BSCVenus.repayBorrowToken: Error repay borrow token");
    }

    function borrowBnb(address _vBnb, uint256 amount) external {
        require(_vBnb != address(0), "BSCVenus.borrowBnb: vBnb address should not be zero address");

        IVBNB vBnb = IVBNB(_vBnb);

        require(vBnb.borrow(amount) == 0, "BSCVenus.borrowBnb: Error borrow bnb");
    }

    function repayBorrowBnb(address _underlying, address _vBnb) external payable {
        require(_underlying != address(0), "BSCVenus.repayBorrowBnb: underlying address should not be zero address");
        require(_vBnb != address(0), "BSCVenus.repayBorrowBnb: vbnb address should not be zero address");

        IVBNB vBnb = IVBNB(_vBnb);
        vBnb.repayBorrow{value: msg.value}();
    }
    
}