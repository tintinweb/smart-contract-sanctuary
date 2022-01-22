/**
 *Submitted for verification at Etherscan.io on 2022-01-22
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// creating token so we will code in ERC20 standard
contract ERC20 {
    //Attribute
    address _admin;
    uint private _totalSupply;
        // owner => balance
    mapping(address => uint) private _balances;
        // owner => spenders => amount
    mapping(address => mapping(address=> uint)) private _allowances;

    //Event
    event Transfer(address indexed from, address indexed to,uint256 amount);
    event Approval(address indexed owner,address indexed spender, uint256 amount);

    //function
    //Invoke only when deploy into blockchain once
    constructor(){
        _admin = msg.sender;
    }
   function name() public pure returns(string memory){
       return "SANGD coin";
   }
   function symbol() public pure returns(string memory){
       return "SANGD";
   }
   function decimals() public pure returns(uint8){
       return 0;
   }
   function totalSupply() public view returns(uint256){
       return _totalSupply;
   }
   function balanceOf(address owner) public view returns(uint256 balance){
       return _balances[owner];
   }

   function transfer(address to,uint256 amount) public returns(bool success){
       
       // get address of sender
       address from = msg.sender;
       
        //Validate input
        require(amount<=_balances[from],"transfer amount exceeds balance");
        require(to != address(0),"transfer to zero address");
      
        _balances[from]-=amount;
        _balances[to]+=amount;

        //invoke event
        emit Transfer(from,to,amount);
        return true;
   }

   function allowance(address owner,address spender) public view returns(uint256 remaining){
       return _allowances[owner][spender];
   }
   function approve(address spender,uint256 amount) public returns (bool success){
      //Validate
      require(spender != address(0),"approve spender zero address");

       _allowances[msg.sender][spender] = amount;
       //invoke event
       emit Approval(msg.sender,spender,amount);
       return true;
   }

   function transferFrom(address from,address to,uint256 amount) public returns(bool success){
       //Validate
       require(from != address(0),"transfer from zero address");
       require(to != address(0),"transfer to zero address");
       require(amount<=_balances[from],"transfer amount exceeds balance");
       
       if(from != msg.sender){
           uint allowanceAmount = _allowances[from][msg.sender];
           //Validate
           require(amount<=allowanceAmount,"transfer amount exceeds allowance");
           uint remaining=allowanceAmount - amount;
           _allowances[from][msg.sender] = remaining;
           //invoke event
           emit Approval(from,msg.sender,remaining); 
       }
        _balances[from]-=amount;
        _balances[to]+=amount;
        //invoke event
        emit Transfer(from,to,amount);
        return true;
   }
   function mint(address to,uint amount) public returns(uint){
       //Validate
       require(msg.sender == _admin,"Mint allow only admin");
       require(to != address(0),"transfer to zero address");

       _balances[to] += amount;
       _totalSupply += amount;
      
        //generate 'zero address'
        address from = address(0);
       emit Transfer(from,to,amount);
        return _balances[to];
   }

   function burn(address from,uint amount) public{
       //Validate
       require(msg.sender == _admin,"Burn allow only admin");
       require(from!=address(0),"burn from zero address");
       require(amount<=_balances[from],"burn amount exceeds balance");

       _balances[from] -= amount;
       _totalSupply -= amount;

       //Invoke event
       emit Transfer(from,address(0),amount);
   }
}
//contract contain
//-attribute => data that store in blockchain
 //-function contain 
    //1.function 
    //2.name(parameter)
    //3.access modifier -public - private -internal==protected(JAVA) 
    //4.pure => use when not associate with attribute (free tracsaction) , view => use when associate with attribute (only getter value from attribute not change value of attribute **free transaction)
    // not have 4. in function it must have gas in transaction because it must change the data that contain in blockchain disk
    //5.returns(return type) ** if return type is string use 'string memory'
    // other return type can add discription of return by 'type discription'
    // example returns(uint hello) show in log decoded output "hello:value"

// mapping(type of key=>type of value) == dict == object