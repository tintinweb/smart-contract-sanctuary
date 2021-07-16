//SourceUnit: ITRC20.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;


interface ITRC20 {
    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function increaseApproval(address _spender, uint _addedValue) external returns (bool);

    function decreaseApproval(address _spender, uint _subtractedValue) external returns (bool);

    event Approval(address indexed owner, address indexed spender, uint256 value);

    event Transfer(address indexed from, address indexed to, uint256 value);

}



//SourceUnit: Ownable.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

import "./SafeMath.sol";
contract Ownable {
    using SafeMath for uint256;
    
    address public mintAccessor;
    address public mintDest;
    address public mintAccessorChanger;
    address public mintDestChanger;
    
    event MintAccessorChanged (address indexed from, address indexed to);
    event MintDestChanged (address indexed from, address indexed to);
    event MintAccessorChangerChanged (address indexed from, address indexed to);
    event MintDestChangerChanged (address indexed from, address indexed to);
    
    /**
    * change destination of mint address
    */
    function changeMintDestAddress(address addr) public{
        require(msg.sender == mintDestChanger);
        emit MintDestChanged(mintDest, addr);
        mintDest = addr;
    }
    
    /**
    * change the mint destination changer
    */
    function changeMintDestChangerAddress(address addr) public{
        require(msg.sender == mintDestChanger);
        emit MintDestChangerChanged(mintDestChanger, addr);
        mintDestChanger = addr;
    }
    
     /**
    * change the mint accessor changer
    */
    function changeMintAccessorChanger(address addr) public{
        require(msg.sender == mintAccessorChanger);
        emit MintAccessorChangerChanged(mintAccessorChanger, addr);
        mintAccessorChanger = addr;
    }
    
     /**
    * change accessor of mint function
    */
    function changeMintAccessorAddress(address addr) public{
        require(msg.sender == mintAccessorChanger);
        emit MintAccessorChanged(mintAccessor, addr);
        mintAccessor = addr;
    }
}



//SourceUnit: SafeMath.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }


    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }
    
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
          return 0;
        }
        c = a * b;
        assert(c / a == b);
        return c;
      }
    
      /**
      * @dev Integer division of two numbers, truncating the quotient.
      */
      function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        // uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return a / b;
      }


}


//SourceUnit: TRC20.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "./ITRC20.sol";
import "./SafeMath.sol";
import "./Ownable.sol";

contract PallapayToken is ITRC20, Ownable {
    using SafeMath for uint256;

    mapping(address => uint256) internal balances;
    mapping(address => mapping(address => uint256)) internal allowances;
    uint256 internal totalSupply_;
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public inflationRate; // in 10**4
    uint256 private maximumSupply;
    uint256 public startTime;
    uint256 public lastTime;


    constructor(address mintAccessorAddress, address mintDestAddress, address mintAccessorChangerAddress, address mintDestChangerAddress,uint256 initialSupply, uint256 InfRate, uint256 mSupply) public {
        mintAccessor = mintAccessorAddress;
        mintDest = mintDestAddress;
        mintAccessorChanger = mintAccessorChangerAddress;
        mintDestChanger = mintDestChangerAddress;
        balances[mintAccessor] = initialSupply;
        totalSupply_ = initialSupply;
        emit Transfer(address(0), mintAccessor, initialSupply);
        inflationRate = InfRate;
        name = "Pallapay";
        symbol = "PALLA";
        decimals = 8;
        maximumSupply = mSupply;
        startTime = block.timestamp;
        lastTime = block.timestamp;
    }


    /**
     * Transfer token from sender(caller) to '_to' account
     *
     * Requirements:
     *
     * - `_to` cannot be the zero address.
     * - the sender(caller) must have a balance of at least `_value`.
     */
    function transfer(address _to, uint256 _value) public override returns (bool) {
        require (_value <= balances[msg.sender], "transfer value should be smaller than your balance");
        require (_to != address(0));
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }


    /**
     * sender(caller) transfer '_value' token to '_to' address from '_from' address
     *
     * Requirements:
     *
     * - `_to` and `_from` cannot be the zero address.
     * - `_from` must have a balance of at least `_value` .
     * - the sender(caller) must have allowance for `_from`'s tokens of at least `_value`.
     */
    function transferFrom(address _from, address _to, uint256 _value) public override returns (bool) {
        require (_from != address(0),"_from address is not valid");
        require (_to != address(0),"_to address is not valid");
        require(_value<=allowances[_from][msg.sender], "_value should be smaller than your allowance");
        require(_value<=balances[_from],"_value should be smaller than _from's balance");
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowances[_from][msg.sender] = allowances[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    /**
     * change allowance of `_spender` to `_value` by sender(caller)
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address _spender, uint256 _value) public override returns (bool) {
        require (_spender != address(0),  "_spender is not valid address");
        allowances[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    /**
    * Atomically increases the allowance granted to `spender` by the sender(caller).
    * Emits an {Approval} event indicating the updated allowance.
    *
    * Requirements:
    *
    * - `spender` cannot be the zero address.
    */
    function increaseApproval(address _spender, uint _addedValue) public override returns (bool) {
        require (_spender != address(0),  "_spender is not valid address");
        allowances[msg.sender][_spender] = allowances[msg.sender][_spender].add(_addedValue);
        emit Approval(msg.sender, _spender, allowances[msg.sender][_spender]);
        return true;
    }

    /**
    * Atomically decreases the allowance granted to `spender` by the sender(caller).
    * Emits an {Approval} event indicating the updated allowance.
    *
    * Requirements:
    *
    * - `_spender` cannot be the zero address.
    * - `_spender` must have allowance for the caller of at least `_subtractedValue`.
    */
    function decreaseApproval(address _spender, uint _subtractedValue) public override returns (bool) {
        require (_spender != address(0),  "_spender is not valid address");
        uint oldValue = allowances[msg.sender][_spender];
        allowances[msg.sender][_spender] = _subtractedValue > oldValue ? 0 : oldValue.sub(_subtractedValue);
        emit Approval(msg.sender, _spender, allowances[msg.sender][_spender]);
        return true;
    }


    /**
    * Destroys `amount` tokens from `account`, reducing the
    * total supply.
    * Emits a {Transfer} event with `to` set to the zero address.
    *
    * Requirements:
    * - `amount` cannot be less than zero.
    * - `amount` cannot be more than sender(caller)'s balance.
    */
    function burn(uint256 amount) public {
        require(amount > 0, "amount cannot be less than zero");
        require(amount <= balances[msg.sender], "amount to burn is more than the caller's balance");
        balances[msg.sender] = balances[msg.sender].sub(amount);
        totalSupply_ = totalSupply_.sub(amount);
        emit Transfer(msg.sender, address(0), amount);
    }
    

    /**
    * sender(caller) create a 'value' token mint request.
    *
    * Requirement:
    * - sender(Caller) should be mintAccessorAddress
    */
    function mint(uint256 value) public {
        require(msg.sender == mintAccessor,"you are not permitted to create mint request!");
        
        if (block.timestamp.sub(lastTime) >= 366 days) {
            maximumSupply = maximumSupply.mul(10**4 + inflationRate).div(10**4);
            lastTime = block.timestamp;
        }

        require(totalSupply().add(value) <= maxSupply(), "mint value more than maxSupply is not allowed!");

        totalSupply_ = totalSupply_.add(value);
        balances[mintDest] = balances[mintDest].add(value);
        emit Transfer(address(0), mintDest, value);
    }

    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }

    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }

    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowances[_owner][_spender];
    }


    function maxSupply() public view returns(uint256) {
        return maximumSupply.add(maximumSupply.mul(inflationRate).mul(block.timestamp.sub(lastTime)).div(366 days).div(10**4));
    }
}