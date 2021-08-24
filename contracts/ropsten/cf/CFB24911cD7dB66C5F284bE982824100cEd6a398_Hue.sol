// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.0;

import "./ERC20.sol";
import "./Ownable.sol";

contract Hue is ERC20, Ownable{
    
    mapping(address => bool) addressExist;

    uint private taxation = 6; 
    
    bool private firstInit = true;
    
    address private _ownerAddress;
    address private _charityWallet;
    address private _marketingWallet;
    address private _burnWallet;
    address[] internal _staking;
    function addStakeholder(address _walletAddress) public onlyOwner{
        require(!addressExist[_walletAddress], "This addres already in system");
        _staking.push(_walletAddress);
        addressExist[_walletAddress] = true;
    }
    
    function setCharityWallet(address _walletAddress) private returns(bool){
        _charityWallet = _walletAddress;
        return true;
    }
    
    function setMarketingWallet(address _walletAddress) public returns(bool){
        _marketingWallet = _walletAddress;
        return true;
    }
    
    function removeStakeholder(address _stakeholder)public onlyOwner{
        require(addressExist[_stakeholder], "Address not exist");
        uint location;
        for(uint i = 0; i < _staking.length; i++){
            if(_staking[i] == _stakeholder){
                location = i;
            }
        }
        _staking[location] = _staking[_staking.length - 1];
        _staking.pop();
    }
    constructor(string memory token_name, string memory token_symbol, address[] memory stakeholders) ERC20(token_name, token_symbol){
        _ownerAddress = msg.sender;
        _mint(_ownerAddress, 1000000000000*10**decimals());
        
        for(uint i = 0; i < stakeholders.length; i++){
	        addStakeholder(stakeholders[i]);
	        
	    }
    }
    
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    function mint(uint256 amount) public virtual onlyOwner returns (bool) {
        _mint(_msgSender(), amount);
        return true;
    }
    function burn(uint256 amount) public virtual onlyOwner returns (bool) {
        _burn(_msgSender(), amount);
        return true;
    }
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        uint256 currentAllowance = allowance(sender, _msgSender());
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

        return true;
    }
    
    function listStakeholders() public view returns(address[] memory){
        return _staking;
    }
}