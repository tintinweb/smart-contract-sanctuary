pragma solidity 0.4.24;

import "./DetailedERC20.sol";
import "./PausableToken.sol";
import "./MintableToken.sol";
import "./BurnableToken.sol";
import "./MapBoolOfAddress.sol";


contract ZadToken is DetailedERC20, PausableToken, MintableToken, BurnableToken {
    MapBoolOfAddress locks;
    
    constructor(string _name, string _symbol, uint8 _decimals, uint256 _amount)
    DetailedERC20(_name, _symbol, _decimals) public {
        require(_amount > 0, "amount has to be greater than 0");
        totalSupply_ = _amount.mul(10 ** uint256(_decimals));
        balances[msg.sender] = totalSupply_;
        locks = new MapBoolOfAddress();
        emit Transfer(address(0), msg.sender, totalSupply_);
    }
    
    function _zadToWei(uint256 _zad) public view returns (uint256) {
        return _zad.mul(10 ** uint256(decimals));
    }
    
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(!locks.getByKey(msg.sender), "locked address");
        
        return super.transfer(_to, _value);
    }
    
    function tokenInfo() public view returns (string, string, uint256, address, address) {
        address _tokenAddress = this;
        
        return (name, symbol, totalSupply_, _tokenAddress, owner);
    }
    
    function lock(address _beneficiary) external onlyOwner {
        locks.addOrUpdate(_beneficiary, true);
    }
    
    function lockMany(address[] _beneficiaries) external onlyOwner {
    	for (uint i = 0; i < _beneficiaries.length; i++) {
    		locks.addOrUpdate(_beneficiaries[i], true);
    	}
    }
    
    function lockAll() external onlyOwner {
        uint _size = locks.size();
        address[] memory _beneficiaries = locks.getKeys();
        for (uint i = 0; i < _size; i++) {
            address _beneficiary = _beneficiaries[i];
            locks.addOrUpdate(_beneficiary, true);
        }
    }
    
    function unlock(address _beneficiary) external onlyOwner {
        locks.addOrUpdate(_beneficiary, false);
    }
    
    function unlockMany(address[] _beneficiaries) external onlyOwner {
    	for (uint i = 0; i < _beneficiaries.length; i++) {
    		locks.addOrUpdate(_beneficiaries[i], false);
    	}
    }
    
    function unlockAll() external onlyOwner {
        uint _size = locks.size();
        address[] memory _beneficiaries = locks.getKeys();
        for (uint i = 0; i < _size; i++) {
            address _beneficiary = _beneficiaries[i];
            locks.addOrUpdate(_beneficiary, false);
        }
    }
    
    function islock(address _beneficiary) public view returns (bool) {
        return locks.getByKey(_beneficiary);
    }
}