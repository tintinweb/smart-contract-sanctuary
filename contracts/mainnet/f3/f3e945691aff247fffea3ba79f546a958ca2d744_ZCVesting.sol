pragma solidity ^0.4.24;

// File: contracts/IZCDistribution.sol

/**
 * @title IZCDistribution
 * 
 * Interface for the ZCDistribuition contract
 *
 * (c) Philip Louw / Zero Carbon Project 2018. The MIT Licence.
 */
interface IZCDistribution {

    /**
     * @dev Returns the Amount of tokens issued to consumers 
     */
    function getSentAmount() external pure returns (uint256);
}

// File: openzeppelin-solidity/contracts/math/SafeMath.sol

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (_a == 0) {
      return 0;
    }

    c = _a * _b;
    assert(c / _a == _b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
    // assert(_b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = _a / _b;
    // assert(_a == _b * c + _a % _b); // There is no case in which this doesn&#39;t hold
    return _a / _b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    assert(_b <= _a);
    return _a - _b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    c = _a + _b;
    assert(c >= _a);
    return c;
  }
}

// File: openzeppelin-solidity/contracts/token/ERC20/ERC20Basic.sol

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * See https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address _who) public view returns (uint256);
  function transfer(address _to, uint256 _value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

// File: contracts/ZCVesting.sol

/**
 * @title ZCVesting
 * 
 * Used to hold tokens and release once configured amount has been released to consumers.
 *
 * 10% of initial tokens in contract can be claimed for every 15 million tokens that are distributed to consumers.
 * After 150 million tokens are distributed consumer the full balanceof the vesting contract is transferable.
 *
 * (c) Philip Louw / Zero Carbon Project 2018. The MIT Licence.
 */
contract ZCVesting {

    using SafeMath for uint256;

    // Total amount of tokens released
    uint256 public releasedAmount = 0;
    // Address of the Token
    ERC20Basic public token;
    // Address of the Distribution Contract
    IZCDistribution public dist;
    // Release to Address
    address public releaseAddress;

    // Every amount of tokens to release funds
    uint256 internal constant STEP_DIST_TOKENS = 15000000 * (10**18);
    // Max amount of tokens before all is released
    uint256 internal constant MAX_DIST_TOKENS = 150000000 * (10**18);

    /**
     * @param _tokenAddr The Address of the Token
     * @param _distAddr The Address of the Distribution contract
     * @param _releaseAddr The Address where to release funds to
     */
    constructor(ERC20Basic _tokenAddr, IZCDistribution _distAddr, address _releaseAddr) public {
        assert(_tokenAddr != address(0));
        assert(_distAddr != address(0));
        assert(_releaseAddr != address(0));
        token = _tokenAddr;
        dist = _distAddr;
        releaseAddress = _releaseAddr;
    }

    /**
     * @dev Event when Tokens are released
     * @param releaseAmount Amount of tokens released
     */
    event TokenReleased(uint256 releaseAmount);


    /**
     * @dev Releases the current allowed amount to the releaseAddress. Returns the amount released    
     */
    function release() public  returns (uint256) {
        
        uint256 distAmount = dist.getSentAmount();
        if (distAmount < STEP_DIST_TOKENS) 
            return 0;

        uint256 currBalance = token.balanceOf(address(this));

        if (distAmount >= MAX_DIST_TOKENS) {
            assert(token.transfer(releaseAddress, currBalance));
            releasedAmount = releasedAmount.add(currBalance);
            return currBalance;
        }

        uint256 releaseAllowed = currBalance.add(releasedAmount).div(10).mul(distAmount.div(STEP_DIST_TOKENS));

        if (releaseAllowed <= releasedAmount)
            return 0;

        uint256 releaseAmount = releaseAllowed.sub(releasedAmount);
        releasedAmount = releasedAmount.add(releaseAmount);
        assert(token.transfer(releaseAddress, releaseAmount));
        emit TokenReleased(releaseAmount);
        return releaseAmount;
    }

    /**
    * @dev Returns the token balance of this ZCVesting contract
    */
    function currentBalance() public view returns (uint256) {
        return token.balanceOf(address(this));
    }
}