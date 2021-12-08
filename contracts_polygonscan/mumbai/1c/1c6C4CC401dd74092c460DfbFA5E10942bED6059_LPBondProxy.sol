/**
 *Submitted for verification at polygonscan.com on 2021-12-07
*/

//SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity 0.7.5;

// File: contracts/common/IManagerOwnable.sol

// 


interface IManagerOwnable {
  function manager() external view returns (address);

  function renounceManagement() external;
  
  function pushManagement( address newOwner_ ) external;
  
  function pullManagement() external;
}

// File: contracts/common/ManagerOwnable.sol

// 



contract ManagerOwnable is IManagerOwnable {

    address internal _owner;
    address internal _newOwner;

    event OwnershipPushed(address indexed previousOwner, address indexed newOwner);
    event OwnershipPulled(address indexed previousOwner, address indexed newOwner);

    constructor () {
        _owner = msg.sender;
        emit OwnershipPushed( address(0), _owner );
    }

    function manager() public view override returns (address) {
        return _owner;
    }

    modifier onlyManager() {
        require( _owner == msg.sender, "Ownable: caller is not the owner" );
        _;
    }

    function renounceManagement() public virtual override onlyManager() {
        emit OwnershipPushed( _owner, address(0) );
        _owner = address(0);
    }

    function pushManagement( address newOwner_ ) public virtual override onlyManager() {
        require( newOwner_ != address(0), "Ownable: new owner is the zero address");
        emit OwnershipPushed( _owner, newOwner_ );
        _newOwner = newOwner_;
    }
    
    function pullManagement() public virtual override {
        require( msg.sender == _newOwner, "Ownable: must be new owner to pull");
        emit OwnershipPulled( _owner, _newOwner );
        _owner = _newOwner;
    }
}

// File: contracts/common/IUniswapV2Router02.sol



interface IUniswapV2Router02 {

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
}

// File: contracts/common/IBondDepository.sol



interface IBondDepository {

    function deposit( 
        uint _amount, 
        uint _maxPrice,
        address _depositor
    ) external returns ( uint );
}

// File: contracts/common/IERC20.sol

// 


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

// File: contracts/LPBondProxy.sol

// 







contract LPBondProxy is ManagerOwnable {

    address public immutable router;
    address public immutable bondDepository;
    address public immutable lpToken;
    address public immutable tokenA;
    address public immutable tokenB;

    constructor(
        address _uniswapV2Router02,
        address _bondDepository,
        address _lptoken,
        address _tokenA,
        address _tokenB
     ) {
         router = _uniswapV2Router02;
         bondDepository = _bondDepository;
         lpToken = _lptoken;
         tokenA = _tokenA;
         tokenB = _tokenB;
    }

    function deposit(
        bool _tokenSelector, //  1 - tokenA, 0 - tokenB
        uint _amount,
        uint _maxBondPrice,
        address _depositor
    ) external {
        
        address tokenSource;
        address tokenTarget;

        if (_tokenSelector) {
            tokenSource = tokenA;
            tokenTarget = tokenB;
        } else {
            tokenSource = tokenB;
            tokenTarget = tokenA;
        }

        IERC20( tokenSource ).transferFrom(_depositor, address(this), _amount);

        // exchange half of tokenSource for tokenTarget
        uint amountA = _amount / 2;
        uint half = _amount - amountA;
        address[] memory path = new address[](2);
        path[0] = tokenSource;
        path[1] = tokenTarget;
        IERC20( tokenSource ).approve(router, half);
        uint[] memory amounts = IUniswapV2Router02( router ).swapExactTokensForTokens(half, 0, path, address(this), block.timestamp);

        uint amountB = amounts[1];

        // put liquidity
        IERC20( tokenSource ).approve(router, amountA);
        IERC20( tokenTarget ).approve(router, amountB);
        (uint filledA, uint filledB, uint liquidity) = IUniswapV2Router02( router ).addLiquidity(tokenSource, tokenTarget, amountA, amountB, 0, 0, address(this), block.timestamp);

        // deposit LP tokens
        IERC20( lpToken ).approve(bondDepository, liquidity);
        IBondDepository( bondDepository ).deposit(liquidity, _maxBondPrice, _depositor);

        // refund
        uint refundA = amountA - filledA;
        uint refundB = amountB - filledB;
        IERC20( tokenSource ).transferFrom(address(this), msg.sender, refundA);
        IERC20( tokenTarget ).transferFrom(address(this), msg.sender, refundB);

    }
}