/**
 *Submitted for verification at Etherscan.io on 2021-07-05
*/

// File: contracts/IDefiERC20.sol

pragma solidity 0.5.12;


/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
 */
interface IDefiERC20 {
    function submitStakingReward(uint256 amount) external returns (bool);
    function submitMint(address account, uint256 amount) external returns (bool);
    function submitBurn(address from, uint256 amount) external returns (bool);
    function claimReward() external returns (uint256 userReward);
    function rewardOf(address account) external view returns (uint256);
    function totalBalanceOf(address account) external view returns (uint256);
        
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

// File: contracts/IDefiWrap.sol



/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
 */
interface IDefiWrap {
    function submitMint(address erc20Address, bytes32 hashSourceAddress, uint256 amount) external returns (bool);
    function submitStakingReward(address erc20Address, uint256 amount) external returns (bool);
    
    function erc20ImplementationOf(address erc20) external view returns (address);
}

// File: contracts/IAssets_Manager.sol



/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
 */
interface IAssetManager {
    function deposit(address erc20, address account, uint256 amount) external returns (bool);

    /**
    * claim stake reward for asset if available (e.g., mADA)
    * @return amount of reward for asset.
    */
    function claimStakingReward(address erc20) external returns (uint256);

    /**
    * claim user stake reward for asset if available (e.g., mADA)
    * @return amount of asset reward for user.
    */
    function claimReward(address erc20, address account) external returns (uint256);
    
    function transfer(address erc20, address sender, address receiver, uint256 amount) external returns (bool);

    function redeem(address erc20, address account, uint256 amount) external returns (bool);
    function pushUnderlying(address erc20, address to, uint amount) external;
}

// File: contracts/math/SafeMath.sol



/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
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
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
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
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: contracts/MAssets_Manager.sol

/**
 *Submitted for verification at Etherscan.io on 2020-06-19
*/

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.


contract ERC20 {
    function balanceOf(address whom) external view returns (uint);
    function allowance(address, address) external view returns (uint);
    function approve(address spender, uint amount) external returns (bool);
    function transfer(address dst, uint amt) external returns (bool);
    function transferFrom(address sender, address recipient, uint amount) external returns (bool);
}

// contract IBPool is ERC20 {
//     function isBound(address t) external view returns (bool);
//     function getFinalTokens() external view returns(address[] memory);
//     function getBalance(address token) external view returns (uint);
//     function setSwapFee(uint swapFee) external;
//     function setController(address controller) external;
//     function setPublicSwap(bool public_) external;
//     function finalize() external;
//     function bind(address token, uint balance, uint denorm) external;
//     function rebind(address token, uint balance, uint denorm) external;
//     function unbind(address token) external;
//     function joinPool(uint poolAmountOut, uint  maxAmountsIn) external;
//     function joinswapExternAmountIn(
//         address tokenIn, uint tokenAmountIn, uint minPoolAmountOut
//     ) external returns (uint poolAmountOut);
// }

contract IBFactory {
    function isBPool(address) external view returns (bool);
}

contract AssetManager is IAssetManager{
    using SafeMath for uint256;

    // mapping(erc20 => totalSupply) 
    // Total mint tokens (e.g., DP.mADA) for deposited assets (should equal to total deposits, including rewards) 
    mapping(address => uint256) public _totalSupply;
    
    //mADA address => User address => user balance (DP token)
    mapping (address => mapping(address => uint256)) public _DP_balances;

    // mapping(erc20 => totalPointSupply) 
    // Total minted points (e.g., LP.mADA)
    mapping(address => uint256) public _totalPointSupply;
    
    //mADA address => User address => user balance (LP token)
    mapping (address => mapping(address => uint256)) public _LP_balances;
    
    //pointRate decimal rate
    //mapping(address => uint256) public _LP_rates;
    uint256 private constant _rate_decimal = 10 ** 18;
    
    IDefiWrap private _wrapImplementation;

    address private _factory;    // BFactory address to check if a pool was created by this factory
    
    modifier _verifyPool_() {
        require(IBFactory(_factory).isBPool(msg.sender), "ERR_NOT_EXISTED_POOL");
        _;
    }
    
    constructor(address fac, address wrapAddress) public {
        _wrapImplementation = IDefiWrap(wrapAddress);
        _factory = fac;
    }

    function pushUnderlying(address erc20, address to, uint amount)
     _verifyPool_ external
    {
        bool xfer = ERC20(erc20).transfer(to, amount);
        require(xfer, "ERR_ERC20_FALSE");
    }
    
    function balanceOf(address erc20, address account)
        public view returns (uint256){
        return _DP_balances[erc20][account];
    }

    
    function pointBalanceOf(address erc20, address account)
        public view returns (uint256){
        return _LP_balances[erc20][account];
    }
    
    function pointRate(address erc20)
        public view returns (uint256){
        uint256 erc20TotalSupply = _totalSupply[erc20];
        uint256 erc20TotalPointSupply = _totalPointSupply[erc20];
        if(erc20TotalSupply == 0 || erc20TotalPointSupply == 0){
            return 1 * _rate_decimal;
        }
        //return bdiv(bmul(erc20TotalSupply, _rate_decimal), erc20TotalPointSupply);
        return (erc20TotalSupply.mul(_rate_decimal)).div(erc20TotalPointSupply);
    }
    
    function deposit(address erc20, address account, uint256 amount) external returns (bool){
        uint256 _mintedPoint = (amount.mul(_rate_decimal)).div(pointRate(erc20));
        _LP_balances[erc20][account] = (_LP_balances[erc20][account]).add(_mintedPoint);
        _DP_balances[erc20][account] = (_DP_balances[erc20][account]).add(amount);
        
        _totalPointSupply[erc20] = (_totalPointSupply[erc20]).add(_mintedPoint);
        _totalSupply[erc20] = (_totalSupply[erc20]).add(amount);
        return true;
    }
    
    function _addReward(address erc20, uint256 amount) 
        private returns (bool){
        _totalSupply[erc20] = (_totalSupply[erc20]).add(amount);    
    }
    
    function claimStakingReward(address erc20) public returns (uint256){
        if(_wrapImplementation.erc20ImplementationOf(erc20) == address(0)){
            return 0;
        }
        
        if(IDefiERC20(erc20).rewardOf(address(this)) > 0){
            uint256 reward = IDefiERC20(erc20).claimReward();
            _addReward(erc20, reward);
            return reward;
        }
        return 0;
    }
    
    function claimReward(address erc20, address account) public returns (uint256){
        claimStakingReward(erc20);
        uint256 _claimable = ((pointBalanceOf(erc20, account)).mul(pointRate(erc20))).div((_rate_decimal)).sub(balanceOf(erc20, account));
        uint256 _diffPointBalance = (pointBalanceOf(erc20, account)).sub(((balanceOf(erc20, account)).mul(_rate_decimal)).div(pointRate(erc20)));
        _LP_balances[erc20][account] = ((balanceOf(erc20, account)).mul(_rate_decimal)).div(pointRate(erc20));
        _totalSupply[erc20] = (_totalSupply[erc20]).sub(_claimable);
        _totalPointSupply[erc20] = (_totalPointSupply[erc20]).sub(_diffPointBalance);
        
        bool xfer = ERC20(erc20).transfer(account, _claimable);
        require(xfer, "ERR_ERC20_FALSE");
        return _claimable;
    }
    
    function transfer(address erc20, address sender, address receiver, uint256 amount) external returns (bool){
        if(_wrapImplementation.erc20ImplementationOf(erc20) == address(0)){
            return false;
        }
        claimReward(erc20, sender);
        uint256 _transferedPoint = ((pointBalanceOf(erc20, sender)).mul(amount)).div(balanceOf(erc20, sender));
        
        _DP_balances[erc20][sender] = (_DP_balances[erc20][sender]).sub(amount);
        _LP_balances[erc20][sender] = (_LP_balances[erc20][sender]).sub(_transferedPoint);
        
        _DP_balances[erc20][receiver] = (_DP_balances[erc20][receiver]).add(amount);
        _LP_balances[erc20][receiver] = (_LP_balances[erc20][receiver]).add(_transferedPoint);
        return true;
    }
    
    function redeem(address erc20, address account, uint256 amount) external returns (bool){
        if(_wrapImplementation.erc20ImplementationOf(erc20) == address(0)){
            return false;
        }
        claimReward(erc20, account);
        uint256 _burntPoint = ((pointBalanceOf(erc20, account)).mul(amount)).div(balanceOf(erc20, account));
        _LP_balances[erc20][account] = (_LP_balances[erc20][account]).sub(_burntPoint);
        _DP_balances[erc20][account] = (_DP_balances[erc20][account]).sub(amount);
        _totalSupply[erc20] = (_totalSupply[erc20]).sub(amount);
        _totalPointSupply[erc20] = (_totalPointSupply[erc20]).sub(_burntPoint);
        
        bool xfer = ERC20(erc20).transfer(account, _burntPoint);
        require(xfer, "ERR_ERC20_FALSE");
        
        return true;
    }
}

// File: contracts/BColor.sol

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.


contract BColor {
    function getColor()
        external view
        returns (bytes32);
}

contract BBronze is BColor {
    function getColor()
        external view
        returns (bytes32) {
            return bytes32("BRONZE");
        }
}

// File: contracts/BConst.sol

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.



contract BConst is BBronze {
    uint public constant BONE              = 10**18;

    uint public constant MIN_BOUND_TOKENS  = 2;
    uint public constant MAX_BOUND_TOKENS  = 2;

    uint public constant MIN_FEE           = BONE / 10**6;
    uint public constant MAX_FEE           = BONE / 10;
    uint public constant EXIT_FEE          = 0;

    uint public constant MIN_WEIGHT        = BONE;
    uint public constant MAX_WEIGHT        = BONE * 50;
    uint public constant MAX_TOTAL_WEIGHT  = BONE * 50;
    uint public constant MIN_BALANCE       = BONE / 10**12;

    uint public constant INIT_POOL_SUPPLY  = BONE * 100;

    uint public constant MIN_BPOW_BASE     = 1 wei;
    uint public constant MAX_BPOW_BASE     = (2 * BONE) - 1 wei;
    uint public constant BPOW_PRECISION    = BONE / 10**10;

    uint public constant MAX_IN_RATIO      = BONE / 2;
    uint public constant MAX_OUT_RATIO     = (BONE / 3) + 1 wei;
}

// File: contracts/BFactory.sol

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is disstributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.


// Builds new BPools, logging their addresses and providing `isBPool(address) -> (bool)`

// import "./BPool.sol";




contract MasterFactory {

  function createClone(address target) internal returns (address result) {
    bytes20 targetBytes = bytes20(target);
    assembly {
      let clone := mload(0x40)
      mstore(clone, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
      mstore(add(clone, 0x14), targetBytes)
      mstore(add(clone, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
      result := create(0, clone, 0x37)
    }
  }

}
interface IERC20 {
    event Approval(address indexed src, address indexed dst, uint amt);
    event Transfer(address indexed src, address indexed dst, uint amt);

    function totalSupply() external view returns (uint);
    function balanceOf(address whom) external view returns (uint);
    function allowance(address src, address dst) external view returns (uint);

    function approve(address dst, uint amt) external returns (bool);
    function transfer(address dst, uint amt) external returns (bool);
    function transferFrom(
        address src, address dst, uint amt
    ) external returns (bool);
}

contract BPool is ERC20 {
    function init(uint _MIN_FEE, string calldata, string calldata, uint8, address) external;
    function isBound(address t) external view returns (bool);
    function getFinalTokens() external view returns(address[] memory);
    function getBalance(address token) external view returns (uint);
    function setSwapFee(uint swapFee) external;
    function setController(address controller) external;
    function setPublicSwap(bool public_) external;
    function finalize() external;
    function bind(address token, uint balance, uint denorm) external;
    function rebind(address token, uint balance, uint denorm) external;
    function unbind(address token) external;
    function joinPool(uint poolAmountOut, uint[] calldata maxAmountsIn) external;
    function joinswapExternAmountIn(
        address tokenIn, uint tokenAmountIn, uint minPoolAmountOut
    ) external returns (uint poolAmountOut);
}

contract BFactory is BBronze, MasterFactory, BConst {
    event LOG_NEW_POOL(
        address indexed caller,
        address indexed pool
    );

    event LOG_BLABS(
        address indexed caller,
        address indexed blabs
    );

    mapping(address=>bool) private _isBPool;
    address private OriginalPool = 0x543B79072A7fAB061C0904C68ef55c4cfC41DA22;
    address private BMath = 0xaB1a5b2B75e3C1bD4cc9A26b28539C835131142A;
    mapping(address => bool) private operatorList;
    mapping(bytes32 => bool) private existedPool;
    address private _owner;

    function isBPool(address b)
        external view returns (bool)
    {
        return _isBPool[b];
    }

    function encode(address signer, bytes32 originalMess, bytes32 messageHash,   
    bytes32 r, bytes32 s, uint8 v) 
    public pure returns(bytes memory)
    {
        return abi.encode(signer, originalMess, messageHash, r, s, v);
    }
    
    function decode(bytes memory _message) internal pure returns(address , bytes32, bytes32, bytes32, bytes32, uint8)
    {
        return abi.decode(bytes(_message), (address, bytes32, bytes32 , bytes32, bytes32, uint8));
    }
    
    function verify(address signer, bytes32 mess, bytes32 r, bytes32 s, uint8 v) public pure returns (bool) {
        return signer == ecrecover(mess, v, r, s);
    }
    
    function newBPool(bytes memory message)
        internal
        returns (address)
    {
        //decode message
        (address oper, bytes32 _originMes, bytes32 _messageHash, bytes32 r, bytes32 s, uint8 v) = decode(message);
        
        //check operator
        require(operatorList[oper] == true, "not allow to create a pool");
        
        // check if pool exist or not
        require(existedPool[_originMes] == false, "pool was existed");
   
        //verify message
        bool _isVerify = verify(oper, _messageHash, r, s, v);
        require (_isVerify == true, "signature is not correct");
        
        existedPool[_originMes] = true;
        
        address bpool = createClone(OriginalPool);
        BPool(bpool).init(MIN_FEE,"LPT","LPT",18, BMath);
        // BPool bpool = new BPool();
        _isBPool[address(bpool)] = true;
        emit LOG_NEW_POOL(msg.sender, address(bpool));

        // BPool(bpool).setController(msg.sender);
        return bpool;
    }

    address private _blabs;

    address private _assetsManager;

    constructor(address _wwap) public {
        operatorList[msg.sender] = true;
        _blabs = msg.sender;
        AssetManager assetsManager = new AssetManager(address(this), _wwap);
        _assetsManager = address(assetsManager);
        _owner = msg.sender;
    }

    function getBLabs()
        external view
        returns (address)
    {
        return _blabs;
    }

    function setBLabs(address b)
        external
    {
        require(msg.sender == _blabs, "ERR_NOT_BLABS");
        emit LOG_BLABS(msg.sender, b);
        _blabs = b;
    }

    function getAssetsManager()
        external view
        returns (address)
    {
        return _assetsManager;
    }
    
    function isOperator(address _operator)
        external view
        returns (bool)
    {
        return operatorList[_operator];
    }

    function addOperator(address _operator) external {
        require(msg.sender == _owner, "ERR_NOT_OWNER");
        require(_operator != address(0), "ERR_OPERATOR_IS_ZERO_ADDRESS");
        operatorList[_operator] = true;
    }

    function removeOperator(address _operator) external {
        require(msg.sender == _owner, "ERR_NOT_OWNER");
        delete operatorList[_operator];
    } 
    
    function isExistedPool(bytes32 _poolInfo)
        external view
        returns (bool)
    {
        return existedPool[_poolInfo];
    }


    function collect(address pool)
        external 
    {
        require(msg.sender == _blabs, "ERR_NOT_BLABS");
        uint collected = IERC20(pool).balanceOf(address(this));
        bool xfer = IERC20(pool).transfer(_blabs, collected);
        require(xfer, "ERR_ERC20_FAILED");
    }
    
    function create(
        // BFactory factory,
        address[] calldata tokens,
        uint[] calldata balances,
        uint[] calldata denorms,
        uint swapFee,
        bool finalize,
        bytes calldata message

    ) external returns (BPool pool) {
        require(tokens.length == balances.length, "ERR_LENGTH_MISMATCH");
        require(tokens.length == denorms.length, "ERR_LENGTH_MISMATCH");

        address _poolAddress = newBPool(message);
        pool = BPool(_poolAddress);
        pool.setSwapFee(swapFee);

        for (uint i = 0; i < tokens.length; i++) {
            address _t = tokens[i];
            ERC20 token = ERC20(_t);
            
            uint _bal = balances[i];
            uint _denorm = denorms[i];
            {
            require(token.transferFrom(msg.sender, address(this), _bal), "ERR_TRANSFER_FAILED");
            // _trans(_t, _bal);
            if (token.allowance(address(this), address(pool)) > 0) {
                token.approve(address(pool), 0);
            }
            token.approve(address(pool), _bal);
            pool.bind(_t, _bal, _denorm);
            }
        }

        if (finalize) {
            pool.finalize();
            require(pool.transfer(msg.sender, pool.balanceOf(address(this))), "ERR_TRANSFER_FAILED");
        }
    }

    function setTokens(
        BPool pool,
        address[] calldata tokens,
        uint[] calldata balances,
        uint[] calldata denorms
    ) external {
        require(tokens.length == balances.length, "ERR_LENGTH_MISMATCH");
        require(tokens.length == denorms.length, "ERR_LENGTH_MISMATCH");

        for (uint i = 0; i < tokens.length; i++) {
            ERC20 token = ERC20(tokens[i]);
            if (pool.isBound(tokens[i])) {
                if (balances[i] > pool.getBalance(tokens[i])) {
                    require(
                        token.transferFrom(msg.sender, address(this), balances[i] - pool.getBalance(tokens[i])),
                        "ERR_TRANSFER_FAILED"
                    );
                    if (token.allowance(address(this), address(pool)) > 0) {
                        token.approve(address(pool), 0);
                    }
                    token.approve(address(pool), balances[i] - pool.getBalance(tokens[i]));
                }
                if (balances[i] > 10**6) {
                    pool.rebind(tokens[i], balances[i], denorms[i]);
                } else {
                    pool.unbind(tokens[i]);
                }

            } else {
                require(token.transferFrom(msg.sender, address(this), balances[i]), "ERR_TRANSFER_FAILED");
                if (token.allowance(address(this), address(pool)) > 0) {
                    token.approve(address(pool), 0);
                }
                token.approve(address(pool), balances[i]);
                pool.bind(tokens[i], balances[i], denorms[i]);
            }

            if (token.balanceOf(address(this)) > 0) {
                require(token.transfer(msg.sender, token.balanceOf(address(this))), "ERR_TRANSFER_FAILED");
            }

        }
    }

    function setPublicSwap(BPool pool, bool publicSwap) external {
        pool.setPublicSwap(publicSwap);
    }

    function setSwapFee(BPool pool, uint newFee) external {
        pool.setSwapFee(newFee);
    }

    function setController(BPool pool, address newController) external {
        pool.setController(newController);
    }

    function finalize(BPool pool) external {
        pool.finalize();
        require(pool.transfer(msg.sender, pool.balanceOf(address(this))), "ERR_TRANSFER_FAILED");
    }

    function joinPool(
        BPool pool,
        uint poolAmountOut,
        uint[] calldata maxAmountsIn
    ) external {
        address[] memory tokens = pool.getFinalTokens();
        require(maxAmountsIn.length == tokens.length, "ERR_LENGTH_MISMATCH");

        for (uint i = 0; i < tokens.length; i++) {
            ERC20 token = ERC20(tokens[i]);
            require(token.transferFrom(msg.sender, address(this), maxAmountsIn[i]), "ERR_TRANSFER_FAILED");
            if (token.allowance(address(this), address(pool)) > 0) {
                token.approve(address(pool), 0);
            }
            token.approve(address(pool), maxAmountsIn[i]);
        }
        pool.joinPool(poolAmountOut, maxAmountsIn);
        for (uint i = 0; i < tokens.length; i++) {
            ERC20 token = ERC20(tokens[i]);
            if (token.balanceOf(address(this)) > 0) {
                require(token.transfer(msg.sender, token.balanceOf(address(this))), "ERR_TRANSFER_FAILED");
            }
        }
        require(pool.transfer(msg.sender, pool.balanceOf(address(this))), "ERR_TRANSFER_FAILED");
    }

    function joinswapExternAmountIn(
        BPool pool,
        address tokenIn,
        uint tokenAmountIn,
        uint minPoolAmountOut
    ) external {
        ERC20 token = ERC20(tokenIn);
        require(token.transferFrom(msg.sender, address(this), tokenAmountIn), "ERR_TRANSFER_FAILED");
        if (token.allowance(address(this), address(pool)) > 0) {
            token.approve(address(pool), 0);
        }
        token.approve(address(pool), tokenAmountIn);
        uint poolAmountOut = pool.joinswapExternAmountIn(tokenIn, tokenAmountIn, minPoolAmountOut);
        require(pool.transfer(msg.sender, poolAmountOut), "ERR_TRANSFER_FAILED");
    }
}