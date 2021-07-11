// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.6.6;

import './TomiLP.sol';
import './modules/Ownable.sol';

interface ITomiLP {
    function addLiquidity(
        address user,
        uint256 amountA,
        uint256 amountB,
        uint256 amountAMin,
        uint256 amountBMin,
        uint256 deadline) external returns (
            uint256 _amountA,
            uint256 _amountB,
            uint256 _liquidity
        );
    function removeLiquidity(
        address user,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        uint256 deadline) external returns (
            uint256 _amountA,
            uint256 _amountB
        );
    function addLiquidityETH(
        address user,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        uint256 deadline) external payable returns (
            uint256 _amountToken,
            uint256 _amountETH,
            uint256 _liquidity
        );
    function removeLiquidityETH (
        address user,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        uint256 deadline) external returns (uint256 _amountToken, uint256 _amountETH);
    function initialize(address _tokenA, address _tokenB, address _TGAS, address _POOL, address _PLATFORM, address _WETH) external;
    function upgrade(address _PLATFORM) external;
    function tokenA() external returns(address);
}

contract TomiDelegate is Ownable{
    using SafeMath for uint;
    
    address public PLATFORM;
    address public POOL;
    address public TGAS;
    address public WETH;
    mapping(address => mapping(address => address)) public getPair;
    address[] public allPairs;
    mapping(address => bool) public isPair;
    mapping(address => address[]) public playerPairs;
    mapping(address => mapping(address => bool)) public isAddPlayerPair;

    bytes32 public contractCodeHash;
    event PairCreated(address indexed token0, address indexed token1, address pair, uint256);
    
    constructor(address _PLATFORM, address _POOL, address _TGAS, address _WETH) public {
        PLATFORM = _PLATFORM;
        POOL = _POOL;
        TGAS = _TGAS;
        WETH = _WETH;
    }
    
    receive() external payable {
    }
    
    function upgradePlatform(address _PLATFORM) external onlyOwner {
        for(uint i = 0; i < allPairs.length;i++) {
            ITomiLP(allPairs[i]).upgrade(_PLATFORM);
        }
    }

    function allPairsLength() external view returns (uint256) {
        return allPairs.length;
    }

    function getPlayerPairCount(address player) external view returns (uint256) {
        return playerPairs[player].length;
    }

    function _addPlayerPair(address _user, address _pair) internal {
        if (isAddPlayerPair[_user][_pair] == false) {
            isAddPlayerPair[_user][_pair] = true;
            playerPairs[_user].push(_pair);
        }
    }

    function addPlayerPair(address _user) external {
        require(isPair[msg.sender], 'addPlayerPair Forbidden');
        _addPlayerPair(_user, msg.sender);
    }
    
    function approveContract(address token, address spender, uint amount) internal {
        uint allowAmount = IERC20(token).totalSupply();
        if(allowAmount < amount) {
            allowAmount = amount;
        }
        if(IERC20(token).allowance(address(this), spender) < amount) {
            TransferHelper.safeApprove(token, spender, allowAmount);
        }
    }

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        uint256 deadline
        ) payable external returns (
            uint256 _amountToken,
            uint256 _amountETH,
            uint256 _liquidity
        ) {
        address pair = getPair[token][WETH];
            if(pair == address(0)) {
                pair = _createPair(token, WETH);
            }
            
            _addPlayerPair(msg.sender, pair);

            TransferHelper.safeTransferFrom(token, msg.sender, address(this), amountTokenDesired);
            approveContract(token, pair, amountTokenDesired);
            (_amountToken, _amountETH, _liquidity) = ITomiLP(pair).addLiquidityETH{value: msg.value}(msg.sender, amountTokenDesired, amountTokenMin, amountETHMin, deadline);
    }
    
    
    
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountA,
        uint256 amountB,
        uint256 amountAMin,
        uint256 amountBMin,
        uint256 deadline) external returns (
            uint256 _amountA,
            uint256 _amountB,
            uint256 _liquidity
        ) {
            address pair = getPair[tokenA][tokenB];
            if(pair == address(0)) {
                pair = _createPair(tokenA, tokenB);
            }

            _addPlayerPair(msg.sender, pair);

            if(tokenA != ITomiLP(pair).tokenA()) {
                (tokenA, tokenB) = (tokenB, tokenA);
                (amountA, amountB, amountAMin, amountBMin) = (amountB, amountA, amountBMin, amountAMin);
            }
            
            TransferHelper.safeTransferFrom(tokenA, msg.sender, address(this), amountA);
            TransferHelper.safeTransferFrom(tokenB, msg.sender, address(this), amountB);
            approveContract(tokenA, pair, amountA);
            approveContract(tokenB, pair, amountB);

            (_amountA, _amountB, _liquidity) = ITomiLP(pair).addLiquidity(msg.sender, amountA, amountB, amountAMin, amountBMin, deadline);
            if(tokenA != ITomiLP(pair).tokenA()) {
                (_amountA, _amountB) = (_amountB, _amountA);
            }
    }
    
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        uint deadline
        ) external returns (uint _amountToken, uint _amountETH) {
            address pair = getPair[token][WETH];
            (_amountToken, _amountETH) = ITomiLP(pair).removeLiquidityETH(msg.sender, liquidity, amountTokenMin, amountETHMin, deadline);
        }
    
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        uint256 deadline) external returns (
            uint256 _amountA,
            uint256 _amountB
        ) {
        address pair = getPair[tokenA][tokenB];
        (_amountA, _amountB) = ITomiLP(pair).removeLiquidity(msg.sender, liquidity, amountAMin, amountBMin, deadline);
    }

    function _createPair(address tokenA, address tokenB) internal returns (address pair){
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'TOMI FACTORY: ZERO_ADDRESS');
        require(getPair[token0][token1] == address(0), 'TOMI FACTORY: PAIR_EXISTS'); // single check is sufficient
        bytes memory bytecode = type(TomiLP).creationCode;
        if (uint256(contractCodeHash) == 0) {
            contractCodeHash = keccak256(bytecode);
        }
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));
        assembly {
            pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        isPair[pair] = true;
        ITomiLP(pair).initialize(token0, token1, TGAS, POOL, PLATFORM, WETH);
        getPair[token0][token1] = pair;
        getPair[token1][token0] = pair; // populate mapping in the reverse direction
        allPairs.push(pair);
        emit PairCreated(token0, token1, pair, allPairs.length);
    }
}

pragma solidity >=0.6.6;

import './libraries/SafeMath.sol';
import './modules/BaseShareField.sol';

interface ITomiPool {
    function queryReward(address _pair, address _user) external view returns(uint);
    function claimReward(address _pair, address _rewardToken) external;
}

interface ITomiPair {
    function queryReward() external view returns (uint256 rewardAmount, uint256 blockNumber);
    function mintReward() external returns (uint256 userReward);
}

interface ITomiDelegate {
    function addPlayerPair(address _user) external;
}

interface ITomiPlatform{
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountA,
        uint256 amountB,
        uint256 amountAMin,
        uint256 amountBMin,
        uint256 deadline
    )
        external
        returns (
            uint256 _amountA,
            uint256 _amountB,
            uint256 _liquidity
        );
        
    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 _amountToken,
            uint256 _amountETH,
            uint256 _liquidity
        );
    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);
    
    function pairFor(address tokenA, address tokenB) external view returns (address);
}

contract TomiLP is BaseShareField {
    // ERC20 Start
    
    using SafeMath for uint;

    string public constant name = 'Tomi LP';
    string public constant symbol = 'BLP';
    uint8 public constant decimals = 18;
    uint public totalSupply;
    
    mapping(address => uint) public balanceOf;
    mapping(address => mapping(address => uint)) public allowance;

    event Mint(address indexed user, uint amount);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
    
    function _mint(address to, uint value) internal {
        totalSupply = totalSupply.add(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(address(0), to, value);
    }
    
    receive() external payable {
    }
    
    function _burn(address from, uint value) internal {
        balanceOf[from] = balanceOf[from].sub(value);
        totalSupply = totalSupply.sub(value);
        emit Transfer(from, address(0), value);
    }

    function _transfer(address from, address to, uint value) private {
        require(balanceOf[from] >= value, 'ERC20Token: INSUFFICIENT_BALANCE');
        balanceOf[from] = balanceOf[from].sub(value);
        balanceOf[to] = balanceOf[to].add(value);
        if (to == address(0)) { // burn
            totalSupply = totalSupply.sub(value);
        }

        ITomiDelegate(owner).addPlayerPair(to);
        _mintReward();
        _decreaseProductivity(from, value);
        _increaseProductivity(to, value);
        emit Transfer(from, to, value);
    }

    function approve(address spender, uint value) external returns (bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function transfer(address to, uint value) external returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint value) external returns (bool) {
        require(allowance[from][msg.sender] >= value, 'ERC20Token: INSUFFICIENT_ALLOWANCE');
        allowance[from][msg.sender] = allowance[from][msg.sender].sub(value);
        _transfer(from, to, value);
        return true;
    }    
    
    // ERC20 End
    
    
    address public owner;
    address public POOL;
    address public PLATFORM;
    address public tokenA;
    address public tokenB;
    address public WETH;
    
    event AddLiquidity (address indexed user, uint amountA, uint amountB, uint value);
    event RemoveLiquidity (address indexed user, uint amountA, uint amountB, uint value);
    
    constructor() public {
        owner = msg.sender;
    }
    
    function initialize(address _tokenA, address _tokenB, address _TGAS, address _POOL, address _PLATFORM, address _WETH) external {
        require(msg.sender == owner, "Tomi LP Forbidden");
        tokenA = _tokenA;
        tokenB = _tokenB;
        _setShareToken(_TGAS);
        PLATFORM = _PLATFORM;
        POOL = _POOL;
        WETH = _WETH;
    }
 
    function upgrade(address _PLATFORM) external {
        require(msg.sender == owner, "Tomi LP Forbidden");
        PLATFORM = _PLATFORM;
    }

    function approveContract(address token, address spender, uint amount) internal {
        uint allowAmount = IERC20(token).totalSupply();
        if(allowAmount < amount) {
            allowAmount = amount;
        }
        if(IERC20(token).allowance(address(this), spender) < amount) {
            TransferHelper.safeApprove(token, spender, allowAmount);
        }
    }
    
    function addLiquidityETH(
        address user,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        uint256 deadline) external payable returns (
            uint256 _amountToken,
            uint256 _amountETH,
            uint256 _liquidity
        ) {
           require(msg.sender == owner, "Tomi LP Forbidden");
           require(tokenA == WETH || tokenB == WETH, "INVALID CALL");
           address token = tokenA == WETH ? tokenB: tokenA;
           approveContract(token, PLATFORM, amountTokenDesired);
           TransferHelper.safeTransferFrom(token, msg.sender, address(this), amountTokenDesired);
           
           (_amountToken, _amountETH, _liquidity) = ITomiPlatform(PLATFORM).addLiquidityETH{value: msg.value}(token, amountTokenDesired, amountTokenMin, amountETHMin, deadline);
           
           if(amountTokenDesired > _amountToken) {
                TransferHelper.safeTransfer(token, user, amountTokenDesired.sub(_amountToken));
            }
            
            if(msg.value > _amountETH) {
                TransferHelper.safeTransferETH(user, msg.value.sub(_amountETH));
            }
        _mintReward();
        _mint(user, _liquidity);
        _increaseProductivity(user, _liquidity);
        (uint amountA, uint amountB) = token == tokenA ? (_amountToken, _amountETH): (_amountETH, _amountToken);
        emit AddLiquidity (user, amountA, amountB, _liquidity);
    }
    
    function addLiquidity(
        address user,
        uint256 amountA,
        uint256 amountB,
        uint256 amountAMin,
        uint256 amountBMin,
        uint256 deadline) external returns (
            uint256 _amountA,
            uint256 _amountB,
            uint256 _liquidity
        ) {
            require(msg.sender == owner, "Tomi LP Forbidden");
            approveContract(tokenA, PLATFORM, amountA);
            approveContract(tokenB, PLATFORM, amountB);
            TransferHelper.safeTransferFrom(tokenA, msg.sender, address(this), amountA);
            TransferHelper.safeTransferFrom(tokenB, msg.sender, address(this), amountB);
        (_amountA, _amountB, _liquidity) = ITomiPlatform(PLATFORM).addLiquidity(tokenA, tokenB, amountA, amountB, amountAMin, amountBMin, deadline);
        if(amountA > _amountA) {
            TransferHelper.safeTransfer(tokenA, user, amountA.sub(_amountA));
        }
        
        if(amountB > _amountB) {
            TransferHelper.safeTransfer(tokenB, user, amountB.sub(_amountB));
        }
        
        _mintReward();
        _mint(user, _liquidity);
        _increaseProductivity(user, _liquidity);
        emit AddLiquidity (user, _amountA, _amountB, _liquidity);
    }
    
    function removeLiquidityETH (
        address user,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        uint256 deadline) external returns (uint256 _amountToken, uint256 _amountETH) {
         require(msg.sender == owner, "Tomi LP Forbidden");
         require(tokenA == WETH || tokenB == WETH, "INVALID CALL");
         address token = tokenA == WETH ? tokenB: tokenA;
           
        (_amountToken, _amountETH) = ITomiPlatform(PLATFORM).removeLiquidityETH(token, liquidity, amountTokenMin, amountETHMin, user, deadline);
         
        _mintReward();
        _burn(user, liquidity);
        _decreaseProductivity(user, liquidity);
        (uint amountA, uint amountB) = token == tokenA ? (_amountToken, _amountETH): (_amountETH, _amountToken);
        emit RemoveLiquidity (user, amountA, amountB, liquidity);
    }
    
    function removeLiquidity(
        address user,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        uint256 deadline) external returns (
            uint256 _amountA,
            uint256 _amountB
        ) {
            require(msg.sender == owner, "Tomi LP Forbidden");
        (_amountA, _amountB) = ITomiPlatform(PLATFORM).removeLiquidity(tokenA, tokenB, liquidity, amountAMin, amountBMin, user, deadline);
        
        _mintReward();
        _burn(user, liquidity);
        _decreaseProductivity(user, liquidity);
        emit RemoveLiquidity (user, _amountA, _amountB, liquidity);
    }
    
    function _currentReward() internal override view returns (uint) {
        address pair = ITomiPlatform(PLATFORM).pairFor(tokenA, tokenB);
        uint countractAmount = mintedShare.add(IERC20(shareToken).balanceOf(address(this))).sub(totalShare);
        if(pair != address(0)) {
            uint poolAmount = ITomiPool(POOL).queryReward(pair, address(this));
            (uint pairAmount, ) = ITomiPair(pair).queryReward();
            return countractAmount.add(poolAmount).add(pairAmount);
        } else {
            return countractAmount;
        }
    }
    
    function _mintReward() internal {
        address pair = ITomiPlatform(PLATFORM).pairFor(tokenA, tokenB);
        if(pair != address(0)) {
            uint poolAmount = ITomiPool(POOL).queryReward(pair, address(this));
            (uint pairAmount, ) = ITomiPair(pair).queryReward();
            if(poolAmount > 0) {
                ITomiPool(POOL).claimReward(pair, shareToken);
            }
            
            if(pairAmount > 0) {
                ITomiPair(pair).mintReward();
            }
        } 
    }
    
    function queryReward() external view returns (uint) {
        return _takeWithAddress(msg.sender);
    }
    
    function mintReward() external returns (uint amount) {
        _mintReward();
        amount = _mint(msg.sender);
        emit Mint(msg.sender, amount);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.6.6;
import '../interfaces/IERC20.sol';

interface IERC2917 is IERC20 {

    /// @dev This emit when interests amount per block is changed by the owner of the contract.
    /// It emits with the old interests amount and the new interests amount.
    event InterestRatePerBlockChanged (uint oldValue, uint newValue);

    /// @dev This emit when a users' productivity has changed
    /// It emits with the user's address and the the value after the change.
    event ProductivityIncreased (address indexed user, uint value);

    /// @dev This emit when a users' productivity has changed
    /// It emits with the user's address and the the value after the change.
    event ProductivityDecreased (address indexed user, uint value);

    /// @dev Return the current contract's interests rate per block.
    /// @return The amount of interests currently producing per each block.
    function interestsPerBlock() external view returns (uint);

    /// @notice Change the current contract's interests rate.
    /// @dev Note the best practice will be restrict the gross product provider's contract address to call this.
    /// @return The true/fase to notice that the value has successfully changed or not, when it succeed, it will emite the InterestRatePerBlockChanged event.
    function changeInterestRatePerBlock(uint value) external returns (bool);

    /// @notice It will get the productivity of given user.
    /// @dev it will return 0 if user has no productivity proved in the contract.
    /// @return user's productivity and overall productivity.
    function getProductivity(address user) external view returns (uint, uint);

    /// @notice increase a user's productivity.
    /// @dev Note the best practice will be restrict the callee to prove of productivity's contract address.
    /// @return true to confirm that the productivity added success.
    function increaseProductivity(address user, uint value) external returns (bool);

    /// @notice decrease a user's productivity.
    /// @dev Note the best practice will be restrict the callee to prove of productivity's contract address.
    /// @return true to confirm that the productivity removed success.
    function decreaseProductivity(address user, uint value) external returns (bool);

    /// @notice take() will return the interests that callee will get at current block height.
    /// @dev it will always calculated by block.number, so it will change when block height changes.
    /// @return amount of the interests that user are able to mint() at current block height.
    function take() external view returns (uint);

    /// @notice similar to take(), but with the block height joined to calculate return.
    /// @dev for instance, it returns (_amount, _block), which means at block height _block, the callee has accumulated _amount of interests.
    /// @return amount of interests and the block height.
    function takeWithBlock() external view returns (uint, uint);

    /// @notice mint the avaiable interests to callee.
    /// @dev once it mint, the amount of interests will transfer to callee's address.
    /// @return the amount of interests minted.
    function mint() external returns (uint);
}

pragma solidity >=0.5.0;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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
     *
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
     *
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
     *
     * - Subtraction cannot overflow.
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
     *
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.6.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}

pragma solidity >=0.6.6;
import '../interfaces/ERC2917-Interface.sol';
import '../libraries/SafeMath.sol';
import '../libraries/TransferHelper.sol';

contract BaseShareField {
    using SafeMath for uint;
    
    uint totalProductivity;
    uint accAmountPerShare;
    
    uint public totalShare;
    uint public mintedShare;
    uint public mintCumulation;
    
    address public shareToken;
    
    struct UserInfo {
        uint amount;     // How many tokens the user has provided.
        uint rewardDebt; // Reward debt. 
        uint rewardEarn; // Reward earn and not minted
    }

    mapping(address => UserInfo) public users;
    
    function _setShareToken(address _shareToken) internal {
        shareToken = _shareToken;
    }

    // Update reward variables of the given pool to be up-to-date.
    function _update() internal virtual {
        if (totalProductivity == 0) {
            totalShare = totalShare.add(_currentReward());
            return;
        }
        
        uint256 reward = _currentReward();
        accAmountPerShare = accAmountPerShare.add(reward.mul(1e12).div(totalProductivity));
        totalShare = totalShare.add(reward);
    }
    
    function _currentReward() internal virtual view returns (uint) {
        return mintedShare.add(IERC20(shareToken).balanceOf(address(this))).sub(totalShare);
    }
    
    // Audit user's reward to be up-to-date
    function _audit(address user) internal virtual {
        UserInfo storage userInfo = users[user];
        if (userInfo.amount > 0) {
            uint pending = userInfo.amount.mul(accAmountPerShare).div(1e12).sub(userInfo.rewardDebt);
            userInfo.rewardEarn = userInfo.rewardEarn.add(pending);
            mintCumulation = mintCumulation.add(pending);
            userInfo.rewardDebt = userInfo.amount.mul(accAmountPerShare).div(1e12);
        }
    }

    // External function call
    // This function increase user's productivity and updates the global productivity.
    // the users' actual share percentage will calculated by:
    // Formula:     user_productivity / global_productivity
    function _increaseProductivity(address user, uint value) internal virtual returns (bool) {
        require(value > 0, 'PRODUCTIVITY_VALUE_MUST_BE_GREATER_THAN_ZERO');

        UserInfo storage userInfo = users[user];
        _update();
        _audit(user);

        totalProductivity = totalProductivity.add(value);

        userInfo.amount = userInfo.amount.add(value);
        userInfo.rewardDebt = userInfo.amount.mul(accAmountPerShare).div(1e12);
        return true;
    }

    // External function call 
    // This function will decreases user's productivity by value, and updates the global productivity
    // it will record which block this is happenning and accumulates the area of (productivity * time)
    function _decreaseProductivity(address user, uint value) internal virtual returns (bool) {
        UserInfo storage userInfo = users[user];
        require(value > 0 && userInfo.amount >= value, 'INSUFFICIENT_PRODUCTIVITY');
        
        _update();
        _audit(user);
        
        userInfo.amount = userInfo.amount.sub(value);
        userInfo.rewardDebt = userInfo.amount.mul(accAmountPerShare).div(1e12);
        totalProductivity = totalProductivity.sub(value);
        
        return true;
    }
    
    function _takeWithAddress(address user) internal view returns (uint) {
        UserInfo storage userInfo = users[user];
        uint _accAmountPerShare = accAmountPerShare;
        // uint256 lpSupply = totalProductivity;
        if (totalProductivity != 0) {
            uint reward = _currentReward();
            _accAmountPerShare = _accAmountPerShare.add(reward.mul(1e12).div(totalProductivity));
        }
        return userInfo.amount.mul(_accAmountPerShare).div(1e12).add(userInfo.rewardEarn).sub(userInfo.rewardDebt);
    }

    // External function call
    // When user calls this function, it will calculate how many token will mint to user from his productivity * time
    // Also it calculates global token supply from last time the user mint to this time.
    function _mint(address user) internal virtual returns (uint) {
        _update();
        _audit(user);
        require(users[user].rewardEarn > 0, "NOTHING TO MINT");
        uint amount = users[user].rewardEarn;
        TransferHelper.safeTransfer(shareToken, msg.sender, amount);
        users[user].rewardEarn = 0;
        mintedShare += amount;
        return amount;
    }

    // Returns how many productivity a user has and global has.
    function getProductivity(address user) public virtual view returns (uint, uint) {
        return (users[user].amount, totalProductivity);
    }

    // Returns the current gorss product rate.
    function interestsPerBlock() public virtual view returns (uint) {
        return accAmountPerShare;
    }
    
}

pragma solidity >=0.5.16;

contract Ownable {
    address public owner;

    event OwnerChanged(address indexed _oldOwner, address indexed _newOwner);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, 'Ownable: FORBIDDEN');
        _;
    }

    function changeOwner(address _newOwner) public onlyOwner {
        require(_newOwner != address(0), 'Ownable: INVALID_ADDRESS');
        emit OwnerChanged(owner, _newOwner);
        owner = _newOwner;
    }

}