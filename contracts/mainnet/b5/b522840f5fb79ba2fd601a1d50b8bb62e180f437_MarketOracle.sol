/**
 *Submitted for verification at Etherscan.io on 2020-08-23
*/

pragma solidity > 0.6.0;

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

library SafeMath {

  /**
  * @dev Multiplies two numbers, reverts on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b);

    return c;
  }

  /**
  * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0); // Solidity only automatically asserts when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold

    return c;
  }

  /**
  * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    uint256 c = a - b;

    return c;
  }

  /**
  * @dev Adds two numbers, reverts on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);

    return c;
  }

  /**
  * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
  * reverts when dividing by zero.
  */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}

library UniswapV2Library {
    using SafeMath for uint;

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'UniswapV2Library: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'UniswapV2Library: ZERO_ADDRESS');
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(address factory, address tokenA, address tokenB) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(uint(keccak256(abi.encodePacked(
                hex'ff',
                factory,
                keccak256(abi.encodePacked(token0, token1)),
                hex'96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f' // init code hash
            ))));
    }

}
interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
}

contract Ownable {
    address owner;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
}

contract MonetaryPolicy {
    uint256 public minRebaseTimeIntervalSec;
    uint256 public rebaseWindowOffsetSec;
    uint256 public rebaseWindowLengthSec;    
}

contract MarketOracle is Ownable {
    using SafeMath for uint256;

    MonetaryPolicy public policy;
    
    address public liquidityTokenAddress;

    uint256 public constant zero = uint256(0);

    uint256 public window;
    uint256 public sumOfStakes;
    uint256 public sumOfWeightedPrices;

    struct Staker {
        uint256 stake;
        uint256 lastTimeStaked;
    }

    mapping(address => Staker) public staker;
    
    modifier onlyPolicy() {
        require(address(msg.sender) == address(policy));
        _;
    }
  
    function removeAdmin() external onlyOwner {
        owner = address(0);
    }
  
   function setWindow(uint256 _window) external onlyOwner {
       window = _window;
   }
    
   function setPolicy(address _policyAddress) external onlyOwner {
       policy = MonetaryPolicy(_policyAddress);       
   }
   
   function setLiquidityToken(address _factory, address _donutAddress, address _coffeeAddress) external onlyOwner {
       liquidityTokenAddress = UniswapV2Library.pairFor(_factory, _donutAddress, _coffeeAddress);
   }   

    function inOracleWindow() public view returns(bool isWithinBounds) {
        uint256 minRebaseTimeIntervalSec_ = policy.minRebaseTimeIntervalSec();
        uint256 rebaseWindowOffsetSec_ = policy.rebaseWindowOffsetSec();
        isWithinBounds = (now.mod(minRebaseTimeIntervalSec_) < rebaseWindowOffsetSec_);
    }    
    
    function inVotingWindow() public view returns(bool isWithinBounds) {
        uint256 lastTimeStaked_ = staker[msg.sender].lastTimeStaked;
        uint256 minRebaseTimeIntervalSec_ = policy.minRebaseTimeIntervalSec();
        uint256 timeVoted_ = (lastTimeStaked_.mod(minRebaseTimeIntervalSec_));
        isWithinBounds = (now.sub(lastTimeStaked_)) > minRebaseTimeIntervalSec_.sub(timeVoted_);
    }
    
    function inUnStakingWindow() public view returns(bool isWithinBounds) {
        uint256 lastTimeStaked_ = staker[msg.sender].lastTimeStaked;
        isWithinBounds = lastTimeStaked_ > zero ? now.sub(lastTimeStaked_) >= window : true;
    }

    function stake(uint256 _stake) external {
        staker[msg.sender].stake = staker[msg.sender].stake.add(_stake);        
        TransferHelper.safeTransferFrom(liquidityTokenAddress, msg.sender, address(this), _stake);
    }

    function unstake(uint256 _stake) external {
        require(inUnStakingWindow());
        require(_stake <= staker[msg.sender].stake);
        staker[msg.sender].stake = staker[msg.sender].stake.sub(_stake);        
        TransferHelper.safeTransfer(liquidityTokenAddress, msg.sender, _stake);
    }

    function vote(uint256 _price) external {
        require(inOracleWindow());
        require(inVotingWindow());
        require(_price >= 1e17 && _price <= 1e19);
        uint256 stake_ = staker[msg.sender].stake;
        sumOfStakes = sumOfStakes.add(stake_);
        sumOfWeightedPrices = sumOfWeightedPrices.add(stake_.mul(_price));
        staker[msg.sender].lastTimeStaked = now;        
    }

    function getMean() external view returns(uint256 weightedMean_) {
        weightedMean_ = ((sumOfWeightedPrices.mul(1e18)).div(sumOfStakes)).div(1e18);
    }

    function getData() external onlyPolicy returns(uint256 weightedMean_) {
        weightedMean_ =  sumOfStakes > zero ? ((sumOfWeightedPrices.mul(1e18)).div(sumOfStakes)).div(1e18) : 1e18;
        delete sumOfStakes;
        delete sumOfWeightedPrices;
    }

    
}