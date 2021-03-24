/**
 *Submitted for verification at Etherscan.io on 2021-03-24
*/

/*
/  ░██████╗░██╗░░░░░░░██╗░█████╗░██████╗░
/  ██╔════╝░██║░░██╗░░██║██╔══██╗██╔══██╗
/  ╚█████╗░░╚██╗████╗██╔╝███████║██████╔╝
/  ░╚═══██╗░░████╔═████║░██╔══██║██╔═══╝░
/  ██████╔╝░░╚██╔╝░╚██╔╝░██║░░██║██║░░░░░
/  ╚═════╝░░░░╚═╝░░░╚═╝░░╚═╝░░╚═╝╚═╝░░░░░
/ 
/  https://www.adonexchange.com
/  https://twitter.com/official_adon
/  https://t.me/adonexchange
/  
*/

pragma solidity 0.5.16;

interface IBorrower {
    function executeOnFlashMint(uint256 amount) external;
}



pragma solidity ^0.5.0;


library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }


    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
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

        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;


        return c;
    }


    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v2.3.0/contracts/token/ERC20/IERC20.sol

pragma solidity ^0.5.0;


interface IERC20 {

    function totalSupply() external view returns (uint256);


    function balanceOf(address account) external view returns (uint256);


    function transfer(address recipient, uint256 amount) external returns (bool);


    function allowance(address owner, address spender) external view returns (uint256);


    function approve(address spender, uint256 amount) external returns (bool);


    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);


    event Transfer(address indexed from, address indexed to, uint256 value);


    event Approval(address indexed owner, address indexed spender, uint256 value);
}



pragma solidity ^0.5.0;




contract ERC20 is IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;


    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }


    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }


    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }


    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }


    function approve(address spender, uint256 value) public returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }


    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount));
        return true;
    }


    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
        return true;
    }


    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue));
        return true;
    }



    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }


    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }


    function _burn(address account, uint256 value) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }


    function _approve(address owner, address spender, uint256 value) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = value;
        emit Approval(owner, spender, value);
    }


    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, msg.sender, _allowances[account][msg.sender].sub(amount));
    }
}

pragma solidity 0.5.16;


contract AdonToken is ERC20 {
    using SafeMath for uint256;

    string public name = "Adon Exchange";
    string public symbol = "ADN";
    uint8 public decimals = 18;

    function() external payable {
        _mint(msg.sender, msg.value);
    }


    function deposit() public payable {
        _mint(msg.sender, msg.value);
    }


    function withdraw(uint256 amount) public {
        _burn(msg.sender, amount); 
        msg.sender.transfer(amount);
    }

    //////////////////////
    // AdonExchange.com //
    /////////////////////

    modifier flashMint(uint256 amount) {

        _mint(msg.sender, amount); 


        _;

        // burn tokens
        _burn(msg.sender, amount); 


        require(
            address(this).balance >= totalSupply(),
            "redeemability was broken"
        );
    }


    function softFlashFuck(uint256 amount) public flashMint(amount) {

        IBorrower(msg.sender).executeOnFlashMint(amount);
    }


    function hardFlashFuck(
        address target,
        bytes memory targetCalldata,
        uint256 amount
    ) public flashMint(amount) {
        (bool success, ) = target.call(targetCalldata);
        require(success, "external call failed");
    }
}