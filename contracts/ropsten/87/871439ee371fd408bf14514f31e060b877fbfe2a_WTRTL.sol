/**
 *Submitted for verification at Etherscan.io on 2021-10-07
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint256 amount);

    event Transfer(address indexed from, address indexed to, uint256 amount);

    function approve(address spender, uint256 amount) external returns (bool);

    function balanceOf(address account) external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

contract Ownable {
    address payable public owner = payable(0);

    event Owner(address indexed _prev, address indexed _new);

    constructor () {
        owner = payable(msg.sender);

        emit Owner(address(0), msg.sender);
    }

    modifier isOwner() {
        require(msg.sender == owner, "Caller is not owner");

        _;
    }

    function renounceOwnership() public isOwner {
        transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public isOwner {
        owner = payable(newOwner);

        emit Owner(msg.sender, newOwner);
    }

    function withdrawEther(uint256 amount) public isOwner {
        owner.transfer(amount);
    }

    receive() external payable {}
}

abstract contract Burnable is Ownable {
    bool public burnable = true;

    modifier isBurnable() {
        require(burnable == true, "Burning disabled");

        _;
    }

    function burn(uint256 amount) public virtual;

    function lockBurning() public isBurnable isOwner {
        burnable = false;
    }
}

abstract contract Mintable is Ownable {
    bool public mintable = true;

    modifier isMintable() {
        require(mintable == true, "Minting disabled");

        _;
    }

    function lockMinting() public isMintable isOwner {
        mintable = false;
    }

    function mint(address to, uint256 amount) public virtual;
}

contract WTRTL is IERC20, Burnable, Mintable {
    uint256 internal tokenSupply = 0;

    uint8 public decimals = 2;

    string public name = "WrappedTurtleCoin";

    string public symbol = "WTRTL";

    mapping (address => uint256) internal balances;

    mapping (address => mapping (address => uint256)) internal allowances;

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        require(balances[msg.sender] >= amount, "ERC20: approval amount exceeds balance");

        allowances[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return balances[account];
    }

    function burn(uint256 amount) public override isBurnable isOwner {
        balances[msg.sender] -= amount;

        tokenSupply -= amount;

        emit Transfer(msg.sender, address(0), amount);
    }

    function mint(address to, uint256 amount) public override isMintable isOwner {
        tokenSupply += amount;

        balances[to] += amount;

        emit Transfer(address(0), to, amount);
    }

    function totalSupply() public view override returns (uint256) {
        return tokenSupply;
    }

    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        return _transfer(msg.sender, to, amount);
    }

    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
        allowances[from][msg.sender] -= amount;

        return _transfer(from, to, amount);
    }

    function _transfer(address from, address to, uint256 amount) internal virtual returns (bool) {
        require(to != address(0), "ERC20: transfer to the zero address");

        balances[from] -= amount;

        balances[to] += amount;

        emit Transfer(from, to, amount);

        return true;
    }
}