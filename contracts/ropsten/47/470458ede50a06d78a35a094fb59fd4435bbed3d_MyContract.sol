/**
 *Submitted for verification at Etherscan.io on 2021-09-20
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract MyContract {
    address public devaddr;
    address public feeAddress;
    uint8 public WisePerBlock;
    uint256 public startingblock;
    uint256 public lastblock;
    uint256 public lastMintBlock;
    address private _owner;
    uint256 private _totalSupply;
    
    mapping (address => uint256) private _balances;
    
    constructor() {
        devaddr = msg.sender;
        WisePerBlock = 2;
        startingblock = block.number;
        _owner = msg.sender;
    }
    
    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }
    
    
    function mint(address _to) external onlyOwner {
        _mint(_to);
    }
    
    function _mint(address account) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");
        _totalSupply += WisePerBlock;

        
    }
    
    
    
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }
    
    
    
    
}