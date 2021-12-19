/**
 *Submitted for verification at Etherscan.io on 2021-12-18
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.7;

contract MyTokenContract{

    address owner_address;
    
    string constant name = "REN";
    string constant symbol = "R";
    uint8 constant decimals = 5;
    uint totalSupply = 0;
    

    mapping(address => uint) balances;
    mapping (address => mapping (address => uint)) allowed;


    constructor(){
        owner_address = msg.sender;
    }

    modifier onlyOwner(address _adr){
        require(_adr == owner_address);
        _;
    }

    event Transfer(address _from, address _to, uint _value);		
	event Approval(address _from, address _spender, uint _value);

    function mint(address taker, uint256 _value) public onlyOwner(msg.sender){
        totalSupply += _value;
        balances[taker] += _value;
    }


    function balanceOf(address _owner) public view returns (uint balance) {
		return balances[_owner];
	}

    function balanceOf() public view returns (uint balance) {
		return balances[msg.sender];
	}

    function transfer(address _to, uint _value) public {
	    require(balances[msg.sender] >= _value && _value > 0);
            balances[msg.sender] -= _value;            
            balances[_to] += _value; 

            emit Transfer(msg.sender, _to, _value);
    }

    function transferFrom(address _from, address _to, uint _value) public {
	    require(balances[_from] >= _value && _value > 0 && allowed[_from][msg.sender] >= _value);
            balances[_from] -= _value;
            balances[_to] += _value;

            emit Approval(_from, msg.sender, allowed[_from][msg.sender] - _value);

            allowed[_from][msg.sender] -= _value;

            emit Transfer(_from, _to, _value);
    }
    
    function approve(address _spender, uint _value) public {
		allowed[msg.sender][_spender] = _value;

        emit Approval(msg.sender, _spender, _value);
	}

    function allowance(address _from, address _spender) public view returns (uint balance) {
		return allowed[_from][_spender];
	}

}