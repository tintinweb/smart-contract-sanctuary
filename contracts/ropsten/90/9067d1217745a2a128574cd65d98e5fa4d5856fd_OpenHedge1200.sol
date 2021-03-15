/**
 *Submitted for verification at Etherscan.io on 2021-03-15
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.2;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;

        return c;
    }
}

interface ERC20 {
    function balanceOf(address tokenOwner) external view returns (uint balance);

    function allowance(address tokenOwner, address spender) external view returns (uint remaining);

    function transfer(address to, uint tokens) external;

    function approve(address spender, uint tokens) external returns (bool success);

    function transferFrom(address from, address to, uint tokens) external;

    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract HedgerParty {
    enum HedgerStatus {NEW, FUNDED, WITHDRAWN}
    HedgerStatus public status = HedgerStatus.NEW;

    // OpenHedge Primary Contract Address
    address public contractAddr;
    // User Ethereum Address
    address public account;
    // Asset Address, Use 0x0/address(0) for ETH
    address public assetAddr;
    // Asset code/symbol/ticker
    string public assetCode;
    // Scale/precision value for asset
    uint8 public assetScale;
    // Amount of asset value
    uint256 public amount;
    // Timestamp: funded on
    uint256 public fundedOn;
    // Timestamp: withdrawn on
    uint256 public withdrawnOn;

    // Constructor for Hedger object
    constructor(address _contract) {
        contractAddr = _contract;
        reset();
    }

    // Reset hedger object
    function reset() public {
        status = HedgerStatus.NEW;
        account = address(0);
        assetAddr = address(0);
        assetCode = "";
        assetScale = 0;
        amount = 0;
        fundedOn = 0;
        withdrawnOn = 0;
    }

    // Reserve this hedger object
    function reserve(address _asset, uint256 _amount) public {
        status = HedgerStatus.NEW;
        if (_asset == address(0)) {// Is ETH
            assetAddr = address(0);
            assetCode = "ETH";
            assetScale = 18;
        } else {
            assetAddr = _asset;
            assetCode = ERC20(_asset).symbol();
            assetScale = ERC20(_asset).decimals();
        }

        amount = _amount;
    }

    // Set address of hedger party
    function setUserAccount(address _user) public {
        require(status == HedgerStatus.NEW);
        account = _user;
    }

    // Internal method to retrieve uint256 balance
    function getBalance() public view returns (uint256) {
        if (assetAddr == address(0)) {
            return contractAddr.balance;
        } else {
            (bool success, bytes memory tokenBalance) = assetAddr.staticcall(abi.encodeWithSignature("balanceOf(address)", contractAddr));
            require(success);
            return abi.decode(tokenBalance, (uint256));
        }
    }

    // Status of this object is "FUNDED" ?
    function isFunded() public view returns (bool) {
        return status == HedgerStatus.FUNDED;
    }

    // Get current object as string
    function getStatusStr() public view returns (string memory) {
        uint currentStatus = uint(status);
        if (currentStatus == 0) return "NEW";
        if (currentStatus == 1) return "FUNDED";
        if (currentStatus == 2) return "WITHDRAWN";

        revert("Unknown/Invalid HedgerStatus status");
    }

    // Marks as funded
    function markAsFunded() public {
        require(status == HedgerStatus.NEW);
        status = HedgerStatus.FUNDED;
        fundedOn = block.timestamp;
    }

    // Marks as withdrawn
    function markWithdrawn() public {
        require(status == HedgerStatus.FUNDED);
        status = HedgerStatus.WITHDRAWN;
        withdrawnOn = block.timestamp;
    }
}

contract OpenHedge1200
{
    // OpenHedgeProtocol Version
    string public constant OpenHedgeProtocol = "0.12.0";

    enum HedgeStatus {AVAILABLE, RESERVED, FUNDED, CANCELLED, ACTIVE, FINISHED}
    HedgeStatus public status = HedgeStatus.AVAILABLE;

    // Owner address
    address private ownerAddr;
    // Timestamp contract deployed On
    uint256 private deployedOn;

    // Seller (Party A) Object
    HedgerParty private seller;
    // Buyer (Party B) Object
    HedgerParty private buyer;
    // Maturity of contract in seconds
    int256 public maturity;
    // Premium/Fee paid to Buyer
    uint16 private premium;
    // Premium/Fee amount
    uint256 private premiumAmount;
    // Timestamp this contract became reserved for Party A
    uint256 private reservedOn;
    // Timestamp contract HedgeStatus is ACTIVE
    uint256 private activatedOn;
    // Timestamp contract HedgeStatus is FINISHED
    uint256 private finishedOn;

    event Spend(address asset, address payee, uint256 amount);

    // For certain methods that are only callable by ProSwap owner address
    modifier onlyOwner {
        if (msg.sender != ownerAddr) {
            revert("Can only be called by Owner address");
        }
        _;
    }

    // For certain methods that are only callable by Seller address
    modifier onlySeller {
        if (msg.sender != seller.account()) {
            revert("Can only be called by Seller address");
        }
        _;
    }

    modifier onlyOwnerOrSeller {
        if (msg.sender != ownerAddr) {
            if (msg.sender != seller.account()) {
                revert("Can only be called by Admin or Seller address");
            }
        }
        _;
    }

    // Todo: add ownership transfer

    // Open Hedger Constructor
    constructor() {
        ownerAddr = msg.sender;
        deployedOn = block.timestamp;
        seller = new HedgerParty(address(this));
        buyer = new HedgerParty(address(this));
    }

    // Get owner address
    function ownerAddress() public view returns (address) {
        return (ownerAddr);
    }

    // Determines if OH-SC can be reset at current stage
    function canReset() public view returns (bool) {
        if (status == HedgeStatus.RESERVED) {// Available SC was allotted but not yet funded
            return true;
        }

        if (status == HedgeStatus.CANCELLED) {// SC was allotted, funded and then later cancelled
            return true;
        }

        if (status == HedgeStatus.FINISHED) {// SC was finished successfully
            return true;
        }

        return false;
    }

    // Super reset
    function reset() public onlyOwner {
        if (!canReset()) {
            revert("Hedger cannot be reset");
        }

        status = HedgeStatus.AVAILABLE;
        seller.reset();
        buyer.reset();
        maturity = 0;
        premium = 0;
        premiumAmount = 0;
        reservedOn = 0;
        activatedOn = 0;
        finishedOn = 0;

        uint256 eth = address(this).balance;
        if (eth > 0) {
            spend(address(0), ownerAddr, eth);
        }
    }

    // Reserve this AVAILABLE hedge contract
    function reserve(address _userA, address _assetA, uint256 _assetAAmount, address _assetB, uint256 _assetBAmount, int256 _maturity, uint16 _premium) public onlyOwner {
        if (status != HedgeStatus.AVAILABLE) {
            revert("HedgerStatus is not AVAILABLE");
        }

        status = HedgeStatus.RESERVED;
        seller.reserve(_assetA, _assetAAmount);
        seller.setUserAccount(_userA);
        buyer.reserve(_assetB, _assetBAmount);
        maturity = _maturity;
        premium = _premium;
        premiumAmount = SafeMath.div(SafeMath.mul(premium, _assetAAmount), 10000);
        reservedOn = block.timestamp;
    }

    // Get the premium amount
    function getPremium() public view returns (uint16, uint256) {
        return (
        premium,
        premiumAmount
        );
    }

    // Get current timestamp as per last block
    function currentTs() public view returns (int256) {
        return int256(block.timestamp);
    }

    // Get number of seconds since contract is HedgeStatus.ACTIVE
    function activatedSince() public view returns (int256) {
        if (activatedOn > 0) {
            return int256(block.timestamp) - int256(activatedOn);
        }

        return 0;
    }

    // Check if contract has matured
    function isMatured() public view returns (bool) {
        if (maturity > 0) {
            int256 matured = int256(activatedSince()) - int256(maturity);
            if (matured > 0) {
                return true;
            }
        }

        return false;
    }

    // Check if funds are claimable
    function isClaimable() public view returns (bool) {
        return status == HedgeStatus.ACTIVE && isMatured();
    }

    // Get seller information
    function getPartyA() public view returns (uint8, string memory, address, uint256, address, string memory, uint8, uint256) {
        return (
        uint8(seller.status()),
        seller.getStatusStr(),
        seller.account(),
        seller.getBalance(),
        seller.assetAddr(),
        seller.assetCode(),
        seller.assetScale(),
        seller.amount()
        );
    }

    // Get buyer information
    function getPartyB() public view returns (uint8, string memory, address, uint256, address, string memory, uint8, uint256) {
        return (
        uint8(buyer.status()),
        buyer.getStatusStr(),
        buyer.account(),
        buyer.getBalance(),
        buyer.assetAddr(),
        buyer.assetCode(),
        buyer.assetScale(),
        buyer.amount()
        );
    }

    // Spend ETH or ERC20 to payee
    function spend(address _asset, address _payee, uint256 _amount) internal {
        emit Spend(_asset, _payee, _amount);
        if (_asset == address(0)) {
            (bool success,) = _payee.call{value : _amount}("");
            require(success);
        } else {
            ERC20(_asset).transfer(_payee, _amount);
        }
    }

    // Checks if hedge can be funded
    function canBeFunded() public view {
        if (status != HedgeStatus.RESERVED) {
            revert("Hedge status cannot be funded");
        }

        if (seller.isFunded()) {
            revert("Hedge already marked funded");
        }
    }

    // Mark hedge as funded
    function _markAsFunded() internal {
        status = HedgeStatus.FUNDED;
        seller.markAsFunded();
    }

    // Handling incoming ETH
    receive() external payable {
        // Check if can be funded
        canBeFunded();

        // Further checks
        if (msg.sender != seller.account()) {
            revert("Only seller can fund contract with ETH");
        }

        if (seller.assetAddr() != address(0)) {
            revert("Cannot fund contract with ETH");
        }

        uint256 amtReq = SafeMath.add(seller.amount(), premiumAmount);
        uint256 ethBalance = address(this).balance;
        if (ethBalance >= amtReq) {
            uint256 leftover = ethBalance - amtReq;
            if (leftover > 0) {
                spend(address(0), seller.account(), leftover);
            }

            _markAsFunded();
        }
    }

    // Fund the hedge with ERC20
    function fundErc20() public onlyOwnerOrSeller returns (bool) {
        // Check if can be funded
        canBeFunded();

        if (seller.assetAddr() == address(0)) {// Selling ERC20?
            revert("Cannot fund contract with ERC20");
        }

        if (seller.account() == address(0)) {
            revert("Seller account not set");
        }

        uint256 amtReq = SafeMath.add(seller.amount(), premiumAmount);
        ERC20 sellerToken = ERC20(seller.assetAddr());

        // Check ERC20 allowance
        (uint256 allowance) = sellerToken.allowance(seller.account(), address(this));
        if (allowance < amtReq) {
            revert("Not enough ERC20 allowance");
        }

        (uint balance) = sellerToken.balanceOf(seller.account());
        if (balance < amtReq) {
            revert("Not enough ERC20 balance");
        }

        sellerToken.transferFrom(seller.account(), address(this), amtReq);

        // Verify transfer from ERC20
        (uint newTokenBalance) = sellerToken.balanceOf(address(this));
        if (newTokenBalance < amtReq) {
            revert("Not receive full ERC20");
        }

        _markAsFunded();
        return true;
    }

    // Cancel funded, but unsold hedge back to seller's address
    function cancel() public onlyOwnerOrSeller {
        if (status != HedgeStatus.FUNDED || !seller.isFunded()) {
            revert("Cannot cancel hedge at current stage");
        }

        // Send back all held assets to seller
        uint256 balance = seller.getBalance();
        spend(seller.assetAddr(), seller.account(), balance);

        // Set status to cancelled
        status = HedgeStatus.CANCELLED;
        seller.markWithdrawn();
    }

    // Buy the hedge
    function buyHedge(address _user) public onlyOwner {
        if (buyer.account() != address(0) || buyer.isFunded()) {// Checking if its still up for sale
            revert("Hedge no longer available");
        }

        if (status != HedgeStatus.FUNDED || !seller.isFunded()) {
            revert("Cannot buy unfunded hedge");
        }
        // Check ERC20 allowance
        ERC20 token = ERC20(buyer.assetAddr());
        (uint256 allowance) = token.allowance(_user, address(this));
        if (allowance < buyer.amount()) {
            revert("Not enough ERC20 allowance");
        }

        (uint balance) = token.balanceOf(_user);
        if (balance < buyer.amount()) {
            revert("Not enough ERC20 balance");
        }

        // Transfer ERC20 units to itself
        token.transferFrom(_user, address(this), buyer.amount());

        // Verify transfer from ERC20
        (uint ownTokenBalance) = token.balanceOf(address(this));
        if (ownTokenBalance < buyer.amount()) {
            revert("Not receive full ERC20");
        }

        // Mark Buyer Hedge Object
        buyer.setUserAccount(_user);
        buyer.markAsFunded();

        // Transfer premium to Buyer
        spend(seller.assetAddr(), _user, premiumAmount);

        // Activate Hedge
        status = HedgeStatus.ACTIVE;
        activatedOn = block.timestamp;
    }

    // Claim hedge
    function claim(uint8 _for, uint8 _asset) public returns (bool) {
        if (status != HedgeStatus.ACTIVE) {// Status check
            revert("Hedge cannot be claimed at this stage");
        }

        if (maturity > activatedSince()) {// Check maturity
            revert("Hedge not matured");
        }

        if (msg.sender != ownerAddr) {
            if (msg.sender == seller.account()) {
                _for = 1;
            } else if (msg.sender == buyer.account()) {
                _for = 2;
            } else {
                revert("Unauthorized address");
            }
        }

        // Accounting
        bool claimed = false;
        if (_for == 1) {// On behalf of Party A
            if (_asset != 1 && _asset != 2) {// Check asset claim
                revert("Invalid seller asset claim");
            }

            if (_asset == 1) {
                // Return asset A to seller
                spend(seller.assetAddr(), seller.account(), seller.amount());
                // Return asset B to buyer
                spend(buyer.assetAddr(), buyer.account(), buyer.amount());
            } else if (_asset == 2) {
                // Return asset B to seller
                spend(buyer.assetAddr(), seller.account(), buyer.amount());
                // Return asset A to buyer
                spend(seller.assetAddr(), buyer.account(), seller.amount());
            }
        } else if (_for == 2) {// On behalf of Party B
            // Return asset A to seller
            spend(seller.assetAddr(), seller.account(), seller.amount());
            // Return asset B to buyer
            spend(buyer.assetAddr(), buyer.account(), buyer.amount());
        } else {
            revert("Invalid argument _for");
        }

        // Change Statuses
        status = HedgeStatus.FINISHED;
        finishedOn = block.timestamp;
        seller.markWithdrawn();
        buyer.markWithdrawn();

        return claimed;
    }

    // Refuse any incoming ETH value with calls
    fallback() external payable {
        revert("Do not send ETH with your call");
    }
}