/**
 *Submitted for verification at BscScan.com on 2022-01-19
*/

// File: contracts/utils/Access.sol

/********************

         .----------------.  .----------------.  .----------------.
        | .--------------. || .--------------. || .--------------. |
        | |   ______     | || |   ______     | || |  _________   | |
        | |  |_   _ \    | || |  |_   _ \    | || | |  _   _  |  | |
        | |    | |_) |   | || |    | |_) |   | || | |_/ | | \_|  | |
        | |    |  __'.   | || |    |  __'.   | || |     | |      | |
        | |   _| |__) |  | || |   _| |__) |  | || |    _| |_     | |
        | |  |_______/   | || |  |_______/   | || |   |_____|    | |
        | |              | || |              | || |              | |
        | '--------------' || '--------------' || '--------------' |
         '----------------'  '----------------'  '----------------'

                                                ****************************/

pragma solidity ^0.8.0;


contract Access {
    bool private _contractCallable = false;
    bool private _pause = false;
    address private _owner;
    address private _pendingOwner;

    event NewOwner(address indexed owner);
    event NewPendingOwner(address indexed pendingOwner);
    event SetContractCallable(bool indexed able,address indexed owner);

    constructor(){
        _owner = msg.sender;
    }

    // ownership
    modifier onlyOwner() {
        require(owner() == msg.sender, "caller is not the owner");
        _;
    }
    function owner() public view virtual returns (address) {
        return _owner;
    }
    function pendingOwner() public view virtual returns (address) {
        return _pendingOwner;
    }
    function setPendingOwner(address account) public onlyOwner {
        require(account != address(0),"zero address");
        require(_pendingOwner == address(0), "pendingOwner already exist");
        _pendingOwner = account;
        emit NewPendingOwner(_pendingOwner);
    }
    function becomeOwner() external {
        require(msg.sender == _pendingOwner,"not pending owner");
        _owner = _pendingOwner;
        _pendingOwner = address(0);
        emit NewOwner(_owner);
    }

    // pause
    modifier checkPaused() {
        require(!paused(), "paused");
        _;
    }
    function paused() public view virtual returns (bool) {
        return _pause;
    }
    function setPaused(bool p) external onlyOwner{
        _pause = p;
    }


    // contract call
    modifier checkContractCall() {
        require(contractCallable() || msg.sender == tx.origin, "non contract");
        _;
    }
    function contractCallable() public view virtual returns (bool) {
        return _contractCallable;
    }
    function setContractCallable(bool able) external onlyOwner {
        _contractCallable = able;
        emit SetContractCallable(able,_owner);
    }

}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

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

// File: contracts/Stake20.sol

pragma solidity ^0.8.0;



interface IBBT20 is IERC20 {
    function mint(address recipient_, uint256 amount_) external returns (bool);
}

interface IBBT1155 {
    function mintFT(address account, uint id, uint amount) external;
}

interface ITemplar {
    function mintKeys(uint amount, uint8 supplyId, address recipient) external;
}

contract StakeERC20 is Access{

    IERC20      public constant LP = IERC20(0x53C9747aa9A53bdd312A373dE6e89474e923bFC6);
    IBBT20      public constant BBT20 = IBBT20(0xca4F7A7783A5379F07F8aCB936eCbd8dA4d53bF1);
    IBBT1155    public constant BBT1155 = IBBT1155(0x300bac8d3F893FFEC024De01647313AE72a040DC);
    ITemplar    public Templar;

    uint public blockSupply = 0.3472222e28;
    uint public lastUpdate;
    uint public rewardsPerToken;
    uint public totalPledge;

    struct User {
        uint pledge;
        uint rewards;
        uint rewardsPerToken;
        uint bbtReward;
        address inviter;
        address[] invitees;
    }
    mapping(address=>User) public users;

    event Bind(address indexed inviter, address indexed invitee);
    event SetBlockSupply(uint blockSupply);
    event Pledge(address indexed user, uint amount, uint rewards);
    event Claim(address indexed user, address indexed inviter, uint pledges, uint fragmentReward, uint inviterReward, uint keyReward, uint rewards);
    event Redemption(address indexed user, uint indexed amount);

    constructor () {
        lastUpdate = block.number;
        setPendingOwner(0x2C190B5e4deD339EBE87259266692776A5243BB6);
    }

    modifier update() {

        if (blockSupply > 0 && totalPledge > 0){
            rewardsPerToken = calRewardsPerToken();
        }
        lastUpdate = block.number;

        _;
    }

    function calRewardsPerToken() public view returns(uint) {
        return (block.number - lastUpdate) * blockSupply / totalPledge + rewardsPerToken;
    }

    function bind(address inviter) external checkContractCall checkPaused {

        require(inviter != address(0), "not zero account");
        require(inviter != msg.sender, "can not be yourself");
        require(users[msg.sender].inviter == address(0), "already bind");
        users[msg.sender].inviter = inviter;
        users[inviter].invitees.push(msg.sender);
        emit Bind(inviter, msg.sender);
    }

    function calRewards(uint perToken, address account) internal view returns(uint){
        uint rewards = (perToken - users[account].rewardsPerToken) * users[account].pledge;

        if (rewards > 0) {
            rewards = rewards;
        }
        rewards += users[account].rewards;
        return rewards;
    }

    function setBlockSupply(uint supply) external update onlyOwner {
        blockSupply = supply;
    }
    function setTemplar(address t) external {
        require(tx.origin == owner(), "Stake20: only owner");
        Templar = ITemplar(t);
    }

    // pledge
    function pledge(uint amount) external update checkPaused checkContractCall {

        require(amount > 0, "Stake: The amount must be greater than 0");

        uint balanceBefore = LP.balanceOf(address(this));
        LP.transferFrom(msg.sender, address(this), amount);
        uint balanceAfter = LP.balanceOf(address(this));
        require(balanceBefore + amount == balanceAfter,"bad erc20");

        if (users[msg.sender].pledge > 0) {
            users[msg.sender].rewards = calRewards(rewardsPerToken, msg.sender);
        }

        users[msg.sender].rewardsPerToken = rewardsPerToken;
        users[msg.sender].pledge += amount;
        totalPledge += amount;

        emit Pledge(msg.sender, users[msg.sender].pledge, users[msg.sender].rewards);
    }


    // claimAble
    function claimAble(address account) public view returns (uint) {

        if (users[account].pledge == 0) {
            return 0;
        }

        uint rewards;
        if (blockSupply > 0){
            uint perToken = calRewardsPerToken();
            rewards = calRewards(perToken, account);
        }else {
            rewards = calRewards(rewardsPerToken, account);
        }
        return rewards;
    }

    function claim() external checkPaused checkContractCall returns (bool) {
        require(users[msg.sender].pledge > 0, "You can claim rewards only after pledge");

        _claim();
        return true;
    }

    // claim
    function _claim() internal update {

        uint rewards = calRewards(rewardsPerToken, msg.sender);

        users[msg.sender].rewards = 0;
        users[msg.sender].rewardsPerToken = rewardsPerToken;

        address inviter = users[msg.sender].inviter;
        uint inviterReward;
        uint fragmentReward;
        uint keyReward;

        if (rewards > 1e28) {

            fragmentReward = rewards / 1e28;
            BBT1155.mintFT(msg.sender, 1, fragmentReward);

            if (inviter != address(0)){
                inviterReward = fragmentReward * 1e17;
                BBT20.mint(inviter, inviterReward);
                users[inviter].bbtReward += inviterReward;
            }

            keyReward = fragmentReward / 100;
            if (keyReward > 0 && address(Templar) != address(0)) {
                Templar.mintKeys(keyReward, 7, msg.sender);
            }
        }
        emit Claim(msg.sender, inviter, users[msg.sender].pledge, fragmentReward, inviterReward, keyReward, rewards);
    }

    // redemption
    function redemption(uint amount) external update checkContractCall returns (bool) {

        require(amount > 0, "Stake: illegal amount (1)");
        require(users[msg.sender].pledge >= amount, "Stake: illegal amount (2)");

        _claim();
        LP.transfer(msg.sender, amount);

        totalPledge -= amount;
        users[msg.sender].pledge -= amount;
        return true;
    }

    // emergencyWithdraw
    function emergencyWithdraw() external returns (bool) {
        require(users[msg.sender].pledge > 0, "Stake20: You can withdraw only after pledge");

        LP.transfer(msg.sender, users[msg.sender].pledge);

        totalPledge -= users[msg.sender].pledge;
        users[msg.sender].pledge = 0;
        return true;
    }

    function getBaseInfo(address account) external view returns (uint blockSupply_, uint totalPledge_, uint userPledge_, uint rewards, uint blocks) {
        rewards = claimAble(account);
        userPledge_ = users[account].pledge;
        if (rewards > 0) {
            blocks = ((rewards/1e28 + 1) * 1e28 - rewards) * totalPledge / userPledge_ / blockSupply;
        }
        return (blockSupply, totalPledge, userPledge_, rewards, blocks);
    }

    function getInvitation(address account) external view returns (address inviter, uint bbtReward, address[] memory invitees) {
        inviter = users[account].inviter;
        bbtReward = users[account].bbtReward;
        invitees = users[account].invitees;
    }
}