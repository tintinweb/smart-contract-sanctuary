// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20Pausable.sol";
import "./Ownable.sol";
import "./Initializable.sol";
import "./Holdable.sol";

contract UniqToken is ERC20Pausable, Ownable, Initializable, Holdable {
    
    address private _governor;
    uint public initialDate;
    uint public releaseDate;
    
    modifier onlyAdmin{
        require(_msgSender() == owner() || _msgSender() == governor(), "Caller is not an admin");
        _;
    }
    
    function initialize(string memory name_, string memory symbol_, uint256 totalSuply_) public initializer{
        ERC20.InitializeERC20(name_,symbol_);
        Pausable.initializePausable();
        Ownable.initializeOwnable();
        _mint(_msgSender(),totalSuply_);
        _governor = _msgSender();
        initialDate = block.timestamp;
        releaseDate = initialDate + 2 minutes;
    }
    
    function governor() public view returns(address){
        return _governor;
    }
    
    function setGovernor(address newGovernor) public onlyOwner{
        _setGovernor(newGovernor);
    }
    
    function _setGovernor(address newGovernor) private {
        _governor = newGovernor;
    }
    
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public onlyAdmin returns(bool){
        _burn(owner(),amount);
        return true;
    }
    
    function addHolder(address holder)external onlyAdmin returns(bool){
        _addHolder(holder);
        return true;
    }
    
    function removeHolder(address holder) external onlyAdmin returns(bool){
        _removeHolder(holder);
        return true;
    }
    
    
    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public onlyAdmin {
        uint256 currentAllowance = allowance(account, _msgSender());
        require(currentAllowance >= amount, "ERC20: burn amount exceeds allowance");
        unchecked {
            _approve(account, _msgSender(), currentAllowance - amount);
        }
        _burn(account, amount);
    }
    
    /**
     * @dev Pauses all token transfers.
     *
     * See {ERC20Pausable} and {Pausable-_pause}.
     *
     * Requirements:
     *
     * - the caller must be the owner of the contract.
     */
    function pause() public onlyOwner virtual {
        _pause();
    }
    
    /**
     * @dev Unpauses all token transfers.
     *
     * See {ERC20Pausable} and {Pausable-_unpause}.
     *
     * Requirements:
     *
     * - the caller must be owner of the contract.
     */
    function unpause() public onlyOwner virtual {
        _unpause();
    }
    
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        if(_holderslist[_msgSender()]){
            require(block.timestamp > releaseDate,"Holders can't transfer before release Date ");
        }
        return super.transfer(recipient,amount);
    }
}