pragma solidity ^0.4.24;

/*
    Copyright 2018, Vicent Nos

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.


 */



library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}


contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () internal {
      owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}


//////////////////////////////////////////////////////////////
//                                                          //
//  Alt Index, Open End Crypto Fund ERC20                    //
//                                                          //
//////////////////////////////////////////////////////////////

contract ALXERC20 is Ownable {

    using SafeMath for uint256;


    mapping (address => uint256) public balances;

    mapping (address => mapping (address => uint256)) internal allowed;

    mapping (address => mapping (uint256 => timeHold)) internal requestWithdraws;
   
 

    struct timeHold{
        uint256[] amount;
        uint256[] time;
        uint256 length;
    }
   
   function requestOfAmount(address addr, uint256 n) public view returns(uint256){
     return requestWithdraws[addr][n].amount[0];   
    }   
   
    function requestOfTime(address addr, uint256 n) public view returns(uint256){
     return requestWithdraws[addr][n].time[0];   
    }  
    
    uint256 public roundCounter=0;
    
    /* Public variables for the ERC20 token */
    string public constant standard = "ERC20 ALX";
    uint8 public constant decimals = 8; // hardcoded to be a constant
    uint256 public totalSupply;
    string public name;
    string public symbol;

    uint256 public transactionFee = 1;

    uint256 public icoEnd=0;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);


    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }


    function setTransactionFee(uint256 _value) public onlyOwner{
      transactionFee=_value;
 
    }

    function setIcoEnd(uint256 _value) public onlyOwner{
      icoEnd=_value;
 
    }

    function transfer(address _to, uint256 _value) public returns (bool) {

        require(_to != address(0));
        require(_value <= balances[msg.sender]);
        require(block.timestamp>icoEnd);
        // SafeMath.sub will throw if there is not enough balance.
        balances[msg.sender] = balances[msg.sender].sub(_value);

        uint256 fee=(_value*transactionFee)/1000;
 
        delete requestWithdraws[msg.sender][roundCounter];

        balances[_to] = balances[_to].add(_value-fee);
        balances[owner]=balances[owner].add(fee);
        
        emit Transfer(msg.sender, _to, _value-fee);
        emit Transfer(msg.sender, owner, fee);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);
        require(block.timestamp>icoEnd);
        balances[_from] = balances[_from].sub(_value);

        uint256 fee=(_value*transactionFee)/1000;

        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);

        delete requestWithdraws[msg.sender][roundCounter];
        delete requestWithdraws[_from][roundCounter];

        balances[_to] = balances[_to].add(_value-fee);
        balances[owner]=balances[owner].add(fee);
        
        emit Transfer(_from, _to, _value-fee);
        emit Transfer(_from, owner, fee);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }

    function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    /* Approve and then communicate the approved contract in a single tx */
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);

        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }
}


interface tokenRecipient {
    function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external ;
}


contract ALX is ALXERC20 {

    // Contract variables and constants


    uint256 public tokenPrice = 30000000000000000;
    uint256 public tokenAmount=0;

    // constant to simplify conversion of token amounts into integer form
    uint256 public tokenUnit = uint256(10)**decimals;

    uint256 public holdTime;
    uint256 public holdMax;
    uint256 public maxSupply;

    //Declare logging events
    event LogDeposit(address sender, uint amount);



    uint256 public withdrawFee = 1;

    /* Initializes contract with initial supply tokens to the creator of the contract */
        constructor (
            
            uint256 initialSupply,
            string contractName,
            string tokenSymbol,
            uint256 contractHoldTime,
            uint256 contractHoldMax,
            
            address contractOwner

        ) public {


        totalSupply = initialSupply;  // Update total supply
        name = contractName;             // Set the name for display purposes
        symbol = tokenSymbol;         // Set the symbol for display purposes
        holdTime=contractHoldTime;
        holdMax=contractHoldMax;
        
        owner=contractOwner;
        balances[contractOwner]= balances[contractOwner].add(totalSupply);

    }

    function () public payable {
        buy();   // Allow to buy tokens sending ether directly to contract
    }


    function deposit() external payable onlyOwner returns(bool success) {
        // Check for overflows;
        //executes event to reflect the changes
        emit LogDeposit(msg.sender, msg.value);

        return true;
    }


    function setWithdrawFee(uint256 _value) public onlyOwner{
      withdrawFee=_value;
 
    }
    


    function withdrawReward() external {

        uint i = 0;
        uint256 ethAmount = 0;

        uint256 tokenM=0;
        
        if (block.timestamp -  requestWithdraws[msg.sender][roundCounter].time[i] > holdTime && block.timestamp -  requestWithdraws[msg.sender][roundCounter].time[i] < holdMax){
                ethAmount += tokenPrice * requestWithdraws[msg.sender][roundCounter].amount[i];
                tokenM +=requestWithdraws[msg.sender][roundCounter].amount[i];
        }
    
        ethAmount=ethAmount/tokenUnit;
        require(ethAmount > 0);

        emit LogWithdrawal(msg.sender, ethAmount);

        totalSupply = totalSupply.sub(tokenM);

        delete requestWithdraws[msg.sender][roundCounter];

        uint256 fee=ethAmount*withdrawFee/1000;

        balances[msg.sender] = balances[msg.sender].sub(tokenM);

        msg.sender.transfer(ethAmount-fee);
        owner.transfer(fee);

    }

     
    function withdraw(uint256 amount) public onlyOwner{ 
        msg.sender.transfer(amount);
    }

    function setPrice(uint256 _value) public onlyOwner{
      tokenPrice=_value;
      roundCounter++;

    }



    event LogWithdrawal(address receiver, uint amount);

    function requestWithdraw(uint256 value) public {
      require(value <= balances[msg.sender]);

      delete requestWithdraws[msg.sender][roundCounter];

      requestWithdraws[msg.sender][roundCounter].amount.push(value);
      requestWithdraws[msg.sender][roundCounter].time.push(block.timestamp);
      requestWithdraws[msg.sender][roundCounter].length++;
      //executes event ro register the changes

    }
    
    uint256 public minPrice=250000000000000000;
    
    function setMinPrice(uint256 value) public onlyOwner{
        minPrice=value;
    }

    function buy() public payable {
        require(msg.value>=minPrice);
        tokenAmount = (msg.value * tokenUnit) / tokenPrice ;  // calculates the amount
        
        transferBuy(msg.sender, tokenAmount);
        owner.transfer(msg.value);
    }

    function transferBuy(address _to, uint256 _value) internal returns (bool) {
        require(_to != address(0));

        // SafeMath.add will throw if there is not enough balance.
        totalSupply = totalSupply.add(_value);
        
        uint256 teamAmount=_value*100/1000;

        totalSupply = totalSupply.add(teamAmount);



        balances[_to] = balances[_to].add(_value);
        balances[owner] = balances[owner].add(teamAmount);

        emit Transfer(this, _to, _value);
        emit Transfer(this, owner, teamAmount);
        return true;

    }
}