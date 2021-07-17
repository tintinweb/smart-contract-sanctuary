/**
 *Submitted for verification at Etherscan.io on 2021-07-17
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface iERC20 {

	function balanceOf(address who) external view returns (uint256 balance);

	function allowance(address owner, address spender) external view returns (uint256 remaining);

	function transfer(address to, uint256 value) external returns (bool success);

	function approve(address spender, uint256 value) external returns (bool success);

	function transferFrom(address from, address to, uint256 value) external returns (bool success);

	event Transfer(address indexed _from, address indexed _to, uint256 _value);

	event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract Context {
	function _msgSender() internal view returns (address) {
		return msg.sender;
	}

	function _msgData() internal view returns (bytes memory) {
		this;
		return msg.data;
	}
}

library SafeMath {
	function sub(uint256 a, uint256 b) internal pure returns (uint256 c) {
		c = a - b;
		assert(b <= a && c <= a);
		return c;
	}

	function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
		c = a + b;
		assert(c >= a && c>=b);
		return c;
	}
}

library SafeERC20 {
	function safeTransfer(iERC20 _token, address _to, uint256 _value) internal {
		require(_token.transfer(_to, _value));
	}
	function safeTransferFrom(iERC20 _token, address _from, address _to, uint256 _value) internal {
		require(_token.transferFrom(_from, _to, _value));
	}
}

contract Controllable is Context {
    mapping (address => bool) public controllers;

	constructor () {
		address msgSender = _msgSender();
		controllers[msgSender] = true;
	}

	modifier onlyController() {
		require(controllers[_msgSender()], "Controllable: caller is not a controller");
		_;
	}

    function addController(address _address) public onlyController {
        controllers[_address] = true;
    }

    function removeController(address _address) public onlyController {
        delete controllers[_address];
    }
}

contract Pausable is Controllable {
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

	function pause() public onlyController whenNotPaused {
		paused = true;
		emit Pause();
	}

	function unpause() public onlyController whenPaused {
		paused = false;
		emit Unpause();
	}
}

contract MNW_tokenswap is Controllable, Pausable {
	using SafeMath for uint256;
	using SafeERC20 for iERC20;

	mapping (address => bool) public blocklist;

    iERC20 public tokenOld; // MRPH Rinkeby 0xd06f350F50AC1a3414762a617E1130ca1f079C77 Ethereum 0x7B0C06043468469967DBA22d1AF33d77d44056c8
    iERC20 public tokenNew; // MNW Rinkeby 0x88d4067802186DD70704a85866974997F4DeD734 Ethereum 0xd3E4Ba569045546D09CF021ECC5dFe42b1d7f6E4
    address public tokenPool; // 0x8BbF984Be7fc6db1602E056AA4256D7FB1954BF4
    uint256 public blocked;

	constructor(iERC20 _tokenOld, iERC20 _tokenNew, address _tokenPool) {
        tokenOld = _tokenOld;
        tokenNew = _tokenNew;
        tokenPool = _tokenPool;
    	controllers[msg.sender] = true;
    	blocklist[0xCCE8D59AFFdd93be338FC77FA0A298C2CB65Da59] = true;
        blocklist[0x3c11c3025ce387D76C2eDDf1493eC55a8cC2A0f7] = true;
        blocklist[0x7B0C06043468469967DBA22d1AF33d77d44056c8] = true;
        blocklist[0x8533A0bd9310Eb63E7CC8E1116c18a3D67B1976A] = true;
	}
	
	function switchPool(address _tokenPool) public onlyController {
	    tokenPool = _tokenPool;
	}

	function receiveEther() public payable {
		revert();
	}

    function swap() public {
        uint256 _amount = tokenOld.balanceOf(msg.sender);
        require(_amount > 0,"No balance of MRPH tokens");
        _swap(_amount);
    }

    function _swap(uint256 _amount) internal {
        tokenOld.safeTransferFrom(address(msg.sender), tokenPool, _amount);
        if (blocklist[msg.sender]) {
            blocked.add(_amount);
        } else {
            tokenNew.safeTransferFrom(tokenPool, address(msg.sender), _amount * (10 ** 14));
        }
        emit swapped(_amount / (10 ** 4));
    }
    
    function blockAddress(address _address, bool _state) external onlyController returns (bool) {
		blocklist[_address] = _state;
		return true;
	}

	function transferToken(address tokenAddress, uint256 amount) external onlyController {
		iERC20(tokenAddress).safeTransfer(msg.sender,amount);
	}

	function flushToken(address tokenAddress) external onlyController {
		uint256 amount = iERC20(tokenAddress).balanceOf(address(this));
		iERC20(tokenAddress).safeTransfer(msg.sender,amount);
	}

    event swapped(uint256 indexed amount);
}