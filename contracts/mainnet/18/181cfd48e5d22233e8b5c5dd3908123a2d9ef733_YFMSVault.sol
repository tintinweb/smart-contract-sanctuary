pragma solidity 0.6.8;

library SafeMath {
  /**
  * @dev Multiplies two unsigned integers, reverts on overflow.
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
  * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // Solidity only automatically asserts when dividing by 0
    require(b > 0);
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold

    return c;
  }

  /**
  * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    uint256 c = a - b;

    return c;
  }

  /**
  * @dev Adds two unsigned integers, reverts on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);

    return c;
  }

  /**
  * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
  * reverts when dividing by zero.
  */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}

interface ERC20 {
  function balanceOf(address who) external view returns (uint256);
  function transfer(address to, uint value) external returns (bool success);
  function transferFrom(address from, address to, uint value) external returns (bool success);
}

interface CuraAnnonaes {
  function getDailyReward() external view returns (uint256);
  function getNumberOfVaults() external view returns (uint256);
  function getUserBalanceInVault(string calldata vault, address user) external view returns (uint256);
  function stake(string calldata, address receiver, uint256 amount, address _vault) external returns (bool);
  function unstake(string calldata vault, address receiver, address _vault) external;
  function updateVaultData(string calldata vault, address who, address user, uint value) external;
}

// https://en.wikipedia.org/wiki/Cura_Annonae
contract YFMSVault {
  using SafeMath for uint256;

  // variables.
  address public owner;
  address[] public stakers; // tracks all addresses in vault.
  uint256 public burnTotal = 0;
  CuraAnnonaes public CuraAnnonae;
  ERC20 public YFMSToken;
  
  constructor(address _cura, address _token) public {
    owner = msg.sender;
    CuraAnnonae = CuraAnnonaes(_cura);
    YFMSToken = ERC20(_token);
  }

  // balance of a user in the vault.
  function getUserBalance(address _from) public view returns (uint256) {
    return CuraAnnonae.getUserBalanceInVault("YFMS", _from);
  }

  // returns all users currently staking in this vault.
  function getStakers() public view returns (address[] memory) {
    return stakers; 
  }

  function getUnstakingFee(address _user) public view returns (uint256) {
    uint256 _balance = getUserBalance(_user);
    return _balance / 10000 * 250;
  }

  function cleanStakersArray(address user) internal {
    uint256 index;
    // search the array for the user.
    for (uint i=0; i < stakers.length; i++) {
      if (stakers[i] == user)
        index = i;
      break;
    }
    // swap the last user in the array for the current unstaked user.
    stakers[index] = stakers[stakers.length - 1];
    // remove the last element (empty)
    stakers.pop();
  }

  function stakeYFMS(uint256 _amount, address _from) public {
    // add user to stakers array if not currently present.
    require(msg.sender == _from);
    require(_amount >= 500000000000000000);
    require(_amount <= YFMSToken.balanceOf(_from));
    if (getUserBalance(_from) == 0)
      stakers.push(_from);
    YFMSToken.transferFrom(_from, address(this), _amount);
    require(CuraAnnonae.stake("YFMS", _from, _amount, address(this)));
  }

  function unstakeYFMS(address _to) public {
    uint256 _unstakingFee = getUnstakingFee(_to);
    uint256 _amount = getUserBalance(_to).sub(_unstakingFee);
    // ensure data integrity.
    require(_amount > 0);
    require(msg.sender == _to);
    // first transfer funds back to the user then burn the unstaking fee.
    YFMSToken.transfer(_to, _amount);
    YFMSToken.transfer(address(0), _unstakingFee);
    // add to burn total.
    burnTotal = burnTotal.add(_unstakingFee); 
    // unstake.
    CuraAnnonae.unstake("YFMS", _to, address(this));
    // remove user from array.
    cleanStakersArray(_to);
  }

  function ratioMath(uint256 _numerator, uint256 _denominator) internal pure returns (uint256) {
    uint256 numerator = _numerator * 10 ** 18; // precision to 18 decimals.
    uint256 quotient = (numerator / _denominator).add(5).div(10);
    return quotient;
  }

  // daily call to distribute vault rewards to users who have staked.
  function distributeVaultRewards () public {
    require(msg.sender == owner);
    uint256 _reward = CuraAnnonae.getDailyReward();
    uint256 _vaults = CuraAnnonae.getNumberOfVaults();
    uint256 _vaultReward = _reward.div(_vaults);
    // remove daily reward from address(this) total.
    uint256 _pool = YFMSToken.balanceOf(address(this)).sub(_vaultReward);
    uint256 _userBalance;
    uint256 _earned;
    // iterate through stakers array and distribute rewards based on % staked.
    for (uint i = 0; i < stakers.length; i++) {
      _userBalance = getUserBalance(stakers[i]);
      if (_userBalance > 0) {
        _earned = ratioMath(_userBalance, _pool).mul(_vaultReward / 100000000000000000);
        // update the vault data.
        CuraAnnonae.updateVaultData("YFMS", address(this), stakers[i], _earned);
      }
    }
  }
}