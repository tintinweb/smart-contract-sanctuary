// https://eips.ethereum.org/EIPS/eip-20
// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.8.0;

import "./library/Erc20.sol";
/**
 * Contract that will forward any incoming Ether to the creator of the contract
 */
contract Forwarder {
    // Address to which any funds sent to this contract will be forwarded
    address payable public destination;
    bool inititalised = false;

    event ForwarderDeposited(address from, uint value, bytes data);
    event TokensFlushed(address forwarderAddress, uint value, address tokenContractAddress);

    /**
     * Create the contract, and sets the destination address to that of the creator
     * set initialised true for the default forwarder on normal contract deployment
     */
    constructor() {
        destination = msg.sender;
        inititalised = true;
    }


    modifier onlyDestination {
        if (msg.sender != destination) {
            revert("Only destination");
        }
        _;
    }
    //if forwarder is deployed.. forward the payment straight away
    receive() external payable {
        destination.transfer(msg.value);
        emit ForwarderDeposited(msg.sender, msg.value, msg.data);
    }

    //init on create2
    function init(address payable newDestination) public {
        if (!inititalised) {
            destination = newDestination;
            inititalised = true;
        }
    }

    function changeDestination(address payable newDestination) public onlyDestination {
        destination = newDestination;
    }

    //flush the tokens
    function flushTokens(address tokenContractAddress) public {
        IERC20 instance = IERC20(tokenContractAddress);
        uint256 forwarderBalance = instance.balanceOf(address(this));
        if (forwarderBalance == 0) {
            revert();
        }
        if (!instance.transfer(destination, forwarderBalance)) {
            revert();
        }
        emit TokensFlushed(address(this), forwarderBalance, tokenContractAddress);
    }

    function flush() payable public {
        address payable thisContract = address(this);
        destination.transfer(thisContract.balance);
    }

    //simple withdraw instead of flush
    function withdraw() payable external onlyDestination {
        address payable thisContract = address(this);
        msg.sender.transfer(thisContract.balance);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.8.0;

import "./Forwarder.sol";

contract ForwarderFactory {

    event ForwarderCloned(address clonedAdress);

    function cloneForwarder(address payable forwarder, uint256 salt)
    public returns (Forwarder clonedForwarder) {
        address payable clonedAddress = createClone(forwarder, salt);
        Forwarder parentForwarder = Forwarder(forwarder);
        clonedForwarder = Forwarder(clonedAddress);
        clonedForwarder.init(parentForwarder.destination());
        emit ForwarderCloned(clonedAddress);
    }

    function createClone(address target, uint256 salt) private returns (address payable result) {
        bytes20 targetBytes = bytes20(target);
        assembly {
            let clone := mload(0x40)
            mstore(clone, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(clone, 0x14), targetBytes)
            mstore(add(clone, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            result := create2(0, clone, 0x37, salt)
        }
    }

    function flushTokens(address payable[]  memory forwarders, address tokenAddres) public {
        for (uint index = 0; index < forwarders.length; index++) {
            Forwarder forwarder = Forwarder(forwarders[index]);
            forwarder.flushTokens(tokenAddres);
        }
    }

    function flushEther(address payable[]  memory forwarders) public {
        for (uint index = 0; index < forwarders.length; index++) {
            Forwarder forwarder = Forwarder(forwarders[index]);
            forwarder.flush();
        }
    }

}

// https://eips.ethereum.org/EIPS/eip-20
// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 <0.8.0;

interface IERC20 {

    /// @param _owner The address from which the balance will be retrieved
    /// @return balance the balance
    function balanceOf(address _owner) external view returns (uint256 balance);

    /// @notice send `_value` token to `_to` from `msg.sender`
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return success Whether the transfer was successful or not
    function transfer(address _to, uint256 _value)  external returns (bool success);

    /// @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
    /// @param _from The address of the sender
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return success Whether the transfer was successful or not
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);

    /// @notice `msg.sender` approves `_addr` to spend `_value` tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @param _value The amount of wei to be approved for transfer
    /// @return success Whether the approval was successful or not
    function approve(address _spender  , uint256 _value) external returns (bool success);

    /// @param _owner The address of the account owning tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @return remaining Amount of remaining tokens allowed to spent
    function allowance(address _owner, address _spender) external view returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract ERC20Token is IERC20 {
    uint256 constant private MAX_UINT256 = 2**256 - 1;
    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) public allowed;
    uint256 public totalSupply;
    /*
    NOTE:
    The following variables are OPTIONAL vanities. One does not have to include them.
    They allow one to customise the token contract & in no way influences the core functionality.
    Some wallets/interfaces might not even bother to look at this information.
    */
    string public name;                   //fancy name: eg Simon Bucks
    uint8 public decimals;                //How many decimals to show.
    string public symbol;                 //An identifier: eg SBX

    constructor(uint256 _initialAmount, string memory _tokenName, uint8 _decimalUnits, string  memory _tokenSymbol) {
        balances[msg.sender] = _initialAmount;               // Give the creator all initial tokens
        totalSupply = _initialAmount;                        // Update total supply
        name = _tokenName;                                   // Set the name for display purposes
        decimals = _decimalUnits;                            // Amount of decimals for display purposes
        symbol = _tokenSymbol;                               // Set the symbol for display purposes
    }

    function transfer(address _to, uint256 _value) public override returns (bool success) {
        require(balances[msg.sender] >= _value, "token balance is lower than the value requested");
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value); //solhint-disable-line indent, no-unused-vars
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public override returns (bool success) {
        uint256 allowance = allowed[_from][msg.sender];
        require(balances[_from] >= _value && allowance >= _value, "token balance or allowance is lower than amount requested");
        balances[_to] += _value;
        balances[_from] -= _value;
        if (allowance < MAX_UINT256) {
            allowed[_from][msg.sender] -= _value;
        }
        emit Transfer(_from, _to, _value); //solhint-disable-line indent, no-unused-vars
        return true;
    }

    function balanceOf(address _owner) public override view returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) public override returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value); //solhint-disable-line indent, no-unused-vars
        return true;
    }

    function allowance(address _owner, address _spender) public override view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
}

{
  "remappings": [],
  "optimizer": {
    "enabled": true,
    "runs": 1
  },
  "evmVersion": "petersburg",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}