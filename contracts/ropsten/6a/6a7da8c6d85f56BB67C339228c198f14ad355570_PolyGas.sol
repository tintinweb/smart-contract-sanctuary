/**
 *Submitted for verification at Etherscan.io on 2021-05-26
*/

// File: contracts/Polygas.sol

pragma solidity ^0.6.2;

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

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

contract Ownable{
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract PolyGas is Ownable {
    
    using SafeMath for uint256;
  
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

   
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    struct ExcludeAddress {bool isExist;}
    mapping (address => ExcludeAddress) public excludeSendersAddresses;
    mapping (address => ExcludeAddress) public excludeRecipientsAddresses;
    
    
    string public constant name = "PolyGas";
    string public constant symbol = "POLYG";
    uint256 public constant decimals = 18;
    uint256 public _totalSupply;
    uint256 taxPercent = 4;
    address serviceWallet = 0xd5A9E423A8Af252E0efa862D679A2fEBcF4cAe19;
    
    
    function totalSupply() external view returns (uint256){
        return _totalSupply;
    }
    
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }
    
    function transfer(address recipient, uint256 amount) public returns (bool) {
        _taxTransfer(msg.sender, recipient, amount);
        return true;
    }
    
    
    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }
    
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _taxTransfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }
    
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }
    
    
    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    
    
    function _taxTransfer(address _sender, address _recipient, uint256 _amount) internal returns (bool) {

       if(!excludeSendersAddresses[_sender].isExist && !excludeRecipientsAddresses[_recipient].isExist){
        uint _taxedAmount = _amount.mul(taxPercent).div(100);
        uint _transferedAmount = _amount.sub(_taxedAmount);

        _transfer(_sender, serviceWallet, _taxedAmount); // tax to serviceWallet
        _transfer(_sender, _recipient, _transferedAmount); // amount - tax to recipient
       } else {
        _transfer(_sender, _recipient, _amount);
       }

        return true;
    }
    
    
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }
      
      function mint() external payable {
        require(msg.value > 0, "You need to send some Ether");
        require(msg.sender != address(0), "ERC20: mint to the zero address");
        uint256 amountTobuy = msg.value;
        _totalSupply = _totalSupply.add(amountTobuy);
        _balances[msg.sender] = _balances[msg.sender].add(amountTobuy);
        emit Transfer(address(0), msg.sender, amountTobuy);
    }
 
    function burn(uint256 amountToburn) external {
        require(amountToburn > 0, "You need to sell at least some tokens");
        require(_balances[msg.sender]>=amountToburn,"Check the token allowance");
        _balances[msg.sender]=_balances[msg.sender].sub(amountToburn);
        _totalSupply = _totalSupply.sub(amountToburn);
        payable(msg.sender).transfer(amountToburn);
        emit Transfer(msg.sender,address(0),amountToburn);
    }
        

  
    // OWNER utils
    function setAddressToExcludeRecipients (address addr) public onlyOwner {
        excludeRecipientsAddresses[addr] = ExcludeAddress({isExist:true});
    }

    function setAddressToExcludeSenders (address addr) public onlyOwner {
        excludeSendersAddresses[addr] = ExcludeAddress({isExist:true});
    }

    function removeAddressFromExcludes (address addr) public onlyOwner {
        excludeSendersAddresses[addr] = ExcludeAddress({isExist:false});
        excludeRecipientsAddresses[addr] = ExcludeAddress({isExist:false});
    }

    function changePercentOfTax(uint percent) public onlyOwner {
        taxPercent = percent;
    }

    function changeServiceWallet(address addr) public onlyOwner {
        serviceWallet = addr;
    }

    
}