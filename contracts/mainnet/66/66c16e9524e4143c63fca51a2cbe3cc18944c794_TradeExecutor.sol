pragma solidity 0.4.24;

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

pragma solidity 0.4.24;

contract Transfer {

    address constant public ETH = 0x0;

    /**
    * @dev Transfer tokens from this contract to an account.
    * @param token Address of token to transfer. 0x0 for ETH
    * @param to Address to send tokens to.
    * @param amount Amount of token to send.
    */
    function transfer(address token, address to, uint256 amount) internal returns (bool) {
        if (token == ETH) {
            to.transfer(amount);
        } else {
            require(ERC20(token).transfer(to, amount));
        }
        return true;
    }

    /**
    * @dev Transfer tokens from an account to this contract.
    * @param token Address of token to transfer. 0x0 for ETH
    * @param from Address to send tokens from.
    * @param to Address to send tokens to.
    * @param amount Amount of token to send.
    */
    function transferFrom(
        address token,
        address from,
        address to,
        uint256 amount
    ) 
        internal
        returns (bool)
    {
        require(token == ETH && msg.value == amount || msg.value == 0);

        if (token != ETH) {
            // Remember to approve first
            require(ERC20(token).transferFrom(from, to, amount));
        }
        return true;
    }

}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}


interface IERC20 {
    function balanceOf(address _owner) public view returns (uint balance);
    function transfer(address _to, uint _value) public returns (bool success);
}


contract Withdrawable is Ownable {
    function () public payable {}

    // Allow the owner to withdraw Ether
    function withdraw() public onlyOwner {
        owner.transfer(address(this).balance);
    }
    
    // Allow the owner to withdraw tokens
    function withdrawToken(address token) public onlyOwner returns (bool) {
        IERC20 foreignToken = IERC20(token);
        uint256 amount = foreignToken.balanceOf(address(this));
        return foreignToken.transfer(owner, amount);
    }
}

pragma solidity 0.4.24;

contract ExternalCall {
    // Source: https://github.com/gnosis/MultiSigWallet/blob/master/contracts/MultiSigWallet.sol
    // call has been separated into its own function in order to take advantage
    // of the Solidity&#39;s code generator to produce a loop that copies tx.data into memory.
    function external_call(address destination, uint value, uint dataLength, bytes data) internal returns (bool) {
        bool result;
        assembly {
            let x := mload(0x40)   // "Allocate" memory for output (0x40 is where "free memory" pointer is stored by convention)
            let d := add(data, 32) // First 32 bytes are the padded length of data, so exclude that
            result := call(
                sub(gas, 34710),   // 34710 is the value that solidity is currently emitting
                                   // It includes callGas (700) + callVeryLow (3, to pay for SUB) + callValueTransferGas (9000) +
                                   // callNewAccountGas (25000, in case the destination address does not exist and needs creating)
                destination,
                value,
                d,
                dataLength,        // Size of the input (in bytes) - this is what fixes the padding problem
                x,
                0                  // Output is ignored, therefore the output size is zero
            )
        }
        return result;
    }
}

/*

  Copyright 2018 Contra Labs Inc.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

  http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity 0.4.24;

// @title TradeExecutor: Atomically execute two trades using decentralized exchange wrapper contracts.
// @author Rich McAteer <rich@marble.org>, Max Wolff <max@marble.org>
contract TradeExecutor is Transfer, Withdrawable, ExternalCall {

    // Allow exchange wrappers to send Ether
    function () public payable {}

    /**
     * @dev Execute multiple trades in a single transaction.
     * @param wrappers Addresses of exchange wrappers.
     * @param token Address of ERC20 token to receive in first trade.
     * @param trade1 Calldata of Ether => ERC20 trade.
     * @param trade2 Calldata of ERC20 => Ether trade.
    */
    function trade(
        address[2] wrappers,
        address token,
        bytes trade1,
        bytes trade2
    )
        external
        payable
    {
        // Execute the first trade to get tokens
        require(execute(wrappers[0], msg.value, trade1));

        uint256 tokenBalance = IERC20(token).balanceOf(this);

        // Transfer tokens to the next exchange wrapper
        transfer(token, wrappers[1], tokenBalance);

        // Execute the second trade to get Ether
        require(execute(wrappers[1], 0, trade2));
        
        // Send the arbitrageur Ether
        msg.sender.transfer(address(this).balance);
    }

    function tradeForTokens(
        address[2] wrappers,
        address token,
        bytes trade1,
        bytes trade2
    )
        external
    {
        // Transfer tokens to the first exchange wrapper
        uint256 tokenBalance = IERC20(token).balanceOf(this);
        transfer(token, wrappers[0], tokenBalance);

        // Execute the first trade to get Ether
        require(execute(wrappers[0], 0, trade1));

        uint256 balance = address(this).balance;

        // Execute the second trade to get tokens
        require(execute(wrappers[1], balance, trade2));

        tokenBalance = IERC20(token).balanceOf(this);
        require(IERC20(token).transfer(msg.sender, tokenBalance));
    }

    function execute(address wrapper, uint256 value, bytes data) private returns (bool) {
        return external_call(wrapper, value, data.length, data);
    }

}