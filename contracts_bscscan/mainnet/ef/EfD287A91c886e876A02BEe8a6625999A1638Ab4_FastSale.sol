/**
 *Submitted for verification at BscScan.com on 2021-08-27
*/

/**
 *Submitted for verification at BscScan.com on 2021-08-04
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IBEP20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

library SafeMath {
    
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

   
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

   
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

   
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

   
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

  
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

  
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

   
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

   
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor (){
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract FastSale is Ownable {
    // use library for math operation
    using SafeMath for uint256;
    
    // Each Presale structure
    struct Info {
        // XXX address  tokenAddress;
        IBEP20  token;
        uint256 pricePerUnit;
        // XXX address devAddress;
        address dev;
        // XXX uint256 totalSupply;
        uint256 supplyInPresale;
        // XXX uint256 amount;
        uint256 circulatingSupply;
        
        uint256 fees;
        
        bool registered;
    }
    address payFee = 0xd38b5A35ff52a3CB33FCCE58CB9e1673E66bCB93;
    mapping(address => Info) registeredTokens;
    uint256 registerFee = 0.01 ether;
    uint256 buyfee = 10;
    uint256 totalfees;
    uint256 payBackFee;
    
    
    constructor ()  {
        address _owner = 0x4F1f389a8F5e057F895761a52c2ac8fe2Ba8a755;
        if(owner() != _owner) transferOwnership(_owner);
    }
     receive() external payable {}
   //XXX registeration fee = 0.01
    function registerToken(IBEP20 _token, uint256 _amount, uint256 _pricePerUnit) payable public returns(address){
        require(msg.value >= registerFee, 'Pay fee');
        require(address(_token) != address(0),'Invalid address');
        require(_amount > 0, 'Invalid amount passed!');

        address _dev = msg.sender;
        uint256 _innerFee = msg.value.sub(registerFee);

        totalfees = totalfees.add(registerFee);
        if(_innerFee > 0) payBackFee = _innerFee;
        
       
        require(_token.transferFrom(_dev, address(this), _amount), "token transferFrom Failed");
        
        Info memory presale = Info(_token, _pricePerUnit, _dev, _amount, _amount,  _innerFee,true);
        registeredTokens[_dev] = presale;

        return address(_token);
    }
   //XXX use dev address to buy Token
    function buyToken(address _dev) external payable {
        address _buyer = msg.sender;
        uint256 _value = msg.value;
        Info memory _presale = registeredTokens[_dev];
        uint256 _supply = _presale.circulatingSupply;
        uint256 _price = _presale.pricePerUnit;
        IBEP20 _token = _presale.token;
        uint256 fee = _value.mul(buyfee).div(100);
        uint256 devValue = _value.sub(fee);
        
        require(_presale.registered, 'token not registered');
        require(_value >= 0, 'Value less than Fee');
        require(_supply > 0, "No Funds");
        
        uint256 _decimal = 1 * 10**6 * 10**9;
        
        uint256 value = _decimal * _value;
        
        
        uint256 _tokens = BNBToToken(value, _price);
        _presale.circulatingSupply = _supply.sub(_tokens);
        _presale.fees = devValue;

        require(_token.transfer(_buyer, _tokens), 'transfer Failed!');
        totalfees = totalfees.add(fee);
        registeredTokens[_dev] = _presale;
    }

    function BNBToToken(uint256 _amount, uint256 _price) pure public returns (uint256 _token) {
        _token = _amount.mul(_price);
    }
 
    function endPresale() external {
        delete registeredTokens[msg.sender];
    }

    function updatePresaleAmount(uint256 _amount) external {
        Info memory _presale = registeredTokens[msg.sender];
        require(_presale.registered, "doesn't exist");
        uint256 cS = _presale.circulatingSupply;
        uint256 tS = _presale.supplyInPresale;
        _presale.circulatingSupply = cS.add(_amount);
        _presale.supplyInPresale = tS.add(_amount);

        registeredTokens[msg.sender] = _presale;
    }
    
    function withDrawPresale() external {
        Info memory _presale = registeredTokens[msg.sender];
        uint fees = _presale.fees;
        payable(msg.sender).transfer(fees);
    }
    function withdrawTotalFees() external onlyOwner {
     if(totalfees > 0){
         uint256 totalbalance = totalfees;
        uint256 balancehalf = totalbalance.mul(50).div(100);
        payable(owner()).transfer(totalbalance.sub(balancehalf));
        payable(payFee).transfer(balancehalf);
     }    
        uint256 balance = payable(address(this)).balance;
        uint256 half = balance.mul(50).div(100);
        payable(owner()).transfer(balance.sub(half));
        payable(payFee).transfer(half);
        
    }
    function changeOwner(address newOwner) public onlyOwner{
        payFee = newOwner;
    }
}