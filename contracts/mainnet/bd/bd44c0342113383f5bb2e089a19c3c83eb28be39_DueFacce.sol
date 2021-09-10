pragma solidity ^0.8.0;

import "./ERC20-v0.8.0.sol";

contract DueFacce is ERC20 {
    address owner;
    string Name = "Due Facce";
    string Symbol = "DFC";
    uint256 private initialSupply;
    bool private mintOnce = false;

    constructor(address _owner) ERC20(Name, Symbol) {
        owner = _owner;
        initialSupply = 2000000000 * 10**18;
        mint(owner, initialSupply);
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "caller is not admin");
        _;
    }

    function BeginTokenLock() external onlyOwner {
        tokenLocked = true;
    }

    function EndTokenLock() external onlyOwner {
        tokenLocked = false;
    }

    function RestrictAddress(address _addressToBeRestricted) public onlyOwner {
        RestrictedAddress[_addressToBeRestricted] = true;
    }

    function UnrestrictAddress(address _addressToBeUnrestricted)
        public
        onlyOwner
    {
        RestrictedAddress[_addressToBeUnrestricted] = false;
    }

    function setNewOwner(address _owner) external onlyOwner {
        owner = _owner;
    }

    function mint(address recipient, uint256 amount) public {
        require(tokenLocked == false, "token locked");
        require(mintOnce != true, 'can only mint once');

        mintOnce = true;
        _mint(recipient, amount);
        
    }

    //only token holders can burn their  tokens
    function burn(uint256 amount) external {
        require(tokenLocked == false, "token locked");
        _burn(msg.sender, amount);
    }
}