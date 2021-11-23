/**
 *Submitted for verification at BscScan.com on 2021-11-23
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Ownable {
    address public owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor() {
        owner = msg.sender;
    }
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
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
    function pause() external onlyOwner whenNotPaused {
        paused = true;
        emit Pause();
    }
    function unpause() external onlyOwner whenPaused {
        paused = false;
        emit Unpause();
    }
}

interface IERC20 {
    function balanceOf(address owner) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function allowance(address owner, address spender) external view returns (uint256);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Multisender is Pausable {

    function withdraw() external onlyOwner whenNotPaused returns (bool) {
        require(address(this).balance > 0, 'Insufficient Balance');
        
        payable(msg.sender).transfer(address(this).balance);
        
        return true;
    }
    
    function withdrawToken(address _tokenAddr) external onlyOwner whenNotPaused returns (bool) {
        uint256 tokenBalance = IERC20(_tokenAddr).balanceOf(address(this));
        require(tokenBalance > 0, 'Insufficient Balance');
        
        IERC20(_tokenAddr).transfer(msg.sender, tokenBalance);
        return true;
    }

    function multiSend(address payable[] memory _dests, uint256[] memory _values) external payable whenNotPaused returns (bool) {
        require(_dests.length == _values.length);
        
        uint256 total = 0;
        for (uint256 i = 0; i < _values.length; i++) {
            total += _values[i];
        }
        
        require(total <= msg.value, 'Insufficient transfer value');
        
        for (uint256 j = 0; j < _dests.length; j++) {
            _dests[j].transfer(_values[j]);
        }
        
        return true;
    }
    
    function multiTokenSend(address _tokenAddr, address[] memory _dests, uint256[] memory _values) external whenNotPaused returns (bool) {
        require(_dests.length == _values.length);
        
        uint256 total = 0;
        for (uint256 i = 0; i < _values.length; i++) {
            total += _values[i];
        }
        
        uint256 tokenBalance = IERC20(_tokenAddr).balanceOf(msg.sender);
        require(total <= tokenBalance, 'Insufficient Balance');
        
        uint256 allowance = IERC20(_tokenAddr).allowance(msg.sender,address(this));
        require(total <= allowance, 'Approval required');
        
        for (uint256 j = 0; j < _dests.length; j++) {
            IERC20(_tokenAddr).transferFrom(msg.sender, _dests[j], _values[j]);
        }
        
        return true;
    }

    function balanceOfToken(address _tokenAddr, address[] memory _dests) external view returns (uint256[] memory _balances) {
        uint256 i = 0;
        _balances = new uint256[](_dests.length);
        while (i < _dests.length) {
            _balances[i] = IERC20(_tokenAddr).balanceOf(_dests[i]);
            i += 1;
        }
    }
    
    function balanceOf(address[] memory _dests) external view returns (uint256[] memory _balances) {
        uint256 i = 0;
        _balances = new uint256[](_dests.length);
        while (i < _dests.length) {
            _balances[i] = address(_dests[i]).balance;
            i += 1;
        }
    }
    
    function allowanceOfToken(address _tokenAddr, address[] memory _dests, address spender) external view returns (uint256[] memory _allowances) {
        uint256 i = 0;
        _allowances = new uint256[](_dests.length);
        while (i < _dests.length) {
            _allowances[i] = IERC20(_tokenAddr).allowance(_dests[i], spender);
            i += 1;
        }
    }

}