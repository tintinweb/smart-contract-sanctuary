/**
 *Submitted for verification at Etherscan.io on 2021-06-16
*/

pragma solidity ^0.8.3;

contract ElementContract {
    address private owner = msg.sender;
    uint256 profitPercent = 0;

    struct Account {
        address addr;
        uint256 numberTrx;
        uint256 depositAmount;
        uint256 depositCounter;
        uint256 depositYields;
    }

    mapping(address => Account[]) private accounts;
    mapping(address => bool) private joinedAccounts;
    address[] internal keyList;

    //Function to deposit in the contract: 80% owner, 20% contract
    function invest(uint256 amount) public payable {
        require(msg.value == amount);
        payable(owner).transfer((amount * 80) / 100);
        join(amount);
    }

    //Function to save data of personal accounts in map accounts
    function join(uint256 amount) private {
        if (accountJoined(msg.sender)) {
            uint256 count = accounts[msg.sender].length;
            Account memory account = accounts[msg.sender][count - 1];
            uint256 numberTrxAux = (account.numberTrx + 1);

            accounts[msg.sender].push(
                Account(msg.sender, numberTrxAux, amount, 0, 0)
            );
        } else {
            accounts[msg.sender].push(Account(msg.sender, 1, amount, 0, 0));
            keyList.push(msg.sender);
        }
        joinedAccounts[msg.sender] = true;
    }

    //Function to deposit yields in an Account
    function depositYields(
        uint256 amount,
        address to,
        uint256 transactionNumber
    ) private {
        Account storage accountAux = accounts[to][transactionNumber - 1];
        uint256 numberTrx = accountAux.numberTrx;
        uint256 depositAmount = accountAux.depositAmount;
        uint256 depositCounter = (accountAux.depositCounter + 1);
        uint256 depostiYields = (accountAux.depositYields + amount);
        accounts[to][transactionNumber - 1] = (
            Account(to, numberTrx, depositAmount, depositCounter, depostiYields)
        );
    }

    //Function to get the balance of the contract
    function getBalance() private view returns (uint256) {
        return (address(this).balance);
    }

    //Function to tranfer an amount of cash to an owner account
    function transferToOwner(uint256 amount) public onlyBy(owner) {
        require(address(this).balance >= amount, "Insufficient balance amount");
        payable(owner).transfer(amount);
    }

    //Function to tranfer an amount of cash to an account
    function transferTo() public onlyBy(owner) {
        //require(accountJoined(to), "Account not registered.");
        //require(to != address(0));

        uint256 sum = 0;
        uint256 amount = 0;
        for (uint256 i = 0; i < keyList.length; i++) {
            address addrAux = keyList[i];
            for (uint256 j = 0; j < accounts[addrAux].length; j++) {
                Account memory accountAux = accounts[addrAux][j];
                if (accountAux.depositCounter < 12) {
                    amount = (accountAux.depositAmount * profitPercent) / 100;
                    sum = sum + amount;
                }
            }
        }
        amount = 0;
        if (sum > 0) {
            if (getBalance() >= sum) {
                for (uint256 i = 0; i < keyList.length; i++) {
                    address addrAux = keyList[i];
                    for (uint256 j = 0; j < accounts[addrAux].length; j++) {
                        Account memory accountAux = accounts[addrAux][j];
                        if (accountAux.depositCounter < 12) {
                            amount =
                                (accountAux.depositAmount * profitPercent) /
                                100;
                            depositYields(
                                amount,
                                addrAux,
                                accountAux.numberTrx
                            );
                            payable(addrAux).transfer(amount);
                        }
                    }
                }
            } else {
                revert("This transaction exceeds the number of deposits limit");
            }
        } else {
            revert("No benefits to deposit");
        }
    }

    //Function to get info about personal accounts
    function getAccountBalance(address add) public view returns (Account[] memory) {
        require(accountJoined(add), "Account not registered.");
        uint256 count = accounts[add].length;
        Account[] memory array = new Account[](count);
        for (uint256 i = 0; i < count; i++) {
            array[i] = accounts[add][i];
        }
        return array;
    }

    //Function to validate if an account exist
    function accountJoined(address addr) private view returns (bool) {
        return joinedAccounts[addr];
    }

    //Function to modify profitPercent
    function modifyProfitPercent(uint256 percent) public  onlyBy(owner){
        profitPercent = percent;
    }

    //Function for owner
    modifier onlyBy(address _account) {
        require(msg.sender == _account, "Sender not authorized.");
        _;
    }
        function transferOwnership(address _newOwner) public onlyBy(owner) {
        owner = _newOwner;
    }
}