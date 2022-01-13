/**
 *Submitted for verification at BscScan.com on 2022-01-13
*/

/**
 *Submitted for verification at BscScan.com on 2022-01-12
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

interface IBEP20 {
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

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

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

contract TeamVest is Ownable {
    event Deposit( address indexed account , uint amount);
    event Claim( address indexed claimer, uint amount);

    mapping(address => userStruct) public user;
    mapping(address => bool) public auth;

    struct userStruct {
        uint balance;
        uint totalClaimed;
        uint lastClaim;
    }

    IBEP20 public token;
    uint public initialClaim = 50e18;
    uint public subsequentClaim = 25e18;

    uint[2] public claimPeriod = [180 days, 90 days];
    uint public totalTokens;

    receive() external payable {
        revert("No receive calls");
    }

    modifier onlyAuth {
        require(auth[msg.sender], "only auth");
        _;
    }

    function setToken( IBEP20 token_) external onlyOwner {
        require( address(token_) != address(0));
        token = token_;
    }

    function setClaimPeriod( uint initial, uint subsequent) external onlyOwner {
        claimPeriod[0] = (initial != 0) ? initial : claimPeriod[0];
        claimPeriod[1] = (subsequent != 0) ? subsequent : claimPeriod[1];
    }

    function setInitialClaim( uint initClaim) external onlyOwner {
        initialClaim = initClaim;
    }

    function setMonthClaim( uint subClaim) external onlyOwner {
        subsequentClaim = subClaim;
    }

    function setAuth( address account, bool status) external onlyOwner {
        auth[account] = status;
    }

    function deposit( address account, uint amount) external onlyAuth {
        require(account != address(0), "deposit : account != 0x00");
        require(amount > 0, "deposit : amount > 0");
        require(user[account].balance == 0, "deposit : user.balance == 0");
        require(token.balanceOf(msg.sender) >= amount, "deposit : insufficient balance");
        require(token.allowance(msg.sender, address(this)) >= amount, "deposit : insufficient allowance");

        if(user[account].lastClaim == 0)
            user[account].lastClaim = block.timestamp + claimPeriod[0];

        totalTokens += amount;
        user[account].balance += amount;
        token.transferFrom(msg.sender, address(this), amount);
        emit Deposit( account, amount);
    }

    function claim() external {
        require(user[msg.sender].balance > 0, "claim : user.balance > 0");
        require(user[msg.sender].totalClaimed < user[msg.sender].balance, "claim : total claim < total balance");
        
        uint totDays;
        uint lastClaimTimestamp = user[msg.sender].lastClaim;
        uint claimAmount;

        if(user[msg.sender].totalClaimed == 0) {
            require((lastClaimTimestamp + claimPeriod[0]) < block.timestamp, "claim : wait till next claim");
            
            if((lastClaimTimestamp + claimPeriod[0] + claimPeriod[1]) < block.timestamp){
                totDays = (block.timestamp - (user[msg.sender].lastClaim + claimPeriod[0])) / claimPeriod[1];
            }

            user[msg.sender].lastClaim += (claimPeriod[0] + (claimPeriod[1] * totDays));
            
            claimAmount = user[msg.sender].balance * (initialClaim + (subsequentClaim * totDays)) / 100e18;
        }else {
            require((lastClaimTimestamp + claimPeriod[1]) < block.timestamp, "claim : wait till next claim");

            totDays = (block.timestamp - user[msg.sender].lastClaim) / claimPeriod[1];
            user[msg.sender].lastClaim += claimPeriod[1] * totDays;
            claimAmount = user[msg.sender].balance * (subsequentClaim * totDays) / 100e18;
        }

        if((user[msg.sender].totalClaimed + claimAmount) > user[msg.sender].balance) 
            claimAmount = user[msg.sender].balance - user[msg.sender].totalClaimed; 

        user[msg.sender].totalClaimed += claimAmount;
        token.transfer(msg.sender, claimAmount);
        emit Claim( msg.sender, claimAmount);
    }

    function emergency( address tokenAdd, uint amount) external onlyOwner{
        address self = address(this);
        if(tokenAdd == address(0)) {
            require(self.balance >= amount, "emergency : insufficient balance");
            require(payable(owner()).send(amount), "emergency : transfer failed");
        }
        else {
            require(IBEP20(tokenAdd).balanceOf(self) >= amount, "emergency : insufficient balance");
            require(IBEP20(tokenAdd).transfer(owner(),amount), "emergency : transfer failed");
        }
    }
}