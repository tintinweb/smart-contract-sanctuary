/**
 *Submitted for verification at BscScan.com on 2021-08-03
*/

// SPDX-License-Identifier: No License (None)
pragma solidity ^0.8.0;

interface VBep20Interface {
    function transfer(address dst, uint amount) external returns (bool);
    function transferFrom(address src, address dst, uint amount) external returns (bool);
    function approve(address spender, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function balanceOfUnderlying(address owner) external returns (uint);
    function getAccountSnapshot(address account) external view returns (uint, uint, uint, uint);
    function borrowRatePerBlock() external view returns (uint);
    function supplyRatePerBlock() external view returns (uint);
    function totalBorrowsCurrent() external returns (uint);
    function borrowBalanceCurrent(address account) external returns (uint);
    function borrowBalanceStored(address account) external view returns (uint);
    function exchangeRateCurrent() external returns (uint);
    function exchangeRateStored() external view returns (uint);
    function getCash() external view returns (uint);
    function accrueInterest() external returns (uint);
    function seize(address liquidator, address borrower, uint seizeTokens) external returns (uint);
    //function mint(uint mintAmount) external returns (uint);
    function mint() external payable;
    function redeem(uint redeemTokens) external returns (uint);
    function redeemUnderlying(uint redeemAmount) external returns (uint);
    function borrow(uint borrowAmount) external returns (uint);
    function repayBorrow(uint repayAmount) external returns (uint);
    function repayBorrowBehalf(address borrower, uint repayAmount) external returns (uint);
}

abstract contract Ownable {
    address internal _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

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
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
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


contract Depository is Ownable {

    struct DepositData {
        uint128 reserve;
        uint128 shares;
    }

    mapping(address => mapping(uint256 => DepositData)) public deposits;    // user => deposit ID => deposit details
    uint256 public depositCounter;
    uint256 public pending_vBNB;    // pending amount of BNB tokens the should be redeemed
    uint256 public reserveRate;     // percentage of deposited amount that should be left on contract.
    VBep20Interface public vBNB;    // Venus BNB token contract

    event Deposit(address indexed user, uint256 indexed depositId, uint256 value);
    event Withdraw(address indexed user, uint256 indexed depositId, uint256 value);
    event Redeem(address indexed user, uint256 indexed depositId, uint256 value);
    event RedeemPending(uint256 sharesRedeemed);
    event Pending(uint256 addedToPending, uint256 insuficiantAmount); // addedToPending - tokens that should be redeemed, insuficiantAmount - insuficiant BNB amount

    function initialize() external {
        require(_owner == address(0), "Already initialized");
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
        vBNB = VBep20Interface(0x2E7222e51c0f6e98610A1543Aa3836E092CDe62c); // BSC testnet
        //vBNB = VBep20Interface(0xA07c5b74C9B40447a954e1466938b865b6BBea36); // BSC main net
        //vBNB = VBep20Interface(0x859e9d8a4edadfEDb5A2fF311243af80F85A91b8); // ETH Ropsten testnet
        //vBNB = VBep20Interface(0x4Ddc2D193948926D02f9B1fE9e1daa0718270ED5); // ETH main net
    }

    // Set percentage of deposited amount that should be left on contract.
    function setReserveRate(uint256 rate) external onlyOwner {
        require(reserveRate <= 100, "Wrong rate");
        reserveRate = rate;
    }
    
    // Set Venus vBNB contract address
    function set_vBNB(address _addr) external onlyOwner {
        require(_addr != address(0));
        vBNB = VBep20Interface(_addr);
    }

    // redeem deposit from Venus on user behalf. If `amount` = 0, redeem entire deposit
    function redeemDeposit(address user, uint256 depositId, uint256 amount) external onlyOwner {
        DepositData storage d = deposits[user][depositId];
        require (d.shares != 0, "No deposit");
        uint256 balance = address(this).balance;
        if (amount == 0) amount = uint256(d.shares);
        uint256 error = vBNB.redeem(amount);
        require (error == 0, "redeem error");
        uint256 value = address(this).balance - balance;
        d.reserve += uint128(value);
        emit Redeem(user, depositId, value);
    }

    // deposit BNB
    function deposit() external payable returns(uint256 depositId){
        depositId = ++depositCounter;
        uint256 reserve = msg.value * reserveRate / 100;
        uint256 depositAmount = msg.value - reserve;
        uint256 shares;
        if (depositAmount != 0) {
            uint256 balanceBefore = vBNB.balanceOf(address(this));
            vBNB.mint{value: depositAmount}();
            shares = vBNB.balanceOf(address(this)) - balanceBefore;
        }
        deposits[msg.sender][depositId] = DepositData(uint128(reserve), uint128(shares));
        emit Deposit(msg.sender, depositId, msg.value);
    }

    // withdraw BNB
    function withdraw(uint256 depositId) external returns(uint256 value){
        DepositData memory d = deposits[msg.sender][depositId];
        require (d.reserve != 0 || d.shares != 0, "No deposit");
        uint256 balance = address(this).balance;
        value = d.reserve;
        if (balance < value) {
            redeemPending();
            balance = address(this).balance;
            if (balance < value) {
                emit Pending(0, value - balance);
                return 0;  // Not enough balance
            }
        }
        if (d.shares != 0) {
            uint256 error = vBNB.redeem(uint256(d.shares));
            if (error != 0) {
                (uint256 shares, uint256 underlyingBalance) = _redeemMax(d.shares);
                pending_vBNB = pending_vBNB + shares;
                balance = address(this).balance;
                if (balance >= underlyingBalance + value) { //there is enough money when use reserve
                    value += underlyingBalance; // amount to return
                    emit Pending(shares, 0);
                } else {
                    d.reserve += uint128(underlyingBalance);
                    d.shares = 0;
                    emit Pending(shares, d.reserve - balance);
                    return 0;
                }
            } else {
                value = address(this).balance - balance + value; // amount to return
            }
        }
        delete deposits[msg.sender][depositId];
        safeTransferETH(msg.sender, value);
        emit Withdraw(msg.sender, depositId, value);(msg.sender, depositId, value);
    }

    // redeem pending shares
    function redeemPending() public {
        (uint256 shares,) = _redeemMax(pending_vBNB);
        pending_vBNB = shares;
    }

    // redeem as many as possible shares
    // returns number of shares remain, underlyingBalance - amount that should be received for all shares
    function _redeemMax(uint256 shares) internal returns(uint256, uint256) {
        require(shares != 0, "No shares");
        uint256 underlyingBalance = vBNB.balanceOfUnderlying(address(this));
        uint256 total_vBNB = vBNB.balanceOf(address(this));
        underlyingBalance = underlyingBalance * shares / total_vBNB;    // underlyingBalance for shares
        uint256 cash = vBNB.getCash();
        require (underlyingBalance >= cash, "Redeem error"); // there is cash, but redeem error
        uint256 error = vBNB.redeemUnderlying(cash);  // redeem available cash
        require (error == 0, "redeemUnderlying error");
        uint256 redeemedShares = total_vBNB - vBNB.balanceOf(address(this));
        require (shares >= redeemedShares, "Redeemed more shares");
        shares -= redeemedShares; // shares remain
        emit RedeemPending(redeemedShares);
        return (shares, underlyingBalance);
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }

    receive() external payable {}
}