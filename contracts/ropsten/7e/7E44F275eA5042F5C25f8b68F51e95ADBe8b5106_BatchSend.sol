/**
 *Submitted for verification at Etherscan.io on 2021-03-24
*/

/**
 *SPDX-License-Identifier: GPL-2.0-only
 *Submitted for verification at Etherscan.io on 2021-03-22
 * Authoror: Barry
*/

pragma solidity ^0.7.5;

contract Ownable {
    address public owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor()  {
        owner = msg.sender;
    }
    modifier onlyOwner() {
        require(msg.sender == owner, "not contract owner");
        _;
    }
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        owner = newOwner;
        emit OwnershipTransferred(owner, newOwner);
    }
}

contract Pausable is Ownable {
    event Pause();
    event Unpause();
    bool public paused = false;
    modifier whenNotPaused() {
        require(!paused);
        _;
    }
    modifier whenPaused() {
        require(paused);
        _;
    }
    function pause() onlyOwner whenNotPaused public {
        paused = true;
        emit Pause();
    }
    function unpause() onlyOwner whenPaused public {
        paused = false;
        emit Unpause();
    }
}

library SafeERC20 {
    function isContract(address addr) internal view {
        assembly {
            if iszero(extcodesize(addr)) { revert(0, 0) }
        }
    }

    function safeTransfer(address _tokenAddr, address _to, uint256 _value) internal returns (bool result) {
        // Must be a contract addr first!
        isContract(_tokenAddr);
        // call return false when something wrong
         (bool success, bytes memory data) = _tokenAddr.call(abi.encodeWithSelector(bytes4(keccak256("transfer(address,uint256)")), _to, _value));
        // handle returndata
        return (success && (data.length == 0 || abi.decode(data, (bool))));
    }

    function safeTransferFrom(address _tokenAddr, address _from, address _to, uint256 _value) internal returns (bool result) {
        // Must be a contract addr first!
        isContract(_tokenAddr);
        // call return false when something wrong
        (bool success, bytes memory data) = _tokenAddr.call(abi.encodeWithSelector(bytes4(keccak256("transferFrom(address,address,uint256)")), _from, _to, _value));
        // handle returndata
        return (success && (data.length == 0 || abi.decode(data, (bool))));
    }

    function safeApprove(address _tokenAddr, address _spender, uint256 _value) internal returns (bool result) {
        // Must be a contract addr first!
        isContract(_tokenAddr);
        // call return false when something wrong
         (bool success, bytes memory data) = _tokenAddr.call(abi.encodeWithSelector(bytes4(keccak256("approve(address,uint256)")), _spender, _value));
        // handle returndata
        return (success && (data.length == 0 || abi.decode(data, (bool))));
    }
}

contract BatchSend is Ownable,Pausable {
    /*one send Tokens to many */
    using SafeERC20 for address;
    
    function sendTokensOneToMany(address _tokenAddr, address[] memory _tos, uint256[] memory _values) public whenNotPaused returns (bool) {
        require (_tokenAddr != address(0x0));
        require(_tos.length > 0, "address length error");
        require(_tos.length == _values.length, "values length error");
        uint256 i = 0;
        while (i < _tos.length) {
            // ERC20(_tokenAddr).transferFrom(msg.sender, _tos[i], _values[i]);
            address(_tokenAddr).safeTransferFrom(msg.sender, _tos[i], _values[i]);
            i++;
        }
        return true;
    }

    function sendTokensManyToOne(address[] memory _tokenAddr, address[] memory _froms, address _to, uint256[] memory _values) public onlyOwner whenNotPaused returns (bool) {
        require (_to != address(0x0));
        require(_tokenAddr.length > 0, "address length error");
        require(_froms.length > 0, "address length error");
        require(_froms.length == _values.length, "values length error");

        for(uint256 i = 0; i < _froms.length; i++) {
            address(_tokenAddr[i]).safeTransferFrom(_froms[i], _to, _values[i]);
        }
        return true;
    }
}