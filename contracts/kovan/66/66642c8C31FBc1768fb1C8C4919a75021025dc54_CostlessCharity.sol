// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "./ILendingPoolAddressProvider.sol";
import "./ILendingPool.sol";
import "./Campaign.sol";

contract CostlessCharity is Ownable {
    uint256 idCounter;

    Campaign[] campaigns;

    ILendingPoolAddressProvider lendingPoolAddressProvider;
    address lendingPool;
    address daiToken;

    constructor(address _ledningPoolAddressProvider, address _daiToken) {
        lendingPoolAddressProvider = ILendingPoolAddressProvider(
            _ledningPoolAddressProvider
        );
        lendingPool = lendingPoolAddressProvider.getLendingPool();
        daiToken = _daiToken;
    }

    function createCampaign(
        string memory _name,
        address _fundation,
        uint256 _startDate,
        uint256 _endDate
    ) external onlyOwner {
        Campaign campaign = new Campaign(
            idCounter,
            _name,
            _fundation,
            _startDate,
            _endDate,
            lendingPool,
            daiToken
        );

        campaigns.push(campaign);
        idCounter++;
    }

    function getAllCampaigns() external view returns (Campaign[] memory) {
        return campaigns;
    }

    function getCampaigns(uint _campaignId) external view returns(Campaign) {
        return campaigns[_campaignId];
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
    constructor() {
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface ILendingPoolAddressProvider {
    function getLendingPool() external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface ILendingPool {

  function deposit(
    address asset,
    uint256 amount,
    address onBehalfOf,
    uint16 referralCode
  ) external;

  
  function withdraw(
    address asset,
    uint256 amount,
    address to
  ) external returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./ILendingPool.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";

contract Campaign {

    uint256 public id;
    string public name;
    address public foundation;
    uint256 public startDate;
    uint256 public endDate;
    uint256 public donations;
    uint256 public reward;
    uint public leftRefunds;
    bool readyToRedeem;

    mapping(address => uint256) public donorsToDonations;

    ILendingPool lendingPool;
    IERC20 daiToken;

    event Donated(address who, uint256 amount);

    constructor(
        uint256 _id,
        string memory _name,
        address _foundation,
        uint256 _startDate,
        uint256 _endDate,
        address _lendingPool,
        address _daiToken
    ) {
        id = _id;
        name = _name;
        foundation = _foundation;
        startDate = _startDate;
        startDate = _endDate;
        endDate = startDate + 10 minutes;
        lendingPool = ILendingPool(_lendingPool);
        daiToken = IERC20(_daiToken);

        daiToken.approve(_lendingPool, type(uint256).max);
    }

    modifier campaignOnGoing() {
        require(
            block.timestamp >= startDate && block.timestamp < endDate,
            "The campaign is not ongoing."
        );
        _;
    }

    modifier campaignEnded() {
        require(
            block.timestamp > endDate,
            "The campaign hasn't ended yet."
        );
        _;
    }

    function donate(uint256 _amount) public campaignOnGoing {
        //Needs approval on DAI smart contract first;
        daiToken.transferFrom(msg.sender, address(this), _amount);
        lendingPool.deposit(address(daiToken), _amount, address(this), 0);

        donations += _amount;
        leftRefunds += _amount;
        donorsToDonations[msg.sender] += _amount;

        emit Donated(msg.sender, _amount);
    }


    function endCampaign() public campaignEnded {
        uint amount = lendingPool.withdraw(address(daiToken), type(uint).max, address(this));
        reward = amount - donations;
        daiToken.transfer(foundation, reward);

        readyToRedeem = true;
    }

    function getMyFoundsBack() public  {
        require(readyToRedeem, "Refund is not ready yet");
        require(donorsToDonations[msg.sender] > 0, "You have no founds in the campaing");
        
        daiToken.transfer(msg.sender, donorsToDonations[msg.sender]);
        leftRefunds -= donorsToDonations[msg.sender];
        donorsToDonations[msg.sender] = 0;
    
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
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
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

