pragma solidity 0.6.9;
pragma experimental ABIEncoderV2;


struct Account {
    uint256 etherBalance;
    TokenBalance[] tokenBalances;
}


struct TokenBalance {
    bool callSuccess;
    uint256 balance;
}


interface ERC20Interface {
    function balanceOf(address account) external view returns (uint256 balance);
}


interface AccountWatcherInterface {
    function balancesOf(
        ERC20Interface[] calldata tokens, address[] calldata accounts
    ) external view returns (Account[] memory accountBalances);
}


/// Quickly check the Ether balance, as well as the balance of each
/// supplied ERC20 token, for a collection of accounts.
/// @author 0age
contract AccountWatcherV2 is AccountWatcherInterface {
    function balancesOf(
        ERC20Interface[] calldata tokens, address[] calldata accounts
    ) external view override returns (Account[] memory) {
        Account[] memory accountBalances = new Account[](accounts.length);

        for (uint256 i = 0; i < accounts.length; i++) {
            address account = accounts[i];

            TokenBalance[] memory tokenBalances = new TokenBalance[](tokens.length);

            for (uint256 j = 0; j < tokens.length; j++) {
                ERC20Interface token = tokens[j];
                (bool success, bytes memory returnData) = address(token).staticcall(
                    abi.encodeWithSelector(token.balanceOf.selector, account)
                );
                
                if (success && returnData.length >= 32) {
                    TokenBalance memory tokenBalance;
                    
                    tokenBalance.callSuccess = true;
                    tokenBalance.balance = abi.decode(returnData, (uint256));
                    
                    tokenBalances[j] = tokenBalance;
                }
            }

            accountBalances[i].etherBalance = account.balance;
            accountBalances[i].tokenBalances = tokenBalances;
        }

        return accountBalances;
    }
}