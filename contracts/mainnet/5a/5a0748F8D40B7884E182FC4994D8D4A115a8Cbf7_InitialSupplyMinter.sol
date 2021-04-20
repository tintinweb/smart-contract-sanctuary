// SPDX-License-Identifier: F-F-F-FIAT!!!
pragma solidity ^0.7.4;

import "./Address.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";
import "./IERC20.sol";
import "./Fiat.sol";
import "./TokensRecoverable.sol";

/* ROOTKIT:
- Minting contract for initial supply of FIAT
- To be Owned by the ROOT DAO multisig
- This minter contract is for internal use only
- Mint amount per ROOT should never be more than 50% of the current ROOT price
- This Minter contracts will be phased out when more public minters are active
- Other minter contracts will all be available to the public
*/

contract InitialSupplyMinter is TokensRecoverable {
    using Address for address;
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    Fiat public immutable fiat;
    IERC20 public immutable rootKit;

    mapping(address => bool) public approvedMinters;
    mapping(address => uint256) public collaterals; // Root
    mapping(address => uint256) public debts; // Fiat   

    uint256 public fiatPerRoot = 1000;

    constructor(Fiat _fiat, IERC20 _rootKit) {
        fiat = _fiat;
        rootKit = _rootKit;
    }

    function updateFiatPerRoot(uint256 _fiatPerRoot) public ownerOnly() {
        fiatPerRoot = _fiatPerRoot;
    }

    function setMinter(address minter, bool canMint) public ownerOnly() {
        approvedMinters[minter] = canMint;
    }

    function depositCollateral(uint256 amount) public {
        require(approvedMinters[msg.sender], "Not an approved minter");

        rootKit.transferFrom(msg.sender, address(this), amount);
        collaterals[msg.sender] += amount;
    }

    function mintFiat(uint256 amount) public {
        require(approvedMinters[msg.sender], "Not an approved minter");
        require(amount <= getAvailableToMint(msg.sender), "Not enought collateral to mint fiat");

        fiat.mint(msg.sender, amount);
        debts[msg.sender] += amount;
    }

    function repayDebt(address account, uint256 amount) public {
        fiat.burn(msg.sender, amount);
        debts[account] -= amount;
    }

    function withdrawCollateral(uint256 amount) public {
        require(approvedMinters[msg.sender], "Not an approved minter");
        require(getAvailableCollateralToWithdraw(msg.sender) >= amount, "Not enought collateral to withdraw");

        rootKit.transfer(msg.sender, amount);
        collaterals[msg.sender] -= amount;
    }

    function getAvailableToMint(address account) public view returns (uint256) {
        return collaterals[account] * fiatPerRoot - debts[account];
    }

    function getAvailableCollateralToWithdraw(address account) public view returns (uint256) {
        return collaterals[account] - debts[account].mul(1e18).div(fiatPerRoot).div(1e18);
    }
}