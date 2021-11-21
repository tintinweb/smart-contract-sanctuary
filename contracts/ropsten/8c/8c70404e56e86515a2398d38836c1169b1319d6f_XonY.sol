// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./UintUtils.sol";

contract XonY is Ownable {

    using SafeMath for uint;
    using UintUtils for uint;

    struct Future {
        address nativeToken;
        address purchaseToken;
        address owner;
        uint unitPrice;
        uint unlockInBlock;
        uint balance;
        bool isEnabled;
        bool flag;
        bool isAssigned;
    }

    address[] private _sources;
    mapping(address => Future) private _futures;
    mapping(address => address) private _nativeToSource;
    uint private _feePercentage;
    address private _feeWallet;

    constructor() {
        _feePercentage = 2; // 0.2
        _feeWallet = _msgSender();
    }

    function deposit(address sourceAddress, address purchaseAddress, uint unitPrice, uint256 amount, uint256 unlockInBlock) public returns (bool) {
        require(unitPrice > 0, "invalid unit price");
        require(unlockInBlock > block.number, "invalid block number");

        Future memory f;

        ERC20 sourceToken = ERC20(sourceAddress);
        uint amountApproved = sourceToken.allowance(_msgSender(), address(this));
        require(amountApproved >= amount, "insufficient approval for source token");

        bool result = sourceToken.transferFrom(_msgSender(), address(this), amount);
        require(result == true, "unable to transfer source token");

        uint256 sourceTokenBalance = sourceToken.balanceOf(address(this));
        require(sourceTokenBalance == amount, "mismatched balance");

        f.purchaseToken = purchaseAddress;
        f.unitPrice = unitPrice;
        f.balance = amount;

        address nativeToken = mintToken(sourceToken.symbol(), amount, sourceToken.decimals(), unlockInBlock);
        f.nativeToken = nativeToken;
        f.unlockInBlock = unlockInBlock;
        f.owner = _msgSender();
        f.isAssigned = true;
        f.isEnabled = true;
        f.flag = false;

        _sources.push(sourceAddress);
        _futures[sourceAddress] = f;
        _nativeToSource[nativeToken] = sourceAddress;
        return true;
    }

    function mintToken(string memory symbol, uint256 amount, uint8 decimal, uint256 blockNumber) private returns (address) {
        string memory name = string(abi.encodePacked(symbol, "@", blockNumber.toString()));
        ERC20 newToken = new ERC20(name, name, decimal, amount);
        return address(newToken);
    }

    function buy(address native, uint amount) public returns (bool) {
        require(amount > 0, "invalid amount");

        address source = _nativeToSource[native];
        Future storage f = _futures[source];
        require(f.isAssigned == true, "token not found");
        require(f.isEnabled == true, "token is not enabled");

        ERC20 nativeToken = ERC20(native);
        ERC20 purchaseToken = ERC20(f.purchaseToken);
        checkManipulation(source, f);

        uint calcAmount = amount.div(f.unitPrice, "error: SM-div").mul(10 ** nativeToken.decimals());
        {
            uint nativeBalance = nativeToken.balanceOf(address(this));
            require(nativeBalance > 0, "sold out!");
            
            require(nativeBalance >= calcAmount, "insufficient native balance");

            uint pAmountApproved = purchaseToken.allowance(_msgSender(), address(this));
            require(pAmountApproved >= amount, "insufficient approval for purchase token");
        }

        uint fee = amount.mul(_feePercentage * (10 ** (purchaseToken.decimals() - 1))).div(100 * (10 ** purchaseToken.decimals()), "error: SM-div");
        uint ownerShare = amount.sub(fee, "error: SM-sub");
        bool tResult = purchaseToken.transferFrom(_msgSender(), f.owner, ownerShare);
        bool ftResult = purchaseToken.transferFrom(_msgSender(), _feeWallet, fee);
        require(tResult == true && ftResult == true, "unable to transfer purchase token");

        bool ntResult = nativeToken.transfer(_msgSender(), calcAmount);
        require(ntResult == true, "unable to transfer native token");

        return true;
    }

    function redeem(address native, uint256 amount) public returns (bool) {
        require(amount > 0, "invalid amount");

        address source = _nativeToSource[native];
        Future storage f = _futures[source];
        require(f.isAssigned == true, "token not found");
        require(f.isEnabled == true, "token is not enabled");
        require(block.number >= f.unlockInBlock, "redeem still locked");
        checkManipulation(source, f);

        ERC20 sourceToken = ERC20(source);
        bool tResult = sourceToken.transfer(_msgSender(), amount);
        require(tResult == true, "unable to transfer source token");
        f.balance -= amount;

        ERC20 nativeToken = ERC20(native);
        nativeToken.burnFrom(_msgSender(), amount);

        return true;
    }

    function checkManipulation(address source, Future storage f) private {
        require(f.flag == false, "token is flagged");
        ERC20 sourceToken = ERC20(source);
        uint sourceBalance = sourceToken.balanceOf(address(this));
        bool isManipulated = sourceBalance != f.balance;
        if (isManipulated) {
            f.flag = true;
            f.isEnabled = false;
            revert("source balance manipulated");
        }
    }

    function getDepositedTokens() public view returns (address[] memory) {
        return _sources;
    }

    function futureOf(address source) public view returns (Future memory) {
        return _futures[source];
    }

    function setEnabled(address token, bool isEnabled) public onlyOwner {
        _futures[token].isEnabled = isEnabled;
    }

    function setFee(uint fee) public onlyOwner {
        _feePercentage = fee;
    }

    function getFee() public view returns (uint) {
        return _feePercentage;
    }

    function setFeeWallet(address wallet) public onlyOwner {
        _feeWallet = wallet;
    }

    function getFeeAddress() public view returns (address) {
        return _feeWallet;
    }

}