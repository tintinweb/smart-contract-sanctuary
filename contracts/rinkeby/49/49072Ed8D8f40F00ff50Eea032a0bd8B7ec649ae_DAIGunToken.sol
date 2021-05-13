/**
 *Submitted for verification at Etherscan.io on 2021-05-13
*/

//SPDX-License-Identifier: UNLICENSED //0.5.12

// pragma solidity ^0.7.0;
// pragma experimental ABIEncoderV2;
pragma solidity ^0.8.0;


interface IERC20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);    
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


abstract contract ERC20 is IERC20 {
        constructor () { }

    function _msgSender() internal view returns (address payable) {
        return payable(msg.sender);
    }
    // using SafeMath for uint256;

    // string public name = 'DAI Token';       
    // string public symbol = 'DAI';               //当作DAI的测试币

    uint8 internal _decimals = 18;                //18位
    function decimals() external view override returns (uint8) {
        return _decimals;
    }

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    uint256 private _totalSupply = 0;

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    //Fix for short address attack against ERC20    //现在的虚拟机应该处理了，没求毛用。
	modifier onlyPayloadSize(uint size) {
		assert(msg.data.length == size + 4);
		_;
	}
   
    function transfer(address recipient, uint256 amount) public  onlyPayloadSize(2*32)  override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
   
    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }
   
    function approve(address spender, uint256 amount) public  onlyPayloadSize(2*32)  override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    
    function transferFrom(address sender, address recipient, uint256 amount) public onlyPayloadSize(3 * 32) override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()] - (amount));
        return true;
    }
  
    function _transfer(address sender, address recipient, uint256 amount) internal  {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        
        _balances[sender] = _balances[sender] - (amount);
        _balances[recipient] = _balances[recipient] + (amount);
        emit Transfer(sender, recipient, amount);
    }
    
    function _mint(address account, uint256 amount) internal  {
        require(account != address(0), "ERC20: mint to the zero address");
      
        _totalSupply = _totalSupply + (amount);
        _balances[account] = _balances[account] + (amount);
        emit Transfer(address(0), account, amount);
    }
    
    function burn(uint256 amount) public {
        _burn(_msgSender(), amount);
    }

    function _burn(address account, uint256 amount) internal  {
        require(account != address(0), "ERC20: burn from the zero address");

        _balances[account] = _balances[account] - (amount);
        _totalSupply = _totalSupply - (amount);
        emit Transfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

  
}


// // 这个 ERC20 通用 Token， 用于测试
// contract UsdtToken is ERC20 {
    
//     string public name = 'Usdt Token';       
//     string public symbol = 'Usdt';               //当作DAI的测试币
//     //   uint8 private _decimals = 6;               //18位

//     constructor() {
//         _decimals = 6;
//         _mint(msg.sender,  (1e9) * (10 ** uint256(_decimals)));        
//     }

//     // 谁都可用挖矿，用于测试
//     function TestMint() external  {
//          _mint(msg.sender,  (1e9) * (10 ** uint256(_decimals)));        
//     }
// }




// 这个 ERC20 通用 Token， 用于测试
contract DAIGunToken is ERC20 {
    
    string public name = 'Dai Gun Token';       
    string public symbol = 'DaiGun';               //当作DAI的测试币
    //   uint8 private _decimals = 6;               //18位

    constructor() {
        _decimals = 18;
        _mint(msg.sender,  (1e9) * (10 ** uint256(_decimals)));        
    }

    // 谁都可用挖矿，用于测试
    function TestMint() external  {
         _mint(msg.sender,  (1e9) * (10 ** uint256(_decimals)));        
    }


}