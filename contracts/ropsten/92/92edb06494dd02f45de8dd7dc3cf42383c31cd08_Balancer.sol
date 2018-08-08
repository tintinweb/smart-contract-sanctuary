contract Ownable {
    address public owner;

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    constructor() public {
        owner = msg.sender; 
    }

    /**
        @dev Transfers the ownership of the contract.

        @param _owner Address of the new owner
    */
    function setOwner(address _owner) public onlyOwner returns (bool) {
        require(_owner != address(0));
        owner = _owner;
        return true;
    } 
}

contract RpSafeMath {
    function safeAdd(uint256 x, uint256 y) internal returns(uint256) {
      uint256 z = x + y;
      assert((z >= x) && (z >= y));
      return z;
    }

    function safeSubtract(uint256 x, uint256 y) internal returns(uint256) {
      assert(x >= y);
      uint256 z = x - y;
      return z;
    }

    function safeMult(uint256 x, uint256 y) internal returns(uint256) {
      uint256 z = x * y;
      assert((x == 0)||(z/x == y));
      return z;
    }

    function min(uint256 a, uint256 b) internal returns(uint256) {
        if (a < b) { 
          return a;
        } else { 
          return b; 
        }
    }
    
    function max(uint256 a, uint256 b) internal returns(uint256) {
        if (a > b) { 
          return a;
        } else { 
          return b; 
        }
    }
}

contract HasWorkers is Ownable {
    mapping(address => uint256) private workerToIndex;    
    address[] private workers;

    event AddedWorker(address _worker);
    event RemovedWorker(address _worker);

    constructor() public {
        workers.length++;
    }

    modifier onlyWorker() {
        require(isWorker(msg.sender));
        _;
    }

    modifier workerOrOwner() {
        require(isWorker(msg.sender) || msg.sender == owner);
        _;
    }

    function isWorker(address _worker) public view returns (bool) {
        return workerToIndex[_worker] != 0;
    }

    function allWorkers() public view returns (address[] memory result) {
        result = new address[](workers.length - 1);
        for (uint256 i = 1; i < workers.length; i++) {
            result[i - 1] = workers[i];
        }
    }

    function addWorker(address _worker) public onlyOwner returns (bool) {
        require(!isWorker(_worker));
        uint256 index = workers.push(_worker) - 1;
        workerToIndex[_worker] = index;
        emit AddedWorker(_worker);
        return true;
    }

    function removeWorker(address _worker) public onlyOwner returns (bool) {
        require(isWorker(_worker));
        uint256 index = workerToIndex[_worker];
        address lastWorker = workers[workers.length - 1];
        workerToIndex[lastWorker] = index;
        workers[index] = lastWorker;
        workers.length--;
        delete workerToIndex[_worker];
        emit RemovedWorker(_worker);
        return true;
    }
}

contract Token {
    function transfer(address _to, uint _value) returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);
    function allowance(address _owner, address _spender) constant returns (uint256 remaining);
    function approve(address _spender, uint256 _value) returns (bool success);
    function increaseApproval (address _spender, uint _addedValue) public returns (bool success);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
}


/*
    @notice Receives ETH or Tokens and routes them to a list of accounts or to a cold wallet.
*/
contract Balancer is RpSafeMath, Ownable, HasWorkers {
    address[] public accounts;
    address public coldWallet;

    uint256 public limitEth;
    mapping(address => uint256) public limitToken;

    bool public paused;

    constructor() public {
        coldWallet = msg.sender;
    }

    /*
        @return All the "hotwallet" accounts, it must have at least one.
    */
    function allAccounts() public view returns (address[]) {
        return accounts;
    }

    /*
        @notice Pauses the balancer, if the Balancer is paused all ETH/tokens
            will be realyed to the coldwallet.

        @dev Any worker can pause the contract
    */
    function pause() public workerOrOwner returns (bool) {
        paused = true;
        return true;
    }

    /*
        @notice Unpauses the balancer.

        @dev Only the owner can unpause
    */
    function unpause() public onlyOwner returns (bool) {
        paused = false;
        return true;
    }

    /*
        @notice Sets the total max amount in ETH for the accounts to hold,
            any exceeding funds will be sent to the coldWallet.
        
        @param limit Max amount in wei
    */
    function setLimitEth(uint256 limit) public onlyOwner returns (bool) {
        limitEth = limit;
        return true;
    }

    /*
        @notice Sets the total max amount in token for the accounts to hold,
            any exceeding funds will be sent to the coldWallet.
        
        @param token Token to set the limit
        @param limit Max amount in wei
    */
    function setLimitToken(Token token, uint256 limit) public onlyOwner returns (bool) {
        limitToken[token] = limit;
        return true;
    }

    /*
        @notice Adds an account to the "hotwallet" group

        @param account Address of the account
    */
    function addAccount(address account) public onlyOwner returns (bool) {
        accounts.push(account);
        return true;
    }

    /*
        @notice Removes an account

        @dev This method iterates over the accounts array, if number of accounts
            is too big this method will fail. Use carefully.

        @param account Account to remove
    */
    function removeAccountSearch(address account) public onlyOwner returns (bool) {
        for(uint256 index = 0; index < accounts.length; index++) {
            if (accounts[index] == account) {
                return removeAccount(index, account);
            }
        }

        revert();
    }

    /*
        @notice Removes an account without searching for the index.

        @param index Index of the account, must match the account index.
        @param account Account to remove
    */
    function removeAccount(uint256 index, address account) public onlyOwner returns (bool) {
        require(accounts[index] == account);
        accounts[index] = accounts[accounts.length - 1];
        accounts.length -= 1;
        return true;
    }

    /*
        @notice Changes the coldwallet, exceeding funds will be sent here

        @param wallet New coldwallet address
    */
    function setColdWallet(address wallet) public onlyOwner returns (bool) {
        coldWallet = wallet;
        return true;
    }

    /*
        @notice Executes any transaction
    */
    function executeTransaction(address to, uint256 value, bytes data) public onlyOwner returns (bool) {
        return to.call.value(value)(data);
    }

    /*
        @notice Loads the ETH balances of all the accounts
    */
    function loadEthBalances() public view returns (uint256[] memory, uint256 total) {
        uint256[] memory result = new uint256[](accounts.length);
        uint256 balance;
        for (uint256 i = 0; i < accounts.length; i++) {
            balance = accounts[i].balance;
            result[i] = balance;
            total += balance;
        }
        return (result, total);
    }

    /*
        @notice Loads the token balance of all the accounts
    */
    function loadTokenBalances(Token token) public view returns (uint256[] memory, uint256 total) {
        uint256[] memory result = new uint256[](accounts.length);
        uint256 balance;
        for (uint256 i = 0; i < accounts.length; i++) {
            balance = token.balanceOf(accounts[i]);
            result[i] = balance;
            total += balance;
        }
        return (result, total);
    }

    /*
        @notice Calculates the optimal per-wallet balance target

        @param target The global target
        @param balances The balance of each account

        @return nTarget The target per account
    */
    function getTargetPerWallet(uint256 target, uint256[] memory balances) internal pure returns (uint256 nTarget) {
        uint256 d = balances.length;
        uint256 oTarget = target / balances.length;
        uint256 t;

        for (uint256 i = 0; i < balances.length; i++) {
            if (balances[i] > oTarget) {
                d--;
                t += (balances[i] - oTarget);
            }
        }

        nTarget = oTarget - (t / d);
    }

    /*
        @notice Forawards the ETH to the defined accounts, if the limit is exceeded
            sends the extra ETH to the coldwallet.

        @dev If gas is not enought the ETH is temporary stored in the contract
    */
    function() public payable {
        if (gasleft() > 2400) {
            if (paused) {
                coldWallet.transfer(address(this).balance);
            } else {
                uint256[] memory balances;
                uint256 total;
                
                (balances, total) = loadEthBalances();

                uint256 value = address(this).balance;
                uint256 targetTotal = min(limitEth, total + value);

                if (targetTotal > total) {
                    uint256 targetPerHotwallet = getTargetPerWallet(targetTotal, balances);

                    for (uint256 i = 0; i < balances.length; i++) {                        
                        if (balances[i] < targetPerHotwallet) {
                            accounts[i].transfer(targetPerHotwallet - balances[i]);
                        }
                    }
                }

                uint256 toColdWallet = address(this).balance;
                if (toColdWallet != 0) {
                    coldWallet.transfer(toColdWallet);
                }
            }
        }            
    }

    /*
        @notice Forawards the tokens to the defined accounts, if the limit is exceeded
            sends the extra tokens to the coldwallet.

        @param token Token to forward
    */
    function handleTokens(Token token) public returns (bool) {
        if (paused) {
            token.transfer(coldWallet, token.balanceOf(this));
        } else {
            uint256[] memory balances;
            uint256 total;
            
            (balances, total) = loadTokenBalances(token);

            uint256 value = token.balanceOf(address(this));
            uint256 targetTotal = min(limitToken[token], total + value);

            if (targetTotal > total) {
                uint256 targetPerHotwallet = getTargetPerWallet(targetTotal, balances);

                for (uint256 i = 0; i < balances.length; i++) {
                    if (balances[i] < targetPerHotwallet) {
                        token.transfer(accounts[i], targetPerHotwallet - balances[i]);
                    }
                }
            }

            uint256 toColdWallet = token.balanceOf(address(this));
            if (toColdWallet != 0) {
                token.transfer(coldWallet, toColdWallet);
            }
        }
    }
}