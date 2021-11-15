// SPDX-License-Identifier: --🦉--

pragma solidity =0.7.6;

contract Context {

    /**
     * @dev returns address executing the method
     */
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    /**
     * @dev returns data passed into the method
     */
    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}

// SPDX-License-Identifier: --🦉--

pragma solidity =0.7.6;

abstract contract Declaration {

    uint256 constant _decimals = 18;
    uint256 constant PERCENTAGE_IDO = 31;
    uint256 constant PERCENTAGE_PRIVATE_SALE = 2;
    uint256 constant PERCENTAGE_TEAM = 10;
    uint256 constant PERCENTAGE_REWARD = 30;
    uint256 constant PERCENTAGE_ADVIOSORS_PARTNERS = 10;
    uint256 constant PERCENTAGE_STRATEGIC_RESERVE = 5;
    uint256 constant PERCENTAGE_MARKETING = 12;

    uint32 constant SECONDS_IN_DAY = 86400 seconds;
    uint16 constant DAYS_IN_MONTH = 30;

    uint256 constant PERCENTAGE_PRIVATE_SALE_TGE = 34;
    uint256 constant PERCENTAGE_PRIVATE_SALE_MONTH = 33;
    uint256 constant PERCENTAGE_IDO_TGE = 34;
    uint256 constant PERCENTAGE_IDO_MONTH = 33;
    uint256 constant PERCENTAGE_MARKETING_MONTH = 10;
    uint256 constant PERCENTAGE_ADVISORS_PARTNERS_TGE = 20;
    uint256 constant PERCENTAGE_ADVISORS_PARTNERS_MONTH = 10;
    uint256 constant PERCENTAGE_TEAM_MONTH = 10;
    uint256 constant PERCENTAGE_STRATEGIC_RESERVE_TGE = 20;
    uint256 constant PERCENTAGE_STRATEGIC_RESERVE_MONTH = 10;
}

// SPDX-License-Identifier: --🦉--

pragma solidity =0.7.6;

contract Events {

    event Withdraw_Reward (
        address indexed withdrawOwner,
        uint256 withdrawAmount
    );

    event Withdraw_Ido (
        address indexed withdrawOwner,
        uint256 withdrawAmount
    );

    event Withdraw_Marketing (
        address indexed withdrawOwner,
        uint256 withdrawAmount
    );

    event Withdraw_Advisor (
        address indexed withdrawOwner,
        uint256 withdrawAmount
    );

    event Withdraw_Team (
        address indexed withdrawOwner,
        uint256 withdrawAmount
    );

    event Withdraw_Strategic (
        address indexed withdrawOwner,
        uint256 withdrawAmount
    );

    event Withdraw_Private_sale (
        address indexed withdrawOwner,
        uint256 withdrawAmount
    );
}

// SPDX-License-Identifier: --🦉--

pragma solidity =0.7.6;

interface IERC20 {
    function decimals() external view returns (uint256);

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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// SPDX-License-Identifier: MIT

pragma solidity =0.7.6;

import './Context.sol';


 /**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
  address private _owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
   * @dev Initializes the contract setting the deployer as the initial owner.
   */
  constructor () {
    address msgSender = _msgSender();
    _owner = msgSender;
    emit OwnershipTransferred(address(0), msgSender);
  }

  /**
   * @dev Returns the address of the current owner.
   */
  function owner() public view virtual returns (address) {
    return _owner;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(owner() == _msgSender(), "Ownable: caller is not the owner");
    _;
  }

  /**
   * @dev Leaves the contract without owner. It will not be possible to call
   * `onlyOwner` functions anymore. Can only be called by the current owner.
   *
   * NOTE: Renouncing ownership will leave the contract without an owner,
   * thereby removing any functionality that is only available to the owner.
   */
  function renounceOwnership() public virtual onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }

  /**
   * @dev Transfers ownership of the contract to a new account (`newOwner`).
   * Can only be called by the current owner.
   */
  function transferOwnership(address newOwner) public virtual onlyOwner {
    require(newOwner != address(0), "Ownable: new owner is the zero address");
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

// SPDX-License-Identifier: --🦉--

pragma solidity =0.7.6;

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {

        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0);
        uint256 c = a / b;
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

// SPDX-License-Identifier: --🦉--

pragma solidity =0.7.6;

import "./SafeMath.sol";
import "./IERC20.sol";
import "./Ownable.sol";
import "./Declaration.sol";
import "./Events.sol";

contract Vesting is Ownable, Declaration, Events {
    using SafeMath for uint256;

    address public qdropToken;
    address public owner_reward;
    address public owner_ido;
    address public owner_marketing;
    address public owner_advisor;
    address public owner_team;
    address public owner_strategic;
    address public owner_private_sale;

    uint256 public LAUNCH_TIME;

    struct DataReward {
        uint256 available;
        uint256 withdrawn;
    }

    struct DataOther {
        uint256[] available;
        bool[] isWithdrawn;
        uint256 counter;
    }

    DataReward dataReward;
    DataOther dataIDO;
    DataOther dataPrivateSale;
    DataOther dataMarketing;
    DataOther dataAdvisors;
    DataOther dataTeam;
    DataOther dataStrategy;

    constructor(
        address _owner_reward,
        address _owner_ido,
        address _owner_marketing,
        address _owner_advisor,
        address _owner_team,
        address _owner_strategic,
        address _owner_private_sale
    ) {
        owner_reward = _owner_reward;
        owner_ido = _owner_ido;
        owner_marketing = _owner_marketing;
        owner_advisor = _owner_advisor;
        owner_team = _owner_team;
        owner_strategic = _owner_strategic;
        owner_private_sale = _owner_private_sale;
        LAUNCH_TIME = block.timestamp;
    }

    function setQdropTokenAddress(address _qdropToken) public onlyOwner {
        qdropToken = _qdropToken;
    }

    function initialize() public onlyOwner {
        uint256 totalSupply = IERC20(qdropToken).totalSupply();
        dataReward = DataReward(
            totalSupply.mul(PERCENTAGE_REWARD).div(100),
            block.timestamp
        );

        dataIDO.available.push(
            totalSupply.mul(PERCENTAGE_IDO).mul(PERCENTAGE_IDO_TGE).div(10000)
        );
        dataIDO.available.push(
            totalSupply.mul(PERCENTAGE_IDO).mul(PERCENTAGE_IDO_MONTH).div(10000)
        );
        dataIDO.available.push(
            totalSupply.mul(PERCENTAGE_IDO).mul(PERCENTAGE_IDO_MONTH).div(10000)
        );

        dataIDO.isWithdrawn.push(false);
        dataIDO.isWithdrawn.push(false);
        dataIDO.isWithdrawn.push(false);

        dataIDO.counter = 0;

        dataPrivateSale.available.push(
            totalSupply
                .mul(PERCENTAGE_PRIVATE_SALE)
                .mul(PERCENTAGE_PRIVATE_SALE_TGE)
                .div(10000)
        );

        dataPrivateSale.available.push(
            totalSupply
                .mul(PERCENTAGE_PRIVATE_SALE)
                .mul(PERCENTAGE_PRIVATE_SALE_MONTH)
                .div(10000)
        );

        dataPrivateSale.available.push(
            totalSupply
                .mul(PERCENTAGE_PRIVATE_SALE)
                .mul(PERCENTAGE_PRIVATE_SALE_MONTH)
                .div(10000)
        );

        dataPrivateSale.isWithdrawn.push(false);
        dataPrivateSale.isWithdrawn.push(false);
        dataPrivateSale.isWithdrawn.push(false);

        dataPrivateSale.counter = 0;

        dataMarketing.available.push(
            totalSupply
                .mul(PERCENTAGE_MARKETING)
                .mul(PERCENTAGE_MARKETING_MONTH)
                .div(10000)
        );
        dataMarketing.available.push(
            totalSupply
                .mul(PERCENTAGE_MARKETING)
                .mul(PERCENTAGE_MARKETING_MONTH)
                .div(10000)
        );
        dataMarketing.available.push(
            totalSupply
                .mul(PERCENTAGE_MARKETING)
                .mul(PERCENTAGE_MARKETING_MONTH)
                .div(10000)
        );
        dataMarketing.available.push(
            totalSupply
                .mul(PERCENTAGE_MARKETING)
                .mul(PERCENTAGE_MARKETING_MONTH)
                .div(10000)
        );
        dataMarketing.available.push(
            totalSupply
                .mul(PERCENTAGE_MARKETING)
                .mul(PERCENTAGE_MARKETING_MONTH)
                .div(10000)
        );
        dataMarketing.available.push(
            totalSupply
                .mul(PERCENTAGE_MARKETING)
                .mul(PERCENTAGE_MARKETING_MONTH)
                .div(10000)
        );
        dataMarketing.available.push(
            totalSupply
                .mul(PERCENTAGE_MARKETING)
                .mul(PERCENTAGE_MARKETING_MONTH)
                .div(10000)
        );
        dataMarketing.available.push(
            totalSupply
                .mul(PERCENTAGE_MARKETING)
                .mul(PERCENTAGE_MARKETING_MONTH)
                .div(10000)
        );
        dataMarketing.available.push(
            totalSupply
                .mul(PERCENTAGE_MARKETING)
                .mul(PERCENTAGE_MARKETING_MONTH)
                .div(10000)
        );
        dataMarketing.available.push(
            totalSupply
                .mul(PERCENTAGE_MARKETING)
                .mul(PERCENTAGE_MARKETING_MONTH)
                .div(10000)
        );

        dataMarketing.isWithdrawn.push(false);
        dataMarketing.isWithdrawn.push(false);
        dataMarketing.isWithdrawn.push(false);
        dataMarketing.isWithdrawn.push(false);
        dataMarketing.isWithdrawn.push(false);
        dataMarketing.isWithdrawn.push(false);
        dataMarketing.isWithdrawn.push(false);
        dataMarketing.isWithdrawn.push(false);
        dataMarketing.isWithdrawn.push(false);
        dataMarketing.isWithdrawn.push(false);

        dataMarketing.counter = 0;

        dataTeam.available.push(
            totalSupply.mul(PERCENTAGE_TEAM).mul(PERCENTAGE_TEAM_MONTH).div(
                10000
            )
        );
        dataTeam.available.push(
            totalSupply.mul(PERCENTAGE_TEAM).mul(PERCENTAGE_TEAM_MONTH).div(
                10000
            )
        );
        dataTeam.available.push(
            totalSupply.mul(PERCENTAGE_TEAM).mul(PERCENTAGE_TEAM_MONTH).div(
                10000
            )
        );
        dataTeam.available.push(
            totalSupply.mul(PERCENTAGE_TEAM).mul(PERCENTAGE_TEAM_MONTH).div(
                10000
            )
        );
        dataTeam.available.push(
            totalSupply.mul(PERCENTAGE_TEAM).mul(PERCENTAGE_TEAM_MONTH).div(
                10000
            )
        );
        dataTeam.available.push(
            totalSupply.mul(PERCENTAGE_TEAM).mul(PERCENTAGE_TEAM_MONTH).div(
                10000
            )
        );
        dataTeam.available.push(
            totalSupply.mul(PERCENTAGE_TEAM).mul(PERCENTAGE_TEAM_MONTH).div(
                10000
            )
        );
        dataTeam.available.push(
            totalSupply.mul(PERCENTAGE_TEAM).mul(PERCENTAGE_TEAM_MONTH).div(
                10000
            )
        );
        dataTeam.available.push(
            totalSupply.mul(PERCENTAGE_TEAM).mul(PERCENTAGE_TEAM_MONTH).div(
                10000
            )
        );
        dataTeam.available.push(
            totalSupply.mul(PERCENTAGE_TEAM).mul(PERCENTAGE_TEAM_MONTH).div(
                10000
            )
        );

        dataTeam.isWithdrawn.push(false);
        dataTeam.isWithdrawn.push(false);
        dataTeam.isWithdrawn.push(false);
        dataTeam.isWithdrawn.push(false);
        dataTeam.isWithdrawn.push(false);
        dataTeam.isWithdrawn.push(false);
        dataTeam.isWithdrawn.push(false);
        dataTeam.isWithdrawn.push(false);
        dataTeam.isWithdrawn.push(false);
        dataTeam.isWithdrawn.push(false);

        dataTeam.counter = 0;

        dataAdvisors.available.push(
            totalSupply
                .mul(PERCENTAGE_ADVIOSORS_PARTNERS)
                .mul(PERCENTAGE_ADVISORS_PARTNERS_TGE)
                .div(10000)
        );
        dataAdvisors.available.push(
            totalSupply
                .mul(PERCENTAGE_ADVIOSORS_PARTNERS)
                .mul(PERCENTAGE_ADVISORS_PARTNERS_MONTH)
                .div(10000)
        );
        dataAdvisors.available.push(
            totalSupply
                .mul(PERCENTAGE_ADVIOSORS_PARTNERS)
                .mul(PERCENTAGE_ADVISORS_PARTNERS_MONTH)
                .div(10000)
        );
        dataAdvisors.available.push(
            totalSupply
                .mul(PERCENTAGE_ADVIOSORS_PARTNERS)
                .mul(PERCENTAGE_ADVISORS_PARTNERS_MONTH)
                .div(10000)
        );
        dataAdvisors.available.push(
            totalSupply
                .mul(PERCENTAGE_ADVIOSORS_PARTNERS)
                .mul(PERCENTAGE_ADVISORS_PARTNERS_MONTH)
                .div(10000)
        );
        dataAdvisors.available.push(
            totalSupply
                .mul(PERCENTAGE_ADVIOSORS_PARTNERS)
                .mul(PERCENTAGE_ADVISORS_PARTNERS_MONTH)
                .div(10000)
        );
        dataAdvisors.available.push(
            totalSupply
                .mul(PERCENTAGE_ADVIOSORS_PARTNERS)
                .mul(PERCENTAGE_ADVISORS_PARTNERS_MONTH)
                .div(10000)
        );
        dataAdvisors.available.push(
            totalSupply
                .mul(PERCENTAGE_ADVIOSORS_PARTNERS)
                .mul(PERCENTAGE_ADVISORS_PARTNERS_MONTH)
                .div(10000)
        );
        dataAdvisors.available.push(
            totalSupply
                .mul(PERCENTAGE_ADVIOSORS_PARTNERS)
                .mul(PERCENTAGE_ADVISORS_PARTNERS_MONTH)
                .div(10000)
        );

        dataAdvisors.isWithdrawn.push(false);
        dataAdvisors.isWithdrawn.push(false);
        dataAdvisors.isWithdrawn.push(false);
        dataAdvisors.isWithdrawn.push(false);
        dataAdvisors.isWithdrawn.push(false);
        dataAdvisors.isWithdrawn.push(false);
        dataAdvisors.isWithdrawn.push(false);
        dataAdvisors.isWithdrawn.push(false);
        dataAdvisors.isWithdrawn.push(false);

        dataAdvisors.counter = 0;

        dataStrategy.available.push(
            totalSupply
                .mul(PERCENTAGE_STRATEGIC_RESERVE)
                .mul(PERCENTAGE_STRATEGIC_RESERVE_TGE)
                .div(10000)
        );
        dataStrategy.available.push(
            totalSupply
                .mul(PERCENTAGE_STRATEGIC_RESERVE)
                .mul(PERCENTAGE_STRATEGIC_RESERVE_MONTH)
                .div(10000)
        );
        dataStrategy.available.push(
            totalSupply
                .mul(PERCENTAGE_STRATEGIC_RESERVE)
                .mul(PERCENTAGE_STRATEGIC_RESERVE_MONTH)
                .div(10000)
        );
        dataStrategy.available.push(
            totalSupply
                .mul(PERCENTAGE_STRATEGIC_RESERVE)
                .mul(PERCENTAGE_STRATEGIC_RESERVE_MONTH)
                .div(10000)
        );
        dataStrategy.available.push(
            totalSupply
                .mul(PERCENTAGE_STRATEGIC_RESERVE)
                .mul(PERCENTAGE_STRATEGIC_RESERVE_MONTH)
                .div(10000)
        );
        dataStrategy.available.push(
            totalSupply
                .mul(PERCENTAGE_STRATEGIC_RESERVE)
                .mul(PERCENTAGE_STRATEGIC_RESERVE_MONTH)
                .div(10000)
        );
        dataStrategy.available.push(
            totalSupply
                .mul(PERCENTAGE_STRATEGIC_RESERVE)
                .mul(PERCENTAGE_STRATEGIC_RESERVE_MONTH)
                .div(10000)
        );
        dataStrategy.available.push(
            totalSupply
                .mul(PERCENTAGE_STRATEGIC_RESERVE)
                .mul(PERCENTAGE_STRATEGIC_RESERVE_MONTH)
                .div(10000)
        );
        dataStrategy.available.push(
            totalSupply
                .mul(PERCENTAGE_STRATEGIC_RESERVE)
                .mul(PERCENTAGE_STRATEGIC_RESERVE_MONTH)
                .div(10000)
        );

        dataStrategy.isWithdrawn.push(false);
        dataStrategy.isWithdrawn.push(false);
        dataStrategy.isWithdrawn.push(false);
        dataStrategy.isWithdrawn.push(false);
        dataStrategy.isWithdrawn.push(false);
        dataStrategy.isWithdrawn.push(false);
        dataStrategy.isWithdrawn.push(false);
        dataStrategy.isWithdrawn.push(false);
        dataStrategy.isWithdrawn.push(false);

        dataStrategy.counter = 0;
    }

    function withdrawRewardToken(uint256 amount) public {
        require(
            owner_reward == _msgSender(),
            "Ownable: caller is not the reward owner"
        );
        require(amount <= dataReward.available, "Invalid amount");

        IERC20(qdropToken).transfer(owner_reward, amount);
        emit Withdraw_Reward(owner_reward, amount);
    }

    function withdrawIDOToken() public {
        uint256 _counter = dataIDO.counter;
        uint256 current = block.timestamp;
        require(_counter < 3, "Already withdrawn all");
        require(
            owner_ido == _msgSender(),
            "Ownable: caller is not the ido owner"
        );
        require(
            _counter == 0 || !dataIDO.isWithdrawn[_counter],
            "Withdraw: already withdrawn for this month"
        );
        require(
            (LAUNCH_TIME + _counter * DAYS_IN_MONTH * SECONDS_IN_DAY) <
                current &&
                current <
                (LAUNCH_TIME + (_counter + 1) * DAYS_IN_MONTH * SECONDS_IN_DAY),
            "Invalid withdrawn"
        );

        IERC20(qdropToken).transfer(owner_ido, dataIDO.available[_counter]);
        dataIDO.counter = _counter + 1;
        dataIDO.isWithdrawn[_counter] = true;
        emit Withdraw_Ido(owner_ido, dataIDO.available[_counter]);
    }

    function withdrawPrivateSaleToken() public {
        uint256 _counter = dataPrivateSale.counter;
        uint256 current = block.timestamp;
        require(_counter < 3, "Already withdrawn all");
        require(
            owner_private_sale == _msgSender(),
            "Ownable: caller is not the private sale owner"
        );
        require(
            _counter == 0 || !dataPrivateSale.isWithdrawn[_counter],
            "Withdraw: already withdrawn for this month"
        );
        require(
            (LAUNCH_TIME + _counter * DAYS_IN_MONTH * SECONDS_IN_DAY) <
                current &&
                current <
                (LAUNCH_TIME + (_counter + 1) * DAYS_IN_MONTH * SECONDS_IN_DAY),
            "Invalid withdrawn"
        );

        IERC20(qdropToken).transfer(
            owner_private_sale,
            dataPrivateSale.available[_counter]
        );
        dataPrivateSale.counter = _counter + 1;
        dataPrivateSale.isWithdrawn[_counter] = true;
        emit Withdraw_Private_sale(
            owner_private_sale,
            dataPrivateSale.available[_counter]
        );
    }

    function withdrawMarketingToken() public {
        uint256 _counter = dataMarketing.counter;
        uint256 current = block.timestamp;
        require(_counter < 10, "Already withdrawn all");
        require(
            owner_marketing == _msgSender(),
            "Ownable: caller is not the marketing owner"
        );
        require(
            _counter == 0 || !dataMarketing.isWithdrawn[_counter],
            "Withdraw: already withdrawn for this month"
        );
        require(
            (LAUNCH_TIME + _counter * DAYS_IN_MONTH * SECONDS_IN_DAY) <
                current &&
                current <
                (LAUNCH_TIME + (_counter + 1) * DAYS_IN_MONTH * SECONDS_IN_DAY),
            "Invalid withdrawn"
        );

        IERC20(qdropToken).transfer(
            owner_marketing,
            dataMarketing.available[_counter]
        );
        dataMarketing.counter = _counter + 1;
        dataMarketing.isWithdrawn[_counter] = true;
        emit Withdraw_Marketing(
            owner_marketing,
            dataMarketing.available[_counter]
        );
    }

    function withdrawAdvisorToken() public {
        uint256 _counter = dataAdvisors.counter;
        uint256 current = block.timestamp;
        require(_counter < 9, "Already withdrawn all");
        require(
            owner_advisor == _msgSender(),
            "Ownable: caller is not the advisor owner"
        );
        require(
            _counter == 0 || !dataAdvisors.isWithdrawn[_counter],
            "Withdraw: already withdrawn for this month"
        );
        require(
            (LAUNCH_TIME + _counter * DAYS_IN_MONTH * SECONDS_IN_DAY) <
                current &&
                current <
                (LAUNCH_TIME + (_counter + 1) * DAYS_IN_MONTH * SECONDS_IN_DAY),
            "Invalid withdrawn"
        );

        IERC20(qdropToken).transfer(
            owner_advisor,
            dataAdvisors.available[_counter]
        );
        dataAdvisors.counter = _counter + 1;
        dataAdvisors.isWithdrawn[_counter] = true;
        emit Withdraw_Advisor(owner_advisor, dataAdvisors.available[_counter]);
    }

    function withdrawTeamToken() public {
        uint256 _counter = dataTeam.counter;
        uint256 current = block.timestamp;
        require(_counter < 10, "Already withdrawn all");
        require(
            owner_team == _msgSender(),
            "Ownable: caller is not the team owner"
        );
        require(
            _counter == 0 || !dataTeam.isWithdrawn[_counter],
            "Withdraw: already withdrawn for this month"
        );
        require(
            (LAUNCH_TIME + _counter * DAYS_IN_MONTH * SECONDS_IN_DAY) <
                current &&
                current <
                (LAUNCH_TIME + (_counter + 1) * DAYS_IN_MONTH * SECONDS_IN_DAY),
            "Invalid withdrawn"
        );

        IERC20(qdropToken).transfer(owner_team, dataTeam.available[_counter]);
        dataTeam.counter = _counter + 1;
        dataTeam.isWithdrawn[_counter] = true;
        emit Withdraw_Team(owner_team, dataTeam.available[_counter]);
    }

    function withdrawStrategyToken() public {
        uint256 _counter = dataStrategy.counter;
        uint256 current = block.timestamp;
        require(_counter < 9, "Already withdrawn all");
        require(
            owner_strategic == _msgSender(),
            "Ownable: caller is not the strategic owner"
        );
        require(
            _counter == 0 || !dataStrategy.isWithdrawn[_counter],
            "Withdraw: already withdrawn for this month"
        );
        require(
            (LAUNCH_TIME + _counter * DAYS_IN_MONTH * SECONDS_IN_DAY) <
                current &&
                current <
                (LAUNCH_TIME + (_counter + 1) * DAYS_IN_MONTH * SECONDS_IN_DAY),
            "Invalid withdrawn"
        );

        IERC20(qdropToken).transfer(
            owner_strategic,
            dataStrategy.available[_counter]
        );
        dataStrategy.counter = _counter + 1;
        dataStrategy.isWithdrawn[_counter] = true;
        emit Withdraw_Strategic(
            owner_strategic,
            dataStrategy.available[_counter]
        );
    }
}

