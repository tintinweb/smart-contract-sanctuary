/**
 *Submitted for verification at snowtrace.io on 2021-12-19
*/

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;


interface IERC20 {
    function decimals() external view returns (uint8);
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

interface IStaking {
    function stake( uint _amount, address _recipient ) external returns ( bool );
    function claim( address _recipient ) external;
}

contract StakingHelper {

    address public immutable staking;
    address public immutable Hocus;
    address public operator;
    uint8 public stakingMode;

    mapping(address => bool) public isWhiteListed;

    constructor ( address _staking, address _Hocus ) {
        require( _staking != address(0) );
        staking = _staking;
        require( _Hocus != address(0) );
        Hocus = _Hocus;
        operator = msg.sender;
    }

    function stake( uint _amount, address _recipient ) external {
        require(stakingMode == 0, "staking mode is not zero");

        IERC20( Hocus ).transferFrom( msg.sender, address(this), _amount );
        IERC20( Hocus ).approve( staking, _amount );
        IStaking( staking ).stake( _amount, _recipient );
        IStaking( staking ).claim( _recipient );
    }

    function stakeOnlyWhite( uint _amount, address _recipient ) external {
        require(stakingMode == 1, "staking mode is not zero");
        require(isWhiteListed[msg.sender], "msg.sender is not whiteListed") ;

        IERC20( Hocus ).transferFrom( msg.sender, address(this), _amount );
        IERC20( Hocus ).approve( staking, _amount );
        IStaking( staking ).stake( _amount, _recipient );
        IStaking( staking ).claim( _recipient );
    }

    function setWhiteAddress(address _account, bool _bValue) public {
        require(msg.sender == operator, "msg.sender is not operator");
        require(_account != address(0), "address is zero");

        isWhiteListed[_account] = _bValue;
    }

    function setWhiteLists(address [] memory _whiteLists) public {
        require(msg.sender == operator, "msg.sender is not operator");
        require(_whiteLists.length != 0, "white Lists is zero");

        uint256 k = 0;
        uint256 len = _whiteLists.length;
        for(k=0; k<len; k++) {
            isWhiteListed[_whiteLists[k]] = true;
        }
    }

    function setStakingMode(uint8 _mode) public {
        require(msg.sender == operator, "msg.sender is not operator");
        require(_mode < 2, "staking mode is biger than 2");

        stakingMode = _mode;
    }

}