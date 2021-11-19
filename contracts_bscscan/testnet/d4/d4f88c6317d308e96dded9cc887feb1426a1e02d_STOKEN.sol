/**
 *Submitted for verification at BscScan.com on 2021-11-18
*/

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.5.0 <0.9.0;


interface IERC20 {

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);


    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract STOKEN is IERC20{
    string public name;         //value is given by admin at the time of deploying SC
    string public symbol;       //value is given by admin at the time of deploying SC
    //uint8 public decimals;      //value is given by admin at the time of deploying SC
    address admin;              //who deployed the contract 
    uint totalSupply_;           //value is given by admin at the time of deploying SC
    
    
    modifier onlyAdmin{         //modifier only admin can use this function
        require(msg.sender==admin,"only admin can run this command");
        _;
    }

    //value is given by admin so that value are not hardcored in SC
    constructor(string memory _name, string memory _symbol, uint _totalsupply) {
            name=_name;
            symbol=_symbol;
            //decimals=_decimals;
            totalSupply_=_totalsupply;
            admin=msg.sender; 
            balances[admin]=totalSupply_;  //total supply added to the amdin account
    }
    
    mapping(address=>uint) balances;  //balance of the users
    
    mapping(address=>mapping(address=>uint)) allowed; //nested mapping tells about how much tokens is allowed for spender
    
    function totalSupply() public override view returns(uint){ //getter function returns the total supply of token 
        return totalSupply_;
    }
    
    
    //return the balance of the user 
    function balanceOf(address tokenowner) public override view returns(uint){
        return balances[tokenowner];
    }
    
    //transfer the number of tokens to another address
    function transfer(address receiver, uint numTokens) public override returns (bool){
        require(numTokens<=balances[msg.sender]);
        balances[msg.sender]-=numTokens;
        balances[receiver]+=numTokens;
        emit Transfer(msg.sender,receiver,numTokens);
        return true;
    }
    
    //minting of tokens to the total supply 
    //only admin can execute this command
    //returns the totalsupply_ after minting
    
    function mint(uint _qty) public onlyAdmin returns(uint){
        totalSupply_+=_qty;
        balances[msg.sender]+=_qty;
        return totalSupply_;
        
    }
    
    //burning of tokens from the totalsupply 
    //returns the total supply after burning
    
    function burn(uint _qty) public  onlyAdmin returns(uint){
        require(balances[msg.sender]>=_qty);
        totalSupply_-=_qty;         //decrease of tokens from the total supply
        balances[msg.sender]-=_qty; //decrease of token from the admin account also
        return totalSupply_;
    }
    
    
    //taking the approval for spending to the spender 
    //giving the amount of token he can spend 
    //firstly provide the Approval
    
    function approve (address _spender, uint _value)public override returns(bool){
        allowed[msg.sender][_spender]=_value;
        emit Approval(msg.sender,_spender,_value);
        return true;
    }
    
    //tranascting from the owner account to the beneficiaray account 
    function transferFrom(address _from, address _to , uint _value) public override returns(bool success){
        uint allowances = allowed[_from][msg.sender]; 
        
        // checking the owner have this much tokens or not 
        // check the spender have permisssion to spend this much tokens or not
        require(allowances >= _value && balances[_from] >= _value);
        
            balances[_to]+=_value;                  //adding tokens to the beneficiaray
            balances[_from]-=_value;                //subtractiing from the owner account
            allowed[_from][msg.sender]-=_value;     //subtracting allownace from the spender
            emit Transfer(_from,_to,_value);
            return true;
        
    }
    
    
    //get the maount of tokens allowed for spending from the owner account to spender account
    function allowance(address _owner, address _spender) public override view returns(uint remaining){
        return allowed[_owner][_spender];
    }
}