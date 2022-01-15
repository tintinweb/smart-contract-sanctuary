pragma solidity ^0.8.9;

import "./IERC20.sol";
import "./OwnableApprovers.sol";

contract Beneficiaries is OwnableApprovers {
    IERC20Metadata token =
        IERC20Metadata(0x3d89AC72cA5d5881F6F00C73B1ce59431aeC0b04);

    address[] public accounts = [
        0x4bDbceC5Eba3Fc4072B75d9b94B4029Df19849be,
        0x8D4ee4542A89A0320f038090627d67DC2d8DD41A,
        0x17519fd17e82dBfeD3776b89b31477eA4447A725,
        0x1ecb0ddC3265CDB2Ce5E9747298C22196ec87B41
    ];

    uint256[] public shares = [25, 25, 40, 10]; // %

    function withdraw() external {
        uint256 balance = token.balanceOf(address(this));
        for (uint8 i = 0; i < shares.length; i++) {
            uint256 value = (shares[i] * balance) / 100;
            if (value > 0) {
                token.transfer(accounts[i], value);
            }
        }
    }

    function sumShares() internal view returns (uint256 sum) {
        sum = 0;
        for (uint256 i = 0; i < shares.length; i++) {
            sum += shares[i];
        }
    }

    function findAccountIndex(address account)
        internal
        view
        returns (bool accountFound, uint256 accountIndex)
    {
        accountFound = false;
        for (uint256 i = 0; i < accounts.length; i++) {
            if (accounts[i] == account) {
                accountIndex = i;
                accountFound = true;
            }
        }
    }

    function checkShares() internal view {
        require(
            sumShares() <= 100,
            "sum of shares should less or equal than 100%"
        );
    }

    function setShare(address account, uint256 share) external onlyOwner {
        (bool accountFound, uint256 i) = findAccountIndex(account);
        require(accountFound, "the Account not found");
        shares[i] = share;
        checkShares();
    }

    function newBeneficiary(address account, uint256 share) external onlyOwner {
        (bool accountFound, uint256 i) = findAccountIndex(account);
        require(!accountFound, "the Account currently exists");
        accounts.push(account);
        shares.push(share);
        checkShares();
    }
}