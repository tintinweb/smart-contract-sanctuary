/**
 *Submitted for verification at Etherscan.io on 2021-05-06
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


interface IERC20 {
  function balanceOf(address tokenOwner)
    external
    view
    returns (uint256 balance);

  function transfer(address to, uint256 tokens) external returns (bool success);
}

interface IWallet {
    function move() external payable;
    function createForward() external;

    event Move(address from,uint256 value);
    event CreateForward(address forward);
}

interface IForward {
    function init(address) external;
    function invoke(address _target,uint256 _value,bytes calldata _param) external returns (bytes memory);
}

contract Forward is IForward {
    address public wallet;

    modifier OnlyWallet {
        require(msg.sender == wallet);
        _;
    }

    function init(address _wallet) external override {
        require(wallet == address(0));
        wallet = _wallet;
    }

    function invoke(address _target,uint256 _value,bytes calldata _param) external override OnlyWallet returns (bytes memory){
       (bool success,bytes memory result) =  _target.call{value: _value}(_param);
       require(success);
       return result;
    }

    event Deposit(address from, uint256 value);
    receive() external payable {
        if (msg.value>0) {
            emit Deposit(msg.sender, msg.value);
            IWallet(wallet).move{value: msg.value}();
        }
    }
}

contract Wallet is IWallet {
    address private impl = address(new Forward());
    
    address payable public owner = payable(msg.sender);

    constructor() {}

    modifier OnlyOwner {
        require(msg.sender == owner);
        _;
    }

    function clone(address implementation) internal returns (address instance) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    function createForward() external override OnlyOwner {
       address forward = clone(impl);
       IForward(forward).init(address(this));
       emit CreateForward(forward);
    }

    function flushERC20(address _forward,address _token) external OnlyOwner {
       uint256 balance = IERC20(_token).balanceOf(_forward);
       bytes memory param = abi.encodeWithSelector(0xa9059cbb, owner, balance);
       bytes memory result = IForward(_forward).invoke(_token,0,param);
       require((result.length == 0 || abi.decode(result, (bool))),"ERC20_TRANSFER_FAILED");
    }

    function move() external override payable {
        (bool success,) = owner.call{value: msg.value}(new bytes(0));
        require(success);
        emit Move(msg.sender, msg.value);
    }
}