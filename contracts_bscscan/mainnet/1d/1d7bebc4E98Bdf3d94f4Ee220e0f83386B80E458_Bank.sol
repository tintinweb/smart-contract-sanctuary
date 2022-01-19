/**
 *Submitted for verification at BscScan.com on 2022-01-19
*/

// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.7;

// import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

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

contract Bank {
    /*///////////////////////////////////////////////////////////////
                    Global STATE
    //////////////////////////////////////////////////////////////*/

    address private admin;

    IERC20 public token;
    address private dusty = 0xc6f82B6922Ad6484c69BBE5f0c52751cE7F15EF2;

    // mapping (address => Action[])   public activities;
    mapping(address => uint256) public staked;
    mapping(address => mapping(address => mapping(uint256 => Action)))
        public status;

    uint256 public totalStaked;
    uint256 public earlyRemoved;
    uint256 public bonusPool;

    /*///////////////////////////////////////////////////////////////
                            DATA STRUCTURES 
    //////////////////////////////////////////////////////////////*/

    enum Actions {
        UNSTAKED,
        FARMING
    }

    struct Action {
        uint256 stakedTime;
        uint256 stakedAmount;
        uint256 percent;
        uint256 reward;
        Actions action;
    }

    /*///////////////////////////////////////////////////////////////
                            CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor() {
        admin = msg.sender;
        token = IERC20(dusty);
    }

    /*///////////////////////////////////////////////////////////////
                    PUBLIC FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function stakeByHash(
        address[] calldata NFTaddress,
        uint256[] calldata tokenId,
        uint256 amount
    ) external {
        uint256 length = tokenId.length;

        require((amount * length) <= token.balanceOf(msg.sender), "NE"); // MsgSender's balance must be larger than total amount
        require(amount >= 1 * 10**18 && amount <= 1000 * 10**18, "IN"); //Amount must be in this range (1~1000)

        // Define the parameters of the status
        uint256 reward;
        uint256 percent;
        uint256 timestamp;

        // Get percent and reward from the staked amount and set the timestamp
        (percent, reward) = calc(amount);
        timestamp = block.timestamp;

        // Set the status according to the NFTaddress and tokenId
        for (uint256 i = 0; i < length; i++) {
            status[msg.sender][NFTaddress[i]][tokenId[i]] = Action({
                stakedTime: timestamp,
                stakedAmount: amount,
                percent: percent,
                reward: reward,
                action: Actions.FARMING
            });
        }

        token.transferFrom(msg.sender, address(this), amount * length);

        // Add length to the totalStaked
        totalStaked += length;
        staked[msg.sender] += length;
    }

    //////////////////// Calculate the percent and reward from the amount ////////////////////////
    function calc(uint256 amount) internal pure returns (uint256, uint256) {
        uint256 percent;
        uint256 reward;

        if (amount >= 1 * 10**18 && amount < 10 * 10**18) {
            percent = 1;
            reward = (amount * 101) / 100;
        }
        if (amount >= 10 * 10**18 && amount < 20 * 10**18) {
            percent = 10;
            reward = (amount * 110) / 100;
        }
        if (amount >= 20 * 10**18 && amount < 30 * 10**18) {
            percent = 12;
            reward = (amount * 112) / 100;
        }
        if (amount >= 30 * 10**18 && amount < 50 * 10**18) {
            percent = 15;
            reward = (amount * 115) / 100;
        }
        if (amount >= 50 * 10**18 && amount < 100 * 10**18) {
            percent = 20;
            reward = (amount * 120) / 100;
        }
        if (amount >= 100 * 10**18 && amount < 500 * 10**18) {
            percent = 25;
            reward = (amount * 125) / 100;
        }
        if (amount >= 500 * 10**18 && amount < 800 * 10**18) {
            percent = 35;
            reward = (amount * 135) / 100;
        }
        if (amount >= 800 * 10**18 && amount < 1000 * 10**18) {
            percent = 42;
            reward = (amount * 142) / 100;
        }
        if (amount == 1000 * 10**18) {
            percent = 50;
            reward = (amount * 150) / 100;
        }

        return (percent, reward);
    }

    function autoClaim(address addr, uint256 tokenId) external {
        require(
            status[msg.sender][addr][tokenId].stakedTime + 365 days <
                block.timestamp,
            "NT"
        ); //This NFT is automatically Claim by its Hash

        Action memory act = status[msg.sender][addr][tokenId]; // Get the Action form the Address and Tokenid

        // To save the gas, we use new variables in this function
        uint256 rwd = act.reward;

        token.transfer(msg.sender, rwd); // Pay for the owner the reward

        //Set the mapping status[msg.sender][addr][tokenId] to its own Action which has stakedTime, stakedAmount, percent, reward, action
        status[msg.sender][addr][tokenId] = Action({
            stakedTime: 0,
            stakedAmount: 0,
            percent: 0,
            reward: 0,
            action: Actions.UNSTAKED
        });

        staked[msg.sender]--; //Decrease the staked amount of msg.sender

        totalStaked--; // Decrease the total staked NFTs
    }

    function unStake(address[] calldata addr, uint256[] calldata tokenId)
        external
    {
        uint256 length = tokenId.length;

        for (uint256 i = 0; i < length; i++) {
            Action memory act = status[msg.sender][addr[i]][tokenId[i]]; // Get the Action form the Address and Tokenid

            //Set the mapping status[msg.sender][addr][tokenId] to its own Action which has stakedTime, stakedAmount, percent, reward, action
            status[msg.sender][addr[i]][tokenId[i]] = Action({
                stakedTime: 0,
                stakedAmount: 0,
                percent: 0,
                reward: 0,
                action: Actions.UNSTAKED
            });

            bonusPool += act.stakedAmount; // Increase the amount of bonus/charity pool
        }
        staked[msg.sender] -= length; //Decrease the staked amount of msg.sender

        totalStaked -= length; // Decrease the total staked NFTs

        earlyRemoved += length; // Increase the number of early removed NFTs
    }

    ////////////////////////////////////////////
    //              WithDraw Mode             //
    ////////////////////////////////////////////
    modifier onlyAdmin() {
        require(admin == msg.sender, "OA");
        _;
    }

    function setNewAdmin(address newAdd) external onlyAdmin {
        admin = newAdd;
    }

    function withdraw() external onlyAdmin {
        uint256 amount = token.balanceOf(address(this));
        token.transfer(msg.sender, amount);
    }
}