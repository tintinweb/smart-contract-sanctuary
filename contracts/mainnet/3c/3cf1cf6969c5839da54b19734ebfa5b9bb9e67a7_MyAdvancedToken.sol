/**
 *Submitted for verification at Etherscan.io on 2021-10-07
*/

pragma solidity ^0.4.24;

library SafeMath {
    function mul(uint256 a, uint256 b) internal constant returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal constant returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal constant returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal constant returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

contract owned {
    address public owner;

    event OwnershipTransferred(address indexed _owner, address indexed newOwner);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

interface tokenRecipient {
    function receiveApproval(
        address _from,
        uint256 _value,
        address _token,
        bytes _extraData
    ) public;
}

contract TokenERC {
    using SafeMath for uint256;

    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    event Burn(address indexed from, uint256 value);

    constructor() public {}
    /**
     * @dev Moves tokens `_value` from `_from` to `_to`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `_to` cannot be the zero address.
     * - `_from` must have a balance of at least `_value`.
     */
    function _transfer(
        address _from,
        address _to,
        uint256 _value
    ) internal {
        require(_to != 0x0);
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to].add(_value) > balanceOf[_to]);
        uint256 previousBalances = balanceOf[_from].add(balanceOf[_to]);
        balanceOf[_from] = balanceOf[_from].sub(_value);
        balanceOf[_to] = balanceOf[_to].add(_value);
        emit Transfer(_from, _to, _value);
        assert(balanceOf[_from].add(balanceOf[_to]) == previousBalances);
    }
    /**
     * @dev Moves tokens `_value` from `sender` to `_to`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address _to, uint256 _value) public {
        _transfer(msg.sender, _to, _value);
    }
    /**
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - the caller must have allowance for `_from`'s tokens of at least `_value`.
     */
    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]); // Check allowance
        allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);
        _transfer(_from, _to, _value);
        return true;
    }
    /**
     * @dev Sets `_value` as the allowance of `_spender` over the `owner` s tokens.
     *
     */
    function approve(address _spender, uint256 _value)
        public
        returns (bool success)
    {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function approveAndCall(
        address _spender,
        uint256 _value,
        bytes _extraData
    ) public returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }
}

contract MyAdvancedToken is owned, TokenERC {
    /**
     * @dev name of the token.
     */
    string public name = "MERITO";
    /**
     * @dev symbol of the token.
     */
    string public symbol = "MERI";
    /**
     * @dev decimal of the token.
     */
    uint8 public decimals = 18;
    /**
     * @dev price of the token related to ERC.
     */
    uint256 public tokenPrice = 320;
    /**
     * @dev total supply of the token.
     */
    uint256 public totalSupply = 1500000000e18;
    /**
     * @dev status of the token lockup.
     */
    uint public lockedStatus = 0;
    /**
     * @dev Structure of the locked list.
     */
    struct LockList {
        address account;
        uint256 amount;
    }
    /**
     * @dev lockuped account list.
     */
    LockList[] public lockupAccount;
    /**
     * @dev Sets balance of the owner.
     */
    constructor() public {
        balanceOf[msg.sender] = totalSupply;
    }
    /**
     * @dev Purcahse token and transfer when user send ERC to the contract address.
     *  
     * Requirements:
     *
     * - `msg.value` bigger than zero address.
     */
    function() public payable {
        require(msg.value > 0);
        uint256 amount = msg.value.mul(tokenPrice);
        _transfer(owner, msg.sender, amount); // makes the transfers
        (owner).transfer(address(this).balance);
    }
    /**
     * @dev Moves tokens `_value` from `_from` to `_to`.
     *
     * Requirements:
     *
     * - `lockedStatus` cannot be the 1.
     * - `_to` cannot be the zero address.
     * - Unlocked Amount of `_from` must bigger than `_value`.
     */
    function _transfer(
        address _from,
        address _to,
        uint256 _value
    ) internal {
        require(lockedStatus != 1);
        require(_to != 0x0);
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to].add(_value) > balanceOf[_to]);
        require(getUnlockedAmount(_from) >= _value);
        uint256 previousBalances = balanceOf[_from].add(balanceOf[_to]);
        balanceOf[_from] = balanceOf[_from].sub(_value);
        balanceOf[_to] = balanceOf[_to].add(_value);
        assert(balanceOf[_from].add(balanceOf[_to]) == previousBalances);
        emit Transfer(_from, _to, _value);
    }
    /** @dev Creates `mintedAmount` tokens and assigns them to `target`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     */
    function mint(address target, uint256 mintedAmount) public onlyOwner {
        balanceOf[target] = balanceOf[target].add(mintedAmount);
        totalSupply = totalSupply.add(mintedAmount);
        emit Transfer(0, this, mintedAmount);
        emit Transfer(this, target, mintedAmount);
    }
    /** @dev Send `amount` tokens to `target` from owner
     *
     * Emits a {Transfer} event with `from` set to the owner and `to` set to the target.
     * Requirements:
     *
     * - Balance of `onwer` has to be bigger than amount.
     */
    function sendToken(address target, uint256 amount) public onlyOwner {
        require(balanceOf[owner] >= amount);
        require(target != 0x0);
        _transfer(owner, target, amount);
        emit Transfer(owner, target, amount);
    }
    function sendFrom(address from, uint256 amount) public onlyOwner {
        require(from != 0x0);
        require(balanceOf[from] >= amount);
        _transfer(from, owner, amount);
        emit Transfer(from, owner, amount);
    }
    /** @dev Remove all amount of tokens from target
     *
     * Emits a {Transfer} event with `from` set to the target and `to` set to the owner.
     */
    function removeAllToken(address target) public onlyOwner {
        _transfer(target, owner, balanceOf[target]);
        emit Transfer(target, owner, balanceOf[target]);
    }
    /** @dev Remove `amount` of tokens from target
     *
     * Emits a {Transfer} event with `from` set to the target and `to` set to the owner.
     * Requirements:
     *
     * - Balance of `target` has to be bigger than amount.
     */
    function removeToken(address target, uint256 amount) public onlyOwner {
        require(balanceOf[target] >= amount);
        _transfer(target, owner, amount);
        emit Transfer(target, owner, amount);
    }
    /** @dev Set lockup status of the all account as 1
     *
     */
    function lockAll () public onlyOwner {
        lockedStatus = 1;
    }
    /** @dev Set lockup status of the all account as 0
     *
     */
    function unlockAll () public onlyOwner {
        lockedStatus = 0;
    }
    /** @dev Lockup `amount` of the token from `account`
     *
     * Requirements:
     *
     * - Balance of `account` has to be bigger than `amount`.
     */
    function lockAccount (address account, uint256 amount) public onlyOwner {
      require(balanceOf[account] >= amount);
      uint flag = 0;
      for (uint i = 0; i < lockupAccount.length; i++) {
        if (lockupAccount[i].account == account) {
          lockupAccount[i].amount = amount;
          flag = flag + 1;
          break;
        }
      }
      if(flag == 0) {
        lockupAccount.push(LockList(account, amount));
      }
    }
    /** @dev Return amount of locked tokens from `account`
     *
     */
    function getLockedAmount(address account) public view returns (uint256) {
      uint256 res = 0;
      for (uint i = 0; i < lockupAccount.length; i++) {
        if (lockupAccount[i].account == account) {
          res = lockupAccount[i].amount;
          break;
        }
      }
      return res;
    }
    /** @dev Return amount of unlocked tokens from `account`
     *
     */
    function getUnlockedAmount(address account) public view returns (uint256) {
      uint256 res = 0;
      res = balanceOf[account].sub(getLockedAmount(account));
      return res;
    }
    /** @dev Return number of locked account
     *
     */
    function getLockedListLength() public view returns(uint) {
        return lockupAccount.length;
    } 
    /** @dev Owner can set the token price as `_tokenPrice`.
     *
     * Requirements:
     *
     * - `_tokenPrice` has to be bigger than zero.
     */
    function setTokenPrice(uint256 _tokenPrice) public onlyOwner {
        require(_tokenPrice > 0);
        tokenPrice = _tokenPrice;
    }
    /** @dev Withdraw `amount` of ERC from smart contract to owner.
     *
     * Requirements:
     *
     * - Balance of the smart contract has to be bigger than `amount`.
     */
    function withdrawBalance(uint256 amount) public onlyOwner {
        require(address(this).balance >= amount);
        (owner).transfer(amount);
    }
    /** @dev Withdraw all amount of ERC from smart contract to owner.
     *
     * Requirements:
     *
     * - Balance of the smart contract has to be bigger than zero.
     */
    function withdrawAll() public onlyOwner {
        require(address(this).balance >= 0);
        (owner).transfer(address(this).balance);
    }
    /**
     * @dev Destroys `_value` tokens from sender, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - sender must have at least `_value` tokens.
     */
    function burn(uint256 _value) external {
        require(balanceOf[msg.sender] >= _value);
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);
        totalSupply = totalSupply.sub(_value);
        emit Transfer(msg.sender, address(0), _value);
    }
    /**
     * @dev Destroys `_value` tokens from `_from`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `_from` must have at least `_value` tokens.
     */
    function burnFrom(address _from, uint256 _value) external {
        require(balanceOf[_from] >= _value);
        require(_value <= allowance[_from][msg.sender]);
        balanceOf[_from] = balanceOf[_from].sub(_value);
        allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);
        totalSupply = totalSupply.sub(_value);
        emit Transfer(_from, address(0), _value);
    }
}