pragma solidity ^0.6.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

 
 /* https://github.com/LykkeCity/EthereumApiDotNetCore/blob/master/src/ContractBuilder/contracts/token/SafeMath.sol */
library SafeMath {
    uint256 constant public MAX_UINT256 =
    0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

    function safeAdd(uint256 x, uint256 y) pure internal returns (uint256 z) {
        if (x > MAX_UINT256 - y) revert();
        return x + y;
    }

    function safeSub(uint256 x, uint256 y) pure internal returns (uint256 z) {
        if (x < y) revert();
        return x - y;
    }

    function safeMul(uint256 x, uint256 y) pure internal returns (uint256 z) {
        if (y == 0) return 0;
        if (x > MAX_UINT256 / y) revert();
        return x * y;
    }
}

interface ContractReceiver {
  function tokenFallback( address _from, uint _value, bytes calldata _data) external;
}
 
contract Kinary {

    using SafeMath for uint256;
    
    event Transfer(address indexed _from, address indexed _to, uint256 _value, bytes _data);
    event Print(address indexed _to, uint256 _value);
    event OwnershipTransfered(address indexed _old, address indexed _new);

    mapping(address => uint) public balances;
  
    string public name  = "Kinary";
    string public symbol  = "KINA";
    uint8 public decimals = 3;
    uint256 public totalSupply;
    bool ableToPrint = true;
    uint signatures = 0;
    uint APY1 = 2000;
    uint APY2 = 3000;
    uint public price = 1000000;
    uint public genesisTime = 0;
    uint public totalInCirculation = 0;
    address public central;
    address[] public acceptedTokens;
    address[] public owners;
    address[] public signedOwners;
    address[] allowedTokens;

    // Deposits
    struct Deposit {
        address owner;
        uint amount;
        uint time;
        uint rate;
        address token;
    }

    Deposit[] public deposits;
    
    constructor() public {
        balances[msg.sender] = 80000000000000000 * (10 ** uint256(decimals));
        totalSupply = balances[msg.sender];
        central = msg.sender;
        owners.push(0x2E42c06BCD058ebF81d1F3BE3f7cf59DFFd9Deb1);
        owners.push(0xf9AED95D77792adC39F681e5AddFd27Ede21f490);
        owners.push(0x6edC9aFA41B8a1Ea7006f085A4483094F45D2675);
    }
    
    
    receive() external payable {
        require(ableToPrint);
        require(isOwner(msg.sender));
        uint amount = msg.value.safeMul(price);
        transferFromContract(msg.sender, amount);
        totalInCirculation += amount;
        emit Print(msg.sender, amount);
        ableToPrint = false;
    }

    function addAllowedTokens(address token) public returns (bool) {
        require(isOwner(msg.sender));
        allowedTokens.push(token);
    }
    
    
    function transferOwnerShip(address _newOwner) public returns (bool success) {
        require(isOwner(msg.sender));
        for (uint i=0; i<owners.length;i++){
            if (owners[i] == msg.sender) {
                owners[i] = _newOwner;
            }
        }
        emit OwnershipTransfered(msg.sender, _newOwner);
        return true;
    }
    
    
    function isOwner(address _sender) public returns (bool) {
        bool addressIsOwner = false;
        for (uint i=0; i<owners.length; i++){
            if (owners[i] == _sender) {
                addressIsOwner = true;
            }
        }
        return addressIsOwner;
    }

    function addToken(uint _amount, address _sender) public returns (bool) {
        require(isOwner(msg.sender));
        //TODO
        return true;
    }

    function removeToken(uint _amount, address _sender) public returns (bool) {
        require(isOwner(msg.sender));
        //TODO
        return true;
    }

    function findDeposit(address account) internal view
    returns (int index) {
        uint length = deposits.length;
        for (uint u = 0; u < length; u++) {
            if (deposits[u].owner == account) return int(u);
        }
        return -1;
    }


    function addDeposit(address owner, uint _amount, uint time, uint rate, address token) 
    public {
        require(findDeposit(owner) < 0, "Already exists");
        if (tokenIsAllowed(token)) {
            IERC20(token).transferFrom(msg.sender, address(this), _amount);
            deposits.push(
           Deposit({owner: owner, amount: _amount, time: time, rate: rate, token: token}));
        }
    }


     function withdraw(uint _amount, address _sender) public returns (bool) {
        int256 userIndex = findDeposit(_sender);
        if (userIndex == -1) return false;
        Deposit memory userDeposit = deposits[uint(userIndex)];
        uint value = 0;
        transferFromContract(msg.sender, userDeposit.amount * 2);
        return true;
    }


    function tokenIsAllowed(address token) public returns (bool) {
        for (
            uint256 allowedTokensIndex = 0;
            allowedTokensIndex < allowedTokens.length;
            allowedTokensIndex++
        ) {
            if (allowedTokens[allowedTokensIndex] == token) {
                return true;
            }
        }
        return false;
    }
    
    

    function addSignature() public returns (bool success) {
        require(isOwner(msg.sender));
        uint totalSig = 0;
        signedOwners.push(msg.sender);
        if (signedOwners.length == 2) {
            ableToPrint = true;
            delete signedOwners;
        }
        return true;
    }
    
    
    // Function that is called when a user or another contract wants to transfer funds .
    function transfer(address _to, uint _value, bytes memory _data, bytes memory _custom_fallback) public returns (bool success) {
        require(msg.sender != central);
        if(isContract(_to)) {
            if (balanceOf(msg.sender) < _value) revert();
            balances[msg.sender] = balanceOf(msg.sender).safeSub(_value);
            balances[_to] = balanceOf(_to).safeAdd(_value);
            ContractReceiver rx = ContractReceiver(_to);
            emit Transfer(msg.sender, _to, _value, _data);
            return true;
        }
        else {
            return transferToAddress(_to, _value, _data);
        }
    }
  

  // Function that is called when a user or another contract wants to transfer funds .
    function transfer(address _to, uint _value, bytes memory _data) public returns (bool success) {
        require(msg.sender != central);
        if(isContract(_to)) {
            return transferToContract(_to, _value, _data);
        }
        else {
            return transferToAddress(_to, _value, _data);
        }
    }
  
  // Standard function transfer similar to ERC20 transfer with no _data .
  // Added due to backwards compatibility reasons .
    function transfer(address _to, uint _value) public returns (bool success) {
        require(msg.sender != central);
        //standard function transfer similar to ERC20 transfer with no _data
        //added due to backwards compatibility reasons
        bytes memory empty;
        if(isContract(_to)) {
            return transferToContract(_to, _value, empty);
        }
        else {
            return transferToAddress(_to, _value, empty);
        }
    }

//assemble the given address bytecode. If bytecode exists then the _addr is a contract.
    function isContract(address _addr) private view returns (bool is_contract) {
        uint length;
        assembly {
                //retrieve the size of the code on target address, this needs assembly
                length := extcodesize(_addr)
        }
        return (length>0);
    }

  //function that is called when transaction target is an address
    function transferToAddress(address _to, uint _value, bytes memory _data) private returns (bool success) {
        require(msg.sender != central);
        if (balanceOf(msg.sender) < _value) revert();
        balances[msg.sender] = balanceOf(msg.sender).safeSub(_value);
        balances[_to] = balanceOf(_to).safeAdd(_value);
        emit Transfer(msg.sender, _to, _value, _data);
        return true;
    }
    
    function transferFromContract(address _to, uint _value) private returns (bool success) {
        require(msg.sender != central);
        bytes memory _data;
        if (balanceOf(central) < _value) revert();
        balances[central] = balanceOf(central).safeSub(_value);
        balances[_to] = balanceOf(_to).safeAdd(_value);
        payable(central).transfer(msg.value);
        emit Transfer(central, _to, _value, _data);
        return true;
    }
  
  //function that is called when transaction target is a contract
    function transferToContract(address _to, uint _value, bytes memory _data) private returns (bool success) {
        require(msg.sender != central);
        if (balanceOf(msg.sender) < _value) revert();
        balances[msg.sender] = balanceOf(msg.sender).safeSub(_value);
        balances[_to] = balanceOf(_to).safeAdd(_value);
        ContractReceiver receiver = ContractReceiver(_to);
        receiver.tokenFallback(msg.sender, _value, _data);
        emit Transfer(msg.sender, _to, _value, _data);
        return true;
    }

    function balanceOf(address _owner) view public returns (uint balance) {
        return balances[_owner];
    }
  
  
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}