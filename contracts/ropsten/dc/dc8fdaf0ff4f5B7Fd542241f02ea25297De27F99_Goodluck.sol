pragma solidity ^0.5.17;

import "./ERC20.sol";
import "./ERC20Detailed.sol";
import "./ERC20Pausable.sol";
import "./ERC20Burnable.sol";
import "./ERC20Mintable.sol";
import "./Ownable.sol";

/**
 * @title SimpleToken
 * @dev Very simple ERC20 Token example, where all tokens are pre-assigned to the creator.
 * Note they can later distribute these tokens as they wish using `transfer` and other
 * `ERC20` functions.
 */
contract Goodluck is ERC20, ERC20Detailed, ERC20Pausable, ERC20Burnable, ERC20Mintable, Ownable {

    /**
     * @dev Constructor that gives msg.sender all of existing tokens.
     */
    struct LockInfo {
        uint256 _releaseTime;
        uint256 _amount;
    }
   
    address public implementation;

    mapping (address => LockInfo[]) public timelockList;
    mapping (address => bool) public frozenAccount;
   
    event Freeze(address indexed holder,bool status);    
    event Lock(address indexed holder, uint256 value, uint256 releaseTime);
    event Unlock(address indexed holder, uint256 value);

    modifier notFrozen(address _holder) {
        require(!frozenAccount[_holder], "ERC20: frozenAccount");
        _;
    }
   
    constructor () public ERC20Detailed("Goodluck Token", "GLK", 18) {
        _mint(msg.sender, 3000000000 * (10 ** uint256(decimals())));
    }
   
    function balanceOf(address owner) public view returns (uint256) {
       
        uint256 totalBalance = super.balanceOf(owner);
        if( timelockList[owner].length >0 ){
            for(uint i=0; i<timelockList[owner].length;i++){
                totalBalance = totalBalance.add(timelockList[owner][i]._amount);
            }
        }
       
        return totalBalance;
    }
   
    function transfer(address to, uint256 value) public notFrozen(msg.sender) notFrozen(to) returns (bool) {
        if (timelockList[msg.sender].length > 0 ) {
            _autoUnlock(msg.sender);            
        }
        return super.transfer(to, value);
    }
   

    function freezeAccount(address holder, bool value) public onlyPauser returns (bool) {        
        frozenAccount[holder] = value;
        emit Freeze(holder,value);
        return true;
    }

    function lock(address holder, uint256 value, uint256 releaseTime) public onlyPauser returns (bool) {
        require(_balances[holder] >= value,"There is not enough balances of holder.");
        _lock(holder,value,releaseTime);
       
        return true;
    }
   
    function transferWithLock(address holder, uint256 value, uint256 releaseTime) public onlyPauser returns (bool) {
        _transfer(msg.sender, holder, value);
        _lock(holder,value,releaseTime);
        return true;
    }
   
    function unlock(address holder, uint256 idx) public onlyPauser returns (bool) {
        require( timelockList[holder].length > idx, "There is not lock info.");
        _unlock(holder,idx);
        return true;
    }
   
    /**
     * @dev Upgrades the implementation address
     * @param _newImplementation address of the new implementation
     */
    function upgradeTo(address _newImplementation) public onlyOwner {
        require(implementation != _newImplementation);
        _setImplementation(_newImplementation);
    }
   
    function _lock(address holder, uint256 value, uint256 releaseTime) internal returns(bool) {
        _balances[holder] = _balances[holder].sub(value);
        timelockList[holder].push( LockInfo(releaseTime, value) );
       
        emit Lock(holder, value, releaseTime);
        return true;
    }
   
    function _unlock(address holder, uint256 idx) internal returns(bool) {
        LockInfo storage lockinfo = timelockList[holder][idx];
        uint256 releaseAmount = lockinfo._amount;
        timelockList[holder][idx] = timelockList[holder][timelockList[holder].length.sub(1)];
        timelockList[holder].pop();
       
        emit Unlock(holder, releaseAmount);
        _balances[holder] = _balances[holder].add(releaseAmount);
       
        return true;
    }
   
    function _autoUnlock(address holder) internal returns(bool) {
        for(uint256 idx =0; idx < timelockList[holder].length ; idx++ ) {
            if (timelockList[holder][idx]._releaseTime <= now) {
                // If lockupinfo was deleted, loop restart at same position.
                if( _unlock(holder, idx) ) {
                    idx -=1;
                }
            }
        }
        return true;
    }
   
    /**
     * @dev Sets the address of the current implementation
     * @param _newImp address of the new implementation
     */
    function _setImplementation(address _newImp) internal {
        implementation = _newImp;
    }
   
    /**
     * @dev Fallback function allowing to perform a delegatecall
     * to the given implementation. This function will return
     * whatever the implementation call returns
     */
    function () payable external {
        address impl = implementation;
        require(impl != address(0), "ERC20: account is the zero address");
        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, 0, calldatasize)
            let result := delegatecall(gas, impl, ptr, calldatasize, 0, 0)
            let size := returndatasize
            returndatacopy(ptr, 0, size)
           
            switch result
            case 0 { revert(ptr, size) }
            default { return(ptr, size) }
        }
    }
}