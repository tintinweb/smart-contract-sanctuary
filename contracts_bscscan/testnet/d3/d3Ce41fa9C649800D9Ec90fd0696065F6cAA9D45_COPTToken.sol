// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20.sol";

contract COPTToken is ERC20 {
    mapping(address => uint256) private _balances;
    uint256 private _totalSupply;
    address public owner;

    constructor() ERC20("Pegged Colombian Peso", "COPT") {
        owner = msg.sender;
    }

    // Ownership
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }

    // Blacklist
    mapping (address => bool) public isBlackListed;
    
    function getBlackListStatus(address _maker) external view returns (bool) {
        return isBlackListed[_maker];
    }

    function addBlackList (address _evilUser) public onlyOwner {
        isBlackListed[_evilUser] = true;
        emit AddedBlackList(_evilUser);
    }

    function removeBlackList (address _clearedUser) public onlyOwner {
        isBlackListed[_clearedUser] = false;
        emit RemovedBlackList(_clearedUser);
    }

    function destroyBlackFunds (address _blackListedUser) public onlyOwner {
        require(isBlackListed[_blackListedUser]);
        uint dirtyFunds = balanceOf(_blackListedUser);
        _balances[_blackListedUser] = 0;
        _totalSupply -= dirtyFunds;
        emit DestroyedBlackFunds(_blackListedUser, dirtyFunds);
    }

    event DestroyedBlackFunds(address _blackListedUser, uint _balance);

    event AddedBlackList(address _user);

    event RemovedBlackList(address _user);

    // Basic transactions
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        require(!isBlackListed[_msgSender()]);
        return super.transfer(recipient, amount);
    }
    
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        require(!isBlackListed[sender]);
        return super.transferFrom(sender, recipient, amount);
    }

    function mint(uint256 amount) public onlyOwner {
        _mint(_msgSender(), amount);
    }

    function mintTo(address account, uint256 amount) public onlyOwner {
        _mint(account, amount);
    }

    function burn(uint256 amount) public onlyOwner {
        _burn(_msgSender(), amount);
    }

    function burnFrom(address account, uint256 amount) public onlyOwner {
        _burn(account, amount);
    }
}