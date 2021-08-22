/**
 *Submitted for verification at Etherscan.io on 2021-08-22
*/

pragma solidity ^0.6.7;

abstract contract ERC20Events {
    event Approval(address indexed src, address indexed guy, uint wad);
    event Transfer(address indexed src, address indexed dst, uint wad);
}

abstract contract ERC20 is ERC20Events {
    function totalSupply() virtual public view returns (uint);
    function balanceOf(address guy) virtual public view returns (uint);
    function allowance(address src, address guy) virtual public view returns (uint);

    function approve(address guy, uint wad) virtual public returns (bool);
    function transfer(address dst, uint wad) virtual public returns (bool);
    function transferFrom(
        address src, address dst, uint wad
    ) virtual public returns (bool);
}

contract StakeRewardRefill {
    // --- Auth ---
    mapping (address => uint) public authorizedAccounts;
    /**
     * @notice Add auth to an account
     * @param account Account to add auth to
     */
    function addAuthorization(address account) external isAuthorized {
        authorizedAccounts[account] = 1;
        emit AddAuthorization(account);
    }
    /**
     * @notice Remove auth from an account
     * @param account Account to remove auth from
     */
    function removeAuthorization(address account) external isAuthorized {
        authorizedAccounts[account] = 0;
        emit RemoveAuthorization(account);
    }
    /**
    * @notice Checks whether msg.sender can call an authed function
    **/
    modifier isAuthorized {
        require(authorizedAccounts[msg.sender] == 1, "StakeRewardRefill/account-not-authorized");
        _;
    }

    /**
    * @notice Checks whether msg.sender can refill
    **/
    modifier canRefill {
        require(either(openRefill == 1, authorizedAccounts[msg.sender] == 1), "StakeRewardRefill/cannot-refill");
        _;
    }

    // --- Variables ---
    // Last timestamp for a refill
    uint256 public lastRefillTime;
    // The delay between two consecutive refills
    uint256 public refillDelay;
    // The amount to send per refill
    uint256 public refillAmount;
    // Whether anyone can refill or only authed accounts
    uint256 public openRefill;

    // The address that receives tokens
    address public refillDestination;

    // The token used as reward
    ERC20   public rewardToken;

    // --- Events ---
    event AddAuthorization(address account);
    event RemoveAuthorization(address account);
    event ModifyParameters(
      bytes32 parameter,
      address addr
    );
    event ModifyParameters(
      bytes32 parameter,
      uint256 val
    );
    event Refill(address refillDestination, uint256 amountToTransfer);

    constructor(
      address rewardToken_,
      address refillDestination_,
      uint256 openRefill_,
      uint256 refillDelay_,
      uint256 refillAmount_
    ) public {
        require(rewardToken_ != address(0), "StakeRewardRefill/null-reward-token");
        require(refillDestination_ != address(0), "StakeRewardRefill/null-refill-destination");
        require(refillDelay_ > 0, "StakeRewardRefill/null-refill-delay");
        require(refillAmount_ > 0, "StakeRewardRefill/null-refill-amount");
        require(openRefill_ <= 1, "StakeRewardRefill/invalid-open-refill");

        authorizedAccounts[msg.sender] = 1;

        openRefill        = openRefill_;
        refillDelay       = refillDelay_;
        refillAmount      = refillAmount_;
        lastRefillTime    = now;

        rewardToken       = ERC20(rewardToken_);
        refillDestination = refillDestination_;

        emit AddAuthorization(msg.sender);
        emit ModifyParameters("openRefill", openRefill);
        emit ModifyParameters("refillDestination", refillDestination);
        emit ModifyParameters("refillDelay", refillDelay);
        emit ModifyParameters("refillAmount", refillAmount);
    }

    // --- Boolean Logic ---
    function either(bool x, bool y) internal pure returns (bool z) {
        assembly{ z := or(x, y)}
    }

    // --- Math ---
    function subtract(uint x, uint y) public pure returns (uint z) {
        z = x - y;
        require(z <= x, "uint-uint-sub-underflow");
    }
    function multiply(uint x, uint y) public pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, "uint-uint-mul-overflow");
    }

    // --- Administration ---
    /**
    * @notice Modify an address parameter
    * @param parameter The parameter name
    * @param data The new parameter value
    **/
    function modifyParameters(bytes32 parameter, address data) external isAuthorized {
        require(data != address(0), "StakeRewardRefill/null-address");

        if (parameter == "refillDestination") {
          refillDestination = data;
        } else revert("StakeRewardRefill/modify-unrecognized-param");
    }
    /**
    * @notice Modify a uint256 parameter
    * @param parameter The parameter name
    * @param data The new parameter value
    **/
    function modifyParameters(bytes32 parameter, uint256 data) external isAuthorized {
        if (parameter == "openRefill") {
          require(data <= 1, "StakeRewardRefill/invalid-open-refill");
          openRefill = data;
        } else if (parameter == "lastRefillTime") {
          require(data >= lastRefillTime, "StakeRewardRefill/invalid-refill-time");
          lastRefillTime = data;
        } else if (parameter == "refillDelay") {
          require(data > 0, "StakeRewardRefill/null-refill-delay");
          refillDelay = data;
        } else if (parameter == "refillAmount") {
          require(data > 0, "StakeRewardRefill/null-refill-amount");
          refillAmount = data;
        }
        else revert("StakeRewardRefill/modify-unrecognized-param");
    }
    /**
    * @notice Transfer tokens to a custom address
    * @param dst Transfer destination
    * @param amount Amount of tokens to transfer
    **/
    function transferTokenOut(address dst, uint256 amount) external isAuthorized {
        require(dst != address(0), "StakeRewardRefill/null-dst");
        require(amount > 0, "StakeRewardRefill/null-amount");

        rewardToken.transfer(dst, amount);
    }

    // --- Core Logic ---
    /**
    * @notice Send tokens to refillDestination
    * @dev This function can only be called if msg.sender passes canRefill checks
    **/
    function refill() external canRefill {
        uint256 delay = subtract(now, lastRefillTime);
        require(delay >= refillDelay, "StakeRewardRefill/wait-more");

        // Update the last refill time
        lastRefillTime = subtract(now, delay % refillDelay);

        // Send tokens
        uint256 amountToTransfer = multiply(delay / refillDelay, refillAmount);
        rewardToken.transfer(refillDestination, amountToTransfer);

        emit Refill(refillDestination, amountToTransfer);
    }
}