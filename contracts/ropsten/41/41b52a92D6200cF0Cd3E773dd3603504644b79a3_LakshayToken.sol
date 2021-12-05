/**
 *Submitted for verification at Etherscan.io on 2021-12-05
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

contract LakshayToken{

    string tokenName = "LakshayToken";
    string tokenSymbol = "LAT";
    mapping(address => uint) balances;
    address deployer;
    uint totalTokenSupply = 10000000 * 1e8;
    uint coinsLefttoBeMinted = totalTokenSupply;

    constructor(){
        deployer = msg.sender;
        balances[deployer] = 1000000 * 1e8;
        coinsLefttoBeMinted -= 1000000 * 1e8;
    }

    function name() public view returns (string memory){
        return tokenName;
    }

    function symbol() public view returns (string memory){
        return tokenSymbol;
    }


    function decimals() public view returns (uint8){
        return 8;
    }


    function totalSupply() public view returns (uint256){
        return totalTokenSupply; //10M
    }


    function balanceOf(address _owner) public view returns (uint256 balance){
        return balances[_owner];
    }

    mapping(uint => bool) blockMined;

    function mine() public returns(bool){
        if(coinsLefttoBeMinted < 10 * 1e8){
            return false;
        }
        if (block.number % 10 !=0){
            return false;
        }
        if (blockMined[block.number]){
            return false;
        }

        balances[msg.sender] += 10 * 1e8;
        blockMined[block.number] = true;
        coinsLefttoBeMinted -= 10 * 1e8;
        return true;
    }

    function transfer(address _to, uint256 _value) public returns (bool success){
        address fromAddress = msg.sender;
        require(balances[fromAddress] >= _value, "Insufficient balance");
        balances[fromAddress] -= _value;
        balances[_to] += _value;
        emit Transfer(fromAddress, _to, _value);
        return true;
    }

    mapping(address => mapping(address => uint)) allowances;

        
    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowances[msg.sender][_spender] += _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success){
        require(balances[_from] >= _value, "Insufficient balance");
        require(allowances[_from][msg.sender] >= _value, "This third party is not allowed to withdraw these much funds");
        allowances[_from][msg.sender] -= _value;
        balances[_from] -= _value;
        balances[_to] += _value;
        emit Transfer(_from, _to, _value);
        return true;
    }


    function allowance(address _owner, address _spender) public view returns (uint256 remaining){
        return allowances[_owner][_spender];
    }

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}