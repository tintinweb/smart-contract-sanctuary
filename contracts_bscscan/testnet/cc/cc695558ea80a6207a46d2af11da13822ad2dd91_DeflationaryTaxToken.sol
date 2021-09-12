/**
 *Submitted for verification at BscScan.com on 2021-09-11
*/

/*
Developed By - @Krypto_Adrian
------------------------------------

Join Telegram - https://t.me/bigdollardoge
*/

//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;

contract DeflationaryTaxToken {
    mapping(address => uint) private balances;
    mapping(address => mapping(address => uint)) private allowed;
    uint public totalSupply;
    string public name;
    string public symbol;
    uint public decimals;
    uint public tax1;
    uint public tax2;
    address public addressTax1;
    address public addressTax2;
    uint public deflation;
    uint public minSupply;
    uint public initialSupply;
    uint public totalTax1;
    uint public totalTax2;
    uint public burnt;
    
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
    
    constructor(string memory _name, string memory _symbol, uint _dec, uint _supply, uint _tax1, address _address1, uint _tax2, address _address2, uint _deflation, uint _minSupply, address _owner) {
        name = _name;
        symbol = _symbol;
        decimals = _dec;
        totalSupply = _supply * 10 ** decimals;
        initialSupply = _supply * 10 ** decimals;
        tax1 = _tax1;
        tax2 = _tax2;
        addressTax1 = _address1;
        addressTax2 = _address2;
        deflation = _deflation;
        minSupply = _minSupply * 10 ** decimals;
        totalTax1 = 0;
        totalTax2 = 0;
        burnt = 0;
        balances[_owner] = totalSupply;
        emit Transfer(address(0), _owner, totalSupply);
    }
    
    function balanceOf(address owner) public view returns(uint) {
        return balances[owner];
    }
    
    function transfer(address to, uint value) public returns(bool) {
        require(balances[msg.sender] >= value, 'balance too low');
        
        balances[msg.sender] -= value;
        
        uint deduct = 0;
        
        if (tax1 > 0) {
            uint tax1Amount = value * tax1 / 1000;
            
            if (tax1Amount > 0) {
                
                deduct = deduct + tax1Amount;
                totalTax1 += tax1Amount;
                balances[addressTax1] += tax1Amount;
                emit Transfer(msg.sender, addressTax1, tax1Amount);
            }
        }
        
        if (tax2 > 0) {
            uint tax2Amount = value * tax2 / 1000;
            
            if (tax2Amount > 0) {
                
                deduct = deduct + tax2Amount;
                totalTax2 += tax2Amount;
                balances[addressTax2] += tax2Amount;
                emit Transfer(msg.sender, addressTax2, tax2Amount);
            }
        }
        
        if (deflation > 0 && totalSupply > minSupply) {
            uint defAmount = value * deflation / 1000;
            
            if (defAmount > 0) {
                
                if (totalSupply - defAmount < minSupply) {
                    defAmount = totalSupply - minSupply;
                }
                deduct = deduct + defAmount;
                totalSupply -= defAmount;
                burnt += defAmount;
                emit Transfer(msg.sender, address(0), defAmount);
            }
        }
        
        value = value - deduct;
        
        balances[to] += value;
        emit Transfer(msg.sender, to, value);
        return true;
    }
    
    function transferFrom(address from, address to, uint value) public returns(bool) {
        require(balances[from] >= value, 'balance too low');
        require(allowed[from][msg.sender] >= value, 'allowance too low');
        
        balances[from] -= value;
        allowed[from][msg.sender] -=value;
        
        uint deduct = 0;
        
        if (tax1 > 0) {
            uint tax1Amount = value * tax1 / 1000;
            
            if (tax1Amount > 0) {
                
                deduct = deduct + tax1Amount;
                totalTax1 += tax1Amount;
                balances[addressTax1] += tax1Amount;
                emit Transfer(from, addressTax1, tax1Amount);
            }
        }
        
        if (tax2 > 0) {
            uint tax2Amount = value * tax2 / 1000;
            
            if (tax2Amount > 0) {
                
                deduct = deduct + tax2Amount;
                totalTax2 += tax2Amount;
                balances[addressTax2] += tax2Amount;
                emit Transfer(from, addressTax2, tax2Amount);
            }
        }
        
        if (deflation > 0 && totalSupply > minSupply) {
            uint defAmount = value * deflation / 1000;
            
            if (defAmount > 0) {
                
                if (totalSupply - defAmount < minSupply) {
                    defAmount = totalSupply - minSupply;
                }
                deduct = deduct + defAmount;
                totalSupply -= defAmount;
                burnt += defAmount;
                emit Transfer(from, address(0), defAmount);
            }
        }
        
        value = value - deduct;
        
        balances[to] += value;
        emit Transfer(from, to, value);
        return true;   
    }
    
    function approve(address spender, uint value) public returns (bool) {
        allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;   
    }
    
    function allowance(address owner, address spender) public view returns (uint) {
        return allowed[owner][spender];
    }
    
}

 contract DeflationaryTaxTokenBuilder {
    
    address public owner;
    address public beneficiary;
    uint public cost;
    uint public totalBuilt;
    
    mapping (address => address[]) public mytokens;

    event TokenCreated(address indexed tokenCreator, address indexed tokenAddress, string name, string symbol, uint decimals, uint totalSupply, uint tax1, address address1, uint tax2, address address2, uint deflation, uint minSupply);
    event OwnerSet(address indexed oldOwner, address indexed newOwner);
    event BeneficiarySet(address indexed oldBeneficiary, address indexed newBeneficiary);
    event Cost(uint newCost);
    
    modifier isOwner() {
        require(msg.sender == owner, "Only owner can do this!");
        _;
    }
    
    constructor(uint _cost) {
        owner = msg.sender;
        beneficiary = msg.sender;
        cost = _cost;
        totalBuilt = 0;
    }

    function createToken(string memory name, string memory symbol, uint decimals, uint totalSupply, uint tax1, address address1, uint tax2, address address2, uint deflation, uint minSupply, address to) public payable returns(address tokenAddress) { 
        require(minSupply <= totalSupply, "min supply more than initial supply");
        require(tax1 + tax2 + deflation <= 1000, "taxes are more than 100 percent");
        require(msg.value >= cost, "not enough ETH");
        if (msg.value > cost) {
            payable(msg.sender).transfer(msg.value - cost);
        }
        DeflationaryTaxToken newtoken = new DeflationaryTaxToken(name, symbol, decimals, totalSupply, tax1, address1, tax2, address2, deflation, minSupply, to);
        mytokens[msg.sender].push(address(newtoken));
        
        totalBuilt++;

        emit TokenCreated(msg.sender, address(newtoken), name, symbol, decimals, totalSupply, tax1, address1, tax2, address2, deflation, minSupply);

        return(address(newtoken));
    } 

    function myTokens() public view returns (address[] memory) {
        return mytokens[msg.sender];
    }
    
    function changeCost(uint _newcost) public isOwner {
        cost = _newcost;
        emit Cost(_newcost);
    }
    
    function withdraw() public isOwner {
        uint amount = address(this).balance;
        payable(beneficiary).transfer(amount);
    }
    
    function changeOwner(address newOwner) public isOwner {
        emit OwnerSet(owner, newOwner);
        owner = newOwner;
    }
    
    function changeBeneficiary(address newBeneficiary) public isOwner {
        beneficiary = newBeneficiary;
        emit BeneficiarySet(beneficiary, newBeneficiary);
    }
}