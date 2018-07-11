pragma solidity ^0.4.23;

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender)
    public view returns (uint256);

  function transferFrom(address from, address to, uint256 value)
    public returns (bool);

  function approve(address spender, uint256 value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
  function safeTransfer(ERC20Basic token, address to, uint256 value) internal {
    require(token.transfer(to, value));
  }

  function safeTransferFrom(
    ERC20 token,
    address from,
    address to,
    uint256 value
  )
    internal
  {
    require(token.transferFrom(from, to, value));
  }

  function safeApprove(ERC20 token, address spender, uint256 value) internal {
    require(token.approve(spender, value));
  }
}

contract ARPHoldingWallet {
    using SafeERC20 for ERC20;

    // Middle term holding
    uint256 constant MID_TERM   = 1 finney; // = 0.001 ether
    // Long term holding
    uint256 constant LONG_TERM  = 2 finney; // = 0.002 ether

    uint256 constant GAS_LIMIT  = 200000;

    address owner;

    // ERC20 basic token contract being held
    ERC20 arpToken;
    address midTermHolding;
    address longTermHolding;

    /// Initialize the contract
    constructor(address _owner, ERC20 _arpToken, address _midTermHolding, address _longTermHolding) public {
        owner = _owner;
        arpToken = _arpToken;
        midTermHolding = _midTermHolding;
        longTermHolding = _longTermHolding;
    }

    /*
     * PUBLIC FUNCTIONS
     */

    function() payable public {
        require(msg.sender == owner);

        if (msg.value == MID_TERM) {
            depositOrWithdraw(midTermHolding);
        } else if (msg.value == LONG_TERM) {
            depositOrWithdraw(longTermHolding);
        } else if (msg.value == 0) {
            drain();
        } else {
            revert();
        }
    }

    function depositOrWithdraw(address _holding) private {
        uint256 amount = arpToken.balanceOf(address(this));
        if (amount > 0) {
            arpToken.safeApprove(_holding, amount);
        }
        require(_holding.call.gas(GAS_LIMIT)());
        amount = arpToken.balanceOf(address(this));
        if (amount > 0) {
            arpToken.safeTransfer(msg.sender, amount);
        }
        msg.sender.transfer(msg.value);
    }

    /// Drains ARP.
    function drain() private {
        uint256 amount = arpToken.balanceOf(address(this));
        require(amount > 0);

        arpToken.safeTransfer(owner, amount);
    }
}

contract ARPHoldingWalletCreator {
    /* 
     * EVENTS
     */
    event Created(address indexed _owner, address _wallet);

    mapping (address => address) public wallets;
    ERC20 public arpToken;
    address public midTermHolding;
    address public longTermHolding;

    constructor(ERC20 _arpToken, address _midTermHolding, address _longTermHolding) public {
        arpToken = _arpToken;
        midTermHolding = _midTermHolding;
        longTermHolding = _longTermHolding;
    }

    function() public {
        require(wallets[msg.sender] == address(0x0));

        address wallet = new ARPHoldingWallet(msg.sender, arpToken, midTermHolding, longTermHolding);
        wallets[msg.sender] = wallet;

        emit Created(msg.sender, wallet);
    }
}