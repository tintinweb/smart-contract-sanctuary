/**
 *Submitted for verification at BscScan.com on 2021-09-02
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

contract KAPEXTransfer{
  address KODA_V1_ADDRESS = address(0x0);
  address KODA_V2_ADDRESS = address(0x0);
  address BURN_ADDRESS = address(0x0);
  mapping(address => bool) public redeemed;
  mapping(address => uint256) public limit;
  
  address admin;
  modifier hasNotRedeemed(){
      require(redeemed[msg.sender]!=true,"You have already redeemed your tokens");
      _;
  }
  modifier onlyAdmin(){
      require(msg.sender==admin,"msg.sender it not admin");
      _;
  }
  modifier ifContractsIntialised(){
      require(KODA_V1_ADDRESS!=address(0x0),"KODA v1 address not set");
      require(KODA_V2_ADDRESS!=address(0x0),"KODA v2 address not set");
      _;
  }
  modifier isBurnAddressInitialised(){
      require(BURN_ADDRESS!=address(0x0),"Burn address not set");
      _;
  }
  constructor() {
      admin = msg.sender;
  }
  function convertKODAtoKAPEX(uint256 _amount) ifContractsIntialised isBurnAddressInitialised external{
      IERC20(KODA_V1_ADDRESS).transferFrom(msg.sender,BURN_ADDRESS,_amount);
      IERC20(KODA_V2_ADDRESS).transfer(msg.sender,_amount*10**9);
  }
  function collectBonusKoda(uint256 _amount) hasNotRedeemed external{
      //require(_amount<limit[msg.sender])  uncomment this to enable check for amount OR just replace amount with limit[msg.sender] in the line below
      IERC20(KODA_V1_ADDRESS).transfer(msg.sender,_amount);
      redeemed[msg.sender] = true;
  }
  function setLimit(address _user,uint256 _limit) onlyAdmin external {
      limit[_user] = _limit;
      redeemed[_user] = false;
  }
  function setKODAv1Address(address _contract) onlyAdmin external {
      KODA_V1_ADDRESS = _contract;
  }
  function setKODAv2Address(address _contract) onlyAdmin external {
      KODA_V2_ADDRESS = _contract;
  }
  function setBurnAddress(address _burnAddress) onlyAdmin external {
      BURN_ADDRESS = _burnAddress;
  }
  function transferOwnership(address _newAdmin) onlyAdmin external {
      admin = _newAdmin;
  }
  function withdrawKODAv1(uint256 _amount) onlyAdmin external {
      IERC20(KODA_V1_ADDRESS).transfer(msg.sender,_amount);
  }
  function withdrawKODAv2(uint256 _amount) onlyAdmin external {
      IERC20(KODA_V2_ADDRESS).transfer(msg.sender,_amount);
  }
}