/**
 *Submitted for verification at Etherscan.io on 2021-08-26
*/

pragma solidity ^0.8.0;

//"SPDX-License-Identifier: UNLICENSED"

//PIAIC PIAIC79180 Name Abdul Basit Abbasi

//Assignment 3A,3B and 3C (All bugs are fixed and now code works fine logically and code wise)

//contract deployment address on ropsten  0x9E0AC73597A8aa1204254597576042cCC12F50D6

contract assignment3bc {
    
    mapping(address => uint) balances;
    mapping(string => address) setPrices;

    string public Name;
    string public Symbol;
    uint public initialSuppply;
    uint public totalSuppply;
    address public owner;
    uint decimal = 2;
    uint price = 1*10**16;
    uint releaseTime = 2 minutes;
    uint time;
    uint cap;
    
    constructor() {
        
        Name = "My First Token";
        Symbol = "MFT";
        owner = msg.sender;
        cap = 2000000*10**decimal;
        
        time = block.timestamp;
        
        initialSuppply = 1000000 * 10**decimal;
        totalSuppply = initialSuppply;
        
        balances[owner] = totalSuppply;

    }

    //any one can buy tokken buy using this function
    function buyToken() public payable {
        
        uint amount = msg.value;
        uint tokenQty = amount/price;
        address buyer = msg.sender;
        
        require(owner != buyer,"Owner can not be buyer");
        require(msg.value >= 1, "Value should be more than 1");

        balances[buyer] = balances[buyer] + tokenQty *1e2 ;
        balances[owner] = balances[owner] - tokenQty *1e2 ;
        
    }
    
    //tokken holder can return token and get his ether back to his account based on current price
    
    function returnToken(uint _noOfTokken) external {
        
        require(balances[msg.sender]>= _noOfTokken, "You don't have enough quantity to return");
        
        uint noOfTokken = _noOfTokken*1e2;
        balances[msg.sender] -= noOfTokken;
        balances[owner] += noOfTokken;
        
        uint etherToReturn = noOfTokken/1e2*price;
        
        payable(msg.sender).transfer(etherToReturn);
    }
    
    //price will be adjusted, at the moment price is 100 tokens per ether so price = 1/100 then (result*1e18 to convert in wei). owner can give approval to multiple accounts to setPrices
    function setPrice(string memory approverName, uint newPrice) external {
        
        require(msg.sender == setPrices[approverName], "please get approval from owner and use your own address to change price");
        price = newPrice;
    }
    
    
    //owner will give approval to accounts to set prices. owner will give approval by using name of approvee and assign a addres against that name
    function setApprover(string memory approverName, address _address) external {
        require(msg.sender == owner, "Only owner can give approval");
        setPrices[approverName] = _address;
    }
    
    
    //Owner can remove person from setting price of takken.
    function removerApprover(string memory name) external {
        require(msg.sender == owner, "only owner can remover approver");
        delete setPrices[name];
    }
    
    //owner can mint tokkens untill cap reaches.
    function mintToken(uint _NoOfToken) external {
        
        uint NoOfToken = _NoOfToken*1e2; //there are two decimals in tokken so multiplying it with 1e2
        require(totalSuppply + NoOfToken <= cap, "Token Quantity can not be more than Capped amount");
        require(msg.sender == owner, "Only owner can mint tokken");
        
        totalSuppply += NoOfToken;
        balances[owner] += NoOfToken ;
        
    }
    
    
    //tokken holder can transfer tokkens to any other address. Here it will only be possible after release time which is 2 miuntes after contract deployment.
    function transfer(address recepient, uint _amount) external {
        uint amount = _amount *1e2;
        require(balances[msg.sender] >= amount, "not enought balance to transfer");
        require(block.timestamp >= time + releaseTime, "Tokens Can only be release after release time");
        
        balances[recepient] = balances[recepient] + amount;
        balances[msg.sender] = balances[msg.sender] - amount;
    }
    
    
    //owner can give ownership to any other address. Here ownership will be transferred to any given address.
    function transferOwnership(address _address) external {
        require(msg.sender == owner, "Only owner can update function");
        
        balances[address(_address)] = balances[owner];
        balances[owner] -= balances[owner];

        owner = address(_address);
        
        
    }
    
    
    //will check the tokken balance of address.
    function tokenBalance(address a) public view returns(uint) {
        require(a == msg.sender, "You can not check the balance of other account");
        return balances[a];
    }
    
    
    //will check the ether balance of contrat
    function contractBalance() external view returns(uint) {
        return address(this).balance;
    }
}