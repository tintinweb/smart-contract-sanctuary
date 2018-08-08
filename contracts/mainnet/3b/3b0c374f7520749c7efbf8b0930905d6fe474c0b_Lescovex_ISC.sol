pragma solidity ^0.4.24;

/*
    Copyright 2018, Vicent Nos & Enrique Santos

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

    constructor() internal {
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
//  Lescovex Equity ERC20                                   //
//                                                          //
//////////////////////////////////////////////////////////////

contract LescovexERC20 is Ownable {

    using SafeMath for uint256;


    mapping (address => uint256) public balances;

    mapping (address => mapping (address => uint256)) internal allowed;

    mapping (address => timeHold) holded;

    struct timeHold{
        uint256[] amount;
        uint256[] time;
        uint256 length;
    }



    /* Public variables for the ERC20 token */
    string public constant standard = "ERC20 Lescovex ISC Income Smart Contract";
    uint8 public constant decimals = 8; // hardcoded to be a constant
    uint256 public totalSupply;
    uint256 public holdTime;
    string public name;
    string public symbol;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);


    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }

    function holdedOf(address _owner) public view returns (uint256) {
        uint i = 0;
        uint256 tokenAmount = 0;
        uint256 len = holded[_owner].length;
        uint256 maxHoldStart = block.number - holdTime;

        while (i < len && holded[_owner].time[i] < maxHoldStart){
               tokenAmount += holded[_owner].amount[i];
               i++;
        }
        return tokenAmount;
    }

    function hold(address _to, uint256 _value) internal {
        holded[_to].amount.push(_value);
        holded[_to].time.push(block.number);
        holded[_to].length++;
    }

    function transfer(address _to, uint256 _value) public returns (bool) {

        require(_to != address(0));
        require(_value <= balances[msg.sender]);
        // SafeMath.sub will throw if there is not enough balance.
        balances[msg.sender] = balances[msg.sender].sub(_value);

        delete holded[msg.sender];
        hold(msg.sender,balances[msg.sender]);
        hold(_to,_value);

        balances[_to] = balances[_to].add(_value);

        emit Transfer(msg.sender, _to, _value);
        return true;
    }




    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

        balances[_from] = balances[_from].sub(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);

        delete holded[_from];
        hold(_from,balances[_from]);
        hold(_to,_value);

        balances[_to] = balances[_to].add(_value);


        emit Transfer(_from, _to, _value);
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


contract Lescovex_ISC is LescovexERC20 {

    uint256 public contractBalance = 0;

    //Declare logging events
    event LogDeposit(address sender, uint amount);
    event LogWithdrawal(address receiver, uint amount);

    address contractAddr = this;

    /* Initializes contract with initial supply tokens to the creator of the contract */
    constructor (
        uint256 initialSupply,
        string contractName,
        string tokenSymbol,
        uint256 contractHoldTime,
        address contractOwner

        ) public {
        totalSupply = initialSupply;  // Update total supply
        name = contractName;             // Set the name for display purposes
        symbol = tokenSymbol;         // Set the symbol for display purposes
        holdTime = contractHoldTime;
        balances[contractOwner] = totalSupply;

    }

    function () public {

    }

    function deposit() external payable onlyOwner returns(bool success) {
        contractBalance = contractAddr.balance;
        //executes event to reflect the changes
        emit LogDeposit(msg.sender, msg.value);

        return true;
    }

    function withdrawReward() external {
    
        uint256 ethAmount = (holdedOf(msg.sender) * contractBalance) / totalSupply;

        require(ethAmount > 0);


        //executes event to register the changes
        emit LogWithdrawal(msg.sender, ethAmount);

        delete holded[msg.sender];
        hold(msg.sender,balances[msg.sender]);
        //send eth to owner address
        msg.sender.transfer(ethAmount);
    }

    function withdraw(uint256 value) external onlyOwner {
        //send eth to owner address
        msg.sender.transfer(value);
        //executes event to register the changes
        emit LogWithdrawal(msg.sender, value);
    }
}