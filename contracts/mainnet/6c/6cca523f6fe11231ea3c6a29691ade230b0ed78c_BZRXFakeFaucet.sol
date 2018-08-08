/*

  Copyright 2018 bZeroX, LLC

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

interface NonCompliantEIP20 {
    function transfer(address _to, uint _value) external;
    function transferFrom(address _from, address _to, uint _value) external;
    function approve(address _spender, uint _value) external;
}

/**
 * @title EIP20/ERC20 wrapper that will support noncompliant ERC20s
 * @dev see https://github.com/ethereum/EIPs/issues/20
 * @dev see https://medium.com/coinmonks/missing-return-value-bug-at-least-130-tokens-affected-d67bf08521ca
 */
contract EIP20Wrapper {

    function eip20Transfer(
        address token,
        address to,
        uint256 value)
        internal
        returns (bool result) {

        NonCompliantEIP20(token).transfer(to, value);

        assembly {
            switch returndatasize()   
            case 0 {                        // non compliant ERC20
                result := not(0)            // result is true
            }
            case 32 {                       // compliant ERC20
                returndatacopy(0, 0, 32) 
                result := mload(0)          // result == returndata of external call
            }
            default {                       // not an not an ERC20 token
                revert(0, 0) 
            }
        }

        require(result, "eip20Transfer failed");
    }

    function eip20TransferFrom(
        address token,
        address from,
        address to,
        uint256 value)
        internal
        returns (bool result) {

        NonCompliantEIP20(token).transferFrom(from, to, value);

        assembly {
            switch returndatasize()   
            case 0 {                        // non compliant ERC20
                result := not(0)            // result is true
            }
            case 32 {                       // compliant ERC20
                returndatacopy(0, 0, 32) 
                result := mload(0)          // result == returndata of external call
            }
            default {                       // not an not an ERC20 token
                revert(0, 0) 
            }
        }

        require(result, "eip20TransferFrom failed");
    }

    function eip20Approve(
        address token,
        address spender,
        uint256 value)
        internal
        returns (bool result) {

        NonCompliantEIP20(token).approve(spender, value);

        assembly {
            switch returndatasize()   
            case 0 {                        // non compliant ERC20
                result := not(0)            // result is true
            }
            case 32 {                       // compliant ERC20
                returndatacopy(0, 0, 32) 
                result := mload(0)          // result == returndata of external call
            }
            default {                       // not an not an ERC20 token
                revert(0, 0) 
            }
        }

        require(result, "eip20Approve failed");
    }
}

contract BZRXFakeFaucet is EIP20Wrapper, Ownable {

    uint public faucetThresholdSecs = 14400; // 4 hours

    mapping (address => mapping (address => uint)) public faucetUsers; // mapping of users to mapping of tokens to last request times

    function() public payable {}

    function faucet(
        address getToken,
        address receiver)
        public
        returns (bool)
    {
        require(block.timestamp-faucetUsers[receiver][getToken] >= faucetThresholdSecs 
            && block.timestamp-faucetUsers[msg.sender][getToken] >= faucetThresholdSecs, "BZRXFakeFaucet::faucet: token requested too recently");

        faucetUsers[receiver][getToken] = block.timestamp;
        faucetUsers[msg.sender][getToken] = block.timestamp;

        eip20Transfer(
            getToken,
            receiver,
            1 ether);

        return true;
    }

    function withdrawEther(
        address to,
        uint value)
        public
        onlyOwner
        returns (bool)
    {
        uint amount = value;
        if (amount > address(this).balance) {
            amount = address(this).balance;
        }

        return (to.send(amount)); // solhint-disable-line check-send-result, multiple-sends
    }

    function withdrawToken(
        address token,
        address to,
        uint tokenAmount)
        public
        onlyOwner
        returns (bool)
    {
        if (tokenAmount == 0) {
            return false;
        }
        
        eip20Transfer(
            token,
            to,
            tokenAmount);

        return true;
    }

    function depositToken(
        address token,
        address from,
        uint tokenAmount)
        public
        onlyOwner
        returns (bool)
    {
        if (tokenAmount == 0) {
            return false;
        }
        
        eip20TransferFrom(
            token,
            from,
            this,
            tokenAmount);

        return true;
    }

    function transferTokenFrom(
        address token,
        address from,
        address to,
        uint tokenAmount)
        public
        onlyOwner
        returns (bool)
    {
        if (tokenAmount == 0) {
            return false;
        }
        
        eip20TransferFrom(
            token,
            from,
            to,
            tokenAmount);

        return true;
    }

    function setFaucetThresholdSecs(
        uint newValue) 
        public
        onlyOwner
    {
        require(newValue != faucetThresholdSecs);
        faucetThresholdSecs = newValue;
    }
}