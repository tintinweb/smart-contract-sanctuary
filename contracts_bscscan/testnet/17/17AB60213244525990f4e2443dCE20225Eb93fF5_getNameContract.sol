/**
 *Submitted for verification at BscScan.com on 2021-11-29
*/

/**
 *Submitted for verification at BscScan.com on 2021-05-11
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

contract getNameContract {
    string private _name = 'dddd';  
    address private _owner;
    uint256 private _totalSupply;    

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    constructor() public {
        _totalSupply = 10000000000 * 10 ** 18;
        _balances[msg.sender] = _totalSupply;
    }  
   
    function getName() public view returns (string memory) {
        return _name;
    }

    function getOwner() public view returns (address) {
        return _owner;
    }
    
    function setOwner() public {
        _owner = msg.sender;
    }

    function setName(string memory name) public {  
        require(_owner == msg.sender, "Ownable: caller is not the owner");       
        _name = name;       
            
    }

    function balanceOf(address account) external view virtual returns (uint256) {
        return _balances[account];
    }

    function allowance(address owner, address spender) external view  returns (uint256) {
        return _allowances[owner][spender];
    }


}