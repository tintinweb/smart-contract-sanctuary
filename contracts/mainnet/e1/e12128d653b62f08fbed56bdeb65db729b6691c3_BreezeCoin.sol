pragma solidity ^0.4.18;

/**

 * This is BreezeCoin contract

 */

 

/**

 * Defining basic ERC20 interface. Standard ERC20 interface functions.

 * Please check https://github.com/ethereum/EIPs/issues/179

 */

contract ERC20Basic {

    function totalSupply() public view returns (uint256);

    function balanceOf(address who) public view returns (uint256);

    function transfer(address to, uint256 value) public returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

}

/**

 * Defining ERC20 interface. This functions are standard for every token.

 * Please check https://github.com/ethereum/EIPs/issues/20

 */

contract ERC20 is ERC20Basic {

    function allowance(address owner, address spender) public view returns (uint256);

    function transferFrom(address from, address to, uint256 value) public returns (bool);

    function approve(address spender, uint256 value) public returns (bool);

    event Approval(address indexed owner, address indexed spender, uint256 value);

}

/**

 *OpenZeppelin SafeMath library to make the contract secure.

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

        uint256 c = a / b;

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

/**

 * Defining BasicToken with

 * fucntions of check total supply of the token, token transfer and check balance

 * of the input address. These functions are standard for every basic token.

 */

contract BasicToken is ERC20Basic {

    using SafeMath for uint256;



    mapping(address => uint256) balances;



    uint256 totalSupply_;



    function totalSupply() public view returns (uint256) {

        return totalSupply_;

    }



    function transfer(address _to, uint256 _value) public returns (bool) {

        require(_to != address(0));

        require(_value <= balances[msg.sender]);



        balances[msg.sender] = balances[msg.sender].sub(_value);

        balances[_to] = balances[_to].add(_value);

        emit Transfer(msg.sender, _to, _value);

        return true;

    }



    function balanceOf(address _owner) public view returns (uint256 balance) {

        return balances[_owner];

    }



}

/**

 * Defining StandardToken with

 * approval function. These functions are standard for every token.

 * Please check https://github.com/ethereum/EIPs/issues/20

 */

contract StandardToken is ERC20, BasicToken {



    mapping (address => mapping (address => uint256)) internal allowed;



    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {

        require(_to != address(0));

        require(_value <= balances[_from]);

        require(_value <= allowed[_from][msg.sender]);



        balances[_from] = balances[_from].sub(_value);

        balances[_to] = balances[_to].add(_value);

        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);

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



}



/**

 * Defining ownershipTransfer

 * function. Function takes the new address and transfer the ownership.

 *

 */

contract Ownable {

    address public owner;





    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);





    function Ownable() public {

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

/**

 * Creating BreezeCoin.

 * BreezeCoin calls the contracts StandardToken and ownable.

 */

contract BreezeCoin is StandardToken, Ownable {



    string public constant name = "BreezeCoin";



    string public constant symbol = "BRZC";



    uint256 public constant decimals = 18;



    bool public released = false;

    event Release();

    address public holder;

    address private wallet1;
    address private wallet2;
    address private team_tips;
    address private Reserve;
/** 
 * This modifier allows only owner of the token and holder of the token call a function.
 */
    modifier isReleased () {

        require(released || msg.sender == holder || msg.sender == owner);

        _;

    }



    function BreezeCoin() public {

        owner = 0xE601Bb5Ef5Ca433e6B467a5fc8453dcACE3974De;

        wallet1 = 0x5a86671071Ad67f2DF02c821e587BCe5B8e26C38; //early investors

        wallet2 = 0x25b25f5dE7C81b14DEf6db5B65107853687702EC; //manager

        team_tips =  0x6FcF24c918631Bb385DeeDC6d01e8f68293E2641; //team tips

        Reserve =  0x3d4Bd578291737fAED39bA3F20F32DF25111D724; //Reserve

        holder = 0x2bb3a4f80bFb939716E6d85799116feB1906748B; //ico coins holder

        totalSupply_ = 200000000 * (10 ** decimals); // our total supply is 200 million

        balances[holder] = 30000000* (10 ** decimals); //ico wallet holds 30 million

        balances[wallet1] = 10000000* (10 ** decimals);
        balances[wallet2] = 1250000* (10 ** decimals);
        balances[team_tips] = 8750000* (10 ** decimals);
        balances[Reserve] = 150000000* (10 ** decimals);


        emit Transfer(0x0, holder, 30000000* (10 ** decimals)); // creating token out of thin air to ICO holder account address.
        emit Transfer(0x0, wallet1, 10000000* (10 ** decimals)); // creating token out of thin air to team wallet1 account address.
        emit Transfer(0x0, team_tips, 8750000* (10 ** decimals)); // creating token out of thin air to team tips account address.
        emit Transfer(0x0, wallet2, 1250000* (10 ** decimals)); // creating token out of thin air to wallet2 account address.
        emit Transfer(0x0, Reserve, 150000000* (10 ** decimals)); // creating token out of thin air to reserve account address.



        

    }

/** 
 * Tokens are first not released. This function can be called only by owner. This function releases the tokens and allow token transfers.
 */

    function release() onlyOwner public returns (bool) {

        require(!released);

        released = true;

        emit Release();



        return true;

    }



    function getOwner() public view returns (address) {

        return owner;

    }


/** 
 * These functions allow users to use transfer and approve functions if the token is released.
 */
    function transfer(address _to, uint256 _value) public isReleased returns (bool) {

        return super.transfer(_to, _value);

    }



    function transferFrom(address _from, address _to, uint256 _value) public isReleased returns (bool) {

        return super.transferFrom(_from, _to, _value);

    }



    function approve(address _spender, uint256 _value) public isReleased returns (bool) {

        return super.approve(_spender, _value);

    }



    function increaseApproval(address _spender, uint _addedValue) public isReleased returns (bool success) {

        return super.increaseApproval(_spender, _addedValue);

    }



    function decreaseApproval(address _spender, uint _subtractedValue) public isReleased returns (bool success) {

        return super.decreaseApproval(_spender, _subtractedValue);

    }



    function transferOwnership(address newOwner) public onlyOwner {

        address oldOwner = owner;

        super.transferOwnership(newOwner);



        if (oldOwner != holder) {

            allowed[holder][oldOwner] = 0;

            emit Approval(holder, oldOwner, 0);

        }



        if (owner != holder) {

            allowed[holder][owner] = balances[holder];

            emit Approval(holder, owner, balances[holder]);

        }

    }



}