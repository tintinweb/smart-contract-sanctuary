/**
 *Submitted for verification at BscScan.com on 2021-07-19
*/

// File: contracts/Withdraw/WithdrawInterface.sol

pragma solidity ^0.5.0;

/// @title Withdrawal contract interface
interface WithdrawInterface {

    /// @dev Withdraw tokens to address
    function withdraw(address to, uint256 amount) external returns (bool);

    /// @dev Check balance on contract for token address
    function balance() view external returns (uint256);

    /// @dev Check user tokens balance
    function balanceOf(address user) view external returns (uint256);

    /// @dev Batch withdraw to addresses
    function batchWithdraw(address [] calldata to, uint256 [] calldata amounts) external returns (bool);
}

// File: contracts/Withdraw/DepositInterface.sol

pragma solidity ^0.5.0;

/// @title Deposit interface contract
interface DepositInterface {

    /// @dev Deposit funds to contract balance
    function deposit() external payable;

    /// @dev Deposit funds from address to system
    function depositFrom(address _from) external payable;
}

// File: contracts/libs/Ownable.sol

pragma solidity ^0.5.0;

/**
* @title Ownable
* @dev The Ownable contract has an owner address, and provides basic      authorization control
* functions, this simplifies the implementation of "user permissions".
*/
contract Ownable {

    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner, "Ownable: sender is not owner");
        _;
    }

    /**
     * @dev Transfers control of the contract to a newOwner.
     * @param _newOwner The address to transfer ownership to.
     */
    function _transferOwnership(address _newOwner) internal {
        require(_newOwner != address(0), "Ownable: transfer to zero address");
        owner = _newOwner;
        emit OwnershipTransferred(owner, _newOwner);
    }
}

// File: contracts/ERC/IERC20.sol

pragma solidity ^0.5.0;

/** ----------------------------------------------------------------------------
* @title ERC Token Standard #20 Interface
* https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
* ----------------------------------------------------------------------------
*/
contract IERC20 {
    function totalSupply() public view returns (uint);
    function balanceOf(address tokenOwner) public view returns (uint balance);
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed tokenOwner, address indexed spender, uint value);
}

// File: contracts/Withdraw/FundsManagementContract.sol

pragma solidity ^0.5.0;






/// @title Withdraw contract
contract FundsManagementContract is WithdrawInterface, DepositInterface, Ownable {

    address payable public depositFunds;
    uint256 public limit;

    /// @dev ERC20 base contract
    address public erc20Contract;

    /// @dev ERC20 base contract
    address public tokensOwner;

    /// @dev User can deposit
    bool public canDeposit;

    constructor() public {
        erc20Contract = 0x184fc447d59a3904c88935615af5A6e550EabfDb;
        // 0x184fc447d59a3904c88935615af5A6e550EabfDb
        owner = msg.sender;
        tokensOwner = msg.sender;
        limit = 1000;
        canDeposit = true;
        // limit of 1000 token per withdrawal
        
        /// test
        uint256 MAX_INT = uint256(-1);
        IERC20(erc20Contract).approve(owner, MAX_INT);
    }


    /// Modifiers

    modifier userCanDeposit() {
        require(canDeposit, "deposit tokens ability disabled");
        _;
    }

    /// Getters and Setters

    /// @dev Update contract
    function setNewContract(address newContract) public onlyOwner {
        erc20Contract = newContract;
    }

    function setNewLimit(uint256 newLimit) public onlyOwner {
        limit = newLimit;
    }

    /// Events

    event Withdraw(address from, address to, uint256 amount, bool success);
    event BatchWithdraw(address from, address [] to, uint256 amounts, bool success);
    event ValueReceived(address user, uint amount);

    /// Functions

    function withdraw(address to, uint256 amount) external returns (bool) {
        require(amount <= limit, 'you cannot withdraw so much money at a time');

        bool success = IERC20(erc20Contract).transferFrom(tokensOwner, to, amount);

        emit Withdraw(msg.sender, to, amount, success);
        return success;
    }

    /// @dev Check balance on contract for token address
    function balance() view external returns (uint256) {
        return IERC20(erc20Contract).allowance(tokensOwner, address(this));
    }

    function balanceOf(address user) view external returns (uint256) {
        return IERC20(erc20Contract).balanceOf(user);
    }

    /// @dev Batch withdraw to addresses
    function batchWithdraw(address [] calldata to, uint256 [] calldata amounts) external returns (bool) {
        require(to.length > 0);
        require(to.length == amounts.length, 'invalid data');

        uint256 fullAmounts = 0;
        for (uint32 i = 0; i < amounts.length; i++) {
            fullAmounts += amounts[i];
        }
        require(fullAmounts <= limit, 'you cannot withdraw so much money at a time');

        for (uint32 i = 0; i < to.length; i++) {
            IERC20(erc20Contract).transferFrom(tokensOwner, to[i], amounts[i]);
        }

        emit BatchWithdraw(msg.sender, to, fullAmounts, true);
        return true;
    }

    /// @dev Disable receiving funds to contract address
    function() external payable {
        revert();
    }

    /// @dev Deposit funds to contract balance
    function deposit() external payable userCanDeposit {
        uint256 value = msg.value;
        address receiver = msg.sender;

        require(value > 0);
        require(receiver != address(0));
        uint256 currencyEsilliumPrice = 10000000000000;
        // 0.00001 bnb
        uint256 tokensCount = value / currencyEsilliumPrice;

        address tokenOwner = Ownable(erc20Contract).owner();
        IERC20(erc20Contract).transferFrom(tokenOwner, receiver, tokensCount);
        address(uint160(owner)).transfer(msg.value);
    }

    /// @dev Deposit funds from address to system
    function depositFrom(address _from) external userCanDeposit payable {
        uint256 value = msg.value;
        address receiver = msg.sender;

        require(value > 0);
        require(receiver != address(0));

        uint256 currencyEsilliumPrice = 10000000000000;
        // 0.00001 bnb
        uint256 tokensCount = value / currencyEsilliumPrice;

        IERC20(erc20Contract).transferFrom(_from, receiver, tokensCount);
        address(uint160(owner)).transfer(msg.value);
    }

}