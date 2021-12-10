/**
 *Submitted for verification at Etherscan.io on 2021-12-10
*/

pragma solidity 0.5.0;

    contract TeckTrax{
        address owner;
    constructor(uint256 _qty) public {
           owner =msg.sender;
           tsupply = _qty;

           balances[msg.sender] = tsupply;
           name_ = "TechTrax";
           symbol_ = "ASM";
           decimal_ = 0;

    }


    string name_;
    function name () public view returns(string memory){
        return name_;

    }
    string symbol_;
    function symbol () public view returns(string memory){
        return symbol_;
    }
    uint8 decimal_;
    function decimals () public view returns(uint8){
        return decimal_;
        
    }
    uint256 tsupply;
    function totalsupply () public view returns(uint256){
        return tsupply;
    }
    mapping(address => uint256) balances;
    function balanceof(address _owner) public view returns(uint256 Balance){
     return balances[_owner];
    }
  

    event Transfer(address _from, address _too,uint256 _amt);

    function transfer(address _to , uint256 _value) public returns(bool success){
     require(balances[msg.sender]>= _value,"insufficient balance");
     balances[msg.sender] -= _value;
     balances[_to] += _value;
     emit Transfer(msg.sender,_to,_value);
     return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success){
     require (balances[_from] >= _value, "insufficient balance with owner");

     //check if allowance is available
     require (allowed[_from][msg.sender] >= _value,"Not enough allowance");

     //reducing balance from owner
     balances[_from]-=_value;

     //adding to receipents address
     balances[_to]+=_value;

     //updating allowance
     allowed[_from][msg.sender]-=_value;
     emit Transfer(_from, _to, _value);
     return true;
    }
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);


    mapping (address => mapping (address => uint256)) allowed;

    function approve(address _spender, uint256 _value) public returns (bool success){
        allowed[msg.sender][_spender] =  _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    //Function for Increase allowance
    function increaseallowance(address _spender, uint256 _value )public returns(bool){
        allowed[msg.sender][_spender] += _value;
        return true;
    }
     //Function for Decrease allowance
    function decreaseallowance(address _spender, uint256 _value )public returns(bool){
        allowed[msg.sender][_spender] -= _value;
        return true;
    }
     //Function of allowance
    function allowance(address _owner, address _spender) public view returns (uint256 remaining){
        return allowed[_owner][_spender];
    }

    modifier onlyOwner {
        require(msg.sender == owner, "Only Owner");
        _;
    }

      //Mint

      function mint(uint256 _qty, address _to)public returns(bool){
      tsupply += _qty;
      //Newly minted token to some specified address
      balances[_to] += _qty;
      //newly minted token to msg.sender
      balances[msg.sender] += _qty;
      //To contract deployer
      balances[owner] += _qty;
          return true;
      }

      //Burn
       
       function burn(uint256 _qty)public onlyOwner returns(bool){
           require(balances[msg.sender] >= _qty, "Not enough tokens to burn");

           tsupply -= _qty;
           balances[owner] -= _qty;
           return true;
       }

    }