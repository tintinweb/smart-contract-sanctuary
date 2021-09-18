// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.4.22 <0.9.0;

import "./IERC20.sol";

contract LuckEToken is IERC20 {

    string public override name;
    string public override symbol;

    uint8 public override decimals;

    uint256 public override totalSupply;

    mapping(address => uint256) public override balanceOf;
    mapping(address => mapping(address => uint256)) public override allowance;

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        uint256 initialSupply
    ) {
        name    = _name;
        symbol  = _symbol;
        decimals = _decimals;
        _mint(msg.sender, initialSupply);
    }

    /**
     * @dev External Functions
     */

     function approve(
         address spender,
         uint256 amount
    )external override returns (bool) {
         _approve(msg.sender, spender, amount);
         return true;
     }

     function transfer(
         address recipient,
         uint amount
    ) external override returns (bool) {
         _transfer(msg.sender, recipient, amount);
         return true;
     }

     function transferFrom(
         address owner,
         address recipient,
         uint256 amount
    ) external override returns (bool) {
         _approve(owner, msg.sender, allowance[owner][msg.sender] - amount);
         _transfer(owner, recipient, amount);
         return true;
     }

    /**
     * @dev Internal Functions
     */

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal {
        require(owner != address(0), "XERC20: approve from the zero address");
        require(spender != address(0), "XERC20: approve to the zero address");

        emit Approval(owner, spender, allowance[owner][spender] = amount);
    }

    function _transfer(
        address owner,
        address recipient,
        uint256 amount
    ) internal {
        require(owner != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        balanceOf[owner]     -= amount;
        balanceOf[recipient] += amount;

        emit Transfer(owner, recipient, amount);
    }

    function _mint(
        address recipient,
        uint256 amount
    ) internal {
        require(recipient != address(0), "XERC20: mint to the zero address");

        amount = amount * 10 ** decimals;

        totalSupply          += amount;
        balanceOf[recipient] += amount;

        emit Transfer(address(0), recipient, amount);
    }

    function _burn(
        address owner,
        uint256 amount
    ) internal {
        require(owner != address(0), "XERC20: burn from the zero address");

        amount = amount * 10 ** decimals;

        balanceOf[owner] -= amount;
        totalSupply      -= amount;

        emit Transfer(owner, address(0), amount);
    }

}