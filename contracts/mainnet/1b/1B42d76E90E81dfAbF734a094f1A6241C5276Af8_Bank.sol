// File: contracts/pike/BaseBank.sol

pragma solidity >=0.5.0 <0.6.0;

contract BaseBank {

}


// File: contracts/library/ERC20Not.sol

pragma solidity >=0.5.0 <0.6.0;

interface ERC20Not {
    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address _owner) external view returns (uint256);

    function allowance(address _owner, address _spender)
        external
        view
        returns (uint256);

    function transfer(address _to, uint256 _value) external ;

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) external;

    function approve(address _spender, uint256 _value) external returns (bool);

    function decreaseApproval(address _spender, uint256 _subtractedValue)
        external
        returns (bool);

    function increaseApproval(address _spender, uint256 _addedValue)
        external
        returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// File: contracts/library/ERC20Yes.sol

pragma solidity >=0.5.0 <0.6.0;

// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
interface ERC20Yes {
    function totalSupply() external view returns (uint256);

    function balanceOf(address tokenOwner)
        external
        view
        returns (uint256 balance);

    function allowance(address tokenOwner, address spender)
        external
        view
        returns (uint256 remaining);

    function transfer(address to, uint256 tokens)
        external
        returns (bool success);

    function approve(address spender, uint256 tokens)
        external
        returns (bool success);

    function transferFrom(
        address from,
        address to,
        uint256 tokens
    ) external returns (bool success);

    event Transfer(address indexed from, address indexed to, uint256 tokens);
    event Approval(
        address indexed tokenOwner,
        address indexed spender,
        uint256 tokens
    );
}

// File: contracts/user/BaseUsers.sol

pragma solidity >=0.5.0 <0.6.0;

contract BaseUsers {
    //
    function register(address _pid, address _who) external returns (bool);

    function setActive(address _who) external returns (bool);
    
    function setMiner(address _who) external returns (bool);

    function isActive(address _who) external view returns (bool);

    // Determine if the address has been registered
    function isRegister(address _who) external view returns (bool);

    // Get invitees
    function inviteUser(address _who) external view returns (address);

    function isBlackList(address _who) external view returns (bool);

    function getUser(address _who)
        external
        view
        returns (
            address id,
            address pid,
            bool miner,
            bool active,
            uint256 created_at
        );

}

// File: contracts/funds/BaseFunds.sol

pragma solidity >=0.5.0 <0.6.0;

contract BaseFunds {
    function activeUser(
        address _who,
        uint256 _tokens
    ) external returns (bool);

    function upgradeUser(
        address _who,
        uint256 _tokens
    ) external returns (bool);

    function buyMiner(
        address _who,
        uint256 _tokens
    ) external returns (bool);

    function deposit(
        address _tokenAddress,
        address _who,
        uint256 _tokens
    ) external returns (bool);

    function withdraw(
        address _tokenAddress,
        address _who,
        uint256 _tokens
    ) external returns (bool);

    function loan(
        address _tokenAddress,
        address _who,
        uint256 _tokens
    ) external returns (bool);

    function repay(
        address _tokenAddress,
        address _who,
        uint256 _tokens
    ) external returns (bool);

    function liquidate(
        address _tokenAddress,
        address _who,
        address _owner,
        uint256 _tokens
    ) external returns (bool);

    function isToken(address _tokenAddress) external view returns (bool);

    function isErc20(address _tokenAddress) external view returns (bool);
}

// File: contracts/net/BaseNet.sol

pragma solidity >=0.5.0 <0.6.0;

contract BaseNet {
    address payable internal _gasAddress;
    function register(address _who, address _pid) external returns (bool);

    function activeUser(address _pid, address _who, uint256 _tokens) external returns (bool);

    function upgradeUser(address _who, uint256 _tokens) external returns (bool);

    function buyMiner(address _who, uint256 _tokens) external returns (bool);

    function deposit(
        address _tokenAddress,
        address _who,
        uint256 _amount
    ) external returns (bool);

    function repay(
        address _tokenAddress,
        address _who,
        uint256 _amount
    ) external returns (bool);

    function liquidate(
        address _tokenAddress,
        address _payer,
        uint256 _amount,
        uint256 _oid
    ) external returns (bool);
}

// File: contracts/pause/BasePause.sol

pragma solidity >=0.5.0 <0.6.0;

contract BasePause {
    function isPaused() external view returns (bool);
}

// File: contracts/receipt/BaseReceipt.sol

pragma solidity >=0.5.0 <0.6.0;

contract BaseReceipt {
    function active(address _to, uint256 _tokens)
        external
        payable
        returns (bool);

    function upgrade(address _to, uint256 _tokens)
        external
        payable
        returns (bool);

    function buyMiner(address _to, uint256 _tokens)
        external
        payable
        returns (bool);

    function getActive(address _who) external view returns (uint256);
    function getUpgrade(address _who) external view returns (uint256);
    function getMiner(address _who) external view returns (uint256);
}


// File: contracts/library/Ownable.sol

pragma solidity >=0.5.0 <0.6.0;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address[3] internal owner;

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor() public {
        owner[0] = msg.sender;
        owner[1] = msg.sender;
        owner[2] = msg.sender;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlySafe() {
        require(
            msg.sender == owner[0] ||
                msg.sender == owner[1] ||
                msg.sender == owner[2]
        );
        _;
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner, uint256 k) public onlySafe {
        if (newOwner != address(0)) {
            owner[k] = newOwner;
        }
    }
}

// File: contracts/library/Interfaces.sol

pragma solidity >=0.5.0 <0.6.0;

contract Interfaces is Ownable {
    BaseNet internal NetContract;
    BaseBank internal BankContract;
    BaseUsers internal UserContract;
    BaseFunds internal FundsContract;
    BasePause internal PauseContract;
    BaseReceipt internal ReceiptContract;

    function setBankContract(BaseBank _address) public onlySafe {
        BankContract = _address;
    }

    function setUserContract(BaseUsers _address) public onlySafe {
        UserContract = _address;
    }

    function setFundsContract(BaseFunds _address) public onlySafe {
        FundsContract = _address;
    }

    function setNetContract(BaseNet _address) public onlySafe {
        NetContract = _address;
    }

    function setPauseContract(BasePause _address) public onlySafe {
        PauseContract = _address;
    }

    function setReceiptContract(BaseReceipt _address) public onlySafe {
        ReceiptContract = _address;
    }
}

// File: contracts/Bank.sol

pragma solidity >=0.5.0 <0.6.0;



contract Bank is BaseBank, Interfaces {
    bool internal open_deposit = true;
    bool internal open_loan = true;

    modifier isNotBlackList(address _who) {
        require(
            !UserContract.isBlackList(_who),
            "You are already on the blacklist"
        );
        _;
    }

    modifier whenNotPaused() {
        require(!PauseContract.isPaused(), "Data is being maintained");
        _;
    }

    function() external payable {
        revert();
    }

    function isRegister(address _who) public view returns (bool is_register) {
        return UserContract.isRegister(_who);
    }

    function isActive(address _who) public view returns (bool is_active) {
        return UserContract.isActive(_who);
    }

    // register
    function register(address _pid) public returns (bool) {
        if (UserContract.register(_pid, msg.sender)) {
            if (!NetContract.register(_pid, msg.sender)) {
                revert("register failed");
            }
            return true;
        }
        return false;
    }

    // active user
    function activeUser(address _pid)
        public
        payable
        whenNotPaused
        isNotBlackList(msg.sender)
    {
        require(msg.sender != _pid);
        if (!isRegister(msg.sender)) {
            UserContract.register(_pid, msg.sender);
        }
        if (address(uint160(address(FundsContract))).send(msg.value)) {
            require(FundsContract.activeUser(msg.sender, msg.value));
            UserContract.setActive(msg.sender);
            if (!NetContract.activeUser(_pid, msg.sender, msg.value)) {
                revert("upgrade failed");
            }
        }
    }

    // 升级矿工
    function upgradeUser()
        public
        payable
        whenNotPaused
        isNotBlackList(msg.sender)
    {
        require(isActive(msg.sender));
        if (address(uint160(address(FundsContract))).send(msg.value)) {
            require(FundsContract.upgradeUser(msg.sender, msg.value));
            if (!NetContract.upgradeUser(msg.sender, msg.value)) {
                revert("upgrade failed");
            }
        }
    }

    // buy mining
    function buyMiner()
        public
        payable
        whenNotPaused
        isNotBlackList(msg.sender)
    {
        require(isActive(msg.sender));
        if (address(uint160(address(FundsContract))).send(msg.value)) {
            require(FundsContract.buyMiner(msg.sender, msg.value));
            UserContract.setMiner(msg.sender);
            if (!NetContract.buyMiner(msg.sender, msg.value)) {
                revert("buy mining failed");
            }
        }
    }

    // deposit
    function deposit(address _tokenAddress, uint256 _tokens)
        public
        payable
        whenNotPaused
        isNotBlackList(msg.sender)
    {
        require(open_deposit == true);
        require(isActive(msg.sender));

        if (address(FundsContract) == _tokenAddress) {
            if (address(uint160(address(FundsContract))).send(msg.value)) {
                require(
                    FundsContract.deposit(_tokenAddress, msg.sender, msg.value)
                );
                if (
                    !NetContract.deposit(_tokenAddress, msg.sender, msg.value)
                ) {
                    revert("deposit failed");
                }
            }
        } else {
            require(FundsContract.deposit(_tokenAddress, msg.sender, _tokens));
            if (!NetContract.deposit(_tokenAddress, msg.sender, _tokens)) {
                revert("deposit failed");
            }
        }
    }

    // Tokens withdraw
    function withdraw(
        address _tokenAddress,
        address _who,
        uint256 _tokens
    )
        public
        whenNotPaused
        isNotBlackList(_who)
        onlySafe
        returns (bool success)
    {
        require(isActive(_who));
        return FundsContract.withdraw(_tokenAddress, _who, _tokens);
    }

    // loan
    function loan(
        address _tokenAddress,
        address _who,
        uint256 _tokens
    )
        public
        whenNotPaused
        isNotBlackList(_who)
        onlySafe
        returns (bool success)
    {
        require(open_loan == true);
        require(isActive(_who));
        return FundsContract.loan(_tokenAddress, _who, _tokens);
    }

    // repay
    function repay(address _tokenAddress, uint256 _tokens)
        public
        payable
        whenNotPaused
        isNotBlackList(msg.sender)
    {
        if (address(FundsContract) == _tokenAddress) {
            if (address(uint160(address(FundsContract))).send(msg.value)) {
                require(
                    FundsContract.repay(_tokenAddress, msg.sender, msg.value)
                );
                if (!NetContract.repay(_tokenAddress, msg.sender, msg.value)) {
                    revert("repay failed");
                }
            }
        } else {
            require(FundsContract.repay(_tokenAddress, msg.sender, _tokens));
            if (!NetContract.repay(_tokenAddress, msg.sender, _tokens)) {
                revert("repay failed");
            }
        }
    }

    // liquidate
    function liquidate(
        address _tokenAddress,
        address _owner,
        uint256 _tokens,
        uint256 _oid
    ) public payable whenNotPaused isNotBlackList(msg.sender) {
        require(isActive(_owner));
        require(isActive(msg.sender));
        if (address(FundsContract) == _tokenAddress) {
            if (address(uint160(address(FundsContract))).send(msg.value)) {
                require(
                    FundsContract.liquidate(
                        _tokenAddress,
                        msg.sender,
                        _owner,
                        msg.value
                    )
                );
                if (
                    !NetContract.liquidate(
                        _tokenAddress,
                        msg.sender,
                        msg.value,
                        _oid
                    )
                ) {
                    revert("liquidate failed");
                }
            }
        } else {
            require(
                FundsContract.liquidate(
                    _tokenAddress,
                    msg.sender,
                    _owner,
                    _tokens
                )
            );
            if (
                !NetContract.liquidate(_tokenAddress, msg.sender, _tokens, _oid)
            ) {
                revert("liquidate failed");
            }
        }
    }

    function setOpenDeposit(bool _status) public onlySafe {
        open_deposit = _status;
    }

    function setOpenLoan(bool _status) public onlySafe {
        open_loan = _status;
    }

    function getOpenDeposit() public view returns (bool deposit_status) {
        return open_deposit;
    }

    function getOpenLoan() public view returns (bool loan_status) {
        return open_loan;
    }

    // 获取存款余额
    function balanceOf(address _tokenAddress, address _who)
        public
        view
        returns (uint256 balance)
    {
        return ERC20Yes(_tokenAddress).balanceOf(_who);
    }

    function balanceEth(address _tokenAddress)
        public
        view
        returns (uint256 balance)
    {
        return address(uint160(address(_tokenAddress))).balance;
    }

    function isPaused() public view returns (bool paused) {
        return PauseContract.isPaused();
    }

    function getUser(address _who)
        public
        view
        returns (
            address id,
            address pid,
            bool miner,
            bool active,
            uint256 created_at
        )
    {
        return UserContract.getUser(_who);
    }

    function getActive(address _who) public view returns (uint256 amount) {
        return ReceiptContract.getActive(_who);
    }

    function getUpgrade(address _who) public view returns (uint256 amount) {
        return ReceiptContract.getUpgrade(_who);
    }

    function getMiner(address _who) public view returns (uint256 amount) {
        return ReceiptContract.getMiner(_who);
    }
}