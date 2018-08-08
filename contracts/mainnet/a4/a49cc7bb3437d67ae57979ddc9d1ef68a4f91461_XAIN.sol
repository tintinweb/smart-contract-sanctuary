pragma solidity ^0.4.24;

/*

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





contract XAIN_ERC20 is Ownable {

    using SafeMath for uint256;


    mapping (address => uint256) public balances;


    mapping (address => mapping (address => uint256)) internal allowed;



    // Public variables for the XAIN ERC20 XNP token contract
    string public constant standard = "XAIN erc20 and Genesis";
    uint256 public constant decimals = 18;   // hardcoded to be a constant
    string public name = "XAIN";
    string public symbol = "XNP";
    uint256 public totalSupply;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);



    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }

    function transfer(address _to, uint256 _value) public returns (bool) {

        require(_to != address(0));
        require(_value <= balances[msg.sender]);
        // SafeMath.sub will throw if there is not enough balance.
        balances[msg.sender] = balances[msg.sender].sub(_value);


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


//
// This creates and adds six genesis pools of XNP tokens to the balance of the A,B,C,D,E and F Ethereum addresses
//

contract XAIN is XAIN_ERC20 {


        address public A;
        address public B;
        address public C;
        address public D;
        address public E;
        address public F;


    constructor (

        ) public {

        A = 0xc3b60984Df1FeffBd884Da6C083EaB735563C641;
        B = 0xD5b8D79dE753C98f165bD8d3eb896C1276c4B1FF;
        C = 0x75B351AD3e51376C9a3373D724e16daA52C54cD5;
        D = 0x908dA0Eb55C64Ea116A47a9bF62C6bfBd542FA81;
        E = 0x48875C46796C14e3fDC27D7acfBbd4a0f2a39953;
        F = 0xA010C083B38A9013d7E1Db8b4e5015BB7b280224;

        balances[A]=balances[A].add(5000000*(uint256(10)**decimals));
        balances[B]=balances[B].add(5000000*(uint256(10)**decimals));
        balances[C]=balances[C].add(10000000*(uint256(10)**decimals));
        balances[D]=balances[D].add(10000000*(uint256(10)**decimals));
        balances[E]=balances[E].add(25000000*(uint256(10)**decimals));
        balances[F]=balances[F].add(45000000*(uint256(10)**decimals));

        totalSupply=balances[A]+balances[B]+balances[C]+balances[D]+balances[E]+balances[F];


    }


}