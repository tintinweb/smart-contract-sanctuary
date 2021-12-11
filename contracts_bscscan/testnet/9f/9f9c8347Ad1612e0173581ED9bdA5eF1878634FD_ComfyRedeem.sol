/**
 *Submitted for verification at BscScan.com on 2021-12-10
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
abstract contract ReentrancyGuard {

    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
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
    mapping (address => bool) internal authorizations;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(_msgSender());
    }

  
    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    modifier authorized() {
        require(isAuthorized(msg.sender), "Not authorized!"); 
        _;
    }

 
    function authorizeAddress(address adr) internal {
        authorizations[adr] = true;
    }

    
    function unauthorizeAddress(address adr) internal {
        authorizations[adr] = false;
    }

    function isAuthorized(address adr) public view returns (bool) {
        return authorizations[adr];
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        authorizations[newOwner] = true;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IBEP20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function getOwner() external view returns (address);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract ComfyRedeem is ReentrancyGuard, Ownable {

    address CUSD;
    address BUSD = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;
    address USDT = 0xaF5DcEBba2f8bEc8729117336b2FE8B4E0D99b0B;
    address USDC = 0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d;
    address UST = 0x23396cF899Ca06c4472205fC903bDB4de249D6fC;
    address TUSD = 0x14016E85a25aeb13065688cAFB43044C2ef86784;
    address DEAD = 0x000000000000000000000000000000000000dEaD;

    address multiSigWallet = 0xeAeC88719a429229DBc7689F55aDe8c218261040; // CHANGE THIS BEFORE DEPLOY 0x85f2893B8984d289C9afb6B4F0fB73d84fb1efbA
    address oldMultiSigWallet = 0xeAeC88719a429229DBc7689F55aDe8c218261040; // CHANGE THIS BEFORE DEPLOY

    uint256 changeMultiSigTimer = 1 hours; // CHANGE THIS BEFORE DEPLOY 7 DAYS
    uint256 multiSigWalletDate;

    struct WithdrawalTracker {
        uint256 timestamp;
        uint256 amount;
    }
    
    mapping(address => uint256) stablesDecimals; // address -> decimals
    uint256 stableWithdrawalLimit = 10000; // This value will then be multiplied by the decimals of the selected stable coin
    mapping(uint256 => WithdrawalTracker) stableWithdrawals; // index -> WithdrawalTracker
    uint256 stableWithdrawalCounter = 0;

    modifier onlyMultiSig() {
        address currentMultiSigWallet = (block.timestamp - multiSigWalletDate) > 7 days ? multiSigWallet : oldMultiSigWallet;
        require(msg.sender == currentMultiSigWallet, "Only the MultiSig wallet can call this function!");
        _;
    } 

    constructor() {
        stablesDecimals[BUSD] = 18;
        stablesDecimals[USDT] = 18;
        stablesDecimals[USDC] = 6;
        stablesDecimals[UST] = 18;
        stablesDecimals[TUSD] = 18;
    }

    receive() external payable { }

    function withdrawalToken(address tokenAddress) external authorized {
        require(!isStable(tokenAddress), "Can not withdraw stable coins");
        IBEP20 token = IBEP20(tokenAddress);
        uint256 balance = token.balanceOf(address(this));
        require(balance > 0, "Nothing to withdraw");
        require(token.transfer(multiSigWallet, balance), "Transfer failed");
    }

    function withdrawalStable(address tokenAddress, uint256 amount) external authorized {
        require(isStable(tokenAddress), "Can not withdraw not stable coins");
        require(checkWithdrawalPeriod(amount, stablesDecimals[tokenAddress]), "You need to wait 22 hours before whitdraw again");
        require(amount <= stableWithdrawalLimit * 10 ** stablesDecimals[tokenAddress], "Withdrawal limit exceeded");

        IBEP20 stableCoin = IBEP20(tokenAddress);
        require(stableCoin.transfer(msg.sender, amount));
    }

    function swapCusdForStable(address stableAddress, uint256 amount) external nonReentrant {
        require(isStable(stableAddress), "Invalid stable address");
        IBEP20 cusdToken = IBEP20(CUSD);
        IBEP20 stable = IBEP20(stableAddress);
        uint256 userBalance = cusdToken.balanceOf(msg.sender);
        require(userBalance >= amount, "Insufficient amount");
        require(cusdToken.transferFrom(msg.sender, address(this), amount), "Transfer to ComfyRedeem failed");
        require(stable.transfer(msg.sender, amount), "Transfer from ComfyRedeem failed");
        require(cusdToken.transfer(DEAD, amount));
    }
    
    function changeMultiSig(address newWalletAddress) external onlyMultiSig {
        multiSigWalletDate = block.timestamp;
        oldMultiSigWallet = multiSigWallet;
        multiSigWallet = newWalletAddress;
    }


    function checkWithdrawalPeriod(uint256 amount, uint256 decimals) internal view returns(bool) {
        uint256 totalWithdrawal = 0;
        uint256 withdrawalLimit = stableWithdrawalLimit * 10 ** decimals;
        if(stableWithdrawalCounter > 0) {
            for(uint256 i = stableWithdrawalCounter; i >= 0; i--) {
                if(stableWithdrawals[i].timestamp > (block.timestamp - 22 hours)) {
                    totalWithdrawal += stableWithdrawals[i].amount;
                } else {
                    break;
                }
            }
        }
        return totalWithdrawal + amount <= withdrawalLimit;
    }

    function setCusdAddress(address cusdAddress) external onlyOwner {
        CUSD = cusdAddress;
    }
    function isStable(address tokenAddress) internal view returns(bool) {
        return tokenAddress == BUSD || tokenAddress == USDT || tokenAddress == USDC 
                || tokenAddress == UST || tokenAddress == TUSD;
    }

    function authorizeUser(address walletAddress) external onlyMultiSig {
        authorizeAddress(walletAddress);
    }

    function unauthorizeUser(address walletAddress) external onlyMultiSig {
        unauthorizeAddress(walletAddress);
    }

    // REMOVE THIS AFTER TESTS

    function setTUSDAddress(address newTestAddress) external onlyOwner {
        TUSD = newTestAddress;
    }

    function setUSDTAddress(address newTestAddress) external onlyOwner {
        USDT = newTestAddress;
    }

}